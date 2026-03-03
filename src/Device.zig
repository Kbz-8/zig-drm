const std = @import("std");
const drm = @import("drm.zig");
const sys = @import("sys.zig");
const log = std.log.scoped(.drm);

const node_max = 3;

const Device = @This();

nodes: struct {
    primary: ?[drm.max_node_name]u8,
    /// Deprecated
    control: ?[drm.max_node_name]u8,
    render: ?[drm.max_node_name]u8,
},
bus_info: union(BusType) {
    pci: PciBusInfo,
    usb: UsbBusInfo,
    platform: PlatformBusInfo,
    host1x: Host1xBusInfo,
    faux: FauxBusInfo,
    virtio: void,
},
device_info: union(BusType) {
    pci: PciDeviceInfo,
    usb: UsbDeviceInfo,
    platform: PlatformDeviceInfo,
    host1x: Host1xDeviceInfo,
    faux: void,
    virtio: void,
},

pub const Flags = packed struct {
    get_pci_revision: bool = false,
};

pub fn getFromDevId(io: std.Io, devid: std.posix.dev_t, flags: Flags) !Device {
    var local_devices: [drm.max_nodes]Device = undefined;

    const major = drm.devMajor(devid);
    const minor = drm.devMinor(devid);

    if (!drm.nodeIsDrm(io, major, minor))
        return error.NotDrmDevice;

    const subsystem_type = try drm.parseSubsystemType(io, major, minor);

    const sysdir = try std.Io.Dir.openDirAbsolute(io, drm.dir_name, .{ .iterate = true });
    defer sysdir.close(io);

    var it = sysdir.iterate();
    const i: usize = 0;
    while (try it.next(io)) |entry| {
        const dev = processDevice(entry.name, subsystem_type, true, flags) catch continue;

        if (i >= drm.max_nodes) {
            log.err(
                "More than {d} drm nodes detected. This is a bug. Extra nodes will be skipped.",
                .{drm.max_nodes},
            );
            break;
        }

        local_devices[i] = dev;
        i += 1;
    }

    return for (local_devices[0..i]) |dev| {
        if (hasRdev(dev, devid)) break dev;
    } else error.NoDeviceFound;
}

pub const BusType = enum(c_int) {
    pci = 0,
    usb = 1,
    platform = 2,
    host1x = 3,
    faux = 4,
    /// According to libdrm, "Little white lie to avoid major rework of the existing code"
    virtio = 0x10,
};

pub const PciBusInfo = struct {
    domain: u16,
    bus: u8,
    dev: u8,
    func: u8,
};

pub const PciDeviceInfo = struct {
    vendor_id: u16,
    device_id: u16,
    subvendor_id: u16,
    subdevice_id: u16,
    revision_id: u8,
};

pub const UsbBusInfo = struct {
    bus: u8,
    dev: u8,
};

pub const UsbDeviceInfo = struct {
    vendor: u16,
    product: u16,
};

pub const platform_device_name_len = 512;

pub const PlatformBusInfo = struct {
    fullname: [platform_device_name_len]u8,
};

pub const PlatformDeviceInfo = struct {
    compatible: [][]const u8,
};

pub const host1x_device_name_len = 512;

pub const Host1xBusInfo = struct {
    fullname: [host1x_device_name_len]u8,
};

pub const Host1xDeviceInfo = struct {
    compatible: [][]const u8,
};

pub const faux_device_name_len = 512;

pub const FauxBusInfo = struct {
    name: [faux_device_name_len]u8,
};

pub fn parseSubsystemType(io: std.Io, major: u32, minor: u32) !Device.BusType {
    var path_buf: [std.os.linux.PATH_MAX]u8 = undefined;
    var path = std.ArrayList(u8).initBuffer(&path_buf);
    path.printAssumeCapacity("/sys/dev/char/{d}:{d}/device", .{ major, minor });

    var subsystem_type = try getSubsystemType(io, path.items);
    if (subsystem_type == .virtio) {
        path.appendSliceAssumeCapacity("/..");
        subsystem_type = getSubsystemType(io, path.items) catch .virtio;
    }

    return subsystem_type;
}

fn getSubsystemType(io: std.Io, device_path: []const u8) !Device.BusType {
    const bus_types = [_]struct { name: []const u8, bus_type: Device.BusType }{
        .{ .name = "/pci", .bus_type = .pci },
        .{ .name = "/usb", .bus_type = .usb },
        .{ .name = "/platform", .bus_type = .platform },
        .{ .name = "/spi", .bus_type = .platform },
        .{ .name = "/host1x", .bus_type = .host1x },
        .{ .name = "/virtio", .bus_type = .virtio },
        .{ .name = "/faux", .bus_type = .faux },
    };

    var path_buf: [std.os.linux.PATH_MAX]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/subsystem", .{device_path}) catch unreachable;

    var link_buf: [std.os.linux.PATH_MAX]u8 = undefined;
    const link_len = try std.Io.Dir.cwd().readLink(io, path, &link_buf);
    const link = link_buf[0..link_len];

    const last = std.mem.findScalarLast(u8, link, '/') orelse unreachable;
    const name = link[last..];
    if (name.len == 0) return error.InvalidDevice;

    return for (bus_types) |bus_type| {
        if (std.mem.eql(u8, bus_type.name, name)) break bus_type.bus_type;
    } else error.InvalidDevice;
}

pub const NodeType = enum {
    primary,
    /// Deprecated
    control,
    render,
    _max,
};

fn processDevice(
    io: std.Io,
    name: []const u8,
    required_subsystem_type: sys.BusType,
    fetch_devinfo: bool,
    flags: Flags,
) !Device {
    const max_node_length = std.mem.alignForward(usize, drm.max_node_name, @sizeOf(usize));
    const node_type = try getNodeType(name);

    var path_buf: [std.os.linux.PATH_MAX]u8 = undefined;
    const node = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ drm.dir_name, name }) catch unreachable;

    if (node.len + 1 > max_node_length)
        return error.NodePathTooLong;

    const stat = try statx(node);

    if (!drm.nodeIsDrm(io, stat.rdev_major, stat.rdev_minor) || !std.os.linux.S.ISCHR(stat.mode))
        return error.InvalidDevice;

    const subsystem_type = try drm.parseSubsystemType(io, stat.rdev_major, stat.rdev_minor);
    if (subsystem_type != required_subsystem_type)
        return error.IncorrectSubsystemType;

    _ = fetch_devinfo;
    _ = flags;
    _ = node_type;
    return switch (subsystem_type) {
        .pci, .virtio => error.PciUnimplemented,
        .usb => error.UsbInimplemented,
        .platform => error.PlatformUnimplemented,
        .host1x => error.Host1xUnimplemented,
        .faux => error.FauxUnimplemented,
    };
}

fn processPciDevice(
    node: []const u8,
    node_type: drm.NodeType,
    major: u32,
    minor: u32,
    fetch_devinfo: bool,
    flags: Flags,
) !*Device {
    var device = Device{
        .nodes = .{ .primary = null, .control = null, .render = null },
        .bus_info = undefined,
        .device_info = undefined,
    };

    _ = &device;

    return device;
}

fn parsePciBusInfo(major: u32, minor: u32) !PciBusInfo {
    const pci_path = try getPciPath(major, minor);

    const value = try sysfsUeventGet(&pci_path, "PCI_SLOT_NAME");

    const format = "{x:4}:{x:2}:{x:2}.{d:1}";

    return PciBusInfo{
        .domain = 0,
        .bus = 0,
        .dev = 0,
        .func = 0,
    };
}

fn hasRdev(dev: Device, rdev: std.posix.dev_t) bool {
    const node_fields = @typeInfo(@FieldType(Device, "available_nodes")).@"struct".fields;
    inline for (node_fields, dev.nodes) |field, node| {
        if (@field(dev.available_nodes, field.name)) {
            const stat = statx(node) catch continue;
            if (drm.makeDev(stat.rdev_major, stat.rdev_minor) == rdev) return true;
        }
    }

    return false;
}

fn getNodeType(name: []const u8) !drm.NodeType {
    if (std.mem.eql(u8, name, drm.primary_minor_name)) return .primary;
    if (std.mem.eql(u8, name, drm.control_minor_name)) return .control;
    if (std.mem.eql(u8, name, drm.render_minor_name)) return .render;

    return error.InvalidName;
}

fn statx(path: []const u8) !std.os.linux.Statx {
    const posix_path = std.posix.toPosixPath(path);
    var stat_buf: std.os.linux.Statx = undefined;
    const rc = std.os.linux.statx(std.os.linux.AT.FDCWD, &posix_path, 0, .{}, &stat_buf);
    return switch (std.posix.errno(rc)) {
        .SUCCESS => stat_buf,
        else => |err| std.posix.unexpectedErrno(err),
    };
}

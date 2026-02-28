const std = @import("std");
const drm = @import("drm.zig");
const sys = @import("sys.zig");
const log = std.log.scoped(.drm);

const node_max = 3;

const Device = @This();

nodes: [node_max][]const u8,
available_nodes: packed struct(u3) {
    primary: bool = false,
    /// Deprecated
    control: bool = false,
    render: bool = false,
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

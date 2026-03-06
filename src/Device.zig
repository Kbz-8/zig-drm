const std = @import("std");
const path_max = std.os.linux.PATH_MAX;

const Card = @import("Card.zig");
const drm = @import("drm.zig");
const sys = @import("sys.zig");

const log = std.log.scoped(.drm);
const Device = @This();

node_type: NodeType,
node_path_buf: [drm.max_node_name:0]u8,
bus_info: union(BusType) {
    pci: PciBusInfo,
    usb: UsbBusInfo,
    platform: PlatformBusInfo,
    host1x: Host1xBusInfo,
    faux: FauxBusInfo,
    virtio: void,
},
device_info: ?union(BusType) {
    pci: PciDeviceInfo,
    usb: UsbDeviceInfo,
    platform: PlatformDeviceInfo,
    host1x: Host1xDeviceInfo,
    faux: void,
    virtio: void,
},

pub fn nodePath(self: *const Device) []const u8 {
    return std.mem.sliceTo(&self.node_path_buf, 0);
}

pub const Flags = packed struct {
    get_pci_revision: bool = false,
};

pub fn getFromDevId(io: std.Io, gpa: std.mem.Allocator, devid: std.posix.dev_t, flags: Flags) !Device {
    var local_devices: [drm.max_nodes]Device = undefined;

    const major = drm.devMajor(devid);
    const minor = drm.devMinor(devid);

    if (!drm.nodeIsDrm(io, major, minor))
        return error.NotDrmDevice;

    const subsystem_type = try parseSubsystemType(io, major, minor);

    const sysdir = try std.Io.Dir.openDirAbsolute(io, drm.dir_name, .{ .iterate = true });
    defer sysdir.close(io);

    var it = sysdir.iterate();
    var i: usize = 0;
    while (try it.next(io)) |entry| if (entry.kind == .character_device) {
        const dev = processDevice(io, gpa, entry.name, subsystem_type, true, flags) catch continue;

        if (i >= drm.max_nodes) {
            log.err(
                "More than {d} drm nodes detected. This is a bug. Extra nodes will be skipped.",
                .{drm.max_nodes},
            );
            break;
        }

        local_devices[i] = dev;
        i += 1;
    };

    return for (local_devices[0..i]) |dev| {
        if (hasRdev(dev, devid)) break dev;
    } else error.NoDeviceFound;
}

pub fn openNode(self: *const Device, io: std.Io) std.Io.File.OpenError!Card {
    return Card.open(io, self.nodePath());
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
    var path_buf: [path_max]u8 = undefined;
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

    var path_buf: [path_max]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/subsystem", .{device_path}) catch unreachable;

    var link_buf: [path_max]u8 = undefined;
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
    pub const max = 3;
};

fn processDevice(
    io: std.Io,
    gpa: std.mem.Allocator,
    name: []const u8,
    required_subsystem_type: BusType,
    fetch_devinfo: bool,
    flags: Flags,
) !Device {
    const max_node_length = std.mem.alignForward(usize, drm.max_node_name, @sizeOf(usize));
    const node_type = try getNodeType(name);

    var path_buf: [path_max]u8 = undefined;
    const node = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ drm.dir_name, name }) catch unreachable;

    if (node.len + 1 > max_node_length)
        return error.NodePathTooLong;

    const stat = try statx(node);
    const major = stat.rdev_major;
    const minor = stat.rdev_minor;

    if (!drm.nodeIsDrm(io, stat.rdev_major, stat.rdev_minor) or !std.os.linux.S.ISCHR(stat.mode))
        return error.InvalidDevice;

    const subsystem_type = try parseSubsystemType(io, stat.rdev_major, stat.rdev_minor);
    if (subsystem_type != required_subsystem_type)
        return error.IncorrectSubsystemType;

    return switch (subsystem_type) {
        .pci, .virtio => try processPciDevice(io, gpa, node, node_type, major, minor, fetch_devinfo, flags),
        .usb => error.UsbInimplemented,
        .platform => error.PlatformUnimplemented,
        .host1x => error.Host1xUnimplemented,
        .faux => error.FauxUnimplemented,
    };
}

fn processPciDevice(
    io: std.Io,
    gpa: std.mem.Allocator,
    node_path: []const u8,
    node_type: NodeType,
    major: u32,
    minor: u32,
    fetch_devinfo: bool,
    flags: Flags,
) !Device {
    var device = Device{
        .node_type = node_type,
        .node_path_buf = @splat(0),
        .bus_info = .{ .pci = try parsePciBusInfo(io, gpa, major, minor) },
        .device_info = if (fetch_devinfo) .{ .pci = try parsePciDeviceInfo(io, major, minor, flags) } else null,
    };
    @memcpy(device.node_path_buf[0..node_path.len], node_path);
    return device;
}

fn parsePciBusInfo(io: std.Io, gpa: std.mem.Allocator, major: u32, minor: u32) !PciBusInfo {
    var pci_path_buf: [path_max]u8 = undefined;
    const pci_path = try getPciPath(io, &pci_path_buf, major, minor);

    const value = try sysfsUeventGet(io, gpa, pci_path, "PCI_SLOT_NAME", .{});
    defer gpa.free(value);

    const domain = try std.fmt.parseInt(u16, value[0..4], 16);
    const bus = try std.fmt.parseInt(u8, value[5..7], 16);
    const dev = try std.fmt.parseInt(u8, value[8..10], 16);
    const func = try std.fmt.parseInt(u8, value[11..12], 16);

    return PciBusInfo{
        .domain = domain,
        .bus = bus,
        .dev = dev,
        .func = func,
    };
}

fn parsePciDeviceInfo(io: std.Io, major: u32, minor: u32, flags: Flags) !PciDeviceInfo {
    return if (!flags.get_pci_revision)
        parseSeparateSysfsFiles(io, major, minor, true)
    else
        parseSeparateSysfsFiles(io, major, minor, false) catch
            parseConfigSysfsFile(io, major, minor);
}

fn getPciPath(io: std.Io, buf: []u8, major: u32, minor: u32) ![]const u8 {
    var path_buf: [path_max]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "/sys/dev/char/{}:{}/device", .{ major, minor });

    const len = try std.Io.Dir.realPathFileAbsolute(io, path, buf);
    const real_path = buf[0..len];

    if (std.mem.endsWith(u8, real_path, "/virtio")) return buf[0 .. len - 7];
    return real_path;
}

fn sysfsUeventGet(
    io: std.Io,
    gpa: std.mem.Allocator,
    path: []const u8,
    comptime format: []const u8,
    args: anytype,
) ![]const u8 {
    const key = try std.fmt.allocPrint(gpa, format, args);
    defer gpa.free(key);

    var filename_buf: [path_max]u8 = undefined;
    const filename = try std.fmt.bufPrint(&filename_buf, "{s}/uevent", .{path});

    const file = try std.Io.Dir.openFileAbsolute(io, filename, .{});
    defer file.close(io);

    var reader = file.reader(io, &.{});
    const content = try reader.interface.allocRemaining(gpa, .unlimited);
    defer gpa.free(content);

    var it = std.mem.tokenizeScalar(u8, content, '\n');
    while (it.next()) |line| {
        if (std.mem.eql(u8, line[0..key.len], key) and line[key.len] == '=') {
            return gpa.dupe(u8, line[key.len + 1 ..]);
        }
    }

    return error.KeyNotFound;
}

fn parseSeparateSysfsFiles(
    io: std.Io,
    major: u32,
    minor: u32,
    ignore_revision: bool,
) !PciDeviceInfo {
    const attrs = [_][]const u8{
        "revision",
        "vendor",
        "device",
        "subsystem_vendor",
        "subsystem_device",
    };

    var pci_path_buf: [path_max]u8 = undefined;
    const pci_path = try getPciPath(io, &pci_path_buf, major, minor);
    const start: usize = if (ignore_revision) 1 else 0;

    var data: [attrs.len]u16 = undefined;
    for (attrs[start..], data[start..]) |attr, *value| {
        var path_buf: [path_max]u8 = undefined;
        const path = try std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ pci_path, attr });

        const file = try std.Io.Dir.openFileAbsolute(io, path, .{});
        defer file.close(io);

        var value_buf: [16]u8 = undefined;
        const len = try file.readStreaming(io, &.{&value_buf}) - 1;

        value.* = try std.fmt.parseInt(u16, value_buf[0..len], 0);
    }

    return PciDeviceInfo{
        .revision_id = if (ignore_revision) 0xff else @intCast(data[0] & 0xff),
        .vendor_id = data[1] & 0xffff,
        .device_id = data[2] & 0xffff,
        .subvendor_id = data[3] & 0xffff,
        .subdevice_id = data[4] & 0xffff,
    };
}

fn parseConfigSysfsFile(io: std.Io, major: u32, minor: u32) !PciDeviceInfo {
    var pci_path_buf: [path_max]u8 = undefined;
    const pci_path = try getPciPath(io, &pci_path_buf, major, minor);

    var path_buf: [path_max]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "{s}/config", .{pci_path});

    const file = try std.Io.Dir.openFileAbsolute(io, path, .{});
    defer file.close(io);

    var config: [64]u8 = undefined;
    _ = try file.readStreaming(io, &.{&config});

    return PciDeviceInfo{
        .vendor_id = config[0] | @as(u16, config[1]) << 8,
        .device_id = config[2] | @as(u16, config[3]) << 8,
        .revision_id = config[8],
        .subvendor_id = config[44] | @as(u16, config[45]) << 8,
        .subdevice_id = config[46] | @as(u16, config[47]) << 8,
    };
}

fn hasRdev(dev: Device, rdev: std.posix.dev_t) bool {
    const stat = statx(dev.nodePath()) catch return false;
    return drm.makeDev(stat.rdev_major, stat.rdev_minor) == rdev;
}

fn getNodeType(name: []const u8) !NodeType {
    if (std.mem.eql(u8, name[0..drm.primary_minor_name.len], drm.primary_minor_name)) return .primary;
    if (std.mem.eql(u8, name[0..drm.control_minor_name.len], drm.control_minor_name)) return .control;
    if (std.mem.eql(u8, name[0..drm.render_minor_name.len], drm.render_minor_name)) return .render;

    return error.InvalidName;
}

fn statx(path: []const u8) !std.os.linux.Statx {
    const posix_path = try std.posix.toPosixPath(path);
    var stat_buf: std.os.linux.Statx = undefined;
    const rc = std.os.linux.statx(std.os.linux.AT.FDCWD, &posix_path, 0, .{}, &stat_buf);
    return switch (std.posix.errno(rc)) {
        .SUCCESS => stat_buf,
        else => |err| std.posix.unexpectedErrno(err),
    };
}

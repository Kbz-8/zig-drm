const std = @import("std");

const Device = @import("Device.zig");
const drm = @import("drm.zig");
const fmt = @import("format.zig");
const sys = @import("sys.zig");
const util = @import("util.zig");

const log = std.log.scoped(.drm);
const Card = @This();

handle: std.Io.File,

pub const OpenError = std.Io.File.OpenError || std.Io.Dir.OpenError;

pub fn open(io: std.Io, path: []const u8) OpenError!Card {
    if (std.fs.path.isAbsolute(path))
        return Card{ .handle = try std.Io.Dir.openFileAbsolute(io, path, .{ .mode = .read_write }) };

    const dir = try std.Io.Dir.openDirAbsolute(io, drm.dir_name, .{});
    defer dir.close(io);

    return Card{ .handle = try dir.openFile(io, path, .{ .mode = .read_write }) };
}

pub const OpenAutoError = OpenError || std.Io.Dir.Iterator.Error || error{NoDevicesFound};

pub fn openAuto(io: std.Io, target_type: ?drm.Device.NodeType) OpenAutoError!Card {
    const dir = try std.Io.Dir.openDirAbsolute(io, drm.dir_name, .{ .iterate = true });
    defer dir.close(io);

    var it = dir.iterateAssumeFirstIteration();
    while (try it.next(io)) |entry| if (entry.kind == .character_device) {
        if (target_type) |t| if (!std.mem.startsWith(u8, entry.name, t.name())) continue;
        return Card{ .handle = dir.openFile(io, entry.name, .{ .mode = .read_write }) catch continue };
    };

    return error.NoDevicesFound;
}

pub fn openForDev(io: std.Io, dev: std.posix.dev_t) OpenAutoError!Card {
    const dir = try std.Io.Dir.openDirAbsolute(io, drm.dir_name, .{ .iterate = true });
    defer dir.close(io);

    var it = dir.iterateAssumeFirstIteration();
    while (try it.next(io)) |entry| if (entry.kind == .character_device) {
        const posix_name = std.posix.toPosixPath(entry.name);
        const stat = util.stat(dir.handle, &posix_name, 0) catch continue;
        if (drm.makeDev(stat.rdev_major, stat.rdev_minor) == dev)
            return Card{ .handle = try dir.openFile(io, entry.name, .{ .mode = .read_write }) };
    };

    return error.NoDevicesFound;
}

pub fn close(self: Card, io: std.Io) void {
    self.handle.close(io);
}

pub fn getDevId(self: Card) !std.posix.dev_t {
    const stat = try util.statFile(self.handle.handle);
    return drm.makeDev(stat.rdev_major, stat.rdev_minor);
}

pub fn getDevice(self: Card, io: std.Io, gpa: std.mem.Allocator, flags: Device.Flags) !Device {
    return .getFromDevId(io, gpa, try self.getDevId(), flags);
}

pub fn handleEvents(
    self: Card,
    io: std.Io,
    callback: fn (Card, drm.Event, anytype) anyerror!void,
    args: anytype,
) anyerror!void {
    var buf: [4096]u8 = undefined;
    const read = try self.handle.readStreaming(io, &.{&buf});
    if (read == 0) return error.EndOfStream;

    var offset: usize = 0;
    while (offset < read) {
        if (read - offset < @sizeOf(sys.Event)) return error.IncompleteEvent;

        const ev: *align(1) const sys.Event = std.mem.bytesAsValue(
            sys.Event,
            buf[offset..][0..@sizeOf(sys.Event)],
        );

        offset += ev.length;

        const event = drm.Event.parse(ev);
        try callback(self, event, args);
    }
}

pub fn setClientCapability(self: Card, capability: sys.ClientCapability, value: u64) sys.IoctlError!void {
    var set_cap = sys.SetClientCap{
        .capability = capability,
        .value = value,
    };
    try sys.ioctl(self.handle.handle, .set_client_cap, &set_cap);
}

pub fn getCapability(self: Card, capability: sys.Capability) sys.IoctlError!u64 {
    var get_cap = sys.GetCap{
        .capability = capability,
        .value = 0,
    };
    try sys.ioctl(self.handle.handle, .get_cap, &get_cap);
    return get_cap.value;
}

pub fn createModesettingPropertyBlob(self: Card, data: []const u8) sys.IoctlError!u32 {
    var create = std.mem.zeroInit(sys.mode.CreateBlob, .{
        .length = @as(u32, @intCast(data.len)),
        .data = @intFromPtr(data.ptr),
    });
    try sys.ioctl(self.handle.handle, .mode_createpropblob, &create);
    return create.blob_id;
}

// BEGIN MODESETTING API

pub const GetResourcesError = sys.IoctlError || error{OutOfMemory};

pub fn getModesettingResources(
    self: Card,
    gpa: std.mem.Allocator,
) GetResourcesError!drm.ModesettingResources {
    while (true) {
        var res = std.mem.zeroes(sys.mode.CardRes);
        try sys.ioctl(self.handle.handle, .mode_getresources, &res);

        var ret = drm.ModesettingResources{
            .min_width = res.min_width,
            .max_width = res.max_width,
            .min_height = res.min_height,
            .max_height = res.max_height,
            .fbs = &.{},
            .crtcs = &.{},
            .connectors = &.{},
            .encoders = &.{},
        };

        ret.fbs = try gpa.alloc(u32, res.count_fbs);
        errdefer gpa.free(ret.fbs);
        res.fb_id_ptr = @intFromPtr(ret.fbs.ptr);

        ret.crtcs = try gpa.alloc(u32, res.count_crtcs);
        errdefer gpa.free(ret.crtcs);
        res.crtc_id_ptr = @intFromPtr(ret.crtcs.ptr);

        ret.connectors = try gpa.alloc(u32, res.count_connectors);
        errdefer gpa.free(ret.connectors);
        res.connector_id_ptr = @intFromPtr(ret.connectors.ptr);

        ret.encoders = try gpa.alloc(u32, res.count_encoders);
        errdefer gpa.free(ret.encoders);
        res.encoder_id_ptr = @intFromPtr(ret.encoders.ptr);

        const cached = res;
        try sys.ioctl(self.handle.handle, .mode_getresources, &res);

        if (cached.count_fbs < res.count_fbs or
            cached.count_crtcs < res.count_crtcs or
            cached.count_connectors < res.count_connectors or
            cached.count_encoders < res.count_encoders)
        {
            gpa.free(ret.encoders);
            gpa.free(ret.connectors);
            gpa.free(ret.crtcs);
            gpa.free(ret.fbs);
            continue;
        }

        return ret;
    }
}

pub const GetConnectorError = sys.IoctlError || error{OutOfMemory};

pub fn getConnector(self: Card, gpa: std.mem.Allocator, id: u32) GetConnectorError!drm.Connector {
    while (true) {
        var get_conn = std.mem.zeroInit(sys.mode.GetConnector, .{ .connector_id = id });
        try sys.ioctl(self.handle.handle, .mode_getconnector, &get_conn);
        const cached = get_conn;

        const encoders = try gpa.alloc(u32, get_conn.count_encoders);
        errdefer gpa.free(encoders);

        const modes = try gpa.alloc(sys.mode.ModeInfo, get_conn.count_modes);
        errdefer gpa.free(modes);

        const props = try gpa.alloc(u32, get_conn.count_props);
        errdefer gpa.free(props);
        const prop_values = try gpa.alloc(u64, get_conn.count_props);
        errdefer gpa.free(prop_values);

        get_conn.encoders_ptr = @intFromPtr(encoders.ptr);
        get_conn.modes_ptr = @intFromPtr(modes.ptr);
        get_conn.props_ptr = @intFromPtr(props.ptr);
        get_conn.prop_values_ptr = @intFromPtr(prop_values.ptr);

        try sys.ioctl(self.handle.handle, .mode_getconnector, &get_conn);

        if (cached.count_encoders < get_conn.count_encoders or
            cached.count_modes < get_conn.count_modes or
            cached.count_props < get_conn.count_props)
        {
            gpa.free(prop_values);
            gpa.free(props);
            gpa.free(modes);
            gpa.free(encoders);
            continue;
        }

        return drm.Connector{
            .id = id,
            .encoder_id = get_conn.encoder_id,
            .connection = @enumFromInt(get_conn.connection),
            // Unsure why libdrm does this conversion,
            // but we'll follow suite for compatability.
            .subpixel = @enumFromInt(get_conn.subpixel + 1),
            .encoders = encoders[0..get_conn.count_encoders],
            .modes = modes[0..get_conn.count_modes],
            .props = props[0..get_conn.count_props],
            .prop_values = prop_values[0..get_conn.count_props],
            .mm_width = get_conn.mm_width,
            .mm_height = get_conn.mm_height,
            .type = get_conn.connector_type,
            .type_id = get_conn.connector_type_id,
        };
    }
}

pub fn getEncoder(self: Card, id: u32) sys.IoctlError!drm.Encoder {
    var get_encoder = std.mem.zeroInit(sys.mode.GetEncoder, .{ .encoder_id = id });
    try sys.ioctl(self.handle.handle, .mode_getencoder, &get_encoder);

    return drm.Encoder{
        .id = id,
        .type = get_encoder.encoder_type,
        .crtc_id = get_encoder.crtc_id,
        .possible_crtcs = get_encoder.possible_crtcs,
        .possible_clones = get_encoder.possible_clones,
    };
}

pub fn getCrtc(self: Card, id: u32) sys.IoctlError!drm.Crtc {
    var crtc = std.mem.zeroInit(sys.mode.Crtc, .{ .crtc_id = id });
    try sys.ioctl(self.handle.handle, .mode_getcrtc, &crtc);

    return drm.Crtc{
        .id = id,
        .fb_id = crtc.fb_id,
        .x = crtc.x,
        .y = crtc.y,
        .gamma_size = crtc.gamma_size,
        .mode = if (crtc.mode_valid != 0) crtc.mode else null,
    };
}

pub fn setCrtc(
    self: Card,
    id: u32,
    fb_id: u32,
    x: u32,
    y: u32,
    connectors: []u32,
    mode: ?sys.mode.ModeInfo,
) sys.IoctlError!void {
    var crtc = std.mem.zeroInit(sys.mode.Crtc, .{
        .crtc_id = id,
        .fb_id = fb_id,
        .x = x,
        .y = y,
        .count_connectors = @as(u32, @intCast(connectors.len)),
        .set_connectors_ptr = @intFromPtr(connectors.ptr),
    });
    if (mode) |m| {
        crtc.mode_valid = 1;
        crtc.mode = m;
    }
    try sys.ioctl(self.handle.handle, .mode_setcrtc, &crtc);
}

pub fn createDumbBuffer(self: Card, width: u32, height: u32, bpp: u32) sys.IoctlError!drm.DumbBuffer {
    var create = std.mem.zeroInit(sys.mode.CreateDumb, .{
        .width = width,
        .height = height,
        .bpp = bpp,
    });
    try sys.ioctl(self.handle.handle, .mode_create_dumb, &create);

    return drm.DumbBuffer{
        .handle = create.handle,
        .width = create.width,
        .height = create.height,
        .stride = create.pitch,
        .size = @intCast(create.size),
    };
}

pub fn destroyDumbBuffer(self: Card, handle: u32) sys.IoctlError!void {
    var destroy = sys.mode.DestroyDumb{ .handle = handle };
    try sys.ioctl(self.handle.handle, .mode_destroy_dumb, &destroy);
}

pub fn mapDumbBuffer(self: Card, dumb: drm.DumbBuffer, offset: usize) sys.IoctlError!usize {
    var map = sys.mode.MapDumb{ .handle = dumb.handle, .pad = 0, .offset = offset };
    try sys.ioctl(self.handle.handle, .mode_map_dumb, &map);
    return @intCast(map.offset);
}

pub fn addFb2(
    self: Card,
    width: u32,
    height: u32,
    format: fmt.Format,
    handles: [4]u32,
    pitches: [4]u32,
    offsets: [4]u32,
    flags: u32, // FIXME: add flags type
) sys.IoctlError!u32 {
    var cmd = std.mem.zeroInit(sys.mode.FbCmd2, .{
        .width = width,
        .height = height,
        .pixel_format = @intFromEnum(format),
        .handles = handles,
        .pitches = pitches,
        .offsets = offsets,
        .flags = flags,
    });
    try sys.ioctl(self.handle.handle, .mode_addfb2, &cmd);
    return cmd.fb_id;
}

pub fn removeFb(self: Card, fb: u32) sys.IoctlError!void {
    try sys.ioctl(self.handle.handle, .mode_rmfb, &fb);
}

pub fn pageFlip(
    self: Card,
    crtc_id: u32,
    fb_id: u32,
    flags: sys.mode.PageFlipFlags,
    data: ?*anyopaque,
) sys.IoctlError!void {
    var flip = sys.mode.CrtcPageFlip{
        .crtc_id = crtc_id,
        .fb_id = fb_id,
        .flags = flags,
        .reserved = 0,
        .user_data = @intFromPtr(data),
    };
    try sys.ioctl(self.handle.handle, .mode_page_flip, &flip);
}

pub const GetPlaneResourcesError = sys.IoctlError || error{OutOfMemory};

pub fn getPlaneResources(self: Card, gpa: std.mem.Allocator) GetPlaneResourcesError!drm.PlaneResources {
    while (true) {
        var res = std.mem.zeroes(sys.mode.GetPlaneRes);
        try sys.ioctl(self.handle.handle, .mode_getplaneresources, &res);
        const cached = res;

        const planes = try gpa.alloc(u32, res.count_planes);
        errdefer gpa.free(planes);
        res.plane_id_ptr = @intFromPtr(planes.ptr);

        try sys.ioctl(self.handle.handle, .mode_getplaneresources, &res);
        if (res.count_planes > cached.count_planes) {
            gpa.free(planes);
            continue;
        }

        return drm.PlaneResources{ .planes = planes };
    }
}

pub const GetPlaneError = sys.IoctlError || error{OutOfMemory};

pub fn getPlane(self: Card, gpa: std.mem.Allocator, id: u32) GetPlaneError!drm.Plane {
    while (true) {
        var get = std.mem.zeroInit(sys.mode.GetPlane, .{ .plane_id = id });
        try sys.ioctl(self.handle.handle, .mode_getplane, &get);
        const cached = get;

        const formats = try gpa.alloc(u32, get.count_format_types);
        errdefer gpa.free(formats);
        get.format_type_ptr = @intFromPtr(formats.ptr);

        try sys.ioctl(self.handle.handle, .mode_getplane, &get);
        if (get.count_format_types > cached.count_format_types) {
            gpa.free(formats);
            continue;
        }

        return drm.Plane{
            .id = id,
            .formats = formats,
            .crtc_id = get.crtc_id,
            .fb_id = get.fb_id,
            .crtc_x = 0,
            .crtc_y = 0,
            .x = 0,
            .y = 0,
            .possible_crtcs = get.possible_crtcs,
            .gamma_size = get.gamma_size,
        };
    }
}

pub const GetObjectPropertiesError = sys.IoctlError || error{OutOfMemory};

pub fn getObjectProperties(
    self: Card,
    gpa: std.mem.Allocator,
    object_id: u32,
    object_type: sys.mode.ObjType,
) GetObjectPropertiesError!drm.ObjectProperties {
    while (true) {
        var get = std.mem.zeroInit(sys.mode.ObjGetProperties, .{
            .obj_id = object_id,
            .obj_type = object_type,
        });
        try sys.ioctl(self.handle.handle, .mode_obj_getproperties, &get);
        const cached = get;

        const keys = try gpa.alloc(u32, get.count_props);
        errdefer gpa.free(keys);
        get.props_ptr = keys.ptr;

        const values = try gpa.alloc(u64, get.count_props);
        errdefer gpa.free(values);
        get.prop_values_ptr = values.ptr;

        try sys.ioctl(self.handle.handle, .mode_obj_getproperties, &get);
        if (get.count_props > cached.count_props) {
            gpa.free(keys);
            gpa.free(values);
            continue;
        }

        return drm.ObjectProperties{
            .keys = keys,
            .values = values,
        };
    }
}

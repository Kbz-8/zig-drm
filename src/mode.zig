const std = @import("std");
const sys = @import("sys.zig");
const base = @import("drm.zig");
const Allocator = std.mem.Allocator;

pub const Card = struct {
    handle: std.Io.File,

    pub const OpenError = std.Io.File.OpenError || std.Io.Dir.OpenError;

    pub fn open(io: std.Io, path: []const u8) OpenError!Card {
        if (std.fs.path.isAbsolute(path))
            return std.Io.Dir.openFileAbsolute(io, path, .{ .mode = .read_write });

        const dir = try std.Io.Dir.openDirAbsolute(io, "/dev/dri", .{});
        defer dir.close(io);

        return Card{ .handle = try dir.openFile(io, path, .{ .mode = .read_write }) };
    }

    pub const OpenAutoError = OpenError || std.Io.Dir.Iterator.Error || error{NoDevicesFound};

    pub fn openAuto(io: std.Io) OpenAutoError!Card {
        const dir = try std.Io.Dir.openDirAbsolute(io, "/dev/dri", .{ .iterate = true });
        defer dir.close(io);

        var it = dir.iterateAssumeFirstIteration();
        while (try it.next(io)) |entry| if (entry.kind == .character_device)
            return Card{ .handle = try dir.openFile(io, entry.name, .{ .mode = .read_write }) };

        return error.NoDevicesFound;
    }

    pub fn close(self: Card, io: std.Io) void {
        self.handle.close(io);
    }

    pub inline fn baseHandle(self: Card) base.Card {
        return .{ .handle = self.handle };
    }

    pub const GetResourcesError = sys.IoctlError || error{OutOfMemory};

    pub fn getResourcesAlloc(self: Card, gpa: Allocator) GetResourcesError!Resources {
        while (true) {
            var res = std.mem.zeroes(sys.mode.CardRes);
            try sys.ioctl(self.handle.handle, .mode_getresources, &res);

            var ret = Resources{
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

    pub fn getResourcesBuffered(
        self: Card,
        fbs: []u32,
        crtcs: []u32,
        connectors: []u32,
        encoders: []u32,
    ) GetResourcesError!Resources {
        var res = sys.mode.CardRes{
            .min_width = 0,
            .max_width = 0,
            .min_height = 0,
            .max_height = 0,
            .count_fbs = @intCast(fbs.len),
            .fb_id_ptr = @intFromPtr(fbs.ptr),
            .count_crtcs = @intCast(crtcs.len),
            .crtc_id_ptr = @intFromPtr(crtcs.ptr),
            .count_connectors = @intCast(connectors.len),
            .connector_id_ptr = @intFromPtr(connectors.ptr),
            .count_encoders = @intCast(encoders.len),
            .encoder_id_ptr = @intFromPtr(encoders.ptr),
        };
        try sys.ioctl(self.handle.handle, .mode_getresources, &res);

        if (res.count_fbs > fbs.len or
            res.count_crtcs > crtcs.len or
            res.count_connectors > connectors.len or
            res.count_encoders > encoders.len)
            return error.OutOfMemory;

        return Resources{
            .min_width = res.min_width,
            .max_width = res.max_width,
            .min_height = res.min_height,
            .max_height = res.max_height,
            .fbs = fbs[0..res.count_fbs],
            .crtcs = crtcs[0..res.count_crtcs],
            .connectors = connectors[0..res.count_connectors],
            .encoders = encoders[0..res.count_encoders],
        };
    }

    pub const GetConnectorError = sys.IoctlError || error{OutOfMemory};

    pub fn getConnectorAlloc(self: Card, gpa: Allocator, id: u32) GetConnectorError!Connector {
        while (true) {
            var get_conn = std.mem.zeroInit(sys.mode.GetConnector, .{ .connector_id = id });
            try sys.ioctl(self.handle.handle, .mode_getconnector, &get_conn);
            const cached = get_conn;

            const encoders = try gpa.alloc(u32, get_conn.count_encoders);
            errdefer gpa.free(encoders);

            const modes = try gpa.alloc(sys.mode.Modeinfo, get_conn.count_modes);
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

            return Connector{
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
            };
        }
    }

    pub inline fn getConnectorBuffered(
        self: Card,
        encoders: []u32,
        modes: []sys.mode.Modeinfo,
        props: []u32,
        prop_values: []u64,
        id: u32,
    ) GetConnectorError!Connector {
        std.debug.assert(props.len == prop_values.len);
        var get_conn = std.mem.zeroInit(sys.mode.GetConnector, .{
            .connector_id = id,
            .count_encoders = @as(u32, @intCast(encoders.len)),
            .encoders_ptr = @intFromPtr(encoders.ptr),
            .count_modes = @as(u32, @intCast(modes.len)),
            .modes_ptr = @intFromPtr(modes.ptr),
            .count_props = @as(u32, @intCast(props.len)),
            .props_ptr = @intFromPtr(props.ptr),
            .prop_values_ptr = @intFromPtr(prop_values.ptr),
        });
        try sys.ioctl(self.handle.handle, .mode_getconnector, &get_conn);

        if (get_conn.count_encoders > encoders.len or
            get_conn.count_modes > modes.len or
            get_conn.count_props > props.len)
            return error.OutOfMemory;

        return Connector{
            .id = id,
            .encoder_id = get_conn.encoder_id,
            .connection = @enumFromInt(get_conn.connection),
            .subpixel = @enumFromInt(get_conn.subpixel + 1),
            .encoders = encoders[0..get_conn.count_encoders],
            .modes = modes[0..get_conn.count_modes],
            .props = props[0..get_conn.count_props],
            .prop_values = prop_values[0..get_conn.count_props],
            .mm_width = get_conn.mm_width,
            .mm_height = get_conn.mm_height,
        };
    }

    pub const GetEncoderError = sys.IoctlError;

    pub fn getEncoder(self: Card, id: u32) GetEncoderError!Encoder {
        var get_encoder = std.mem.zeroInit(sys.mode.GetEncoder, .{ .encoder_id = id });
        try sys.ioctl(self.handle.handle, .mode_getencoder, &get_encoder);

        return Encoder{
            .id = id,
            .type = get_encoder.encoder_type,
            .crtc_id = get_encoder.crtc_id,
            .possible_crtcs = get_encoder.possible_crtcs,
            .possible_clones = get_encoder.possible_clones,
        };
    }

    pub const GetCrtcError = sys.IoctlError;

    pub fn getCrtc(self: Card, id: u32) GetCrtcError!Crtc {
        var crtc = std.mem.zeroInit(sys.mode.Crtc, .{ .crtc_id = id });
        try sys.ioctl(self.handle.handle, .mode_getcrtc, &crtc);

        return Crtc{
            .id = id,
            .fb_id = crtc.fb_id,
            .x = crtc.x,
            .y = crtc.y,
            .gamma_size = crtc.gamma_size,
            .mode = if (crtc.mode_valid != 0) crtc.mode else null,
        };
    }
};

pub const Connection = enum(u32) {
    connected = 1,
    disconnected = 2,
    unknown = 3,
};

pub const Subpixel = enum(u32) {
    unknown = 1,
    horizontal_rgb = 2,
    horizontal_bgr = 3,
    vertical_rgb = 4,
    vertical_bgr = 5,
    none = 6,
};

pub const Resources = struct {
    min_width: u32,
    max_width: u32,
    min_height: u32,
    max_height: u32,
    fbs: []const u32,
    crtcs: []const u32,
    connectors: []const u32,
    encoders: []const u32,

    pub fn deinit(self: Resources, gpa: Allocator) void {
        gpa.free(self.encoders);
        gpa.free(self.connectors);
        gpa.free(self.crtcs);
        gpa.free(self.fbs);
    }
};

pub const Connector = struct {
    id: u32,
    encoder_id: u32,
    connection: Connection,
    mm_width: u32,
    mm_height: u32,
    subpixel: Subpixel,
    encoders: []const u32,
    modes: []const sys.mode.Modeinfo,
    props: []const u32,
    prop_values: []const u64,

    pub fn deinit(self: Connector, gpa: Allocator) void {
        gpa.free(self.prop_values);
        gpa.free(self.props);
        gpa.free(self.modes);
        gpa.free(self.encoders);
    }
};

pub const Encoder = struct {
    id: u32,
    type: sys.mode.GetEncoder.Type,
    crtc_id: u32,
    possible_crtcs: u32,
    possible_clones: u32,
};

pub const Crtc = struct {
    id: u32,
    fb_id: u32,
    x: u32,
    y: u32,
    gamma_size: u32,
    mode: ?sys.mode.Modeinfo,
};

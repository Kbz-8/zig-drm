const std = @import("std");
const dev_t = std.posix.dev_t;

pub const Card = @import("Card.zig");
pub const Device = @import("Device.zig");
const fmt = @import("format.zig");
pub const Format = fmt.Format;
pub const FormatModifiers = fmt.FormatModifiers;
pub const sys = @import("sys.zig");
pub const ModeInfo = sys.mode.ModeInfo;

const log = std.log.scoped(.drm);

pub const dir_name = "/dev/dri";
pub const primary_minor_name = "card";
pub const control_minor_name = "controlD";
pub const render_minor_name = "renderD";
pub const max_nodes = 256;
pub const max_node_name = dir_name.len + @max(
    primary_minor_name.len,
    control_minor_name.len,
    render_minor_name.len,
) + 3;

pub inline fn devMajor(dev: dev_t) u32 {
    return @intCast(((dev & @as(dev_t, 0x00000000000fff00)) >> 8) |
        ((dev & @as(dev_t, 0xfffff00000000000)) >> 32));
}

pub inline fn devMinor(dev: dev_t) u32 {
    return @intCast(((dev & @as(dev_t, 0x00000000000000ff)) >> 0) |
        ((dev & @as(dev_t, 0x00000ffffff00000)) >> 12));
}

pub inline fn makeDev(major: u32, minor: u32) dev_t {
    return (@as(dev_t, major & 0x00000fff) << 8) |
        (@as(dev_t, major & 0xfffff000) << 32) |
        (@as(dev_t, minor & 0x000000ff) << 0) |
        (@as(dev_t, minor & 0xffffff00) << 12);
}

pub fn nodeIsDrm(io: std.Io, major: u32, minor: u32) bool {
    const drm_node_path_format = "/sys/dev/char/{d}:{d}/device/drm";

    var path_buf: [64]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, drm_node_path_format, .{ major, minor }) catch unreachable;

    return if (std.Io.Dir.cwd().statFile(io, path, .{})) |_| true else |_| false;
}

pub const Event = union(enum) {
    vblank: Vblank,
    flip_complete: Vblank,
    crtc_sequence: CrtcSequence,

    pub fn parse(event: *align(1) const sys.Event) Event {
        return switch (event.type) {
            inline .vblank, .flip_complete => |tag| @unionInit(Event, @tagName(tag), ev: {
                const vblank: *align(1) const sys.EventVblank = @ptrCast(@alignCast(event));
                break :ev .{
                    .user_data = @ptrFromInt(vblank.user_data),
                    .sec = vblank.tv_sec,
                    .usec = vblank.tv_usec,
                    .sequence = vblank.sequence,
                    .crtc_id = vblank.crtc_id,
                };
            }),
            .crtc_sequence => Event{ .crtc_sequence = ev: {
                const crtc_sequence: *align(1) const sys.EventCrtcSequence = @ptrCast(@alignCast(event));
                break :ev .{
                    .user_data = @ptrFromInt(crtc_sequence.user_data),
                    .ns = crtc_sequence.time_ns,
                    .sequence = crtc_sequence.sequence,
                };
            } },
        };
    }

    pub const Vblank = struct {
        user_data: *anyopaque,
        sec: u32,
        usec: u32,
        sequence: u32,
        crtc_id: u32,
    };

    pub const CrtcSequence = struct {
        user_data: *anyopaque,
        ns: i64,
        sequence: u64,
    };
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

pub const ModesettingResources = struct {
    min_width: u32,
    max_width: u32,
    min_height: u32,
    max_height: u32,
    fbs: []const u32,
    crtcs: []const u32,
    connectors: []const u32,
    encoders: []const u32,

    pub fn deinit(self: ModesettingResources, gpa: std.mem.Allocator) void {
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
    modes: []const sys.mode.ModeInfo,
    props: []const u32,
    prop_values: []const u64,
    type: sys.mode.ConnectorType,
    type_id: u32,

    pub fn deinit(self: Connector, gpa: std.mem.Allocator) void {
        gpa.free(self.prop_values);
        gpa.free(self.props);
        gpa.free(self.modes);
        gpa.free(self.encoders);
    }
};

pub const Encoder = struct {
    id: u32,
    type: sys.mode.EncoderType,
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
    mode: ?sys.mode.ModeInfo,
};

pub const DumbBuffer = struct {
    handle: u32,
    width: u32,
    height: u32,
    stride: u32,
    size: usize,
};

pub const PlaneResources = struct {
    planes: []const u32,

    pub fn deinit(self: PlaneResources, gpa: std.mem.Allocator) void {
        gpa.free(self.planes);
    }
};

pub const Plane = struct {
    id: u32,
    formats: []const u32,
    crtc_id: u32,
    fb_id: u32,
    crtc_x: u32,
    crtc_y: u32,
    x: u32,
    y: u32,
    possible_crtcs: u32,
    gamma_size: u32,

    pub fn deinit(self: Plane, gpa: std.mem.Allocator) void {
        gpa.free(self.formats);
    }
};

pub const ObjectProperties = struct {
    keys: []const u32,
    values: []const u64,

    pub fn deinit(self: ObjectProperties, gpa: std.mem.Allocator) void {
        gpa.free(self.keys);
        gpa.free(self.values);
    }
};

test {
    std.testing.refAllDecls(@This());
}

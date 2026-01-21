const std = @import("std");
const format = @import("format.zig");
const log = std.log.scoped(.drm);

pub const sys = @import("sys.zig");
pub const Format = format.Format;
pub const FormatModifiers = format.FormatModifiers;

pub const Card = struct {
    handle: std.Io.File,

    pub fn openAuto(io: std.Io) !Card {
        const dir = try std.Io.Dir.openDirAbsolute(io, "/dev/dri", .{ .iterate = true });
        defer dir.close(io);

        var it = dir.iterate();
        const handle = try while (try it.next(io)) |entry| {
            if (entry.kind == .character_device) {
                log.debug("Found device /dev/dri/{s}.", .{entry.name});
                break dir.openFile(io, entry.name, .{});
            }
        } else error.NoDevicesFound;

        return Card{ .handle = handle };
    }

    pub fn open(io: std.Io, path: []const u8) !Card {
        const handle = try if (std.Io.Dir.path.isAbsolute(path)) handle: {
            log.debug("Using device path {s}.", .{path});
            break :handle std.Io.Dir.openFileAbsolute(io, path, .{});
        } else handle: {
            const dir = try std.Io.Dir.openDirAbsolute(io, "/dev/dri", .{});
            defer dir.close(io);

            log.debug("Using device path /dev/dri/{s}.", .{path});
            break :handle dir.openDir(io, path, .{});
        };

        return Card{ .handle = handle };
    }

    pub fn close(self: Card, io: std.Io) void {
        self.handle.close(io);
    }

    pub const GetModeError = sys.IoctlError;

    pub fn getModeAlloc(
        self: Card,
        gpa: std.mem.Allocator,
    ) (GetModeError || std.mem.Allocator.Error)!ModeCard {
        return while (true) {
            var res = std.mem.zeroes(sys.mode.CardRes);
            try sys.ioctl(self.handle.handle, .mode_getresources, &res);

            var ret = ModeCard{
                .handle = self.handle,
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

            break ret;
        };
    }

    pub fn getModeBuffered(
        self: Card,
        fbs: []u32,
        crtcs: []u32,
        connectors: []u32,
        encoders: []u32,
    ) (GetModeError || error{
        TooManyFbs,
        TooManyCrtcs,
        TooManyConnectors,
        TooManyEncoders,
    })!ModeCard {
        return while (true) {
            var res = std.mem.zeroes(sys.mode.CardRes);
            try sys.ioctl(self.handle.handle, .mode_getresources, &res);

            var ret = ModeCard{
                .handle = self.handle,
                .min_width = res.min_width,
                .max_width = res.max_width,
                .min_height = res.min_height,
                .max_height = res.max_height,
                .fbs = &.{},
                .crtcs = &.{},
                .connectors = &.{},
                .encoders = &.{},
            };

            if (res.count_fbs > fbs.len) return error.TooManyFbs;
            ret.fbs = fbs[0..res.count_fbs];
            res.fb_id_ptr = @intFromPtr(ret.fbs.ptr);

            if (res.count_crtcs > crtcs.len) return error.TooManyCrtcs;
            ret.crtcs = crtcs[0..res.count_crtcs];
            res.crtc_id_ptr = @intFromPtr(ret.crtcs.ptr);

            if (res.count_connectors > connectors.len) return error.TooManyConnectors;
            ret.connectors = connectors[0..res.count_connectors];
            res.connector_id_ptr = @intFromPtr(ret.connectors.ptr);

            if (res.count_encoders > encoders.len) return error.TooManyEncoders;
            ret.encoders = encoders[0..res.count_encoders];
            res.encoder_id_ptr = @intFromPtr(ret.encoders.ptr);

            const cached = res;
            try sys.ioctl(self.handle.handle, .mode_getresources, &res);

            if (cached.count_fbs < res.count_fbs or
                cached.count_crtcs < res.count_crtcs or
                cached.count_connectors < res.count_connectors or
                cached.count_encoders < res.count_encoders)
                continue;

            break ret;
        };
    }
};

pub const ModeCard = struct {
    handle: std.Io.File,
    min_width: u32,
    max_width: u32,
    min_height: u32,
    max_height: u32,
    fbs: []const u32,
    crtcs: []const u32,
    connectors: []const u32,
    encoders: []const u32,

    pub fn deinit(self: ModeCard, gpa: std.mem.Allocator) void {
        gpa.free(self.encoders);
        gpa.free(self.connectors);
        gpa.free(self.crtcs);
        gpa.free(self.fbs);
    }
};

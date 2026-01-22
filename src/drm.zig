const std = @import("std");
const format = @import("format.zig");
const log = std.log.scoped(.drm);

pub const sys = @import("sys.zig");
pub const mode = @import("mode.zig");
pub const Format = format.Format;
pub const FormatModifiers = format.FormatModifiers;

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

    pub inline fn modeHandle(self: Card) mode.Card {
        return .{ .handle = self.handle };
    }
};

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
            return Card{ .handle = try std.Io.Dir.openFileAbsolute(io, path, .{ .mode = .read_write }) };

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

    pub fn handleEvents(
        self: Card,
        io: std.Io,
        callback: fn (Card, Event, anytype) anyerror!void,
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

            const event = Event.parse(ev);
            try callback(self, event, args);
        }
    }
};

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

test {
    std.testing.refAllDeclsRecursive(@This());
}

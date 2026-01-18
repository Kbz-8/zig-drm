const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("drm_fourcc", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("drm_fourcc.zig"),
    });
}

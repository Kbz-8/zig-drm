const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const drm = b.addModule("drm", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/drm.zig"),
    });

    const example = b.addExecutable(.{
        .name = "example",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("example.zig"),
        }),
    });
    example.root_module.addImport("drm", drm);
    b.installArtifact(example);
}

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

    const test_exe = b.addTest(.{ .root_module = drm });
    const run_tests = b.addRunArtifact(test_exe);
    const test_step = b.step("test", "Run tests.");
    test_step.dependOn(&run_tests.step);
}

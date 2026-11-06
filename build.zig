const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    //packages
    const clap = b.dependency("clap", .{});

    //compiler executable
    const root_module = b.addModule("Claw", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    root_module.addImport("clap", clap.module("clap"));

    const claw_artifact = b.addExecutable(.{
        .name = "claw",
        .root_module = root_module,
    });

    const exe = b.addInstallArtifact(claw_artifact, .{});
    b.default_step.dependOn(&exe.step);
}

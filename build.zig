const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const os = switch (target.result.os.tag) {
        .linux => "x11",
        .windows => "windows",
        .macos => "darwin",
        else => @panic("unsupported target"),
    };

    const libuiohook = b.dependency("libuiohook", .{});
    const files: []const []const u8 = &.{
        "logger.c",
        try std.mem.concat(b.allocator, u8, &.{ os, "/input_helper.c" }),
        try std.mem.concat(b.allocator, u8, &.{ os, "/input_hook.c" }),
        try std.mem.concat(b.allocator, u8, &.{ os, "/post_event.c" }),
        try std.mem.concat(b.allocator, u8, &.{ os, "/system_properties.c" }),
    };

    const flags: []const []const u8 = &.{"--std=c99"};

    const lib = b.addStaticLibrary(.{
        .name = "libuiohook",
        .target = target,
        .optimize = optimize,
    });

    lib.addCSourceFiles(.{
        .root = libuiohook.path("src"),
        .files = files,
        .flags = flags,
    });
    lib.addIncludePath(libuiohook.path("include"));
    lib.addIncludePath(libuiohook.path("src"));

    switch (target.result.os.tag) {
        .macos => {
            lib.linkSystemLibrary("pthread");
            lib.linkSystemLibrary("IOKit");
            lib.linkSystemLibrary("objc");
        },
        else => {
            @panic("platform not supported yet");
        },
    }

    //=====EXAMPLE=====
    const example = b.addExecutable(.{
        .target = target,
        .name = "example",
        .optimize = optimize,
        .root_source_file = b.path("src/example.zig"),
    });
    b.getInstallStep().dependOn(&b.addInstallArtifact(example, .{}).step);
    example.linkLibrary(lib);
    const import = b.addTranslateC(.{
        .root_source_file = libuiohook.path("include/uiohook.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    example.root_module.addImport("libuiohook", import.createModule());
    //example.addIncludePath(libuiohook.path("include"));
}

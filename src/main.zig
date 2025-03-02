const std = @import("std");
const win = @import("win32.zig");
const w32 = win.windows;

fn printUsage() void {
    std.debug.print(
        \\QRes-Zig - Screen Resolution Utility
        \\
        \\Usage:
        \\  qres-zig [options]
        \\
        \\Options:
        \\  --list                       List available screen resolutions
        \\  --set WIDTHxHEIGHT[@RATE]    Set screen resolution and optional refresh rate 
        \\                               (e.g., 1920x1080 or 1920x1080@60)
        \\  --current                    Show current screen resolution
        \\  --help                       Display this help message
        \\
    , .{});
}

fn parseResolution(arg: []const u8) !struct { width: u32, height: u32, refresh_rate: ?u32 } {
    // Format: WIDTHxHEIGHT[@RATE] (e.g., 1920x1080 or 1920x1080@60)

    // First check if we have a refresh rate specified
    var refresh_rate: ?u32 = null;
    var resolution_str = arg;

    if (std.mem.indexOf(u8, arg, "@")) |at_pos| {
        const rate_str = arg[at_pos + 1 ..];
        refresh_rate = try std.fmt.parseInt(u32, rate_str, 10);
        resolution_str = arg[0..at_pos];
    }

    // Now parse the resolution
    var parts = std.mem.split(u8, resolution_str, "x");
    const width_str = parts.next() orelse return error.InvalidResolution;
    const height_str = parts.next() orelse return error.InvalidResolution;

    const width = try std.fmt.parseInt(u32, width_str, 10);
    const height = try std.fmt.parseInt(u32, height_str, 10);

    return .{
        .width = width,
        .height = height,
        .refresh_rate = refresh_rate,
    };
}

fn listResolutions(allocator: std.mem.Allocator) !void {
    const resolutions = try win.getAvailableResolutions(allocator);
    defer allocator.free(resolutions);

    std.debug.print("Available resolutions:\n", .{});
    for (resolutions) |resolution| {
        std.debug.print("  {d}x{d} @ {d}Hz\n", .{ resolution.width, resolution.height, resolution.refresh_rate });
    }
}

fn printCurrentResolution() !void {
    const resolution = try win.getCurrentResolution();
    std.debug.print("Current resolution: {d}x{d} @ {d}Hz\n", .{
        resolution.width,
        resolution.height,
        resolution.refresh_rate,
    });
}

fn setResolution(width: u32, height: u32, refresh_rate: ?u32) !void {
    try win.setResolution(width, height, refresh_rate);

    if (refresh_rate) |rate| {
        std.debug.print("Resolution set to {d}x{d} @ {d}Hz\n", .{ width, height, rate });
    } else {
        std.debug.print("Resolution set to {d}x{d}\n", .{ width, height });
    }
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    defer _ = general_purpose_allocator.deinit();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len < 2) {
        printUsage();
        return;
    }

    const cmd = args[1];
    if (std.mem.eql(u8, cmd, "--help")) {
        printUsage();
    } else if (std.mem.eql(u8, cmd, "--list")) {
        try listResolutions(gpa);
    } else if (std.mem.eql(u8, cmd, "--current")) {
        try printCurrentResolution();
    } else if (std.mem.eql(u8, cmd, "--set") and args.len > 2) {
        const resolution_params = try parseResolution(args[2]);
        try setResolution(resolution_params.width, resolution_params.height, resolution_params.refresh_rate);
    } else {
        std.debug.print("Invalid command. Use --help for usage information.\n", .{});
        return error.InvalidCommand;
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

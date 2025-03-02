const std = @import("std");

// Export the Windows API bindings and our resolution functions
pub const win32 = @import("win32.zig");
pub const Resolution = win32.Resolution;
pub const getCurrentResolution = win32.getCurrentResolution;
pub const getAvailableResolutions = win32.getAvailableResolutions;
pub const setResolution = win32.setResolution;

// Simple dummy function to satisfy the lib build
pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}

test {
    // Test the exports
    _ = win32;
    _ = Resolution;
    _ = getCurrentResolution;
    _ = getAvailableResolutions;
    _ = setResolution;
}

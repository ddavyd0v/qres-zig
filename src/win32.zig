const std = @import("std");

pub const windows = struct {
    pub const RECT = extern struct {
        left: i32,
        top: i32,
        right: i32,
        bottom: i32,
    };

    pub const DEVMODEW = extern struct {
        dmDeviceName: [32]u16,
        dmSpecVersion: u16,
        dmDriverVersion: u16,
        dmSize: u16,
        dmDriverExtra: u16,
        dmFields: u32,
        union1: extern union {
            struct1: extern struct {
                dmOrientation: i16,
                dmPaperSize: i16,
                dmPaperLength: i16,
                dmPaperWidth: i16,
                dmScale: i16,
                dmCopies: i16,
                dmDefaultSource: i16,
                dmPrintQuality: i16,
            },
            struct2: extern struct {
                dmPosition: POINTL,
                dmDisplayOrientation: u32,
                dmDisplayFixedOutput: u32,
            },
        },
        dmColor: i16,
        dmDuplex: i16,
        dmYResolution: i16,
        dmTTOption: i16,
        dmCollate: i16,
        dmFormName: [32]u16,
        dmLogPixels: u16,
        dmBitsPerPel: u32,
        dmPelsWidth: u32,
        dmPelsHeight: u32,
        union2: extern union {
            dmDisplayFlags: u32,
            dmNup: u32,
        },
        dmDisplayFrequency: u32,
        dmICMMethod: u32,
        dmICMIntent: u32,
        dmMediaType: u32,
        dmDitherType: u32,
        dmReserved1: u32,
        dmReserved2: u32,
        dmPanningWidth: u32,
        dmPanningHeight: u32,
    };

    pub const POINTL = extern struct {
        x: i32,
        y: i32,
    };

    pub const ENUM_CURRENT_SETTINGS: u32 = 0xFFFFFFFF;
    pub const ENUM_REGISTRY_SETTINGS: u32 = 0xFFFFFFFE;
    pub const CDS_UPDATEREGISTRY: u32 = 0x00000001;
    pub const CDS_TEST: u32 = 0x00000002;
    pub const CDS_FULLSCREEN: u32 = 0x00000004;
    pub const CDS_GLOBAL: u32 = 0x00000008;
    pub const CDS_SET_PRIMARY: u32 = 0x00000010;
    pub const CDS_RESET: u32 = 0x40000000;
    pub const CDS_NORESET: u32 = 0x10000000;
    pub const DISP_CHANGE_SUCCESSFUL: i32 = 0;
    pub const DISP_CHANGE_RESTART: i32 = 1;
    pub const DISP_CHANGE_FAILED: i32 = -1;
    pub const DISP_CHANGE_BADMODE: i32 = -2;
    pub const DISP_CHANGE_NOTUPDATED: i32 = -3;
    pub const DISP_CHANGE_BADFLAGS: i32 = -4;
    pub const DISP_CHANGE_BADPARAM: i32 = -5;
    pub const DISP_CHANGE_BADDUALVIEW: i32 = -6;
    pub const DM_BITSPERPEL: u32 = 0x00040000;
    pub const DM_PELSWIDTH: u32 = 0x00080000;
    pub const DM_PELSHEIGHT: u32 = 0x00100000;
    pub const DM_DISPLAYFREQUENCY: u32 = 0x00400000;

    pub extern "user32" fn EnumDisplaySettingsW(
        lpszDeviceName: ?[*:0]const u16,
        iModeNum: u32,
        lpDevMode: *DEVMODEW,
    ) callconv(std.os.windows.WINAPI) i32;

    pub extern "user32" fn ChangeDisplaySettingsW(
        lpDevMode: ?*DEVMODEW,
        dwFlags: u32,
    ) callconv(std.os.windows.WINAPI) i32;
};

pub const Resolution = struct {
    width: u32,
    height: u32,
    refresh_rate: u32,
    bits_per_pixel: u32,
};

pub fn getCurrentResolution() !Resolution {
    var dev_mode: windows.DEVMODEW = undefined;
    dev_mode = std.mem.zeroes(windows.DEVMODEW);
    dev_mode.dmSize = @sizeOf(windows.DEVMODEW);

    if (windows.EnumDisplaySettingsW(null, windows.ENUM_CURRENT_SETTINGS, &dev_mode) == 0) {
        return error.FailedToGetCurrentSettings;
    }

    return Resolution{
        .width = dev_mode.dmPelsWidth,
        .height = dev_mode.dmPelsHeight,
        .refresh_rate = dev_mode.dmDisplayFrequency,
        .bits_per_pixel = dev_mode.dmBitsPerPel,
    };
}

pub fn getAvailableResolutions(allocator: std.mem.Allocator) ![]Resolution {
    var resolutions = std.ArrayList(Resolution).init(allocator);
    defer resolutions.deinit();

    var mode_index: u32 = 0;
    var dev_mode: windows.DEVMODEW = undefined;
    dev_mode = std.mem.zeroes(windows.DEVMODEW);
    dev_mode.dmSize = @sizeOf(windows.DEVMODEW);

    // Get all available display modes
    while (windows.EnumDisplaySettingsW(null, mode_index, &dev_mode) != 0) : (mode_index += 1) {
        const resolution = Resolution{
            .width = dev_mode.dmPelsWidth,
            .height = dev_mode.dmPelsHeight,
            .refresh_rate = dev_mode.dmDisplayFrequency,
            .bits_per_pixel = dev_mode.dmBitsPerPel,
        };

        // Only add unique resolutions to our list and ensure they're valid
        if (resolution.width > 0 and resolution.height > 0) {
            var is_duplicate = false;
            for (resolutions.items) |existing| {
                if (existing.width == resolution.width and
                    existing.height == resolution.height and
                    existing.refresh_rate == resolution.refresh_rate)
                {
                    is_duplicate = true;
                    break;
                }
            }

            if (!is_duplicate) {
                try resolutions.append(resolution);
            }
        }
    }

    // Return a slice owned by the caller
    return resolutions.toOwnedSlice();
}

pub fn setResolution(width: u32, height: u32, refresh_rate: ?u32) !void {
    var dev_mode: windows.DEVMODEW = undefined;
    dev_mode = std.mem.zeroes(windows.DEVMODEW);
    dev_mode.dmSize = @sizeOf(windows.DEVMODEW);

    // Set the fields we want to change
    dev_mode.dmPelsWidth = width;
    dev_mode.dmPelsHeight = height;
    dev_mode.dmFields = windows.DM_PELSWIDTH | windows.DM_PELSHEIGHT;

    // If refresh rate is provided, set it as well
    if (refresh_rate) |rate| {
        dev_mode.dmDisplayFrequency = rate;
        dev_mode.dmFields |= windows.DM_DISPLAYFREQUENCY;
    }

    const result = windows.ChangeDisplaySettingsW(&dev_mode, windows.CDS_UPDATEREGISTRY);
    switch (result) {
        windows.DISP_CHANGE_SUCCESSFUL => return,
        windows.DISP_CHANGE_RESTART => return error.SystemRestartRequired,
        windows.DISP_CHANGE_BADMODE => return error.InvalidResolution,
        windows.DISP_CHANGE_BADFLAGS => return error.InvalidFlags,
        windows.DISP_CHANGE_FAILED => return error.ChangeDisplaySettingsFailed,
        windows.DISP_CHANGE_NOTUPDATED => return error.RegistryNotUpdated,
        windows.DISP_CHANGE_BADPARAM => return error.InvalidParameter,
        else => return error.UnknownError,
    }
}

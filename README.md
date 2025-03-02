# QRes-Zig

A screen resolution utility written in Zig. This is a command-line tool similar to QRes that allows viewing and changing the screen resolution on Windows systems.

## Features

- List all available screen resolutions
- Show the current screen resolution
- Change screen resolution
- Set refresh rate

## Requirements

- Windows OS
- Zig compiler (tested with 0.11.0)

## Building

```
zig build
```

The executable will be created in the `zig-out/bin` directory.

## Usage

```
qres-zig [options]
```

### Options:

- `--list` - List all available screen resolutions
- `--current` - Show the current screen resolution
- `--set WIDTHxHEIGHT[@RATE]` - Set screen resolution and optional refresh rate (e.g., `--set 1920x1080` or `--set 1920x1080@60`)
- `--help` - Display help message

## Examples

List all available resolutions:
```
qres-zig --list
```

Show current resolution:
```
qres-zig --current
```

Change resolution to 1920x1080:
```
qres-zig --set 1920x1080
```

Change resolution to 1920x1080 with 60Hz refresh rate:
```
qres-zig --set 1920x1080@60
```

## How It Works

QRes-Zig uses the Windows Display API through Zig's foreign function interface to interact with the system. Specifically, it uses:

- `EnumDisplaySettingsW` to enumerate available display modes and get the current mode
- `ChangeDisplaySettingsW` to change the display settings

## Limitations

- Currently only works on Windows
- Only supports the primary display

## License

MIT 
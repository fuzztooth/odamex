# Odamex for Android

Android-specific platform code for Odamex.

## Directory Structure

- `android_io.cpp` - File system and I/O operations for Android
- `android_system.h` - Android-specific system interface

## Storage Paths

Android builds use the following directory structure:

- **Internal Storage**: `/data/data/net.odamex.android/files/`
  - `wads/` - WAD files (DOOM.WAD, DOOM2.WAD, PWADs)
  - `config/` - Configuration files

- **External Storage** (if available): `/sdcard/Android/data/net.odamex.android/files/`

## Building

See the main Android build documentation in `android/README.md` for build instructions.

## Platform Features

- SDL2-based rendering and input
- Touch screen input (virtual controls)
- Android asset loading
- Proper lifecycle management (pause/resume)
- Android logging integration

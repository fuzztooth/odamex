# Odamex Android Build

This directory contains the Android Studio project for building Odamex as an Android APK.

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for a step-by-step build guide.

## Prerequisites

- **Android Studio** Arctic Fox or later
- **Android SDK** API Level 23-36  
- **Android NDK** 27.0.12077973
- **CMake** 3.22.1+ (bundled with Android Studio)
- **Java (JDK)** (included with Android Studio)
- **Git Bash** (Windows) or standard bash (Linux/Mac)

**Version Management:** All Android-related version numbers (SDK levels, NDK, CMake, SDL2, dependencies) are centralized in [gradle/dependencies.gradle](gradle/dependencies.gradle). Update versions there to keep the entire build system in sync. See [VERSION-DEPENDENCIES.md](VERSION-DEPENDENCIES.md) for details.

### Environment Variables

Set these before building:

```bash
# Android SDK location
export ANDROID_HOME="/path/to/Android/Sdk"

# Java for Gradle (command-line builds only)
export JAVA_HOME="/path/to/android-studio/jbr"
```

## Building

### 1. Build Dependencies

```bash
cd android

# Build SDL2 libraries (downloads and compiles SDL2 + SDL2_mixer)
bash ./build-sdl2.sh

# Build protoc compiler (for protobuf code generation)
bash ./build-protoc.sh
```

These scripts:
- Download source code to temp directories
- Build for Android (arm64-v8a and armeabi-v7a)
- Copy artifacts to the Android project
- Clean up temp files on next run

### 2. Build APK

**Android Studio**:
```
File → Open → Select android/ directory
Build → Make Project
```

**Command Line**:
```bash
./gradlew assembleDebug     # Debug build
./gradlew assembleRelease   # Release build
```

### 3. Install to Device

```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## Project Structure

```
android/
├── app/
│   └── src/
│       └── main/
│           ├── assets/          # Game data files (WADs)
│           ├── cpp/
│           │   ├── CMakeLists.txt
│           │   └── protoc/      # Built by build-protoc.sh
│           ├── java/
│           │   └── org/libsdl/  # Built by build-sdl2.sh
│           └── jniLibs/         # Built by build-sdl2.sh
├── build-sdl2.sh        # Downloads and builds SDL2
├── build-protoc.sh      # Builds protoc for host
├── build.gradle         # Top-level Gradle config
└── settings.gradle
```

## Build Scripts

### build-sdl2.sh

Downloads and builds SDL2 (2.30.8) and SDL2_mixer (2.8.0) for Android:
- Builds to `/tmp/sdl2-android-build` (or `$TMPDIR`)
- Extracts `.so` files to `app/src/main/jniLibs/`
- Copies Java classes to `app/src/main/java/org/libsdl/`
- Cleans temp directory on next run

### build-protoc.sh

Builds protoc compiler for the host platform:
- Builds to `/tmp/protoc-host-build` (or `$TMPDIR`)
- Uses Visual Studio (Windows) or system compiler (Linux/Mac)
- Copies `protoc.exe`/`protoc` to `app/src/main/cpp/protoc/`
- Cleans temp directory on next run

**Note**: These scripts must be run from Git Bash on Windows.

## Adding Game Data

Place WAD files in `app/src/main/assets/`:
- `odamex.wad` (required)
- `doom.wad`, `doom2.wad`, or other IWADs
- Additional PWADs as needed

Build `odamex.wad`:
```bash
cd ../wad
deutex -make odamex.txt
cp odamex.wad ../android/app/src/main/assets/
```

## Clean Build

```bash
# Clean Gradle build
./gradlew clean

# Remove all build artifacts
rm -rf app/.cxx app/build

# Rebuild dependencies
bash ./build-sdl2.sh
bash ./build-protoc.sh

# Rebuild APK
./gradlew assembleDebug
```

## Gradle Wrapper

If `gradle-wrapper.jar` is missing, download it:

**Bash** (Linux/Mac/Git Bash):
```bash
bash ./download-wrapper.sh
```

**PowerShell** (Windows):
```powershell
.\download-wrapper.ps1
```

Or open the project in Android Studio - it will auto-generate.

## Storage Paths

The app stores data in Android's private storage:
- Internal: `/data/data/net.odamex.android/files/`
- Config files and saves go here
- No special permissions required

## Troubleshooting

**Build fails with "ANDROID_HOME not set"**:
```bash
export ANDROID_HOME="/path/to/Android/Sdk"
```

**Build fails with "NDK not found"**:
Install via Android Studio → SDK Manager → SDK Tools → NDK (27.0.12077973)

**build-sdl2.sh fails with "bash: command not found"** (Windows):
Use Git Bash instead of cmd or PowerShell

**Gradle fails with Java errors**:
```bash
export JAVA_HOME="/path/to/android-studio/jbr"
```

**CMake fails to find protoc**:
```bash
bash ./build-protoc.sh
```

## Target Devices

- **Minimum SDK**: API 23 (Android 6.0 Marshmallow)
- **Target SDK**: API 36 (Android 15)
- **Architectures**: arm64-v8a, armeabi-v7a
- **Orientation**: Landscape

## Development

- Open `android/` directory in Android Studio
- Source code is in the main repository (`client/`, `common/`, etc.)
- Android-specific code is in `client/android/`
- CMake configuration is in `client/CMakeLists.txt`

## Project Structure

```
android/
├── app/
│   ├── build.gradle              # App-level Gradle config
│   ├── src/main/
│   │   ├── AndroidManifest.xml   # App manifest
│   │   ├── java/                 # Java source (SDL activity wrapper)
│   │   ├── assets/               # Place odamex.wad here
│   │   └── jniLibs/              # Prebuilt .so files (if any)
│   └── CMakeLists.txt (uses ../../CMakeLists.txt)
├── build.gradle                  # Project-level Gradle config
└── settings.gradle               # Gradle settings
```

## Adding WAD Files

Place your WAD files in `android/app/src/main/assets/`:

```
android/app/src/main/assets/
├── odamex.wad      # Required
├── DOOM.WAD        # Shareware or registered
└── DOOM2.WAD       # Optional
```

These will be copied to device internal storage on first launch.

## Supported ABIs

- ARM64 (arm64-v8a) - Primary target
- ARMv7 (armeabi-v7a) - Legacy 32-bit devices

To build for specific ABI:
```bash
./gradlew assembleDebug -Pandroid.ndkAbi=arm64-v8a
```

## Debugging

View native logs:
```bash
adb logcat | grep -E "Odamex|SDL|DEBUG"
```

Debug native code:
1. Build → Debug 'app'
2. Set breakpoints in C++ code
3. Run with native debugger attached

##Java not found / JAVA_HOME errors**: 
- Set JAVA_HOME to Android Studio's JDK: `C:\Program Files\Android\Android Studio\jbr`
- Or install JDK separately from https://adoptium.net/

**CMake not found**: Install via SDK Manager → SDK Tools → CMake

**NDK errors**: Install via SDK Manager → SDK Tools → NDK (Side by side)

**SDL2 errors**: SDL2 will be fetched automatically by gradle (via Maven)

**Build fails**: Ensure environment variables are set:
- `JAVA_HOME` - Required for gradle
- `ANDROID_HOME` - Path to Android SDK (usually auto-detected)
- `ANDROID_NDK_HOME` - Path to NDK (usually auto-detected)

## Troubleshooting

**CMake not found**: Install via SDK Manager → SDK Tools → CMake

**NDK errors**: Install via SDK Manager → SDK Tools → NDK (Side by side)

**SDL2 errors**: SDL2 will be fetched automatically by CMake or use prebuilt libraries

**Build fails**: Ensure `ANDROID_HOME` and `ANDROID_NDK_HOME` environment variables are set

## Phase 1 Status

✅ Android Studio project structure
✅ Gradle build configuration  
✅ SDL2 activity wrapper
✅ CMake integration
⏳ SDL2 library integration (next step)
⏳ First successful build

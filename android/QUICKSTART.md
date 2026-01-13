# Odamex Android Build - Quick Start

## Prerequisites

### Required Software

- **Android Studio** (Arctic Fox or later)
- **Android SDK** (API Level 23-36)
- **Android NDK** 27.0.12077973
- **CMake** 3.22.1+ (included with Android Studio)
- **Java (JDK)** (included with Android Studio)
- **Git Bash** (Windows) or **bash** (Linux/Mac)

### Environment Setup

Set `ANDROID_HOME` to your Android SDK location:

**Windows (Git Bash)**:
```bash
export ANDROID_HOME="C:/Users/YourName/AppData/Local/Android/Sdk"
```

**Linux/Mac**:
```bash
export ANDROID_HOME="$HOME/Android/Sdk"
```

For command-line builds, also set `JAVA_HOME`:
```bash
# Windows
export JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"

# Linux/Mac  
export JAVA_HOME="/path/to/android-studio/jbr"
```

Verify setup:
```bash
java -version
echo $ANDROID_HOME
```

## Building

### Step 1: Build SDL2 and Protoc

Run these scripts once (or when dependencies change):

```bash
cd android

# Build SDL2 libraries
bash ./build-sdl2.sh

# Build protoc compiler for host
bash ./build-protoc.sh

# Build odamex.wad
bash ./build-wad.sh
```

**What these do**:
- `build-sdl2.sh` - Downloads and builds SDL2 + SDL2_mixer for Android
- `build-protoc.sh` - Builds protoc.exe for protobuf code generation
- `build-wad.sh` - Downloads DeuTex and builds odamex.wad

### Step 1.5: Add Game IWAD (Required)

The engine needs a DOOM IWAD to run. Copy one of these to `android/app/src/main/assets/`:
- **DOOM.WAD** - Original DOOM (shareware or registered)
- **DOOM2.WAD** - DOOM II  
- **FREEDOOM1.WAD** / **FREEDOOM2.WAD** - Free alternatives

Download Freedoom from: https://freedoom.github.io/

### Step 2: Build APK

**Option A: Android Studio**

1. Open Android Studio
2. File → Open → Select the `android/` directory  
3. Wait for Gradle sync
4. Build → Make Project

**Option B: Command Line**

```bash
cd android
./gradlew assembleDebug
```

Build output: `android/app/build/outputs/apk/debug/app-debug.apk`

### Step 3: Install to Device/Emulator

```bash
# Install APK
adb install -r app/build/outputs/apk/debug/app-debug.apk

# Launch app
adb shell am start -n net.odamex.android/.MainActivity
```

## Clean Rebuild

To rebuild from scratch:

```bash
cd android

# Clean build artifacts
./gradlew clean
rm -rf app/.cxx
rm -rf app/build

# Rebuild dependencies
bash ./build-sdl2.sh
bash ./build-protoc.sh

# Build APK
./gradlew assembleDebug
```

## Troubleshooting

**"ANDROID_HOME not set"**: Set environment variable (see Prerequisites)

**"NDK not found"**: Install via Android Studio → SDK Manager → SDK Tools → NDK

**"bash: command not found"** (Windows): Install Git Bash or use WSL

**Build fails with Java errors**: Ensure `JAVA_HOME` is set correctly
bash ./build-wad.sh

**SDL2 build fails**: Check that curl and unzip are installed

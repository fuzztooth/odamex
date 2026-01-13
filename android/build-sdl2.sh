#!/bin/bash
# Build SDL2 for Android
# Downloads SDL2 source, builds for Android, extracts .so files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read versions from Gradle dependencies file
GRADLE_DEPS="$SCRIPT_DIR/gradle/dependencies.gradle"
if [ -f "$GRADLE_DEPS" ]; then
    SDL_VERSION=$(grep "sdl2Version" "$GRADLE_DEPS" | sed "s/.*['\"]\([0-9.]\+\)['\"].*/\1/")
    MIXER_VERSION=$(grep "sdl2MixerVersion" "$GRADLE_DEPS" | sed "s/.*['\"]\([0-9.]\+\)['\"].*/\1/")
    NDK_VERSION=$(grep "ndkVersion" "$GRADLE_DEPS" | sed "s/.*['\"]\([0-9.]\+\)['\"].*/\1/")
    CMAKE_VERSION=$(grep "cmakeVersion" "$GRADLE_DEPS" | sed "s/.*['\"]\([0-9.]\+\)['\"].*/\1/")
    echo "Read versions from gradle/dependencies.gradle:"
    echo "  SDL2: $SDL_VERSION"
    echo "  SDL2_mixer: $MIXER_VERSION"
    echo "  NDK: $NDK_VERSION"
    echo "  CMake: $CMAKE_VERSION"
    echo ""
else
    echo "Warning: gradle/dependencies.gradle not found, using fallback versions"
    SDL_VERSION="2.30.8"
    MIXER_VERSION="2.8.0"
    NDK_VERSION="27.0.12077973"
    CMAKE_VERSION="3.22.1"
fi

TEMP_DIR="${TMPDIR:-/tmp}/sdl2-android-build"

echo "========================================"
echo "SDL2 Android Build Script"
echo "========================================"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if [ -z "$ANDROID_HOME" ]; then
    echo "ERROR: ANDROID_HOME not set"
    echo "Please set ANDROID_HOME to your Android SDK location"
    exit 1
fi
echo "✓ Android SDK: $ANDROID_HOME"

NDK_PATH="$ANDROID_HOME/ndk/$NDK_VERSION"
if [ ! -d "$NDK_PATH" ]; then
    echo "ERROR: NDK not found at $NDK_PATH"
    echo "Please install NDK $NDK_VERSION via Android Studio"
    exit 1
fi
echo "✓ Android NDK: $NDK_PATH"

CMAKE_BIN="$ANDROID_HOME/cmake/$CMAKE_VERSION/bin/cmake"
if [ ! -f "$CMAKE_BIN" ]; then
    # Try to find cmake in PATH
    if command -v cmake &> /dev/null; then
        CMAKE_BIN="cmake"
    else
        echo "ERROR: CMake not found"
        echo "Please install CMake via Android Studio SDK Manager"
        exit 1
    fi
fi
echo "✓ CMake: $CMAKE_BIN"

NINJA_BIN="$ANDROID_HOME/cmake/3.22.1/bin/ninja"
if [ ! -f "$NINJA_BIN" ]; then
    echo "ERROR: Ninja not found"
    echo "Please install CMake via Android Studio SDK Manager"
    exit 1
fi
echo "✓ Ninja: $NINJA_BIN"
echo ""

# Setup directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JNI_LIBS_DIR="$SCRIPT_DIR/app/src/main/jniLibs"
JAVA_LIBS_DIR="$SCRIPT_DIR/app/src/main/java/org/libsdl"
SDL_SRC_DIR="$TEMP_DIR/SDL"
MIXER_SRC_DIR="$TEMP_DIR/SDL_mixer"

echo "Cleaning previous build artifacts..."
rm -rf "$TEMP_DIR"
rm -rf "$JNI_LIBS_DIR"
rm -rf "$JAVA_LIBS_DIR"

echo "Creating fresh build directories..."
mkdir -p "$TEMP_DIR"
mkdir -p "$JNI_LIBS_DIR"
mkdir -p "$JAVA_LIBS_DIR"

# Download SDL2
echo ""
echo "========================================"
echo "Downloading SDL2 $SDL_VERSION..."
echo "========================================"

SDL_ZIP="$TEMP_DIR/SDL2-$SDL_VERSION.zip"
SDL_URL="https://github.com/libsdl-org/SDL/archive/refs/tags/release-$SDL_VERSION.zip"

echo "Downloading from: $SDL_URL"
curl -L -o "$SDL_ZIP" "$SDL_URL"

echo "Extracting SDL2..."
unzip -o -q "$SDL_ZIP" -d "$TEMP_DIR"
mv "$TEMP_DIR/SDL-release-$SDL_VERSION" "$SDL_SRC_DIR"

# Download SDL2_mixer
echo ""
echo "========================================"
echo "Downloading SDL2_mixer $MIXER_VERSION..."
echo "========================================"

MIXER_ZIP="$TEMP_DIR/SDL2_mixer-$MIXER_VERSION.zip"
MIXER_URL="https://github.com/libsdl-org/SDL_mixer/archive/refs/tags/release-$MIXER_VERSION.zip"

echo "Downloading from: $MIXER_URL"
curl -L -o "$MIXER_ZIP" "$MIXER_URL"

echo "Extracting SDL2_mixer..."
unzip -o -q "$MIXER_ZIP" -d "$TEMP_DIR"
mv "$TEMP_DIR/SDL_mixer-release-$MIXER_VERSION" "$MIXER_SRC_DIR"

# Download SDL2_mixer external dependencies
echo ""
echo "========================================"
echo "Downloading SDL2_mixer dependencies..."
echo "========================================"

cd "$MIXER_SRC_DIR/external"
if [ -f "download.sh" ]; then
    echo "Running download.sh..."
    bash download.sh
else
    echo "WARNING: download.sh not found, SDL2_mixer may fail to build"
fi

# Build SDL2
echo ""
echo "========================================"
echo "Building SDL2 for Android..."
echo "========================================"

SDL_BUILD_DIR="$SDL_SRC_DIR/build-android"
SDL_INSTALL_DIR="$TEMP_DIR/SDL-install"
echo "Build directory: $SDL_BUILD_DIR"
echo "Install directory: $SDL_INSTALL_DIR"

cd "$SDL_SRC_DIR"

for ABI in "arm64-v8a" "armeabi-v7a"; do
    echo ""
    echo "Building for $ABI..."
    
    ABI_BUILD_DIR="$SDL_BUILD_DIR/$ABI"
    ABI_INSTALL_DIR="$SDL_INSTALL_DIR/$ABI"
    mkdir -p "$ABI_BUILD_DIR"
    mkdir -p "$ABI_INSTALL_DIR"
    
    cd "$ABI_BUILD_DIR"
    
    echo "Running CMake..."
    "$CMAKE_BIN" \
        -G Ninja \
        -DCMAKE_MAKE_PROGRAM="$NINJA_BIN" \
        -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI="$ABI" \
        -DANDROID_PLATFORM=android-23 \
        -DCMAKE_INSTALL_PREFIX="$ABI_INSTALL_DIR" \
        -DSDL_SHARED=ON \
        -DSDL_STATIC=OFF \
        ../..
    
    echo "Building..."
    "$CMAKE_BIN" --build . --config Release
    
    echo "Installing SDL2..."
    "$CMAKE_BIN" --install .
    
    # Copy the built library
    ABI_LIB_DIR="$JNI_LIBS_DIR/$ABI"
    mkdir -p "$ABI_LIB_DIR"
    
    SO_FILE="$ABI_BUILD_DIR/libSDL2.so"
    if [ -f "$SO_FILE" ]; then
        echo "Copying libSDL2.so to $ABI_LIB_DIR"
        cp "$SO_FILE" "$ABI_LIB_DIR/"
    else
        echo "WARNING: libSDL2.so not found at $SO_FILE"
    fi
    
    cd "$SDL_SRC_DIR"
done

# Copy SDL2 Java source files
echo ""
echo "========================================"
echo "Copying SDL2 Java source files..."
echo "========================================"

SDL_JAVA_SRC="$SDL_SRC_DIR/android-project/app/src/main/java/org/libsdl/app"
SDL_JAVA_DEST="$SCRIPT_DIR/app/src/main/java/org/libsdl/app"

if [ -d "$SDL_JAVA_SRC" ]; then
    echo "Copying from: $SDL_JAVA_SRC"
    echo "Copying to: $SDL_JAVA_DEST"
    mkdir -p "$SDL_JAVA_DEST"
    cp -r "$SDL_JAVA_SRC"/*.java "$SDL_JAVA_DEST/"
    echo "✓ SDL2 Java files copied"
else
    echo "WARNING: SDL2 Java source not found at $SDL_JAVA_SRC"
fi

# Build SDL2_mixer
echo ""
echo "========================================"
echo "Building SDL2_mixer for Android..."
echo "========================================"

MIXER_BUILD_DIR="$MIXER_SRC_DIR/build-android"
echo "Build directory: $MIXER_BUILD_DIR"

cd "$MIXER_SRC_DIR"

for ABI in "arm64-v8a" "armeabi-v7a"; do
    echo ""
    echo "Building for $ABI..."
    
    ABI_BUILD_DIR="$MIXER_BUILD_DIR/$ABI"
    ABI_INSTALL_DIR="$SDL_INSTALL_DIR/$ABI"
    mkdir -p "$ABI_BUILD_DIR"
    
    cd "$ABI_BUILD_DIR"
    
    echo "Running CMake..."
    echo "Using SDL2_DIR=$ABI_INSTALL_DIR/lib/cmake/SDL2"
    if "$CMAKE_BIN" \
        -G Ninja \
        -DCMAKE_MAKE_PROGRAM="$NINJA_BIN" \
        -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI="$ABI" \
        -DANDROID_PLATFORM=android-23 \
        -DSDL2MIXER_VENDORED=ON \
        -DSDL2MIXER_WAVPACK=OFF \
        -DCMAKE_PREFIX_PATH="$ABI_INSTALL_DIR" \
        -DSDL2_DIR="$ABI_INSTALL_DIR/lib/cmake/SDL2" \
        ../..; then
        
        echo "Building..."
        if "$CMAKE_BIN" --build . --config Release; then
            # Copy the built library
            ABI_LIB_DIR="$JNI_LIBS_DIR/$ABI"
            mkdir -p "$ABI_LIB_DIR"
            
            SO_FILE="$ABI_BUILD_DIR/libSDL2_mixer.so"
            if [ -f "$SO_FILE" ]; then
                echo "Copying libSDL2_mixer.so to $ABI_LIB_DIR"
                cp "$SO_FILE" "$ABI_LIB_DIR/"
            else
                echo "WARNING: libSDL2_mixer.so not found at $SO_FILE"
            fi
        else
            echo "WARNING: Build failed for SDL2_mixer $ABI"
            echo "Continuing anyway..."
        fi
    else
        echo "WARNING: CMake configuration failed for SDL2_mixer $ABI"
        echo "Continuing anyway..."
    fi
    
    cd "$MIXER_SRC_DIR"
done

# Clean temp directory
echo ""
echo "Saving SDL2 headers for later..."
# Save headers to a known location that persists
HEADERS_DIR="$SCRIPT_DIR/app/src/main/cpp/SDL2-headers"
mkdir -p "$HEADERS_DIR"
echo "  Copying SDL2 headers to $HEADERS_DIR"
if [ -d "$SDL_INSTALL_DIR/arm64-v8a/include/SDL2" ]; then
    cp -r "$SDL_INSTALL_DIR/arm64-v8a/include/SDL2/"* "$HEADERS_DIR/"
fi
# Copy SDL2_mixer headers
if [ -d "$MIXER_SRC_DIR/include" ]; then
    cp "$MIXER_SRC_DIR/include/"*.h "$HEADERS_DIR/" 2>/dev/null || true
fi

echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Summary
echo ""
echo "========================================"
echo "Build Complete!"
echo "========================================"
echo ""
echo "Libraries installed to: $JNI_LIBS_DIR"
echo ""

# List what was built
for ABI in "arm64-v8a" "armeabi-v7a"; do
    ABI_LIB_DIR="$JNI_LIBS_DIR/$ABI"
    echo "$ABI:"
    
    if [ -f "$ABI_LIB_DIR/libSDL2.so" ]; then
        echo "  ✓ libSDL2.so"
    else
        echo "  ✗ libSDL2.so MISSING"
    fi
    
    if [ -f "$ABI_LIB_DIR/libSDL2_mixer.so" ]; then
        echo "  ✓ libSDL2_mixer.so"
    else
        echo "  ✗ libSDL2_mixer.so MISSING"
    fi
done

echo ""
echo "Next steps:"
echo "1. Open Android Studio and sync project"
echo "2. Build the Odamex APK"
echo ""

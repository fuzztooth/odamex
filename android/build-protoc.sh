#!/bin/bash
set -e

# Build protoc for the host platform (Windows)
# This is needed for Android cross-compilation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBRARIES_DIR="$SCRIPT_DIR/../libraries"
PROTOBUF_SRC="$LIBRARIES_DIR/protobuf/cmake"
TEMP_DIR="${TMPDIR:-/tmp}/protoc-host-build"
BUILD_DIR="$TEMP_DIR/build"
INSTALL_DIR="$TEMP_DIR/install"
FINAL_DEST="$SCRIPT_DIR/app/src/main/cpp/protoc"

echo "Building host protoc compiler..."

# Find Visual Studio installation
VSWHERE="/c/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
if [ ! -f "$VSWHERE" ]; then
    echo "ERROR: vswhere.exe not found at $VSWHERE"
    echo "Please install Visual Studio 2022 or later"
    exit 1
fi

VSINSTALLDIR=$("$VSWHERE" -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath)
if [ -z "$VSINSTALLDIR" ]; then
    echo "ERROR: Visual Studio with C++ tools not found"
    exit 1
fi

VCVARSALL="$VSINSTALLDIR/VC/Auxiliary/Build/vcvarsall.bat"
if [ ! -f "$VCVARSALL" ]; then
    echo "ERROR: vcvarsall.bat not found at $VCVARSALL"
    exit 1
fi

echo "Found Visual Studio at: $VSINSTALLDIR"

# Read CMake version from Gradle dependencies file
GRADLE_DEPS="$SCRIPT_DIR/gradle/dependencies.gradle"
if [ -f "$GRADLE_DEPS" ]; then
    CMAKE_VERSION=$(grep "cmakeVersion" "$GRADLE_DEPS" | sed "s/.*['\"\]\([0-9.]\+\)['\"].*/\1/")
    echo "Using CMake version from gradle/dependencies.gradle: $CMAKE_VERSION"
else
    CMAKE_VERSION="3.22.1"
    echo "Warning: gradle/dependencies.gradle not found, using fallback CMake version: $CMAKE_VERSION"
fi

# Use the Android SDK's CMake
CMAKE="$ANDROID_HOME/cmake/$CMAKE_VERSION/bin/cmake.exe"

# Clean previous build artifacts (like build-sdl2.sh does)
echo "Cleaning previous build artifacts..."
rm -rf "$TEMP_DIR"
rm -rf "$FINAL_DEST"

# Create fresh build directories
echo "Creating fresh build directories..."
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$FINAL_DEST"

# Convert Unix paths to Windows paths for cmd
PROTOBUF_SRC_WIN=$(cygpath -w "$PROTOBUF_SRC")
BUILD_DIR_WIN=$(cygpath -w "$BUILD_DIR")
INSTALL_DIR_WIN=$(cygpath -w "$INSTALL_DIR")

# Configure and build protoc using Visual Studio environment
# We need to run this through cmd to set up the VS environment first
echo "Configuring protoc with Visual Studio environment..."
cmd <<EOF
call "$VCVARSALL" x64
"$CMAKE" -S "$PROTOBUF_SRC_WIN" -B "$BUILD_DIR_WIN" -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR_WIN" -Dprotobuf_BUILD_SHARED_LIBS=OFF -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_MSVC_STATIC_RUNTIME=OFF
"$CMAKE" --build "$BUILD_DIR_WIN" --target protoc --config Release
EOF

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build protoc"
    exit 1
fi

# Copy protoc.exe to final destination
if [ -f "$BUILD_DIR/Release/protoc.exe" ]; then
    cp "$BUILD_DIR/Release/protoc.exe" "$FINAL_DEST/"
    echo "Copied protoc.exe from $BUILD_DIR/Release/"
elif [ -f "$BUILD_DIR/protoc.exe" ]; then
    cp "$BUILD_DIR/protoc.exe" "$FINAL_DEST/"
    echo "Copied protoc.exe from $BUILD_DIR/"
else
    echo "ERROR: protoc.exe not found after build"
    exit 1
fi

echo "Host protoc built successfully at $FINAL_DEST/protoc.exe"

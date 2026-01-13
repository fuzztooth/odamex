#!/bin/bash
# Build odamex.wad for Android
# This script downloads DeuTex and builds the odamex.wad file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAD_SOURCE_DIR="$SCRIPT_DIR/../wad"
ASSETS_DIR="$SCRIPT_DIR/app/src/main/assets"
TEMP_DIR="${TMPDIR:-/tmp}/odamex-wad-build"

echo "========================================"
echo "Odamex WAD Builder for Android"
echo "========================================"
echo ""

# Clean and create temp directory
echo "Setting up build directories..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
mkdir -p "$ASSETS_DIR"

# Download DeuTex for Windows
DEUTEX_VERSION="5.2.3"
DEUTEX_URL="https://github.com/Doom-Utils/deutex/releases/download/v${DEUTEX_VERSION}/deutex-${DEUTEX_VERSION}_w32.zip"
DEUTEX_ZIP="$TEMP_DIR/deutex.zip"
DEUTEX_DIR="$TEMP_DIR/deutex"

echo "Downloading DeuTex ${DEUTEX_VERSION}..."
curl -L -o "$DEUTEX_ZIP" "$DEUTEX_URL"

echo "Extracting DeuTex..."
unzip -q "$DEUTEX_ZIP" -d "$DEUTEX_DIR"

# Find the deutex executable (it's in the root of the zip)
DEUTEX_EXE="$DEUTEX_DIR/deutex.exe"
if [ ! -f "$DEUTEX_EXE" ]; then
    echo "ERROR: Could not find deutex.exe in extracted archive"
    echo "Contents:"
    ls -la "$DEUTEX_DIR"
    exit 1
fi
echo "✓ DeuTex: $DEUTEX_EXE"

# Build odamex.wad
echo ""
echo "Building odamex.wad..."
cd "$WAD_SOURCE_DIR"

"$DEUTEX_EXE" -overwrite -rgb 0 255 255 -doom2 bootstrap -build wadinfo.txt "$TEMP_DIR/odamex.wad"

if [ ! -f "$TEMP_DIR/odamex.wad" ]; then
    echo "ERROR: Failed to build odamex.wad"
    exit 1
fi

# Check file size (should be reasonable, typically 500KB-2MB)
WAD_SIZE=$(stat -c%s "$TEMP_DIR/odamex.wad" 2>/dev/null || stat -f%z "$TEMP_DIR/odamex.wad" 2>/dev/null)
echo "✓ Built odamex.wad ($(numfmt --to=iec-i --suffix=B $WAD_SIZE 2>/dev/null || echo "$WAD_SIZE bytes"))"

# Copy to Android assets
echo ""
echo "Copying to Android assets..."
cp "$TEMP_DIR/odamex.wad" "$ASSETS_DIR/odamex.wad"
echo "✓ Copied to: $ASSETS_DIR/odamex.wad"

# Clean up temp directory
echo ""
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo ""
echo "========================================"
echo "✓ WAD build complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Add a DOOM IWAD to assets/ (DOOM.WAD, DOOM2.WAD, or FREEDOOM)"
echo "  2. Build the APK: ./gradlew assembleDebug"
echo ""

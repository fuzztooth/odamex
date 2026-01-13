#!/bin/bash
# Gradle Wrapper JAR Download Script
# Run this to download the gradle-wrapper.jar

set -e

WRAPPER_DIR="gradle/wrapper"
WRAPPER_JAR="$WRAPPER_DIR/gradle-wrapper.jar"
WRAPPER_URL="https://raw.githubusercontent.com/gradle/gradle/v8.2.0/gradle/wrapper/gradle-wrapper.jar"

echo "Downloading Gradle Wrapper JAR..."

if [ ! -d "$WRAPPER_DIR" ]; then
    mkdir -p "$WRAPPER_DIR"
fi

if curl -L -o "$WRAPPER_JAR" "$WRAPPER_URL"; then
    echo "✓ Gradle wrapper downloaded successfully!"
    echo ""
    echo "You can now run: ./gradlew assembleDebug"
else
    echo "✗ Failed to download wrapper. You can alternatively:"
    echo "  1. Open the project in Android Studio (it will auto-generate)"
    echo "  2. Or manually download from: https://raw.githubusercontent.com/gradle/gradle/v8.2.0/gradle/wrapper/gradle-wrapper.jar"
    exit 1
fi

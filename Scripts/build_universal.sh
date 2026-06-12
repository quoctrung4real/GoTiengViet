#!/bin/bash
# Build Universal Binary for GoTiengViet
# Supports both Intel (x86_64) and Apple Silicon (arm64)

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="GoTiengViet"

echo "=== Building GoTiengViet Universal Binary ==="
echo "Project: $PROJECT_DIR"
echo "Output:  $BUILD_DIR"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build with xcodebuild
xcodebuild \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    BUILD_DIR="$BUILD_DIR" \
    clean build

# Copy the built app
APP_PATH="$BUILD_DIR/Release/$APP_NAME.app"

if [ -d "$APP_PATH" ]; then
    echo ""
    echo "=== Build Successful ==="
    echo "App: $APP_PATH"

    # Verify Universal Binary
    echo ""
    echo "=== Verifying Architecture ==="
    file "$APP_PATH/Contents/MacOS/$APP_NAME"

    # Show architectures
    lipo -info "$APP_PATH/Contents/MacOS/$APP_NAME" 2>/dev/null || true

    echo ""
    echo "=== Binary Size ==="
    ls -lh "$APP_PATH/Contents/MacOS/$APP_NAME"
else
    echo "ERROR: Build failed — app bundle not found at $APP_PATH"
    exit 1
fi

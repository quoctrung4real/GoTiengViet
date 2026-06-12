#!/bin/bash
# Install GoTiengViet for development/testing
# Copies the built app to ~/Library/Input Methods/

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="GoTiengViet"
INSTALL_DIR="$HOME/Library/Input Methods"

echo "=== Installing GoTiengViet for Development ==="

# Build first if needed
APP_PATH="$BUILD_DIR/Release/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
    echo "App not built yet. Building..."
    "$PROJECT_DIR/Scripts/build_universal.sh"
fi

# Kill any running instance
echo "Stopping existing instance..."
killall "$APP_NAME" 2>/dev/null || true
sleep 1

# Create Input Methods directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Remove old installation
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo "Removing old installation..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

# Copy new build
echo "Installing to $INSTALL_DIR/"
cp -R "$APP_PATH" "$INSTALL_DIR/"

echo ""
echo "=== Installation Complete ==="
echo "Installed: $INSTALL_DIR/$APP_NAME.app"
echo ""
echo "To activate:"
echo "1. Open System Settings > Keyboard > Input Sources"
echo "2. Click '+' to add a new input source"
echo "3. Find 'Vietnamese' > 'Gõ Tiếng Việt'"
echo "4. Click 'Add'"
echo ""
echo "You may need to log out and log back in for changes to take effect."

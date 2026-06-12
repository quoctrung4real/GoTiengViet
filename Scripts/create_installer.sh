#!/bin/bash
# Create installer package (PKG) and disk image (DMG) for GoTiengViet

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="GoTiengViet"
VERSION="1.0.0"
BUNDLE_ID="com.govietnamese.inputmethod.GoTiengViet"
PKG_DIR="$BUILD_DIR/pkg"
DMG_DIR="$BUILD_DIR/dmg"

echo "=== Creating GoTiengViet Installer ==="

# Ensure the app is built
APP_PATH="$BUILD_DIR/Release/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
    echo "App not built. Building first..."
    "$PROJECT_DIR/Scripts/build_universal.sh"
fi

# Clean
rm -rf "$PKG_DIR" "$DMG_DIR"
mkdir -p "$PKG_DIR/root/Library/Input Methods"
mkdir -p "$PKG_DIR/scripts"
mkdir -p "$DMG_DIR"

# Copy app to package root
cp -R "$APP_PATH" "$PKG_DIR/root/Library/Input Methods/"

# Create postinstall script
cat > "$PKG_DIR/scripts/postinstall" << 'EOF'
#!/bin/bash
# Post-installation: notify user
echo "GoTiengViet installed to /Library/Input Methods/"
echo "Please add it via System Settings > Keyboard > Input Sources"

# Kill any existing instance to force reload
killall GoTiengViet 2>/dev/null || true

exit 0
EOF
chmod +x "$PKG_DIR/scripts/postinstall"

# Build the component package
echo "Building PKG..."
pkgbuild \
    --root "$PKG_DIR/root" \
    --install-location "/" \
    --scripts "$PKG_DIR/scripts" \
    --identifier "$BUNDLE_ID" \
    --version "$VERSION" \
    "$PKG_DIR/$APP_NAME-$VERSION.pkg"

echo "PKG created: $PKG_DIR/$APP_NAME-$VERSION.pkg"

# Create DMG
echo "Creating DMG..."
cp "$PKG_DIR/$APP_NAME-$VERSION.pkg" "$DMG_DIR/"

# Add a README
cat > "$DMG_DIR/README.txt" << EOF
Gõ Tiếng Việt — Vietnamese Input Method for macOS
Version: $VERSION

CÀI ĐẶT:
1. Mở file GoTiengViet-$VERSION.pkg
2. Làm theo hướng dẫn cài đặt
3. Mở System Settings > Keyboard > Input Sources
4. Nhấn '+' để thêm nguồn nhập liệu mới
5. Tìm 'Vietnamese' > 'Gõ Tiếng Việt'
6. Nhấn 'Add'

Hỗ trợ: Intel Mac và Apple Silicon (M1/M2/M3/M4)
EOF

# Create DMG using hdiutil
hdiutil create \
    -volname "Gõ Tiếng Việt $VERSION" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$BUILD_DIR/$APP_NAME-$VERSION.dmg"

echo ""
echo "=== Installer Created ==="
echo "PKG: $PKG_DIR/$APP_NAME-$VERSION.pkg"
echo "DMG: $BUILD_DIR/$APP_NAME-$VERSION.dmg"

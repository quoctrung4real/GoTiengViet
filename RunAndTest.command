#!/bin/bash
# ============================================================
#  GoTiengViet — Build, Install & Test (Double-click to run)
# ============================================================
# Mỗi khi có thay đổi code, chỉ cần double-click file này
# trong Finder để build lại, cài đặt và chạy app để test.
# ============================================================

set -e

# Navigate to project root (regardless of where the script is opened from)
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="GoTiengViet"
INSTALL_DIR="$HOME/Library/Input Methods"
BUILD_DIR="$PROJECT_DIR/build"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   🇻🇳  GoTiengViet — Build & Test Runner        ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Kill existing instance ──────────────────────────
echo "⏹  Đang tắt phiên bản cũ..."
killall "$APP_NAME" 2>/dev/null || true
sleep 0.5

# ── Step 2: Build ───────────────────────────────────────────
echo "🔨 Đang build..."
xcodebuild \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    ARCHS="$(uname -m)" \
    ONLY_ACTIVE_ARCH=YES \
    BUILD_DIR="$BUILD_DIR" \
    build 2>&1 | tail -5

APP_PATH="$BUILD_DIR/Release/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo ""
    echo "❌ Build thất bại! Kiểm tra lỗi ở trên."
    echo ""
    read -n 1 -s -r -p "Nhấn phím bất kỳ để đóng..."
    exit 1
fi

echo "✅ Build thành công!"
echo ""

# ── Step 3: Install to ~/Library/Input Methods ──────────────
echo "📦 Đang cài đặt vào $INSTALL_DIR/..."
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$APP_PATH" "$INSTALL_DIR/"
echo "✅ Đã cài đặt!"
echo ""

# ── Step 4: Register & reload input services ────────────────
echo "🔄 Đang đăng ký lại bộ gõ với hệ thống..."
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister \
    -f -R "$INSTALL_DIR/$APP_NAME.app"
killall -HUP IMKLaunchAgent 2>/dev/null || true
killall TextInputMenuAgent 2>/dev/null || true
echo "✅ Đã đăng ký!"
echo ""

# ── Step 5: Launch the app ──────────────────────────────────
echo "🚀 Đang khởi chạy $APP_NAME..."
open "$INSTALL_DIR/$APP_NAME.app"
sleep 1

# Verify it's running
if pgrep -x "$APP_NAME" > /dev/null; then
    echo "✅ $APP_NAME đang chạy! Kiểm tra icon trên menu bar."
else
    echo "⚠️  App có thể chưa khởi động. Thử mở thủ công:"
    echo "   open \"$INSTALL_DIR/$APP_NAME.app\""
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   ✨ Sẵn sàng test! Chuyển sang app khác để gõ  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "💡 Mẹo:"
echo "   • Nhìn icon V/E trên menu bar"
echo "   • Mở TextEdit hoặc trình duyệt để test gõ tiếng Việt"
echo "   • Nhấn vào icon trên menu bar để xem menu"
echo ""
read -n 1 -s -r -p "Nhấn phím bất kỳ để đóng cửa sổ này..."
echo ""

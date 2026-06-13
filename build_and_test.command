#!/bin/zsh

# Script để build và cài đặt nhanh ứng dụng Gõ Tiếng Việt
# Khi có thay đổi code, bạn chỉ cần click đúp vào file này để chạy.

echo "========================================="
echo "🛠 Đang build Gõ Tiếng Việt..."
echo "========================================="

# Di chuyển đến thư mục chứa project
cd "$(dirname "$0")"

# Build project với xcodebuild
xcodebuild -project GoTiengViet.xcodeproj -scheme GoTiengViet -configuration Release build

if [ $? -eq 0 ]; then
    echo "✅ Build thành công!"
else
    echo "❌ Build thất bại. Vui lòng kiểm tra lại code."
    read -p "Nhấn Enter để thoát..."
    exit 1
fi

# Thư mục đích cài đặt Input Method
DEST_DIR="$HOME/Library/Input Methods"
APP_NAME="GoTiengViet.app"

# Đường dẫn file build
BUILD_APP_PATH="build/Release/$APP_NAME"

echo "========================================="
echo "🚀 Đang cài đặt vào $DEST_DIR..."
echo "========================================="

# Tạo thư mục nếu chưa có
mkdir -p "$DEST_DIR"

# Xóa bản cũ nếu có
if [ -d "$DEST_DIR/$APP_NAME" ]; then
    rm -rf "$DEST_DIR/$APP_NAME"
fi

# Copy app mới vào thư mục Input Methods
cp -r "$BUILD_APP_PATH" "$DEST_DIR/"

# Khởi động lại Input Method để áp dụng bản mới
echo "🔄 Khởi động lại Gõ Tiếng Việt..."

# Tắt app đang chạy
killall "GoTiengViet" 2>/dev/null

# Chờ 1 chút để app kịp tắt
sleep 1

# Mở lại app
open "$DEST_DIR/$APP_NAME"

echo "✅ Đã cài đặt và khởi động xong!"
echo "Bạn có thể vào Cài đặt Hệ thống (System Settings) > Bàn phím (Keyboard) > Sửa (Edit) nguồn đầu vào để bật Gõ Tiếng Việt."
echo "========================================="

# Giữ cửa sổ terminal không bị tắt ngay để bạn xem log
echo "Nhấn phím Enter để đóng cửa sổ này..."
read

#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT_NAME="ClaudeCodeMenuBar"
BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$PRODUCT_NAME.app"

cd "$ROOT_DIR"
swift build -c release

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/$PRODUCT_NAME" "$APP_DIR/Contents/MacOS/$PRODUCT_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/Resources/Assets/claude-mascot.png" "$APP_DIR/Contents/Resources/claude-mascot.png"
cp "$ROOT_DIR/Resources/Assets/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true
echo "$APP_DIR"

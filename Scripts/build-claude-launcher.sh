#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ClaudeCodeLauncher"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
INSTALL_DIR="$HOME/Applications/$APP_NAME.app"
ICON_SRC="$ROOT_DIR/Resources/Assets/AppIcon.icns"
INFO_PLIST="$ROOT_DIR/Resources/LauncherInfo.plist"
SWIFT_SRC="$ROOT_DIR/Launcher/ClaudeCodeLauncher.swift"

mkdir -p "$DIST_DIR" "$HOME/Applications"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

swiftc \
  -O \
  -parse-as-library \
  -framework AppKit \
  "$SWIFT_SRC" \
  -o "$APP_DIR/Contents/MacOS/$APP_NAME"

cp "$INFO_PLIST" "$APP_DIR/Contents/Info.plist"
cp "$ICON_SRC" "$APP_DIR/Contents/Resources/AppIcon.icns"

codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

rm -rf "$INSTALL_DIR"
cp -R "$APP_DIR" "$INSTALL_DIR"

echo "$INSTALL_DIR"

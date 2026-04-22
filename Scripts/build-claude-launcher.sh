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
APP_PLIST="$APP_DIR/Contents/Info.plist"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

DEFAULT_VERSION="$("$PLIST_BUDDY" -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
DEFAULT_BUILD_NUMBER="$("$PLIST_BUDDY" -c 'Print :CFBundleVersion' "$INFO_PLIST")"
VERSION_INPUT="${APP_VERSION:-$DEFAULT_VERSION}"
APP_VERSION_NORMALIZED="${VERSION_INPUT#v}"
APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-$DEFAULT_BUILD_NUMBER}"

mkdir -p "$DIST_DIR" "$HOME/Applications"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

swiftc \
  -O \
  -parse-as-library \
  -framework AppKit \
  "$SWIFT_SRC" \
  -o "$APP_DIR/Contents/MacOS/$APP_NAME"

cp "$INFO_PLIST" "$APP_PLIST"
cp "$ICON_SRC" "$APP_DIR/Contents/Resources/AppIcon.icns"

"$PLIST_BUDDY" -c "Set :CFBundleShortVersionString $APP_VERSION_NORMALIZED" "$APP_PLIST"
"$PLIST_BUDDY" -c "Set :CFBundleVersion $APP_BUILD_NUMBER" "$APP_PLIST"

codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

rm -rf "$INSTALL_DIR"
cp -R "$APP_DIR" "$INSTALL_DIR"

echo "$INSTALL_DIR"

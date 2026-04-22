#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT_NAME="ClaudeCodeMenuBar"
BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$PRODUCT_NAME.app"
APP_PLIST="$APP_DIR/Contents/Info.plist"
BUILD_INFO_PLIST="$APP_DIR/Contents/Resources/BuildInfo.plist"
ZIP_PATH=""
PLIST_BUDDY="/usr/libexec/PlistBuddy"

DEFAULT_VERSION="$("$PLIST_BUDDY" -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Resources/Info.plist")"
DEFAULT_BUILD_NUMBER="$("$PLIST_BUDDY" -c 'Print :CFBundleVersion' "$ROOT_DIR/Resources/Info.plist")"
VERSION_INPUT="${APP_VERSION:-$DEFAULT_VERSION}"
APP_VERSION_NORMALIZED="${VERSION_INPUT#v}"
APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-$DEFAULT_BUILD_NUMBER}"
PACKAGED_AT="${PACKAGED_AT:-$(date '+%Y-%m-%d %H:%M %Z')}"
ARCHIVE_VERSION_LABEL="${ARCHIVE_VERSION_LABEL:-$APP_VERSION_NORMALIZED}"

cd "$ROOT_DIR"
swift build -c release

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/$PRODUCT_NAME" "$APP_DIR/Contents/MacOS/$PRODUCT_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_PLIST"
cp "$ROOT_DIR/Resources/Assets/claude-mascot.png" "$APP_DIR/Contents/Resources/claude-mascot.png"
cp "$ROOT_DIR/Resources/Assets/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

"$PLIST_BUDDY" -c "Set :CFBundleShortVersionString $APP_VERSION_NORMALIZED" "$APP_PLIST"
"$PLIST_BUDDY" -c "Set :CFBundleVersion $APP_BUILD_NUMBER" "$APP_PLIST"

cat > "$BUILD_INFO_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PackagedAt</key>
  <string>${PACKAGED_AT}</string>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

ZIP_PATH="$DIST_DIR/${PRODUCT_NAME}-${ARCHIVE_VERSION_LABEL}.zip"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

echo "Built $APP_DIR"
echo "Version: $APP_VERSION_NORMALIZED ($APP_BUILD_NUMBER)"
echo "Packaged at: $PACKAGED_AT"
echo "Archive: $ZIP_PATH"

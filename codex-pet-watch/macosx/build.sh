#!/bin/sh
set -eu

APP_NAME="CodexPetWatch"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
ZIP_NAME="codex_pet_watch-macosx-x64-v0.20.zip"
ZIP_PATH="$BUILD_DIR/$ZIP_NAME"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_DIR" "$ZIP_PATH"
mkdir -p "$MACOS" "$RESOURCES"

clang -fobjc-arc \
  -mmacosx-version-min=10.13 \
  -framework Cocoa \
  -framework CoreGraphics \
  -o "$MACOS/$APP_NAME" \
  src/main.m

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>CodexPetWatch</string>
  <key>CFBundleIdentifier</key>
  <string>local.codex.CodexPetWatch</string>
  <key>CFBundleName</key>
  <string>CodexPetWatch</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.13</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

if [ -f "../shared/sounds/ringout.wav" ]; then
  cp "../shared/sounds/ringout.wav" "$MACOS/ringout.wav"
fi

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR"
  echo "Ad-hoc signed $APP_DIR"
else
  echo "codesign not found; built unsigned app"
fi

(
  cd "$BUILD_DIR"
  zip -qry -X "$ZIP_NAME" "$APP_NAME.app"
)

echo "Built $APP_DIR"
echo "Packaged $ZIP_PATH"

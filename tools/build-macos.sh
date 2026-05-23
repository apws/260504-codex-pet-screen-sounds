#!/bin/sh
set -eu

APP_NAME="CodexPetWatch"
ZIP_NAME="codex_pet_watch-macosx-x64-v0.50.zip"
INSTALL_MISSING=0

usage() {
  cat <<'EOF'
Usage:
  ./tools/build-macos.sh [--install-missing]

Build the macOS CodexPetWatch.app.

Options:
  --install-missing  Run ./get-tools.sh first when clang is missing.
  --help             Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --install-missing)
      INSTALL_MISSING=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This build helper is for macOS only." >&2
  exit 1
fi

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
MACOS_DIR="$REPO_ROOT/codex-pet-watch/macosx"
SRC_DIR="$MACOS_DIR/src"
SHARED_SOUND="$REPO_ROOT/codex-pet-watch/shared/sounds/ringout.wav"
BUILD_DIR="$MACOS_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
ZIP_PATH="$BUILD_DIR/$ZIP_NAME"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

if ! command -v clang >/dev/null 2>&1; then
  if [ "$INSTALL_MISSING" -eq 1 ]; then
    "$REPO_ROOT/get-tools.sh"
  else
    echo "clang is missing. Install Apple Command Line Tools or run:" >&2
    echo "  ./build.sh --install-missing" >&2
    exit 1
  fi
fi

rm -rf "$APP_DIR" "$ZIP_PATH"
mkdir -p "$MACOS" "$RESOURCES"

clang -fobjc-arc \
  -mmacosx-version-min=10.13 \
  -framework Cocoa \
  -framework CoreGraphics \
  -o "$MACOS/$APP_NAME" \
  "$SRC_DIR/main.m"

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

if [ -f "$SHARED_SOUND" ]; then
  cp "$SHARED_SOUND" "$RESOURCES/ringout.wav"
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

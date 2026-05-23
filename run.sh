#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
APP_NAME="CodexPetWatch"
APP_DIR="$SCRIPT_DIR/codex-pet-watch/macosx/build/$APP_NAME.app"

if [ ! -d "$APP_DIR" ]; then
  echo "Missing $APP_DIR"
  echo "Run ./build.sh first."
  exit 1
fi

osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
open "$APP_DIR"

echo "Launched $APP_DIR"

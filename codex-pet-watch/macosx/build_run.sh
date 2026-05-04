#!/bin/sh
set -eu

APP_NAME="CodexPetWatch"
APP_DIR="build/$APP_NAME.app"

cd "$(dirname "$0")"

./build.sh

osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
open "$APP_DIR"

echo "Launched $APP_DIR"

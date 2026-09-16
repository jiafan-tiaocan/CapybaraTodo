#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_NAME="CapybaraTodo"
EXECUTABLE_NAME="DesktopTodoDaemon"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
SIGN_IDENTITY="${DESKTOP_TODO_SIGN_IDENTITY:--}"

cd "$PROJECT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp ".build/release/$EXECUTABLE_NAME" "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
cp "$PROJECT_DIR/resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/Sources/DesktopTodoDaemon/Resources/capybara-pixel-logo.png" "$APP_DIR/Contents/Resources/capybara-pixel-logo.png"
cp "$PROJECT_DIR/resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
/usr/bin/ditto "$PROJECT_DIR/resources/en.lproj" "$APP_DIR/Contents/Resources/en.lproj"
/usr/bin/ditto "$PROJECT_DIR/resources/zh-Hans.lproj" "$APP_DIR/Contents/Resources/zh-Hans.lproj"

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  codesign --force --deep --sign - "$APP_DIR"
else
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR"
fi
echo "$APP_DIR"

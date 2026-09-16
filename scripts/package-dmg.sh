#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_NAME="CapybaraTodo"
APP_PATH="$PROJECT_DIR/build/$APP_NAME.app"
DIST_DIR="$PROJECT_DIR/dist"
SIGN_IDENTITY="${DESKTOP_TODO_SIGN_IDENTITY:--}"
NOTARY_PROFILE="${DESKTOP_TODO_NOTARY_PROFILE:-}"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/resources/Info.plist")
ARCHITECTURE="$(uname -m)"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION-$ARCHITECTURE-internal.dmg"
STAGING_DIR=$(mktemp -d "${TMPDIR:-/tmp}/desktop-todo-dmg.XXXXXX")

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

DESKTOP_TODO_SIGN_IDENTITY="$SIGN_IDENTITY" "$PROJECT_DIR/scripts/build-app.sh" >/dev/null
mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"

/usr/bin/ditto "$APP_PATH" "$STAGING_DIR/卡皮待办.app"
ln -s /Applications "$STAGING_DIR/Applications"
cp "$PROJECT_DIR/docs/DMG-安装说明.txt" "$STAGING_DIR/安装说明.txt"
cp "$PROJECT_DIR/LICENSE" "$STAGING_DIR/LICENSE.txt"

hdiutil create \
  -volname "卡皮待办 $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -format UDZO \
  -ov \
  "$DMG_PATH" >/dev/null

if [[ "$SIGN_IDENTITY" != "-" ]]; then
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
  if [[ "$SIGN_IDENTITY" == "-" ]]; then
    echo "公证中止：设置 DESKTOP_TODO_NOTARY_PROFILE 时必须同时设置 Developer ID 签名身份。" >&2
    exit 1
  fi
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
fi

hdiutil verify "$DMG_PATH" >/dev/null
shasum -a 256 "$DMG_PATH"

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  echo "已生成内部测试 DMG（临时签名，其他 Mac 仍可能被 Gatekeeper 拦截）："
else
  echo "已生成 Developer ID 签名 DMG："
fi
echo "$DMG_PATH"

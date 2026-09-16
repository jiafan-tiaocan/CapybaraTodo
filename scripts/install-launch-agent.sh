#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
BUILT_APP_PATH="$PROJECT_DIR/build/DesktopTodoDaemon.app"
INSTALL_DIR="${DESKTOP_TODO_INSTALL_DIR:-$HOME/Applications}"
APP_PATH="$INSTALL_DIR/DesktopTodoDaemon.app"
PLIST_PATH="$HOME/Library/LaunchAgents/com.jiafan.desktop-todo-daemon.plist"
EXPECTED_BUNDLE_ID="com.jiafan.desktop-todo-daemon"

"$PROJECT_DIR/scripts/build-app.sh"
mkdir -p "$INSTALL_DIR" "$HOME/Library/LaunchAgents"

if [[ -d "$APP_PATH" ]]; then
  EXISTING_BUNDLE_ID=$(/usr/libexec/PlistBuddy \
    -c 'Print :CFBundleIdentifier' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)
  if [[ "$EXISTING_BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ]]; then
    echo "安装中止：$APP_PATH 已存在，但不是 DesktopTodoDaemon。" >&2
    exit 1
  fi
fi

STAGING_DIR=$(mktemp -d "${TMPDIR:-/tmp}/desktop-todo-install.XXXXXX")
trap 'rm -rf "$STAGING_DIR"' EXIT
/usr/bin/ditto "$BUILT_APP_PATH" "$STAGING_DIR/DesktopTodoDaemon.app"
/usr/bin/codesign --verify --deep --strict "$STAGING_DIR/DesktopTodoDaemon.app"

/usr/bin/sed "s|__APP_PATH__|$APP_PATH|g" \
  "$PROJECT_DIR/resources/com.jiafan.desktop-todo-daemon.plist.template" > "$PLIST_PATH"

launchctl bootout "gui/$(id -u)/com.jiafan.desktop-todo-daemon" 2>/dev/null || true
pkill -f 'DesktopTodoDaemon.app/Contents/MacOS/DesktopTodoDaemon$' 2>/dev/null || true
for _ in {1..50}; do
  if ! launchctl print "gui/$(id -u)/com.jiafan.desktop-todo-daemon" >/dev/null 2>&1 \
      && ! pgrep -f 'DesktopTodoDaemon.app/Contents/MacOS/DesktopTodoDaemon$' >/dev/null; then
    break
  fi
  sleep 0.1
done

if [[ -d "$APP_PATH" ]]; then
  rm -rf "$APP_PATH"
fi
mv "$STAGING_DIR/DesktopTodoDaemon.app" "$APP_PATH"
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"

echo "已安装并启动：$APP_PATH"
echo "LaunchAgent：$PLIST_PATH"

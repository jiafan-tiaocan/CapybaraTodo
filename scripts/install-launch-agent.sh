#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_PATH="$PROJECT_DIR/build/DesktopTodoDaemon.app"
PLIST_PATH="$HOME/Library/LaunchAgents/com.jiafan.desktop-todo-daemon.plist"

"$PROJECT_DIR/scripts/build-app.sh"
mkdir -p "$HOME/Library/LaunchAgents"

/usr/bin/sed "s|__APP_PATH__|$APP_PATH|g" \
  "$PROJECT_DIR/resources/com.jiafan.desktop-todo-daemon.plist.template" > "$PLIST_PATH"

launchctl bootout "gui/$(id -u)/com.jiafan.desktop-todo-daemon" 2>/dev/null || true
for _ in {1..50}; do
  if ! launchctl print "gui/$(id -u)/com.jiafan.desktop-todo-daemon" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"

echo "已安装并启动：$APP_PATH"
echo "LaunchAgent：$PLIST_PATH"

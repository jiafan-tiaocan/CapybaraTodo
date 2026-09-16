#!/bin/zsh
set -euo pipefail

LABEL="com.jiafan.desktop-todo-daemon"
APP_PATH="${DESKTOP_TODO_INSTALL_DIR:-$HOME/Applications}/DesktopTodoDaemon.app"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
FAILED=0

check() {
  local description="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "✓ $description"
  else
    echo "✗ $description"
    FAILED=1
  fi
}

check "已安装应用" test -d "$APP_PATH"
check "应用签名有效" /usr/bin/codesign --verify --deep --strict "$APP_PATH"
check "LaunchAgent 配置存在" test -f "$PLIST_PATH"
check "LaunchAgent 指向稳定安装路径" /usr/bin/grep -Fq "$APP_PATH" "$PLIST_PATH"
check "LaunchAgent 已加载" launchctl print "gui/$(id -u)/$LABEL"
check "应用正在运行" pgrep -f "$APP_PATH/Contents/MacOS/DesktopTodoDaemon"

if (( FAILED )); then
  echo "健康检查未通过，请重新运行 ./install.sh。" >&2
  exit 1
fi

echo "DesktopTodoDaemon 安装与登录自启正常。"

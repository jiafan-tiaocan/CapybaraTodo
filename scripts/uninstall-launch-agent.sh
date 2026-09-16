#!/bin/zsh
set -euo pipefail

LABEL="com.jiafan.desktop-todo-daemon"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
if [[ -f "$PLIST_PATH" ]]; then
  mv "$PLIST_PATH" "$HOME/.Trash/$LABEL.plist"
fi
echo "已停止并移除登录启动项；应用和待办文档未删除。"


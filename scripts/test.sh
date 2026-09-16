#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
CHECK_BINARY="$(mktemp -d)/desktop-todo-self-check"

swiftc \
  "$PROJECT_DIR/Sources/DesktopTodoDaemon/TodoItem.swift" \
  "$PROJECT_DIR/Sources/DesktopTodoDaemon/MarkdownTodoStore.swift" \
  "$PROJECT_DIR/scripts/self-check/main.swift" \
  -o "$CHECK_BINARY"

"$CHECK_BINARY"

WINDOW_SOURCE="$PROJECT_DIR/Sources/DesktopTodoDaemon/DesktopTodoDaemonApp.swift"
if /usr/bin/grep -Eq '\.(canJoinAllSpaces|fullScreenAuxiliary)' "$WINDOW_SOURCE"; then
  echo "全屏空间隔离校验失败：待办窗口不能加入所有 Space 或作为全屏辅助窗口" >&2
  exit 1
fi
echo "全屏空间隔离配置校验通过"

swift build --package-path "$PROJECT_DIR"

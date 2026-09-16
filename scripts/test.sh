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
swift build --package-path "$PROJECT_DIR"


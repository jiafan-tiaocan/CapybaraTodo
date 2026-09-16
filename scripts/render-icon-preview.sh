#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
OUTPUT_PATH="${1:-$PROJECT_DIR/build/capybara-status-icon-preview.png}"
TEMP_DIR="$(mktemp -d)"
RENDER_BINARY="$TEMP_DIR/render-capybara-icon"
mkdir -p "${OUTPUT_PATH:h}"

swiftc \
  "$PROJECT_DIR/Sources/DesktopTodoDaemon/CapybaraStatusIcon.swift" \
  "$PROJECT_DIR/scripts/icon-preview/main.swift" \
  -o "$RENDER_BINARY"

"$RENDER_BINARY" "$OUTPUT_PATH"

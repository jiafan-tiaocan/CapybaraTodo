#!/bin/zsh
set -u

PROJECT_DIR="${0:A:h}"
clear
echo "桌面待办 · 停止并取消登录自启"
echo "待办 Markdown、源码和应用本体都不会被删除。"
echo
"$PROJECT_DIR/scripts/uninstall-launch-agent.sh"
echo
echo "处理完成。按任意键关闭此窗口。"
read -k 1
echo

#!/bin/zsh
set -u

PROJECT_DIR="${0:A:h}"
clear
echo "卡皮待办 · 安装或更新"
echo "应用和待办数据都只保存在这台 Mac。"
echo

if "$PROJECT_DIR/install.sh"; then
  echo
  "$PROJECT_DIR/scripts/doctor.sh"
  echo
  echo "安装完成。右上角菜单栏会出现卡皮巴拉图标。"
  echo "按任意键关闭此窗口。"
else
  status=$?
  echo
  if [[ $status -eq 2 ]]; then
    echo "命令行工具安装完成后，再双击本文件即可。"
  else
    echo "安装没有完成，请保留上面的报错信息。"
  fi
  echo "按任意键关闭此窗口。"
fi

read -k 1
echo

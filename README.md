# DesktopTodoDaemon

macOS 原生桌面待办小窗：半透明、无边框、跨桌面置顶。点击复选圆圈标记完成，状态写入本地 Markdown 文档。

## 功能

- 在普通桌面空间置顶，不进入浏览器等应用的全屏空间，也不显示 Dock 图标
- 菜单栏使用自绘卡皮巴拉模板图标，可显示或隐藏浮窗并查看未完成数量
- 拖动窗口并记住位置
- 输入并回车添加待办
- 点击待办标记完成
- 只点击复选圆圈才会完成，支持即时撤销和从“已完成”列表恢复
- 展开“已完成”时窗口会随内容增高，收起后恢复紧凑高度
- 进行中和已完成事项都可原位编辑或删除；删除后可撤销
- 自动维护 Markdown 的“进行中”和“已完成”两个分区
- 外部编辑 Markdown 后约 0.7 秒内自动刷新
- 每条事项可手动设置 P0–P3；P0 或标题含“高优、重要、紧急、p0”时自动重点高亮
- 时间使用本地时区偏移记录，例如北京时间 `2026-09-16T09:00:00+08:00`
- 可从菜单打开或更换记录文档
- 使用 LaunchAgent 在登录时通过 macOS Launch Services 启动应用；从菜单退出后停到下次登录

默认文档：`~/Desktop/贾凡的知识库/待办事项/桌面待办.md`

设计参考与取舍见 [`docs/open-source-references.md`](docs/open-source-references.md)。仓库约定要求在窗口行为、交互和数据可靠性等设计决策前主动核验优质开源实现。

## 构建与运行

运行无头数据校验并编译：

```bash
./scripts/test.sh
```

```bash
swift run
```

构建 `.app`：

```bash
./scripts/build-app.sh
open build/DesktopTodoDaemon.app
```

安装为登录后自动启动的用户级 daemon：

```bash
./scripts/install-launch-agent.sh
```

停止并取消自动启动：

```bash
./scripts/uninstall-launch-agent.sh
```

卸载脚本不会删除应用、仓库或待办 Markdown 文档。

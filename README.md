# DesktopTodoDaemon

macOS 原生桌面待办小窗：半透明、无边框、跨桌面置顶。点击待办即标记完成，状态写入本地 Markdown 文档。

## 功能

- 常驻桌面置顶，不显示 Dock 图标
- 拖动窗口并记住位置
- 输入并回车添加待办
- 点击待办标记完成
- 只点击复选圆圈才会完成，支持即时撤销和从“已完成”列表恢复
- 自动维护 Markdown 的“进行中”和“已完成”两个分区
- 外部编辑 Markdown 后约 0.7 秒内自动刷新
- 可从菜单打开或更换记录文档
- 使用 LaunchAgent 登录启动、异常退出自动重启；从菜单主动退出后停到下次登录

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

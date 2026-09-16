# DesktopTodoDaemon

macOS 原生桌面待办小窗：半透明、无边框、跨桌面置顶。点击复选圆圈标记完成，状态写入本地 Markdown 文档。

## 功能

- 在普通桌面空间置顶，不进入浏览器等应用的全屏空间，也不显示 Dock 图标
- 菜单栏使用眯眼侧身卡皮巴拉模板图标；待办窗口标题区的全身像素卡皮巴拉会以低频步态持续前走
- 菜单栏用“卡皮巴拉 + 未完成数量”显示固定入口，收起浮窗后可从这里恢复；再次打开“桌面待办”也会恢复浮窗
- 拖动顶部标题栏移动窗口并记住位置；列表区域不会带动整窗
- 长标题自动换行，窗口按列表的真实渲染高度增长，最高可增长到 780 px，超出后改为内部滚动
- 输入并回车添加待办
- 拖拽每条事项最左侧的三横线手柄调整上下顺序；顺序同步到 Markdown 行顺序
- 点击待办标记完成
- 只点击复选圆圈才会完成，支持即时撤销和从“已完成”列表恢复
- 进行中事项可移入折叠的“待重启”分区，之后可恢复到进行中或直接标记完成
- 展开“已完成”时窗口会随内容增高，收起后恢复紧凑高度
- 已完成事项显示本地时区下的创建时间和完成时间，精确到小时
- 进行中、待重启和已完成事项都可原位编辑或删除；删除后可撤销
- 自动维护 Markdown 的“进行中”、“待重启”和“已完成”三个分区
- 外部编辑 Markdown 后约 0.7 秒内自动刷新
- 每条事项可手动设置 P0–P3；P0 或标题含“高优、重要、紧急、p0”时自动重点高亮
- 时间使用本地时区偏移记录，例如北京时间 `2026-09-16T09:00:00+08:00`
- 可从菜单打开或更换记录文档
- 使用 LaunchAgent 在登录时通过 macOS Launch Services 启动应用；从菜单退出后停到下次登录

默认文档：`~/Desktop/贾凡的知识库/待办事项/桌面待办.md`

设计参考与取舍见 [`docs/open-source-references.md`](docs/open-source-references.md)。仓库约定要求在窗口行为、交互和数据可靠性等设计决策前主动核验优质开源实现。

## 一键安装

需要 macOS 14 或更高版本，并已安装 Xcode Command Line Tools。克隆仓库后只需执行：

```bash
./install.sh
```

安装器会完成编译、本地签名、安装和登录自启：

- 应用安装到 `~/Applications/DesktopTodoDaemon.app`，移动或删除源码仓库不会影响运行。
- LaunchAgent 安装到 `~/Library/LaunchAgents/com.jiafan.desktop-todo-daemon.plist`。
- 重复运行同一命令即可安全更新已安装版本。

安装后可执行健康检查：

```bash
./scripts/doctor.sh
```

## 换机与数据迁移

GitHub 仓库只保存应用源码，不上传个人待办数据。换机时：

1. 从 GitHub 克隆仓库，运行 `./install.sh`。
2. 将原 Mac 上的待办 Markdown 文档复制或同步到新 Mac。
3. 从菜单栏卡皮巴拉图标选择“更换记录文档…”，指向该 Markdown 文档。

事项 ID、状态、顺序、优先级、创建时间和完成时间都保存在 Markdown 中；窗口位置和“记录文档路径”是每台 Mac 的本地设置，不会进入 GitHub。

## 开发与验证

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

也可直接调用底层安装脚本：

```bash
./scripts/install-launch-agent.sh
```

停止并取消自动启动：

```bash
./scripts/uninstall-launch-agent.sh
```

卸载脚本不会删除应用、仓库或待办 Markdown 文档。

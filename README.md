# 卡皮待办 / CapybaraTodo

macOS 原生桌面待办小窗：半透明、无边框、跨桌面置顶。中文系统显示“卡皮待办”，英文系统显示“CapybaraTodo”。点击复选圆圈标记完成，状态写入本地 Markdown 文档。

## 功能

- 在所在的普通桌面空间置顶，不进入浏览器等应用的全屏空间；运行时在 Dock 显示卡皮巴拉 App 图标
- 菜单栏使用眯眼侧身卡皮巴拉模板图标；待办窗口标题区的全身像素卡皮巴拉会以低频步态持续前走
- 菜单栏用“卡皮巴拉 + 未完成数量”显示固定入口，收起浮窗后可从这里恢复；再次打开“卡皮待办”也会恢复浮窗
- 拖动顶部标题栏移动窗口并记住位置；列表区域不会带动整窗
- 长标题自动换行，窗口按列表的真实渲染高度增长，最高可增长到 780 px，超出后改为内部滚动
- 输入并回车添加待办
- 拖拽每条事项最左侧的三横线手柄调整上下顺序；顺序同步到 Markdown 行顺序
- 点击待办标记完成
- 只点击复选圆圈才会完成，支持即时撤销和从“已完成”列表恢复；撤销提示 4 秒后自动收起
- 进行中事项可移入折叠的“待重启”分区，之后可恢复到进行中或直接标记完成
- 展开“已完成”时窗口会随内容增高，收起后恢复紧凑高度
- 已完成默认只显示近 7 个自然日，按完成时间倒序；需要时可展开更早记录
- 已完成事项显示本地时区下的创建时间和完成时间，精确到小时
- 进行中、待重启和已完成事项都可原位编辑或删除；删除后可在 4 秒内撤销
- 每条进行中或待重启事项右侧都有“过程”按钮，可直接输入一层过程节点；节点支持单独完成、恢复、编辑和删除
- 自动维护 Markdown 的“进行中”、“待重启”和“已完成”三个分区
- 外部编辑 Markdown 后约 1.5 秒内自动刷新
- 每条事项可手动设置 P0–P3；P0 或标题含“高优、重要、紧急、p0”时自动重点高亮
- 时间使用本地时区偏移记录，例如北京时间 `2026-09-16T09:00:00+08:00`
- 可从菜单打开或更换记录文档
- 可从右上角菜单查看产品名称、版本号和构建号
- 使用 LaunchAgent 在登录时通过 macOS Launch Services 启动应用；从菜单退出后停到下次登录

默认文档：`~/Documents/桌面待办/桌面待办.md`

应用只改写文档中 `desktop-todo:start` 与 `desktop-todo:end` 标记之间的内容。标记之外可以写团队备注或其他 Markdown，应用保存时会原样保留。老版本文档首次保存时会自动迁移为这种结构。

过程节点使用标准 Markdown 缩进复选框，可直接在文件中编辑：

```markdown
- [ ] 发布知识平台
  - [x] 完成技术评审
  - [ ] 核对发布清单
```

设计参考与取舍见 [`docs/open-source-references.md`](docs/open-source-references.md)。仓库约定要求在窗口行为、交互和数据可靠性等设计决策前主动核验优质开源实现。

## 内部安装

需要 macOS 14 或更高版本。推荐把整个源码目录发给同事，让对方双击：

```text
安装卡皮待办.command
```

安装脚本会检查 Apple 命令行开发工具；如果尚未安装，会打开系统安装窗口，完成后再双击一次即可。这样每个人都在自己的 Mac 上编译，不需要传递会被 Gatekeeper 拦截的临时签名 `.app`。

也可以在终端执行：

```bash
./install.sh
```

安装器会完成编译、本地签名、安装和登录自启：

- 应用安装到 `~/Applications/CapybaraTodo.app`，移动或删除源码仓库不会影响运行。
- LaunchAgent 安装到 `~/Library/LaunchAgents/com.jiafan.desktop-todo-daemon.plist`。
- 重复运行同一命令即可安全更新已安装版本。
- 源码保留在原目录，可直接修改；修改后再次双击安装入口即可重新编译和更新。

安装后可执行健康检查：

```bash
./scripts/doctor.sh
```

### DMG 分发

生成当前 Mac 架构的 DMG：

```bash
./scripts/package-dmg.sh
```

产物位于 `dist/`。DMG 内包含应用、Applications 快捷方式和安装说明。

临时签名 DMG 适合本机验收，但从网络传到其他 Mac 后仍可能被 Gatekeeper 拦截。真正面向同事直接安装时，需要 Developer ID 签名并经 Apple 公证：

```bash
DESKTOP_TODO_SIGN_IDENTITY="Developer ID Application: 姓名或组织 (TEAMID)" \
DESKTOP_TODO_NOTARY_PROFILE="notary-profile" \
./scripts/package-dmg.sh
```

脚本会提交公证、等待结果并把票据装订到 DMG。没有分发证书时，继续使用前面的源码安装方式。

## 换机与数据迁移

GitHub 仓库只保存应用源码，不上传个人待办数据。换机时：

1. 从 GitHub 克隆仓库，运行 `./install.sh`。
2. 将原 Mac 上的待办 Markdown 文档复制或同步到新 Mac。
3. 从菜单栏卡皮巴拉图标选择“更换记录文档…”，指向该 Markdown 文档。

事项 ID、状态、顺序、优先级、过程节点、创建时间和完成时间都保存在 Markdown 中；窗口位置和“记录文档路径”是每台 Mac 的本地设置，不会进入 GitHub。

## 开发与验证

运行无头数据校验并编译：

```bash
./scripts/test.sh
```

```bash
swift run
```

主要代码入口：

- `TodoView.swift`：待办、过程节点和编辑交互
- `TodoModel.swift`：状态变化、撤销和文档刷新
- `MarkdownTodoStore.swift`：Markdown 解析、无损保存和时间元数据
- `DesktopTodoDaemonApp.swift`：浮窗、菜单栏和显示隐藏行为
- `scripts/self-check/main.swift`：不依赖 UI 的数据回归校验

构建 `.app`：

```bash
./scripts/build-app.sh
open build/CapybaraTodo.app
```

也可直接调用底层安装脚本：

```bash
./scripts/install-launch-agent.sh
```

停止并取消自动启动，可双击 `卸载卡皮待办.command`，也可以执行：

```bash
./scripts/uninstall-launch-agent.sh
```

卸载脚本不会删除应用、仓库或待办 Markdown 文档。

## 内部分享说明

- 当前仓库适合通过 GitHub 私有仓库邀请成员，或直接发送完整源码压缩包。
- 没有 Developer ID 时不要只发送 `build/CapybaraTodo.app` 或临时签名 DMG：下载到另一台 Mac 后可能被 Gatekeeper 阻止。
- 项目采用 MIT License，同事可以保留来源后修改和再分发。

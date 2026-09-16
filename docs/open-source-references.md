# 开源项目参考

调研日期：2026-09-16。这里只记录会影响本项目设计的做法；是否采用以本项目“桌面置顶 + 本地 Markdown 记录”的目标为准。

| 项目 | 可验证做法 | 本项目判断 |
|---|---|---|
| [Flodo](https://github.com/michellemayes/flodo) | 无边框、置顶、任意非控件区域可拖动；维持单列表的克制范围 | 采用无边框置顶与拖动；按实际需求加入四级优先级，但仍不引入标签和项目层级 |
| [TodoPop](https://github.com/shakee93/todopop) | SwiftUI + SwiftPM、无第三方依赖；业务逻辑与 UI 分离并做无头测试；完成历史保留 | 采用 SwiftPM、零依赖、独立 Markdown store 与往返测试 |
| [Boost Timer](https://github.com/awens84/timer) | `NSPanel`、`.floating`、`hidesOnDeactivate = false` 与 SwiftUI material 实现半透明常驻窗 | 采用同类原生窗口组合；窗口保持可交互，不做默认点击穿透 |
| [Reinschrift](https://github.com/danst0/ReinschriftTodo) | Markdown checkbox 是主数据，可由普通编辑器读取和修改 | 采用 Markdown 作为唯一持久化文档；追加稳定 ID 和时间元数据以避免丢失历史 |
| [TodoPop](https://github.com/shakee93/todopop) | 外部文件变更通过内容差异去重，避免应用自己的写入触发无效刷新；对瞬时空文件有数据丢失保护；项目记录了 Swift 6 下文件监听闭包的隔离陷阱 | 采用内容级快照比较和瞬时空文件保护；每次应用内变更前先吸收外部修改。本项目只有单个本地文件，因此用低频轮询代替更复杂的目录 DispatchSource |
| [Docket](https://github.com/santoru/docket) / [Quiet Tasks](https://github.com/rakeshutekar/quiet-tasks) / [EasyTODO](https://github.com/ArabelaTso/easytodo-on-macos) | 完成和删除提供 undo，Done 视图允许恢复，事项支持原位编辑 | 同时提供完成撤销、删除撤销和折叠的“已完成”恢复区；进行中与已完成事项均可原位编辑和删除 |
| [tado](https://github.com/Entrepenulian/tado) / [TodoPop](https://github.com/shakee93/todopop) | 用系统菜单栏场景管理常驻应用，应用不占 Dock | 采用 AppKit 原生 `NSStatusItem` 并由 AppDelegate 长期持有，避免后台重启时入口注册不稳定；菜单负责显示/隐藏浮窗、显示未完成数量、打开记录和退出 |
| [EasyTODO](https://github.com/ArabelaTso/easytodo-on-macos) | 用细色条和少量颜色表达优先级，桌面组件保持安静 | P0/关键词高亮使用暖红细条、低透明底色和小标签；P1–P3 只显示彩色胶囊，避免整行强色块 |
| [Planify](https://github.com/alainm23/planify) | 用原生拖放手势调整任务和分区顺序 | 只在进行中事项左侧提供独立拖拽手柄，不让整行可拖，避免与完成、选中文字和菜单交互冲突；以 Markdown 行顺序持久化 |
| [Taskwarrior](https://taskwarrior.org/docs/terminology/) / [Vikunja](https://vikunja.io/help/views/) | Taskwarrior 将 waiting 建模为与 pending/completed 并列的状态，Vikunja 允许独立工作流分区折叠 | 将“待重启”建模为独立状态和 Markdown 分区，默认折叠以保持主列表聚焦，不用标签或完成状态模拟 |
| [tic](https://github.com/kasvith/tic) | 悬停任务后在该行下方出现新增子任务入口，点击后直接原位输入；空输入离开时自动退出 | 本项目不依赖悬停才能发现功能，改为在进行中与待重启事项右侧常驻紧凑“过程”按钮，点击后在事项下方原位输入并自动聚焦 |
| [TodoPop](https://github.com/shakee93/todopop) | 用 SwiftPM、零依赖、源码构建和 Release 压缩包同时覆盖开发者与普通用户，并明确 Command Line Tools 是最低构建依赖 | 内部阶段保留 SwiftPM 源码构建，增加可双击安装入口和依赖检测；不直接分发临时签名 `.app`，公开分发再补 Developer ID 与公证 |

## 全屏空间行为

[Apple 的 `NSWindow.CollectionBehavior` 文档](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct)明确区分了两件事：`canJoinAllSpaces` 会让窗口出现在所有 Space；`fullScreenNone` 只表示窗口自身不支持全屏。多个悬浮层项目会组合 `canJoinAllSpaces` 与 `fullScreenAuxiliary` 来主动覆盖别的应用全屏，本项目的目标相反，因此不使用 `canJoinAllSpaces`，只保留 `stationary`、`fullScreenNone` 和 `fullScreenDisallowsTiling`。这样待办停留在所在的普通桌面 Space，切换到浏览器等应用的全屏 Space 时不会覆盖其内容；菜单栏入口仍然常驻。

后续重点核验：外部编辑与应用内操作同时发生时的冲突提示、辅助功能与键盘操作。

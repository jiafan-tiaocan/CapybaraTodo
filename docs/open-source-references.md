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
| [tado](https://github.com/Entrepenulian/tado) / [TodoPop](https://github.com/shakee93/todopop) | 用系统菜单栏场景管理常驻应用，应用不占 Dock | 采用原生 `MenuBarExtra`；菜单负责显示/隐藏浮窗、显示未完成数量、打开记录和退出，不复制一套待办界面 |
| [EasyTODO](https://github.com/ArabelaTso/easytodo-on-macos) | 用细色条和少量颜色表达优先级，桌面组件保持安静 | P0/关键词高亮使用暖红细条、低透明底色和小标签；P1–P3 只显示彩色胶囊，避免整行强色块 |

## 全屏空间行为

AppKit 的 `fullScreenAuxiliary` 明确表示窗口可与其他应用的全屏窗口显示在同一空间；多个悬浮层项目也用它实现“覆盖全屏”。本项目的目标相反，因此只保留 `canJoinAllSpaces` 和 `stationary` 以覆盖普通桌面空间，并使用 `fullScreenNone` 明确不参与全屏。菜单栏入口仍可用于手动显示或隐藏待办。

后续重点核验：外部编辑与应用内操作同时发生时的冲突提示、辅助功能与键盘操作。

# 开源项目参考

调研日期：2026-09-16。这里只记录会影响本项目设计的做法；是否采用以本项目“桌面置顶 + 本地 Markdown 记录”的目标为准。

| 项目 | 可验证做法 | 本项目判断 |
|---|---|---|
| [Flodo](https://github.com/michellemayes/flodo) | 无边框、置顶、任意非控件区域可拖动；维持单列表的克制范围 | 采用无边框置顶与拖动；暂不引入标签、优先级、项目等层级 |
| [TodoPop](https://github.com/shakee93/todopop) | SwiftUI + SwiftPM、无第三方依赖；业务逻辑与 UI 分离并做无头测试；完成历史保留 | 采用 SwiftPM、零依赖、独立 Markdown store 与往返测试 |
| [Boost Timer](https://github.com/awens84/timer) | `NSPanel`、`.floating`、`hidesOnDeactivate = false` 与 SwiftUI material 实现半透明常驻窗 | 采用同类原生窗口组合；窗口保持可交互，不做默认点击穿透 |
| [Reinschrift](https://github.com/danst0/ReinschriftTodo) | Markdown checkbox 是主数据，可由普通编辑器读取和修改 | 采用 Markdown 作为唯一持久化文档；追加稳定 ID 和时间元数据以避免丢失历史 |
| [TodoPop](https://github.com/shakee93/todopop) | 外部文件变更通过内容差异去重，避免应用自己的写入触发无效刷新；对瞬时空文件有数据丢失保护；项目记录了 Swift 6 下文件监听闭包的隔离陷阱 | 采用内容级快照比较和瞬时空文件保护；每次应用内变更前先吸收外部修改。本项目只有单个本地文件，因此用低频轮询代替更复杂的目录 DispatchSource |
| [Docket](https://github.com/santoru/docket) / [Quiet Tasks](https://github.com/rakeshutekar/quiet-tasks) | 完成后提供 undo toast，并允许从 Done 视图恢复 | 同时提供即时“撤销”和折叠的“已完成”恢复区；完成动作只绑定复选圆圈，减少误触 |

后续重点核验：外部编辑与应用内操作同时发生时的冲突提示、辅助功能与键盘操作。

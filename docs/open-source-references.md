# 开源项目参考

调研日期：2026-09-16。这里只记录会影响本项目设计的做法；是否采用以本项目“桌面置顶 + 本地 Markdown 记录”的目标为准。

| 项目 | 可验证做法 | 本项目判断 |
|---|---|---|
| [Flodo](https://github.com/michellemayes/flodo) | 无边框、置顶、任意非控件区域可拖动；维持单列表的克制范围 | 采用无边框置顶与拖动；暂不引入标签、优先级、项目等层级 |
| [TodoPop](https://github.com/shakee93/todopop) | SwiftUI + SwiftPM、无第三方依赖；业务逻辑与 UI 分离并做无头测试；完成历史保留 | 采用 SwiftPM、零依赖、独立 Markdown store 与往返测试 |
| [Boost Timer](https://github.com/awens84/timer) | `NSPanel`、`.floating`、`hidesOnDeactivate = false` 与 SwiftUI material 实现半透明常驻窗 | 采用同类原生窗口组合；窗口保持可交互，不做默认点击穿透 |
| [Reinschrift](https://github.com/danst0/ReinschriftTodo) | Markdown checkbox 是主数据，可由普通编辑器读取和修改 | 采用 Markdown 作为唯一持久化文档；追加稳定 ID 和时间元数据以避免丢失历史 |

后续重点核验：外部编辑文件后的实时刷新、防止并发覆盖、撤销误完成、辅助功能与键盘操作。


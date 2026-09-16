import Foundation

let url = FileManager.default.temporaryDirectory
    .appending(path: "desktop-todo-\(UUID().uuidString).md")
defer { try? FileManager.default.removeItem(at: url) }

let active = TodoItem(
    title: "核对重要方案",
    createdAt: Date(timeIntervalSince1970: 1_700_000_000),
    priority: .p0,
    checkpoints: [
        TodoCheckpoint(
            title: "完成技术评审",
            createdAt: Date(timeIntervalSince1970: 1_700_000_010),
            completedAt: Date(timeIntervalSince1970: 1_700_000_020)
        ),
        TodoCheckpoint(
            title: "核对发布清单",
            createdAt: Date(timeIntervalSince1970: 1_700_000_030)
        )
    ]
)
let done = TodoItem(
    title: "完成原型",
    createdAt: Date(timeIntervalSince1970: 1_700_000_100),
    completedAt: Date(timeIntervalSince1970: 1_700_000_200)
)
let pendingRestart = TodoItem(
    title: "重启后复核服务",
    createdAt: Date(timeIntervalSince1970: 1_700_000_150),
    status: .pendingRestart
)
let store = MarkdownTodoStore()
try store.save([active, pendingRestart, done], to: url)
let savedDocument = try String(contentsOf: url, encoding: .utf8)
let loaded = try store.load(from: url)

guard loaded.count == 3 else {
    fatalError("期望 3 项，实际为 \(loaded.count) 项")
}
guard loaded.first(where: { $0.id == active.id })?.completedAt == nil else {
    fatalError("进行中事项状态未保留")
}
guard loaded.first(where: { $0.id == active.id })?.priority == .p0 else {
    fatalError("优先级未保留")
}
guard loaded.first(where: { $0.id == active.id })?.checkpoints.count == 2,
      loaded.first(where: { $0.id == active.id })?.checkpoints[0].isCompleted == true,
      loaded.first(where: { $0.id == active.id })?.checkpoints[1].isCompleted == false,
      savedDocument.contains("  - [x] 完成技术评审") else {
    fatalError("过程节点往返持久化失败")
}
guard loaded.first(where: { $0.id == done.id })?.completedAt != nil else {
    fatalError("已完成事项状态未保留")
}
guard loaded.first(where: { $0.id == pendingRestart.id })?.status == .pendingRestart,
      savedDocument.contains("## 待重启") else {
    fatalError("待重启事项状态未保留")
}
let offsetSeconds = TimeZone.current.secondsFromGMT(for: active.createdAt)
let sign = offsetSeconds >= 0 ? "+" : "-"
let absoluteOffset = abs(offsetSeconds)
let expectedOffset = String(
    format: "%@%02d:%02d",
    sign,
    absoluteOffset / 3_600,
    (absoluteOffset % 3_600) / 60
)
guard savedDocument.contains(expectedOffset) else {
    fatalError("时间未使用本地时区偏移：期望 \(expectedOffset)")
}

print("Markdown 往返校验通过")
print("过程节点层级与状态校验通过")

let externalContent = """
# 桌面待办

## 进行中

- [ ] 外部新增一
  - [x] 需求对齐
  - [ ] 技术评审
- [ ] 外部新增二

## 待重启

- [ ] 等待重启复核

## 已完成

- [x] 可恢复事项
"""
let externalItems = store.load(content: externalContent)
guard externalItems.count == 4,
      externalItems.filter({ $0.status == .active }).count == 2,
      externalItems.filter({ $0.status == .pendingRestart }).count == 1,
      externalItems.filter({ $0.status == .completed }).count == 1,
      externalItems[0].checkpoints.map(\.title) == ["需求对齐", "技术评审"],
      externalItems[0].checkpoints[0].isCompleted else {
    fatalError("外部 Markdown 内容解析失败")
}

var restored = externalItems
restored[3].completedAt = nil
restored[3].status = .active
try store.save(restored, to: url)
let restoredItems = try store.load(from: url)
guard restoredItems.filter({ $0.status == .completed }).isEmpty else {
    fatalError("已完成事项恢复后状态未保留")
}

print("外部编辑与恢复校验通过")

guard TodoItem(title: "P0 修复发布故障").needsHighPriorityHighlight,
      TodoItem(title: "这是重要事项").needsHighPriorityHighlight,
      TodoItem(title: "普通事项", priority: .p0).needsHighPriorityHighlight,
      !TodoItem(title: "普通事项", priority: .p1).needsHighPriorityHighlight else {
    fatalError("高优先级自动高亮判定失败")
}

print("优先级持久化与自动高亮校验通过")

var editedAndDeleted = loaded.filter { $0.status != .pendingRestart }
editedAndDeleted[0].title = "已修改的重要方案"
editedAndDeleted.removeAll { $0.id == done.id }
try store.save(editedAndDeleted, to: url)
let mutationResult = try store.load(from: url)
guard mutationResult.count == 1,
      mutationResult[0].title == "已修改的重要方案",
      mutationResult[0].priority == .p0 else {
    fatalError("编辑或删除后的 Markdown 持久化失败")
}

print("编辑与删除持久化校验通过")

let earlier = TodoItem(
    title: "较早创建但排在后面",
    createdAt: Date(timeIntervalSince1970: 1_600_000_000)
)
let later = TodoItem(
    title: "较晚创建但排在前面",
    createdAt: Date(timeIntervalSince1970: 1_800_000_000)
)
try store.save([later, earlier], to: url)
let reorderedResult = try store.load(from: url)
guard reorderedResult.map(\.id) == [later.id, earlier.id] else {
    fatalError("进行中事项的相对顺序未持久化")
}

print("拖拽顺序持久化校验通过")

let manualPendingRestart = store.load(content: """
# 桌面待办

## 待重启

- [ ] 手动移入待重启
""")
guard manualPendingRestart.count == 1,
      manualPendingRestart[0].status == .pendingRestart,
      manualPendingRestart[0].completedAt == nil else {
    fatalError("手动编辑待重启分区解析失败")
}

print("待重启分区校验通过")

let mixedDocument = """
# 桌面待办

## 进行中

- [ ] 旧待办

## 已完成

## 团队备注

这段说明必须由应用保留。
- [ ] 这不是桌面待办的数据
"""
try mixedDocument.write(to: url, atomically: true, encoding: .utf8)
let mixedItems = store.load(content: mixedDocument)
guard mixedItems.count == 1, mixedItems[0].title == "旧待办" else {
    fatalError("自定义 Markdown 标题下的复选框被误识别为应用待办")
}
try store.save(mixedItems, to: url)
let preservedDocument = try String(contentsOf: url, encoding: .utf8)
let preservedItems = try store.load(from: url)
guard preservedDocument.contains("<!-- desktop-todo:start -->"),
      preservedDocument.contains("<!-- desktop-todo:end -->"),
      preservedDocument.contains("## 团队备注"),
      preservedDocument.contains("这段说明必须由应用保留。"),
      preservedDocument.contains("- [ ] 这不是桌面待办的数据"),
      preservedItems.count == 1,
      preservedItems[0].title == "旧待办" else {
    fatalError("应用写入时未正确隔离或保留用户自定义 Markdown 内容")
}

try store.save(preservedItems, to: url)
let secondSave = try String(contentsOf: url, encoding: .utf8)
guard secondSave.components(separatedBy: "<!-- desktop-todo:start -->").count == 2 else {
    fatalError("重复保存生成了多个应用管理区")
}

guard MarkdownTodoStore.defaultDocumentURL.path.contains("/Documents/桌面待办/"),
      !MarkdownTodoStore.defaultDocumentURL.path.contains("贾凡") else {
    fatalError("默认文档路径不是可迁移的用户通用路径")
}

print("自定义 Markdown 内容保留与通用默认路径校验通过")

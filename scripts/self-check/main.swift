import Foundation

let url = FileManager.default.temporaryDirectory
    .appending(path: "desktop-todo-\(UUID().uuidString).md")
defer { try? FileManager.default.removeItem(at: url) }

let active = TodoItem(
    title: "核对重要方案",
    createdAt: Date(timeIntervalSince1970: 1_700_000_000),
    priority: .p0
)
let done = TodoItem(
    title: "完成原型",
    createdAt: Date(timeIntervalSince1970: 1_700_000_100),
    completedAt: Date(timeIntervalSince1970: 1_700_000_200)
)
let store = MarkdownTodoStore()
try store.save([active, done], to: url)
let savedDocument = try String(contentsOf: url, encoding: .utf8)
let loaded = try store.load(from: url)

guard loaded.count == 2 else {
    fatalError("期望 2 项，实际为 \(loaded.count) 项")
}
guard loaded.first(where: { $0.id == active.id })?.completedAt == nil else {
    fatalError("进行中事项状态未保留")
}
guard loaded.first(where: { $0.id == active.id })?.priority == .p0 else {
    fatalError("优先级未保留")
}
guard loaded.first(where: { $0.id == done.id })?.completedAt != nil else {
    fatalError("已完成事项状态未保留")
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

let externalContent = """
# 桌面待办

## 进行中

- [ ] 外部新增一
- [ ] 外部新增二

## 已完成

- [x] 可恢复事项
"""
let externalItems = store.load(content: externalContent)
guard externalItems.count == 3,
      externalItems.filter({ $0.completedAt == nil }).count == 2,
      externalItems.filter({ $0.completedAt != nil }).count == 1 else {
    fatalError("外部 Markdown 内容解析失败")
}

var restored = externalItems
restored[2].completedAt = nil
try store.save(restored, to: url)
let restoredItems = try store.load(from: url)
guard restoredItems.allSatisfy({ $0.completedAt == nil }) else {
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

var editedAndDeleted = loaded
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

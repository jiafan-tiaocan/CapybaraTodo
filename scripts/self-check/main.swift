import Foundation

let url = FileManager.default.temporaryDirectory
    .appending(path: "desktop-todo-\(UUID().uuidString).md")
defer { try? FileManager.default.removeItem(at: url) }

let active = TodoItem(title: "核对方案", createdAt: Date(timeIntervalSince1970: 1_700_000_000))
let done = TodoItem(
    title: "完成原型",
    createdAt: Date(timeIntervalSince1970: 1_700_000_100),
    completedAt: Date(timeIntervalSince1970: 1_700_000_200)
)
let store = MarkdownTodoStore()
try store.save([active, done], to: url)
let loaded = try store.load(from: url)

guard loaded.count == 2 else {
    fatalError("期望 2 项，实际为 \(loaded.count) 项")
}
guard loaded.first(where: { $0.id == active.id })?.completedAt == nil else {
    fatalError("进行中事项状态未保留")
}
guard loaded.first(where: { $0.id == done.id })?.completedAt != nil else {
    fatalError("已完成事项状态未保留")
}

print("Markdown 往返校验通过")


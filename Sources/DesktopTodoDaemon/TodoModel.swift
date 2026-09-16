import AppKit
import Foundation

@MainActor
final class TodoModel: ObservableObject {
    @Published private(set) var items: [TodoItem] = []
    @Published var errorMessage: String?
    @Published var documentURL: URL
    @Published private(set) var lastCompletedItemID: UUID?
    @Published private(set) var lastDeletedItem: TodoItem?

    private let store = MarkdownTodoStore()
    private let documentPathKey = "todoDocumentPath"
    private var lastKnownDocumentData: Data?
    private var lastCompletionOrigin: TodoStatus?

    init() {
        if let savedPath = UserDefaults.standard.string(forKey: documentPathKey), !savedPath.isEmpty {
            documentURL = URL(fileURLWithPath: savedPath)
        } else {
            documentURL = MarkdownTodoStore.defaultDocumentURL
        }
        reload()
    }

    var activeItems: [TodoItem] {
        items.filter { $0.status == .active }
    }

    var pendingRestartItems: [TodoItem] {
        items.filter { $0.status == .pendingRestart }
    }

    var pendingRestartCount: Int {
        pendingRestartItems.count
    }

    var completedCount: Int {
        items.lazy.filter { $0.status == .completed }.count
    }

    var completedItems: [TodoItem] {
        items.filter { $0.status == .completed }.sorted {
            ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
        }
    }

    var canUndoLastCompletion: Bool {
        guard let id = lastCompletedItemID else { return false }
        return items.contains { $0.id == id && $0.status == .completed }
    }

    var canUndoLastDelete: Bool {
        guard let item = lastDeletedItem else { return false }
        return !items.contains { $0.id == item.id }
    }

    func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        reloadIfChanged()
        items.append(TodoItem(title: trimmed))
        persist()
    }

    func complete(_ item: TodoItem) {
        reloadIfChanged()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        lastCompletionOrigin = items[index].status
        items[index].status = .completed
        items[index].completedAt = .now
        lastCompletedItemID = item.id
        persist()
    }

    func restore(_ item: TodoItem) {
        reloadIfChanged()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].status = .active
        items[index].completedAt = nil
        if lastCompletedItemID == item.id {
            lastCompletedItemID = nil
            lastCompletionOrigin = nil
        }
        persist()
    }

    func undoLastCompletion() {
        guard let id = lastCompletedItemID,
              let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].status = lastCompletionOrigin ?? .active
        items[index].completedAt = nil
        lastCompletedItemID = nil
        lastCompletionOrigin = nil
        persist()
    }

    func moveToPendingRestart(_ item: TodoItem) {
        changeStatus(of: item, to: .pendingRestart)
    }

    func moveToActive(_ item: TodoItem) {
        changeStatus(of: item, to: .active)
    }

    func setPriority(_ priority: TodoPriority, for item: TodoItem) {
        reloadIfChanged()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].priority = priority
        persist()
    }

    func reorderActiveItem(_ draggedID: UUID, relativeTo targetID: UUID) {
        guard draggedID != targetID else { return }
        reloadIfChanged()

        var active = activeItems
        guard let sourceIndex = active.firstIndex(where: { $0.id == draggedID }),
              let targetIndex = active.firstIndex(where: { $0.id == targetID }) else { return }

        let movedItem = active.remove(at: sourceIndex)
        active.insert(movedItem, at: min(targetIndex, active.endIndex))
        items = active + items.filter { $0.status != .active }
        persist()
    }

    func rename(_ item: TodoItem, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        reloadIfChanged()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].title = trimmed
        persist()
    }

    func delete(_ item: TodoItem) {
        reloadIfChanged()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let deleted = items.remove(at: index)
        lastDeletedItem = deleted
        if lastCompletedItemID == deleted.id {
            lastCompletedItemID = nil
            lastCompletionOrigin = nil
        }
        persist()
    }

    func undoLastDelete() {
        reloadIfChanged()
        guard let deleted = lastDeletedItem,
              !items.contains(where: { $0.id == deleted.id }) else { return }
        items.append(deleted)
        lastDeletedItem = nil
        persist()
    }

    func reload() {
        do {
            items = try store.load(from: documentURL)
            if !FileManager.default.fileExists(atPath: documentURL.path) {
                try store.save(items, to: documentURL)
            }
            lastKnownDocumentData = try Data(contentsOf: documentURL)
            errorMessage = nil
        } catch {
            errorMessage = "读取失败：\(error.localizedDescription)"
        }
    }

    func reloadIfChanged() {
        do {
            let data = try Data(contentsOf: documentURL)
            guard data != lastKnownDocumentData else { return }
            guard !data.isEmpty || items.isEmpty else { return }
            guard let content = String(data: data, encoding: .utf8) else {
                errorMessage = "读取失败：Markdown 不是 UTF-8 编码"
                return
            }
            items = store.load(content: content)
            lastKnownDocumentData = data
            if !canUndoLastCompletion {
                lastCompletedItemID = nil
                lastCompletionOrigin = nil
            }
            if !canUndoLastDelete {
                lastDeletedItem = nil
            }
            errorMessage = nil
        } catch {
            errorMessage = "读取失败：\(error.localizedDescription)"
        }
    }

    func chooseDocument() {
        let panel = NSSavePanel()
        panel.title = "选择待办 Markdown 文档"
        panel.nameFieldStringValue = documentURL.lastPathComponent
        panel.directoryURL = documentURL.deletingLastPathComponent()
        panel.allowedContentTypes = [.init(filenameExtension: "md")!]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        documentURL = url
        UserDefaults.standard.set(url.path, forKey: documentPathKey)
        reload()
    }

    func openDocument() {
        NSWorkspace.shared.open(documentURL)
    }

    private func persist() {
        do {
            try store.save(items, to: documentURL)
            lastKnownDocumentData = try Data(contentsOf: documentURL)
            errorMessage = nil
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    private func changeStatus(of item: TodoItem, to status: TodoStatus) {
        reloadIfChanged()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].status = status
        items[index].completedAt = status == .completed ? (items[index].completedAt ?? .now) : nil
        if lastCompletedItemID == item.id, status != .completed {
            lastCompletedItemID = nil
            lastCompletionOrigin = nil
        }
        persist()
    }
}

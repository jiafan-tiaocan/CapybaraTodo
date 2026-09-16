import AppKit
import Foundation

@MainActor
final class TodoModel: ObservableObject {
    @Published private(set) var items: [TodoItem] = []
    @Published var errorMessage: String?
    @Published var documentURL: URL
    @Published private(set) var lastCompletedItemID: UUID?

    private let store = MarkdownTodoStore()
    private let documentPathKey = "todoDocumentPath"
    private var lastKnownDocumentData: Data?

    init() {
        if let savedPath = UserDefaults.standard.string(forKey: documentPathKey), !savedPath.isEmpty {
            documentURL = URL(fileURLWithPath: savedPath)
        } else {
            documentURL = MarkdownTodoStore.defaultDocumentURL
        }
        reload()
    }

    var activeItems: [TodoItem] {
        items.filter { $0.completedAt == nil }
    }

    var completedCount: Int {
        items.lazy.filter { $0.completedAt != nil }.count
    }

    var completedItems: [TodoItem] {
        items.filter { $0.completedAt != nil }.sorted {
            ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
        }
    }

    var canUndoLastCompletion: Bool {
        guard let id = lastCompletedItemID else { return false }
        return items.contains { $0.id == id && $0.completedAt != nil }
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
        items[index].completedAt = .now
        lastCompletedItemID = item.id
        persist()
    }

    func restore(_ item: TodoItem) {
        reloadIfChanged()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].completedAt = nil
        if lastCompletedItemID == item.id {
            lastCompletedItemID = nil
        }
        persist()
    }

    func undoLastCompletion() {
        guard let id = lastCompletedItemID,
              let item = items.first(where: { $0.id == id }) else { return }
        restore(item)
    }

    func setPriority(_ priority: TodoPriority, for item: TodoItem) {
        reloadIfChanged()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].priority = priority
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
}

import AppKit
import Foundation

@MainActor
final class TodoModel: ObservableObject {
    @Published private(set) var items: [TodoItem] = []
    @Published var errorMessage: String?
    @Published var documentURL: URL

    private let store = MarkdownTodoStore()
    private let documentPathKey = "todoDocumentPath"

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

    func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(TodoItem(title: trimmed))
        persist()
    }

    func complete(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].completedAt = .now
        persist()
    }

    func reload() {
        do {
            items = try store.load(from: documentURL)
            if !FileManager.default.fileExists(atPath: documentURL.path) {
                try store.save(items, to: documentURL)
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
            errorMessage = nil
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }
}


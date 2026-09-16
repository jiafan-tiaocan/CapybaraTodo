import Foundation

struct MarkdownTodoStore {
    static let defaultDocumentURL = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: "Desktop/贾凡的知识库/待办事项/桌面待办.md")

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = .current
        return formatter
    }()

    func load(from url: URL) throws -> [TodoItem] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let content = try String(contentsOf: url, encoding: .utf8)
        return load(content: content)
    }

    func load(content: String) -> [TodoItem] {
        var items: [TodoItem] = []
        var section = TodoStatus.active

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line == "## 进行中" {
                section = .active
                continue
            }
            if line == "## 待重启" {
                section = .pendingRestart
                continue
            }
            if line == "## 已完成" {
                section = .completed
                continue
            }
            if line.hasPrefix("## ") {
                section = .active
                continue
            }
            guard line.hasPrefix("- [") else { continue }
            if let item = parse(line: line, section: section) {
                items.append(item)
            }
        }
        return items
    }

    func save(_ items: [TodoItem], to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let active = items.filter { $0.status == .active }
        let pendingRestart = items.filter { $0.status == .pendingRestart }
        let completed = items.filter { $0.status == .completed }.sorted {
            ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
        }

        var lines = [
            "# 桌面待办",
            "",
            "> 本文件由 DesktopTodoDaemon 维护，也可直接编辑。时间采用带本地时区偏移的 ISO 8601 格式。",
            "",
            "## 进行中",
            ""
        ]
        lines.append(contentsOf: active.map(activeLine))
        if active.isEmpty { lines.append("_暂无_" ) }
        lines += ["", "## 待重启", ""]
        lines.append(contentsOf: pendingRestart.map(activeLine))
        if pendingRestart.isEmpty { lines.append("_暂无_" ) }
        lines += ["", "## 已完成", ""]
        lines.append(contentsOf: completed.map(completedLine))
        if completed.isEmpty { lines.append("_暂无_" ) }
        lines.append("")

        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    private func activeLine(_ item: TodoItem) -> String {
        "- [ ] \(sanitize(item.title)) \(metadata(for: item))"
    }

    private func completedLine(_ item: TodoItem) -> String {
        let completed = dateFormatter.string(from: item.completedAt ?? .now)
        return "- [x] \(sanitize(item.title)) — 完成于 \(completed) \(metadata(for: item))"
    }

    private func metadata(for item: TodoItem) -> String {
        var fields = [
            "id:\(item.id.uuidString)",
            "created:\(dateFormatter.string(from: item.createdAt))"
        ]
        if item.priority != .none {
            fields.append("priority:\(item.priority.rawValue)")
        }
        return "<!-- \(fields.joined(separator: " ")) -->"
    }

    private func parse(line: String, section: TodoStatus) -> TodoItem? {
        let checked = line.hasPrefix("- [x]") || line.hasPrefix("- [X]") || section == .completed
        let status: TodoStatus = checked ? .completed : section
        let markerEnd = line.index(line.startIndex, offsetBy: 5)
        var body = String(line[markerEnd...]).trimmingCharacters(in: .whitespaces)

        var id = UUID()
        var createdAt = Date()
        var priority = TodoPriority.none
        if let metadataStart = body.range(of: "<!--"), let metadataEnd = body.range(of: "-->") {
            let metadata = String(body[metadataStart.upperBound..<metadataEnd.lowerBound])
            for token in metadata.split(separator: " ") {
                if token.hasPrefix("id:"), let parsed = UUID(uuidString: String(token.dropFirst(3))) {
                    id = parsed
                } else if token.hasPrefix("created:"), let parsed = dateFormatter.date(from: String(token.dropFirst(8))) {
                    createdAt = parsed
                } else if token.hasPrefix("priority:"),
                          let parsed = TodoPriority(rawValue: String(token.dropFirst(9)).lowercased()) {
                    priority = parsed
                }
            }
            body.removeSubrange(metadataStart.lowerBound..<metadataEnd.upperBound)
        }

        var completedAt: Date?
        if checked, let range = body.range(of: " — 完成于 ", options: .backwards) {
            let timestamp = body[range.upperBound...].trimmingCharacters(in: .whitespaces)
            completedAt = dateFormatter.date(from: timestamp) ?? createdAt
            body = String(body[..<range.lowerBound])
        } else if checked {
            completedAt = createdAt
        }

        let title = body.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return nil }
        return TodoItem(
            id: id,
            title: title,
            createdAt: createdAt,
            completedAt: completedAt,
            priority: priority,
            status: status
        )
    }

    private func sanitize(_ title: String) -> String {
        title.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "<!--", with: "＜!--")
    }
}

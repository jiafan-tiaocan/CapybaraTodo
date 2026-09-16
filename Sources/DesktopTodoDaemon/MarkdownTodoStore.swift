import Foundation

struct MarkdownTodoStore {
    static let defaultDocumentURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? home.appending(path: "Documents")
        return documents.appending(path: "桌面待办/桌面待办.md")
    }()

    private let managedStartMarker = "<!-- desktop-todo:start -->"
    private let managedEndMarker = "<!-- desktop-todo:end -->"

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
        var section: TodoStatus? = .active
        var parentIndex: Int?
        let source = managedContent(in: content) ?? content

        for rawLine in source.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line == "## 进行中" {
                section = .active
                parentIndex = nil
                continue
            }
            if line == "## 待重启" {
                section = .pendingRestart
                parentIndex = nil
                continue
            }
            if line == "## 已完成" {
                section = .completed
                parentIndex = nil
                continue
            }
            if line.hasPrefix("## ") {
                section = nil
                parentIndex = nil
                continue
            }
            guard line.hasPrefix("- [") else { continue }

            let indentation = rawLine.prefix { $0 == " " || $0 == "\t" }
            if !indentation.isEmpty,
               let parentIndex,
               let checkpoint = parseCheckpoint(line: line) {
                items[parentIndex].checkpoints.append(checkpoint)
            } else if let section, let item = parse(line: line, section: section) {
                items.append(item)
                parentIndex = items.indices.last
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
            managedStartMarker,
            "# 桌面待办",
            "",
            "> 本文件由 DesktopTodoDaemon 维护，也可直接编辑。时间采用带本地时区偏移的 ISO 8601 格式。",
            "",
            "## 进行中",
            ""
        ]
        append(active, to: &lines, line: activeLine)
        if active.isEmpty { lines.append("_暂无_" ) }
        lines += ["", "## 待重启", ""]
        append(pendingRestart, to: &lines, line: activeLine)
        if pendingRestart.isEmpty { lines.append("_暂无_" ) }
        lines += ["", "## 已完成", ""]
        append(completed, to: &lines, line: completedLine)
        if completed.isEmpty { lines.append("_暂无_" ) }
        lines += [managedEndMarker, ""]

        let managedDocument = lines.joined(separator: "\n")
        let existing = try? String(contentsOf: url, encoding: .utf8)
        let output = mergedDocument(managedDocument, preserving: existing)
        try output.write(to: url, atomically: true, encoding: .utf8)
    }

    private func activeLine(_ item: TodoItem) -> String {
        "- [ ] \(sanitize(item.title)) \(metadata(for: item))"
    }

    private func completedLine(_ item: TodoItem) -> String {
        let completed = dateFormatter.string(from: item.completedAt ?? .now)
        return "- [x] \(sanitize(item.title)) — 完成于 \(completed) \(metadata(for: item))"
    }

    private func append(
        _ items: [TodoItem],
        to lines: inout [String],
        line: (TodoItem) -> String
    ) {
        for item in items {
            lines.append(line(item))
            lines.append(contentsOf: item.checkpoints.map(checkpointLine))
        }
    }

    private func checkpointLine(_ checkpoint: TodoCheckpoint) -> String {
        let mark = checkpoint.isCompleted ? "x" : " "
        var body = "  - [\(mark)] \(sanitize(checkpoint.title))"
        if let completedAt = checkpoint.completedAt {
            body += " — 完成于 \(dateFormatter.string(from: completedAt))"
        }
        let fields = [
            "id:\(checkpoint.id.uuidString)",
            "created:\(dateFormatter.string(from: checkpoint.createdAt))"
        ]
        return "\(body) <!-- \(fields.joined(separator: " ")) -->"
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

    private func parseCheckpoint(line: String) -> TodoCheckpoint? {
        let checked = line.hasPrefix("- [x]") || line.hasPrefix("- [X]")
        let markerEnd = line.index(line.startIndex, offsetBy: 5)
        var body = String(line[markerEnd...]).trimmingCharacters(in: .whitespaces)

        var id = UUID()
        var createdAt = Date()
        if let metadataStart = body.range(of: "<!--"), let metadataEnd = body.range(of: "-->") {
            let metadata = String(body[metadataStart.upperBound..<metadataEnd.lowerBound])
            for token in metadata.split(separator: " ") {
                if token.hasPrefix("id:"), let parsed = UUID(uuidString: String(token.dropFirst(3))) {
                    id = parsed
                } else if token.hasPrefix("created:"), let parsed = dateFormatter.date(from: String(token.dropFirst(8))) {
                    createdAt = parsed
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
        return TodoCheckpoint(
            id: id,
            title: title,
            createdAt: createdAt,
            completedAt: completedAt
        )
    }

    private func sanitize(_ title: String) -> String {
        title.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "<!--", with: "＜!--")
    }

    private func managedContent(in content: String) -> String? {
        guard let start = content.range(of: managedStartMarker),
              let end = content.range(of: managedEndMarker, range: start.upperBound..<content.endIndex),
              start.upperBound <= end.lowerBound else {
            return nil
        }
        return String(content[start.upperBound..<end.lowerBound])
    }

    private func mergedDocument(_ managedDocument: String, preserving existing: String?) -> String {
        guard let existing, !existing.isEmpty else { return managedDocument }

        if let start = existing.range(of: managedStartMarker),
           let end = existing.range(of: managedEndMarker, range: start.upperBound..<existing.endIndex) {
            var updated = existing
            updated.replaceSubrange(start.lowerBound..<end.upperBound, with: managedDocument.trimmingCharacters(in: .newlines))
            return updated.hasSuffix("\n") ? updated : updated + "\n"
        }

        let preserved = legacyUnmanagedContent(from: existing)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !preserved.isEmpty else { return managedDocument }
        return managedDocument.trimmingCharacters(in: .newlines)
            + "\n\n"
            + preserved
            + "\n"
    }

    private func legacyUnmanagedContent(from content: String) -> String {
        var isInManagedSection = false
        var preserved: [String] = []

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line == "# 桌面待办"
                || line.hasPrefix("> 本文件由 DesktopTodoDaemon 维护")
                || line == "_暂无_" {
                continue
            }
            if ["## 进行中", "## 待重启", "## 已完成"].contains(line) {
                isInManagedSection = true
                continue
            }
            if line.hasPrefix("## ") {
                isInManagedSection = false
                preserved.append(rawLine)
                continue
            }
            if isInManagedSection, line.hasPrefix("- [") {
                continue
            }
            preserved.append(rawLine)
        }

        return preserved.joined(separator: "\n")
    }
}

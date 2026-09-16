import Foundation

enum TodoStatus: String, Sendable {
    case active
    case pendingRestart
    case completed
}

enum TodoPriority: String, CaseIterable, Sendable {
    case none
    case p0
    case p1
    case p2
    case p3

    var label: String {
        switch self {
        case .none: "无"
        case .p0: "P0"
        case .p1: "P1"
        case .p2: "P2"
        case .p3: "P3"
        }
    }
}

struct TodoCheckpoint: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    var isCompleted: Bool {
        completedAt != nil
    }
}

struct TodoItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var createdAt: Date
    var completedAt: Date?
    var priority: TodoPriority
    var status: TodoStatus
    var checkpoints: [TodoCheckpoint]

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        priority: TodoPriority = .none,
        status: TodoStatus? = nil,
        checkpoints: [TodoCheckpoint] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.priority = priority
        self.status = status ?? (completedAt == nil ? .active : .completed)
        self.checkpoints = checkpoints
    }

    var needsHighPriorityHighlight: Bool {
        guard status != .completed else { return false }
        if priority == .p0 { return true }
        let normalizedTitle = title.lowercased()
        return normalizedTitle.contains("p0")
            || title.contains("高优")
            || title.contains("重要")
            || title.contains("紧急")
    }
}

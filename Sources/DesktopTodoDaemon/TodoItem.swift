import Foundation

struct TodoItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var createdAt: Date
    var completedAt: Date?

    init(id: UUID = UUID(), title: String, createdAt: Date = .now, completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}


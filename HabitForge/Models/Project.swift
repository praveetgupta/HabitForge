import SwiftData
import Foundation

@Model
class Project {
    var id: UUID
    var name: String
    var notes: String
    var icon: String
    var colorHex: String
    var sortOrder: Int
    
    var whenDate: Date?
    var deadline: Date?
    
    var status: String                        // "Active", "Completed", "On Hold", "Dropped"
    var completedAt: Date?
    var createdAt: Date
    var tags: [String]
    
    var area: Area?
    
    @Relationship(deleteRule: .cascade)
    var todos: [Todo] = []
    
    @Relationship(deleteRule: .cascade)
    var headings: [ProjectHeading] = []
    
    var progressFraction: Double {
        let activeTodos = todos.filter { $0.status != "Trash" }
        guard !activeTodos.isEmpty else { return 0 }
        let completed = activeTodos.filter { $0.status == "Logbook" }.count
        return Double(completed) / Double(activeTodos.count)
    }
    
    init(name: String, icon: String = "📋", colorHex: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.notes = ""
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = 0
        self.status = "Active"
        self.createdAt = Date()
        self.tags = []
    }
}

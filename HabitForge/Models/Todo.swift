import SwiftData
import Foundation

@Model
class Todo {
    var id: UUID
    var title: String
    var notes: String
    
    // Scheduling (Things 3 style)
    var whenDate: Date?
    var whenTime: Date?
    var deadline: Date?
    var isEvening: Bool
    
    // Reminders
    var reminderDate: Date?
    
    // Recurrence
    var isRepeating: Bool
    var repeatType: String?                   // "Daily", "Weekly", "Monthly", "Yearly"
    var repeatInterval: Int?
    var repeatDaysOfWeek: [Int]?
    var repeatAfterCompletion: Bool
    
    // Organization
    var status: String                        // "Inbox", "Today", "Upcoming", "Anytime", "Someday", "Logbook", "Trash"
    var priority: Int                         // 0=none, 1=low, 2=medium, 3=high
    var tags: [String]
    var headingId: UUID?
    var sortOrder: Int
    
    // Metadata
    var createdAt: Date
    var completedAt: Date?
    
    // Relationships
    var project: Project?
    var area: Area?
    
    @Relationship(deleteRule: .cascade)
    var checklist: [ChecklistItem] = []
    
    init(title: String, status: String = "Inbox") {
        self.id = UUID()
        self.title = title
        self.notes = ""
        self.isEvening = false
        self.isRepeating = false
        self.repeatAfterCompletion = false
        self.status = status
        self.priority = 0
        self.tags = []
        self.sortOrder = 0
        self.createdAt = Date()
    }
}

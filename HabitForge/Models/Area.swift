import SwiftData
import Foundation

@Model
class Area {
    var id: UUID
    var name: String
    var icon: String
    var sortOrder: Int
    var isArchived: Bool
    
    @Relationship(deleteRule: .nullify)
    var projects: [Project] = []
    
    @Relationship(deleteRule: .nullify)
    var todos: [Todo] = []
    
    init(name: String, icon: String = "📁") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = 0
        self.isArchived = false
    }
}

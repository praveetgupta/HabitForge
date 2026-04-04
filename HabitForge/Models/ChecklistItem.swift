import SwiftData
import Foundation

@Model
class ChecklistItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    
    var todo: Todo?
    
    init(title: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.sortOrder = sortOrder
    }
}

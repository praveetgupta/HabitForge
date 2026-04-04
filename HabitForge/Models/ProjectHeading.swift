import SwiftData
import Foundation

@Model
class ProjectHeading {
    var id: UUID
    var name: String
    var sortOrder: Int
    
    var project: Project?
    
    init(name: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
    }
}

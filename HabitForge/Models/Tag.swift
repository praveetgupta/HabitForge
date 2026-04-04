import SwiftData
import Foundation

@Model
class Tag {
    var id: UUID
    var name: String
    var colorHex: String?
    var sortOrder: Int
    
    init(name: String, colorHex: String? = nil) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = 0
    }
}

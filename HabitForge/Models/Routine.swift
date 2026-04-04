import SwiftData
import Foundation

@Model
class Routine {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    var notes: String?
    var sortOrder: Int
    var isArchived: Bool
    var createdAt: Date
    var lastPerformedAt: Date?
    
    @Relationship(deleteRule: .cascade)
    var templateExercises: [RoutineExercise] = []
    
    @Relationship(deleteRule: .cascade)
    var sessions: [WorkoutSession] = []
    
    init(name: String, colorHex: String = "#007AFF", icon: String = "🏋️") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.sortOrder = 0
        self.isArchived = false
        self.createdAt = Date()
    }
}

import SwiftData
import Foundation

@Model
class WorkoutSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var durationSeconds: Int?
    var notes: String?
    var mood: String?
    var isCompleted: Bool
    var totalVolumeKg: Double
    var numberOfPRs: Int
    
    var routine: Routine?
    
    @Relationship(deleteRule: .cascade)
    var performedExercises: [PerformedExercise] = []
    
    init(startTime: Date = Date()) {
        self.id = UUID()
        self.startTime = startTime
        self.isCompleted = false
        self.totalVolumeKg = 0
        self.numberOfPRs = 0
    }
}

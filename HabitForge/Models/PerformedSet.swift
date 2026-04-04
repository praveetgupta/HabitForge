import SwiftData
import Foundation

@Model
class PerformedSet {
    var id: UUID
    var setNumber: Int
    var setType: String                       // "Warmup", "Working", "Drop Set", "To Failure"
    var reps: Int?
    var weightKg: Double?
    var durationSeconds: Int?
    var distanceKm: Double?
    var isCompleted: Bool
    var isPR: Bool
    var timestamp: Date
    
    var performedExercise: PerformedExercise?
    
    init(setNumber: Int, setType: String = "Working") {
        self.id = UUID()
        self.setNumber = setNumber
        self.setType = setType
        self.isCompleted = false
        self.isPR = false
        self.timestamp = Date()
    }
}

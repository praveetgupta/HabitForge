import SwiftData
import Foundation

@Model
class RoutineExercise {
    var id: UUID
    var sortOrder: Int
    var defaultSets: Int
    var defaultReps: Int
    var defaultWeightKg: Double?
    var restSeconds: Int
    var notes: String?
    var supersetTag: String?
    
    var routine: Routine?
    var exercise: Exercise?
    
    init(sortOrder: Int, defaultSets: Int = 3, defaultReps: Int = 10, restSeconds: Int = 90) {
        self.id = UUID()
        self.sortOrder = sortOrder
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.restSeconds = restSeconds
    }
}

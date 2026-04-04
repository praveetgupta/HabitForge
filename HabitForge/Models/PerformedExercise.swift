import SwiftData
import Foundation

@Model
class PerformedExercise {
    var id: UUID
    var sortOrder: Int
    var exerciseName: String
    var muscleGroup: String
    
    var session: WorkoutSession?
    var exercise: Exercise?
    
    @Relationship(deleteRule: .cascade)
    var sets: [PerformedSet] = []
    
    init(exerciseName: String, muscleGroup: String, sortOrder: Int) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.muscleGroup = muscleGroup
        self.sortOrder = sortOrder
    }
}

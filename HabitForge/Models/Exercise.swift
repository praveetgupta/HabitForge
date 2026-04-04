import SwiftData
import Foundation

@Model
class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: String
    var equipmentType: String
    var exerciseType: String                  // "Weighted", "Bodyweight", "Timed", "Cardio"
    var instructions: String?
    var isCustom: Bool
    var isArchived: Bool
    var createdAt: Date
    
    var prMaxWeight: Double?
    var prMaxVolume: Double?
    
    init(name: String, muscleGroup: String, equipmentType: String = "Barbell",
         exerciseType: String = "Weighted", isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipmentType = equipmentType
        self.exerciseType = exerciseType
        self.isCustom = isCustom
        self.isArchived = false
        self.createdAt = Date()
    }
}

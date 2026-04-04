import SwiftData
import Foundation

@Model
class HabitEntry {
    var id: UUID
    var date: Date
    var timestamp: Date
    var isCompleted: Bool
    var durationSeconds: Int?
    var countValue: Int?
    var didAvoid: Bool?
    var note: String?
    var mood: String?                         // "😊", "🙂", "😐", "😓", "😞"
    
    var habit: Habit?
    
    init(date: Date = Date(), isCompleted: Bool = true) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.timestamp = Date()
        self.isCompleted = isCompleted
    }
}

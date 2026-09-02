import SwiftData
import Foundation

@Model
class Habit: Identifiable {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var habitType: String                     // "Build" or "Break"
    var sortOrder: Int
    
    // Scheduling
    var frequency: String                     // "Daily", "Times per Week", "Times per Month"
    var targetCount: Int
    var scheduledDays: [Int]                  // [1=Mon...7=Sun], empty = every day
    
    // Duration tracking
    var tracksDuration: Bool
    var targetDurationSeconds: Int?
    
    // Count tracking
    var tracksCount: Bool
    var targetCountValue: Int?
    var countUnit: String?
    
    // Reminders
    var reminderEnabled: Bool
    var reminderTime: Date?
    
    // Metadata
    var createdAt: Date
    var isArchived: Bool
    var isPaused: Bool
    var pausedUntil: Date?
    
    // Cached stats
    var currentStreak: Int
    var bestStreak: Int
    var totalCompletions: Int
    
    @Relationship(deleteRule: .cascade)
    var entries: [HabitEntry] = []
    
    init(name: String, icon: String = "⭐", colorHex: String = "#FF6B6B",
         habitType: String = "Build", frequency: String = "Daily") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.habitType = habitType
        self.sortOrder = 0
        self.frequency = frequency
        self.targetCount = 1
        self.scheduledDays = []
        self.tracksDuration = false
        self.tracksCount = false
        self.reminderEnabled = false
        self.createdAt = Date()
        self.isArchived = false
        self.isPaused = false
        self.currentStreak = 0
        self.bestStreak = 0
        self.totalCompletions = 0
    }
}

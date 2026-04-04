import SwiftUI
import SwiftData

@Observable
class HabitViewModel {
    private var modelContext: ModelContext
    
    var habits: [Habit] = []
    var selectedDate: Date = Date()
    
    // Timer state
    var showingTimerFor: Habit?
    var timerSeconds: Int = 0
    var timerRunning: Bool = false
    private var timer: Timer?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchHabits()
    }
    
    func fetchHabits() {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        habits = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        let targetDate = Calendar.current.startOfDay(for: date)
        return habit.entries.contains { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: targetDate) && entry.isCompleted
        }
    }
    
    func toggleHabit(_ habit: Habit) {
        let today = Calendar.current.startOfDay(for: Date())
        if let existing = habit.entries.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }) {
            existing.isCompleted.toggle()
        } else {
            let entry = HabitEntry(date: today, isCompleted: true)
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
        try? modelContext.save()
        fetchHabits()
    }
    
    func addHabit(name: String, icon: String, colorHex: String) {
        let habit = Habit(name: name, icon: icon, colorHex: colorHex)
        habit.sortOrder = habits.count
        modelContext.insert(habit)
        try? modelContext.save()
        fetchHabits()
    }
    
    // TODO: Implement full ViewModel from HabitForge-Habit-Module.md
    // - progressFraction(), incrementCount(), startTimer(), stopTimer()
    // - recalculateStreak(), completionRate(), chartData(), heatmapData()
}

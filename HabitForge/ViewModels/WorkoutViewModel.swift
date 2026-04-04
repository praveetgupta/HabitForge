import SwiftUI
import SwiftData

@Observable
class WorkoutViewModel {
    private var modelContext: ModelContext
    
    var routines: [Routine] = []
    var exerciseLibrary: [Exercise] = []
    var activeSession: WorkoutSession?
    
    // Rest timer
    var restTimerSeconds: Int = 0
    var restTimerRunning: Bool = false
    private var restTimer: Timer?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchRoutines()
        fetchExercises()
    }
    
    func fetchRoutines() {
        let descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        routines = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchExercises() {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.name)]
        )
        exerciseLibrary = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func createRoutine(name: String, icon: String, colorHex: String) {
        let routine = Routine(name: name, colorHex: colorHex, icon: icon)
        routine.sortOrder = routines.count
        modelContext.insert(routine)
        try? modelContext.save()
        fetchRoutines()
    }
    
    // TODO: Implement full ViewModel from HabitForge-Workout-Module.md
    // - startSession(), completeSet(), addSet(), finishSession()
    // - rest timer, PR detection, exercise history, progress charts
}

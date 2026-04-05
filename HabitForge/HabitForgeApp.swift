import SwiftUI
import SwiftData

@main
struct HabitForgeApp: App {
    var body: some Scene {
        WindowGroup {
            // Habit (and related) notification permission + reminder reschedule: `MainTabView.task`
            MainTabView()
        }
        .modelContainer(for: [
            Habit.self,
            HabitEntry.self,
            Todo.self,
            ChecklistItem.self,
            Area.self,
            Project.self,
            ProjectHeading.self,
            Tag.self,
            Routine.self,
            Exercise.self,
            RoutineExercise.self,
            WorkoutSession.self,
            PerformedExercise.self,
            PerformedSet.self
        ])
    }
}

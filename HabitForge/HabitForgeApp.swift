import SwiftUI
import SwiftData

@main
struct HabitForgeApp: App {
    @Environment(\.modelContext) private var modelContext

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .task {
                    let granted = await NotificationService.shared.requestPermission()
                    print("[HabitForge] Notification permission granted: \(granted)")
                }
                .task {
                    ExerciseSeedData.seedIfNeeded(modelContext: modelContext)
                }
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

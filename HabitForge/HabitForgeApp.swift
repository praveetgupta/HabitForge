import SwiftUI
import SwiftData

@main
struct HabitForgeApp: App {
    /// Built explicitly rather than via `.modelContainer(for:)` so that launch-time work
    /// (seeding the exercise library) runs against *this* container's context. Reading
    /// `@Environment(\.modelContext)` in an `App` does not see the scene's container.
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: HabitForgeSchema.container)
        } catch {
            fatalError("Could not create the HabitForge model container: \(error)")
        }
    }

    @State private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(settings.appearance.colorScheme)
                .task {
                    #if DEBUG
                    if DemoData.isResetRequested {
                        DemoData.wipe(modelContext: modelContainer.mainContext)
                        return
                    }
                    if DemoData.isRequested {
                        DemoData.reseed(modelContext: modelContainer.mainContext)
                        return
                    }
                    #endif
                    ExerciseSeedData.seedIfNeeded(modelContext: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }
}

/// The single source of truth for which models the store holds. Kept here so tests can
/// build an in-memory container with exactly the same schema.
enum HabitForgeSchema {
    static let models: [any PersistentModel.Type] = [
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
    ]

    static var container: Schema { Schema(models) }
}

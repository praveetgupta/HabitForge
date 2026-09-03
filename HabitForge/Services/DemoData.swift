#if DEBUG
import Foundation
import SwiftData

/// Populates the store with a realistic dataset so the README screenshots can be regenerated
/// reproducibly instead of being hand-curated from whatever happened to be on the device.
///
/// Only compiled into DEBUG builds, and only runs when the app is launched with
/// `-HabitForgeDemoData`, which `ScreenshotTests` passes. It wipes the store first, so the
/// screenshots are identical on every run.
enum DemoData {
    static let launchArgument = "-HabitForgeDemoData"

    /// Wipes the store back to a clean install. `ScreenshotTests` relaunches with this once it
    /// is done so it does not leave its dataset behind for the next UI test to trip over.
    static let resetArgument = "-HabitForgeResetStore"

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static var isResetRequested: Bool {
        ProcessInfo.processInfo.arguments.contains(resetArgument)
    }

    static func wipe(modelContext: ModelContext) {
        for model in HabitForgeSchema.models {
            try? modelContext.delete(model: model)
        }
        try? modelContext.save()
        ExerciseSeedData.seedIfNeeded(modelContext: modelContext)
    }

    private static let calendar = Calendar.current

    private static func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: Date()))!
    }

    static func reseed(modelContext: ModelContext) {
        for model in HabitForgeSchema.models {
            try? modelContext.delete(model: model)
        }
        try? modelContext.save()

        ExerciseSeedData.seedIfNeeded(modelContext: modelContext)
        seedHabits(modelContext)
        seedTodos(modelContext)
        seedWorkouts(modelContext)
        try? modelContext.save()
    }

    // MARK: - Habits

    private static func seedHabits(_ context: ModelContext) {
        let viewModel = HabitViewModel(modelContext: context)

        // (name, icon, colour, frequency, target, tracksDuration, durationTarget,
        //  tracksCount, countTarget, unit, hit-rate over the window)
        let specs: [(String, String, String, String, Int, Bool, Int?, Bool, Int?, String?, Double)] = [
            ("Workout", "🏋️", "#0A84FF", "Times per Week", 4, false, nil, false, nil, nil, 0.62),
            ("Read", "📚", "#5E5CE6", "Daily", 1, true, 1800, false, nil, nil, 0.84),
            ("Drink water", "💧", "#32ADE6", "Daily", 1, false, nil, true, 8, "glasses", 0.78),
            ("Meditate", "🧘", "#30D158", "Daily", 1, true, 600, false, nil, nil, 0.72),
            ("No late-night snacks", "🚫", "#FF453A", "Daily", 1, false, nil, false, nil, nil, 0.88)
        ]

        for (index, spec) in specs.enumerated() {
            viewModel.addHabit(
                name: spec.0, icon: spec.1, colorHex: spec.2,
                habitType: spec.0.hasPrefix("No ") ? "Break" : "Build",
                frequency: spec.3,
                targetCount: spec.4,
                tracksDuration: spec.5,
                targetDurationSeconds: spec.6,
                tracksCount: spec.7,
                targetCountValue: spec.8,
                countUnit: spec.9
            )
            guard let habit = viewModel.habits.last else { continue }
            habit.sortOrder = index

            // A deterministic pseudo-random pattern: stable across runs, but not so regular
            // that the charts look synthetic.
            var seed = UInt64(index &* 7919 &+ 13)
            for offset in stride(from: 89, through: 0, by: -1) {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                let roll = Double((seed >> 33) % 1000) / 1000.0
                guard roll < spec.10 else { continue }

                let entry = HabitEntry(date: day(offset), isCompleted: true)
                if habit.tracksDuration, let target = habit.targetDurationSeconds {
                    entry.durationSeconds = target
                }
                if habit.tracksCount, let target = habit.targetCountValue {
                    entry.countValue = target
                }
                entry.habit = habit
                habit.entries.append(entry)
                context.insert(entry)
            }
            // Today stays partly open, so the dashboard ring is not a flat 100%.
            if habit.name == "Drink water" {
                let today = habit.entries.first { calendar.isDateInToday($0.date) }
                    ?? {
                        let e = HabitEntry(date: Date(), isCompleted: false)
                        e.habit = habit
                        habit.entries.append(e)
                        context.insert(e)
                        return e
                    }()
                today.countValue = 5
                today.isCompleted = false
            }
            if habit.name == "Meditate" {
                habit.entries.removeAll { calendar.isDateInToday($0.date) }
            }
            viewModel.recalculateStreak(for: habit)
        }
        try? context.save()
    }

    // MARK: - Todos

    private static func seedTodos(_ context: ModelContext) {
        let viewModel = TodoViewModel(modelContext: context)

        let work = viewModel.createArea(name: "Work", icon: "💼")
        let personal = viewModel.createArea(name: "Personal", icon: "🏡")
        let health = viewModel.createArea(name: "Health", icon: "🩺")

        let launch = viewModel.createProject(name: "Ship HabitForge 1.0", icon: "🚀",
                                             colorHex: "#0A84FF", area: work)
        launch.deadline = calendar.date(byAdding: .day, value: 12, to: Date())
        let move = viewModel.createProject(name: "Apartment move", icon: "📦",
                                           colorHex: "#FF9F0A", area: personal)

        // Today
        viewModel.addTodo(title: "Review pull requests", whenDate: day(0), priority: 2,
                          project: launch, status: "Today")
        viewModel.addTodo(title: "Write release notes", whenDate: day(0),
                          project: launch, status: "Today")
        viewModel.addTodo(title: "Call the letting agent", whenDate: day(0),
                          deadline: calendar.date(byAdding: .day, value: 2, to: Date()),
                          priority: 3, project: move, status: "Today")
        viewModel.addTodo(title: "Stretch for 10 minutes", whenDate: day(0), isEvening: true,
                          area: health, status: "Today")
        viewModel.addTodo(title: "Plan tomorrow", whenDate: day(0), isEvening: true,
                          status: "Today")

        // Inbox
        viewModel.quickAdd(title: "Look into Swift Charts annotations")
        viewModel.quickAdd(title: "Book dentist appointment")

        // Upcoming
        viewModel.addTodo(title: "Submit to App Store review",
                          whenDate: calendar.date(byAdding: .day, value: 5, to: Date()),
                          project: launch, status: "Upcoming")
        viewModel.addTodo(title: "Renew gym membership",
                          whenDate: calendar.date(byAdding: .day, value: 9, to: Date()),
                          area: health, status: "Upcoming")

        // Anytime / Someday
        viewModel.addTodo(title: "Refactor the notification scheduler",
                          project: launch, status: "Anytime")
        viewModel.addTodo(title: "Learn to make sourdough", area: personal, status: "Someday")

        // A project todo with a checklist
        let packing = viewModel.addTodo(title: "Pack the kitchen", project: move, status: "Anytime")
        for item in ["Wrap glassware", "Label the boxes", "Defrost the freezer"] {
            viewModel.addChecklistItem(packing, title: item)
        }

        // Logbook — a few things already done
        for title in ["Set up TestFlight", "Design the app icon", "Cancel old subscription"] {
            let done = viewModel.addTodo(title: title, project: launch)
            viewModel.completeTodo(done)
        }
        try? context.save()
    }

    // MARK: - Workouts

    private static func seedWorkouts(_ context: ModelContext) {
        let viewModel = WorkoutViewModel(modelContext: context)

        let plans: [(String, String, String, [String])] = [
            ("Push", "🏋️", "#0A84FF", ["Barbell Bench Press", "Overhead Press",
                                        "Incline Dumbbell Press", "Lateral Raise", "Triceps Pushdown"]),
            ("Pull", "💪", "#5E5CE6", ["Deadlift", "Pull-Up", "Barbell Row",
                                       "Seated Cable Row", "Barbell Curl"]),
            ("Legs", "🦵", "#30D158", ["Back Squat", "Romanian Deadlift", "Leg Press",
                                       "Lying Leg Curl", "Standing Calf Raise"])
        ]

        var routines: [Routine] = []
        for (index, plan) in plans.enumerated() {
            let routine = viewModel.createRoutine(name: plan.0, icon: plan.1, colorHex: plan.2)
            routine.sortOrder = index
            for name in plan.3 {
                guard let exercise = viewModel.exerciseLibrary.first(where: { $0.name == name }) else { continue }
                viewModel.addExerciseToRoutine(routine, exercise: exercise, sets: 3, reps: 8)
            }
            routines.append(routine)
        }

        // Nine completed sessions over six weeks, cycling the split, with weights creeping up
        // so the progress charts and PR list have something to show.
        let startingWeights: [String: Double] = [
            "Barbell Bench Press": 70, "Overhead Press": 40, "Incline Dumbbell Press": 26,
            "Lateral Raise": 10, "Triceps Pushdown": 25,
            "Deadlift": 110, "Pull-Up": 0, "Barbell Row": 60,
            "Seated Cable Row": 55, "Barbell Curl": 30,
            "Back Squat": 90, "Romanian Deadlift": 80, "Leg Press": 140,
            "Lying Leg Curl": 40, "Standing Calf Raise": 60
        ]

        for sessionIndex in 0..<9 {
            let routine = routines[sessionIndex % routines.count]
            let daysBack = 40 - sessionIndex * 4
            let cycle = sessionIndex / routines.count

            let session = WorkoutSession(startTime: calendar.date(
                byAdding: .hour, value: 18, to: day(daysBack))!)
            session.routine = routine
            context.insert(session)

            for (order, template) in viewModel.sortedTemplateExercises(for: routine).enumerated() {
                guard let exercise = template.exercise else { continue }
                let performed = PerformedExercise(exerciseName: exercise.name,
                                                  muscleGroup: exercise.muscleGroup,
                                                  sortOrder: order)
                performed.exercise = exercise
                performed.session = session
                session.performedExercises.append(performed)
                context.insert(performed)

                let base = (startingWeights[exercise.name] ?? 40) + Double(cycle) * 2.5
                for setNumber in 1...3 {
                    let set = PerformedSet(setNumber: setNumber)
                    set.reps = 8
                    set.weightKg = base
                    set.isCompleted = true
                    set.timestamp = session.startTime
                    if base > 0, base > (exercise.prMaxWeight ?? 0) {
                        set.isPR = true
                        exercise.prMaxWeight = base
                        session.numberOfPRs += 1
                    }
                    set.performedExercise = performed
                    performed.sets.append(set)
                    context.insert(set)
                }
            }

            session.totalVolumeKg = session.performedExercises
                .flatMap(\.sets)
                .reduce(0) { $0 + ($1.weightKg ?? 0) * Double($1.reps ?? 0) }
            session.durationSeconds = 3300 + sessionIndex * 60
            session.endTime = session.startTime.addingTimeInterval(Double(session.durationSeconds!))
            session.isCompleted = true
            session.mood = ["💪", "🙂", "😤"][sessionIndex % 3]
            routine.lastPerformedAt = session.startTime
        }
        try? context.save()
    }
}
#endif

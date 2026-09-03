import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import HabitForge

/// Every suite runs against a fresh in-memory store built from the same schema the app ships,
/// so a model added to `HabitForgeSchema` is automatically covered here too.
@MainActor
private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: HabitForgeSchema.container,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

private let calendar = Calendar.current

private func daysAgo(_ days: Int) -> Date {
    calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: Date()))!
}

// MARK: - Weight units

@Suite("Weight units")
struct WeightUnitTests {

    @Test("Kilograms are the identity conversion")
    func kilogramsPassThrough() {
        #expect(WeightUnit.kilograms.fromKilograms(100) == 100)
        #expect(WeightUnit.kilograms.toKilograms(100) == 100)
    }

    @Test("100 kg is about 220.5 lb")
    func poundsConversion() {
        let pounds = WeightUnit.pounds.fromKilograms(100)
        #expect(abs(pounds - 220.462) < 0.01)
    }

    @Test("Converting to pounds and back is lossless")
    func poundsRoundTrip() {
        let original = 82.5
        let roundTripped = WeightUnit.pounds.toKilograms(WeightUnit.pounds.fromKilograms(original))
        #expect(abs(roundTripped - original) < 1e-9)
    }

    @Test("Formatting appends the unit and rounds to whole numbers")
    func formatting() {
        #expect(WeightUnit.kilograms.format(kilograms: 40) == "40 kg")
        #expect(WeightUnit.pounds.format(kilograms: 100) == "220 lb")
    }
}

// MARK: - Exercise seeding

@Suite("Exercise library seeding")
struct ExerciseSeedTests {

    @Test("Seeding is idempotent")
    @MainActor
    func seedingRunsOnce() throws {
        let context = try makeContext()

        #expect(ExerciseSeedData.seedIfNeeded(modelContext: context) == true)
        let firstCount = try context.fetchCount(FetchDescriptor<Exercise>())
        #expect(firstCount == ExerciseSeedData.exercises.count)

        // A second call on a populated store must be a no-op, not a duplicate insert.
        #expect(ExerciseSeedData.seedIfNeeded(modelContext: context) == false)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == firstCount)
    }

    @Test("Every seeded exercise uses a canonical muscle group, equipment and type")
    func seedStringsAreCanonical() {
        for exercise in ExerciseSeedData.exercises {
            #expect(ExerciseSeedData.muscleGroups.contains(exercise.muscleGroup),
                    "\(exercise.name) has muscle group \(exercise.muscleGroup)")
            #expect(ExerciseSeedData.equipmentTypes.contains(exercise.equipmentType),
                    "\(exercise.name) has equipment \(exercise.equipmentType)")
            #expect(ExerciseSeedData.exerciseTypes.contains(exercise.exerciseType),
                    "\(exercise.name) has type \(exercise.exerciseType)")
        }
    }

    @Test("Seeded exercise names are unique")
    func seedNamesAreUnique() {
        let names = ExerciseSeedData.exercises.map(\.name)
        #expect(Set(names).count == names.count)
    }
}

// MARK: - Habits

@Suite("Habits")
@MainActor
struct HabitTests {

    private func makeViewModel() throws -> (HabitViewModel, ModelContext) {
        let context = try makeContext()
        return (HabitViewModel(modelContext: context), context)
    }

    @Test("A simple daily habit toggles complete and back")
    func toggleSimpleHabit() throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.addHabit(name: "Read", icon: "📚", colorHex: "#007AFF")
        let habit = try #require(viewModel.habits.first)

        #expect(viewModel.isCompleted(habit, on: Date()) == false)
        viewModel.toggleHabit(habit)
        #expect(viewModel.isCompleted(habit, on: Date()) == true)
        viewModel.toggleHabit(habit)
        #expect(viewModel.isCompleted(habit, on: Date()) == false)
    }

    @Test("Count habits report partial progress and clamp at the target")
    func countHabitProgress() throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.addHabit(name: "Water", icon: "💧", colorHex: "#007AFF",
                           tracksCount: true, targetCountValue: 8, countUnit: "glasses")
        let habit = try #require(viewModel.habits.first)

        for _ in 0..<3 { viewModel.incrementCount(habit) }
        #expect(abs(viewModel.progressFraction(habit, on: Date()) - 0.375) < 1e-9)
        #expect(viewModel.isCompleted(habit, on: Date()) == false)

        // Overshooting the target must not push progress past 1.
        for _ in 0..<10 { viewModel.incrementCount(habit) }
        #expect(viewModel.progressFraction(habit, on: Date()) == 1)
        #expect(viewModel.entryForHabit(habit, on: Date())?.countValue == 8)
    }

    @Test("Decrementing a count habit floors at zero")
    func countHabitDecrement() throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.addHabit(name: "Water", icon: "💧", colorHex: "#007AFF",
                           tracksCount: true, targetCountValue: 8)
        let habit = try #require(viewModel.habits.first)

        viewModel.incrementCount(habit)
        for _ in 0..<5 { viewModel.decrementCount(habit) }
        #expect(viewModel.entryForHabit(habit, on: Date())?.countValue == 0)
    }

    @Test("An unscheduled day cannot be completed")
    func unscheduledDayIsNotToggleable() throws {
        let (viewModel, _) = try makeViewModel()
        // Schedule the habit on every weekday except today.
        let today = viewModel.habitWeekday(for: Date())
        let otherDays = (1...7).filter { $0 != today }
        viewModel.addHabit(name: "Gym", icon: "🏋️", colorHex: "#007AFF", scheduledDays: otherDays)
        let habit = try #require(viewModel.habits.first)

        #expect(viewModel.isScheduled(habit, on: Date()) == false)
        viewModel.toggleHabit(habit)
        #expect(viewModel.isCompleted(habit, on: Date()) == false)
        #expect(viewModel.progressFraction(habit, on: Date()) == 0)
    }

    @Test("An empty schedule means every day")
    func emptyScheduleMeansDaily() throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.addHabit(name: "Stretch", icon: "🧘", colorHex: "#007AFF", scheduledDays: [])
        let habit = try #require(viewModel.habits.first)

        for offset in 0..<7 {
            #expect(viewModel.isScheduled(habit, on: daysAgo(offset)) == true)
        }
    }

    @Test("Three consecutive completed days make a streak of three")
    func currentStreak() throws {
        let (viewModel, context) = try makeViewModel()
        viewModel.addHabit(name: "Journal", icon: "📓", colorHex: "#007AFF")
        let habit = try #require(viewModel.habits.first)

        for offset in 0..<3 {
            let entry = HabitEntry(date: daysAgo(offset), isCompleted: true)
            entry.habit = habit
            habit.entries.append(entry)
            context.insert(entry)
        }
        viewModel.recalculateStreak(for: habit)

        #expect(habit.currentStreak == 3)
        #expect(habit.bestStreak >= 3)
        #expect(habit.totalCompletions == 3)
    }

    @Test("A gap yesterday breaks the current streak")
    func brokenStreak() throws {
        let (viewModel, context) = try makeViewModel()
        viewModel.addHabit(name: "Journal", icon: "📓", colorHex: "#007AFF")
        let habit = try #require(viewModel.habits.first)

        // Completed today and three days ago, but not yesterday or the day before.
        for offset in [0, 3, 4] {
            let entry = HabitEntry(date: daysAgo(offset), isCompleted: true)
            entry.habit = habit
            habit.entries.append(entry)
            context.insert(entry)
        }
        viewModel.recalculateStreak(for: habit)

        #expect(habit.currentStreak == 1)
        #expect(habit.bestStreak == 2)
    }

    @Test("Archiving hides a habit from the active list")
    func archiveHabit() throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.addHabit(name: "Old habit", icon: "⭐", colorHex: "#007AFF")
        let habit = try #require(viewModel.habits.first)

        viewModel.archiveHabit(habit)
        #expect(viewModel.habits.isEmpty)
        #expect(habit.isArchived == true)
        #expect(viewModel.isScheduled(habit, on: Date()) == false)
    }

    @Test("Duration habits complete once the target is reached")
    func durationHabit() throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.addHabit(name: "Meditate", icon: "🧘", colorHex: "#007AFF",
                           tracksDuration: true, targetDurationSeconds: 600)
        let habit = try #require(viewModel.habits.first)

        viewModel.applyDurationSeconds(300, habit: habit, on: Date())
        #expect(abs(viewModel.progressFraction(habit, on: Date()) - 0.5) < 1e-9)

        viewModel.applyDurationSeconds(600, habit: habit, on: Date())
        #expect(viewModel.isCompleted(habit, on: Date()) == true)
    }
}

// MARK: - Todos

@Suite("Todos")
@MainActor
struct TodoTests {

    private func makeViewModel() throws -> (TodoViewModel, ModelContext) {
        let context = try makeContext()
        return (TodoViewModel(modelContext: context), context)
    }

    @Test("Quick add lands in the Inbox")
    func quickAddGoesToInbox() throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.quickAdd(title: "Buy milk")

        #expect(viewModel.inboxTodos.count == 1)
        #expect(viewModel.inboxTodos.first?.status == "Inbox")
    }

    @Test("Completing a todo files it in the Logbook with a timestamp")
    func completeTodo() throws {
        let (viewModel, _) = try makeViewModel()
        let todo = viewModel.quickAdd(title: "Ship the release")

        viewModel.completeTodo(todo)
        #expect(todo.status == "Logbook")
        #expect(todo.completedAt != nil)
        #expect(viewModel.inboxTodos.isEmpty)
        #expect(viewModel.logbookTodos.count == 1)
        #expect(viewModel.completedToday() == 1)
    }

    @Test("Completing a repeating todo spawns the next occurrence")
    func repeatingTodoRespawns() throws {
        let (viewModel, _) = try makeViewModel()
        let todo = viewModel.addTodo(
            title: "Weekly review",
            whenDate: calendar.startOfDay(for: Date()),
            status: "Today",
            isRepeating: true,
            repeatType: "Weekly",
            repeatInterval: 1
        )

        viewModel.completeTodo(todo)
        viewModel.fetchAll()

        #expect(viewModel.logbookTodos.count == 1)
        let next = try #require((viewModel.upcomingTodos + viewModel.todayTodos)
            .first { $0.title == "Weekly review" && $0.status != "Logbook" })
        #expect(next.isRepeating == true)
        let expected = calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.startOfDay(for: Date()))!
        #expect(calendar.isDate(try #require(next.whenDate), inSameDayAs: expected))
    }

    @Test("Upcoming todos whose date has arrived are promoted to Today")
    func autoPromote() throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.addTodo(title: "Overdue", whenDate: daysAgo(2), status: "Upcoming")
        viewModel.addTodo(title: "Still future",
                          whenDate: calendar.date(byAdding: .day, value: 5, to: Date()),
                          status: "Upcoming")

        viewModel.autoPromoteUpcoming()

        #expect(viewModel.todayTodos.map(\.title) == ["Overdue"])
        #expect(viewModel.upcomingTodos.map(\.title) == ["Still future"])
    }

    @Test("Status moves clear the scheduled date")
    func statusMovesClearWhenDate() throws {
        let (viewModel, _) = try makeViewModel()
        let todo = viewModel.addTodo(title: "Someday thing", whenDate: Date(), status: "Today")

        viewModel.moveToSomeday(todo)
        #expect(todo.status == "Someday")
        #expect(todo.whenDate == nil)
    }

    @Test("Scheduling in the future files the todo under Upcoming")
    func scheduleFuture() throws {
        let (viewModel, _) = try makeViewModel()
        let todo = viewModel.quickAdd(title: "Dentist")
        let future = calendar.date(byAdding: .day, value: 3, to: Date())!

        viewModel.scheduleFor(todo, date: future)
        #expect(todo.status == "Upcoming")

        viewModel.scheduleFor(todo, date: Date())
        #expect(todo.status == "Today")
    }

    @Test("Project progress counts only untrashed todos")
    func projectProgress() throws {
        let (viewModel, _) = try makeViewModel()
        let project = viewModel.createProject(name: "Launch")

        let done = viewModel.addTodo(title: "Done", project: project)
        viewModel.addTodo(title: "Open", project: project)
        viewModel.completeTodo(done)

        #expect(abs(project.progressFraction - 0.5) < 1e-9)
    }

    @Test("Search matches title, notes and tags")
    func search() throws {
        let (viewModel, _) = try makeViewModel()
        viewModel.addTodo(title: "Call plumber", notes: "about the leak", tags: ["home"])
        viewModel.addTodo(title: "Read paper", notes: "", tags: ["work"])

        #expect(viewModel.search(query: "plumb").count == 1)
        #expect(viewModel.search(query: "leak").count == 1)
        #expect(viewModel.search(query: "home").count == 1)
        #expect(viewModel.search(query: "zzz").isEmpty)
    }
}

// MARK: - Workouts

@Suite("Workouts")
@MainActor
struct WorkoutTests {

    private func makeViewModel() throws -> (WorkoutViewModel, ModelContext) {
        let context = try makeContext()
        return (WorkoutViewModel(modelContext: context), context)
    }

    private func makeRoutine(_ viewModel: WorkoutViewModel,
                             exerciseName: String = "Barbell Bench Press") throws -> (Routine, Exercise) {
        let routine = viewModel.createRoutine(name: "Push", icon: "🏋️", colorHex: "#007AFF")
        let exercise = try #require(viewModel.exerciseLibrary.first { $0.name == exerciseName })
        viewModel.addExerciseToRoutine(routine, exercise: exercise, sets: 3, reps: 10)
        return (routine, exercise)
    }

    @Test("Starting a session materialises the routine's sets")
    func startSessionBuildsSets() throws {
        let (viewModel, _) = try makeViewModel()
        let (routine, _) = try makeRoutine(viewModel)

        let session = viewModel.startSession(from: routine)
        let performed = try #require(session.performedExercises.first)

        #expect(session.performedExercises.count == 1)
        #expect(performed.sets.count == 3)
        #expect(performed.sets.allSatisfy { $0.reps == 10 })
        #expect(viewModel.activeSession != nil)
    }

    @Test("The first weighted set is a PR, and only heavier ones follow it")
    func prDetection() throws {
        let (viewModel, _) = try makeViewModel()
        let (routine, exercise) = try makeRoutine(viewModel)
        let session = viewModel.startSession(from: routine)
        let sets = viewModel.sortedSets(in: try #require(session.performedExercises.first))

        viewModel.completeSet(sets[0], reps: 5, weight: 60)
        #expect(sets[0].isPR == true)
        #expect(exercise.prMaxWeight == 60)

        // Lighter than the standing best — not a PR.
        viewModel.completeSet(sets[1], reps: 5, weight: 50)
        #expect(sets[1].isPR == false)
        #expect(exercise.prMaxWeight == 60)

        viewModel.completeSet(sets[2], reps: 5, weight: 70)
        #expect(sets[2].isPR == true)
        #expect(exercise.prMaxWeight == 70)
        #expect(session.numberOfPRs == 2)
    }

    @Test("Bodyweight sets never generate PRs")
    func bodyweightSetsHaveNoPR() throws {
        let (viewModel, _) = try makeViewModel()
        let (routine, exercise) = try makeRoutine(viewModel, exerciseName: "Pull-Up")
        let session = viewModel.startSession(from: routine)
        let sets = viewModel.sortedSets(in: try #require(session.performedExercises.first))

        viewModel.completeSet(sets[0], reps: 12, weight: 0)
        #expect(sets[0].isPR == false)
        #expect(exercise.prMaxWeight == nil)
    }

    @Test("Volume is the sum of completed sets only")
    func volumeTracking() throws {
        let (viewModel, _) = try makeViewModel()
        let (routine, _) = try makeRoutine(viewModel)
        let session = viewModel.startSession(from: routine)
        let sets = viewModel.sortedSets(in: try #require(session.performedExercises.first))

        viewModel.completeSet(sets[0], reps: 10, weight: 60)
        viewModel.completeSet(sets[1], reps: 8, weight: 60)
        #expect(session.totalVolumeKg == 60 * 10 + 60 * 8)

        // Undoing a set removes its contribution, and its PR flag.
        viewModel.uncompleteSet(sets[0])
        #expect(session.totalVolumeKg == 60 * 8)
        #expect(session.numberOfPRs == 0)
    }

    @Test("Removing a set renumbers the ones left behind")
    func removeSetRenumbers() throws {
        let (viewModel, _) = try makeViewModel()
        let (routine, _) = try makeRoutine(viewModel)
        let session = viewModel.startSession(from: routine)
        let performed = try #require(session.performedExercises.first)
        let sets = viewModel.sortedSets(in: performed)

        viewModel.removeSet(from: performed, at: sets[1])
        #expect(viewModel.sortedSets(in: performed).map(\.setNumber) == [1, 2])
    }

    @Test("Adding a set copies the previous set's weight and reps")
    func addSetCopiesPrevious() throws {
        let (viewModel, _) = try makeViewModel()
        let (routine, _) = try makeRoutine(viewModel)
        let session = viewModel.startSession(from: routine)
        let performed = try #require(session.performedExercises.first)
        let sets = viewModel.sortedSets(in: performed)

        viewModel.completeSet(sets[2], reps: 6, weight: 80)
        viewModel.addSet(to: performed)

        let added = try #require(viewModel.sortedSets(in: performed).last)
        #expect(added.setNumber == 4)
        #expect(added.weightKg == 80)
        #expect(added.reps == 6)
    }

    @Test("The next session pre-fills weights from the last completed one")
    func previousWeightsAutofill() throws {
        let (viewModel, _) = try makeViewModel()
        let (routine, exercise) = try makeRoutine(viewModel)

        let first = viewModel.startSession(from: routine)
        let sets = viewModel.sortedSets(in: try #require(first.performedExercises.first))
        viewModel.completeSet(sets[0], reps: 10, weight: 60)
        viewModel.completeSet(sets[1], reps: 10, weight: 65)
        viewModel.completeSet(sets[2], reps: 8, weight: 70)
        viewModel.finishSession()

        #expect(viewModel.previousWeights(for: exercise) == [60, 65, 70])

        let second = viewModel.startSession(from: routine)
        let secondSets = viewModel.sortedSets(in: try #require(second.performedExercises.first))
        #expect(secondSets.map(\.weightKg) == [60, 65, 70])
    }

    @Test("Finishing a session stamps it and records it against the routine")
    func finishSession() throws {
        let (viewModel, _) = try makeViewModel()
        let (routine, _) = try makeRoutine(viewModel)
        viewModel.startSession(from: routine)

        let finished = try #require(viewModel.finishSession())
        #expect(finished.isCompleted == true)
        #expect(finished.endTime != nil)
        #expect(finished.durationSeconds != nil)
        #expect(routine.lastPerformedAt != nil)
        #expect(viewModel.activeSession == nil)
        #expect(viewModel.sessions.count == 1)
    }

    @Test("Discarding a session leaves no trace")
    func discardSession() throws {
        let (viewModel, _) = try makeViewModel()
        let (routine, _) = try makeRoutine(viewModel)
        viewModel.startSession(from: routine)

        viewModel.discardSession()
        #expect(viewModel.activeSession == nil)
        viewModel.fetchSessions()
        #expect(viewModel.sessions.isEmpty)
    }

    @Test("Exercise search filters by name, muscle group and equipment")
    func exerciseSearch() throws {
        let (viewModel, _) = try makeViewModel()

        #expect(viewModel.searchExercises(query: "bench").isEmpty == false)
        #expect(viewModel.searchExercises(query: "", muscleFilter: "Chest")
            .allSatisfy { $0.muscleGroup == "Chest" })
        #expect(viewModel.searchExercises(query: "", equipmentFilter: "Barbell")
            .allSatisfy { $0.equipmentType == "Barbell" })
        #expect(viewModel.searchExercises(query: "definitely not an exercise").isEmpty)
    }

    @Test("Archiving a routine hides it from the dashboard list")
    func archiveRoutine() throws {
        let (viewModel, _) = try makeViewModel()
        let (routine, _) = try makeRoutine(viewModel)

        viewModel.archiveRoutine(routine)
        #expect(viewModel.routines.isEmpty)
        #expect(routine.isArchived == true)
    }
}

// MARK: - Export

@Suite("Data export")
@MainActor
struct DataExportTests {

    @Test("An export round-trips through JSON with its contents intact")
    func exportRoundTrip() throws {
        let context = try makeContext()

        let habitViewModel = HabitViewModel(modelContext: context)
        habitViewModel.addHabit(name: "Read", icon: "📚", colorHex: "#007AFF")
        habitViewModel.toggleHabit(try #require(habitViewModel.habits.first))

        let todoViewModel = TodoViewModel(modelContext: context)
        todoViewModel.quickAdd(title: "Buy milk")

        let workoutViewModel = WorkoutViewModel(modelContext: context)
        let routine = workoutViewModel.createRoutine(name: "Push", icon: "🏋️", colorHex: "#007AFF")
        let exercise = try #require(workoutViewModel.exerciseLibrary.first)
        workoutViewModel.addExerciseToRoutine(routine, exercise: exercise)
        workoutViewModel.startSession(from: routine)
        workoutViewModel.finishSession()

        let data = try DataExportService.encode(DataExportService.buildExport(modelContext: context))

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DataExportService.Export.self, from: data)

        #expect(decoded.formatVersion == DataExportService.formatVersion)
        #expect(decoded.habits.count == 1)
        #expect(decoded.habits.first?.entries.count == 1)
        #expect(decoded.todos.count == 1)
        #expect(decoded.routines.count == 1)
        #expect(decoded.routines.first?.exercises.count == 1)
        #expect(decoded.sessions.count == 1)
    }

    @Test("Exporting an empty store produces empty collections, not an error")
    func emptyExport() throws {
        let context = try makeContext()
        let export = DataExportService.buildExport(modelContext: context)

        #expect(export.habits.isEmpty)
        #expect(export.todos.isEmpty)
        #expect(export.sessions.isEmpty)
        #expect(try DataExportService.encode(export).isEmpty == false)
    }
}

// MARK: - Extensions

@Suite("Helpers")
struct ExtensionTests {

    @Test("Hex colours parse with and without the leading hash")
    func hexColours() {
        #expect(Color(hex: "#FF6B6B") != nil)
        #expect(Color(hex: "FF6B6B") != nil)
        #expect(Color(hex: "not a colour") == nil)
    }

    @Test("Relative descriptions name today and tomorrow")
    func relativeDates() {
        #expect(Date().relativeDescription == "Today")
        #expect(calendar.date(byAdding: .day, value: 1, to: Date())!.relativeDescription == "Tomorrow")
    }
}

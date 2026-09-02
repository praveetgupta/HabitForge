import SwiftUI
import SwiftData

struct ExerciseHistoryEntry: Identifiable {
    let id = UUID()
    let date: Date
    let bestWeight: Double?
    let bestReps: Int?
    let totalVolume: Double
    let setCount: Int
}

@Observable
class WorkoutViewModel {
    private var modelContext: ModelContext

    var routines: [Routine] = []
    var exerciseLibrary: [Exercise] = []
    var sessions: [WorkoutSession] = []
    var activeSession: WorkoutSession?

    // Rest timer
    var restTimerSeconds: Int = 0
    var restTimerRunning: Bool = false
    private var restTimer: Timer?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        ExerciseSeedData.seedIfNeeded(modelContext: modelContext)
        fetchRoutines()
        fetchExercises()
        fetchSessions()
    }

    // MARK: - Fetch

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

    func fetchSessions() {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        sessions = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Routine CRUD

    @discardableResult
    func createRoutine(name: String, icon: String, colorHex: String) -> Routine {
        let routine = Routine(name: name, colorHex: colorHex, icon: icon)
        routine.sortOrder = routines.count
        modelContext.insert(routine)
        save()
        fetchRoutines()
        return routine
    }

    func updateRoutine(_ routine: Routine, name: String, icon: String, colorHex: String) {
        routine.name = name
        routine.icon = icon
        routine.colorHex = colorHex
        save()
        fetchRoutines()
    }

    func archiveRoutine(_ routine: Routine) {
        routine.isArchived = true
        save()
        fetchRoutines()
    }

    func deleteRoutine(_ routine: Routine) {
        modelContext.delete(routine)
        save()
        fetchRoutines()
    }

    func saveContext() {
        save()
    }

    func addExerciseToRoutine(_ routine: Routine,
                              exercise: Exercise,
                              sets: Int = 3,
                              reps: Int = 10,
                              restSeconds: Int = 90) {
        let re = RoutineExercise(sortOrder: routine.templateExercises.count,
                                 defaultSets: sets,
                                 defaultReps: reps,
                                 restSeconds: restSeconds)
        re.exercise = exercise
        routine.templateExercises.append(re)
        modelContext.insert(re)
        save()
    }

    func removeExerciseFromRoutine(_ routine: Routine, routineExercise: RoutineExercise) {
        routine.templateExercises.removeAll { $0.id == routineExercise.id }
        modelContext.delete(routineExercise)
        reorderRoutineExercises(routine)
        save()
    }

    func moveRoutineExercise(_ routine: Routine, fromOffsets: IndexSet, toOffset: Int) {
        var items = routine.templateExercises.sorted { $0.sortOrder < $1.sortOrder }
        items.move(fromOffsets: fromOffsets, toOffset: toOffset)
        routine.templateExercises = items
        reorderRoutineExercises(routine)
        save()
    }

    private func reorderRoutineExercises(_ routine: Routine) {
        let sorted = routine.templateExercises.sorted { $0.sortOrder < $1.sortOrder }
        for (i, re) in sorted.enumerated() { re.sortOrder = i }
    }

    func sortedTemplateExercises(for routine: Routine) -> [RoutineExercise] {
        routine.templateExercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Exercise library

    func searchExercises(query: String,
                         muscleFilter: String? = nil,
                         equipmentFilter: String? = nil) -> [Exercise] {
        var results = exerciseLibrary
        if let muscle = muscleFilter, muscle != "All" {
            results = results.filter { $0.muscleGroup == muscle }
        }
        if let equipment = equipmentFilter, equipment != "All" {
            results = results.filter { $0.equipmentType == equipment }
        }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            results = results.filter {
                $0.name.lowercased().contains(q) || $0.muscleGroup.lowercased().contains(q)
            }
        }
        return results
    }

    @discardableResult
    func createCustomExercise(name: String,
                              muscleGroup: String,
                              equipmentType: String,
                              exerciseType: String) -> Exercise {
        let e = Exercise(name: name,
                         muscleGroup: muscleGroup,
                         equipmentType: equipmentType,
                         exerciseType: exerciseType,
                         isCustom: true)
        modelContext.insert(e)
        save()
        fetchExercises()
        return e
    }

    // MARK: - Session lifecycle

    @discardableResult
    func startSession(from routine: Routine) -> WorkoutSession {
        let session = WorkoutSession()
        session.routine = routine
        modelContext.insert(session)

        for re in sortedTemplateExercises(for: routine) {
            guard let exercise = re.exercise else { continue }
            let pe = PerformedExercise(exerciseName: exercise.name,
                                       muscleGroup: exercise.muscleGroup,
                                       sortOrder: re.sortOrder)
            pe.exercise = exercise
            pe.session = session
            session.performedExercises.append(pe)
            modelContext.insert(pe)

            let lastWeights = previousWeights(for: exercise)
            for setIndex in 0..<max(re.defaultSets, 1) {
                let set = PerformedSet(setNumber: setIndex + 1)
                set.reps = re.defaultReps
                // Auto-fill from the last session of this exercise; fall back to routine default.
                if setIndex < lastWeights.count {
                    set.weightKg = lastWeights[setIndex]
                } else if let def = re.defaultWeightKg {
                    set.weightKg = def
                }
                set.performedExercise = pe
                pe.sets.append(set)
                modelContext.insert(set)
            }
        }

        activeSession = session
        save()
        return session
    }

    @discardableResult
    func startEmptySession() -> WorkoutSession {
        let session = WorkoutSession()
        modelContext.insert(session)
        activeSession = session
        save()
        return session
    }

    func addExerciseToActiveSession(_ exercise: Exercise) {
        guard let session = activeSession else { return }
        let pe = PerformedExercise(exerciseName: exercise.name,
                                   muscleGroup: exercise.muscleGroup,
                                   sortOrder: session.performedExercises.count)
        pe.exercise = exercise
        pe.session = session
        session.performedExercises.append(pe)
        modelContext.insert(pe)

        let defaultSets = 3
        let lastWeights = previousWeights(for: exercise)
        for setIndex in 0..<defaultSets {
            let set = PerformedSet(setNumber: setIndex + 1)
            if setIndex < lastWeights.count { set.weightKg = lastWeights[setIndex] }
            set.performedExercise = pe
            pe.sets.append(set)
            modelContext.insert(set)
        }
        save()
    }

    func removePerformedExercise(_ pe: PerformedExercise) {
        guard let session = activeSession else { return }
        session.performedExercises.removeAll { $0.id == pe.id }
        modelContext.delete(pe)
        let sorted = session.performedExercises.sorted { $0.sortOrder < $1.sortOrder }
        for (i, item) in sorted.enumerated() { item.sortOrder = i }
        recalculateVolume(for: session)
        save()
    }

    func sortedPerformedExercises(in session: WorkoutSession) -> [PerformedExercise] {
        session.performedExercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    func sortedSets(in pe: PerformedExercise) -> [PerformedSet] {
        pe.sets.sorted { $0.setNumber < $1.setNumber }
    }

    // MARK: - Set logging

    func completeSet(_ set: PerformedSet, reps: Int?, weight: Double?, restSeconds: Int = 90) {
        guard !set.isCompleted else { return }
        set.reps = reps
        set.weightKg = weight
        set.isCompleted = true
        set.timestamp = Date()

        // PR detection against the exercise's all-time best weight.
        if let weight, weight > 0,
           let exercise = set.performedExercise?.exercise {
            if weight > (exercise.prMaxWeight ?? 0) {
                set.isPR = true
                exercise.prMaxWeight = weight
                set.performedExercise?.session?.numberOfPRs += 1
            }
            let volume = weight * Double(reps ?? 0)
            if volume > (exercise.prMaxVolume ?? 0) {
                exercise.prMaxVolume = volume
            }
        }

        if let session = set.performedExercise?.session {
            recalculateVolume(for: session)
        }
        save()
        startRestTimer(seconds: restSeconds)
    }

    func uncompleteSet(_ set: PerformedSet) {
        guard set.isCompleted else { return }
        set.isCompleted = false
        if set.isPR {
            set.isPR = false
            set.performedExercise?.session?.numberOfPRs = max(0, (set.performedExercise?.session?.numberOfPRs ?? 1) - 1)
        }
        if let session = set.performedExercise?.session {
            recalculateVolume(for: session)
        }
        save()
    }

    func addSet(to pe: PerformedExercise) {
        let existing = sortedSets(in: pe)
        let set = PerformedSet(setNumber: (existing.last?.setNumber ?? 0) + 1)
        if let last = existing.last {
            // Copy the previous set's values as a starting point.
            set.reps = last.reps
            set.weightKg = last.weightKg
        }
        set.performedExercise = pe
        pe.sets.append(set)
        modelContext.insert(set)
        save()
    }

    func removeSet(from pe: PerformedExercise, at set: PerformedSet) {
        pe.sets.removeAll { $0.id == set.id }
        modelContext.delete(set)
        for (i, s) in sortedSets(in: pe).enumerated() { s.setNumber = i + 1 }
        if let session = pe.session { recalculateVolume(for: session) }
        save()
    }

    private func recalculateVolume(for session: WorkoutSession) {
        let volume = session.performedExercises
            .flatMap { $0.sets }
            .filter { $0.isCompleted }
            .reduce(0.0) { $0 + ($1.weightKg ?? 0) * Double($1.reps ?? 0) }
        session.totalVolumeKg = volume
    }

    // MARK: - Finish / discard

    @discardableResult
    func finishSession() -> WorkoutSession? {
        guard let session = activeSession, !session.isCompleted else { return nil }
        let end = Date()
        session.endTime = end
        session.durationSeconds = max(0, Int(end.timeIntervalSince(session.startTime)))
        session.isCompleted = true
        session.routine?.lastPerformedAt = end
        activeSession = nil
        stopRestTimer()
        save()
        fetchSessions()
        fetchRoutines()
        return session
    }

    func discardSession() {
        guard let session = activeSession else { return }
        activeSession = nil
        stopRestTimer()
        modelContext.delete(session)
        save()
    }

    // MARK: - Rest timer

    func startRestTimer(seconds: Int) {
        guard seconds > 0 else { return }
        restTimerSeconds = seconds
        restTimerRunning = true
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.restTimerSeconds > 0 {
                    self.restTimerSeconds -= 1
                    if self.restTimerSeconds == 0 {
                        self.stopRestTimer()
                    }
                } else {
                    self.stopRestTimer()
                }
            }
        }
    }

    func adjustRestTimer(by seconds: Int) {
        restTimerSeconds = max(0, restTimerSeconds + seconds)
        if restTimerSeconds == 0 { stopRestTimer() }
    }

    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restTimerRunning = false
        restTimerSeconds = 0
    }

    // MARK: - History

    func getExerciseHistory(for exercise: Exercise, limit: Int = 50) -> [ExerciseHistoryEntry] {
        let all = (try? modelContext.fetch(FetchDescriptor<PerformedExercise>())) ?? []
        let relevant = all
            .filter { $0.exercise?.id == exercise.id && $0.session?.isCompleted == true }
            .sorted { ($0.session?.startTime ?? .distantPast) > ($1.session?.startTime ?? .distantPast) }

        return relevant.prefix(limit).map { pe in
            let sets = pe.sets.filter { $0.isCompleted }
            let bestWeight = sets.compactMap { $0.weightKg }.max()
            let bestReps = sets.compactMap { $0.reps }.max()
            let volume = sets.reduce(0.0) { $0 + ($1.weightKg ?? 0) * Double($1.reps ?? 0) }
            return ExerciseHistoryEntry(
                date: pe.session?.startTime ?? Date(),
                bestWeight: bestWeight,
                bestReps: bestReps,
                totalVolume: volume,
                setCount: sets.count
            )
        }
    }

    /// Weight used per set index in the most recent completed session of this exercise.
    func previousWeights(for exercise: Exercise) -> [Double?] {
        let all = (try? modelContext.fetch(FetchDescriptor<PerformedExercise>())) ?? []
        let relevant = all
            .filter { $0.exercise?.id == exercise.id && $0.session?.isCompleted == true }
            .sorted { ($0.session?.startTime ?? .distantPast) > ($1.session?.startTime ?? .distantPast) }
        guard let latest = relevant.first else { return [] }
        return latest.sets
            .sorted { $0.setNumber < $1.setNumber }
            .map { $0.weightKg }
    }

    func getLastWeight(for exercise: Exercise) -> Double? {
        previousWeights(for: exercise).compactMap { $0 }.first
    }

    /// All-time recent PR sets across every exercise, newest first.
    func recentPRSets(limit: Int = 10) -> [PerformedSet] {
        let all = (try? modelContext.fetch(FetchDescriptor<PerformedSet>(
            predicate: #Predicate { $0.isPR },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        ))) ?? []
        return Array(all.prefix(limit))
    }

    private func save() {
        try? modelContext.save()
    }
}

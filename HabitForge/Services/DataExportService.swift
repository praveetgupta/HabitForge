import Foundation
import SwiftData

/// Serialises the whole local store to JSON so the user can get their data out of the app.
/// HabitForge keeps everything on-device, so this is the only backup route — it is a plain,
/// documented format rather than an opaque archive, and weights stay in kilograms
/// regardless of the display unit.
@MainActor
enum DataExportService {
    static let formatVersion = 1

    // MARK: - Transfer types

    struct Export: Codable {
        var formatVersion: Int
        var exportedAt: Date
        var appVersion: String
        var habits: [HabitExport]
        var todos: [TodoExport]
        var areas: [AreaExport]
        var projects: [ProjectExport]
        var routines: [RoutineExport]
        var sessions: [SessionExport]
    }

    struct HabitExport: Codable {
        var name: String
        var icon: String
        var colorHex: String
        var habitType: String
        var frequency: String
        var targetCount: Int
        var scheduledDays: [Int]
        var tracksDuration: Bool
        var targetDurationSeconds: Int?
        var tracksCount: Bool
        var targetCountValue: Int?
        var countUnit: String?
        var currentStreak: Int
        var bestStreak: Int
        var totalCompletions: Int
        var isArchived: Bool
        var createdAt: Date
        var entries: [HabitEntryExport]
    }

    struct HabitEntryExport: Codable {
        var date: Date
        var isCompleted: Bool
        var durationSeconds: Int?
        var countValue: Int?
        var note: String?
        var mood: String?
    }

    struct TodoExport: Codable {
        var title: String
        var notes: String
        var status: String
        var priority: Int
        var tags: [String]
        var whenDate: Date?
        var deadline: Date?
        var isEvening: Bool
        var isRepeating: Bool
        var repeatType: String?
        var projectName: String?
        var areaName: String?
        var createdAt: Date
        var completedAt: Date?
        var checklist: [ChecklistItemExport]
    }

    struct ChecklistItemExport: Codable {
        var title: String
        var isCompleted: Bool
    }

    struct AreaExport: Codable {
        var name: String
        var icon: String
    }

    struct ProjectExport: Codable {
        var name: String
        var notes: String
        var icon: String
        var colorHex: String
        var status: String
        var areaName: String?
        var deadline: Date?
    }

    struct RoutineExport: Codable {
        var name: String
        var icon: String
        var colorHex: String
        var isArchived: Bool
        var exercises: [RoutineExerciseExport]
    }

    struct RoutineExerciseExport: Codable {
        var exerciseName: String
        var muscleGroup: String
        var defaultSets: Int
        var defaultReps: Int
        var defaultWeightKg: Double?
        var restSeconds: Int
    }

    struct SessionExport: Codable {
        var startTime: Date
        var endTime: Date?
        var durationSeconds: Int?
        var routineName: String?
        var totalVolumeKg: Double
        var numberOfPRs: Int
        var mood: String?
        var notes: String?
        var exercises: [PerformedExerciseExport]
    }

    struct PerformedExerciseExport: Codable {
        var exerciseName: String
        var muscleGroup: String
        var sets: [PerformedSetExport]
    }

    struct PerformedSetExport: Codable {
        var setNumber: Int
        var setType: String
        var reps: Int?
        var weightKg: Double?
        var isCompleted: Bool
        var isPR: Bool
    }

    // MARK: - Building

    static func buildExport(modelContext: ModelContext) -> Export {
        let habits = fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)]), in: modelContext)
        let todos = fetch(FetchDescriptor<Todo>(sortBy: [SortDescriptor(\.createdAt)]), in: modelContext)
        let areas = fetch(FetchDescriptor<Area>(sortBy: [SortDescriptor(\.sortOrder)]), in: modelContext)
        let projects = fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.sortOrder)]), in: modelContext)
        let routines = fetch(FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.sortOrder)]), in: modelContext)
        let sessions = fetch(
            FetchDescriptor<WorkoutSession>(
                predicate: #Predicate { $0.isCompleted },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            ),
            in: modelContext
        )

        return Export(
            formatVersion: formatVersion,
            exportedAt: Date(),
            appVersion: Bundle.main.shortVersionString,
            habits: habits.map(habitExport),
            todos: todos.map(todoExport),
            areas: areas.map { AreaExport(name: $0.name, icon: $0.icon) },
            projects: projects.map(projectExport),
            routines: routines.map(routineExport),
            sessions: sessions.map(sessionExport)
        )
    }

    static func encode(_ export: Export) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }

    /// Writes the export to a uniquely-named file in the temporary directory and returns its
    /// URL, ready to hand to a `ShareLink`.
    static func writeExportFile(modelContext: ModelContext) throws -> URL {
        let data = try encode(buildExport(modelContext: modelContext))
        let stamp = ISO8601DateFormatter.filenameSafe.string(from: Date())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("HabitForge-Export-\(stamp).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Mapping

    private static func fetch<T>(_ descriptor: FetchDescriptor<T>, in context: ModelContext) -> [T] {
        (try? context.fetch(descriptor)) ?? []
    }

    private static func habitExport(_ habit: Habit) -> HabitExport {
        HabitExport(
            name: habit.name,
            icon: habit.icon,
            colorHex: habit.colorHex,
            habitType: habit.habitType,
            frequency: habit.frequency,
            targetCount: habit.targetCount,
            scheduledDays: habit.scheduledDays,
            tracksDuration: habit.tracksDuration,
            targetDurationSeconds: habit.targetDurationSeconds,
            tracksCount: habit.tracksCount,
            targetCountValue: habit.targetCountValue,
            countUnit: habit.countUnit,
            currentStreak: habit.currentStreak,
            bestStreak: habit.bestStreak,
            totalCompletions: habit.totalCompletions,
            isArchived: habit.isArchived,
            createdAt: habit.createdAt,
            entries: habit.entries
                .sorted { $0.date < $1.date }
                .map {
                    HabitEntryExport(
                        date: $0.date,
                        isCompleted: $0.isCompleted,
                        durationSeconds: $0.durationSeconds,
                        countValue: $0.countValue,
                        note: $0.note,
                        mood: $0.mood
                    )
                }
        )
    }

    private static func todoExport(_ todo: Todo) -> TodoExport {
        TodoExport(
            title: todo.title,
            notes: todo.notes,
            status: todo.status,
            priority: todo.priority,
            tags: todo.tags,
            whenDate: todo.whenDate,
            deadline: todo.deadline,
            isEvening: todo.isEvening,
            isRepeating: todo.isRepeating,
            repeatType: todo.repeatType,
            projectName: todo.project?.name,
            areaName: todo.area?.name,
            createdAt: todo.createdAt,
            completedAt: todo.completedAt,
            checklist: todo.checklist
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { ChecklistItemExport(title: $0.title, isCompleted: $0.isCompleted) }
        )
    }

    private static func projectExport(_ project: Project) -> ProjectExport {
        ProjectExport(
            name: project.name,
            notes: project.notes,
            icon: project.icon,
            colorHex: project.colorHex,
            status: project.status,
            areaName: project.area?.name,
            deadline: project.deadline
        )
    }

    private static func routineExport(_ routine: Routine) -> RoutineExport {
        RoutineExport(
            name: routine.name,
            icon: routine.icon,
            colorHex: routine.colorHex,
            isArchived: routine.isArchived,
            exercises: routine.templateExercises
                .sorted { $0.sortOrder < $1.sortOrder }
                .map {
                    RoutineExerciseExport(
                        exerciseName: $0.exercise?.name ?? "Unknown",
                        muscleGroup: $0.exercise?.muscleGroup ?? "",
                        defaultSets: $0.defaultSets,
                        defaultReps: $0.defaultReps,
                        defaultWeightKg: $0.defaultWeightKg,
                        restSeconds: $0.restSeconds
                    )
                }
        )
    }

    private static func sessionExport(_ session: WorkoutSession) -> SessionExport {
        SessionExport(
            startTime: session.startTime,
            endTime: session.endTime,
            durationSeconds: session.durationSeconds,
            routineName: session.routine?.name,
            totalVolumeKg: session.totalVolumeKg,
            numberOfPRs: session.numberOfPRs,
            mood: session.mood,
            notes: session.notes,
            exercises: session.performedExercises
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { pe in
                    PerformedExerciseExport(
                        exerciseName: pe.exerciseName,
                        muscleGroup: pe.muscleGroup,
                        sets: pe.sets
                            .sorted { $0.setNumber < $1.setNumber }
                            .map {
                                PerformedSetExport(
                                    setNumber: $0.setNumber,
                                    setType: $0.setType,
                                    reps: $0.reps,
                                    weightKg: $0.weightKg,
                                    isCompleted: $0.isCompleted,
                                    isPR: $0.isPR
                                )
                            }
                    )
                }
        )
    }
}

extension Bundle {
    var shortVersionString: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var buildNumber: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

private extension ISO8601DateFormatter {
    static let filenameSafe: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withYear, .withMonth, .withDay]
        return f
    }()
}

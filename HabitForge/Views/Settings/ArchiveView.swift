import SwiftUI
import SwiftData

/// Archiving is how habits and routines are retired without losing their history, but until
/// now nothing in the app could bring one back. This is that screen: restore, or delete for
/// good along with the entries and sessions hanging off it.
struct ArchiveView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<Habit> { $0.isArchived }, sort: \Habit.name)
    private var archivedHabits: [Habit]

    @Query(filter: #Predicate<Routine> { $0.isArchived }, sort: \Routine.name)
    private var archivedRoutines: [Routine]

    @State private var habitPendingDeletion: Habit?
    @State private var routinePendingDeletion: Routine?

    var body: some View {
        List {
            if archivedHabits.isEmpty && archivedRoutines.isEmpty {
                ContentUnavailableView(
                    "Nothing archived",
                    systemImage: "archivebox",
                    description: Text("Archived habits and routines are kept here so you can restore them later.")
                )
                .listRowBackground(Color.clear)
            }

            if !archivedHabits.isEmpty {
                Section("Habits") {
                    ForEach(archivedHabits) { habit in
                        row(icon: habit.icon,
                            title: habit.name,
                            subtitle: "\(habit.totalCompletions) completions · best streak \(habit.bestStreak)",
                            restore: { restore(habit) },
                            delete: { habitPendingDeletion = habit })
                    }
                }
            }

            if !archivedRoutines.isEmpty {
                Section("Routines") {
                    ForEach(archivedRoutines) { routine in
                        row(icon: routine.icon,
                            title: routine.name,
                            subtitle: "\(routine.templateExercises.count) exercises · \(routine.sessions.count) sessions",
                            restore: { restore(routine) },
                            delete: { routinePendingDeletion = routine })
                    }
                }
            }
        }
        .navigationTitle("Archive")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete this habit permanently?",
            isPresented: .init(get: { habitPendingDeletion != nil },
                               set: { if !$0 { habitPendingDeletion = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let habit = habitPendingDeletion { delete(habit) }
                habitPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { habitPendingDeletion = nil }
        } message: {
            Text("Its entire entry history is deleted too.")
        }
        .confirmationDialog(
            "Delete this routine permanently?",
            isPresented: .init(get: { routinePendingDeletion != nil },
                               set: { if !$0 { routinePendingDeletion = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let routine = routinePendingDeletion { delete(routine) }
                routinePendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { routinePendingDeletion = nil }
        } message: {
            Text("Every workout logged against this routine is deleted too.")
        }
    }

    private func row(icon: String,
                     title: String,
                     subtitle: String,
                     restore: @escaping () -> Void,
                     delete: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Text(icon).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Restore", action: restore)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive, action: delete)
        }
    }

    private func restore(_ habit: Habit) {
        habit.isArchived = false
        try? modelContext.save()
        if habit.reminderEnabled, habit.reminderTime != nil {
            NotificationService.shared.scheduleHabitReminder(habit: habit)
        }
    }

    private func restore(_ routine: Routine) {
        routine.isArchived = false
        try? modelContext.save()
    }

    private func delete(_ habit: Habit) {
        NotificationService.shared.cancelHabitReminder(habitId: habit.id)
        modelContext.delete(habit)
        try? modelContext.save()
    }

    private func delete(_ routine: Routine) {
        modelContext.delete(routine)
        try? modelContext.save()
    }
}

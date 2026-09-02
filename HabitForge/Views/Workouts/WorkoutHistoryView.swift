import SwiftUI
import SwiftData

/// Past sessions grouped by month.
struct WorkoutHistoryView: View {
    let viewModel: WorkoutViewModel

    var body: some View {
        List {
            if viewModel.sessions.isEmpty {
                ContentUnavailableView(
                    "No workouts yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Finished workouts will appear here.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedByMonth(), id: \.month) { group in
                    Section(group.month) {
                        ForEach(group.sessions, id: \.id) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                SessionRowView(session: session)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchSessions()
        }
    }

    private func groupedByMonth() -> [(month: String, sessions: [WorkoutSession])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: viewModel.sessions) { session in
            formatter.string(from: session.startTime)
        }
        // Preserve reverse-chronological month order.
        let order = viewModel.sessions.map { formatter.string(from: $0.startTime) }
        var seen = Set<String>()
        let months = order.filter { seen.insert($0).inserted }

        return months.map { month in
            (month: month, sessions: grouped[month] ?? [])
        }
    }
}

// MARK: - Session detail

struct SessionDetailView: View {
    let session: WorkoutSession

    @State private var notes = ""

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    StatCell(value: WorkoutSessionRowFormatter.duration(session.durationSeconds), label: "Duration", tint: .blue)
                    StatCell(value: volumeText, label: "Volume", tint: .purple)
                    StatCell(value: "\(session.numberOfPRs)", label: "PRs", tint: .yellow)
                    StatCell(value: session.mood ?? "—", label: "Mood", tint: .orange)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            } header: {
                Text(session.startTime.formatted(date: .long, time: .shortened))
            }

            ForEach(session.performedExercises.sorted { $0.sortOrder < $1.sortOrder }, id: \.id) { pe in
                Section(pe.exerciseName) {
                    ForEach(pe.sets.sorted { $0.setNumber < $1.setNumber }, id: \.id) { set in
                        HStack {
                            Text("Set \(set.setNumber)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let w = set.weightKg, let r = set.reps {
                                Text("\(Int(w)) kg × \(r)")
                                    .font(.subheadline.monospacedDigit())
                            } else if let r = set.reps {
                                Text("\(r) reps")
                                    .font(.subheadline.monospacedDigit())
                            }
                            if set.isPR {
                                Text("PR")
                                    .font(.caption2.weight(.heavy))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.yellow.opacity(0.2)))
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 70)
                    .onChange(of: notes) { _, newValue in
                        session.notes = newValue
                        try? session.modelContext?.save()
                    }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(session.routine?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notes = session.notes ?? ""
        }
    }

    private var volumeText: String {
        session.totalVolumeKg > 0 ? "\(Int(session.totalVolumeKg).formatted()) kg" : "—"
    }
}

private struct StatCell: View {
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

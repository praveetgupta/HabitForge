import SwiftUI
import SwiftData

/// Post-session summary sheet: duration, volume, PRs, mood.
struct WorkoutSummaryView: View {
    let session: WorkoutSession

    @Environment(\.dismiss) private var dismiss
    @State private var mood = ""

    private let moodOptions = ["😞", "😐", "🙂", "😄"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 6) {
                        Text(session.routine?.icon ?? "🏋️")
                            .font(.system(size: 56))
                        Text(session.routine?.name ?? "Workout")
                            .font(.title2.bold())
                        Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Stat grid
                    HStack(spacing: 12) {
                        SummaryStatCell(value: durationText, label: "Duration", icon: "clock.fill", tint: .blue)
                        SummaryStatCell(value: volumeText, label: "Volume", icon: "scalemass.fill", tint: .purple)
                        SummaryStatCell(value: "\(session.numberOfPRs)", label: "PRs", icon: "trophy.fill", tint: .yellow)
                        SummaryStatCell(value: "\(exerciseCount)", label: "Exercises", icon: "list.bullet", tint: .green)
                    }
                    .padding(.horizontal)

                    // Exercises performed
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Exercises")
                            .font(.headline)
                        ForEach(session.performedExercises.sorted { $0.sortOrder < $1.sortOrder }, id: \.id) { pe in
                            let done = pe.sets.filter { $0.isCompleted }.count
                            HStack {
                                Text(pe.exerciseName)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(done)/\(pe.sets.count) sets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Mood
                    VStack(spacing: 10) {
                        Text("How did it feel?")
                            .font(.headline)
                        HStack(spacing: 20) {
                            ForEach(moodOptions, id: \.self) { option in
                                Button {
                                    mood = option
                                    session.mood = option
                                    try? session.modelContext?.save()
                                } label: {
                                    Text(option)
                                        .font(.system(size: 34))
                                        .padding(8)
                                        .background(
                                            Circle().fill(mood == option ? Color.blue.opacity(0.15) : Color.clear)
                                        )
                                        .overlay {
                                            Circle().stroke(Color.blue.opacity(mood == option ? 0.4 : 0), lineWidth: 2)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let m = session.mood { mood = m }
            }
        }
    }

    private var exerciseCount: Int { session.performedExercises.count }

    private var durationText: String {
        WorkoutSessionRowFormatter.duration(session.durationSeconds)
    }

    private var volumeText: String {
        session.totalVolumeKg > 0 ? "\(Int(session.totalVolumeKg).formatted()) kg" : "—"
    }
}

struct SummaryStatCell: View {
    let value: String
    let label: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

// Shared formatting for session rows across views.
enum WorkoutSessionRowFormatter {
    static func duration(_ seconds: Int?) -> String {
        guard let seconds, seconds > 0 else { return "—" }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}

import SwiftUI
import SwiftData
import Charts

/// Overall training progress: weekly volume, totals, and recent PRs.
struct WorkoutProgressView: View {
    let viewModel: WorkoutViewModel

    private struct WeekVolume: Identifiable {
        let id = UUID()
        let weekStart: Date
        let volume: Double
        let sessions: Int
    }

    @State private var weeklyVolumes: [WeekVolume] = []
    @State private var settings = AppSettings.shared

    private var unit: WeightUnit { settings.weightUnit }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    StatCell(value: "\(viewModel.sessions.count)", label: "Workouts", tint: .blue)
                    StatCell(value: totalVolumeText, label: "Total volume", tint: .purple)
                    StatCell(value: totalPRText, label: "PRs", tint: .yellow)
                    StatCell(value: totalTimeText, label: "Time trained", tint: .green)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            }

            Section("Weekly Volume (\(unit.shortName))") {
                if weeklyVolumes.isEmpty {
                    Text("Finish a workout to see progress here.")
                        .foregroundStyle(.tertiary)
                } else {
                    Chart(weeklyVolumes) { week in
                        BarMark(
                            x: .value("Week", week.weekStart, unit: .weekOfYear),
                            y: .value("Volume", unit.fromKilograms(week.volume))
                        )
                        .foregroundStyle(.purple.opacity(0.8))
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }
            }

            Section("Recent PRs") {
                let prs = viewModel.recentPRSets(limit: 10)
                if prs.isEmpty {
                    Text("No PRs yet — they'll show up as you lift heavier.")
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(prs, id: \.id) { set in
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                            Text(set.performedExercise?.exerciseName ?? "Exercise")
                                .font(.subheadline)
                            Spacer()
                            if let w = set.weightKg {
                                Text("\(unit.format(kilograms: w)) × \(set.reps ?? 0)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            Text(set.timestamp.formatted(date: .numeric, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchSessions()
            weeklyVolumes = Self.computeWeeklyVolumes(sessions: viewModel.sessions)
        }
    }

    private static func computeWeeklyVolumes(sessions: [WorkoutSession], weeks: Int = 8) -> [WeekVolume] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let interval = cal.dateInterval(of: .weekOfYear, for: today) else { return [] }

        return (0..<weeks).reversed().compactMap { weeksAgo in
            guard let weekDate = cal.date(byAdding: .weekOfYear, value: -weeksAgo, to: interval.start) else { return nil }
            let inWeek = sessions.filter { cal.isDate($0.startTime, equalTo: weekDate, toGranularity: .weekOfYear) }
            let volume = inWeek.reduce(0.0) { $0 + $1.totalVolumeKg }
            return WeekVolume(weekStart: weekDate, volume: volume, sessions: inWeek.count)
        }
    }

    private var totalVolumeText: String {
        let total = viewModel.sessions.reduce(0.0) { $0 + $1.totalVolumeKg }
        return total > 0 ? unit.format(kilograms: total) : "—"
    }

    private var totalPRText: String {
        let total = viewModel.sessions.reduce(0) { $0 + $1.numberOfPRs }
        return "\(total)"
    }

    private var totalTimeText: String {
        let seconds = viewModel.sessions.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
        return WorkoutSessionRowFormatter.duration(seconds)
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

import SwiftUI
import Charts

/// Per-exercise history: stats, weight & volume charts, session-by-session list.
struct ExerciseDetailView: View {
    let exercise: Exercise
    let viewModel: WorkoutViewModel

    @State private var history: [ExerciseHistoryEntry] = []

    @State private var settings = AppSettings.shared

    private var chronological: [ExerciseHistoryEntry] { history.reversed() }

    private var unit: WeightUnit { settings.weightUnit }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    StatCell(value: prText, label: "Best weight", tint: .yellow)
                    StatCell(value: volumePRText, label: "Best volume", tint: .purple)
                    StatCell(value: "\(history.count)", label: "Sessions", tint: .blue)
                    StatCell(value: "\(totalSets)", label: "Sets", tint: .green)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            }

            if chronological.count >= 2 {
                Section("Weight Over Time (\(unit.shortName))") {
                    Chart {
                        ForEach(Array(chronological.enumerated()), id: \.offset) { index, entry in
                            if let w = entry.bestWeight {
                                LineMark(x: .value("Date", entry.date), y: .value(unit.shortName, unit.fromKilograms(w)))
                                    .foregroundStyle(.blue)
                                    .symbol(Circle())
                                PointMark(x: .value("Date", entry.date), y: .value(unit.shortName, unit.fromKilograms(w)))
                                    .foregroundStyle(.blue)
                                if index == chronological.count - 1 {
                                    RuleMark(y: .value(unit.shortName, unit.fromKilograms(w)))
                                        .foregroundStyle(.blue.opacity(0.2))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 180)
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }

                Section("Volume Over Time (\(unit.shortName))") {
                    Chart {
                        ForEach(chronological) { entry in
                            BarMark(
                                x: .value("Date", entry.date, unit: .day),
                                y: .value(unit.shortName, unit.fromKilograms(entry.totalVolume))
                            )
                            .foregroundStyle(.purple.opacity(0.8))
                        }
                    }
                    .frame(height: 180)
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }
            }

            Section("Sessions") {
                if history.isEmpty {
                    Text("No logged sessions yet.")
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(history) { entry in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.body.weight(.medium))
                                Spacer()
                                if let best = entry.bestWeight {
                                    Text("\(unit.format(kilograms: best)) × \(entry.bestReps ?? 0)")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text("\(entry.setCount) sets · \(unit.format(kilograms: entry.totalVolume)) total")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            history = viewModel.getExerciseHistory(for: exercise)
        }
    }

    private var prText: String {
        if let pr = exercise.prMaxWeight { return unit.format(kilograms: pr) }
        return "—"
    }

    private var volumePRText: String {
        if let v = exercise.prMaxVolume, v > 0 { return unit.format(kilograms: v) }
        return "—"
    }

    private var totalSets: Int {
        history.reduce(0) { $0 + $1.setCount }
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

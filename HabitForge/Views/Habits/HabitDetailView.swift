import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    let viewModel: HabitViewModel

    @State private var calendarMonth = Date()
    @State private var chartPeriod: ChartPeriod = .month

    private var habitColor: Color {
        Color(hex: habit.colorHex) ?? .accentColor
    }

    private var todayProgress: Double {
        viewModel.progressFraction(habit, on: Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                heroRing

                statsRow

                HabitCalendarView(habit: habit, viewModel: viewModel, displayedMonth: $calendarMonth)

                HabitChartView(habit: habit, viewModel: viewModel, period: $chartPeriod)

                entryHistorySection
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.recalculateStreak(for: habit)
        }
    }

    private var heroRing: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(habitColor.opacity(0.15), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: min(todayProgress, 1))
                    .stroke(
                        habitColor,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.55, dampingFraction: 0.82), value: todayProgress)

                VStack(spacing: 4) {
                    Text("\(habit.currentStreak)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("day streak")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(Int(round(todayProgress * 100)))% today")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(habitColor)
                }
            }
            .frame(width: 168, height: 168)

            HStack(spacing: 8) {
                Text(habit.icon)
                    .font(.title2)
                Text(habit.habitType == "Break" ? "Break habit" : "Build habit")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var statsRow: some View {
        let rate30 = viewModel.completionRate(for: habit, lastDays: 30)
        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            StatBox(label: "Current streak", value: "\(habit.currentStreak)")
            StatBox(label: "Best streak", value: "\(habit.bestStreak)")
            StatBox(label: "30-day rate", value: "\(Int(round(rate30 * 100)))%")
            StatBox(label: "Total completions", value: "\(habit.totalCompletions)")
        }
    }

    private var entryHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent entries")
                .font(.headline)

            let sorted = habit.entries.sorted { $0.date > $1.date }
            if sorted.isEmpty {
                Text("No entries yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sorted.prefix(20).enumerated()), id: \.element.id) { index, entry in
                        entryRow(entry)
                        if index < min(19, sorted.prefix(20).count - 1) {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func entryRow(_ entry: HabitEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(habitColor.opacity(entry.isCompleted ? 0.35 : 0.12))
                .frame(width: 4)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year(.twoDigits))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(entry.isCompleted ? "Completed" : "Not completed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(entry.isCompleted ? Color.green : Color.secondary)
                }

                if let mood = entry.mood, !mood.isEmpty {
                    HStack(spacing: 6) {
                        Text("Mood")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.tertiary)
                        Text(mood)
                            .font(.subheadline)
                    }
                }

                if let note = entry.note, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Note")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.tertiary)
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    if let c = entry.countValue {
                        Label("\(c)", systemImage: "number")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let s = entry.durationSeconds {
                        Label("\(s / 60)m \(s % 60)s", systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }
}

struct StatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

enum ChartPeriod: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case quarter = "3 Mo"
    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
    let ctx = ModelContext(container)
    let h = Habit(name: "Read", icon: "📚", colorHex: "#5856D6")
    ctx.insert(h)
    let vm = HabitViewModel(modelContext: ctx)
    return NavigationStack {
        HabitDetailView(habit: h, viewModel: vm)
    }
}

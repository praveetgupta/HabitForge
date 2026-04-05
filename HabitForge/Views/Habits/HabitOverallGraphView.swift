import SwiftUI
import SwiftData
import Charts

struct HabitOverallGraphView: View {
    let viewModel: HabitViewModel
    let habits: [Habit]
    /// Tighter layout when embedded on the dashboard card.
    var isCompact: Bool = false

    @State private var windowDays = 7

    private var calendar: Calendar { Calendar.current }

    private var rawOverallPoints: [(date: Date, percentage: Double)] {
        viewModel.overallDailyCompletion(days: windowDays, habits: habits)
    }

    /// Earliest habit creation (start of day); days before have no tracking yet.
    private var trackingStartDay: Date {
        guard let earliest = habits.map(\.createdAt).min() else {
            return calendar.startOfDay(for: Date())
        }
        return calendar.startOfDay(for: earliest)
    }

    private var enrichedChartPoints: [OverallBarPoint] {
        rawOverallPoints.map { p in
            let day = calendar.startOfDay(for: p.date)
            let preTracking = day < trackingStartDay
            if preTracking {
                return OverallBarPoint(
                    date: p.date,
                    barValue: 4,
                    rawPercentage: 0,
                    isPreTracking: true
                )
            }
            return OverallBarPoint(
                date: p.date,
                barValue: p.percentage,
                rawPercentage: p.percentage,
                isPreTracking: false
            )
        }
    }

    /// Days in range with real tracking where the user made some progress.
    private var daysWithRecordedProgress: Int {
        enrichedChartPoints.filter { !$0.isPreTracking && $0.rawPercentage > 0.5 }.count
    }

    private var showSparseDataHint: Bool {
        daysWithRecordedProgress < 3
    }

    private var chartHeight: CGFloat { isCompact ? 150 : 230 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Range", selection: $windowDays) {
                Text("7 days").tag(7)
                Text("14 days").tag(14)
                Text("30 days").tag(30)
            }
            .pickerStyle(.segmented)

            Chart {
                RuleMark(y: .value("Goal", 100))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.4))

                ForEach(enrichedChartPoints) { point in
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Complete", point.barValue),
                        width: .fixed(isCompact ? 10 : 12)
                    )
                    .foregroundStyle(barFill(for: point))
                    .cornerRadius(4)
                }
            }
            .chartYScale(domain: 0 ... 100)
            .chartPlotStyle { plot in
                plot.padding(.horizontal, 4)
            }
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let n = value.as(Int.self) {
                            Text("\(n)%")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, windowDays / 5))) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: chartHeight)

            if showSparseDataHint {
                Text("Keep going! Your progress chart fills in as you track habits over the coming days.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Text("By habit")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                    habitSparkRow(habit: habit)
                    if index < habits.count - 1 {
                        Divider()
                            .padding(.leading, 4)
                    }
                }
            }
        }
    }

    private func barFill(for point: OverallBarPoint) -> Color {
        if point.isPreTracking {
            return Color.gray.opacity(0.15)
        }
        if point.rawPercentage >= 99.5 { return .green }
        if point.rawPercentage <= 0.5 { return .gray.opacity(0.55) }
        return Color.accentColor
    }

    private enum SparkDayState {
        case completed
        case missed
        case notScheduled
    }

    private func lastSevenDayStates(habit: Habit) -> [SparkDayState] {
        let end = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -6, to: end) else { return [] }
        var d = start
        var out: [SparkDayState] = []
        while d <= end {
            let scheduled = viewModel.isScheduled(habit, on: d)
            if !scheduled {
                out.append(.notScheduled)
            } else if viewModel.isHabitCompletedForDailySummary(habit, on: d) {
                out.append(.completed)
            } else {
                out.append(.missed)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        return out
    }

    private func habitSparkRow(habit: Habit) -> some View {
        let tint = Color(hex: habit.colorHex) ?? .accentColor
        let states = lastSevenDayStates(habit: habit)
        let cell: CGFloat = isCompact ? 10 : 12
        let dot: CGFloat = 6

        return HStack(alignment: .center, spacing: 10) {
            Text(habit.icon)
                .font(.title3)
                .frame(width: 28, alignment: .center)

            Text(habit.name)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .frame(width: 88, alignment: .leading)

            HStack(spacing: isCompact ? 5 : 7) {
                ForEach(Array(states.enumerated()), id: \.offset) { _, state in
                    Group {
                        switch state {
                        case .completed:
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(tint)
                                .frame(width: cell, height: cell)
                        case .missed:
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(Color.gray.opacity(0.15))
                                )
                                .frame(width: cell, height: cell)
                        case .notScheduled:
                            Circle()
                                .fill(Color.secondary.opacity(0.22))
                                .frame(width: dot, height: dot)
                        }
                    }
                    .frame(height: max(cell, dot))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .frame(minHeight: 14)
        }
        .padding(.vertical, isCompact ? 8 : 10)
    }
}

private struct OverallBarPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let barValue: Double
    let rawPercentage: Double
    let isPreTracking: Bool
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
    let ctx = ModelContext(container)
    let h1 = Habit(name: "Walk", icon: "🚶", colorHex: "#34C759")
    let h2 = Habit(name: "Read", icon: "📚", colorHex: "#5856D6")
    ctx.insert(h1)
    ctx.insert(h2)
    let vm = HabitViewModel(modelContext: ctx)
    return NavigationStack {
        ScrollView {
            HabitOverallGraphView(viewModel: vm, habits: [h1, h2])
                .padding()
        }
        .navigationTitle("Progress")
    }
}

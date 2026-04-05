import SwiftUI
import SwiftData
import Charts

struct HabitChartView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    @Binding var period: ChartPeriod

    private var habitColor: Color {
        Color(hex: habit.colorHex) ?? .accentColor
    }

    private var data: [HabitViewModel.ChartDayPoint] {
        viewModel.chartData(for: habit, lastDays: period.days)
    }

    private var hasAnyEntries: Bool {
        !habit.entries.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Trends")
                    .font(.headline)
                Spacer()
                Picker("Period", selection: $period) {
                    ForEach(ChartPeriod.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }

            let barHeight: CGFloat = 200

            if habit.tracksDuration {
                if hasAnyEntries {
                    durationLineChart(height: barHeight)
                    completionBarChart(height: 140)
                        .padding(.top, 4)
                } else {
                    chartEmptyPlaceholder(height: barHeight, message: "No data yet")
                }
            } else if habit.tracksCount {
                if hasAnyEntries {
                    countLineChart(height: barHeight)
                    completionBarChart(height: 140)
                        .padding(.top, 4)
                } else {
                    chartEmptyPlaceholder(height: barHeight, message: "No data yet")
                }
            } else if hasAnyEntries {
                completionBarChart(height: barHeight)
            } else {
                chartEmptyPlaceholder(height: barHeight, message: "No data yet")
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func chartEmptyPlaceholder(height: CGFloat, message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func completionBarChart(height: CGFloat) -> some View {
        Chart(data) { point in
            BarMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Done", point.completion * 100)
            )
            .foregroundStyle(habitColor.gradient)
            .cornerRadius(4)
        }
        .chartYScale(domain: 0 ... 100)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { v in
                AxisGridLine()
                AxisValueLabel {
                    if let n = v.as(Int.self) {
                        Text("\(n)%")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, period.days / 6))) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: height)
    }

    private func durationLineChart(height: CGFloat) -> some View {
        Chart(data) { point in
            LineMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Minutes", point.durationMinutes ?? 0)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(habitColor)

            AreaMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Minutes", point.durationMinutes ?? 0)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(habitColor.opacity(0.12))
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, period.days / 6))) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: height)
    }

    private func countLineChart(height: CGFloat) -> some View {
        Chart(data) { point in
            LineMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Count", point.count ?? 0)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(habitColor)

            PointMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Count", point.count ?? 0)
            )
            .foregroundStyle(habitColor)
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, period.days / 6))) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: height)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
    let ctx = ModelContext(container)
    let h = Habit(name: "Meditate", icon: "🧘", colorHex: "#AF52DE")
    h.tracksDuration = true
    h.targetDurationSeconds = 600
    ctx.insert(h)
    let vm = HabitViewModel(modelContext: ctx)
    return HabitChartView(habit: h, viewModel: vm, period: .constant(.month))
        .padding()
}

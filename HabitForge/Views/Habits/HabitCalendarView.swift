import SwiftUI
import SwiftData

struct HabitCalendarView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    @Binding var displayedMonth: Date

    @State private var selectedDay: Date?
    @State private var showDaySheet = false

    private var habitColor: Color {
        Color(hex: habit.colorHex) ?? .accentColor
    }

    private var calendar: Calendar { Calendar.current }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var heatmap: [Date: HabitViewModel.HeatmapCellState] {
        viewModel.heatmapData(for: habit, in: displayedMonth)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    shiftMonth(-1)
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                }

                Spacer()
                Text(monthTitle)
                    .font(.headline.weight(.semibold))
                Spacer()

                Button {
                    shiftMonth(1)
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(weekdayHeaders.enumerated()), id: \.offset) { _, w in
                    Text(w)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(daysInMonthGrid.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .sheet(isPresented: $showDaySheet) {
            if let d = selectedDay {
                dayNoteSheet(date: d)
            }
        }
    }

    private var weekdayHeaders: [String] {
        ["M", "T", "W", "T", "F", "S", "S"]
    }

    /// Grid cells for current month (nil = empty padding cell).
    private var daysInMonthGrid: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leading = (firstWeekday + 5) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)

        var d = interval.start
        while d < interval.end {
            cells.append(d)
            d = calendar.date(byAdding: .day, value: 1, to: d) ?? d
        }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = next
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let start = calendar.startOfDay(for: day)
        let state = heatmap[start] ?? .upcoming
        let isToday = calendar.isDateInToday(start)

        return Button {
            selectedDay = start
            showDaySheet = true
        } label: {
            Text("\(calendar.component(.day, from: start))")
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(cellColor(state: state))
                .foregroundStyle(foregroundForState(state))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    if isToday {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(habitColor, lineWidth: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func foregroundForState(_ state: HabitViewModel.HeatmapCellState) -> Color {
        switch state {
        case .notScheduled:
            return .secondary.opacity(0.35)
        case .missed:
            return .secondary
        case .partial:
            return .white.opacity(0.95)
        case .done:
            return .white
        case .upcoming:
            return .secondary.opacity(0.55)
        }
    }

    private func cellColor(state: HabitViewModel.HeatmapCellState) -> Color {
        switch state {
        case .notScheduled:
            return Color.secondary.opacity(0.06)
        case .missed:
            return Color.secondary.opacity(0.22)
        case .partial(let p):
            return habitColor.opacity(0.25 + p * 0.45)
        case .done:
            return habitColor
        case .upcoming:
            return Color.secondary.opacity(0.1)
        }
    }

    @ViewBuilder
    private func dayNoteSheet(date: Date) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(date, format: .dateTime.weekday(.wide).month().day().year())
                    .font(.headline)

                if let entry = viewModel.entryForHabit(habit, on: date) {
                    if let note = entry.note, !note.isEmpty {
                        Text(note)
                            .font(.body)
                    } else {
                        Text("No note for this day.")
                            .foregroundStyle(.secondary)
                    }
                    if let mood = entry.mood {
                        Text("Mood: \(mood)")
                            .font(.subheadline)
                    }
                } else {
                    Text("No entry logged.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .navigationTitle("Day detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showDaySheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
    let ctx = ModelContext(container)
    let h = Habit(name: "Walk", icon: "🚶", colorHex: "#34C759")
    ctx.insert(h)
    let vm = HabitViewModel(modelContext: ctx)
    return HabitCalendarView(habit: h, viewModel: vm, displayedMonth: .constant(Date()))
        .padding()
}

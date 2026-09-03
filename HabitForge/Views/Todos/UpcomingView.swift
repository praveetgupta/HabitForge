import SwiftUI

struct UpcomingView: View {
    let viewModel: TodoViewModel
    @State private var todoToSchedule: Todo?

    private var groups: [(date: Date, todos: [Todo])] {
        viewModel.upcomingGroupedByDay()
    }

    var body: some View {
        Group {
            if groups.isEmpty {
                ContentUnavailableView {
                    Label("Nothing Upcoming", systemImage: "calendar")
                } description: {
                    Text("Scheduled tasks will appear here.")
                }
            } else {
                List {
                    ForEach(groups, id: \.date) { group in
                        Section {
                            rows(for: group.todos)
                        } header: {
                            HStack {
                                Text(sectionTitle(for: group.date))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                Spacer()
                                let overdue = group.todos.filter { isDeadlineOverdue($0) }.count
                                if overdue > 0 {
                                    Text("\(overdue) overdue")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Upcoming")
        .sheet(item: $todoToSchedule) { todo in
            ScheduleTodoSheet(todo: todo, viewModel: viewModel)
        }
        .onAppear { viewModel.autoPromoteUpcoming() }
    }

    /// Explicitly `@ViewBuilder`-typed rather than inlined in the `Section` — see the note
    /// in `LogbookView.rows(for:)`; the same `ChartContentBuilder` ambiguity bit here.
    @ViewBuilder
    private func rows(for todos: [Todo]) -> some View {
        ForEach(todos, id: \.id) { todo in
            TodoRowView(todo: todo, viewModel: viewModel)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        viewModel.moveToToday(todo)
                    } label: {
                        Label("Today", systemImage: "star.fill")
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        todoToSchedule = todo
                    } label: {
                        Label("Reschedule", systemImage: "calendar")
                    }
                    .tint(.blue)
                    Button {
                        viewModel.moveToSomeday(todo)
                    } label: {
                        Label("Someday", systemImage: "moon.zzz")
                    }
                    .tint(.purple)
                }
                .contextMenu {
                    TodoContextMenu(todo: todo, viewModel: viewModel)
                }
        }
    }

    private func sectionTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)    { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        // "Wednesday, Apr 8" style
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: date).day ?? 0
        if days < 7 {
            formatter.dateFormat = "EEEE, MMM d"
        } else {
            formatter.dateFormat = "MMMM d"
        }
        return formatter.string(from: date)
    }

    private func isDeadlineOverdue(_ todo: Todo) -> Bool {
        guard let dl = todo.deadline else { return false }
        return dl < Date()
    }
}

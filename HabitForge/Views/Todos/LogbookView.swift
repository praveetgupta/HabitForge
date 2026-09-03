import SwiftUI

struct LogbookView: View {
    let viewModel: TodoViewModel

    private var entries: [(date: Date, todos: [Todo])] {
        viewModel.logbookEntries()
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView {
                    Label("Nothing Logged Yet", systemImage: "book.closed")
                } description: {
                    Text("Completed tasks will appear here.")
                }
            } else {
                List {
                    ForEach(entries, id: \.date) { group in
                        Section {
                            rows(for: group.todos)
                        } header: {
                            Text(sectionTitle(for: group.date))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Logbook")
    }

    /// Explicitly `@ViewBuilder`-typed rather than inlined in the `Section`.
    /// `ForEach`'s `ChartContent` conformance leaks module-wide from the files that
    /// `import Charts`, and inside a `Section` nested in a `ForEach` over tuples the
    /// compiler was resolving this against `ChartContentBuilder`, which fails to build
    /// for iOS 17. Naming the return type pins it to `ViewBuilder`.
    @ViewBuilder
    private func rows(for todos: [Todo]) -> some View {
        ForEach(todos, id: \.id) { todo in
            LogbookRow(todo: todo, viewModel: viewModel)
        }
    }

    private func sectionTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}

private struct LogbookRow: View {
    let todo: Todo
    let viewModel: TodoViewModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough()
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    if let project = todo.project {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.text").font(.caption2)
                            Text(project.name).font(.caption)
                        }
                        .foregroundStyle(.tertiary)
                    }
                    if let completedAt = todo.completedAt {
                        Text(completedAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                viewModel.uncompleteTodo(todo)
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .tint(.blue)
        }
    }
}

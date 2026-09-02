import SwiftUI

struct ProjectView: View {
    let project: Project
    let viewModel: TodoViewModel

    @State private var showingAddTodo = false
    @State private var showingAddHeading = false
    @State private var newHeadingName = ""

    private var sortedHeadings: [ProjectHeading] {
        project.headings.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var unassignedTodos: [Todo] {
        project.todos
            .filter { $0.status != "Logbook" && $0.status != "Trash" && $0.headingId == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            // Progress bar
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: project.progressFraction)
                        .tint(Color(hex: project.colorHex) ?? .blue)

                    let total = project.todos.filter { $0.status != "Trash" }.count
                    let done  = project.todos.filter { $0.status == "Logbook" }.count
                    Text("\(done) of \(total) tasks completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Notes
            if !project.notes.isEmpty {
                Section("Notes") {
                    Text(project.notes)
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
            }

            // Unassigned todos (no heading)
            if !unassignedTodos.isEmpty {
                Section {
                    ForEach(unassignedTodos, id: \.id) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    viewModel.completeTodo(todo)
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.green)
                            }
                            .contextMenu {
                                TodoContextMenu(todo: todo, viewModel: viewModel)
                            }
                    }
                }
            }

            // Headings with their todos
            ForEach(sortedHeadings, id: \.id) { heading in
                let headingTodos = project.todos
                    .filter { $0.headingId == heading.id && $0.status != "Logbook" && $0.status != "Trash" }
                    .sorted { $0.sortOrder < $1.sortOrder }

                Section {
                    ForEach(headingTodos, id: \.id) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    viewModel.completeTodo(todo)
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.green)
                            }
                            .contextMenu {
                                TodoContextMenu(todo: todo, viewModel: viewModel)
                            }
                    }

                    // Add todo under this heading
                    Button {
                        showingAddTodo = true
                    } label: {
                        Label("Add Task", systemImage: "plus")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(heading.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }

            // Completed tasks summary
            let completedCount = project.todos.filter { $0.status == "Logbook" }.count
            if completedCount > 0 {
                Section {
                    NavigationLink(destination: ProjectLogbookView(project: project, viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("\(completedCount) Completed")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Actions
            Section {
                Button {
                    showingAddTodo = true
                } label: {
                    Label("Add Task", systemImage: "plus.circle.fill")
                }

                Button {
                    showingAddHeading = true
                } label: {
                    Label("Add Heading", systemImage: "text.append")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddTodo) {
            QuickAddView(viewModel: viewModel, defaultDestination: .inbox)
        }
        .alert("New Heading", isPresented: $showingAddHeading) {
            TextField("Heading name", text: $newHeadingName)
            Button("Add") {
                let name = newHeadingName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    viewModel.addHeading(project, name: name)
                }
                newHeadingName = ""
            }
            Button("Cancel", role: .cancel) { newHeadingName = "" }
        }
    }
}

private struct ProjectLogbookView: View {
    let project: Project
    let viewModel: TodoViewModel

    private var completed: [Todo] {
        project.todos
            .filter { $0.status == "Logbook" }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        List {
            ForEach(completed, id: \.id) { todo in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(todo.title)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                        if let at = todo.completedAt {
                            Text(at.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
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
        .listStyle(.insetGrouped)
        .navigationTitle("Completed")
    }
}

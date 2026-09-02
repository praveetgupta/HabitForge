import SwiftUI

struct AreaView: View {
    let area: Area
    let viewModel: TodoViewModel

    @State private var showingAddTodo = false
    @State private var showingAddProject = false
    @State private var newProjectName = ""

    private var areaProjects: [Project] {
        viewModel.activeProjects().filter { $0.area?.id == area.id }
    }

    /// Todos assigned directly to the area (not to one of its projects).
    private var looseTodos: [Todo] {
        area.todos
            .filter { $0.status != "Logbook" && $0.status != "Trash" }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var completedLooseTodos: [Todo] {
        area.todos
            .filter { $0.status == "Logbook" }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        List {
            if !looseTodos.isEmpty {
                Section("Tasks") {
                    ForEach(looseTodos, id: \.id) { todo in
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
            } else {
                Section {
                    Text("No loose tasks in this area")
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                }
            }

            if !areaProjects.isEmpty {
                Section("Projects") {
                    ForEach(areaProjects, id: \.id) { project in
                        NavigationLink(destination: ProjectView(project: project, viewModel: viewModel)) {
                            HStack(spacing: 10) {
                                Text(project.icon)
                                Text(project.name)
                                Spacer()
                                let frac = project.progressFraction
                                if frac > 0 {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 2)
                                            .frame(width: 18, height: 18)
                                        Circle()
                                            .trim(from: 0, to: frac)
                                            .stroke(Color(hex: project.colorHex) ?? .blue, lineWidth: 2)
                                            .frame(width: 18, height: 18)
                                            .rotationEffect(.degrees(-90))
                                    }
                                }
                                let pending = project.todos.filter { $0.status != "Logbook" && $0.status != "Trash" }.count
                                if pending > 0 {
                                    Text("\(pending)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            if !completedLooseTodos.isEmpty {
                Section {
                    ForEach(completedLooseTodos, id: \.id) { todo in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(todo.title)
                                .strikethrough()
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Completed (\(completedLooseTodos.count))")
                }
            }

            Section {
                Button {
                    showingAddTodo = true
                } label: {
                    Label("Add Task", systemImage: "plus.circle.fill")
                }

                Button {
                    showingAddProject = true
                } label: {
                    Label("New Project in Area", systemImage: "doc.text.badge.plus")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(area.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddTodo) {
            QuickAddView(viewModel: viewModel, defaultDestination: .inbox, defaultArea: area)
        }
        .alert("New Project", isPresented: $showingAddProject) {
            TextField("Project name", text: $newProjectName)
            Button("Create") {
                let name = newProjectName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    viewModel.createProject(name: name, area: area)
                }
                newProjectName = ""
            }
            Button("Cancel", role: .cancel) { newProjectName = "" }
        }
    }
}

import SwiftUI
import SwiftData

struct TodoSidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodoViewModel?
    @State private var searchQuery = ""
    @State private var showingAddArea = false
    @State private var showingAddProject = false
    @State private var newAreaName = ""
    @State private var newProjectName = ""

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    SidebarContent(
                        viewModel: vm,
                        searchQuery: $searchQuery,
                        showingAddArea: $showingAddArea,
                        showingAddProject: $showingAddProject
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Todos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingAddProject = true
                        } label: {
                            Label("New Project", systemImage: "doc.text")
                        }
                        Button {
                            showingAddArea = true
                        } label: {
                            Label("New Area", systemImage: "folder")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New Area", isPresented: $showingAddArea) {
                TextField("Area name", text: $newAreaName)
                Button("Create") {
                    let name = newAreaName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty { viewModel?.createArea(name: name) }
                    newAreaName = ""
                }
                Button("Cancel", role: .cancel) { newAreaName = "" }
            }
            .alert("New Project", isPresented: $showingAddProject) {
                TextField("Project name", text: $newProjectName)
                Button("Create") {
                    let name = newProjectName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty { viewModel?.createProject(name: name) }
                    newProjectName = ""
                }
                Button("Cancel", role: .cancel) { newProjectName = "" }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TodoViewModel(modelContext: modelContext)
            }
        }
    }
}

private struct SidebarContent: View {
    let viewModel: TodoViewModel
    @Binding var searchQuery: String
    @Binding var showingAddArea: Bool
    @Binding var showingAddProject: Bool

    private var standaloneProjects: [Project] {
        viewModel.activeProjects().filter { $0.area == nil }
    }

    var body: some View {
        List {
            // Search bar
            if !searchQuery.isEmpty {
                SearchResultsSection(query: searchQuery, viewModel: viewModel)
            }

            // Main nav
            Section {
                NavigationLink(destination: InboxView(viewModel: viewModel)) {
                    Label("Inbox", systemImage: "tray")
                        .badge(viewModel.inboxTodos.count > 0 ? viewModel.inboxTodos.count : 0)
                }
                NavigationLink(destination: TodayView(viewModel: viewModel)) {
                    Label("Today", systemImage: "star.fill")
                        .badge(viewModel.todayTodos.count > 0 ? viewModel.todayTodos.count : 0)
                }
                NavigationLink(destination: UpcomingView(viewModel: viewModel)) {
                    Label("Upcoming", systemImage: "calendar")
                }
                NavigationLink(destination: AnytimeView(viewModel: viewModel)) {
                    Label("Anytime", systemImage: "tray.full")
                }
                NavigationLink(destination: SomedayView(viewModel: viewModel)) {
                    Label("Someday", systemImage: "moon.zzz")
                }
                NavigationLink(destination: LogbookView(viewModel: viewModel)) {
                    Label("Logbook", systemImage: "book.closed")
                }
            }

            // Areas with nested projects
            if !viewModel.areas.isEmpty {
                Section {
                    ForEach(viewModel.areas, id: \.id) { area in
                        AreaRow(area: area, viewModel: viewModel)
                    }
                } header: {
                    HStack {
                        Text("Areas")
                        Spacer()
                        Button {
                            showingAddArea = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                        .textCase(nil)
                    }
                }
            }

            // Standalone projects (no area)
            if !standaloneProjects.isEmpty {
                Section {
                    ForEach(standaloneProjects, id: \.id) { project in
                        ProjectSidebarRow(project: project, viewModel: viewModel)
                    }
                } header: {
                    HStack {
                        Text("Projects")
                        Spacer()
                        Button {
                            showingAddProject = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                        .textCase(nil)
                    }
                }
            }

            // Tags
            if !viewModel.tags.isEmpty {
                Section("Tags") {
                    ForEach(viewModel.tags, id: \.id) { tag in
                        NavigationLink(destination: TagTodosView(tag: tag, viewModel: viewModel)) {
                            HStack(spacing: 8) {
                                if let hex = tag.colorHex, let color = Color(hex: hex) {
                                    Circle().fill(color).frame(width: 10, height: 10)
                                } else {
                                    Circle().fill(Color.secondary.opacity(0.4)).frame(width: 10, height: 10)
                                }
                                Text(tag.name)
                                Spacer()
                                Text("\(viewModel.todosWithTag(tag.name).count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchQuery, prompt: "Search tasks")
    }
}

private struct AreaRow: View {
    let area: Area
    let viewModel: TodoViewModel
    @State private var isExpanded = false

    private var areaProjects: [Project] {
        viewModel.activeProjects().filter { $0.area?.id == area.id }
    }

    var body: some View {
        Group {
            HStack(spacing: 4) {
                if !areaProjects.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                }

                NavigationLink(destination: AreaView(area: area, viewModel: viewModel)) {
                    HStack(spacing: 8) {
                        Text(area.icon)
                            .font(.body)
                        Text(area.name)
                            .font(.body.weight(.medium))
                    }
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                ForEach(areaProjects, id: \.id) { project in
                    ProjectSidebarRow(project: project, viewModel: viewModel)
                        .padding(.leading, 28)
                }
            }
        }
    }
}

private struct ProjectSidebarRow: View {
    let project: Project
    let viewModel: TodoViewModel

    var body: some View {
        NavigationLink(destination: ProjectView(project: project, viewModel: viewModel)) {
            HStack(spacing: 10) {
                Text(project.icon)
                    .font(.body)

                Text(project.name)

                Spacer()

                // Progress
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

                // Pending task count
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

private struct SearchResultsSection: View {
    let query: String
    let viewModel: TodoViewModel

    private var results: [Todo] {
        viewModel.search(query: query)
    }

    var body: some View {
        Section("Results") {
            if results.isEmpty {
                Text("No results for \"\(query)\"")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(results, id: \.id) { todo in
                    TodoRowView(todo: todo, viewModel: viewModel)
                }
            }
        }
    }
}

private struct TagTodosView: View {
    let tag: Tag
    let viewModel: TodoViewModel

    private var todos: [Todo] {
        viewModel.todosWithTag(tag.name)
    }

    var body: some View {
        Group {
            if todos.isEmpty {
                ContentUnavailableView {
                    Label(tag.name, systemImage: "tag")
                } description: {
                    Text("No tasks with this tag.")
                }
            } else {
                List {
                    ForEach(todos, id: \.id) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                            .contextMenu {
                                TodoContextMenu(todo: todo, viewModel: viewModel)
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(tag.name)
    }
}

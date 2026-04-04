import SwiftUI
import SwiftData

struct TodoSidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodoViewModel?
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    List {
                        Section {
                            NavigationLink(destination: InboxView(viewModel: vm)) {
                                Label("Inbox", systemImage: "tray")
                                    .badge(vm.inboxTodos.count)
                            }
                            NavigationLink(destination: TodayView(viewModel: vm)) {
                                Label("Today", systemImage: "star.fill")
                                    .badge(vm.todayTodos.count)
                            }
                            NavigationLink(destination: UpcomingView(viewModel: vm)) {
                                Label("Upcoming", systemImage: "calendar")
                            }
                            NavigationLink(destination: AnytimeView(viewModel: vm)) {
                                Label("Anytime", systemImage: "tray.full")
                            }
                            NavigationLink(destination: SomedayView(viewModel: vm)) {
                                Label("Someday", systemImage: "moon.zzz")
                            }
                            NavigationLink(destination: LogbookView(viewModel: vm)) {
                                Label("Logbook", systemImage: "book.closed")
                            }
                        }
                        
                        if !vm.areas.isEmpty {
                            TodoSidebarAreasSection(areas: vm.areas, viewModel: vm)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Todos")
            .onAppear {
                if viewModel == nil {
                    viewModel = TodoViewModel(modelContext: modelContext)
                }
            }
        }
    }
}

private struct TodoSidebarAreasSection: View {
    let areas: [Area]
    let viewModel: TodoViewModel

    var body: some View {
        Section("Areas") {
            ForEach(areas, id: \.id) { area in
                TodoSidebarAreaRow(area: area, viewModel: viewModel)
            }
        }
    }
}

private struct TodoSidebarAreaRow: View {
    let area: Area
    let viewModel: TodoViewModel

    var body: some View {
        DisclosureGroup {
            ForEach(area.projects, id: \.id) { project in
                NavigationLink(destination: ProjectView(project: project, viewModel: viewModel)) {
                    Label(project.name, systemImage: "doc.text")
                }
            }
        } label: {
            Label(area.name, systemImage: "folder")
        }
    }
}

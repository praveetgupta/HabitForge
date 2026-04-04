import SwiftUI

struct ProjectView: View {
    let project: Project
    let viewModel: TodoViewModel
    
    var body: some View {
        List {
            // Progress bar
            Section {
                ProgressView(value: project.progressFraction)
                    .tint(Color(hex: project.colorHex) ?? .blue)
            }
            
            // Project notes
            if !project.notes.isEmpty {
                Section("Notes") {
                    Text(project.notes)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Todos grouped by heading
            // TODO: Group by headings from ProjectHeading
            Section("Tasks") {
                ForEach(project.todos.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.id) { todo in
                    TodoRowView(todo: todo, viewModel: viewModel)
                }
            }
        }
        .navigationTitle(project.name)
    }
}

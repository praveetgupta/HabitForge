import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let viewModel: TodoViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion circle
            Button(action: { viewModel.completeTodo(todo) }) {
                Image(systemName: todo.status == "Logbook" ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.status == "Logbook" ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough(todo.status == "Logbook")
                    .foregroundStyle(todo.status == "Logbook" ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    if let project = todo.project {
                        Label(project.name, systemImage: "doc.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let deadline = todo.deadline {
                        Label(deadline.formatted(date: .abbreviated, time: .omitted), systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    if todo.priority > 0 {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(priorityColor)
                    }
                }
            }
            
            Spacer()
        }
        .swipeActions(edge: .leading) {
            Button("Today") { viewModel.moveToToday(todo) }
                .tint(.orange)
        }
    }
    
    private var priorityColor: Color {
        switch todo.priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return .gray
        }
    }
}

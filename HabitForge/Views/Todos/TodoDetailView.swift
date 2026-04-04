import SwiftUI

struct TodoDetailView: View {
    let todo: Todo
    let viewModel: TodoViewModel
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: .constant(todo.title))
                    .font(.title3)
            }
            
            Section("Notes") {
                TextEditor(text: .constant(todo.notes))
                    .frame(minHeight: 100)
            }
            
            Section("Schedule") {
                // TODO: When date picker
                // TODO: Deadline date picker
                // TODO: Reminder picker
                // TODO: Repeat rule picker
                Text("Scheduling options — implement from guide")
                    .foregroundStyle(.secondary)
            }
            
            Section("Checklist") {
                ForEach(todo.checklist.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.id) { item in
                    HStack {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isCompleted ? .green : .secondary)
                        Text(item.title)
                    }
                }
                // TODO: Add checklist item
            }
        }
        .navigationTitle("Details")
    }
}

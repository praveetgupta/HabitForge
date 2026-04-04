import SwiftUI

struct InboxView: View {
    let viewModel: TodoViewModel
    @State private var showingQuickAdd = false
    
    var body: some View {
        List {
            if viewModel.inboxTodos.isEmpty {
                ContentUnavailableView(
                    "Inbox Zero",
                    systemImage: "tray",
                    description: Text("All tasks have been processed")
                )
            } else {
                ForEach(viewModel.inboxTodos, id: \.id) { todo in
                    TodoRowView(todo: todo, viewModel: viewModel)
                }
            }
        }
        .navigationTitle("Inbox")
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showingQuickAdd = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)
                    .shadow(radius: 4)
            }
            .padding(24)
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddView(viewModel: viewModel)
        }
    }
}

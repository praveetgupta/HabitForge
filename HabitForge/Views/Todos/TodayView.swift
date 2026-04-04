import SwiftUI

struct TodayView: View {
    let viewModel: TodoViewModel
    @State private var showingQuickAdd = false
    
    var body: some View {
        List {
            // Morning todos
            ForEach(viewModel.todayTodos.filter { !$0.isEvening }, id: \.id) { todo in
                TodoRowView(todo: todo, viewModel: viewModel)
            }
            
            // Evening section
            if viewModel.todayTodos.contains(where: { $0.isEvening }) {
                Section("This Evening") {
                    ForEach(viewModel.todayTodos.filter { $0.isEvening }, id: \.id) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                    }
                }
            }
        }
        .navigationTitle("Today")
        .overlay(alignment: .bottomTrailing) {
            // Magic Plus button
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

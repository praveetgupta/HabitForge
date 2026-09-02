import SwiftUI

struct SomedayView: View {
    let viewModel: TodoViewModel
    @State private var showingQuickAdd = false

    var body: some View {
        Group {
            if viewModel.somedayTodos.isEmpty {
                ContentUnavailableView {
                    Label("Nothing Someday", systemImage: "moon.zzz")
                } description: {
                    Text("Ideas and tasks for the future live here.")
                }
            } else {
                List {
                    ForEach(viewModel.somedayTodos, id: \.id) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    viewModel.moveToToday(todo)
                                } label: {
                                    Label("Today", systemImage: "star.fill")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    viewModel.moveToAnytime(todo)
                                } label: {
                                    Label("Anytime", systemImage: "tray.full")
                                }
                                .tint(.teal)
                            }
                            .contextMenu {
                                TodoContextMenu(todo: todo, viewModel: viewModel)
                            }
                    }
                    .onMove { from, to in viewModel.reorderSomedayTodos(fromOffsets: from, toOffset: to) }
                    .onDelete { indices in
                        indices.forEach { viewModel.deleteTodo(viewModel.somedayTodos[$0]) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Someday")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingQuickAdd = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.blue)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddView(viewModel: viewModel, defaultDestination: .inbox)
        }
    }
}

import SwiftUI

struct InboxView: View {
    let viewModel: TodoViewModel
    @State private var showingQuickAdd = false
    @State private var todoToSchedule: Todo?

    var body: some View {
        Group {
            if viewModel.inboxTodos.isEmpty {
                ContentUnavailableView {
                    Label("Inbox Zero", systemImage: "tray")
                } description: {
                    Text("All tasks have been processed.")
                }
            } else {
                List {
                    ForEach(viewModel.inboxTodos, id: \.id) { todo in
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
                                    viewModel.moveToSomeday(todo)
                                } label: {
                                    Label("Someday", systemImage: "moon.zzz")
                                }
                                .tint(.purple)
                                Button {
                                    todoToSchedule = todo
                                } label: {
                                    Label("Schedule", systemImage: "calendar")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                TodoContextMenu(todo: todo, viewModel: viewModel)
                            }
                    }
                    .onMove { from, to in viewModel.reorderInboxTodos(fromOffsets: from, toOffset: to) }
                    .onDelete { indices in
                        indices.forEach { viewModel.deleteTodo(viewModel.inboxTodos[$0]) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Inbox")
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
        .sheet(item: $todoToSchedule) { todo in
            ScheduleTodoSheet(todo: todo, viewModel: viewModel)
        }
    }
}

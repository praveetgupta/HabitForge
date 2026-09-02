import SwiftUI

struct TodayView: View {
    let viewModel: TodoViewModel
    @State private var showingQuickAdd = false
    @State private var showCompletedToday = false
    @State private var todoToSchedule: Todo?

    private var morningTodos: [Todo] {
        viewModel.todayTodos.filter { !$0.isEvening }
    }

    private var eveningTodos: [Todo] {
        viewModel.todayTodos.filter { $0.isEvening }
    }

    private var completedTodayTodos: [Todo] {
        viewModel.logbookTodos.filter {
            Calendar.current.isDateInToday($0.completedAt ?? .distantPast)
        }
    }

    var body: some View {
        List {
            // Date header
            Section {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.title2.weight(.bold))
                    let total = morningTodos.count + eveningTodos.count
                    if total > 0 {
                        Text("\(total) task\(total == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // Morning todos
            if !morningTodos.isEmpty {
                Section {
                    ForEach(morningTodos, id: \.id) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    viewModel.completeTodo(todo)
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    todoToSchedule = todo
                                } label: {
                                    Label("Schedule", systemImage: "calendar")
                                }
                                .tint(.blue)
                                Button {
                                    viewModel.moveToInbox(todo)
                                } label: {
                                    Label("Inbox", systemImage: "tray")
                                }
                                .tint(.gray)
                            }
                            .contextMenu {
                                TodoContextMenu(todo: todo, viewModel: viewModel)
                            }
                    }
                    .onMove { from, to in viewModel.reorderTodayTodos(fromOffsets: from, toOffset: to) }
                }
            } else if eveningTodos.isEmpty {
                Section {
                    Text("No tasks for today")
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                }
            }

            // This Evening
            if !eveningTodos.isEmpty {
                Section {
                    ForEach(eveningTodos, id: \.id) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    viewModel.completeTodo(todo)
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    todoToSchedule = todo
                                } label: {
                                    Label("Schedule", systemImage: "calendar")
                                }
                                .tint(.blue)
                                Button {
                                    viewModel.moveToInbox(todo)
                                } label: {
                                    Label("Inbox", systemImage: "tray")
                                }
                                .tint(.gray)
                            }
                    }
                } header: {
                    Label("This Evening", systemImage: "moon.fill")
                        .foregroundStyle(.indigo)
                }
            }

            // Completed today (collapsible)
            if !completedTodayTodos.isEmpty {
                Section {
                    if showCompletedToday {
                        ForEach(completedTodayTodos, id: \.id) { todo in
                            TodoRowView(todo: todo, viewModel: viewModel)
                        }
                    }
                } header: {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showCompletedToday.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: showCompletedToday ? "chevron.down" : "chevron.right")
                                .font(.caption2.weight(.semibold))
                            Text("Completed Today")
                            Text("(\(completedTodayTodos.count))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
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
            QuickAddView(viewModel: viewModel, defaultDestination: .today)
        }
        .sheet(item: $todoToSchedule) { todo in
            ScheduleTodoSheet(todo: todo, viewModel: viewModel)
        }
        .onAppear {
            viewModel.autoPromoteUpcoming()
        }
    }
}

import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case habits, todos, workouts, settings
}

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: \Habit.sortOrder
    )
    private var habitsForReminders: [Habit]

    @State private var selectedTab: AppTab = .habits
    @State private var todoViewModel: TodoViewModel?
    @State private var showingGlobalQuickAdd = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HabitDashboardView()
                .tabItem {
                    Label("Habits", systemImage: "flame.fill")
                }
                .tag(AppTab.habits)

            TodoSidebarView()
                .tabItem {
                    Label("Todos", systemImage: "checklist")
                }
                .tag(AppTab.todos)

            WorkoutDashboardView()
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
                .tag(AppTab.workouts)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .overlay(alignment: .bottomTrailing) {
            // Global quick add — the Todos tab has its own per-view buttons.
            // Bottom padding clears the tab bar (49pt + 34pt home indicator) so the
            // button floats above it instead of covering the Settings icon.
            if selectedTab != .todos {
                Button {
                    if todoViewModel == nil {
                        todoViewModel = TodoViewModel(modelContext: modelContext)
                    }
                    showingGlobalQuickAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 64)
            }
        }
        .sheet(isPresented: $showingGlobalQuickAdd) {
            if let vm = todoViewModel {
                QuickAddView(viewModel: vm, defaultDestination: .inbox)
            }
        }
        .task {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                NotificationService.shared.rescheduleAllHabitReminders(habits: habitsForReminders)
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Habit.self, inMemory: true)
}

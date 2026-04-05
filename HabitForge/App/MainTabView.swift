import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: \Habit.sortOrder
    )
    private var habitsForReminders: [Habit]

    var body: some View {
        TabView {
            HabitDashboardView()
                .tabItem {
                    Label("Habits", systemImage: "flame.fill")
                }
            
            TodoSidebarView()
                .tabItem {
                    Label("Todos", systemImage: "checklist")
                }
            
            WorkoutDashboardView()
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
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
}

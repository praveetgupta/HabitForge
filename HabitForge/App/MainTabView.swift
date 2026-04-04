import SwiftUI

struct MainTabView: View {
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
    }
}

#Preview {
    MainTabView()
}

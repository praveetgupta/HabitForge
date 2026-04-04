import SwiftUI

struct HabitCalendarView: View {
    let habit: Habit
    
    var body: some View {
        VStack {
            Text("Calendar Heatmap")
                .font(.headline)
            // TODO: Implement month calendar with colored cells
            // See HabitForge-Habit-Module.md for heatmapData()
            Text("Coming soon")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

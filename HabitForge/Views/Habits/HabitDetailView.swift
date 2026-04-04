import SwiftUI
import Charts

struct HabitDetailView: View {
    let habit: Habit
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Large ring with streak
                ZStack {
                    Circle()
                        .stroke(Color(hex: habit.colorHex)?.opacity(0.2) ?? Color.blue.opacity(0.2), lineWidth: 12)
                    
                    VStack {
                        Text("\(habit.currentStreak)")
                            .font(.system(size: 48, weight: .bold))
                        Text("day streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 160, height: 160)
                
                // Stats row
                HStack(spacing: 24) {
                    StatBox(label: "Current", value: "\(habit.currentStreak)")
                    StatBox(label: "Best", value: "\(habit.bestStreak)")
                    StatBox(label: "Total", value: "\(habit.totalCompletions)")
                }
                
                // TODO: Calendar heatmap (HabitCalendarView)
                // TODO: Completion bar chart (HabitChartView)
                // TODO: Entry history list
            }
            .padding()
        }
        .navigationTitle(habit.name)
    }
}

struct StatBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

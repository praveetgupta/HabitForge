import SwiftUI

struct HabitRingView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    
    private var progress: Double {
        viewModel.isCompleted(habit, on: Date()) ? 1.0 : 0.0
    }
    
    private var habitColor: Color {
        Color(hex: habit.colorHex) ?? .blue
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(habitColor.opacity(0.2), lineWidth: 8)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(habitColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                // Icon
                Text(habit.icon)
                    .font(.system(size: 28))
            }
            .frame(width: 80, height: 80)
            .onTapGesture {
                viewModel.toggleHabit(habit)
            }
            
            Text(habit.name)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
    }
}

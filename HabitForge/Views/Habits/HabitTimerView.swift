import SwiftUI

struct HabitTimerView: View {
    let habit: Habit
    @Binding var timerSeconds: Int
    @Binding var timerRunning: Bool
    var onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color(hex: habit.colorHex)?.opacity(0.2) ?? .blue.opacity(0.2), lineWidth: 12)
                
                VStack {
                    Text(timeString)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                    if let target = habit.targetDurationSeconds {
                        Text("Goal: \(target / 60) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 240, height: 240)
            
            Button(action: onStop) {
                Text("Stop")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 120, height: 48)
                    .background(.red, in: Capsule())
            }
        }
        .padding()
    }
    
    private var timeString: String {
        let minutes = timerSeconds / 60
        let seconds = timerSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

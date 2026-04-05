import SwiftUI
import SwiftData

struct HabitTimerView: View {
    let habit: Habit
    let viewModel: HabitViewModel

    @Environment(\.dismiss) private var dismiss

    private var habitColor: Color {
        Color(hex: habit.colorHex) ?? .blue
    }

    private var targetSeconds: Int {
        max(habit.targetDurationSeconds ?? 60, 1)
    }

    private var progress: Double {
        min(1, Double(viewModel.timerSeconds) / Double(targetSeconds))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 36) {
                Spacer(minLength: 20)

                ZStack {
                    Circle()
                        .stroke(habitColor.opacity(0.15), lineWidth: 18)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            habitColor,
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.35), value: progress)

                    VStack(spacing: 10) {
                        Text(timeString(viewModel.timerSeconds))
                            .font(.system(size: 56, weight: .light, design: .monospaced))
                            .contentTransition(.numericText())

                        Text("Goal \(targetSeconds / 60)m \(targetSeconds % 60 > 0 ? "\(targetSeconds % 60)s" : "")")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        let remaining = max(0, targetSeconds - viewModel.timerSeconds)
                        Text("\(timeString(remaining)) left")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(habitColor)
                    }
                }
                .frame(width: 280, height: 280)

                HStack(spacing: 20) {
                    if viewModel.timerRunning {
                        Button {
                            viewModel.pauseTimer()
                        } label: {
                            Label("Pause", systemImage: "pause.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    } else {
                        Button {
                            viewModel.startTimer()
                        } label: {
                            Label("Start", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(habitColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }

                    Button(role: .destructive) {
                        viewModel.stopTimer(saveProgress: true)
                        dismiss()
                    } label: {
                        Text("Stop")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 8)

                Spacer()
            }
            .padding(24)
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        viewModel.stopTimer(saveProgress: false)
                        dismiss()
                    }
                }
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
    let ctx = ModelContext(container)
    let h = Habit(name: "Focus", icon: "🎯", colorHex: "#FF6B6B")
    h.tracksDuration = true
    h.targetDurationSeconds = 300
    ctx.insert(h)
    let vm = HabitViewModel(modelContext: ctx)
    vm.showingTimerFor = h
    return HabitTimerView(habit: h, viewModel: vm)
}

import SwiftUI
import SwiftData

struct HabitRingView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    var onViewStats: () -> Void
    var onEdit: () -> Void

    @State private var showNoteSheet = false
    @State private var showMoodSheet = false
    @State private var draftNote = ""
    @State private var showingActions = false
    @State private var ringScale: CGFloat = 1

    private var progress: Double {
        viewModel.progressFraction(habit, on: Date())
    }

    private var habitColor: Color {
        Color(hex: habit.colorHex) ?? .blue
    }

    private var isFullyComplete: Bool {
        progress >= 1 - 1e-6
    }

    private var ringSubtitle: String? {
        if habit.tracksCount {
            let cur = viewModel.entryForHabit(habit, on: Date())?.countValue ?? 0
            let t = max(habit.targetCountValue ?? 1, 1)
            return "\(cur)/\(t)"
        }
        if habit.tracksDuration {
            let sec = viewModel.entryForHabit(habit, on: Date())?.durationSeconds ?? 0
            let tgt = max(habit.targetDurationSeconds ?? 60, 1)
            let curM = sec / 60
            let tgtM = max(1, tgt / 60)
            return "\(curM)/\(tgtM)m"
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(habitColor.opacity(0.18), lineWidth: 9)

                Circle()
                    .trim(from: 0, to: min(progress, 1))
                    .stroke(
                        habitColor,
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: progress)

                Text(habit.icon)
                    .font(.system(size: 30))
            }
            .scaleEffect(ringScale)
            .frame(width: 84, height: 84)
            .overlay(alignment: .bottomTrailing) {
                if isFullyComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(habitColor)
                        .padding(5)
                        .background(.thinMaterial, in: Circle())
                        .offset(x: 6, y: 6)
                }
            }
            .contentShape(Circle())
            .opacity(habit.isPaused ? 0.5 : 1)
            .onTapGesture {
                playRingTapAnimation()
                handleTap()
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                showingActions = true
            }

            VStack(spacing: 2) {
                Text(habit.name)
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                if let sub = ringSubtitle {
                    Text(sub)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: ringSubtitle == nil ? 32 : 40, alignment: .top)
        }
        .padding(.vertical, 6)
        .confirmationDialog(habit.name, isPresented: $showingActions) {
            Button("Add note") {
                draftNote = viewModel.entryForHabit(habit, on: Date())?.note ?? ""
                showNoteSheet = true
            }
            Button("Set mood") {
                showMoodSheet = true
            }
            Button("View stats") {
                onViewStats()
            }
            Button("Edit") {
                onEdit()
            }
            if habit.tracksCount {
                Button("Decrement count") {
                    viewModel.decrementCount(habit)
                }
            }
            if habit.isPaused {
                Button("Resume") {
                    viewModel.resumeHabit(habit)
                }
            } else {
                Button("Pause") {
                    viewModel.pauseHabit(habit)
                }
            }
            Button("Archive", role: .destructive) {
                viewModel.archiveHabit(habit)
            }
        }
        .sheet(isPresented: $showNoteSheet) {
            NavigationStack {
                Form {
                    Section("Note for today") {
                        TextField("Note", text: $draftNote, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                .navigationTitle("Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showNoteSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            viewModel.updateNote(habit, on: Date(), note: draftNote.isEmpty ? nil : draftNote)
                            showNoteSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showMoodSheet) {
            MoodPickerSheet { mood in
                viewModel.setMood(habit, on: Date(), mood: mood)
                showMoodSheet = false
            } onDismiss: {
                showMoodSheet = false
            }
            .presentationDetents([.height(280)])
        }
    }

    private func playRingTapAnimation() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
            ringScale = 0.92
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 90_000_000)
            withAnimation(.spring(response: 0.42, dampingFraction: 0.65)) {
                ringScale = 1.0
            }
        }
    }

    private func handleTap() {
        if habit.isPaused {
            viewModel.resumeHabit(habit)
            return
        }
        if habit.tracksDuration {
            viewModel.openTimer(for: habit)
            return
        }
        if habit.tracksCount {
            viewModel.incrementCount(habit)
            return
        }
        if habit.frequency == "Times per Week" || habit.frequency == "Times per Month" {
            viewModel.logPeriodicCompletion(habit)
            return
        }
        viewModel.toggleHabit(habit)
    }
}

private struct MoodPickerSheet: View {
    let onPick: (String) -> Void
    let onDismiss: () -> Void

    private let moods = ["😊", "🙂", "😐", "😓", "😞"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(moods, id: \.self) { m in
                        Button {
                            onPick(m)
                        } label: {
                            Text(m)
                                .font(.system(size: 44))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
    let ctx = ModelContext(container)
    let h = Habit(name: "Water", icon: "💧", colorHex: "#007AFF")
    ctx.insert(h)
    let vm = HabitViewModel(modelContext: ctx)
    return HabitRingView(habit: h, viewModel: vm, onViewStats: {}, onEdit: {})
        .padding()
}

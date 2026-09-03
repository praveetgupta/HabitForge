import SwiftUI

/// Full-screen active workout logger: session clock, one card per exercise with
/// SET | PREVIOUS | KG | REPS | ✓ rows, rest-timer footer, finish/discard.
struct ActiveWorkoutView: View {
    let viewModel: WorkoutViewModel
    let session: WorkoutSession
    var onFinish: (WorkoutSession?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings.shared
    @State private var showingExercisePicker = false
    @State private var showingDiscardDialog = false

    private var completedSets: Int {
        session.performedExercises.flatMap { $0.sets }.filter { $0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Session clock + progress
                    VStack(spacing: 4) {
                        TimelineView(.periodic(from: .now, by: 1)) { _ in
                            Text(Self.formatElapsed(Date().timeIntervalSince(session.startTime)))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        Text("\(completedSets) set\(completedSets == 1 ? "" : "s") · \(settings.weightUnit.format(kilograms: session.totalVolumeKg))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    ForEach(viewModel.sortedPerformedExercises(in: session), id: \.id) { pe in
                        ActiveExerciseCard(performedExercise: pe, viewModel: viewModel, session: session)
                    }

                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .padding(.top, 4)
                    .padding(.bottom, 120)
                }
                .padding(.horizontal)
            }
            .overlay(alignment: .bottom) {
                if viewModel.restTimerRunning {
                    RestTimerBar(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.restTimerRunning)
            .navigationTitle(session.routine?.name ?? "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showingDiscardDialog = true
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.red)
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let finished = viewModel.finishSession()
                        onFinish(finished)
                    } label: {
                        Text("Finish")
                            .fontWeight(.semibold)
                    }
                    .tint(.green)
                }
            }
            .confirmationDialog("Discard this workout?", isPresented: $showingDiscardDialog, titleVisibility: .visible) {
                Button("Discard Workout", role: .destructive) {
                    viewModel.discardSession()
                    onFinish(nil)
                }
                Button("Keep Logging", role: .cancel) {}
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(viewModel: viewModel) { exercise in
                    viewModel.addExerciseToActiveSession(exercise)
                }
            }
        }
        .interactiveDismissDisabled()
    }

    static func formatElapsed(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Exercise card

struct ActiveExerciseCard: View {
    let performedExercise: PerformedExercise
    let viewModel: WorkoutViewModel
    let session: WorkoutSession

    @State private var settings = AppSettings.shared
    @State private var previous: [Double?] = []
    @State private var restSeconds = 90

    private var sortedSets: [PerformedSet] {
        viewModel.sortedSets(in: performedExercise)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(performedExercise.exerciseName)
                        .font(.body.bold())
                    Text(performedExercise.muscleGroup)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    viewModel.removePerformedExercise(performedExercise)
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.borderless)
            }

            // Column headers
            HStack(spacing: 8) {
                Text("SET")
                    .frame(width: 36, alignment: .center)
                Text("PREVIOUS")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(settings.weightUnit.shortName.uppercased())
                    .frame(width: 64, alignment: .center)
                Text("REPS")
                    .frame(width: 50, alignment: .center)
                Text("✓")
                    .frame(width: 36, alignment: .center)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.tertiary)

            ForEach(sortedSets, id: \.id) { set in
                SetLogRow(set: set,
                          previous: previousFor(set),
                          restSeconds: restSeconds,
                          viewModel: viewModel)
                    .padding(.vertical, 2)
            }

            Button {
                viewModel.addSet(to: performedExercise)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            if let exercise = performedExercise.exercise {
                previous = viewModel.previousWeights(for: exercise)
                restSeconds = session.routine?.templateExercises
                    .first { $0.exercise?.id == exercise.id }?
                    .restSeconds ?? settings.defaultRestSeconds
            }
        }
    }

    private func previousFor(_ set: PerformedSet) -> String {
        let index = set.setNumber - 1
        guard index < previous.count else { return "—" }
        guard let w = previous[index] else { return "—" }
        return settings.weightUnit.format(kilograms: w)
    }
}

// MARK: - One set row

struct SetLogRow: View {
    @Bindable var set: PerformedSet
    let previous: String
    let restSeconds: Int
    let viewModel: WorkoutViewModel

    @State private var settings = AppSettings.shared

    var body: some View {
        HStack(spacing: 8) {
            Text("\(set.setNumber)")
                .font(.subheadline.monospacedDigit())
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(set.isCompleted ? Color.green.opacity(0.18) : Color.secondary.opacity(0.12))
                )
                .foregroundStyle(set.isCompleted ? .green : Color.primary)

            Text(previous)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            TextField("0", value: Binding(
                get: { settings.weightUnit.fromKilograms(set.weightKg ?? 0) },
                set: { set.weightKg = settings.weightUnit.toKilograms($0) }
            ), format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.body.monospacedDigit())
                .padding(.vertical, 7)
                .frame(width: 64)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(set.isCompleted ? Color.green.opacity(0.1) : Color.secondary.opacity(0.08))
                )
                .disabled(set.isCompleted)
                .accessibilityLabel("Set \(set.setNumber) weight in \(settings.weightUnit == .kilograms ? "kilograms" : "pounds")")

            TextField("0", value: Binding(
                get: { set.reps ?? 0 },
                set: { set.reps = $0 }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.body.monospacedDigit())
                .padding(.vertical, 7)
                .frame(width: 50)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(set.isCompleted ? Color.green.opacity(0.1) : Color.secondary.opacity(0.08))
                )
                .disabled(set.isCompleted)
                .accessibilityLabel("Set \(set.setNumber) reps")

            Button {
                if set.isCompleted {
                    viewModel.uncompleteSet(set)
                } else {
                    viewModel.completeSet(set, reps: set.reps, weight: set.weightKg, restSeconds: restSeconds)
                    hideKeyboard()
                }
            } label: {
                ZStack {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(set.isCompleted ? Color.green : Color.secondary)
                    if set.isPR {
                        Text("PR")
                            .font(.system(size: 7, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 3)
                            .background(Capsule().fill(Color.yellow))
                            .offset(y: 13)
                    }
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(set.isCompleted ? "Uncomplete set \(set.setNumber)" : "Complete set \(set.setNumber)")
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Rest timer bar

struct RestTimerBar: View {
    let viewModel: WorkoutViewModel

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("REST")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(Self.format(viewModel.restTimerSeconds))
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("restCountdown")
            }

            Spacer()

            Button {
                viewModel.adjustRestTimer(by: -15)
            } label: {
                Text("−15s")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.adjustRestTimer(by: 15)
            } label: {
                Text("+15s")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.stopRestTimer()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip rest")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    static func format(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

import SwiftUI

/// Creates a new routine, or edits an existing one when `routine` is passed.
/// In create mode a draft Routine is inserted as soon as the first exercise is
/// added (so exercises can attach to a real relationship); cancelling deletes it.
struct CreateRoutineView: View {
    let viewModel: WorkoutViewModel
    var routine: Routine? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "🏋️"
    @State private var colorHex = "#007AFF"
    @State private var showingExercisePicker = false
    @State private var draftRoutine: Routine?

    private let colorOptions = ["#FF6B6B", "#FF9500", "#FFCC00", "#34C759", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55"]

    private let commonEmojis = ["🏋️", "💪", "🔥", "🏃", "🦵", "🫁", "⚡", "🎯", "🥊", "🧘", "🚴", "🏊"]

    private var isEditing: Bool { routine != nil }

    private var workingRoutine: Routine? { routine ?? draftRoutine }

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("routineNameField")
                    emojiRow
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 34, height: 34)
                                .overlay {
                                    Circle()
                                        .stroke(Color.primary.opacity(colorHex == hex ? 0.35 : 0), lineWidth: 3)
                                }
                                .shadow(color: colorHex == hex ? .black.opacity(0.12) : .clear, radius: 4, y: 2)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                        colorHex = hex
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    if let r = workingRoutine {
                        let exercises = viewModel.sortedTemplateExercises(for: r)
                        if exercises.isEmpty {
                            Text("No exercises yet — add your first one below.")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        } else {
                            ForEach(exercises, id: \.id) { re in
                                NavigationLink {
                                    RoutineExerciseEditorView(routineExercise: re, viewModel: viewModel)
                                } label: {
                                    RoutineExerciseRow(routineExercise: re)
                                }
                            }
                            .onMove { from, to in
                                viewModel.moveRoutineExercise(r, fromOffsets: from, toOffset: to)
                            }
                            .onDelete { offsets in
                                let exercises = viewModel.sortedTemplateExercises(for: r)
                                for index in offsets {
                                    viewModel.removeExerciseFromRoutine(r, routineExercise: exercises[index])
                                }
                            }
                        }
                    } else {
                        Text("No exercises yet — add your first one below.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }

                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Exercises")
                }
            }
            .navigationTitle(isEditing ? "Edit Routine" : "New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    // Reorder controls only appear while edit mode is active.
                    EditButton()
                    Spacer()
                }
            }
            .onAppear(perform: loadIfEditing)
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(viewModel: viewModel) { exercise in
                    addExercise(exercise)
                }
            }
        }
    }

    private var emojiRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(commonEmojis, id: \.self) { e in
                        Text(e)
                            .font(.title2)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(icon == e ? Color.blue.opacity(0.15) : Color.clear)
                            )
                            .overlay {
                                Circle()
                                    .stroke(Color.blue.opacity(icon == e ? 0.5 : 0), lineWidth: 2)
                            }
                            .onTapGesture { icon = e }
                    }
                }
            }
            TextField("Or type an emoji", text: $icon)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }

    private func loadIfEditing() {
        guard let routine, draftRoutine == nil, name.isEmpty else { return }
        name = routine.name
        icon = routine.icon
        colorHex = routine.colorHex
    }

    private func addExercise(_ exercise: Exercise) {
        if let r = workingRoutine {
            viewModel.addExerciseToRoutine(r, exercise: exercise)
        } else {
            // First exercise in create mode — insert the draft routine now.
            let r = viewModel.createRoutine(
                name: name.isEmpty ? "New Routine" : name,
                icon: icon,
                colorHex: colorHex
            )
            draftRoutine = r
            viewModel.addExerciseToRoutine(r, exercise: exercise)
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let routine {
            viewModel.updateRoutine(routine, name: trimmed, icon: icon, colorHex: colorHex)
        } else if let draft = draftRoutine {
            viewModel.updateRoutine(draft, name: trimmed, icon: icon, colorHex: colorHex)
        } else {
            viewModel.createRoutine(name: trimmed, icon: icon, colorHex: colorHex)
        }
        dismiss()
    }

    private func cancel() {
        // A draft that was never saved should not linger in the store.
        if !isEditing, let draft = draftRoutine {
            viewModel.deleteRoutine(draft)
            draftRoutine = nil
        }
        dismiss()
    }
}

// MARK: - Exercise row inside the routine editor

private struct RoutineExerciseRow: View {
    let routineExercise: RoutineExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Text(routineExercise.exercise?.name ?? "Exercise")
                    .font(.body.weight(.medium))
                if let tag = routineExercise.supersetTag, !tag.isEmpty {
                    Text(tag)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.15), in: Capsule())
                        .foregroundStyle(.purple)
                }
            }
            Text("\(routineExercise.defaultSets) × \(routineExercise.defaultReps) · \(routineExercise.restSeconds)s rest")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Per-exercise defaults editor

struct RoutineExerciseEditorView: View {
    @Bindable var routineExercise: RoutineExercise
    let viewModel: WorkoutViewModel

    var body: some View {
        Form {
            Section("Exercise") {
                Text(routineExercise.exercise?.name ?? "Exercise")
                    .font(.body.weight(.medium))
                if let muscle = routineExercise.exercise?.muscleGroup {
                    LabeledContent("Muscle group", value: muscle)
                }
            }

            Section("Defaults") {
                Stepper("Sets: \(routineExercise.defaultSets)", value: $routineExercise.defaultSets, in: 1...12)
                Stepper("Reps: \(routineExercise.defaultReps)", value: $routineExercise.defaultReps, in: 1...100)

                HStack {
                    Text("Weight (kg)")
                    Spacer()
                    TextField("Optional", value: Binding(
                        get: { routineExercise.defaultWeightKg ?? 0 },
                        set: { routineExercise.defaultWeightKg = $0 == 0 ? nil : $0 }
                    ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                }

                Picker("Rest", selection: $routineExercise.restSeconds) {
                    ForEach([30, 45, 60, 90, 120, 180], id: \.self) { s in
                        Text("\(s)s").tag(s)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                TextField("Superset tag (e.g. A, B)", text: Binding(
                    get: { routineExercise.supersetTag ?? "" },
                    set: { routineExercise.supersetTag = $0.isEmpty ? nil : $0 }
                ))
            } header: {
                Text("Superset (optional)")
            } footer: {
                Text("Exercises sharing the same tag are performed back to back.")
            }
        }
        .navigationTitle("Exercise Defaults")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            try? viewModel.saveContext()
        }
    }
}

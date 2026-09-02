import SwiftUI

/// Picker for adding exercises to a routine or active session.
/// Tap a row to select; the chart icon navigates to that exercise's history.
struct ExercisePickerView: View {
    let viewModel: WorkoutViewModel
    var onSelect: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var muscleFilter = "All"
    @State private var equipmentFilter = "All"
    @State private var showingCreateCustom = false

    private var results: [Exercise] {
        viewModel.searchExercises(
            query: query,
            muscleFilter: muscleFilter,
            equipmentFilter: equipmentFilter
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(results, id: \.id) { exercise in
                        HStack(spacing: 12) {
                            Button {
                                onSelect(exercise)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(exercise.name)
                                                .foregroundStyle(.primary)
                                            if exercise.isCustom {
                                                Text("custom")
                                                    .font(.caption2.weight(.semibold))
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 1)
                                                    .background(Color.blue.opacity(0.12), in: Capsule())
                                                    .foregroundStyle(.blue)
                                            }
                                        }
                                        Text("\(exercise.muscleGroup) · \(exercise.equipmentType)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                ExerciseDetailView(exercise: exercise, viewModel: viewModel)
                            } label: {
                                Image(systemName: "chart.bar")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    if results.isEmpty {
                        ContentUnavailableView.search(text: query)
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("\(results.count) exercises")
                }
            }
            .searchable(text: $query, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showingCreateCustom = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Menu {
                        Button("All") { muscleFilter = "All" }
                        ForEach(ExerciseSeedData.muscleGroups, id: \.self) { m in
                            Button(m) { muscleFilter = m }
                        }
                    } label: {
                        Label(muscleFilter, systemImage: "figure.arms.open")
                    }

                    Spacer()

                    Menu {
                        Button("All") { equipmentFilter = "All" }
                        ForEach(ExerciseSeedData.equipmentTypes, id: \.self) { e in
                            Button(e) { equipmentFilter = e }
                        }
                    } label: {
                        Label(equipmentFilter, systemImage: "wrench.and.screwdriver")
                    }
                }
            }
            .sheet(isPresented: $showingCreateCustom) { CreateCustomExerciseView(viewModel: viewModel) { exercise in
                onSelect(exercise)
                dismiss()
            } }
        }
    }
}

// MARK: - Custom exercise creation

struct CreateCustomExerciseView: View {
    let viewModel: WorkoutViewModel
    var onCreate: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var muscleGroup = "Chest"
    @State private var equipmentType = "Barbell"
    @State private var exerciseType = "Weighted"

    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise name", text: $name)

                Picker("Muscle group", selection: $muscleGroup) {
                    ForEach(ExerciseSeedData.muscleGroups, id: \.self) { m in
                        Text(m).tag(m)
                    }
                }

                Picker("Equipment", selection: $equipmentType) {
                    ForEach(ExerciseSeedData.equipmentTypes, id: \.self) { e in
                        Text(e).tag(e)
                    }
                }

                Picker("Type", selection: $exerciseType) {
                    ForEach(ExerciseSeedData.exerciseTypes, id: \.self) { t in
                        Text(t).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }
            .navigationTitle("Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        let exercise = viewModel.createCustomExercise(
                            name: trimmed,
                            muscleGroup: muscleGroup,
                            equipmentType: equipmentType,
                            exerciseType: exerciseType
                        )
                        onCreate(exercise)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

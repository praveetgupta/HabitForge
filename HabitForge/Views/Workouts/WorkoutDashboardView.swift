import SwiftUI
import SwiftData

struct WorkoutDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WorkoutViewModel?
    @State private var showingCreateRoutine = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.routines.isEmpty {
                        ContentUnavailableView(
                            "No routines yet",
                            systemImage: "dumbbell",
                            description: Text("Create your first workout routine")
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(vm.routines, id: \.id) { routine in
                                    RoutineCardView(routine: routine, viewModel: vm)
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCreateRoutine = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateRoutine) {
                CreateRoutineView(viewModel: viewModel!)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = WorkoutViewModel(modelContext: modelContext)
                }
            }
        }
    }
}

struct RoutineCardView: View {
    let routine: Routine
    let viewModel: WorkoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(routine.icon)
                    .font(.title2)
                Text(routine.name)
                    .font(.title3.bold())
                Spacer()
            }
            
            Text("\(routine.templateExercises.count) exercises")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let lastPerformed = routine.lastPerformedAt {
                Text("Last: \(lastPerformed.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button("Start Workout") {
                // TODO: viewModel.startSession(from: routine)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: routine.colorHex) ?? .blue)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

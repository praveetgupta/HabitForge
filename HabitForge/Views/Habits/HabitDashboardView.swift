import SwiftUI
import SwiftData

struct HabitDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HabitViewModel?
    @State private var showingAddHabit = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.habits.isEmpty {
                        ContentUnavailableView(
                            "No habits yet",
                            systemImage: "flame",
                            description: Text("Tap + to create your first habit")
                        )
                    } else {
                        ScrollView {
                            // TODO: Add overall progress ring
                            // TODO: Add habit grid with circular progress rings
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 20) {
                                ForEach(vm.habits, id: \.id) { habit in
                                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                                        HabitRingView(habit: habit, viewModel: vm)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(viewModel: viewModel!)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = HabitViewModel(modelContext: modelContext)
                }
            }
        }
    }
}

#Preview {
    HabitDashboardView()
        .modelContainer(for: Habit.self, inMemory: true)
}

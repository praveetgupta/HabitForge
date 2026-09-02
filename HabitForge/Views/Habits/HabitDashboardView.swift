import SwiftUI
import SwiftData

struct HabitDashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: \Habit.sortOrder
    )
    private var queriedHabits: [Habit]

    @State private var viewModel: HabitViewModel?
    @State private var showingNewHabit = false
    @State private var habitToEdit: Habit?
    @State private var navPath = NavigationPath()
    @State private var showingProgressDetail = false

    var body: some View {
        NavigationStack(path: $navPath) {
            Group {
                if let vm = viewModel {
                    if queriedHabits.isEmpty {
                        ContentUnavailableView(
                            "No habits yet",
                            systemImage: "flame",
                            description: Text("Tap + to create your first habit")
                        )
                    } else {
                        ScrollView {
                            VStack(spacing: 28) {
                                overallProgressSection(vm: vm)
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Your Habits")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    habitGrid(vm: vm)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                progressGraphSection(vm: vm)
                                    .padding(.top, 12)
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 12)
                            .padding(.bottom, 20)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let vm = viewModel, let h = queriedHabits.first(where: { $0.id == id }) {
                    HabitDetailView(habit: h, viewModel: vm)
                }
            }
            .sheet(isPresented: $showingNewHabit) {
                if let vm = viewModel {
                    AddHabitView(viewModel: vm, habitToEdit: nil)
                }
            }
            .sheet(item: $habitToEdit) { habit in
                if let vm = viewModel {
                    AddHabitView(viewModel: vm, habitToEdit: habit)
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel?.showingTimerFor != nil },
                set: { isOn in
                    if !isOn, let vm = viewModel, vm.showingTimerFor != nil {
                        // Swipe-to-dismiss: keep elapsed time
                        vm.stopTimer(saveProgress: true)
                    }
                }
            )) {
                if let vm = viewModel, let h = vm.showingTimerFor {
                    HabitTimerView(habit: h, viewModel: vm)
                }
            }
            .fullScreenCover(isPresented: $showingProgressDetail) {
                if let vm = viewModel {
                    NavigationStack {
                        ScrollView {
                            HabitOverallGraphView(viewModel: vm, habits: queriedHabits, isCompact: false)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                        }
                        .background(Color(.systemGroupedBackground))
                        .navigationTitle("Progress")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showingProgressDetail = false
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = HabitViewModel(modelContext: modelContext)
                }
                viewModel?.habits = queriedHabits
            }
            .onChange(of: queriedHabits) { _, new in
                viewModel?.habits = new
            }
        }
    }

    @ViewBuilder
    private func overallProgressSection(vm: HabitViewModel) -> some View {
        let stats = vm.dailyCompletionProgress(on: Date())
        let total = max(stats.total, 1)
        let frac = Double(stats.completed) / Double(total)
        let accent = Color.accentColor

        VStack(spacing: 14) {
            Text(Date(), format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            ZStack {
                ProgressRingView(progress: frac, lineWidth: 14, color: accent, size: 120)
                VStack(spacing: 2) {
                    Text("\(stats.completed)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("of \(stats.total) today")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: frac)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    private func progressGraphSection(vm: HabitViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                showingProgressDetail = true
            } label: {
                HStack {
                    Text("Progress")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HabitOverallGraphView(viewModel: vm, habits: queriedHabits, isCompact: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func habitGrid(vm: HabitViewModel) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]

        return LazyVGrid(columns: columns, spacing: 20) {
            ForEach(queriedHabits, id: \.id) { habit in
                HabitRingView(
                    habit: habit,
                    viewModel: vm,
                    onViewStats: { navPath.append(habit.id) },
                    onEdit: {
                        habitToEdit = habit
                    }
                )
            }
        }
    }

}

#Preview {
    HabitDashboardView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

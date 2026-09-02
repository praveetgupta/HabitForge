import SwiftUI
import SwiftData

struct WorkoutDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WorkoutViewModel?
    @State private var showingCreateRoutine = false
    @State private var routineToEdit: Routine?
    @State private var routineForDialog: Routine?
    @State private var sessionToSummarize: WorkoutSession?
    @State private var showingHistory = false
    @State private var showingActiveSession = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.routines.isEmpty && vm.sessions.isEmpty {
                        ContentUnavailableView {
                            Label("No routines yet", systemImage: "dumbbell")
                        } description: {
                            Text("Create your first routine, or start an empty workout and build as you go.")
                        } actions: {
                            Button("New Routine") { showingCreateRoutine = true }
                                .buttonStyle(.borderedProminent)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if let active = vm.activeSession {
                                    Button {
                                        showingActiveSession = true
                                    } label: {
                                        ResumeBanner(session: active)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Resume workout in progress")
                                }

                                if !vm.routines.isEmpty {
                                    routineSection(vm)
                                }

                                if !vm.sessions.isEmpty {
                                    recentSessionsSection(vm)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    if let vm = viewModel {
                        NavigationLink(destination: WorkoutProgressView(viewModel: vm)) {
                            Image(systemName: "chart.bar.fill")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingCreateRoutine = true
                        } label: {
                            Label("New Routine", systemImage: "square.and.pencil")
                        }
                        Button {
                            if let vm = viewModel {
                                if vm.activeSession == nil {
                                    vm.startEmptySession()
                                }
                                showingActiveSession = true
                            }
                        } label: {
                            Label("Empty Workout", systemImage: "figure.strength training")
                        }
                        Button {
                            showingHistory = true
                        } label: {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Workout menu")
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = WorkoutViewModel(modelContext: modelContext)
                } else {
                    viewModel?.fetchSessions()
                    viewModel?.fetchRoutines()
                }
            }
            // Two-sheet rule (HANDOFF §6.1): isPresented for "new", item for "edit".
            .sheet(isPresented: $showingCreateRoutine) {
                if let vm = viewModel {
                    CreateRoutineView(viewModel: vm)
                }
            }
            .sheet(item: $routineToEdit) { routine in
                if let vm = viewModel {
                    CreateRoutineView(viewModel: vm, routine: routine)
                }
            }
            .sheet(item: $sessionToSummarize) { session in
                WorkoutSummaryView(session: session)
            }
            .navigationDestination(isPresented: $showingHistory) {
                if let vm = viewModel {
                    WorkoutHistoryView(viewModel: vm)
                }
            }
            .confirmationDialog(
                routineForDialog?.name ?? "",
                isPresented: Binding(get: { routineForDialog != nil },
                                     set: { if !$0 { routineForDialog = nil } }),
                titleVisibility: .visible
            ) {
                Button("Edit Routine") {
                    if let routine = routineForDialog {
                        routineToEdit = routine
                    }
                }
                Button("Archive Routine", role: .destructive) {
                    if let routine = routineForDialog {
                        viewModel?.archiveRoutine(routine)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showingActiveSession) {
                if let vm = viewModel, let session = vm.activeSession {
                    ActiveWorkoutView(viewModel: vm, session: session) { finished in
                        showingActiveSession = false
                        // Wait for the cover to finish dismissing before presenting the summary.
                        if let finished {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                sessionToSummarize = finished
                            }
                        }
                    }
                }
            }
        }
    }

    private func routineSection(_ vm: WorkoutViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Routines")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            ForEach(vm.routines, id: \.id) { routine in
                RoutineCardView(routine: routine) {
                    routineForDialog = routine
                } onEdit: {
                    routineToEdit = routine
                } onStart: {
                    vm.startSession(from: routine)
                    showingActiveSession = true
                }
            }
        }
    }

    private func recentSessionsSection(_ vm: WorkoutViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Sessions")
                    .font(.title3.bold())
                Spacer()
                Button("See All") { showingHistory = true }
                    .font(.subheadline)
            }
            .padding(.horizontal, 4)

            ForEach(vm.sessions.prefix(5), id: \.id) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    SessionRowView(session: session)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Routine card

struct RoutineCardView: View {
    let routine: Routine
    var onLongPress: () -> Void
    var onEdit: () -> Void
    var onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(routine.icon.isEmpty ? "🏋️" : routine.icon)
                    .font(.title2)
                Text(routine.name)
                    .font(.title3.bold())
                Spacer()
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Edit \(routine.name)")
            }

            let count = routine.templateExercises.count
            Text("\(count) exercise\(count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let lastPerformed = routine.lastPerformedAt {
                Text("Last: \(lastPerformed.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                onStart()
            } label: {
                Label("Start Workout", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: routine.colorHex) ?? .blue)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onLongPressGesture {
            onLongPress()
        }
    }
}

// MARK: - Resume banner

private struct ResumeBanner: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.strength training")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Workout in progress")
                    .font(.headline)
                Text(session.routine?.name ?? "Empty workout")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Session row

struct SessionRowView: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            Text(session.routine?.icon ?? "🏋️")
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.routine?.name ?? "Workout")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(durationText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    if session.numberOfPRs > 0 {
                        Label("\(session.numberOfPRs)", systemImage: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    Text(volumeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var durationText: String {
        guard let secs = session.durationSeconds else { return "—" }
        return Self.formatDuration(secs)
    }

    private var volumeText: String {
        session.totalVolumeKg > 0
            ? "\(Int(session.totalVolumeKg).formatted()) kg"
            : "\(session.performedExercises.count) exercises"
    }

    static func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}

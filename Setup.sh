#!/bin/bash

# ============================================================
# HabitForge — Project Structure Generator
# ============================================================
# 
# HOW TO USE:
# 1. Open Terminal
# 2. cd into your HabitForge Xcode project folder
#    (the folder that contains HabitForge.xcodeproj)
# 3. Run: chmod +x setup.sh && ./setup.sh
# 4. Open Xcode → Right-click "HabitForge" folder in navigator
#    → "Add Files to HabitForge" → select all new folders
#    → ✅ "Create groups" → ✅ "Add to target: HabitForge" → Add
# ============================================================

PROJECT_DIR="HabitForge"

# Check we're in the right place
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Error: Can't find '$PROJECT_DIR' folder."
    echo "   Make sure you're in the folder that contains HabitForge.xcodeproj"
    echo "   Current directory: $(pwd)"
    exit 1
fi

echo "🚀 Creating HabitForge project structure..."

# ============================================================
# Create all directories
# ============================================================
mkdir -p "$PROJECT_DIR/App"
mkdir -p "$PROJECT_DIR/Models"
mkdir -p "$PROJECT_DIR/ViewModels"
mkdir -p "$PROJECT_DIR/Views/Auth"
mkdir -p "$PROJECT_DIR/Views/Habits"
mkdir -p "$PROJECT_DIR/Views/Todos"
mkdir -p "$PROJECT_DIR/Views/Workouts"
mkdir -p "$PROJECT_DIR/Views/Settings"
mkdir -p "$PROJECT_DIR/Services"
mkdir -p "$PROJECT_DIR/Components"
mkdir -p "$PROJECT_DIR/Extensions"

echo "📁 Folders created"

# ============================================================
# App Layer
# ============================================================

cat > "$PROJECT_DIR/App/MainTabView.swift" << 'EOF'
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HabitDashboardView()
                .tabItem {
                    Label("Habits", systemImage: "flame.fill")
                }
            
            TodoSidebarView()
                .tabItem {
                    Label("Todos", systemImage: "checklist")
                }
            
            WorkoutDashboardView()
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
EOF

# ============================================================
# Models
# ============================================================

cat > "$PROJECT_DIR/Models/Habit.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class Habit {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var habitType: String                     // "Build" or "Break"
    var sortOrder: Int
    
    // Scheduling
    var frequency: String                     // "Daily", "Times per Week", "Times per Month"
    var targetCount: Int
    var scheduledDays: [Int]                  // [1=Mon...7=Sun], empty = every day
    
    // Duration tracking
    var tracksDuration: Bool
    var targetDurationSeconds: Int?
    
    // Count tracking
    var tracksCount: Bool
    var targetCountValue: Int?
    var countUnit: String?
    
    // Reminders
    var reminderEnabled: Bool
    var reminderTime: Date?
    
    // Metadata
    var createdAt: Date
    var isArchived: Bool
    var isPaused: Bool
    var pausedUntil: Date?
    
    // Cached stats
    var currentStreak: Int
    var bestStreak: Int
    var totalCompletions: Int
    
    @Relationship(deleteRule: .cascade)
    var entries: [HabitEntry] = []
    
    init(name: String, icon: String = "⭐", colorHex: String = "#FF6B6B",
         habitType: String = "Build", frequency: String = "Daily") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.habitType = habitType
        self.sortOrder = 0
        self.frequency = frequency
        self.targetCount = 1
        self.scheduledDays = []
        self.tracksDuration = false
        self.tracksCount = false
        self.reminderEnabled = false
        self.createdAt = Date()
        self.isArchived = false
        self.isPaused = false
        self.currentStreak = 0
        self.bestStreak = 0
        self.totalCompletions = 0
    }
}
EOF

cat > "$PROJECT_DIR/Models/HabitEntry.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class HabitEntry {
    var id: UUID
    var date: Date
    var timestamp: Date
    var isCompleted: Bool
    var durationSeconds: Int?
    var countValue: Int?
    var didAvoid: Bool?
    var note: String?
    var mood: String?                         // "😊", "🙂", "😐", "😓", "😞"
    
    var habit: Habit?
    
    init(date: Date = Date(), isCompleted: Bool = true) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.timestamp = Date()
        self.isCompleted = isCompleted
    }
}
EOF

cat > "$PROJECT_DIR/Models/Todo.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class Todo {
    var id: UUID
    var title: String
    var notes: String
    
    // Scheduling (Things 3 style)
    var whenDate: Date?
    var whenTime: Date?
    var deadline: Date?
    var isEvening: Bool
    
    // Reminders
    var reminderDate: Date?
    
    // Recurrence
    var isRepeating: Bool
    var repeatType: String?                   // "Daily", "Weekly", "Monthly", "Yearly"
    var repeatInterval: Int?
    var repeatDaysOfWeek: [Int]?
    var repeatAfterCompletion: Bool
    
    // Organization
    var status: String                        // "Inbox", "Today", "Upcoming", "Anytime", "Someday", "Logbook", "Trash"
    var priority: Int                         // 0=none, 1=low, 2=medium, 3=high
    var tags: [String]
    var headingId: UUID?
    var sortOrder: Int
    
    // Metadata
    var createdAt: Date
    var completedAt: Date?
    
    // Relationships
    var project: Project?
    var area: Area?
    
    @Relationship(deleteRule: .cascade)
    var checklist: [ChecklistItem] = []
    
    init(title: String, status: String = "Inbox") {
        self.id = UUID()
        self.title = title
        self.notes = ""
        self.isEvening = false
        self.isRepeating = false
        self.repeatAfterCompletion = false
        self.status = status
        self.priority = 0
        self.tags = []
        self.sortOrder = 0
        self.createdAt = Date()
    }
}
EOF

cat > "$PROJECT_DIR/Models/ChecklistItem.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class ChecklistItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    
    var todo: Todo?
    
    init(title: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.sortOrder = sortOrder
    }
}
EOF

cat > "$PROJECT_DIR/Models/Area.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class Area {
    var id: UUID
    var name: String
    var icon: String
    var sortOrder: Int
    var isArchived: Bool
    
    @Relationship(deleteRule: .nullify)
    var projects: [Project] = []
    
    @Relationship(deleteRule: .nullify)
    var todos: [Todo] = []
    
    init(name: String, icon: String = "📁") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = 0
        self.isArchived = false
    }
}
EOF

cat > "$PROJECT_DIR/Models/Project.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class Project {
    var id: UUID
    var name: String
    var notes: String
    var icon: String
    var colorHex: String
    var sortOrder: Int
    
    var whenDate: Date?
    var deadline: Date?
    
    var status: String                        // "Active", "Completed", "On Hold", "Dropped"
    var completedAt: Date?
    var createdAt: Date
    var tags: [String]
    
    var area: Area?
    
    @Relationship(deleteRule: .cascade)
    var todos: [Todo] = []
    
    @Relationship(deleteRule: .cascade)
    var headings: [ProjectHeading] = []
    
    var progressFraction: Double {
        let activeTodos = todos.filter { $0.status != "Trash" }
        guard !activeTodos.isEmpty else { return 0 }
        let completed = activeTodos.filter { $0.status == "Logbook" }.count
        return Double(completed) / Double(activeTodos.count)
    }
    
    init(name: String, icon: String = "📋", colorHex: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.notes = ""
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = 0
        self.status = "Active"
        self.createdAt = Date()
        self.tags = []
    }
}
EOF

cat > "$PROJECT_DIR/Models/ProjectHeading.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class ProjectHeading {
    var id: UUID
    var name: String
    var sortOrder: Int
    
    var project: Project?
    
    init(name: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
    }
}
EOF

cat > "$PROJECT_DIR/Models/Tag.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class Tag {
    var id: UUID
    var name: String
    var colorHex: String?
    var sortOrder: Int
    
    init(name: String, colorHex: String? = nil) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = 0
    }
}
EOF

cat > "$PROJECT_DIR/Models/Routine.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class Routine {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    var notes: String?
    var sortOrder: Int
    var isArchived: Bool
    var createdAt: Date
    var lastPerformedAt: Date?
    
    @Relationship(deleteRule: .cascade)
    var templateExercises: [RoutineExercise] = []
    
    @Relationship(deleteRule: .cascade)
    var sessions: [WorkoutSession] = []
    
    init(name: String, colorHex: String = "#007AFF", icon: String = "🏋️") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.sortOrder = 0
        self.isArchived = false
        self.createdAt = Date()
    }
}
EOF

cat > "$PROJECT_DIR/Models/Exercise.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: String
    var equipmentType: String
    var exerciseType: String                  // "Weighted", "Bodyweight", "Timed", "Cardio"
    var instructions: String?
    var isCustom: Bool
    var isArchived: Bool
    var createdAt: Date
    
    var prMaxWeight: Double?
    var prMaxVolume: Double?
    
    init(name: String, muscleGroup: String, equipmentType: String = "Barbell",
         exerciseType: String = "Weighted", isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipmentType = equipmentType
        self.exerciseType = exerciseType
        self.isCustom = isCustom
        self.isArchived = false
        self.createdAt = Date()
    }
}
EOF

cat > "$PROJECT_DIR/Models/RoutineExercise.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class RoutineExercise {
    var id: UUID
    var sortOrder: Int
    var defaultSets: Int
    var defaultReps: Int
    var defaultWeightKg: Double?
    var restSeconds: Int
    var notes: String?
    var supersetTag: String?
    
    var routine: Routine?
    var exercise: Exercise?
    
    init(sortOrder: Int, defaultSets: Int = 3, defaultReps: Int = 10, restSeconds: Int = 90) {
        self.id = UUID()
        self.sortOrder = sortOrder
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.restSeconds = restSeconds
    }
}
EOF

cat > "$PROJECT_DIR/Models/WorkoutSession.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class WorkoutSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var durationSeconds: Int?
    var notes: String?
    var mood: String?
    var isCompleted: Bool
    var totalVolumeKg: Double
    var numberOfPRs: Int
    
    var routine: Routine?
    
    @Relationship(deleteRule: .cascade)
    var performedExercises: [PerformedExercise] = []
    
    init(startTime: Date = Date()) {
        self.id = UUID()
        self.startTime = startTime
        self.isCompleted = false
        self.totalVolumeKg = 0
        self.numberOfPRs = 0
    }
}
EOF

cat > "$PROJECT_DIR/Models/PerformedExercise.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class PerformedExercise {
    var id: UUID
    var sortOrder: Int
    var exerciseName: String
    var muscleGroup: String
    
    var session: WorkoutSession?
    var exercise: Exercise?
    
    @Relationship(deleteRule: .cascade)
    var sets: [PerformedSet] = []
    
    init(exerciseName: String, muscleGroup: String, sortOrder: Int) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.muscleGroup = muscleGroup
        self.sortOrder = sortOrder
    }
}
EOF

cat > "$PROJECT_DIR/Models/PerformedSet.swift" << 'EOF'
import SwiftData
import Foundation

@Model
class PerformedSet {
    var id: UUID
    var setNumber: Int
    var setType: String                       // "Warmup", "Working", "Drop Set", "To Failure"
    var reps: Int?
    var weightKg: Double?
    var durationSeconds: Int?
    var distanceKm: Double?
    var isCompleted: Bool
    var isPR: Bool
    var timestamp: Date
    
    var performedExercise: PerformedExercise?
    
    init(setNumber: Int, setType: String = "Working") {
        self.id = UUID()
        self.setNumber = setNumber
        self.setType = setType
        self.isCompleted = false
        self.isPR = false
        self.timestamp = Date()
    }
}
EOF

# ============================================================
# ViewModels (stubs — flesh these out from the guide)
# ============================================================

cat > "$PROJECT_DIR/ViewModels/HabitViewModel.swift" << 'EOF'
import SwiftUI
import SwiftData

@Observable
class HabitViewModel {
    private var modelContext: ModelContext
    
    var habits: [Habit] = []
    var selectedDate: Date = Date()
    
    // Timer state
    var showingTimerFor: Habit?
    var timerSeconds: Int = 0
    var timerRunning: Bool = false
    private var timer: Timer?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchHabits()
    }
    
    func fetchHabits() {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        habits = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        let targetDate = Calendar.current.startOfDay(for: date)
        return habit.entries.contains { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: targetDate) && entry.isCompleted
        }
    }
    
    func toggleHabit(_ habit: Habit) {
        let today = Calendar.current.startOfDay(for: Date())
        if let existing = habit.entries.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }) {
            existing.isCompleted.toggle()
        } else {
            let entry = HabitEntry(date: today, isCompleted: true)
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
        try? modelContext.save()
        fetchHabits()
    }
    
    func addHabit(name: String, icon: String, colorHex: String) {
        let habit = Habit(name: name, icon: icon, colorHex: colorHex)
        habit.sortOrder = habits.count
        modelContext.insert(habit)
        try? modelContext.save()
        fetchHabits()
    }
    
    // TODO: Implement full ViewModel from HabitForge-Habit-Module.md
    // - progressFraction(), incrementCount(), startTimer(), stopTimer()
    // - recalculateStreak(), completionRate(), chartData(), heatmapData()
}
EOF

cat > "$PROJECT_DIR/ViewModels/TodoViewModel.swift" << 'EOF'
import SwiftUI
import SwiftData

@Observable
class TodoViewModel {
    private var modelContext: ModelContext
    
    var inboxTodos: [Todo] = []
    var todayTodos: [Todo] = []
    var upcomingTodos: [Todo] = []
    var anytimeTodos: [Todo] = []
    var somedayTodos: [Todo] = []
    
    var areas: [Area] = []
    var projects: [Project] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchAll()
    }
    
    func fetchAll() {
        fetchTodos()
        fetchAreas()
        fetchProjects()
    }
    
    private func fetchTodos() {
        let descriptor = FetchDescriptor<Todo>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let allTodos = (try? modelContext.fetch(descriptor)) ?? []
        
        inboxTodos = allTodos.filter { $0.status == "Inbox" }
        todayTodos = allTodos.filter { $0.status == "Today" }
        upcomingTodos = allTodos.filter { $0.status == "Upcoming" }
        anytimeTodos = allTodos.filter { $0.status == "Anytime" }
        somedayTodos = allTodos.filter { $0.status == "Someday" }
    }
    
    private func fetchAreas() {
        let descriptor = FetchDescriptor<Area>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        areas = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func fetchProjects() {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        projects = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func quickAdd(title: String) {
        let todo = Todo(title: title, status: "Inbox")
        modelContext.insert(todo)
        try? modelContext.save()
        fetchTodos()
    }
    
    func completeTodo(_ todo: Todo) {
        todo.status = "Logbook"
        todo.completedAt = Date()
        try? modelContext.save()
        fetchTodos()
    }
    
    func moveToToday(_ todo: Todo) {
        todo.status = "Today"
        todo.whenDate = Calendar.current.startOfDay(for: Date())
        try? modelContext.save()
        fetchTodos()
    }
    
    // TODO: Implement full ViewModel from HabitForge-Todo-Module.md
    // - Full CRUD, scheduling, project management, search, repeating tasks
}
EOF

cat > "$PROJECT_DIR/ViewModels/WorkoutViewModel.swift" << 'EOF'
import SwiftUI
import SwiftData

@Observable
class WorkoutViewModel {
    private var modelContext: ModelContext
    
    var routines: [Routine] = []
    var exerciseLibrary: [Exercise] = []
    var activeSession: WorkoutSession?
    
    // Rest timer
    var restTimerSeconds: Int = 0
    var restTimerRunning: Bool = false
    private var restTimer: Timer?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchRoutines()
        fetchExercises()
    }
    
    func fetchRoutines() {
        let descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        routines = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchExercises() {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.name)]
        )
        exerciseLibrary = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func createRoutine(name: String, icon: String, colorHex: String) {
        let routine = Routine(name: name, colorHex: colorHex, icon: icon)
        routine.sortOrder = routines.count
        modelContext.insert(routine)
        try? modelContext.save()
        fetchRoutines()
    }
    
    // TODO: Implement full ViewModel from HabitForge-Workout-Module.md
    // - startSession(), completeSet(), addSet(), finishSession()
    // - rest timer, PR detection, exercise history, progress charts
}
EOF

cat > "$PROJECT_DIR/ViewModels/AuthViewModel.swift" << 'EOF'
import SwiftUI

@Observable
class AuthViewModel {
    var isAuthenticated: Bool = false
    var currentUserEmail: String?
    var isLoading: Bool = false
    var errorMessage: String?
    
    // TODO: Implement Firebase Auth
    // - signIn(email:password:)
    // - signUp(email:password:)
    // - signInWithApple()
    // - signOut()
    
    func signIn(email: String, password: String) {
        // Placeholder — implement with Firebase Auth
        isAuthenticated = true
        currentUserEmail = email
    }
    
    func signOut() {
        isAuthenticated = false
        currentUserEmail = nil
    }
}
EOF

# ============================================================
# Views — Habits
# ============================================================

cat > "$PROJECT_DIR/Views/Habits/HabitDashboardView.swift" << 'EOF'
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
EOF

cat > "$PROJECT_DIR/Views/Habits/HabitRingView.swift" << 'EOF'
import SwiftUI

struct HabitRingView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    
    private var progress: Double {
        viewModel.isCompleted(habit, on: Date()) ? 1.0 : 0.0
    }
    
    private var habitColor: Color {
        Color(hex: habit.colorHex) ?? .blue
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(habitColor.opacity(0.2), lineWidth: 8)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(habitColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                // Icon
                Text(habit.icon)
                    .font(.system(size: 28))
            }
            .frame(width: 80, height: 80)
            .onTapGesture {
                viewModel.toggleHabit(habit)
            }
            
            Text(habit.name)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
    }
}
EOF

cat > "$PROJECT_DIR/Views/Habits/HabitDetailView.swift" << 'EOF'
import SwiftUI
import Charts

struct HabitDetailView: View {
    let habit: Habit
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Large ring with streak
                ZStack {
                    Circle()
                        .stroke(Color(hex: habit.colorHex)?.opacity(0.2) ?? Color.blue.opacity(0.2), lineWidth: 12)
                    
                    VStack {
                        Text("\(habit.currentStreak)")
                            .font(.system(size: 48, weight: .bold))
                        Text("day streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 160, height: 160)
                
                // Stats row
                HStack(spacing: 24) {
                    StatBox(label: "Current", value: "\(habit.currentStreak)")
                    StatBox(label: "Best", value: "\(habit.bestStreak)")
                    StatBox(label: "Total", value: "\(habit.totalCompletions)")
                }
                
                // TODO: Calendar heatmap (HabitCalendarView)
                // TODO: Completion bar chart (HabitChartView)
                // TODO: Entry history list
            }
            .padding()
        }
        .navigationTitle(habit.name)
    }
}

struct StatBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
EOF

cat > "$PROJECT_DIR/Views/Habits/AddHabitView.swift" << 'EOF'
import SwiftUI

struct AddHabitView: View {
    let viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var icon = "⭐"
    @State private var colorHex = "#FF6B6B"
    @State private var habitType = "Build"
    @State private var tracksDuration = false
    @State private var tracksCount = false
    
    let colorOptions = ["#FF6B6B", "#FF9500", "#FFCC00", "#34C759", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("Habit name", text: $name)
                    
                    // TODO: Emoji picker
                    TextField("Icon (emoji)", text: $icon)
                    
                    Picker("Type", selection: $habitType) {
                        Text("Build (do it)").tag("Build")
                        Text("Break (avoid it)").tag("Break")
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(.white, lineWidth: colorHex == hex ? 3 : 0)
                                )
                                .onTapGesture { colorHex = hex }
                        }
                    }
                }
                
                Section("Tracking") {
                    Toggle("Track duration", isOn: $tracksDuration)
                    Toggle("Track count", isOn: $tracksCount)
                }
                
                // TODO: Scheduling section (frequency, days)
                // TODO: Reminder section
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addHabit(name: name, icon: icon, colorHex: colorHex)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
EOF

cat > "$PROJECT_DIR/Views/Habits/HabitCalendarView.swift" << 'EOF'
import SwiftUI

struct HabitCalendarView: View {
    let habit: Habit
    
    var body: some View {
        VStack {
            Text("Calendar Heatmap")
                .font(.headline)
            // TODO: Implement month calendar with colored cells
            // See HabitForge-Habit-Module.md for heatmapData()
            Text("Coming soon")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
EOF

cat > "$PROJECT_DIR/Views/Habits/HabitChartView.swift" << 'EOF'
import SwiftUI
import Charts

struct HabitChartView: View {
    let habit: Habit
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Last 30 Days")
                .font(.headline)
            
            // TODO: Implement bar chart with Swift Charts
            // See HabitForge-Habit-Module.md for chartData()
            Text("Chart placeholder")
                .foregroundStyle(.secondary)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
}
EOF

cat > "$PROJECT_DIR/Views/Habits/HabitTimerView.swift" << 'EOF'
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
EOF

# ============================================================
# Views — Todos
# ============================================================

cat > "$PROJECT_DIR/Views/Todos/TodoSidebarView.swift" << 'EOF'
import SwiftUI
import SwiftData

struct TodoSidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodoViewModel?
    @State private var selectedList: String = "Today"
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    List(selection: $selectedList) {
                        Section {
                            NavigationLink(destination: InboxView(viewModel: vm)) {
                                Label("Inbox", systemImage: "tray")
                                    .badge(vm.inboxTodos.count)
                            }
                            NavigationLink(destination: TodayView(viewModel: vm)) {
                                Label("Today", systemImage: "star.fill")
                                    .badge(vm.todayTodos.count)
                            }
                            NavigationLink(destination: UpcomingView(viewModel: vm)) {
                                Label("Upcoming", systemImage: "calendar")
                            }
                            NavigationLink(destination: AnytimeView(viewModel: vm)) {
                                Label("Anytime", systemImage: "tray.full")
                            }
                            NavigationLink(destination: SomedayView(viewModel: vm)) {
                                Label("Someday", systemImage: "moon.zzz")
                            }
                            NavigationLink(destination: LogbookView(viewModel: vm)) {
                                Label("Logbook", systemImage: "book.closed")
                            }
                        }
                        
                        if !vm.areas.isEmpty {
                            Section("Areas") {
                                ForEach(vm.areas, id: \.id) { area in
                                    DisclosureGroup {
                                        ForEach(area.projects, id: \.id) { project in
                                            NavigationLink(destination: ProjectView(project: project, viewModel: vm)) {
                                                Label(project.name, systemImage: "doc.text")
                                            }
                                        }
                                    } label: {
                                        Label(area.name, systemImage: "folder")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Todos")
            .onAppear {
                if viewModel == nil {
                    viewModel = TodoViewModel(modelContext: modelContext)
                }
            }
        }
    }
}
EOF

cat > "$PROJECT_DIR/Views/Todos/TodayView.swift" << 'EOF'
import SwiftUI

struct TodayView: View {
    let viewModel: TodoViewModel
    @State private var showingQuickAdd = false
    
    var body: some View {
        List {
            // Morning todos
            ForEach(viewModel.todayTodos.filter { !$0.isEvening }, id: \.id) { todo in
                TodoRowView(todo: todo, viewModel: viewModel)
            }
            
            // Evening section
            if viewModel.todayTodos.contains(where: { $0.isEvening }) {
                Section("This Evening") {
                    ForEach(viewModel.todayTodos.filter { $0.isEvening }, id: \.id) { todo in
                        TodoRowView(todo: todo, viewModel: viewModel)
                    }
                }
            }
        }
        .navigationTitle("Today")
        .overlay(alignment: .bottomTrailing) {
            // Magic Plus button
            Button(action: { showingQuickAdd = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)
                    .shadow(radius: 4)
            }
            .padding(24)
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddView(viewModel: viewModel)
        }
    }
}
EOF

cat > "$PROJECT_DIR/Views/Todos/TodoRowView.swift" << 'EOF'
import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let viewModel: TodoViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion circle
            Button(action: { viewModel.completeTodo(todo) }) {
                Image(systemName: todo.status == "Logbook" ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.status == "Logbook" ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough(todo.status == "Logbook")
                    .foregroundStyle(todo.status == "Logbook" ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    if let project = todo.project {
                        Label(project.name, systemImage: "doc.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let deadline = todo.deadline {
                        Label(deadline.formatted(date: .abbreviated, time: .omitted), systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    if todo.priority > 0 {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(priorityColor)
                    }
                }
            }
            
            Spacer()
        }
        .swipeActions(edge: .leading) {
            Button("Today") { viewModel.moveToToday(todo) }
                .tint(.orange)
        }
    }
    
    private var priorityColor: Color {
        switch todo.priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return .gray
        }
    }
}
EOF

cat > "$PROJECT_DIR/Views/Todos/InboxView.swift" << 'EOF'
import SwiftUI

struct InboxView: View {
    let viewModel: TodoViewModel
    @State private var showingQuickAdd = false
    
    var body: some View {
        List {
            if viewModel.inboxTodos.isEmpty {
                ContentUnavailableView(
                    "Inbox Zero",
                    systemImage: "tray",
                    description: Text("All tasks have been processed")
                )
            } else {
                ForEach(viewModel.inboxTodos, id: \.id) { todo in
                    TodoRowView(todo: todo, viewModel: viewModel)
                }
            }
        }
        .navigationTitle("Inbox")
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showingQuickAdd = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)
                    .shadow(radius: 4)
            }
            .padding(24)
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddView(viewModel: viewModel)
        }
    }
}
EOF

cat > "$PROJECT_DIR/Views/Todos/UpcomingView.swift" << 'EOF'
import SwiftUI

struct UpcomingView: View {
    let viewModel: TodoViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.upcomingTodos, id: \.id) { todo in
                TodoRowView(todo: todo, viewModel: viewModel)
            }
        }
        .navigationTitle("Upcoming")
    }
}
EOF

cat > "$PROJECT_DIR/Views/Todos/AnytimeView.swift" << 'EOF'
import SwiftUI

struct AnytimeView: View {
    let viewModel: TodoViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.anytimeTodos, id: \.id) { todo in
                TodoRowView(todo: todo, viewModel: viewModel)
            }
        }
        .navigationTitle("Anytime")
    }
}
EOF

cat > "$PROJECT_DIR/Views/Todos/SomedayView.swift" << 'EOF'
import SwiftUI

struct SomedayView: View {
    let viewModel: TodoViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.somedayTodos, id: \.id) { todo in
                TodoRowView(todo: todo, viewModel: viewModel)
            }
        }
        .navigationTitle("Someday")
    }
}
EOF

cat > "$PROJECT_DIR/Views/Todos/LogbookView.swift" << 'EOF'
import SwiftUI

struct LogbookView: View {
    let viewModel: TodoViewModel
    
    var body: some View {
        List {
            // TODO: Fetch and display completed todos grouped by date
            Text("Completed tasks will appear here")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Logbook")
    }
}
EOF

cat > "$PROJECT_DIR/Views/Todos/TodoDetailView.swift" << 'EOF'
import SwiftUI

struct TodoDetailView: View {
    let todo: Todo
    let viewModel: TodoViewModel
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: .constant(todo.title))
                    .font(.title3)
            }
            
            Section("Notes") {
                TextEditor(text: .constant(todo.notes))
                    .frame(minHeight: 100)
            }
            
            Section("Schedule") {
                // TODO: When date picker
                // TODO: Deadline date picker
                // TODO: Reminder picker
                // TODO: Repeat rule picker
                Text("Scheduling options — implement from guide")
                    .foregroundStyle(.secondary)
            }
            
            Section("Checklist") {
                ForEach(todo.checklist.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.id) { item in
                    HStack {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isCompleted ? .green : .secondary)
                        Text(item.title)
                    }
                }
                // TODO: Add checklist item
            }
        }
        .navigationTitle("Details")
    }
}
EOF

cat > "$PROJECT_DIR/Views/Todos/QuickAddView.swift" << 'EOF'
import SwiftUI

struct QuickAddView: View {
    let viewModel: TodoViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var addToToday = false
    @State private var isEvening = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("What do you want to do?", text: $title)
                    .font(.title3)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Quick schedule buttons
                HStack(spacing: 12) {
                    QuickButton(label: "Today", icon: "star.fill") { addToToday = true; isEvening = false }
                    QuickButton(label: "Evening", icon: "moon.fill") { addToToday = true; isEvening = true }
                    // TODO: Tomorrow, +7 days buttons
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if addToToday {
                            let todo = viewModel.quickAdd(title: title)
                            viewModel.moveToToday(todo)
                        } else {
                            viewModel.quickAdd(title: title)
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct QuickButton: View {
    let label: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}
EOF

cat > "$PROJECT_DIR/Views/Todos/ProjectView.swift" << 'EOF'
import SwiftUI

struct ProjectView: View {
    let project: Project
    let viewModel: TodoViewModel
    
    var body: some View {
        List {
            // Progress bar
            Section {
                ProgressView(value: project.progressFraction)
                    .tint(Color(hex: project.colorHex) ?? .blue)
            }
            
            // Project notes
            if !project.notes.isEmpty {
                Section("Notes") {
                    Text(project.notes)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Todos grouped by heading
            // TODO: Group by headings from ProjectHeading
            Section("Tasks") {
                ForEach(project.todos.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.id) { todo in
                    TodoRowView(todo: todo, viewModel: viewModel)
                }
            }
        }
        .navigationTitle(project.name)
    }
}
EOF

# ============================================================
# Views — Workouts
# ============================================================

cat > "$PROJECT_DIR/Views/Workouts/WorkoutDashboardView.swift" << 'EOF'
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
EOF

cat > "$PROJECT_DIR/Views/Workouts/CreateRoutineView.swift" << 'EOF'
import SwiftUI

struct CreateRoutineView: View {
    let viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var icon = "🏋️"
    @State private var colorHex = "#007AFF"
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Routine name", text: $name)
                TextField("Icon (emoji)", text: $icon)
                // TODO: Color picker, exercise picker
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createRoutine(name: name, icon: icon, colorHex: colorHex)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
EOF

cat > "$PROJECT_DIR/Views/Workouts/ActiveWorkoutView.swift" << 'EOF'
import SwiftUI

struct ActiveWorkoutView: View {
    // TODO: Implement from HabitForge-Workout-Module.md
    // - Session timer, exercise cards, set logging
    // - Rest timer overlay, add exercise, finish workout
    
    var body: some View {
        Text("Active Workout — implement from guide")
            .navigationTitle("Workout")
    }
}
EOF

cat > "$PROJECT_DIR/Views/Workouts/ExercisePickerView.swift" << 'EOF'
import SwiftUI

struct ExercisePickerView: View {
    // TODO: Browse/search exercise library
    // Filter by muscle group tabs + equipment type
    
    var body: some View {
        Text("Exercise Picker — implement from guide")
            .navigationTitle("Exercises")
    }
}
EOF

cat > "$PROJECT_DIR/Views/Workouts/WorkoutProgressView.swift" << 'EOF'
import SwiftUI
import Charts

struct WorkoutProgressView: View {
    // TODO: Per-exercise progress graphs (weight, volume, 1RM)
    
    var body: some View {
        Text("Workout Progress — implement from guide")
            .navigationTitle("Progress")
    }
}
EOF

# ============================================================
# Views — Settings
# ============================================================

cat > "$PROJECT_DIR/Views/Settings/SettingsView.swift" << 'EOF'
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    NavigationLink("Profile", destination: Text("Profile View"))
                    NavigationLink("Subscription", destination: SubscriptionView())
                }
                
                Section("Preferences") {
                    NavigationLink("Notifications", destination: Text("Notification Settings"))
                    // TODO: Units (kg/lbs), theme, export data
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
EOF

cat > "$PROJECT_DIR/Views/Settings/SubscriptionView.swift" << 'EOF'
import SwiftUI

struct SubscriptionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("HabitForge Pro")
                .font(.largeTitle.bold())
            
            // TODO: RevenueCat paywall
            Text("Unlock unlimited habits, todos, routines, and cloud sync")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                Text("$4.99/month")
                Text("$39.99/year (save 33%)")
                    .foregroundStyle(.secondary)
            }
            
            Button("Subscribe") {
                // TODO: RevenueCat purchase
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Pro")
    }
}
EOF

# ============================================================
# Views — Auth
# ============================================================

cat > "$PROJECT_DIR/Views/Auth/LoginView.swift" << 'EOF'
import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("HabitForge")
                .font(.largeTitle.bold())
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            Button("Sign In") {
                // TODO: Firebase Auth
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // TODO: Sign in with Apple button
            // TODO: Sign up link
        }
        .padding(32)
    }
}
EOF

# ============================================================
# Services
# ============================================================

cat > "$PROJECT_DIR/Services/NotificationService.swift" << 'EOF'
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }
    
    func scheduleHabitReminder(habit: Habit) {
        guard let reminderTime = habit.reminderTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(habit.icon) \(habit.name)"
        content.body = "Keep your streak going!"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "habit-\(habit.id)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleTodoReminder(todo: Todo) {
        guard let reminderDate = todo.reminderDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = todo.title
        content.body = todo.notes.isEmpty ? "You have a task due" : String(todo.notes.prefix(100))
        content.sound = .default
        
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "todo-\(todo.id)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
EOF

cat > "$PROJECT_DIR/Services/AuthService.swift" << 'EOF'
import Foundation

// TODO: Implement with Firebase Auth SDK
// See HabitForge-Dev-Guide.md for Firebase setup instructions

class AuthService {
    static let shared = AuthService()
    
    var isAuthenticated: Bool { currentUserId != nil }
    var currentUserId: String?
    
    func signIn(email: String, password: String) async throws {
        // TODO: Firebase Auth signIn
    }
    
    func signUp(email: String, password: String) async throws {
        // TODO: Firebase Auth createUser
    }
    
    func signOut() throws {
        currentUserId = nil
    }
}
EOF

cat > "$PROJECT_DIR/Services/SubscriptionService.swift" << 'EOF'
import Foundation

// TODO: Implement with RevenueCat SDK
// See HabitForge-Dev-Guide.md for RevenueCat setup

class SubscriptionService {
    static let shared = SubscriptionService()
    
    var isProUser: Bool = false
    
    func checkSubscriptionStatus() async {
        // TODO: RevenueCat check entitlements
    }
    
    func purchase(package: String) async throws {
        // TODO: RevenueCat purchase
    }
    
    func restorePurchases() async throws {
        // TODO: RevenueCat restore
    }
}
EOF

# ============================================================
# Components
# ============================================================

cat > "$PROJECT_DIR/Components/ProgressRingView.swift" << 'EOF'
import SwiftUI

struct ProgressRingView: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var color: Color = .blue
    var size: CGFloat = 100
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ProgressRingView(progress: 0.7, color: .green)
}
EOF

cat > "$PROJECT_DIR/Components/EmptyStateView.swift" << 'EOF'
import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
EOF

# ============================================================
# Extensions
# ============================================================

cat > "$PROJECT_DIR/Extensions/Color+Hex.swift" << 'EOF'
import SwiftUI

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
EOF

cat > "$PROJECT_DIR/Extensions/Date+Helpers.swift" << 'EOF'
import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    var relativeDescription: String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
EOF

# ============================================================
# Done!
# ============================================================

echo ""
echo "✅ Project structure created successfully!"
echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "   1. Open Xcode → your HabitForge project"
echo ""
echo "   2. In the left sidebar (Project Navigator), right-click the"
echo "      yellow 'HabitForge' folder → 'Add Files to HabitForge...'"
echo ""
echo "   3. Select ALL the new folders:"
echo "      App, Models, ViewModels, Views, Services, Components, Extensions"
echo ""
echo "   4. Make sure these are checked:"
echo "      ✅ 'Copy items if needed'"
echo "      ✅ 'Create groups' (NOT 'Create folder references')"
echo "      ✅ 'Add to targets: HabitForge'"
echo ""
echo "   5. Click 'Add'"
echo ""
echo "   6. Update your HabitForgeApp.swift (the main app file) to"
echo "      register SwiftData models and show MainTabView"
echo ""
echo "   7. Press ⌘R in Xcode to build and run!"
echo ""
echo "🎉 Files created:"
find "$PROJECT_DIR" -name "*.swift" -newer "$0" | sort | while read f; do
    echo "   $f"
done
echo ""
echo "   Total: $(find "$PROJECT_DIR" -name "*.swift" -newer "$0" | wc -l | xargs) Swift files"

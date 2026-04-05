import SwiftUI
import SwiftData

struct AddHabitView: View {
    let viewModel: HabitViewModel
    var habitToEdit: Habit?

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "⭐"
    @State private var colorHex = "#FF6B6B"
    @State private var habitType = "Build"
    @State private var frequency = "Daily"
    @State private var timesPerPeriod = 3
    @State private var selectedDays: Set<Int> = Set(1 ... 7)
    @State private var tracksDuration = false
    @State private var targetMinutes = 15
    @State private var tracksCount = false
    @State private var targetCountValue = 8
    @State private var countUnit = "glasses"
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()

    private let colorOptions = ["#FF6B6B", "#FF9500", "#FFCC00", "#34C759", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55"]

    private let commonEmojis = [
        "⭐", "💧", "🏃", "📚", "🧘", "😴", "🥗", "💪", "🎯", "✍️", "🎸", "🧹",
        "🚶", "🧠", "❤️", "🌿", "☕️", "🍎", "📵", "🚭", "💊", "🦷", "📝", "🔔"
    ]

    private let weekdaySymbols: [(Int, String)] = [
        (1, "M"), (2, "T"), (3, "W"), (4, "T"), (5, "F"), (6, "S"), (7, "S")
    ]

    private var isEditing: Bool { habitToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("Name", text: $name)

                    emojiSection

                    Picker("Type", selection: $habitType) {
                        Text("Build (do it)").tag("Build")
                        Text("Break (avoid it)").tag("Break")
                    }
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

                Section("Frequency") {
                    Picker("Schedule", selection: $frequency) {
                        Text("Daily").tag("Daily")
                        Text("Times per week").tag("Times per Week")
                        Text("Times per month").tag("Times per Month")
                    }
                    .pickerStyle(.segmented)

                    if frequency != "Daily" {
                        Stepper(value: $timesPerPeriod, in: 1 ... (frequency == "Times per Week" ? 7 : 31)) {
                            Text(
                                frequency == "Times per Week"
                                    ? "\(timesPerPeriod) times per week"
                                    : "\(timesPerPeriod) times per month"
                            )
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Active days")
                            .font(.subheadline.weight(.semibold))
                        HStack(spacing: 8) {
                            ForEach(weekdaySymbols, id: \.0) { day, label in
                                dayToggle(day: day, label: label)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }

                Section("Duration goal") {
                    Toggle("Track duration", isOn: $tracksDuration.animation())
                    if tracksDuration {
                        Picker("Target minutes", selection: $targetMinutes) {
                            ForEach(Array(stride(from: 5, through: 120, by: 5)), id: \.self) { m in
                                Text("\(m) min").tag(m)
                            }
                        }
                    }
                }

                Section("Count goal") {
                    Toggle("Track count", isOn: $tracksCount.animation())
                    if tracksCount {
                        Stepper("Target: \(targetCountValue)", value: $targetCountValue, in: 1 ... 999)
                        TextField("Unit (e.g. glasses, pages)", text: $countUnit)
                    }
                }

                Section("Reminder") {
                    Toggle("Reminder", isOn: $reminderEnabled.animation())
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit habit" : "New habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private var emojiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                ForEach(commonEmojis, id: \.self) { e in
                    Text(e)
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(icon == e ? Color.accentColor.opacity(0.15) : Color.clear)
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                icon = e
                            }
                        }
                }
            }

            TextField("Type or paste an emoji", text: $icon)
                .font(.title2)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: icon) { _, newValue in
                    let clamped = Self.clampSingleEmoji(newValue)
                    if clamped != newValue {
                        icon = clamped
                    }
                }
        }
    }

    /// Keeps a single extended grapheme cluster (one “character” on screen), e.g. 👨‍👩‍👧 or 🇺🇸.
    private static func clampSingleEmoji(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "" }
        return String(first)
    }

    private func dayToggle(day: Int, label: String) -> some View {
        let on = selectedDays.contains(day)
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                if on {
                    selectedDays.remove(day)
                    if selectedDays.isEmpty { selectedDays = [day] }
                } else {
                    selectedDays.insert(day)
                }
            }
        } label: {
            Text(label)
                .font(.caption.weight(.bold))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(on ? Color.accentColor : Color.secondary.opacity(0.12))
                )
                .foregroundStyle(on ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func loadIfEditing() {
        guard let h = habitToEdit else { return }
        name = h.name
        icon = h.icon
        colorHex = h.colorHex
        habitType = h.habitType
        frequency = h.frequency
        if h.frequency == "Times per Week" || h.frequency == "Times per Month" {
            timesPerPeriod = h.targetCount
        }
        if h.scheduledDays.isEmpty {
            selectedDays = Set(1 ... 7)
        } else {
            selectedDays = Set(h.scheduledDays)
        }
        tracksDuration = h.tracksDuration
        if let sec = h.targetDurationSeconds {
            targetMinutes = max(5, sec / 60)
        }
        tracksCount = h.tracksCount
        if let tv = h.targetCountValue {
            targetCountValue = tv
        }
        countUnit = h.countUnit ?? "times"
        reminderEnabled = h.reminderEnabled
        if let t = h.reminderTime {
            reminderTime = t
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let days: [Int] = {
            if selectedDays.count == 7 { return [] }
            return selectedDays.sorted()
        }()
        let periodTarget = frequency == "Daily" ? 1 : timesPerPeriod
        let durSeconds = tracksDuration ? targetMinutes * 60 : nil
        let countTarget = tracksCount ? targetCountValue : nil
        let unit = tracksCount ? (countUnit.isEmpty ? "times" : countUnit) : nil
        let iconSaved: String = {
            let c = Self.clampSingleEmoji(icon)
            return c.isEmpty ? "⭐" : c
        }()

        if let h = habitToEdit {
            viewModel.updateHabit(
                h,
                name: trimmed,
                icon: iconSaved,
                colorHex: colorHex,
                habitType: habitType,
                frequency: frequency,
                targetCount: periodTarget,
                scheduledDays: days,
                tracksDuration: tracksDuration,
                targetDurationSeconds: durSeconds,
                tracksCount: tracksCount,
                targetCountValue: countTarget,
                countUnit: unit,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderEnabled ? reminderTime : nil
            )
        } else {
            viewModel.addHabit(
                name: trimmed,
                icon: iconSaved,
                colorHex: colorHex,
                habitType: habitType,
                frequency: frequency,
                targetCount: periodTarget,
                scheduledDays: days,
                tracksDuration: tracksDuration,
                targetDurationSeconds: durSeconds,
                tracksCount: tracksCount,
                targetCountValue: countTarget,
                countUnit: unit,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderEnabled ? reminderTime : nil
            )
        }
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
    let vm = HabitViewModel(modelContext: ModelContext(container))
    return AddHabitView(viewModel: vm, habitToEdit: nil)
}

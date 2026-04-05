import SwiftUI
import SwiftData
import Combine

@Observable
final class HabitViewModel {
    private var modelContext: ModelContext
    private var timerCancellable: AnyCancellable?

    var habits: [Habit] = []
    var selectedDate: Date = Date()

    /// When non-nil, present fullscreen timer for this habit.
    var showingTimerFor: Habit?

    var timerSeconds: Int = 0
    var timerRunning: Bool = false
    /// Seconds accumulated before current run (for pause/resume session total display).
    private var timerBaseSeconds: Int = 0
    private var timerHabit: Habit?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchHabits()
    }

    private var calendar: Calendar { Calendar.current }

    // MARK: - Fetch

    func fetchHabits() {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        habits = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Weekday (user: 1 = Mon … 7 = Sun)

    func habitWeekday(for date: Date) -> Int {
        let wd = calendar.component(.weekday, from: date)
        let appleToUser = [1: 7, 2: 1, 3: 2, 4: 3, 5: 4, 6: 5, 7: 6]
        return appleToUser[wd] ?? 1
    }

    // MARK: - Scheduling

    func isPausedOn(_ habit: Habit, date: Date) -> Bool {
        guard habit.isPaused else { return false }
        let day = calendar.startOfDay(for: date)
        if let until = habit.pausedUntil {
            return day < calendar.startOfDay(for: until)
        }
        return true
    }

    func isScheduled(_ habit: Habit, on date: Date) -> Bool {
        if habit.isArchived { return false }
        if isPausedOn(habit, date: date) { return false }
        if habit.scheduledDays.isEmpty { return true }
        return habit.scheduledDays.contains(habitWeekday(for: date))
    }

    func habitsForDate(_ date: Date = Date()) -> [Habit] {
        habits.filter { isScheduled($0, on: date) }
    }

    func entryForHabit(_ habit: Habit, on date: Date) -> HabitEntry? {
        let d = calendar.startOfDay(for: date)
        return habit.entries.first { calendar.isDate($0.date, inSameDayAs: d) }
    }

    // MARK: - Period helpers (week / month)

    private func weekInterval(containing date: Date) -> DateInterval? {
        calendar.dateInterval(of: .weekOfYear, for: date)
    }

    private func monthInterval(containing date: Date) -> DateInterval? {
        calendar.dateInterval(of: .month, for: date)
    }

    private func completionsInWeek(habit: Habit, containing date: Date) -> Int {
        guard let interval = weekInterval(containing: date) else { return 0 }
        let qualifying = habit.entries.filter { entry in
            entry.date >= interval.start && entry.date < interval.end && entrySatisfiesLog(habit: habit, entry: entry)
        }
        let uniqueDays = Set(qualifying.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    private func completionsInMonth(habit: Habit, containing date: Date) -> Int {
        guard let interval = monthInterval(containing: date) else { return 0 }
        let qualifying = habit.entries.filter { entry in
            entry.date >= interval.start && entry.date < interval.end && entrySatisfiesLog(habit: habit, entry: entry)
        }
        let uniqueDays = Set(qualifying.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    /// A logged entry counts toward weekly/monthly quotas if it represents meaningful progress.
    private func entrySatisfiesLog(habit: Habit, entry: HabitEntry) -> Bool {
        if habit.tracksDuration {
            return (entry.durationSeconds ?? 0) > 0
        }
        if habit.tracksCount {
            return (entry.countValue ?? 0) > 0
        }
        return entry.isCompleted
    }

    // MARK: - Progress

    func progressFraction(_ habit: Habit, on date: Date) -> Double {
        guard isScheduled(habit, on: date) else { return 0 }

        switch habit.frequency {
        case "Times per Week":
            let target = max(habit.targetCount, 1)
            let done = completionsInWeek(habit: habit, containing: date)
            return min(1, Double(done) / Double(target))
        case "Times per Month":
            let target = max(habit.targetCount, 1)
            let done = completionsInMonth(habit: habit, containing: date)
            return min(1, Double(done) / Double(target))
        default:
            break
        }

        let entry = entryForHabit(habit, on: date)

        if habit.tracksDuration {
            let target = max(habit.targetDurationSeconds ?? 60, 1)
            let done = entry?.durationSeconds ?? 0
            return min(1, Double(done) / Double(target))
        }
        if habit.tracksCount {
            let target = max(habit.targetCountValue ?? 1, 1)
            let done = entry?.countValue ?? 0
            return min(1, Double(done) / Double(target))
        }

        if let entry, entry.isCompleted { return 1 }
        return 0
    }

    func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        progressFraction(habit, on: date) >= 1 - 1e-9
    }

    func dailyCompletionProgress(on date: Date = Date()) -> (completed: Int, total: Int) {
        let list = habitsForDate(date)
        let done = list.filter { isHabitCompletedForDailySummary($0, on: date) }.count
        return (done, list.count)
    }

    /// Whether this habit counts as "done" for a given day in dashboard-style summaries (matches `dailyCompletionProgress`).
    func isHabitCompletedForDailySummary(_ habit: Habit, on date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        switch habit.frequency {
        case "Times per Week", "Times per Month":
            return habit.entries.contains {
                calendar.isDate($0.date, inSameDayAs: day) && $0.isCompleted
            }
        default:
            return isCompleted(habit, on: date)
        }
    }

    /// For each day in the last `days` (ending today), percentage of scheduled habits completed that day (0–100).
    func overallDailyCompletion(days: Int, habits: [Habit]) -> [(date: Date, percentage: Double)] {
        let end = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) else { return [] }
        var d = start
        var out: [(date: Date, percentage: Double)] = []
        while d <= end {
            let scheduled = habits.filter { isScheduled($0, on: d) }
            let done = scheduled.filter { isHabitCompletedForDailySummary($0, on: d) }.count
            let pct: Double
            if scheduled.isEmpty {
                pct = 0
            } else {
                pct = Double(done) / Double(scheduled.count) * 100
            }
            out.append((date: d, percentage: pct))
            guard let next = calendar.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        return out
    }

    // MARK: - Toggle / count

    func toggleHabit(_ habit: Habit, on date: Date = Date()) {
        guard isScheduled(habit, on: date) else { return }
        if habit.tracksCount || habit.tracksDuration || habit.frequency != "Daily" { return }

        let day = calendar.startOfDay(for: date)
        if let existing = entryForHabit(habit, on: day) {
            existing.isCompleted.toggle()
            existing.timestamp = Date()
        } else {
            let entry = HabitEntry(date: day, isCompleted: true)
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
        finalizeHabitUpdate(habit)
    }

    func incrementCount(_ habit: Habit, on date: Date = Date()) {
        guard habit.tracksCount, isScheduled(habit, on: date) else { return }
        let day = calendar.startOfDay(for: date)
        let target = max(habit.targetCountValue ?? 1, 1)
        if let existing = entryForHabit(habit, on: day) {
            existing.countValue = min(target, (existing.countValue ?? 0) + 1)
            existing.isCompleted = (existing.countValue ?? 0) >= target
            existing.timestamp = Date()
        } else {
            let entry = HabitEntry(date: day, isCompleted: false)
            entry.countValue = 1
            entry.isCompleted = 1 >= target
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
        finalizeHabitUpdate(habit)
    }

    func decrementCount(_ habit: Habit, on date: Date = Date()) {
        guard habit.tracksCount, isScheduled(habit, on: date) else { return }
        let day = calendar.startOfDay(for: date)
        guard let existing = entryForHabit(habit, on: day) else { return }
        let target = max(habit.targetCountValue ?? 1, 1)
        let next = max(0, (existing.countValue ?? 0) - 1)
        existing.countValue = next
        existing.isCompleted = next >= target
        existing.timestamp = Date()
        finalizeHabitUpdate(habit)
    }

    /// One completion per calendar day toward weekly/monthly quota; tap again the same day uncompletes (like daily toggle).
    func logPeriodicCompletion(_ habit: Habit, on date: Date = Date()) {
        guard isScheduled(habit, on: date) else { return }
        guard habit.frequency == "Times per Week" || habit.frequency == "Times per Month" else { return }

        let day = calendar.startOfDay(for: date)
        let todayEntries = habit.entries.filter { calendar.isDate($0.date, inSameDayAs: day) }
        let hasCompletedToday = todayEntries.contains { $0.isCompleted }

        if hasCompletedToday {
            for entry in todayEntries where entry.isCompleted {
                entry.isCompleted = false
                entry.timestamp = Date()
            }
        } else if let existing = todayEntries.first {
            existing.isCompleted = true
            existing.timestamp = Date()
        } else {
            let entry = HabitEntry(date: day, isCompleted: true)
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
        finalizeHabitUpdate(habit)
    }

    // MARK: - Timer

    func openTimer(for habit: Habit) {
        guard habit.tracksDuration else { return }
        timerHabit = habit
        timerBaseSeconds = entryForHabit(habit, on: Date())?.durationSeconds ?? 0
        timerSeconds = timerBaseSeconds
        timerRunning = false
        showingTimerFor = habit
    }

    func startTimer() {
        guard timerHabit != nil else { return }
        timerRunning = true
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.timerRunning else { return }
                self.timerSeconds += 1
            }
    }

    func pauseTimer() {
        timerRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func stopTimer(saveProgress: Bool) {
        pauseTimer()
        defer {
            showingTimerFor = nil
            timerHabit = nil
            timerBaseSeconds = 0
            timerSeconds = 0
        }
        guard saveProgress, let habit = timerHabit else { return }
        applyDurationSeconds(timerSeconds, habit: habit, on: Date())
    }

    /// Apply total elapsed seconds for today (replaces session merge).
    func applyDurationSeconds(_ totalSeconds: Int, habit: Habit, on date: Date) {
        guard habit.tracksDuration, isScheduled(habit, on: date) else { return }
        let day = calendar.startOfDay(for: date)
        let target = max(habit.targetDurationSeconds ?? 60, 1)
        if let existing = entryForHabit(habit, on: day) {
            existing.durationSeconds = totalSeconds
            existing.isCompleted = totalSeconds >= target
            existing.timestamp = Date()
        } else {
            let entry = HabitEntry(date: day, isCompleted: totalSeconds >= target)
            entry.durationSeconds = totalSeconds
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
        finalizeHabitUpdate(habit)
    }

    // MARK: - Notes & mood

    func updateNote(_ habit: Habit, on date: Date, note: String?) {
        let day = calendar.startOfDay(for: date)
        if let existing = entryForHabit(habit, on: day) {
            existing.note = note
        } else {
            let entry = HabitEntry(date: day, isCompleted: false)
            entry.note = note
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
        try? modelContext.save()
        fetchHabits()
    }

    func setMood(_ habit: Habit, on date: Date, mood: String?) {
        let day = calendar.startOfDay(for: date)
        if let existing = entryForHabit(habit, on: day) {
            existing.mood = mood
        } else {
            let entry = HabitEntry(date: day, isCompleted: false)
            entry.mood = mood
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
        try? modelContext.save()
        fetchHabits()
    }

    // MARK: - Streaks & stats

    func recalculateStreak(for habit: Habit) {
        switch habit.frequency {
        case "Times per Week":
            habit.currentStreak = consecutiveWeeksMeetingQuota(habit: habit)
        case "Times per Month":
            habit.currentStreak = consecutiveMonthsMeetingQuota(habit: habit)
        default:
            habit.currentStreak = consecutiveCompletedScheduledDaysStreak(habit: habit)
        }

        habit.bestStreak = max(habit.bestStreak, computeBestHistoricalStreak(for: habit))
        habit.totalCompletions = habit.entries.filter(\.isCompleted).count
        try? modelContext.save()
    }

    private func consecutiveCompletedScheduledDaysStreak(habit: Habit) -> Int {
        var streak = 0
        var d = calendar.startOfDay(for: Date())
        for _ in 0..<4000 {
            if isScheduled(habit, on: d) {
                if isCompleted(habit, on: d) {
                    streak += 1
                } else {
                    break
                }
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
        }
        return streak
    }

    private func consecutiveWeeksMeetingQuota(habit: Habit) -> Int {
        let target = max(habit.targetCount, 1)
        var streak = 0
        var ref = Date()
        for _ in 0..<520 {
            guard let interval = weekInterval(containing: ref) else { break }
            let done = completionsInWeek(habit: habit, containing: ref)
            if done >= target {
                streak += 1
                guard let prevWeek = calendar.date(byAdding: .day, value: -1, to: interval.start) else { break }
                ref = prevWeek
            } else {
                break
            }
        }
        return streak
    }

    private func consecutiveMonthsMeetingQuota(habit: Habit) -> Int {
        let target = max(habit.targetCount, 1)
        var streak = 0
        var ref = Date()
        for _ in 0..<120 {
            guard let interval = monthInterval(containing: ref) else { break }
            let done = completionsInMonth(habit: habit, containing: ref)
            if done >= target {
                streak += 1
                guard let prevMonth = calendar.date(byAdding: .day, value: -1, to: interval.start) else { break }
                ref = prevMonth
            } else {
                break
            }
        }
        return streak
    }

    /// Best day-streak for daily habits; for week/month, best consecutive periods.
    private func computeBestHistoricalStreak(for habit: Habit) -> Int {
        switch habit.frequency {
        case "Times per Week":
            return bestWeekStreak(habit: habit)
        case "Times per Month":
            return bestMonthStreak(habit: habit)
        default:
            return bestDayStreak(habit: habit)
        }
    }

    private func bestDayStreak(habit: Habit) -> Int {
        guard let start = calendar.date(byAdding: .year, value: -5, to: Date()) else { return 0 }
        var d = calendar.startOfDay(for: start)
        let end = calendar.startOfDay(for: Date())
        var run = 0
        var best = 0
        while d <= end {
            if isScheduled(habit, on: d) {
                if isCompleted(habit, on: d) {
                    run += 1
                    best = max(best, run)
                } else {
                    run = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        return best
    }

    private func bestWeekStreak(habit: Habit) -> Int {
        let target = max(habit.targetCount, 1)
        guard let start = calendar.date(byAdding: .year, value: -5, to: Date()) else { return 0 }
        var ref = start
        var run = 0
        var best = 0
        while ref < Date() {
            let done = completionsInWeek(habit: habit, containing: ref)
            if done >= target {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: ref) else { break }
            ref = next
        }
        return max(best, consecutiveWeeksMeetingQuota(habit: habit))
    }

    private func bestMonthStreak(habit: Habit) -> Int {
        let target = max(habit.targetCount, 1)
        guard let start = calendar.date(byAdding: .year, value: -5, to: Date()) else { return 0 }
        var ref = start
        var run = 0
        var best = 0
        while ref < Date() {
            let done = completionsInMonth(habit: habit, containing: ref)
            if done >= target {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
            guard let next = calendar.date(byAdding: .month, value: 1, to: ref) else { break }
            ref = next
        }
        return max(best, consecutiveMonthsMeetingQuota(habit: habit))
    }

    func completionRate(for habit: Habit, lastDays: Int) -> Double {
        let end = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(lastDays - 1), to: end) else { return 0 }
        var d = start
        var scheduled = 0
        var done = 0
        while d <= end {
            if isScheduled(habit, on: d) {
                scheduled += 1
                if isCompleted(habit, on: d) { done += 1 }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        guard scheduled > 0 else { return 0 }
        return Double(done) / Double(scheduled)
    }

    struct ChartDayPoint: Identifiable {
        var id: Date { date }
        let date: Date
        let completion: Double
        let durationMinutes: Double?
        let count: Double?
    }

    func chartData(for habit: Habit, lastDays: Int = 30) -> [ChartDayPoint] {
        let end = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(lastDays - 1), to: end) else { return [] }
        var d = start
        var out: [ChartDayPoint] = []
        while d <= end {
            let frac = progressFraction(habit, on: d)
            let entry = entryForHabit(habit, on: d)
            let mins = entry.flatMap { e in e.durationSeconds.map { Double($0) / 60 } }
            let cnt = entry.flatMap { e in e.countValue.map(Double.init) }
            out.append(ChartDayPoint(date: d, completion: frac, durationMinutes: mins, count: cnt))
            guard let next = calendar.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        return out
    }

    enum HeatmapCellState: Equatable {
        case notScheduled
        case missed
        case partial(Double)
        case done
        case upcoming
    }

    func heatmapData(for habit: Habit, in month: Date) -> [Date: HeatmapCellState] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [:] }
        let today = calendar.startOfDay(for: Date())
        var map: [Date: HeatmapCellState] = [:]
        var d = interval.start
        while d < interval.end {
            let day = calendar.startOfDay(for: d)
            if !isScheduled(habit, on: day) {
                map[day] = .notScheduled
            } else if isCompleted(habit, on: day) {
                map[day] = .done
            } else if progressFraction(habit, on: day) > 0 {
                map[day] = .partial(progressFraction(habit, on: day))
            } else if day < today {
                map[day] = .missed
            } else {
                map[day] = .upcoming
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        return map
    }

    // MARK: - Reorder / archive / pause

    func moveHabits(fromOffsets source: IndexSet, toOffset destination: Int) {
        var ordered = habits.sorted { $0.sortOrder < $1.sortOrder }
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, h) in ordered.enumerated() {
            h.sortOrder = i
        }
        try? modelContext.save()
        fetchHabits()
    }

    func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        try? modelContext.save()
        fetchHabits()
    }

    func pauseHabit(_ habit: Habit, until: Date? = nil) {
        habit.isPaused = true
        habit.pausedUntil = until
        try? modelContext.save()
        fetchHabits()
    }

    func resumeHabit(_ habit: Habit) {
        habit.isPaused = false
        habit.pausedUntil = nil
        try? modelContext.save()
        fetchHabits()
    }

    // MARK: - Add / update habit

    func addHabit(
        name: String,
        icon: String,
        colorHex: String,
        habitType: String = "Build",
        frequency: String = "Daily",
        targetCount: Int = 1,
        scheduledDays: [Int] = [],
        tracksDuration: Bool = false,
        targetDurationSeconds: Int? = nil,
        tracksCount: Bool = false,
        targetCountValue: Int? = nil,
        countUnit: String? = nil,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil
    ) {
        let habit = Habit(name: name, icon: icon, colorHex: colorHex, habitType: habitType, frequency: frequency)
        habit.sortOrder = habits.count
        habit.targetCount = max(1, targetCount)
        habit.scheduledDays = scheduledDays
        habit.tracksDuration = tracksDuration
        habit.targetDurationSeconds = targetDurationSeconds
        habit.tracksCount = tracksCount
        habit.targetCountValue = targetCountValue
        habit.countUnit = countUnit
        habit.reminderEnabled = reminderEnabled
        habit.reminderTime = reminderTime
        modelContext.insert(habit)
        try? modelContext.save()
        fetchHabits()
    }

    func updateHabit(
        _ habit: Habit,
        name: String,
        icon: String,
        colorHex: String,
        habitType: String,
        frequency: String,
        targetCount: Int,
        scheduledDays: [Int],
        tracksDuration: Bool,
        targetDurationSeconds: Int?,
        tracksCount: Bool,
        targetCountValue: Int?,
        countUnit: String?,
        reminderEnabled: Bool,
        reminderTime: Date?
    ) {
        habit.name = name
        habit.icon = icon
        habit.colorHex = colorHex
        habit.habitType = habitType
        habit.frequency = frequency
        habit.targetCount = max(1, targetCount)
        habit.scheduledDays = scheduledDays
        habit.tracksDuration = tracksDuration
        habit.targetDurationSeconds = targetDurationSeconds
        habit.tracksCount = tracksCount
        habit.targetCountValue = targetCountValue
        habit.countUnit = countUnit
        habit.reminderEnabled = reminderEnabled
        habit.reminderTime = reminderTime
        try? modelContext.save()
        fetchHabits()
    }

    // MARK: - Private

    private func finalizeHabitUpdate(_ habit: Habit) {
        recalculateStreak(for: habit)
        habit.totalCompletions = habit.entries.filter(\.isCompleted).count
        try? modelContext.save()
        fetchHabits()
    }
}

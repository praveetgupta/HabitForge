import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    /// Schedules local repeating reminders. IDs: `habit-reminder-\(habit.id)` daily, or `habit-reminder-\(habit.id)-d\(userWeekday)` per selected day.
    func scheduleHabitReminder(habit: Habit) {
        cancelHabitReminder(habitId: habit.id)
        scheduleHabitReminderWithoutCancel(habit: habit)
    }

    private func scheduleHabitReminderWithoutCancel(habit: Habit) {
        guard habit.reminderEnabled,
              let reminderTime = habit.reminderTime,
              !habit.isArchived,
              !habit.isPaused else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(habit.icon) \(habit.name)"
        content.body = habit.habitType == "Break"
            ? "Stay strong! Keep avoiding it."
            : "Time to keep your streak going!"
        content.sound = .default

        let cal = Calendar.current
        let parts = cal.dateComponents([.hour, .minute], from: reminderTime)
        let hour = parts.hour ?? 9
        let minute = parts.minute ?? 0
        let uuid = habit.id.uuidString

        if habit.scheduledDays.isEmpty {
            var dc = DateComponents()
            dc.hour = hour
            dc.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let id = "habit-reminder-\(uuid)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        } else {
            for userDay in habit.scheduledDays.sorted() {
                guard let appleWeekday = Self.appleWeekday(fromUserWeekday: userDay) else { continue }
                var dc = DateComponents()
                dc.weekday = appleWeekday
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let id = "habit-reminder-\(uuid)-d\(userDay)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    /// User model: 1 = Monday … 7 = Sunday. Apple `Calendar` weekday: 1 = Sunday … 7 = Saturday.
    private static func appleWeekday(fromUserWeekday user: Int) -> Int? {
        guard (1 ... 7).contains(user) else { return nil }
        let map = [1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 7, 7: 1]
        return map[user]
    }

    /// Removes pending notifications for this habit (current ID scheme and legacy `habit-\(id)`).
    func cancelHabitReminder(habitId: UUID) {
        let u = habitId.uuidString
        var ids: [String] = ["habit-\(u)", "habit-reminder-\(u)"]
        for d in 1 ... 7 {
            ids.append("habit-reminder-\(u)-d\(d)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Clears all habit reminder notifications, then schedules for every eligible habit.
    func rescheduleAllHabitReminders(habits: [Habit]) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let reminderIds = requests.map(\.identifier).filter { $0.hasPrefix("habit-reminder-") }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIds)

            let legacyIds = habits.map { "habit-\($0.id.uuidString)" }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: legacyIds)

            DispatchQueue.main.async {
                for habit in habits where habit.reminderEnabled && habit.reminderTime != nil && !habit.isArchived && !habit.isPaused {
                    self.scheduleHabitReminderWithoutCancel(habit: habit)
                }
            }
        }
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

extension NotificationService {
    /// Current notification permission, for display in Settings.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
}

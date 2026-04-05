import SwiftUI
import SwiftData
import UserNotifications

@Observable
final class TodoViewModel {
    private var modelContext: ModelContext

    var inboxTodos: [Todo] = []
    var todayTodos: [Todo] = []
    var upcomingTodos: [Todo] = []
    var anytimeTodos: [Todo] = []
    var somedayTodos: [Todo] = []
    var logbookTodos: [Todo] = []

    var areas: [Area] = []
    var projects: [Project] = []
    var tags: [Tag] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchAll()
    }

    // MARK: - Fetch

    func fetchAll() {
        fetchTodos()
        fetchAreas()
        fetchProjects()
        fetchTags()
    }

    private func fetchTodos() {
        let descriptor = FetchDescriptor<Todo>(
            predicate: #Predicate { $0.status != "Trash" },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        inboxTodos    = all.filter { $0.status == "Inbox" }
        todayTodos    = all.filter { $0.status == "Today" }
        upcomingTodos = all.filter { $0.status == "Upcoming" }
        anytimeTodos  = all.filter { $0.status == "Anytime" }
        somedayTodos  = all.filter { $0.status == "Someday" }
        logbookTodos  = all.filter { $0.status == "Logbook" }
    }

    private func fetchAreas() {
        let d = FetchDescriptor<Area>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        areas = (try? modelContext.fetch(d)) ?? []
    }

    private func fetchProjects() {
        let d = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.sortOrder)])
        projects = (try? modelContext.fetch(d)) ?? []
    }

    private func fetchTags() {
        let d = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.sortOrder)])
        tags = (try? modelContext.fetch(d)) ?? []
    }

    // MARK: - Auto-promote

    func autoPromoteUpcoming() {
        let today = Calendar.current.startOfDay(for: Date())
        let due = upcomingTodos.filter {
            guard let when = $0.whenDate else { return false }
            return Calendar.current.startOfDay(for: when) <= today
        }
        guard !due.isEmpty else { return }
        due.forEach { $0.status = "Today" }
        save()
        fetchTodos()
    }

    // MARK: - Quick Add

    @discardableResult
    func quickAdd(title: String) -> Todo {
        let todo = Todo(title: title, status: "Inbox")
        todo.sortOrder = inboxTodos.count
        modelContext.insert(todo)
        save()
        fetchTodos()
        return todo
    }

    @discardableResult
    func quickAddToToday(title: String, isEvening: Bool = false) -> Todo {
        let todo = Todo(title: title, status: "Today")
        todo.isEvening = isEvening
        todo.whenDate = Calendar.current.startOfDay(for: Date())
        todo.sortOrder = todayTodos.count
        modelContext.insert(todo)
        save()
        fetchTodos()
        return todo
    }

    // MARK: - Full Add

    @discardableResult
    func addTodo(
        title: String,
        notes: String = "",
        whenDate: Date? = nil,
        deadline: Date? = nil,
        isEvening: Bool = false,
        reminderDate: Date? = nil,
        priority: Int = 0,
        tags: [String] = [],
        project: Project? = nil,
        area: Area? = nil,
        status: String = "Inbox",
        isRepeating: Bool = false,
        repeatType: String? = nil,
        repeatInterval: Int = 1,
        repeatAfterCompletion: Bool = false
    ) -> Todo {
        let todo = Todo(title: title, status: status)
        todo.notes = notes
        todo.whenDate = whenDate
        todo.deadline = deadline
        todo.isEvening = isEvening
        todo.reminderDate = reminderDate
        todo.priority = priority
        todo.tags = tags
        todo.project = project
        todo.area = area
        todo.isRepeating = isRepeating
        todo.repeatType = repeatType
        todo.repeatInterval = repeatInterval
        todo.repeatAfterCompletion = repeatAfterCompletion
        modelContext.insert(todo)
        save()
        if reminderDate != nil { NotificationService.shared.scheduleTodoReminder(todo: todo) }
        fetchAll()
        return todo
    }

    func saveTodo(_ todo: Todo) {
        cancelTodoReminder(todo)
        if let r = todo.reminderDate, r > Date() {
            NotificationService.shared.scheduleTodoReminder(todo: todo)
        }
        save()
        fetchAll()
    }

    func deleteTodo(_ todo: Todo) {
        cancelTodoReminder(todo)
        modelContext.delete(todo)
        save()
        fetchTodos()
    }

    // MARK: - Completion

    func completeTodo(_ todo: Todo) {
        cancelTodoReminder(todo)
        if todo.isRepeating { createNextOccurrence(from: todo) }
        todo.status = "Logbook"
        todo.completedAt = Date()
        save()
        fetchTodos()
    }

    func uncompleteTodo(_ todo: Todo) {
        todo.status = "Today"
        todo.completedAt = nil
        save()
        fetchTodos()
    }

    private func createNextOccurrence(from todo: Todo) {
        guard todo.isRepeating, let rType = todo.repeatType else { return }
        let interval = todo.repeatInterval ?? 1
        let base = todo.repeatAfterCompletion ? Date() : (todo.whenDate ?? Date())
        let cal = Calendar.current
        let nextDate: Date?
        switch rType {
        case "Daily":   nextDate = cal.date(byAdding: .day,       value: interval, to: base)
        case "Weekly":  nextDate = cal.date(byAdding: .weekOfYear, value: interval, to: base)
        case "Monthly": nextDate = cal.date(byAdding: .month,     value: interval, to: base)
        case "Yearly":  nextDate = cal.date(byAdding: .year,      value: interval, to: base)
        default:        nextDate = nil
        }
        guard let next = nextDate else { return }
        let today = cal.startOfDay(for: Date())
        let n = Todo(title: todo.title,
                     status: cal.startOfDay(for: next) <= today ? "Today" : "Upcoming")
        n.notes = todo.notes
        n.whenDate = next
        n.deadline = todo.deadline
        n.isEvening = todo.isEvening
        n.priority = todo.priority
        n.tags = todo.tags
        n.project = todo.project
        n.area = todo.area
        n.isRepeating = true
        n.repeatType = rType
        n.repeatInterval = interval
        n.repeatAfterCompletion = todo.repeatAfterCompletion
        modelContext.insert(n)
    }

    // MARK: - Status Moves

    func moveToInbox(_ todo: Todo) {
        todo.status = "Inbox"; todo.whenDate = nil
        save(); fetchTodos()
    }

    func moveToToday(_ todo: Todo) {
        todo.status = "Today"
        todo.whenDate = Calendar.current.startOfDay(for: Date())
        save(); fetchTodos()
    }

    func moveToAnytime(_ todo: Todo) {
        todo.status = "Anytime"; todo.whenDate = nil
        save(); fetchTodos()
    }

    func moveToSomeday(_ todo: Todo) {
        todo.status = "Someday"; todo.whenDate = nil
        save(); fetchTodos()
    }

    func scheduleFor(_ todo: Todo, date: Date) {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        let today = cal.startOfDay(for: Date())
        todo.whenDate = day
        todo.status = day <= today ? "Today" : "Upcoming"
        save(); fetchTodos()
    }

    func assignToProject(_ todo: Todo, project: Project?) {
        todo.project = project; save(); fetchAll()
    }

    func assignToArea(_ todo: Todo, area: Area?) {
        todo.area = area; save(); fetchAll()
    }

    // MARK: - Checklist

    func addChecklistItem(_ todo: Todo, title: String) {
        let item = ChecklistItem(title: title, sortOrder: todo.checklist.count)
        item.todo = todo
        todo.checklist.append(item)
        modelContext.insert(item)
        save()
    }

    func toggleChecklistItem(_ item: ChecklistItem) {
        item.isCompleted.toggle(); save()
    }

    func removeChecklistItem(_ item: ChecklistItem, from todo: Todo) {
        todo.checklist.removeAll { $0.id == item.id }
        modelContext.delete(item)
        save()
    }

    func reorderChecklist(_ todo: Todo, fromOffsets: IndexSet, toOffset: Int) {
        var items = todo.checklist.sorted { $0.sortOrder < $1.sortOrder }
        items.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (i, item) in items.enumerated() { item.sortOrder = i }
        save()
    }

    // MARK: - Project CRUD

    @discardableResult
    func createProject(name: String, icon: String = "📋", colorHex: String = "#007AFF", area: Area? = nil) -> Project {
        let p = Project(name: name, icon: icon, colorHex: colorHex)
        p.area = area
        p.sortOrder = projects.count
        modelContext.insert(p)
        save(); fetchProjects()
        return p
    }

    func completeProject(_ project: Project) {
        project.status = "Completed"
        project.completedAt = Date()
        save(); fetchProjects()
    }

    func addHeading(_ project: Project, name: String) {
        let h = ProjectHeading(name: name, sortOrder: project.headings.count)
        h.project = project
        project.headings.append(h)
        modelContext.insert(h)
        save()
    }

    // MARK: - Area CRUD

    @discardableResult
    func createArea(name: String, icon: String = "📁") -> Area {
        let a = Area(name: name, icon: icon)
        a.sortOrder = areas.count
        modelContext.insert(a)
        save(); fetchAreas()
        return a
    }

    // MARK: - Tag CRUD

    @discardableResult
    func createTag(name: String, colorHex: String? = nil) -> Tag {
        let t = Tag(name: name, colorHex: colorHex)
        t.sortOrder = tags.count
        modelContext.insert(t)
        save(); fetchTags()
        return t
    }

    func todosWithTag(_ name: String) -> [Todo] {
        (inboxTodos + todayTodos + upcomingTodos + anytimeTodos + somedayTodos)
            .filter { $0.tags.contains(name) }
    }

    // MARK: - Search

    func search(query: String) -> [Todo] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return (inboxTodos + todayTodos + upcomingTodos + anytimeTodos + somedayTodos + logbookTodos)
            .filter {
                $0.title.lowercased().contains(q) ||
                $0.notes.lowercased().contains(q) ||
                $0.tags.contains(where: { $0.lowercased().contains(q) })
            }
    }

    // MARK: - Grouped Views

    func logbookEntries() -> [(date: Date, todos: [Todo])] {
        let cal = Calendar.current
        let sorted = logbookTodos.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        let grouped = Dictionary(grouping: sorted) { todo in
            cal.startOfDay(for: todo.completedAt ?? todo.createdAt)
        }
        return grouped.keys.sorted(by: >).map { date in
            (date: date, todos: grouped[date]!)
        }
    }

    func upcomingGroupedByDay() -> [(date: Date, todos: [Todo])] {
        let cal = Calendar.current
        let pairs = upcomingTodos.compactMap { t -> (Date, Todo)? in
            guard let w = t.whenDate else { return nil }
            return (cal.startOfDay(for: w), t)
        }
        let grouped = Dictionary(grouping: pairs, by: \.0)
        return grouped.keys.sorted().map { date in
            (date: date, todos: grouped[date]!.map(\.1).sorted { $0.sortOrder < $1.sortOrder })
        }
    }

    // MARK: - Reorder

    func reorderTodayTodos(fromOffsets: IndexSet, toOffset: Int) {
        todayTodos.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (i, t) in todayTodos.enumerated() { t.sortOrder = i }
        save()
    }

    func reorderInboxTodos(fromOffsets: IndexSet, toOffset: Int) {
        inboxTodos.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (i, t) in inboxTodos.enumerated() { t.sortOrder = i }
        save()
    }

    func reorderAnytimeTodos(fromOffsets: IndexSet, toOffset: Int) {
        anytimeTodos.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (i, t) in anytimeTodos.enumerated() { t.sortOrder = i }
        save()
    }

    func reorderSomedayTodos(fromOffsets: IndexSet, toOffset: Int) {
        somedayTodos.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (i, t) in somedayTodos.enumerated() { t.sortOrder = i }
        save()
    }

    // MARK: - Stats

    func completedToday() -> Int {
        logbookTodos.filter { Calendar.current.isDateInToday($0.completedAt ?? .distantPast) }.count
    }

    func activeProjects() -> [Project] {
        projects.filter { $0.status == "Active" }
    }

    // MARK: - Notifications

    private func cancelTodoReminder(_ todo: Todo) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["todo-\(todo.id)"])
    }

    // MARK: - Private

    private func save() {
        try? modelContext.save()
    }
}

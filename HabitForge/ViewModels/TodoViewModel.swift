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
    
    @discardableResult
    func quickAdd(title: String) -> Todo {
        let todo = Todo(title: title, status: "Inbox")
        modelContext.insert(todo)
        try? modelContext.save()
        fetchTodos()
        return todo
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

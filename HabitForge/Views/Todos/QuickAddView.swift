import SwiftUI

enum QuickAddDestination: Equatable {
    case inbox
    case today
    case evening
    case tomorrow
    case nextWeek
}

struct QuickAddView: View {
    let viewModel: TodoViewModel
    var defaultDestination: QuickAddDestination = .inbox
    var defaultArea: Area? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var destination: QuickAddDestination
    @State private var selectedProject: Project? = nil
    @State private var showProjectPicker = false
    @State private var addedCount = 0
    @FocusState private var isFocused: Bool

    init(viewModel: TodoViewModel,
         defaultDestination: QuickAddDestination = .inbox,
         defaultArea: Area? = nil) {
        self.viewModel = viewModel
        self.defaultDestination = defaultDestination
        self.defaultArea = defaultArea
        _destination = State(initialValue: defaultDestination)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title input
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    TextField("What do you want to do?", text: $title, axis: .vertical)
                        .font(.body)
                        .focused($isFocused)
                        .onSubmit(saveAndContinue)
                        .submitLabel(.done)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()

                // Bottom bar
                HStack(spacing: 0) {
                    // Schedule chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            DestinationChip(label: "Inbox",    icon: "tray",       dest: .inbox,     current: $destination)
                            DestinationChip(label: "Today",    icon: "star.fill",   dest: .today,     current: $destination)
                            DestinationChip(label: "Evening",  icon: "moon.fill",   dest: .evening,   current: $destination)
                            DestinationChip(label: "Tomorrow", icon: "sunrise.fill",dest: .tomorrow,  current: $destination)
                            DestinationChip(label: "Next Week",icon: "forward.fill",dest: .nextWeek,  current: $destination)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    Divider().frame(height: 32)

                    // Project quick-pick
                    Button {
                        showProjectPicker = true
                    } label: {
                        Image(systemName: selectedProject == nil ? "doc.text" : "doc.text.fill")
                            .font(.body)
                            .foregroundStyle(selectedProject == nil ? Color.secondary : Color.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                }
                .background(.ultraThinMaterial)

                if addedCount > 0 {
                    Text("\(addedCount) added")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                        .transition(.opacity)
                }

                // Pin content to the top of the sheet — without this the fixed-height
                // rows float mid-sheet at the medium detent.
                Spacer(minLength: 0)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showProjectPicker) {
                ProjectPickerSheet(selectedProject: $selectedProject, projects: viewModel.projects)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isFocused = true
            }
        }
    }

    private func saveAndContinue() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        createTodo(title: t)
        withAnimation { addedCount += 1 }
        title = ""
        isFocused = true
    }

    private func saveAndDismiss() {
        let t = title.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty { createTodo(title: t) }
        dismiss()
    }

    private func createTodo(title: String) {
        let cal = Calendar.current
        switch destination {
        case .inbox:
            let todo = viewModel.quickAdd(title: title)
            applyDefaults(to: todo)
        case .today:
            let todo = viewModel.quickAddToToday(title: title)
            applyDefaults(to: todo)
        case .evening:
            let todo = viewModel.quickAddToToday(title: title, isEvening: true)
            applyDefaults(to: todo)
        case .tomorrow:
            let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
            viewModel.addTodo(title: title, whenDate: tomorrow, project: selectedProject,
                              area: defaultArea, status: "Upcoming")
        case .nextWeek:
            let nextWeek = cal.date(byAdding: .weekOfYear, value: 1, to: cal.startOfDay(for: Date()))!
            viewModel.addTodo(title: title, whenDate: nextWeek, project: selectedProject,
                              area: defaultArea, status: "Upcoming")
        }
    }

    private func applyDefaults(to todo: Todo) {
        var changed = false
        if selectedProject != nil { todo.project = selectedProject; changed = true }
        if defaultArea != nil { todo.area = defaultArea; changed = true }
        if changed { viewModel.saveTodo(todo) }
    }
}

private struct DestinationChip: View {
    let label: String
    let icon: String
    let dest: QuickAddDestination
    @Binding var current: QuickAddDestination

    var isSelected: Bool { current == dest }

    var body: some View {
        Button {
            current = dest
        } label: {
            Label(label, systemImage: icon)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    isSelected
                        ? Color.blue.opacity(0.15)
                        : Color.secondary.opacity(0.1),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.blue : Color.secondary)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

struct ProjectPickerSheet: View {
    @Binding var selectedProject: Project?
    let projects: [Project]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedProject = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("No Project")
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedProject == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                ForEach(projects.filter { $0.status == "Active" }, id: \.id) { project in
                    Button {
                        selectedProject = project
                        dismiss()
                    } label: {
                        HStack {
                            Text(project.icon)
                            Text(project.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedProject?.id == project.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct TagPickerSheet: View {
    @Binding var selectedTags: [String]
    let allTags: [Tag]
    let viewModel: TodoViewModel
    @State private var newTagName = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(allTags, id: \.id) { tag in
                        let selected = selectedTags.contains(tag.name)
                        Button {
                            if selected {
                                selectedTags.removeAll { $0 == tag.name }
                            } else {
                                selectedTags.append(tag.name)
                            }
                        } label: {
                            HStack {
                                if let hex = tag.colorHex, let color = Color(hex: hex) {
                                    Circle().fill(color).frame(width: 10, height: 10)
                                } else {
                                    Circle().fill(Color.secondary).frame(width: 10, height: 10)
                                }
                                Text(tag.name).foregroundStyle(.primary)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark").foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("New Tag") {
                    HStack {
                        TextField("Tag name", text: $newTagName)
                        Button("Add") {
                            let name = newTagName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            viewModel.createTag(name: name)
                            selectedTags.append(name)
                            newTagName = ""
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ScheduleTodoSheet: View {
    let todo: Todo
    let viewModel: TodoViewModel
    @State private var customDate = Date()
    @State private var showCustomPicker = false
    @Environment(\.dismiss) private var dismiss

    private var cal: Calendar { Calendar.current }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    viewModel.moveToToday(todo)
                    dismiss()
                } label: {
                    Label("Today", systemImage: "star.fill").foregroundStyle(.orange)
                }

                Button {
                    let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
                    viewModel.scheduleFor(todo, date: tomorrow)
                    dismiss()
                } label: {
                    Label("Tomorrow", systemImage: "sunrise.fill").foregroundStyle(.yellow)
                }

                Button {
                    let nextWeek = cal.date(byAdding: .weekOfYear, value: 1, to: cal.startOfDay(for: Date()))!
                    viewModel.scheduleFor(todo, date: nextWeek)
                    dismiss()
                } label: {
                    Label("Next Week", systemImage: "forward.fill").foregroundStyle(.blue)
                }

                Button {
                    viewModel.moveToSomeday(todo)
                    dismiss()
                } label: {
                    Label("Someday", systemImage: "moon.zzz").foregroundStyle(.purple)
                }

                Section {
                    Button {
                        showCustomPicker.toggle()
                    } label: {
                        Label("Pick a Date", systemImage: "calendar").foregroundStyle(.primary)
                    }

                    if showCustomPicker {
                        DatePicker("", selection: $customDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)

                        Button("Schedule for \(customDate.formatted(date: .abbreviated, time: .omitted))") {
                            viewModel.scheduleFor(todo, date: customDate)
                            dismiss()
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

/// Context menu used across todo list views
struct TodoContextMenu: View {
    let todo: Todo
    let viewModel: TodoViewModel

    var body: some View {
        if todo.status != "Today" {
            Button {
                viewModel.moveToToday(todo)
            } label: {
                Label("Move to Today", systemImage: "star.fill")
            }
        }
        if todo.status != "Inbox" {
            Button {
                viewModel.moveToInbox(todo)
            } label: {
                Label("Move to Inbox", systemImage: "tray")
            }
        }
        if todo.status != "Someday" {
            Button {
                viewModel.moveToSomeday(todo)
            } label: {
                Label("Someday", systemImage: "moon.zzz")
            }
        }
        Divider()
        Button(role: .destructive) {
            viewModel.deleteTodo(todo)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

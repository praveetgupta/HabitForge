import SwiftUI

struct TodoDetailView: View {
    @Bindable var todo: Todo
    let viewModel: TodoViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showWhenPicker = false
    @State private var showDeadlinePicker = false
    @State private var showReminderPicker = false
    @State private var showProjectPicker = false
    @State private var showTagPicker = false
    @State private var newChecklistTitle = ""
    @FocusState private var checklistInputFocused: Bool

    var body: some View {
        Form {
            // MARK: Title
            Section {
                TextField("Title", text: $todo.title, axis: .vertical)
                    .font(.body.weight(.medium))
                    .lineLimit(1...5)
            }

            // MARK: Notes
            Section {
                TextField("Notes", text: $todo.notes, axis: .vertical)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(3...20)
                    .frame(minHeight: 72, alignment: .topLeading)
            }

            // MARK: Schedule
            Section {
                // When
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showWhenPicker.toggle() }
                        if showWhenPicker { showDeadlinePicker = false; showReminderPicker = false }
                    } label: {
                        MetadataRow(
                            icon: "calendar",
                            label: "When",
                            value: todo.whenDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "Someday",
                            valueColor: todo.whenDate != nil ? .primary : Color(UIColor.tertiaryLabel)
                        )
                    }
                    .buttonStyle(.plain)

                    if showWhenPicker {
                        DatePicker("", selection: whenDateBinding, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding(.top, 4)

                        HStack {
                            Button("Clear") {
                                todo.whenDate = nil
                                withAnimation { showWhenPicker = false }
                            }
                            .foregroundStyle(.red)
                            .font(.subheadline)
                            Spacer()
                        }
                        .padding(.bottom, 4)
                    }
                }

                // Deadline
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showDeadlinePicker.toggle() }
                        if showDeadlinePicker { showWhenPicker = false; showReminderPicker = false }
                    } label: {
                        MetadataRow(
                            icon: "flag",
                            label: "Deadline",
                            value: todo.deadline.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "None",
                            valueColor: deadlineColor
                        )
                    }
                    .buttonStyle(.plain)

                    if showDeadlinePicker {
                        DatePicker("", selection: deadlineDateBinding, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding(.top, 4)

                        HStack {
                            Button("Clear") {
                                todo.deadline = nil
                                withAnimation { showDeadlinePicker = false }
                            }
                            .foregroundStyle(.red)
                            .font(.subheadline)
                            Spacer()
                        }
                        .padding(.bottom, 4)
                    }
                }

                // Reminder
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showReminderPicker.toggle() }
                        if showReminderPicker { showWhenPicker = false; showDeadlinePicker = false }
                    } label: {
                        MetadataRow(
                            icon: "bell",
                            label: "Reminder",
                            value: todo.reminderDate.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "None",
                            valueColor: todo.reminderDate != nil ? .primary : Color(UIColor.tertiaryLabel)
                        )
                    }
                    .buttonStyle(.plain)

                    if showReminderPicker {
                        DatePicker("", selection: reminderDateBinding, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .padding(.top, 4)

                        HStack {
                            Button("Clear") {
                                todo.reminderDate = nil
                                withAnimation { showReminderPicker = false }
                            }
                            .foregroundStyle(.red)
                            .font(.subheadline)
                            Spacer()
                        }
                        .padding(.bottom, 4)
                    }
                }

                // Tags
                Button {
                    showTagPicker = true
                } label: {
                    MetadataRow(
                        icon: "tag",
                        label: "Tags",
                        value: todo.tags.isEmpty ? "None" : todo.tags.joined(separator: ", "),
                        valueColor: todo.tags.isEmpty ? Color(UIColor.tertiaryLabel) : .secondary
                    )
                }
                .buttonStyle(.plain)

                // Project
                Button {
                    showProjectPicker = true
                } label: {
                    MetadataRow(
                        icon: "doc.text",
                        label: "Project",
                        value: todo.project?.name ?? "None",
                        valueColor: todo.project != nil ? .secondary : Color(UIColor.tertiaryLabel)
                    )
                }
                .buttonStyle(.plain)

                // Priority
                HStack {
                    Label("Priority", systemImage: "flag.fill")
                        .foregroundStyle(.primary)
                        .font(.body)
                    Spacer()
                    Picker("Priority", selection: $todo.priority) {
                        Text("None").tag(0)
                        Text("Low").tag(1)
                        Text("Med").tag(2)
                        Text("High").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 180)
                }

                // Repeat
                Picker(selection: repeatTypeBinding) {
                    Text("None").tag("None")
                    Text("Daily").tag("Daily")
                    Text("Weekly").tag("Weekly")
                    Text("Monthly").tag("Monthly")
                    Text("Yearly").tag("Yearly")
                } label: {
                    Label("Repeat", systemImage: "repeat")
                }

                // Evening
                Toggle(isOn: $todo.isEvening) {
                    Label("This Evening", systemImage: "moon.fill")
                }
            }

            // MARK: Checklist
            Section {
                let sorted = todo.checklist.sorted { $0.sortOrder < $1.sortOrder }

                ForEach(sorted, id: \.id) { item in
                    HStack(spacing: 12) {
                        Button {
                            viewModel.toggleChecklistItem(item)
                        } label: {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isCompleted ? Color.green : Color.secondary)
                                .font(.body)
                        }
                        .buttonStyle(.plain)

                        Text(item.title)
                            .strikethrough(item.isCompleted)
                            .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                    }
                }
                .onMove { from, to in viewModel.reorderChecklist(todo, fromOffsets: from, toOffset: to) }
                .onDelete { indices in
                    let s = todo.checklist.sorted { $0.sortOrder < $1.sortOrder }
                    indices.forEach { viewModel.removeChecklistItem(s[$0], from: todo) }
                }

                // Add item row
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.body)
                    TextField("Add item", text: $newChecklistTitle)
                        .focused($checklistInputFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            let t = newChecklistTitle.trimmingCharacters(in: .whitespaces)
                            guard !t.isEmpty else { return }
                            viewModel.addChecklistItem(todo, title: t)
                            newChecklistTitle = ""
                            checklistInputFocused = true
                        }
                }
            } header: {
                HStack {
                    let total = todo.checklist.count
                    let done  = todo.checklist.filter(\.isCompleted).count
                    Text(total > 0 ? "Checklist \(done)/\(total)" : "Checklist")
                    Spacer()
                    EditButton()
                        .font(.caption)
                        .textCase(nil)
                }
            }

            // MARK: Move To
            Section("Move To") {
                if todo.status != "Today" {
                    Button {
                        viewModel.moveToToday(todo)
                        dismiss()
                    } label: {
                        Label("Today", systemImage: "star.fill").foregroundStyle(.orange)
                    }
                }
                if todo.status != "Inbox" {
                    Button {
                        viewModel.moveToInbox(todo)
                        dismiss()
                    } label: {
                        Label("Inbox", systemImage: "tray").foregroundStyle(.primary)
                    }
                }
                if todo.status != "Anytime" {
                    Button {
                        viewModel.moveToAnytime(todo)
                        dismiss()
                    } label: {
                        Label("Anytime", systemImage: "tray.full").foregroundStyle(.teal)
                    }
                }
                if todo.status != "Someday" {
                    Button {
                        viewModel.moveToSomeday(todo)
                        dismiss()
                    } label: {
                        Label("Someday", systemImage: "moon.zzz").foregroundStyle(.purple)
                    }
                }
            }

            // MARK: Delete
            Section {
                Button("Delete Task", role: .destructive) {
                    viewModel.deleteTodo(todo)
                    dismiss()
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    viewModel.saveTodo(todo)
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showProjectPicker) {
            ProjectPickerSheet(selectedProject: $todo.project, projects: viewModel.projects)
        }
        .sheet(isPresented: $showTagPicker) {
            TagPickerSheet(selectedTags: $todo.tags, allTags: viewModel.tags, viewModel: viewModel)
        }
    }

    // MARK: - Bindings

    private var whenDateBinding: Binding<Date> {
        Binding(
            get: { todo.whenDate ?? Date() },
            set: { todo.whenDate = $0 }
        )
    }

    private var deadlineDateBinding: Binding<Date> {
        Binding(
            get: { todo.deadline ?? Date() },
            set: { todo.deadline = $0 }
        )
    }

    private var reminderDateBinding: Binding<Date> {
        Binding(
            get: { todo.reminderDate ?? Date() },
            set: { todo.reminderDate = $0 }
        )
    }

    private var repeatTypeBinding: Binding<String> {
        Binding(
            get: { todo.repeatType ?? "None" },
            set: { v in
                todo.repeatType = v == "None" ? nil : v
                todo.isRepeating = v != "None"
            }
        )
    }

    private var deadlineColor: Color {
        guard let dl = todo.deadline else { return Color(UIColor.tertiaryLabel) }
        return dl < Date() ? .red : .primary
    }
}

private struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .secondary

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.primary)
                .font(.body)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .font(.body)
        }
    }
}

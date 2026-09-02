import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let viewModel: TodoViewModel
    @State private var animating = false

    var body: some View {
        NavigationLink(destination: TodoDetailView(todo: todo, viewModel: viewModel)) {
            HStack(spacing: 12) {
                // Completion circle
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        animating = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        if todo.status == "Logbook" {
                            viewModel.uncompleteTodo(todo)
                        } else {
                            viewModel.completeTodo(todo)
                        }
                        animating = false
                    }
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                todo.status == "Logbook" ? Color.green : Color.secondary.opacity(0.5),
                                lineWidth: 1.5
                            )
                            .frame(width: 24, height: 24)
                            .background(
                                Circle().fill(
                                    todo.status == "Logbook" || animating
                                        ? Color.green.opacity(0.15)
                                        : Color.clear
                                )
                            )

                        if todo.status == "Logbook" || animating {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.green)
                        }
                    }
                    .scaleEffect(animating ? 1.2 : 1.0)
                }
                .buttonStyle(.plain)

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(todo.title)
                        .strikethrough(todo.status == "Logbook", color: .secondary)
                        .foregroundStyle(todo.status == "Logbook" ? Color.secondary : Color.primary)
                        .lineLimit(2)

                    // Subtitle row
                    if hasSubtitle {
                        HStack(spacing: 6) {
                            if let project = todo.project {
                                HStack(spacing: 3) {
                                    Image(systemName: "doc.text")
                                        .font(.caption2)
                                    Text(project.name)
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            }

                            if let deadline = todo.deadline {
                                let overdue = deadline < Calendar.current.startOfDay(for: Date())
                                HStack(spacing: 3) {
                                    Image(systemName: "flag.fill")
                                        .font(.caption2)
                                    Text(deadline.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                }
                                .foregroundStyle(overdue ? Color.red : Color.secondary)
                            }

                            if todo.priority > 0 {
                                Image(systemName: "flag.fill")
                                    .font(.caption2)
                                    .foregroundStyle(priorityColor)
                            }

                            if todo.isRepeating {
                                Image(systemName: "repeat")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            if !todo.checklist.isEmpty {
                                let done = todo.checklist.filter(\.isCompleted).count
                                Text("\(done)/\(todo.checklist.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
    }

    private var hasSubtitle: Bool {
        todo.project != nil || todo.deadline != nil || todo.priority > 0 ||
        todo.isRepeating || !todo.checklist.isEmpty
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

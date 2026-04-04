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

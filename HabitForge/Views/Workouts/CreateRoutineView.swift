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

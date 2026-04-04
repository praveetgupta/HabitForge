import SwiftUI

struct AddHabitView: View {
    let viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var icon = "⭐"
    @State private var colorHex = "#FF6B6B"
    @State private var habitType = "Build"
    @State private var tracksDuration = false
    @State private var tracksCount = false
    
    let colorOptions = ["#FF6B6B", "#FF9500", "#FFCC00", "#34C759", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("Habit name", text: $name)
                    
                    // TODO: Emoji picker
                    TextField("Icon (emoji)", text: $icon)
                    
                    Picker("Type", selection: $habitType) {
                        Text("Build (do it)").tag("Build")
                        Text("Break (avoid it)").tag("Break")
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(.white, lineWidth: colorHex == hex ? 3 : 0)
                                )
                                .onTapGesture { colorHex = hex }
                        }
                    }
                }
                
                Section("Tracking") {
                    Toggle("Track duration", isOn: $tracksDuration)
                    Toggle("Track count", isOn: $tracksCount)
                }
                
                // TODO: Scheduling section (frequency, days)
                // TODO: Reminder section
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addHabit(name: name, icon: icon, colorHex: colorHex)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

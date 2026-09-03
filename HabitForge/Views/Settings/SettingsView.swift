import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var settings = AppSettings.shared
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var showingResetConfirmation = false

    @Query(filter: #Predicate<Habit> { $0.isArchived }) private var archivedHabits: [Habit]
    @Query(filter: #Predicate<Routine> { $0.isArchived }) private var archivedRoutines: [Routine]

    private var archivedCount: Int { archivedHabits.count + archivedRoutines.count }

    var body: some View {
        NavigationStack {
            List {
                unitsSection
                remindersSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .task { await refreshNotificationStatus() }
            .confirmationDialog(
                "Delete all HabitForge data?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) { resetAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Every habit, todo, routine and logged workout is erased. This cannot be undone — export your data first if you want a copy.")
            }
            .alert("Export failed", isPresented: .constant(exportError != nil)) {
                Button("OK") { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var unitsSection: some View {
        Section {
            Picker("Weight unit", selection: $settings.weightUnit) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }

            Picker("Appearance", selection: $settings.appearance) {
                ForEach(AppearancePreference.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }

            Picker("Default rest timer", selection: $settings.defaultRestSeconds) {
                ForEach([30, 45, 60, 90, 120, 180], id: \.self) { seconds in
                    Text(restLabel(seconds)).tag(seconds)
                }
            }
        } header: {
            Text("Preferences")
        } footer: {
            Text("Weights are always stored in kilograms; changing the unit only changes how they are shown and entered.")
        }
    }

    private var remindersSection: some View {
        Section {
            LabeledContent("Permission") {
                Text(notificationStatusText)
                    .foregroundStyle(notificationStatus == .authorized ? Color.green : Color.secondary)
            }

            if notificationStatus != .authorized {
                Button("Open iOS Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Habit reminders are local notifications scheduled on this device. They arrive only while HabitForge is in the background.")
        }
    }

    private var dataSection: some View {
        Section {
            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Share export", systemImage: "square.and.arrow.up")
                }
            }

            Button {
                prepareExport()
            } label: {
                Label(exportURL == nil ? "Export all data (JSON)" : "Rebuild export",
                      systemImage: "arrow.down.doc")
            }

            NavigationLink {
                ArchiveView()
            } label: {
                LabeledContent {
                    Text("\(archivedCount)")
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
            }

            Button(role: .destructive) {
                showingResetConfirmation = true
            } label: {
                Label("Reset all data", systemImage: "trash")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("HabitForge stores everything on this device. Nothing is uploaded, and there is no account to sign into.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "\(Bundle.main.shortVersionString) (\(Bundle.main.buildNumber))")

            Link(destination: URL(string: "https://github.com/praveetgupta/HabitForge")!) {
                Label("Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }

            Link(destination: URL(string: "https://github.com/praveetgupta/HabitForge/issues/new")!) {
                Label("Report an issue", systemImage: "exclamationmark.bubble")
            }

            LabeledContent("License", value: "Apache-2.0")
        }
    }

    // MARK: - Helpers

    private func restLabel(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s" : "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }

    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: "Allowed"
        case .denied: "Denied"
        case .notDetermined: "Not asked yet"
        @unknown default: "Unknown"
        }
    }

    private func refreshNotificationStatus() async {
        notificationStatus = await NotificationService.shared.authorizationStatus()
    }

    private func prepareExport() {
        do {
            exportURL = try DataExportService.writeExportFile(modelContext: modelContext)
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func resetAllData() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for model in HabitForgeSchema.models {
            try? modelContext.delete(model: model)
        }
        try? modelContext.save()
        exportURL = nil
        // The exercise library is reference data, not user data — put it straight back.
        ExerciseSeedData.seedIfNeeded(modelContext: modelContext)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Habit.self, inMemory: true)
}

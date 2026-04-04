import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    NavigationLink("Profile", destination: Text("Profile View"))
                    NavigationLink("Subscription", destination: SubscriptionView())
                }
                
                Section("Preferences") {
                    NavigationLink("Notifications", destination: Text("Notification Settings"))
                    // TODO: Units (kg/lbs), theme, export data
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

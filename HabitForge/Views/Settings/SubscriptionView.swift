import SwiftUI

struct SubscriptionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("HabitForge Pro")
                .font(.largeTitle.bold())
            
            // TODO: RevenueCat paywall
            Text("Unlock unlimited habits, todos, routines, and cloud sync")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                Text("$4.99/month")
                Text("$39.99/year (save 33%)")
                    .foregroundStyle(.secondary)
            }
            
            Button("Subscribe") {
                // TODO: RevenueCat purchase
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Pro")
    }
}

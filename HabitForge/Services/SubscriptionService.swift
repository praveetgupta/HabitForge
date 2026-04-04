import Foundation

// TODO: Implement with RevenueCat SDK
// See HabitForge-Dev-Guide.md for RevenueCat setup

class SubscriptionService {
    static let shared = SubscriptionService()
    
    var isProUser: Bool = false
    
    func checkSubscriptionStatus() async {
        // TODO: RevenueCat check entitlements
    }
    
    func purchase(package: String) async throws {
        // TODO: RevenueCat purchase
    }
    
    func restorePurchases() async throws {
        // TODO: RevenueCat restore
    }
}

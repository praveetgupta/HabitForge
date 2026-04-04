import SwiftUI

@Observable
class AuthViewModel {
    var isAuthenticated: Bool = false
    var currentUserEmail: String?
    var isLoading: Bool = false
    var errorMessage: String?
    
    // TODO: Implement Firebase Auth
    // - signIn(email:password:)
    // - signUp(email:password:)
    // - signInWithApple()
    // - signOut()
    
    func signIn(email: String, password: String) {
        // Placeholder — implement with Firebase Auth
        isAuthenticated = true
        currentUserEmail = email
    }
    
    func signOut() {
        isAuthenticated = false
        currentUserEmail = nil
    }
}

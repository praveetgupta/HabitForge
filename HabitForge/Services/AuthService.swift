import Foundation

// TODO: Implement with Firebase Auth SDK
// See HabitForge-Dev-Guide.md for Firebase setup instructions

class AuthService {
    static let shared = AuthService()
    
    var isAuthenticated: Bool { currentUserId != nil }
    var currentUserId: String?
    
    func signIn(email: String, password: String) async throws {
        // TODO: Firebase Auth signIn
    }
    
    func signUp(email: String, password: String) async throws {
        // TODO: Firebase Auth createUser
    }
    
    func signOut() throws {
        currentUserId = nil
    }
}

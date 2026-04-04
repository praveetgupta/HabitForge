import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("HabitForge")
                .font(.largeTitle.bold())
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            Button("Sign In") {
                // TODO: Firebase Auth
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // TODO: Sign in with Apple button
            // TODO: Sign up link
        }
        .padding(32)
    }
}

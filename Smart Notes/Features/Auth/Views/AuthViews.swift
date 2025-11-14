// AuthView.swift
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignUpMode = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account")) {
                    TextField("Email", text: $authViewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $authViewModel.password)
                }
                
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                
                Section {
                    Button(isSignUpMode ? "Sign Up" : "Sign In") {
                        if isSignUpMode {
                            authViewModel.signUp()
                        } else {
                            authViewModel.signIn()
                        }
                    }
                }
            }
            .navigationTitle(isSignUpMode ? "Create Account" : "Sign In")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSignUpMode ? "Have an account?" : "New user?") {
                        isSignUpMode.toggle()
                    }
                }
            }
        }
    }
}

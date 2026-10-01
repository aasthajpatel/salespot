//
//  AuthenticationView.swift
//  SaleSpot
//
//  Created by Aastha Patel on 1/8/26.
//

import SwiftUI
import FirebaseAuth

// Authentication Manager
class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    init() {
        // Check if user is already logged in
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil
        
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            completion(error)
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            completion(error)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
            isAuthenticated = false
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }
}

// Authentication View
struct AuthenticationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var errorMessage = ""
    @State private var showError = false
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: DataManager
    @State private var showResetAlert = false
    @State private var resetMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("SaleSpot")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Find yard sales near you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)
            
            // Forms
            VStack(spacing: 16) {
                // Name field
                if isSignUp {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal, 32)
            
            // Sign In & Sign Up Button
            Button(action: authenticate) {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 32)
            .disabled(email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty))
            
            // Toggle Sign In & Sign Up
            Button(action: {
                isSignUp.toggle()
                errorMessage = ""
            }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            if !isSignUp {
                Button("Forgot password?") {
                    sendReset()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            // Error Message
            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        
        .alert("Password Reset", isPresented: $showResetAlert) {
            Button("OK") {}
        } message: {
            Text(resetMessage)
        }
    }
    
    private func authenticate() {
        if isSignUp {
            authManager.signUp(email: email, password: password) { error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                else {
                    dataManager.userProfile.name = name
                    dataManager.userProfile.email = email
                    dataManager.userProfile.joinedDate = Date()
                    dataManager.saveUserProfile()
                }
            }
        }
        else {
            authManager.signIn(email: email, password: password) { error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func sendReset() {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty else {
            resetMessage = "Enter your email in the field above first."
            showResetAlert = true
            return
        }
        authManager.resetPassword(email: cleanEmail) { error in
            if let error = error {
                resetMessage = error.localizedDescription
            } else {
                resetMessage = "If an account exists for that email, a reset link is on its way."
            }
            showResetAlert = true
        }
    }
}

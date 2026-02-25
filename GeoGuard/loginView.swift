//
//  loginView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingSignup = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo/Header
                VStack(spacing: 12) {
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .font(.system(size: 70))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("GeoGuard")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Personnel Safety Tracking")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal)
                
                // Divider
                HStack {
                    VStack { Divider() }
                    Text("New to GeoGuard?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VStack { Divider() }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Sign Up Button
                Button {
                    showingSignup = true
                } label: {
                    Text("Create Account")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showingSignup) {
                SignupView()
            }
        }
    }
    
    func login() {
        Task {
            isLoading = true
            errorMessage = ""
            defer { isLoading = false }
            
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                print("✅ Login successful: \(result.user.uid)")
                // AuthService will automatically pick up the auth state change
            } catch {
                errorMessage = getErrorMessage(for: error)
                print("❌ Login error: \(error.localizedDescription)")
            }
        }
    }
    
    func getErrorMessage(for error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please try again later."
        default:
            return error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
}


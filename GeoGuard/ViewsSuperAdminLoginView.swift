//
//  SuperAdminLoginView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-27.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SuperAdminLoginView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showVerification = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Super Admin Header
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.red.gradient)
                    
                    Text("Platform Administration")
                        .font(.title)
                        .bold()
                    
                    Text("GeoGuard Super Admin Access")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Admin Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                    
                    if showVerification {
                        SecureField("2FA Code (Optional)", text: $verificationCode)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }
                    
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
                            Text("Sign In as Super Admin")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Back to normal login
                Button {
                    dismiss()
                } label: {
                    Text("Back to Regular Login")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
            .padding()
        }
    }
    
    func login() {
        Task {
            isLoading = true
            errorMessage = ""
            defer { isLoading = false }
            
            do {
                // Sign in with Firebase
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                
                // Verify user has super admin role
                let db = Firestore.firestore()
                let userDoc = try await db.collection("users").document(result.user.uid).getDocument()
                
                guard let userData = try? userDoc.data(as: User.self) else {
                    errorMessage = "Failed to load user data"
                    try Auth.auth().signOut()
                    return
                }
                
                // Check if user is super admin
                guard userData.role == .superAdmin else {
                    errorMessage = "Access denied. Super admin privileges required."
                    try Auth.auth().signOut()
                    return
                }
                
                // Verify account is active
                guard userData.isActive else {
                    errorMessage = "This account has been deactivated."
                    try Auth.auth().signOut()
                    return
                }
                
                print("✅ Super Admin login successful: \(userData.fullName)")
                
                // Optional: Log super admin access
                try await db.collection("audit_logs").addDocument(data: [
                    "userId": result.user.uid,
                    "action": "super_admin_login",
                    "timestamp": FieldValue.serverTimestamp(),
                    "email": email
                ])
                
                dismiss()
                
            } catch {
                errorMessage = getErrorMessage(for: error)
                print("❌ Super admin login error: \(error.localizedDescription)")
            }
        }
    }
    
    func getErrorMessage(for error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.userNotFound.rawValue:
            return "No admin account found with this email."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Account temporarily locked."
        default:
            return error.localizedDescription
        }
    }
}

#Preview {
    SuperAdminLoginView()
        .environmentObject(AuthService())
}

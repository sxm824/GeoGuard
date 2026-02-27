//
//  SuperAdminLoginView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-27.
//

import SwiftUI
import FirebaseAuth

/// Dedicated login page for GeoGuard Super Admins (Platform Team)
struct SuperAdminLoginView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Super Admin Header
                VStack(spacing: 16) {
                    // Crown Icon with Shield
                    ZStack {
                        // Background glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.purple.opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 140, height: 140)
                        
                        // Shield
                        Image(systemName: "shield.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.purple, Color.indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Crown overlay
                        Image(systemName: "crown.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .offset(y: -20)
                            .shadow(color: .orange.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                    .frame(height: 140)
                    
                    VStack(spacing: 8) {
                        Text("Super Admin")
                            .font(.title)
                            .bold()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.purple, Color.indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("GeoGuard Platform Team")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Warning badge
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text("Authorized Personnel Only")
                                .font(.caption)
                                .bold()
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 40)
                
                // Login Form
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Admin Email", systemImage: "envelope.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("admin@geoguard.com", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Admin Password", systemImage: "lock.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                            Text(errorMessage)
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Login Button
                    Button(action: login) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Authenticating...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            HStack {
                                Image(systemName: "key.fill")
                                Text("Access Platform")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.large)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .padding(.top, 8)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Back to Regular Login
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "arrow.left.circle.fill")
                        Text("Back to Regular Login")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
                
                // Footer Info
                VStack(spacing: 4) {
                    Text("This login is for GeoGuard platform administrators only.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Regular users should use the standard login.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Login Function
    
    func login() {
        Task {
            isLoading = true
            errorMessage = ""
            defer { isLoading = false }
            
            do {
                // Sign in with Firebase Auth
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                print("✅ Super Admin login attempt: \(result.user.uid)")
                
                // Verify this is actually a super admin
                let db = Firestore.firestore()
                let userDoc = try await db.collection("users").document(result.user.uid).getDocument()
                
                guard let userData = try? userDoc.data(as: User.self) else {
                    throw SuperAdminLoginError.invalidUser
                }
                
                // Check if user has super admin role
                guard userData.role == .superAdmin else {
                    // Not a super admin - sign them out
                    try Auth.auth().signOut()
                    throw SuperAdminLoginError.notSuperAdmin
                }
                
                // Verify tenant is PLATFORM
                guard userData.tenantId == "PLATFORM" else {
                    try Auth.auth().signOut()
                    throw SuperAdminLoginError.invalidTenant
                }
                
                print("✅ Super Admin authenticated: \(userData.fullName)")
                // AuthService will automatically pick up the auth state change
                
            } catch let error as SuperAdminLoginError {
                errorMessage = error.localizedDescription
                print("❌ Super Admin login error: \(error)")
            } catch {
                errorMessage = getErrorMessage(for: error)
                print("❌ Login error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Error Handling
    
    func getErrorMessage(for error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Access denied."
        case AuthErrorCode.userNotFound.rawValue:
            return "No super admin account found with this email."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many failed attempts. Please try again later."
        default:
            return "Authentication failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Custom Errors

enum SuperAdminLoginError: LocalizedError {
    case invalidUser
    case notSuperAdmin
    case invalidTenant
    
    var errorDescription: String? {
        switch self {
        case .invalidUser:
            return "Unable to load user data. Please contact support."
        case .notSuperAdmin:
            return "Access denied. This account is not a super admin. Please use the regular login."
        case .invalidTenant:
            return "Invalid tenant configuration. Please contact GeoGuard support."
        }
    }
}

// MARK: - Preview

#Preview {
    SuperAdminLoginView()
}

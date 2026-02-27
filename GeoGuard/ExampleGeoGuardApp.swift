//
//  ExampleGeoGuardApp.swift
//  GeoGuard
//
//  Example app entry point for super admin login implementation
//

import SwiftUI
import Firebase

// IMPORTANT: You have TWO @main entry points in your project!
// This file AND GeoGuardApp.swift both have @main
// Comment out ONE of them. Keep this one if you want the simpler setup.

@main
struct ExampleGeoGuardApp: App {
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Optional: Configure other services
        // GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_KEY")
    }
    
    var body: some Scene {
        WindowGroup {
            // Explicitly use the RootView from ViewsRootView.swift
            // This avoids ambiguity with the RootView defined in GeoGuardApp.swift
            ContentRootView()
        }
    }
}

// MARK: - Wrapper to avoid ambiguity

/// Wrapper view that explicitly instantiates the correct RootView
/// This avoids conflicts with other RootView definitions in the project
struct ContentRootView: View {
    @StateObject private var authService = AuthService()
    
    var body: some View {
        AuthenticatedRootView()
            .environmentObject(authService)
    }
}

/// The actual root view with authentication logic
private struct AuthenticatedRootView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isLoading {
                LoadingStateView()
            } else if authService.isAuthenticated, let user = authService.currentUser {
                roleBasedView(for: user)
            } else {
                AuthenticationView()
            }
        }
    }
    
    @ViewBuilder
    private func roleBasedView(for user: User) -> some View {
        switch user.role {
        case .superAdmin:
            SuperAdminDashboardView()
        case .admin:
            AdminDashboardView()
        case .manager:
            ManagerDashboardView()
        case .fieldPersonnel:
            FieldPersonnelDashboardView()
        }
    }
}

// MARK: - Supporting Views

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            Color.blue.opacity(0.15 - Double(index) * 0.05),
                            lineWidth: 1.5
                        )
                        .frame(width: 100 + CGFloat(index * 30), height: 100 + CGFloat(index * 30))
                }
                
                Image(systemName: "shield.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.1, green: 0.3, blue: 0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .frame(height: 120)
            
            Text("GeoGuard")
                .font(.largeTitle)
                .bold()
            
            ProgressView()
                .tint(Color(red: 0.2, green: 0.4, blue: 0.8))
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

private struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingSignup = false
    @State private var showingSuperAdminLogin = false
    @State private var superAdminTapCount = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo/Header
                VStack(spacing: 12) {
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .font(.system(size: 70))
                        .foregroundStyle(.blue.gradient)
                        .onTapGesture {
                            superAdminTapCount += 1
                            if superAdminTapCount >= 5 {
                                showingSuperAdminLogin = true
                                superAdminTapCount = 0
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                superAdminTapCount = 0
                            }
                        }
                    
                    Text("GeoGuard")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Track smart. Stay safe.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Your people, your assets, guarded.")
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
            .sheet(isPresented: $showingSuperAdminLogin) {
                SuperAdminLoginView()
                    .environmentObject(authService)
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

import FirebaseAuth

/*
 IMPLEMENTATION NOTES:
 
 1. RootView handles all authentication state:
    - If not authenticated → Shows LoginView
    - If authenticated → Routes to role-specific dashboard
 
 2. Role-based routing:
    - super_admin → SuperAdminDashboardView
    - admin → AdminDashboardView  
    - manager → ManagerDashboardView
    - field_personnel → FieldPersonnelDashboardView
 
 3. AuthService is provided via @EnvironmentObject
    - Access from any view: @EnvironmentObject var authService: AuthService
    - Use authService.currentUser to get user data
    - Use authService.signOut() to log out
 
 4. Replace YOUR_GOOGLE_MAPS_KEY with your actual API key
 
 */

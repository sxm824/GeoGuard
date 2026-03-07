//
//  RootView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-27.
//

import SwiftUI

/// Root view that handles authentication state and role-based routing
struct RootView: View {
    @StateObject private var authService = AuthService()
    
    var body: some View {
        Group {
            if authService.isLoading {
                // Loading state
                LoadingView()
            } else if let authError = authService.authError {
                // Authentication error - show error screen
                AuthErrorView(error: authError)
            } else if authService.isAuthenticated, let user = authService.currentUser {
                // User is authenticated - route based on role
                roleBasedView(for: user)
            } else {
                // Not authenticated - show login
                LoginView()
            }
        }
        .environmentObject(authService)
    }
    
    // MARK: - Role-Based Routing
    
    @ViewBuilder
    private func roleBasedView(for user: User) -> some View {
        switch user.role {
        case .superAdmin:
            SuperAdminDashboardView()
                .transition(.opacity)
            
        case .admin:
            AdminDashboardView()
                .transition(.opacity)
            
        case .manager:
            ManagerDashboardView()
                .transition(.opacity)
            
        case .fieldPersonnel:
            DriverDashboardView()  // ✅ Changed from FieldPersonnelDashboardView
                .transition(.opacity)
        }
    }
}

// MARK: - Auth Error View

struct AuthErrorView: View {
    let error: AuthError
    @EnvironmentObject var authService: AuthService
    @State private var showingDiagnostics = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Error Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding(.top, 40)
                
                VStack(spacing: 12) {
                    Text("Account Issue Detected")
                        .font(.title2)
                        .bold()
                    
                    if let errorDescription = error.errorDescription {
                        Text(errorDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    if let recoverySuggestion = error.recoverySuggestion {
                        Text(recoverySuggestion)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                    }
                }
                
                VStack(spacing: 16) {
                    Button {
                        showingDiagnostics = true
                    } label: {
                        Label("Run Diagnostics", systemImage: "wrench.and.screwdriver")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 32)
                    
                    Button {
                        Task {
                            try? authService.signOut()
                        }
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 32)
                }
                .padding(.top, 24)
                
                Spacer()
            }
            .navigationTitle("Authentication Error")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDiagnostics) {
                NavigationStack {
                    UserAccountDiagnosticsView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showingDiagnostics = false
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Logo
            ZStack {
                // Radar arcs
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            Color.blue.opacity(0.15 - Double(index) * 0.05),
                            lineWidth: 1.5
                        )
                        .frame(width: 100 + CGFloat(index * 30), height: 100 + CGFloat(index * 30))
                }
                
                // Shield
                Image(systemName: "shield.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.1, green: 0.3, blue: 0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Location pin
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .frame(height: 120)
            
            Text("GeoGuard")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.1, green: 0.3, blue: 0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .tint(Color(red: 0.2, green: 0.4, blue: 0.8))
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Placeholder Dashboard Views
// Replace these with your actual dashboard implementations

struct ManagerDashboardView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Manager Dashboard")
                    .font(.largeTitle)
                    .bold()
                
                if let user = authService.currentUser {
                    Text("Welcome, \(user.fullName)")
                        .foregroundColor(.secondary)
                }
                
                Button("Sign Out") {
                    try? authService.signOut()
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .navigationTitle("Manager")
        }
    }
}

// Note: DriverDashboardView is used for field personnel (see roleBasedView)
// It includes GPS tracking, alerts, and profile tabs

// MARK: - Preview

#Preview("Loading") {
    LoadingView()
}

#Preview("Root View") {
    RootView()
}

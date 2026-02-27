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
            FieldPersonnelDashboardView()
                .transition(.opacity)
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

struct FieldPersonnelDashboardView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Field Personnel Dashboard")
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
            .navigationTitle("Field View")
        }
    }
}

// MARK: - Preview

#Preview("Loading") {
    LoadingView()
}

#Preview("Root View") {
    RootView()
}

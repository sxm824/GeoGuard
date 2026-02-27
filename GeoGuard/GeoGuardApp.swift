//
//  GeoGuardApp.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-23.
//

import SwiftUI
import GoogleMaps
// TODO: Uncomment after adding GooglePlaces package via SPM
// import GooglePlaces
import FirebaseCore

// DISABLED: This entire file is disabled because ExampleGeoGuardApp.swift is the active entry point
// To use this file instead:
// 1. Uncomment @main below
// 2. Comment out @main in ExampleGeoGuardApp.swift
// 3. Make these views public (remove 'private' keywords)

/*
// @main
struct GeoGuardApp: App {
    @StateObject private var authService = AuthService()
    
    init() {
        let apiKey = "AIzaSyAbiceuS7oChS1ojh51MyLq-d4mmx0Wv5g"
        GMSServices.provideAPIKey(apiKey)
        
        // TODO: Uncomment after GooglePlaces is added
        // GMSPlacesClient.provideAPIKey(apiKey)
        
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            GeoGuardRootView()
                .environmentObject(authService)
        }
    }
}

private struct GeoGuardRootView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isLoading {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
            } else if authService.isAuthenticated, let user = authService.currentUser {
                // Authenticated - route by role
                switch user.role {
                case .admin, .superAdmin:
                    AdminDashboardView()
                        .environmentObject(authService)
                case .manager:
                    GeoGuardManagerDashboardView()
                        .environmentObject(authService)
                case .fieldPersonnel:
                    DriverDashboardView()
                        .environmentObject(authService)
                }
            } else {
                // Not authenticated
                GeoGuardLoginView()
            }
        }
    }
}

// Placeholder for Manager Dashboard (similar to Driver for now)
private struct GeoGuardManagerDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Manager Dashboard")
                    .font(.title)
                    .padding()
                
                Text("Coming soon: Enhanced fleet management features")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("GeoGuard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingSignOutAlert = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .imageScale(.large)
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    try? authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

private struct GeoGuardLoginView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Text("Login View - Placeholder")
    }
}

#Preview {
    GeoGuardRootView()
        .environmentObject(AuthService())
}
*/


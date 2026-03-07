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


@main
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
                case .superAdmin:
                    SuperAdminDashboardView()
                        .environmentObject(authService)
                case .admin:
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
                LoginView()
            }
        }
        .errorAlert(authErrorBinding, title: "Authentication Error")
    }
    
    // Helper to convert Binding<AuthError?> to Binding<Error?>
    private var authErrorBinding: Binding<Error?> {
        Binding(
            get: { authService.authError },
            set: { authService.authError = $0 as? AuthError }
        )
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

// Login view is now in LoginView.swift - no placeholder needed

#Preview {
    GeoGuardRootView()
        .environmentObject(AuthService())
}



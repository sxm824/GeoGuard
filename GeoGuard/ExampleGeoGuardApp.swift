//
//  GeoGuardApp.swift
//  GeoGuard
//
//  Example app entry point for super admin login implementation
//

import SwiftUI
import Firebase

@main
struct GeoGuardApp: App {
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Optional: Configure other services
        // GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_KEY")
    }
    
    var body: some Scene {
        WindowGroup {
            // Use RootView for automatic authentication and role-based routing
            RootView()
        }
    }
}

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

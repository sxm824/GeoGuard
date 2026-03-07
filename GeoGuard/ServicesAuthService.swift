//
//  AuthService.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var authError: AuthError?
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // Flag to temporarily disable auth state listener during registration
    private var isRegistrationInProgress = false
    
    init() {
        // Listen for auth state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            // Skip if registration is in progress
            if self.isRegistrationInProgress {
                print("⏸️ Auth state change detected but registration in progress - skipping")
                return
            }
            
            Task {
                if let user = user {
                    // User is signed in, load their data
                    await self.loadUserData(userId: user.uid)
                } else {
                    // User is signed out
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Registration Control
    
    func beginRegistration() {
        print("🔒 Registration started - AuthStateListener disabled")
        isRegistrationInProgress = true
    }
    
    func endRegistration() {
        print("🔓 Registration ended - AuthStateListener enabled")
        isRegistrationInProgress = false
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Load User Data
    
    func loadUserData(userId: String) async {
        print("🔵 loadUserData called for userId: \(userId)")
        isLoading = true
        authError = nil // Clear any previous errors
        
        defer { 
            isLoading = false
            print("🔵 loadUserData finished, isLoading now: false")
        }
        
        do {
            print("🔵 Fetching user document...")
            let document = try await db.collection("users").document(userId).getDocument()
            
            guard document.exists else {
                print("⚠️ User document doesn't exist for UID: \(userId)")
                authError = .userDocumentNotFound(userId: userId)
                currentUser = nil
                isAuthenticated = false
                
                // Sign out the Firebase Auth user since they don't have a valid user document
                try? Auth.auth().signOut()
                return
            }
            
            print("🔵 User document exists, parsing data...")
            currentUser = try document.data(as: User.self)
            isAuthenticated = true
            
            print("✅ Loaded user: \(currentUser?.fullName ?? "Unknown") (Tenant: \(currentUser?.tenantId ?? "None"))")
            print("🔵 User role: \(currentUser?.role.rawValue ?? "unknown")")
            print("🔵 isAuthenticated: \(isAuthenticated)")
            
            // Update last login - this might fail if rules aren't deployed
            print("🔵 Attempting to update lastLoginAt...")
            do {
                try await db.collection("users").document(userId).updateData([
                    "lastLoginAt": FieldValue.serverTimestamp()
                ])
                print("✅ Updated lastLoginAt successfully")
            } catch {
                print("⚠️ Could not update lastLoginAt (not critical): \(error.localizedDescription)")
                // Don't fail the login if this fails
            }
            
        } catch {
            print("❌ Error loading user data: \(error.localizedDescription)")
            authError = .loadUserDataFailed(error: error)
            currentUser = nil
            isAuthenticated = false
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Check Permission
    
    func hasPermission(_ permission: Permission) -> Bool {
        guard let user = currentUser else { return false }
        return user.role.permissions.contains(permission)
    }
    
    func hasRole(_ role: UserRole) -> Bool {
        return currentUser?.role == role
    }
    
    // MARK: - Refresh User Data
    
    func refreshUserData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        await loadUserData(userId: userId)
    }
}

// MARK: - Helper Extensions

extension AuthService {
    var tenantId: String? {
        return currentUser?.tenantId
    }
    
    var userId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    var userRole: UserRole? {
        return currentUser?.role
    }
    
    var isAdmin: Bool {
        return currentUser?.role == .admin || currentUser?.role == .superAdmin
    }
    
    var isManager: Bool {
        return currentUser?.role == .manager || isAdmin
    }
}
// MARK: - Auth Error Types

enum AuthError: LocalizedError {
    case userDocumentNotFound(userId: String)
    case loadUserDataFailed(error: Error)
    case signOutFailed(error: Error)
    
    var errorDescription: String? {
        switch self {
        case .userDocumentNotFound(let userId):
            return "Your account setup is incomplete. Please contact your administrator.\n\nUser ID: \(userId)"
        case .loadUserDataFailed(let error):
            return "Failed to load user data: \(error.localizedDescription)"
        case .signOutFailed(let error):
            return "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .userDocumentNotFound:
            return "This usually happens when your account hasn't been properly set up. Contact your system administrator to complete your account setup."
        case .loadUserDataFailed:
            return "Please check your internet connection and try again. If the problem persists, contact support."
        case .signOutFailed:
            return "Please try again. If the problem persists, restart the app."
        }
    }
}


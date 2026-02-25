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
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen for auth state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
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
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Load User Data
    
    func loadUserData(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            guard document.exists else {
                print("⚠️ User document doesn't exist for UID: \(userId)")
                currentUser = nil
                isAuthenticated = false
                return
            }
            
            currentUser = try document.data(as: User.self)
            isAuthenticated = true
            
            // Update last login
            try await db.collection("users").document(userId).updateData([
                "lastLoginAt": FieldValue.serverTimestamp()
            ])
            
            print("✅ Loaded user: \(currentUser?.fullName ?? "Unknown") (Tenant: \(currentUser?.tenantId ?? "None"))")
            
        } catch {
            print("❌ Error loading user data: \(error.localizedDescription)")
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

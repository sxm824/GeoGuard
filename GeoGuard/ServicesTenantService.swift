//
//  TenantService.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class TenantService: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var currentTenant: Tenant?
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Create Tenant (Company Registration)
    
    func createTenant(
        name: String,
        domain: String?,
        adminUserId: String,
        subscription: Tenant.SubscriptionTier = .trial
    ) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        // Check if tenant name already exists
        let existingTenants = try await db.collection("tenants")
            .whereField("name", isEqualTo: name)
            .getDocuments()
        
        guard existingTenants.documents.isEmpty else {
            throw TenantError.tenantAlreadyExists
        }
        
        // Create tenant document
        let tenant = Tenant(
            name: name,
            domain: domain,
            adminUserId: adminUserId,
            subscription: subscription,
            isActive: true,
            maxUsers: maxUsersForTier(subscription),
            createdAt: Date(),
            settings: TenantSettings()
        )
        
        let docRef = try await db.collection("tenants").addDocument(data: tenant.toDictionary())
        
        // Set custom claims for admin user
        try await setUserTenantClaims(userId: adminUserId, tenantId: docRef.documentID, role: .admin)
        
        return docRef.documentID
    }
    
    // MARK: - Load Tenant
    
    func loadTenant(tenantId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let document = try await db.collection("tenants").document(tenantId).getDocument()
        
        guard document.exists else {
            throw TenantError.tenantNotFound
        }
        
        currentTenant = try document.data(as: Tenant.self)
    }
    
    // MARK: - Find Tenant by Domain
    
    func findTenantByDomain(_ domain: String) async throws -> Tenant? {
        let snapshot = try await db.collection("tenants")
            .whereField("domain", isEqualTo: domain)
            .whereField("isActive", isEqualTo: true)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try document.data(as: Tenant.self)
    }
    
    // MARK: - Check User Limit
    
    func canAddUser(tenantId: String) async throws -> Bool {
        // Get tenant
        let tenantDoc = try await db.collection("tenants").document(tenantId).getDocument()
        guard let tenant = try? tenantDoc.data(as: Tenant.self) else {
            return false
        }
        
        // Count current users
        let usersSnapshot = try await db.collection("users")
            .whereField("tenantId", isEqualTo: tenantId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        return usersSnapshot.documents.count < tenant.maxUsers
    }
    
    // MARK: - Set Custom Claims (for Security Rules)
    
    func setUserTenantClaims(userId: String, tenantId: String, role: UserRole) async throws {
        // This should be done via Cloud Functions in production
        // For now, we store it in the user document and rely on security rules
        try await db.collection("users").document(userId).updateData([
            "tenantId": tenantId,
            "role": role.rawValue
        ])
    }
    
    // MARK: - Helper Methods
    
    private func maxUsersForTier(_ tier: Tenant.SubscriptionTier) -> Int {
        switch tier {
        case .trial: return 5
        case .basic: return 25
        case .professional: return 100
        case .enterprise: return 1000
        }
    }
    
    // MARK: - Update Tenant
    
    func updateTenant(tenantId: String, updates: [String: Any]) async throws {
        try await db.collection("tenants").document(tenantId).updateData(updates)
        
        // Reload tenant
        try await loadTenant(tenantId: tenantId)
    }
}

// MARK: - Errors

enum TenantError: LocalizedError {
    case tenantAlreadyExists
    case tenantNotFound
    case userLimitReached
    case invalidDomain
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .tenantAlreadyExists:
            return "A company with this name already exists."
        case .tenantNotFound:
            return "Company not found."
        case .userLimitReached:
            return "Maximum number of users reached for this subscription tier."
        case .invalidDomain:
            return "Invalid email domain."
        case .unauthorized:
            return "You don't have permission to perform this action."
        }
    }
}

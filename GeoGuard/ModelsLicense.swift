//
//  License.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-26.
//

import Foundation
import FirebaseFirestore

/// Represents a license key for creating a new organization
struct License: Identifiable, Codable {
    @DocumentID var id: String?
    
    let licenseKey: String              // e.g., "GGUARD-2024-ABC123XYZ"
    let issuedTo: String?               // Optional: Company name
    let issuedBy: String                // GeoGuard team member ID
    let issuedAt: Date
    let expiresAt: Date?                // Optional expiration
    let maxOrganizations: Int           // Usually 1, unless enterprise license
    
    var isUsed: Bool
    var usedAt: Date?
    var usedBy: String?                 // Tenant ID that used this license
    var organizationName: String?       // Company name that registered
    
    var isActive: Bool                  // Can be revoked by admin
    
    var notes: String?                  // Internal notes for GeoGuard team
    
    // Computed properties
    var isValid: Bool {
        guard isActive, !isUsed else { return false }
        
        // Check expiration
        if let expiresAt = expiresAt, expiresAt < Date() {
            return false
        }
        
        return true
    }
    
    // Firestore helpers
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "licenseKey": licenseKey,
            "issuedBy": issuedBy,
            "issuedAt": Timestamp(date: issuedAt),
            "maxOrganizations": maxOrganizations,
            "isUsed": isUsed,
            "isActive": isActive
        ]
        
        if let issuedTo = issuedTo {
            dict["issuedTo"] = issuedTo
        }
        
        if let expiresAt = expiresAt {
            dict["expiresAt"] = Timestamp(date: expiresAt)
        }
        
        if let usedAt = usedAt {
            dict["usedAt"] = Timestamp(date: usedAt)
        }
        
        if let usedBy = usedBy {
            dict["usedBy"] = usedBy
        }
        
        if let organizationName = organizationName {
            dict["organizationName"] = organizationName
        }
        
        if let notes = notes {
            dict["notes"] = notes
        }
        
        return dict
    }
}

// MARK: - License Format Examples
/*
 Format: GGUARD-YYYY-XXXXXXXXX
 
 Examples:
 - GGUARD-2026-ABC123XYZ  (Standard license)
 - GGUARD-2026-ENT456ABC  (Enterprise license)
 - GGUARD-2026-TRL789DEF  (Trial license)
 
 Components:
 - GGUARD: Product identifier
 - 2026: Year issued
 - XXXXXXXXX: Random alphanumeric (9 chars)
 */

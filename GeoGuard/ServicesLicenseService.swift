//
//  LicenseService.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-26.
//

import Foundation
import FirebaseFirestore

@MainActor
class LicenseService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Validate License (Used during organization registration)
    
    /// Validates a license key before allowing organization creation
    func validateLicense(key: String) async throws -> License {
        let normalizedKey = key.uppercased().trimmingCharacters(in: .whitespaces)
        
        // Query for license
        let snapshot = try await db.collection("licenses")
            .whereField("licenseKey", isEqualTo: normalizedKey)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw LicenseError.notFound
        }
        
        guard let license = try? document.data(as: License.self) else {
            throw LicenseError.invalidFormat
        }
        
        // Validate license status
        guard license.isActive else {
            throw LicenseError.revoked
        }
        
        guard !license.isUsed else {
            throw LicenseError.alreadyUsed
        }
        
        // Check expiration
        if let expiresAt = license.expiresAt, expiresAt < Date() {
            throw LicenseError.expired
        }
        
        return license
    }
    
    // MARK: - Mark License as Used
    
    /// Marks a license as used after successful organization creation
    func markLicenseAsUsed(
        licenseId: String,
        tenantId: String,
        organizationName: String
    ) async throws {
        try await db.collection("licenses").document(licenseId).updateData([
            "isUsed": true,
            "usedAt": FieldValue.serverTimestamp(),
            "usedBy": tenantId,
            "organizationName": organizationName
        ])
    }
    
    // MARK: - Generate License (GeoGuard Super Admin Only)
    
    /// Generates a new license key for a client
    /// This should only be called by GeoGuard super admins
    func generateLicense(
        issuedBy: String,
        issuedTo: String? = nil,
        expiresInDays: Int? = nil,
        notes: String? = nil
    ) async throws -> License {
        let licenseKey = generateLicenseKey()
        
        let expiresAt: Date? = if let days = expiresInDays {
            Calendar.current.date(byAdding: .day, value: days, to: Date())
        } else {
            nil
        }
        
        let license = License(
            licenseKey: licenseKey,
            issuedTo: issuedTo,
            issuedBy: issuedBy,
            issuedAt: Date(),
            expiresAt: expiresAt,
            maxOrganizations: 1,
            isUsed: false,
            usedAt: nil,
            usedBy: nil,
            organizationName: nil,
            isActive: true,
            notes: notes
        )
        
        // Save to Firestore
        let docRef = try await db.collection("licenses").addDocument(
            data: license.toDictionary()
        )
        
        // Return license with ID
        var savedLicense = license
        savedLicense.id = docRef.documentID
        
        return savedLicense
    }
    
    // MARK: - License Key Generation
    
    private func generateLicenseKey() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let random = generateRandomString(length: 9)
        return "GGUARD-\(year)-\(random)"
    }
    
    private func generateRandomString(length: Int) -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excludes confusing chars
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}

// MARK: - License Errors

enum LicenseError: LocalizedError {
    case notFound
    case alreadyUsed
    case expired
    case revoked
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Invalid license key. Please check the key and try again."
        case .alreadyUsed:
            return "This license key has already been used to create an organization."
        case .expired:
            return "This license key has expired. Please contact support for a new key."
        case .revoked:
            return "This license key has been revoked. Please contact support."
        case .invalidFormat:
            return "Invalid license key format."
        }
    }
}

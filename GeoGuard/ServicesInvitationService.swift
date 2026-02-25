//
//  InvitationService.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import Foundation
import Combine
import FirebaseFirestore

struct Invitation: Codable, Identifiable {
    @DocumentID var id: String?
    var tenantId: String
    var invitedBy: String  // User ID
    var invitationCode: String
    var email: String?  // Optional: specific email invited
    var role: UserRole
    var expiresAt: Date
    var isUsed: Bool
    var usedBy: String?  // User ID who used it
    var usedAt: Date?
    var createdAt: Date
}

@MainActor
class InvitationService: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Create Invitation
    
    func createInvitation(
        tenantId: String,
        invitedBy: String,
        email: String? = nil,
        role: UserRole = .fieldPersonnel,
        expiresInDays: Int = 7
    ) async throws -> Invitation {
        isLoading = true
        defer { isLoading = false }
        
        // Generate unique invitation code
        let invitationCode = generateInvitationCode()
        
        // Check if code already exists (very unlikely, but just in case)
        let existingCode = try await db.collection("invitations")
            .whereField("invitationCode", isEqualTo: invitationCode)
            .whereField("isUsed", isEqualTo: false)
            .getDocuments()
        
        if !existingCode.documents.isEmpty {
            // Recursive call to generate new code
            return try await createInvitation(
                tenantId: tenantId,
                invitedBy: invitedBy,
                email: email,
                role: role,
                expiresInDays: expiresInDays
            )
        }
        
        let invitation = Invitation(
            tenantId: tenantId,
            invitedBy: invitedBy,
            invitationCode: invitationCode,
            email: email,
            role: role,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresInDays * 24 * 60 * 60)),
            isUsed: false,
            createdAt: Date()
        )
        
        let docRef = try await db.collection("invitations").addDocument(data: [
            "tenantId": invitation.tenantId,
            "invitedBy": invitation.invitedBy,
            "invitationCode": invitation.invitationCode,
            "email": invitation.email as Any,
            "role": invitation.role.rawValue,
            "expiresAt": Timestamp(date: invitation.expiresAt),
            "isUsed": invitation.isUsed,
            "createdAt": Timestamp(date: invitation.createdAt)
        ])
        
        var createdInvitation = invitation
        createdInvitation.id = docRef.documentID
        
        return createdInvitation
    }
    
    // MARK: - Validate Invitation
    
    func validateInvitation(code: String, email: String? = nil) async throws -> Invitation {
        isLoading = true
        defer { isLoading = false }
        
        // Find invitation by code
        let snapshot = try await db.collection("invitations")
            .whereField("invitationCode", isEqualTo: code.uppercased())
            .whereField("isUsed", isEqualTo: false)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw InvitationError.invalidCode
        }
        
        let invitation = try document.data(as: Invitation.self)
        
        // Check if expired
        if invitation.expiresAt < Date() {
            throw InvitationError.expired
        }
        
        // Check if email matches (if specific email was invited)
        if let invitedEmail = invitation.email,
           let providedEmail = email,
           invitedEmail.lowercased() != providedEmail.lowercased() {
            throw InvitationError.emailMismatch
        }
        
        return invitation
    }
    
    // MARK: - Mark Invitation as Used
    
    func markAsUsed(invitationId: String, userId: String) async throws {
        try await db.collection("invitations").document(invitationId).updateData([
            "isUsed": true,
            "usedBy": userId,
            "usedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Get Invitations for Tenant
    
    func getInvitations(tenantId: String) async throws -> [Invitation] {
        let snapshot = try await db.collection("invitations")
            .whereField("tenantId", isEqualTo: tenantId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Invitation.self) }
    }
    
    // MARK: - Helper Methods
    
    private func generateInvitationCode() -> String {
        // Generate 8-character alphanumeric code (e.g., "ABC12XYZ")
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Removed ambiguous chars
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}

// MARK: - Errors

enum InvitationError: LocalizedError {
    case invalidCode
    case expired
    case emailMismatch
    case alreadyUsed
    
    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Invalid invitation code."
        case .expired:
            return "This invitation has expired."
        case .emailMismatch:
            return "This invitation was sent to a different email address."
        case .alreadyUsed:
            return "This invitation has already been used."
        }
    }
}

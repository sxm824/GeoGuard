//
//  User.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var tenantId: String  // Links user to their organization
    var fullName: String
    var initials: String
    var email: String
    var phone: String
    var address: String
    var city: String
    var country: String
    var vehicle: String  // Transportation type (for safety planning)
    var role: UserRole
    var isActive: Bool
    var createdAt: Date
    var lastLoginAt: Date?
    
    // Safety & Emergency
    var emergencyContact: String?  // Emergency contact name
    var emergencyPhone: String?    // Emergency contact phone
    var bloodType: String?         // For medical emergencies
    var medicalNotes: String?      // Allergies, conditions, etc.
    
    // For invitation flow
    var invitedBy: String?  // User ID of who invited them
    var invitationCode: String?
}

extension User {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "tenantId": tenantId,
            "fullName": fullName,
            "initials": initials,
            "email": email,
            "phone": phone,
            "address": address,
            "city": city,
            "country": country,
            "vehicle": vehicle,
            "role": role.rawValue,
            "isActive": isActive,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let lastLoginAt = lastLoginAt {
            dict["lastLoginAt"] = Timestamp(date: lastLoginAt)
        }
        
        if let emergencyContact = emergencyContact {
            dict["emergencyContact"] = emergencyContact
        }
        
        if let emergencyPhone = emergencyPhone {
            dict["emergencyPhone"] = emergencyPhone
        }
        
        if let bloodType = bloodType {
            dict["bloodType"] = bloodType
        }
        
        if let medicalNotes = medicalNotes {
            dict["medicalNotes"] = medicalNotes
        }
        
        if let invitedBy = invitedBy {
            dict["invitedBy"] = invitedBy
        }
        
        if let invitationCode = invitationCode {
            dict["invitationCode"] = invitationCode
        }
        
        return dict
    }
}

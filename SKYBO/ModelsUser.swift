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
    
    // Multi-role support: A user can have multiple roles
    // Example: ["admin", "field_personnel"] = Coordinator who also goes to field
    var roles: [UserRole]
    
    // Legacy single role support (for backward compatibility)
    var role: UserRole {
        roles.first ?? .fieldPersonnel
    }
    
    var isActive: Bool
    var createdAt: Date
    var lastLoginAt: Date?
    
    // Safety & Emergency
    var emergencyContact: String?  // Emergency contact name
    var emergencyPhone: String?    // Emergency contact phone
    var emergencyContactRelation: String?  // Relationship to emergency contact
    var bloodType: String?         // For medical emergencies
    var medicalNotes: String?      // Allergies, conditions, etc.
    
    // For invitation flow
    var invitedBy: String?  // User ID of who invited them
    var invitationCode: String?
    
    // MARK: - Role Checking Methods
    
    /// Check if user has a specific role
    func hasRole(_ role: UserRole) -> Bool {
        return roles.contains(role)
    }
    
    /// Check if user has ANY of the specified roles
    func hasAnyRole(_ roles: [UserRole]) -> Bool {
        return !Set(self.roles).isDisjoint(with: Set(roles))
    }
    
    /// Check if user has ALL of the specified roles
    func hasAllRoles(_ roles: [UserRole]) -> Bool {
        return Set(roles).isSubset(of: Set(self.roles))
    }
    
    /// Get the user's primary role (for display purposes)
    var primaryRole: UserRole {
        // Priority order: superAdmin > admin > manager > fieldPersonnel
        if roles.contains(.superAdmin) { return .superAdmin }
        if roles.contains(.admin) { return .admin }
        if roles.contains(.manager) { return .manager }
        return .fieldPersonnel
    }
    
    /// Check if user should be tracked (has field personnel role)
    var shouldBeTracked: Bool {
        return hasRole(.fieldPersonnel)
    }
    
    /// Check if user can monitor others (has admin or manager role)
    var canMonitorOthers: Bool {
        return hasAnyRole([.admin, .manager, .superAdmin])
    }
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
            "roles": roles.map { $0.rawValue },  // Store as array of strings
            "role": role.rawValue,  // Keep single role for backward compatibility
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
        
        if let emergencyContactRelation = emergencyContactRelation {
            dict["emergencyContactRelation"] = emergencyContactRelation
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
    
    // MARK: - Firestore Decoding Helper
    
    /// Custom initializer for backward compatibility with single-role documents
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        tenantId = try container.decode(String.self, forKey: .tenantId)
        fullName = try container.decode(String.self, forKey: .fullName)
        initials = try container.decode(String.self, forKey: .initials)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decode(String.self, forKey: .phone)
        address = try container.decode(String.self, forKey: .address)
        city = try container.decode(String.self, forKey: .city)
        country = try container.decode(String.self, forKey: .country)
        vehicle = try container.decode(String.self, forKey: .vehicle)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastLoginAt = try container.decodeIfPresent(Date.self, forKey: .lastLoginAt)
        
        // Try to decode roles array first, fallback to single role
        print("🔍 User.init - Starting role decoding...")
        
        // First, try to decode as UserRole array
        if let rolesArray = try? container.decode([UserRole].self, forKey: .roles), !rolesArray.isEmpty {
            roles = rolesArray
            print("🟢 User.init - Successfully decoded roles array: \(rolesArray.map { $0.rawValue })")
        } else {
            print("⚠️ User.init - Failed to decode roles as [UserRole], checking alternatives...")
            
            // Try to see what's actually there
            if let rawRoles = try? container.decode([String].self, forKey: .roles) {
                print("   Raw roles in Firestore: \(rawRoles)")
                // Try to convert strings to UserRole
                let convertedRoles = rawRoles.compactMap { UserRole(rawValue: $0) }
                if !convertedRoles.isEmpty {
                    roles = convertedRoles
                    print("🟡 User.init - Converted string array to roles: \(convertedRoles.map { $0.rawValue })")
                    return // Exit early since we got roles
                } else {
                    print("❌ User.init - String array exists but couldn't convert to UserRole")
                }
            }
            
            // Fall back to single role field
            if let singleRole = try? container.decode(UserRole.self, forKey: .role) {
                roles = [singleRole]
                print("🟡 User.init - Using single 'role' field (backward compat): \(singleRole.rawValue)")
            } else {
                // Last resort default
                roles = [.fieldPersonnel]
                print("🔴 User.init - No roles found anywhere, using default: [fieldPersonnel]")
            }
        }
        
        emergencyContact = try container.decodeIfPresent(String.self, forKey: .emergencyContact)
        emergencyPhone = try container.decodeIfPresent(String.self, forKey: .emergencyPhone)
        emergencyContactRelation = try container.decodeIfPresent(String.self, forKey: .emergencyContactRelation)
        bloodType = try container.decodeIfPresent(String.self, forKey: .bloodType)
        medicalNotes = try container.decodeIfPresent(String.self, forKey: .medicalNotes)
        invitedBy = try container.decodeIfPresent(String.self, forKey: .invitedBy)
        invitationCode = try container.decodeIfPresent(String.self, forKey: .invitationCode)
    }
    
    /// Custom encoder implementation
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(_id, forKey: .id)
        try container.encode(tenantId, forKey: .tenantId)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(initials, forKey: .initials)
        try container.encode(email, forKey: .email)
        try container.encode(phone, forKey: .phone)
        try container.encode(address, forKey: .address)
        try container.encode(city, forKey: .city)
        try container.encode(country, forKey: .country)
        try container.encode(vehicle, forKey: .vehicle)
        try container.encode(roles, forKey: .roles)
        try container.encode(role, forKey: .role)  // Keep single role for backward compatibility
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastLoginAt, forKey: .lastLoginAt)
        try container.encodeIfPresent(emergencyContact, forKey: .emergencyContact)
        try container.encodeIfPresent(emergencyPhone, forKey: .emergencyPhone)
        try container.encodeIfPresent(emergencyContactRelation, forKey: .emergencyContactRelation)
        try container.encodeIfPresent(bloodType, forKey: .bloodType)
        try container.encodeIfPresent(medicalNotes, forKey: .medicalNotes)
        try container.encodeIfPresent(invitedBy, forKey: .invitedBy)
        try container.encodeIfPresent(invitationCode, forKey: .invitationCode)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, tenantId, fullName, initials, email, phone, address, city, country, vehicle
        case roles, role, isActive, createdAt, lastLoginAt
        case emergencyContact, emergencyPhone, emergencyContactRelation
        case bloodType, medicalNotes, invitedBy, invitationCode
    }
}

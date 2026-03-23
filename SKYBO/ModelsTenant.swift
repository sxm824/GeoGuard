//
//  Tenant.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import Foundation
import FirebaseFirestore

struct Tenant: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var domain: String? // Optional: for domain-based matching (e.g., "acme.com")
    var adminUserId: String
    var subscription: SubscriptionTier
    var isActive: Bool
    var maxUsers: Int
    var createdAt: Date
    var settings: TenantSettings?
    
    enum SubscriptionTier: String, Codable {
        case trial = "trial"
        case basic = "basic"
        case professional = "professional"
        case enterprise = "enterprise"
    }
}

struct TenantSettings: Codable {
    var allowUserInvites: Bool = true
    var requireInvitationCode: Bool = true
    var logoURL: String?
    var primaryColor: String?
    var timeZone: String = "Europe/London"
}

// Extension for Firestore conversion
extension Tenant {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "adminUserId": adminUserId,
            "subscription": subscription.rawValue,
            "isActive": isActive,
            "maxUsers": maxUsers,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let domain = domain {
            dict["domain"] = domain
        }
        
        if let settings = settings,
           let settingsData = try? JSONEncoder().encode(settings),
           let settingsDict = try? JSONSerialization.jsonObject(with: settingsData) as? [String: Any] {
            dict["settings"] = settingsDict
        }
        
        return dict
    }
}

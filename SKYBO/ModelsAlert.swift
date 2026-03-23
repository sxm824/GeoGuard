//
//  Alert.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-01.
//

import Foundation
import FirebaseFirestore

struct Alert: Identifiable, Codable {
    @DocumentID var id: String?
    let tenantId: String
    let senderId: String
    let senderName: String
    let recipientIds: [String] // Empty array means all users in tenant
    let title: String
    let message: String
    let priority: AlertPriority
    let type: AlertType
    let requiresResponse: Bool
    let quickResponses: [String]
    let allowCustomResponse: Bool
    let createdAt: Date
    let expiresAt: Date?
    let isActive: Bool
    
    enum AlertPriority: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "info.circle.fill"
            case .medium: return "exclamationmark.circle.fill"
            case .high: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }
    
    enum AlertType: String, Codable {
        case safetyCheckin = "safety_checkin"
        case emergency = "emergency"
        case announcement = "announcement"
        case task = "task"
        
        var displayName: String {
            switch self {
            case .safetyCheckin: return "Safety Check-In"
            case .emergency: return "Emergency"
            case .announcement: return "Announcement"
            case .task: return "Task"
            }
        }
        
        var icon: String {
            switch self {
            case .safetyCheckin: return "checkmark.shield.fill"
            case .emergency: return "exclamationmark.triangle.fill"
            case .announcement: return "megaphone.fill"
            case .task: return "list.clipboard.fill"
            }
        }
    }
    
    // Check if this alert is sent to a specific user
    func isSentTo(userId: String) -> Bool {
        return recipientIds.isEmpty || recipientIds.contains(userId)
    }
    
    // Check if alert is expired
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

struct AlertResponse: Identifiable, Codable {
    @DocumentID var id: String?
    let alertId: String
    let userId: String
    let userName: String
    let tenantId: String
    let responseType: ResponseType
    let responseText: String
    let latitude: Double?
    let longitude: Double?
    let timestamp: Date
    var readByAdmin: Bool
    
    enum ResponseType: String, Codable {
        case quick = "quick"
        case custom = "custom"
    }
}

struct UserAlertStatus: Identifiable, Codable {
    @DocumentID var id: String? // Format: alertId_userId
    let alertId: String
    let userId: String
    let tenantId: String
    var delivered: Bool
    var opened: Bool
    var respondedAt: Date?
    var dismissed: Bool
    
    // Computed property to check if user has responded
    var hasResponded: Bool {
        return respondedAt != nil
    }
}

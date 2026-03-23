//
//  SOSAlert.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//

import Foundation
import FirebaseFirestore

struct SOSAlert: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var tenantId: String
    var userName: String
    var userEmail: String
    var status: SOSStatus
    var priority: Priority = .critical
    var triggeredAt: Date
    var resolvedAt: Date?
    var resolvedBy: String?
    var latitude: Double
    var longitude: Double
    var address: String?
    var isSilentMode: Bool // Silent SOS for covert situations
    var notes: String?
    var acknowledgements: [Acknowledgement]
    
    enum SOSStatus: String, Codable {
        case active = "active"
        case acknowledged = "acknowledged"
        case responding = "responding"
        case resolved = "resolved"
        case falseAlarm = "false_alarm"
        
        var displayName: String {
            switch self {
            case .active: return "Active Emergency"
            case .acknowledged: return "Acknowledged"
            case .responding: return "Help on the Way"
            case .resolved: return "Resolved"
            case .falseAlarm: return "False Alarm"
            }
        }
        
        var color: String {
            switch self {
            case .active: return "red"
            case .acknowledged: return "orange"
            case .responding: return "blue"
            case .resolved: return "green"
            case .falseAlarm: return "gray"
            }
        }
    }
    
    enum Priority: String, Codable {
        case critical = "critical"
        
        var displayName: String { "CRITICAL" }
    }
    
    struct Acknowledgement: Codable, Identifiable {
        var id: String { "\(adminId)-\(timestamp.timeIntervalSince1970)" }
        var adminId: String
        var adminName: String
        var timestamp: Date
        var action: String // "acknowledged", "responding", "resolved"
    }
    
    var isActive: Bool {
        status == .active || status == .acknowledged || status == .responding
    }
    
    var durationMinutes: Int? {
        guard let resolvedAt = resolvedAt else { return nil }
        return Int(resolvedAt.timeIntervalSince(triggeredAt) / 60)
    }
}

// MARK: - Safety Check-in Model

struct SafetyCheckIn: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var tenantId: String
    var userName: String
    var checkInTime: Date
    var nextCheckInDue: Date
    var status: CheckInStatus
    var latitude: Double
    var longitude: Double
    var address: String?
    var notes: String?
    var isSafe: Bool
    
    enum CheckInStatus: String, Codable {
        case safe = "safe"
        case needsHelp = "needs_help"
        case overdue = "overdue"
        case missed = "missed"
        
        var displayName: String {
            switch self {
            case .safe: return "Safe"
            case .needsHelp: return "Needs Help"
            case .overdue: return "Overdue"
            case .missed: return "Missed"
            }
        }
        
        var icon: String {
            switch self {
            case .safe: return "checkmark.shield.fill"
            case .needsHelp: return "exclamationmark.triangle.fill"
            case .overdue: return "clock.badge.exclamationmark"
            case .missed: return "xmark.shield"
            }
        }
    }
}

// MARK: - Incident Report Model

struct IncidentReport: Identifiable, Codable {
    @DocumentID var id: String?
    var reporterId: String
    var reporterName: String
    var tenantId: String
    var title: String
    var description: String
    var incidentType: IncidentType
    var severity: Severity
    var reportedAt: Date
    var incidentOccurredAt: Date
    var latitude: Double
    var longitude: Double
    var address: String?
    var status: ReportStatus
    var reviewedBy: String?
    var reviewedAt: Date?
    var reviewNotes: String?
    var affectedPersonnel: [String] // User IDs
    
    enum IncidentType: String, Codable, CaseIterable {
        case security = "security"
        case medical = "medical"
        case accident = "accident"
        case threat = "threat"
        case harassment = "harassment"
        case theft = "theft"
        case naturalDisaster = "natural_disaster"
        case politicalUnrest = "political_unrest"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .security: return "Security Incident"
            case .medical: return "Medical Emergency"
            case .accident: return "Accident"
            case .threat: return "Threat/Intimidation"
            case .harassment: return "Harassment"
            case .theft: return "Theft/Robbery"
            case .naturalDisaster: return "Natural Disaster"
            case .politicalUnrest: return "Political Unrest"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .security: return "shield.slash.fill"
            case .medical: return "cross.circle.fill"
            case .accident: return "car.fill"
            case .threat: return "exclamationmark.triangle.fill"
            case .harassment: return "person.2.slash"
            case .theft: return "briefcase.fill"
            case .naturalDisaster: return "cloud.bolt.rain.fill"
            case .politicalUnrest: return "flag.fill"
            case .other: return "doc.text.fill"
            }
        }
    }
    
    enum Severity: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        var displayName: String {
            rawValue.capitalized
        }
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
    
    enum ReportStatus: String, Codable {
        case pending = "pending"
        case underReview = "under_review"
        case resolved = "resolved"
        case closed = "closed"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending Review"
            case .underReview: return "Under Review"
            case .resolved: return "Resolved"
            case .closed: return "Closed"
            }
        }
    }
}

// MARK: - Geofence Breach Model

struct GeofenceBreach: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var userName: String
    var tenantId: String
    var geofenceId: String
    var geofenceName: String
    var breachType: BreachType
    var breachTime: Date
    var latitude: Double
    var longitude: Double
    var notificationSent: Bool
    var acknowledged: Bool
    var acknowledgedBy: String?
    var acknowledgedAt: Date?
    
    enum BreachType: String, Codable {
        case entry = "entry"
        case exit = "exit"
        case unauthorized = "unauthorized"
        
        var displayName: String {
            switch self {
            case .entry: return "Entered Zone"
            case .exit: return "Exited Zone"
            case .unauthorized: return "Unauthorized Access"
            }
        }
        
        var icon: String {
            switch self {
            case .entry: return "arrow.down.circle.fill"
            case .exit: return "arrow.up.circle.fill"
            case .unauthorized: return "exclamationmark.shield.fill"
            }
        }
    }
}

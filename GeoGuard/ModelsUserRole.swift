//
//  UserRole.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import Foundation

enum UserRole: String, Codable, CaseIterable {
    case superAdmin = "super_admin"      // GeoGuard platform team only
    case admin = "admin"                  // Organization administrator
    case manager = "manager"              // Operations manager / Coordinator
    case fieldPersonnel = "field_personnel"  // Field personnel being tracked
    
    var displayName: String {
        switch self {
        case .superAdmin: return "Super Admin"
        case .admin: return "Administrator"
        case .manager: return "Manager"
        case .fieldPersonnel: return "Field Personnel"
        }
    }
    
    var permissions: [Permission] {
        switch self {
        case .superAdmin:
            return Permission.allCases
        case .admin:
            return [.viewUsers, .manageUsers, .viewGeofences, .manageGeofences, 
                    .viewLocations, .manageLocations, .viewReports, .inviteUsers,
                    .sendAlerts, .viewEmergencyInfo]
        case .manager:
            return [.viewUsers, .viewGeofences, .manageGeofences, 
                    .viewLocations, .viewReports, .sendAlerts, .viewEmergencyInfo]
        case .fieldPersonnel:
            return [.viewGeofences, .shareLocation, .sendEmergencyAlert]
        }
    }
}

enum Permission: String, CaseIterable {
    case viewUsers = "view_users"
    case manageUsers = "manage_users"
    case viewGeofences = "view_geofences"
    case manageGeofences = "manage_geofences"
    case viewLocations = "view_locations"
    case manageLocations = "manage_locations"
    case viewReports = "view_reports"
    case inviteUsers = "invite_users"
    case manageTenant = "manage_tenant"
    case shareLocation = "share_location"
    case sendEmergencyAlert = "send_emergency_alert"
    case sendAlerts = "send_alerts"
    case viewEmergencyInfo = "view_emergency_info"
}

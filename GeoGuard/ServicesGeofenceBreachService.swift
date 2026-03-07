//
//  GeofenceBreachService.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//

import Foundation
import Combine
import FirebaseFirestore
import CoreLocation

@MainActor
class GeofenceBreachService: ObservableObject {
    @Published var breaches: [GeofenceBreach] = []
    @Published var unacknowledgedBreaches: [GeofenceBreach] = []
    
    private let db = Firestore.firestore()
    private var breachListener: ListenerRegistration?
    
    // MARK: - Record Breach
    
    func recordBreach(
        userId: String,
        userName: String,
        tenantId: String,
        geofenceId: String,
        geofenceName: String,
        breachType: GeofenceBreach.BreachType,
        location: CLLocation
    ) async throws {
        
        // Check if breach already recorded in last 5 minutes (avoid duplicates)
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        let recentQuery = try await db.collection("geofence_breaches")
            .whereField("userId", isEqualTo: userId)
            .whereField("geofenceId", isEqualTo: geofenceId)
            .whereField("breachType", isEqualTo: breachType.rawValue)
            .whereField("breachTime", isGreaterThan: Timestamp(date: fiveMinutesAgo))
            .limit(to: 1)
            .getDocuments()
        
        if !recentQuery.documents.isEmpty {
            print("⚠️ Duplicate breach detected, skipping")
            return
        }
        
        let breach = GeofenceBreach(
            userId: userId,
            userName: userName,
            tenantId: tenantId,
            geofenceId: geofenceId,
            geofenceName: geofenceName,
            breachType: breachType,
            breachTime: Date(),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            notificationSent: false,
            acknowledged: false
        )
        
        let docRef = try db.collection("geofence_breaches").addDocument(from: breach)
        
        // Mark notification as sent
        try await db.collection("geofence_breaches").document(docRef.documentID).updateData([
            "notificationSent": true
        ])
        
        // Create alert for admins
        try await createBreachAlert(breach: breach)
        
        print("✅ Geofence breach recorded: \(geofenceName) - \(breachType.rawValue)")
    }
    
    // MARK: - Acknowledge Breach
    
    func acknowledgeBreach(breachId: String, adminId: String) async throws {
        try await db.collection("geofence_breaches").document(breachId).updateData([
            "acknowledged": true,
            "acknowledgedBy": adminId,
            "acknowledgedAt": Timestamp(date: Date())
        ])
        
        print("✅ Breach acknowledged: \(breachId)")
    }
    
    // MARK: - Listen to Breaches
    
    func startListeningToBreaches(tenantId: String) {
        breachListener?.remove()
        
        guard !tenantId.isEmpty else { return }
        
        breachListener = db.collection("geofence_breaches")
            .whereField("tenantId", isEqualTo: tenantId)
            .order(by: "breachTime", descending: true)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to breaches: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    let loadedBreaches = documents.compactMap { doc in
                        try? doc.data(as: GeofenceBreach.self)
                    }
                    
                    self.breaches = loadedBreaches
                    self.unacknowledgedBreaches = loadedBreaches.filter { !$0.acknowledged }
                    
                    print("✅ Loaded \(loadedBreaches.count) geofence breaches")
                }
            }
    }
    
    func stopListening() {
        breachListener?.remove()
        breachListener = nil
    }
    
    // MARK: - Get Breach History
    
    func getBreachesByGeofence(geofenceId: String, limit: Int = 50) async throws -> [GeofenceBreach] {
        let snapshot = try await db.collection("geofence_breaches")
            .whereField("geofenceId", isEqualTo: geofenceId)
            .order(by: "breachTime", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: GeofenceBreach.self) }
    }
    
    func getBreachesByUser(userId: String, limit: Int = 50) async throws -> [GeofenceBreach] {
        let snapshot = try await db.collection("geofence_breaches")
            .whereField("userId", isEqualTo: userId)
            .order(by: "breachTime", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: GeofenceBreach.self) }
    }
    
    // MARK: - Create Breach Alert
    
    private func createBreachAlert(breach: GeofenceBreach) async throws {
        let message: String
        let priority: Alert.AlertPriority
        
        switch breach.breachType {
        case .entry:
            message = "\(breach.userName) has entered \(breach.geofenceName)"
            priority = .medium
        case .exit:
            message = "\(breach.userName) has exited \(breach.geofenceName)"
            priority = .medium
        case .unauthorized:
            message = "🚨 UNAUTHORIZED ACCESS: \(breach.userName) entered restricted area \(breach.geofenceName)"
            priority = .critical
        }
        
        // Unauthorized breaches expire after 1 hour, others after 24 hours
        let expirationTime: TimeInterval = breach.breachType == .unauthorized ? 3600 : 86400
        let expiresAt = Date().addingTimeInterval(expirationTime)
        
        let alert = Alert(
            tenantId: breach.tenantId,
            senderId: "system",
            senderName: "Geofence System",
            recipientIds: [], // Empty array means all users in tenant
            title: "Geofence Alert: \(breach.geofenceName)",
            message: message,
            priority: priority,
            type: breach.breachType == .unauthorized ? .emergency : .announcement,
            requiresResponse: breach.breachType == .unauthorized,
            quickResponses: ["Acknowledged", "Investigating", "Authorized", "Contact personnel"],
            allowCustomResponse: true,
            createdAt: Date(),
            expiresAt: expiresAt,
            isActive: true
        )
        
        try db.collection("alerts").addDocument(from: alert)
    }
}

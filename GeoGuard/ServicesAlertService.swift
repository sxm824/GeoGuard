//
//  AlertService.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-01.
//

import Foundation
import FirebaseFirestore
import CoreLocation
import Combine

@MainActor
class AlertService: ObservableObject {
    @Published var alerts: [Alert] = []
    @Published var alertStatuses: [String: UserAlertStatus] = [:] // alertId -> status
    @Published var unreadCount: Int = 0
    @Published var totalResponseCount: Int = 0  // ✅ Total responses across all time
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var alertsListener: ListenerRegistration?
    private var statusListener: ListenerRegistration?
    
    // MARK: - User Functions (Field Personnel)
    
    /// Start listening for alerts sent to this user
    func startListeningForUserAlerts(userId: String, tenantId: String) {
        print("👂 Starting to listen for alerts for user: \(userId)")
        
        // Listen for all active alerts in the tenant
        alertsListener = db.collection("alerts")
            .whereField("tenantId", isEqualTo: tenantId)
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening for alerts: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No alerts found")
                    return
                }
                
                // Parse alerts
                let allAlerts = documents.compactMap { doc -> Alert? in
                    try? doc.data(as: Alert.self)
                }
                
                // Filter alerts that are sent to this user
                self.alerts = allAlerts.filter { $0.isSentTo(userId: userId) }
                
                print("✅ Loaded \(self.alerts.count) alerts for user")
                
                // Create alert status entries if they don't exist
                Task {
                    await self.ensureAlertStatusExists(userId: userId, tenantId: tenantId)
                }
            }
        
        // Listen for alert statuses
        statusListener = db.collection("user_alert_status")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening for alert statuses: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Parse statuses into dictionary
                var statuses: [String: UserAlertStatus] = [:]
                for doc in documents {
                    if let status = try? doc.data(as: UserAlertStatus.self) {
                        statuses[status.alertId] = status
                    }
                }
                
                self.alertStatuses = statuses
                
                // Calculate unread count (not opened and not responded)
                self.unreadCount = statuses.values.filter { !$0.opened && !$0.hasResponded }.count
                
                // Calculate total response count (all time)
                self.totalResponseCount = statuses.values.filter { $0.hasResponded }.count
                
                print("✅ Loaded \(statuses.count) alert statuses, \(self.unreadCount) unread, \(self.totalResponseCount) total responses")
            }
    }
    
    /// Mark an alert as opened
    func markAlertAsOpened(alertId: String, userId: String) async {
        let statusId = "\(alertId)_\(userId)"
        
        do {
            try await db.collection("user_alert_status")
                .document(statusId)
                .updateData([
                    "opened": true,
                    "delivered": true
                ])
            print("✅ Marked alert \(alertId) as opened")
        } catch {
            print("❌ Error marking alert as opened: \(error.localizedDescription)")
        }
    }
    
    /// Submit a response to an alert
    func submitResponse(
        alertId: String,
        userId: String,
        userName: String,
        tenantId: String,
        responseText: String,
        responseType: AlertResponse.ResponseType,
        location: CLLocationCoordinate2D?
    ) async throws {
        let response = AlertResponse(
            alertId: alertId,
            userId: userId,
            userName: userName,
            tenantId: tenantId,
            responseType: responseType,
            responseText: responseText,
            latitude: location?.latitude,
            longitude: location?.longitude,
            timestamp: Date(),
            readByAdmin: false
        )
        
        // Save response to Firestore
        let docRef = try db.collection("alert_responses").addDocument(from: response)
        print("✅ Response saved with ID: \(docRef.documentID)")
        
        // Update alert status to mark as responded
        let statusId = "\(alertId)_\(userId)"
        try await db.collection("user_alert_status")
            .document(statusId)
            .updateData([
                "respondedAt": Timestamp(date: Date()),
                "opened": true
            ])
        
        print("✅ Alert status updated for alert: \(alertId)")
    }
    
    /// Dismiss an alert without responding
    func dismissAlert(alertId: String, userId: String) async {
        let statusId = "\(alertId)_\(userId)"
        
        do {
            try await db.collection("user_alert_status")
                .document(statusId)
                .updateData([
                    "dismissed": true,
                    "opened": true
                ])
            print("✅ Alert \(alertId) dismissed")
        } catch {
            print("❌ Error dismissing alert: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Functions
    
    /// Ensure alert status document exists for each alert
    private func ensureAlertStatusExists(userId: String, tenantId: String) async {
        for alert in alerts {
            guard let alertId = alert.id else { continue }
            
            let statusId = "\(alertId)_\(userId)"
            
            // Check if status already exists
            if alertStatuses[alertId] != nil {
                continue
            }
            
            // Create new status
            let status = UserAlertStatus(
                id: statusId,
                alertId: alertId,
                userId: userId,
                tenantId: tenantId,
                delivered: true,
                opened: false,
                respondedAt: nil,
                dismissed: false
            )
            
            do {
                try db.collection("user_alert_status")
                    .document(statusId)
                    .setData(from: status)
                print("✅ Created alert status for alert: \(alertId)")
            } catch {
                print("❌ Error creating alert status: \(error.localizedDescription)")
            }
        }
    }
    
    /// Get status for a specific alert
    func getStatus(for alertId: String) -> UserAlertStatus? {
        return alertStatuses[alertId]
    }
    
    /// Check if user has responded to an alert
    func hasResponded(to alertId: String) -> Bool {
        return alertStatuses[alertId]?.hasResponded ?? false
    }
    
    /// Stop listening to Firestore
    func stopListening() {
        alertsListener?.remove()
        statusListener?.remove()
        print("🛑 Stopped listening for alerts")
    }
    
    deinit {
        alertsListener?.remove()
        statusListener?.remove()
    }
}

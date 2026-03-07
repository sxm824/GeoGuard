//
//  SOSService.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//

import Foundation
import FirebaseFirestore
import CoreLocation
import Combine

@MainActor
class SOSService: ObservableObject {
    @Published var activeSOSAlerts: [SOSAlert] = []
    @Published var isSOSActive = false
    @Published var currentSOSAlert: SOSAlert?
    
    private let db = Firestore.firestore()
    private var sosListener: ListenerRegistration?
    
    // MARK: - Trigger SOS
    
    func triggerSOS(
        userId: String,
        userName: String,
        userEmail: String,
        tenantId: String,
        location: CLLocation,
        address: String?,
        isSilentMode: Bool = false
    ) async throws -> SOSAlert {
        
        let sosAlert = SOSAlert(
            userId: userId,
            tenantId: tenantId,
            userName: userName,
            userEmail: userEmail,
            status: .active,
            triggeredAt: Date(),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            address: address,
            isSilentMode: isSilentMode,
            acknowledgements: []
        )
        
        let docRef = try db.collection("sos_alerts").addDocument(from: sosAlert)
        
        // Create high-priority alert for all admins
        try await createSOSAlert(sosAlert: sosAlert, sosId: docRef.documentID)
        
        // Update user status
        try await db.collection("users").document(userId).updateData([
            "inEmergency": true,
            "lastSOSTime": Timestamp(date: Date())
        ])
        
        print("✅ SOS triggered successfully: \(docRef.documentID)")
        
        var createdAlert = sosAlert
        createdAlert.id = docRef.documentID
        
        self.isSOSActive = true
        self.currentSOSAlert = createdAlert
        
        return createdAlert
    }
    
    // MARK: - Cancel SOS (False Alarm)
    
    func cancelSOS(sosId: String, userId: String) async throws {
        try await db.collection("sos_alerts").document(sosId).updateData([
            "status": SOSAlert.SOSStatus.falseAlarm.rawValue,
            "resolvedAt": Timestamp(date: Date()),
            "resolvedBy": userId,
            "notes": "Cancelled by user - false alarm"
        ])
        
        // Update user status
        try await db.collection("users").document(userId).updateData([
            "inEmergency": false
        ])
        
        self.isSOSActive = false
        self.currentSOSAlert = nil
        
        print("✅ SOS cancelled: \(sosId)")
    }
    
    // MARK: - Admin Actions
    
    func acknowledgeSOS(sosId: String, adminId: String, adminName: String) async throws {
        let acknowledgement = SOSAlert.Acknowledgement(
            adminId: adminId,
            adminName: adminName,
            timestamp: Date(),
            action: "acknowledged"
        )
        
        try await db.collection("sos_alerts").document(sosId).updateData([
            "status": SOSAlert.SOSStatus.acknowledged.rawValue,
            "acknowledgements": FieldValue.arrayUnion([
                [
                    "adminId": acknowledgement.adminId,
                    "adminName": acknowledgement.adminName,
                    "timestamp": Timestamp(date: acknowledgement.timestamp),
                    "action": acknowledgement.action
                ]
            ])
        ])
        
        print("✅ SOS acknowledged by admin: \(adminName)")
    }
    
    func updateSOSStatus(sosId: String, status: SOSAlert.SOSStatus, adminId: String, adminName: String, notes: String? = nil) async throws {
        let acknowledgement = SOSAlert.Acknowledgement(
            adminId: adminId,
            adminName: adminName,
            timestamp: Date(),
            action: status.rawValue
        )
        
        var updateData: [String: Any] = [
            "status": status.rawValue,
            "acknowledgements": FieldValue.arrayUnion([
                [
                    "adminId": acknowledgement.adminId,
                    "adminName": acknowledgement.adminName,
                    "timestamp": Timestamp(date: acknowledgement.timestamp),
                    "action": acknowledgement.action
                ]
            ])
        ]
        
        if status == .resolved {
            updateData["resolvedAt"] = Timestamp(date: Date())
            updateData["resolvedBy"] = adminId
        }
        
        if let notes = notes {
            updateData["notes"] = notes
        }
        
        try await db.collection("sos_alerts").document(sosId).updateData(updateData)
        
        // If resolved, update user status
        if status == .resolved {
            if let sosAlert = activeSOSAlerts.first(where: { $0.id == sosId }) {
                try await db.collection("users").document(sosAlert.userId).updateData([
                    "inEmergency": false
                ])
            }
        }
        
        print("✅ SOS status updated to: \(status.rawValue)")
    }
    
    // MARK: - Listen to Active SOS Alerts
    
    func startListeningToSOSAlerts(tenantId: String) {
        sosListener?.remove()
        
        guard !tenantId.isEmpty else { return }
        
        sosListener = db.collection("sos_alerts")
            .whereField("tenantId", isEqualTo: tenantId)
            .whereField("status", in: [
                SOSAlert.SOSStatus.active.rawValue,
                SOSAlert.SOSStatus.acknowledged.rawValue,
                SOSAlert.SOSStatus.responding.rawValue
            ])
            .order(by: "triggeredAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to SOS alerts: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    self.activeSOSAlerts = documents.compactMap { doc in
                        try? doc.data(as: SOSAlert.self)
                    }
                    
                    print("✅ Active SOS alerts: \(self.activeSOSAlerts.count)")
                }
            }
    }
    
    func stopListening() {
        sosListener?.remove()
        sosListener = nil
    }
    
    // MARK: - Get SOS History
    
    func getSOSHistory(tenantId: String, limit: Int = 50) async throws -> [SOSAlert] {
        let snapshot = try await db.collection("sos_alerts")
            .whereField("tenantId", isEqualTo: tenantId)
            .order(by: "triggeredAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: SOSAlert.self)
        }
    }
    
    // MARK: - Create Alert for Admins
    
    private func createSOSAlert(sosAlert: SOSAlert, sosId: String) async throws {
        let alert = Alert(
            tenantId: sosAlert.tenantId,
            senderId: "system",
            senderName: "SOS System",
            recipientIds: [], // Empty array means all users in tenant
            title: sosAlert.isSilentMode ? "Silent Emergency Alert" : "🚨 EMERGENCY SOS",
            message: "Emergency SOS triggered by \(sosAlert.userName) at \(sosAlert.address ?? "Unknown location")",
            priority: .critical,
            type: .emergency,
            requiresResponse: true,
            quickResponses: ["Acknowledged", "Responding", "Need more info"],
            allowCustomResponse: true,
            createdAt: Date(),
            expiresAt: nil, // SOS alerts don't expire
            isActive: true
        )
        
        try db.collection("alerts").addDocument(from: alert)
    }
}

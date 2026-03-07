//
//  SafetyCheckInService.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//

import Foundation
import Combine
import FirebaseFirestore
import CoreLocation
import UserNotifications

@MainActor
class SafetyCheckInService: ObservableObject {
    @Published var checkInInterval: TimeInterval = 4 * 3600 // 4 hours default
    @Published var lastCheckIn: SafetyCheckIn?
    @Published var nextCheckInDue: Date?
    @Published var isCheckInOverdue = false
    @Published var missedCheckIns: [SafetyCheckIn] = []
    
    private let db = Firestore.firestore()
    private var checkInListener: ListenerRegistration?
    private var overdueTimer: Timer?
    
    // MARK: - Perform Check-in
    
    func performCheckIn(
        userId: String,
        userName: String,
        tenantId: String,
        location: CLLocation,
        address: String?,
        isSafe: Bool,
        notes: String? = nil
    ) async throws {
        
        let nextDue = Date().addingTimeInterval(checkInInterval)
        
        let checkIn = SafetyCheckIn(
            userId: userId,
            tenantId: tenantId,
            userName: userName,
            checkInTime: Date(),
            nextCheckInDue: nextDue,
            status: isSafe ? .safe : .needsHelp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            address: address,
            notes: notes,
            isSafe: isSafe
        )
        
        // Save to Firestore
        try db.collection("safety_checkins").addDocument(from: checkIn)
        
        // Update user's last check-in
        try await db.collection("users").document(userId).updateData([
            "lastCheckInAt": Timestamp(date: Date()),
            "nextCheckInDue": Timestamp(date: nextDue),
            "lastCheckInStatus": isSafe ? "safe" : "needs_help"
        ])
        
        self.lastCheckIn = checkIn
        self.nextCheckInDue = nextDue
        self.isCheckInOverdue = false
        
        // If not safe, create alert
        if !isSafe {
            try await createCheckInAlert(checkIn: checkIn)
        }
        
        // Schedule next check-in notification
        scheduleCheckInNotification(dueDate: nextDue, userName: userName)
        
        print("✅ Safety check-in completed. Next due: \(nextDue)")
    }
    
    // MARK: - Monitor Overdue Check-ins
    
    func startMonitoringCheckIns(tenantId: String) {
        checkInListener?.remove()
        
        guard !tenantId.isEmpty else { return }
        
        // Monitor all field personnel check-ins
        checkInListener = db.collection("users")
            .whereField("tenantId", isEqualTo: tenantId)
            .whereField("role", isEqualTo: "field_personnel")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error monitoring check-ins: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    await self.checkForOverdueCheckIns(documents: documents)
                }
            }
        
        // Start periodic timer to check for overdue
        startOverdueTimer()
    }
    
    private func checkForOverdueCheckIns(documents: [QueryDocumentSnapshot]) async {
        let now = Date()
        var overdueUsers: [(String, String, Date)] = [] // (userId, userName, dueDate)
        
        for doc in documents {
            let data = doc.data()
            
            guard let nextDueTimestamp = data["nextCheckInDue"] as? Timestamp,
                  let userName = data["fullName"] as? String else {
                continue
            }
            
            let dueDate = nextDueTimestamp.dateValue()
            
            if now > dueDate {
                overdueUsers.append((doc.documentID, userName, dueDate))
            }
        }
        
        // Create missed check-in records and alerts
        for (userId, userName, dueDate) in overdueUsers {
            await handleMissedCheckIn(userId: userId, userName: userName, dueDate: dueDate)
        }
    }
    
    private func handleMissedCheckIn(userId: String, userName: String, dueDate: Date) async {
        // Check if we already created a missed check-in alert
        let existingQuery = try? await db.collection("safety_checkins")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: SafetyCheckIn.CheckInStatus.missed.rawValue)
            .whereField("nextCheckInDue", isEqualTo: Timestamp(date: dueDate))
            .limit(to: 1)
            .getDocuments()
        
        if let existing = existingQuery, !existing.documents.isEmpty {
            return // Already handled
        }
        
        // Create missed check-in record
        let missedCheckIn = SafetyCheckIn(
            userId: userId,
            tenantId: "", // Will be fetched from user
            userName: userName,
            checkInTime: Date(),
            nextCheckInDue: dueDate,
            status: .missed,
            latitude: 0,
            longitude: 0,
            isSafe: false
        )
        
        try? db.collection("safety_checkins").addDocument(from: missedCheckIn)
        
        // Create alert for admins
        try? await createMissedCheckInAlert(userId: userId, userName: userName, dueDate: dueDate)
        
        print("⚠️ Missed check-in for: \(userName)")
    }
    
    // MARK: - Notifications
    
    private func scheduleCheckInNotification(dueDate: Date, userName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Safety Check-in Required"
        content.body = "Please confirm your safety status"
        content.sound = .default
        content.categoryIdentifier = "SAFETY_CHECKIN"
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "safety-checkin-\(dueDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling check-in notification: \(error)")
            } else {
                print("✅ Check-in notification scheduled for: \(dueDate)")
            }
        }
    }
    
    private func startOverdueTimer() {
        overdueTimer?.invalidate()
        
        // Check every 5 minutes for overdue check-ins
        overdueTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if let nextDue = self.nextCheckInDue, Date() > nextDue {
                Task { @MainActor in
                    self.isCheckInOverdue = true
                }
            }
        }
    }
    
    // MARK: - Alert Creation
    
    private func createCheckInAlert(checkIn: SafetyCheckIn) async throws {
        let alert = Alert(
            tenantId: checkIn.tenantId,
            senderId: checkIn.userId,
            senderName: checkIn.userName,
            recipientIds: [], // Empty array means all users in tenant
            title: "⚠️ Help Needed",
            message: "\(checkIn.userName) has checked in but indicated they need help. Location: \(checkIn.address ?? "Unknown")",
            priority: .high,
            type: .safetyCheckin,
            requiresResponse: true,
            quickResponses: ["Contacting now", "Dispatching help", "Need more info"],
            allowCustomResponse: true,
            createdAt: Date(),
            expiresAt: nil,
            isActive: true
        )
        
        try db.collection("alerts").addDocument(from: alert)
    }
    
    private func createMissedCheckInAlert(userId: String, userName: String, dueDate: Date) async throws {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        let alert = Alert(
            tenantId: "", // Will be populated
            senderId: "system",
            senderName: "Safety System",
            recipientIds: [], // Empty array means all users in tenant
            title: "⚠️ Missed Safety Check-in",
            message: "\(userName) missed their scheduled safety check-in due at \(formatter.string(from: dueDate)). Last check-in was over \(Int(checkInInterval / 3600)) hours ago.",
            priority: .high,
            type: .safetyCheckin,
            requiresResponse: true,
            quickResponses: ["Attempting contact", "Escalating", "Located - Safe"],
            allowCustomResponse: true,
            createdAt: Date(),
            expiresAt: nil,
            isActive: true
        )
        
        try db.collection("alerts").addDocument(from: alert)
    }
    
    // MARK: - Get Check-in History
    
    func getCheckInHistory(userId: String, limit: Int = 30) async throws -> [SafetyCheckIn] {
        let snapshot = try await db.collection("safety_checkins")
            .whereField("userId", isEqualTo: userId)
            .order(by: "checkInTime", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: SafetyCheckIn.self) }
    }
    
    func stopMonitoring() {
        checkInListener?.remove()
        checkInListener = nil
        overdueTimer?.invalidate()
        overdueTimer = nil
    }
    
    nonisolated deinit {
        // Timer and Firestore listener cleanup
        // Note: We can't call MainActor-isolated methods here
        // These will be cleaned up when the service is deallocated
    }
}

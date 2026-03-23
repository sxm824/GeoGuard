//
//  TrackingReliabilityMonitor.swift
//  GeoGuard
//
//  Created on 2026-03-06.
//  Monitors tracking reliability and alerts users of issues
//

import Foundation
import Combine
import CoreLocation
import FirebaseFirestore
import UserNotifications
import UIKit

final class TrackingReliabilityMonitor: ObservableObject {
    @Published var isReliable = true
    @Published var lastIssueDetected: String?
    
    private let db = Firestore.firestore()
    private var monitorTimer: Timer?
    private var lastAlertTime: Date?
    private let alertCooldown: TimeInterval = 300 // 5 minutes between alerts
    
    // MARK: - Start/Stop Monitoring
    
    func startMonitoring(userId: String, tenantId: String, locationManager: LocationManager) {
        print("🔍 Starting tracking reliability monitoring")
        monitorTimer?.invalidate()
        
        // Check immediately
        Task { @MainActor in
            await checkTrackingHealth(
                userId: userId,
                tenantId: tenantId,
                locationManager: locationManager
            )
        }
        
        // Then check every minute
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                await self.checkTrackingHealth(
                    userId: userId,
                    tenantId: tenantId,
                    locationManager: locationManager
                )
            }
        }
    }
    
    func stopMonitoring() {
        print("🔍 Stopping tracking reliability monitoring")
        monitorTimer?.invalidate()
        monitorTimer = nil
    }
    
    // MARK: - Health Checks
    
    @MainActor
    private func checkTrackingHealth(userId: String, tenantId: String, locationManager: LocationManager) async {
        var issues: [String] = []
        
        // Check 1: Low Power Mode
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            issues.append("Low Power Mode enabled")
        }
        
        // Check 2: Background App Refresh
        if UIApplication.shared.backgroundRefreshStatus == .denied {
            issues.append("Background App Refresh disabled")
        } else if UIApplication.shared.backgroundRefreshStatus == .restricted {
            issues.append("Background App Refresh restricted")
        }
        
        // Check 3: Last location update time
        if let lastSync = locationManager.lastSuccessfulSync {
            let timeSinceSync = Date().timeIntervalSince(lastSync)
            
            // If no sync for > 5 minutes while tracking, something is wrong
            if timeSinceSync > 300 && locationManager.isTracking {
                issues.append("No location sync for \(Int(timeSinceSync / 60)) minutes")
            }
        } else if locationManager.isTracking {
            // Tracking but never synced - might be starting up, give it 2 minutes
            // This check is less critical on first start
        }
        
        // Check 4: Queued locations growing excessively
        if locationManager.queuedLocationCount > 50 {
            issues.append("Large offline queue (\(locationManager.queuedLocationCount) locations)")
        }
        
        // Check 5: Location permission
        if locationManager.authorizationStatus != .authorizedAlways {
            issues.append("Location permission not set to 'Always'")
        }
        
        // Update reliability status
        let wasReliable = isReliable
        isReliable = issues.isEmpty
        
        if !issues.isEmpty {
            lastIssueDetected = issues.joined(separator: ", ")
            
            print("⚠️ Tracking reliability issues detected: \(lastIssueDetected ?? "")")
            
            // Log to Firestore for admin visibility
            await logReliabilityIssue(
                userId: userId,
                tenantId: tenantId,
                issues: issues
            )
            
            // Only send alert if:
            // 1. We just became unreliable (status changed from reliable to unreliable)
            // 2. Enough time has passed since last alert (cooldown)
            let shouldAlert = wasReliable || lastAlertTime == nil ||
                              (lastAlertTime != nil && Date().timeIntervalSince(lastAlertTime!) > alertCooldown)
            
            if shouldAlert {
                await sendReliabilityAlert(issues: issues)
                lastAlertTime = Date()
            }
        } else if !wasReliable {
            // Just became reliable again
            print("✅ Tracking reliability restored")
            lastIssueDetected = nil
        }
    }
    
    // MARK: - Issue Logging
    
    private func logReliabilityIssue(userId: String, tenantId: String, issues: [String]) async {
        let issueLog: [String: Any] = [
            "userId": userId,
            "tenantId": tenantId,
            "issues": issues,
            "timestamp": FieldValue.serverTimestamp(),
            "batteryLevel": UIDevice.current.batteryLevel,
            "lowPowerMode": ProcessInfo.processInfo.isLowPowerModeEnabled,
            "backgroundRefreshStatus": UIApplication.shared.backgroundRefreshStatus.rawValue
        ]
        
        do {
            try await db.collection("tracking_issues").addDocument(data: issueLog)
            print("📝 Logged tracking reliability issue to Firestore")
        } catch {
            print("❌ Failed to log reliability issue: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Alerts
    
    private func sendReliabilityAlert(issues: [String]) async {
        // Request notification permission first
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            guard granted else {
                print("⚠️ Notification permission not granted")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Location Tracking Issue"
            content.body = "Your location may not be updating: \(issues.joined(separator: ", ")). Tap to fix in Settings."
            content.sound = .default
            content.categoryIdentifier = "TRACKING_ISSUE"
            
            let request = UNNotificationRequest(
                identifier: "tracking-issue-\(UUID().uuidString)",
                content: content,
                trigger: nil // Immediate
            )
            
            try await center.add(request)
            print("📬 Sent tracking reliability notification to user")
            
        } catch {
            print("❌ Failed to send reliability notification: \(error.localizedDescription)")
        }
    }
}

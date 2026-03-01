//
//  LocationManager.swift
//  GeoGuard
//
//  Location tracking service for field personnel
//

import Foundation
import CoreLocation
import FirebaseFirestore
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var isTracking = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    private var userId: String?
    private var tenantId: String?
    private var updateTimer: Timer?
    
    // MARK: - Configuration
    private let updateInterval: TimeInterval = 30 // Update every 30 seconds
    private let distanceFilter: CLLocationDistance = 50 // Update every 50 meters
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = distanceFilter
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permission Handling
    
    func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            error = "Location permission is required for safety tracking. Please enable it in Settings."
        case .authorizedAlways:
            // Already have permission
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Start/Stop Tracking
    
    func startTracking(userId: String, tenantId: String) {
        self.userId = userId
        self.tenantId = tenantId
        
        guard authorizationStatus == .authorizedAlways else {
            error = "Always location permission is required for continuous safety tracking."
            requestPermission()
            return
        }
        
        isTracking = true
        locationManager.startUpdatingLocation()
        
        // Also start significant location changes for better battery life
        locationManager.startMonitoringSignificantLocationChanges()
        
        print("✅ Started location tracking for user: \(userId)")
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        updateTimer?.invalidate()
        updateTimer = nil
        
        print("🛑 Stopped location tracking")
    }
    
    // MARK: - Update Location to Firestore
    
    private func updateLocationToFirestore(_ location: CLLocation) {
        guard let userId = userId, let tenantId = tenantId else {
            print("⚠️ Cannot update location: missing userId or tenantId")
            return
        }
        
        // Get battery level
        let batteryLevel = getBatteryLevel()
        
        let locationData: [String: Any] = [
            "userId": userId,
            "tenantId": tenantId,
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "altitude": location.altitude,
            "speed": location.speed,
            "heading": location.course,
            "timestamp": Timestamp(date: location.timestamp),
            "batteryLevel": batteryLevel,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Use userId as document ID for easy querying
        db.collection("locations").document(userId).setData(locationData, merge: true) { error in
            if let error = error {
                print("❌ Error updating location: \(error.localizedDescription)")
                Task { @MainActor in
                    self.error = "Failed to update location"
                }
            } else {
                print("✅ Location updated successfully")
            }
        }
    }
    
    // MARK: - Battery Level
    
    private func getBatteryLevel() -> Double {
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        return batteryLevel >= 0 ? Double(batteryLevel) : 1.0
        #else
        return 1.0
        #endif
    }
    
    // MARK: - Permission Status
    
    var hasAlwaysPermission: Bool {
        authorizationStatus == .authorizedAlways
    }
    
    var needsPermission: Bool {
        authorizationStatus == .notDetermined || authorizationStatus == .authorizedWhenInUse
    }
    
    var permissionDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            // If we just got always permission and should be tracking, start
            if authorizationStatus == .authorizedAlways && isTracking {
                if let userId = userId, let tenantId = tenantId {
                    startTracking(userId: userId, tenantId: tenantId)
                }
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            currentLocation = location
            
            // Update to Firestore
            if isTracking {
                updateLocationToFirestore(location)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = "Location error: \(error.localizedDescription)"
            print("❌ Location manager error: \(error)")
        }
    }
}

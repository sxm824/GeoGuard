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
    @Published var batteryLevel: Float = 1.0
    @Published var queuedLocationCount: Int = 0
    @Published var lastSuccessfulSync: Date?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    private var userId: String?
    private var tenantId: String?
    private var updateTimer: Timer?
    
    // MARK: - Offline Location Caching
    private var offlineLocationQueue: [CachedLocation] = []
    private let maxQueueSize = 100
    
    struct CachedLocation: Codable {
        let userId: String
        let tenantId: String
        let latitude: Double
        let longitude: Double
        let timestamp: Date
        let speed: Double
        let accuracy: Double
        let altitude: Double
        let heading: Double
        let batteryLevel: Double
    }
    
    // MARK: - Configuration
    private let updateInterval: TimeInterval = 30 // Update every 30 seconds
    private let distanceFilter: CLLocationDistance = 50 // Update every 50 meters
    
    // MARK: - Battery-Aware Tracking
    private var adaptiveUpdateInterval: TimeInterval {
        switch batteryLevel {
        case 0..<0.10:    // < 10% - Critical
            return 300     // Every 5 minutes only
        case 0.10..<0.20:  // 10-20% - Low
            return 120     // Every 2 minutes
        case 0.20..<0.50:  // 20-50% - Medium
            return 60      // Every minute
        default:          // > 50% - Normal
            return 30      // Every 30 seconds
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
        loadQueueFromDisk()
        monitorBatteryLevel()
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
    
    // MARK: - Battery Monitoring
    
    private func monitorBatteryLevel() {
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateBatteryStatus()
            }
        }
        
        updateBatteryStatus()
        #endif
    }
    
    private func updateBatteryStatus() {
        #if os(iOS)
        batteryLevel = UIDevice.current.batteryLevel
        
        if batteryLevel >= 0 {
            print("🔋 Battery: \(Int(batteryLevel * 100))% - Update interval: \(adaptiveUpdateInterval)s")
            
            // Adjust tracking frequency if tracking
            if isTracking {
                adjustTrackingFrequency()
            }
        }
        #endif
    }
    
    private func adjustTrackingFrequency() {
        // Restart timer with new interval based on battery level
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: adaptiveUpdateInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self = self, let location = self.currentLocation else { return }
            Task { @MainActor in
                self.updateLocationToFirestore(location)
            }
        }
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
        
        // Load any previously cached locations for this user
        loadQueueFromDisk()
        
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
        db.collection("locations").document(userId).setData(locationData, merge: true) { [weak self] error in
            if let error = error {
                print("❌ Error updating location (likely offline): \(error.localizedDescription)")
                Task { @MainActor in
                    // Cache for later sync
                    self?.cacheLocationOffline(location, batteryLevel: batteryLevel)
                }
            } else {
                print("✅ Location updated successfully")
                Task { @MainActor in
                    // Update last successful sync time
                    self?.lastSuccessfulSync = Date()
                    
                    // Try to process any queued locations
                    self?.processOfflineQueue()
                }
            }
        }
    }
    
    // MARK: - Offline Location Caching
    
    private func cacheLocationOffline(_ location: CLLocation, batteryLevel: Double) {
        guard let userId = userId, let tenantId = tenantId else { return }
        
        let cached = CachedLocation(
            userId: userId,
            tenantId: tenantId,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp,
            speed: location.speed,
            accuracy: location.horizontalAccuracy,
            altitude: location.altitude,
            heading: location.course,
            batteryLevel: batteryLevel
        )
        
        offlineLocationQueue.append(cached)
        
        // Limit queue size (keep most recent)
        if offlineLocationQueue.count > maxQueueSize {
            offlineLocationQueue.removeFirst()
        }
        
        // Update published count
        queuedLocationCount = offlineLocationQueue.count
        
        // Persist to disk
        saveQueueToDisk()
        
        print("📦 Cached location offline (queue: \(offlineLocationQueue.count)/\(maxQueueSize))")
    }
    
    private func processOfflineQueue() {
        guard !offlineLocationQueue.isEmpty else { return }
        
        print("📤 Processing \(offlineLocationQueue.count) queued locations...")
        
        let batch = db.batch()
        let locationsToProcess = offlineLocationQueue
        
        for cached in locationsToProcess {
            let data: [String: Any] = [
                "userId": cached.userId,
                "tenantId": cached.tenantId,
                "latitude": cached.latitude,
                "longitude": cached.longitude,
                "accuracy": cached.accuracy,
                "altitude": cached.altitude,
                "speed": cached.speed,
                "heading": cached.heading,
                "timestamp": Timestamp(date: cached.timestamp),
                "batteryLevel": cached.batteryLevel,
                "wasOffline": true, // Flag to indicate this was synced after being offline
                "syncedAt": FieldValue.serverTimestamp()
            ]
            
            let docRef = db.collection("locations").document(cached.userId)
            batch.setData(data, forDocument: docRef, merge: true)
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                print("❌ Failed to sync queued locations: \(error.localizedDescription)")
                // Keep locations in queue for next attempt
            } else {
                Task { @MainActor in
                    guard let self = self else { return }
                    print("✅ Synced \(locationsToProcess.count) offline locations")
                    self.offlineLocationQueue.removeAll()
                    self.queuedLocationCount = 0
                    self.lastSuccessfulSync = Date() // Update sync time after queue processed
                    self.saveQueueToDisk()
                }
            }
        }
    }
    
    private func saveQueueToDisk() {
        guard let userId = userId else { return }
        
        if let encoded = try? JSONEncoder().encode(offlineLocationQueue) {
            UserDefaults.standard.set(encoded, forKey: "offlineLocationQueue_\(userId)")
            print("💾 Saved queue to disk (\(offlineLocationQueue.count) locations)")
        }
    }
    
    private func loadQueueFromDisk() {
        guard let userId = userId,
              let data = UserDefaults.standard.data(forKey: "offlineLocationQueue_\(userId)"),
              let decoded = try? JSONDecoder().decode([CachedLocation].self, from: data) else {
            return
        }
        
        offlineLocationQueue = decoded
        queuedLocationCount = offlineLocationQueue.count
        print("📥 Loaded \(offlineLocationQueue.count) cached locations from disk")
        
        // Try to process queue immediately if we have connectivity
        if offlineLocationQueue.count > 0 {
            processOfflineQueue()
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
    
    // MARK: - Reverse Geocoding
    
    func reverseGeocode(location: CLLocation) async throws -> String {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            return "Unknown location"
        }
        
        // Build address string
        var addressComponents: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            addressComponents.append(streetNumber)
        }
        if let street = placemark.thoroughfare {
            addressComponents.append(street)
        }
        if let city = placemark.locality {
            addressComponents.append(city)
        }
        if let state = placemark.administrativeArea {
            addressComponents.append(state)
        }
        if let postalCode = placemark.postalCode {
            addressComponents.append(postalCode)
        }
        
        return addressComponents.isEmpty ? "Unknown location" : addressComponents.joined(separator: ", ")
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

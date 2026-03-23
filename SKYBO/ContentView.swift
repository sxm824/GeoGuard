//
//  ContentView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-23.
//

import SwiftUI
import GoogleMaps
import FirebaseFirestore
import CoreLocation

struct ContentView: View {
    var body: some View {
        NavigationStack {
            SignupView()
        }
    }
}

struct GoogleMapView: UIViewRepresentable {
    let userId: String
    let showOnlyUser: Bool // If true, show only this user; if false, show all users in tenant
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 40.7128, // Default to New York
                                              longitude: -74.0060,
                                              zoom: 14)
        
        let mapView = GMSMapView()
        mapView.camera = camera
        mapView.isMyLocationEnabled = true // Show user's blue dot
        
        // Set up coordinator
        context.coordinator.mapView = mapView
        context.coordinator.userId = userId
        context.coordinator.showOnlyUser = showOnlyUser
        
        // Start listening for location updates
        context.coordinator.startListeningForLocationUpdates()
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Update if parameters change
        context.coordinator.userId = userId
        context.coordinator.showOnlyUser = showOnlyUser
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var mapView: GMSMapView?
        var userId: String = ""
        var showOnlyUser: Bool = true
        var userMarker: GMSMarker?
        var locationListener: ListenerRegistration?
        
        private let db = Firestore.firestore()
        
        func startListeningForLocationUpdates() {
            // Remove existing listener
            locationListener?.remove()
            
            // Listen to the specific user's location document
            locationListener = db.collection("locations")
                .document(userId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self,
                          let mapView = self.mapView,
                          let snapshot = snapshot,
                          snapshot.exists,
                          let data = snapshot.data() else {
                        if let error = error {
                            print("❌ Error listening to location: \(error.localizedDescription)")
                        }
                        return
                    }
                    
                    // Extract location data
                    guard let latitude = data["latitude"] as? Double,
                          let longitude = data["longitude"] as? Double else {
                        print("⚠️ Invalid location data")
                        return
                    }
                    
                    let position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    
                    // Update or create marker
                    if let marker = self.userMarker {
                        // Update existing marker position
                        marker.position = position
                    } else {
                        // Create new marker
                        let marker = GMSMarker()
                        marker.position = position
                        marker.title = "Your Location"
                        marker.icon = GMSMarker.markerImage(with: .blue)
                        marker.map = mapView
                        self.userMarker = marker
                        
                        // Center camera on user's location
                        let camera = GMSCameraPosition.camera(withTarget: position, zoom: 15)
                        mapView.animate(to: camera)
                    }
                    
                    print("✅ Updated map with user location: \(latitude), \(longitude)")
                }
        }
        
        deinit {
            locationListener?.remove()
        }
    }
}

// For admin view - shows all users in tenant
struct GoogleMapViewAllUsers: UIViewRepresentable {
    let tenantId: String
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 40.7128,
                                              longitude: -74.0060,
                                              zoom: 12)
        
        let mapView = GMSMapView()
        mapView.camera = camera
        
        context.coordinator.mapView = mapView
        context.coordinator.tenantId = tenantId
        context.coordinator.startListeningForAllUsers()
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        context.coordinator.tenantId = tenantId
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var mapView: GMSMapView?
        var tenantId: String = ""
        var userMarkers: [String: GMSMarker] = [:] // userId -> marker
        var locationListener: ListenerRegistration?
        
        private let db = Firestore.firestore()
        
        func startListeningForAllUsers() {
            locationListener?.remove()
            
            // Listen to all locations in the tenant
            locationListener = db.collection("locations")
                .whereField("tenantId", isEqualTo: tenantId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self,
                          let mapView = self.mapView,
                          let snapshot = snapshot else {
                        if let error = error {
                            print("❌ Error listening to locations: \(error.localizedDescription)")
                        }
                        return
                    }
                    
                    // Process all location documents
                    for document in snapshot.documents {
                        let data = document.data()
                        let userId = document.documentID
                        
                        guard let latitude = data["latitude"] as? Double,
                              let longitude = data["longitude"] as? Double else {
                            continue
                        }
                        
                        let position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        
                        // Update or create marker for this user
                        if let marker = self.userMarkers[userId] {
                            marker.position = position
                        } else {
                            let marker = GMSMarker()
                            marker.position = position
                            marker.title = "User"
                            marker.icon = GMSMarker.markerImage(with: .red)
                            marker.map = mapView
                            self.userMarkers[userId] = marker
                        }
                    }
                    
                    print("✅ Updated map with \(self.userMarkers.count) users")
                }
        }
        
        deinit {
            locationListener?.remove()
        }
    }
}

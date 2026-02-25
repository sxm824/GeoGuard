//
//  ContentView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-23.
//

import SwiftUI
import GoogleMaps

struct ContentView: View {
    var body: some View {
        NavigationStack {
            SignupView()
        }
    }
}

struct GoogleMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 40.7128, // New York
                                              longitude: -74.0060,
                                              zoom: 14)
        
        let mapView = GMSMapView()
        mapView.camera = camera
        mapView.isMyLocationEnabled = true // your blue dot
        
        // HQ marker
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        marker.title = "GeoGuard HQ"
        marker.snippet = "Where it all starts"
        marker.map = mapView
        
        // Fake driver marker
        let driverMarker = GMSMarker()
        driverMarker.position = CLLocationCoordinate2D(latitude: 40.7069, longitude: -73.9969) // Brooklyn
        driverMarker.title = "Driver 1"
        driverMarker.icon = GMSMarker.markerImage(with: .red)
        driverMarker.map = mapView
        
        // Move driver every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            driverMarker.position.latitude += 0.001 // nudge north
            driverMarker.position.longitude -= 0.001 // nudge west
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // nothing for now
    }
}

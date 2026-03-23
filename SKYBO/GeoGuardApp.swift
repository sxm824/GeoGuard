//
//  GeoGuardApp.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-23.
//

import SwiftUI
import GoogleMaps
// TODO: Uncomment after adding GooglePlaces package via SPM
import GooglePlaces
import FirebaseCore


@main
struct GeoGuardApp: App {
    init() {
        let apiKey = "AIzaSyAbiceuS7oChS1ojh51MyLq-d4mmx0Wv5g"
        GMSServices.provideAPIKey(apiKey)
        
        // TODO: Uncomment after GooglePlaces is added
        GMSPlacesClient.provideAPIKey(apiKey)
        
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            // Use RootView which has proper multi-role routing support
            RootView()
        }
    }
}

// MARK: - Preview

#Preview("App Root") {
    RootView()
}




//
//  SystemSettingsView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-26.
//

import SwiftUI

struct SystemSettingsView: View {
    @State private var maintenanceMode = false
    @State private var allowNewRegistrations = true
    @State private var defaultTrialDays = 14
    @State private var requireEmailVerification = true
    
    var body: some View {
        Form {
            Section("Platform Status") {
                Toggle("Maintenance Mode", isOn: $maintenanceMode)
                
                Text("When enabled, only super admins can access the platform")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Registration Settings") {
                Toggle("Allow New Registrations", isOn: $allowNewRegistrations)
                
                Toggle("Require Email Verification", isOn: $requireEmailVerification)
                
                Stepper("Trial Period: \(defaultTrialDays) days", value: $defaultTrialDays, in: 7...30)
            }
            
            Section("System Information") {
                LabeledContent("App Version", value: "1.0.0")
                LabeledContent("Database", value: "Cloud Firestore")
                LabeledContent("Authentication", value: "Firebase Auth")
            }
            
            Section("Documentation") {
                Link(destination: URL(string: "https://firebase.google.com/docs")!) {
                    Label("Firebase Documentation", systemImage: "doc.text")
                }
                
                Link(destination: URL(string: "https://developer.apple.com/documentation/swiftui")!) {
                    Label("SwiftUI Documentation", systemImage: "swift")
                }
            }
            
            Section {
                Text("This view allows GeoGuard platform administrators to configure system-wide settings. Changes here affect all organizations.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("System Settings")
    }
}

#Preview {
    NavigationStack {
        SystemSettingsView()
    }
}

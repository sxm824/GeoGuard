//
//  IncidentReportView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//

import SwiftUI
import CoreLocation

struct IncidentReportView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var incidentService = IncidentReportService()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedType: IncidentReport.IncidentType = .security
    @State private var selectedSeverity: IncidentReport.Severity = .medium
    @State private var incidentDate = Date()
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @State private var showingError: String?
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Incident Details") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Describe what happened...")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                    
                    DatePicker("When did this occur?", selection: $incidentDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                // Type Selection
                Section("Incident Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(IncidentReport.IncidentType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Severity Selection
                Section("Severity Level") {
                    Picker("Severity", selection: $selectedSeverity) {
                        ForEach(IncidentReport.Severity.allCases, id: \.self) { severity in
                            HStack {
                                Circle()
                                    .fill(severityColor(severity))
                                    .frame(width: 12, height: 12)
                                Text(severity.displayName)
                            }
                            .tag(severity)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Location Info
                Section("Location") {
                    if let location = locationManager.currentLocation {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Location")
                                    .font(.subheadline)
                                
                                Text("Lat: \(location.coordinate.latitude, specifier: "%.6f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Lon: \(location.coordinate.longitude, specifier: "%.6f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "location.slash")
                                .foregroundColor(.red)
                            Text("Location unavailable")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Safety Tips
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Important Information")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Your report will be immediately sent to administrators. For life-threatening emergencies, use the SOS button instead.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Report Incident")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .alert("Report Submitted", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your incident report has been submitted and administrators have been notified.")
            }
            .alert("Error", isPresented: .init(
                get: { showingError != nil },
                set: { if !$0 { showingError = nil } }
            )) {
                Button("OK", role: .cancel) { showingError = nil }
            } message: {
                if let error = showingError {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Validation
    
    var isFormValid: Bool {
        !title.isEmpty && 
        !description.isEmpty && 
        locationManager.currentLocation != nil
    }
    
    // MARK: - Actions
    
    private func submitReport() {
        guard let user = authService.currentUser,
              let userId = user.id,
              let tenantId = authService.tenantId,
              let location = locationManager.currentLocation else {
            showingError = "Unable to get your current location or user information."
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                let address = try? await locationManager.reverseGeocode(location: location)
                
                _ = try await incidentService.submitIncident(
                    reporterId: userId,
                    reporterName: user.fullName,
                    tenantId: tenantId,
                    title: title,
                    description: description,
                    incidentType: selectedType,
                    severity: selectedSeverity,
                    location: location,
                    address: address,
                    incidentOccurredAt: incidentDate
                )
                
                showingSuccess = true
                
            } catch {
                showingError = "Failed to submit report: \(error.localizedDescription)"
            }
            
            isSubmitting = false
        }
    }
    
    // MARK: - Helpers
    
    private func severityColor(_ severity: IncidentReport.Severity) -> Color {
        switch severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Incident List View (for viewing reports)

struct IncidentListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var incidentService = IncidentReportService()
    @State private var showingNewReport = false
    
    var body: some View {
        List {
            if incidentService.incidents.isEmpty {
                ContentUnavailableView(
                    "No Incidents",
                    systemImage: "doc.text",
                    description: Text("No incidents have been reported yet")
                )
            } else {
                ForEach(incidentService.incidents) { incident in
                    NavigationLink {
                        IncidentDetailView(incident: incident)
                            .environmentObject(authService)
                    } label: {
                        IncidentRowView(incident: incident)
                    }
                }
            }
        }
        .navigationTitle("Incident Reports")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewReport = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingNewReport) {
            IncidentReportView()
                .environmentObject(authService)
        }
        .task {
            if let tenantId = authService.tenantId {
                incidentService.startListeningToIncidents(tenantId: tenantId)
            }
        }
        .onDisappear {
            incidentService.stopListening()
        }
    }
}

// MARK: - Reusable Components
// Note: IncidentRowView and StatusBadge are now in SharedComponents.swift

// MARK: - Incident Detail View

struct IncidentDetailView: View {
    let incident: IncidentReport
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: incident.incidentType.icon)
                            .font(.title)
                            .foregroundColor(severityColor)
                        
                        Text(incident.title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text(incident.incidentType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Details
                DetailRow(label: "Reported by", value: incident.reporterName)
                DetailRow(label: "Reported at", value: incident.reportedAt.formatted(date: .long, time: .shortened))
                DetailRow(label: "Occurred at", value: incident.incidentOccurredAt.formatted(date: .long, time: .shortened))
                DetailRow(label: "Severity", value: incident.severity.displayName, color: severityColor)
                DetailRow(label: "Status", value: incident.status.displayName)
                
                if let address = incident.address {
                    DetailRow(label: "Location", value: address)
                }
                
                Divider()
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    Text(incident.description)
                        .font(.body)
                }
                
                if let reviewNotes = incident.reviewNotes {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review Notes")
                            .font(.headline)
                        
                        Text(reviewNotes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Incident Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var severityColor: Color {
        switch incident.severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Reusable Components
// Note: DetailRow is now in SharedComponents.swift

#Preview {
    NavigationStack {
        IncidentReportView()
            .environmentObject(AuthService())
    }
}

//
//  AdminSafetyDashboardView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//

import SwiftUI
import FirebaseFirestore

struct AdminSafetyDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var sosService = SOSService()
    @StateObject private var incidentService = IncidentReportService()
    @StateObject private var breachService = GeofenceBreachService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Critical Alerts Section
                if !sosService.activeSOSAlerts.isEmpty {
                    activeSOSSection
                }
                
                // Quick Stats
                statsGrid
                
                // Recent Activity
                recentIncidentsSection
                
                // Geofence Breaches
                if !breachService.unacknowledgedBreaches.isEmpty {
                    breachesSection
                }
            }
            .padding()
        }
        .navigationTitle("Safety Dashboard")
        .task {
            if let tenantId = authService.tenantId {
                sosService.startListeningToSOSAlerts(tenantId: tenantId)
                incidentService.startListeningToIncidents(tenantId: tenantId)
                breachService.startListeningToBreaches(tenantId: tenantId)
            }
        }
        .onDisappear {
            sosService.stopListening()
            incidentService.stopListening()
            breachService.stopListening()
        }
    }
    
    // MARK: - Active SOS Section
    
    var activeSOSSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Active SOS Alerts")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            ForEach(sosService.activeSOSAlerts) { sos in
                ActiveSOSCard(sos: sos, sosService: sosService, authService: authService)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Stats Grid
    
    var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Active SOS",
                value: "\(sosService.activeSOSAlerts.count)",
                icon: "sos.circle.fill",
                color: .red
            )
            
            StatCard(
                title: "Pending Incidents",
                value: "\(incidentService.pendingIncidents.count)",
                icon: "doc.text.fill",
                color: .orange
            )
            
            StatCard(
                title: "Unack. Breaches",
                value: "\(breachService.unacknowledgedBreaches.count)",
                icon: "exclamationmark.shield.fill",
                color: .yellow
            )
            
            StatCard(
                title: "Total Incidents",
                value: "\(incidentService.incidents.count)",
                icon: "chart.bar.fill",
                color: .blue
            )
        }
    }
    
    // MARK: - Recent Incidents
    
    var recentIncidentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Incidents")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    AdminIncidentListView()
                        .environmentObject(authService)
                } label: {
                    Text("View All")
                        .font(.caption)
                }
            }
            
            if incidentService.incidents.isEmpty {
                Text("No incidents reported")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(incidentService.incidents.prefix(5)) { incident in
                    NavigationLink {
                        AdminIncidentDetailView(incident: incident)
                            .environmentObject(authService)
                    } label: {
                        IncidentRowView(incident: incident)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Breaches Section
    
    var breachesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Unacknowledged Breaches")
                    .font(.headline)
            }
            
            ForEach(breachService.unacknowledgedBreaches.prefix(5)) { breach in
                BreachCard(breach: breach, breachService: breachService, authService: authService)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Active SOS Card

struct ActiveSOSCard: View {
    let sos: SOSAlert
    @ObservedObject var sosService: SOSService
    @ObservedObject var authService: AuthService
    
    @State private var showingActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sos.userName)
                        .font(.headline)
                    
                    Text(sos.userEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if sos.isSilentMode {
                        Label("Silent SOS", systemImage: "speaker.slash.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(sos.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                    
                    Text("Triggered \(sos.triggeredAt, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let address = sos.address {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                if sos.status == .active {
                    Button {
                        acknowledgeSOS()
                    } label: {
                        Text("Acknowledge")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
                
                Button {
                    updateStatus(.responding)
                } label: {
                    Text("Responding")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Button {
                    updateStatus(.resolved)
                } label: {
                    Text("Resolve")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    var statusColor: Color {
        switch sos.status {
        case .active: return .red
        case .acknowledged: return .orange
        case .responding: return .blue
        case .resolved: return .green
        case .falseAlarm: return .gray
        }
    }
    
    private func acknowledgeSOS() {
        guard let sosId = sos.id,
              let adminId = authService.currentUser?.id,
              let adminName = authService.currentUser?.fullName else {
            return
        }
        
        Task {
            try? await sosService.acknowledgeSOS(sosId: sosId, adminId: adminId, adminName: adminName)
        }
    }
    
    private func updateStatus(_ status: SOSAlert.SOSStatus) {
        guard let sosId = sos.id,
              let adminId = authService.currentUser?.id,
              let adminName = authService.currentUser?.fullName else {
            return
        }
        
        Task {
            try? await sosService.updateSOSStatus(sosId: sosId, status: status, adminId: adminId, adminName: adminName)
        }
    }
}

// MARK: - Breach Card

struct BreachCard: View {
    let breach: GeofenceBreach
    @ObservedObject var breachService: GeofenceBreachService
    @ObservedObject var authService: AuthService
    
    var body: some View {
        HStack {
            Image(systemName: breach.breachType.icon)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(breach.userName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(breach.breachType.displayName): \(breach.geofenceName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(breach.breachTime, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                acknowledgeBreach()
            } label: {
                Text("Acknowledge")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    private func acknowledgeBreach() {
        guard let breachId = breach.id,
              let adminId = authService.currentUser?.id else {
            return
        }
        
        Task {
            try? await breachService.acknowledgeBreach(breachId: breachId, adminId: adminId)
        }
    }
}



// MARK: - Admin Incident List

struct AdminIncidentListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var incidentService = IncidentReportService()
    
    var body: some View {
        List {
            ForEach(incidentService.incidents) { incident in
                NavigationLink {
                    AdminIncidentDetailView(incident: incident)
                        .environmentObject(authService)
                } label: {
                    IncidentRowView(incident: incident)
                }
            }
        }
        .navigationTitle("All Incidents")
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

// MARK: - Admin Incident Detail

struct AdminIncidentDetailView: View {
    let incident: IncidentReport
    @EnvironmentObject var authService: AuthService
    @StateObject private var incidentService = IncidentReportService()
    
    @State private var reviewNotes = ""
    @State private var selectedStatus: IncidentReport.ReportStatus
    @State private var isUpdating = false
    
    init(incident: IncidentReport) {
        self.incident = incident
        _selectedStatus = State(initialValue: incident.status)
        _reviewNotes = State(initialValue: incident.reviewNotes ?? "")
    }
    
    var body: some View {
        Form {
            // Incident details (reuse from IncidentDetailView)
            Section("Details") {
                DetailRow(label: "Reporter", value: incident.reporterName)
                DetailRow(label: "Type", value: incident.incidentType.displayName)
                DetailRow(label: "Severity", value: incident.severity.displayName)
                DetailRow(label: "Reported", value: incident.reportedAt.formatted(date: .abbreviated, time: .shortened))
            }
            
            Section("Description") {
                Text(incident.description)
                    .font(.body)
            }
            
            if let address = incident.address {
                Section("Location") {
                    Text(address)
                }
            }
            
            // Admin actions
            Section("Review") {
                Picker("Status", selection: $selectedStatus) {
                    ForEach([IncidentReport.ReportStatus.pending, .underReview, .resolved, .closed], id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                
                TextEditor(text: $reviewNotes)
                    .frame(minHeight: 100)
                
                Button {
                    updateIncident()
                } label: {
                    if isUpdating {
                        ProgressView()
                    } else {
                        Text("Update Status")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(Color.blue)
                .disabled(isUpdating)
            }
        }
        .navigationTitle("Review Incident")
    }
    
    private func updateIncident() {
        guard let incidentId = incident.id,
              let adminId = authService.currentUser?.id else {
            return
        }
        
        isUpdating = true
        
        Task {
            try? await incidentService.updateIncidentStatus(
                incidentId: incidentId,
                status: selectedStatus,
                reviewerId: adminId,
                reviewNotes: reviewNotes.isEmpty ? nil : reviewNotes
            )
            
            isUpdating = false
        }
    }
}

#Preview {
    NavigationStack {
        AdminSafetyDashboardView()
            .environmentObject(AuthService())
    }
}

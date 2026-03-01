//
//  AdminAlertsDashboardView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-01.
//

import SwiftUI
import FirebaseFirestore
import Combine

struct AdminAlertsDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AdminAlertsViewModel()
    @State private var showingCreateAlert = false
    @State private var selectedAlert: Alert?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading alerts...")
                } else if viewModel.alerts.isEmpty {
                    emptyStateView
                } else {
                    alertsList
                }
            }
            .navigationTitle("Alert Center")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateAlert = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showingCreateAlert) {
                AdminAlertCreationView()
            }
            .sheet(item: $selectedAlert) { alert in
                AdminAlertDetailView(alert: alert)
            }
            .onAppear {
                startListening()
            }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Alerts Sent")
                .font(.title2)
                .bold()
            
            Text("Create your first alert to communicate with your team.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showingCreateAlert = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Alert")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Alerts List
    
    private var alertsList: some View {
        List {
            // Active Alerts
            if !viewModel.activeAlerts.isEmpty {
                Section("Active Alerts") {
                    ForEach(viewModel.activeAlerts) { alert in
                        AdminAlertRowView(
                            alert: alert,
                            responseStats: viewModel.getResponseStats(for: alert)
                        )
                        .onTapGesture {
                            selectedAlert = alert
                        }
                    }
                }
            }
            
            // Past Alerts
            if !viewModel.inactiveAlerts.isEmpty {
                Section("Past Alerts") {
                    ForEach(viewModel.inactiveAlerts) { alert in
                        AdminAlertRowView(
                            alert: alert,
                            responseStats: viewModel.getResponseStats(for: alert)
                        )
                        .onTapGesture {
                            selectedAlert = alert
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            // Refresh is handled automatically by Firestore listener
        }
    }
    
    // MARK: - Helper Functions
    
    private func startListening() {
        guard let user = authService.currentUser else { return }
        viewModel.startListeningForAlerts(tenantId: user.tenantId)
    }
}

// MARK: - Admin Alert Row View

struct AdminAlertRowView: View {
    let alert: Alert
    let responseStats: ResponseStats
    
    struct ResponseStats {
        let totalRecipients: Int
        let respondedCount: Int
        let responseRate: Double
        let newResponseCount: Int
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Priority badge
                HStack(spacing: 4) {
                    Image(systemName: alert.priority.icon)
                    Text(alert.priority.displayName)
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priorityColor)
                .cornerRadius(6)
                
                Spacer()
                
                // Time
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Title
            Text(alert.title)
                .font(.headline)
            
            // Message preview
            Text(alert.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Response stats
            if alert.requiresResponse {
                HStack(spacing: 16) {
                    // Response rate
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(responseStats.respondedCount)/\(responseStats.totalRecipients) responded")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * responseStats.responseRate, height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                    
                    // Percentage
                    Text("\(Int(responseStats.responseRate * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                // New responses badge
                if responseStats.newResponseCount > 0 {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                        Text("\(responseStats.newResponseCount) new response\(responseStats.newResponseCount == 1 ? "" : "s")")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch alert.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: alert.createdAt, relativeTo: Date())
    }
}

// MARK: - Admin Alerts View Model

@MainActor
class AdminAlertsViewModel: ObservableObject {
    @Published var alerts: [Alert] = []
    @Published var responseCounts: [String: (total: Int, responded: Int, unread: Int)] = [:]
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var alertsListener: ListenerRegistration?
    private var responseListeners: [String: ListenerRegistration] = [:]
    
    var activeAlerts: [Alert] {
        alerts.filter { $0.isActive && !$0.isExpired }
    }
    
    var inactiveAlerts: [Alert] {
        alerts.filter { !$0.isActive || $0.isExpired }
    }
    
    func startListeningForAlerts(tenantId: String) {
        isLoading = true
        
        alertsListener = db.collection("alerts")
            .whereField("tenantId", isEqualTo: tenantId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    print("❌ Error listening for alerts: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.alerts = documents.compactMap { doc -> Alert? in
                    try? doc.data(as: Alert.self)
                }
                
                print("✅ Loaded \(self.alerts.count) alerts")
                
                // Start listening for responses for each alert
                for alert in self.alerts {
                    if let alertId = alert.id {
                        self.listenForResponses(alertId: alertId, alert: alert)
                    }
                }
            }
    }
    
    private func listenForResponses(alertId: String, alert: Alert) {
        // Remove existing listener if any
        responseListeners[alertId]?.remove()
        
        // Listen for responses
        responseListeners[alertId] = db.collection("alert_responses")
            .whereField("alertId", isEqualTo: alertId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening for responses: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let respondedCount = documents.count
                let unreadCount = documents.filter { doc in
                    (try? doc.data(as: AlertResponse.self))?.readByAdmin == false
                }.count
                
                // Calculate total recipients
                let totalRecipients = alert.recipientIds.isEmpty ? 100 : alert.recipientIds.count // TODO: Get actual count from users collection
                
                self.responseCounts[alertId] = (total: totalRecipients, responded: respondedCount, unread: unreadCount)
            }
    }
    
    func getResponseStats(for alert: Alert) -> AdminAlertRowView.ResponseStats {
        guard let alertId = alert.id,
              let counts = responseCounts[alertId] else {
            return AdminAlertRowView.ResponseStats(
                totalRecipients: 0,
                respondedCount: 0,
                responseRate: 0.0,
                newResponseCount: 0
            )
        }
        
        let rate = counts.total > 0 ? Double(counts.responded) / Double(counts.total) : 0.0
        
        return AdminAlertRowView.ResponseStats(
            totalRecipients: counts.total,
            respondedCount: counts.responded,
            responseRate: rate,
            newResponseCount: counts.unread
        )
    }
    
    func stopListening() {
        alertsListener?.remove()
        responseListeners.values.forEach { $0.remove() }
        responseListeners.removeAll()
    }
    
    deinit {
        alertsListener?.remove()
        responseListeners.values.forEach { $0.remove() }
    }
}

#Preview {
    AdminAlertsDashboardView()
        .environmentObject(AuthService())
}

//
//  UserAlertsView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-01.
//

import SwiftUI

struct UserAlertsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var alertService: AlertService  // ✅ Changed from @StateObject
    @State private var selectedAlert: Alert?
    
    var body: some View {
        NavigationStack {
            Group {
                if alertService.isLoading {
                    ProgressView("Loading alerts...")
                } else if alertService.alerts.isEmpty {
                    emptyStateView
                } else {
                    alertsList
                }
            }
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedAlert) { alert in
                AlertDetailView(alert: alert, alertService: alertService)
            }
            .onAppear {
                startListening()
            }
            // Don't stop listening when view disappears - keep data loaded
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Alerts")
                .font(.title2)
                .bold()
            
            Text("You're all caught up! New alerts will appear here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Alerts List
    
    private var alertsList: some View {
        List {
            // Group by priority
            if !criticalAlerts.isEmpty {
                Section(header: priorityHeader(priority: .critical)) {
                    ForEach(criticalAlerts) { alert in
                        AlertRowView(alert: alert, alertService: alertService)
                            .onTapGesture {
                                selectedAlert = alert
                            }
                    }
                }
            }
            
            if !highAlerts.isEmpty {
                Section(header: priorityHeader(priority: .high)) {
                    ForEach(highAlerts) { alert in
                        AlertRowView(alert: alert, alertService: alertService)
                            .onTapGesture {
                                selectedAlert = alert
                            }
                    }
                }
            }
            
            if !mediumAlerts.isEmpty {
                Section(header: priorityHeader(priority: .medium)) {
                    ForEach(mediumAlerts) { alert in
                        AlertRowView(alert: alert, alertService: alertService)
                            .onTapGesture {
                                selectedAlert = alert
                            }
                    }
                }
            }
            
            if !lowAlerts.isEmpty {
                Section(header: priorityHeader(priority: .low)) {
                    ForEach(lowAlerts) { alert in
                        AlertRowView(alert: alert, alertService: alertService)
                            .onTapGesture {
                                selectedAlert = alert
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Priority Header
    
    private func priorityHeader(priority: Alert.AlertPriority) -> some View {
        HStack {
            Image(systemName: priority.icon)
            Text(priority.displayName.uppercased())
        }
        .foregroundColor(colorForPriority(priority))
    }
    
    // MARK: - Computed Properties
    
    private var criticalAlerts: [Alert] {
        alertService.alerts.filter { $0.priority == .critical && !$0.isExpired }
    }
    
    private var highAlerts: [Alert] {
        alertService.alerts.filter { $0.priority == .high && !$0.isExpired }
    }
    
    private var mediumAlerts: [Alert] {
        alertService.alerts.filter { $0.priority == .medium && !$0.isExpired }
    }
    
    private var lowAlerts: [Alert] {
        alertService.alerts.filter { $0.priority == .low && !$0.isExpired }
    }
    
    // MARK: - Helper Functions
    
    private func startListening() {
        guard let user = authService.currentUser,
              let userId = user.id else {
            return
        }
        
        alertService.startListeningForUserAlerts(userId: userId, tenantId: user.tenantId)
    }
    
    private func colorForPriority(_ priority: Alert.AlertPriority) -> Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

// MARK: - Alert Row View

struct AlertRowView: View {
    let alert: Alert
    @ObservedObject var alertService: AlertService
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Priority Icon
            Image(systemName: alert.priority.icon)
                .font(.title2)
                .foregroundColor(priorityColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(alert.title)
                    .font(.headline)
                    .foregroundColor(isUnread ? .primary : .secondary)
                
                // Sender and time
                HStack {
                    Text("From: \(alert.senderName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Response status
                if let status = alertService.getStatus(for: alert.id ?? "") {
                    if status.hasResponded {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Responded")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else if alert.requiresResponse {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("Response Required")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            // Unread indicator
            if isUnread {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
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
    
    private var isUnread: Bool {
        guard let status = alertService.getStatus(for: alert.id ?? "") else {
            return true
        }
        return !status.opened
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: alert.createdAt, relativeTo: Date())
    }
}

#Preview {
    UserAlertsView()
        .environmentObject(AuthService())
}

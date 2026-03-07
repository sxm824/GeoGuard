//
//  SharedComponents.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//

import SwiftUI

/*
 SHARED COMPONENTS
 
 This file contains reusable UI components used throughout the GeoGuard app.
 These components help maintain consistency and reduce code duplication.
 
 Components included:
 - StatCard: Display statistics with icon, value, and title
 - DetailRow: Display label-value pairs in forms/detail views
 - IncidentRowView: Display incident information in lists
 - StatusBadge: Display incident severity and status indicators
 - ErrorAlertModifier: Display error alerts consistently across the app
 
 Usage Examples:
 
 1. StatCard:
    StatCard(title: "Active Users", value: "42", icon: "person.fill", color: .blue)
 
 2. DetailRow:
    DetailRow(label: "Name", value: "John Doe")
    DetailRow(label: "Status", value: "Active", color: .green)
 
 3. IncidentRowView:
    IncidentRowView(incident: myIncident)
 
 4. StatusBadge:
    StatusBadge(status: .pending, severity: .high)
 
 5. Error Alert:
    .errorAlert($viewModel.error, title: "Error")
 
 Simply use these components in any SwiftUI view without importing anything extra.
 They are available globally once added to the target.
 */

// MARK: - Error Alert View Modifier

/// A reusable view modifier for displaying error alerts consistently
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?
    let title: String
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.localizedDescription)
                        
                        if let localizedError = error as? LocalizedError,
                           let suggestion = localizedError.recoverySuggestion {
                            Text(suggestion)
                                .font(.caption)
                        }
                    }
                }
            }
    }
}

extension View {
    /// Presents an alert when an error occurs
    /// - Parameters:
    ///   - error: Binding to an optional error
    ///   - title: Title for the alert
    func errorAlert(_ error: Binding<Error?>, title: String = "Error") -> some View {
        modifier(ErrorAlertModifier(error: error, title: title))
    }
}

// MARK: - Stat Card

/// A reusable card component for displaying statistics with an icon, value, and title
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Detail Row

/// A reusable row component for displaying label-value pairs
struct DetailRow: View {
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Incident Row View

/// A reusable row component for displaying incident information in lists
struct IncidentRowView: View {
    let incident: IncidentReport
    
    var body: some View {
        HStack {
            Image(systemName: incident.incidentType.icon)
                .font(.title3)
                .foregroundColor(severityColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(incident.title)
                    .font(.headline)
                
                Text(incident.incidentType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(incident.reportedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: incident.status, severity: incident.severity)
        }
        .padding(.vertical, 4)
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

// MARK: - Status Badge

/// A reusable badge component for displaying incident status and severity
struct StatusBadge: View {
    let status: IncidentReport.ReportStatus
    let severity: IncidentReport.Severity
    
    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)
            
            Text(severity.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    var severityColor: Color {
        switch severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Previews

#Preview("Stat Card") {
    StatCard(
        title: "Active Users",
        value: "42",
        icon: "person.fill",
        color: .blue
    )
    .padding()
}

#Preview("Detail Row") {
    VStack {
        DetailRow(label: "Name", value: "John Doe")
        DetailRow(label: "Status", value: "Active", color: .green)
        DetailRow(label: "Location", value: "New York")
    }
    .padding()
}

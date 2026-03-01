//
//  AlertDetailView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-01.
//

import SwiftUI
import CoreLocation

struct AlertDetailView: View {
    let alert: Alert
    @ObservedObject var alertService: AlertService
    @EnvironmentObject var authService: AuthService
    @StateObject private var locationManager = LocationManager()
    
    @State private var customResponse = ""
    @State private var isSubmitting = false
    @State private var showingSuccessMessage = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    alertHeader
                    
                    Divider()
                    
                    // Message
                    alertMessage
                    
                    Divider()
                    
                    // Response section (only if not already responded)
                    if !hasResponded && alert.requiresResponse && !alert.isExpired {
                        responseSection
                    } else if hasResponded {
                        respondedSection
                    } else if alert.isExpired {
                        expiredSection
                    }
                }
                .padding()
            }
            .navigationTitle("Alert Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                markAsOpened()
            }
            .alert("Success", isPresented: $showingSuccessMessage) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your response has been sent successfully.")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Alert Header
    
    private var alertHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Priority Badge
            HStack {
                Image(systemName: alert.priority.icon)
                Text(alert.priority.displayName.uppercased())
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(priorityColor)
            .cornerRadius(8)
            
            // Title
            Text(alert.title)
                .font(.title2)
                .fontWeight(.bold)
            
            // Metadata
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text("From: \(alert.senderName)")
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Sent: \(formattedDate)")
                }
                
                if let expiresAt = alert.expiresAt {
                    HStack {
                        Image(systemName: "hourglass")
                        Text("Expires: \(formattedExpiryDate(expiresAt))")
                    }
                    .foregroundColor(alert.isExpired ? .red : .orange)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Alert Message
    
    private var alertMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message")
                .font(.headline)
            
            Text(alert.message)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Response Section
    
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Response")
                .font(.headline)
            
            // Quick Response Buttons
            if !alert.quickResponses.isEmpty {
                Text("Quick Responses:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    ForEach(alert.quickResponses, id: \.self) { response in
                        quickResponseButton(text: response)
                    }
                }
            }
            
            // Custom Response
            if alert.allowCustomResponse {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Or write a custom response:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $customResponse)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Button(action: submitCustomResponse) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Send Custom Response")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(customResponse.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(customResponse.isEmpty || isSubmitting)
                }
            }
        }
    }
    
    // MARK: - Quick Response Button
    
    private func quickResponseButton(text: String) -> some View {
        Button(action: {
            submitQuickResponse(text: text)
        }) {
            HStack {
                Image(systemName: iconForResponse(text))
                Text(text)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isSubmitting)
    }
    
    // MARK: - Responded Section
    
    private var respondedSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Response Sent")
                .font(.title3)
                .fontWeight(.bold)
            
            if let status = alertService.getStatus(for: alert.id ?? ""),
               let respondedAt = status.respondedAt {
                Text("You responded \(timeAgo(from: respondedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Expired Section
    
    private var expiredSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.xmark.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Alert Expired")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("This alert is no longer accepting responses")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    
    private func markAsOpened() {
        guard let userId = authService.currentUser?.id,
              let alertId = alert.id else {
            return
        }
        
        Task {
            await alertService.markAlertAsOpened(alertId: alertId, userId: userId)
        }
    }
    
    private func submitQuickResponse(text: String) {
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            
            do {
                try await submitResponse(text: text, type: .quick)
                showingSuccessMessage = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func submitCustomResponse() {
        guard !customResponse.isEmpty else { return }
        
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            
            do {
                try await submitResponse(text: customResponse, type: .custom)
                showingSuccessMessage = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func submitResponse(text: String, type: AlertResponse.ResponseType) async throws {
        guard let user = authService.currentUser,
              let userId = user.id,
              let alertId = alert.id else {
            throw NSError(domain: "AlertError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User or alert not found"])
        }
        
        // Get current location if available
        var location: CLLocationCoordinate2D?
        if locationManager.hasAlwaysPermission,
           let currentLoc = locationManager.currentLocation {
            location = currentLoc.coordinate
        }
        
        try await alertService.submitResponse(
            alertId: alertId,
            userId: userId,
            userName: user.fullName,
            tenantId: user.tenantId,
            responseText: text,
            responseType: type,
            location: location
        )
    }
    
    private var hasResponded: Bool {
        guard let alertId = alert.id else { return false }
        return alertService.hasResponded(to: alertId)
    }
    
    private var priorityColor: Color {
        switch alert.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: alert.createdAt)
    }
    
    private func formattedExpiryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func iconForResponse(_ text: String) -> String {
        let lowercased = text.lowercased()
        if lowercased.contains("safe") || lowercased.contains("ok") {
            return "checkmark.circle.fill"
        } else if lowercased.contains("help") || lowercased.contains("assist") {
            return "exclamationmark.triangle.fill"
        } else if lowercased.contains("route") || lowercased.contains("way") {
            return "arrow.right.circle.fill"
        } else {
            return "message.fill"
        }
    }
}

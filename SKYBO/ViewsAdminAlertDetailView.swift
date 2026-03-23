//
//  AdminAlertDetailView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-01.
//

import SwiftUI
import FirebaseFirestore
import MapKit
import Combine

struct AdminAlertDetailView: View {
    let alert: Alert
    @StateObject private var viewModel = AdminAlertDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Alert Info Section
                Section("Alert Details") {
                    alertInfoView
                }
                
                // Response Stats Section
                if alert.requiresResponse {
                    Section("Response Statistics") {
                        responseStatsView
                    }
                }
                
                // Responses Section
                if !viewModel.responses.isEmpty {
                    Section("Responses (\(viewModel.responses.count))") {
                        ForEach(viewModel.responses) { response in
                            ResponseRowView(response: response)
                                .onTapGesture {
                                    markAsRead(response: response)
                                }
                        }
                    }
                }
                
                // Who Hasn't Responded Section
                if alert.requiresResponse && !viewModel.nonResponders.isEmpty {
                    Section("Waiting for Response (\(viewModel.nonResponders.count))") {
                        ForEach(viewModel.nonResponders, id: \.self) { userId in
                            HStack {
                                Image(systemName: "person.fill.questionmark")
                                    .foregroundColor(.orange)
                                Text("User ID: \(userId)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button {
                        deactivateAlert()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Deactivate Alert")
                        }
                        .foregroundColor(.red)
                    }
                }
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
                viewModel.loadAlertData(alert: alert)
            }
        }
    }
    
    // MARK: - Alert Info View
    
    private var alertInfoView: some View {
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
                .font(.title3)
                .fontWeight(.bold)
            
            // Metadata
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text("Sent by: \(alert.senderName)")
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Sent: \(formattedDate)")
                }
                
                HStack {
                    Image(systemName: "person.2.fill")
                    Text("Recipients: \(recipientText)")
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
            
            Divider()
            
            // Message
            Text(alert.message)
                .font(.body)
            
            // Quick Responses
            if !alert.quickResponses.isEmpty {
                Divider()
                
                Text("Quick Response Options:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(alert.quickResponses, id: \.self) { response in
                    Text("• \(response)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - Response Stats View
    
    private var responseStatsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(viewModel.responses.count)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Responses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(viewModel.nonResponders.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Pending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Response rate progress
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * viewModel.responseRate, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(viewModel.responseRate * 100))% Response Rate")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Functions
    
    private var priorityColor: Color {
        switch alert.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    private var recipientText: String {
        if alert.recipientIds.isEmpty {
            return "All Users"
        } else {
            return "\(alert.recipientIds.count) Users"
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
    
    private func markAsRead(response: AlertResponse) {
        guard let responseId = response.id, !response.readByAdmin else { return }
        
        Task {
            do {
                try await Firestore.firestore()
                    .collection("alert_responses")
                    .document(responseId)
                    .updateData(["readByAdmin": true])
                print("✅ Marked response as read")
            } catch {
                print("❌ Error marking response as read: \(error.localizedDescription)")
            }
        }
    }
    
    private func deactivateAlert() {
        guard let alertId = alert.id else { return }
        
        Task {
            do {
                try await Firestore.firestore()
                    .collection("alerts")
                    .document(alertId)
                    .updateData(["isActive": false])
                print("✅ Alert deactivated")
                dismiss()
            } catch {
                print("❌ Error deactivating alert: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Response Row View

struct ResponseRowView: View {
    let response: AlertResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // User info
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(response.userName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Unread badge
                if !response.readByAdmin {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                }
            }
            
            // Response text
            Text(response.responseText)
                .font(.body)
                .padding(.leading, 8)
            
            // Location badge
            if response.latitude != nil && response.longitude != nil {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                    Text("Location included")
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.leading, 8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: response.timestamp, relativeTo: Date())
    }
}

// MARK: - Admin Alert Detail View Model

@MainActor
class AdminAlertDetailViewModel: ObservableObject {
    @Published var responses: [AlertResponse] = []
    @Published var allRecipients: [String] = []
    @Published var nonResponders: [String] = []
    
    private let db = Firestore.firestore()
    private var responsesListener: ListenerRegistration?
    
    var responseRate: Double {
        let total = allRecipients.isEmpty ? 1 : allRecipients.count
        return Double(responses.count) / Double(total)
    }
    
    func loadAlertData(alert: Alert) {
        // Load recipients
        Task {
            allRecipients = await getRecipients(for: alert)
            updateNonResponders()
        }
        
        // Listen for responses
        guard let alertId = alert.id else { return }
        
        responsesListener = db.collection("alert_responses")
            .whereField("alertId", isEqualTo: alertId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening for responses: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.responses = documents.compactMap { doc -> AlertResponse? in
                    try? doc.data(as: AlertResponse.self)
                }
                
                self.updateNonResponders()
                
                print("✅ Loaded \(self.responses.count) responses")
            }
    }
    
    private func getRecipients(for alert: Alert) async -> [String] {
        if !alert.recipientIds.isEmpty {
            return alert.recipientIds
        }
        
        // If empty, get all users in tenant
        do {
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: alert.tenantId)
                .getDocuments()
            
            return snapshot.documents.map { $0.documentID }
        } catch {
            print("❌ Error fetching recipients: \(error.localizedDescription)")
            return []
        }
    }
    
    private func updateNonResponders() {
        let responderIds = Set(responses.map { $0.userId })
        nonResponders = allRecipients.filter { !responderIds.contains($0) }
    }
    
    deinit {
        responsesListener?.remove()
    }
}

#Preview {
    // Create a sample alert for preview
    let sampleAlert = Alert(
        id: "sample123",
        tenantId: "tenant1",
        senderId: "admin1",
        senderName: "Admin Sarah",
        recipientIds: [],
        title: "Safety Check Required",
        message: "Please confirm your safety status immediately.",
        priority: .critical,
        type: .safetyCheckin,
        requiresResponse: true,
        quickResponses: ["I'm Safe", "Need Help"],
        allowCustomResponse: true,
        createdAt: Date(),
        expiresAt: Date().addingTimeInterval(3600),
        isActive: true
    )
    
    AdminAlertDetailView(alert: sampleAlert)
}

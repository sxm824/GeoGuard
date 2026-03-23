//
//  AdminAlertCreationView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-01.
//

import SwiftUI
import FirebaseFirestore

struct AdminAlertCreationView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    // Alert properties
    @State private var title = ""
    @State private var message = ""
    @State private var selectedPriority: Alert.AlertPriority = .medium
    @State private var selectedType: Alert.AlertType = .announcement
    @State private var requiresResponse = false
    @State private var allowCustomResponse = true
    @State private var quickResponses: [String] = []
    @State private var newQuickResponse = ""
    @State private var selectedRecipients: RecipientType = .allUsers
    @State private var specificUserIds: [String] = []
    @State private var expirationEnabled = false
    @State private var expirationHours = 24
    
    // UI State
    @State private var isSending = false
    @State private var showingSuccessAlert = false
    @State private var errorMessage: String?
    
    enum RecipientType {
        case allUsers
        case fieldPersonnel
        case admins
        case specific
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Alert Details") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if message.isEmpty {
                                Text("Message")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                }
                
                // Priority Section
                Section("Priority") {
                    Picker("Priority Level", selection: $selectedPriority) {
                        ForEach([Alert.AlertPriority.low, .medium, .high, .critical], id: \.self) { priority in
                            HStack {
                                Image(systemName: priority.icon)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Type Section
                Section("Alert Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach([Alert.AlertType.announcement, .safetyCheckin, .emergency, .task], id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                }
                
                // Recipients Section
                Section("Send To") {
                    Picker("Recipients", selection: $selectedRecipients) {
                        Text("All Users").tag(RecipientType.allUsers)
                        Text("Field Personnel Only").tag(RecipientType.fieldPersonnel)
                        Text("Admins Only").tag(RecipientType.admins)
                        Text("Specific Users").tag(RecipientType.specific)
                    }
                    .pickerStyle(.menu)
                    
                    if selectedRecipients == .specific {
                        // TODO: Add user selector
                        Text("User selection coming soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Response Section
                Section("Response Options") {
                    Toggle("Require Response", isOn: $requiresResponse)
                    
                    if requiresResponse {
                        Toggle("Allow Custom Response", isOn: $allowCustomResponse)
                        
                        // Quick Responses
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Response Buttons")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // List of quick responses
                            ForEach(quickResponses, id: \.self) { response in
                                HStack {
                                    Text(response)
                                    Spacer()
                                    Button(role: .destructive) {
                                        quickResponses.removeAll { $0 == response }
                                    } label: {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            // Add new quick response
                            HStack {
                                TextField("Add quick response", text: $newQuickResponse)
                                    .textInputAutocapitalization(.words)
                                
                                Button {
                                    if !newQuickResponse.isEmpty {
                                        quickResponses.append(newQuickResponse)
                                        newQuickResponse = ""
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                                .disabled(newQuickResponse.isEmpty)
                            }
                            
                            // Preset templates
                            if quickResponses.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Quick Templates:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        quickTemplateButton("I'm Safe")
                                        quickTemplateButton("Need Help")
                                        quickTemplateButton("On My Way")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Expiration Section
                Section("Expiration") {
                    Toggle("Set Expiration Time", isOn: $expirationEnabled)
                    
                    if expirationEnabled {
                        Stepper("Expires in \(expirationHours) hours", value: $expirationHours, in: 1...168)
                    }
                }
                
                // Preview Section
                Section("Preview") {
                    alertPreview
                }
            }
            .navigationTitle("Create Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        sendAlert()
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Send")
                                .bold()
                        }
                    }
                    .disabled(!isValid || isSending)
                }
            }
            .alert("Success", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Alert sent successfully!")
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
    
    // MARK: - Alert Preview
    
    private var alertPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Priority badge
            HStack {
                Image(systemName: selectedPriority.icon)
                Text(selectedPriority.displayName.uppercased())
            }
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(priorityColor)
            .cornerRadius(8)
            
            // Title
            Text(title.isEmpty ? "Alert Title" : title)
                .font(.headline)
                .foregroundColor(title.isEmpty ? .secondary : .primary)
            
            // Message
            Text(message.isEmpty ? "Alert message will appear here..." : message)
                .font(.body)
                .foregroundColor(message.isEmpty ? .secondary : .primary)
            
            // Quick responses preview
            if requiresResponse && !quickResponses.isEmpty {
                Divider()
                
                Text("Quick Responses:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(quickResponses, id: \.self) { response in
                    Text("• \(response)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Template Button
    
    private func quickTemplateButton(_ text: String) -> some View {
        Button {
            quickResponses.append(text)
        } label: {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(6)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !title.isEmpty && !message.isEmpty
    }
    
    private var priorityColor: Color {
        switch selectedPriority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    // MARK: - Send Alert
    
    private func sendAlert() {
        guard let user = authService.currentUser,
              let senderId = user.id else {
            errorMessage = "Unable to get user information"
            return
        }
        
        Task {
            isSending = true
            defer { isSending = false }
            
            do {
                // Determine recipient IDs based on selection
                let recipientIds = try await getRecipientIds()
                
                // Calculate expiration date
                var expiresAt: Date?
                if expirationEnabled {
                    expiresAt = Date().addingTimeInterval(TimeInterval(expirationHours * 3600))
                }
                
                // Create alert object
                let alert = Alert(
                    tenantId: user.tenantId,
                    senderId: senderId,
                    senderName: user.fullName,
                    recipientIds: recipientIds,
                    title: title,
                    message: message,
                    priority: selectedPriority,
                    type: selectedType,
                    requiresResponse: requiresResponse,
                    quickResponses: quickResponses,
                    allowCustomResponse: allowCustomResponse,
                    createdAt: Date(),
                    expiresAt: expiresAt,
                    isActive: true
                )
                
                // Save to Firestore
                let db = Firestore.firestore()
                let _ = try db.collection("alerts").addDocument(from: alert)
                
                print("✅ Alert sent successfully!")
                showingSuccessAlert = true
                
            } catch {
                print("❌ Error sending alert: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Get Recipient IDs
    
    private func getRecipientIds() async throws -> [String] {
        guard let user = authService.currentUser else {
            throw NSError(domain: "AlertError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        switch selectedRecipients {
        case .allUsers:
            // Empty array means all users in tenant
            return []
            
        case .fieldPersonnel:
            // Query users with field_personnel role
            let db = Firestore.firestore()
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: user.tenantId)
                .whereField("role", isEqualTo: "field_personnel")
                .getDocuments()
            
            return snapshot.documents.compactMap { $0.documentID }
            
        case .admins:
            // Query users with admin role
            let db = Firestore.firestore()
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: user.tenantId)
                .whereField("role", isEqualTo: "admin")
                .getDocuments()
            
            return snapshot.documents.compactMap { $0.documentID }
            
        case .specific:
            // Return specific user IDs
            return specificUserIds
        }
    }
}

#Preview {
    AdminAlertCreationView()
        .environmentObject(AuthService())
}

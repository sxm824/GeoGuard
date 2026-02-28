//
//  SuperAdminCreationHelper.swift
//  GeoGuard
//
//  Helper view to create super admin Firestore documents
//  This is a one-time setup tool - remove after creating your super admins
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SuperAdminCreationHelper: View {
    @EnvironmentObject var authService: AuthService
    
    @State private var userId = ""
    @State private var email = ""
    @State private var fullName = ""
    @State private var isCreating = false
    @State private var message = ""
    @State private var messageType: MessageType = .info
    
    enum MessageType {
        case info, success, error
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .error: return .red
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Super Admin Setup")
                            .font(.title)
                            .bold()
                        
                        Text("Create Firestore document for super admin users")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Instructions", systemImage: "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Create user in Firebase Authentication first")
                            Text("2. Copy the UID from Firebase Console")
                            Text("3. Enter details below and tap 'Create Document'")
                            Text("4. Remove this helper view after setup")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    Divider()
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // User ID Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("User ID (UID)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Firebase Auth UID", text: $userId)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                            
                            Text("Copy this from Firebase Console → Authentication → Users")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email Address")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("email@example.com", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                            
                            Text("Must match the email in Firebase Authentication")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Full Name Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Full Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("John Doe", text: $fullName)
                                .textFieldStyle(.roundedBorder)
                            
                            Text("Display name for this super admin")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Preview of what will be created
                    if !userId.isEmpty && !email.isEmpty && !fullName.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Document Preview", systemImage: "doc.text.fill")
                                .font(.headline)
                                .foregroundColor(.purple)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                previewField("Document ID", userId)
                                previewField("Email", email)
                                previewField("Full Name", fullName)
                                previewField("Initials", generateInitials())
                                previewField("Role", "super_admin")
                                previewField("Tenant ID", "PLATFORM")
                                previewField("Active", "true")
                            }
                            .font(.caption)
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Create Button
                    Button {
                        Task {
                            await createSuperAdmin()
                        }
                    } label: {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                            }
                            
                            Image(systemName: "crown.fill")
                            Text(isCreating ? "Creating..." : "Create Super Admin Document")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(!isFormValid || isCreating)
                    .opacity(isFormValid ? 1 : 0.5)
                    .padding(.horizontal)
                    
                    // Message Display
                    if !message.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: messageIcon)
                                Text(message)
                                    .font(.subheadline)
                            }
                            
                            if messageType == .success {
                                Text("You can now sign in with this account using the Super Admin login page.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(messageType.color.opacity(0.15))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Super Admin Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func previewField(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Text(value)
                .bold()
                .font(.system(.caption, design: .monospaced))
            Spacer()
        }
    }
    
    private var isFormValid: Bool {
        !userId.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@")
    }
    
    private var messageIcon: String {
        switch messageType {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private func generateInitials() -> String {
        let components = fullName
            .components(separatedBy: " ")
            .filter { !$0.isEmpty }
        
        let initials = components
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
        
        return initials.isEmpty ? "SA" : initials
    }
    
    private func createSuperAdmin() async {
        isCreating = true
        message = ""
        
        do {
            // Validate Firebase Auth user exists
            let db = Firestore.firestore()
            let userQuery = try await db.collection("users")
                .document(userId.trimmingCharacters(in: .whitespaces))
                .getDocument()
            
            if userQuery.exists {
                message = "⚠️ Document already exists. Do you want to overwrite it?"
                messageType = .error
                isCreating = false
                return
            }
            
            // Create the super admin document
            try await authService.createSuperAdminDocument(
                userId: userId.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                fullName: fullName.trimmingCharacters(in: .whitespaces)
            )
            
            message = "✅ Super admin document created successfully!"
            messageType = .success
            
            // Clear form
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                userId = ""
                email = ""
                fullName = ""
            }
            
        } catch {
            message = "❌ Error: \(error.localizedDescription)"
            messageType = .error
        }
        
        isCreating = false
    }
}

#Preview {
    SuperAdminCreationHelper()
        .environmentObject(AuthService())
}

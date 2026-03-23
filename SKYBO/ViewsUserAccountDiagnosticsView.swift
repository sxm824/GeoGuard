//
//  UserAccountDiagnosticsView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

/// A diagnostic tool for administrators to check and fix user account issues
struct UserAccountDiagnosticsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = DiagnosticsViewModel()
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("User Account Diagnostics")
                        .font(.headline)
                    Text("Check for accounts with missing or incomplete user documents")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section("Scan Options") {
                Button {
                    Task {
                        await viewModel.scanOrphanedAuthAccounts()
                    }
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Scan for Orphaned Auth Accounts")
                        Spacer()
                        if viewModel.isScanning {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isScanning)
            }
            
            if !viewModel.orphanedAccounts.isEmpty {
                Section {
                    Text("Found \(viewModel.orphanedAccounts.count) account(s) with issues")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                } header: {
                    Text("Issues Found")
                }
                
                ForEach(viewModel.orphanedAccounts) { account in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "UID", value: account.uid)
                            DetailRow(label: "Email", value: account.email)
                            
                            if let issue = account.issue {
                                Text(issue)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.vertical, 4)
                            }
                            
                            HStack(spacing: 12) {
                                Button {
                                    Task {
                                        await viewModel.deleteAuthAccount(account)
                                    }
                                } label: {
                                    Label("Delete Auth Account", systemImage: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.bordered)
                                
                                Button {
                                    // Copy UID to clipboard
                                    UIPasteboard.general.string = account.uid
                                } label: {
                                    Label("Copy UID", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundColor(errorMessage.hasPrefix("✅") ? .green : (errorMessage.hasPrefix("⚠️") || errorMessage.hasPrefix("❌") ? .red : .secondary))
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Status")
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to Fix Account Issues")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        StepView(number: "1", text: "Tap 'Scan for Orphaned Auth Accounts' to diagnose your account")
                        StepView(number: "2", text: "If issues are found, tap 'Delete Auth Account' button")
                        StepView(number: "3", text: "You'll be automatically signed out")
                        StepView(number: "4", text: "Register again using a valid invitation code")
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About This Tool")
                            .font(.subheadline)
                            .bold()
                        Text("This diagnostic tool checks if your Firebase Authentication account has a corresponding user document in Firestore. Without this document, you cannot access the app.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Help")
            }
        }
        .navigationTitle("Account Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Bullet Point Helper

private struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .fontWeight(.bold)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Step View Helper

private struct StepView: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 28, height: 28)
                Text(number)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.blue)
            }
            
            Text(text)
                .font(.callout)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - View Model

@MainActor
class DiagnosticsViewModel: ObservableObject {
    @Published var orphanedAccounts: [OrphanedAccount] = []
    @Published var isScanning = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func scanOrphanedAuthAccounts() async {
        isScanning = true
        errorMessage = nil
        orphanedAccounts = []
        
        defer { isScanning = false }
        
        // Note: This is a simplified version. In production, you'd need to use
        // Firebase Admin SDK or Cloud Functions to properly enumerate all auth users.
        // For now, we can only show the current user's status if they have this issue.
        
        guard let currentAuthUser = Auth.auth().currentUser else {
            errorMessage = "❌ No authenticated user to check. Please sign in first."
            return
        }
        
        do {
            // Check if current user has a Firestore document
            let userDoc = try await db.collection("users").document(currentAuthUser.uid).getDocument()
            
            if !userDoc.exists {
                orphanedAccounts.append(OrphanedAccount(
                    uid: currentAuthUser.uid,
                    email: currentAuthUser.email ?? "No email",
                    issue: "Firebase Auth account exists, but no Firestore user document was created during signup."
                ))
                
                errorMessage = """
                ⚠️ Account Issue Found
                
                Problem: This Firebase Auth account was created, but the corresponding user document in Firestore is missing.
                
                Common Causes:
                • Signup process was interrupted
                • Network error during user creation
                • Firestore security rules blocked document creation
                • User signed up without a valid invitation
                
                Solution:
                1. Delete this auth account using the button below
                2. Sign out completely
                3. Register again with a valid invitation code
                4. Ensure you have a stable internet connection
                
                Note: Your email (\(currentAuthUser.email ?? "unknown")) will be freed up and you can use it again.
                """
            } else {
                // Check if the user document has all required fields
                let data = userDoc.data() ?? [:]
                let requiredFields = ["email", "fullName", "tenantId", "role", "isActive"]
                let missingFields = requiredFields.filter { !data.keys.contains($0) }
                
                if !missingFields.isEmpty {
                    orphanedAccounts.append(OrphanedAccount(
                        uid: currentAuthUser.uid,
                        email: currentAuthUser.email ?? "No email",
                        issue: "User document is missing required fields: \(missingFields.joined(separator: ", "))"
                    ))
                    
                    errorMessage = """
                    ⚠️ Incomplete User Document
                    
                    Your user document exists but is missing required fields: \(missingFields.joined(separator: ", "))
                    
                    This suggests the signup process didn't complete properly. Please delete your account and re-register.
                    """
                } else {
                    errorMessage = "✅ Current user account is properly configured!\n\nAll required fields are present and the account is set up correctly."
                }
            }
        } catch {
            errorMessage = "❌ Error scanning account: \(error.localizedDescription)\n\nThis might be a Firestore permissions issue or network problem."
        }
    }
    
    func deleteAuthAccount(_ account: OrphanedAccount) async {
        guard let currentUser = Auth.auth().currentUser,
              currentUser.uid == account.uid else {
            errorMessage = "Can only delete current user's account. Please have the user sign in first."
            return
        }
        
        do {
            // Delete the Firebase Auth account
            try await currentUser.delete()
            
            // Remove from list
            orphanedAccounts.removeAll { $0.id == account.id }
            
            errorMessage = "Auth account deleted successfully. User can now re-register."
            
            // Sign out
            try Auth.auth().signOut()
        } catch {
            errorMessage = "Error deleting account: \(error.localizedDescription)"
        }
    }
}

// MARK: - Models

struct OrphanedAccount: Identifiable {
    let id = UUID()
    let uid: String
    let email: String
    let issue: String?
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserAccountDiagnosticsView()
            .environmentObject(AuthService())
    }
}

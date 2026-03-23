//
//  CompanySettingsView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-26.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct CompanySettingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = CompanySettingsViewModel()
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Form {
            // Organization Profile
            Section("Organization Profile") {
                if let tenant = viewModel.tenant {
                    LabeledContent("Organization Name") {
                        Text(tenant.name)
                            .foregroundColor(.secondary)
                    }
                    
                    if let domain = tenant.domain {
                        LabeledContent("Email Domain") {
                            Text(domain)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    LabeledContent("Subscription Tier") {
                        Text(tenant.subscription.rawValue.capitalized)
                            .foregroundColor(.secondary)
                    }
                    
                    LabeledContent("Status") {
                        HStack {
                            Circle()
                                .fill(tenant.isActive ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(tenant.isActive ? "Active" : "Inactive")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    LabeledContent("Max Users") {
                        Text("\(tenant.maxUsers)")
                            .foregroundColor(.secondary)
                    }
                    
                    LabeledContent("Created") {
                        Text(tenant.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Organization Settings
            Section("Organization Settings") {
                Toggle("Allow User Invites", isOn: $viewModel.allowUserInvites)
                    .onChange(of: viewModel.allowUserInvites) { _, newValue in
                        viewModel.updateSetting(key: "allowUserInvites", value: newValue)
                    }
                
                Toggle("Require Invitation Code", isOn: $viewModel.requireInvitationCode)
                    .onChange(of: viewModel.requireInvitationCode) { _, newValue in
                        viewModel.updateSetting(key: "requireInvitationCode", value: newValue)
                    }
                
                Picker("Time Zone", selection: $viewModel.timeZone) {
                    ForEach(TimeZone.knownTimeZoneIdentifiers.prefix(50), id: \.self) { tz in
                        Text(tz).tag(tz)
                    }
                }
                .onChange(of: viewModel.timeZone) { _, newValue in
                    viewModel.updateSetting(key: "timeZone", value: newValue)
                }
            }
            
            // Usage Statistics
            Section("Usage") {
                LabeledContent("Total Users") {
                    Text("\(viewModel.userCount)")
                        .foregroundColor(.secondary)
                }
                
                LabeledContent("Active Users") {
                    Text("\(viewModel.activeUserCount)")
                        .foregroundColor(.secondary)
                }
                
                if let tenant = viewModel.tenant {
                    LabeledContent("Remaining Slots") {
                        Text("\(tenant.maxUsers - viewModel.userCount)")
                            .foregroundColor(tenant.maxUsers - viewModel.userCount > 0 ? .green : .red)
                    }
                    
                    ProgressView(value: Double(viewModel.userCount), total: Double(tenant.maxUsers))
                        .tint(viewModel.userCount >= tenant.maxUsers ? .red : .blue)
                }
            }
            
            // Subscription Management
            Section("Subscription") {
                Button {
                    // TODO: Navigate to subscription upgrade page
                } label: {
                    Label("Upgrade Subscription", systemImage: "arrow.up.circle")
                }
                
                Button {
                    // TODO: Navigate to billing page
                } label: {
                    Label("Billing & Invoices", systemImage: "creditcard")
                }
            }
            
            // Admin Actions
            Section("Administration") {
                NavigationLink {
                    TransferOwnershipView()
                        .environmentObject(authService)
                } label: {
                    Label("Transfer Ownership", systemImage: "arrow.left.arrow.right")
                }
                
                NavigationLink {
                    AuditLogView()
                        .environmentObject(authService)
                } label: {
                    Label("Audit Log", systemImage: "list.bullet.clipboard")
                }
            }
            
            // Danger Zone
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Organization", systemImage: "trash")
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("Deleting your organization will permanently remove all data including users, locations, and settings. This action cannot be undone.")
                    .font(.caption)
            }
            
            if !viewModel.errorMessage.isEmpty {
                Section {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Company Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData(tenantId: authService.tenantId ?? "")
        }
        .refreshable {
            await viewModel.loadData(tenantId: authService.tenantId ?? "")
        }
        .alert("Delete Organization", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteOrganization()
                    // After deletion, sign out
                    try? authService.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to delete this organization? This will permanently delete all users, data, and settings. This action cannot be undone.")
        }
    }
}

// MARK: - Transfer Ownership View

struct TransferOwnershipView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = TransferOwnershipViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUserId: String?
    @State private var showingConfirmation = false
    
    var body: some View {
        Form {
            Section {
                Text("Select a new administrator to transfer ownership of this organization. You will be demoted to a manager role.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Section("Select New Owner") {
                if viewModel.eligibleAdmins.isEmpty {
                    Text("No eligible users found. You must have at least one other admin or manager to transfer ownership.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(viewModel.eligibleAdmins) { user in
                        Button {
                            selectedUserId = user.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.fullName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(user.role.displayName)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                if selectedUserId == user.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            
            if !viewModel.errorMessage.isEmpty {
                Section {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Transfer Ownership")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Transfer") {
                    showingConfirmation = true
                }
                .disabled(selectedUserId == nil || viewModel.isLoading)
            }
        }
        .task {
            await viewModel.loadEligibleUsers(
                tenantId: authService.tenantId ?? "",
                currentUserId: authService.currentUser?.id ?? ""
            )
        }
        .alert("Confirm Transfer", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Transfer", role: .destructive) {
                Task {
                    await viewModel.transferOwnership(
                        tenantId: authService.tenantId ?? "",
                        newOwnerId: selectedUserId ?? "",
                        currentUserId: authService.currentUser?.id ?? ""
                    )
                    if viewModel.transferSuccess {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to transfer ownership? You will lose administrative privileges.")
        }
    }
}

// MARK: - Audit Log View

struct AuditLogView: View {
    var body: some View {
        List {
            Text("Audit log feature coming soon")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Audit Log")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ViewModels

@MainActor
class CompanySettingsViewModel: ObservableObject {
    @Published var tenant: Tenant?
    @Published var userCount: Int = 0
    @Published var activeUserCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    // Settings
    @Published var allowUserInvites: Bool = true
    @Published var requireInvitationCode: Bool = true
    @Published var timeZone: String = "Europe/London"
    
    private let db = Firestore.firestore()
    private let tenantService = TenantService()
    
    func loadData(tenantId: String) async {
        guard !tenantId.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        await loadTenant(tenantId: tenantId)
        await loadUserStats(tenantId: tenantId)
    }
    
    private func loadTenant(tenantId: String) async {
        do {
            let document = try await db.collection("tenants").document(tenantId).getDocument()
            tenant = try document.data(as: Tenant.self)
            
            // Load settings
            if let settings = tenant?.settings {
                allowUserInvites = settings.allowUserInvites
                requireInvitationCode = settings.requireInvitationCode
                timeZone = settings.timeZone
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadUserStats(tenantId: String) async {
        do {
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: tenantId)
                .getDocuments()
            
            userCount = snapshot.documents.count
            activeUserCount = snapshot.documents.filter { doc in
                (try? doc.data(as: User.self))?.isActive == true
            }.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateSetting(key: String, value: Any) {
        guard let tenantId = tenant?.id else { return }
        
        Task {
            do {
                try await db.collection("tenants")
                    .document(tenantId)
                    .updateData(["settings.\(key)": value])
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteOrganization() async {
        guard let tenantId = tenant?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // In production, this should be done via Cloud Function to properly clean up all data
            // For now, just mark as inactive
            try await db.collection("tenants")
                .document(tenantId)
                .updateData(["isActive": false])
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
class TransferOwnershipViewModel: ObservableObject {
    @Published var eligibleAdmins: [User] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var transferSuccess = false
    
    private let db = Firestore.firestore()
    
    func loadEligibleUsers(tenantId: String, currentUserId: String) async {
        guard !tenantId.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: tenantId)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            eligibleAdmins = snapshot.documents.compactMap { doc in
                try? doc.data(as: User.self)
            }.filter { user in
                user.id != currentUserId && (user.role == .admin || user.role == .manager)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func transferOwnership(tenantId: String, newOwnerId: String, currentUserId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Update tenant's adminUserId
            try await db.collection("tenants")
                .document(tenantId)
                .updateData(["adminUserId": newOwnerId])
            
            // Update new owner to admin role
            try await db.collection("users")
                .document(newOwnerId)
                .updateData(["role": UserRole.admin.rawValue])
            
            // Demote current user to manager
            try await db.collection("users")
                .document(currentUserId)
                .updateData(["role": UserRole.manager.rawValue])
            
            transferSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        CompanySettingsView()
            .environmentObject(AuthService())
    }
}

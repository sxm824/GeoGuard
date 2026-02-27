//
//  AllOrganizationsView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-26.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct AllOrganizationsView: View {
    @StateObject private var viewModel = AllOrganizationsViewModel()
    @State private var searchText = ""
    @State private var filterStatus: StatusFilter = .all
    
    enum StatusFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case inactive = "Inactive"
    }
    
    var filteredTenants: [Tenant] {
        var filtered = viewModel.tenants
        
        if !searchText.isEmpty {
            filtered = filtered.filter { tenant in
                tenant.name.localizedCaseInsensitiveContains(searchText) ||
                (tenant.domain?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        switch filterStatus {
        case .all:
            break
        case .active:
            filtered = filtered.filter { $0.isActive }
        case .inactive:
            filtered = filtered.filter { !$0.isActive }
        }
        
        return filtered
    }
    
    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $filterStatus) {
                    ForEach(StatusFilter.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                ForEach(filteredTenants) { tenant in
                    NavigationLink {
                        OrganizationDetailView(tenant: tenant)
                    } label: {
                        OrganizationListRow(tenant: tenant)
                    }
                }
            } header: {
                Text("\(filteredTenants.count) Organizations")
            }
        }
        .navigationTitle("All Organizations")
        .searchable(text: $searchText, prompt: "Search organizations")
        .task {
            await viewModel.loadTenants()
        }
        .refreshable {
            await viewModel.loadTenants()
        }
    }
}

struct OrganizationListRow: View {
    let tenant: Tenant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tenant.name)
                .font(.headline)
            
            HStack(spacing: 12) {
                Label(tenant.subscription.rawValue.capitalized, systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                if let domain = tenant.domain {
                    Label(domain, systemImage: "globe")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Label("\(tenant.maxUsers) users", systemImage: "person.3")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Circle()
                    .fill(tenant.isActive ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Organization Detail View

struct OrganizationDetailView: View {
    let tenant: Tenant
    
    @StateObject private var viewModel = OrganizationDetailViewModel()
    @State private var showingDeactivateConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Organization Information") {
                LabeledContent("Name", value: tenant.name)
                
                if let domain = tenant.domain {
                    LabeledContent("Domain", value: domain)
                }
                
                LabeledContent("Subscription") {
                    Text(tenant.subscription.rawValue.capitalized)
                        .foregroundColor(.orange)
                }
                
                LabeledContent("Max Users", value: "\(tenant.maxUsers)")
                
                LabeledContent("Status") {
                    HStack {
                        Circle()
                            .fill(tenant.isActive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(tenant.isActive ? "Active" : "Inactive")
                    }
                }
                
                LabeledContent("Created") {
                    Text(tenant.createdAt, style: .date)
                }
            }
            
            Section("Statistics") {
                LabeledContent("Total Users", value: "\(viewModel.userCount)")
                LabeledContent("Active Users", value: "\(viewModel.activeUserCount)")
                LabeledContent("Admins", value: "\(viewModel.adminCount)")
                LabeledContent("Managers", value: "\(viewModel.managerCount)")
                LabeledContent("Field Personnel", value: "\(viewModel.fieldPersonnelCount)")
            }
            
            Section("Users") {
                NavigationLink {
                    OrganizationUsersView(tenantId: tenant.id ?? "")
                } label: {
                    Label("View All Users", systemImage: "person.3")
                }
            }
            
            if tenant.isActive {
                Section("Actions") {
                    Button(role: .destructive) {
                        showingDeactivateConfirmation = true
                    } label: {
                        Label("Deactivate Organization", systemImage: "pause.circle")
                    }
                }
            } else {
                Section("Actions") {
                    Button {
                        reactivateOrganization()
                    } label: {
                        Label("Reactivate Organization", systemImage: "play.circle")
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Organization Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadOrganizationData(tenantId: tenant.id ?? "")
        }
        .alert("Deactivate Organization", isPresented: $showingDeactivateConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Deactivate", role: .destructive) {
                deactivateOrganization()
            }
        } message: {
            Text("This will prevent all users from accessing the system. You can reactivate it later.")
        }
    }
    
    func deactivateOrganization() {
        Task {
            guard let tenantId = tenant.id else { return }
            
            do {
                try await Firestore.firestore()
                    .collection("tenants")
                    .document(tenantId)
                    .updateData(["isActive": false])
                
                dismiss()
            } catch {
                print("❌ Error deactivating organization: \(error)")
            }
        }
    }
    
    func reactivateOrganization() {
        Task {
            guard let tenantId = tenant.id else { return }
            
            do {
                try await Firestore.firestore()
                    .collection("tenants")
                    .document(tenantId)
                    .updateData(["isActive": true])
                
                dismiss()
            } catch {
                print("❌ Error reactivating organization: \(error)")
            }
        }
    }
}

// MARK: - Organization Users View

struct OrganizationUsersView: View {
    let tenantId: String
    
    @StateObject private var viewModel = OrganizationUsersViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.users) { user in
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.fullName)
                        .font(.headline)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(user.role.displayName, systemImage: "shield")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        if user.isActive {
                            Label("Active", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Label("Inactive", systemImage: "pause.circle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Organization Users")
        .task {
            await viewModel.loadUsers(tenantId: tenantId)
        }
    }
}

// MARK: - ViewModels

@MainActor
class AllOrganizationsViewModel: ObservableObject {
    @Published var tenants: [Tenant] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    func loadTenants() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await db.collection("tenants")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            tenants = snapshot.documents.compactMap { try? $0.data(as: Tenant.self) }
        } catch {
            print("❌ Error loading tenants: \(error)")
        }
    }
}

@MainActor
class OrganizationDetailViewModel: ObservableObject {
    @Published var userCount = 0
    @Published var activeUserCount = 0
    @Published var adminCount = 0
    @Published var managerCount = 0
    @Published var fieldPersonnelCount = 0
    
    private let db = Firestore.firestore()
    
    func loadOrganizationData(tenantId: String) async {
        guard !tenantId.isEmpty else { return }
        
        do {
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: tenantId)
                .getDocuments()
            
            let users = snapshot.documents.compactMap { try? $0.data(as: User.self) }
            
            userCount = users.count
            activeUserCount = users.filter { $0.isActive }.count
            adminCount = users.filter { $0.role == .admin }.count
            managerCount = users.filter { $0.role == .manager }.count
            fieldPersonnelCount = users.filter { $0.role == .fieldPersonnel }.count
        } catch {
            print("❌ Error loading organization data: \(error)")
        }
    }
}

@MainActor
class OrganizationUsersViewModel: ObservableObject {
    @Published var users: [User] = []
    
    private let db = Firestore.firestore()
    
    func loadUsers(tenantId: String) async {
        guard !tenantId.isEmpty else { return }
        
        do {
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: tenantId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            users = snapshot.documents.compactMap { try? $0.data(as: User.self) }
        } catch {
            print("❌ Error loading users: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        AllOrganizationsView()
    }
}

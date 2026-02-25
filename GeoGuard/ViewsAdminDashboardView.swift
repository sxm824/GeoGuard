//
//  AdminDashboardView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct AdminDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AdminDashboardViewModel()
    @State private var showingInvitationSheet = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    statsSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Users
                    recentUsersSection
                    
                    // Active Invitations
                    activeInvitationsSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingSignOutAlert = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showingInvitationSheet) {
                CreateInvitationView()
                    .environmentObject(authService)
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    try? authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .task {
                await viewModel.loadData(tenantId: authService.tenantId ?? "")
            }
            .refreshable {
                await viewModel.loadData(tenantId: authService.tenantId ?? "")
            }
        }
    }
    
    // MARK: - Sections
    
    var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Total Users",
                value: "\(viewModel.users.count)",
                icon: "person.3.fill",
                color: .blue
            )
            
            StatCard(
                title: "Active Invites",
                value: "\(viewModel.activeInvitations.count)",
                icon: "envelope.fill",
                color: .green
            )
            
            StatCard(
                title: "Admins",
                value: "\(viewModel.users.filter { $0.role == .admin }.count)",
                icon: "shield.fill",
                color: .orange
            )
            
            StatCard(
                title: "Field Personnel",
                value: "\(viewModel.users.filter { $0.role == .fieldPersonnel }.count)",
                icon: "car.fill",
                color: .purple
            )
        }
    }
    
    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            VStack(spacing: 12) {
                Button {
                    showingInvitationSheet = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Create Invitation")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    UserManagementView()
                        .environmentObject(authService)
                } label: {
                    HStack {
                        Image(systemName: "person.2")
                        Text("Manage Users")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    CompanySettingsView()
                        .environmentObject(authService)
                } label: {
                    HStack {
                        Image(systemName: "building.2")
                        Text("Company Settings")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    var recentUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Users")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    UserManagementView()
                        .environmentObject(authService)
                }
                .font(.subheadline)
            }
            
            if viewModel.users.isEmpty {
                Text("No users yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.users.prefix(5))) { user in
                        UserRow(user: user)
                    }
                }
            }
        }
    }
    
    var activeInvitationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Invitations")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    InvitationManagementView()
                        .environmentObject(authService)
                }
                .font(.subheadline)
            }
            
            if viewModel.activeInvitations.isEmpty {
                Text("No active invitations")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.activeInvitations.prefix(3))) { invitation in
                        InvitationRow(invitation: invitation)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

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

struct UserRow: View {
    let user: User
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(user.initials)
                        .font(.caption)
                        .foregroundColor(.white)
                        .bold()
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.subheadline)
                    .bold()
                
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(user.role.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(roleColor(for: user.role).opacity(0.2))
                .foregroundColor(roleColor(for: user.role))
                .cornerRadius(6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    func roleColor(for role: UserRole) -> Color {
        switch role {
        case .superAdmin: return .red
        case .admin: return .orange
        case .manager: return .blue
        case .fieldPersonnel: return .green
        }
    }
}

struct InvitationRow: View {
    let invitation: Invitation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invitation.invitationCode)
                    .font(.headline)
                    .monospaced()
                
                Text(invitation.role.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                UIPasteboard.general.string = invitation.invitationCode
            } label: {
                Image(systemName: "doc.on.doc")
                    .imageScale(.medium)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - ViewModel

@MainActor
class AdminDashboardViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var activeInvitations: [Invitation] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    func loadData(tenantId: String) async {
        guard !tenantId.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        await loadUsers(tenantId: tenantId)
        await loadInvitations(tenantId: tenantId)
    }
    
    private func loadUsers(tenantId: String) async {
        do {
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: tenantId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            users = snapshot.documents.compactMap { doc in
                try? doc.data(as: User.self)
            }
        } catch {
            print("❌ Error loading users: \(error)")
        }
    }
    
    private func loadInvitations(tenantId: String) async {
        do {
            let snapshot = try await db.collection("invitations")
                .whereField("tenantId", isEqualTo: tenantId)
                .whereField("isUsed", isEqualTo: false)
                .getDocuments()
            
            activeInvitations = snapshot.documents.compactMap { doc in
                try? doc.data(as: Invitation.self)
            }.filter { invitation in
                invitation.expiresAt > Date()
            }
        } catch {
            print("❌ Error loading invitations: \(error)")
        }
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(AuthService())
}

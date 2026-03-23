//
//  AdminDashboardView.swift
//  GeoGuard
//
//  Professional Control Center Design
//  Updated by Saleh Mukbil on 2026-03-08.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct AdminDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AdminDashboardViewModel()
    @State private var showingInvitationSheet = false
    @State private var showingSignOutAlert = false
    @State private var selectedTimeFilter: TimeFilter = .today
    
    enum TimeFilter: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        
        var icon: String {
            switch self {
            case .today: return "calendar"
            case .week: return "calendar.badge.clock"
            case .month: return "calendar.circle"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with welcome message
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    
                    // Stats cards with modern design
                    statsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // Quick Actions Grid
                    quickActionsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // Activity Feed
                    activitySection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // Team Overview
                    teamOverviewSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // Active Invitations (if any)
                    if !viewModel.activeInvitations.isEmpty {
                        invitationsSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Control Center")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(authService.currentUser?.tenantId ?? "")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        #if DEBUG
                        NavigationLink {
                            UserRoleDiagnosticView()
                        } label: {
                            Label("Role Diagnostics", systemImage: "stethoscope")
                        }
                        
                        Divider()
                        #endif
                        
                        Button(role: .destructive) {
                            showingSignOutAlert = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text(authService.currentUser?.initials ?? "??")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
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
            .onAppear {
                Task {
                    await viewModel.loadData(tenantId: authService.tenantId ?? "")
                }
            }
            .task {
                await viewModel.loadData(tenantId: authService.tenantId ?? "")
            }
            .refreshable {
                await viewModel.loadData(tenantId: authService.tenantId ?? "")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(.title2)
                .fontWeight(.bold)
            
            if let user = authService.currentUser {
                Text(user.fullName)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Label {
                    Text("Live Monitoring")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } icon: {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
                
                Divider()
                    .frame(height: 12)
                
                Text("Last updated: \(Date().formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    //MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Activity", systemImage: "clock.fill")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    // TODO: Navigate to full activity log
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                if viewModel.users.isEmpty {
                    EmptyStateView(
                        icon: "tray.fill",
                        title: "No activity yet",
                        subtitle: "Team activity will appear here"
                    )
                } else {
                    ForEach(viewModel.users.prefix(3)) { user in
                        ActivityRow(
                            icon: "person.fill",
                            title: user.fullName,
                            subtitle: "Joined the team",
                            time: user.createdAt,
                            color: .blue
                        )
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Team Overview Section
    
    private var teamOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Team Members", systemImage: "person.3.fill")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    UserManagementView()
                        .environmentObject(authService)
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                if viewModel.users.isEmpty {
                    EmptyStateView(
                        icon: "person.3.fill",
                        title: "No team members",
                        subtitle: "Invite your first team member to get started"
                    )
                } else {
                    ForEach(viewModel.users.prefix(5)) { user in
                        ModernUserRow(user: user)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Invitations Section
    
    private var invitationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active Invitations", systemImage: "envelope.badge.fill")
                    .font(.headline)
                Spacer()
                NavigationLink("Manage") {
                    InvitationManagementView()
                        .environmentObject(authService)
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.activeInvitations.prefix(3)) { invitation in
                    ModernInvitationRow(invitation: invitation)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Sections
    
    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ModernStatsCard(
                title: "Total Team",
                value: "\(viewModel.users.count)",
                subtitle: "\(viewModel.activeUsersCount) active now",
                icon: "person.3.fill",
                gradient: [Color.blue, Color.blue.opacity(0.7)]
            )
            
            ModernStatsCard(
                title: "Field Personnel",
                value: "\(viewModel.fieldPersonnelCount)",
                subtitle: "In the field",
                icon: "location.fill",
                gradient: [Color.green, Color.green.opacity(0.7)]
            )
            
            ModernStatsCard(
                title: "Active Alerts",
                value: "0",
                subtitle: "All safe",
                icon: "bell.badge.fill",
                gradient: [Color.orange, Color.orange.opacity(0.7)]
            )
            
            ModernStatsCard(
                title: "Invitations",
                value: "\(viewModel.activeInvitations.count)",
                subtitle: "Pending",
                icon: "envelope.fill",
                gradient: [Color.purple, Color.purple.opacity(0.7)]
            )
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Quick Actions", systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                AdminQuickActionCard(
                    title: "Track Team",
                    subtitle: "Live locations",
                    icon: "map.fill",
                    color: .blue,
                    destination: AnyView(
                        AdminLocationTrackingView()
                            .environmentObject(authService)
                    )
                )
                
                AdminQuickActionCard(
                    title: "Alert Center",
                    subtitle: "Monitor & respond",
                    icon: "bell.badge.fill",
                    color: .red,
                    destination: AnyView(
                        AdminAlertsDashboardView()
                            .environmentObject(authService)
                    )
                )
                
                AdminQuickActionCard(
                    title: "Manage Team",
                    subtitle: "\(viewModel.users.count) members",
                    icon: "person.2.fill",
                    color: .green,
                    destination: AnyView(
                        UserManagementView()
                            .environmentObject(authService)
                    )
                )
                
                AdminQuickActionCard(
                    title: "Invite Member",
                    subtitle: "Generate code",
                    icon: "person.badge.plus.fill",
                    color: .purple,
                    action: { showingInvitationSheet = true }
                )
                
                AdminQuickActionCard(
                    title: "Settings",
                    subtitle: "Company profile",
                    icon: "building.2.fill",
                    color: .orange,
                    destination: AnyView(
                        CompanySettingsView()
                            .environmentObject(authService)
                    )
                )
            }
        }
    }
}

@MainActor
class AdminDashboardViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var activeInvitations: [Invitation] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    var activeUsersCount: Int {
        users.filter { $0.isActive }.count
    }
    
    var fieldPersonnelCount: Int {
        users.filter { $0.hasRole(.fieldPersonnel) }.count
    }
    
    func loadData(tenantId: String) async {
        guard !tenantId.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        await loadUsers(tenantId: tenantId)
        await loadInvitations(tenantId: tenantId)
    }
    
    private func loadUsers(tenantId: String) async {
        do {
            print("🔵 Loading users for tenant: \(tenantId)")
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: tenantId)
                .getDocuments()
            
            // Sort in memory after fetching
            users = snapshot.documents.compactMap { doc in
                try? doc.data(as: User.self)
            }.sorted { $0.createdAt > $1.createdAt }
            
            print("✅ Loaded \(users.count) users")
            print("📊 User breakdown:")
            print("   - Admins: \(users.filter { $0.role == .admin }.count)")
            print("   - Field Personnel: \(users.filter { $0.role == .fieldPersonnel }.count)")
            print("   - Managers: \(users.filter { $0.role == .manager }.count)")
            print("   - Super Admins: \(users.filter { $0.role == .superAdmin }.count)")
            
            // Debug: Print each user's role
            for user in users {
                print("   👤 \(user.fullName): \(user.role.rawValue)")
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

// MARK: - Modern Component Views

// Modern Stats Card
private struct ModernStatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// Quick Action Card
private struct AdminQuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var destination: AnyView? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink {
                    destination
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    action?()
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// Modern User Row
private struct ModernUserRow: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [roleColor(for: user.primaryRole), roleColor(for: user.primaryRole).opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay {
                    Text(user.initials)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: roleIcon(for: user.primaryRole))
                    .font(.caption2)
                Text(user.primaryRole.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(roleColor(for: user.primaryRole).opacity(0.15))
            .foregroundColor(roleColor(for: user.primaryRole))
            .cornerRadius(8)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func roleColor(for role: UserRole) -> Color {
        switch role {
        case .superAdmin: return .red
        case .admin: return .orange
        case .manager: return .blue
        case .fieldPersonnel: return .green
        }
    }
    
    private func roleIcon(for role: UserRole) -> String {
        switch role {
        case .superAdmin: return "crown.fill"
        case .admin: return "shield.fill"
        case .manager: return "person.badge.key.fill"
        case .fieldPersonnel: return "location.fill"
        }
    }
}

// Modern Invitation Row
private struct ModernInvitationRow: View {
    let invitation: Invitation
    @State private var copied = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "envelope.fill")
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(invitation.invitationCode)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Text(invitation.role.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text("Expires \(invitation.expiresAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            Button {
                UIPasteboard.general.string = invitation.invitationCode
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    copied = false
                }
            } label: {
                Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                    .foregroundColor(copied ? .green : .blue)
                    .imageScale(.large)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// Activity Row
private struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: Date
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// Empty State View
private struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(AuthService())
}

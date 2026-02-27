//
//  SuperAdminDashboardView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-26.
//

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

struct SuperAdminDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = SuperAdminViewModel()
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Platform Statistics
                    platformStatsSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Organizations
                    recentOrganizationsSection
                    
                    // License Management Summary
                    licenseSummarySection
                }
                .padding()
            }
            .navigationTitle("GeoGuard Platform")
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
                            .foregroundColor(.red)
                    }
                }
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
                await viewModel.loadDashboardData()
            }
            .refreshable {
                await viewModel.loadDashboardData()
            }
        }
    }
    
    // MARK: - Platform Statistics
    
    var platformStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Platform Overview")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Total Organizations",
                    value: "\(viewModel.totalTenants)",
                    icon: "building.2.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Active Organizations",
                    value: "\(viewModel.activeTenants)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Total Users",
                    value: "\(viewModel.totalUsers)",
                    icon: "person.3.fill",
                    color: .purple
                )
                
                StatCard(
                    title: "Available Licenses",
                    value: "\(viewModel.availableLicenses)",
                    icon: "key.fill",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Quick Actions
    
    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Platform Management")
                .font(.headline)
            
            VStack(spacing: 12) {
                NavigationLink {
                    LicenseManagementView()
                        .environmentObject(authService)
                } label: {
                    ActionCard(
                        icon: "key.fill",
                        title: "License Management",
                        subtitle: "Generate, view, and manage licenses",
                        color: .orange
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    AllOrganizationsView()
                        .environmentObject(authService)
                } label: {
                    ActionCard(
                        icon: "building.2.fill",
                        title: "All Organizations",
                        subtitle: "View and manage all registered organizations",
                        color: .blue
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    PlatformUsersView()
                        .environmentObject(authService)
                } label: {
                    ActionCard(
                        icon: "person.3.fill",
                        title: "Platform Users",
                        subtitle: "Search and manage users across all organizations",
                        color: .purple
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    PlatformAnalyticsView()
                        .environmentObject(authService)
                } label: {
                    ActionCard(
                        icon: "chart.bar.fill",
                        title: "Analytics & Reports",
                        subtitle: "Platform-wide statistics and insights",
                        color: .green
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    SystemSettingsView()
                        .environmentObject(authService)
                } label: {
                    ActionCard(
                        icon: "gearshape.fill",
                        title: "System Settings",
                        subtitle: "Configure platform-wide settings",
                        color: .gray
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Recent Organizations
    
    var recentOrganizationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Organizations")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    AllOrganizationsView()
                        .environmentObject(authService)
                }
                .font(.subheadline)
            }
            
            if viewModel.recentTenants.isEmpty {
                Text("No organizations yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentTenants) { tenant in
                        NavigationLink {
                            OrganizationDetailView(tenant: tenant)
                                .environmentObject(authService)
                        } label: {
                            OrganizationRow(tenant: tenant)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - License Summary
    
    var licenseSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("License Summary")
                    .font(.headline)
                Spacer()
                NavigationLink("Manage") {
                    LicenseManagementView()
                        .environmentObject(authService)
                }
                .font(.subheadline)
            }
            
            HStack(spacing: 16) {
                LicenseStatCard(
                    title: "Available",
                    count: viewModel.availableLicenses,
                    color: .green
                )
                
                LicenseStatCard(
                    title: "Used",
                    count: viewModel.usedLicenses,
                    color: .blue
                )
                
                LicenseStatCard(
                    title: "Expired",
                    count: viewModel.expiredLicenses,
                    color: .orange
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color.gradient)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
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
}

struct OrganizationRow: View {
    let tenant: Tenant
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tenant.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label(tenant.subscription.rawValue.capitalized, systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    if let domain = tenant.domain {
                        Label(domain, systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(tenant.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Circle()
                    .fill(tenant.isActive ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct LicenseStatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.title)
                .bold()
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - ViewModel

@MainActor
class SuperAdminViewModel: ObservableObject {
    @Published var totalTenants = 0
    @Published var activeTenants = 0
    @Published var totalUsers = 0
    @Published var availableLicenses = 0
    @Published var usedLicenses = 0
    @Published var expiredLicenses = 0
    @Published var recentTenants: [Tenant] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTenantStats() }
            group.addTask { await self.loadUserStats() }
            group.addTask { await self.loadLicenseStats() }
            group.addTask { await self.loadRecentTenants() }
        }
    }
    
    private func loadTenantStats() async {
        do {
            let snapshot = try await db.collection("tenants").getDocuments()
            totalTenants = snapshot.documents.count
            activeTenants = snapshot.documents.filter { doc in
                (try? doc.data(as: Tenant.self))?.isActive == true
            }.count
        } catch {
            print("❌ Error loading tenant stats: \(error)")
        }
    }
    
    private func loadUserStats() async {
        do {
            let snapshot = try await db.collection("users").getDocuments()
            totalUsers = snapshot.documents.count
        } catch {
            print("❌ Error loading user stats: \(error)")
        }
    }
    
    private func loadLicenseStats() async {
        do {
            let snapshot = try await db.collection("licenses").getDocuments()
            let licenses = snapshot.documents.compactMap { try? $0.data(as: License.self) }
            
            availableLicenses = licenses.filter { !$0.isUsed && $0.isActive }.count
            usedLicenses = licenses.filter { $0.isUsed }.count
            expiredLicenses = licenses.filter { license in
                guard let expiresAt = license.expiresAt else { return false }
                return expiresAt < Date()
            }.count
        } catch {
            print("❌ Error loading license stats: \(error)")
        }
    }
    
    private func loadRecentTenants() async {
        do {
            let snapshot = try await db.collection("tenants")
                .order(by: "createdAt", descending: true)
                .limit(to: 5)
                .getDocuments()
            
            recentTenants = snapshot.documents.compactMap { try? $0.data(as: Tenant.self) }
        } catch {
            print("❌ Error loading recent tenants: \(error)")
        }
    }
}

#Preview {
    SuperAdminDashboardView()
        .environmentObject(AuthService())
}

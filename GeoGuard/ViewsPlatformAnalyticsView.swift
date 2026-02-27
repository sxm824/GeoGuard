//
//  PlatformAnalyticsView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-26.
//

import SwiftUI
import Combine
import Charts
import FirebaseFirestore

struct PlatformAnalyticsView: View {
    @StateObject private var viewModel = PlatformAnalyticsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Growth Statistics
                growthSection
                
                // Subscription Distribution
                subscriptionSection
                
                // User Activity
                activitySection
                
                // License Usage
                licenseSection
            }
            .padding()
        }
        .navigationTitle("Platform Analytics")
        .task {
            await viewModel.loadAnalytics()
        }
        .refreshable {
            await viewModel.loadAnalytics()
        }
    }
    
    var growthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Platform Growth")
                .font(.headline)
            
            VStack(spacing: 8) {
                StatCard(
                    title: "Total Organizations",
                    value: "\(viewModel.totalOrganizations)",
                    icon: "building.2.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Total Users",
                    value: "\(viewModel.totalUsers)",
                    icon: "person.3.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Growth This Month",
                    value: "+\(viewModel.growthThisMonth)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
            }
        }
    }
    
    var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subscription Distribution")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Tenant.SubscriptionTier.allCases, id: \.self) { tier in
                    HStack {
                        Text(tier.rawValue.capitalized)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(viewModel.subscriptionCounts[tier] ?? 0)")
                            .font(.subheadline)
                            .bold()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User Activity")
                .font(.headline)
            
            Text("Activity tracking coming soon")
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    var licenseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("License Usage")
                .font(.headline)
            
            HStack(spacing: 16) {
                LicenseStatCard(title: "Total", count: viewModel.totalLicenses, color: .blue)
                LicenseStatCard(title: "Used", count: viewModel.usedLicenses, color: .green)
                LicenseStatCard(title: "Available", count: viewModel.availableLicenses, color: .orange)
            }
        }
    }
}

@MainActor
class PlatformAnalyticsViewModel: ObservableObject {
    @Published var totalOrganizations = 0
    @Published var totalUsers = 0
    @Published var growthThisMonth = 0
    @Published var subscriptionCounts: [Tenant.SubscriptionTier: Int] = [:]
    @Published var totalLicenses = 0
    @Published var usedLicenses = 0
    @Published var availableLicenses = 0
    
    private let db = Firestore.firestore()
    
    func loadAnalytics() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadOrganizationStats() }
            group.addTask { await self.loadUserStats() }
            group.addTask { await self.loadLicenseStats() }
        }
    }
    
    private func loadOrganizationStats() async {
        do {
            let snapshot = try await db.collection("tenants").getDocuments()
            totalOrganizations = snapshot.documents.count
            
            let tenants = snapshot.documents.compactMap { try? $0.data(as: Tenant.self) }
            
            // Count by subscription tier
            for tier in Tenant.SubscriptionTier.allCases {
                subscriptionCounts[tier] = tenants.filter { $0.subscription == tier }.count
            }
            
            // Calculate growth this month
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            
            growthThisMonth = tenants.filter { $0.createdAt >= startOfMonth }.count
        } catch {
            print("❌ Error loading organization stats: \(error)")
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
            
            totalLicenses = licenses.count
            usedLicenses = licenses.filter { $0.isUsed }.count
            availableLicenses = licenses.filter { !$0.isUsed && $0.isActive }.count
        } catch {
            print("❌ Error loading license stats: \(error)")
        }
    }
}

// Make Tenant.SubscriptionTier conform to CaseIterable if it doesn't already
extension Tenant.SubscriptionTier: CaseIterable {
    public static var allCases: [Tenant.SubscriptionTier] {
        return [.trial, .basic, .professional, .enterprise]
    }
}

#Preview {
    NavigationStack {
        PlatformAnalyticsView()
    }
}

//
//  DualRoleDashboardView.swift
//  GeoGuard
//
//  Created on 2026-03-07.
//  Provides tabbed interface for users with both admin and field personnel roles
//

import SwiftUI

/// Dashboard for users with BOTH admin and field personnel roles
/// Provides easy switching between Safety Control Center and Field Tracking
struct DualRoleDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedRole: DualRoleTab = .admin
    
    enum DualRoleTab: Int, CaseIterable {
        case admin = 0
        case field = 1
        
        var title: String {
            switch self {
            case .admin: return "Control Center"
            case .field: return "Field Mode"
            }
        }
        
        var icon: String {
            switch self {
            case .admin: return "building.2.fill"
            case .field: return "location.fill"
            }
        }
        
        var description: String {
            switch self {
            case .admin: return "Monitor team and manage operations"
            case .field: return "Your personal safety tracking"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedRole) {
            // Admin Dashboard
            adminTab
                .tabItem {
                    Label(DualRoleTab.admin.title, systemImage: DualRoleTab.admin.icon)
                }
                .tag(DualRoleTab.admin)
            
            // Field Personnel Dashboard
            fieldTab
                .tabItem {
                    Label(DualRoleTab.field.title, systemImage: DualRoleTab.field.icon)
                }
                .tag(DualRoleTab.field)
        }
        .accentColor(.blue)
    }
    
    // MARK: - Admin Tab
    
    private var adminTab: some View {
        NavigationStack {
            AdminDashboardView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 2) {
                            Text("Safety Control Center")
                                .font(.headline)
                            if let user = authService.currentUser {
                                Text(user.fullName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        roleIndicatorBadge(for: .admin)
                    }
                }
        }
    }
    
    // MARK: - Field Tab
    
    private var fieldTab: some View {
        DriverDashboardView()
            .overlay(alignment: .topTrailing) {
                // Add subtle badge indicating dual role
                roleIndicatorBadge(for: .field)
                    .padding()
            }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func roleIndicatorBadge(for tab: DualRoleTab) -> some View {
        HStack(spacing: 4) {
            Image(systemName: tab.icon)
                .font(.caption2)
            Text(tab.title)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tab == .admin ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
        .foregroundColor(tab == .admin ? .orange : .green)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview("Dual Role Dashboard") {
    DualRoleDashboardView()
        .environmentObject(AuthService())
}

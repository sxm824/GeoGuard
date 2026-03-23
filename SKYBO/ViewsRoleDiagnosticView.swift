//
//  RoleDiagnosticView.swift
//  GeoGuard
//
//  Temporary diagnostic view to check user roles
//

import SwiftUI

struct RoleDiagnosticView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔍 Role Diagnostics")
                .font(.title)
                .bold()
            
            if let user = authService.currentUser {
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        Text("User Info:")
                            .font(.headline)
                        Text("Name: \(user.fullName)")
                        Text("Email: \(user.email)")
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Role Details:")
                            .font(.headline)
                        Text("Primary Role: \(user.primaryRole.displayName)")
                            .foregroundColor(.blue)
                        
                        Text("All Roles:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(user.roles, id: \.self) { role in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(role.displayName)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Role Checks:")
                            .font(.headline)
                        
                        roleCheckRow(
                            label: "Has Admin Role",
                            value: user.hasRole(.admin)
                        )
                        
                        roleCheckRow(
                            label: "Has Field Personnel Role",
                            value: user.hasRole(.fieldPersonnel)
                        )
                        
                        roleCheckRow(
                            label: "Has ANY Admin Role",
                            value: user.hasAnyRole([.admin, .manager, .superAdmin])
                        )
                        
                        roleCheckRow(
                            label: "Should Show Tabs",
                            value: user.hasAnyRole([.admin, .manager, .superAdmin]) && user.hasRole(.fieldPersonnel)
                        )
                    }
                    
                    Divider()
                    
                    Group {
                        Text("Computed Properties:")
                            .font(.headline)
                        
                        Text("Should Be Tracked: \(user.shouldBeTracked ? "✅ YES" : "❌ NO")")
                        Text("Can Monitor Others: \(user.canMonitorOthers ? "✅ YES" : "❌ NO")")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Text("No user logged in")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func roleCheckRow(label: String, value: Bool) -> some View {
        HStack {
            Text(label)
            Spacer()
            if value {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("YES")
                    .foregroundColor(.green)
                    .bold()
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("NO")
                    .foregroundColor(.red)
                    .bold()
            }
        }
    }
}

#Preview {
    RoleDiagnosticView()
        .environmentObject(AuthService())
}

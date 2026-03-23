//
//  UserRoleDiagnosticView.swift
//  GeoGuard
//
//  Quick diagnostic tool to check user roles and routing logic
//

import SwiftUI
import FirebaseFirestore

struct UserRoleDiagnosticView: View {
    @EnvironmentObject var authService: AuthService
    @State private var firestoreData: [String: Any]?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            List {
                if let user = authService.currentUser {
                    Section("Current User Object") {
                        LabeledContent("Name", value: user.fullName)
                        LabeledContent("Email", value: user.email)
                        LabeledContent("Tenant ID", value: user.tenantId)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Roles Array")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(user.roles.map { $0.rawValue }.joined(separator: ", "))
                                .font(.body.monospaced())
                        }
                        
                        LabeledContent("Primary Role", value: user.primaryRole.rawValue)
                        
                        Divider()
                        
                        LabeledContent("Has Admin Role?", value: user.hasAnyRole([.admin, .manager, .superAdmin]) ? "✅ YES" : "❌ NO")
                        LabeledContent("Has Field Role?", value: user.hasRole(.fieldPersonnel) ? "✅ YES" : "❌ NO")
                        
                        let hasAdminRole = user.hasAnyRole([.admin, .manager, .superAdmin])
                        let hasFieldRole = user.hasRole(.fieldPersonnel)
                        let shouldShowDualDashboard = hasAdminRole && hasFieldRole
                        
                        LabeledContent("Should Show Dual Dashboard?", value: shouldShowDualDashboard ? "✅ YES" : "❌ NO")
                            .bold()
                            .foregroundColor(shouldShowDualDashboard ? .green : .orange)
                    }
                    
                    Section("Firestore Raw Data") {
                        if isLoading {
                            ProgressView()
                        } else if let data = firestoreData {
                            if let roles = data["roles"] as? [String] {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("roles (array)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("[\(roles.map { "\"\($0)\"" }.joined(separator: ", "))]")
                                        .font(.body.monospaced())
                                        .foregroundColor(.green)
                                }
                            } else {
                                Text("⚠️ No 'roles' array found in Firestore")
                                    .foregroundColor(.orange)
                            }
                            
                            if let role = data["role"] as? String {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("role (legacy)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\"\(role)\"")
                                        .font(.body.monospaced())
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Divider()
                            
                            Text("Full Document:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatJSON(data))
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        } else {
                            Button("Load Firestore Data") {
                                loadFirestoreData(userId: user.id ?? "")
                            }
                        }
                    }
                    
                    Section("Expected Dashboard") {
                        let hasAdminRole = user.hasAnyRole([.admin, .manager, .superAdmin])
                        let hasFieldRole = user.hasRole(.fieldPersonnel)
                        
                        if hasAdminRole && hasFieldRole {
                            Label("DualRoleDashboardView (with tabs)", systemImage: "rectangle.split.2x1")
                                .foregroundColor(.green)
                        } else {
                            Label("\(user.primaryRole.displayName) Dashboard", systemImage: "rectangle")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Section("Quick Fix") {
                        Button("Add Field Personnel Role") {
                            addFieldPersonnelRole(userId: user.id ?? "")
                        }
                        .disabled(user.hasRole(.fieldPersonnel))
                        
                        Button("Remove Field Personnel Role") {
                            removeFieldPersonnelRole(userId: user.id ?? "")
                        }
                        .disabled(!user.hasRole(.fieldPersonnel))
                        
                        Divider()
                        
                        Button("🔧 Fix Roles Field Type") {
                            fixRolesFieldType(userId: user.id ?? "")
                        }
                        .foregroundColor(.orange)
                    }
                    
                } else {
                    Text("No user signed in")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Role Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let userId = authService.currentUser?.id {
                    loadFirestoreData(userId: userId)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func loadFirestoreData(userId: String) {
        guard !userId.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let doc = try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .getDocument()
                
                await MainActor.run {
                    firestoreData = doc.data()
                    isLoading = false
                }
            } catch {
                print("❌ Error loading Firestore data: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func addFieldPersonnelRole(userId: String) {
        guard !userId.isEmpty else { return }
        
        Task {
            do {
                // Get current roles
                let doc = try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .getDocument()
                
                var currentRoles = doc.data()?["roles"] as? [String] ?? []
                
                // Add field_personnel if not already present
                if !currentRoles.contains("field_personnel") {
                    currentRoles.append("field_personnel")
                    
                    try await Firestore.firestore()
                        .collection("users")
                        .document(userId)
                        .updateData(["roles": currentRoles])
                    
                    print("✅ Added field_personnel role")
                    
                    // Reload user
                    await authService.loadUserData(userId: userId)
                    loadFirestoreData(userId: userId)
                }
            } catch {
                print("❌ Error adding role: \(error)")
            }
        }
    }
    
    private func removeFieldPersonnelRole(userId: String) {
        guard !userId.isEmpty else { return }
        
        Task {
            do {
                // Get current roles
                let doc = try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .getDocument()
                
                var currentRoles = doc.data()?["roles"] as? [String] ?? []
                
                // Remove field_personnel
                currentRoles.removeAll { $0 == "field_personnel" }
                
                try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .updateData(["roles": currentRoles])
                
                print("✅ Removed field_personnel role")
                
                // Reload user
                await authService.loadUserData(userId: userId)
                loadFirestoreData(userId: userId)
            } catch {
                print("❌ Error removing role: \(error)")
            }
        }
    }
    
    private func fixRolesFieldType(userId: String) {
        guard !userId.isEmpty else { return }
        
        Task {
            do {
                print("🔧 Starting roles field type fix...")
                
                // Get current document
                let doc = try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .getDocument()
                
                guard let data = doc.data() else {
                    print("❌ No document data found")
                    return
                }
                
                // Check if roles is a string
                if let rolesString = data["roles"] as? String {
                    print("📝 Found roles as string: \"\(rolesString)\"")
                    
                    // Parse the string into an array
                    let rolesArray = rolesString
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    
                    print("📋 Parsed into array: \(rolesArray)")
                    
                    // Update Firestore with array
                    try await Firestore.firestore()
                        .collection("users")
                        .document(userId)
                        .updateData(["roles": rolesArray])
                    
                    print("✅ Successfully converted roles from string to array!")
                    print("   Old: \"\(rolesString)\"")
                    print("   New: \(rolesArray)")
                    
                    // Reload user
                    await authService.loadUserData(userId: userId)
                    loadFirestoreData(userId: userId)
                    
                } else if let rolesArray = data["roles"] as? [String] {
                    print("✅ Roles field is already an array: \(rolesArray)")
                } else {
                    print("⚠️ Roles field has unexpected type: \(type(of: data["roles"]))")
                }
                
            } catch {
                print("❌ Error fixing roles field: \(error)")
            }
        }
    }
    
    private func formatJSON(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
              let string = String(data: data, encoding: .utf8) else {
            return String(describing: dict)
        }
        return string
    }
}

#Preview {
    UserRoleDiagnosticView()
        .environmentObject(AuthService())
}

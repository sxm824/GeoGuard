//
//  CompanySettingsView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct CompanySettingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = CompanySettingsViewModel()
    
    var body: some View {
        Form {
            if let tenant = viewModel.tenant {
                Section("Company Information") {
                    LabeledContent("Company Name", value: tenant.name)
                    
                    if let domain = tenant.domain {
                        LabeledContent("Domain", value: domain)
                    } else {
                        LabeledContent("Domain", value: "Not set")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Subscription") {
                    LabeledContent("Tier", value: tenant.subscription.rawValue.capitalized)
                    LabeledContent("Max Users", value: "\(tenant.maxUsers)")
                    LabeledContent("Active", value: tenant.isActive ? "Yes" : "No")
                }
                
                Section("Administrator") {
                    if let admin = viewModel.adminUser {
                        LabeledContent("Name", value: admin.fullName)
                        LabeledContent("Email", value: admin.email)
                        LabeledContent("Phone", value: admin.phone)
                    }
                }
                
                Section("Account Created") {
                    LabeledContent("Date", value: tenant.createdAt, format: .dateTime)
                }
            } else if viewModel.isLoading {
                ProgressView()
            } else {
                Text("Unable to load company information")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Company Settings")
        .task {
            if let tenantId = authService.tenantId {
                await viewModel.loadTenant(tenantId: tenantId)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class CompanySettingsViewModel: ObservableObject {
    @Published var tenant: Tenant?
    @Published var adminUser: User?
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    func loadTenant(tenantId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let document = try await db.collection("tenants").document(tenantId).getDocument()
            tenant = try document.data(as: Tenant.self)
            
            // Load admin user
            if let adminUserId = tenant?.adminUserId {
                let adminDoc = try await db.collection("users").document(adminUserId).getDocument()
                adminUser = try adminDoc.data(as: User.self)
            }
        } catch {
            print("❌ Error loading tenant: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        CompanySettingsView()
            .environmentObject(AuthService())
    }
}

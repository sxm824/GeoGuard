//
//  PlatformUsersView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-26.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct PlatformUsersView: View {
    @StateObject private var viewModel = PlatformUsersViewModel()
    @State private var searchText = ""
    
    var filteredUsers: [User] {
        guard !searchText.isEmpty else { return viewModel.users }
        
        return viewModel.users.filter { user in
            user.fullName.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(filteredUsers) { user in
                    NavigationLink {
                        UserDetailView(user: user)
                    } label: {
                        PlatformUserRow(user: user)
                    }
                }
            } header: {
                Text("\(filteredUsers.count) Users Across All Organizations")
            }
        }
        .navigationTitle("Platform Users")
        .searchable(text: $searchText, prompt: "Search users")
        .task {
            await viewModel.loadAllUsers()
        }
        .refreshable {
            await viewModel.loadAllUsers()
        }
    }
}

struct PlatformUserRow: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.fullName)
                .font(.headline)
            
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Label(user.role.displayName, systemImage: "shield")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                // Would need to load tenant name
                Label("Organization ID: \(user.tenantId)", systemImage: "building.2")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                if user.isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct UserDetailView: View {
    let user: User
    
    var body: some View {
        Form {
            Section("User Information") {
                LabeledContent("Name", value: user.fullName)
                LabeledContent("Email", value: user.email)
                LabeledContent("Phone", value: user.phone)
                LabeledContent("Role", value: user.role.displayName)
                LabeledContent("Status", value: user.isActive ? "Active" : "Inactive")
            }
            
            Section("Organization") {
                LabeledContent("Tenant ID", value: user.tenantId)
            }
            
            Section("Address") {
                LabeledContent("Street", value: user.address)
                LabeledContent("City", value: user.city)
                LabeledContent("Country", value: user.country)
            }
            
            Section("Account") {
                LabeledContent("Created") {
                    Text(user.createdAt, style: .date)
                }
            }
        }
        .navigationTitle("User Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
class PlatformUsersViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    func loadAllUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await db.collection("users")
                .order(by: "createdAt", descending: true)
                .limit(to: 100) // Limit for performance
                .getDocuments()
            
            users = snapshot.documents.compactMap { try? $0.data(as: User.self) }
        } catch {
            print("❌ Error loading users: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        PlatformUsersView()
    }
}

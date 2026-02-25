//
//  UserManagementView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct UserManagementView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = UserManagementViewModel()
    @State private var searchText = ""
    @State private var selectedRole: UserRole?
    
    var filteredUsers: [User] {
        var filtered = viewModel.users
        
        if !searchText.isEmpty {
            filtered = filtered.filter { user in
                user.fullName.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let role = selectedRole {
            filtered = filtered.filter { $0.role == role }
        }
        
        return filtered
    }
    
    var body: some View {
        List {
            Section {
                Picker("Filter by Role", selection: $selectedRole) {
                    Text("All Roles").tag(nil as UserRole?)
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Text(role.displayName).tag(role as UserRole?)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section {
                ForEach(filteredUsers) { user in
                    UserDetailRow(user: user, authService: authService) {
                        Task {
                            await viewModel.loadUsers(tenantId: authService.tenantId ?? "")
                        }
                    }
                }
            } header: {
                Text("\(filteredUsers.count) Users")
            }
        }
        .navigationTitle("User Management")
        .searchable(text: $searchText, prompt: "Search users")
        .task {
            await viewModel.loadUsers(tenantId: authService.tenantId ?? "")
        }
        .refreshable {
            await viewModel.loadUsers(tenantId: authService.tenantId ?? "")
        }
    }
}

struct UserDetailRow: View {
    let user: User
    let authService: AuthService
    let onUpdate: () -> Void
    
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack {
            Circle()
                .fill(user.isActive ? Color.blue.gradient : Color.gray.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Text(user.initials)
                        .font(.body)
                        .foregroundColor(.white)
                        .bold()
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Label(user.role.displayName, systemImage: "shield")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(roleColor(for: user.role).opacity(0.2))
                        .foregroundColor(roleColor(for: user.role))
                        .cornerRadius(6)
                }
            }
            
            Spacer()
            
            if !user.isActive {
                Image(systemName: "pause.circle.fill")
                    .foregroundColor(.orange)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            EditUserView(user: user, authService: authService, onUpdate: onUpdate)
        }
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

struct EditUserView: View {
    let user: User
    let authService: AuthService
    let onUpdate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRole: UserRole
    @State private var isActive: Bool
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    init(user: User, authService: AuthService, onUpdate: @escaping () -> Void) {
        self.user = user
        self.authService = authService
        self.onUpdate = onUpdate
        _selectedRole = State(initialValue: user.role)
        _isActive = State(initialValue: user.isActive)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("User Information") {
                    LabeledContent("Name", value: user.fullName)
                    LabeledContent("Email", value: user.email)
                    LabeledContent("Phone", value: user.phone)
                }
                
                Section("Role & Status") {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(UserRole.allCases, id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    
                    Toggle("Active", isOn: $isActive)
                }
                
                Section("Address") {
                    LabeledContent("Street", value: user.address)
                    LabeledContent("City", value: user.city)
                    LabeledContent("Country", value: user.country)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    func saveChanges() {
        Task {
            isLoading = true
            errorMessage = ""
            defer { isLoading = false }
            
            do {
                guard let userId = user.id else { return }
                
                try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .updateData([
                        "role": selectedRole.rawValue,
                        "isActive": isActive
                    ])
                
                onUpdate()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class UserManagementViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    func loadUsers(tenantId: String) async {
        guard !tenantId.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
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
}

#Preview {
    NavigationStack {
        UserManagementView()
            .environmentObject(AuthService())
    }
}

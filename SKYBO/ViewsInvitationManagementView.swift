//
//  InvitationManagementView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import SwiftUI
import Combine
import FirebaseFirestore

struct InvitationManagementView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = InvitationManagementViewModel()
    @State private var showingCreateSheet = false
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.activeInvitations) { invitation in
                    InvitationDetailRow(invitation: invitation) {
                        Task {
                            await viewModel.deleteInvitation(invitation)
                            await viewModel.loadInvitations(tenantId: authService.tenantId ?? "")
                        }
                    }
                }
            } header: {
                Text("Active (\(viewModel.activeInvitations.count))")
            }
            
            Section {
                ForEach(viewModel.usedInvitations) { invitation in
                    InvitationDetailRow(invitation: invitation, isUsed: true)
                }
            } header: {
                Text("Used (\(viewModel.usedInvitations.count))")
            }
        }
        .navigationTitle("Invitations")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateInvitationView()
                .environmentObject(authService)
                .onDisappear {
                    Task {
                        await viewModel.loadInvitations(tenantId: authService.tenantId ?? "")
                    }
                }
        }
        .task {
            await viewModel.loadInvitations(tenantId: authService.tenantId ?? "")
        }
        .refreshable {
            await viewModel.loadInvitations(tenantId: authService.tenantId ?? "")
        }
    }
}

struct InvitationDetailRow: View {
    let invitation: Invitation
    var isUsed: Bool = false
    var onDelete: (() -> Void)? = nil
    
    @State private var showingDeleteAlert = false
    @State private var copiedToClipboard = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(invitation.invitationCode)
                    .font(.headline)
                    .monospaced()
                
                Spacer()
                
                if !isUsed {
                    Button {
                        UIPasteboard.general.string = invitation.invitationCode
                        copiedToClipboard = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copiedToClipboard = false
                        }
                    } label: {
                        Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                            .foregroundColor(copiedToClipboard ? .green : .blue)
                    }
                }
            }
            
            HStack {
                Label(invitation.role.displayName, systemImage: "shield")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(roleColor(for: invitation.role).opacity(0.2))
                    .foregroundColor(roleColor(for: invitation.role))
                    .cornerRadius(6)
                
                if let email = invitation.email {
                    Label(email, systemImage: "envelope")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            HStack {
                Text("Expires: \(invitation.expiresAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isUsed, let usedAt = invitation.usedAt {
                    Text("• Used \(usedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !isUsed, onDelete != nil {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .alert("Delete Invitation", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Are you sure you want to delete this invitation code?")
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

struct CreateInvitationView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var invitationService = InvitationService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedRole: UserRole = .fieldPersonnel
    @State private var specificEmail = ""
    @State private var useSpecificEmail = false
    @State private var expirationDays = 7
    @State private var generatedCode = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Invitation Settings") {
                    Picker("Role", selection: $selectedRole) {
                        ForEach([UserRole.fieldPersonnel, .manager, .admin], id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    
                    Stepper("Expires in \(expirationDays) days", value: $expirationDays, in: 1...30)
                }
                
                Section {
                    Toggle("Specific Email Only", isOn: $useSpecificEmail)
                    
                    if useSpecificEmail {
                        TextField("Email Address", text: $specificEmail)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                } header: {
                    Text("Restrictions (Optional)")
                } footer: {
                    Text("If specified, only this email can use the invitation code")
                }
                
                if !generatedCode.isEmpty {
                    Section {
                        HStack {
                            Text(generatedCode)
                                .font(.title2)
                                .bold()
                                .monospaced()
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = generatedCode
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .imageScale(.large)
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Generated Code")
                    } footer: {
                        Text("Share this code with the person you want to invite")
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create Invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(generatedCode.isEmpty ? "Generate" : "Done") {
                        if generatedCode.isEmpty {
                            createInvitation()
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    func createInvitation() {
        Task {
            isLoading = true
            errorMessage = ""
            defer { isLoading = false }
            
            guard let tenantId = authService.tenantId,
                  let userId = authService.userId else {
                errorMessage = "Authentication error"
                return
            }
            
            if useSpecificEmail && specificEmail.isEmpty {
                errorMessage = "Please enter an email address"
                return
            }
            
            do {
                let invitation = try await invitationService.createInvitation(
                    tenantId: tenantId,
                    invitedBy: userId,
                    email: useSpecificEmail ? specificEmail : nil,
                    role: selectedRole,
                    expiresInDays: expirationDays
                )
                
                generatedCode = invitation.invitationCode
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class InvitationManagementViewModel: ObservableObject {
    @Published var activeInvitations: [Invitation] = []
    @Published var usedInvitations: [Invitation] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    func loadInvitations(tenantId: String) async {
        guard !tenantId.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await db.collection("invitations")
                .whereField("tenantId", isEqualTo: tenantId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let allInvitations = snapshot.documents.compactMap { doc in
                try? doc.data(as: Invitation.self)
            }
            
            activeInvitations = allInvitations.filter { invitation in
                !invitation.isUsed && invitation.expiresAt > Date()
            }
            
            usedInvitations = allInvitations.filter { $0.isUsed }
            
        } catch {
            print("❌ Error loading invitations: \(error)")
        }
    }
    
    func deleteInvitation(_ invitation: Invitation) async {
        guard let id = invitation.id else { return }
        
        do {
            try await db.collection("invitations").document(id).delete()
        } catch {
            print("❌ Error deleting invitation: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        InvitationManagementView()
            .environmentObject(AuthService())
    }
}

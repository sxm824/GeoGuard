//
//  LicenseManagementView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-26.
//

import SwiftUI
import Combine
import FirebaseFirestore

#if canImport(UIKit)
import UIKit
#endif

struct LicenseManagementView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = LicenseManagementViewModel()
    @State private var showingGenerateSheet = false
    @State private var searchText = ""
    @State private var filterStatus: LicenseFilterStatus = .all
    
    enum LicenseFilterStatus: String, CaseIterable {
        case all = "All"
        case available = "Available"
        case used = "Used"
        case expired = "Expired"
    }
    
    var filteredLicenses: [License] {
        var filtered = viewModel.licenses
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { license in
                license.licenseKey.localizedCaseInsensitiveContains(searchText) ||
                (license.issuedTo?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (license.organizationName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply status filter
        switch filterStatus {
        case .all:
            break
        case .available:
            filtered = filtered.filter { !$0.isUsed && $0.isActive }
        case .used:
            filtered = filtered.filter { $0.isUsed }
        case .expired:
            filtered = filtered.filter { license in
                guard let expiresAt = license.expiresAt else { return false }
                return expiresAt < Date()
            }
        }
        
        return filtered
    }
    
    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $filterStatus) {
                    ForEach(LicenseFilterStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                ForEach(filteredLicenses) { license in
                    LicenseRow(license: license) {
                        Task {
                            await viewModel.loadLicenses()
                        }
                    }
                }
            } header: {
                HStack {
                    Text("\(filteredLicenses.count) Licenses")
                    Spacer()
                    Button {
                        showingGenerateSheet = true
                    } label: {
                        Label("Generate", systemImage: "plus.circle.fill")
                    }
                }
            }
            
            if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("License Management")
        .searchable(text: $searchText, prompt: "Search licenses")
        .task {
            await viewModel.loadLicenses()
        }
        .refreshable {
            await viewModel.loadLicenses()
        }
        .sheet(isPresented: $showingGenerateSheet) {
            GenerateLicenseView(onGenerated: {
                Task {
                    await viewModel.loadLicenses()
                }
            })
        }
    }
}

// MARK: - License Row

struct LicenseRow: View {
    let license: License
    let onUpdate: () -> Void
    
    @State private var showingDetail = false
    
    var statusColor: Color {
        if !license.isActive {
            return .red
        } else if license.isUsed {
            return .blue
        } else if let expiresAt = license.expiresAt, expiresAt < Date() {
            return .orange
        } else {
            return .green
        }
    }
    
    var statusText: String {
        if !license.isActive {
            return "Revoked"
        } else if license.isUsed {
            return "Used"
        } else if let expiresAt = license.expiresAt, expiresAt < Date() {
            return "Expired"
        } else {
            return "Available"
        }
    }
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(license.licenseKey)
                        .font(.headline)
                        .monospaced()
                    
                    Spacer()
                    
                    Text(statusText)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(6)
                }
                
                if let issuedTo = license.issuedTo {
                    Label(issuedTo, systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let organizationName = license.organizationName {
                    Label("Used by: \(organizationName)", systemImage: "building.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text(license.issuedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let expiresAt = license.expiresAt {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("Expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingDetail) {
            LicenseDetailView(license: license, onUpdate: onUpdate)
        }
    }
}

// MARK: - Generate License View

struct GenerateLicenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var licenseService = LicenseService()
    
    let onGenerated: () -> Void
    
    @State private var issuedTo = ""
    @State private var expirationDays = 365
    @State private var notes = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var generatedLicense: License?
    
    let expirationOptions = [30, 90, 180, 365, 730, 0] // 0 = No expiration
    
    var body: some View {
        NavigationStack {
            Form {
                Section("License Details") {
                    TextField("Issued To (Client Name)", text: $issuedTo)
                    
                    Picker("Expiration", selection: $expirationDays) {
                        ForEach(expirationOptions, id: \.self) { days in
                            if days == 0 {
                                Text("No Expiration").tag(days)
                            } else {
                                Text("\(days) days").tag(days)
                            }
                        }
                    }
                    
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let license = generatedLicense {
                    Section("Generated License Key") {
                        HStack {
                            Text(license.licenseKey)
                                .font(.title3)
                                .monospaced()
                                .bold()
                            
                            Spacer()
                            
                            Button {
                                #if canImport(UIKit)
                                UIPasteboard.general.string = license.licenseKey
                                #endif
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                        
                        Text("License key has been generated and saved. Copy it and share with the client.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Generate License")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        if generatedLicense != nil {
                            onGenerated()
                        }
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        generateLicense()
                    }
                    .disabled(isLoading || generatedLicense != nil)
                }
            }
        }
    }
    
    func generateLicense() {
        Task {
            isLoading = true
            errorMessage = ""
            defer { isLoading = false }
            
            do {
                guard let superAdminId = authService.currentUser?.id else {
                    errorMessage = "User not authenticated"
                    return
                }
                
                let license = try await licenseService.generateLicense(
                    issuedBy: superAdminId,
                    issuedTo: issuedTo.isEmpty ? nil : issuedTo,
                    expiresInDays: expirationDays == 0 ? nil : expirationDays,
                    notes: notes.isEmpty ? nil : notes
                )
                
                generatedLicense = license
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - License Detail View

struct LicenseDetailView: View {
    let license: License
    let onUpdate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingRevokeConfirmation = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("License Key") {
                    HStack {
                        Text(license.licenseKey)
                            .font(.headline)
                            .monospaced()
                        
                        Spacer()
                        
                        Button {
                            #if canImport(UIKit)
                            UIPasteboard.general.string = license.licenseKey
                            #endif
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
                
                Section("Status") {
                    LabeledContent("Active", value: license.isActive ? "Yes" : "No (Revoked)")
                    LabeledContent("Used", value: license.isUsed ? "Yes" : "No")
                }
                
                Section("Details") {
                    if let issuedTo = license.issuedTo {
                        LabeledContent("Issued To", value: issuedTo)
                    }
                    
                    LabeledContent("Issued At") {
                        Text(license.issuedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    if let expiresAt = license.expiresAt {
                        LabeledContent("Expires At") {
                            Text(expiresAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    } else {
                        LabeledContent("Expires At", value: "Never")
                    }
                }
                
                if license.isUsed {
                    Section("Usage") {
                        if let organizationName = license.organizationName {
                            LabeledContent("Organization", value: organizationName)
                        }
                        
                        if let usedAt = license.usedAt {
                            LabeledContent("Used At") {
                                Text(usedAt.formatted(date: .abbreviated, time: .shortened))
                            }
                        }
                    }
                }
                
                if let notes = license.notes {
                    Section("Notes") {
                        Text(notes)
                            .font(.subheadline)
                    }
                }
                
                if license.isActive && !license.isUsed {
                    Section {
                        Button(role: .destructive) {
                            showingRevokeConfirmation = true
                        } label: {
                            Label("Revoke License", systemImage: "xmark.circle")
                        }
                    } footer: {
                        Text("Revoking this license will prevent it from being used to create an organization.")
                    }
                }
            }
            .navigationTitle("License Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Revoke License", isPresented: $showingRevokeConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Revoke", role: .destructive) {
                    revokeLicense()
                }
            } message: {
                Text("Are you sure you want to revoke this license? This action cannot be undone.")
            }
        }
    }
    
    func revokeLicense() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                guard let licenseId = license.id else { return }
                
                try await Firestore.firestore()
                    .collection("licenses")
                    .document(licenseId)
                    .updateData(["isActive": false])
                
                onUpdate()
                dismiss()
            } catch {
                print("❌ Error revoking license: \(error)")
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class LicenseManagementViewModel: ObservableObject {
    @Published var licenses: [License] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    func loadLicenses() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await db.collection("licenses")
                .order(by: "issuedAt", descending: true)
                .getDocuments()
            
            licenses = snapshot.documents.compactMap { try? $0.data(as: License.self) }
        } catch {
            print("❌ Error loading licenses: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        LicenseManagementView()
            .environmentObject(AuthService())
    }
}

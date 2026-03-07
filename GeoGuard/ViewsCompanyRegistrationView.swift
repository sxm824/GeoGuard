//
//  CompanyRegistrationView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CompanyRegistrationView: View {
    @StateObject private var tenantService = TenantService()
    @StateObject private var licenseService = LicenseService()
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var licenseKey = ""
    @State private var validatedLicense: License?
    
    @State private var companyName = ""
    @State private var companyDomain = ""
    @State private var adminEmail = ""
    @State private var adminPassword = ""
    @State private var adminFirstName = ""
    @State private var adminLastName = ""
    @State private var adminPhone = ""
    @State private var adminAddress = ""
    @State private var adminCity = ""
    @State private var adminCountry = ""
    @State private var subscriptionTier: Tenant.SubscriptionTier = .trial
    @State private var showManualAddressEntry = false
    
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var registrationSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Register Your Organization")
                            .font(.title)
                            .bold()
                        
                        Text("Create a GeoGuard account for your organization's safety tracking")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom)
                    
                    // License Key Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("License Key Required", systemImage: "key.fill")
                            .font(.headline)
                        
                        HStack {
                            TextField("Enter License Key", text: $licenseKey)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.allCharacters)
                                .onChange(of: licenseKey) { oldValue, newValue in
                                    licenseKey = newValue.uppercased()
                                }
                            
                            Button("Validate") {
                                validateLicense()
                            }
                            .buttonStyle(.bordered)
                            .disabled(licenseKey.isEmpty || isLoading)
                        }
                        
                        if let license = validatedLicense {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Valid License")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                        .bold()
                                    
                                    if let issuedTo = license.issuedTo {
                                        Text("Issued to: \(issuedTo)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Text("Contact GeoGuard support to obtain a license key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Organization Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Organization Information")
                            .font(.headline)
                        
                        TextField("Organization Name", text: $companyName)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Organization Domain (optional)", text: $companyDomain)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .keyboardType(.URL)
                        
                        Text("e.g., acme.com - Employees with this domain can auto-join")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Subscription Tier", selection: $subscriptionTier) {
                            Text("Trial (5 users)").tag(Tenant.SubscriptionTier.trial)
                            Text("Basic (25 users)").tag(Tenant.SubscriptionTier.basic)
                            Text("Professional (100 users)").tag(Tenant.SubscriptionTier.professional)
                            Text("Enterprise (1000 users)").tag(Tenant.SubscriptionTier.enterprise)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Divider()
                    
                    // Admin Account
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Administrator Account")
                            .font(.headline)
                        
                        TextField("Email", text: $adminEmail)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $adminPassword)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack(spacing: 12) {
                            TextField("First Name", text: $adminFirstName)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Last Name", text: $adminLastName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        TextField("Phone Number (e.g., +1234567890)", text: $adminPhone)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numbersAndPunctuation)
                            .textContentType(.telephoneNumber)
                            .autocapitalization(.none)
                            .onChange(of: adminPhone) { oldValue, newValue in
                                let filtered = newValue.filter { char in
                                    char.isNumber || char == "+" || char == " " || char == "-" || char == "(" || char == ")"
                                }
                                if filtered != newValue {
                                    adminPhone = filtered
                                }
                            }
                        
                        // Address section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Address")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button {
                                    showManualAddressEntry.toggle()
                                } label: {
                                    Text(showManualAddressEntry ? "Use Autocomplete" : "Enter Manually")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if showManualAddressEntry {
                                TextField("Street Address", text: $adminAddress)
                                    .textFieldStyle(.roundedBorder)
                                
                                ManualAddressFields(city: $adminCity, country: $adminCountry)
                            } else {
                                AddressAutocompleteField(
                                    address: $adminAddress,
                                    city: $adminCity,
                                    country: $adminCountry
                                )
                                
                                if !adminCity.isEmpty || !adminCountry.isEmpty {
                                    ManualAddressFields(city: $adminCity, country: $adminCountry)
                                }
                            }
                        }
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: registerCompany) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create Company Account")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    .padding(.vertical)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $registrationSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your organization has been registered successfully!\n\nPlease log in with your admin credentials to continue.")
            }
        }
    }
    
    func validateLicense() {
        Task {
            isLoading = true
            errorMessage = ""
            defer { isLoading = false }
            
            print("🔑 Validating license key: \(licenseKey)")
            
            // Validate license key format first
            let trimmedKey = licenseKey.trimmingCharacters(in: .whitespaces)
            guard !trimmedKey.isEmpty else {
                print("❌ License key is empty")
                errorMessage = "Please enter a license key"
                return
            }
            
            do {
                print("🔵 Calling licenseService.validateLicense")
                let license = try await licenseService.validateLicense(key: licenseKey)
                print("✅ License validated successfully")
                validatedLicense = license
            } catch {
                print("❌ License validation error: \(error)")
                print("❌ Error type: \(type(of: error))")
                print("❌ Error localizedDescription: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                validatedLicense = nil
            }
        }
    }
    
    func registerCompany() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            // Validate inputs
            guard validateInputs() else { return }
            
            do {
                // CRITICAL: Disable AuthStateListener to prevent race condition
                // The listener would try to load user data immediately after createUser()
                // but before we've created the Firestore document
                authService.beginRegistration()
                
                // 1. Sign out first to ensure clean slate
                print("🔵 Signing out any existing session")
                try? Auth.auth().signOut()
                
                // 2. Create Firebase Auth account for admin
                print("🔵 Creating Firebase Auth account")
                let authResult = try await Auth.auth().createUser(
                    withEmail: adminEmail,
                    password: adminPassword
                )
                
                let userId = authResult.user.uid
                print("✅ Firebase Auth account created: \(userId)")
                
                // 🔥 CRITICAL FIX: Force token refresh to ensure it's ready for Firestore
                // Without this, Firestore security rules may fail because the token isn't ready
                print("🔵 Forcing token refresh...")
                _ = try await authResult.user.getIDToken(forcingRefresh: true)
                print("✅ Token refreshed and ready")
                
                print("⚠️ User is now auto-signed in, but AuthStateListener is disabled")
                
                // 3. Create tenant (company)
                print("🔵 Creating tenant")
                print("🔵 Tenant will be created with adminUserId: \(userId)")
                print("🔵 Auth.auth().currentUser?.uid: \(Auth.auth().currentUser?.uid ?? "nil")")
                print("🔵 Are they equal? \(Auth.auth().currentUser?.uid == userId)")
                
                let tenantId = try await tenantService.createTenant(
                    name: companyName,
                    domain: companyDomain.isEmpty ? nil : companyDomain.lowercased(),
                    adminUserId: userId,
                    subscription: subscriptionTier
                )
                print("✅ Tenant created: \(tenantId)")
                
                // 4. Create admin user document (WHILE AUTHENTICATED)
                let baseInitials = getInitials(from: "\(adminFirstName) \(adminLastName)")
                let initials = try await findUniqueInitials(baseInitials: baseInitials, tenantId: tenantId)
                
                let adminUser = User(
                    id: userId,
                    tenantId: tenantId,
                    fullName: "\(adminFirstName) \(adminLastName)",
                    initials: initials,
                    email: adminEmail,
                    phone: adminPhone,
                    address: adminAddress,
                    city: adminCity,
                    country: adminCountry,
                    vehicle: "N/A",
                    role: .admin,
                    isActive: true,
                    createdAt: Date()
                )
                
                print("🔵 Creating user document for: \(userId)")
                let userData = adminUser.toDictionary()
                print("🔵 User data dictionary keys: \(userData.keys)")
                print("🔵 User data full: \(userData)")
                
                try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .setData(userData)
                
                print("✅ User document created successfully")
                
                // 5. Verify document was written by reading it back
                print("🔵 Verifying user document exists")
                let verifyDoc = try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .getDocument()
                
                guard verifyDoc.exists else {
                    throw NSError(
                        domain: "GeoGuard",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "User document failed to save"]
                    )
                }
                print("✅ User document verified")
                
                // 6. Mark license as used
                if let licenseId = validatedLicense?.id {
                    print("🔵 Marking license as used: \(licenseId)")
                    try await licenseService.markLicenseAsUsed(
                        licenseId: licenseId,
                        tenantId: tenantId,
                        organizationName: companyName
                    )
                    print("✅ License marked as used")
                }
                
                // 7. Re-enable AuthStateListener
                authService.endRegistration()
                
                // 8. Sign out so user can log in fresh with complete setup
                print("🔵 Signing out to allow fresh login")
                try Auth.auth().signOut()
                print("✅ Signed out successfully")
                
                // Success! User can now log in and the document will exist
                print("✅ Registration complete - ready for login")
                registrationSuccess = true
                
            } catch {
                print("❌ Company registration error: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                
                // Re-enable listener and sign out on error
                authService.endRegistration()
                try? Auth.auth().signOut()
            }
        }
    }
    
    func validateInputs() -> Bool {
        errorMessage = ""
        
        // Check license key first
        if validatedLicense == nil {
            errorMessage = "Please validate your license key before proceeding"
            return false
        }
        
        if companyName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your company name"
            return false
        }
        
        if adminEmail.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter an email address"
            return false
        }
        
        if adminPassword.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        if adminFirstName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your first name"
            return false
        }
        
        if adminLastName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your last name"
            return false
        }
        
        if !isValidPhoneNumber(adminPhone) {
            errorMessage = "Please enter a valid international phone number"
            return false
        }
        
        if adminAddress.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your address"
            return false
        }
        
        if adminCity.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your city"
            return false
        }
        
        if adminCountry.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your country"
            return false
        }
        
        return true
    }
    
    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        guard trimmed.hasPrefix("+") else { return false }
        let digitsOnly = trimmed.dropFirst().filter { $0.isNumber }
        guard digitsOnly.count >= 7 && digitsOnly.count <= 15 else { return false }
        let allowedCharacters = CharacterSet(charactersIn: "+0123456789 -()")
        let phoneCharacters = CharacterSet(charactersIn: trimmed)
        return allowedCharacters.isSuperset(of: phoneCharacters)
    }
    
    func getInitials(from fullName: String) -> String {
        let parts = fullName.components(separatedBy: " ")
        guard parts.count >= 2 else { return "???" }
        let first = parts[0].prefix(1).uppercased()
        let last = parts[1].prefix(1).uppercased()
        return first + last
    }
    
    func findUniqueInitials(baseInitials: String, tenantId: String) async throws -> String {
        let db = Firestore.firestore()
        var counter = 0
        
        print("🔵 Finding unique initials starting with: \(baseInitials)")
        
        while true {
            let testInitials = counter == 0 ? baseInitials : "\(baseInitials)\(counter)"
            
            print("🔵 Checking if '\(testInitials)' is available...")
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: tenantId)
                .whereField("initials", isEqualTo: testInitials)
                .limit(to: 1)  // CRITICAL: Required by Firestore rules!
                .getDocuments()
            
            if snapshot.documents.isEmpty {
                print("✅ Unique initials found: \(testInitials)")
                return testInitials
            }
            
            print("⚠️ '\(testInitials)' is taken, trying next...")
            counter += 1
            
            // Safety check to prevent infinite loop
            if counter > 100 {
                throw NSError(
                    domain: "GeoGuard",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to generate unique initials after 100 attempts"]
                )
            }
        }
    }
}

#Preview {
    CompanyRegistrationView()
        .environmentObject(AuthService())
}

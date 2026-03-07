//
//  SignupView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-24.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignupView: View {
    @StateObject private var invitationService = InvitationService()
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var country = ""
    @State private var invitationCode = ""
    @State private var errorMessage = ""
    @State private var showManualAddressEntry = false
    @State private var showingCompanyRegistration = false
    
    // Emergency contact information (critical for war zones)
    @State private var emergencyContactName = ""
    @State private var emergencyContactPhone = ""
    @State private var emergencyContactRelation = ""
    @State private var bloodType = ""
    @State private var medicalNotes = ""
    
    @State private var validatedInvitation: Invitation?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Join Your Organization")
                        .font(.title)
                        .bold()
                    
                    Text("Personnel Safety Network")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Invitation Code Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Invitation Code", text: $invitationCode)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.allCharacters)
                                .onChange(of: invitationCode) { oldValue, newValue in
                                    invitationCode = newValue.uppercased()
                                }
                            
                            Button("Validate") {
                                validateInvitationCode()
                            }
                            .buttonStyle(.bordered)
                            .disabled(invitationCode.isEmpty)
                        }
                        
                        if let invitation = validatedInvitation {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Valid invitation for \(invitation.role.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Text("Have an invitation code from your organization? Enter it above.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Or Register Organization
                    HStack {
                        VStack { Divider() }
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        VStack { Divider() }
                    }
                    
                    Button {
                        showingCompanyRegistration = true
                    } label: {
                        Label("Register Your Organization", systemImage: "building.2")
                    }
                    .buttonStyle(.bordered)
                    
                    Divider()
                        .padding(.vertical)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Phone Number (e.g., +1234567890)", text: $phone)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numbersAndPunctuation)
                        .textContentType(.telephoneNumber)
                        .autocapitalization(.none)
                        .onChange(of: phone) { oldValue, newValue in
                            // Filter out any invalid characters
                            let filtered = newValue.filter { char in
                                char.isNumber || char == "+" || char == " " || char == "-" || char == "(" || char == ")"
                            }
                            if filtered != newValue {
                                phone = filtered
                            }
                        }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Emergency Contact Section (Critical for Safety)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "cross.case.fill")
                                .foregroundColor(.red)
                            Text("Emergency Contact (Required)")
                                .font(.headline)
                        }
                        
                        Text("In case of emergency, who should we contact?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Emergency Contact Name", text: $emergencyContactName)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Emergency Contact Phone (e.g., +1234567890)", text: $emergencyContactPhone)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numbersAndPunctuation)
                            .textContentType(.telephoneNumber)
                            .autocapitalization(.none)
                            .onChange(of: emergencyContactPhone) { oldValue, newValue in
                                // Filter out any invalid characters
                                let filtered = newValue.filter { char in
                                    char.isNumber || char == "+" || char == " " || char == "-" || char == "(" || char == ")"
                                }
                                if filtered != newValue {
                                    emergencyContactPhone = filtered
                                }
                            }
                        
                        TextField("Relationship (e.g., Spouse, Parent, Colleague)", text: $emergencyContactRelation)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Medical Information (Optional but recommended)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundColor(.orange)
                            Text("Medical Information (Optional)")
                                .font(.headline)
                        }
                        
                        Text("Helps first responders in emergencies")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Blood Type (e.g., A+, O-, AB+)", text: $bloodType)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.allCharacters)
                        
                        TextField("Allergies or Medical Conditions", text: $medicalNotes)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Address section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Address")
                                .font(.headline)
                            
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
                            // Manual entry
                            TextField("Street Address", text: $address)
                                .textFieldStyle(.roundedBorder)
                            
                            ManualAddressFields(city: $city, country: $country)
                        } else {
                            // Google Places Autocomplete
                            AddressAutocompleteField(
                                address: $address,
                                city: $city,
                                country: $country
                            )
                            
                            // Show city and country fields if they're filled
                            if !city.isEmpty || !country.isEmpty {
                                ManualAddressFields(city: $city, country: $country)
                            }
                        }
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button("Sign Up") {
                        signUp()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .padding()
            }
            .sheet(isPresented: $showingCompanyRegistration) {
                CompanyRegistrationView()
            }
        }
    }
    
    func validateInvitationCode() {
        Task {
            do {
                let invitation = try await invitationService.validateInvitation(
                    code: invitationCode,
                    email: email.isEmpty ? nil : email
                )
                validatedInvitation = invitation
                errorMessage = ""
            } catch {
                errorMessage = error.localizedDescription
                validatedInvitation = nil
            }
        }
    }
    
    func signUp() {
        Task {
            // Validate inputs before attempting signup
            guard validateInputs() else { return }
            
            do {
                // CRITICAL: Disable AuthStateListener to prevent race condition
                authService.beginRegistration()
                
                // 1. Sign out first to ensure clean slate
                print("🔵 Signing out any existing session")
                try? Auth.auth().signOut()
                
                // 2. Create Firebase Auth account
                print("🔵 Creating Firebase Auth account")
                let authResult = try await Auth.auth().createUser(
                    withEmail: email,
                    password: password
                )
                
                let userId = authResult.user.uid
                print("✅ Firebase Auth account created: \(userId)")
                print("⚠️ User is now auto-signed in, but AuthStateListener is disabled")
                
                // CRITICAL: Force token refresh to ensure Firestore has the latest auth state
                print("🔵 Forcing token refresh before Firestore queries")
                do {
                    _ = try await authResult.user.getIDTokenResult(forcingRefresh: true)
                    print("✅ Token refreshed successfully")
                } catch {
                    print("⚠️ Token refresh failed: \(error.localizedDescription)")
                    // Continue anyway - the token might still work
                }
                
                // 3. Determine tenant ID
                let tenantId: String
                let role: UserRole
                
                if let invitation = validatedInvitation {
                    // User signed up with invitation
                    tenantId = invitation.tenantId
                    role = invitation.role
                    
                    print("🔵 User signed up with invitation")
                    print("   Invitation ID: \(invitation.id ?? "nil")")
                    print("   Tenant ID: \(tenantId)")
                    print("   Role: \(role.rawValue)")
                    
                    // Mark invitation as used
                    if let invitationId = invitation.id {
                        do {
                            try await invitationService.markAsUsed(
                                invitationId: invitationId,
                                userId: userId
                            )
                            print("✅ Invitation marked as used")
                        } catch {
                            print("⚠️ Failed to mark invitation as used: \(error.localizedDescription)")
                            // Don't fail the signup, but log the error
                        }
                    } else {
                        print("⚠️ Invitation ID is nil, cannot mark as used")
                    }
                } else {
                    // Check if email domain matches existing tenant
                    let emailDomain = email.components(separatedBy: "@").last?.lowercased() ?? ""
                    let tenantService = TenantService()
                    
                    if let tenant = try await tenantService.findTenantByDomain(emailDomain) {
                        tenantId = tenant.id ?? ""
                        role = .fieldPersonnel  // Default role for domain-matched users
                    } else {
                        authService.endRegistration()
                        errorMessage = "No invitation code provided and email domain doesn't match any registered company."
                        // Note: No need to delete user here since we already signed out
                        return
                    }
                }
                
                // 4. Find unique initials within tenant
                print("🔵 Finding unique initials")
                let baseInitials = getInitials(from: "\(firstName) \(lastName)")
                let initials = try await findUniqueInitials(
                    baseInitials: baseInitials,
                    tenantId: tenantId
                )
                print("✅ Unique initials: \(initials)")
                
                // 5. Create user document (WHILE AUTHENTICATED)
                print("🔵 Creating user document")
                let newUser = User(
                    id: userId,
                    tenantId: tenantId,
                    fullName: "\(firstName) \(lastName)",
                    initials: initials,
                    email: email,
                    phone: phone,
                    address: address,
                    city: city,
                    country: country,
                    vehicle: "N/A", // Not applicable for safety tracking
                    role: role,
                    isActive: true,
                    createdAt: Date(),
                    emergencyContact: emergencyContactName.isEmpty ? nil : emergencyContactName,
                    emergencyPhone: emergencyContactPhone.isEmpty ? nil : emergencyContactPhone,
                    emergencyContactRelation: emergencyContactRelation.isEmpty ? nil : emergencyContactRelation,
                    bloodType: bloodType.isEmpty ? nil : bloodType,
                    medicalNotes: medicalNotes.isEmpty ? nil : medicalNotes,
                    invitedBy: validatedInvitation?.invitedBy,
                    invitationCode: validatedInvitation?.invitationCode
                )
                
                try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .setData(newUser.toDictionary())
                print("✅ User document created successfully")
                
                // 6. Verify document was written by reading it back
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
                
                // 7. Re-enable AuthStateListener
                authService.endRegistration()
                
                // 8. Sign out so user can log in fresh with complete setup
                print("🔵 Signing out to allow fresh login")
                try Auth.auth().signOut()
                print("✅ Signed out successfully")
                
                // Success! User can now log in and the document will exist
                print("✅ Signup complete - ready for login")
                
                // Close the signup view
                dismiss()
                
            } catch {
                print("❌ Signup error: \(error)")
                errorMessage = error.localizedDescription
                
                // Re-enable listener and sign out on error
                authService.endRegistration()
                try? Auth.auth().signOut()
            }
        }
    }
    
    func findUniqueInitials(baseInitials: String, tenantId: String) async throws -> String {
        let db = Firestore.firestore()
        var counter = 0
        
        while true {
            let testInitials = counter == 0 ? baseInitials : "\(baseInitials)\(counter)"
            
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: tenantId)
                .whereField("initials", isEqualTo: testInitials)
                .limit(to: 1)  // Add limit to satisfy security rules
                .getDocuments()
            
            if snapshot.documents.isEmpty {
                return testInitials
            }
            
            counter += 1
        }
    }
    
    func validateInputs() -> Bool {
        // Clear previous errors
        errorMessage = ""
        
        // Check if fields are empty
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter an email address"
            return false
        }
        
        if password.isEmpty {
            errorMessage = "Please enter a password"
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your first name"
            return false
        }
        
        if lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your last name"
            return false
        }
        
        // Validate phone number
        if !isValidPhoneNumber(phone) {
            errorMessage = "Please enter a valid international phone number (e.g., +1234567890)"
            return false
        }
        
        // CRITICAL: Validate emergency contact (required for safety)
        if emergencyContactName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please provide an emergency contact name"
            return false
        }
        
        if !isValidPhoneNumber(emergencyContactPhone) {
            errorMessage = "Please provide a valid emergency contact phone number (e.g., +1234567890)"
            return false
        }
        
        if emergencyContactRelation.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please specify your relationship to the emergency contact"
            return false
        }
        
        // Validate address fields
        if address.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your street address"
            return false
        }
        
        if city.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your city"
            return false
        }
        
        if country.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your country"
            return false
        }
        
        return true
    }
    
    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        // Remove whitespace for validation
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespaces)
        
        // Must not be empty
        guard !trimmed.isEmpty else { return false }
        
        // Must start with +
        guard trimmed.hasPrefix("+") else { return false }
        
        // Remove + and all formatting characters
        let digitsOnly = trimmed.dropFirst().filter { $0.isNumber }
        
        // Must have at least 7 digits (shortest international numbers)
        // and no more than 15 digits (E.164 standard)
        guard digitsOnly.count >= 7 && digitsOnly.count <= 15 else { return false }
        
        // Only allow valid characters: +, digits, spaces, hyphens, parentheses
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
}

#Preview {
    SignupView()
        .environmentObject(AuthService())
}

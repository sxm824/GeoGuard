//
//  SuperAdminSetupView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-27.
//
//  ⚠️ DEVELOPMENT ONLY - This file should NOT be included in production builds
//  
//  PURPOSE: One-time setup tool to create the initial super admin account
//  
//  USAGE:
//  1. Temporarily change ExampleGeoGuardApp.swift to show SuperAdminSetupView()
//  2. Run the app and create your super admin
//  3. Change back to ContentRootView()
//  4. (Optional) Delete this file before production deployment
//
//  SECURITY: Before creating super admin, temporarily open Firestore rules:
//  match /{document=**} { allow write: if true; }
//  Then secure them again after creation!

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SuperAdminSetupView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = "admin@geoguard.com"
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = "Super Admin"
    @State private var phoneNumber = "+1234567890"
    
    @State private var isCreating = false
    @State private var statusMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("⚠️ DEVELOPMENT ONLY") {
                    Text("This view creates a super admin account. Remove this feature before deploying to production.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Section("Super Admin Details") {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                
                Section("Password") {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                    
                    if !password.isEmpty {
                        PasswordStrengthIndicator(password: password)
                    }
                }
                
                Section("Credentials Summary") {
                    LabeledContent("Role", value: "super Admin")
                        .foregroundColor(.purple)
                    LabeledContent("Tenant ID", value: "PLATFORM")
                        .foregroundColor(.purple)
                    LabeledContent("Organization ID", value: "PLATFORM")
                        .foregroundColor(.purple)
                }
                
                if !statusMessage.isEmpty {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(statusMessage)
                                .font(.callout)
                        }
                        .foregroundColor(isSuccess ? .green : .red)
                    }
                }
                
                Section {
                    Button(action: createSuperAdmin) {
                        HStack {
                            Spacer()
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Creating Super Admin...")
                            } else {
                                Image(systemName: "crown.fill")
                                Text("Create Super Admin Account")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .navigationTitle("Super Admin Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !fullName.isEmpty &&
        password == confirmPassword &&
        password.count >= 8
    }
    
    func createSuperAdmin() {
        Task {
            isCreating = true
            statusMessage = ""
            isSuccess = false
            defer { isCreating = false }
            
            do {
                var uid: String
                var authResult: AuthDataResult?
                
                // 1. Try to create Firebase Auth user OR use existing one
                do {
                    authResult = try await Auth.auth().createUser(withEmail: email, password: password)
                    uid = authResult!.user.uid
                    print("✅ Created new Firebase Auth user: \(uid)")
                } catch let authError as NSError {
                    // Check if user already exists
                    if authError.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                        print("⚠️ User already exists in Firebase Auth, signing in to get UID...")
                        
                        // Sign in to get the UID
                        let signInResult = try await Auth.auth().signIn(withEmail: email, password: password)
                        uid = signInResult.user.uid
                        print("✅ Using existing Firebase Auth user: \(uid)")
                        
                        statusMessage = "ℹ️ Note: Firebase Auth user already existed, creating/updating Firestore document..."
                    } else {
                        // Different auth error, re-throw it
                        throw authError
                    }
                }
                
                // 2. Generate initials from full name
                let initials = fullName
                    .components(separatedBy: " ")
                    .compactMap { $0.first }
                    .map { String($0).uppercased() }
                    .joined()
                
                // 3. Create User document in Firestore with ALL required fields
                let db = Firestore.firestore()
                
                let superAdminData: [String: Any] = [
                    "id": uid,
                    "email": email,
                    "fullName": fullName,
                    "initials": initials.isEmpty ? "SA" : initials,
                    "phone": phoneNumber,
                    "address": "GeoGuard Platform",
                    "city": "Platform",
                    "country": "Global",
                    "vehicle": "N/A",
                    "role": "super_admin",  // Must match UserRole.superAdmin.rawValue
                    "tenantId": "PLATFORM",
                    "isActive": true,
                    "createdAt": Timestamp(date: Date())
                ]
                
                try await db.collection("users").document(uid).setData(superAdminData)
                
                print("✅ Created Firestore user document")
                
                // 4. Sign out (we don't want to be logged in as this user yet)
                try Auth.auth().signOut()
                
                statusMessage = "✅ Super Admin account created successfully!\n\nEmail: \(email)\nUID: \(uid)\n\nYou can now log in using the Super Admin Login button."
                isSuccess = true
                
                // Clear password fields
                password = ""
                confirmPassword = ""
                
            } catch let error as NSError {
                // Better error handling
                if error.domain == "FIRFirestoreErrorDomain" && error.code == 7 {
                    statusMessage = "❌ Firestore permission denied.\n\nPlease update your Firestore rules to allow writes:\n\nGo to Firebase Console → Firestore Database → Rules\n\nAdd this temporarily:\nmatch /{document=**} {\n  allow write: if true;\n}\n\nThen try again. Remember to secure your rules after!"
                } else if error.domain == "FIRAuthErrorDomain" && error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    statusMessage = "❌ Email already in use but couldn't verify password. Please delete the user from Firebase Console → Authentication → Users, or use the correct password."
                } else {
                    statusMessage = "❌ Failed to create super admin: \(error.localizedDescription)"
                }
                isSuccess = false
                print("❌ Super admin creation error: \(error)")
            }
        }
    }
}

// MARK: - Password Strength Indicator

struct PasswordStrengthIndicator: View {
    let password: String
    
    var strength: PasswordStrength {
        if password.count < 6 {
            return .weak
        } else if password.count < 8 {
            return .medium
        } else if password.count >= 12 && containsNumbersAndSpecialChars {
            return .veryStrong
        } else if password.count >= 8 {
            return .strong
        }
        return .medium
    }
    
    var containsNumbersAndSpecialChars: Bool {
        let numberRegex = ".*[0-9]+.*"
        let specialCharRegex = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>/?]+.*"
        let hasNumber = NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password)
        let hasSpecial = NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: password)
        return hasNumber && hasSpecial
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Strength:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(index < strength.bars ? strength.color : Color.gray.opacity(0.2))
                    .frame(height: 4)
            }
            
            Text(strength.text)
                .font(.caption)
                .foregroundColor(strength.color)
        }
    }
}

enum PasswordStrength {
    case weak, medium, strong, veryStrong
    
    var bars: Int {
        switch self {
        case .weak: return 1
        case .medium: return 2
        case .strong: return 3
        case .veryStrong: return 4
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        case .veryStrong: return .blue
        }
    }
    
    var text: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }
}

// MARK: - Preview

#Preview {
    SuperAdminSetupView()
}

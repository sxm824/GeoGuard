# License Key Implementation Guide

## 🔐 Adding License Key Requirement for Organization Registration

This guide shows how to add license key validation to prevent unauthorized organization creation.

---

## Overview

**Problem:** Anyone who downloads the app can create an organization  
**Solution:** Require a valid license key issued by GeoGuard team

---

## Implementation Steps

### Step 1: Add License Key Field to CompanyRegistrationView

Add these state variables at the top of `CompanyRegistrationView`:

```swift
@State private var licenseKey = ""
@StateObject private var licenseService = LicenseService()
@State private var validatedLicense: License? = nil
```

### Step 2: Add License Key Section to UI

Add this section **FIRST** in the form, before organization information:

```swift
// License Key Section (Add at the top)
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
```

### Step 3: Add Validation Function

Add this function to `CompanyRegistrationView`:

```swift
func validateLicense() {
    Task {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        
        do {
            let license = try await licenseService.validateLicense(key: licenseKey)
            validatedLicense = license
        } catch {
            errorMessage = error.localizedDescription
            validatedLicense = nil
        }
    }
}
```

### Step 4: Update Registration Function

Modify the `registerCompany()` function to check for valid license:

```swift
func registerCompany() {
    Task {
        // FIRST: Check license
        guard let license = validatedLicense else {
            errorMessage = "Please validate your license key first"
            return
        }
        
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        
        // Validate inputs
        guard validateInputs() else { return }
        
        do {
            // 1. Create Firebase Auth account for admin
            let authResult = try await Auth.auth().createUser(
                withEmail: adminEmail,
                password: adminPassword
            )
            
            let adminUserId = authResult.user.uid
            
            // 2. Create tenant (organization)
            let tenant = Tenant(
                name: companyName,
                domain: companyDomain.isEmpty ? nil : companyDomain,
                adminUserId: adminUserId,
                subscriptionTier: subscriptionTier,
                isActive: true,
                settings: Tenant.TenantSettings(),
                createdAt: Date(),
                licenseKey: license.licenseKey  // ← Store license key reference
            )
            
            let tenantId = try await tenantService.createTenant(tenant)
            
            // 3. Mark license as used
            if let licenseId = license.id {
                try await licenseService.markLicenseAsUsed(
                    licenseId: licenseId,
                    tenantId: tenantId,
                    organizationName: companyName
                )
            }
            
            // 4. Create admin user document
            // ... rest of existing code ...
            
        } catch {
            errorMessage = error.localizedDescription
            // If anything fails, clean up Firebase Auth account
            try? await Auth.auth().currentUser?.delete()
        }
    }
}
```

### Step 5: Disable Registration Without Valid License

Update the "Create Organization" button:

```swift
Button("Create Organization") {
    registerCompany()
}
.buttonStyle(.borderedProminent)
.disabled(isLoading || validatedLicense == nil)  // ← Add license check
.padding()

if validatedLicense == nil {
    Text("Please validate your license key to continue")
        .font(.caption)
        .foregroundColor(.orange)
}
```

---

## Firestore Security Rules Update

Add this rule to `firestore.rules`:

```javascript
// Licenses collection (read-only for validation, write only by super admins)
match /licenses/{licenseId} {
  // Anyone can read to validate during registration
  allow read: if request.auth != null;
  
  // Only authenticated users can update (mark as used)
  allow update: if request.auth != null && 
                   request.resource.data.keys().hasOnly(['isUsed', 'usedAt', 'usedBy', 'organizationName']) &&
                   resource.data.isUsed == false &&  // Can only update unused licenses
                   request.resource.data.isUsed == true;  // Can only mark as used
  
  // Only super admins can create licenses
  allow create: if request.auth != null && 
                  get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
  
  // Only super admins can delete
  allow delete: if request.auth != null && 
                  get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
}
```

---

## Super Admin Panel for License Generation

Create a view for GeoGuard team to generate licenses:

```swift
struct LicenseManagementView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var licenseService = LicenseService()
    @State private var licenses: [License] = []
    @State private var showingCreateSheet = false
    
    var body: some View {
        List {
            Section("Active Licenses") {
                ForEach(licenses.filter { $0.isValid }) { license in
                    LicenseRow(license: license)
                }
            }
            
            Section("Used Licenses") {
                ForEach(licenses.filter { $0.isUsed }) { license in
                    LicenseRow(license: license, isUsed: true)
                }
            }
        }
        .navigationTitle("License Management")
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
            CreateLicenseView()
                .environmentObject(authService)
        }
        .task {
            await loadLicenses()
        }
    }
    
    func loadLicenses() async {
        // Load all licenses (super admin only)
    }
}

struct LicenseRow: View {
    let license: License
    var isUsed: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(license.licenseKey)
                    .font(.headline)
                    .monospaced()
                
                Spacer()
                
                if !isUsed {
                    Button {
                        UIPasteboard.general.string = license.licenseKey
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
            
            if let issuedTo = license.issuedTo {
                Text("Issued to: \(issuedTo)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let organizationName = license.organizationName {
                Text("Used by: \(organizationName)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            if let expiresAt = license.expiresAt {
                Text("Expires: \(expiresAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(license.isValid ? .secondary : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateLicenseView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var licenseService = LicenseService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var issuedTo = ""
    @State private var expiresInDays = 365
    @State private var notes = ""
    @State private var generatedLicense: License? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section("License Details") {
                    TextField("Issued To (Company Name)", text: $issuedTo)
                    
                    Stepper("Expires in \(expiresInDays) days", value: $expiresInDays, in: 1...365)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let license = generatedLicense {
                    Section {
                        HStack {
                            Text(license.licenseKey)
                                .font(.title3)
                                .bold()
                                .monospaced()
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = license.licenseKey
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .imageScale(.large)
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Generated License Key")
                    } footer: {
                        Text("Share this key with the client")
                    }
                }
            }
            .navigationTitle("Create License")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(generatedLicense == nil ? "Generate" : "Done") {
                        if generatedLicense == nil {
                            generateLicense()
                        } else {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    func generateLicense() {
        Task {
            guard let userId = authService.userId else { return }
            
            do {
                let license = try await licenseService.generateLicense(
                    issuedBy: userId,
                    issuedTo: issuedTo.isEmpty ? nil : issuedTo,
                    expiresInDays: expiresInDays,
                    notes: notes.isEmpty ? nil : notes
                )
                
                generatedLicense = license
            } catch {
                print("Error generating license: \(error)")
            }
        }
    }
}
```

---

## Updated User Flow with License Key

### Before (Insecure):
```
Anyone downloads app
    ↓
Tap "Register Organization"
    ↓
Fill in form
    ↓
Organization created ❌ (No control)
```

### After (Secure):
```
Client contacts GeoGuard team
    ↓
GeoGuard team generates license key
    ↓
Client receives license: "GGUARD-2026-ABC123XYZ"
    ↓
Client downloads app
    ↓
Tap "Register Organization"
    ↓
Enter license key
    ↓
Validate key ✅
    ↓
Fill in organization info
    ↓
Organization created ✅ (Controlled)
```

---

## License Key Format

```
GGUARD-YYYY-XXXXXXXXX

Examples:
- GGUARD-2026-ABC123XYZ
- GGUARD-2026-DEF456UVW
- GGUARD-2026-GHI789RST

Components:
- GGUARD: Product identifier
- 2026: Year issued
- XXXXXXXXX: 9 random characters (no confusing chars: 0,O,1,I)
```

---

## Alternative: Simpler Approaches

If license keys are too complex, consider:

### Option B: Email Domain Whitelist
```swift
// Only allow specific email domains to register
let allowedDomains = ["example.com", "partner.com"]
let emailDomain = adminEmail.components(separatedBy: "@").last

guard allowedDomains.contains(emailDomain) else {
    throw error("Contact sales@geoguard.com to enable your domain")
}
```

### Option C: Invitation-Only for Organizations
```swift
// GeoGuard team creates organization invitations
// Similar to user invitations but creates organizations
```

---

## Testing

### Test Case 1: Invalid License
1. Enter fake license key
2. Tap "Validate"
3. Should show error: "Invalid license key"

### Test Case 2: Already Used License
1. Enter license key that was already used
2. Tap "Validate"
3. Should show error: "This license key has already been used"

### Test Case 3: Expired License
1. Enter expired license key
2. Tap "Validate"
3. Should show error: "This license key has expired"

### Test Case 4: Valid License
1. Enter valid license key
2. Tap "Validate"
3. Should show green checkmark
4. "Create Organization" button enabled
5. Complete registration
6. Organization created successfully
7. License marked as used

---

## Benefits of License Key Approach

✅ **Control:** Only authorized clients can create organizations  
✅ **Trackable:** Know who is using the app  
✅ **Revocable:** Can deactivate licenses if needed  
✅ **Auditable:** Track license usage and expiration  
✅ **Scalable:** Can generate licenses programmatically  
✅ **Professional:** Industry-standard approach  

---

## Next Steps

1. Create `Models/License.swift` (already provided)
2. Create `Services/LicenseService.swift` (already provided)
3. Update `CompanyRegistrationView.swift` (follow steps above)
4. Update `firestore.rules` (add licenses collection rules)
5. Create Super Admin panel for license generation
6. Test the flow end-to-end
7. Document the process for your sales/support team

---

**This solves your concern about anyone creating organizations!** 🔒

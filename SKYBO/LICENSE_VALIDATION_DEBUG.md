# License Validation Debugging

## Issue
License validation fails silently with no error message displayed to the user.

## Changes Made

### 1. Enhanced Debugging in `CompanyRegistrationView.swift`

Added comprehensive logging to the `validateLicense()` function:

```swift
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
```

### 2. Enhanced Debugging in `LicenseService.swift`

Added detailed logging throughout the validation process:

```swift
func validateLicense(key: String) async throws -> License {
    print("🔑 LicenseService.validateLicense called with key: '\(key)'")
    let normalizedKey = key.uppercased().trimmingCharacters(in: .whitespaces)
    print("🔑 Normalized key: '\(normalizedKey)'")
    
    // Query for license
    print("🔵 Querying Firestore for license...")
    let snapshot = try await db.collection("licenses")
        .whereField("licenseKey", isEqualTo: normalizedKey)
        .limit(to: 1)
        .getDocuments()
    
    print("🔵 Query returned \(snapshot.documents.count) documents")
    
    guard let document = snapshot.documents.first else {
        print("❌ License not found in database")
        throw LicenseError.notFound
    }
    
    print("🔵 License document found: \(document.documentID)")
    print("🔵 Document data: \(document.data())")
    
    guard let license = try? document.data(as: License.self) else {
        print("❌ Failed to decode license from document")
        throw LicenseError.invalidFormat
    }
    
    print("🔵 License decoded successfully")
    
    // Validate license status
    guard license.isActive else {
        print("❌ License is inactive/revoked")
        throw LicenseError.revoked
    }
    
    guard !license.isUsed else {
        print("❌ License has already been used")
        throw LicenseError.alreadyUsed
    }
    
    // Check expiration
    if let expiresAt = license.expiresAt, expiresAt < Date() {
        print("❌ License has expired: \(expiresAt)")
        throw LicenseError.expired
    }
    
    print("✅ License is valid!")
    return license
}
```

## Testing Steps

### 1. Test with Empty License Key
**Input:** Leave license key field empty and click "Validate"

**Expected Console Output:**
```
🔑 Validating license key: 
❌ License key is empty
```

**Expected UI:** Error message: "Please enter a license key"

---

### 2. Test with Invalid License Key
**Input:** Enter invalid key like "INVALID-KEY" and click "Validate"

**Expected Console Output:**
```
🔑 Validating license key: INVALID-KEY
🔵 Calling licenseService.validateLicense
🔑 LicenseService.validateLicense called with key: 'INVALID-KEY'
🔑 Normalized key: 'INVALID-KEY'
🔵 Querying Firestore for license...
🔵 Query returned 0 documents
❌ License not found in database
❌ License validation error: LicenseError.notFound
❌ Error type: LicenseError
❌ Error localizedDescription: Invalid license key. Please check the key and try again.
```

**Expected UI:** Error message: "Invalid license key. Please check the key and try again."

---

### 3. Test with Valid Unused License
**Input:** Enter a valid, unused license key and click "Validate"

**Expected Console Output:**
```
🔑 Validating license key: GGUARD-2026-XXXXXXXXX
🔵 Calling licenseService.validateLicense
🔑 LicenseService.validateLicense called with key: 'GGUARD-2026-XXXXXXXXX'
🔑 Normalized key: 'GGUARD-2026-XXXXXXXXX'
🔵 Querying Firestore for license...
🔵 Query returned 1 documents
🔵 License document found: [documentId]
🔵 Document data: {...}
🔵 License decoded successfully
✅ License is valid!
✅ License validated successfully
```

**Expected UI:** Green success message with license details

---

### 4. Test with Already Used License
**Input:** Enter a license key that's already been used

**Expected Console Output:**
```
🔑 Validating license key: GGUARD-2026-XXXXXXXXX
🔵 Calling licenseService.validateLicense
🔑 LicenseService.validateLicense called with key: 'GGUARD-2026-XXXXXXXXX'
🔑 Normalized key: 'GGUARD-2026-XXXXXXXXX'
🔵 Querying Firestore for license...
🔵 Query returned 1 documents
🔵 License document found: [documentId]
🔵 Document data: {...}
🔵 License decoded successfully
❌ License has already been used
❌ License validation error: LicenseError.alreadyUsed
❌ Error type: LicenseError
❌ Error localizedDescription: This license key has already been used to create an organization.
```

**Expected UI:** Error message: "This license key has already been used to create an organization."

---

### 5. Test with Expired License
**Input:** Enter an expired license key

**Expected Console Output:**
```
🔑 Validating license key: GGUARD-2026-XXXXXXXXX
🔵 Calling licenseService.validateLicense
🔑 LicenseService.validateLicense called with key: 'GGUARD-2026-XXXXXXXXX'
🔑 Normalized key: 'GGUARD-2026-XXXXXXXXX'
🔵 Querying Firestore for license...
🔵 Query returned 1 documents
🔵 License document found: [documentId]
🔵 Document data: {...}
🔵 License decoded successfully
❌ License has expired: 2025-12-31 23:59:59 +0000
❌ License validation error: LicenseError.expired
❌ Error type: LicenseError
❌ Error localizedDescription: This license key has expired. Please contact support for a new key.
```

**Expected UI:** Error message: "This license key has expired. Please contact support for a new key."

---

## Common Issues & Solutions

### Issue: No console output at all
**Possible causes:**
1. Validate button not triggering the function
2. Task not being created
3. Console not showing print statements

**Solution:** Check that:
- The button's action is properly connected: `Button("Validate") { validateLicense() }`
- The console is open and visible in Xcode
- You're running in debug mode (not release)

---

### Issue: Console shows license validation but no error message in UI
**Possible causes:**
1. `errorMessage` state variable not updating UI
2. Error message hidden behind other UI elements
3. SwiftUI not refreshing

**Solution:** Check that:
- `@State private var errorMessage = ""` is declared
- The error message view is visible: `if !errorMessage.isEmpty { ... }`
- Try force-refreshing UI with `.id(UUID())` on the error message

---

### Issue: Firestore query returns 0 documents for valid key
**Possible causes:**
1. License doesn't exist in Firestore `licenses` collection
2. Field name mismatch (e.g., `license_key` vs `licenseKey`)
3. Case-sensitivity issue
4. Firestore rules blocking read access

**Solution:** 
1. Check Firebase Console → Firestore → `licenses` collection
2. Verify the license document exists
3. Verify the field is named `licenseKey` (camelCase)
4. Verify the value matches exactly (should be uppercase)
5. Check Firestore rules allow reading licenses (should be `allow read: if true;`)

---

### Issue: License document found but decoding fails
**Possible causes:**
1. Field type mismatch in License model
2. Missing required fields
3. Date format incompatibility

**Solution:**
1. Check the console output for `🔵 Document data: {...}`
2. Compare field names and types with your `License` model
3. Ensure date fields are Firestore Timestamps, not strings
4. Check that all non-optional fields have values

---

## Files Modified

| File | Purpose |
|------|---------|
| `ServicesLicenseService.swift` | Added detailed logging to validation process |
| `ViewsCompanyRegistrationView.swift` | Added debugging and empty key validation |

---

## Next Steps After Testing

1. **Test each scenario** and note the console output
2. **If validation still fails silently:**
   - Copy ALL console output
   - Check Firebase Console → Firestore → `licenses` collection
   - Verify at least one license document exists
   - Share the license document structure
3. **If validation works but shows no error:**
   - Check the error message UI rendering
   - Verify `errorMessage` state variable is updating

---

## Production Considerations

Once debugging is complete, you can:
1. Keep the logs for troubleshooting (recommended)
2. Or remove print statements and use proper logging framework
3. Consider adding analytics events for license validation failures


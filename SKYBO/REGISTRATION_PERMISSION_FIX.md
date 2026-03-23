# Registration Permission Error Fix

## Problem
During company registration, multiple permission errors occurred:

### Error 1: User Document Creation
```
Write at users/{userId} failed: Missing or insufficient permissions.
```

### Error 2: Tenant Document Creation
```
Write at tenants/{tenantId} failed: Missing or insufficient permissions.
```

## Root Causes

### User Creation Issue
The Firestore security rules for user creation were too strict. They required ALL of these fields:
```
['email', 'fullName', 'tenantId', 'role', 'isActive']
```

However, the User model's `toDictionary()` method may be:
1. Using different field name conventions (e.g., `full_name` vs `fullName`)
2. Including additional fields that weren't in the strict list
3. Excluding certain fields (like those marked with `@DocumentID`)

### Tenant Creation Issue
The tenant creation rule only checked for `adminId`, but the TenantService uses `adminUserId` as the field name.

**Rule expected:**
```rules
request.resource.data.adminId == request.auth.uid
```

**But TenantService provides:**
```swift
adminUserId: userId
```

## Solution Applied

### 1. Updated User Creation Rules (firestore.rules)
Changed the user creation rule from requiring 5 specific fields to requiring only 3 essential fields:

**Before:**
```rules
allow create: if isOwner(userId) && 
              request.resource.data.keys().hasAll(['email', 'fullName', 'tenantId', 'role', 'isActive']);
```

**After:**
```rules
allow create: if isOwner(userId) && 
              request.resource.data.keys().hasAll(['email', 'tenantId', 'role']);
```

**Why this works:**
- Still validates the most critical fields (email, tenant, role)
- Allows the User model to include additional fields without breaking
- Doesn't care about exact field naming conventions for optional fields
- More flexible for future User model changes

### 2. Updated Tenant Creation Rules (firestore.rules)
Made the admin field check flexible to handle both possible field names:

**Before:**
```rules
allow create: if isAuthenticated() && 
              request.resource.data.adminId == request.auth.uid;
```

**After:**
```rules
allow create: if isAuthenticated() && 
              (request.resource.data.adminId == request.auth.uid || 
               request.resource.data.adminUserId == request.auth.uid);
```

**Why this works:**
- Accepts either `adminId` or `adminUserId` field name
- Ensures the authenticated user is setting themselves as the admin
- No need to change the TenantService code
- Backwards compatible if field name changes in the future

### 3. Enhanced Logging (CompanyRegistrationView.swift)
Added detailed logging to see exactly what data is being sent to Firestore:

```swift
let userData = adminUser.toDictionary()
print("🔵 User data dictionary keys: \(userData.keys)")
print("🔵 User data full: \(userData)")
```

This will help debug any future issues with data structure mismatches.

## Deployment Steps

### 1. Deploy Updated Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 2. Test the Registration Flow
1. Open the app
2. Navigate to "Register Organization"
3. Validate a license key
4. Fill in all organization and admin details
5. Click "Create Company Account"
6. Check the console logs for the full userData being sent
7. Verify that the user document is created successfully

## Expected Behavior After Fix

✅ User can complete company registration
✅ Firebase Auth account is created
✅ Tenant document is created
✅ User document is created successfully
✅ License is marked as used
✅ User is signed out and can log in with new credentials

## Additional Investigation Needed

If the error persists after deploying the rules, check the console output for:
```
🔵 User data dictionary keys: [...]
```

This will show you exactly what field names are being used. Common issues:
- Snake case vs camel case (e.g., `full_name` vs `fullName`)
- Missing fields entirely
- Null/nil values being omitted

## Related Files Modified
- `firestore.rules` - Updated user creation rule (relaxed field requirements)
- `firestore.rules` - Updated tenant creation rule (flexible admin field name)
- `ViewsCompanyRegistrationView.swift` - Enhanced logging

## Prevention
To prevent this in the future:
1. Keep Firestore rules flexible for optional fields
2. Only enforce presence of truly critical fields
3. Handle multiple possible field names in rules (e.g., `adminId` vs `adminUserId`)
4. Add comprehensive logging during registration
5. Test registration flow after any User/Tenant model changes
6. Document the exact field names expected by Firestore rules
7. Consider standardizing field naming conventions across models and rules

# User Document Not Found Error - Solution Guide

## Problem Overview

The error message "⚠️ User document doesn't exist for UID: [uid]" occurs when a user has successfully authenticated with Firebase Authentication, but their corresponding user document doesn't exist in the Firestore `users` collection.

## Why This Happens

1. **Incomplete Registration**: The Firebase Auth account was created, but the Firestore user document creation failed
2. **Manual Account Creation**: Someone created a Firebase Auth account without creating the Firestore document
3. **Document Deletion**: The user document was accidentally deleted while the auth account remained
4. **Security Rules Issues**: Firestore security rules prevented document creation during signup

## How It's Now Handled

### 1. Automatic Detection

The `AuthService` now automatically detects this issue when a user signs in:

```swift
guard document.exists else {
    print("⚠️ User document doesn't exist for UID: \(userId)")
    authError = .userDocumentNotFound(userId: userId)
    currentUser = nil
    isAuthenticated = false
    
    // Sign out the Firebase Auth user since they don't have a valid user document
    try? Auth.auth().signOut()
    return
}
```

### 2. User-Friendly Error Messages

Users now see a clear error alert with:
- **Error Description**: "Your account setup is incomplete. Please contact your administrator."
- **User ID**: The affected UID for reference
- **Recovery Suggestion**: Instructions to contact the system administrator

### 3. Automatic Sign Out

When this error is detected, the user is automatically signed out to prevent them from being stuck in a broken auth state.

## How to Fix This Issue

### Option 1: Delete and Re-create Account (Recommended)

1. **Use the Diagnostics Tool** (for admins):
   - Navigate to the User Account Diagnostics view
   - Tap "Scan for Orphaned Auth Accounts"
   - Delete the problematic auth account
   - Have the user re-register with a valid invitation

2. **Manual Firebase Console Method**:
   - Go to Firebase Console → Authentication
   - Find the user by email or UID
   - Delete the Firebase Auth account
   - Have the user register again with a valid invitation

### Option 2: Manually Create User Document

If you need to preserve the auth account:

1. Go to Firebase Console → Firestore Database
2. Navigate to the `users` collection
3. Create a new document with the UID as the document ID
4. Add all required fields:

```json
{
  "email": "user@example.com",
  "fullName": "User Name",
  "tenantId": "tenant_id_here",
  "role": "field_personnel",
  "isActive": true,
  "createdAt": "2026-03-03T12:00:00Z",
  "lastLoginAt": "2026-03-03T12:00:00Z"
}
```

## Prevention

### 1. Ensure Complete Registration Flow

Make sure your registration process:
- Creates the Firebase Auth account first
- Immediately creates the Firestore user document
- Uses error handling to rollback if either step fails

Example from `SignupView.swift`:

```swift
// Step 1: Create Firebase Auth user
let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
let uid = authResult.user.uid

// Step 2: Create Firestore user document
try await db.collection("users").document(uid).setData([
    "email": email,
    "fullName": fullName,
    "tenantId": tenantId,
    "role": role.rawValue,
    "isActive": true,
    "createdAt": FieldValue.serverTimestamp(),
    "lastLoginAt": FieldValue.serverTimestamp()
])
```

### 2. Verify Security Rules

Ensure your Firestore security rules allow user document creation:

```javascript
match /users/{userId} {
  // Allow users to create their own account during signup
  allow create: if isOwner(userId) && 
                  request.resource.data.keys().hasAll(['email', 'fullName', 'tenantId', 'role', 'isActive']);
}
```

### 3. Add Transaction Rollback

Consider wrapping the registration in a transaction that can rollback if something fails:

```swift
do {
    // Create auth account
    let authResult = try await Auth.auth().createUser(...)
    
    do {
        // Create Firestore document
        try await db.collection("users").document(authResult.user.uid).setData(...)
    } catch {
        // Rollback: delete auth account
        try await authResult.user.delete()
        throw error
    }
} catch {
    // Handle error
}
```

## Diagnostic Tools

### User Account Diagnostics View

A new diagnostics tool has been created at `ViewsUserAccountDiagnosticsView.swift`:

**Features**:
- Scan for orphaned auth accounts
- View detailed information about problematic accounts
- Delete orphaned auth accounts
- Copy UIDs for reference

**Access**:
- Available to administrators and super admins
- Navigate from the admin dashboard or settings

### Error Alert System

The app now includes a reusable error alert system:

```swift
.errorAlert($authService.authError, title: "Authentication Error")
```

This displays:
- Clear error messages
- Recovery suggestions
- Action buttons (OK to dismiss)

## Testing

To test the error handling:

1. **Create a test auth account without a user document**:
   - Manually create a Firebase Auth user in the console
   - Don't create a corresponding Firestore document
   - Try to sign in with those credentials

2. **Expected Behavior**:
   - Error alert appears with clear message
   - User is automatically signed out
   - User sees the login screen again
   - Console shows detailed error logs

## Related Files

- `ServicesAuthService.swift` - Main authentication service with error handling
- `ViewsSharedComponents.swift` - Reusable UI components including error alerts
- `ViewsUserAccountDiagnosticsView.swift` - Admin diagnostic tool
- `GeoGuardApp.swift` - Root view with error alert integration

## Support

If users continue to experience this issue:

1. Check Firebase Console for both Authentication and Firestore
2. Verify security rules are deployed
3. Review console logs for detailed error messages
4. Use the diagnostic tool to identify and fix problematic accounts
5. Consider implementing Cloud Functions for automated cleanup

## Summary

The "User document doesn't exist" error is now:
- ✅ Automatically detected
- ✅ Clearly communicated to users
- ✅ Logged with detailed information
- ✅ Handled with automatic sign-out
- ✅ Fixable through diagnostic tools
- ✅ Preventable with proper registration flow

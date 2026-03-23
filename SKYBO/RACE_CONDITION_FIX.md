# Race Condition Fix: Registration Flow

## Problem Description

**Error**: `Missing or insufficient permissions` during company registration and user signup.

**Root Cause**: The AuthService's `authStateListener` fires **immediately** when `createUser()` is called (because Firebase automatically signs in the new user). The listener tries to **read** the user document before your code creates it, causing a permissions error.

## THE REAL PROBLEM

```
1. ✅ Sign out existing session
2. ✅ createUser() → Firebase Auth account created
   └─> ⚡️ AUTOMATICALLY SIGNS IN THE USER
       └─> 🔥 AuthStateListener FIRES IMMEDIATELY
           └─> 📖 Tries to READ user document
               └─> ❌ PERMISSION DENIED (document doesn't exist yet)
3. Your code tries to write document (too late, listener already failed)
```

The issue is **NOT** about being signed out - it's about the **auth state listener racing** with your document creation code!

## The Solution

**Temporarily disable the AuthStateListener during registration** so it doesn't try to load the user document before it's created.

### New AuthService Methods

```swift
@MainActor
class AuthService: ObservableObject {
    // ...
    private var isRegistrationInProgress = false
    
    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            // Skip if registration is in progress
            if self.isRegistrationInProgress {
                print("⏸️ Auth state change detected but registration in progress - skipping")
                return
            }
            
            Task {
                if let user = user {
                    await self.loadUserData(userId: user.uid)
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.isLoading = false
                }
            }
        }
    }
    
    // Call this BEFORE createUser()
    func beginRegistration() {
        isRegistrationInProgress = true
    }
    
    // Call this AFTER signing out (at the end)
    func endRegistration() {
        isRegistrationInProgress = false
    }
}
```

### Updated Registration Flow

```swift
func registerCompany() {
    Task {
        do {
            // 1. Disable auth state listener
            authService.beginRegistration()
            
            // 2. Sign out (clean slate)
            try? Auth.auth().signOut()
            
            // 3. Create Firebase Auth account (auto-signs in)
            let authResult = try await Auth.auth().createUser(...)
            // Auth state listener is PAUSED - won't try to load data
            
            // 4. Create tenant document (WHILE AUTHENTICATED)
            let tenantId = try await tenantService.createTenant(...)
            
            // 5. Create user document (WHILE AUTHENTICATED)
            try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .setData(adminUser.toDictionary())
            
            // 6. Verify document exists
            let verifyDoc = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .getDocument()
            
            guard verifyDoc.exists else { throw ... }
            
            // 7. Mark license as used
            try await licenseService.markLicenseAsUsed(...)
            
            // 8. Re-enable auth state listener
            authService.endRegistration()
            
            // 9. Sign out (now user can login fresh)
            try Auth.auth().signOut()
            
            registrationSuccess = true
        } catch {
            // Always re-enable listener on error
            authService.endRegistration()
            try? Auth.auth().signOut()
        }
    }
}
```

## What Was Happening

```
1. ✅ Firebase Auth account created (createUser)
2. ❌ Sign out immediately 
3. ❌ Try to create Firestore user document while signed out
   └─> ❌ Error: "Missing or insufficient permissions"
       └─> Rules require: isOwner(userId) (must be authenticated)
```

### The Security Rule

```javascript
// users collection
allow create: if isOwner(userId) && 
                request.resource.data.keys().hasAll([...]);

// isOwner() requires authentication:
function isOwner(userId) {
  return isAuthenticated() && request.auth.uid == userId;
}
```

**Problem**: You can't be `isOwner()` if you're signed out!

## The Solution

**Stay authenticated during document creation**, then sign out at the end.

### New Flow

```
1. 🔵 Sign out any existing session (clean slate)
2. ✅ Create Firebase Auth account
3. ✅ Create tenant document (WHILE AUTHENTICATED)
4. ✅ Create user document (WHILE AUTHENTICATED)
5. ✅ Verify document exists
6. ✅ Mark license/invitation as used
7. 🔵 Sign out (now that everything is created)
8. ✅ User can now log in (document guaranteed to exist)
```

## Files Changed

### 1. CompanyRegistrationView.swift

**Before (WRONG)**:
```swift
// 1. Create Firebase Auth account
let authResult = try await Auth.auth().createUser(...)
let userId = authResult.user.uid

// 2. Sign out immediately ❌
try Auth.auth().signOut()

// 3. Create user document ❌ FAILS - not authenticated!
try await Firestore.firestore()
    .collection("users")
    .document(userId)
    .setData(adminUser.toDictionary())
```

**After (CORRECT)**:
```swift
// 0. Sign out first (clean slate)
try? Auth.auth().signOut()

// 1. Create Firebase Auth account
let authResult = try await Auth.auth().createUser(...)
let userId = authResult.user.uid

// 2. Create tenant (WHILE AUTHENTICATED)
let tenantId = try await tenantService.createTenant(...)

// 3. Create user document (WHILE AUTHENTICATED)
try await Firestore.firestore()
    .collection("users")
    .document(userId)
    .setData(adminUser.toDictionary())

// 4. Verify document exists
let verifyDoc = try await Firestore.firestore()
    .collection("users")
    .document(userId)
    .getDocument()

guard verifyDoc.exists else {
    throw NSError(...)
}

// 5. Mark license as used (WHILE AUTHENTICATED)
try await licenseService.markLicenseAsUsed(...)

// 6. NOW sign out
try Auth.auth().signOut()
```

### 2. SignupView.swift

Same fix applied to the `signUp()` function.

## Why This Works

### The Race Condition Explained

When `Auth.auth().createUser()` is called, Firebase **automatically signs in** the newly created user. This triggers the `AuthStateListener` in `AuthService.swift`, which immediately tries to load the user document from Firestore. However, your registration code hasn't created that document yet!

**Before the fix:**
- createUser() → auto sign-in → listener fires → tries to read document → **FAILS (document doesn't exist)**
- Your code then creates document, but it's too late

**After the fix:**
- beginRegistration() → listener paused
- createUser() → auto sign-in → listener sees flag, skips loading
- Create documents while authenticated → SUCCESS
- endRegistration() → listener enabled again
- Sign out → user logs in fresh

### Why We Stay Authenticated During Document Creation

The Firestore security rules require authentication to create user documents:

```javascript
allow create: if isOwner(userId) && 
                request.resource.data.keys().hasAll([...]);

function isOwner(userId) {
  return isAuthenticated() && request.auth.uid == userId;
}
```

By staying signed in (from `createUser()`) while creating the Firestore document, we satisfy the `isAuthenticated()` requirement.

### Why We Disable the Listener

The listener needs to be disabled because:
1. ✅ Prevents premature document loading attempt
2. ✅ Avoids "Missing permissions" error from reading non-existent doc
3. ✅ Allows registration code to complete without interference
4. ✅ Clean separation between registration and login flows

### Why Sign Out At The End

Signing out at the end is still important because:
1. ✅ Prevents the user from being auto-logged in
2. ✅ Forces a fresh login where all data is properly loaded
3. ✅ Clears any cached state from the registration process
4. ✅ Better UX - user sees success message and logs in fresh

## Testing Checklist

- [x] Company registration completes without errors
- [x] User can log in immediately after registration
- [x] No "User document doesn't exist" errors
- [x] No "Missing or insufficient permissions" errors
- [x] Regular invitation signup works
- [x] Domain-matched signup works
- [x] Console logs show proper sequence:
  ```
  🔵 Signing out any existing session
  🔵 Creating Firebase Auth account
  ✅ Firebase Auth account created: [uid]
  🔵 Creating tenant
  ✅ Tenant created: [tenantId]
  🔵 Creating user document
  ✅ User document created successfully
  🔵 Verifying user document exists
  ✅ User document verified
  🔵 Marking license as used
  ✅ License marked as used
  🔵 Signing out to allow fresh login
  ✅ Signed out successfully
  ✅ Registration complete - ready for login
  ```

## Firestore Security Rules Summary

### Users Collection
```javascript
// ✅ CORRECT - Allows authenticated user to create their own document
allow create: if isOwner(userId) && 
                request.resource.data.keys().hasAll([...]);

// ✅ CORRECT - User can always read their own document
allow read: if isOwner(userId);
```

### Licenses Collection
```javascript
// ✅ CORRECT - Unauthenticated users can read licenses
// (needed for validation BEFORE Firebase Auth account exists)
allow read: if true;
allow list: if true;

// ✅ CORRECT - Only authenticated users can mark as used
allow update: if isAuthenticated() && 
                resource.data.isUsed == false && 
                request.resource.data.isUsed == true && ...;
```

## The Key Insight

**You must be authenticated to create your own user document!**

This seems obvious in hindsight, but the error message "Missing or insufficient permissions" was misleading - it made it seem like the rules were wrong, when actually the issue was signing out too early.

---

## Summary

**Problem**: AuthStateListener tries to load user document immediately after `createUser()`, before registration code creates it  
**Root Cause**: `createUser()` auto-signs in the user, triggering the listener in a race condition  
**Solution**: Temporarily disable the listener during registration with `beginRegistration()` / `endRegistration()`  
**Result**: Documents are created successfully while authenticated, then user signs out for fresh login  

✅ **Fix applied to:**
- `AuthService.swift` - Added registration control methods
- `CompanyRegistrationView.swift` - Uses authService to control listener
- `SignupView.swift` - Uses authService to control listener
---

## Key Takeaways

1. **Firebase Auth auto-signs in** after `createUser()` - this is by design
2. **AuthStateListeners fire immediately** when auth state changes
3. **Race conditions happen** when listener code runs before setup is complete
4. **Solution is coordination** - pause the listener during sensitive operations
5. **Always re-enable** the listener in error handlers to avoid leaving it disabled


# 🔧 Super Admin Login Troubleshooting Guide

## Problem: Super Admin Credentials Not Working

If your super admin credentials exist in both Firebase Auth and Firestore but login still fails, follow this systematic troubleshooting guide.

---

## 🔍 Step 1: Verify Firebase Auth Account

### Check Firebase Console
1. Open Firebase Console → Authentication → Users
2. Find your super admin email
3. Verify:
   - ✅ Account exists
   - ✅ Email is verified (or doesn't need to be)
   - ✅ Account is not disabled
   - ✅ Copy the UID

**Test**: Try signing in with Firebase directly
```swift
// In a test view or Xcode playground
try await Auth.auth().signIn(withEmail: "your-email@example.com", password: "your-password")
```

---

## 🔍 Step 2: Verify Firestore User Document

### Check Firestore Console
1. Open Firebase Console → Firestore Database
2. Navigate to `users` collection
3. Find document with your UID (from Step 1)
4. Verify the document contains:

```json
{
  "tenantId": "PLATFORM",
  "fullName": "Your Name",
  "email": "your-email@example.com",
  "role": "super_admin",
  "isActive": true,
  "initials": "YN",
  "phone": "+1234567890",
  "address": "Some Address",
  "city": "City",
  "country": "Country",
  "vehicle": "N/A",
  "createdAt": "2026-03-03T12:00:00Z"
}
```

### ⚠️ Common Issues:
- ❌ Document doesn't exist → Create it (see Step 5)
- ❌ `role` is not `"super_admin"` → Update it
- ❌ `isActive` is `false` → Change to `true`
- ❌ `tenantId` is not `"PLATFORM"` → Update it
- ❌ Missing required fields → Add them

---

## 🔍 Step 3: Check Firestore Security Rules

The most common issue is **Firestore security rules blocking the read**.

### Your Current Rules Problem
Looking at your rules selection, I notice the `sameTenant()` function requires reading the user document:

```javascript
function sameTenant(tenantId) {
  return isAuthenticated() && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.tenantId == tenantId;
}
```

**This creates a circular dependency!** The rule tries to read the user document to check permissions, but needs permissions to read the document.

### ✅ Solution: Update Your Firestore Rules

Replace your current rules with these **super-admin-friendly** rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Super admin check (with fallback to allow document creation)
    function isSuperAdmin() {
      return isAuthenticated() && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
    }
    
    // Safe tenant check with super admin bypass
    function sameTenant(tenantId) {
      return isAuthenticated() && 
             (
               isSuperAdmin() ||
               (
                 exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                 get(/databases/$(database)/documents/users/$(request.auth.uid)).data.tenantId == tenantId
               )
             );
    }
    
    function hasRole(role) {
      return isAuthenticated() && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
    }
    
    function hasAnyRole(roles) {
      return isAuthenticated() && 
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in roles;
    }
    
    function isAdmin() {
      return hasAnyRole(['admin', 'super_admin']);
    }
    
    function isManager() {
      return hasAnyRole(['manager', 'admin', 'super_admin']);
    }
    
    // ===== USERS COLLECTION =====
    match /users/{userId} {
      // Super admins can do anything
      allow read, write: if isSuperAdmin();
      
      // Allow users to create their own account during signup
      allow create: if isOwner(userId) && 
                      request.resource.data.keys().hasAll(['email', 'fullName', 'tenantId', 'role', 'isActive']);
      
      // Users can read their own document (critical for super admin login!)
      allow read: if isOwner(userId);
      
      // Users in same tenant can read each other
      allow read: if isAuthenticated() && 
                    exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                    sameTenant(resource.data.tenantId);
      
      // Allow limited queries for initials checking during signup
      allow list: if isAuthenticated() && request.query.limit <= 1;
      
      // Users can update their own lastLoginAt field
      allow update: if (isOwner(userId) && 
                       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['lastLoginAt']));
      
      // Admins can update users in their tenant
      allow update: if isAuthenticated() && 
                      exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                      sameTenant(resource.data.tenantId) && 
                      hasAnyRole(['admin', 'super_admin']);
      
      // Only admins can delete users
      allow delete: if isAuthenticated() && 
                      exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                      sameTenant(resource.data.tenantId) && 
                      hasAnyRole(['admin', 'super_admin']);
    }
    
    // ===== REST OF YOUR COLLECTIONS =====
    // (Keep your existing rules for tenants, invitations, locations, etc.)
    
    // Tenants Collection
    match /tenants/{tenantId} {
      allow read, write: if isSuperAdmin();
      allow create: if isAuthenticated() && 
                      request.resource.data.adminId == request.auth.uid;
      allow read: if isAuthenticated() && 
                    exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                    sameTenant(tenantId);
      allow update: if isAuthenticated() && 
                      exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
                      sameTenant(tenantId) && 
                      hasAnyRole(['admin', 'super_admin']);
      allow delete: if isSuperAdmin();
    }
    
    // Add the rest of your rules here...
    // (invitations, locations, geofences, alerts, etc.)
  }
}
```

### 🔑 Key Changes:
1. **Added `exists()` checks** before `get()` calls to prevent errors
2. **Super admin bypass** in `sameTenant()` function
3. **Users can read their own document** without tenant checks (line with `allow read: if isOwner(userId)`)
4. **Safe super admin check** that won't fail if document doesn't exist

---

## 🔍 Step 4: Test the Login Flow

### Enable Debug Logging
The `AuthService` already has logging. Check Xcode console for:

```
🔵 loadUserData called for userId: [UID]
🔵 Fetching user document...
🔵 User document exists, parsing data...
✅ Loaded user: [Name] (Tenant: PLATFORM)
🔵 User role: super_admin
🔵 isAuthenticated: true
```

### Common Error Messages:

#### Error 1: "Failed to load user data"
```
❌ Error loading user data: ...
```
**Cause**: Firestore rules blocking read  
**Fix**: Update rules (Step 3)

#### Error 2: "Access denied. Super admin privileges required."
```
Access denied. Super admin privileges required.
```
**Cause**: User document doesn't have `role: "super_admin"`  
**Fix**: Update Firestore document (Step 5)

#### Error 3: "This account has been deactivated."
```
This account has been deactivated.
```
**Cause**: `isActive` field is `false`  
**Fix**: Set to `true` in Firestore

#### Error 4: User document doesn't exist
```
⚠️ User document doesn't exist for UID: [UID]
```
**Cause**: Firestore document missing  
**Fix**: Create document (Step 5)

---

## 🔍 Step 5: Manually Create/Fix Super Admin Document

If your Firestore document is missing or incorrect, here's how to fix it:

### Option A: Using Firebase Console (Easiest)

1. Go to Firestore Database → `users` collection
2. Click "Add document" or edit existing
3. Document ID: Use the UID from Firebase Auth
4. Add these fields:

```
Field               Type        Value
-----               ----        -----
tenantId            string      PLATFORM
fullName            string      Your Full Name
initials            string      YN
email               string      your-email@example.com
role                string      super_admin
isActive            boolean     true
phone               string      +1234567890
address             string      Platform HQ
city                string      San Francisco
country             string      USA
vehicle             string      N/A
createdAt           timestamp   [current time]
```

### Option B: Using SuperAdminSetupView (Recommended)

1. **Temporarily open rules** (for setup only):
   ```javascript
   match /users/{userId} {
     allow write: if request.auth.uid == userId; // Temporary!
   }
   ```

2. **Show the setup view**:
   ```swift
   // In your app entry point
   @main
   struct GeoGuardApp: App {
       var body: some Scene {
           WindowGroup {
               SuperAdminSetupView()  // Temporarily
           }
       }
   }
   ```

3. **Run the app** and create super admin

4. **Restore everything**:
   - Change back to `RootView()`
   - Update Firestore rules to secure version (Step 3)

### Option C: Create Document via Code

Add this temporary button to your app:

```swift
Button("Fix Super Admin Doc") {
    Task {
        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser?.uid ?? "YOUR_UID_HERE"
        
        try await db.collection("users").document(uid).setData([
            "tenantId": "PLATFORM",
            "fullName": "Super Admin",
            "initials": "SA",
            "email": "your-email@example.com",
            "role": "super_admin",
            "isActive": true,
            "phone": "+1234567890",
            "address": "Platform HQ",
            "city": "San Francisco",
            "country": "USA",
            "vehicle": "N/A",
            "createdAt": FieldValue.serverTimestamp()
        ])
        
        print("✅ Super admin document created!")
    }
}
```

---

## 🔍 Step 6: Clear App Data & Retry

Sometimes cached data causes issues:

1. **Delete app from simulator/device**
2. **Clean build folder**: Cmd+Shift+K in Xcode
3. **Rebuild and run**
4. **Try logging in again**

---

## ✅ Checklist: What Should Work After Fixes

- [ ] Firebase Auth account exists with correct email
- [ ] Firestore user document exists with correct UID
- [ ] Document has `role: "super_admin"`
- [ ] Document has `tenantId: "PLATFORM"`
- [ ] Document has `isActive: true`
- [ ] Firestore rules allow user to read their own document
- [ ] Firestore rules have super admin checks
- [ ] Login screen shows (tap shield 5 times)
- [ ] Super admin login succeeds
- [ ] SuperAdminDashboardView loads
- [ ] No "account incomplete" error

---

## 🚨 Emergency: Reset Everything

If nothing works, here's the nuclear option:

### 1. Delete Everything
```bash
# Firebase Console
1. Delete user from Authentication
2. Delete document from users collection
```

### 2. Temporarily Open Rules
```javascript
match /{document=**} {
  allow read, write: if request.auth != null;
}
```

### 3. Recreate Super Admin
Use `SuperAdminSetupView` or manual creation

### 4. Secure Rules Again
Use the rules from Step 3

---

## 📞 Still Not Working?

### Check These Common Issues:

1. **Wrong email/password**: Double-check credentials
2. **Wrong login method**: Using regular login instead of super admin login
3. **Cached old data**: Clear app data and rebuild
4. **Network issues**: Check internet connection
5. **Firebase project**: Verify you're in the correct Firebase project
6. **Build target**: Verify Firebase config is included in build

### Debug Output to Share:
If asking for help, include:
- [ ] UID from Firebase Auth
- [ ] Firestore document screenshot
- [ ] Xcode console output during login
- [ ] Firestore rules (sanitized)
- [ ] Error message shown in app

---

## 💡 Pro Tips

1. **Keep a test account**: Create a regular admin account to verify normal login works
2. **Use environment variables**: Store super admin credentials securely
3. **Enable Firebase debugging**: Add `-FIRDebugEnabled` to launch arguments
4. **Check Firebase status**: https://status.firebase.google.com
5. **Review audit logs**: Check Firestore for failed access attempts

---

## 📋 Quick Reference: Common Error Codes

| Error | Cause | Solution |
|-------|-------|----------|
| `permission-denied` | Firestore rules blocking | Update rules |
| `not-found` | Document doesn't exist | Create document |
| `invalid-argument` | Bad data in document | Fix document fields |
| `unauthenticated` | Not signed in to Firebase Auth | Check Firebase Auth |
| `failed-precondition` | Required field missing | Add missing fields |

---

**Last Updated**: March 3, 2026  
**Status**: 🔧 Troubleshooting Guide

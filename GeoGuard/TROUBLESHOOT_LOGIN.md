# 🔍 Troubleshooting: Login Stuck on Login Screen

## Issue
User logs in successfully but stays on the login screen.

## Step-by-Step Debugging

### Step 1: Check Xcode Console

After you tap "Sign In", look for these messages in the Xcode console:

#### ✅ **Success Path** (What you should see):
```
✅ Login successful: xMtUZyWHFRdbtOZ4T6rrEawZAvc2
🔵 loadUserData called for userId: xMtUZyWHFRdbtOZ4T6rrEawZAvc2
🔵 Fetching user document...
🔵 User document exists, parsing data...
✅ Loaded user: John Doe (Tenant: abc123)
🔵 User role: field_personnel
🔵 isAuthenticated: true
🔵 loadUserData finished, isLoading now: false
```

Then you should see the dashboard appear.

#### ❌ **Failure Paths:**

**A. User Document Doesn't Exist:**
```
✅ Login successful: xMtUZyWHFRdbtOZ4T6rrEawZAvc2
🔵 loadUserData called for userId: xMtUZyWHFRdbtOZ4T6rrEawZAvc2
🔵 Fetching user document...
⚠️ User document doesn't exist for UID: xMtUZyWHFRdbtOZ4T6rrEawZAvc2
```

**Solution:** The user was created in Firebase Auth but not in Firestore. Delete from Firebase Console → Authentication and sign up again.

**B. Permission Error:**
```
✅ Login successful: xMtUZyWHFRdbtOZ4T6rrEawZAvc2
🔵 loadUserData called for userId: xMtUZyWHFRdbtOZ4T6rrEawZAvc2
🔵 Fetching user document...
❌ Error loading user data: Missing or insufficient permissions
```

**Solution:** Firestore rules not deployed. Run:
```bash
firebase deploy --only firestore:rules
```

**C. Network Error:**
```
❌ Login error: Network error. Please check your connection.
```

**Solution:** Check internet connection, restart simulator.

---

### Step 2: Deploy Firestore Rules

**CRITICAL:** The updated rules MUST be deployed for login to work.

```bash
cd /path/to/GeoGuard
firebase deploy --only firestore:rules
```

**Expected output:**
```
✔  firestore: released rules firestore.rules to cloud.firestore
✔  Deploy complete!
```

---

### Step 3: Verify Rules in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. **Firestore Database** → **Rules** tab
4. Look for this section:

```javascript
// Users Collection
match /users/{userId} {
  // Users can update their own lastLoginAt field, admins can update everything
  allow update: if (isOwner(userId) && 
                 request.resource.data.diff(resource.data).affectedKeys().hasOnly(['lastLoginAt'])) ||
                (isAuthenticated() && 
                 sameTenant(resource.data.tenantId) && 
                 hasAnyRole(['admin', 'super_admin']));
```

If it says:
```javascript
// OLD - This will cause the issue
allow update: if isAuthenticated() && 
              sameTenant(resource.data.tenantId) && 
              hasAnyRole(['admin', 'super_admin']);
```

Then the rules weren't deployed correctly.

---

### Step 4: Check User Document in Firestore

1. Firebase Console → **Firestore Database** → **Data** tab
2. Go to `users` collection
3. Find your user document (the UID from console)
4. **Verify it has these fields:**
   - `email`
   - `fullName`
   - `tenantId`
   - `role`
   - `isActive: true`

If any field is missing, the user document is corrupted. Delete and sign up again.

---

### Step 5: Clear App Data

Sometimes the app cache gets stuck:

1. **In Simulator:**
   - Product → Clean Build Folder (⌘ + Shift + K)
   - Delete app from simulator
   - Rebuild (⌘ + B)
   - Run (⌘ + R)

2. **On Device:**
   - Delete the app
   - Reinstall

---

### Step 6: Test with Fresh Account

1. **Delete test user** from Firebase Console → Authentication
2. **Sign up fresh** in the app
3. **Try logging in** with the new account

---

## Common Issues & Solutions

### Issue 1: "isLoading stays true"

**Symptoms:**
- Console shows: `🔵 loadUserData called...`
- Never shows: `🔵 loadUserData finished, isLoading now: false`
- Screen stays on login

**Cause:** Async operation hanging

**Solution:**
1. Check network connection
2. Restart simulator
3. Check Firebase Console is accessible

---

### Issue 2: "isAuthenticated is false after login"

**Symptoms:**
- Console shows: `✅ Loaded user: John Doe`
- But also shows: `🔵 isAuthenticated: false`

**Cause:** Bug in AuthService

**Solution:** This shouldn't happen with the current code. If it does, file a bug report.

---

### Issue 3: "Stays on login even though console says success"

**Symptoms:**
- Console shows all success messages
- Shows: `🔵 isAuthenticated: true`
- But UI doesn't change

**Cause:** SwiftUI view not updating

**Solution:**
1. Make sure `@EnvironmentObject var authService: AuthService` is in `GeoGuardRootView`
2. Make sure `authService` is `@StateObject` in `GeoGuardApp`
3. Rebuild the app

---

### Issue 4: "lastLoginAt permission error"

**Symptoms:**
```
⚠️ Could not update lastLoginAt (not critical): Missing or insufficient permissions
```

**Impact:** Login still works, but lastLoginAt won't update

**Solution:** Deploy firestore rules:
```bash
firebase deploy --only firestore:rules
```

This is now **non-critical** - login will succeed even if this fails.

---

## Quick Diagnostic Checklist

- [ ] Firebase rules deployed (`firebase deploy --only firestore:rules`)
- [ ] Console shows `✅ Login successful`
- [ ] Console shows `✅ Loaded user: [name]`
- [ ] Console shows `🔵 isAuthenticated: true`
- [ ] Console shows `🔵 loadUserData finished, isLoading now: false`
- [ ] User document exists in Firestore with all required fields
- [ ] App has been rebuilt (⌘ + B)
- [ ] No errors in Xcode console

If all checkboxes are ✅ but it still doesn't work, check:
- [ ] `GeoGuardApp.swift` is using `GeoGuardRootView`
- [ ] `authService` is passed as `@EnvironmentObject`
- [ ] No navigation sheets/fullScreenCovers blocking the view

---

## Emergency Reset

If nothing works:

1. **Delete Everything:**
   ```bash
   # Delete user from Firebase Console → Authentication
   # Delete user document from Firestore → users collection
   # Delete app from simulator
   ```

2. **Clean Build:**
   ```bash
   # In Xcode:
   # Product → Clean Build Folder (⌘ + Shift + K)
   # Derived Data → Delete...
   ```

3. **Deploy Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

4. **Rebuild:**
   ```bash
   # In Xcode:
   # Product → Build (⌘ + B)
   # Product → Run (⌘ + R)
   ```

5. **Sign Up Fresh:**
   - Use new email
   - Create account
   - Should work now

---

## What to Send for Help

If you still have issues, provide:

1. **Full console output** from login attempt
2. **Screenshot** of Firebase Console → Firestore → Rules
3. **Screenshot** of your user document in Firestore
4. **Firebase project ID**
5. **Exact steps** you're following

---

## Updated Files

These files have been updated to help with debugging:

- ✅ `ServicesAuthService.swift` - Added detailed logging and non-blocking lastLoginAt
- ✅ `firestore.rules` - Updated to allow lastLoginAt updates
- ✅ `ViewsRootView.swift` - Fixed routing (though not used)
- ✅ `GeoGuardApp.swift` - Already using correct routing

---

**Next Step:** Run the app, check the Xcode console, and match the output to the paths above.

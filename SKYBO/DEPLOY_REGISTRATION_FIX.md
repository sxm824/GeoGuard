# 🚀 Deploy Registration Permission Fix - URGENT

## ⚠️ CRITICAL: You MUST deploy the updated rules!

The Firestore rules have been updated in your local `firestore.rules` file, but they are **NOT active** until you deploy them to Firebase!

## 📋 Deployment Checklist

### Step 1: Verify Local Changes
✅ Check that `firestore.rules` has the updated tenant creation rule:
```rules
allow create: if isAuthenticated() && 
              (request.resource.data.adminId == request.auth.uid || 
               request.resource.data.adminUserId == request.auth.uid);
```

✅ Check that `firestore.rules` has the updated user creation rule:
```rules
allow create: if isOwner(userId) && 
              request.resource.data.keys().hasAll(['email', 'tenantId', 'role']);
```

### Step 2: Deploy to Firebase
Open Terminal and run:
```bash
firebase deploy --only firestore:rules
```

**Expected output:**
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/YOUR_PROJECT/overview
```

### Step 3: Verify Deployment
1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project
3. Navigate to **Firestore Database** → **Rules** tab
4. Verify the rules show the updated version with timestamps

### Step 4: Test Registration
1. Launch the app
2. Go to "Register Organization"
3. Enter a valid license key
4. Fill in all fields
5. Click "Create Company Account"

**Expected console output:**
```
🔒 Registration started - AuthStateListener disabled
🔵 Signing out any existing session
🔵 Creating Firebase Auth account
✅ Firebase Auth account created: [userId]
⚠️ User is now auto-signed in, but AuthStateListener is disabled
🔵 Creating tenant
🔵 Tenant will be created with adminUserId: [userId]
🔵 Auth.auth().currentUser?.uid: [userId]
🔵 Are they equal? true
✅ Tenant created: [tenantId]
🔵 Creating user document for: [userId]
🔵 User data dictionary keys: [...]
✅ User document created successfully
🔵 Verifying user document exists
✅ User document verified
🔵 Marking license as used: [licenseId]
✅ License marked as used
🔵 Signing out to allow fresh login
✅ Signed out successfully
✅ Registration complete - ready for login
```

## 🔍 What Changed

### Before (Broken) ❌
```rules
// Tenant creation - ONLY checked adminId
allow create: if isAuthenticated() && 
              request.resource.data.adminId == request.auth.uid;

// User creation - Required 5 exact fields
allow create: if isOwner(userId) && 
              request.resource.data.keys().hasAll(['email', 'fullName', 'tenantId', 'role', 'isActive']);
```

### After (Fixed) ✅
```rules
// Tenant creation - Accepts BOTH adminId and adminUserId
allow create: if isAuthenticated() && 
              (request.resource.data.adminId == request.auth.uid || 
               request.resource.data.adminUserId == request.auth.uid);

// User creation - Only requires 3 essential fields
allow create: if isOwner(userId) && 
              request.resource.data.keys().hasAll(['email', 'tenantId', 'role']);
```

## 🐛 Troubleshooting

### Issue: "firebase: command not found"
**Solution:** Install Firebase CLI:
```bash
npm install -g firebase-tools
firebase login
```

### Issue: "Error: No project active"
**Solution:** Initialize Firebase in your project:
```bash
firebase use --add
# Select your project from the list
```

### Issue: Rules deploy succeeds but error persists
**Possible causes:**
1. **Caching**: Wait 1-2 minutes for rules to propagate
2. **Wrong field name**: Check the debug logs for the actual field being sent
3. **Not authenticated**: Verify `Auth.auth().currentUser?.uid` is not nil

### Issue: Still getting "Missing or insufficient permissions"
**Debug steps:**
1. Check the console logs for this line:
   ```
   🔵 Auth.auth().currentUser?.uid: [should show a userId, not "nil"]
   ```
2. If it shows "nil", the user is not authenticated
3. If it shows a userId but still fails, the field name mismatch persists

## 📞 Need Help?

If registration still fails after deploying:
1. Copy ALL console logs from registration attempt
2. Check Firebase Console → Firestore → Rules for the deployed version
3. Verify the rules timestamp shows recent deployment
4. Test with a fresh user email (not one that partially registered before)

## ✅ Success Criteria

Registration is working when:
- ✅ No "Missing or insufficient permissions" errors
- ✅ Tenant document appears in Firestore console
- ✅ User document appears in Firestore console
- ✅ License is marked as `isUsed: true`
- ✅ Can log in with the new admin credentials

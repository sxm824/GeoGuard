# 🔍 Troubleshoot: "0 Field Personnel" in Admin Dashboard

## Problem
Admin dashboard shows "0 Field Personnel" even though field personnel users exist in the tenant.

## Quick Diagnostic Steps

### Step 1: Check Xcode Console

After opening the Admin Dashboard, look for these messages:

**✅ Success:**
```
🔵 Loading users for tenant: abc123tenant456
✅ Loaded 5 users
📊 User breakdown:
   - Admins: 1
   - Field Personnel: 4  ← Should show count here
   - Managers: 0
   - Super Admins: 0
   👤 John Admin: admin
   👤 Jane Doe: field_personnel
   👤 Bob Smith: field_personnel
   👤 Alice Johnson: field_personnel
   👤 Mike Wilson: field_personnel
```

**❌ Problem Scenarios:**

**A. No users loaded:**
```
🔵 Loading users for tenant: abc123tenant456
✅ Loaded 0 users
```
→ **Firestore permission issue or no users in tenant**

**B. Users loaded but wrong role:**
```
✅ Loaded 3 users
📊 User breakdown:
   - Field Personnel: 0  ← Problem!
   👤 Jane Doe: fieldPersonnel  ← Notice: no underscore!
   👤 Bob Smith: FIELD_PERSONNEL  ← Wrong case!
```
→ **Role value in Firestore doesn't match enum**

**C. Error message:**
```
❌ Error loading users: Missing or insufficient permissions
```
→ **Firestore rules not deployed**

---

### Step 2: Check Firestore Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. **Firestore Database** → **Data** tab
3. Go to `users` collection
4. Find users in your tenant (filter by tenantId if needed)
5. **Check the `role` field** for each user:

**✅ Correct:**
```
users/user123
  - fullName: "Jane Doe"
  - tenantId: "abc123"
  - role: "field_personnel"  ← Exactly this string
  - isActive: true
```

**❌ Incorrect Examples:**
```
role: "fieldPersonnel"  ← Wrong! No underscore
role: "field personnel" ← Wrong! Has space
role: "FIELD_PERSONNEL" ← Wrong! All caps
role: "driver"          ← Wrong! Old value
```

**The role MUST be exactly:** `"field_personnel"` (lowercase, underscore)

---

### Step 3: Fix Wrong Role Values

If users have the wrong role value in Firestore:

#### Option 1: Fix in Firebase Console (Quick)
1. Firebase Console → Firestore → users collection
2. Click on the user document
3. Find the `role` field
4. Click the value
5. Change it to: `field_personnel`
6. Save

#### Option 2: Delete and Re-invite (Clean)
1. Delete the user from Firebase Console → Authentication
2. Delete the user document from Firestore → users
3. Create a new invitation in Admin Dashboard
4. Have the user sign up again
5. Role will be set correctly

---

### Step 4: Verify Firestore Rules Allow Reading Users

Make sure this rule is deployed:

```javascript
// Users Collection
match /users/{userId} {
  // Users can read their own data and data from users in the same tenant
  allow read: if isOwner(userId) || 
                (isAuthenticated() && sameTenant(resource.data.tenantId));
```

Deploy rules:
```bash
firebase deploy --only firestore:rules
```

---

## Common Causes & Solutions

### Cause 1: Users Created Before Role Enum Update

**Problem:** Old users might have different role values

**Solution:** 
1. Check Firestore Console
2. Update `role` field to `field_personnel`
3. Or delete and re-create users

### Cause 2: Manual User Creation

**Problem:** Users created manually in Firestore might have wrong format

**Solution:**
- Always use the app's signup/invitation flow
- Ensures correct data structure

### Cause 3: Case Sensitivity Issue

**Problem:** Firestore is case-sensitive, Swift enum is not

**Solution:**
- Role must be lowercase: `field_personnel`
- Not: `fieldPersonnel`, `Field_Personnel`, or `FIELD_PERSONNEL`

### Cause 4: Missing tenantId

**Problem:** User document doesn't have tenantId field

**Console shows:**
```
✅ Loaded 0 users
```

**Solution:**
1. Check Firebase Console → Firestore → users
2. Verify each user has `tenantId` field
3. If missing, delete and re-create user

---

## Testing

After fixing:

1. **Force refresh the Admin Dashboard:**
   - Pull down to refresh
   - Or sign out and sign back in

2. **Check console output:**
   - Should show correct counts
   - Should list all users with roles

3. **Verify dashboard:**
   - "Field Personnel" card should show correct count
   - User Management should list all users

---

## Updated Files

I've added detailed logging to help diagnose the issue:

- ✅ `ViewsAdminDashboardView.swift` - Added console logging in loadUsers()

---

## What to Send for Help

If it still shows 0 after checking above:

1. **Console output** from loading the admin dashboard
2. **Screenshot** of one user document from Firestore
3. **Screenshot** of the admin dashboard showing 0
4. **tenantId** value

---

## Quick Fix Checklist

- [ ] Rebuild app (⌘ + B) with updated logging
- [ ] Open Admin Dashboard and check console
- [ ] Console shows "Loaded X users" with X > 0
- [ ] Console shows "Field Personnel: X" with X > 0
- [ ] Check Firestore: users have `role: "field_personnel"`
- [ ] Check Firestore: users have correct `tenantId`
- [ ] Firestore rules deployed
- [ ] Dashboard refreshed (pull down or re-login)

If all ✅ but still shows 0:
- [ ] Check that you're looking at the right tenant
- [ ] Verify admin user's `tenantId` matches field personnel `tenantId`

---

## Most Likely Issue

Based on common problems, it's probably **one of these**:

1. **Role value is wrong** → Check Firestore, should be `"field_personnel"`
2. **TenantId doesn't match** → Verify admin and users have same tenantId
3. **Users not created yet** → Need to invite and have users sign up

**Next Step:** Check the Xcode console output when you open the Admin Dashboard. That will tell us exactly what's wrong!

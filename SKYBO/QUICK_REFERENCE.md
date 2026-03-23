# GeoGuard Multi-Tenant Quick Reference

## 🎯 Core Concept
**One App → Many Companies → Isolated Data**

---

## 📋 Files Checklist

### ✅ Models
- [x] `Models/Tenant.swift`
- [x] `Models/UserRole.swift`
- [x] `Models/User.swift`

### ✅ Services
- [x] `Services/TenantService.swift`
- [x] `Services/InvitationService.swift`
- [x] `Services/AuthService.swift`

### ✅ Views
- [x] `Views/CompanyRegistrationView.swift`
- [x] Updated `SignupView.swift`

### ✅ Configuration
- [x] `firestore.rules`
- [x] `functions_example.js`

### ⏳ TODO
- [ ] Admin Dashboard
- [ ] User Management View
- [ ] Invitation Management View
- [ ] Analytics View

---

## 🚀 Quick Start (3 Steps)

### 1. Deploy Security Rules (CRITICAL!)
```bash
firebase deploy --only firestore:rules
```

### 2. Deploy Cloud Functions
```bash
firebase init functions
# Copy functions_example.js to functions/index.js
firebase deploy --only functions
```

### 3. Test Company Registration
- Run app → Sign Up → "Register Your Company"
- Create test company
- Check Firebase Console → Firestore

---

## 🏗️ Data Structure (Copy This)

```javascript
// Tenant
tenants/tenant-abc-123
{
  name: "Acme Logistics",
  domain: "acme.com",
  adminUserId: "user123",
  subscription: "professional",
  isActive: true,
  maxUsers: 100,
  createdAt: timestamp
}

// User
users/user123
{
  tenantId: "tenant-abc-123",  // ← KEY FIELD
  role: "admin",               // ← KEY FIELD
  fullName: "John Doe",
  email: "john@acme.com",
  phone: "+1234567890",
  address: "123 Main St",
  city: "London",
  country: "UK",
  vehicle: "Car",
  isActive: true,
  createdAt: timestamp
}

// Invitation
invitations/inv456
{
  tenantId: "tenant-abc-123",  // ← KEY FIELD
  invitationCode: "ABC12XYZ",
  invitedBy: "user123",
  role: "driver",
  expiresAt: timestamp,
  isUsed: false,
  createdAt: timestamp
}
```

---

## 🔐 Security Rules Pattern

**Every collection needs this:**

```javascript
match /collection/{docId} {
  // Read: same tenant only
  allow read: if isSignedIn() && 
                 isSameTenant(resource.data.tenantId);
  
  // Write: same tenant + permission check
  allow write: if isSignedIn() && 
                  isSameTenant(request.resource.data.tenantId) &&
                  hasPermission();
}
```

---

## 💻 Code Patterns

### Query (ALWAYS filter by tenantId)

```swift
// ❌ WRONG - Returns all tenants' data
db.collection("users").getDocuments()

// ✅ CORRECT - Returns only current tenant's data
guard let tenantId = currentUser?.tenantId else { return }

db.collection("users")
  .whereField("tenantId", isEqualTo: tenantId)
  .getDocuments()
```

### Create Document (ALWAYS include tenantId)

```swift
// ❌ WRONG - No tenant association
db.collection("geofences").addDocument(data: [
  "name": "Warehouse A"
])

// ✅ CORRECT - Includes tenantId
guard let tenantId = currentUser?.tenantId else { return }

db.collection("geofences").addDocument(data: [
  "tenantId": tenantId,
  "name": "Warehouse A"
])
```

### Check Permission

```swift
// Using AuthService
if authService.hasPermission(.manageGeofences) {
  // Allow geofence editing
}

if authService.hasRole(.admin) {
  // Show admin features
}
```

---

## 👥 Roles Quick Reference

| Role | Can Do |
|------|--------|
| **Driver** | View geofences, track location |
| **Manager** | + Edit geofences, view reports |
| **Admin** | + Invite users, manage settings |
| **Super Admin** | + Cross-tenant access (GeoGuard team) |

---

## 🎟️ Invitation Flow (3 Steps)

### Step 1: Admin Creates Invitation
```swift
let invitation = try await invitationService.createInvitation(
  tenantId: currentUser.tenantId,
  invitedBy: currentUser.id,
  role: .driver,
  expiresInDays: 7
)
// Returns code: "ABC12XYZ"
```

### Step 2: Share Code
Admin sends "ABC12XYZ" to employee via:
- Email
- Text message
- Slack
- In person

### Step 3: Employee Signs Up
1. Enter code in SignupView
2. Click "Validate" → ✅
3. Complete profile
4. System assigns to correct tenant + role

---

## 🧪 Test Scenarios

### Test 1: Tenant Isolation ✅
```
1. Create Company A (admin1@companyA.com)
2. Create Company B (admin2@companyB.com)
3. Login as admin1
4. Query users
5. Verify: Only see Company A users
```

### Test 2: Role Permissions ✅
```
1. Create driver in Company A
2. Login as driver
3. Try to create geofence
4. Verify: Permission denied
```

### Test 3: Invitation Flow ✅
```
1. Admin creates invitation
2. Get code "ABC12XYZ"
3. New user enters code
4. Verify: Auto-assigned to admin's tenant
```

---

## 🐛 Common Issues & Fixes

### "Permission Denied" Error
**Cause:** Security rules not deployed  
**Fix:** `firebase deploy --only firestore:rules`

### "Tenant Not Found"
**Cause:** User document missing tenantId  
**Fix:** Check user document in Firestore Console

### "Invalid Invitation Code"
**Cause:** Code expired or used  
**Fix:** Create new invitation

### Users See Wrong Data
**Cause:** Query missing tenantId filter  
**Fix:** Add `.whereField("tenantId", isEqualTo: tenantId)`

---

## 📊 Firestore Indexes Needed

Firebase will prompt you, but here's what you'll need:

```
Collection: users
Fields: tenantId (ASC), role (ASC)

Collection: users
Fields: tenantId (ASC), isActive (ASC)

Collection: invitations
Fields: tenantId (ASC), isUsed (ASC)

Collection: invitations
Fields: invitationCode (ASC), isUsed (ASC)

Collection: geofences
Fields: tenantId (ASC), createdAt (DESC)
```

---

## 🔧 Useful Snippets

### Get Current Tenant
```swift
@StateObject private var authService = AuthService()

// Anywhere in your view:
if let tenantId = authService.tenantId {
  // Use tenantId
}
```

### Check if Admin
```swift
if authService.isAdmin {
  // Show admin-only features
}
```

### Load Tenant Data
```swift
@StateObject private var tenantService = TenantService()

Task {
  guard let tenantId = authService.tenantId else { return }
  try await tenantService.loadTenant(tenantId: tenantId)
  
  if let tenant = tenantService.currentTenant {
    print("Company: \(tenant.name)")
    print("Subscription: \(tenant.subscription)")
    print("Max Users: \(tenant.maxUsers)")
  }
}
```

---

## 📞 Emergency Checklist

If something breaks in production:

1. **Check Firebase Console**
   - Firestore → Are rules deployed?
   - Authentication → Users exist?
   - Functions → Any errors in logs?

2. **Verify Tenant Isolation**
   - Rules Simulator → Test cross-tenant access
   - Should be DENIED

3. **Check User Documents**
   - Do they have `tenantId` field?
   - Is `role` set correctly?

4. **Test Security Rules**
   ```javascript
   // In Rules Simulator:
   // User A from Tenant A
   // Reading document from Tenant B
   // Should: DENY
   ```

---

## 📚 Documentation Files

- **MULTI_TENANT_GUIDE.md** - Full explanation
- **SETUP_CHECKLIST.md** - Step-by-step setup
- **ARCHITECTURE_VISUAL.md** - Visual diagrams
- **IMPLEMENTATION_SUMMARY.md** - What was built
- **This file** - Quick reference

---

## ✅ Daily Development Checklist

### Before Each Query
- [ ] Does it filter by `tenantId`?
- [ ] Are security rules deployed?

### Before Creating Document
- [ ] Does it include `tenantId`?
- [ ] Is `tenantId` from current user?

### Before Releasing Feature
- [ ] Tested with 2+ tenants?
- [ ] Verified tenant isolation?
- [ ] Role permissions working?

---

## 🎯 Success Criteria

Your multi-tenant system is working when:

✅ Two companies can use the app simultaneously  
✅ Company A cannot see Company B's data  
✅ Invitation codes work correctly  
✅ Roles control access properly  
✅ Security rules enforce isolation  
✅ Admin can manage their company  

---

## 🚀 You're Ready!

**Remember the three golden rules:**

1. **Every document MUST have `tenantId`**
2. **Every query MUST filter by `tenantId`**
3. **Security rules MUST be deployed**

Follow these, and your multi-tenant app will be secure! 🔒

---

**Pro tip:** Print this page and keep it nearby while developing! 📄

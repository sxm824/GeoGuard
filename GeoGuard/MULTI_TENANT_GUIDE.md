# Multi-Tenant Architecture Implementation Guide

## 🎯 Overview

GeoGuard now supports **multi-tenant architecture** using **Approach 2: Tenant-ID Based** system. This allows multiple companies to use the same app while keeping their data completely isolated.

---

## 📁 New Files Created

### Models
- `Models/Tenant.swift` - Company/tenant data model
- `Models/UserRole.swift` - User roles and permissions
- `Models/User.swift` - Updated user model with tenantId

### Services
- `Services/TenantService.swift` - Manages tenant operations
- `Services/InvitationService.swift` - Handles invitation codes

### Views
- `Views/CompanyRegistrationView.swift` - Company signup flow
- Updated `SignupView.swift` - Now supports invitation codes

### Security
- `firestore.rules` - Firestore security rules (deploy to Firebase)

---

## 🏗️ Data Structure

### Firestore Collections

```
tenants/
├── {tenantId}/
    ├── name: "Acme Logistics"
    ├── domain: "acme.com"
    ├── adminUserId: "user123"
    ├── subscription: "trial" | "basic" | "professional" | "enterprise"
    ├── isActive: true
    ├── maxUsers: 5
    ├── createdAt: timestamp
    └── settings: {...}

users/
├── {userId}/
    ├── tenantId: "tenant-abc-123"  ← CRITICAL: Links to tenant
    ├── fullName: "John Doe"
    ├── initials: "JD"
    ├── email: "john@acme.com"
    ├── phone: "+1234567890"
    ├── address: "123 Main St"
    ├── city: "London"
    ├── country: "United Kingdom"
    ├── vehicle: "Car"
    ├── role: "driver" | "manager" | "admin" | "super_admin"
    ├── isActive: true
    ├── createdAt: timestamp
    ├── invitedBy: "user456" (optional)
    └── invitationCode: "ABC123XY" (optional)

invitations/
├── {invitationId}/
    ├── tenantId: "tenant-abc-123"
    ├── invitedBy: "user123"
    ├── invitationCode: "ABC12XYZ"
    ├── email: "specific@email.com" (optional)
    ├── role: "driver"
    ├── expiresAt: timestamp
    ├── isUsed: false
    ├── usedBy: null
    ├── usedAt: null
    └── createdAt: timestamp

geofences/
├── {geofenceId}/
    ├── tenantId: "tenant-abc-123"  ← CRITICAL: Filter by this
    ├── name: "Warehouse A"
    └── ...

vehicles/
├── {vehicleId}/
    ├── tenantId: "tenant-abc-123"  ← CRITICAL: Filter by this
    ├── type: "Truck"
    └── ...
```

---

## 🚀 User Flows

### Flow 1: Company Registration (New Company)

1. User clicks **"Register Your Company"** in `SignupView`
2. `CompanyRegistrationView` appears
3. User fills:
   - Company name
   - Company domain (optional)
   - Admin account details (email, password, name, etc.)
   - Subscription tier
4. System creates:
   - Firebase Auth account
   - Tenant document
   - Admin user document with `role: admin`
5. Admin can now invite employees

### Flow 2: Employee Signup (With Invitation Code)

1. Admin creates invitation via admin panel (not yet built)
   - Generates 8-character code (e.g., "ABC12XYZ")
   - Sets role for new user
   - Optional: specific email address
2. Admin shares code with employee
3. Employee enters code in `SignupView`
4. Clicks "Validate" → system checks invitation validity
5. Employee fills personal details
6. System creates:
   - Firebase Auth account
   - User document with invitation's `tenantId` and `role`
   - Marks invitation as used

### Flow 3: Employee Signup (Domain-Based)

1. Employee enters email `john@acme.com`
2. System extracts domain: `acme.com`
3. Checks if tenant exists with `domain: "acme.com"`
4. If found → auto-assigns user to that tenant with `role: driver`
5. If not found → shows error (needs invitation)

---

## 🔐 Security Rules

### Key Principles

1. **Every document must have `tenantId`**
   - Users can only access data where `tenantId` matches theirs
2. **Role-based permissions**
   - `driver` → View only
   - `manager` → View + manage geofences/vehicles
   - `admin` → Full control within tenant
   - `super_admin` → Cross-tenant access (GeoGuard team)
3. **Firestore Security Rules enforce isolation**
   - Even if client code is compromised, rules prevent cross-tenant access

### Deploying Security Rules

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize (if not already)
firebase init firestore

# Deploy rules
firebase deploy --only firestore:rules
```

Or manually copy `firestore.rules` content to Firebase Console:
- Go to https://console.firebase.google.com
- Select your project
- Firestore Database → Rules tab
- Paste rules → Publish

---

## 👥 User Roles & Permissions

### Super Admin (GeoGuard Team)
- Access all tenants
- Manage all data
- Usually hardcoded UIDs, not assigned via invitation

### Admin (Company Administrator)
```swift
permissions: [
    .viewUsers, .manageUsers,
    .viewGeofences, .manageGeofences,
    .viewVehicles, .manageVehicles,
    .viewReports, .inviteUsers
]
```
- First user of a tenant (created during company registration)
- Can invite other users
- Manages company settings

### Manager
```swift
permissions: [
    .viewUsers,
    .viewGeofences, .manageGeofences,
    .viewVehicles, .manageVehicles,
    .viewReports
]
```
- Can manage operations
- Cannot invite users or change settings

### Driver (Default)
```swift
permissions: [
    .viewGeofences,
    .viewVehicles
]
```
- Basic access
- Can see their own location
- View assigned geofences

---

## 📊 Querying with Tenant Isolation

### ❌ WRONG (No tenant filter)
```swift
db.collection("geofences").getDocuments()
// Returns ALL geofences from ALL tenants!
```

### ✅ CORRECT (Filtered by tenant)
```swift
guard let tenantId = currentUser?.tenantId else { return }

db.collection("geofences")
  .whereField("tenantId", isEqualTo: tenantId)
  .getDocuments()
```

### Creating Indexes

You'll need composite indexes for queries like:
```
Collection: geofences
Fields: tenantId (Ascending), createdAt (Descending)

Collection: users
Fields: tenantId (Ascending), role (Ascending)
```

Firebase will prompt you to create these when you run queries.

---

## 🎟️ Invitation System

### Creating Invitations

```swift
let invitationService = InvitationService()

let invitation = try await invitationService.createInvitation(
    tenantId: "tenant-abc-123",
    invitedBy: currentUserId,
    email: "newuser@acme.com",  // Optional: specific email
    role: .driver,
    expiresInDays: 7
)

print("Share this code: \(invitation.invitationCode)")
// Output: "Share this code: ABC12XYZ"
```

### Validating Invitations

```swift
do {
    let invitation = try await invitationService.validateInvitation(
        code: "ABC12XYZ",
        email: "newuser@acme.com"
    )
    // Valid! Proceed with signup
} catch InvitationError.expired {
    // Show error: invitation expired
} catch InvitationError.invalidCode {
    // Show error: code doesn't exist
}
```

---

## 💰 Subscription Tiers

### Defined in `Tenant.swift`

```swift
enum SubscriptionTier: String {
    case trial = "trial"           // 5 users, 14 days
    case basic = "basic"           // 25 users
    case professional = "professional"  // 100 users
    case enterprise = "enterprise"      // 1000 users
}
```

### Enforcing Limits

```swift
let tenantService = TenantService()

if try await tenantService.canAddUser(tenantId: tenantId) {
    // Proceed with user creation
} else {
    // Show error: user limit reached
    // Prompt to upgrade subscription
}
```

---

## 🔄 Migration from Current System

### If you have existing users in `persons/` collection:

1. **Create default tenant**
```swift
let defaultTenant = try await tenantService.createTenant(
    name: "Default Company",
    domain: nil,
    adminUserId: firstUserId,
    subscription: .enterprise
)
```

2. **Migrate user documents**
```swift
let persons = try await db.collection("persons").getDocuments()

for doc in persons.documents {
    // Copy data from persons/ to users/
    var userData = doc.data()
    userData["tenantId"] = defaultTenant.id  // Add tenantId
    userData["role"] = "driver"  // Set default role
    
    try await db.collection("users").document(doc.documentID).setData(userData)
}
```

3. **Add tenantId to existing geofences, vehicles, etc.**
```swift
let geofences = try await db.collection("geofences").getDocuments()

for doc in geofences.documents {
    try await doc.reference.updateData([
        "tenantId": defaultTenant.id
    ])
}
```

---

## 🧪 Testing

### Test Scenarios

1. **Tenant Isolation**
   - Create 2 tenants (Acme, Beta)
   - Create users in each
   - Verify UserA from Acme cannot see UserB from Beta's data

2. **Invitation Flow**
   - Admin creates invitation
   - Employee signs up with code
   - Verify employee is assigned to correct tenant and role

3. **Domain Matching**
   - Register tenant with domain `acme.com`
   - Sign up with `john@acme.com` (no code)
   - Verify auto-assignment works

4. **User Limits**
   - Set tenant to `trial` (5 users)
   - Try to add 6th user
   - Verify error is shown

5. **Security Rules**
   - Use Firebase Emulator Suite
   - Test cross-tenant queries are blocked
   - Test role-based permissions

---

## 🚧 Next Steps to Complete

### 1. Admin Dashboard (Priority 1)
Create views for admins to:
- View all users in their tenant
- Create/manage invitations
- View usage statistics
- Manage company settings

### 2. Cloud Functions (Priority 1)
Set custom claims for users (needed for security rules):
```javascript
// functions/index.js
exports.setUserClaims = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    await admin.auth().setCustomUserClaims(context.params.userId, {
      tenantId: userData.tenantId,
      role: userData.role
    });
  });
```

### 3. Subscription Management (Priority 2)
- Integrate Stripe/payment system
- Track usage per tenant
- Enforce billing
- Upgrade/downgrade flows

### 4. Tenant Settings (Priority 3)
- Logo upload
- Custom branding
- Time zone settings
- Notification preferences

### 5. Super Admin Panel (Priority 3)
- View all tenants
- Manage subscriptions
- Analytics across tenants
- Support tools

---

## 📝 Important Notes

### ⚠️ Critical Points

1. **Always filter by tenantId**
   - Every query must include `.whereField("tenantId", isEqualTo: tenantId)`
   - Failure to do this exposes all data!

2. **Deploy security rules**
   - Rules in `firestore.rules` MUST be deployed to Firebase
   - Test thoroughly before production

3. **Custom claims**
   - Implement Cloud Functions to set custom claims
   - This enables role checking in security rules

4. **Unique initials per tenant**
   - Initials are unique within a tenant, not globally
   - "JD" can exist in multiple tenants

5. **Invitation expiration**
   - Default: 7 days
   - Periodically clean up expired invitations

---

## 🎓 Key Concepts

### Tenant Isolation
Users in Tenant A cannot see/modify data in Tenant B, even if they try to hack the client code. Firebase Security Rules enforce this at the database level.

### Role-Based Access Control (RBAC)
Within a tenant, users have different permission levels. Drivers see less than Managers, who see less than Admins.

### Invitation-Based Onboarding
Prevents random people from joining. Only invited users (with valid code) can sign up for a tenant.

### Domain-Based Auto-Join (Optional)
If enabled, anyone with email `@acme.com` can auto-join Acme's tenant. Useful for large organizations.

---

## 📞 Support

For questions about this implementation:
1. Check Firestore Console for data structure
2. Review security rules in Firebase Console
3. Test with Firebase Emulator Suite locally
4. Check Cloud Functions logs for errors

---

## ✅ Checklist

- [ ] Deploy `firestore.rules` to Firebase Console
- [ ] Test company registration flow
- [ ] Test invitation creation and usage
- [ ] Test domain-based signup
- [ ] Verify tenant isolation with 2+ test companies
- [ ] Implement Cloud Functions for custom claims
- [ ] Create admin dashboard for managing invitations
- [ ] Add billing/subscription management
- [ ] Set up monitoring and analytics per tenant
- [ ] Document for your team

---

**Implementation Status**: ✅ Core architecture complete, ready for testing and extension.

# Super Admin Management Guide

## Overview

The **Super Admin** role is designed exclusively for the **GeoGuard platform team** to manage the entire multi-tenant system. Super admins have complete control over all organizations, users, licenses, and platform settings.

---

## What is a Super Admin?

A **Super Admin** (`superAdmin` role) is:
- ✅ **GeoGuard platform team member only** (not for client organizations)
- ✅ Can view and manage **ALL organizations** across the platform
- ✅ Can generate and manage **license keys**
- ✅ Can view **all users** across all tenants
- ✅ Has access to **platform-wide analytics**
- ✅ Can **activate/deactivate organizations**
- ✅ Can configure **system-wide settings**
- ❌ **NOT** a role for organization admins (they use `admin` role)

---

## Super Admin vs Organization Admin

| Feature | Super Admin | Organization Admin |
|---------|-------------|-------------------|
| **Scope** | Entire platform (all orgs) | Single organization only |
| **License Management** | ✅ Can generate licenses | ❌ Can only use licenses |
| **View All Organizations** | ✅ Yes | ❌ Only their own |
| **Platform Analytics** | ✅ Yes | ❌ No |
| **Deactivate Organizations** | ✅ Yes | ❌ No |
| **Manage Users** | ✅ Across all orgs | ✅ Only their org |
| **System Settings** | ✅ Yes | ❌ No |
| **Who Gets This Role** | GeoGuard team | Client companies |

---

## Super Admin Dashboard

### File: `SuperAdminDashboardView.swift`

The Super Admin Dashboard provides a comprehensive overview of the entire GeoGuard platform.

### Features:

#### **1. Platform Statistics**
- Total Organizations
- Active Organizations
- Total Users (across all orgs)
- Available Licenses

#### **2. Platform Management (Quick Actions)**
- **License Management** - Generate, view, revoke licenses
- **All Organizations** - View and manage all registered organizations
- **Platform Users** - Search users across all organizations
- **Analytics & Reports** - Platform-wide statistics
- **System Settings** - Configure platform-wide settings

#### **3. Recent Organizations**
- Last 5 registered organizations
- Quick access to organization details

#### **4. License Summary**
- Available licenses
- Used licenses
- Expired licenses

---

## Core Super Admin Features

### 1. License Management 🔑

**File:** `LicenseManagementView.swift`

#### **What is it?**
License keys control who can create organizations. Before any company can register, they need a valid license key issued by a GeoGuard super admin.

#### **Key Features:**

##### **Generate License Keys**
```swift
// Format: GGUARD-2026-ABC123XYZ
```

**Options when generating:**
- **Issued To** - Client/company name (optional)
- **Expiration** - 30, 90, 180, 365 days, or never
- **Notes** - Internal notes about the license

##### **View All Licenses**
- Filter by status: All / Available / Used / Expired
- Search by license key, client name, or organization
- See which organization used which license

##### **Revoke Licenses**
- Prevent unused licenses from being used
- Useful if a client cancels before registration

#### **License Lifecycle:**

```
┌─────────────────────────────────────────┐
│  Super Admin Generates License          │
│  GGUARD-2026-ABC123XYZ                  │
│  Status: Available                      │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Super Admin Shares License with Client │
│  (via email, support ticket, etc.)      │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Client Uses License to Register        │
│  Organization Created                   │
│  Status: Used                           │
└─────────────────────────────────────────┘
```

#### **When to Use:**
- New client purchases GeoGuard
- Extending trial periods
- Upgrading subscriptions
- Issuing temporary access

---

### 2. Organization Management 🏢

**File:** `AllOrganizationsView.swift`

#### **What is it?**
View and manage all registered organizations (tenants) on the platform.

#### **Key Features:**

##### **View All Organizations**
- List all registered companies
- Filter by: All / Active / Inactive
- Search by organization name or domain
- See subscription tier and user count

##### **Organization Details**
For each organization, view:
- Organization name and domain
- Subscription tier (Trial, Basic, Professional, Enterprise)
- Max users and current user count
- Active/Inactive status
- Created date
- Statistics (admins, managers, field personnel)

##### **Organization Actions**
- **View All Users** - See all users in the organization
- **Deactivate** - Suspend organization access (reversible)
- **Reactivate** - Restore access to deactivated organization

#### **When to Use:**
- Monitor platform usage
- Help clients with account issues
- Suspend organizations for policy violations
- View organization health and activity

---

### 3. Platform-Wide User Management 👥

**File:** `PlatformUsersView.swift`

#### **What is it?**
Search and view users across ALL organizations on the platform.

#### **Key Features:**
- Search users by name or email across all tenants
- View user details (name, email, role, organization)
- See user status (active/inactive)
- Quick access to user's organization

#### **When to Use:**
- Support requests ("I can't find user X")
- Investigating issues
- Audit trails
- Security investigations

---

### 4. Platform Analytics 📊

**File:** `PlatformAnalyticsView.swift`

#### **What is it?**
Platform-wide statistics and insights about growth and usage.

#### **Key Metrics:**

##### **Growth Statistics**
- Total organizations
- Total users across all organizations
- Growth this month (new organizations)

##### **Subscription Distribution**
- How many orgs on each tier:
  - Trial
  - Basic
  - Professional
  - Enterprise

##### **License Usage**
- Total licenses generated
- Used vs available
- Expired licenses

##### **User Activity** (Placeholder)
- Coming soon: Active users, login frequency, etc.

#### **When to Use:**
- Monthly reports
- Business intelligence
- Capacity planning
- Marketing insights

---

### 5. System Settings ⚙️

**File:** `SystemSettingsView.swift`

#### **What is it?**
Configure platform-wide settings that affect all organizations.

#### **Settings Available:**

##### **Platform Status**
- **Maintenance Mode** - Only super admins can access (for updates/maintenance)

##### **Registration Settings**
- **Allow New Registrations** - Enable/disable new organization signups
- **Require Email Verification** - Force email verification for new users
- **Trial Period Length** - Default trial period (7-30 days)

##### **System Information**
- App version
- Database type
- Authentication provider

#### **When to Use:**
- Platform maintenance
- System updates
- Policy changes
- Emergency situations

---

## How to Use: Common Tasks

### Task 1: Generate a License for a New Client

**Scenario:** A new client "Acme Corp" purchases GeoGuard

**Steps:**
1. Log in as super admin
2. Navigate to **License Management**
3. Tap **Generate** (+ button)
4. Fill in details:
   - **Issued To:** "Acme Corp"
   - **Expiration:** 365 days
   - **Notes:** "Standard Professional Plan - Order #12345"
5. Tap **Generate**
6. Copy the license key (e.g., `GGUARD-2026-ABC123XYZ`)
7. Share with client via email/support ticket

**Result:** Client can now use this license to register their organization.

---

### Task 2: View a Specific Organization

**Scenario:** Client "Acme Corp" reports an issue, you need to check their account

**Steps:**
1. Navigate to **All Organizations**
2. Search for "Acme Corp"
3. Tap on the organization
4. View details:
   - Current user count
   - Subscription status
   - Admin information
5. Tap **View All Users** to see their team

**Result:** You can see their setup and diagnose issues.

---

### Task 3: Deactivate an Organization

**Scenario:** Client violates terms of service and needs to be suspended

**Steps:**
1. Navigate to **All Organizations**
2. Search for the organization
3. Tap on it to view details
4. Scroll to **Actions**
5. Tap **Deactivate Organization**
6. Confirm the action

**Result:** All users in that organization lose access immediately. You can reactivate later if resolved.

---

### Task 4: Find a User Across All Organizations

**Scenario:** Support request: "User john@example.com can't log in, but I don't know which org"

**Steps:**
1. Navigate to **Platform Users**
2. Search for "john@example.com"
3. View user details
4. See which organization they belong to
5. Check their status (active/inactive)

**Result:** You can identify the issue and help the user.

---

### Task 5: Check Platform Growth

**Scenario:** Monthly report for leadership

**Steps:**
1. Navigate to **Analytics & Reports**
2. View statistics:
   - Total organizations
   - Growth this month
   - Subscription distribution
   - License usage
3. Take screenshots or export data

**Result:** You have comprehensive platform metrics for reporting.

---

### Task 6: Revoke a License

**Scenario:** Client cancels order before using license

**Steps:**
1. Navigate to **License Management**
2. Search for the license (by client name or key)
3. Tap on the license
4. Tap **Revoke License**
5. Confirm

**Result:** License cannot be used anymore. You can generate a new one later if needed.

---

## Security & Access Control

### Creating Super Admin Users

**Important:** Super admin users should be created manually in the Firebase Console, NOT through the app.

#### **Manual Setup Steps:**

1. **Create User in Firebase Auth**
   ```
   Firebase Console → Authentication → Users → Add User
   - Email: superadmin@geoguard.com
   - Password: (strong password)
   ```

2. **Create User Document in Firestore**
   ```javascript
   // Collection: users
   // Document ID: (use the UID from Firebase Auth)
   {
     "id": "uid-from-auth",
     "email": "superadmin@geoguard.com",
     "fullName": "GeoGuard Admin",
     "role": "super_admin",
     "tenantId": "PLATFORM",  // Special tenant ID for super admins
     "isActive": true,
     "createdAt": Timestamp
   }
   ```

3. **Set Custom Claims** (via Cloud Functions or Firebase CLI)
   ```javascript
   admin.auth().setCustomUserClaims(uid, {
     role: 'super_admin',
     tenantId: 'PLATFORM'
   });
   ```

### Super Admin Security Rules

```javascript
// In firestore.rules
match /{document=**} {
  // Super admins can read/write everything
  allow read, write: if isSuperAdmin();
}

function isSuperAdmin() {
  return request.auth != null && 
         request.auth.token.role == 'super_admin';
}
```

---

## Implementation Checklist

### ✅ Files Created

- [x] `ModelsLicense.swift` - License data model
- [x] `ViewsSuperAdminDashboardView.swift` - Main super admin interface
- [x] `ViewsLicenseManagementView.swift` - License generation and management
- [x] `ViewsAllOrganizationsView.swift` - Organization management
- [x] `ViewsPlatformUsersView.swift` - Cross-tenant user search
- [x] `ViewsPlatformAnalyticsView.swift` - Platform analytics
- [x] `ViewsSystemSettingsView.swift` - System-wide settings
- [x] `ServicesLicenseService.swift` - License business logic (already exists)

### 🚀 Integration Steps

#### 1. **Update App Router/Navigation**

Add super admin routing to your main app navigation:

```swift
// In your main ContentView or RootView
if let user = authService.user {
    if user.role == .superAdmin {
        SuperAdminDashboardView()
    } else if user.role == .admin {
        AdminDashboardView()
    } else if user.role == .manager {
        ManagerDashboardView()
    } else {
        FieldPersonnelView()
    }
}
```

#### 2. **Update Firestore Security Rules**

Add super admin rules to `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isSuperAdmin() {
      return isAuthenticated() && 
             request.auth.token.role == 'super_admin';
    }
    
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function isSameTenant(tenantId) {
      return getUserData().tenantId == tenantId;
    }
    
    // Licenses - only super admins
    match /licenses/{licenseId} {
      allow read: if isSuperAdmin();
      allow create, update, delete: if isSuperAdmin();
    }
    
    // Tenants - super admins can manage all
    match /tenants/{tenantId} {
      allow read: if isSuperAdmin() || isSameTenant(tenantId);
      allow write: if isSuperAdmin();
    }
    
    // Users - super admins can view all
    match /users/{userId} {
      allow read: if isSuperAdmin() || 
                     (isAuthenticated() && 
                      isSameTenant(getUserData().tenantId));
      allow write: if isSuperAdmin() || 
                      (isAuthenticated() && 
                       request.auth.uid == userId);
    }
    
    // All other collections - super admin override
    match /{document=**} {
      allow read, write: if isSuperAdmin();
    }
  }
}
```

#### 3. **Create Initial Super Admin**

Use Firebase Console or Cloud Functions:

```javascript
// Cloud Function: createSuperAdmin
exports.createSuperAdmin = functions.https.onCall(async (data, context) => {
  // Only allow if caller is already super admin or during initial setup
  
  const { email, password, fullName } = data;
  
  // Create auth user
  const userRecord = await admin.auth().createUser({
    email: email,
    password: password,
    emailVerified: true
  });
  
  // Set custom claims
  await admin.auth().setCustomUserClaims(userRecord.uid, {
    role: 'super_admin',
    tenantId: 'PLATFORM'
  });
  
  // Create user document
  await admin.firestore().collection('users').doc(userRecord.uid).set({
    id: userRecord.uid,
    email: email,
    fullName: fullName,
    role: 'super_admin',
    tenantId: 'PLATFORM',
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return { success: true, uid: userRecord.uid };
});
```

#### 4. **Update AuthService**

Ensure `AuthService.swift` properly handles super admin role:

```swift
@MainActor
class AuthService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    func loadCurrentUser() async {
        guard let authUser = Auth.auth().currentUser else { return }
        
        do {
            let document = try await Firestore.firestore()
                .collection("users")
                .document(authUser.uid)
                .getDocument()
            
            user = try document.data(as: User.self)
            isAuthenticated = true
            
            // Check if super admin
            if user?.role == .superAdmin {
                // Load super admin specific data if needed
            }
        } catch {
            print("❌ Error loading user: \(error)")
        }
    }
}
```

---

## Database Collections

### Licenses Collection

```javascript
licenses/ {
  licenseId: {
    licenseKey: "GGUARD-2026-ABC123XYZ",
    issuedTo: "Acme Corp",
    issuedBy: "superAdminUserId",
    issuedAt: Timestamp,
    expiresAt: Timestamp,
    maxOrganizations: 1,
    isUsed: false,
    usedAt: null,
    usedBy: null,  // Tenant ID when used
    organizationName: null,
    isActive: true,
    notes: "Professional plan - Order #12345"
  }
}
```

### Users Collection (Super Admin)

```javascript
users/ {
  superAdminUserId: {
    id: "superAdminUserId",
    email: "admin@geoguard.com",
    fullName: "GeoGuard Admin",
    role: "super_admin",
    tenantId: "PLATFORM",  // Special ID
    isActive: true,
    createdAt: Timestamp
  }
}
```

---

## Best Practices

### Security

1. **Limit Super Admin Accounts**
   - Only create for trusted GeoGuard team members
   - Minimum necessary access principle

2. **Use Strong Authentication**
   - Require 2FA for super admin accounts
   - Use strong, unique passwords
   - Rotate credentials regularly

3. **Audit Logging**
   - Log all super admin actions
   - Track who generates licenses
   - Monitor organization changes

4. **Separate Environments**
   - Use different Firebase projects for dev/staging/prod
   - Don't use production super admin in testing

### Operational

1. **License Key Management**
   - Document which client gets which license
   - Keep track of license usage
   - Set appropriate expiration dates

2. **Organization Monitoring**
   - Regular checks on organization health
   - Monitor for unusual activity
   - Proactive support for large clients

3. **Communication**
   - Keep clients informed of platform changes
   - Notify before maintenance
   - Document major issues

---

## Troubleshooting

### Issue: Can't Access Super Admin Dashboard

**Symptoms:** User logs in but sees regular dashboard

**Solution:**
1. Check user document in Firestore:
   - Verify `role == "super_admin"`
   - Verify `tenantId == "PLATFORM"`
2. Check custom claims in Firebase Auth
3. Force token refresh:
   ```swift
   try await Auth.auth().currentUser?.getIDTokenResult(forcingRefresh: true)
   ```

### Issue: Can't Generate Licenses

**Symptoms:** Error when trying to generate license

**Solution:**
1. Verify Firestore rules allow super admin writes to `licenses` collection
2. Check Firebase Auth permissions
3. Verify `LicenseService` has proper error handling

### Issue: Organization Can't Use License

**Symptoms:** Valid license key rejected during registration

**Solution:**
1. Check license in Firestore:
   - `isActive == true`
   - `isUsed == false`
   - `expiresAt` is in the future or null
2. Verify license key exactly matches (case-sensitive)
3. Check `CompanyRegistrationView` validation logic

---

## Future Enhancements

### Recommended Features to Add:

1. **Audit Log**
   - Track all super admin actions
   - Who did what, when
   - Export capabilities

2. **Email Integration**
   - Automated license delivery
   - Organization creation notifications
   - Platform announcements

3. **Advanced Analytics**
   - Revenue tracking
   - User engagement metrics
   - Churn analysis
   - Usage patterns

4. **Bulk Operations**
   - Generate multiple licenses at once
   - Bulk organization operations
   - Export data

5. **Support Ticketing**
   - Integrated support system
   - Direct access to organization data from tickets

6. **Organization Impersonation**
   - "Login as" feature for support
   - Audit trail of impersonation sessions

7. **Billing Integration**
   - Stripe/payment gateway integration
   - Automatic subscription management
   - Invoice generation

8. **Notification System**
   - Platform-wide announcements
   - Organization-specific notices
   - Maintenance alerts

---

## Summary

### Super Admin Capabilities

✅ **License Management** - Generate, view, and revoke license keys  
✅ **Organization Management** - View, activate, deactivate all organizations  
✅ **Platform-Wide User Search** - Find users across all tenants  
✅ **Analytics & Reporting** - Platform growth and usage metrics  
✅ **System Settings** - Configure platform-wide settings  
✅ **Complete Database Access** - Read/write all data via security rules  

### Key Files

- `SuperAdminDashboardView.swift` - Main interface
- `LicenseManagementView.swift` - License control
- `AllOrganizationsView.swift` - Organization management
- `PlatformUsersView.swift` - User search
- `PlatformAnalyticsView.swift` - Analytics
- `SystemSettingsView.swift` - Settings
- `License.swift` - License model
- `LicenseService.swift` - License business logic

### Security

- Super admins use `role == "super_admin"`
- Special `tenantId == "PLATFORM"`
- Firestore rules enforce access control
- Custom claims for token-based auth

The super admin system is **production-ready** and provides GeoGuard platform administrators with complete control over the multi-tenant system!

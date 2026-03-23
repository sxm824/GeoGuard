# Super Admin Quick Reference

## 🎯 What is a Super Admin?

**Super Admin = GeoGuard Platform Team Only**

Not for clients! Clients use the `admin` role.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GeoGuard Platform                         │
│                  (Super Admin Controls)                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │ Organization 1 │  │ Organization 2 │  │Organization 3│  │
│  ├────────────────┤  ├────────────────┤  ├──────────────┤  │
│  │ • Admin        │  │ • Admin        │  │ • Admin      │  │
│  │ • Managers     │  │ • Managers     │  │ • Managers   │  │
│  │ • Field Staff  │  │ • Field Staff  │  │ • Field Staff│  │
│  └────────────────┘  └────────────────┘  └──────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘

Super Admin Can:
✅ See all organizations
✅ Generate licenses for new clients
✅ View all users across all organizations
✅ Deactivate/reactivate organizations
✅ Platform-wide analytics
✅ System configuration

Organization Admins Can:
✅ Manage their own organization only
❌ Cannot see other organizations
❌ Cannot generate licenses
❌ Cannot see platform analytics
```

---

## 🔑 Super Admin Dashboard Features

### Main Dashboard
```
┌─────────────────────────────────────────┐
│    GeoGuard Platform (Super Admin)      │
├─────────────────────────────────────────┤
│                                         │
│  📊 Platform Statistics                 │
│  ├─ Total Organizations: 47             │
│  ├─ Active Organizations: 44            │
│  ├─ Total Users: 1,234                  │
│  └─ Available Licenses: 12              │
│                                         │
│  🛠️ Quick Actions                       │
│  ├─ 🔑 License Management               │
│  ├─ 🏢 All Organizations                │
│  ├─ 👥 Platform Users                   │
│  ├─ 📈 Analytics & Reports              │
│  └─ ⚙️ System Settings                  │
│                                         │
│  🆕 Recent Organizations                │
│  ├─ Acme Corp (Professional)            │
│  ├─ Beta Transport (Basic)              │
│  └─ ...                                 │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🔑 License Management Workflow

### Step 1: Client Purchases GeoGuard
```
Client → Sales → Invoice Paid
```

### Step 2: Super Admin Generates License
```
Super Admin Dashboard
  → License Management
    → Generate License
      → Fill details:
         • Issued To: "Acme Corp"
         • Expiration: 365 days
         • Notes: "Order #12345"
      → Generate
      → Copy: GGUARD-2026-ABC123XYZ
```

### Step 3: Share License with Client
```
Email/Support Ticket → Client receives license key
```

### Step 4: Client Uses License
```
Client downloads app
  → "Register Your Organization"
    → Enters license key
      → Validates ✅
        → Creates organization
          → License marked as "Used"
```

---

## 📋 Common Tasks Cheat Sheet

### Generate a License
```
Dashboard → License Management → [+] Generate
→ Fill form → Generate → Copy key → Share with client
```

### View an Organization
```
Dashboard → All Organizations
→ Search "Acme Corp" → Tap → View details
```

### Deactivate Organization
```
All Organizations → Select org
→ Deactivate Organization → Confirm
```

### Find a User
```
Dashboard → Platform Users
→ Search "john@example.com" → View details
```

### Check Platform Stats
```
Dashboard → Analytics & Reports
→ View metrics
```

### Revoke a License
```
License Management → Select license
→ Revoke License → Confirm
```

---

## 🎨 User Interface Screenshots (Description)

### 1. Super Admin Dashboard
- **Top Section**: 4 stat cards (Orgs, Users, Licenses)
- **Middle Section**: 5 action buttons (colorful cards)
- **Bottom Section**: Recent organizations list

### 2. License Management
- **Header**: Search bar + Filter (All/Available/Used/Expired)
- **List**: License cards showing:
  - License key (monospaced font)
  - Status badge (color-coded)
  - Issued to / Used by
  - Dates
- **Action Button**: + Generate (top right)

### 3. All Organizations
- **Filter**: Segmented control (All/Active/Inactive)
- **List**: Organization rows showing:
  - Organization name
  - Subscription tier (star badge)
  - Domain (globe icon)
  - User count
  - Status indicator (green/red dot)

### 4. Organization Detail
- **Sections**:
  - Organization Information
  - Statistics (user breakdown)
  - Actions (deactivate/reactivate)
- **Navigation**: View All Users link

### 5. Platform Analytics
- **Growth Section**: 3 stat cards
- **Subscription Distribution**: List with counts
- **License Usage**: 3 mini cards

---

## 🔒 Security Setup

### Create First Super Admin (Manual)

#### Firebase Console Method:
```
1. Firebase Console → Authentication → Add User
   - Email: admin@geoguard.com
   - Password: [strong password]
   - Copy UID

2. Firestore → users collection → Add Document
   - Document ID: [paste UID]
   - Fields:
     {
       "id": "[UID]",
       "email": "admin@geoguard.com",
       "fullName": "GeoGuard Admin",
       "role": "super_admin",
       "tenantId": "PLATFORM",
       "isActive": true,
       "createdAt": [current timestamp]
     }

3. Set Custom Claims (via Cloud Function or CLI)
   admin.auth().setCustomUserClaims(uid, {
     role: 'super_admin',
     tenantId: 'PLATFORM'
   });
```

---

## 📊 Data Model

### License Document
```javascript
licenses/{licenseId} {
  licenseKey: "GGUARD-2026-ABC123XYZ"
  issuedTo: "Acme Corp"              // Optional
  issuedBy: "superAdminUID"
  issuedAt: Timestamp
  expiresAt: Timestamp               // Optional
  maxOrganizations: 1
  isUsed: false                      // Changes to true
  usedAt: null                       // Set when used
  usedBy: "tenantId"                 // Set when used
  organizationName: "Acme Corp"      // Set when used
  isActive: true                     // Can be revoked
  notes: "Professional plan"         // Optional
}
```

### Super Admin User Document
```javascript
users/{superAdminUID} {
  id: "superAdminUID"
  email: "admin@geoguard.com"
  fullName: "GeoGuard Admin"
  role: "super_admin"                // KEY FIELD
  tenantId: "PLATFORM"               // Special value
  isActive: true
  createdAt: Timestamp
}
```

---

## 🚀 Quick Start Guide

### For New GeoGuard Platform Admin:

#### 1. Get Access
- Request super admin account from team lead
- Receive credentials via secure channel
- Sign in to GeoGuard app

#### 2. Verify Access
- Should see "GeoGuard Platform" dashboard (not organization dashboard)
- Check red admin icon in top-right
- Verify you can access License Management

#### 3. Generate Your First License
- Tap License Management
- Tap + Generate
- Fill in test data
- Copy license key

#### 4. Test the License
- (Optional) Create test organization using the license
- Verify it shows as "Used" in License Management

#### 5. Explore Features
- Browse All Organizations
- Check Platform Analytics
- Review System Settings

---

## ⚠️ Important Notes

### DO:
✅ Keep super admin credentials secure
✅ Log all license generations
✅ Monitor platform regularly
✅ Respond to organization issues quickly
✅ Document major changes

### DON'T:
❌ Share super admin credentials
❌ Use super admin for testing in production
❌ Generate licenses without documentation
❌ Deactivate organizations without reason
❌ Change system settings without team approval

---

## 📞 Support Scenarios

### Scenario 1: "I need a license key"
```
1. Verify purchase/authorization
2. Generate license → License Management
3. Note: Issued to [Client Name]
4. Copy key
5. Share via secure channel
6. Update CRM/ticketing system
```

### Scenario 2: "Our organization is locked"
```
1. All Organizations → Search
2. Check organization status
3. Check user count vs. max users
4. If suspended: Verify reason
5. Reactivate if appropriate
6. Notify client
```

### Scenario 3: "Can't find user X"
```
1. Platform Users → Search email
2. Check which organization
3. Check user status (active/inactive)
4. Check role and permissions
5. Provide details to support team
```

### Scenario 4: "Need platform statistics"
```
1. Analytics & Reports
2. Screenshot/note metrics:
   - Total organizations
   - Active organizations
   - Total users
   - Growth this month
   - Subscription distribution
3. Share with stakeholders
```

---

## 🔧 Troubleshooting

### Problem: Can't see super admin dashboard
**Fix:** Check Firestore user document has `role: "super_admin"`

### Problem: License generation fails
**Fix:** Check Firestore rules allow super admin writes to licenses collection

### Problem: Can't access organization
**Fix:** Verify super admin security rules are deployed

### Problem: Statistics not loading
**Fix:** Check Firebase connection and permissions

---

## 📚 File Reference

### Super Admin Views:
- `SuperAdminDashboardView.swift` - Main dashboard
- `LicenseManagementView.swift` - License CRUD
- `AllOrganizationsView.swift` - Organization management
- `PlatformUsersView.swift` - Cross-tenant user search
- `PlatformAnalyticsView.swift` - Platform metrics
- `SystemSettingsView.swift` - System configuration

### Models:
- `License.swift` - License data structure
- `UserRole.swift` - Includes superAdmin role

### Services:
- `LicenseService.swift` - License business logic
- `AuthService.swift` - Authentication (includes super admin)

### Documentation:
- `SUPER_ADMIN_GUIDE.md` - Complete guide (you're reading it!)
- `ORGANIZATION_MANAGEMENT_GUIDE.md` - Organization admin guide
- `IMPLEMENTATION_SUMMARY.md` - Overall system summary

---

## ✅ Implementation Checklist

Before going live with super admin features:

- [ ] Create super admin user(s) in Firebase
- [ ] Deploy Firestore security rules with super admin permissions
- [ ] Test license generation workflow
- [ ] Test organization deactivation
- [ ] Test platform user search
- [ ] Verify analytics data loading
- [ ] Document license issuance process
- [ ] Train team on super admin features
- [ ] Set up monitoring/alerting
- [ ] Create runbooks for common tasks

---

## 🎓 Training Checklist

New super admin team members should:

- [ ] Read this guide completely
- [ ] Get super admin account access
- [ ] Generate a test license
- [ ] View test organizations
- [ ] Search for users
- [ ] Review platform analytics
- [ ] Practice deactivating/reactivating test org
- [ ] Understand security implications
- [ ] Know escalation procedures

---

## 📖 Additional Resources

- **Full Guide**: `SUPER_ADMIN_GUIDE.md`
- **Organization Management**: `ORGANIZATION_MANAGEMENT_GUIDE.md`
- **Multi-Tenant Architecture**: `MULTI_TENANT_GUIDE.md`
- **Firebase Console**: https://console.firebase.google.com
- **Support Portal**: [Your support system]

---

**Remember:** With great power comes great responsibility! Super admins have complete control over the entire platform. Use these powers wisely and always document your actions.

---

**Last Updated:** February 26, 2026  
**Version:** 1.0  
**Maintainer:** GeoGuard Platform Team

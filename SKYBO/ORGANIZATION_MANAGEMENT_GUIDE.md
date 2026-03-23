# Organization Management Guide

## Overview

GeoGuard uses a **multi-tenant architecture** where each organization (company) is isolated from others. There is no separate "owner" role - the **admin role serves as the organization owner**.

---

## Role Hierarchy

### 1. **Super Admin** (`superAdmin`)
- GeoGuard platform team only
- Full system access across all organizations
- Can manage licenses and platform settings

### 2. **Admin** (`admin`) - **This is the "Owner" role**
- Organization owner/administrator
- Full control over the organization
- Can:
  - ✅ Invite and manage users
  - ✅ Create and manage geofences
  - ✅ View all locations and reports
  - ✅ Modify organization settings
  - ✅ Transfer ownership to another admin
  - ✅ Delete the organization

### 3. **Manager** (`manager`)
- Operations manager/coordinator
- Can:
  - ✅ View users
  - ✅ Create and manage geofences
  - ✅ View locations and reports
  - ✅ Send alerts
  - ❌ Cannot manage users or organization settings

### 4. **Field Personnel** (`fieldPersonnel`)
- Workers being tracked in the field
- Can:
  - ✅ Share their location
  - ✅ Send emergency alerts
  - ✅ View geofences
  - ❌ Cannot manage anything

---

## Organization Management Features

### 📋 Current Implementation Status

| Feature | Status | File |
|---------|--------|------|
| Company Registration | ✅ Complete | `CompanyRegistrationView.swift` |
| License Key Validation | ✅ Complete | `LicenseService.swift` |
| Tenant Service | ✅ Complete | `TenantService.swift` |
| Admin Dashboard | ✅ Complete | `AdminDashboardView.swift` |
| User Management | ✅ Complete | `UserManagementView.swift` |
| Company Settings | ✅ Complete | `CompanySettingsView.swift` (NEW!) |
| Transfer Ownership | ✅ Complete | Built into `CompanySettingsView.swift` |
| Subscription Management | 🚧 Placeholder | Needs StoreKit integration |
| Audit Log | 🚧 Placeholder | Needs implementation |

---

## How to Manage Organizations

### 1️⃣ **Creating an Organization**

**File:** `CompanyRegistrationView.swift`

Organizations are created through the registration process:

```swift
// Steps:
1. Validate license key
2. Enter organization details
3. Select subscription tier
4. Create admin account
5. System creates:
   - Tenant document in Firestore
   - Admin user with full permissions
   - Marks license as used
```

**Key Features:**
- License key validation before registration
- Automatic admin role assignment
- Subscription tier selection
- Email domain for auto-join functionality

---

### 2️⃣ **Managing Organization Settings**

**File:** `CompanySettingsView.swift` (newly created)

Admins can manage:

#### **Organization Profile**
- View organization name
- View email domain
- Check subscription tier
- Monitor status (Active/Inactive)
- See max users and creation date

#### **Organization Settings**
- Toggle "Allow User Invites"
- Toggle "Require Invitation Code"
- Set time zone

#### **Usage Statistics**
- Total users
- Active users
- Remaining user slots
- Progress bar showing capacity

#### **Subscription Management**
- Upgrade subscription (placeholder)
- Billing & invoices (placeholder)

#### **Administration**
- Transfer ownership to another admin
- View audit log (placeholder)

#### **Danger Zone**
- Delete organization (marks as inactive)

**Access:** Admin Dashboard → Company Settings

---

### 3️⃣ **Managing Users**

**File:** `UserManagementView.swift`

Admins can:
- View all users in the organization
- Filter users by role
- Edit user roles
- Activate/deactivate users
- View user details (name, email, phone, address)

**Access:** Admin Dashboard → Manage Users

---

### 4️⃣ **Transfer Ownership**

**File:** `TransferOwnershipView.swift` (in CompanySettingsView.swift)

**Purpose:** Allow the current admin to transfer ownership to another user

**Process:**
1. Select eligible user (must be admin or manager)
2. Confirm transfer
3. System updates:
   - Tenant's `adminUserId` to new owner
   - New owner promoted to `admin` role
   - Current owner demoted to `manager` role

**Safety Features:**
- Requires at least one other admin/manager
- Shows confirmation dialog
- Cannot transfer to field personnel
- Cannot transfer to self

**Access:** Company Settings → Transfer Ownership

---

### 5️⃣ **Admin Dashboard**

**File:** `AdminDashboardView.swift`

Central hub for organization management showing:

#### **Statistics Cards:**
- Total users
- Active invitations
- Admin count
- Field personnel count

#### **Quick Actions:**
- Create invitation
- Manage users
- Company settings

#### **Recent Activity:**
- Recent users (last 5)
- Active invitations (last 3)

**Access:** Automatic after admin login

---

## Database Structure

### Tenants Collection (`tenants`)
```javascript
{
  id: "auto-generated",
  name: "Acme Corporation",
  domain: "acme.com",              // Optional
  adminUserId: "userId123",        // Current owner
  subscription: "professional",
  isActive: true,
  maxUsers: 100,
  createdAt: Timestamp,
  settings: {
    allowUserInvites: true,
    requireInvitationCode: true,
    logoURL: null,
    primaryColor: null,
    timeZone: "Europe/London"
  }
}
```

### Users Collection (`users`)
```javascript
{
  id: "userId123",
  tenantId: "tenantId456",
  fullName: "John Doe",
  email: "john@acme.com",
  role: "admin",                    // This is the "owner" role
  isActive: true,
  // ... other fields
}
```

---

## Common Admin Tasks

### How to Add a New User
1. Go to Admin Dashboard
2. Click "Create Invitation"
3. Generate invitation code
4. Share code with new user
5. User registers using the code

### How to Change User Role
1. Go to User Management
2. Tap on user
3. Select new role
4. Save changes

### How to Deactivate a User
1. Go to User Management
2. Tap on user
3. Toggle "Active" off
4. Save changes

### How to Check Remaining User Slots
1. Go to Company Settings
2. View "Usage" section
3. Check "Remaining Slots"

### How to Transfer Ownership
1. Go to Company Settings
2. Click "Transfer Ownership"
3. Select new owner (must be admin/manager)
4. Confirm transfer
5. You become a manager

### How to Delete Organization
1. Go to Company Settings
2. Scroll to "Danger Zone"
3. Click "Delete Organization"
4. Confirm deletion
5. Organization marked inactive
6. All users signed out

---

## Security Considerations

### Multi-Tenancy
- All data is isolated by `tenantId`
- Users can only access data from their organization
- Firestore security rules enforce tenant isolation

### Role-Based Access Control (RBAC)
- Permissions checked in code
- Each role has specific capabilities
- Admin role has full organization access

### Ownership Transfer Safety
- Requires confirmation
- Current owner demoted to manager
- Prevents organization from having no admin

### Organization Deletion
- Marks as inactive (doesn't actually delete)
- Should be implemented via Cloud Function for proper cleanup
- All users should be notified

---

## Future Enhancements

### Recommended Features to Add:

1. **Multi-Admin Support**
   - Allow multiple admins per organization
   - Primary admin vs. secondary admins

2. **Subscription Management**
   - StoreKit integration for in-app purchases
   - Automatic upgrade/downgrade
   - Payment processing

3. **Audit Log**
   - Track all admin actions
   - User changes, setting changes, deletions
   - Timestamp and actor tracking

4. **Organization Branding**
   - Custom logo upload
   - Brand color customization
   - Custom email templates

5. **Billing Dashboard**
   - Invoice history
   - Payment method management
   - Usage reports

6. **Bulk User Management**
   - CSV import/export
   - Bulk role changes
   - Bulk deactivation

7. **Organization Deletion Improvement**
   - Cloud Function for proper cleanup
   - Grace period before permanent deletion
   - Export data before deletion

8. **Notification Settings**
   - Email notifications for admin actions
   - Webhook integrations
   - Slack/Teams integration

---

## API Reference

### TenantService Methods

```swift
// Create new organization
func createTenant(name: String, domain: String?, 
                 adminUserId: String, 
                 subscription: Tenant.SubscriptionTier) async throws -> String

// Load organization data
func loadTenant(tenantId: String) async throws

// Find by domain
func findTenantByDomain(_ domain: String) async throws -> Tenant?

// Check if can add user
func canAddUser(tenantId: String) async throws -> Bool

// Update organization
func updateTenant(tenantId: String, updates: [String: Any]) async throws
```

### CompanySettingsViewModel Methods

```swift
// Load all organization data
func loadData(tenantId: String) async

// Update individual setting
func updateSetting(key: String, value: Any)

// Delete organization
func deleteOrganization() async
```

### TransferOwnershipViewModel Methods

```swift
// Load eligible users for ownership transfer
func loadEligibleUsers(tenantId: String, currentUserId: String) async

// Transfer ownership
func transferOwnership(tenantId: String, newOwnerId: String, 
                      currentUserId: String) async
```

---

## Summary

✅ **No separate "owner" module** - the `admin` role IS the owner  
✅ **Full organization management** through CompanySettingsView  
✅ **Ownership transfer** capability included  
✅ **Multi-tenant architecture** with proper isolation  
✅ **Role-based access control** with 4 distinct roles  
✅ **Comprehensive admin dashboard** for management  

The organization management system is **production-ready** for basic use cases. Consider adding the recommended enhancements for enterprise deployments.

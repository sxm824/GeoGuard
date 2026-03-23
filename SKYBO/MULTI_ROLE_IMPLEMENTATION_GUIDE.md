# 🎯 Multi-Role System Implementation Guide

**GeoGuard - Personal Safety Monitoring in Conflict Zones**

---

## 📋 Overview

GeoGuard now supports **multi-role user accounts**, allowing a single user to have multiple roles simultaneously. This is critical for:

- **Coordinators who go to the field** → Admin + Field Person
- **Team leaders** → Manager + Field Person  
- **Future web dashboard** → Admin-only access (field workers blocked)

---

## 🏗️ Architecture Changes

### **Phase 1: Mobile App (Implemented)**

#### **1. User Model Updates**

**OLD (Single Role):**
```swift
struct User {
    var role: UserRole  // Single role only
}
```

**NEW (Multi-Role):**
```swift
struct User {
    var roles: [UserRole]  // Array of roles
    
    // Convenience properties
    var role: UserRole { roles.first ?? .fieldPersonnel }  // Backward compatibility
    var primaryRole: UserRole { /* highest priority role */ }
    
    // Helper methods
    func hasRole(_ role: UserRole) -> Bool
    func hasAnyRole(_ roles: [UserRole]) -> Bool
    func hasAllRoles(_ roles: [UserRole]) -> Bool
    var shouldBeTracked: Bool { hasRole(.fieldPersonnel) }
    var canMonitorOthers: Bool { hasAnyRole([.admin, .manager]) }
}
```

**Backward Compatibility:**
- Old documents with single `role` field will be automatically converted to `roles: [role]`
- New documents store both `role` (first role) and `roles` array
- Custom Codable decoder handles both formats seamlessly

---

#### **2. Role Types**

| Role | Code | Purpose | Tracked? |
|------|------|---------|----------|
| **Super Admin** | `superAdmin` | Platform administrators (GeoGuard team) | No |
| **Admin** | `admin` | Organization coordinator/administrator | Only if also `field_personnel` |
| **Manager** | `manager` | Operations manager, can view reports | Only if also `field_personnel` |
| **Field Personnel** | `fieldPersonnel` | Person being tracked for safety | Yes |

---

#### **3. Navigation Logic**

Users are routed to dashboards based on their **primary role** (highest privilege):

```swift
Primary Role Priority:
1. superAdmin → SuperAdminDashboardView
2. admin      → AdminDashboardView
3. manager    → ManagerDashboardView
4. fieldPersonnel → DriverDashboardView (GPS tracking interface)
```

**Multi-Role Behavior:**
- User with `["admin", "fieldPersonnel"]` → Sees AdminDashboardView
- AdminDashboardView detects secondary `fieldPersonnel` role
- Shows "My Safety Monitoring" section at top of admin dashboard
- Can start/stop their own tracking from admin interface

---

#### **4. AdminDashboardView Enhancements**

**NEW: "My Safety Monitoring" Section**

Only appears if `currentUser.hasRole(.fieldPersonnel)` returns true.

**Features:**
- ✅ Start/Stop Tracking toggle button
- ✅ Real-time location status indicators
- ✅ Battery level, sync status, queue count
- ✅ Same LocationManager used by field personnel
- ✅ Admin's location appears on team map alongside other field workers

**UI Layout:**
```
┌─────────────────────────────────────────┐
│  📍 GeoGuard - Admin Dashboard           │
├─────────────────────────────────────────┤
│                                          │
│  🛡️ My Safety Monitoring                │
│  ┌────────────────────────────────────┐ │
│  │ 🟢 Tracking Active                 │ │
│  │ Last sync: 1 min ago               │ │
│  │ Battery: 78% | Queue: 0            │ │
│  │ [Stop Tracking]                    │ │
│  └────────────────────────────────────┘ │
│  "When you go into the field, your     │
│   location will be monitored."          │
│                                          │
│  📊 Team Statistics                     │
│  ┌────────────┬────────────┐           │
│  │ Total Users│ Active     │           │
│  │     15     │ Invites: 3 │           │
│  └────────────┴────────────┘           │
│                                          │
│  [View All Field Personnel]             │
│  [Manage Users] [Reports]               │
└─────────────────────────────────────────┘
```

---

## 🎯 Common Use Cases

### **Use Case 1: Pure Admin (Office-Based Coordinator)**

**Profile:**
```json
{
  "fullName": "Sarah Johnson",
  "email": "sarah@ngo.org",
  "roles": ["admin"],
  "tenantId": "ngo_syria_operations"
}
```

**Experience:**
- ✅ Sees AdminDashboardView
- ✅ Can monitor all field personnel
- ✅ Manages users, geofences, reports
- ❌ NO "My Safety Monitoring" section (not going to field)
- ❌ NO GPS tracking (stays in office)

---

### **Use Case 2: Field Coordinator (Admin Who Goes to Field)**

**Profile:**
```json
{
  "fullName": "Ahmed Hassan",
  "email": "ahmed@ngo.org",
  "roles": ["admin", "fieldPersonnel"],
  "tenantId": "ngo_syria_operations"
}
```

**Experience:**
- ✅ Sees AdminDashboardView (primary role is admin)
- ✅ "My Safety Monitoring" section appears at top
- ✅ Can start tracking when going to field sites
- ✅ Can monitor entire team while also being monitored
- ✅ His location appears on team map when tracking
- ✅ Gets same safety alerts as field personnel

**Typical Workflow:**
1. Morning: At office, views admin dashboard, checks team status
2. 10 AM: Going to field → Taps "Start Tracking"
3. Field visit: GPS tracking active, location shared with team
4. 4 PM: Returns to office → Taps "Stop Tracking"
5. Evening: Reviews reports, manages geofences

---

### **Use Case 3: Pure Field Personnel**

**Profile:**
```json
{
  "fullName": "Maria Lopez",
  "email": "maria@ngo.org",
  "roles": ["fieldPersonnel"],
  "tenantId": "ngo_syria_operations"
}
```

**Experience:**
- ✅ Sees DriverDashboardView (field personnel interface)
- ✅ GPS tracking, SOS button, safety check-ins
- ✅ Can see their own location history
- ❌ Cannot view other team members
- ❌ No admin or management features

---

## 📱 Firebase Data Structure

### **User Document (Multi-Role)**

```json
{
  "id": "user_abc123",
  "tenantId": "ngo_syria_operations",
  "fullName": "Ahmed Hassan",
  "email": "ahmed@ngo.org",
  "roles": ["admin", "fieldPersonnel"],  // ✅ New: Array of roles
  "role": "admin",                       // ✅ Kept for backward compatibility
  "isActive": true,
  "createdAt": "2026-03-01T08:00:00Z",
  "lastLoginAt": "2026-03-07T09:30:00Z",
  
  "emergencyContact": "Sarah Hassan",
  "emergencyPhone": "+963-XXX-XXXX",
  "emergencyContactRelation": "Spouse",
  "bloodType": "O+",
  "medicalNotes": "No known allergies",
  
  "phone": "+963-XXX-XXXX",
  "address": "Damascus Office",
  "city": "Damascus",
  "country": "Syria",
  "vehicle": "Toyota Land Cruiser (White)"
}
```

---

## 🔄 Migration Strategy

### **Existing Users (Single Role → Multi-Role)**

**No manual migration needed!** The custom Codable decoder automatically converts:

**Old Document:**
```json
{
  "role": "admin"
}
```

**Decoded As:**
```swift
User(
  roles: ["admin"],  // ✅ Automatically converted to array
  role: "admin"      // ✅ Backward compatibility maintained
)
```

**Next Save:**
```json
{
  "roles": ["admin"],  // ✅ Now stored as array
  "role": "admin"      // ✅ Still included for old clients
}
```

### **Adding Field Role to Existing Admin**

**Option 1: Firebase Console** (Manual)
1. Open Firestore
2. Navigate to `users/{userId}`
3. Edit document
4. Change `role: "admin"` to `roles: ["admin", "fieldPersonnel"]`
5. Save

**Option 2: Admin Panel** (Recommended - Future Feature)
- User management screen
- "Edit Roles" button
- Checkboxes for each role
- Save → Updates Firestore

**Option 3: Programmatically** (For bulk updates)
```swift
func addFieldRoleToAdmin(userId: String) async throws {
    let userRef = Firestore.firestore().collection("users").document(userId)
    
    try await userRef.updateData([
        "roles": ["admin", "fieldPersonnel"],
        "role": "admin"  // Keep primary role
    ])
}
```

---

## 🌐 Phase 2: Web Dashboard (Future)

### **Access Control Strategy**

**Purpose:**
- Large-screen monitoring for coordinators
- Real-time map of all field personnel
- Analytics, reports, user management
- Geofence management

**Who Can Access:**
```swift
Web Login:
  ├─ Check user.roles
  ├─ Has "admin" OR "manager"? → ✅ Allow access
  └─ Only "fieldPersonnel"? → ❌ Block, show "Download mobile app" message
```

**Tech Stack:**
- Frontend: Next.js / React / SwiftUI for Mac
- Auth: Firebase Auth (same accounts as mobile!)
- Database: Same Firestore collections
- Real-time: Firestore listeners
- Map: Mapbox or Google Maps

### **Firestore Security Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
  
    // Helper: Check if user has a role
    function hasRole(role) {
      let userData = get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
      return userData.roles.hasAny([role]);
    }
    
    // Helper: Check same tenant
    function sameTenant(otherUserId) {
      let myTenant = get(/databases/$(database)/documents/users/$(request.auth.uid)).data.tenantId;
      let otherTenant = get(/databases/$(database)/documents/users/$(otherUserId)).data.tenantId;
      return myTenant == otherTenant;
    }
    
    // Users collection
    match /users/{userId} {
      // Mobile: Read own data
      allow read: if request.auth.uid == userId;
      
      // Web: Admins/Managers can read all users in their tenant
      allow read: if (hasRole('admin') || hasRole('manager')) && sameTenant(userId);
      
      // Create: During registration
      allow create: if request.auth.uid == userId;
      
      // Update: Own data or admin of same tenant
      allow update: if request.auth.uid == userId 
                    || (hasRole('admin') && sameTenant(userId));
    }
    
    // Locations collection
    match /user_locations/{locationId} {
      // Create: Field personnel tracking
      allow create: if request.auth.uid == request.resource.data.userId;
      
      // Read: Own locations OR admin/manager of same tenant
      allow read: if request.auth.uid == resource.data.userId
                  || (hasRole('admin') && sameTenant(resource.data.userId))
                  || (hasRole('manager') && sameTenant(resource.data.userId));
    }
    
    // Geofences collection
    match /geofences/{geofenceId} {
      // Read: All users in tenant
      allow read: if sameTenant(resource.data.tenantId);
      
      // Write: Admins/Managers only
      allow write: if (hasRole('admin') || hasRole('manager')) 
                   && sameTenant(resource.data.tenantId);
    }
    
    // Alerts collection
    match /alerts/{alertId} {
      // Read: All users in tenant
      allow read: if sameTenant(resource.data.tenantId);
      
      // Create: Field personnel (SOS) or Admins (manual alerts)
      allow create: if hasRole('fieldPersonnel') || hasRole('admin');
      
      // Update: Admins only (responding to alerts)
      allow update: if hasRole('admin') && sameTenant(resource.data.tenantId);
    }
  }
}
```

---

## 🧪 Testing Checklist

### **Test 1: Pure Admin**
- [ ] Create user with `roles: ["admin"]`
- [ ] Login → Should see AdminDashboardView
- [ ] "My Safety Monitoring" section should NOT appear
- [ ] Can view all field personnel
- [ ] Can manage users, geofences, reports

### **Test 2: Admin + Field Personnel**
- [ ] Create/Update user with `roles: ["admin", "fieldPersonnel"]`
- [ ] Login → Should see AdminDashboardView
- [ ] "My Safety Monitoring" section SHOULD appear at top
- [ ] Tap "Start Tracking" → GPS should activate
- [ ] Location should sync to Firestore
- [ ] Admin's location should appear on team map
- [ ] Tap "Stop Tracking" → GPS should stop

### **Test 3: Pure Field Personnel**
- [ ] Create user with `roles: ["fieldPersonnel"]`
- [ ] Login → Should see DriverDashboardView
- [ ] GPS tracking interface visible
- [ ] Can start/stop tracking
- [ ] Cannot access admin features

### **Test 4: Backward Compatibility**
- [ ] Find user with old single `role: "admin"` field
- [ ] Login → Should work normally
- [ ] Check `user.roles` → Should be `["admin"]`
- [ ] Save user → Should now have `roles` array in Firestore

### **Test 5: Role Checking**
```swift
let admin = User(roles: [.admin])
admin.hasRole(.admin) // ✅ true
admin.hasRole(.fieldPersonnel) // ❌ false
admin.canMonitorOthers // ✅ true
admin.shouldBeTracked // ❌ false

let fieldCoordinator = User(roles: [.admin, .fieldPersonnel])
fieldCoordinator.hasRole(.admin) // ✅ true
fieldCoordinator.hasRole(.fieldPersonnel) // ✅ true
fieldCoordinator.canMonitorOthers // ✅ true
fieldCoordinator.shouldBeTracked // ✅ true
fieldCoordinator.primaryRole // .admin (highest priority)
```

---

## 🚀 Implementation Status

### ✅ **Completed (Phase 1)**

- [x] User model updated with `roles` array
- [x] Backward-compatible Codable decoder
- [x] Custom Codable encoder for Firestore
- [x] Role checking helper methods (`hasRole`, `hasAnyRole`, etc.)
- [x] `primaryRole` computed property
- [x] `shouldBeTracked` and `canMonitorOthers` flags
- [x] RootView updated for multi-role navigation
- [x] AdminDashboardView updated with "My Safety Monitoring" section
- [x] LocationManager integration in AdminDashboardView
- [x] Start/Stop tracking from admin interface

### 🔜 **Pending (Phase 2 - Web Dashboard)**

- [ ] Web frontend (Next.js/React)
- [ ] Web authentication flow
- [ ] Role-based access control for web
- [ ] Real-time map of all field personnel
- [ ] Analytics dashboard
- [ ] Firestore security rules update
- [ ] "Download mobile app" redirect for field personnel

### 📋 **Future Enhancements**

- [ ] Admin panel for role management
- [ ] Bulk role assignment
- [ ] Role change notifications
- [ ] Audit log for role changes
- [ ] Permission granularity (custom permissions per user)

---

## 📚 Code Examples

### **Example 1: Check If User Should Be Tracked**

```swift
// In LocationManager or ViewModel
func shouldEnableTracking(for user: User) -> Bool {
    return user.shouldBeTracked
}

// Usage
if authService.currentUser?.shouldBeTracked == true {
    startLocationTracking()
}
```

### **Example 2: Show Admin Features**

```swift
// In any View
var canAccessAdminFeatures: Bool {
    authService.currentUser?.canMonitorOthers ?? false
}

var body: some View {
    VStack {
        if canAccessAdminFeatures {
            AdminControlPanel()
        }
    }
}
```

### **Example 3: Assign Multiple Roles During Registration**

```swift
func createUser(email: String, fullName: String, isFieldWorker: Bool) async throws {
    var roles: [UserRole] = [.admin]  // Base role
    
    if isFieldWorker {
        roles.append(.fieldPersonnel)  // Add field role
    }
    
    let user = User(
        tenantId: tenantId,
        fullName: fullName,
        email: email,
        roles: roles,  // ✅ Multiple roles assigned
        isActive: true,
        createdAt: Date()
    )
    
    try await Firestore.firestore()
        .collection("users")
        .document(userId)
        .setData(user.toDictionary())
}
```

### **Example 4: Update User Roles**

```swift
func addFieldRoleToUser(userId: String) async throws {
    let userRef = Firestore.firestore().collection("users").document(userId)
    
    // Fetch current user
    let snapshot = try await userRef.getDocument()
    guard var user = try? snapshot.data(as: User.self) else {
        throw NSError(domain: "User not found", code: 404)
    }
    
    // Add field personnel role if not already present
    if !user.hasRole(.fieldPersonnel) {
        user.roles.append(.fieldPersonnel)
        
        // Save back to Firestore
        try await userRef.updateData(user.toDictionary())
        
        print("✅ Added field personnel role to \(user.fullName)")
    }
}
```

---

## 🎯 Summary

### **What Changed:**
1. ✅ User model now supports multiple roles via `roles: [UserRole]`
2. ✅ Backward-compatible with single `role` field
3. ✅ AdminDashboardView shows "My Safety Monitoring" for admin+field users
4. ✅ Navigation based on primary role (highest privilege)
5. ✅ Helper methods for easy role checking

### **What Stays Same:**
- ✅ Existing single-role users work without changes
- ✅ LocationManager unchanged
- ✅ Firestore collections unchanged
- ✅ Authentication flow unchanged
- ✅ Field personnel dashboard unchanged

### **Benefits:**
- 🎯 **Flexible**: One person can be coordinator AND field worker
- 🔒 **Secure**: Role-based permissions still enforced
- 📱 **Scalable**: Easy to add new roles in future
- 🌐 **Future-proof**: Web dashboard slots in seamlessly
- 🛡️ **Safety-focused**: Coordinators can be tracked when in danger zones

---

**Ready for device testing!** 🚀

See `DEVICE_TESTING_CHECKLIST.md` for comprehensive testing procedures.

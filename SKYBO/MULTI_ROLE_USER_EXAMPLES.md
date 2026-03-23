# 🎯 Multi-Role User Creation Examples

**Quick reference for creating users with different role combinations**

---

## 📋 Role Combinations

### **1. Pure Admin (Office Coordinator)**
**Use when:** Person manages operations but never goes to field

```swift
let user = User(
    tenantId: "ngo_damascus",
    fullName: "Sarah Johnson",
    initials: "SJ",
    email: "sarah@ngo.org",
    phone: "+963-XXX-XXXX",
    address: "Damascus Office",
    city: "Damascus",
    country: "Syria",
    vehicle: "N/A",
    roles: [.admin],  // ✅ Admin only
    isActive: true,
    createdAt: Date()
)
```

**What they can do:**
- ✅ View all field personnel locations
- ✅ Manage users and invitations
- ✅ Configure geofences
- ✅ View reports and analytics
- ❌ NOT tracked (stays in office)

---

### **2. Field Coordinator (Admin + Field Person)**
**Use when:** Admin who also goes to field sites

```swift
let user = User(
    tenantId: "ngo_damascus",
    fullName: "Ahmed Hassan",
    initials: "AH",
    email: "ahmed@ngo.org",
    phone: "+963-XXX-XXXX",
    address: "Damascus Office",
    city: "Damascus",
    country: "Syria",
    vehicle: "Toyota Land Cruiser",
    roles: [.admin, .fieldPersonnel],  // ✅ Both roles!
    isActive: true,
    createdAt: Date(),
    emergencyContact: "Sarah Hassan",
    emergencyPhone: "+963-XXX-XXXX",
    emergencyContactRelation: "Spouse",
    bloodType: "O+",
    medicalNotes: "No known allergies"
)
```

**What they can do:**
- ✅ Everything a pure admin can do
- ✅ PLUS: Can be tracked when in field
- ✅ "My Safety Monitoring" section in admin dashboard
- ✅ Their location appears on team map
- ✅ Gets safety alerts and geofence notifications

**UI Experience:**
```
AdminDashboardView
├─ 🛡️ My Safety Monitoring
│  ├─ Start/Stop Tracking toggle
│  ├─ Location status indicators
│  └─ Battery, sync, queue info
├─ 📊 Team Statistics
├─ 👥 Field Personnel List
└─ ⚙️ Settings & Reports
```

---

### **3. Pure Field Personnel**
**Use when:** Person only works in field, no management duties

```swift
let user = User(
    tenantId: "ngo_damascus",
    fullName: "Maria Lopez",
    initials: "ML",
    email: "maria@ngo.org",
    phone: "+963-XXX-XXXX",
    address: "Field Base Alpha",
    city: "Aleppo",
    country: "Syria",
    vehicle: "Honda CRV",
    roles: [.fieldPersonnel],  // ✅ Field person only
    isActive: true,
    createdAt: Date(),
    emergencyContact: "Carlos Lopez",
    emergencyPhone: "+1-XXX-XXX-XXXX",
    emergencyContactRelation: "Brother",
    bloodType: "A+",
    medicalNotes: "Allergic to penicillin"
)
```

**What they can do:**
- ✅ GPS tracking when on duty
- ✅ SOS emergency button
- ✅ Safety check-ins
- ✅ View geofences
- ✅ View own location history
- ❌ Cannot view other team members
- ❌ No admin features

---

### **4. Operations Manager (Manager + Field Person)**
**Use when:** Middle management who also goes to field

```swift
let user = User(
    tenantId: "ngo_damascus",
    fullName: "Yusuf Ibrahim",
    initials: "YI",
    email: "yusuf@ngo.org",
    phone: "+963-XXX-XXXX",
    address: "Damascus Office",
    city: "Damascus",
    country: "Syria",
    vehicle: "Ford Ranger",
    roles: [.manager, .fieldPersonnel],  // ✅ Manager + Field
    isActive: true,
    createdAt: Date(),
    emergencyContact: "Fatima Ibrahim",
    emergencyPhone: "+963-XXX-XXXX",
    emergencyContactRelation: "Wife",
    bloodType: "B+",
    medicalNotes: "Diabetic - carries insulin"
)
```

**What they can do:**
- ✅ View team members and their locations
- ✅ Create/manage geofences
- ✅ View reports
- ✅ Send alerts to team
- ✅ PLUS: Can be tracked when in field
- ❌ Cannot manage users (only admin can)

---

### **5. Super Admin (Platform Administrator)**
**Use when:** GeoGuard platform team only

```swift
let user = User(
    tenantId: "geoguard_platform",  // Special tenant for platform admins
    fullName: "Platform Admin",
    initials: "PA",
    email: "admin@geoguard.com",
    phone: "+1-XXX-XXX-XXXX",
    address: "GeoGuard HQ",
    city: "San Francisco",
    country: "USA",
    vehicle: "N/A",
    roles: [.superAdmin],  // ✅ Super admin
    isActive: true,
    createdAt: Date()
)
```

**What they can do:**
- ✅ Access ALL tenants
- ✅ Full platform management
- ✅ User management across organizations
- ✅ System configuration
- ❌ Should NOT be used for regular organizations

---

## 🔧 Firebase Console Quick Create

### **Method 1: Using Firestore Console**

1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to `users` collection
4. Click "Add Document"
5. Use Auto-ID or specify user ID
6. Add fields:

```json
{
  "tenantId": "ngo_damascus",
  "fullName": "Ahmed Hassan",
  "initials": "AH",
  "email": "ahmed@ngo.org",
  "phone": "+963-123-4567",
  "address": "Damascus Office",
  "city": "Damascus",
  "country": "Syria",
  "vehicle": "Toyota Land Cruiser",
  "roles": ["admin", "field_personnel"],
  "role": "admin",
  "isActive": true,
  "createdAt": "2026-03-07T10:00:00Z",
  "emergencyContact": "Sarah Hassan",
  "emergencyPhone": "+963-XXX-XXXX",
  "emergencyContactRelation": "Spouse",
  "bloodType": "O+",
  "medicalNotes": ""
}
```

7. Save

---

### **Method 2: Programmatically (Recommended)**

```swift
import FirebaseFirestore
import FirebaseAuth

class UserCreationService {
    private let db = Firestore.firestore()
    
    /// Create field coordinator (admin + field person)
    func createFieldCoordinator(
        email: String,
        password: String,
        fullName: String,
        tenantId: String
    ) async throws {
        // 1. Create Firebase Auth account
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let userId = authResult.user.uid
        
        // 2. Generate initials
        let nameParts = fullName.split(separator: " ")
        let initials = nameParts.compactMap { $0.first }.map(String.init).joined()
        
        // 3. Create User document
        let user = User(
            id: userId,
            tenantId: tenantId,
            fullName: fullName,
            initials: initials,
            email: email,
            phone: "",
            address: "",
            city: "",
            country: "",
            vehicle: "",
            roles: [.admin, .fieldPersonnel],  // ✅ Both roles
            isActive: true,
            createdAt: Date()
        )
        
        // 4. Save to Firestore
        try db.collection("users")
            .document(userId)
            .setData(user.toDictionary())
        
        print("✅ Created field coordinator: \(fullName)")
    }
    
    /// Create pure field personnel
    func createFieldPersonnel(
        email: String,
        password: String,
        fullName: String,
        tenantId: String,
        emergencyContact: String,
        emergencyPhone: String,
        bloodType: String?
    ) async throws {
        // 1. Create Firebase Auth account
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let userId = authResult.user.uid
        
        // 2. Generate initials
        let nameParts = fullName.split(separator: " ")
        let initials = nameParts.compactMap { $0.first }.map(String.init).joined()
        
        // 3. Create User document
        var user = User(
            id: userId,
            tenantId: tenantId,
            fullName: fullName,
            initials: initials,
            email: email,
            phone: "",
            address: "",
            city: "",
            country: "",
            vehicle: "",
            roles: [.fieldPersonnel],  // ✅ Field person only
            isActive: true,
            createdAt: Date()
        )
        
        // Add emergency info
        user.emergencyContact = emergencyContact
        user.emergencyPhone = emergencyPhone
        user.emergencyContactRelation = "Emergency Contact"
        user.bloodType = bloodType
        
        // 4. Save to Firestore
        try db.collection("users")
            .document(userId)
            .setData(user.toDictionary())
        
        print("✅ Created field personnel: \(fullName)")
    }
}
```

---

## 🔄 Adding Field Role to Existing Admin

### **Scenario:** You have an admin who now needs to go to field

```swift
func addFieldRoleToAdmin(userId: String) async throws {
    let userRef = db.collection("users").document(userId)
    
    // Fetch current user
    let snapshot = try await userRef.getDocument()
    guard var user = try? snapshot.data(as: User.self) else {
        throw NSError(domain: "User not found", code: 404)
    }
    
    // Check if already has field role
    guard !user.hasRole(.fieldPersonnel) else {
        print("⚠️ User already has field personnel role")
        return
    }
    
    // Add field role
    user.roles.append(.fieldPersonnel)
    
    // Update in Firestore
    try await userRef.updateData([
        "roles": user.roles.map { $0.rawValue },
        "role": user.primaryRole.rawValue  // Update primary role
    ])
    
    print("✅ Added field personnel role to \(user.fullName)")
    print("   Roles: \(user.roles.map { $0.displayName }.joined(separator: ", "))")
}
```

---

## 🧪 Testing Role Behavior

```swift
// Test role checking
let coordinator = User(
    roles: [.admin, .fieldPersonnel],
    // ... other fields
)

// Individual role checks
print(coordinator.hasRole(.admin))          // true
print(coordinator.hasRole(.fieldPersonnel)) // true
print(coordinator.hasRole(.manager))        // false

// Multiple role checks
print(coordinator.hasAnyRole([.admin, .manager]))  // true (has admin)
print(coordinator.hasAllRoles([.admin, .fieldPersonnel]))  // true

// Derived properties
print(coordinator.primaryRole)        // .admin (highest priority)
print(coordinator.shouldBeTracked)    // true (has field_personnel)
print(coordinator.canMonitorOthers)   // true (has admin)

// Display
print(coordinator.primaryRole.displayName)  // "Administrator"
```

---

## 📱 What Users See

### **Pure Admin Login:**
```
┌─────────────────────────────────┐
│  📍 GeoGuard - Admin Dashboard   │
├─────────────────────────────────┤
│                                  │
│  📊 Team Statistics              │
│  ┌──────────┬──────────┐        │
│  │ Total    │ Active   │        │
│  │ Users:15 │ Track:8  │        │
│  └──────────┴──────────┘        │
│                                  │
│  👥 Field Personnel (8 active)   │
│  🟢 Maria - Active (2h ago)      │
│  🟢 Yusuf - Active (15m ago)     │
│  ⚫ John - Offline (1d ago)      │
│                                  │
│  [View Map] [Reports] [Settings] │
└─────────────────────────────────┘
```

### **Field Coordinator Login:**
```
┌─────────────────────────────────┐
│  📍 GeoGuard - Admin Dashboard   │
├─────────────────────────────────┤
│                                  │
│  🛡️ My Safety Monitoring         │
│  ┌─────────────────────────────┐│
│  │ ⚫ Not Tracking              ││
│  │ [Start Tracking]            ││
│  │ Tap to begin when entering  ││
│  │ the field                   ││
│  └─────────────────────────────┘│
│                                  │
│  📊 Team Statistics              │
│  (same as pure admin...)         │
│                                  │
└─────────────────────────────────┘
```

### **Pure Field Person Login:**
```
┌─────────────────────────────────┐
│  📍 GeoGuard - Safety Monitor    │
├─────────────────────────────────┤
│                                  │
│  🟢 Tracking Active              │
│  Last sync: 2 minutes ago        │
│  Battery: 65% | Queue: 0         │
│                                  │
│  [Stop Tracking]                 │
│                                  │
│  🆘 EMERGENCY SOS                │
│  Tap if you need help            │
│                                  │
│  📍 My Location                  │
│  [Map showing current position]  │
│                                  │
│  [Profile] [History] [Settings]  │
└─────────────────────────────────┘
```

---

## ✅ Quick Checklist

Before creating users, ensure:

- [ ] Firebase Auth is configured
- [ ] Firestore database is set up
- [ ] `users` collection exists
- [ ] Security rules allow user creation
- [ ] You have the correct tenant ID
- [ ] For field personnel: Emergency contact info is collected
- [ ] For admins: Confirmed they need admin privileges
- [ ] For dual roles: Confirmed they actually go to field

---

**Need help?** See `MULTI_ROLE_IMPLEMENTATION_GUIDE.md` for full details.

# 🎯 Multi-Role System - Quick Visual Guide

---

## 📱 What Users See

### **1. Pure Admin** (Office Coordinator)
```
Roles: ["admin"]
Primary Role: admin
Should Be Tracked: NO
```

**Dashboard:**
```
╔═══════════════════════════════════════╗
║  📍 GeoGuard - Admin Dashboard        ║
╠═══════════════════════════════════════╣
║                                       ║
║  📊 TEAM STATISTICS                   ║
║  ┌─────────────┬─────────────┐       ║
║  │ Total Users │ Active      │       ║
║  │     15      │ Tracking: 8 │       ║
║  └─────────────┴─────────────┘       ║
║                                       ║
║  👥 FIELD PERSONNEL (8 active)        ║
║  ┌─────────────────────────────────┐ ║
║  │ 🟢 Maria Lopez                  │ ║
║  │    Active • 2 min ago           │ ║
║  │                                 │ ║
║  │ 🟢 Yusuf Ibrahim                │ ║
║  │    Active • 15 min ago          │ ║
║  │                                 │ ║
║  │ ⚫ John Smith                    │ ║
║  │    Offline • 1 day ago          │ ║
║  └─────────────────────────────────┘ ║
║                                       ║
║  [View Map] [Reports] [Settings]      ║
║                                       ║
╚═══════════════════════════════════════╝
```

---

### **2. Field Coordinator** (Admin + Field Person) ⭐
```
Roles: ["admin", "field_personnel"]
Primary Role: admin
Should Be Tracked: YES
```

**Dashboard (when NOT tracking):**
```
╔═══════════════════════════════════════╗
║  📍 GeoGuard - Admin Dashboard        ║
╠═══════════════════════════════════════╣
║                                       ║
║  🛡️ MY SAFETY MONITORING              ║
║  ┌─────────────────────────────────┐ ║
║  │ ⚫ Not Tracking                  │ ║
║  │ Last sync: Never                │ ║
║  │                                 │ ║
║  │      [START TRACKING]           │ ║
║  │                                 │ ║
║  └─────────────────────────────────┘ ║
║  When you go into the field, your     ║
║  location will be monitored.          ║
║                                       ║
║  📊 TEAM STATISTICS                   ║
║  (same as pure admin...)              ║
║                                       ║
╚═══════════════════════════════════════╝
```

**Dashboard (when TRACKING):**
```
╔═══════════════════════════════════════╗
║  📍 GeoGuard - Admin Dashboard        ║
╠═══════════════════════════════════════╣
║                                       ║
║  🛡️ MY SAFETY MONITORING              ║
║  ┌─────────────────────────────────┐ ║
║  │ 🟢 Tracking Active              │ ║
║  │ Last sync: 1 min ago            │ ║
║  │ Battery: 78% | Queue: 0         │ ║
║  │ Accuracy: High (±5m)            │ ║
║  │                                 │ ║
║  │      [STOP TRACKING] 🔴         │ ║
║  │                                 │ ║
║  └─────────────────────────────────┘ ║
║  Your location is being monitored     ║
║  for safety.                          ║
║                                       ║
║  📊 TEAM STATISTICS                   ║
║  ┌─────────────┬─────────────┐       ║
║  │ Total Users │ Active      │       ║
║  │     15      │ Tracking: 9 │       ║ ← Includes YOU!
║  └─────────────┴─────────────┘       ║
║                                       ║
║  👥 FIELD PERSONNEL (9 active)        ║
║  ┌─────────────────────────────────┐ ║
║  │ 🟢 Ahmed Hassan (You)           │ ║ ← YOU appear here
║  │    Active • Just now            │ ║
║  │                                 │ ║
║  │ 🟢 Maria Lopez                  │ ║
║  │    Active • 2 min ago           │ ║
║  └─────────────────────────────────┘ ║
║                                       ║
║  [View Map] [Reports] [Settings]      ║
║                                       ║
╚═══════════════════════════════════════╝
```

---

### **3. Pure Field Personnel**
```
Roles: ["field_personnel"]
Primary Role: field_personnel
Should Be Tracked: YES
```

**Dashboard:**
```
╔═══════════════════════════════════════╗
║  📍 GeoGuard - Safety Monitor         ║
╠═══════════════════════════════════════╣
║                                       ║
║  🟢 TRACKING ACTIVE                   ║
║  Last sync: 2 minutes ago             ║
║  Battery: 65% | Queue: 0              ║
║  Accuracy: High (±8m)                 ║
║                                       ║
║       [STOP TRACKING] 🔴              ║
║                                       ║
║  ┌─────────────────────────────────┐ ║
║  │                                 │ ║
║  │      🆘 EMERGENCY SOS            │ ║
║  │                                 │ ║
║  │   Tap if you need help          │ ║
║  │                                 │ ║
║  └─────────────────────────────────┘ ║
║                                       ║
║  📍 MY CURRENT LOCATION               ║
║  ┌─────────────────────────────────┐ ║
║  │        🗺️ MAP VIEW              │ ║
║  │                                 │ ║
║  │         📍 You                  │ ║
║  │                                 │ ║
║  │                                 │ ║
║  └─────────────────────────────────┘ ║
║  Lat: 33.5138°N                       ║
║  Lon: 36.2765°E                       ║
║                                       ║
║  [GPS] [Alerts] [Profile]             ║
║                                       ║
╚═══════════════════════════════════════╝
```

---

## 🔄 Role Combination Decision Tree

```
User Login
    │
    ├─ Fetch user.roles from Firestore
    │
    ├─ Calculate primaryRole
    │   ├─ superAdmin? → Primary = superAdmin
    │   ├─ admin? → Primary = admin
    │   ├─ manager? → Primary = manager
    │   └─ fieldPersonnel? → Primary = fieldPersonnel
    │
    └─ Route to Dashboard
        │
        ├─ Primary = superAdmin
        │   └─→ SuperAdminDashboardView
        │
        ├─ Primary = admin
        │   └─→ AdminDashboardView
        │       ├─ Has field_personnel role?
        │       │   ├─ YES → Show "My Safety Monitoring" section ✅
        │       │   └─ NO → Hide "My Safety Monitoring" section
        │       └─ Show team stats, user management, reports
        │
        ├─ Primary = manager
        │   └─→ ManagerDashboardView
        │       ├─ Has field_personnel role?
        │       │   ├─ YES → Show tracking section
        │       │   └─ NO → Hide tracking section
        │       └─ Show team monitoring, reports
        │
        └─ Primary = fieldPersonnel
            └─→ DriverDashboardView
                └─ GPS tracking, SOS, check-ins
```

---

## 📊 Role Permissions Matrix

| Feature | Super Admin | Admin | Manager | Field Personnel | Admin+Field |
|---------|-------------|-------|---------|----------------|-------------|
| **View all field personnel** | ✅ | ✅ | ✅ | ❌ | ✅ |
| **Manage users** | ✅ | ✅ | ❌ | ❌ | ✅ |
| **Create geofences** | ✅ | ✅ | ✅ | ❌ | ✅ |
| **View reports** | ✅ | ✅ | ✅ | ❌ | ✅ |
| **Send team alerts** | ✅ | ✅ | ✅ | ❌ | ✅ |
| **Be GPS tracked** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Trigger SOS** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Safety check-ins** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Appear on team map** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Start/stop own tracking** | ❌ | ❌ | ❌ | ✅ | ✅ |

---

## 🎯 Common Scenarios

### **Scenario 1: Office Day**
```
User: Ahmed Hassan
Roles: [admin, field_personnel]
Location: Damascus Office

8:00 AM  → Login to app
8:05 AM  → Check team dashboard
          ├─ 8 people currently tracking
          ├─ 2 in danger zones (get alerts)
          └─ 1 missed check-in (send message)

9:00 AM  → Review overnight reports

10:00 AM → Configure new geofence for aid distribution site

12:00 PM → Lunch

2:00 PM  → User management (approve new field worker)

5:00 PM  → Generate weekly report

6:00 PM  → Sign out

Tracking Status: ⚫ NEVER ENABLED (stayed in office)
```

---

### **Scenario 2: Field Visit Day**
```
User: Ahmed Hassan
Roles: [admin, field_personnel]

8:00 AM  → Login to app
8:05 AM  → Check team dashboard
8:30 AM  → Prepare for field visit

9:00 AM  → 🚗 Leaving office
          └─→ TAP "START TRACKING" ✅
              ├─ GPS activates
              ├─ Location syncs every 30s
              └─ Appears on team map

9:30 AM  → Enter geofence "Distribution Site A"
          └─→ Alert sent to office team

10:00 AM → Meeting with aid recipients

12:00 PM → Safety check-in triggered
          └─→ Confirm "I'm OK"

2:00 PM  → Leave distribution site

3:00 PM  → 🚗 Return to office
          └─→ TAP "STOP TRACKING" 🔴
              ├─ GPS deactivates
              └─ Removed from active tracking list

3:30 PM  → Back to admin dashboard
          └─→ File field report

5:00 PM  → Sign out

Tracking Status: 🟢 ENABLED 9:00 AM - 3:00 PM (6 hours)
```

---

### **Scenario 3: Pure Field Worker Day**
```
User: Maria Lopez
Roles: [field_personnel]

7:00 AM  → Login to app
7:05 AM  → 🚗 TAP "START TRACKING" ✅
          └─→ GPS tracking begins

8:00 AM  → Arrive at supply depot
          └─→ Geofence entry logged

9:00 AM  → Load supplies

10:00 AM → 🚗 En route to delivery point 1

11:00 AM → Delivery complete
          └─→ Safety check-in: "I'm OK"

12:00 PM → 🚗 En route to delivery point 2

1:00 PM  → ⚠️ Enter DANGER ZONE geofence
          └─→ Alert sent to coordinators
          └─→ Notification: "You've entered a high-risk area"

2:00 PM  → Exit danger zone
          └─→ Alert sent: "Exited danger zone safely"

3:00 PM  → Final delivery complete

4:00 PM  → 🚗 Return to depot

5:00 PM  → TAP "STOP TRACKING" 🔴

5:30 PM  → Sign out

Tracking Status: 🟢 ENABLED ALL DAY (10 hours)
```

---

## 📱 User Profile Examples

### **Pure Admin**
```json
{
  "fullName": "Sarah Johnson",
  "email": "sarah@ngo.org",
  "roles": ["admin"],
  "vehicle": "N/A",
  "emergencyContact": null,
  "bloodType": null
}
```
**Why?** Stays in office, doesn't need emergency info

---

### **Field Coordinator**
```json
{
  "fullName": "Ahmed Hassan",
  "email": "ahmed@ngo.org",
  "roles": ["admin", "field_personnel"],
  "vehicle": "Toyota Land Cruiser (White)",
  "emergencyContact": "Sarah Hassan",
  "emergencyPhone": "+963-XXX-XXXX",
  "emergencyContactRelation": "Spouse",
  "bloodType": "O+",
  "medicalNotes": "No known allergies"
}
```
**Why?** Goes to field, needs full emergency info

---

### **Pure Field Worker**
```json
{
  "fullName": "Maria Lopez",
  "email": "maria@ngo.org",
  "roles": ["field_personnel"],
  "vehicle": "Honda CRV (Blue)",
  "emergencyContact": "Carlos Lopez",
  "emergencyPhone": "+1-XXX-XXX-XXXX",
  "emergencyContactRelation": "Brother",
  "bloodType": "A+",
  "medicalNotes": "Allergic to penicillin"
}
```
**Why?** Always in field, critical emergency info required

---

## 🔧 Code Examples

### **Check if user should see admin features:**
```swift
if authService.currentUser?.canMonitorOthers == true {
    // Show admin dashboard
}
```

### **Check if user should be tracked:**
```swift
if authService.currentUser?.shouldBeTracked == true {
    locationManager.startTracking(...)
}
```

### **Check specific role:**
```swift
if authService.currentUser?.hasRole(.fieldPersonnel) == true {
    // Show "My Safety Monitoring" section
}
```

### **Check primary role:**
```swift
switch authService.currentUser?.primaryRole {
case .admin:
    // Route to AdminDashboardView
case .fieldPersonnel:
    // Route to DriverDashboardView
default:
    break
}
```

---

## ✅ Quick Test Checklist

- [ ] Create pure admin → No tracking section
- [ ] Create admin+field → Tracking section appears
- [ ] Start tracking as admin+field → GPS works
- [ ] Stop tracking → GPS stops
- [ ] Pure field login → See DriverDashboardView
- [ ] Old user with single role → Still works

---

**Ready to test!** See `MULTI_ROLE_COMPLETE.md` for next steps.

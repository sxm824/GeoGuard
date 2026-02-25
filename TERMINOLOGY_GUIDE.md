# 🛡️ GeoGuard Terminology & Context Guide

## Application Purpose

**GeoGuard is a personnel safety tracking system for high-risk environments**, NOT a delivery/fleet tracking app.

### Primary Use Cases
- 🏥 **Humanitarian Organizations**: Track aid workers in conflict zones
- 📰 **Journalists**: Monitor reporters in war zones and hostile areas
- 🛡️ **Security Contractors**: Personnel accountability in combat zones
- 🚑 **NGOs**: Field worker safety in dangerous regions
- 🏛️ **Diplomats**: Embassy staff and delegation security

---

## Terminology Changes

### ❌ OLD (Fleet/Delivery) → ✅ NEW (Safety Tracking)

| Old Term | New Term | Context |
|----------|----------|---------|
| Company | **Organization** | NGO, news agency, security firm |
| Driver | **Field Personnel** | People being tracked for safety |
| Fleet | **Personnel** / **Team** | Group of people being monitored |
| Vehicle Tracking | **Personnel Tracking** | Location monitoring for safety |
| Delivery | **Mission** / **Assignment** | Field work or task |
| Route | **Movement** / **Path** | Personnel movement history |
| Geofence | **Safety Zone** | Secure/danger area boundary |

### Key Concepts

#### 🎯 Roles
- **Admin**: Organization leader (e.g., Country Director, Bureau Chief)
- **Manager**: Operations coordinator (e.g., Security Manager, Operations Lead)
- **Field Personnel**: People being tracked (journalists, aid workers, contractors)
- **Super Admin**: GeoGuard platform administrators

#### 🗺️ Safety Zones (Geofences)
- **Safe Zones**: Bases, safe houses, friendly areas
- **Danger Zones**: Conflict areas, restricted regions, checkpoints
- **Exclusion Zones**: Areas personnel must avoid
- **Interest Zones**: Important locations to monitor

#### 🚨 Safety Features
- **Check-In/Check-Out**: Daily status reporting
- **Emergency SOS**: Panic button for immediate help
- **Breach Alerts**: Notifications when entering/exiting zones
- **Last Known Location**: Critical for rescue operations
- **Route History**: Movement tracking for incident investigation

---

## UI/UX Language Updates

### Screen Titles
- ~~"Fleet Dashboard"~~ → **"Personnel Monitor"**
- ~~"Driver List"~~ → **"Field Personnel"** or **"Team Members"**
- ~~"Vehicle Management"~~ → **"Equipment Tracking"** (if needed)
- ~~"Delivery Tracking"~~ → **"Mission Tracking"**

### Button Labels
- ~~"Add Driver"~~ → **"Add Personnel"**
- ~~"Track Fleet"~~ → **"Monitor Team"**
- ~~"View Routes"~~ → **"View Movements"**

### Form Fields
- `vehicle` → Keep (means: car, truck, motorcycle, on-foot)
  - But update picker options: "Car", "Truck", "Motorcycle", "On Foot", "Bicycle"
  - This is for safety planning (evacuation capacity)

### Notifications
- ~~"Driver entered geofence"~~ → **"Personnel entered safety zone"**
- ~~"Delivery complete"~~ → **"Mission complete"** or **"Check-in received"**

---

## Code Changes Needed

### 1. Update User Model Comments
```swift
struct User: Codable, Identifiable {
    var tenantId: String  // Links user to their organization
    var vehicle: String   // Transportation method (for safety/evacuation planning)
    var role: UserRole    // Admin, Manager, or Field Personnel
    
    // Safety & Emergency Information
    var emergencyContact: String?
    var emergencyPhone: String?
    var bloodType: String?
    var medicalNotes: String?
}
```

### 2. Update UserRole Cases
Already done! Changed:
- `driver` → `fieldPersonnel`
- Added safety-specific permissions

### 3. Update UI Components

**SignupView.swift** - Vehicle picker:
```swift
let transportMethods = ["Car", "Truck", "Motorcycle", "On Foot", "Bicycle", "Other"]
```

**CompanyRegistrationView.swift**:
```swift
Text("Register Your Organization")
    .font(.title)
    
Text("Create a GeoGuard account for your humanitarian organization, news agency, or security team")
```

**AdminDashboardView.swift**:
```swift
StatCard(
    title: "Field Personnel",
    value: "\(viewModel.users.filter { $0.role == .fieldPersonnel }.count)",
    icon: "person.fill",
    color: .blue
)
```

### 4. Update Subscription Tiers (Optional)

```swift
enum SubscriptionTier: String, Codable {
    case trial = "trial"            // 5 personnel
    case small = "small"            // 25 personnel (small NGO, bureau)
    case medium = "medium"          // 100 personnel (regional operations)
    case large = "large"            // 500 personnel (country-wide)
    case enterprise = "enterprise"  // Unlimited (international operations)
}
```

---

## Documentation Updates

### README.md
✅ Already updated in `README_UPDATED.md`

Key sections added:
- Use Cases (Humanitarian, Journalism, Security)
- Ethical Considerations
- Privacy & Consent
- Best Practices

### User-Facing Strings

Update these in your views:

```swift
// Login/Signup
"Track your team's safety in high-risk environments"
"Join your organization's safety network"

// Dashboard
"Personnel Status Overview"
"Active Field Personnel: X"
"Safety Zones Configured: X"

// Invitations
"Invite team members to join your organization's safety network"
"Share this code securely with new field personnel"

// Alerts
"⚠️ EMERGENCY: [Name] has activated SOS"
"🚨 [Name] entered danger zone: [Zone Name]"
"✅ [Name] checked in safely at [Location]"
```

---

## Ethical & Legal Considerations

### Required Features

1. **Explicit Consent**
   - Personnel must actively consent to tracking
   - Clear explanation of what data is collected
   - Option to disable tracking during off-hours

2. **Privacy Controls**
   - Personnel can see who has access to their location
   - Location data retention policies
   - Data deletion upon departure

3. **Transparency**
   - Clear indication when tracking is active
   - Notification when location is accessed
   - Audit trail of who viewed location data

4. **Safety First**
   - Emergency SOS always available
   - Location data encrypted
   - No sharing of location with unauthorized parties

### Terms of Service Updates

Add these to your app:

```
GeoGuard is designed for VOLUNTARY safety tracking in high-risk environments.

Prohibited Uses:
- Surveillance without explicit consent
- Tracking during personal/off-duty time (unless agreed)
- Sharing location data with third parties
- Using data for disciplinary purposes

Organizations using GeoGuard must:
- Obtain written consent from all tracked personnel
- Establish clear use policies
- Train administrators on privacy
- Respect personnel privacy rights
- Only use data for safety purposes
```

---

## Updated Features for Phase 2

### High Priority (Safety-Critical)

1. **Emergency SOS Button**
   - Prominent red button in app
   - Sends immediate alert with location
   - Notifies all admins/managers
   - Optional: Triggers local emergency services

2. **Check-In System**
   - Daily/scheduled check-ins
   - "Safe" / "Need Help" / "Emergency" status
   - Missed check-in alerts
   - Bulk check-in for teams

3. **Safety Zone Breach Alerts**
   - Real-time notifications
   - Push + SMS + email
   - Escalation for danger zones
   - Automatic incident logging

4. **Last Known Location**
   - Always accessible in emergencies
   - Works even if personnel offline
   - Historical location playback
   - Export for rescue coordination

5. **Offline Mode**
   - Cached maps for no-network areas
   - Queue location updates
   - Sync when connection returns

### Medium Priority

6. **Incident Reporting**
   - Quick incident forms
   - Photo/video evidence
   - GPS-tagged automatically
   - Share with team/authorities

7. **Team Coordination**
   - See other personnel on map (if permitted)
   - Group messaging
   - Rally points
   - Evacuation coordination

8. **Medical Information**
   - Blood type, allergies, medications
   - Emergency contact details
   - Medical evacuation preferences
   - Accessible to admins in emergencies

---

## Screenshots & Marketing

### App Store Description

```
GeoGuard: Personnel Safety Tracking

Keep your team safe in high-risk environments. Designed for humanitarian 
organizations, journalists, and security personnel operating in conflict 
zones and dangerous areas.

Features:
• Real-time personnel location tracking
• Safety zones with breach alerts
• Emergency SOS button
• Check-in/check-out system
• Secure multi-organization platform
• Complete privacy controls

Trusted by NGOs, news organizations, and security contractors worldwide 
to keep their people safe.
```

### Marketing Focus

❌ Don't say:
- "Track your fleet"
- "Improve delivery efficiency"
- "Monitor productivity"

✅ Do say:
- "Keep your team safe"
- "Ensure personnel safety"
- "Emergency response coordination"
- "Built for high-risk environments"

---

## Quick Reference

### Find & Replace in Code

```bash
# Case-sensitive replacements:
"driver" → "field personnel" (UI strings)
"Driver" → "Field Personnel" (titles)
"company" → "organization" (UI strings, keep in code)
"fleet" → "personnel" (UI strings)
"vehicle tracking" → "personnel tracking"
```

### Keep As-Is (Internal Code)

These internal names are fine to keep:
- `tenantId` (database field)
- `vehicle` (field name - it's generic enough)
- Collection names: `users`, `tenants`, `invitations`

### Update in UI Only

Change these in user-facing text:
- Screen titles
- Button labels
- Help text
- Notifications
- Error messages

---

## Summary

**Core Message**: GeoGuard is about **saving lives**, not tracking packages.

Every feature should be designed with this question:
> "Would this help keep someone safe in a war zone?"

Focus on:
- 🛡️ Safety & Security
- 🚨 Emergency Response
- 🤝 Team Coordination
- 📊 Accountability (for good reasons)
- 🔐 Privacy & Consent

NOT on:
- ❌ Productivity monitoring
- ❌ Efficiency metrics
- ❌ Surveillance

---

**Next Steps:**
1. Review README_UPDATED.md (already done)
2. Update UI strings in views (field personnel, organizations, etc.)
3. Add emergency contact fields to signup
4. Plan Phase 2 with safety-first features
5. Add Terms of Service with ethical guidelines

Let me know what you'd like to update first!

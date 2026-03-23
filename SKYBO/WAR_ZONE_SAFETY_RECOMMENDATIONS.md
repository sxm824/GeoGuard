# 🚨 War Zone Safety Recommendations for GeoGuard

**Last Updated:** March 6, 2026  
**Context:** Personnel safety tracking for humanitarian workers, journalists, and security contractors in conflict zones

---

## ✅ IMPLEMENTED FEATURES

### 1. Emergency Contact System (SignupView.swift + User Model)
**Status:** ✅ COMPLETE

- Added required emergency contact fields to signup:
  - Emergency contact name
  - Emergency contact phone (validated international format)
  - Relationship to contact
  - Blood type (optional)
  - Medical notes/allergies (optional)

**Impact:** Critical for emergency response when personnel are injured or missing.

**Files Modified:**
- `SignupView.swift` - Added UI fields and validation
- `ModelsUser.swift` - Added `emergencyContactRelation` field

---

### 2. Offline Location Caching
**Status:** ✅ COMPLETE

- Implemented automatic location caching when network fails
- Queue persists to disk (survives app restart)
- Auto-syncs when connection returns
- Supports up to 100 cached locations
- Battery-aware tracking intervals

**Impact:** CRITICAL - No lost location data during network outages in conflict zones.

**Files Modified:**
- `ServicesLocationManager.swift` - Added offline queue and battery monitoring

**Documentation:** See `OFFLINE_AND_DURESS_IMPLEMENTATION.md`

---

### 3. Duress Code System
**Status:** ✅ COMPLETE

- Silent detection of special codes during check-in
- NO visual feedback to user (completely covert)
- Sends CRITICAL alert to admins only
- Pre-defined codes: "999", "911", "000"
- Clear response guidance for admins

**Impact:** CRITICAL - Personnel can signal danger while under duress/coercion.

**Files Modified:**
- `ViewsSafetyCheckInView.swift` - Added duress detection and alert system

**Documentation:** See `OFFLINE_AND_DURESS_IMPLEMENTATION.md`

---

## 🔴 CRITICAL RECOMMENDATIONS TO IMPLEMENT
## 🔴 REMAINING RECOMMENDATIONS TO IMPLEMENT

### 4. Dead Man's Switch
**Priority:** HIGH  
**Complexity:** Medium  
**Impact:** HIGH

**Problem:** If personnel is captured, injured, or killed, they can't manually trigger SOS. Organization may not know for hours.

**Solution:** Automatic alerts if personnel doesn't check in on schedule.

**Implementation:**
```swift
// Add to ServicesSafetyCheckInService.swift

private var deadManTimer: Timer?
private let maxCheckInInterval: TimeInterval = 14400 // 4 hours

func startDeadManSwitch(userId: String, userName: String, tenantId: String) {
    deadManTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
        Task {
            await self?.checkDeadManSwitch(userId, userName, tenantId)
        }
    }
}

private func checkDeadManSwitch(userId: String, userName: String, tenantId: String) async {
    guard let lastCheckIn = lastCheckIn else {
        await sendMissedCheckInAlert(severity: .warning)
        return
    }
    
    let timeSinceCheckIn = Date().timeIntervalSince(lastCheckIn.checkInTime)
    
    if timeSinceCheckIn > maxCheckInInterval {
        // CRITICAL: No check-in for too long
        await sendMissedCheckInAlert(severity: .critical)
    } else if timeSinceCheckIn > maxCheckInInterval * 0.8 {
        // WARNING: Approaching deadline
        await sendMissedCheckInAlert(severity: .warning)
    }
}

private func sendMissedCheckInAlert(severity: AlertSeverity) async {
    let alert = Alert(
        title: severity == .critical ? "🚨 PERSONNEL MISSING CHECK-IN" : "⚠️ Check-in Overdue",
        message: "\(userName) has not checked in for \(hours) hours. Last known location should be investigated.",
        priority: severity == .critical ? .critical : .high,
        type: .emergency
    )
    // Send to admins
}
```

**Benefits:**
- ✅ Automatic detection of missing personnel
- ✅ Faster emergency response
- ✅ Works even if personnel can't manually call for help

**Configuration:**
- Default: 4-hour check-in interval
- Organizations should configure based on risk level
- High-risk zones: 2-hour intervals
- Low-risk zones: 8-hour intervals

---

### 6. Enhanced SOS with Threat Categories
**Priority:** MEDIUM  
**Complexity:** Low  
**Impact:** MEDIUM

**Problem:** Generic SOS doesn't tell responders what kind of emergency. Different threats require different responses.

**Solution:** Add quick-select threat categories to SOS button.

**Implementation:**
```swift
// Add to ViewsSOSButtonView.swift

enum PanicCode: String, CaseIterable {
    case hostileFire = "Under hostile fire"
    case detained = "Detained/captured"
    case injured = "Injured, need medical"
    case compromised = "Position compromised"
    case evacuation = "Need immediate evacuation"
    case duress = "Under duress (acting under coercion)"
    
    var icon: String {
        switch self {
        case .hostileFire: return "flame.fill"
        case .detained: return "person.fill.xmark"
        case .injured: return "cross.fill"
        case .compromised: return "eye.trianglebadge.exclamationmark.fill"
        case .evacuation: return "airplane.departure"
        case .duress: return "hand.raised.fill"
        }
    }
    
    var responseGuidance: String {
        switch self {
        case .hostileFire: return "Coordinate with security. Consider evacuation."
        case .detained: return "DO NOT approach directly. Contact authorities."
        case .injured: return "Dispatch medical support to last known location."
        case .compromised: return "Monitor location. Prepare extraction if needed."
        case .evacuation: return "Immediate extraction required."
        case .duress: return "Covert monitoring only. No direct contact."
        }
    }
}

// In SOS UI:
Picker("Emergency Type", selection: $selectedPanicCode) {
    ForEach(PanicCode.allCases, id: \.self) { code in
        Label(code.rawValue, systemImage: code.icon)
    }
}

// Include in SOS alert
let alert = SOSAlert(
    // ... existing fields ...
    panicCode: selectedPanicCode,
    responseGuidance: selectedPanicCode.responseGuidance
)
```

**Benefits:**
- ✅ Responders know what kind of emergency
- ✅ Faster, more appropriate response
- ✅ Better decision-making under pressure

---

### 7. Code Words in Check-ins
**Priority:** LOW  
**Complexity:** Low  
**Impact:** MEDIUM

**Problem:** Personnel may need to communicate situation details discreetly.

**Solution:** Pre-defined phrases that have coded meanings.

**Implementation:**
```swift
// Add to ViewsSafetyCheckInView.swift

private let codeWords: [String: String] = [
    "weather is fine": "Under surveillance but safe",
    "traffic is heavy": "Checkpoint nearby, delayed",
    "road is clear": "All clear, no threats",
    "need supplies": "Running low on resources",
    "meeting scheduled": "Planning to move soon",
    "slight delay": "Minor issue, not urgent",
    "route changed": "Changed plans due to security"
]

// In UI:
Picker("Quick Status (Optional)", selection: $notes) {
    Text("None").tag("")
    ForEach(Array(codeWords.keys.sorted()), id: \.self) { phrase in
        Text(phrase).tag(phrase)
    }
}

if let meaning = codeWords[notes] {
    Text("Meaning: \(meaning)")
        .font(.caption2)
        .foregroundColor(.orange)
}
```

**Benefits:**
- ✅ Discreet communication in public
- ✅ Standardized phrases reduce confusion
- ✅ Useful at checkpoints or when monitored

---

## 🟡 OPTIONAL ENHANCEMENTS

### 8. Stealth Mode UI
**Priority:** LOW  
**Complexity:** HIGH  
**Impact:** LOW (situational)

Disguise app as innocuous weather/news app for checkpoint inspections.

**Recommendation:** Only implement if requested by users operating in extremely hostile environments where device inspection is common.

---

## 🔒 SECURITY RECOMMENDATIONS

### Enhanced Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Locations - CRITICAL SECURITY
    match /locations/{userId} {
      // Only user and their org's admins can read
      allow read: if request.auth.uid == userId ||
                    (isAdminInSameTenant(request.auth.uid, userId));
      
      // Only user can write their own location
      allow write: if request.auth.uid == userId;
    }
    
    // Emergency contacts - highly restricted
    match /users/{userId} {
      allow read: if request.auth.uid == userId ||
                    isAdminInSameTenant(request.auth.uid, userId);
      
      allow update: if request.auth.uid == userId;
    }
    
    function isAdminInSameTenant(adminId, userId) {
      let admin = get(/databases/$(database)/documents/users/$(adminId));
      let user = get(/databases/$(database)/documents/users/$(userId));
      return admin.data.tenantId == user.data.tenantId &&
             admin.data.role in ['admin', 'manager'];
    }
  }
}
```

---

## 📋 IMPLEMENTATION PRIORITY

**Phase 1 (IMMEDIATE):**
1. ✅ Emergency contact system (COMPLETE)
2. ✅ Offline location caching (COMPLETE)
3. ✅ Duress code system (COMPLETE)
4. ✅ Battery-aware tracking (COMPLETE - bonus feature)

**Phase 2 (NEXT SPRINT):**
5. Dead man's switch
6. Enhanced SOS categories

**Phase 3 (FUTURE):**
7. Code words
8. Stealth mode (if needed)

---

## 🎓 TRAINING REQUIREMENTS

Organizations must train personnel on:

1. **Duress Codes:**
   - When to use
   - Which code for which situation
   - What happens after using code
   - **CRITICAL:** Codes must remain secret

2. **Check-in Procedures:**
   - Required frequency
   - What to include
   - What triggers alerts
   - How to use code words

3. **SOS Procedures:**
   - When to trigger
   - Threat categories
   - What information to provide
   - Expected response times

4. **Battery Management:**
   - Keep device charged when possible
   - Understand reduced tracking at low battery
   - Backup power options

---

## 🚫 REMOVED FEATURES (Per User Request)

The following features were considered but **NOT implemented** per user request:

1. ❌ **Location Deletion on Logout**  
   *Reason:* Organization needs location history for accountability and incident investigation.

2. ❌ **Emergency Data Wipe**  
   *Reason:* Risk of accidental data loss outweighs benefits. Location data is protected by Firestore security rules.

---

## 📞 EMERGENCY RESPONSE GUIDELINES

### When Personnel Triggers SOS:

1. **Immediate Actions:**
   - Note exact time and location
   - Check threat category
   - Review recent check-ins and movement history
   - Contact emergency services if needed

2. **Communication:**
   - If "duress" code: DO NOT contact personnel directly
   - If "hostileFire": Coordinate with security team
   - If "injured": Dispatch medical support
   - If "detained": Contact authorities, do not approach

3. **Documentation:**
   - Log all actions taken
   - Record all communications
   - Save location history
   - Create incident report

### When Personnel Misses Check-in:

1. **After 80% of interval (e.g., 3.2 hours of 4-hour interval):**
   - Send gentle reminder notification
   - Note as "approaching deadline"

2. **After full interval (e.g., 4 hours):**
   - Escalate to admin alert
   - Attempt to contact personnel
   - Review last known location
   - Check recent activity

3. **After 2x interval (e.g., 8 hours):**
   - **CRITICAL ALERT**
   - Activate emergency response protocol
   - Contact emergency services
   - Investigate last known location
   - Notify emergency contacts

---

## 📊 METRICS TO TRACK

Monitor these metrics to evaluate effectiveness:

- Average check-in frequency
- Missed check-in incidents
- SOS triggers (real vs. false alarm)
- Duress code usage
- Battery levels at check-in
- Offline location queue size
- Response time to emergencies

---

## 🔄 NEXT STEPS

1. **Immediate:**
   - Review and approve implementation plan
   - Implement offline location caching
   - Implement duress code system
   - Test emergency contact fields

2. **This Week:**
   - Add battery-aware tracking
   - Implement dead man's switch
   - Update Firestore security rules

3. **Next Sprint:**
   - Add SOS threat categories
   - Implement code words
   - Create training materials
   - Develop emergency response SOPs

4. **Testing:**
   - Test offline caching in airplane mode
   - Verify duress codes work silently
   - Test dead man's switch timing
   - Validate battery level detection

---

**Questions or concerns? Let's discuss implementation details for each feature.**

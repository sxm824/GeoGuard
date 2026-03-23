# 🚨 Offline Location Caching & Duress Code Implementation

**Implemented:** March 6, 2026  
**Features:** Offline location queue + Silent duress alert system

---

## ✅ IMPLEMENTED FEATURES

### 1. Offline Location Caching

**Problem Solved:** Location updates are now cached locally when network connectivity fails (common in conflict zones), and automatically synced when connection returns.

**Files Modified:**
- `ServicesLocationManager.swift`

**Key Features:**
- ✅ Queues up to 100 location updates when offline
- ✅ Persists queue to disk (survives app restart)
- ✅ Auto-syncs when connectivity returns
- ✅ Batch updates for efficiency
- ✅ Flags synced locations with `wasOffline: true`

**How It Works:**

```swift
// When location update fails (offline):
1. Location is cached to offlineLocationQueue
2. Queue is saved to UserDefaults
3. User sees queuedLocationCount indicator

// When connection returns:
1. processOfflineQueue() is called automatically
2. All cached locations sent in single batch
3. Queue is cleared on successful sync
4. Disk storage is updated
```

**Published Properties:**
- `@Published var queuedLocationCount: Int` - Number of locations waiting to sync

**Usage:**
```swift
// In your UI, you can show queue status:
if locationManager.queuedLocationCount > 0 {
    Text("📦 \(locationManager.queuedLocationCount) locations queued (offline)")
        .foregroundColor(.orange)
}
```

---

### 2. Battery-Aware Location Tracking

**Bonus Feature:** Location update frequency now adapts to battery level.

**Update Intervals:**
- **> 50% battery:** Every 30 seconds (normal)
- **20-50% battery:** Every 60 seconds
- **10-20% battery:** Every 2 minutes
- **< 10% battery:** Every 5 minutes (critical battery saving)

**Benefits:**
- ✅ Extends device life in field
- ✅ Personnel can operate longer without charging
- ✅ Still tracks critical movements even at low battery

---

### 3. Duress Code System

**Problem Solved:** Personnel can now signal danger while appearing to comply with captors or hostile forces.

**Files Modified:**
- `ViewsSafetyCheckInView.swift`

**Key Features:**
- ✅ Silent detection of special codes
- ✅ NO visual feedback to user (completely covert)
- ✅ Sends CRITICAL alert to admins only
- ✅ Clear guidance for admin response

**Pre-Defined Duress Codes:**
```swift
"999"  // General duress code
"911"  // Emergency duress
"000"  // Silent duress
```

**How It Works:**

```swift
// 1. User enters duress code in "Check-in Code" field
// 2. Code is detected silently (NO UI change)
// 3. Check-in proceeds normally
// 4. AFTER check-in succeeds, silent alert is sent to admins
// 5. User sees normal success message
```

**Alert Content:**
```
🚨 DURESS ALERT - COVERT

COVERT ALERT: [Name] ([Email]) may be under duress or coercion.

The check-in appeared normal but a duress code was entered.

⚠️ CRITICAL: DO NOT contact [Name] directly - this may compromise their safety.

Last Location: [Address]
Coordinates: [Lat], [Lon]
Time: [Timestamp]
Check-in Notes: [Any notes entered]

RECOMMENDED ACTIONS:
- Monitor location discreetly
- Coordinate with security team
- Prepare discreet extraction if needed
- DO NOT send notifications to personnel's device
```

**Critical Security Features:**
1. **No visual feedback:** User sees no indication duress was detected
2. **Admin-only alerts:** Alert only goes to admins/managers in tenant
3. **System sender:** Alert appears from "Duress Detection System"
4. **Clear instructions:** Tells admins NOT to contact personnel directly
5. **Silent logging:** Logged to console but not to user's device

---

## 🔒 SECURITY CONSIDERATIONS

### Duress Code Security

**CRITICAL:** These codes must be:
- ✅ Kept confidential (shared only with personnel during private training)
- ✅ Never displayed in UI
- ✅ Never mentioned in public documentation
- ✅ Changed periodically by organization
- ✅ Different for different organizations (configurable)

**Training Requirements:**
1. Personnel must memorize codes during private briefing
2. Codes should be simple enough to remember under stress
3. Personnel must understand NO visual confirmation will appear
4. Personnel must trust the system works even without feedback

### Customizing Duress Codes

Organizations can customize codes by modifying the array:

```swift
// In SafetyCheckInView.swift
private let duressIndicators = [
    "999",  // Your organization's code
    "911",  // Emergency code
    "000"   // Silent code
]
```

**Best Practices:**
- Use 3-digit codes (easy to remember, hard to enter accidentally)
- Avoid common PINs (1234, 0000, 1111)
- Consider codes that look like normal check-in codes
- Test codes during training but not in production

---

## 📊 TESTING

### Test Offline Location Caching

1. **Simulate Offline:**
   ```
   - Enable Airplane Mode on device
   - Move to different locations
   - Watch console for "📦 Cached location offline" messages
   - Check queuedLocationCount property
   ```

2. **Simulate Reconnection:**
   ```
   - Disable Airplane Mode
   - Next location update triggers processOfflineQueue()
   - Watch console for "✅ Synced X offline locations"
   - Verify queuedLocationCount returns to 0
   ```

3. **Verify Persistence:**
   ```
   - Queue locations while offline
   - Force quit app
   - Reopen app
   - Should see "📥 Loaded X cached locations from disk"
   - Locations should sync when online
   ```

### Test Duress Code System

**⚠️ WARNING: Test in development environment only!**

1. **Test Code Detection:**
   ```
   - Go to Safety Check-in
   - Enter "999" in Check-in Code field
   - Submit check-in
   - Watch console for "🚨 Duress alert sent (COVERT)"
   ```

2. **Test Silent Operation:**
   ```
   - Verify NO visual indication appears
   - Verify success message is normal
   - Verify no special UI changes
   - User should see standard check-in success
   ```

3. **Test Admin Alert:**
   ```
   - Login as admin
   - Check Alert Center
   - Should see CRITICAL alert with duress details
   - Verify response options are appropriate
   ```

4. **Test Code Reset:**
   ```
   - Enter duress code
   - Submit check-in
   - Enter normal check-in without code
   - Verify duressMode resets to false
   ```

---

## 🚨 ADMIN RESPONSE PROTOCOL

### When Duress Alert Received

**IMMEDIATE ACTIONS:**

1. **DO NOT contact personnel directly**
   - No calls
   - No texts
   - No app notifications
   - Any contact may alert captors

2. **Assess situation:**
   - Check last known location
   - Review recent check-ins
   - Note time of duress signal
   - Check movement patterns

3. **Coordinate response:**
   - Notify security team
   - Contact local authorities if appropriate
   - Consider embassy/consulate notification
   - Prepare extraction team if available

4. **Monitor silently:**
   - Track location updates
   - Watch for additional check-ins
   - Note any changes in pattern
   - Document all observations

5. **Prepare intervention:**
   - Plan discreet verification if possible
   - Coordinate with other field personnel nearby
   - Prepare medical/security support
   - Have evacuation plan ready

**NEVER:**
- ❌ Call or text the personnel directly
- ❌ Send app notifications
- ❌ Contact personnel's emergency contact (may compromise safety)
- ❌ Approach location without security coordination
- ❌ Discuss situation on unsecured channels

---

## 📱 USER INTERFACE

### Check-in Code Field

The duress code field appears as a normal, optional field:

```
Check-in Code (Optional)
[Secure text field]
Use your organization's code if provided
```

**Design Rationale:**
- Appears completely normal
- Marked as "optional" (no pressure to enter)
- Generic help text (doesn't mention duress)
- Uses SecureField (code not visible on screen)
- No special styling or indicators

---

## 🔧 CONFIGURATION

### Offline Queue Settings

```swift
// In LocationManager.swift
private let maxQueueSize = 100  // Max locations to cache

// Adjust based on needs:
// - Higher value = more history retained when offline
// - Lower value = less storage used
// - 100 = ~24 hours of updates at 30s intervals
```

### Battery-Aware Intervals

```swift
private var adaptiveUpdateInterval: TimeInterval {
    switch batteryLevel {
    case 0..<0.10:    return 300  // 5 minutes
    case 0.10..<0.20: return 120  // 2 minutes
    case 0.20..<0.50: return 60   // 1 minute
    default:          return 30   // 30 seconds
    }
}

// Customize intervals based on:
// - Field conditions
// - Expected battery access
// - Importance of frequent updates
```

---

## 📈 METRICS & MONITORING

### Offline Queue Metrics

Monitor these in your analytics:

```
- Average queue size
- Max queue size reached
- Queue persistence failures
- Sync success rate
- Time between offline and sync
- Number of locations lost (if queue overflows)
```

### Duress Code Metrics

**SENSITIVE - Handle with care:**

```
- Number of duress alerts (by organization)
- Response time to duress alerts
- False positives (if personnel reports error)
- Admin response actions taken
- Outcomes (resolved, ongoing, etc.)
```

**Security Note:** This data is extremely sensitive and should be:
- ✅ Encrypted at rest
- ✅ Access-restricted to super admins only
- ✅ Not shared with third parties
- ✅ Purged after incident resolution
- ✅ Never used for personnel evaluation

---

## 🆘 TROUBLESHOOTING

### Offline Queue Not Working

**Symptoms:** Locations not cached when offline

**Checks:**
1. Verify `loadQueueFromDisk()` called in `init()`
2. Check UserDefaults key format: `offlineLocationQueue_{userId}`
3. Verify `saveQueueToDisk()` has write permissions
4. Check console for encoding/decoding errors

**Fix:**
```swift
// Check if queue is being populated
print("Queue size: \(offlineLocationQueue.count)")
print("Published count: \(queuedLocationCount)")
```

### Queue Not Syncing

**Symptoms:** Locations stay in queue even when online

**Checks:**
1. Verify Firestore batch commit succeeds
2. Check network connectivity
3. Verify Firestore rules allow batch writes
4. Check for timeout errors

**Fix:**
```swift
// Add timeout handling
batch.commit { error in
    if let error = error {
        print("Batch failed: \(error)")
        // Queue remains for retry
    }
}
```

### Duress Code Not Detected

**Symptoms:** Code entered but no alert sent

**Checks:**
1. Verify code exactly matches array: `"999"` not `"999 "`
2. Check `onChange` modifier is triggering
3. Verify `duressMode` is set to `true`
4. Check `sendDuressAlert()` is called after check-in succeeds

**Debug:**
```swift
.onChange(of: checkInCode) { oldValue, newValue in
    print("Code entered: '\(newValue)'")
    print("Duress codes: \(duressIndicators)")
    print("Match: \(duressIndicators.contains(newValue))")
}
```

### Duress Alert Not Silent

**Symptoms:** User sees indication of duress detection

**Critical Fix Required:**
- Remove ANY visual feedback
- Remove ANY notifications to user
- Check no alerts sent to personnel's device
- Verify `recipientIds: []` (only admins)

---

## 🔄 FUTURE ENHANCEMENTS

### Configurable Duress Codes

Allow organizations to set custom codes:

```swift
// Fetch from Firestore
private var duressIndicators: [String] {
    // Fetch from tenant settings
    return tenantSettings.duressCodes ?? ["999", "911", "000"]
}
```

### Multi-Level Duress

Different codes for different threat levels:

```swift
enum DuressLevel {
    case monitoring      // "999" - Under surveillance
    case detained        // "911" - Detained/captured
    case immediateDanger // "000" - Life-threatening
}
```

### Duress Code Expiry

Rotate codes automatically:

```swift
// Check if code is current
func isValidDuressCode(_ code: String) -> Bool {
    guard let lastRotation = tenantSettings.duressCodeRotationDate else {
        return duressIndicators.contains(code)
    }
    
    // Codes older than 30 days are invalid
    let daysSinceRotation = Calendar.current.dateComponents([.day], from: lastRotation, to: Date()).day ?? 0
    return daysSinceRotation < 30 && duressIndicators.contains(code)
}
```

---

## 📋 DEPLOYMENT CHECKLIST

Before deploying to production:

- [ ] Offline queue tested in airplane mode
- [ ] Queue persistence verified (app restart)
- [ ] Batch sync tested with multiple locations
- [ ] Battery monitoring tested on device
- [ ] Duress codes tested in development
- [ ] Admin alerts verified (correct recipients)
- [ ] Silent operation confirmed (no user feedback)
- [ ] Response protocol documented
- [ ] Security team trained on duress response
- [ ] Codes distributed to personnel (private training)
- [ ] Firestore rules updated (allow batch writes)
- [ ] Analytics/monitoring configured
- [ ] Incident response plan ready

---

## 📞 SUPPORT

### For Implementation Questions:
Review this guide and test in development environment.

### For Security Concerns:
Contact security team immediately if:
- Duress codes may be compromised
- Alert system fails during real incident
- Personnel unable to use duress system

### For Incidents:
Follow emergency response protocol in WAR_ZONE_SAFETY_RECOMMENDATIONS.md

---

**Remember: Lives depend on these systems working correctly. Test thoroughly before deployment.**

# 📱 Device Testing Checklist for GeoGuard

**Testing Date:** _____________  
**Device:** _____________  
**iOS Version:** _____________  
**Tester:** _____________

---

## ✅ PRE-TESTING SETUP

### 1. Info.plist Configuration
Verify these keys exist in your Info.plist:

- [ ] `NSLocationAlwaysAndWhenInUseUsageDescription`
- [ ] `NSLocationWhenInUseUsageDescription`
- [ ] `UIBackgroundModes` with `location` and `fetch`
- [ ] `Privacy - Notifications Usage Description` (optional but recommended)

**To check:** Open your project → Target → Info tab → Custom iOS Target Properties

### 2. Xcode Settings
- [ ] Physical device connected and selected
- [ ] Signing & Capabilities configured with valid Team
- [ ] Background Modes capability enabled with "Location updates" checked
- [ ] Push Notifications capability enabled (if using remote notifications)
- [ ] Clean build folder (Product → Clean Build Folder)
- [ ] Build succeeds without errors

### 3. Device Preparation
- [ ] Device has cellular data or Wi-Fi
- [ ] Device is logged into iCloud (for some location features)
- [ ] Device battery > 20% for initial testing
- [ ] Remove any previous installations of GeoGuard

---

## 🧪 CORE FUNCTIONALITY TESTS

### Authentication
- [ ] Launch app on device
- [ ] Register new company (tenant)
- [ ] Log out
- [ ] Log in with created account
- [ ] Verify role-based routing (Admin sees admin view, Driver sees dashboard)

### Location Permissions
- [ ] App requests location permission on first use
- [ ] Grant "While Using" first (test incremental permission flow)
- [ ] App should show prompt or alert to upgrade to "Always Allow"
- [ ] Change to "Always Allow" in Settings
- [ ] Verify `authorizationStatus` updates correctly

---

## 🎯 TRACKING RELIABILITY MONITOR TESTS

### Initial Startup
- [ ] Start tracking from Driver Dashboard
- [ ] Verify green "Tracking Active" indicator appears
- [ ] Check Xcode console for: `🔍 Starting tracking reliability monitoring`
- [ ] Wait 1 minute, verify health check runs (console logs)

### Low Power Mode Detection
- [ ] Enable Low Power Mode (Settings → Battery → Low Power Mode)
- [ ] Wait up to 1 minute for health check
- [ ] Verify red reliability banner appears with "Low Power Mode enabled"
- [ ] Check for notification: "Location Tracking Issue"
- [ ] Disable Low Power Mode
- [ ] Verify banner disappears and console shows: `✅ Tracking reliability restored`

### Background App Refresh Detection
- [ ] Go to Settings → General → Background App Refresh
- [ ] Disable Background App Refresh entirely
- [ ] Return to GeoGuard
- [ ] Wait up to 1 minute
- [ ] Verify reliability banner shows "Background App Refresh disabled"
- [ ] Re-enable Background App Refresh
- [ ] Verify issue clears

### Permission Downgrade Detection
- [ ] While tracking, go to Settings → Privacy & Security → Location Services → GeoGuard
- [ ] Change from "Always" to "While Using App"
- [ ] Return to app
- [ ] Wait up to 1 minute
- [ ] Verify banner shows "Location permission not set to 'Always'"
- [ ] Change back to "Always"
- [ ] Verify issue clears

### Offline Queue Detection
*Note: This requires simulating 50+ queued locations - may need code modification for testing*
- [ ] Enable Airplane Mode
- [ ] Let app run for several minutes (locations queue up)
- [ ] Check console for queue size
- [ ] Verify banner appears if queue > 50
- [ ] Disable Airplane Mode
- [ ] Verify queue syncs and issue clears

---

## 📍 LOCATION TRACKING TESTS

### Foreground Tracking
- [ ] Start tracking
- [ ] Verify location updates in console (every ~30 seconds)
- [ ] Check Firebase Console → `user_locations` collection
- [ ] Verify documents are being created with correct data:
  - userId
  - tenantId
  - latitude/longitude
  - timestamp
  - batteryLevel
  - speed, accuracy, altitude, heading

### Background Tracking
- [ ] Start tracking
- [ ] Press Home button (background app)
- [ ] Wait 2-3 minutes
- [ ] Check Firebase for new location documents
- [ ] Verify timestamps show background updates occurred
- [ ] Verify console shows: `📍 Sent app heartbeat to Firestore (background)`

### Location Updates After Lock
- [ ] Start tracking
- [ ] Lock device (press side/top button)
- [ ] Wait 5 minutes
- [ ] Unlock and check Firebase
- [ ] Verify location updates continued while locked

### App Termination
- [ ] Start tracking
- [ ] Swipe up and force-quit app
- [ ] Check Firebase for final location with `appState: terminating`
- [ ] Relaunch app
- [ ] Verify tracking resumes if it was active before

---

## 🔋 BATTERY-AWARE BEHAVIOR

### High Battery (> 50%)
- [ ] Charge device above 50%
- [ ] Start tracking
- [ ] Verify updates every ~30 seconds (check console timestamps)

### Medium Battery (20-50%)
- [ ] Drain battery to ~40%
- [ ] Verify update interval increases to ~60 seconds

### Low Battery (10-20%)
- [ ] Drain battery to ~15%
- [ ] Verify update interval increases to ~120 seconds

### Critical Battery (< 10%)
- [ ] Drain battery to ~8%
- [ ] Verify update interval increases to ~300 seconds (5 min)

---

## 🔔 NOTIFICATION TESTS

### Permission Request
- [ ] On first notification trigger, verify permission alert appears
- [ ] Tap "Allow"
- [ ] Verify permission granted

### Issue Notifications
- [ ] Trigger a tracking issue (e.g., enable Low Power Mode)
- [ ] Background the app
- [ ] Wait 1 minute
- [ ] Verify notification appears on lock screen
- [ ] Tap notification → app should open

### Cooldown Period
- [ ] Trigger issue
- [ ] Wait for notification (note time)
- [ ] Keep issue active (don't fix it)
- [ ] Verify NO second notification within 5 minutes
- [ ] After 5 minutes, verify another notification can be sent

---

## 🔄 OFFLINE & SYNC TESTS

### Offline Queueing
- [ ] Enable Airplane Mode
- [ ] Start tracking
- [ ] Move around or wait for location updates
- [ ] Check console for: `📦 Queued location for offline sync`
- [ ] Verify `queuedLocationCount` increases
- [ ] Verify queue saved to disk (console logs)

### Online Sync
- [ ] Disable Airplane Mode
- [ ] Verify console shows: `🔄 Processing offline queue`
- [ ] Verify `✅ Synced X locations from offline queue`
- [ ] Check Firebase - all queued locations should appear
- [ ] Verify `queuedLocationCount` returns to 0

---

## 🎨 UI/UX TESTS

### Status Indicators
- [ ] `LocationStatusView` shows correct status:
  - "Not Tracking" (gray) when idle
  - "Tracking Active" (green) when tracking
  - Permission warnings when not "Always"
- [ ] "Synced X ago" updates regularly
- [ ] Battery level displays correctly
- [ ] Queued location count displays when offline

### Reliability Banner
- [ ] Only appears when actual issues detected
- [ ] Shows specific error message
- [ ] "Fix in Settings" button opens Settings app
- [ ] Banner is RED and prominent
- [ ] Disappears when issue resolved

### Driver Dashboard
- [ ] Start/Stop Tracking button toggles correctly
- [ ] Button text changes: "Start Tracking" ↔ "Stop Tracking"
- [ ] Map shows current location (if Maps configured)
- [ ] No crashes or UI glitches

---

## 📊 FIREBASE VERIFICATION

### Collections to Check
1. **`user_locations`**
   - [ ] Documents created during tracking
   - [ ] All required fields present
   - [ ] Timestamps are recent and accurate

2. **`tracking_issues`**
   - [ ] Documents created when issues detected
   - [ ] Contains correct issue descriptions
   - [ ] Battery level and device state captured

3. **`app_heartbeats`**
   - [ ] Documents created when app backgrounds
   - [ ] `appState` field shows "background" or "terminating"
   - [ ] Timestamps align with app state changes

### Security Rules
- [ ] Non-admin users can only read their own locations
- [ ] Non-admin users can only read their tenant's data
- [ ] Admin users have appropriate elevated permissions

---

## 🐛 KNOWN ISSUES TO WATCH FOR

### Potential Problems
- [ ] Notifications not appearing → Check permissions in Settings
- [ ] Background tracking stops → Verify Background Modes capability
- [ ] Locations not syncing → Check internet connection and Firebase rules
- [ ] High battery drain → Verify adaptive update intervals working
- [ ] App crashes on permission changes → Check console for errors

### Console Messages to Monitor
✅ **Good Signs:**
```
🔍 Starting tracking reliability monitoring
📍 Location tracking started
✅ Location synced to Firestore
✅ Tracking reliability restored
```

❌ **Warning Signs:**
```
⚠️ Tracking reliability issues detected
❌ Failed to sync location
❌ Failed to log reliability issue
❌ Failed to send reliability notification
```

---

## 📝 TESTING NOTES

### Issues Found:
_____________________________________________
_____________________________________________
_____________________________________________

### Performance Observations:
_____________________________________________
_____________________________________________
_____________________________________________

### Battery Impact:
_____________________________________________
_____________________________________________
_____________________________________________

### User Experience Feedback:
_____________________________________________
_____________________________________________
_____________________________________________

---

## ✅ FINAL SIGN-OFF

- [ ] All critical tests passed
- [ ] No crashes or major bugs
- [ ] Battery impact is acceptable
- [ ] Notifications working correctly
- [ ] Background tracking reliable
- [ ] Firebase data syncing properly
- [ ] UI is responsive and clear

**Ready for Production:** ☐ Yes  ☐ No  ☐ Needs Work

**Notes:**
_____________________________________________
_____________________________________________
_____________________________________________


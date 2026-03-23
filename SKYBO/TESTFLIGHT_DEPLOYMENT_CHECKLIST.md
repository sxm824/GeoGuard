# ✅ Pre-TestFlight Deployment Checklist

**Date:** March 6, 2026  
**Build:** GeoGuard v1.0  
**Target:** TestFlight Beta Testing

---

## 🔧 CODE COMPILATION

### Fixed Issues:
- [x] ✅ `TrackingReliabilityMonitor` ObservableObject conformance fixed
- [x] ✅ Removed `@MainActor` from class declaration
- [x] ✅ Added `@MainActor` to specific methods that need main thread
- [x] ✅ Added `FirebaseFirestore` import to SafetyCheckInView

### Verify Build:
- [ ] **Clean Build Folder** (Cmd + Shift + K)
- [ ] **Build Project** (Cmd + B)
- [ ] **Fix any warnings**
- [ ] **Fix any errors**
- [ ] **Run on Simulator** - Test basic functionality
- [ ] **Run on Physical Device** - Test location features

---

## 📋 REQUIRED: Info.plist Configuration

### Background Modes (CRITICAL):
Add these to enable background tracking:

**Target → Signing & Capabilities → + Capability → Background Modes**

Enable:
- [ ] ✅ **Location updates**
- [ ] ✅ **Background fetch** (if using)
- [ ] ✅ **Remote notifications** (for silent push)

### Privacy Descriptions (REQUIRED):
Verify these keys exist in Info.plist:

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>GeoGuard needs your location to keep you safe in high-risk environments. Your team can see your location for emergency response coordination.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>GeoGuard needs your location to keep you safe.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>GeoGuard needs continuous access to your location for safety tracking, even when the app is in the background.</string>

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

**Verification:**
- [ ] Location descriptions are clear and explain war zone safety use
- [ ] Background modes array includes "location"
- [ ] Descriptions comply with App Store guidelines

---

## 🔐 FIREBASE CONFIGURATION

### Firestore Security Rules:
- [ ] Deploy updated rules that include:
  - `locations` collection rules
  - `app_heartbeats` collection rules
  - `tracking_issues` collection rules
  - `check_ins` collection rules
  - `alerts` collection rules

### Firebase Console Checklist:
- [ ] GoogleService-Info.plist is up to date
- [ ] Authentication enabled (Email/Password)
- [ ] Firestore database created
- [ ] Indexes created if needed
- [ ] Cloud Functions deployed (if any)

---

## 🧪 FEATURE TESTING CHECKLIST

### Emergency Contact System:
- [ ] Signup requires emergency contact
- [ ] Phone validation works
- [ ] Blood type saved correctly
- [ ] Emergency contact displayed in profile

### Offline Location Caching:
- [ ] Enable airplane mode
- [ ] Locations queued correctly
- [ ] Queue count shows in UI
- [ ] Disable airplane mode → locations sync
- [ ] Console shows "✅ Synced X offline locations"
- [ ] Queue clears after sync

### Battery-Aware Tracking:
- [ ] Battery level displays correctly
- [ ] Warning shows when < 20%
- [ ] Critical warning when < 10%
- [ ] Update interval adjusts based on battery
- [ ] Console shows interval changes

### Duress Code System:
**⚠️ CRITICAL - Test in DEV only!**
- [ ] Enter "999" in check-in code field
- [ ] NO visual indication appears
- [ ] Check-in succeeds normally
- [ ] Console shows "🚨 Duress alert sent"
- [ ] Login as admin → verify CRITICAL alert received
- [ ] Alert has correct location and details

### Background Tracking Reliability:
- [ ] Enable Low Power Mode → Red banner appears
- [ ] Disable Background App Refresh → Warning shows
- [ ] App goes to background → Heartbeat sent
- [ ] Force quit → App state marked "terminated"
- [ ] Reliability monitor checks every minute
- [ ] Notification sent when issues detected

### Status Indicators:
- [ ] Offline banner shows when disconnected
- [ ] Battery warning shows when low
- [ ] Last sync time displays and updates
- [ ] Reliability banner shows issues
- [ ] "Fix" button opens Settings

---

## 📱 DEVICE TESTING

### Test on Multiple Devices:
- [ ] iPhone (newer model with Dynamic Island if possible)
- [ ] iPhone (older model)
- [ ] iPad (if supported)

### Test iOS Versions:
- [ ] iOS 17.x (latest)
- [ ] iOS 16.x (if supporting)

### Location Scenarios:
- [ ] Indoor (building)
- [ ] Outdoor (clear sky)
- [ ] Moving (walking/driving)
- [ ] Stationary
- [ ] Poor GPS signal
- [ ] No network connection

---

## 🔒 SECURITY VERIFICATION

### Authentication:
- [ ] Sign up works
- [ ] Login works
- [ ] Password reset works
- [ ] Session management works
- [ ] Auto-logout on error

### Authorization:
- [ ] Field personnel can only see their own data
- [ ] Admins can see all tenant personnel
- [ ] Cross-tenant access blocked
- [ ] Invitation validation works

### Data Privacy:
- [ ] Location data encrypted in transit (HTTPS/Firestore)
- [ ] Emergency contact data secured
- [ ] Duress codes not exposed in logs
- [ ] Sensitive data not in console output

---

## 📚 DOCUMENTATION

### User-Facing:
- [ ] README updated
- [ ] Help screens accessible
- [ ] Error messages clear
- [ ] Training materials ready

### Admin Documentation:
- [ ] Duress code training guide (CLASSIFIED)
- [ ] Emergency response protocol
- [ ] System health monitoring guide
- [ ] Firestore collections documented

---

## 🚀 TESTFLIGHT PREPARATION

### App Store Connect:
- [ ] App created in App Store Connect
- [ ] Bundle ID matches
- [ ] Version number set (e.g., 1.0)
- [ ] Build number incremented
- [ ] Screenshots prepared
- [ ] App description written
- [ ] Keywords set
- [ ] Support URL provided
- [ ] Privacy policy URL provided

### Archive & Upload:
1. [ ] Select "Any iOS Device (arm64)" scheme
2. [ ] Product → Archive
3. [ ] Validate App
4. [ ] Distribute App → App Store Connect
5. [ ] Upload to TestFlight

### TestFlight Configuration:
- [ ] Beta App Description written
- [ ] Test Information provided
- [ ] Export Compliance answered
- [ ] Internal Testing group created
- [ ] Testers invited

---

## 👥 BETA TESTING PLAN

### Internal Testers (Week 1):
- [ ] Development team (3-5 people)
- [ ] Test all features
- [ ] Focus on reliability
- [ ] Check crash logs

### External Beta (Week 2-3):
- [ ] Select 10-20 trusted users
- [ ] Mix of roles (admins, personnel)
- [ ] Different locations/scenarios
- [ ] Collect feedback

### Metrics to Monitor:
- [ ] Crash rate (target: < 1%)
- [ ] Location tracking reliability
- [ ] Offline queue performance
- [ ] Battery impact
- [ ] User feedback
- [ ] Duress code false positives

---

## ⚠️ CRITICAL WARNINGS FOR TESTERS

### Beta Test Instructions:

**For All Testers:**
```
CRITICAL SAFETY NOTICE:

This is BETA software for life safety in war zones.

DO NOT use as sole safety system yet.
DO NOT test in actual hostile environments.
DO TEST all features thoroughly in safe areas.

Report all issues immediately.
```

**For Duress Code Testing:**
```
CLASSIFIED - AUTHORIZED TESTERS ONLY

Duress codes for testing: 999, 911, 000

ONLY test in development environment.
NEVER use in production.
NEVER share codes publicly.

Codes will change before production release.
```

---

## 📊 SUCCESS CRITERIA

### Minimum Requirements for Production:
- [ ] **Zero critical bugs**
- [ ] **Crash rate < 1%**
- [ ] **Location tracking reliability > 95%**
- [ ] **Battery drain < 10% per hour of tracking**
- [ ] **Offline sync success rate > 98%**
- [ ] **User satisfaction > 4.0/5.0**
- [ ] **All security tests passed**

---

## 🔄 POST-UPLOAD STEPS

After uploading to TestFlight:

1. **Wait for Processing** (10-30 minutes)
2. **Check for Processing Errors**
3. **Complete Export Compliance**
4. **Add Build to Internal Testing**
5. **Invite Internal Testers**
6. **Monitor Crash Reports**
7. **Review Feedback**
8. **Iterate and Fix Issues**

---

## 🐛 KNOWN ISSUES (Document Here)

### Non-Critical Issues:
- [ ] List any known bugs that won't block release
- [ ] Plan for fixes in next version

### To Be Monitored:
- [ ] Battery impact on specific devices
- [ ] Network performance in poor conditions
- [ ] UI performance with many personnel

---

## 📞 SUPPORT PLAN

### During Beta:
- **Primary Contact:** [Your email/Slack]
- **Response Time:** < 4 hours for critical issues
- **Bug Tracking:** [GitHub Issues / JIRA / etc.]
- **Feedback Channel:** [TestFlight feedback / Form / etc.]

### Emergency Protocol:
If critical security issue discovered:
1. Immediately revoke beta build
2. Notify all testers
3. Fix issue
4. Re-release with security patch
5. Document incident

---

## ✅ FINAL SIGN-OFF

**Before Submitting to TestFlight:**

I confirm that:
- [ ] All compilation errors fixed
- [ ] All critical features tested
- [ ] Info.plist configured correctly
- [ ] Firebase properly configured
- [ ] Security review completed
- [ ] Documentation ready
- [ ] Beta testers identified
- [ ] Support plan in place

**Submitted By:** _________________  
**Date:** _________________  
**Build Number:** _________________  
**Notes:** _________________

---

## 🎯 READY TO DEPLOY?

If all checkboxes above are checked:

### ✅ YES - READY FOR TESTFLIGHT
Proceed with archive and upload.

### ❌ NO - NOT READY
Review unchecked items and complete before deploying.

---

**This is a life-safety application. Do not rush deployment. Test thoroughly.**

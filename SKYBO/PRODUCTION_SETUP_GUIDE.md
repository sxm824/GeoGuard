# GeoGuard - Production Firebase & Technical Setup Guide

## 🔥 Firebase Production Setup

### 1. Create Production Firebase Project

**Steps:**
1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Name: `GeoGuard-Production`
4. Enable Google Analytics (recommended)
5. Click "Create Project"

---

### 2. Add iOS App to Firebase

**In Firebase Console:**
1. Click "Add app" → iOS
2. **iOS bundle ID**: `com.yourcompany.geoguard` (must match Xcode)
3. **App nickname**: GeoGuard iOS Production
4. **App Store ID**: Leave blank for now (add after first release)
5. Download `GoogleService-Info.plist`
6. Add to Xcode project (drag into project, ensure "Copy items if needed" is checked)

**⚠️ IMPORTANT**: Never commit your production `GoogleService-Info.plist` to public repos!

---

### 3. Enable Firebase Authentication

**In Firebase Console → Authentication:**

1. Click "Get started"
2. **Sign-in method** tab → Enable:
   - ✅ Email/Password
   - Optional: Google Sign-In (for future)
   - Optional: Apple Sign-In (recommended for iOS)

**Configure Email Templates:**
- Go to **Templates** tab
- Customize:
  - Email verification template
  - Password reset template
  - Email change verification
- Set **Action URL**: `https://www.geoguard-app.com`

---

### 4. Set Up Firestore Database

**In Firebase Console → Firestore Database:**

1. Click "Create database"
2. **Location**: Choose closest to your users
   - Recommended: `us-central` (US), `europe-west` (EU), `asia-northeast` (Asia)
   - ⚠️ **Cannot be changed later!**
3. **Security rules**: Start in **production mode** (we'll add custom rules next)
4. Click "Enable"

**Create Collections:**

Your app will auto-create these, but you can create indexes manually:

**Collections needed:**
- `users` - User profiles and roles
- `locations` - Real-time GPS locations
- `invitations` - Invitation codes
- `alerts` - Team alerts
- `checkIns` - Safety check-ins
- `incidents` - Incident reports
- `tenants` - Organization/tenant data

---

### 5. Deploy Firestore Security Rules

**Copy this to Firestore Rules tab:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ===== HELPER FUNCTIONS =====
    
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isUser(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function getTenantId() {
      return getUserData().tenantId;
    }
    
    function getUserRole() {
      return getUserData().role;
    }
    
    function isAdmin() {
      return getUserRole() in ['admin', 'super_admin'];
    }
    
    function isManager() {
      return getUserRole() in ['admin', 'super_admin', 'manager'];
    }
    
    function isSameTenant(tenantId) {
      return isSignedIn() && tenantId == getTenantId();
    }
    
    // ===== USERS COLLECTION =====
    
    match /users/{userId} {
      // Users can read their own profile
      // Users can read other users in same tenant
      allow read: if isSignedIn() && 
                    (isUser(userId) || 
                     isSameTenant(resource.data.tenantId));
      
      // Anyone can create their own user (sign up)
      allow create: if isSignedIn() && isUser(userId);
      
      // Users can update their own profile
      // Admins can update any user in their tenant
      allow update: if isUser(userId) || 
                      (isAdmin() && isSameTenant(resource.data.tenantId));
      
      // Only admins can delete users in their tenant
      allow delete: if isAdmin() && isSameTenant(resource.data.tenantId);
    }
    
    // ===== LOCATIONS COLLECTION =====
    
    match /locations/{userId} {
      // Users in same tenant can read locations
      allow read: if isSignedIn() && isSameTenant(resource.data.tenantId);
      
      // Users can write their own location
      // Admins can write any location in their tenant
      allow write: if isSignedIn() && 
                     (isUser(userId) || 
                      (isAdmin() && isSameTenant(request.resource.data.tenantId)));
    }
    
    // ===== INVITATIONS COLLECTION =====
    
    match /invitations/{invitationId} {
      // Anyone signed in can read invitations (to use invitation codes)
      allow read: if isSignedIn();
      
      // Only admins can create/update/delete invitations in their tenant
      allow create: if isAdmin() && isSameTenant(request.resource.data.tenantId);
      allow update: if isAdmin() && isSameTenant(resource.data.tenantId);
      allow delete: if isAdmin() && isSameTenant(resource.data.tenantId);
    }
    
    // ===== ALERTS COLLECTION =====
    
    match /alerts/{alertId} {
      // Users in same tenant can read alerts
      allow read: if isSignedIn() && isSameTenant(resource.data.tenantId);
      
      // Admins and managers can create/update/delete alerts
      allow write: if isManager() && isSameTenant(request.resource.data.tenantId);
    }
    
    // ===== CHECK-INS COLLECTION =====
    
    match /checkIns/{checkInId} {
      // Users in same tenant can read check-ins
      allow read: if isSignedIn() && isSameTenant(resource.data.tenantId);
      
      // Users can create their own check-ins
      allow create: if isSignedIn() && 
                      isUser(request.resource.data.userId) &&
                      isSameTenant(request.resource.data.tenantId);
      
      // Users can update their own check-ins
      // Admins can update any check-in in their tenant
      allow update: if isUser(resource.data.userId) || 
                      (isAdmin() && isSameTenant(resource.data.tenantId));
      
      // Only admins can delete check-ins
      allow delete: if isAdmin() && isSameTenant(resource.data.tenantId);
    }
    
    // ===== INCIDENTS COLLECTION =====
    
    match /incidents/{incidentId} {
      // Users in same tenant can read incidents
      allow read: if isSignedIn() && isSameTenant(resource.data.tenantId);
      
      // Any user can create incidents
      allow create: if isSignedIn() && isSameTenant(request.resource.data.tenantId);
      
      // Admins and incident creator can update
      allow update: if isUser(resource.data.reportedBy) || 
                      (isAdmin() && isSameTenant(resource.data.tenantId));
      
      // Only admins can delete incidents
      allow delete: if isAdmin() && isSameTenant(resource.data.tenantId);
    }
    
    // ===== TENANTS COLLECTION =====
    
    match /tenants/{tenantId} {
      // Users can read their own tenant
      allow read: if isSignedIn() && isSameTenant(tenantId);
      
      // Only admins can update their tenant
      allow update: if isAdmin() && isSameTenant(tenantId);
      
      // Tenant creation handled by Cloud Functions or admin
      allow create: if isSignedIn(); // First user creates tenant
      
      // Only super admins can delete tenants
      allow delete: if getUserRole() == 'super_admin' && isSameTenant(tenantId);
    }
    
    // ===== DEFAULT DENY =====
    // Any collection not explicitly allowed above is denied
  }
}
```

**Click "Publish" to deploy these rules.**

**⚠️ Test your rules!** Use the Rules Playground tab to verify:
- Users can only access their tenant data
- Admins have proper permissions
- Field personnel can't access admin features

---

### 6. Create Firestore Indexes

**Composite Indexes Needed:**

Go to **Firestore → Indexes → Composite** tab and create:

**1. Users by Tenant and Role**
```
Collection: users
Fields: 
  - tenantId (Ascending)
  - role (Ascending)
  - createdAt (Descending)
```

**2. Users by Tenant and Active Status**
```
Collection: users
Fields:
  - tenantId (Ascending)
  - isActive (Ascending)
  - createdAt (Descending)
```

**3. Locations by Tenant**
```
Collection: locations
Fields:
  - tenantId (Ascending)
  - timestamp (Descending)
```

**4. Invitations by Tenant and Status**
```
Collection: invitations
Fields:
  - tenantId (Ascending)
  - isUsed (Ascending)
  - expiresAt (Descending)
```

**5. Alerts by Tenant and Priority**
```
Collection: alerts
Fields:
  - tenantId (Ascending)
  - priority (Ascending)
  - createdAt (Descending)
```

**6. Check-ins by User and Date**
```
Collection: checkIns
Fields:
  - userId (Ascending)
  - tenantId (Ascending)
  - checkInTime (Descending)
```

**7. Incidents by Tenant and Status**
```
Collection: incidents
Fields:
  - tenantId (Ascending)
  - status (Ascending)
  - reportedAt (Descending)
```

**Note**: Firestore will prompt you to create indexes when needed. You can also create them via the error messages in your Xcode console.

---

### 7. Enable Firebase Cloud Messaging (Push Notifications)

**Upload APNs Certificate:**

1. **Generate APNs Key in Apple Developer:**
   - Go to https://developer.apple.com/account
   - Certificates, Identifiers & Profiles
   - Keys → Click "+" to create new key
   - Name: GeoGuard Push Notifications
   - Check "Apple Push Notifications service (APNs)"
   - Click "Continue" → "Register"
   - Download `.p8` file (save securely, can't re-download!)
   - Note the **Key ID** and **Team ID**

2. **Upload to Firebase:**
   - Firebase Console → Project Settings → Cloud Messaging
   - Under "APNs Certificates"
   - Click "Upload" for APNs Authentication Key
   - Upload your `.p8` file
   - Enter **Key ID** and **Team ID**
   - Click "Upload"

---

### 8. Configure Firebase Analytics (Optional but Recommended)

**In Firebase Console → Analytics:**

1. **Enable Google Analytics**: Should be on by default
2. **Events to track** (auto-tracked):
   - `screen_view` - Screen navigation
   - `app_open` - App launches
   - `session_start` - User sessions

3. **Custom events to add in your app** (for future):
   - `sos_triggered`
   - `check_in_completed`
   - `incident_reported`
   - `invitation_created`
   - `team_member_tracked`

---

### 9. Enable Firebase Crashlytics

**Setup:**

1. In Xcode, add Firebase Crashlytics:
   - File → Add Packages
   - Search: `https://github.com/firebase/firebase-ios-sdk`
   - Add `FirebaseCrashlytics` product

2. In `AppDelegate.swift`, add:
```swift
import FirebaseCrashlytics

func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
    return true
}
```

3. Add Run Script in Xcode:
   - Target → Build Phases → "+" → New Run Script Phase
   - Add: `"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"`

---

### 10. Set Up Firebase Performance Monitoring (Optional)

**Add to Podfile or SPM:**
```
FirebasePerformance
```

**Track custom traces:**
```swift
let trace = Performance.startTrace(name: "location_update")
// Your code
trace?.stop()
```

---

## 🗺️ Google Maps API Setup

### 1. Create Google Cloud Project

1. Go to https://console.cloud.google.com
2. Create new project: "GeoGuard Production"
3. Enable billing (required for Maps)

### 2. Enable Required APIs

**In Google Cloud Console → APIs & Services → Library:**

Enable these APIs:
- ✅ Maps SDK for iOS
- ✅ Places API
- ✅ Geocoding API (for address lookup)
- ✅ Geolocation API (optional, for WiFi/cell location)

### 3. Create API Key

**In APIs & Services → Credentials:**

1. Click "Create Credentials" → "API key"
2. Copy the API key
3. Click "Restrict Key"

**Configure Restrictions:**

**Application restrictions:**
- Select: "iOS apps"
- Add bundle identifier: `com.yourcompany.geoguard`

**API restrictions:**
- Select: "Restrict key"
- Choose:
  - Maps SDK for iOS
  - Places API
  - Geocoding API

4. Click "Save"

### 4. Add to Your App

**In AppDelegate.swift:**
```swift
import GoogleMaps

func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Configure Firebase
    FirebaseApp.configure()
    
    // Configure Google Maps
    GMSServices.provideAPIKey("YOUR_PRODUCTION_API_KEY_HERE")
    
    return true
}
```

**⚠️ Security:** Store API key securely:
- Use `.xcconfig` file for sensitive data
- Add to `.gitignore`
- Or use build-time configuration

---

## 🔐 Security Checklist

### API Keys & Secrets

- [ ] Production Firebase project created
- [ ] `GoogleService-Info.plist` added to project
- [ ] `GoogleService-Info.plist` added to `.gitignore`
- [ ] Google Maps API key created
- [ ] API key properly restricted (iOS bundle ID)
- [ ] API key APIs restricted (only needed APIs)
- [ ] APNs key uploaded to Firebase

### Firestore

- [ ] Security rules deployed
- [ ] Security rules tested in playground
- [ ] Composite indexes created
- [ ] Data retention policies configured

### Authentication

- [ ] Email/Password enabled
- [ ] Email templates customized
- [ ] Action URL configured
- [ ] Optional: Apple Sign-In enabled

---

## 📊 Monitoring & Alerts

### Set Up Budget Alerts

**In Google Cloud Console → Billing:**

1. Create budget alerts at:
   - 50% of expected usage
   - 90% of expected usage
   - 100% of expected usage

2. Recommended monthly budget:
   - **Starter**: $50-100/month
   - **Growing**: $200-500/month
   - **Enterprise**: $500+/month

### Firebase Usage Alerts

**In Firebase Console → Usage:**

Monitor:
- Firestore reads/writes
- Authentication users
- Cloud Storage (if using)
- Functions invocations (if using)

---

## 🧪 Testing Production Setup

### Test Checklist

**Firebase Authentication:**
```swift
// Test sign up
try await Auth.auth().createUser(withEmail: "test@test.com", password: "Test123!")

// Test sign in
try await Auth.auth().signIn(withEmail: "test@test.com", password: "Test123!")

// Verify user created in Firebase Console
```

**Firestore Security:**
```swift
// Test writing to Firestore
let db = Firestore.firestore()
try await db.collection("users").document(userId).setData([
    "email": "test@test.com",
    "tenantId": "test-tenant",
    "role": "admin"
])

// Verify data appears in Firestore Console
```

**Location Updates:**
```swift
// Test location tracking
let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
try await db.collection("locations").document(userId).setData([
    "latitude": location.coordinate.latitude,
    "longitude": location.coordinate.longitude,
    "timestamp": FieldValue.serverTimestamp()
])
```

**Google Maps:**
```swift
// Test map display
let camera = GMSCameraPosition.camera(
    withLatitude: 37.7749,
    longitude: -122.4194,
    zoom: 15
)
let mapView = GMSMapView(frame: .zero, camera: camera)
// Verify map displays correctly
```

**Push Notifications:**
```swift
// Test FCM token registration
Messaging.messaging().token { token, error in
    if let token = token {
        print("FCM Token: \(token)")
        // Save to Firestore
    }
}
```

---

## 🚀 Go-Live Checklist

### Pre-Launch

- [ ] All tests passing
- [ ] No console errors or warnings
- [ ] Firebase security rules deployed
- [ ] Firestore indexes created
- [ ] Google Maps displaying correctly
- [ ] Push notifications working
- [ ] Location tracking functioning
- [ ] Authentication flow smooth
- [ ] Data isolation verified (tenant separation)

### Launch Day

- [ ] Monitor Firebase Console for errors
- [ ] Watch Crashlytics for crashes
- [ ] Monitor Google Cloud costs
- [ ] Check user feedback
- [ ] Respond to support emails quickly

### Post-Launch

- [ ] Weekly analytics review
- [ ] Monthly cost analysis
- [ ] Security rules audit
- [ ] Performance optimization
- [ ] User feedback implementation

---

## 📞 Support Resources

**Firebase Support:**
- Documentation: https://firebase.google.com/docs
- Stack Overflow: Tag `firebase`
- Community: https://firebase.google.com/community

**Google Maps Support:**
- Documentation: https://developers.google.com/maps/documentation
- Support: https://developers.google.com/maps/support

**Swift/iOS Support:**
- Apple Developer Forums: https://developer.apple.com/forums
- Stack Overflow: Tags `swift`, `swiftui`, `ios`

---

## 💰 Cost Estimates

### Firebase (Free Tier Limits)

**Firestore:**
- 50K reads/day (free)
- 20K writes/day (free)
- 20K deletes/day (free)
- 1GB storage (free)

**Exceeding free tier:**
- $0.06 per 100K reads
- $0.18 per 100K writes
- $0.02 per 100K deletes
- $0.18/GB storage per month

**Authentication:**
- Unlimited free for Email/Password

**Cloud Messaging (Push):**
- Unlimited free

**Estimated for 100 users:**
- ~5K-10K writes/day (locations, check-ins)
- ~20K-40K reads/day (dashboard, maps)
- **Cost**: $0-50/month

### Google Maps

**Maps SDK for iOS:**
- $7 per 1,000 map loads
- First $200/month free (Google Cloud credit)

**Places API:**
- Varies by request type
- $17-32 per 1,000 requests

**Geocoding API:**
- $5 per 1,000 requests

**Estimated for 100 users:**
- ~3K-5K map loads/day
- ~1K geocoding requests/day
- **Cost**: $0-200/month (covered by free credit initially)

**Total Estimated Cost (100 users):** $50-250/month

---

## 🎯 Performance Optimization Tips

1. **Batch Firestore Reads**: Use `whereIn` queries
2. **Cache Location Data**: Don't query Firestore too frequently
3. **Optimize Map Rendering**: Cluster markers for large teams
4. **Background Tasks**: Use efficient location updates
5. **Offline Mode**: Cache data locally with Firestore offline persistence

---

**Your production environment is ready! 🚀**

Next steps:
1. Complete App Store submission (see APP_STORE_SUBMISSION_GUIDE.md)
2. Monitor usage and costs
3. Gather user feedback
4. Iterate and improve!

# Multi-Tenant Setup Checklist

## ✅ Completed (Files Created)

- [x] `Models/Tenant.swift` - Tenant data model
- [x] `Models/UserRole.swift` - Role definitions and permissions
- [x] `Models/User.swift` - Updated user model with tenantId
- [x] `Services/TenantService.swift` - Tenant management service
- [x] `Services/InvitationService.swift` - Invitation system
- [x] `Views/CompanyRegistrationView.swift` - Company signup UI
- [x] Updated `SignupView.swift` - Added invitation support
- [x] `firestore.rules` - Security rules
- [x] `functions_example.js` - Cloud Functions examples
- [x] `MULTI_TENANT_GUIDE.md` - Comprehensive documentation

## 🚀 Next Steps (Action Required)

### 1. Deploy Firestore Security Rules (CRITICAL)
```bash
# Option A: Using Firebase CLI
firebase deploy --only firestore:rules

# Option B: Manual via Console
# 1. Go to https://console.firebase.google.com
# 2. Select your project
# 3. Firestore Database → Rules
# 4. Copy content from firestore.rules
# 5. Click Publish
```

### 2. Set Up Cloud Functions (HIGH PRIORITY)
```bash
# Initialize functions
firebase init functions

# Copy functions_example.js content to functions/index.js

# Install dependencies
cd functions
npm install

# Deploy
firebase deploy --only functions
```

**Why this is important:**
- Sets custom claims on user auth tokens
- Enables role-based security rules
- Cleans up expired invitations
- Sends invitation emails

### 3. Update Existing Data (If Applicable)

If you have existing users in the `persons/` collection:

```swift
// Run this migration once
let db = Firestore.firestore()

// 1. Create default tenant
let tenantService = TenantService()
let defaultTenantId = try await tenantService.createTenant(
    name: "Default Company",
    domain: nil,
    adminUserId: "YOUR_FIRST_USER_ID",
    subscription: .enterprise
)

// 2. Migrate persons to users
let persons = try await db.collection("persons").getDocuments()
for doc in persons.documents {
    var data = doc.data()
    data["tenantId"] = defaultTenantId
    data["role"] = "driver"
    data["isActive"] = true
    
    try await db.collection("users").document(doc.documentID).setData(data)
}

// 3. Add tenantId to geofences
let geofences = try await db.collection("geofences").getDocuments()
for doc in geofences.documents {
    try await doc.reference.updateData(["tenantId": defaultTenantId])
}
```

### 4. Test the Flows

#### A. Test Company Registration
1. Run the app
2. Go to Sign Up
3. Click "Register Your Company"
4. Fill out company details
5. Verify tenant and admin user are created in Firestore

#### B. Test Invitation Flow
1. Create invitation manually in Firestore:
```
invitations/test-invite-001
{
  "tenantId": "<your-tenant-id>",
  "invitedBy": "<admin-user-id>",
  "invitationCode": "TEST1234",
  "role": "driver",
  "expiresAt": <7 days from now>,
  "isUsed": false,
  "createdAt": <now>
}
```
2. Go to Sign Up
3. Enter "TEST1234"
4. Click Validate → should show green checkmark
5. Complete signup
6. Verify user is created with correct tenantId and role

#### C. Test Tenant Isolation
1. Create 2 test companies
2. Add users to each
3. Query users from Company A's context
4. Verify you cannot see Company B's users

### 5. Create Admin Dashboard (Next Development)

You'll need views for:
- **User Management**
  - List all users in tenant
  - Edit user roles
  - Deactivate/activate users
  
- **Invitation Management**
  - Create new invitations
  - List active invitations
  - Copy invitation code
  - Delete unused invitations
  
- **Company Settings**
  - Edit company name
  - Change domain
  - Upload logo
  - View subscription tier
  
- **Analytics**
  - Total users count
  - Users by role
  - Active vs inactive
  - Recent signups

Example file structure:
```
Views/Admin/
├── AdminDashboardView.swift
├── UserManagementView.swift
├── InvitationManagementView.swift
├── CompanySettingsView.swift
└── AnalyticsView.swift
```

### 6. Add Navigation Logic

Update your app's navigation to:
1. Check if user is authenticated
2. Load user's tenant data
3. Navigate based on role:
   - `admin` → Admin Dashboard
   - `manager` → Manager Dashboard  
   - `driver` → Map View (existing)

Example:
```swift
@main
struct GeoGuardApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var tenantService = TenantService()
    
    var body: some Scene {
        WindowGroup {
            if authService.currentUser == nil {
                // Not logged in
                LoginView()
            } else if let user = authService.currentUser {
                // Logged in - route by role
                switch user.role {
                case .admin:
                    AdminDashboardView()
                case .manager:
                    ManagerDashboardView()
                case .driver:
                    ContentView()  // Your existing map view
                case .superAdmin:
                    SuperAdminView()
                }
            }
        }
    }
}
```

### 7. Add Firestore Indexes

When you run queries, Firebase will prompt you to create indexes. Click the provided links or create manually:

**Common indexes needed:**
```
Collection: users
Fields: tenantId (ASC), role (ASC)

Collection: users
Fields: tenantId (ASC), isActive (ASC)

Collection: invitations
Fields: tenantId (ASC), isUsed (ASC)

Collection: invitations
Fields: invitationCode (ASC), isUsed (ASC)

Collection: geofences
Fields: tenantId (ASC), createdAt (DESC)
```

### 8. Configure Email Service (For Invitations)

Update `functions_example.js` with your email provider:

**Option A: SendGrid**
```javascript
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(functions.config().sendgrid.key);

await sgMail.send({
  to: invitation.email,
  from: 'noreply@geoguard.com',
  subject: `You're invited to ${tenant.name}`,
  html: emailContent.html
});
```

**Option B: Mailgun**
**Option C: AWS SES**
**Option D: Custom SMTP**

### 9. Add Environment Configuration

Consider using different configs for dev/staging/prod:

```swift
// Config.swift
struct Config {
    static let environment: Environment = .development
    
    enum Environment {
        case development
        case staging
        case production
    }
    
    static var firestoreEmulator: (host: String, port: Int)? {
        switch environment {
        case .development:
            return ("localhost", 8080)
        default:
            return nil
        }
    }
}
```

### 10. Set Up Monitoring

Add logging for tenant operations:
```swift
// TenantLogger.swift
class TenantLogger {
    static func log(event: String, tenantId: String, metadata: [String: Any] = [:]) {
        var logData = metadata
        logData["event"] = event
        logData["tenantId"] = tenantId
        logData["timestamp"] = Date()
        
        // Send to your analytics service
        // Analytics.log(event, properties: logData)
        
        print("📊 Tenant Event: \(event) | Tenant: \(tenantId)")
    }
}
```

## 🧪 Testing Checklist

- [ ] Company registration creates tenant + admin user
- [ ] Admin can create invitations
- [ ] Users can sign up with valid invitation code
- [ ] Invalid/expired codes show errors
- [ ] Users can only see data from their tenant
- [ ] Role permissions work correctly
- [ ] Security rules block cross-tenant access
- [ ] Cloud Functions set custom claims
- [ ] Expired invitations are cleaned up
- [ ] User limit enforcement works

## 📊 Firebase Console Verification

After setup, verify in Firebase Console:

### Firestore Database
- `tenants/` collection has documents
- `users/` collection has `tenantId` field
- `invitations/` collection working
- All documents have proper indexes

### Authentication
- Users exist with correct emails
- Custom claims are set (check token)

### Functions
- Functions are deployed and active
- Logs show successful executions
- No errors in function logs

### Rules
- Rules simulator shows correct permissions
- Test queries with different user contexts

## 🎯 Production Readiness

Before going live:

- [ ] Security rules deployed and tested
- [ ] Cloud Functions deployed
- [ ] Email service configured
- [ ] Billing/subscription system integrated
- [ ] Admin dashboard complete
- [ ] User documentation created
- [ ] Support system in place
- [ ] Monitoring and alerts set up
- [ ] Backup strategy defined
- [ ] GDPR compliance reviewed (if applicable)

## 📚 Resources

- Firebase Security Rules: https://firebase.google.com/docs/firestore/security/rules-structure
- Cloud Functions: https://firebase.google.com/docs/functions
- Custom Claims: https://firebase.google.com/docs/auth/admin/custom-claims
- Composite Indexes: https://firebase.google.com/docs/firestore/query-data/indexing

## 🆘 Common Issues

### "Permission denied" errors
- Check security rules are deployed
- Verify custom claims are set
- Ensure user's tenantId matches query filter

### Queries not returning data
- Check composite indexes exist
- Verify tenantId is correct
- Look at Firebase Console → Firestore for actual data

### Invitation validation fails
- Check invitation hasn't expired
- Verify invitationCode is exact match (case-sensitive)
- Ensure invitation hasn't been used

### Users can see other tenants' data
- **CRITICAL**: Security rules not properly deployed
- Deploy rules immediately
- Review rules simulator

---

## 🎉 You're Ready!

The multi-tenant architecture is now in place. Follow this checklist to complete the setup, and you'll have a fully functional enterprise-ready GeoGuard system!

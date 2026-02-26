# GeoGuard User Onboarding Guide

## 📱 Complete User Journey

This guide explains how users join and use GeoGuard, step by step.

---

## 👤 User Type 1: Company Owner/First Admin

### The Journey
```
Step 1: Download GeoGuard
   ↓
Step 2: Open app → See login/signup screen
   ↓
Step 3: Tap "Register Your Organization"
   ↓
Step 4: Fill in ONE FORM with:
   
   📋 COMPANY INFORMATION
   • Company Name (e.g., "Acme Logistics")
   • Company Domain (optional, e.g., "acme.com")
   • Company Address (with autocomplete)
   • City, Country
   • Subscription Tier (Trial/Basic/Pro/Enterprise)
   
   👤 YOUR ADMIN ACCOUNT
   • Email (becomes admin)
   • Password
   • First Name
   • Last Name
   • Phone Number
   • Your Address
   
   ↓
Step 5: Tap "Create Company" button
   ↓
Step 6: ✅ TWO THINGS CREATED SIMULTANEOUSLY:
   1. Company/Organization (Tenant)
   2. Your Admin Account
   ↓
Step 7: Automatically logged in!
   ↓
Step 8: See Admin Dashboard with:
   • User Statistics
   • Quick Actions
   • "Create Invitation" button ← Important!
```

### What You Can Do Now
- ✅ Create invitation codes for employees
- ✅ Manage users
- ✅ Configure company settings
- ✅ View analytics
- ✅ Set up geofences (future)
- ✅ Track employee locations (future)

---

## 👥 User Type 2: Employees/Team Members

### The Journey
```
Step 1: Admin creates invitation for you
   (Admin Dashboard → "Create Invitation")
   
   Admin selects:
   • Your role (Field Personnel, Manager, or Admin)
   • Optional: Your specific email address
   • Expiration (default: 7 days)
   
   ↓
   Code generated: "ABC12XYZ"
   ↓
   
Step 2: You receive invitation code
   (via text message, email, Slack, etc.)
   
   Example message:
   "Join our team on GeoGuard! 
    Use invitation code: ABC12XYZ
    Download: [app link]"
   
   ↓
Step 3: Download GeoGuard app
   ↓
Step 4: Open app → See login/signup screen
   ↓
Step 5: Enter invitation code in "Invitation Code" field
   ↓
Step 6: Tap "Validate" button
   ↓
   ✅ "Valid invitation for Field Personnel" appears
   ↓
Step 7: Fill in your personal information:
   • Email
   • Password
   • First Name
   • Last Name
   • Phone Number
   • Address (with autocomplete)
   
   ↓
Step 8: Tap "Sign Up" button
   ↓
Step 9: ✅ YOU'RE IN!
   • Account created
   • Joined your company automatically
   • Role assigned from invitation
   • Invitation marked as "used"
   ↓
Step 10: Automatically logged in!
   ↓
Step 11: See your dashboard based on role:
   • Admin → Full Admin Dashboard
   • Manager → Manager Dashboard
   • Field Personnel → Location Tracking Screen
```

### What You Can Do (Based on Role)

#### Field Personnel Can:
- ✅ View your location tracking
- ✅ See assigned areas
- ✅ View safety alerts
- ❌ Cannot manage users
- ❌ Cannot create invitations

#### Managers Can:
- ✅ Everything Field Personnel can do
- ✅ View all team locations
- ✅ Create/edit geofences
- ✅ Create invitations for Field Personnel
- ❌ Cannot manage admins

#### Admins Can:
- ✅ Everything Managers can do
- ✅ Manage all users
- ✅ Create invitations for any role
- ✅ Configure company settings
- ✅ View analytics

---

## 🔑 Alternative: Domain-Based Auto-Join

### If Company Enabled Domain Matching

Example: Company registered with domain `acme.com`

```
Step 1: Employee has email like "john@acme.com"
   ↓
Step 2: Download GeoGuard → Go to signup
   ↓
Step 3: Enter email "john@acme.com"
   ↓
Step 4: Skip invitation code (leave blank)
   ↓
Step 5: Fill in other details → Sign up
   ↓
Step 6: ✅ Automatically joined company!
   • Matched domain "acme.com"
   • Assigned default role: Field Personnel
```

**Note:** This is optional. Admins can choose to:
- Enable domain matching → Employees auto-join
- Disable domain matching → Everyone needs invitation code

---

## 📊 Invitation Code Details

### Code Format
- **8 characters** (letters and numbers)
- **Example:** `ABC12XYZ`, `DEF34UVW`, `GHI56RST`
- **Case-insensitive** (abc12xyz = ABC12XYZ)

### Code Types

#### General Invitation
```
• No email restriction
• Anyone can use it
• Good for: Sharing on team chat
```

#### Email-Specific Invitation
```
• Tied to specific email
• Only that person can use it
• Good for: Individual invites
```

### Expiration
- **Default:** 7 days
- **Range:** 1-30 days (configurable)
- **After expiration:** Code becomes invalid

### Usage
- **Single use only**
- After one person signs up, code is "used"
- Shows in "Used Invitations" section
- Cannot be reused

---

## 📱 Admin: How to Create Invitations

### Method 1: From Admin Dashboard
```
1. Login as Admin
   ↓
2. See Dashboard
   ↓
3. Tap "Create Invitation" button
   (in Quick Actions section)
   ↓
4. Fill in invitation settings:
   • Role (select from dropdown)
   • Specific Email (optional)
   • Expiration (1-30 days)
   ↓
5. Tap "Generate"
   ↓
6. Code appears: "ABC12XYZ"
   ↓
7. Tap copy icon to copy
   ↓
8. Share via:
   • Text message
   • Email
   • Slack/Teams
   • Any messaging app
   ↓
9. Tap "Done"
```

### Method 2: From Invitation Management
```
1. Login as Admin
   ↓
2. Dashboard → "See All" next to Active Invitations
   ↓
3. Invitation Management screen appears
   ↓
4. Tap "+" button (top right)
   ↓
5. Same process as Method 1
```

### Invitation Management Features
- **View Active Invitations:** All unused, non-expired codes
- **View Used Invitations:** History of who joined
- **Delete Invitations:** Cancel unused codes
- **Copy Codes:** Quick copy to clipboard
- **See Details:** Role, email, expiration, creation date

---

## 🎯 Real-World Scenarios

### Scenario 1: Small Delivery Company
```
Owner (Sarah):
1. Downloads GeoGuard
2. Registers "Fast Delivery Co"
3. Creates admin account
4. Creates 5 invitations for drivers
5. Texts codes to each driver

Drivers:
1. Receive text: "Join Fast Delivery on GeoGuard: XYZ123AB"
2. Download app
3. Enter code → Sign up
4. Start location tracking
```

### Scenario 2: Large Logistics Firm
```
IT Admin (John):
1. Registers "Mega Logistics Inc"
2. Domain: megalogistics.com
3. Enables domain matching

Regional Managers (5 people):
1. Receive email invitations with codes
2. Sign up as Managers
3. Each manager creates invitations for their team

Drivers (200 people):
Option A: Receive invitation codes from managers
Option B: Use @megalogistics.com email → Auto-join
```

### Scenario 3: Security Company
```
CEO:
1. Registers "SecureGuard Services"
2. Creates invitation for Operations Manager

Operations Manager:
1. Joins with invitation code
2. Now has manager permissions
3. Creates invitations for:
   • Field supervisors (Managers)
   • Security officers (Field Personnel)

Field Supervisors:
1. Join as Managers
2. Can create invitations for their teams
3. Monitor their assigned officers

Security Officers:
1. Join as Field Personnel
2. Use app for location tracking
3. Receive safety alerts
```

---

## ⚠️ Common Questions

### Q: I'm the first user. Do I need an invitation code?
**A: NO!** As the first user, you **"Register Your Organization"**. This creates both the company and your admin account together. You don't need a code.

### Q: Can I create multiple admins during company registration?
**A: NO.** Company registration creates ONE admin (you). To add more admins:
1. Login as the first admin
2. Create invitation with role = Admin
3. Share code with the person
4. They sign up with that code

### Q: What if I lose an invitation code?
**A: Admins/Managers can view all active codes:**
1. Dashboard → Invitation Management
2. See list of Active Invitations
3. Copy code again

### Q: Can I change someone's role after they join?
**A: YES (Admin only):**
1. Dashboard → Manage Users
2. Select user
3. Edit role
4. Save changes

### Q: What happens if invitation code expires?
**A: It becomes invalid.** Admin needs to:
1. Delete old invitation
2. Create new invitation
3. Share new code

### Q: Can I have multiple admins?
**A: YES!** 
- First admin creates invitation with role = Admin
- New person joins with that code
- Now you have 2 admins

### Q: Do invitation codes cost anything?
**A: NO, but user limits apply:**
- Trial: 5 users total
- Basic: 25 users total
- Professional: 100 users total
- Enterprise: Unlimited

### Q: Can I invite someone to multiple companies?
**A: YES.** One person can be in multiple organizations:
- Use different email for each
- Or same email joins different companies
- Switch between companies in app (future feature)

### Q: What if someone signs up without invitation?
**A: Depends on settings:**
- If domain matching enabled + email matches → Joins as Field Personnel
- Otherwise → Signup fails with error message

---

## 🔒 Security Notes

### Data Isolation
- ✅ Each company's data is completely separate
- ✅ Users can only see data from their company
- ✅ Even if someone hacks the app code, Firestore rules block access

### Invitation Security
- ✅ Codes expire after set time (default 7 days)
- ✅ Single-use only
- ✅ Can be deleted/cancelled by admin
- ✅ Optional email restriction

### Role Permissions
- ✅ Field Personnel cannot see admin features
- ✅ Managers cannot access company settings
- ✅ Only admins can manage users
- ✅ Enforced at database level

---

## 📞 Support Flow

### User Can't Sign Up
1. Check invitation code spelling
2. Verify code hasn't expired (check with admin)
3. If email-specific, verify correct email
4. Contact admin to create new invitation

### Admin Can't Create Invitations
1. Check user limit for subscription tier
2. Verify admin permissions
3. Check internet connection
4. Try logging out and back in

### Wrong Role Assigned
1. Contact admin
2. Admin goes to User Management
3. Admin edits user → Change role
4. User logs out and back in

---

## 🎉 Summary

### For Company Owners
1. ✅ **Register organization** (creates company + admin together)
2. ✅ **Create invitations** (assign roles)
3. ✅ **Share codes** (text/email/chat)
4. ✅ **Manage team** (add/remove users)

### For Employees
1. ✅ **Get invitation code** (from admin)
2. ✅ **Download app** (App Store)
3. ✅ **Enter code** (during signup)
4. ✅ **Start working** (automatic role assignment)

### Key Principle
```
┌──────────────────────────────────────────────────┐
│  Organization + First Admin = Created Together   │
│  All Other Users = Join via Invitation Codes    │
└──────────────────────────────────────────────────┘
```

---

**Need more help?** Check:
- `IMPLEMENTATION_SUMMARY.md` - Technical details
- `MULTI_TENANT_GUIDE.md` - Architecture explanation
- `SETUP_CHECKLIST.md` - Deployment guide

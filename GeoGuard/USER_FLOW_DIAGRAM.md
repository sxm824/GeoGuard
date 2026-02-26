# GeoGuard User Flow Diagram

## 🎯 Quick Visual Reference

---

## Flow 1: Company Owner (First User)

```
╔═══════════════════════════════════════════════════════════╗
║                    COMPANY OWNER FLOW                      ║
╚═══════════════════════════════════════════════════════════╝

    📱 Download GeoGuard
           │
           ▼
    🏢 Tap "Register Your Organization"
           │
           ▼
    ┌─────────────────────────────────────┐
    │  SINGLE FORM WITH:                  │
    │                                     │
    │  Company Info:                      │
    │  • Company Name                     │
    │  • Domain (optional)                │
    │  • Address                          │
    │  • Subscription Tier                │
    │                                     │
    │  Your Admin Account:                │
    │  • Email                            │
    │  • Password                         │
    │  • Name                             │
    │  • Phone                            │
    └─────────────────────────────────────┘
           │
           ▼
    💾 Tap "Create Company"
           │
           ▼
    ✅ BOTH CREATED TOGETHER:
       1. Tenant/Organization
       2. Admin User Account
           │
           ▼
    🎉 Logged in automatically!
           │
           ▼
    📊 Admin Dashboard
       │
       ├─→ Create Invitations
       ├─→ Manage Users
       ├─→ Company Settings
       └─→ View Analytics
```

---

## Flow 2: Employee (Invited User)

```
╔═══════════════════════════════════════════════════════════╗
║                      EMPLOYEE FLOW                         ║
╚═══════════════════════════════════════════════════════════╝

    👤 Admin creates invitation
           │
           ▼
    🎫 Code generated: "ABC12XYZ"
           │
           ▼
    📧 You receive code
       (text/email/chat)
           │
           ▼
    📱 Download GeoGuard
           │
           ▼
    📝 Sign Up Screen
           │
           ▼
    🔑 Enter invitation code: "ABC12XYZ"
           │
           ▼
    ✓ Tap "Validate"
           │
           ▼
    ✅ "Valid invitation for Field Personnel"
           │
           ▼
    ┌─────────────────────────────────────┐
    │  Fill in YOUR info:                 │
    │  • Email                            │
    │  • Password                         │
    │  • Name                             │
    │  • Phone                            │
    │  • Address                          │
    └─────────────────────────────────────┘
           │
           ▼
    💾 Tap "Sign Up"
           │
           ▼
    ✅ AUTOMATICALLY:
       • Joined company
       • Role assigned
       • Invitation marked "used"
           │
           ▼
    🎉 Logged in automatically!
           │
           ▼
    📱 Your Dashboard
       (based on role)
```

---

## Flow 3: Admin Creating Invitations

```
╔═══════════════════════════════════════════════════════════╗
║              ADMIN CREATING INVITATION FLOW                ║
╚═══════════════════════════════════════════════════════════╝

    🔐 Login as Admin
           │
           ▼
    📊 Admin Dashboard
           │
           ▼
    ➕ Tap "Create Invitation"
           │
           ▼
    ┌─────────────────────────────────────┐
    │  Invitation Settings:               │
    │                                     │
    │  • Select Role:                     │
    │    ○ Field Personnel               │
    │    ○ Manager                        │
    │    ○ Admin                          │
    │                                     │
    │  • Specific Email (optional):      │
    │    [john@company.com]              │
    │                                     │
    │  • Expires in:                     │
    │    [7 days] ▼                      │
    └─────────────────────────────────────┘
           │
           ▼
    💾 Tap "Generate"
           │
           ▼
    🎫 Code Created: "ABC12XYZ"
           │
           ▼
    📋 Tap Copy Icon
           │
           ▼
    📧 Share via:
       • Text Message
       • Email
       • Slack/Teams
       • Any messaging app
           │
           ▼
    ✅ Done!
       Code valid for 7 days
```

---

## Architecture Overview

```
╔═══════════════════════════════════════════════════════════╗
║                   MULTI-TENANT STRUCTURE                   ║
╚═══════════════════════════════════════════════════════════╝

    🌐 Firebase Project
           │
           ├─── 🏢 Company A (Tenant: acme-logistics)
           │         │
           │         ├─── 👤 Admin: Sarah
           │         ├─── 👤 Manager: John
           │         ├─── 👤 Driver: Mike
           │         └─── 👤 Driver: Lisa
           │
           ├─── 🏢 Company B (Tenant: beta-delivery)
           │         │
           │         ├─── 👤 Admin: David
           │         ├─── 👤 Manager: Emma
           │         └─── 👤 Driver: Tom
           │
           └─── 🏢 Company C (Tenant: gamma-trans)
                     │
                     ├─── 👤 Admin: Alice
                     └─── 👤 Driver: Bob

    ✅ Each company's data is COMPLETELY ISOLATED
    ❌ Company A users CANNOT see Company B data
    🔒 Enforced by Firestore Security Rules
```

---

## Data Relationships

```
╔═══════════════════════════════════════════════════════════╗
║                  DATA MODEL DIAGRAM                        ║
╚═══════════════════════════════════════════════════════════╝

    📁 Tenant
       ├─ id: "acme-logistics"
       ├─ name: "Acme Logistics"
       ├─ domain: "acme.com"
       └─ subscriptionTier: "professional"
              │
              │ (1 tenant → many users)
              │
              ▼
    📁 Users
       ├─ User 1
       │  ├─ tenantId: "acme-logistics" ◄── Links to tenant
       │  ├─ role: "admin"
       │  └─ email: "sarah@acme.com"
       │
       ├─ User 2
       │  ├─ tenantId: "acme-logistics" ◄── Same tenant
       │  ├─ role: "driver"
       │  └─ email: "mike@acme.com"
       │
       └─ User 3
          ├─ tenantId: "beta-delivery" ◄── Different tenant!
          ├─ role: "admin"
          └─ email: "david@beta.com"
              │
              │ (Users join via invitations)
              │
              ▼
    📁 Invitations
       ├─ Invitation 1
       │  ├─ tenantId: "acme-logistics" ◄── Links to tenant
       │  ├─ code: "ABC12XYZ"
       │  ├─ role: "driver"
       │  ├─ isUsed: false
       │  └─ expiresAt: "2026-03-05"
       │
       └─ Invitation 2
          ├─ tenantId: "acme-logistics" ◄── Same tenant
          ├─ code: "DEF34UVW"
          ├─ role: "manager"
          ├─ isUsed: true ◄── Already used
          └─ usedBy: "user-002"
```

---

## Permission Matrix

```
╔═══════════════════════════════════════════════════════════╗
║                  WHO CAN DO WHAT?                          ║
╚═══════════════════════════════════════════════════════════╝

┌─────────────────────┬───────┬─────────┬─────────┬──────────┐
│      ACTION         │ Admin │ Manager │  Field  │  Other   │
│                     │       │         │Personnel│ Company  │
├─────────────────────┼───────┼─────────┼─────────┼──────────┤
│ Register Company    │  ✅   │   N/A   │   N/A   │    ─     │
│ Create Invitations  │  ✅   │   ✅    │   ❌    │    ❌    │
│ Delete Invitations  │  ✅   │   ✅    │   ❌    │    ❌    │
│ View Own Company    │  ✅   │   ✅    │   ✅    │    ❌    │
│ View Other Company  │  ❌   │   ❌    │   ❌    │    ❌    │
│ Manage Users        │  ✅   │   ❌    │   ❌    │    ❌    │
│ Edit Roles          │  ✅   │   ❌    │   ❌    │    ❌    │
│ Company Settings    │  ✅   │   ❌    │   ❌    │    ❌    │
│ Track Location      │  ✅   │   ✅    │   ✅    │    ❌    │
│ View Analytics      │  ✅   │   ✅    │   ❌    │    ❌    │
└─────────────────────┴───────┴─────────┴─────────┴──────────┘

Legend:
✅ = Allowed
❌ = Blocked by Firestore Security Rules
─  = Not applicable
```

---

## Invitation Lifecycle

```
╔═══════════════════════════════════════════════════════════╗
║               INVITATION CODE LIFECYCLE                    ║
╚═══════════════════════════════════════════════════════════╝

    🆕 CREATED
       │  Admin creates invitation
       │  Code: "ABC12XYZ"
       │  Status: Active
       │  Expires: 7 days
       ▼
    📤 SHARED
       │  Admin sends code to employee
       │  Via text/email/chat
       ▼
    ✅ VALIDATED
       │  Employee enters code
       │  System checks:
       │  • Code exists?
       │  • Not expired?
       │  • Email matches (if specific)?
       ▼
    💾 USED
       │  Employee completes signup
       │  Code marked as "used"
       │  Cannot be reused
       ▼
    📊 ARCHIVED
       │  Shows in "Used Invitations"
       │  Tracks who used it
       │  Shows usage date
       
    OR
    
    ⏰ EXPIRED
       │  7 days passed
       │  Code becomes invalid
       │  Admin must create new one
       
    OR
    
    🗑️ DELETED
       │  Admin cancels invitation
       │  Code immediately invalid
       │  Cannot be recovered
```

---

## Security Layers

```
╔═══════════════════════════════════════════════════════════╗
║                   SECURITY ARCHITECTURE                    ║
╚═══════════════════════════════════════════════════════════╝

    Layer 1: Firebase Authentication
    ┌─────────────────────────────────────┐
    │  ✅ Email/Password                  │
    │  ✅ User must be authenticated      │
    │  ❌ Anonymous access blocked        │
    └─────────────────────────────────────┘
              │
              ▼
    Layer 2: Firestore Security Rules
    ┌─────────────────────────────────────┐
    │  ✅ tenantId must match             │
    │  ✅ Role permissions enforced       │
    │  ❌ Cross-tenant access blocked     │
    └─────────────────────────────────────┘
              │
              ▼
    Layer 3: Application Logic
    ┌─────────────────────────────────────┐
    │  ✅ UI based on permissions         │
    │  ✅ Queries filtered by tenantId    │
    │  ✅ Role-based feature access       │
    └─────────────────────────────────────┘
              │
              ▼
    Layer 4: Data Validation
    ┌─────────────────────────────────────┐
    │  ✅ Input validation                │
    │  ✅ Business rules enforcement      │
    │  ✅ Audit logging (future)          │
    └─────────────────────────────────────┘

    Result: Multi-layered security
            Even if one layer fails, others protect data
```

---

## Real-World Timeline Example

```
╔═══════════════════════════════════════════════════════════╗
║            ACME LOGISTICS ONBOARDING STORY                 ║
╚═══════════════════════════════════════════════════════════╝

Day 1 - Monday 9:00 AM
    👤 Sarah (Owner) registers "Acme Logistics"
       ✅ Company created
       ✅ Sarah = Admin
    
Day 1 - Monday 10:00 AM
    📝 Sarah creates 3 invitations:
       • "ABC12XYZ" for John (Manager)
       • "DEF34UVW" for Mike (Driver)
       • "GHI56RST" for Lisa (Driver)
    
Day 1 - Monday 11:00 AM
    📧 Sarah texts codes to team
    
Day 1 - Monday 2:00 PM
    👤 John signs up with "ABC12XYZ"
       ✅ Joined as Manager
       ✅ Code marked "used"
    
Day 2 - Tuesday 8:00 AM
    👤 Mike signs up with "DEF34UVW"
       ✅ Joined as Field Personnel
       ✅ Code marked "used"
    
Day 3 - Wednesday 10:00 AM
    👤 John (Manager) creates invitation for Emma
       ✅ "JKL78MNO" for Emma (Driver)
    
Day 3 - Wednesday 3:00 PM
    👤 Emma signs up with "JKL78MNO"
       ✅ Joined as Field Personnel
    
Day 8 - Next Monday
    ⏰ Code "GHI56RST" expires (unused)
       ❌ Lisa can no longer use it
    
Day 8 - Next Monday 9:00 AM
    📝 Sarah creates new invitation for Lisa
       ✅ "PQR90STU" for Lisa (Driver)
    
Day 8 - Next Monday 11:00 AM
    👤 Lisa signs up with new code
       ✅ Joined as Field Personnel
    
Result: Team of 5 people ready to work!
    • 1 Admin (Sarah)
    • 1 Manager (John)
    • 3 Field Personnel (Mike, Lisa, Emma)
```

---

## Troubleshooting Decision Tree

```
╔═══════════════════════════════════════════════════════════╗
║              TROUBLESHOOTING FLOWCHART                     ║
╚═══════════════════════════════════════════════════════════╝

    ❓ Cannot sign up
           │
           ├─→ Have invitation code?
           │      │
           │      ├─→ YES → Code not working?
           │      │           │
           │      │           ├─→ Check spelling
           │      │           ├─→ Check expiration
           │      │           ├─→ Ask admin for new code
           │      │           └─→ Verify correct email (if specific)
           │      │
           │      └─→ NO → Company has domain matching?
           │                 │
           │                 ├─→ YES → Use company email
           │                 └─→ NO → Get invitation from admin
           │
           ├─→ Admin cannot create invitation?
           │      │
           │      └─→ Check user limit for subscription
           │           (Trial: 5, Basic: 25, Pro: 100)
           │
           └─→ Wrong role assigned?
                  │
                  └─→ Contact admin to change role
                      in User Management

    ❓ Cannot see company data
           │
           └─→ Check:
                  │
                  ├─→ Correct company?
                  ├─→ Role has permission?
                  └─→ Internet connection?

    ❓ Invitation expired
           │
           └─→ Admin creates new invitation
                  │
                  └─→ Use new code to sign up
```

---

## Summary Cheat Sheet

```
╔═══════════════════════════════════════════════════════════╗
║                    QUICK REFERENCE                         ║
╚═══════════════════════════════════════════════════════════╝

WHO DOES WHAT:

✅ Company Owner (First User):
   → "Register Your Organization"
   → Creates company + admin account together
   → Can invite others

✅ Employees (After First):
   → Get invitation code from admin
   → Enter code during signup
   → Join company automatically

✅ Admins:
   → Create invitations
   → Manage users
   → Configure company
   → View everything

✅ Managers:
   → Create invitations (limited)
   → View team data
   → Manage geofences

✅ Field Personnel:
   → Track location
   → View assignments
   → Cannot manage others

KEY PRINCIPLES:

1️⃣ Organization = Created with first admin
2️⃣ Everyone else = Joins via invitation
3️⃣ One invitation = One person
4️⃣ Invitations = Expire after 7 days
5️⃣ All data = Isolated by company
6️⃣ Roles = Determine permissions
7️⃣ Security = Enforced at database level

COMMON QUESTIONS:

Q: Need invitation to create company?
A: NO! First person registers company.

Q: Can reuse invitation codes?
A: NO! One-time use only.

Q: Can join multiple companies?
A: YES! Use different email or same.

Q: Can change someone's role?
A: YES! Admins can change roles.

Q: What if code expires?
A: Admin creates new code.
```

---

## Next Steps

```
📚 Read these guides in order:

1. USER_ONBOARDING_GUIDE.md
   ↓ (How users join)
   
2. IMPLEMENTATION_SUMMARY.md
   ↓ (What was built)
   
3. MULTI_TENANT_GUIDE.md
   ↓ (Technical architecture)
   
4. SETUP_CHECKLIST.md
   ↓ (Deployment steps)
   
5. FIREBASE_RULES_SETUP.md
   ↓ (Security configuration)

🚀 Then deploy and test!
```

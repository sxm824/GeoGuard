# Firebase Security Rules Setup

## ⚠️ CRITICAL: Deploy These Rules Before Testing

The app will not work properly without deploying the Firestore security rules. These rules enable:
- User signup and account creation
- Multi-tenant data isolation
- Role-based access control

## Quick Deploy

```bash
# Make sure you're in the project directory
cd /path/to/GeoGuard

# Deploy the rules
firebase deploy --only firestore:rules
```

## Verify Deployment

After deployment, you should see output like:
```
✔  firestore: released rules firestore.rules to cloud.firestore
✔  Deploy complete!
```

## Testing the Rules

### Test User Signup
1. Open the app
2. Tap "Create Account"
3. Fill in the form
4. Try to create an account

**Before deploying rules:** You'll get a permission denied error
**After deploying rules:** Account creation should succeed

### Test Company Registration
1. Tap "Register Your Organization"
2. Fill in organization details
3. Create admin account

This should now work without permission errors.

## Rules Overview

### Users Collection
- ✅ **Create**: Users can create their own account during signup
- ✅ **Read**: Users can read their own data and data from users in the same tenant
- ✅ **Update**: Only admins can update user data
- ✅ **Delete**: Only admins can delete users

### Tenants Collection
- ✅ **Create**: Authenticated users can create a tenant if they're the admin
- ✅ **Read**: Users in the tenant can read tenant data
- ✅ **Update**: Only admins can update tenant settings
- ✅ **Delete**: Only super admins can delete tenants

### Invitations Collection
- ✅ **Create**: Admins and managers can create invitations
- ✅ **Read**: Anyone can read (needed for signup validation)
- ✅ **Update**: Admins and managers can update invitations
- ✅ **Delete**: Admins and managers can delete invitations

### Locations Collection (Future)
- ✅ **Create/Update**: Field personnel can update their own location
- ✅ **Read**: Users in the tenant can read locations
- ❌ **Delete**: Location history cannot be deleted

### Geofences Collection (Future)
- ✅ **Create**: Managers and admins can create geofences
- ✅ **Read**: All users in tenant can read geofences
- ✅ **Update**: Managers and admins can update geofences
- ✅ **Delete**: Managers and admins can delete geofences

### Alerts Collection (Future)
- ✅ **Create**: Any user can create alerts (emergencies)
- ✅ **Read**: Users in tenant can read alerts
- ✅ **Update**: Managers and admins can update alerts
- ✅ **Delete**: Only admins can delete alerts

## Troubleshooting

### "Permission Denied" Error During Signup
**Cause:** Rules not deployed or deployed incorrectly
**Fix:** 
```bash
firebase deploy --only firestore:rules
```

### "Error getting documents" in User Management
**Cause:** User document doesn't have required `tenantId` field
**Fix:** Delete test users from Firebase Console and re-register

### Can't Read Other Users in Tenant
**Cause:** User's role might not be set correctly
**Fix:** Check Firebase Console → Firestore → users collection → verify `role` field

### Rules Not Taking Effect
**Cause:** Browser/app cache
**Fix:** 
1. Log out and log back in
2. Clear app data
3. Restart Xcode/rebuild app

## Advanced: Testing Rules Locally

You can test rules locally before deploying:

```bash
# Install Firebase Emulator
firebase emulators:start --only firestore

# Run tests (if you have them)
firebase emulators:exec --only firestore "npm test"
```

## Security Best Practices

### ✅ DO
- Deploy rules before production
- Test with different user roles
- Use tenant isolation for all queries
- Validate data on both client and server

### ❌ DON'T
- Never use `allow read, write: if true;` in production
- Don't skip tenant validation
- Don't allow users to modify their own role
- Don't expose sensitive data without authentication

## Modifying Rules

If you need to modify the rules:

1. Edit `firestore.rules`
2. Test changes locally (optional)
3. Deploy updated rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
4. Test in the app
5. Monitor Firebase Console for any permission errors

## Common Modifications

### Allow Field Personnel to Update Their Profile
```javascript
// In users/{userId} match
allow update: if isOwner(userId) || 
                (isAuthenticated() && 
                 sameTenant(resource.data.tenantId) && 
                 hasAnyRole(['admin', 'super_admin']));
```

### Add New Collection
```javascript
match /your_collection/{docId} {
  allow create: if isAuthenticated() && 
                  sameTenant(request.resource.data.tenantId);
  allow read: if isAuthenticated() && 
                sameTenant(resource.data.tenantId);
  // Add update/delete rules as needed
}
```

## Monitoring

Check Firebase Console → Firestore → Rules tab to see:
- Rule deployment history
- Error logs
- Request metrics

## Support

If you continue to have permission issues:

1. Check Firebase Console → Firestore → Rules → View "Rules Playground"
2. Test specific operations
3. Review error messages in Xcode console
4. Check user document has all required fields:
   - `tenantId`
   - `role`
   - `email`
   - `isActive`

---

## Quick Reference

| Action | Command |
|--------|---------|
| Deploy rules | `firebase deploy --only firestore:rules` |
| View current rules | Firebase Console → Firestore → Rules |
| Test rules | Firebase Console → Firestore → Rules → Rules Playground |
| View errors | Xcode Console or Firebase Console → Firestore → Usage |

---

**Remember:** Always deploy rules before testing the app!

```bash
firebase deploy --only firestore:rules
```

# 🚀 Pre-Publish Checklist

Use this checklist before pushing GeoGuard to GitHub.

## 🔐 Security Review (CRITICAL)

### API Keys & Secrets
- [ ] Remove hardcoded Google Maps API key from `GeoGuardApp.swift`
  - [ ] Replace with Config.plist OR environment variable
  - [ ] Create Config.example.plist with placeholder
- [ ] Verify `GoogleService-Info.plist` is in `.gitignore`
- [ ] Check no Firebase credentials in code
- [ ] Check no test emails/passwords in code
- [ ] Review all `print()` statements for sensitive data

### Git Status Check
```bash
# Run these commands and verify output
git status | grep GoogleService-Info.plist  # Should be EMPTY
git status | grep xcuserdata                 # Should be EMPTY  
git status | grep .DS_Store                  # Should be EMPTY
git status | grep Pods                       # Should be EMPTY (if using CocoaPods)
```

## 🛠️ Build & Test

### Xcode Checks
- [ ] Project builds without errors (`⌘B`)
- [ ] Project builds without warnings
- [ ] All files are added to target
- [ ] Deployment target is correct (iOS 17.0+)
- [ ] Bundle identifier is set correctly
- [ ] Team/signing configured (for real device testing)

### Functionality Tests
- [ ] Login works with test account
- [ ] Company registration creates tenant + admin
- [ ] Invitation generation works
- [ ] Invitation validation works
- [ ] User signup with invitation works
- [ ] Admin dashboard loads correctly
- [ ] User management CRUD works
- [ ] Role-based routing works (Admin/Driver)
- [ ] Sign out works
- [ ] Map loads (if Google Maps key configured)

### Data Verification (Firebase Console)
- [ ] `tenants` collection has documents
- [ ] `users` collection has documents with correct `tenantId`
- [ ] `invitations` collection has documents
- [ ] Security rules are deployed (NOT test mode)

## 📝 Documentation Review

### README.md
- [ ] Project description is accurate
- [ ] Features list is up-to-date
- [ ] Setup instructions are clear
- [ ] Repository URLs updated (search for "YOUR_USERNAME")
- [ ] Contact information updated
- [ ] Screenshots/badges added (optional)

### Other Docs
- [ ] QUICKSTART.md reviewed for accuracy
- [ ] GITHUB_SETUP.md paths are correct
- [ ] PHASE1_COMPLETE.md reflects current state
- [ ] SETUP_CHECKLIST.md is still relevant

## 📂 File Structure

### Required Files Present
- [ ] README.md
- [ ] .gitignore
- [ ] QUICKSTART.md
- [ ] GITHUB_SETUP.md
- [ ] PHASE1_COMPLETE.md
- [ ] SETUP_CHECKLIST.md
- [ ] MULTI_TENANT_GUIDE.md
- [ ] firestore.rules
- [ ] functions_example.js (optional but recommended)

### Optional But Recommended
- [ ] LICENSE (MIT recommended)
- [ ] CONTRIBUTING.md
- [ ] CHANGELOG.md
- [ ] .github/ISSUE_TEMPLATE/ (issue templates)
- [ ] .github/pull_request_template.md

## 🔧 Configuration Files

### Create Config Files
- [ ] Create `Config.example.plist` with placeholders:
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
  <plist version="1.0">
  <dict>
      <key>GoogleMapsAPIKey</key>
      <string>YOUR_GOOGLE_MAPS_API_KEY_HERE</string>
  </dict>
  </plist>
  ```
- [ ] Add note in README about copying Config.example.plist → Config.plist

### Update GeoGuardApp.swift
- [ ] Remove hardcoded API key
- [ ] Load from Config.plist or environment variable
- [ ] Add clear error message if key missing

Example:
```swift
init() {
    // Load API key from Config.plist
    guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
          let config = NSDictionary(contentsOfFile: path),
          let apiKey = config["GoogleMapsAPIKey"] as? String else {
        fatalError("⚠️ Config.plist not found or GoogleMapsAPIKey missing!\n\nPlease:\n1. Copy Config.example.plist → Config.plist\n2. Add your Google Maps API key")
    }
    
    GMSServices.provideAPIKey(apiKey)
    FirebaseApp.configure()
}
```

## 🎨 Code Quality

### Swift Code
- [ ] No force unwraps (`!`) without good reason
- [ ] Proper error handling (no `try!` except in safe contexts)
- [ ] Consistent naming conventions
- [ ] Comments on complex logic
- [ ] No debug/test code left in
- [ ] No unused imports
- [ ] No unused variables/functions

### SwiftUI Best Practices
- [ ] @State for local view state
- [ ] @StateObject for view models
- [ ] @EnvironmentObject for shared services
- [ ] Proper use of @MainActor
- [ ] No force unwrapping in views

## 📊 Firebase Configuration

### Firestore
- [ ] Security rules deployed (NOT test mode!)
- [ ] Indexes created (check console for warnings)
- [ ] Collections structured correctly

### Authentication
- [ ] Email/Password provider enabled
- [ ] Password policy configured
- [ ] Email verification settings reviewed

### Cloud Functions (Optional)
- [ ] Functions deployed if using
- [ ] Environment variables configured
- [ ] Test functions work

## 🎯 Git Setup

### Initialize Repository
```bash
# In project directory
git init

# Check .gitignore is working
git status

# Expected: Should NOT see:
# - GoogleService-Info.plist
# - xcuserdata/
# - .DS_Store
# - Pods/ (if using CocoaPods)
```

### Create .gitattributes (Optional)
```bash
echo "*.pbxproj merge=union" > .gitattributes
```
This helps with Xcode project file merges.

### First Commit
```bash
git add .
git commit -m "🎉 Initial commit: GeoGuard Phase 1

Multi-tenant fleet tracking application with:
- Complete authentication & authorization
- Role-based access control
- Company registration & invitation system
- Admin dashboard with user management
- Firebase & Google Maps integration
- SwiftUI + Swift Concurrency

Phase 1 complete - Foundation ready for deployment"
```

## 🌐 GitHub Setup

### Create Repository
- [ ] Repository name: `geoguard` or `GeoGuard`
- [ ] Description: "Multi-Tenant Fleet Tracking & Geofencing iOS App"
- [ ] Visibility: Public or Private
- [ ] DON'T initialize with README/License/.gitignore (you have them)

### Repository Settings
- [ ] Add topics/tags: `swift`, `swiftui`, `ios`, `firebase`, `fleet-tracking`, `geofencing`, `multi-tenant`
- [ ] Set "About" description
- [ ] Add website URL if available
- [ ] Enable Discussions (optional)
- [ ] Enable Issues

### Push Code
```bash
git remote add origin https://github.com/YOUR_USERNAME/geoguard.git
git branch -M main
git push -u origin main
```

### Create First Release
- [ ] Tag: `v0.1.0`
- [ ] Title: "GeoGuard v0.1.0 - Phase 1 Complete"
- [ ] Description: See template in GITHUB_SETUP.md
- [ ] Publish release

## 📱 Optional Enhancements

### Screenshots
Add to `/Screenshots/` folder:
- [ ] Login screen
- [ ] Company registration
- [ ] Admin dashboard
- [ ] User management
- [ ] Invitation creation

Update README.md with:
```markdown
## 📸 Screenshots

<table>
  <tr>
    <td><img src="Screenshots/login.png" width="200"/></td>
    <td><img src="Screenshots/dashboard.png" width="200"/></td>
    <td><img src="Screenshots/users.png" width="200"/></td>
  </tr>
</table>
```

### Badges
Add to top of README.md:
```markdown
![Platform](https://img.shields.io/badge/platform-iOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-0.1.0-blue)
```

### Demo GIF
- [ ] Record demo using QuickTime or SimGIF
- [ ] Add to README: `![Demo](demo.gif)`

## ✅ Final Verification

### Before Pushing
- [ ] Read through this entire checklist
- [ ] All security items addressed
- [ ] All tests passing
- [ ] Documentation reviewed
- [ ] Sensitive data removed

### After Pushing
- [ ] Repository visible on GitHub
- [ ] README displays correctly
- [ ] No sensitive files in repo
- [ ] Clone on new machine and test setup
- [ ] All links in README work

## 🎉 Post-Publication

### Share Your Work
- [ ] Post on Twitter/X
- [ ] Share on LinkedIn
- [ ] Post in iOS dev communities
- [ ] Add to your portfolio

### Set Up Project Management
- [ ] Create issues for Phase 2 features
- [ ] Set up GitHub Projects board
- [ ] Create milestones

### Documentation
- [ ] Add to README: "How to Contribute"
- [ ] Create CONTRIBUTING.md
- [ ] Add CODE_OF_CONDUCT.md (optional)

---

## 🆘 Common Issues & Solutions

### Issue: "Permission denied" on git push
**Solution:**
```bash
# Use HTTPS:
git remote set-url origin https://github.com/YOUR_USERNAME/geoguard.git

# Or SSH (if configured):
git remote set-url origin git@github.com:YOUR_USERNAME/geoguard.git
```

### Issue: GoogleService-Info.plist shows up in git
**Solution:**
```bash
# Remove from git but keep locally
git rm --cached GoogleService-Info.plist
git commit -m "Remove sensitive file"

# Verify .gitignore has:
# GoogleService-Info.plist
```

### Issue: Too many files to commit
**Solution:**
```bash
# Check .gitignore is working
git check-ignore -v xcuserdata/

# If not ignored, fix .gitignore then:
git rm -r --cached xcuserdata/
git commit -m "Fix gitignore"
```

### Issue: Merge conflicts in .xcodeproj
**Solution:**
```bash
# Add to .gitattributes
echo "*.pbxproj merge=union" >> .gitattributes
git add .gitattributes
git commit -m "Add merge strategy for Xcode project"
```

---

## 📞 Need Help?

- **Setup Issues**: See QUICKSTART.md
- **Architecture Questions**: See MULTI_TENANT_GUIDE.md  
- **GitHub Specific**: See GITHUB_SETUP.md
- **Firebase Issues**: Check Firebase Console logs

---

## ✨ You're Ready When...

- ✅ All items in "Security Review" checked
- ✅ All items in "Build & Test" checked
- ✅ All items in "Git Setup" checked
- ✅ No compiler warnings or errors
- ✅ Documentation reviewed and updated

---

**Next Step:** Follow GITHUB_SETUP.md for detailed push instructions!

Good luck! 🚀

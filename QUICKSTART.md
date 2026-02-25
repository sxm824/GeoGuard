# 🚀 Quick Start Guide

This guide will help you get GeoGuard up and running in under 10 minutes.

## ⚡ Quick Setup (Essential Steps Only)

### 1. Prerequisites
- ✅ Xcode 15.0+ installed
- ✅ Firebase account (free tier works)
- ✅ Google Cloud account (for Maps API)

### 2. Firebase Setup (5 minutes)

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com
   - Click "Add project"
   - Name it "GeoGuard" (or your preference)
   - Disable Google Analytics (optional)

2. **Add iOS App**
   - Click iOS icon
   - Bundle ID: `com.yourdomain.geoguard` (or match your Xcode project)
   - Download `GoogleService-Info.plist`
   - Drag it into your Xcode project root

3. **Enable Authentication**
   - In Firebase Console: Authentication → Sign-in method
   - Enable "Email/Password"
   - Save

4. **Create Firestore Database**
   - In Firebase Console: Firestore Database → Create database
   - Start in **test mode** for now
   - Choose a location close to your users
   - Click Enable

5. **Deploy Security Rules** 🔒 **CRITICAL**
   ```bash
   # Install Firebase CLI if you haven't
   npm install -g firebase-tools
   
   # Login
   firebase login
   
   # Initialize (in your project directory)
   firebase init firestore
   # Select your Firebase project
   # Accept default files
   
   # Copy the security rules
   # The rules are in firestore.rules file
   
   # Deploy
   firebase deploy --only firestore:rules
   ```

### 3. Google Maps Setup (3 minutes)

1. **Get API Key**
   - Go to https://console.cloud.google.com
   - Create new project or select existing
   - Enable "Maps SDK for iOS"
   - Enable "Places API"
   - Create credentials → API Key

2. **Restrict API Key** (Recommended)
   - In API Key settings
   - Application restrictions → iOS apps
   - Add your bundle ID
   - API restrictions → Restrict key
   - Select: Maps SDK for iOS, Places API

3. **Add to App**
   - Open `GeoGuardApp.swift`
   - Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual key

### 4. Build & Run (2 minutes)

1. Open `GeoGuard.xcodeproj` in Xcode
2. Wait for Swift Package Manager to resolve dependencies
3. Select your target device/simulator
4. Press ⌘R to build and run

## 🎯 First Time Usage

### Create Your Company

1. Launch the app
2. Click "Register Your Company"
3. Fill in:
   - Company name
   - Your admin email & password
   - Personal details
   - Address (use autocomplete!)
   - Subscription tier (choose Trial for testing)
4. Click "Create Company Account"
5. ✅ You're now logged in as admin!

### Invite an Employee

1. In the Admin Dashboard, click "Create Invitation"
2. Choose role (e.g., Driver)
3. Set expiration (default: 7 days)
4. Click "Generate"
5. Copy the code (e.g., "ABC12XYZ")
6. Share with your employee

### Sign Up as Employee (Testing)

1. Sign out from the menu
2. Click "Create Account"
3. Enter the invitation code
4. Click "Validate" (should show green checkmark)
5. Complete signup form
6. ✅ Logged in as driver!

## 🔧 Troubleshooting

### "Permission denied" errors
**Solution:** Make sure you deployed Firestore security rules
```bash
firebase deploy --only firestore:rules
```

### Map doesn't show
**Solution:** Check your Google Maps API key
- Verify it's correct in `GeoGuardApp.swift`
- Ensure Maps SDK for iOS is enabled
- Check billing is enabled in Google Cloud Console

### Can't sign up
**Solution:** Check Firebase Authentication
- Ensure Email/Password provider is enabled
- Check Firebase Console for error logs

### Invitation code doesn't work
**Solution:** Check Firestore
- Go to Firebase Console → Firestore Database
- Look for "invitations" collection
- Verify the invitation exists and isn't expired

## 📚 Next Steps

Once everything is working:

1. ✅ Deploy Cloud Functions (see SETUP_CHECKLIST.md)
2. ✅ Set up email notifications
3. ✅ Add more users and test different roles
4. ✅ Start building geofencing features

## 🆘 Need Help?

- Check the full documentation in SETUP_CHECKLIST.md
- Review Firebase logs for errors
- Check Xcode console for error messages
- Review MULTI_TENANT_GUIDE.md for architecture details

## ⚠️ Important Security Notes

### Before Production:
1. **Deploy proper Firestore security rules** (not test mode)
2. **Set up Cloud Functions** for custom claims
3. **Restrict API keys** to your app's bundle ID
4. **Enable App Check** in Firebase
5. **Review and test all permissions**

### Test Mode Warning:
If you started Firestore in test mode, your data is **publicly readable** for 30 days. Deploy the security rules immediately!

---

🎉 **You're all set! Enjoy building with GeoGuard!**

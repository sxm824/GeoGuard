# 🛡️ GeoGuard

**Multi-Tenant Fleet Tracking & Geofencing Application**

GeoGuard is a modern iOS application built with SwiftUI and Firebase that enables companies to track their fleet, manage geofences, and monitor driver locations in real-time. The app features a complete multi-tenant architecture allowing multiple companies to use the same platform with full data isolation.

![Platform](https://img.shields.io/badge/platform-iOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![Firebase](https://img.shields.io/badge/Firebase-✓-yellow)

## ✨ Features

### 🏢 Multi-Tenant Architecture
- **Complete tenant isolation** - Each company's data is fully separated
- **Role-based access control** (Super Admin, Admin, Manager, Driver)
- **Invitation-based onboarding** - Secure employee signup with 8-character codes
- **Company registration flow** - Self-service company account creation
- **Domain-based auto-join** - Optional email domain matching

### 👥 User Management
- Create and manage users within your organization
- Assign roles and permissions
- Activate/deactivate user accounts
- Track user activity and login history

### 📨 Invitation System
- Generate secure invitation codes
- Optional email-specific invitations
- Configurable expiration (1-30 days)
- Track invitation usage
- Copy-to-clipboard functionality

### 🗺️ Fleet Tracking (In Progress)
- Real-time driver location tracking
- Interactive Google Maps integration
- Vehicle assignment and management
- Route history

### 📊 Admin Dashboard
- User statistics and analytics
- Quick access to common tasks
- Recent user activity
- Active invitation overview

## 🏗️ Architecture

### Tech Stack
- **Frontend**: SwiftUI
- **Backend**: Firebase (Authentication, Firestore, Cloud Functions)
- **Maps**: Google Maps SDK for iOS
- **Places**: Google Places API (for address autocomplete)

### Project Structure
```
GeoGuard/
├── Models/
│   ├── Tenant.swift              # Company/organization model
│   ├── User.swift                # User model with tenant relationship
│   └── UserRole.swift            # Role definitions & permissions
├── Services/
│   ├── AuthService.swift         # Authentication management
│   ├── TenantService.swift       # Tenant CRUD operations
│   └── InvitationService.swift  # Invitation generation & validation
├── Views/
│   ├── LoginView.swift
│   ├── SignupView.swift
│   ├── CompanyRegistrationView.swift
│   ├── AdminDashboardView.swift
│   ├── UserManagementView.swift
│   ├── InvitationManagementView.swift
│   ├── CompanySettingsView.swift
│   └── DriverDashboardView.swift
└── GeoGuardApp.swift             # App entry point & routing
```

### Data Model

**Firestore Collections:**
- `tenants/` - Company information
- `users/` - User profiles (linked to tenants)
- `invitations/` - Invitation codes
- `geofences/` - Geofence definitions (coming soon)

**Key Relationships:**
```
Tenant (1) ──→ (many) Users
Tenant (1) ──→ (many) Invitations
User (1) ──→ (many) Geofences
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Firebase account
- Google Maps API key

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/geoguard.git
   cd geoguard
   ```

2. **Install Dependencies**
   - Open `GeoGuard.xcodeproj` in Xcode
   - Firebase packages should auto-resolve via SPM
   - Install Google Maps SDK (CocoaPods or SPM)

3. **Firebase Configuration**
   - Create a new Firebase project at https://console.firebase.google.com
   - Enable Authentication (Email/Password provider)
   - Create a Firestore database
   - Download `GoogleService-Info.plist` and add to project

4. **Deploy Firestore Security Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```
   (Rules file located at `firestore.rules`)

5. **Set Up Cloud Functions** (Optional but recommended)
   ```bash
   firebase init functions
   # Copy content from functions_example.js to functions/index.js
   cd functions && npm install
   firebase deploy --only functions
   ```

6. **Configure Google Maps**
   - Get an API key from Google Cloud Console
   - Enable Maps SDK for iOS and Places API
   - Update the API key in `GeoGuardApp.swift`

7. **Build and Run**
   - Select your target device/simulator
   - Press ⌘R to build and run

## 📱 Usage

### For Company Admins

1. **Register Your Company**
   - Open the app and click "Register Your Company"
   - Fill in company details and admin account info
   - Choose your subscription tier

2. **Invite Employees**
   - Log in with your admin account
   - Navigate to Invitations → Create Invitation
   - Share the generated code with your employee

3. **Manage Users**
   - View all users in your organization
   - Edit roles and permissions
   - Activate/deactivate accounts

### For Employees

1. **Sign Up with Invitation**
   - Open the app and click "Create Account"
   - Enter your invitation code
   - Complete the signup form

2. **Access the App**
   - Log in with your credentials
   - Access features based on your role

## 🔐 Security

- **Tenant Isolation**: Firestore security rules enforce strict data separation
- **Role-Based Access**: Custom claims control what users can access
- **Secure Authentication**: Firebase Authentication handles user management
- **Code Generation**: Cryptographically secure random invitation codes

## 📋 Roadmap

### Phase 1: Foundation ✅ (Completed)
- [x] Multi-tenant architecture
- [x] User authentication & authorization
- [x] Company registration
- [x] Invitation system
- [x] Admin dashboard
- [x] User management

### Phase 2: Core Features (In Progress)
- [ ] Real-time location tracking
- [ ] Geofence creation & management
- [ ] Geofence breach alerts
- [ ] Route history & reporting
- [ ] Vehicle management

### Phase 3: Polish & Launch
- [ ] Push notifications
- [ ] Email notifications
- [ ] Advanced analytics
- [ ] Billing/subscription management
- [ ] Company branding (logos, colors)
- [ ] App Store submission

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Firebase for backend infrastructure
- Google Maps for mapping capabilities
- SwiftUI for the modern UI framework

## 📧 Contact

Saleh Mukbil - [@yourusername](https://twitter.com/yourusername)

Project Link: [https://github.com/yourusername/geoguard](https://github.com/yourusername/geoguard)

---

Built with ❤️ using SwiftUI and Firebase

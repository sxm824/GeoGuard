# 🛡️ GeoGuard

**Multi-Tenant Personnel Safety Tracking & Geofencing Application**

GeoGuard is a modern iOS application built with SwiftUI and Firebase that enables organizations to track personnel in high-risk environments, manage safety zones (geofences), and monitor locations in real-time for security and safety purposes. Designed for NGOs, security contractors, news organizations, and humanitarian agencies operating in conflict zones and dangerous areas.

The app features a complete multi-tenant architecture allowing multiple organizations to use the same platform with full data isolation and security.

![Platform](https://img.shields.io/badge/platform-iOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![Firebase](https://img.shields.io/badge/Firebase-✓-yellow)

## ✨ Features

### 🏢 Multi-Tenant Architecture
- **Complete tenant isolation** - Each organization's data is fully separated
- **Role-based access control** (Admin, Manager, Field Personnel)
- **Invitation-based onboarding** - Secure personnel signup with 8-character codes
- **Organization registration flow** - Self-service organizational account creation
- **Domain-based auto-join** - Optional email domain matching

### 👥 Personnel Management
- Create and manage personnel within your organization
- Assign roles and permissions
- Activate/deactivate accounts
- Track personnel activity and login history
- Emergency contact information

### 🛡️ Safety Features
- **Real-time location tracking** of field personnel
- **Safety zones (geofences)** for secure/danger areas
- **Breach notifications** when personnel enter/exit zones
- **Emergency alerts** and check-in system
- **Location history** for incident investigation

### 📨 Invitation System
- Generate secure invitation codes
- Optional email-specific invitations
- Configurable expiration (1-30 days)
- Track invitation usage
- Copy-to-clipboard functionality

### 🗺️ Location & Mapping
- Interactive Google Maps integration
- Real-time personnel location tracking
- Safety zone visualization
- Route history and movement patterns
- Offline map support (planned)

### 📊 Admin Dashboard
- Personnel statistics and analytics
- Quick access to common tasks
- Recent personnel activity
- Active invitation overview
- Safety zone status

## 🎯 Use Cases

### Humanitarian Organizations
- Track field workers in conflict zones
- Monitor safety zones around safe houses
- Emergency evacuation coordination
- Daily check-in/check-out protocols

### News Organizations
- Track journalists in hostile environments
- Monitor movement between safe zones
- Emergency assistance coordination
- Incident reporting and documentation

### Security Contractors
- Personnel accountability in war zones
- Base perimeter security
- Convoy tracking and coordination
- Quick reaction force deployment

### NGOs & Aid Agencies
- Field worker safety monitoring
- Safe zone management
- Team coordination in remote areas
- Incident response and evacuation

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
│   ├── Tenant.swift              # Organization model
│   ├── User.swift                # Personnel model with tenant relationship
│   └── UserRole.swift            # Role definitions & permissions
├── Services/
│   ├── AuthService.swift         # Authentication management
│   ├── TenantService.swift       # Organization CRUD operations
│   └── InvitationService.swift  # Invitation generation & validation
├── Views/
│   ├── LoginView.swift
│   ├── SignupView.swift
│   ├── CompanyRegistrationView.swift    # Organization registration
│   ├── AdminDashboardView.swift
│   ├── UserManagementView.swift          # Personnel management
│   ├── InvitationManagementView.swift
│   ├── CompanySettingsView.swift         # Organization settings
│   └── DriverDashboardView.swift         # Field personnel view
└── GeoGuardApp.swift             # App entry point & routing
```

### Data Model

**Firestore Collections:**
- `tenants/` - Organization information
- `users/` - Personnel profiles (linked to organizations)
- `invitations/` - Invitation codes
- `geofences/` - Safety zone definitions (coming soon)
- `locations/` - Real-time location data (coming soon)

**Key Relationships:**
```
Organization (1) ──→ (many) Personnel
Organization (1) ──→ (many) Invitations
Organization (1) ──→ (many) Safety Zones
Personnel (1) ──→ (many) Location Updates
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
   - Create `Config.plist` (see QUICKSTART.md)
   - Add your API key to Config.plist

7. **Build and Run**
   - Select your target device/simulator
   - Press ⌘R to build and run

## 📱 Usage

### For Organization Admins

1. **Register Your Organization**
   - Open the app and click "Register Your Company"
   - Fill in organization details and admin account info
   - Choose your subscription tier

2. **Invite Personnel**
   - Log in with your admin account
   - Navigate to Invitations → Create Invitation
   - Share the generated code with your field personnel

3. **Manage Personnel**
   - View all personnel in your organization
   - Edit roles and permissions
   - Activate/deactivate accounts
   - Emergency contact management

4. **Set Up Safety Zones** (Coming in Phase 2)
   - Define safe zones (bases, safe houses)
   - Define danger zones (conflict areas)
   - Set up breach notifications

### For Field Personnel

1. **Sign Up with Invitation**
   - Open the app and click "Create Account"
   - Enter your invitation code from your admin
   - Complete the signup form with emergency contact info

2. **Daily Use**
   - Log in with your credentials
   - Enable location tracking
   - View your assigned safety zones
   - Check in/out as required
   - Report incidents if needed

## 🔐 Security & Privacy

- **Tenant Isolation**: Firestore security rules enforce strict data separation between organizations
- **Role-Based Access**: Custom claims control what personnel can access
- **Secure Authentication**: Firebase Authentication handles user management
- **Location Privacy**: Location data is only visible to organization admins/managers
- **End-to-End Encryption**: All data encrypted in transit and at rest
- **Code Generation**: Cryptographically secure random invitation codes
- **Audit Trail**: All access and changes logged for security review

### Privacy Considerations
- Personnel must explicitly consent to location tracking
- Location data retention policies configurable
- Personnel can see who has access to their location
- Emergency contacts kept private
- Data deletion upon personnel departure

## 📋 Roadmap

### Phase 1: Foundation ✅ (Completed)
- [x] Multi-tenant architecture
- [x] User authentication & authorization
- [x] Organization registration
- [x] Invitation system
- [x] Admin dashboard
- [x] Personnel management

### Phase 2: Safety Features (In Progress)
- [ ] Real-time location tracking with background updates
- [ ] Safety zone (geofence) creation & management
- [ ] Safety zone breach detection & alerts
- [ ] Check-in/check-out system
- [ ] Emergency SOS button
- [ ] Location history & route playback

### Phase 3: Communication & Alerts
- [ ] Push notifications for breaches
- [ ] In-app messaging between personnel
- [ ] Emergency broadcast messages
- [ ] Email/SMS notifications
- [ ] Integration with satellite phones (Iridium)

### Phase 4: Advanced Features
- [ ] Offline map support
- [ ] Incident reporting & documentation
- [ ] Route planning & waypoints
- [ ] Team coordination features
- [ ] Analytics & safety reports
- [ ] Export data for incident investigation

### Phase 5: Enterprise
- [ ] Multi-factor authentication
- [ ] Advanced audit logs
- [ ] Custom branding per organization
- [ ] API for third-party integrations
- [ ] Compliance reporting (ISO, GDPR, etc.)

## 🛡️ Ethical Considerations

GeoGuard is designed for **voluntary personnel safety tracking** in high-risk environments. It is not intended for:
- Surveillance without consent
- Tracking personnel during off-duty hours (unless explicitly agreed)
- Monitoring personal activities

### Best Practices
- Obtain explicit written consent from all tracked personnel
- Clearly communicate when tracking is active
- Establish and document use policies
- Regular privacy training for administrators
- Respect personnel privacy during off-hours
- Provide opt-out for non-critical situations

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
- The humanitarian and journalism communities for inspiration

## 📧 Contact

Saleh Mukbil - [@yourusername](https://twitter.com/yourusername)

Project Link: [https://github.com/yourusername/geoguard](https://github.com/yourusername/geoguard)

---

**⚠️ Important Note**: This software is provided for legitimate safety and security purposes. Users are responsible for ensuring compliance with all applicable laws, regulations, and ethical guidelines regarding personnel tracking and location data.

---

Built with ❤️ for keeping people safe

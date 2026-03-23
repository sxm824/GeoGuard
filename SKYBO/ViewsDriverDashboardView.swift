//
//  DriverDashboardView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import SwiftUI
import GoogleMaps

struct DriverDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var locationManager = LocationManager()
    @StateObject private var alertService = AlertService()
    @StateObject private var reliabilityMonitor = TrackingReliabilityMonitor()
    @State private var showingSignOutAlert = false
    @State private var showingPermissionAlert = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Map Tab
            mapView
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(0)
            
            // Alerts Tab
            UserAlertsView()
                .environmentObject(authService)
                .environmentObject(alertService)  // ✅ Pass alertService
                .tabItem {
                    Label("Alerts", systemImage: "bell.fill")
                }
                .badge(alertService.unreadCount > 0 ? "\(alertService.unreadCount)" : "")
                .tag(1)
            
            // Profile Tab
            profileView
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .onAppear {
            startTrackingIfNeeded()
            startListeningForAlerts()
        }
        .onDisappear {
            reliabilityMonitor.stopMonitoring()
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                locationManager.stopTracking()
                alertService.stopListening()
                try? authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Status Indicators (NEW)
                LocationStatusView(
                    locationManager: locationManager,
                    reliabilityMonitor: reliabilityMonitor,
                    showAllBanners: true,
                    showSyncTime: true
                )
                
                // MARK: - Map Content
                if locationManager.hasAlwaysPermission {
                    // Show map with tracking indicator
                    ZStack(alignment: .topTrailing) {
                        // Only show the current user's location
                        if let userId = authService.currentUser?.id {
                            GoogleMapView(userId: userId, showOnlyUser: true)
                                .edgesIgnoringSafeArea(.bottom)
                        }
                        
                        // Legacy tracking indicator (keep for redundancy)
                        if locationManager.isTracking && locationManager.queuedLocationCount == 0 {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Tracking Active")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(20)
                            .padding()
                        }
                    }
                } else if locationManager.needsPermission {
                    // Permission request view
                    PermissionRequestView(locationManager: locationManager)
                } else if locationManager.permissionDenied {
                    // Permission denied view
                    PermissionDeniedView()
                }
            }
            .navigationTitle("GeoGuard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let user = authService.currentUser {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.fullName)
                                .font(.headline)
                            Text(user.role.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingSignOutAlert = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .imageScale(.large)
                    }
                }
            }
        }
    }
    
    // MARK: - Profile View
    
    private var profileView: some View {
        NavigationStack {
            List {
                // User Info Section
                Section {
                    if let user = authService.currentUser {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text(user.fullName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(user.role.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                }
                
                // Stats Section
                Section("Today's Activity") {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Tracking Active")
                        Spacer()
                        if locationManager.isTracking {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    // NEW: Last Sync Status
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Last Sync")
                        Spacer()
                        LastSyncIndicator(
                            locationManager: locationManager,
                            style: .compact
                        )
                    }
                    
                    // NEW: Queue Status (if any)
                    if locationManager.queuedLocationCount > 0 {
                        HStack {
                            Image(systemName: "tray.full.fill")
                                .foregroundColor(.orange)
                            Text("Queued Locations")
                            Spacer()
                            Text("\(locationManager.queuedLocationCount)")
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // NEW: Battery Status
                    if locationManager.batteryLevel > 0 {
                        HStack {
                            Image(systemName: batteryIcon)
                                .foregroundColor(batteryLevelColor)
                            Text("Device Battery")
                            Spacer()
                            Text("\(Int(locationManager.batteryLevel * 100))%")
                                .foregroundColor(batteryLevelColor)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Alerts Responded")
                        Spacer()
                        Text("\(alertService.totalResponseCount)")  // ✅ Use totalResponseCount
                            .foregroundColor(.secondary)
                    }
                }
                
                // Settings Section
                Section("Settings") {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "location.circle.fill")
                            Text("Location Permissions")
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bell.circle.fill")
                            Text("Notification Settings")
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Sign Out Section
                Section {
                    Button(role: .destructive) {
                        showingSignOutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Helper Computed Properties
    
    private var batteryIcon: String {
        switch locationManager.batteryLevel {
        case 0..<0.10:
            return "battery.0"
        case 0.10..<0.25:
            return "battery.25"
        case 0.25..<0.50:
            return "battery.50"
        case 0.50..<0.75:
            return "battery.75"
        default:
            return "battery.100"
        }
    }
    
    private var batteryLevelColor: Color {
        switch locationManager.batteryLevel {
        case 0..<0.10:
            return .red
        case 0.10..<0.20:
            return .orange
        default:
            return .green
        }
    }
    
    // MARK: - Helper Functions
    
    private func startTrackingIfNeeded() {
        guard let user = authService.currentUser else { return }
        
        if locationManager.hasAlwaysPermission && !locationManager.isTracking {
            // Start location tracking
            locationManager.startTracking(userId: user.id!, tenantId: user.tenantId)
            
            // Start reliability monitoring
            reliabilityMonitor.startMonitoring(
                userId: user.id!,
                tenantId: user.tenantId,
                locationManager: locationManager
            )
            
            print("✅ Location tracking and reliability monitoring started")
        } else if locationManager.needsPermission {
            showingPermissionAlert = true
        }
    }
    
    private func startListeningForAlerts() {
        guard let user = authService.currentUser,
              let userId = user.id else {
            return
        }
        
        alertService.startListeningForUserAlerts(userId: userId, tenantId: user.tenantId)
    }
}

// MARK: - Permission Request View

struct PermissionRequestView: View {
    let locationManager: LocationManager
    @State private var showingInstructions = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 12) {
                Text("Location Permission Required")
                    .font(.title2)
                    .bold()
                
                Text("GeoGuard needs access to your location at all times to ensure your safety.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Text("This allows:")
                    .font(.subheadline)
                    .bold()
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    PermissionBenefitRow(icon: "shield.checkmark", text: "Emergency response tracking")
                    PermissionBenefitRow(icon: "person.2", text: "Team coordination")
                    PermissionBenefitRow(icon: "bell.badge", text: "Safety alerts and check-ins")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
            
            Button(action: {
                print("🔵 Permission button tapped - Current status: \(locationManager.authorizationStatus.rawValue)")
                locationManager.requestPermission()
            }) {
                Text("Enable Location Tracking")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Show when in use permission instructions if needed
            if locationManager.authorizationStatus == .authorizedWhenInUse {
                VStack(spacing: 12) {
                    Text("⚠️ Additional Step Required")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.orange)
                    
                    Text("Please select 'Always' in the permission dialog")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

struct PermissionBenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - Permission Denied View

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.slash.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            VStack(spacing: 12) {
                Text("Location Access Denied")
                    .font(.title2)
                    .bold()
                
                Text("GeoGuard requires location access to track your safety. Please enable it in Settings.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    DriverDashboardView()
        .environmentObject(AuthService())
}

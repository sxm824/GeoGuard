//
//  AdminLocationTrackingView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-02.
//

import SwiftUI
import Combine
import GoogleMaps
import FirebaseFirestore
import CoreLocation

struct AdminLocationTrackingView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AdminLocationTrackingViewModel()
    @State private var selectedUserId: String?
    @State private var showUserList = false
    
    var body: some View {
        ZStack {
            // Map View
            if let tenantId = authService.tenantId {
                EnhancedMapViewAllUsers(
                    tenantId: tenantId,
                    selectedUserId: $selectedUserId,
                    users: viewModel.users
                )
                .ignoresSafeArea()
            }
            
            // Top Controls
            VStack {
                HStack {
                    // User List Toggle
                    Button {
                        withAnimation {
                            showUserList.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            Text("\(viewModel.activeFieldPersonnel.count) Team")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // Refresh Button
                    Button {
                        Task {
                            await viewModel.refreshData(tenantId: authService.tenantId ?? "")
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // User List Drawer
                if showUserList {
                    userListDrawer
                        .transition(.move(edge: .bottom))
                }
            }
            
            // Selected User Details
            if let userId = selectedUserId,
               let user = viewModel.users.first(where: { $0.id == userId }),
               let location = viewModel.locations[userId] {
                VStack {
                    Spacer()
                    userDetailsCard(user: user, location: location)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Team Location Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData(tenantId: authService.tenantId ?? "")
        }
        .onAppear {
            viewModel.startLocationUpdates(tenantId: authService.tenantId ?? "")
        }
        .onDisappear {
            viewModel.stopLocationUpdates()
        }
    }
    
    // MARK: - User List Drawer
    
    var userListDrawer: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Team Members")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    withAnimation {
                        showUserList = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // User List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.activeFieldPersonnel) { user in
                        UserLocationRow(
                            user: user,
                            location: viewModel.locations[user.id ?? ""],
                            isSelected: selectedUserId == user.id
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedUserId = user.id
                                showUserList = false
                            }
                        }
                    }
                    
                    if viewModel.activeFieldPersonnel.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.fill.questionmark")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No Active Team Members")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Team members will appear here when they start sharing their location.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }
                }
                .padding()
            }
            .frame(maxHeight: 400)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
    }
    
    // MARK: - User Details Card
    
    func userDetailsCard(user: User, location: UserLocation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(roleColor(for: user.role).gradient)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(user.initials)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.fullName)
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Role badge
                        HStack(spacing: 2) {
                            Image(systemName: roleIcon(for: user.role))
                                .font(.caption2)
                            Text(user.role.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(roleColor(for: user.role).opacity(0.15))
                        .foregroundColor(roleColor(for: user.role))
                        .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        selectedUserId = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .imageScale(.large)
                }
            }
            
            Divider()
            
            // Location Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("Current Location")
                        .font(.subheadline)
                        .bold()
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("Last updated: \(location.timestamp, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(.secondary)
                    Text("Speed: \(location.speed, specifier: "%.1f") km/h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let address = location.address {
                    HStack(alignment: .top) {
                        Image(systemName: "mappin.circle")
                            .foregroundColor(.secondary)
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Quick Actions
            HStack(spacing: 12) {
                Button {
                    // Open in Maps
                    let url = URL(string: "maps://?ll=\(location.latitude),\(location.longitude)")!
                    UIApplication.shared.open(url)
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Directions")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                NavigationLink {
                    AdminAlertCreationView()
                        .environmentObject(authService)
                } label: {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Send Alert")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    // MARK: - Helper Functions
    
    private func roleColor(for role: UserRole) -> Color {
        switch role {
        case .superAdmin: return .red
        case .admin: return .orange
        case .manager: return .blue
        case .fieldPersonnel: return .green
        }
    }
    
    private func roleIcon(for role: UserRole) -> String {
        switch role {
        case .superAdmin: return "crown.fill"
        case .admin: return "shield.fill"
        case .manager: return "person.badge.key.fill"
        case .fieldPersonnel: return "location.fill"
        }
    }
}

// MARK: - User Location Row

struct UserLocationRow: View {
    let user: User
    let location: UserLocation?
    let isSelected: Bool
    
    private var roleColor: Color {
        switch user.role {
        case .superAdmin: return .red
        case .admin: return .orange
        case .manager: return .blue
        case .fieldPersonnel: return .green
        }
    }
    
    private var roleIcon: String {
        switch user.role {
        case .superAdmin: return "crown.fill"
        case .admin: return "shield.fill"
        case .manager: return "person.badge.key.fill"
        case .fieldPersonnel: return "location.fill"
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(isSelected ? Color.blue.gradient : roleColor.gradient)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(user.initials)
                        .font(.caption)
                        .foregroundColor(.white)
                        .bold()
                }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.fullName)
                        .font(.subheadline)
                        .bold()
                    
                    // Role badge
                    HStack(spacing: 2) {
                        Image(systemName: roleIcon)
                            .font(.caption2)
                        Text(user.role.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(roleColor.opacity(0.15))
                    .foregroundColor(roleColor)
                    .cornerRadius(4)
                }
                
                if let location = location {
                    Text("Updated \(location.timestamp, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Location unavailable")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            if location != nil {
                Image(systemName: "location.fill")
                    .foregroundColor(isSelected ? .blue : .green)
            } else {
                Image(systemName: "location.slash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Enhanced Map View with User Markers

struct EnhancedMapViewAllUsers: UIViewRepresentable {
    let tenantId: String
    @Binding var selectedUserId: String?
    let users: [User]
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(
            withLatitude: 40.7128,
            longitude: -74.0060,
            zoom: 12
        )
        
        let mapView = GMSMapView()
        mapView.camera = camera
        mapView.delegate = context.coordinator
        
        context.coordinator.mapView = mapView
        context.coordinator.tenantId = tenantId
        context.coordinator.users = users
        context.coordinator.selectedUserId = selectedUserId
        context.coordinator.startListeningForAllUsers()
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        context.coordinator.tenantId = tenantId
        context.coordinator.users = users
        context.coordinator.selectedUserId = selectedUserId
        context.coordinator.updateMarkerSelection()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selectedUserId: $selectedUserId)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var mapView: GMSMapView?
        var tenantId: String = ""
        var users: [User] = []
        var selectedUserId: String?
        @Binding var selectedUserIdBinding: String?
        var userMarkers: [String: GMSMarker] = [:]
        var locationListener: ListenerRegistration?
        
        private let db = Firestore.firestore()
        
        init(selectedUserId: Binding<String?>) {
            self._selectedUserIdBinding = selectedUserId
        }
        
        func startListeningForAllUsers() {
            locationListener?.remove()
            
            guard !tenantId.isEmpty else { return }
            
            locationListener = db.collection("locations")
                .whereField("tenantId", isEqualTo: tenantId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self,
                          let mapView = self.mapView,
                          let snapshot = snapshot else {
                        if let error = error {
                            print("❌ Error listening to locations: \(error.localizedDescription)")
                        }
                        return
                    }
                    
                    var hasValidLocation = false
                    var bounds = GMSCoordinateBounds()
                    
                    for document in snapshot.documents {
                        let data = document.data()
                        let userId = document.documentID
                        
                        guard let latitude = data["latitude"] as? Double,
                              let longitude = data["longitude"] as? Double else {
                            continue
                        }
                        
                        let position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        let user = self.users.first { $0.id == userId }
                        
                        if let marker = self.userMarkers[userId] {
                            marker.position = position
                        } else {
                            let marker = GMSMarker()
                            marker.position = position
                            marker.title = user?.fullName ?? "User"
                            marker.snippet = "Tap for details"
                            marker.userData = userId
                            
                            // Custom marker icon based on selection
                            if self.selectedUserId == userId {
                                marker.icon = GMSMarker.markerImage(with: .blue)
                                marker.zIndex = 1000
                            } else {
                                marker.icon = GMSMarker.markerImage(with: .red)
                            }
                            
                            marker.map = mapView
                            self.userMarkers[userId] = marker
                        }
                        
                        bounds = bounds.includingCoordinate(position)
                        hasValidLocation = true
                    }
                    
                    // Fit camera to show all markers
                    if hasValidLocation && self.userMarkers.count > 0 {
                        let update = GMSCameraUpdate.fit(bounds, withPadding: 100)
                        mapView.animate(with: update)
                    }
                    
                    print("✅ Updated map with \(self.userMarkers.count) team members")
                }
        }
        
        func updateMarkerSelection() {
            for (userId, marker) in userMarkers {
                if userId == selectedUserId {
                    marker.icon = GMSMarker.markerImage(with: .blue)
                    marker.zIndex = 1000
                } else {
                    marker.icon = GMSMarker.markerImage(with: .red)
                    marker.zIndex = 0
                }
            }
        }
        
        // MARK: - GMSMapViewDelegate
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let userId = marker.userData as? String {
                selectedUserIdBinding = userId
            }
            return true
        }
        
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            // Deselect when tapping map
            selectedUserIdBinding = nil
        }
        
        deinit {
            locationListener?.remove()
        }
    }
}

// MARK: - User Location Model

struct UserLocation: Codable {
    var userId: String
    var tenantId: String
    var latitude: Double
    var longitude: Double
    var speed: Double
    var accuracy: Double
    var timestamp: Date
    var address: String?
}

// MARK: - ViewModel

@MainActor
class AdminLocationTrackingViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var locations: [String: UserLocation] = [:]
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var locationListener: ListenerRegistration?
    
    var activeFieldPersonnel: [User] {
        // Show all active users, not just field personnel
        users.filter { $0.isActive }
    }
    
    func loadData(tenantId: String) async {
        guard !tenantId.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        await loadUsers(tenantId: tenantId)
        await loadLocations(tenantId: tenantId)
    }
    
    func refreshData(tenantId: String) async {
        await loadData(tenantId: tenantId)
    }
    
    private func loadUsers(tenantId: String) async {
        do {
            // Load ALL users in the tenant, not just field personnel
            let snapshot = try await db.collection("users")
                .whereField("tenantId", isEqualTo: tenantId)
                .getDocuments()
            
            users = snapshot.documents.compactMap { doc in
                try? doc.data(as: User.self)
            }
            
            print("✅ Loaded \(users.count) team members for tracking")
            print("   - Admins: \(users.filter { $0.role == .admin }.count)")
            print("   - Field Personnel: \(users.filter { $0.role == .fieldPersonnel }.count)")
            print("   - Managers: \(users.filter { $0.role == .manager }.count)")
        } catch {
            print("❌ Error loading users: \(error)")
        }
    }
    
    private func loadLocations(tenantId: String) async {
        do {
            let snapshot = try await db.collection("locations")
                .whereField("tenantId", isEqualTo: tenantId)
                .getDocuments()
            
            for document in snapshot.documents {
                if let location = try? document.data(as: UserLocation.self) {
                    locations[location.userId] = location
                }
            }
            
            print("✅ Loaded \(locations.count) locations")
        } catch {
            print("❌ Error loading locations: \(error)")
        }
    }
    
    func startLocationUpdates(tenantId: String) {
        guard !tenantId.isEmpty else { return }
        
        locationListener?.remove()
        
        locationListener = db.collection("locations")
            .whereField("tenantId", isEqualTo: tenantId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let snapshot = snapshot else {
                    if let error = error {
                        print("❌ Error in location listener: \(error)")
                    }
                    return
                }
                
                Task { @MainActor in
                    for document in snapshot.documents {
                        if let location = try? document.data(as: UserLocation.self) {
                            self.locations[location.userId] = location
                        }
                    }
                }
            }
    }
    
    func stopLocationUpdates() {
        locationListener?.remove()
        locationListener = nil
    }
}

// MARK: - Helper Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        AdminLocationTrackingView()
            .environmentObject(AuthService())
    }
}

//
//  SafetyCheckInView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//

import SwiftUI
import CoreLocation
import FirebaseFirestore

struct SafetyCheckInView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var checkInService = SafetyCheckInService()
    @StateObject private var locationManager = LocationManager()
    
    @State private var isSafe = true
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @State private var showingError: String?
    
    // MARK: - Duress Code System (COVERT)
    @State private var duressMode = false
    @State private var checkInCode = ""
    
    // Pre-defined duress codes - DO NOT display to user
    private let duressIndicators = [
        "999",  // General duress code
        "911",  // Emergency duress
        "000"   // Silent duress
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Header
                statusHeader
                
                // Check-in Form
                checkInForm
                
                // Submit Button
                submitButton
                
                // History
                if let lastCheckIn = checkInService.lastCheckIn {
                    lastCheckInCard(lastCheckIn)
                }
            }
            .padding()
        }
        .navigationTitle("Safety Check-in")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Check-in Successful", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your safety status has been recorded. Next check-in due \(checkInService.nextCheckInDue ?? Date(), style: .relative).")
        }
        .alert("Error", isPresented: .init(
            get: { showingError != nil },
            set: { if !$0 { showingError = nil } }
        )) {
            Button("OK", role: .cancel) { showingError = nil }
        } message: {
            if let error = showingError {
                Text(error)
            }
        }
    }
    
    // MARK: - Status Header
    
    var statusHeader: some View {
        VStack(spacing: 16) {
            // Timer indicator
            if let nextDue = checkInService.nextCheckInDue {
                if checkInService.isCheckInOverdue {
                    overdueIndicator
                } else {
                    nextCheckInIndicator(nextDue: nextDue)
                }
            } else {
                firstCheckInIndicator
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    var overdueIndicator: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Check-in Overdue")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text("Please confirm your safety status immediately")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    func nextCheckInIndicator(nextDue: Date) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            Text("Next Check-in")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(nextDue, style: .relative)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
    
    var firstCheckInIndicator: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.badge.shield.checkmark")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Perform Your First Check-in")
                .font(.headline)
            
            Text("Regular check-ins help us ensure your safety")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Check-in Form
    
    var checkInForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Safety Status")
                .font(.headline)
            
            // Safety status toggle
            HStack(spacing: 16) {
                statusButton(
                    title: "I'm Safe",
                    icon: "checkmark.shield.fill",
                    color: .green,
                    isSelected: isSafe
                ) {
                    isSafe = true
                }
                
                statusButton(
                    title: "Need Help",
                    icon: "exclamationmark.shield.fill",
                    color: .red,
                    isSelected: !isSafe
                ) {
                    isSafe = false
                }
            }
            
            // CRITICAL: Duress Code Field (appears normal)
            VStack(alignment: .leading, spacing: 8) {
                Text("Check-in Code (Optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                SecureField("Enter code if required", text: $checkInCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .onChange(of: checkInCode) { oldValue, newValue in
                        // SILENTLY detect duress codes - NO UI CHANGE!
                        if duressIndicators.contains(newValue) {
                            duressMode = true
                            // DO NOT show any visual feedback
                        } else {
                            duressMode = false
                        }
                    }
                
                Text("Use your organization's code if provided")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Notes (optional)
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional Notes (Optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            
            // Location info
            if let location = locationManager.currentLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Lat: \(location.coordinate.latitude, specifier: "%.6f"), Lon: \(location.coordinate.longitude, specifier: "%.6f")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    func statusButton(title: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? color : .secondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Submit Button
    
    var submitButton: some View {
        Button {
            performCheckIn()
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                
                Text(isSubmitting ? "Submitting..." : "Submit Check-in")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSafe ? Color.green : Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isSubmitting || locationManager.currentLocation == nil)
    }
    
    // MARK: - Last Check-in Card
    
    func lastCheckInCard(_ checkIn: SafetyCheckIn) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last Check-in")
                .font(.headline)
            
            HStack {
                Image(systemName: checkIn.status.icon)
                    .foregroundColor(checkIn.isSafe ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(checkIn.status.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(checkIn.checkInTime, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let notes = checkIn.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func performCheckIn() {
        guard let user = authService.currentUser,
              let userId = user.id,
              let tenantId = authService.tenantId,
              let location = locationManager.currentLocation else {
            showingError = "Unable to get your current location or user information."
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                let address = try? await locationManager.reverseGeocode(location: location)
                
                try await checkInService.performCheckIn(
                    userId: userId,
                    userName: user.fullName,
                    tenantId: tenantId,
                    location: location,
                    address: address,
                    isSafe: isSafe,
                    notes: notes.isEmpty ? nil : notes
                )
                
                // CRITICAL: If duress mode, send silent alert to admins
                if duressMode {
                    await sendDuressAlert(
                        userId: userId,
                        userName: user.fullName,
                        userEmail: user.email,
                        tenantId: tenantId,
                        location: location,
                        address: address,
                        checkInNotes: notes
                    )
                    print("🚨 Duress alert sent (COVERT - user not notified)")
                }
                
                // Reset form
                notes = ""
                checkInCode = ""
                duressMode = false
                isSafe = true
                showingSuccess = true
                
            } catch {
                showingError = "Failed to submit check-in: \(error.localizedDescription)"
            }
            
            isSubmitting = false
        }
    }
    
    // MARK: - Duress Alert System
    
    private func sendDuressAlert(
        userId: String,
        userName: String,
        userEmail: String,
        tenantId: String,
        location: CLLocation,
        address: String?,
        checkInNotes: String?
    ) async {
        do {
            // Create COVERT alert - only visible to admins
            let alert = Alert(
                tenantId: tenantId,
                senderId: "system_duress",
                senderName: "Duress Detection System",
                recipientIds: [], // Empty = all admins in tenant
                title: "🚨 DURESS ALERT - COVERT",
                message: """
                COVERT ALERT: \(userName) (\(userEmail)) may be under duress or coercion.
                
                The check-in appeared normal but a duress code was entered.
                
                ⚠️ CRITICAL: DO NOT contact \(userName) directly - this may compromise their safety.
                
                Last Location: \(address ?? "Unknown")
                Coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)
                Time: \(Date().formatted())
                Check-in Notes: \(checkInNotes ?? "None")
                
                RECOMMENDED ACTIONS:
                - Monitor location discreetly
                - Coordinate with security team
                - Prepare discreet extraction if needed
                - DO NOT send notifications to personnel's device
                """,
                priority: .critical,
                type: .emergency,
                requiresResponse: true,
                quickResponses: [
                    "Monitoring situation",
                    "Security team notified",
                    "Discreet check planned",
                    "Extraction being coordinated"
                ],
                allowCustomResponse: true,
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(86400), // 24 hours
                isActive: true
            )
            
            _ = try await Firestore.firestore().collection("alerts").addDocument(from: alert)
            
            // Log to console but DO NOT notify user
            print("🔇 DURESS ALERT sent silently to admins")
            print("   User: \(userName)")
            print("   Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("   Time: \(Date())")
            
        } catch {
            // Even if alert fails, log it
            print("❌ Failed to send duress alert: \(error.localizedDescription)")
            print("   CRITICAL: Manual intervention may be needed for \(userName)")
        }
    }
}

#Preview {
    NavigationStack {
        SafetyCheckInView()
            .environmentObject(AuthService())
    }
}

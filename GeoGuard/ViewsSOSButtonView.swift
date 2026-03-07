//
//  SOSButtonView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//

import SwiftUI
import CoreLocation

struct SOSButtonView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var sosService = SOSService()
    @StateObject private var locationManager = LocationManager()
    
    @State private var showingConfirmation = false
    @State private var showingCancelConfirmation = false
    @State private var showingSilentOption = false
    @State private var isSilentMode = false
    @State private var isTriggering = false
    @State private var showingError: String?
    
    // Haptic feedback
    private let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    var body: some View {
        ZStack {
            if sosService.isSOSActive {
                activeSOSView
            } else {
                sosButtonView
            }
        }
        .alert("Trigger SOS Emergency?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Silent SOS", role: .none) {
                isSilentMode = true
                triggerSOS()
            }
            Button("Alert SOS", role: .destructive) {
                isSilentMode = false
                triggerSOS()
            }
        } message: {
            Text("This will send an emergency alert to all administrators with your current location.\n\n• Silent SOS: Discreet alert for sensitive situations\n• Alert SOS: Full notification with sound")
        }
        .alert("Cancel SOS?", isPresented: $showingCancelConfirmation) {
            Button("No", role: .cancel) { }
            Button("Yes, False Alarm", role: .destructive) {
                cancelSOS()
            }
        } message: {
            Text("Are you sure you want to cancel this SOS? This will mark it as a false alarm.")
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
    
    // MARK: - SOS Button
    
    var sosButtonView: some View {
        Button {
            impactFeedback.impactOccurred()
            showingConfirmation = true
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    // Pulsing rings
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 4)
                        .frame(width: 140, height: 140)
                        .scaleEffect(1.2)
                    
                    Circle()
                        .stroke(Color.red.opacity(0.2), lineWidth: 4)
                        .frame(width: 160, height: 160)
                        .scaleEffect(1.4)
                    
                    // Main button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .red.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 4) {
                        Image(systemName: "sos.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("SOS")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                    }
                }
                
                Text("Emergency")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .disabled(isTriggering)
    }
    
    // MARK: - Active SOS View
    
    var activeSOSView: some View {
        VStack(spacing: 20) {
            // Active indicator
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 3)
                            .scaleEffect(1.5)
                            .opacity(0.5)
                    }
                
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
            }
            
            VStack(spacing: 8) {
                Text("SOS Active")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("Help is being notified")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let sosAlert = sosService.currentSOSAlert {
                    Text("Triggered \(sosAlert.triggeredAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Cancel button
            Button {
                showingCancelConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Cancel SOS (False Alarm)")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    // MARK: - Actions
    
    private func triggerSOS() {
        guard let user = authService.currentUser,
              let userId = user.id,
              let tenantId = authService.tenantId,
              let location = locationManager.currentLocation else {
            showingError = "Unable to get your current location. Please enable location services."
            return
        }
        
        isTriggering = true
        
        Task {
            do {
                impactFeedback.prepare()
                impactFeedback.impactOccurred()
                
                // Get address
                let address = try? await locationManager.reverseGeocode(location: location)
                
                _ = try await sosService.triggerSOS(
                    userId: userId,
                    userName: user.fullName,
                    userEmail: user.email,
                    tenantId: tenantId,
                    location: location,
                    address: address,
                    isSilentMode: isSilentMode
                )
                
                notificationFeedback.notificationOccurred(.success)
                
                print("✅ SOS triggered successfully")
            } catch {
                notificationFeedback.notificationOccurred(.error)
                showingError = "Failed to trigger SOS: \(error.localizedDescription)"
            }
            
            isTriggering = false
        }
    }
    
    private func cancelSOS() {
        guard let user = authService.currentUser,
              let userId = user.id,
              let sosId = sosService.currentSOSAlert?.id else {
            return
        }
        
        Task {
            do {
                try await sosService.cancelSOS(sosId: sosId, userId: userId)
                notificationFeedback.notificationOccurred(.success)
            } catch {
                showingError = "Failed to cancel SOS: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Compact SOS Button (for toolbars/navigation)

struct CompactSOSButton: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var sosService = SOSService()
    @State private var showingSOSView = false
    
    var body: some View {
        Button {
            showingSOSView = true
        } label: {
            ZStack {
                Circle()
                    .fill(sosService.isSOSActive ? Color.red : Color.red.opacity(0.8))
                    .frame(width: 44, height: 44)
                
                if sosService.isSOSActive {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                } else {
                    Text("SOS")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingSOSView) {
            NavigationStack {
                SOSButtonView()
                    .environmentObject(authService)
                    .navigationTitle("Emergency SOS")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showingSOSView = false
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    SOSButtonView()
        .environmentObject(AuthService())
}

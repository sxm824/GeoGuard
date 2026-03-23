//
//  FieldPersonnelDashboardView.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//  Example dashboard integrating Phase 1 safety features
//

import SwiftUI

struct FieldPersonnelDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var checkInService = SafetyCheckInService()
    @State private var showingCheckIn = false
    @State private var showingIncidentReport = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader
                    
                    // CRITICAL: SOS Emergency Button
                    sosEmergencyButton
                    
                    // Safety Check-in Status
                    checkInStatusCard
                    
                    // Quick Actions
                    quickActionsGrid
                    
                    // Recent Activity
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Compact SOS button always visible
                    CompactSOSButton()
                        .environmentObject(authService)
                }
            }
            .sheet(isPresented: $showingCheckIn) {
                SafetyCheckInView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingIncidentReport) {
                IncidentReportView()
                    .environmentObject(authService)
            }
        }
    }
    
    // MARK: - Welcome Header
    
    var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(authService.currentUser?.fullName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Safety status indicator
            if checkInService.isCheckInOverdue {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Check-in Overdue")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else if let nextDue = checkInService.nextCheckInDue {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Next check-in")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(nextDue, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - SOS Emergency Button
    
    var sosEmergencyButton: some View {
        VStack(spacing: 12) {
            Text("Emergency?")
                .font(.headline)
            
            SOSButtonView()
                .environmentObject(authService)
            
            Text("Press for immediate help")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.red.opacity(0.1), Color.red.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Check-in Status Card
    
    var checkInStatusCard: some View {
        Button {
            showingCheckIn = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: checkInService.isCheckInOverdue ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                            .foregroundColor(checkInService.isCheckInOverdue ? .red : .green)
                        
                        Text("Safety Check-in")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    if checkInService.isCheckInOverdue {
                        Text("Overdue - Check in now")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    } else if let nextDue = checkInService.nextCheckInDue {
                        Text("Next due \(nextDue, style: .relative)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Perform your first check-in")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                checkInService.isCheckInOverdue 
                    ? Color.red.opacity(0.1) 
                    : Color.clear
            )
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Quick Actions
    
    var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                QuickActionCard(
                    title: "Report Incident",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                ) {
                    showingIncidentReport = true
                }
                
                QuickActionCard(
                    title: "My Location",
                    icon: "location.fill",
                    color: .blue
                ) {
                    // Navigate to location view
                }
                
                QuickActionCard(
                    title: "Geofences",
                    icon: "map.circle.fill",
                    color: .purple
                ) {
                    // Navigate to geofences view
                }
                
                QuickActionCard(
                    title: "Alerts",
                    icon: "bell.fill",
                    color: .green
                ) {
                    // Navigate to alerts view
                }
            }
        }
    }
    
    // MARK: - Recent Activity
    
    var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
            
            if let lastCheckIn = checkInService.lastCheckIn {
                ActivityCard(
                    icon: "checkmark.shield.fill",
                    title: "Safety Check-in",
                    subtitle: lastCheckIn.isSafe ? "Marked as safe" : "Requested help",
                    time: lastCheckIn.checkInTime,
                    color: lastCheckIn.isSafe ? .green : .orange
                )
            }
            
            // Placeholder for other activities
            ActivityCard(
                icon: "location.fill",
                title: "Location Updated",
                subtitle: "GPS tracking active",
                time: Date(),
                color: .blue
            )
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
}

// MARK: - Activity Card

struct ActivityCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: Date
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

#Preview {
    FieldPersonnelDashboardView()
        .environmentObject(AuthService())
}

//
//  LocationStatusIndicators.swift
//  GeoGuard
//
//  Created on 2026-03-06.
//  Status indicators for location tracking
//

import SwiftUI

// MARK: - Offline Status Banner

struct OfflineStatusBanner: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        if locationManager.queuedLocationCount > 0 {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                    .imageScale(.medium)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Offline Mode")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("\(locationManager.queuedLocationCount) location\(locationManager.queuedLocationCount == 1 ? "" : "s") queued for sync")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Queue indicator
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Text("\(locationManager.queuedLocationCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.orange.opacity(0.1))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.orange.opacity(0.3)),
                alignment: .bottom
            )
        }
    }
}

// MARK: - Battery Warning Banner

struct BatteryWarningBanner: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        if locationManager.batteryLevel < 0.20 && locationManager.batteryLevel > 0 {
            HStack {
                Image(systemName: batteryIcon)
                    .foregroundColor(batteryColor)
                    .imageScale(.medium)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Battery Saving Mode")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(batteryColor)
                    
                    Text("Location updates reduced to \(updateInterval)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Battery percentage
                Text("\(Int(locationManager.batteryLevel * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(batteryColor)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(batteryColor.opacity(0.1))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(batteryColor.opacity(0.3)),
                alignment: .bottom
            )
        }
    }
    
    private var batteryIcon: String {
        switch locationManager.batteryLevel {
        case 0..<0.10:
            return "battery.0"
        case 0.10..<0.20:
            return "battery.25"
        default:
            return "battery.50"
        }
    }
    
    private var batteryColor: Color {
        if locationManager.batteryLevel < 0.10 {
            return .red
        } else {
            return .orange
        }
    }
    
    private var updateInterval: String {
        switch locationManager.batteryLevel {
        case 0..<0.10:
            return "every 5 minutes"
        case 0.10..<0.20:
            return "every 2 minutes"
        case 0.20..<0.50:
            return "every minute"
        default:
            return "every 30 seconds"
        }
    }
}

// MARK: - Last Sync Time Indicator

struct LastSyncIndicator: View {
    @ObservedObject var locationManager: LocationManager
    var style: SyncIndicatorStyle = .compact
    
    var body: some View {
        Group {
            if let lastSync = locationManager.lastSuccessfulSync {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .imageScale(style == .compact ? .small : .medium)
                    
                    if style == .detailed {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Last Synced")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(lastSync, style: .relative)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    } else {
                        Text("Synced \(lastSync, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else if locationManager.isTracking {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    
                    Text("Waiting for first sync...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    enum SyncIndicatorStyle {
        case compact, detailed
    }
}

// MARK: - Tracking Reliability Banner

struct TrackingReliabilityBanner: View {
    @ObservedObject var monitor: TrackingReliabilityMonitor
    
    var body: some View {
        if !monitor.isReliable, let issue = monitor.lastIssueDetected {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .imageScale(.medium)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tracking May Be Affected")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text(issue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button {
                    // Open settings
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Fix")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.1))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.red.opacity(0.3)),
                alignment: .bottom
            )
        }
    }
}

// MARK: - Combined Location Status View

struct LocationStatusView: View {
    @ObservedObject var locationManager: LocationManager
    var reliabilityMonitor: TrackingReliabilityMonitor? = nil
    var showAllBanners: Bool = true
    var showSyncTime: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Reliability warning (highest priority!)
            if let monitor = reliabilityMonitor {
                TrackingReliabilityBanner(monitor: monitor)
            }
            
            // Offline banner
            if showAllBanners {
                OfflineStatusBanner(locationManager: locationManager)
            }
            
            // Battery warning
            if showAllBanners {
                BatteryWarningBanner(locationManager: locationManager)
            }
            
            // Last sync time (subtle, at bottom)
            if showSyncTime {
                HStack {
                    LastSyncIndicator(locationManager: locationManager, style: .compact)
                    
                    Spacer()
                    
                    // Tracking status
                    if locationManager.isTracking {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            
                            Text("Tracking Active")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6).opacity(0.5))
            }
        }
    }
}

// MARK: - Preview

#Preview("Offline Mode") {
    VStack {
        LocationStatusView(locationManager: {
            let manager = LocationManager()
            manager.queuedLocationCount = 42
            manager.lastSuccessfulSync = Date().addingTimeInterval(-300) // 5 mins ago
            return manager
        }())
        
        Spacer()
    }
}

#Preview("Low Battery") {
    VStack {
        LocationStatusView(locationManager: {
            let manager = LocationManager()
            manager.batteryLevel = 0.15
            manager.isTracking = true
            manager.lastSuccessfulSync = Date().addingTimeInterval(-60) // 1 min ago
            return manager
        }())
        
        Spacer()
    }
}

#Preview("Critical Battery") {
    VStack {
        LocationStatusView(locationManager: {
            let manager = LocationManager()
            manager.batteryLevel = 0.08
            manager.isTracking = true
            manager.lastSuccessfulSync = Date().addingTimeInterval(-120) // 2 mins ago
            return manager
        }())
        
        Spacer()
    }
}

#Preview("All Normal") {
    VStack {
        LocationStatusView(locationManager: {
            let manager = LocationManager()
            manager.batteryLevel = 0.75
            manager.isTracking = true
            manager.lastSuccessfulSync = Date().addingTimeInterval(-30) // 30 secs ago
            return manager
        }())
        
        Spacer()
    }
}

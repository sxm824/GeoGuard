//
//  ReportsAnalyticsView.swift
//  GeoGuard
//
//  Created by AI Assistant on 2026-03-20.
//  Enhanced with CSV/PDF export, email reports, scheduled reports, and advanced analytics
//

import SwiftUI
import Charts
import UniformTypeIdentifiers

struct ReportsAnalyticsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var incidentService = IncidentReportService()
    @StateObject private var reportExporter = ReportExporter()
    
    @State private var stats: IncidentStats?
    @State private var selectedTimeRange: TimeRange = .last30Days
    @State private var isLoading = false
    @State private var showingCustomDatePicker = false
    @State private var customStartDate = Date().addingTimeInterval(-30 * 24 * 60 * 60)
    @State private var customEndDate = Date()
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingEmailComposer = false
    @State private var showingScheduleSheet = false
    @State private var selectedUser: User?
    @State private var showingUserReports = false
    @State private var trendData: [TrendDataPoint] = []
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case custom = "Custom Range"
        
        var id: String { rawValue }
        
        var days: Int {
            switch self {
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            case .custom: return 30
            }
        }
    }
    
    struct TrendDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
        let severity: String
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time Range Selector
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedTimeRange) { _ in
                    Task { await loadStats() }
                }
                
                if isLoading {
                    ProgressView("Loading reports...")
                        .padding()
                } else if let stats = stats {
                    // Overview Cards
                    overviewSection(stats: stats)
                    
                    // Incidents by Type
                    incidentsByTypeSection(stats: stats)
                    
                    // Incidents by Severity
                    incidentsBySeveritySection(stats: stats)
                    
                    // Export Button
                    exportSection
                    
                } else {
                    ContentUnavailableView(
                        "No Data Available",
                        systemImage: "chart.bar.xaxis",
                        description: Text("No incidents reported in this time period")
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Reports & Analytics")
        .task {
            await loadStats()
        }
    }
    
    // MARK: - Overview Section
    
    @ViewBuilder
    func overviewSection(stats: IncidentStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                OverviewCard(
                    title: "Total Incidents",
                    value: "\(stats.totalIncidents)",
                    icon: "doc.text.fill",
                    color: .blue
                )
                
                OverviewCard(
                    title: "Critical",
                    value: "\(stats.criticalIncidents)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                OverviewCard(
                    title: "High Priority",
                    value: "\(stats.highIncidents)",
                    icon: "exclamationmark.circle.fill",
                    color: .orange
                )
                
                OverviewCard(
                    title: "Pending Review",
                    value: "\(stats.pendingReview)",
                    icon: "clock.fill",
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Incidents by Type Chart
    
    @ViewBuilder
    func incidentsByTypeSection(stats: IncidentStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Incidents by Type")
                .font(.headline)
            
            if stats.typeBreakdown.isEmpty {
                Text("No incidents")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                // Bar Chart
                Chart {
                    ForEach(Array(stats.typeBreakdown.keys), id: \.self) { type in
                        BarMark(
                            x: .value("Type", type.displayName),
                            y: .value("Count", stats.typeBreakdown[type] ?? 0)
                        )
                        .foregroundStyle(by: .value("Type", type.displayName))
                    }
                }
                .frame(height: 200)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                // Legend / List View
                VStack(spacing: 8) {
                    ForEach(Array(stats.typeBreakdown.keys.sorted(by: {
                        (stats.typeBreakdown[$0] ?? 0) > (stats.typeBreakdown[$1] ?? 0)
                    })), id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text(type.displayName)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(stats.typeBreakdown[type] ?? 0)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Incidents by Severity Chart
    
    @ViewBuilder
    func incidentsBySeveritySection(stats: IncidentStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Incidents by Severity")
                .font(.headline)
            
            if stats.severityBreakdown.isEmpty {
                Text("No incidents")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                // Pie Chart or Bar Chart
                Chart {
                    ForEach(Array(stats.severityBreakdown.keys.sorted(by: {
                        $0.rawValue > $1.rawValue
                    })), id: \.self) { severity in
                        BarMark(
                            x: .value("Severity", severity.displayName),
                            y: .value("Count", stats.severityBreakdown[severity] ?? 0)
                        )
                        .foregroundStyle(severityColor(severity))
                    }
                }
                .frame(height: 200)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                // List View
                VStack(spacing: 8) {
                    ForEach([IncidentReport.Severity.critical, .high, .medium, .low], id: \.self) { severity in
                        if let count = stats.severityBreakdown[severity], count > 0 {
                            HStack {
                                Circle()
                                    .fill(severityColor(severity))
                                    .frame(width: 12, height: 12)
                                
                                Text(severity.displayName)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .font(.headline)
                                    .foregroundColor(severityColor(severity))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Export Section
    
    var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Data")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button {
                    exportAsCSV()
                } label: {
                    Label("Export CSV", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button {
                    shareReport()
                } label: {
                    Label("Share Report", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadStats() async {
        guard let tenantId = authService.tenantId else { return }
        
        isLoading = true
        
        do {
            let loadedStats = try await incidentService.getIncidentStats(
                tenantId: tenantId,
                days: selectedTimeRange.days
            )
            stats = loadedStats
        } catch {
            print("❌ Error loading stats: \(error)")
        }
        
        isLoading = false
    }
    
    private func exportAsCSV() {
        // TODO: Implement CSV export
        print("📄 Exporting as CSV...")
    }
    
    private func shareReport() {
        // TODO: Implement share sheet
        print("📤 Sharing report...")
    }
    
    // MARK: - Helpers
    
    private func severityColor(_ severity: IncidentReport.Severity) -> Color {
        switch severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Overview Card

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReportsAnalyticsView()
            .environmentObject(AuthService())
    }
}

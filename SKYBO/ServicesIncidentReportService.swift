//
//  IncidentReportService.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-03-03.
//

import Foundation
import Combine
import FirebaseFirestore
import CoreLocation

@MainActor
class IncidentReportService: ObservableObject {
    @Published var incidents: [IncidentReport] = []
    @Published var pendingIncidents: [IncidentReport] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var incidentListener: ListenerRegistration?
    
    // MARK: - Submit Incident Report
    
    func submitIncident(
        reporterId: String,
        reporterName: String,
        tenantId: String,
        title: String,
        description: String,
        incidentType: IncidentReport.IncidentType,
        severity: IncidentReport.Severity,
        location: CLLocation,
        address: String?,
        incidentOccurredAt: Date,
        affectedPersonnel: [String] = []
    ) async throws -> String {
        
        let incident = IncidentReport(
            reporterId: reporterId,
            reporterName: reporterName,
            tenantId: tenantId,
            title: title,
            description: description,
            incidentType: incidentType,
            severity: severity,
            reportedAt: Date(),
            incidentOccurredAt: incidentOccurredAt,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            address: address,
            status: .pending,
            affectedPersonnel: affectedPersonnel
        )
        
        let docRef = try db.collection("incident_reports").addDocument(from: incident)
        
        // Create alert for admins
        try await createIncidentAlert(incident: incident, incidentId: docRef.documentID)
        
        print("✅ Incident report submitted: \(docRef.documentID)")
        
        return docRef.documentID
    }
    
    // MARK: - Admin Actions
    
    func updateIncidentStatus(
        incidentId: String,
        status: IncidentReport.ReportStatus,
        reviewerId: String,
        reviewNotes: String? = nil
    ) async throws {
        
        var updateData: [String: Any] = [
            "status": status.rawValue,
            "reviewedBy": reviewerId,
            "reviewedAt": Timestamp(date: Date())
        ]
        
        if let notes = reviewNotes {
            updateData["reviewNotes"] = notes
        }
        
        try await db.collection("incident_reports").document(incidentId).updateData(updateData)
        
        print("✅ Incident status updated to: \(status.rawValue)")
    }
    
    // MARK: - Listen to Incidents
    
    func startListeningToIncidents(tenantId: String, showOnlyPending: Bool = false) {
        incidentListener?.remove()
        
        guard !tenantId.isEmpty else { return }
        
        var query = db.collection("incident_reports")
            .whereField("tenantId", isEqualTo: tenantId)
        
        if showOnlyPending {
            query = query.whereField("status", isEqualTo: IncidentReport.ReportStatus.pending.rawValue)
        }
        
        incidentListener = query
            .order(by: "reportedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to incidents: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    let loadedIncidents = documents.compactMap { doc in
                        try? doc.data(as: IncidentReport.self)
                    }
                    
                    self.incidents = loadedIncidents
                    self.pendingIncidents = loadedIncidents.filter { $0.status == .pending }
                    
                    print("✅ Loaded \(loadedIncidents.count) incident reports")
                }
            }
    }
    
    func stopListening() {
        incidentListener?.remove()
        incidentListener = nil
    }
    
    // MARK: - Get Incident History
    
    func getIncidentsByType(
        tenantId: String,
        type: IncidentReport.IncidentType,
        limit: Int = 50
    ) async throws -> [IncidentReport] {
        let snapshot = try await db.collection("incident_reports")
            .whereField("tenantId", isEqualTo: tenantId)
            .whereField("incidentType", isEqualTo: type.rawValue)
            .order(by: "reportedAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: IncidentReport.self) }
    }
    
    func getIncidentsBySeverity(
        tenantId: String,
        severity: IncidentReport.Severity,
        limit: Int = 50
    ) async throws -> [IncidentReport] {
        let snapshot = try await db.collection("incident_reports")
            .whereField("tenantId", isEqualTo: tenantId)
            .whereField("severity", isEqualTo: severity.rawValue)
            .order(by: "reportedAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: IncidentReport.self) }
    }
    
    func getIncidentsByReporter(userId: String, limit: Int = 50) async throws -> [IncidentReport] {
        let snapshot = try await db.collection("incident_reports")
            .whereField("reporterId", isEqualTo: userId)
            .order(by: "reportedAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: IncidentReport.self) }
    }
    
    // MARK: - Create Alert for Admins
    
    private func createIncidentAlert(incident: IncidentReport, incidentId: String) async throws {
        let severityEmoji: String
        switch incident.severity {
        case .low: severityEmoji = "ℹ️"
        case .medium: severityEmoji = "⚠️"
        case .high: severityEmoji = "🔴"
        case .critical: severityEmoji = "🚨"
        }
        
        let alert = Alert(
            tenantId: incident.tenantId,
            senderId: incident.reporterId,
            senderName: incident.reporterName,
            recipientIds: [], // Empty array means all users in tenant
            title: "\(severityEmoji) \(incident.incidentType.displayName)",
            message: "\(incident.title)\n\nReported by: \(incident.reporterName)\nLocation: \(incident.address ?? "Unknown")\n\nDescription: \(incident.description)",
            priority: incident.severity == .critical ? .critical : (incident.severity == .high ? .high : .medium),
            type: incident.incidentType == .medical ? .emergency : .announcement,
            requiresResponse: incident.severity == .critical || incident.severity == .high,
            quickResponses: ["Acknowledged", "Investigating", "Need more info", "Resolved"],
            allowCustomResponse: true,
            createdAt: Date(),
            expiresAt: nil,
            isActive: true
        )
        
        try db.collection("alerts").addDocument(from: alert)
    }
    
    // MARK: - Statistics
    
    func getIncidentStats(tenantId: String, days: Int = 30) async throws -> IncidentStats {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let snapshot = try await db.collection("incident_reports")
            .whereField("tenantId", isEqualTo: tenantId)
            .whereField("reportedAt", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .getDocuments()
        
        let incidents = snapshot.documents.compactMap { try? $0.data(as: IncidentReport.self) }
        
        var typeCount: [IncidentReport.IncidentType: Int] = [:]
        var severityCount: [IncidentReport.Severity: Int] = [:]
        
        for incident in incidents {
            typeCount[incident.incidentType, default: 0] += 1
            severityCount[incident.severity, default: 0] += 1
        }
        
        return IncidentStats(
            totalIncidents: incidents.count,
            criticalIncidents: severityCount[.critical] ?? 0,
            highIncidents: severityCount[.high] ?? 0,
            pendingReview: incidents.filter { $0.status == .pending }.count,
            typeBreakdown: typeCount,
            severityBreakdown: severityCount
        )
    }
}

// MARK: - Statistics Model

struct IncidentStats {
    let totalIncidents: Int
    let criticalIncidents: Int
    let highIncidents: Int
    let pendingReview: Int
    let typeBreakdown: [IncidentReport.IncidentType: Int]
    let severityBreakdown: [IncidentReport.Severity: Int]
}

//
//  FocusSummary.swift
//  MessageAI
//
//  Focus Mode session summary data model
//

import Foundation
import FirebaseFirestore

/// Focus Summary model for AI-generated session summaries
struct FocusSummary: Codable, Identifiable {
    /// Unique summary identifier
    let id: String
    
    /// ID of the session this summary belongs to (optional - not needed for direct generation)
    let sessionID: String?
    
    /// User ID who owns this summary
    let userID: String
    
    /// When this summary was generated
    let generatedAt: Date
    
    /// Overview of the session content
    let overview: String
    
    /// Array of action items extracted from the session
    let actionItems: [String]
    
    /// Array of key decisions made during the session
    let keyDecisions: [String]
    
    /// Number of messages in the session
    let messageCount: Int
    
    /// Number of urgent/priority messages
    let urgentMessageCount: Int
    
    /// Confidence score for the summary quality (0.0-1.0)
    let confidence: Double
    
    /// Cached export data (optional)
    var exportData: String?
    
    /// Processing time in milliseconds
    let processingTimeMs: Int
    
    /// Method used for summarization (openai/fallback)
    let method: String
    
    /// Duration of the session in minutes
    let sessionDuration: Int
    
    /// Firestore collection name
    static let collectionName = "focusSummaries"
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionID
        case userID
        case generatedAt
        case overview
        case actionItems
        case keyDecisions
        case messageCount
        case urgentMessageCount
        case confidence
        case exportData
        case processingTimeMs
        case method
        case sessionDuration
    }
    
    // MARK: - Initialization
    
    init(id: String, sessionID: String? = nil, userID: String, generatedAt: Date, overview: String, actionItems: [String], keyDecisions: [String], messageCount: Int, urgentMessageCount: Int, confidence: Double, exportData: String? = nil, processingTimeMs: Int, method: String, sessionDuration: Int) {
        self.id = id
        self.sessionID = sessionID
        self.userID = userID
        self.generatedAt = generatedAt
        self.overview = overview
        self.actionItems = actionItems
        self.keyDecisions = keyDecisions
        self.messageCount = messageCount
        self.urgentMessageCount = urgentMessageCount
        self.confidence = confidence
        self.exportData = exportData
        self.processingTimeMs = processingTimeMs
        self.method = method
        self.sessionDuration = sessionDuration
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        sessionID = try container.decodeIfPresent(String.self, forKey: .sessionID)
        userID = try container.decode(String.self, forKey: .userID)
        overview = try container.decode(String.self, forKey: .overview)
        actionItems = try container.decodeIfPresent([String].self, forKey: .actionItems) ?? []
        keyDecisions = try container.decodeIfPresent([String].self, forKey: .keyDecisions) ?? []
        messageCount = try container.decodeIfPresent(Int.self, forKey: .messageCount) ?? 0
        urgentMessageCount = try container.decodeIfPresent(Int.self, forKey: .urgentMessageCount) ?? 0
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.0
        exportData = try container.decodeIfPresent(String.self, forKey: .exportData)
        processingTimeMs = try container.decodeIfPresent(Int.self, forKey: .processingTimeMs) ?? 0
        method = try container.decodeIfPresent(String.self, forKey: .method) ?? "fallback"
        sessionDuration = try container.decodeIfPresent(Int.self, forKey: .sessionDuration) ?? 0
        
        // Handle Firestore Timestamp conversion
        if let timestamp = try? container.decode(Timestamp.self, forKey: .generatedAt) {
            self.generatedAt = timestamp.dateValue()
        } else {
            self.generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        }
    }
    
    /// Encode to Firestore document
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(sessionID, forKey: .sessionID)
        try container.encode(userID, forKey: .userID)
        try container.encode(overview, forKey: .overview)
        try container.encode(actionItems, forKey: .actionItems)
        try container.encode(keyDecisions, forKey: .keyDecisions)
        try container.encode(messageCount, forKey: .messageCount)
        try container.encode(urgentMessageCount, forKey: .urgentMessageCount)
        try container.encode(confidence, forKey: .confidence)
        try container.encodeIfPresent(exportData, forKey: .exportData)
        try container.encode(processingTimeMs, forKey: .processingTimeMs)
        try container.encode(method, forKey: .method)
        try container.encode(sessionDuration, forKey: .sessionDuration)
        
        // Convert date to Firestore Timestamp
        try container.encode(Timestamp(date: generatedAt), forKey: .generatedAt)
    }
}

// MARK: - Export Format

/// Export format enum for summary exports
enum ExportFormat: String, CaseIterable {
    case text = "text"
    case markdown = "markdown"
    case pdf = "pdf"
    
    var fileExtension: String {
        switch self {
        case .text:
            return "txt"
        case .markdown:
            return "md"
        case .pdf:
            return "pdf"
        }
    }
    
    var mimeType: String {
        switch self {
        case .text:
            return "text/plain"
        case .markdown:
            return "text/markdown"
        case .pdf:
            return "application/pdf"
        }
    }
}

// MARK: - Extensions

extension FocusSummary {
    /// Generate export data in the specified format
    func generateExportData(format: ExportFormat) -> String {
        let sessionDate = DateFormatter.localizedString(from: generatedAt, dateStyle: .medium, timeStyle: .short)
        let duration = formatDuration(sessionDuration)
        
        switch format {
        case .text:
            return generateTextExport(sessionDate: sessionDate, duration: duration)
        case .markdown:
            return generateMarkdownExport(sessionDate: sessionDate, duration: duration)
        case .pdf:
            return generateTextExport(sessionDate: sessionDate, duration: duration) // PDF generation would be handled separately
        }
    }
    
    private func generateTextExport(sessionDate: String, duration: String) -> String {
        var export = "Focus Mode Session Summary\n"
        export += "Generated: \(sessionDate)\n"
        export += "Duration: \(duration)\n"
        export += "Messages: \(messageCount)\n"
        export += "Urgent Messages: \(urgentMessageCount)\n"
        export += "Confidence: \(String(format: "%.1f%%", confidence * 100))\n\n"
        
        export += "OVERVIEW\n"
        export += "========\n"
        export += "\(overview)\n\n"
        
        if !actionItems.isEmpty {
            export += "ACTION ITEMS\n"
            export += "============\n"
            for (index, item) in actionItems.enumerated() {
                export += "\(index + 1). \(item)\n"
            }
            export += "\n"
        }
        
        if !keyDecisions.isEmpty {
            export += "KEY DECISIONS\n"
            export += "=============\n"
            for (index, decision) in keyDecisions.enumerated() {
                export += "\(index + 1). \(decision)\n"
            }
            export += "\n"
        }
        
        return export
    }
    
    private func generateMarkdownExport(sessionDate: String, duration: String) -> String {
        var export = "# Focus Mode Session Summary\n\n"
        export += "**Generated:** \(sessionDate)\n"
        export += "**Duration:** \(duration)\n"
        export += "**Messages:** \(messageCount)\n"
        export += "**Urgent Messages:** \(urgentMessageCount)\n"
        export += "**Confidence:** \(String(format: "%.1f%%", confidence * 100))\n\n"
        
        export += "## Overview\n\n"
        export += "\(overview)\n\n"
        
        if !actionItems.isEmpty {
            export += "## Action Items\n\n"
            for item in actionItems {
                export += "- \(item)\n"
            }
            export += "\n"
        }
        
        if !keyDecisions.isEmpty {
            export += "## Key Decisions\n\n"
            for decision in keyDecisions {
                export += "- \(decision)\n"
            }
            export += "\n"
        }
        
        return export
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours) hour\(hours == 1 ? "" : "s") \(remainingMinutes) minutes"
            }
        }
    }
}

//
//  PresenceStatus.swift
//  MessageAI
//
//  Data model for user presence status
//

import Foundation

/// Enum representing possible presence states
enum PresenceState: String, Codable {
    case online = "online"
    case offline = "offline"
    
    /// Returns display color for the presence state
    var displayColor: String {
        switch self {
        case .online:
            return "green"
        case .offline:
            return "gray"
        }
    }
}

/// Model representing user presence status
/// - Note: Maps to Firebase Realtime Database structure at /presence/{userID}
struct PresenceStatus: Codable, Equatable {
    /// Current presence state (online/offline)
    var status: PresenceState
    
    /// Timestamp of last status change
    var lastSeen: Date
    
    /// Device information for tracking
    var deviceInfo: DeviceInfo?
    
    // MARK: - Nested Types
    
    /// Device information for presence tracking
    struct DeviceInfo: Codable, Equatable {
        /// Platform (iOS, Android, Web)
        var platform: String
        
        /// App version
        var version: String
        
        /// Device model (optional)
        var model: String?
        
        init(platform: String = "iOS", version: String = "1.0.0", model: String? = nil) {
            self.platform = platform
            self.version = version
            self.model = model
        }
    }
    
    // MARK: - Initialization
    
    init(status: PresenceState, lastSeen: Date = Date(), deviceInfo: DeviceInfo? = nil) {
        self.status = status
        self.lastSeen = lastSeen
        self.deviceInfo = deviceInfo
    }
    
    // MARK: - Helpers
    
    /// Returns true if user is currently online
    var isOnline: Bool {
        return status == .online
    }
    
    /// Returns formatted last seen string
    var lastSeenFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSeen, relativeTo: Date())
    }
    
    // MARK: - Firebase Conversion
    
    /// Converts to Firebase Realtime Database dictionary
    func toFirebaseDict() -> [String: Any] {
        var dict: [String: Any] = [
            "status": status.rawValue,
            "lastSeen": lastSeen.timeIntervalSince1970
        ]
        
        if let deviceInfo = deviceInfo {
            dict["deviceInfo"] = [
                "platform": deviceInfo.platform,
                "version": deviceInfo.version,
                "model": deviceInfo.model ?? ""
            ]
        }
        
        return dict
    }
    
    /// Initialize from Firebase Realtime Database dictionary
    static func from(firebaseDict: [String: Any]) -> PresenceStatus? {
        guard let statusString = firebaseDict["status"] as? String,
              let status = PresenceState(rawValue: statusString),
              let lastSeenTimestamp = firebaseDict["lastSeen"] as? TimeInterval else {
            return nil
        }
        
        let lastSeen = Date(timeIntervalSince1970: lastSeenTimestamp)
        
        var deviceInfo: DeviceInfo?
        if let deviceDict = firebaseDict["deviceInfo"] as? [String: Any],
           let platform = deviceDict["platform"] as? String,
           let version = deviceDict["version"] as? String {
            let model = deviceDict["model"] as? String
            deviceInfo = DeviceInfo(platform: platform, version: version, model: model)
        }
        
        return PresenceStatus(status: status, lastSeen: lastSeen, deviceInfo: deviceInfo)
    }
}

// MARK: - Default Presence Status

extension PresenceStatus {
    /// Default offline status
    static var offline: PresenceStatus {
        PresenceStatus(status: .offline)
    }
    
    /// Default online status
    static var online: PresenceStatus {
        PresenceStatus(status: .online, deviceInfo: DeviceInfo())
    }
}


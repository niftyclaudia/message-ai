//
//  ConnectionState.swift
//  MessageAI
//
//  Connection state enum for offline persistence system
//

import Foundation

/// Connection state enum representing the current network and sync status
/// - Note: Used for UI state management and offline message handling
enum ConnectionState: Equatable {
    case online
    case offline
    case connecting
    case syncing(Int) // number of messages being sent
    
    /// Returns true if the device is currently online
    var isOnline: Bool {
        switch self {
        case .online:
            return true
        case .offline, .connecting, .syncing:
            return false
        }
    }
    
    /// Returns true if messages are being synced
    var isSyncing: Bool {
        switch self {
        case .syncing:
            return true
        case .online, .offline, .connecting:
            return false
        }
    }
    
    /// Returns the number of messages being synced
    var syncingCount: Int {
        switch self {
        case .syncing(let count):
            return count
        case .online, .offline, .connecting:
            return 0
        }
    }
    
    /// Returns a user-friendly description of the current state
    var description: String {
        switch self {
        case .online:
            return "Online"
        case .offline:
            return "Offline"
        case .connecting:
            return "Connecting..."
        case .syncing(let count):
            return "Sending \(count) message\(count == 1 ? "" : "s")..."
        }
    }
    
    /// Returns an icon name for the current state
    var iconName: String {
        switch self {
        case .online:
            return "wifi"
        case .offline:
            return "wifi.slash"
        case .connecting:
            return "arrow.clockwise"
        case .syncing:
            return "arrow.up.circle"
        }
    }
}

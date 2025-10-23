//
//  NetworkMonitor.swift
//  MessageAI
//
//  Network monitoring service for connection status tracking
//

import Foundation
import Network
import SwiftUI

/// Network connection type enum
enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case none
}

/// Network monitoring service that tracks connection status
/// - Note: Uses Network framework for real-time connection monitoring
@MainActor
class NetworkMonitor: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .wifi
    @Published var isExpensive: Bool = false
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - Initialization
    
    init() {
        // Start monitoring immediately
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path: path)
            }
        }
        monitor.start(queue: queue)
        
        // Get actual status very quickly after monitor starts
        queue.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            guard let self = self else { return }
            let currentPath = self.monitor.currentPath
            
            Task { @MainActor in
                self.updateConnectionStatus(path: currentPath)
            }
        }
    }
    
    deinit {
        // Stop monitoring without main actor isolation
        monitor.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring network connectivity
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path: path)
            }
        }
        monitor.start(queue: queue)
    }
    
    /// Stops monitoring network connectivity
    func stopMonitoring() {
        monitor.cancel()
    }
    
    // MARK: - Private Methods
    
    /// Updates connection status based on network path
    /// - Parameter path: The current network path
    private func updateConnectionStatus(path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        
        if path.status == .satisfied {
            // Determine connection type based on available interfaces
            if path.usesInterfaceType(.wifi) {
                connectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                connectionType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                connectionType = .ethernet
            } else {
                connectionType = .wifi // Default fallback
            }
        } else {
            connectionType = .none
        }
    }
}

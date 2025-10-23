//
//  NetworkMonitorService.swift
//  MessageAI
//
//  Enhanced network monitoring service for offline persistence
//

import Foundation
import Network
import SwiftUI

/// Enhanced network monitoring service for offline persistence system
/// - Note: Provides connection state management, auto-sync, and real-time network monitoring
@MainActor
class NetworkMonitorService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var connectionState: ConnectionState = .online
    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .wifi
    @Published var isExpensive: Bool = false
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorService")
    private var connectionStateTimer: Timer?
    private let autoSyncDelay: TimeInterval = 1.0 // 1 second delay for auto-sync
    
    // MARK: - Initialization
    
    init() {
        // Start monitoring immediately - this will trigger pathUpdateHandler very quickly
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path: path)
            }
        }
        monitor.start(queue: queue)
        
        // Use a very short delay to let the path monitor get the actual status
        // This happens almost immediately (< 10ms) after start()
        queue.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            guard let self = self else { return }
            let currentPath = self.monitor.currentPath
            
            Task { @MainActor in
                self.updateConnectionStatus(path: currentPath)
            }
        }
    }
    
    deinit {
        Task { @MainActor in
            stopMonitoring()
        }
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
        connectionStateTimer?.invalidate()
        connectionStateTimer = nil
    }
    
    /// Checks if the device is currently online
    /// - Returns: True if online, false if offline
    func isOnline() -> Bool {
        return isConnected
    }
    
    /// Waits for network connection with timeout
    /// - Parameter timeout: Maximum time to wait in seconds
    /// - Returns: True if connection established within timeout
    func waitForConnection(timeout: TimeInterval = 30.0) async -> Bool {
        if isConnected {
            return true
        }
        
        // Wait for connection with timeout
        let startTime = Date()
        while !isConnected && Date().timeIntervalSince(startTime) < timeout {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        return isConnected
    }
    
    /// Observes network state changes
    /// - Returns: AsyncStream of connection states (only yields on actual changes)
    func observeNetworkState() -> AsyncStream<ConnectionState> {
        return AsyncStream { continuation in
            var lastYieldedState = self.connectionState
            
            // Yield initial state
            continuation.yield(lastYieldedState)
            
            // Create a timer to check for state changes (not constant polling)
            let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                Task { @MainActor in
                    let currentState = self.connectionState
                    if currentState != lastYieldedState {
                        continuation.yield(currentState)
                        lastYieldedState = currentState
                    }
                }
            }
            
            // Store timer for cleanup
            self.connectionStateTimer = timer
            
            // Cleanup when stream is cancelled
            continuation.onTermination = { _ in
                Task { @MainActor in
                    timer.invalidate()
                }
            }
        }
    }
    
    /// Simulates network state for testing
    /// - Parameter state: The state to simulate
    func simulateNetworkState(_ state: ConnectionState) {
        connectionState = state
        isConnected = state.isOnline
    }
    
    // MARK: - Private Methods
    
    /// Updates connection status based on network path
    /// - Parameter path: The current network path
    private func updateConnectionStatus(path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        
        // Update connection type
        if path.status == .satisfied {
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
        
        // Update connection state
        if isConnected {
            if !wasConnected {
                // Just reconnected - show connecting state briefly
                connectionState = .connecting
                
                // Auto-transition to online after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + autoSyncDelay) {
                    self.connectionState = .online
                }
            } else {
                connectionState = .online
            }
        } else {
            connectionState = .offline
        }
    }
    
    /// Updates connection state to syncing
    /// - Parameter messageCount: Number of messages being synced
    func updateToSyncing(messageCount: Int) {
        connectionState = .syncing(messageCount)
    }
    
    /// Updates connection state back to online after sync
    func updateToOnline() {
        connectionState = .online
    }
}

//
//  NetworkMonitorServiceTests.swift
//  MessageAITests
//
//  Unit tests for network monitoring service
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for NetworkMonitorService
/// - Note: Tests network connectivity detection and state management
struct NetworkMonitorServiceTests {
    
    // MARK: - Test Properties
    
    private var service: NetworkMonitorService!
    
    // MARK: - Setup
    
    init() {
        service = NetworkMonitorService()
    }
    
    // MARK: - Connection State Tests
    
    @Test("Initial Connection State")
    func initialConnectionState() {
        // Then
        #expect(service.connectionState == .online)
        #expect(service.isConnected == true)
        #expect(service.connectionType == .wifi)
    }
    
    @Test("Simulate Offline State")
    func simulateOfflineState() {
        // When
        service.simulateNetworkState(.offline)
        
        // Then
        #expect(service.connectionState == .offline)
        #expect(service.isConnected == false)
        #expect(service.isOnline() == false)
    }
    
    @Test("Simulate Connecting State")
    func simulateConnectingState() {
        // When
        service.simulateNetworkState(.connecting)
        
        // Then
        #expect(service.connectionState == .connecting)
        #expect(service.isConnected == false)
        #expect(service.isOnline() == false)
    }
    
    @Test("Simulate Syncing State")
    func simulateSyncingState() {
        // When
        service.simulateNetworkState(.syncing(3))
        
        // Then
        #expect(service.connectionState == .syncing(3))
        #expect(service.isConnected == false)
        #expect(service.isOnline() == false)
        #expect(service.connectionState.syncingCount == 3)
    }
    
    @Test("Connection State Properties")
    func connectionStateProperties() {
        // Test online state
        service.simulateNetworkState(.online)
        #expect(service.connectionState.isOnline == true)
        #expect(service.connectionState.isSyncing == false)
        #expect(service.connectionState.syncingCount == 0)
        
        // Test offline state
        service.simulateNetworkState(.offline)
        #expect(service.connectionState.isOnline == false)
        #expect(service.connectionState.isSyncing == false)
        #expect(service.connectionState.syncingCount == 0)
        
        // Test connecting state
        service.simulateNetworkState(.connecting)
        #expect(service.connectionState.isOnline == false)
        #expect(service.connectionState.isSyncing == false)
        #expect(service.connectionState.syncingCount == 0)
        
        // Test syncing state
        service.simulateNetworkState(.syncing(5))
        #expect(service.connectionState.isOnline == false)
        #expect(service.connectionState.isSyncing == true)
        #expect(service.connectionState.syncingCount == 5)
    }
    
    @Test("Connection State Descriptions")
    func connectionStateDescriptions() {
        // Test descriptions
        service.simulateNetworkState(.online)
        #expect(service.connectionState.description == "Online")
        
        service.simulateNetworkState(.offline)
        #expect(service.connectionState.description == "Offline")
        
        service.simulateNetworkState(.connecting)
        #expect(service.connectionState.description == "Connecting...")
        
        service.simulateNetworkState(.syncing(3))
        #expect(service.connectionState.description == "Sending 3 messages...")
    }
    
    @Test("Connection State Icons")
    func connectionStateIcons() {
        // Test icon names
        service.simulateNetworkState(.online)
        #expect(service.connectionState.iconName == "wifi")
        
        service.simulateNetworkState(.offline)
        #expect(service.connectionState.iconName == "wifi.slash")
        
        service.simulateNetworkState(.connecting)
        #expect(service.connectionState.iconName == "arrow.clockwise")
        
        service.simulateNetworkState(.syncing(3))
        #expect(service.connectionState.iconName == "arrow.up.circle")
    }
    
    @Test("Wait For Connection Timeout")
    func waitForConnectionTimeout() async {
        // Given - Start offline
        service.simulateNetworkState(.offline)
        
        // When - Wait for connection with short timeout
        let connected = await service.waitForConnection(timeout: 0.1)
        
        // Then - Should timeout
        #expect(connected == false)
    }
    
    @Test("Wait For Connection Success")
    func waitForConnectionSuccess() async {
        // Given - Start online
        service.simulateNetworkState(.online)
        
        // When - Wait for connection
        let connected = await service.waitForConnection(timeout: 1.0)
        
        // Then - Should succeed immediately
        #expect(connected == true)
    }
    
    @Test("Network State Observation")
    func networkStateObservation() async {
        // Given
        var observedStates: [ConnectionState] = []
        
        // When - Start observing
        let observationTask = Task {
            for await state in service.observeNetworkState() {
                observedStates.append(state)
                if observedStates.count >= 3 {
                    break
                }
            }
        }
        
        // Simulate state changes
        service.simulateNetworkState(.offline)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        service.simulateNetworkState(.connecting)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        service.simulateNetworkState(.online)
        
        // Wait for observation to complete
        await observationTask.value
        
        // Then - Should have observed state changes
        #expect(observedStates.count >= 3)
        #expect(observedStates.contains(.offline))
        #expect(observedStates.contains(.connecting))
        #expect(observedStates.contains(.online))
    }
    
    @Test("Update To Syncing")
    func updateToSyncing() {
        // Given
        service.simulateNetworkState(.online)
        
        // When
        service.updateToSyncing(messageCount: 5)
        
        // Then
        #expect(service.connectionState == .syncing(5))
        #expect(service.connectionState.syncingCount == 5)
    }
    
    @Test("Update To Online")
    func updateToOnline() {
        // Given
        service.simulateNetworkState(.syncing(3))
        
        // When
        service.updateToOnline()
        
        // Then
        #expect(service.connectionState == .online)
        #expect(service.connectionState.isOnline == true)
    }
}

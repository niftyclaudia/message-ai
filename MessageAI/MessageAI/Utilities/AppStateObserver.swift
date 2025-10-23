//
//  AppStateObserver.swift
//  MessageAI
//
//  SwiftUI environment observer for app state changes
//  PR #4: Mobile Lifecycle Management
//

import Foundation
import SwiftUI
import Combine

/// SwiftUI-friendly observer for app state changes
/// - Note: Provides reactive updates to UI components based on app lifecycle
class AppStateObserver: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current app lifecycle state
    @Published var appState: AppLifecycleState = .inactive
    
    /// Whether the app is currently reconnecting
    @Published var isReconnecting: Bool = false
    
    /// Last reconnect duration in milliseconds
    @Published var reconnectDuration: TimeInterval = 0
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let lifecycleManager: AppLifecycleManager
    
    // MARK: - Initialization
    
    init(lifecycleManager: AppLifecycleManager) {
        self.lifecycleManager = lifecycleManager
        setupObservers()
    }
    
    // MARK: - Private Methods
    
    /// Sets up observers for lifecycle manager state changes
    private func setupObservers() {
        // Observe app state changes
        lifecycleManager.$currentState
            .receive(on: DispatchQueue.main)
            .assign(to: &$appState)
        
        // Observe reconnection state
        lifecycleManager.$isReconnecting
            .receive(on: DispatchQueue.main)
            .assign(to: &$isReconnecting)
        
        // Observe reconnect duration
        lifecycleManager.$lastReconnectDuration
            .receive(on: DispatchQueue.main)
            .assign(to: &$reconnectDuration)
    }
    
    // MARK: - Public Methods
    
    /// Check if app is in active state
    var isActive: Bool {
        appState == .active
    }
    
    /// Check if app is in background
    var isBackground: Bool {
        appState == .background
    }
    
    /// Get formatted reconnect duration
    var reconnectDurationFormatted: String {
        String(format: "%.0f", reconnectDuration) + "ms"
    }
}


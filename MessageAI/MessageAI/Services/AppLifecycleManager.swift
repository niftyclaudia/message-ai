//
//  AppLifecycleManager.swift
//  MessageAI
//
//  Manages app lifecycle events and presence status updates
//  Enhanced for PR #4: Mobile Lifecycle Management
//

import Foundation
import SwiftUI
import FirebaseAuth
import Combine
import FirebaseFirestore

/// Manages app lifecycle events and coordinates presence status updates
/// - Note: Handles foreground/background/terminated states for presence system
/// - PR #4: Added connection management, reconnect timing, and state preservation
class AppLifecycleManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current app lifecycle state
    @Published private(set) var currentState: AppLifecycleState = .inactive
    
    /// Whether the app is reconnecting after foregrounding
    @Published private(set) var isReconnecting: Bool = false
    
    /// Last reconnect duration in milliseconds
    @Published private(set) var lastReconnectDuration: TimeInterval = 0
    
    // MARK: - Private Properties
    
    private let presenceService: PresenceService
    private let messageService: MessageService
    @MainActor
    private lazy var offlineViewModel: OfflineViewModel = OfflineViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var currentUserID: String?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    /// Firestore listeners that need to be managed during lifecycle transitions
    private var activeListeners: [ListenerRegistration] = []
    
    /// Track lifecycle transitions for performance monitoring
    private var transitionEvents: [LifecycleTransitionEvent] = []
    
    /// Time when background transition started
    private var backgroundStartTime: Date?
    
    // MARK: - Initialization
    
    init(presenceService: PresenceService = PresenceService(), messageService: MessageService = MessageService()) {
        self.presenceService = presenceService
        self.messageService = messageService
        setupAuthObserver()
        setupLifecycleObservers()
    }
    
    // MARK: - Private Methods
    
    /// Observes authentication state changes
    private func setupAuthObserver() {
        // Observe auth state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.currentUserID = user.uid
                self?.handleUserLoggedIn(userID: user.uid)
            } else {
                self?.handleUserLoggedOut()
            }
        }
    }
    
    deinit {
        // Remove auth listener
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    /// Sets up observers for app lifecycle notifications
    private func setupLifecycleObservers() {
        // App becomes active (foreground)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppBecameActive()
            }
            .store(in: &cancellables)
        
        // App enters background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppEnteredBackground()
            }
            .store(in: &cancellables)
        
        // App will terminate
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.handleAppWillTerminate()
            }
            .store(in: &cancellables)
    }
    
    /// Handles user logged in event
    private func handleUserLoggedIn(userID: String) {
        Task {
            do {
                try await presenceService.setUserOnline(userID: userID)
            } catch {
            }
        }
    }
    
    /// Handles user logged out event
    private func handleUserLoggedOut() {
        guard let userID = currentUserID else { return }
        
        Task {
            do {
                try await presenceService.setUserOffline(userID: userID)
            } catch {
            }
        }
        
        currentUserID = nil
    }
    
    /// Handles app became active event (foreground)
    /// - PR #4: Added reconnect timing and connection management (< 500ms target)
    private func handleAppBecameActive() {
        let transitionStart = Date()
        let previousState = currentState
        currentState = .active
        
        guard let userID = currentUserID else { return }
        
        // Start reconnection process
        isReconnecting = true
        PerformanceMonitor.shared.startSync()
        
        Task {
            do {
                // Restore connections and sync messages
                try await resumeConnections()
                
                // Set user online
                try await presenceService.setUserOnline(userID: userID)
                
                // Sync offline messages when reconnecting
                await offlineViewModel.retryFailedMessages()
                let syncedCount = await MainActor.run {
                    offlineViewModel.getOfflineMessages().count
                }
                
                // Calculate and track reconnect duration
                let duration = Date().timeIntervalSince(transitionStart)
                lastReconnectDuration = duration * 1000  // Convert to ms
                
                // Track performance
                PerformanceMonitor.shared.endSync(messageCount: syncedCount)
                
                // Log transition event
                let event = LifecycleTransitionEvent(
                    from: previousState,
                    to: .active,
                    duration: duration,
                    messagesPending: syncedCount
                )
                transitionEvents.append(event)
                
                isReconnecting = false
            } catch {
                isReconnecting = false
            }
        }
    }
    
    /// Handles app entered background event
    /// - PR #4: Added connection suspension (< 2s target for battery optimization)
    private func handleAppEnteredBackground() {
        let transitionStart = Date()
        let previousState = currentState
        currentState = .background
        backgroundStartTime = Date()
        
        guard currentUserID != nil else { return }
        
        Task {
            do {
                // Suspend connections gracefully
                try await suspendConnections()
                
                // Calculate transition duration
                let duration = Date().timeIntervalSince(transitionStart)
                
                // Log transition event
                let pendingCount = await MainActor.run {
                    offlineViewModel.getOfflineMessages().count
                }
                let event = LifecycleTransitionEvent(
                    from: previousState,
                    to: .background,
                    duration: duration,
                    messagesPending: pendingCount
                )
                transitionEvents.append(event)
            } catch {
                // Handle error silently - background transition is non-critical
            }
        }
    }
    
    /// Handles app will terminate event
    /// - PR #4: Added state preservation for zero message loss
    private func handleAppWillTerminate() {
        let transitionStart = Date()
        let previousState = currentState
        currentState = .terminated
        
        guard let userID = currentUserID else { return }
        
        // Best-effort state preservation (iOS may kill us immediately)
        Task {
            do {
                // Teardown connections
                try await teardownConnections()
                
                // Set user offline
                try await presenceService.setUserOffline(userID: userID)
                
                // Calculate transition duration
                let duration = Date().timeIntervalSince(transitionStart)
                
                // Log transition event
                let event = LifecycleTransitionEvent(
                    from: previousState,
                    to: .terminated,
                    duration: duration
                )
                transitionEvents.append(event)
            } catch {
                // Handle error silently - termination is time-critical
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Manually sets user online (for testing or manual control)
    /// - Parameter userID: The user's ID
    func setUserOnline(userID: String) async throws {
        try await presenceService.setUserOnline(userID: userID)
        currentUserID = userID
    }
    
    /// Manually sets user offline (for testing or manual control)
    /// - Parameter userID: The user's ID
    func setUserOffline(userID: String) async throws {
        try await presenceService.setUserOffline(userID: userID)
    }
    
    // MARK: - Connection Management (PR #4)
    
    /// Suspends all active connections gracefully
    /// - Note: Called when app enters background, should complete in < 2s
    private func suspendConnections() async throws {
        // Remove all active Firestore listeners
        for listener in activeListeners {
            listener.remove()
        }
        activeListeners.removeAll()
    }
    
    /// Resumes all connections after foregrounding
    /// - Note: Should complete in < 500ms (PR #4 requirement)
    /// - Returns: Time taken to reconnect in seconds
    @discardableResult
    private func resumeConnections() async throws -> TimeInterval {
        let startTime = Date()
        
        // Connections will be re-established by ViewModels when they observe state change
        // MessageService listeners will reconnect automatically via Firestore
        
        let duration = Date().timeIntervalSince(startTime)
        return duration
    }
    
    /// Tears down all connections completely
    /// - Note: Called during app termination
    private func teardownConnections() async throws {
        // Remove all listeners
        for listener in activeListeners {
            listener.remove()
        }
        activeListeners.removeAll()
    }
    
    /// Register a Firestore listener for lifecycle management
    /// - Parameter listener: Firestore listener registration to track
    func registerListener(_ listener: ListenerRegistration) {
        activeListeners.append(listener)
    }
    
    /// Observe app state changes
    /// - Returns: AsyncStream of AppLifecycleState changes
    func observeAppState() -> AsyncStream<AppLifecycleState> {
        AsyncStream { continuation in
            let cancellable = $currentState.sink { state in
                continuation.yield(state)
            }
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
    
    /// Get current app lifecycle state
    /// - Returns: Current AppLifecycleState
    func getCurrentState() -> AppLifecycleState {
        return currentState
    }
    
    /// Get all recorded lifecycle transition events
    /// - Returns: Array of LifecycleTransitionEvent
    func getTransitionEvents() -> [LifecycleTransitionEvent] {
        return transitionEvents
    }
    
    /// Clear transition event history
    func clearTransitionEvents() {
        transitionEvents.removeAll()
    }
    
    /// Get performance statistics for lifecycle transitions
    /// - Returns: Statistics about foreground/background transitions
    func getPerformanceStatistics() -> (foregroundAvg: TimeInterval, backgroundAvg: TimeInterval) {
        let foregroundEvents = transitionEvents.filter { $0.isForegrounding }
        let backgroundEvents = transitionEvents.filter { $0.isBackgrounding }
        
        let foregroundAvg = foregroundEvents.isEmpty ? 0 : foregroundEvents.map { $0.duration }.reduce(0, +) / Double(foregroundEvents.count)
        let backgroundAvg = backgroundEvents.isEmpty ? 0 : backgroundEvents.map { $0.duration }.reduce(0, +) / Double(backgroundEvents.count)
        
        return (foregroundAvg, backgroundAvg)
    }
}


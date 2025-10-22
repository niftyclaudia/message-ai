//
//  AppLifecycleManager.swift
//  MessageAI
//
//  Manages app lifecycle events and presence status updates
//

import Foundation
import SwiftUI
import FirebaseAuth
import Combine

/// Manages app lifecycle events and coordinates presence status updates
/// - Note: Handles foreground/background/terminated states for presence system
class AppLifecycleManager: ObservableObject {
    
    // MARK: - Properties
    
    private let presenceService: PresenceService
    private var cancellables = Set<AnyCancellable>()
    private var currentUserID: String?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    
    init(presenceService: PresenceService = PresenceService()) {
        self.presenceService = presenceService
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
    private func handleAppBecameActive() {
        guard let userID = currentUserID else { return }
        
        Task {
            do {
                try await presenceService.setUserOnline(userID: userID)
            } catch {
            }
        }
    }
    
    /// Handles app entered background event
    private func handleAppEnteredBackground() {
        guard currentUserID != nil else { return }
        
        // Note: We keep user online for a short time (handled by Firebase onDisconnect)
        // The onDisconnect hook will set user offline after connection is lost
    }
    
    /// Handles app will terminate event
    private func handleAppWillTerminate() {
        guard let userID = currentUserID else { return }
        
        // Note: Firebase onDisconnect hooks will automatically set user offline
        // when the connection is terminated
        
        // Attempt to set offline immediately (best effort)
        Task {
            do {
                try await presenceService.setUserOffline(userID: userID)
            } catch {
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
}


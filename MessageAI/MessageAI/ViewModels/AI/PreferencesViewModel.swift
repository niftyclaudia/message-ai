//
//  PreferencesViewModel.swift
//  MessageAI
//
//  ViewModel for managing user AI preferences state
//

import Foundation
import SwiftUI
import FirebaseFirestore
import Network

/// ViewModel for managing AI preferences screen state and operations
/// - Note: Handles preferences loading, saving, and real-time sync
@MainActor
class PreferencesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current user preferences (nil if not yet loaded or first-time user)
    @Published var preferences: UserPreferences?
    
    /// Loading state for initial fetch
    @Published var isLoading: Bool = false
    
    /// Saving state for save operations
    @Published var isSaving: Bool = false
    
    /// Error message to display
    @Published var errorMessage: String?
    
    /// Success message flag
    @Published var showSuccessMessage: Bool = false
    
    /// Whether real-time sync is active
    @Published var isSyncActive: Bool = false
    
    // MARK: - Private Properties
    
    private let preferencesService: PreferencesService
    private let userID: String
    private nonisolated(unsafe) var listener: ListenerRegistration?
    
    // MARK: - Initialization
    
    /// Initialize with user ID and optional service (for dependency injection)
    /// - Parameters:
    ///   - userID: Current user's ID
    ///   - preferencesService: Preferences service (defaults to new instance with userID)
    init(userID: String, preferencesService: PreferencesService? = nil) {
        self.userID = userID
        self.preferencesService = preferencesService ?? PreferencesService(userID: userID)
    }
    
    deinit {
        stopObserving()
    }
    
    // MARK: - Public Methods
    
    /// Loads preferences from Firestore (or uses defaults for first-time users)
    /// - Performance: Target <100ms per PRD
    func loadPreferences() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let fetchedPreferences = try await preferencesService.fetchPreferences(for: userID) {
                preferences = fetchedPreferences
            } else {
                // First-time user - use defaults
                preferences = UserPreferences.defaultPreferences
            }
        } catch {
            errorMessage = error.localizedDescription
            // Still use defaults on error for better UX
            preferences = UserPreferences.defaultPreferences
        }
        
        isLoading = false
    }
    
    /// Saves current preferences to Firestore
    /// - Performance: Target <200ms per PRD
    func savePreferences() async {
        guard let preferences = preferences else {
            errorMessage = "No preferences to save"
            return
        }
        
        isSaving = true
        errorMessage = nil
        showSuccessMessage = false
        
        // Check network status
        let isOnline = await checkNetworkStatus()
        
        do {
            try await preferencesService.savePreferences(preferences, for: userID)
            
            // Show success feedback with appropriate message
            if isOnline {
                showSuccessMessage = true
            } else {
                // Offline - saved locally, will sync later
                errorMessage = "Saved locally. Will sync when you're back online."
            }
            
            // Hide success message after 2 seconds
            if showSuccessMessage {
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    showSuccessMessage = false
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
    
    /// Checks if device is connected to the internet
    private func checkNetworkStatus() async -> Bool {
        return await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "NetworkMonitor")
            
            monitor.pathUpdateHandler = { path in
                let isConnected = path.status == .satisfied
                monitor.cancel()
                continuation.resume(returning: isConnected)
            }
            
            monitor.start(queue: queue)
            
            // Timeout after 1 second
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                monitor.cancel()
                continuation.resume(returning: true) // Assume online if check times out
            }
        }
    }
    
    /// Adds a user to urgent contacts list (with optimistic update)
    /// - Parameter userID: User ID to add
    func addUrgentContact(_ contactUserID: String) async {
        guard var currentPreferences = preferences else { return }
        
        // Check if already added
        if currentPreferences.urgentContacts.contains(contactUserID) {
            return
        }
        
        // Check max limit
        if currentPreferences.urgentContacts.count >= 20 {
            errorMessage = "Maximum 20 urgent contacts allowed"
            return
        }
        
        // Optimistic update
        currentPreferences.urgentContacts.append(contactUserID)
        preferences = currentPreferences
        
        do {
            try await preferencesService.addUrgentContact(contactUserID, for: userID)
        } catch {
            // Revert optimistic update on error
            currentPreferences.urgentContacts.removeAll { $0 == contactUserID }
            preferences = currentPreferences
            errorMessage = error.localizedDescription
        }
    }
    
    /// Removes a user from urgent contacts list (with optimistic update)
    /// - Parameter userID: User ID to remove
    func removeUrgentContact(_ contactUserID: String) async {
        guard var currentPreferences = preferences else { return }
        
        // Optimistic update
        currentPreferences.urgentContacts.removeAll { $0 == contactUserID }
        preferences = currentPreferences
        
        do {
            try await preferencesService.removeUrgentContact(contactUserID, for: userID)
        } catch {
            // Revert optimistic update on error
            currentPreferences.urgentContacts.append(contactUserID)
            preferences = currentPreferences
            errorMessage = error.localizedDescription
        }
    }
    
    /// Updates focus hours configuration
    /// - Parameter focusHours: New focus hours configuration
    func updateFocusHours(_ focusHours: FocusHours) {
        guard var currentPreferences = preferences else { return }
        
        currentPreferences.focusHours = focusHours
        currentPreferences.updatedAt = Date()
        preferences = currentPreferences
    }
    
    /// Updates urgent keywords
    /// - Parameter keywords: New keywords array
    func updateUrgentKeywords(_ keywords: [String]) {
        guard var currentPreferences = preferences else { return }
        
        // Validate keyword count
        guard keywords.count >= 3 && keywords.count <= 50 else {
            if keywords.count < 3 {
                errorMessage = "Please add at least 3 urgent keywords"
            } else {
                errorMessage = "Maximum 50 keywords allowed"
            }
            return
        }
        
        currentPreferences.urgentKeywords = keywords
        currentPreferences.updatedAt = Date()
        preferences = currentPreferences
    }
    
    /// Updates priority rules configuration
    /// - Parameter rules: New priority rules
    func updatePriorityRules(_ rules: PriorityRules) {
        guard var currentPreferences = preferences else { return }
        
        currentPreferences.priorityRules = rules
        currentPreferences.updatedAt = Date()
        preferences = currentPreferences
    }
    
    /// Updates communication tone
    /// - Parameter tone: New communication tone
    func updateCommunicationTone(_ tone: CommunicationTone) {
        guard var currentPreferences = preferences else { return }
        
        currentPreferences.communicationTone = tone
        currentPreferences.updatedAt = Date()
        preferences = currentPreferences
    }
    
    /// Starts real-time observation of preferences
    /// - Performance: Updates sync <500ms per PRD
    func startObserving() {
        guard listener == nil else { return }
        
        do {
            listener = try preferencesService.observePreferences(for: userID) { [weak self] updatedPreferences in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let updatedPreferences = updatedPreferences {
                        self.preferences = updatedPreferences
                        self.isSyncActive = true
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Stops real-time observation
    nonisolated func stopObserving() {
        listener?.remove()
        listener = nil
    }
    
    /// Clears error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Resets to default preferences
    func resetToDefaults() {
        preferences = UserPreferences.defaultPreferences
    }
    
    // MARK: - Validation Helpers
    
    /// Checks if current preferences are valid
    var isValid: Bool {
        preferences?.isValid ?? false
    }
    
    /// Gets validation error message if any
    var validationError: String? {
        preferences?.validationError
    }
}


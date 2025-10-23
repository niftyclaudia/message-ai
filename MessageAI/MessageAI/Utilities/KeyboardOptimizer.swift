//
//  KeyboardOptimizer.swift
//  MessageAI
//
//  Keyboard optimization utility to eliminate jank and maintain input focus
//

import Foundation
import SwiftUI
import Combine

/// Keyboard state for optimization
enum KeyboardState {
    case hidden
    case showing
    case visible
    case hiding
}

/// Keyboard optimizer for smooth transitions and focus management
/// - Note: Eliminates jank during keyboard show/hide and maintains input focus
@MainActor
class KeyboardOptimizer: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var keyboardHeight: CGFloat = 0
    @Published var keyboardState: KeyboardState = .hidden
    @Published var isKeyboardVisible: Bool = false
    @Published var animationDuration: Double = 0.25
    @Published var animationCurve: Animation = .easeInOut(duration: 0.25)
    
    // MARK: - Private Properties
    
    private var keyboardObserver: AnyCancellable?
    private var focusTimer: Timer?
    private var lastFocusTime: Date = Date()
    private var isTransitioning: Bool = false
    
    // MARK: - Initialization
    
    init() {
        setupKeyboardObserver()
    }
    
    deinit {
        keyboardObserver?.cancel()
        focusTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Optimizes keyboard handling for smooth transitions
    func optimizeKeyboardHandling() {
        // Start keyboard transition tracking
        PerformanceMonitor.shared.startKeyboardTransition()
        
        // Configure smooth animations
        configureSmoothAnimations()
        
        // Set up focus management
        setupFocusManagement()
    }
    
    /// Handles keyboard transition with smooth animation
    /// - Parameter height: New keyboard height
    func handleKeyboardTransition(height: CGFloat) {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        
        // Update state
        let wasVisible = isKeyboardVisible
        let isNowVisible = height > 0
        
        if isNowVisible && !wasVisible {
            keyboardState = .showing
        } else if !isNowVisible && wasVisible {
            keyboardState = .hiding
        } else if isNowVisible {
            keyboardState = .visible
        } else {
            keyboardState = .hidden
        }
        
        // Animate height change
        withAnimation(animationCurve) {
            keyboardHeight = height
            isKeyboardVisible = isNowVisible
        }
        
        // Complete transition
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            self?.isTransitioning = false
            self?.keyboardState = isNowVisible ? .visible : .hidden
            
            // Track completion
            PerformanceMonitor.shared.endKeyboardTransition()
        }
    }
    
    /// Maintains input focus during keyboard transitions
    /// - Parameter textField: The text field to maintain focus on
    func maintainInputFocus<T: View>(textField: T) -> some View {
        return textField
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                self.handleKeyboardWillShow()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                self.handleKeyboardWillHide()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                self.handleKeyboardDidShow()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
                self.handleKeyboardDidHide()
            }
    }
    
    /// Adds haptic feedback for key interactions
    /// - Parameter interaction: The type of interaction
    func addHapticFeedback(for interaction: HapticInteraction) {
        let impactFeedback = UIImpactFeedbackGenerator(style: interaction.hapticStyle)
        impactFeedback.impactOccurred()
    }
    
    /// Gets the safe area for content above keyboard
    /// - Returns: Safe area height
    func getKeyboardSafeArea() -> CGFloat {
        return keyboardHeight
    }
    
    /// Checks if keyboard is currently transitioning
    /// - Returns: True if transitioning
    func isKeyboardTransitioning() -> Bool {
        return isTransitioning
    }
    
    /// Gets the current keyboard animation curve
    /// - Returns: Animation curve for keyboard transitions
    func getKeyboardAnimation() -> Animation {
        return animationCurve
    }
    
    // MARK: - Private Methods
    
    /// Sets up keyboard observer for notifications
    private func setupKeyboardObserver() {
        keyboardObserver = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardFrameChange(notification)
            }
    }
    
    /// Handles keyboard frame change notification
    /// - Parameter notification: The keyboard notification
    private func handleKeyboardFrameChange(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        
        // Update animation properties
        self.animationDuration = animationDuration
        self.animationCurve = Animation.timingCurve(
            UnitCurve(rawValue: animationCurve) ?? .easeInOut,
            duration: animationDuration
        )
        
        // Calculate keyboard height
        let screenHeight = UIScreen.main.bounds.height
        let keyboardHeight = max(0, screenHeight - keyboardFrame.minY)
        
        // Handle transition
        handleKeyboardTransition(height: keyboardHeight)
    }
    
    /// Configures smooth animations for keyboard transitions
    private func configureSmoothAnimations() {
        // Use optimized animation curves
        animationCurve = .timingCurve(.easeInOut, duration: animationDuration)
    }
    
    /// Sets up focus management
    private func setupFocusManagement() {
        // Set up focus timer for maintaining input focus
        focusTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.maintainFocusIfNeeded()
        }
    }
    
    /// Maintains focus if needed during transitions
    private func maintainFocusIfNeeded() {
        Task { @MainActor in
            // Only maintain focus during keyboard transitions
            guard isTransitioning else { return }
            
            // Check if focus is still needed
            let timeSinceLastFocus = Date().timeIntervalSince(lastFocusTime)
            if timeSinceLastFocus > 0.5 {
                // Focus might be lost, try to restore
                restoreFocus()
            }
        }
    }
    
    /// Restores focus to the active text field
    private func restoreFocus() {
        // Find the first responder and ensure it stays focused
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let firstResponder = windowScene.windows.first?.rootViewController?.view.findFirstResponder() {
            firstResponder.becomeFirstResponder()
            lastFocusTime = Date()
        }
    }
    
    /// Handles keyboard will show notification
    func handleKeyboardWillShow() {
        // Start transition tracking
        PerformanceMonitor.shared.startKeyboardTransition()
    }
    
    /// Handles keyboard will hide notification
    func handleKeyboardWillHide() {
        // Continue transition tracking
    }
    
    /// Handles keyboard did show notification
    func handleKeyboardDidShow() {
        // Complete transition tracking
        PerformanceMonitor.shared.endKeyboardTransition()
    }
    
    /// Handles keyboard did hide notification
    func handleKeyboardDidHide() {
        // Complete transition tracking
        PerformanceMonitor.shared.endKeyboardTransition()
    }
}

// MARK: - Haptic Interaction Types

enum HapticInteraction {
    case send
    case retry
    case error
    case success
    case tap
    
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .send, .success:
            return .light
        case .retry:
            return .medium
        case .error:
            return .heavy
        case .tap:
            return .light
        }
    }
}

// MARK: - View Extensions

extension View {
    
    /// Applies keyboard optimization to a view
    /// - Parameter optimizer: The keyboard optimizer
    /// - Returns: View with keyboard optimization applied
    func keyboardOptimized(optimizer: KeyboardOptimizer) -> some View {
        self
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                optimizer.handleKeyboardWillShow()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                optimizer.handleKeyboardWillHide()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                optimizer.handleKeyboardDidShow()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
                optimizer.handleKeyboardDidHide()
            }
    }
    
    /// Adds haptic feedback to a view
    /// - Parameters:
    ///   - interaction: The haptic interaction type
    ///   - optimizer: The keyboard optimizer
    /// - Returns: View with haptic feedback
    func hapticFeedback(_ interaction: HapticInteraction, optimizer: KeyboardOptimizer) -> some View {
        self.onTapGesture {
            optimizer.addHapticFeedback(for: interaction)
        }
    }
}

// MARK: - UIView Extensions

extension UIView {
    
    /// Finds the first responder in the view hierarchy
    /// - Returns: The first responder view or nil
    func findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }
        
        for subview in subviews {
            if let firstResponder = subview.findFirstResponder() {
                return firstResponder
            }
        }
        
        return nil
    }
}

// MARK: - UnitCurve Extension

extension UnitCurve {
    
    /// Creates a UnitCurve from a UInt value
    /// - Parameter rawValue: The raw UInt value
    /// - Returns: UnitCurve or default easeInOut
    init?(rawValue: UInt) {
        switch rawValue {
        case 0:
            self = .easeInOut
        case 1:
            self = .easeIn
        case 2:
            self = .easeOut
        case 3:
            self = .linear
        default:
            return nil
        }
    }
}

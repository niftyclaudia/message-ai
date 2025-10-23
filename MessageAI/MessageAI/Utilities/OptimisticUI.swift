//
//  OptimisticUI.swift
//  MessageAI
//
//  Optimistic UI utility for instant feedback and retry mechanisms
//

import Foundation
import SwiftUI
import Combine

/// UI state for optimistic operations
enum UIState {
    case idle
    case optimistic(operation: String)
    case loading
    case error(message: String)
    case retrying(attempt: Int)
    case success(operation: String)
}

/// Optimistic UI manager for instant feedback and retry mechanisms
/// - Note: Handles optimistic updates with proper state management and retry logic
@MainActor
class OptimisticUI: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentState: UIState = .idle
    @Published var isOptimisticUpdate: Bool = false
    @Published var retryCount: Int = 0
    @Published var maxRetries: Int = 3
    @Published var retryDelay: TimeInterval = 1.0
    
    // MARK: - Private Properties
    
    private var retryTimer: Timer?
    private var operationQueue: [OptimisticOperation] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Performs an optimistic operation with instant UI feedback
    /// - Parameters:
    ///   - operation: The operation to perform
    ///   - fallback: Fallback value if operation fails
    /// - Returns: Result of the operation
    func performOptimisticOperation<T>(
        operation: @escaping () async throws -> T,
        fallback: T
    ) async -> T {
        
        // Start optimistic state
        currentState = .optimistic(operation: "Processing...")
        isOptimisticUpdate = true
        
        // Track UI response time
        PerformanceMonitor.shared.startUIResponse(action: "optimistic_operation")
        
        do {
            let result = try await operation()
            
            // Success - update state
            await MainActor.run {
                currentState = .success(operation: "Completed")
                isOptimisticUpdate = false
            }
            
            // Track success
            PerformanceMonitor.shared.endUIResponse(action: "optimistic_operation")
            
            // Clear success state after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.currentState = .idle
            }
            
            return result
            
        } catch {
            // Failure - start retry process
            await MainActor.run {
                currentState = .error(message: error.localizedDescription)
                isOptimisticUpdate = false
            }
            
            // Track failure
            PerformanceMonitor.shared.endUIResponse(action: "optimistic_operation")
            
            // Start retry process
            await startRetryProcess(operation: operation, fallback: fallback)
            
            return fallback
        }
    }
    
    /// Retries a failed operation with exponential backoff
    /// - Parameters:
    ///   - operation: The operation to retry
    ///   - maxRetries: Maximum number of retry attempts
    /// - Returns: Result of the retry operation
    func retryFailedOperation<T>(
        operation: @escaping () async throws -> T,
        maxRetries: Int = 3
    ) async throws -> T {
        
        var attempt = 0
        var lastError: Error?
        
        while attempt < maxRetries {
            attempt += 1
            retryCount = attempt
            
            // Update state
            currentState = .retrying(attempt: attempt)
            
            do {
                let result = try await operation()
                
                // Success
                currentState = .success(operation: "Retry successful")
                retryCount = 0
                
                // Clear success state after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.currentState = .idle
                }
                
                return result
                
            } catch {
                lastError = error
                
                // Wait before next retry (exponential backoff)
                if attempt < maxRetries {
                    let delay = retryDelay * pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // All retries failed
        currentState = .error(message: "Failed after \(maxRetries) attempts: \(lastError?.localizedDescription ?? "Unknown error")")
        retryCount = 0
        
        throw lastError ?? OptimisticUIError.retryFailed
    }
    
    /// Updates UI state with animation
    /// - Parameter state: The new UI state
    func updateUIState(_ state: UIState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentState = state
        }
    }
    
    /// Clears all optimistic state
    func clearOptimisticState() {
        currentState = .idle
        isOptimisticUpdate = false
        retryCount = 0
        retryTimer?.invalidate()
        retryTimer = nil
    }
    
    /// Gets the current error message if in error state
    /// - Returns: Error message or nil
    func getErrorMessage() -> String? {
        if case .error(let message) = currentState {
            return message
        }
        return nil
    }
    
    /// Checks if currently in an optimistic state
    /// - Returns: True if in optimistic state
    func isInOptimisticState() -> Bool {
        if case .optimistic = currentState {
            return true
        }
        return false
    }
    
    /// Checks if currently retrying
    /// - Returns: True if retrying
    func isRetrying() -> Bool {
        if case .retrying = currentState {
            return true
        }
        return false
    }
    
    // MARK: - Private Methods
    
    /// Starts the retry process for a failed operation
    /// - Parameters:
    ///   - operation: The operation to retry
    ///   - fallback: Fallback value
    private func startRetryProcess<T>(
        operation: @escaping () async throws -> T,
        fallback: T
    ) {
        // Queue the retry operation
        let retryOp = OptimisticOperation(
            id: UUID().uuidString,
            operation: operation,
            fallback: fallback,
            maxRetries: maxRetries
        )
        
        operationQueue.append(retryOp)
        
        // Start retry timer
        retryTimer = Timer.scheduledTimer(withTimeInterval: retryDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.processRetryQueue()
            }
        }
    }
    
    /// Processes the retry queue
    private func processRetryQueue() async {
        guard !operationQueue.isEmpty else { return }
        
        let operation = operationQueue.removeFirst()
        
        do {
            _ = try await retryFailedOperation(
                operation: operation.operation,
                maxRetries: operation.maxRetries
            )
        } catch {
            // Retry failed - remove from queue
            print("OptimisticUI: Retry failed for operation \(operation.id): \(error)")
        }
    }
}

// MARK: - Optimistic Operation Model

struct OptimisticOperation {
    let id: String
    let operation: () async throws -> Any
    let fallback: Any
    let maxRetries: Int
}

// MARK: - Optimistic UI Errors

enum OptimisticUIError: Error, LocalizedError {
    case retryFailed
    case operationTimeout
    case invalidState
    
    var errorDescription: String? {
        switch self {
        case .retryFailed:
            return "Retry operation failed"
        case .operationTimeout:
            return "Operation timed out"
        case .invalidState:
            return "Invalid UI state"
        }
    }
}

// MARK: - Optimistic UI Extensions

extension OptimisticUI {
    
    /// Creates an optimistic message for immediate UI display
    /// - Parameters:
    ///   - chatID: The chat ID
    ///   - text: The message text
    ///   - senderID: The sender ID
    /// - Returns: Optimistic message
    func createOptimisticMessage(chatID: String, text: String, senderID: String) -> Message {
        return Message(
            id: UUID().uuidString,
            chatID: chatID,
            senderID: senderID,
            text: text,
            timestamp: Date(),
            serverTimestamp: nil,
            readBy: [senderID],
            status: .sending,
            senderName: nil,
            isOffline: false,
            retryCount: 0,
            isOptimistic: true
        )
    }
    
    /// Handles optimistic message sending with retry
    /// - Parameters:
    ///   - message: The message to send
    ///   - messageService: The message service
    /// - Returns: Success or failure
    func sendOptimisticMessage(
        message: Message,
        messageService: MessageService
    ) async -> Bool {
        
        return await performOptimisticOperation(
            operation: {
                _ = try await messageService.sendMessage(
                    chatID: message.chatID,
                    text: message.text,
                    senderName: message.senderName
                )
                return true
            },
            fallback: false
        )
    }
    
    /// Handles optimistic message retry
    /// - Parameters:
    ///   - messageID: The message ID to retry
    ///   - messageService: The message service
    /// - Returns: Success or failure
    func retryOptimisticMessage(
        messageID: String,
        messageService: MessageService
    ) async -> Bool {
        
        do {
            _ = try await retryFailedOperation(
                operation: {
                    try await messageService.retryFailedMessage(messageID: messageID)
                },
                maxRetries: maxRetries
            )
            return true
        } catch {
            return false
        }
    }
}

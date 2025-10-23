//
//  RetryButton.swift
//  MessageAI
//
//  Retry button component for failed operations
//

import SwiftUI

/// Retry button for failed operations
/// - Note: Provides smooth retry mechanisms with user feedback
struct RetryButton: View {
    
    // MARK: - Properties
    
    let action: () -> Void
    let isRetrying: Bool
    let retryCount: Int
    let maxRetries: Int
    let style: RetryButtonStyle
    
    // MARK: - Initialization
    
    init(
        action: @escaping () -> Void,
        isRetrying: Bool = false,
        retryCount: Int = 0,
        maxRetries: Int = 3,
        style: RetryButtonStyle = .primary
    ) {
        self.action = action
        self.isRetrying = isRetrying
        self.retryCount = retryCount
        self.maxRetries = maxRetries
        self.style = style
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isRetrying {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(buttonText)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(style.backgroundColor)
            .cornerRadius(style.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
        }
        .disabled(isRetrying)
        .opacity(isRetrying ? 0.7 : 1.0)
        .scaleEffect(isRetrying ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isRetrying)
    }
    
    // MARK: - Computed Properties
    
    private var buttonText: String {
        if isRetrying {
            return "Retrying..."
        } else if retryCount > 0 {
            return "Retry (\(retryCount)/\(maxRetries))"
        } else {
            return "Retry"
        }
    }
}

// MARK: - Retry Button Style

struct RetryButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    
    static let primary = RetryButtonStyle(
        backgroundColor: .blue,
        foregroundColor: .white,
        borderColor: .blue,
        borderWidth: 0,
        cornerRadius: 8
    )
    
    static let secondary = RetryButtonStyle(
        backgroundColor: .clear,
        foregroundColor: .blue,
        borderColor: .blue,
        borderWidth: 1,
        cornerRadius: 8
    )
    
    static let destructive = RetryButtonStyle(
        backgroundColor: .red,
        foregroundColor: .white,
        borderColor: .red,
        borderWidth: 0,
        cornerRadius: 8
    )
    
    static let minimal = RetryButtonStyle(
        backgroundColor: .clear,
        foregroundColor: .secondary,
        borderColor: .clear,
        borderWidth: 0,
        cornerRadius: 6
    )
}

// MARK: - Retry Button Variants

/// Retry button for message operations
struct MessageRetryButton: View {
    
    let messageID: String
    let onRetry: (String) -> Void
    let isRetrying: Bool
    let retryCount: Int
    
    var body: some View {
        RetryButton(
            action: { onRetry(messageID) },
            isRetrying: isRetrying,
            retryCount: retryCount,
            style: .minimal
        )
    }
}

/// Retry button for network operations
struct NetworkRetryButton: View {
    
    let onRetry: () -> Void
    let isRetrying: Bool
    let retryCount: Int
    let maxRetries: Int
    
    var body: some View {
        RetryButton(
            action: onRetry,
            isRetrying: isRetrying,
            retryCount: retryCount,
            maxRetries: maxRetries,
            style: .secondary
        )
    }
}

/// Retry button for sync operations
struct SyncRetryButton: View {
    
    let onRetry: () -> Void
    let isRetrying: Bool
    let queuedCount: Int
    
    var body: some View {
        RetryButton(
            action: onRetry,
            isRetrying: isRetrying,
            retryCount: 0,
            style: .primary
        )
        .overlay(
            HStack {
                Spacer()
                if queuedCount > 0 {
                    Text("\(queuedCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 8, y: -8)
                }
            }
        )
    }
}

// MARK: - Retry Button with Haptic Feedback

struct HapticRetryButton: View {
    
    let action: () -> Void
    let isRetrying: Bool
    let retryCount: Int
    let maxRetries: Int
    let style: RetryButtonStyle
    
    var body: some View {
        RetryButton(
            action: {
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                action()
            },
            isRetrying: isRetrying,
            retryCount: retryCount,
            maxRetries: maxRetries,
            style: style
        )
    }
}

// MARK: - Retry Button Group

struct RetryButtonGroup: View {
    
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    let isRetrying: Bool
    let retryCount: Int
    let maxRetries: Int
    
    var body: some View {
        HStack(spacing: 12) {
            RetryButton(
                action: primaryAction,
                isRetrying: isRetrying,
                retryCount: retryCount,
                maxRetries: maxRetries,
                style: .primary
            )
            
            RetryButton(
                action: secondaryAction,
                isRetrying: false,
                retryCount: 0,
                maxRetries: 0,
                style: .secondary
            )
        }
    }
}

// MARK: - Preview

#Preview("Retry Button") {
    VStack(spacing: 20) {
        RetryButton(
            action: {},
            isRetrying: false,
            retryCount: 0,
            style: .primary
        )
        
        RetryButton(
            action: {},
            isRetrying: true,
            retryCount: 2,
            maxRetries: 3,
            style: .secondary
        )
        
        MessageRetryButton(
            messageID: "test",
            onRetry: { _ in },
            isRetrying: false,
            retryCount: 1
        )
        
        NetworkRetryButton(
            onRetry: {},
            isRetrying: false,
            retryCount: 1,
            maxRetries: 3
        )
        
        SyncRetryButton(
            onRetry: {},
            isRetrying: false,
            queuedCount: 3
        )
    }
    .padding()
}

//
//  CalmErrorView.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Calm intelligence error display with blue/gray theme and first-person messaging
//

import SwiftUI

struct CalmErrorView: View {
    let errorResponse: ErrorResponse
    let onRetry: () -> Void
    let onFallback: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            // Info icon (not error icon)
            Image(systemName: "info.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue.opacity(0.7))
            
            // Calm, first-person message
            Text(errorResponse.userMessage)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            // Action buttons
            VStack(spacing: 12) {
                // Primary action button
                Button(action: onRetry) {
                    HStack {
                        if errorResponse.shouldRetry {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(errorResponse.primaryActionTitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Secondary action (fallback) if available
                if let fallbackAction = errorResponse.fallbackAction,
                   let secondaryTitle = errorResponse.secondaryActionTitle,
                   let onFallback = onFallback {
                    Button(action: onFallback) {
                        HStack {
                            Image(systemName: fallbackAction.iconName)
                            Text(secondaryTitle)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "F0F4F8")) // Calm blue/gray background
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview("Retryable Error") {
    CalmErrorView(
        errorResponse: ErrorResponse(
            error: AIError(
                type: .timeout,
                message: "Operation timed out"
            ),
            userMessage: "I'm having trouble right now. Want to try again?",
            fallbackAction: .openFullThread(threadId: "123"),
            shouldRetry: true,
            retryDelay: 1.0,
            primaryActionTitle: "Try Again",
            secondaryActionTitle: "Open Full Thread"
        ),
        onRetry: {
            print("Retry tapped")
        },
        onFallback: {
            print("Fallback tapped")
        }
    )
}

#Preview("Non-Retryable Error") {
    CalmErrorView(
        errorResponse: ErrorResponse(
            error: AIError(
                type: .quotaExceeded,
                message: "Quota exceeded"
            ),
            userMessage: "AI features are temporarily limited. I'll be back soon!",
            fallbackAction: nil,
            shouldRetry: false,
            retryDelay: 0,
            primaryActionTitle: "Got It",
            secondaryActionTitle: nil
        ),
        onRetry: {
            print("Got it tapped")
        },
        onFallback: nil
    )
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}


//
//  MessageStatusIndicatorView.swift
//  MessageAI
//
//  Message status indicator component with animations
//

import SwiftUI

/// Message status indicator view with smooth animations
/// - Note: Displays sending, sent, delivered, read, failed, and queued states with animations
struct MessageStatusIndicatorView: View {
    
    // MARK: - Properties
    
    let status: MessageStatus
    let isOptimistic: Bool
    let onRetry: (() -> Void)?
    
    // MARK: - Animation Properties
    
    @State private var isAnimating: Bool = false
    @State private var rotationAngle: Double = 0
    @State private var scale: Double = 1.0
    @State private var opacity: Double = 1.0
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 4) {
            statusIcon
                .scaleEffect(scale)
                .opacity(opacity)
                .rotationEffect(.degrees(rotationAngle))
                .animation(.easeInOut(duration: 0.3), value: scale)
                .animation(.easeInOut(duration: 0.3), value: opacity)
                .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: rotationAngle)
            
            if let onRetry = onRetry, status == .failed {
                retryButton(onRetry: onRetry)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: status) { _, newStatus in
            animateStatusChange(to: newStatus)
        }
    }
    
    // MARK: - Status Icon
    
    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .sending:
            if isOptimistic {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(.blue)
            } else {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundColor(.blue)
            
        case .delivered:
            Image(systemName: "checkmark.circle")
                .font(.caption)
                .foregroundColor(.blue)
            
        case .read:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.blue)
            
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .font(.caption)
                .foregroundColor(.red)
            
        case .queued:
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
    
    // MARK: - Retry Button
    
    private func retryButton(onRetry: @escaping () -> Void) -> some View {
        Button(action: onRetry) {
            Image(systemName: "arrow.clockwise")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
        .scaleEffect(scale)
        .animation(.easeInOut(duration: 0.2), value: scale)
    }
    
    // MARK: - Animation Methods
    
    private func startAnimations() {
        switch status {
        case .sending:
            if isOptimistic {
                // Continuous rotation for optimistic sending
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                // Subtle pulsing
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    scale = 1.1
                }
            }
        case .sent, .delivered, .read:
            // Success animation
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 1.2
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                scale = 1.0
            }
        case .failed:
            // Shake animation for failed
            withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                rotationAngle = 5
            }
            withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true).delay(0.3)) {
                rotationAngle = -5
            }
            withAnimation(.easeInOut(duration: 0.1).delay(0.6)) {
                rotationAngle = 0
            }
        case .queued:
            // Gentle pulsing for queued
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                opacity = 0.6
            }
        }
    }
    
    private func animateStatusChange(to newStatus: MessageStatus) {
        // Reset animations
        rotationAngle = 0
        scale = 1.0
        opacity = 1.0
        
        // Start new animations based on status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startAnimations()
        }
    }
}

// MARK: - Animated Status Icon

struct AnimatedStatusIcon: View {
    
    // MARK: - Properties
    
    let status: MessageStatus
    let isOptimistic: Bool
    
    // MARK: - Animation Properties
    
    @State private var isRotating: Bool = false
    @State private var isPulsing: Bool = false
    @State private var isBouncing: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch status {
            case .sending:
                if isOptimistic {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.blue)
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                } else {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                }
                
            case .sent:
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .scaleEffect(isBouncing ? 1.2 : 1.0)
                
            case .delivered:
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.blue)
                    .scaleEffect(isBouncing ? 1.2 : 1.0)
                
            case .read:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .scaleEffect(isBouncing ? 1.2 : 1.0)
                
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.red)
                    .scaleEffect(isBouncing ? 1.1 : 1.0)
                
            case .queued:
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.orange)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animation Methods
    
    private func startAnimations() {
        switch status {
        case .sending:
            if isOptimistic {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    isRotating = true
                }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        case .sent, .delivered, .read:
            withAnimation(.easeOut(duration: 0.3)) {
                isBouncing = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                isBouncing = false
            }
        case .failed:
            withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                isBouncing = true
            }
        case .queued:
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ForEach(MessageStatus.allCases, id: \.self) { status in
            HStack {
                Text(status.rawValue.capitalized)
                    .font(.caption)
                    .frame(width: 80, alignment: .leading)
                
                MessageStatusIndicatorView(
                    status: status,
                    isOptimistic: status == .sending,
                    onRetry: status == .failed ? {} : nil
                )
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    .padding()
}

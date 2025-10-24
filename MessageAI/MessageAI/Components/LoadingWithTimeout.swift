//
//  LoadingWithTimeout.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Loading indicator with timeout warning and cancel option
//

import SwiftUI

struct LoadingWithTimeout: View {
    let message: String
    let timeoutSeconds: TimeInterval
    let onCancel: () -> Void
    
    @State private var showingCancelOption = false
    @State private var elapsedTime: TimeInterval = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(
        message: String = "Loading...",
        timeoutSeconds: TimeInterval = 8.0,
        onCancel: @escaping () -> Void
    ) {
        self.message = message
        self.timeoutSeconds = timeoutSeconds
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Loading spinner
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.2)
            
            // Loading message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
            
            // Cancel option after timeout
            if showingCancelOption {
                Button(action: onCancel) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Taking too long? Cancel")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onReceive(timer) { _ in
            elapsedTime += 1
            
            if elapsedTime >= timeoutSeconds && !showingCancelOption {
                withAnimation {
                    showingCancelOption = true
                }
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
    }
}

// MARK: - Previews

#Preview("Loading") {
    LoadingWithTimeout(
        message: "Generating summary...",
        timeoutSeconds: 2, // Shortened for preview
        onCancel: {
            print("Cancel tapped")
        }
    )
}

#Preview("With Cancel Option") {
    @Previewable @State var showCancel = true
    
    VStack(spacing: 16) {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            .scaleEffect(1.2)
        
        Text("Generating summary...")
            .font(.body)
            .foregroundColor(.secondary)
        
        if showCancel {
            Button(action: {}) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Taking too long? Cancel")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                )
            }
        }
    }
}


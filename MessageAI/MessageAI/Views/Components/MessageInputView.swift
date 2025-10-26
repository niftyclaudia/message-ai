//
//  MessageInputView.swift
//  MessageAI
//
//  Message input component with send functionality
//

import SwiftUI
import UIKit

/// Message input view with text field and send button
/// - Note: Handles message composition and sending with loading states
struct MessageInputView: View {
    
    // MARK: - Properties
    
    @Binding var messageText: String
    @Binding var isSending: Bool
    @Binding var isOffline: Bool
    
    let onSend: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Text input field
            textInputField
            
            // Send button
            sendButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
    }
    
    // MARK: - Text Input Field
    
    private var textInputField: some View {
        HStack {
            TextField("Type a message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .disabled(isSending)
                .focused($isTextFieldFocused)
                .onTapGesture {
                    DispatchQueue.main.async {
                        isTextFieldFocused = true
                    }
                }
                .onSubmit {
                    // Handle Enter key press
                    if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        isTextFieldFocused = false
                        onSend()
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Send") {
                            if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                isTextFieldFocused = false
                                onSend()
                            }
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            
            if isOffline {
                offlineIndicator
            }
        }
    }
    
    // MARK: - Send Button
    
    private var sendButton: some View {
        Button(action: {
            guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            isTextFieldFocused = false // Dismiss keyboard
            onSend()
        }) {
            Group {
                if isSending {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
            }
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(canSend ? Color.blue : Color.gray)
            )
        }
        .disabled(!canSend || isSending)
        .animation(.easeInOut(duration: 0.2), value: canSend)
    }
    
    // MARK: - Offline Indicator
    
    private var offlineIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "wifi.slash")
                .font(.caption)
                .foregroundColor(.orange)
            
            Text("Offline")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Properties
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        
        MessageInputView(
            messageText: .constant(""),
            isSending: .constant(false),
            isOffline: .constant(false),
            onSend: {}
        )
    }
    .background(Color(.systemGroupedBackground))
}

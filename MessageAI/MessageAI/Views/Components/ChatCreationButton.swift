//
//  ChatCreationButton.swift
//  MessageAI
//
//  Create chat button with loading states
//

import SwiftUI

/// Create chat button with loading states
/// - Note: Handles enabled/disabled states and loading animation
struct ChatCreationButton: View {
    
    // MARK: - Properties
    
    let isEnabled: Bool
    let isLoading: Bool
    let selectedCount: Int
    let isGroupChat: Bool
    let onTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: isGroupChat ? "person.3.fill" : "person.fill")
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(buttonTitle)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
    
    // MARK: - Computed Properties
    
    private var buttonTitle: String {
        if isLoading {
            return "Creating..."
        } else if selectedCount == 0 {
            return "Select Contacts"
        } else if isGroupChat {
            return "Create Group Chat"
        } else {
            return "Start Chat"
        }
    }
    
    private var backgroundColor: Color {
        if isEnabled && !isLoading {
            return .blue
        } else {
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Disabled state
        ChatCreationButton(
            isEnabled: false,
            isLoading: false,
            selectedCount: 0,
            isGroupChat: false,
            onTap: {}
        )
        
        // Enabled - one-on-one
        ChatCreationButton(
            isEnabled: true,
            isLoading: false,
            selectedCount: 1,
            isGroupChat: false,
            onTap: {}
        )
        
        // Enabled - group chat
        ChatCreationButton(
            isEnabled: true,
            isLoading: false,
            selectedCount: 3,
            isGroupChat: true,
            onTap: {}
        )
        
        // Loading state
        ChatCreationButton(
            isEnabled: true,
            isLoading: true,
            selectedCount: 2,
            isGroupChat: true,
            onTap: {}
        )
    }
    .padding()
}

//
//  PrimaryButton.swift
//  MessageAI
//
//  Reusable primary action button with loading state
//

import SwiftUI

/// Primary action button with consistent styling and loading state
/// - Note: Follows AppTheme design system
struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(AppTheme.headlineFont)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.buttonHeight)
            .background(AppTheme.primaryColor)
            .cornerRadius(AppTheme.mediumRadius)
        }
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: AppTheme.mediumSpacing) {
        PrimaryButton(title: "Sign In", isLoading: false) {
        }
        
        PrimaryButton(title: "Loading...", isLoading: true) {
        }
    }
    .padding()
}


//
//  CalmErrorToast.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Bottom toast notification for background AI errors
//

import SwiftUI

struct CalmErrorToast: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "F0F4F8"))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: isShowing)
        .onChange(of: isShowing) { oldValue, newValue in
            if newValue {
                // Auto-dismiss after 4 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    @Previewable @State var isShowing = true
    
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        CalmErrorToast(
            message: "I need a moment to catch up. Try again in 30 seconds?",
            isShowing: $isShowing
        )
    }
}


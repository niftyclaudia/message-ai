//
//  FallbackModeIndicator.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Top banner indicator when AI feature is in fallback/degraded mode
//

import SwiftUI

struct FallbackModeIndicator: View {
    let feature: AIFeature
    @State private var showingExplanation = false
    
    var body: some View {
        Button(action: {
            showingExplanation = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue.opacity(0.7))
                
                Text("🔵 \(feature.fallbackModeDescription)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "F0F4F8"))
        }
        .sheet(isPresented: $showingExplanation) {
            FallbackModeExplanationSheet(feature: feature)
        }
    }
}

struct FallbackModeExplanationSheet: View {
    let feature: AIFeature
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Using Basic Mode")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(feature.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)
                
                // Explanation
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's happening?")
                        .font(.headline)
                    
                    Text("I've switched to a simpler mode because I'm having trouble with my AI assistant right now. Don't worry—everything still works, just with a bit less intelligence for the moment.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("What does this mean?")
                        .font(.headline)
                    
                    Text("• \(feature.fallbackModeDescription)")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("• Your messages and data are safe")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("• I'll automatically switch back when things improve")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: {
                    dismiss()
                }) {
                    Text("Got It")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Banner") {
    FallbackModeIndicator(feature: .smartSearch)
}

#Preview("Explanation Sheet") {
    FallbackModeExplanationSheet(feature: .threadSummary)
}


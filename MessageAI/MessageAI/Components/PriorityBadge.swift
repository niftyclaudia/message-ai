//
//  PriorityBadge.swift
//  MessageAI
//
//  Reusable priority indicator component for message categorization
//

import SwiftUI

/// Reusable priority badge component for displaying message categorization
struct PriorityBadge: View {
    
    // MARK: - Properties
    
    let category: MessageCategory
    let confidence: Double?
    let showConfidence: Bool
    
    // MARK: - Initialization
    
    init(
        category: MessageCategory,
        confidence: Double? = nil,
        showConfidence: Bool = false
    ) {
        self.category = category
        self.confidence = confidence
        self.showConfidence = showConfidence
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 4) {
            // Priority icon
            Image(systemName: category.iconName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(category.iconColor)
            
            // Category text
            Text(category.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(category.textColor)
            
            // Confidence indicator (optional)
            if showConfidence, let confidence = confidence {
                Text("\(Int(confidence * 100))%")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(category.textColor.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(category.borderColor, lineWidth: 1)
        )
    }
}


// MARK: - Preview

struct PriorityBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Urgent badge
            PriorityBadge(
                category: .urgent,
                confidence: 0.9,
                showConfidence: true
            )
            
            // Can Wait badge
            PriorityBadge(
                category: .canWait,
                confidence: 0.7,
                showConfidence: true
            )
            
            // AI Handled badge
            PriorityBadge(
                category: .aiHandled,
                confidence: 0.85,
                showConfidence: true
            )
            
            // Without confidence
            PriorityBadge(category: .urgent)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

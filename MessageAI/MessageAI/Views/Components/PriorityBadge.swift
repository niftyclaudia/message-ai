//
//  PriorityBadge.swift
//  MessageAI
//
//  Priority badge component for urgent messages
//

import SwiftUI

/// Priority badge component for displaying message urgency indicators
struct PriorityBadge: View {
    
    // MARK: - Properties
    
    /// The priority level to display
    let priority: String?
    
    /// The classification status
    let classificationStatus: ClassificationStatus
    
    /// Whether to show the badge (for customization)
    let isVisible: Bool
    
    /// Size variant for the badge
    let size: BadgeSize
    
    // MARK: - Initialization
    
    init(priority: String?, classificationStatus: ClassificationStatus = .pending, isVisible: Bool = true, size: BadgeSize = .medium) {
        self.priority = priority
        self.classificationStatus = classificationStatus
        self.isVisible = isVisible
        self.size = size
    }
    
    // MARK: - Body
    
    var body: some View {
        if isVisible {
            HStack(spacing: 4) {
                badgeContent
            }
            .animation(.easeInOut(duration: 0.2), value: priority)
            .animation(.easeInOut(duration: 0.2), value: classificationStatus)
        }
    }
    
    // MARK: - Badge Content
    
    @ViewBuilder
    private var badgeContent: some View {
        switch classificationStatus {
        case .pending:
            pendingBadge
        case .classified(let priority, _):
            if priority == "urgent" {
                urgentBadge
            } else {
                // Normal priority - no badge needed
                EmptyView()
            }
        case .failed:
            failedBadge
        case .feedbackSubmitted:
            feedbackSubmittedBadge
        }
    }
    
    // MARK: - Badge Variants
    
    /// Pending classification badge
    private var pendingBadge: some View {
        HStack(spacing: 2) {
            ProgressView()
                .scaleEffect(size.scaleFactor)
                .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
            
            if size == .large {
                Text("Classifying...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
    
    /// Urgent message badge
    private var urgentBadge: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(Color.red)
                .frame(width: size.dotSize, height: size.dotSize)
            
            if size == .large {
                Text("URGENT")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    /// Failed classification badge
    private var failedBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: size.iconSize))
            
            if size == .large {
                Text("Failed")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    /// Feedback submitted badge
    private var feedbackSubmittedBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: size.iconSize))
            
            if size == .large {
                Text("Feedback Sent")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color.green.opacity(0.1))
        )
    }
}

// MARK: - Badge Size

extension PriorityBadge {
    /// Size variants for the priority badge
    enum BadgeSize {
        case small
        case medium
        case large
        
        var scaleFactor: CGFloat {
            switch self {
            case .small: return 0.6
            case .medium: return 0.8
            case .large: return 1.0
            }
        }
        
        var dotSize: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
}

// MARK: - Preview

struct PriorityBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Small badges
            HStack(spacing: 8) {
                PriorityBadge(priority: nil, classificationStatus: .pending, size: .small)
                PriorityBadge(priority: "urgent", classificationStatus: .classified(priority: "urgent", confidence: 0.9), size: .small)
                PriorityBadge(priority: nil, classificationStatus: .failed(error: "Network error"), size: .small)
                PriorityBadge(priority: nil, classificationStatus: .feedbackSubmitted, size: .small)
            }
            
            // Medium badges
            HStack(spacing: 8) {
                PriorityBadge(priority: nil, classificationStatus: .pending, size: .medium)
                PriorityBadge(priority: "urgent", classificationStatus: .classified(priority: "urgent", confidence: 0.9), size: .medium)
                PriorityBadge(priority: nil, classificationStatus: .failed(error: "Network error"), size: .medium)
                PriorityBadge(priority: nil, classificationStatus: .feedbackSubmitted, size: .medium)
            }
            
            // Large badges
            VStack(spacing: 8) {
                PriorityBadge(priority: nil, classificationStatus: .pending, size: .large)
                PriorityBadge(priority: "urgent", classificationStatus: .classified(priority: "urgent", confidence: 0.9), size: .large)
                PriorityBadge(priority: nil, classificationStatus: .failed(error: "Network error"), size: .large)
                PriorityBadge(priority: nil, classificationStatus: .feedbackSubmitted, size: .large)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

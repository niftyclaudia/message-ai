//
//  ClassificationFeedbackView.swift
//  MessageAI
//
//  Classification feedback submission UI component
//

import SwiftUI

/// View for submitting classification feedback
struct ClassificationFeedbackView: View {
    
    // MARK: - Properties
    
    /// The message ID this feedback is for
    let messageId: String
    
    /// The current classification status
    let currentStatus: ClassificationStatus
    
    /// Callback when feedback is submitted
    let onFeedbackSubmitted: (String, String?) -> Void
    
    /// Callback when retry is requested
    let onRetryRequested: () -> Void
    
    /// Whether the view is currently submitting feedback
    @State private var isSubmitting = false
    
    /// Whether to show the feedback form
    @State private var showFeedbackForm = false
    
    /// The selected priority for feedback
    @State private var selectedPriority: String = "normal"
    
    /// Optional reason for the feedback
    @State private var feedbackReason: String = ""
    
    /// Whether to show the reason text field
    @State private var showReasonField = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Main feedback button
            feedbackButton
            
            // Feedback form (shown when button is tapped)
            if showFeedbackForm {
                feedbackForm
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showFeedbackForm)
    }
    
    // MARK: - Feedback Button
    
    @ViewBuilder
    private var feedbackButton: some View {
        Button(action: {
            withAnimation {
                showFeedbackForm.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(buttonText)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(buttonColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(buttonColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(buttonColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(isSubmitting)
    }
    
    // MARK: - Feedback Form
    
    private var feedbackForm: some View {
        VStack(spacing: 12) {
            // Priority selection
            prioritySelection
            
            // Reason field (optional)
            if showReasonField {
                reasonField
            }
            
            // Action buttons
            actionButtons
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
        .padding(.top, 8)
    }
    
    // MARK: - Priority Selection
    
    private var prioritySelection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This message should be:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                priorityButton(title: "Normal", priority: "normal", color: .blue)
                priorityButton(title: "Urgent", priority: "urgent", color: .red)
            }
        }
    }
    
    private func priorityButton(title: String, priority: String, color: Color) -> some View {
        Button(action: {
            selectedPriority = priority
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(selectedPriority == priority ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedPriority == priority ? color : color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Reason Field
    
    private var reasonField: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Reason (optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Hide") {
                    withAnimation {
                        showReasonField = false
                        feedbackReason = ""
                    }
                }
                .font(.caption2)
                .foregroundColor(.blue)
            }
            
            TextField("Why should this be \(selectedPriority)?", text: $feedbackReason)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.caption)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Cancel button
            Button("Cancel") {
                withAnimation {
                    showFeedbackForm = false
                    resetForm()
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Spacer()
            
            // Add reason button
            if !showReasonField {
                Button("Add Reason") {
                    withAnimation {
                        showReasonField = true
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Submit button
            Button(action: submitFeedback) {
                HStack(spacing: 4) {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Text(isSubmitting ? "Submitting..." : "Submit")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedPriority == "urgent" ? Color.red : Color.blue)
                )
            }
            .disabled(isSubmitting)
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonIcon: String {
        switch currentStatus {
        case .pending:
            return "clock"
        case .classified:
            return "exclamationmark.bubble"
        case .failed:
            return "arrow.clockwise"
        case .feedbackSubmitted:
            return "checkmark.circle"
        }
    }
    
    private var buttonText: String {
        switch currentStatus {
        case .pending:
            return "Classifying..."
        case .classified:
            return "Feedback"
        case .failed:
            return "Retry"
        case .feedbackSubmitted:
            return "Feedback Sent"
        }
    }
    
    private var buttonColor: Color {
        switch currentStatus {
        case .pending:
            return .secondary
        case .classified:
            return .blue
        case .failed:
            return .orange
        case .feedbackSubmitted:
            return .green
        }
    }
    
    // MARK: - Actions
    
    private func submitFeedback() {
        guard !isSubmitting else { return }
        
        isSubmitting = true
        
        // Simulate submission delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSubmitting = false
            
            let reason = feedbackReason.isEmpty ? nil : feedbackReason
            onFeedbackSubmitted(selectedPriority, reason)
            
            withAnimation {
                showFeedbackForm = false
                resetForm()
            }
        }
    }
    
    private func resetForm() {
        selectedPriority = "normal"
        feedbackReason = ""
        showReasonField = false
    }
}

// MARK: - Preview

struct ClassificationFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Pending status
            ClassificationFeedbackView(
                messageId: "test1",
                currentStatus: .pending,
                onFeedbackSubmitted: { _, _ in },
                onRetryRequested: { }
            )
            
            // Classified status
            ClassificationFeedbackView(
                messageId: "test2",
                currentStatus: .classified(priority: "urgent", confidence: 0.9),
                onFeedbackSubmitted: { _, _ in },
                onRetryRequested: { }
            )
            
            // Failed status
            ClassificationFeedbackView(
                messageId: "test3",
                currentStatus: .failed(error: "Network error"),
                onFeedbackSubmitted: { _, _ in },
                onRetryRequested: { }
            )
            
            // Feedback submitted status
            ClassificationFeedbackView(
                messageId: "test4",
                currentStatus: .feedbackSubmitted,
                onFeedbackSubmitted: { _, _ in },
                onRetryRequested: { }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

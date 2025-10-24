//
//  InfoTooltipView.swift
//  MessageAI
//
//  Reusable info tooltip component with icon and popover
//

import SwiftUI

/// Info icon with expandable tooltip explanation
/// - Note: Displays (ⓘ) icon that shows popover with help text
struct InfoTooltipView: View {
    
    // MARK: - Properties
    
    let message: String
    
    // MARK: - State
    
    @State private var showPopover = false
    
    // MARK: - Body
    
    var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(AppTheme.secondaryColor)
                .font(.body)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover) {
            Text(message)
                .font(AppTheme.bodyFont)
                .padding()
                .frame(maxWidth: 280)
                .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    InfoTooltipView(message: "This is helpful information about this setting")
}


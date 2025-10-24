//
//  UrgentKeywordsInputView.swift
//  MessageAI
//
//  Urgent keywords input section
//

import SwiftUI

/// Tag-style input field for urgent keywords
struct UrgentKeywordsInputView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PreferencesViewModel
    
    // MARK: - State
    
    @State private var keywordInput = ""
    @State private var keywords: [String] = []
    
    // MARK: - Body
    
    var body: some View {
        Section {
            // Keywords display
            keywordsDisplay
            
            // Input field
            HStack {
                TextField("Enter keywords (comma-separated)", text: $keywordInput)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .onSubmit {
                        addKeywords()
                    }
                
                if !keywordInput.isEmpty {
                    Button("Add") {
                        addKeywords()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            // Validation message
            validationMessage
        } header: {
            HStack {
                Text("Urgent Keywords")
                InfoTooltipView(message: "Keywords that indicate urgent messages (min 3, max 50)")
            }
        } footer: {
            Text("\(keywords.count)/50 keywords")
                .font(AppTheme.captionFont)
                .foregroundColor(keywordCountColor)
        }
        .onAppear {
            loadKeywords()
        }
    }
    
    // MARK: - Private Views
    
    /// Keywords display with tags
    private var keywordsDisplay: some View {
        FlowLayout(spacing: 8) {
            ForEach(keywords, id: \.self) { keyword in
                keywordTag(keyword)
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Individual keyword tag
    private func keywordTag(_ keyword: String) -> some View {
        HStack(spacing: 4) {
            Text(keyword)
                .font(.caption)
                .foregroundColor(.white)
            
            Button {
                removeKeyword(keyword)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppTheme.primaryColor)
        .cornerRadius(16)
    }
    
    /// Validation message
    @ViewBuilder
    private var validationMessage: some View {
        if keywords.count < 3 {
            Label("Add at least 3 keywords", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundColor(AppTheme.errorColor)
        }
    }
    
    // MARK: - Computed Properties
    
    private var keywordCountColor: Color {
        if keywords.count < 3 {
            return AppTheme.errorColor
        } else if keywords.count >= 50 {
            return AppTheme.errorColor
        } else {
            return AppTheme.secondaryTextColor
        }
    }
    
    // MARK: - Private Methods
    
    /// Load keywords from preferences
    private func loadKeywords() {
        keywords = viewModel.preferences?.urgentKeywords ?? []
    }
    
    /// Add keywords from input
    private func addKeywords() {
        let newKeywords = keywordInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty && !keywords.contains($0) }
        
        // Check max limit
        guard keywords.count + newKeywords.count <= 50 else {
            return
        }
        
        keywords.append(contentsOf: newKeywords)
        keywordInput = ""
        
        // Update view model
        viewModel.updateUrgentKeywords(keywords)
    }
    
    /// Remove keyword
    private func removeKeyword(_ keyword: String) {
        keywords.removeAll { $0 == keyword }
        viewModel.updateUrgentKeywords(keywords)
    }
}

/// Flow layout for wrapping tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var frames: [CGRect]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var frames: [CGRect] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.frames = frames
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}


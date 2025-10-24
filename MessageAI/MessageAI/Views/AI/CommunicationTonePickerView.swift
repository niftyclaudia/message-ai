//
//  CommunicationTonePickerView.swift
//  MessageAI
//
//  Communication tone picker section
//

import SwiftUI

/// Radio button picker for communication tone selection
struct CommunicationTonePickerView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PreferencesViewModel
    
    // MARK: - State
    
    @State private var selectedTone: CommunicationTone = .friendly
    
    // MARK: - Body
    
    var body: some View {
        Section {
            ForEach(CommunicationTone.allCases, id: \.self) { tone in
                toneOption(tone)
            }
        } header: {
            HStack {
                Text("Communication Tone")
                InfoTooltipView(message: "Choose how AI should respond on your behalf")
            }
        }
        .onAppear {
            loadTone()
        }
    }
    
    // MARK: - Private Views
    
    /// Tone option row
    private func toneOption(_ tone: CommunicationTone) -> some View {
        Button {
            selectedTone = tone
            updateTone()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tone.displayName)
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.primaryTextColor)
                    
                    Text(tone.description)
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.secondaryTextColor)
                }
                
                Spacer()
                
                if selectedTone == tone {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.primaryColor)
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Private Methods
    
    /// Load tone from preferences
    private func loadTone() {
        selectedTone = viewModel.preferences?.communicationTone ?? .friendly
    }
    
    /// Update view model with new tone
    private func updateTone() {
        viewModel.updateCommunicationTone(selectedTone)
    }
}


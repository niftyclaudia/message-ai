//
//  PreferencesSettingsView.swift
//  MessageAI
//
//  Main settings screen for configuring all AI preferences
//

import SwiftUI

/// Main AI preferences configuration screen
/// - Note: Allows users to configure focus hours, urgent contacts, keywords, rules, and tone
struct PreferencesSettingsView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Objects
    
    @StateObject private var viewModel: PreferencesViewModel
    
    // MARK: - State
    
    @State private var showContactSelection = false
    
    // MARK: - Initialization
    
    init(userID: String) {
        _viewModel = StateObject(wrappedValue: PreferencesViewModel(userID: userID))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    LoadingView(message: "Loading preferences...")
                } else {
                    preferencesContent
                }
                
                // Success toast
                if viewModel.showSuccessMessage {
                    successToast
                }
            }
            .navigationTitle("AI Preferences")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
            }
            .task {
                await viewModel.loadPreferences()
                viewModel.startObserving()
            }
            .onDisappear {
                viewModel.stopObserving()
            }
            .sheet(isPresented: $showContactSelection) {
                ContactSelectionSheetView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Private Views
    
    /// Main preferences content with all sections
    private var preferencesContent: some View {
        Form {
            // Privacy Notice
            privacySection
            
            // Focus Hours Section
            FocusHoursConfigView(viewModel: viewModel)
            
            // Urgent Contacts Section
            UrgentContactsListView(
                viewModel: viewModel,
                showContactSelection: $showContactSelection
            )
            
            // Urgent Keywords Section
            UrgentKeywordsInputView(viewModel: viewModel)
            
            // Priority Rules Section
            PriorityRulesConfigView(viewModel: viewModel)
            
            // Communication Tone Section
            CommunicationTonePickerView(viewModel: viewModel)
            
            // Reset to defaults
            resetSection
        }
        .scrollDismissesKeyboard(.interactively)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    /// Privacy notice section
    private var privacySection: some View {
        Section {
            HStack(spacing: AppTheme.mediumSpacing) {
                Image(systemName: "lock.shield")
                    .foregroundColor(AppTheme.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI learns from your corrections")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.primaryTextColor)
                    
                    Text("Data auto-deleted after 90 days")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.secondaryTextColor)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    /// Reset to defaults section
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.resetToDefaults()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset to Defaults")
                }
            }
        }
    }
    
    /// Save button in toolbar
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.savePreferences()
            }
        } label: {
            if viewModel.isSaving {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                Text("Save")
                    .fontWeight(.semibold)
            }
        }
        .disabled(viewModel.isSaving || !viewModel.isValid)
    }
    
    /// Success toast notification
    private var successToast: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                
                Text("Preferences saved")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(.white)
            }
            .padding()
            .background(AppTheme.successColor)
            .cornerRadius(12)
            .shadow(radius: 8)
            .padding(.bottom, 50)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(), value: viewModel.showSuccessMessage)
    }
}

#Preview {
    PreferencesSettingsView(userID: "preview-user-id")
        .environmentObject(AuthService())
}


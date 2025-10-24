//
//  PriorityRulesConfigView.swift
//  MessageAI
//
//  Priority rules configuration section
//

import SwiftUI

/// Toggle switches for priority rules configuration
struct PriorityRulesConfigView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PreferencesViewModel
    
    // MARK: - State
    
    @State private var mentionsWithDeadlines = true
    @State private var fyiMessages = true
    @State private var questionsNeedingResponse = false
    @State private var approvalsAndDecisions = true
    
    // MARK: - Body
    
    var body: some View {
        Section {
            // Mentions with deadlines
            ruleToggle(
                title: PriorityRules.mentionsWithDeadlinesName,
                description: PriorityRules.mentionsWithDeadlinesDescription,
                isOn: $mentionsWithDeadlines
            )
            
            // FYI messages
            ruleToggle(
                title: PriorityRules.fyiMessagesName,
                description: PriorityRules.fyiMessagesDescription,
                isOn: $fyiMessages
            )
            
            // Questions needing response
            ruleToggle(
                title: PriorityRules.questionsNeedingResponseName,
                description: PriorityRules.questionsNeedingResponseDescription,
                isOn: $questionsNeedingResponse
            )
            
            // Approvals and decisions
            ruleToggle(
                title: PriorityRules.approvalsAndDecisionsName,
                description: PriorityRules.approvalsAndDecisionsDescription,
                isOn: $approvalsAndDecisions
            )
        } header: {
            HStack {
                Text("Priority Rules")
                InfoTooltipView(message: "Configure how AI categorizes messages based on content patterns")
            }
        }
        .onAppear {
            loadRules()
        }
    }
    
    // MARK: - Private Views
    
    /// Rule toggle with description
    private func ruleToggle(title: String, description: String, isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: isOn) {
                Text(title)
                    .font(AppTheme.bodyFont)
            }
            .onChange(of: isOn.wrappedValue) { _, _ in
                updateRules()
            }
            
            Text(description)
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.secondaryTextColor)
                .padding(.leading, 0)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Private Methods
    
    /// Load rules from preferences
    private func loadRules() {
        guard let rules = viewModel.preferences?.priorityRules else { return }
        
        mentionsWithDeadlines = rules.mentionsWithDeadlines
        fyiMessages = rules.fyiMessages
        questionsNeedingResponse = rules.questionsNeedingResponse
        approvalsAndDecisions = rules.approvalsAndDecisions
    }
    
    /// Update view model with new rules
    private func updateRules() {
        let rules = PriorityRules(
            mentionsWithDeadlines: mentionsWithDeadlines,
            fyiMessages: fyiMessages,
            questionsNeedingResponse: questionsNeedingResponse,
            approvalsAndDecisions: approvalsAndDecisions
        )
        
        viewModel.updatePriorityRules(rules)
    }
}


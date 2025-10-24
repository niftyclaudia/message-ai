//
//  FocusHoursConfigView.swift
//  MessageAI
//
//  Focus hours configuration section
//

import SwiftUI

/// Focus hours configuration view with time picker and day selection
struct FocusHoursConfigView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PreferencesViewModel
    
    // MARK: - State
    
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var isEnabled = false
    @State private var selectedDays: Set<Int> = []
    
    // MARK: - Constants
    
    private let daysOfWeek = [
        (0, "Sun"),
        (1, "Mon"),
        (2, "Tue"),
        (3, "Wed"),
        (4, "Thu"),
        (5, "Fri"),
        (6, "Sat")
    ]
    
    // MARK: - Body
    
    var body: some View {
        Section {
            // Enable toggle
            Toggle(isOn: $isEnabled) {
                HStack {
                    Text("Focus Hours")
                        .font(AppTheme.bodyFont)
                    
                    InfoTooltipView(message: "Set your deep work hours. AI will respect these times when categorizing message urgency.")
                }
            }
            .onChange(of: isEnabled) { _, newValue in
                updateFocusHours()
            }
            
            if isEnabled {
                // Time pickers
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    .onChange(of: startTime) { _, _ in
                        updateFocusHours()
                    }
                
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    .onChange(of: endTime) { _, _ in
                        updateFocusHours()
                    }
                
                // Day selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Days")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.secondaryTextColor)
                    
                    HStack(spacing: 8) {
                        ForEach(daysOfWeek, id: \.0) { day, label in
                            dayButton(day: day, label: label)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Focus Hours")
        }
        .onAppear {
            loadFocusHours()
        }
    }
    
    // MARK: - Private Views
    
    /// Day selection button
    private func dayButton(day: Int, label: String) -> some View {
        Button {
            if selectedDays.contains(day) {
                selectedDays.remove(day)
            } else {
                selectedDays.insert(day)
            }
            updateFocusHours()
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(selectedDays.contains(day) ? .white : AppTheme.primaryColor)
                .frame(width: 44, height: 36)
                .background(selectedDays.contains(day) ? AppTheme.primaryColor : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.primaryColor, lineWidth: 1)
                )
                .cornerRadius(8)
        }
    }
    
    // MARK: - Private Methods
    
    /// Load focus hours from preferences
    private func loadFocusHours() {
        guard let preferences = viewModel.preferences else { return }
        
        let focusHours = preferences.focusHours
        isEnabled = focusHours.enabled
        selectedDays = Set(focusHours.daysOfWeek)
        
        // Parse time strings to Date
        if let start = parseTime(focusHours.startTime) {
            startTime = start
        }
        if let end = parseTime(focusHours.endTime) {
            endTime = end
        }
    }
    
    /// Update view model with new focus hours
    private func updateFocusHours() {
        let focusHours = FocusHours(
            enabled: isEnabled,
            startTime: formatTime(startTime),
            endTime: formatTime(endTime),
            daysOfWeek: Array(selectedDays).sorted()
        )
        
        viewModel.updateFocusHours(focusHours)
    }
    
    /// Parse time string (HH:mm) to Date
    private func parseTime(_ timeString: String) -> Date? {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        
        var dateComponents = DateComponents()
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]
        
        return Calendar.current.date(from: dateComponents)
    }
    
    /// Format Date to time string (HH:mm)
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}


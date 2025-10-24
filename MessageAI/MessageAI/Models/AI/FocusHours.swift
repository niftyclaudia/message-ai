//
//  FocusHours.swift
//  MessageAI
//
//  Focus hours configuration for AI message prioritization
//

import Foundation

/// Focus hours configuration defining user's deep work time
/// - Note: AI will respect these hours when categorizing message urgency
struct FocusHours: Codable, Equatable {
    /// Whether focus hours are enabled
    var enabled: Bool
    
    /// Start time in 24-hour format (e.g., "10:00")
    var startTime: String
    
    /// End time in 24-hour format (e.g., "14:00")
    var endTime: String
    
    /// Days of week when focus hours apply (0 = Sunday, 1 = Monday, etc.)
    var daysOfWeek: [Int]
    
    // MARK: - Validation
    
    /// Validates that start time is before end time
    var isValid: Bool {
        guard let start = timeToMinutes(startTime),
              let end = timeToMinutes(endTime) else {
            return false
        }
        return start < end && daysOfWeek.allSatisfy { $0 >= 0 && $0 <= 6 }
    }
    
    /// Checks if current time falls within focus hours
    func isInFocusHours() -> Bool {
        guard enabled && isValid else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now) - 1 // Convert to 0-6 range
        
        // Check if today is a focus day
        guard daysOfWeek.contains(weekday) else { return false }
        
        // Get current time in minutes
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        
        guard let startMinutes = timeToMinutes(startTime),
              let endMinutes = timeToMinutes(endTime) else {
            return false
        }
        
        return currentMinutes >= startMinutes && currentMinutes < endMinutes
    }
    
    // MARK: - Helper Methods
    
    /// Converts time string (HH:mm) to minutes since midnight
    private func timeToMinutes(_ time: String) -> Int? {
        let components = time.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        return components[0] * 60 + components[1]
    }
    
    /// Default focus hours (10 AM - 2 PM, Monday-Friday, disabled)
    static var defaultFocusHours: FocusHours {
        FocusHours(
            enabled: false,
            startTime: "10:00",
            endTime: "14:00",
            daysOfWeek: [1, 2, 3, 4, 5] // Mon-Fri
        )
    }
}


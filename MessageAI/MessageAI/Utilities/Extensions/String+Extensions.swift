//
//  String+Extensions.swift
//  MessageAI
//
//  String utility extensions
//

import Foundation

extension String {
    
    /// Extracts initials from a name string
    /// - Returns: Initials string (e.g., "John Doe" → "JD", "Alice" → "A")
    /// - Note: Returns up to 2 characters, handles empty strings gracefully
    func extractInitials() -> String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return "?"
        }
        
        let words = trimmed.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        if words.count >= 2 {
            // Two or more words: Take first letter of first two words
            let first = words[0].prefix(1).uppercased()
            let second = words[1].prefix(1).uppercased()
            return first + second
        } else if let firstWord = words.first {
            // Single word: Take first letter
            return String(firstWord.prefix(1).uppercased())
        }
        
        return "?"
    }
}


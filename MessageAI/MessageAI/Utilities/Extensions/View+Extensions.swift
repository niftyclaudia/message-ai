//
//  View+Extensions.swift
//  MessageAI
//
//  SwiftUI View extensions for common functionality
//

import SwiftUI

extension View {
    /// Dismisses keyboard when tapping outside text fields
    /// Usage: Apply to any view to enable tap-to-dismiss
    func hideKeyboard() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    /// Presents an error alert with user-friendly message
    /// - Parameters:
    ///   - isPresented: Binding to control alert visibility
    ///   - error: Binding to error to display (automatically converts to user-friendly message)
    func errorAlert(isPresented: Binding<Bool>, error: Binding<String?>) -> some View {
        self.alert("Error", isPresented: isPresented) {
            Button("OK", role: .cancel) {
                error.wrappedValue = nil
            }
        } message: {
            if let errorMessage = error.wrappedValue {
                Text(errorMessage)
            }
        }
    }
}


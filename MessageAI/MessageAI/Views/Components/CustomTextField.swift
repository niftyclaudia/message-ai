//
//  CustomTextField.swift
//  MessageAI
//
//  Reusable styled text field with secure entry support
//

import SwiftUI

/// Styled text field with consistent design and secure entry option
/// - Note: Follows AppTheme design system
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    
    init(placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding()
        .frame(height: AppTheme.textFieldHeight)
        .background(AppTheme.secondaryBackgroundColor)
        .cornerRadius(AppTheme.mediumRadius)
        .autocapitalization(isSecure ? .none : .none)
        .textInputAutocapitalization(.never)
    }
}

#Preview {
    VStack(spacing: AppTheme.mediumSpacing) {
        CustomTextField(placeholder: "Email", text: .constant(""))
        CustomTextField(placeholder: "Password", text: .constant(""), isSecure: true)
    }
    .padding()
}


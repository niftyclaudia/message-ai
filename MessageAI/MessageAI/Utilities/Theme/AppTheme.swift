//
//  AppTheme.swift
//  MessageAI
//
//  Centralized theme configuration for consistent design system
//

import SwiftUI

/// Centralized theme configuration for consistent UI across the app
/// - Note: Use these constants instead of hardcoding colors, fonts, and spacing
struct AppTheme {
    
    // MARK: - Colors
    
    /// Primary brand color for buttons, accents
    static let primaryColor = Color.blue
    
    /// Secondary color for less prominent UI elements
    static let secondaryColor = Color.gray
    
    /// Accent color for highlights and interactive elements
    static let accentColor = Color.green
    
    /// Background color adapts to light/dark mode
    static let backgroundColor = Color(.systemBackground)
    
    /// Secondary background for cards and sections
    static let secondaryBackgroundColor = Color(.secondarySystemBackground)
    
    /// Error and destructive actions
    static let errorColor = Color.red
    
    /// Success states
    static let successColor = Color.green
    
    /// Text colors
    static let primaryTextColor = Color.primary
    static let secondaryTextColor = Color.secondary
    
    // MARK: - Typography
    
    /// Large titles for main headings
    static let titleFont = Font.largeTitle.weight(.bold)
    
    /// Section headings and prominent labels
    static let headlineFont = Font.headline
    
    /// Body text for most content
    static let bodyFont = Font.body
    
    /// Small labels and secondary information
    static let captionFont = Font.caption
    
    /// Subheadings
    static let subheadlineFont = Font.subheadline
    
    // MARK: - Spacing
    
    /// Small spacing (8pt)
    static let smallSpacing: CGFloat = 8
    
    /// Medium spacing (16pt)
    static let mediumSpacing: CGFloat = 16
    
    /// Large spacing (24pt)
    static let largeSpacing: CGFloat = 24
    
    /// Extra large spacing (32pt)
    static let extraLargeSpacing: CGFloat = 32
    
    // MARK: - Corner Radius
    
    /// Small corner radius for subtle rounding
    static let smallRadius: CGFloat = 8
    
    /// Medium corner radius for buttons and cards
    static let mediumRadius: CGFloat = 12
    
    /// Large corner radius for prominent UI elements
    static let largeRadius: CGFloat = 16
    
    // MARK: - Dimensions
    
    /// Standard button height
    static let buttonHeight: CGFloat = 50
    
    /// Standard text field height
    static let textFieldHeight: CGFloat = 50
    
    /// Standard icon size
    static let iconSize: CGFloat = 24
    
    // MARK: - Animation
    
    /// Standard animation duration
    static let animationDuration: Double = 0.3
    
    /// Spring animation for interactive elements
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
}


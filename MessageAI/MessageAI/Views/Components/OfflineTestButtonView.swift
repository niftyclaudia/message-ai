//
//  OfflineTestButtonView.swift
//  MessageAI
//
//  Offline testing component for simulator
//

import SwiftUI

/// View that provides offline testing controls (simulator only)
/// - Note: Only visible in debug builds and simulator
struct OfflineTestButtonView: View {
    
    // MARK: - Properties
    
    let isOffline: Bool
    let onToggleOffline: () -> Void
    let onSimulateNetworkFailure: () -> Void
    let onSimulateSlowNetwork: () -> Void
    let onClearCache: () -> Void
    
    #if DEBUG
    @State private var showingTestMenu = false
    #endif
    
    // MARK: - Body
    
    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
            VStack {
                Button(action: { showingTestMenu.toggle() }) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("Offline Test")
                            .font(.system(size: 12, weight: .medium))
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(6)
                }
                
                if showingTestMenu {
                    VStack(spacing: 8) {
                        Button("Toggle Offline") {
                            onToggleOffline()
                            showingTestMenu = false
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                        
                        Button("Simulate Network Failure") {
                            onSimulateNetworkFailure()
                            showingTestMenu = false
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        
                        Button("Simulate Slow Network") {
                            onSimulateSlowNetwork()
                            showingTestMenu = false
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                        
                        Button("Clear Cache") {
                            onClearCache()
                            showingTestMenu = false
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        #endif
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        OfflineTestButtonView(
            isOffline: false,
            onToggleOffline: {},
            onSimulateNetworkFailure: {},
            onSimulateSlowNetwork: {},
            onClearCache: {}
        )
        
        OfflineTestButtonView(
            isOffline: true,
            onToggleOffline: {},
            onSimulateNetworkFailure: {},
            onSimulateSlowNetwork: {},
            onClearCache: {}
        )
    }
    .padding()
}

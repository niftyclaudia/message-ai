//
//  MockTestingView.swift
//  MessageAI
//
//  Mock testing component for simulating real-time messaging scenarios
//

import SwiftUI

/// Mock testing component for simulating real-time messaging scenarios
/// - Note: Only available in debug builds for testing purposes
struct MockTestingView: View {
    
    // MARK: - Properties
    
    @Binding var isPresented: Bool
    @StateObject private var mockDataService = MockDataService()
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                
                // Header
                headerSection
                
            // Connection Status
            connectionStatusSection
            
            // Mock Controls
            mockControlsSection
            
            // Preset Scenarios
            presetScenariosSection
            
            // Message Status
            messageStatusSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("🧪 Mock Testing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Real-Time Messaging Mock Tests")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Simulate different messaging scenarios to test UI and behavior")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Connection Status Section
    
    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connection Status")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Circle()
                    .fill(mockDataService.mockConnectionStatus == .connected ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(mockDataService.mockConnectionStatus.rawValue)
                    .foregroundColor(mockDataService.mockConnectionStatus == .connected ? .green : .red)
                
                Spacer()
                
                Button(mockDataService.mockConnectionStatus == .connected ? "Go Offline" : "Go Online") {
                    toggleConnectionStatus()
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Mock Controls Section
    
    private var mockControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mock Scenarios")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Message Sending
            VStack(spacing: 8) {
                HStack {
                    Button("📤 Send Message") {
                        mockDataService.simulateMessageSending(text: "Test message")
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    
                    Button("📥 Receive Message") {
                        mockDataService.simulateRealTimeMessage()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                
                HStack {
                    Button("🔄 Real-time Update") {
                        mockDataService.simulateRealTimeMessage()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    
                    Button("❌ Send Failure") {
                        mockDataService.simulateSendFailure()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
            
            // Network Scenarios
            VStack(spacing: 8) {
                HStack {
                    Button("📱 Offline Mode") {
                        mockDataService.simulateOfflineMode()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    
                    Button("🔄 Reconnect") {
                        mockDataService.simulateReconnection()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                
                HStack {
                    Button("⚡ Fast Messages") {
                        mockDataService.simulateRapidMessaging()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    
                    Button("🧹 Clear All") {
                        mockDataService.clearAllMockData()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Preset Scenarios Section
    
    private var presetScenariosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preset Scenarios")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Button("💬 Load Conversation") {
                    mockDataService.loadPresetConversation()
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Button("❌ Error Scenarios") {
                    mockDataService.loadErrorScenarios()
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
            
            HStack {
                Button("🔄 Auto Messages") {
                    mockDataService.startAutoMessaging()
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Button("⏹️ Stop Auto") {
                    mockDataService.stopAutoMessaging()
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Message Status Section
    
    private var messageStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mock Messages (\(mockDataService.mockMessages.count))")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if mockDataService.mockMessages.isEmpty {
                Text("No mock messages yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(mockDataService.mockMessages.suffix(10)) { message in
                            mockMessageRow(message)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Mock Message Row
    
    private func mockMessageRow(_ message: Message) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(message.text)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(message.senderID == mockDataService.mockUserID ? "You" : "Other") • \(message.timestamp.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            statusIndicator(message.status)
        }
        .padding(.vertical, 2)
    }
    
    private func statusIndicator(_ status: MessageStatus) -> some View {
        HStack(spacing: 4) {
            switch status {
            case .sending:
                ProgressView()
                    .scaleEffect(0.5)
            case .sent:
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(.blue)
            case .delivered:
                Image(systemName: "checkmark.circle")
                    .font(.caption2)
                    .foregroundColor(.green)
            case .read:
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundColor(.red)
            case .queued:
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Mock Testing Functions
    
    private func toggleConnectionStatus() {
        if mockDataService.mockConnectionStatus == .connected {
            mockDataService.simulateOfflineMode()
        } else {
            mockDataService.simulateReconnection()
        }
    }
}

// MARK: - Preview

#Preview {
    MockTestingView(isPresented: .constant(true))
}

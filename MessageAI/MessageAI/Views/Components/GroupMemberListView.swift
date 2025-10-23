//
//  GroupMemberListView.swift
//  MessageAI
//
//  PR-3: Group member list with live presence indicators
//  Modal/sheet showing all group chat participants with online status
//

import SwiftUI
import FirebaseDatabase

/// Modal view showing all members of a group chat with live presence
/// - Note: Updates presence in real-time using PresenceService
/// - Performance: Target < 400ms load time, < 500ms presence propagation
struct GroupMemberListView: View {
    
    // MARK: - Properties
    
    let chat: Chat
    @Environment(\.dismiss) private var dismiss
    
    @State private var members: [User] = []
    @State private var presenceMap: [String: PresenceStatus] = [:]
    @State private var isLoading = true
    @State private var error: String?
    
    private let userService = UserService()
    private let presenceService = PresenceService()
    
    // Presence observer handles for cleanup
    @State private var presenceHandles: [String: DatabaseHandle] = [:]
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(message: error)
                } else if members.isEmpty {
                    emptyView
                } else {
                    memberListView
                }
            }
            .navigationTitle("Group Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadMembers()
        }
        .onDisappear {
            cleanupPresenceObservers()
        }
    }
    
    // MARK: - Private Views
    
    /// Loading state view
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading members...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    /// Error state view
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Error Loading Members")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                Task {
                    await loadMembers()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    /// Empty state view
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No Members Found")
                .font(.headline)
            
            Text("This group appears to be empty")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    /// Member list view with presence indicators
    private var memberListView: some View {
        List {
            Section {
                ForEach(members) { member in
                    MemberStatusRow(
                        user: member,
                        presenceStatus: presenceMap[member.id] ?? .offline
                    )
                }
            } header: {
                Text("\(members.count) member\(members.count == 1 ? "" : "s")")
                    .textCase(.none)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Private Methods
    
    /// Loads group members and sets up presence observation
    /// - Performance: Target < 400ms for fetching all members
    private func loadMembers() async {
        isLoading = true
        error = nil
        
        do {
            // Fetch all member profiles
            let memberProfiles = try await userService.fetchMultipleUserProfiles(userIDs: chat.members)
            
            await MainActor.run {
                // Convert dictionary to sorted array
                members = chat.members.compactMap { memberProfiles[$0] }
                    .sorted { $0.displayName < $1.displayName }
                
                isLoading = false
                
                // Set up presence observation for all members
                observeMemberPresence()
            }
        } catch {
            // Show error to user since this affects core functionality
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    /// Sets up real-time presence observers for all members
    /// - Note: Uses PresenceService to track online/offline status
    /// - Performance: Updates propagate in < 500ms
    private func observeMemberPresence() {
        // Observe presence for each member
        let handles = presenceService.observeMultipleUsersPresence(userIDs: chat.members) { [self] updatedPresence in
            // Update presence map on main thread
            Task { @MainActor in
                self.presenceMap = updatedPresence
            }
        }
        
        presenceHandles = handles
    }
    
    /// Cleans up presence observers when view disappears
    private func cleanupPresenceObservers() {
        presenceService.removeObservers(handles: presenceHandles)
        presenceHandles.removeAll()
    }
}

// MARK: - Preview

#Preview("Group Member List") {
    GroupMemberListView(
        chat: Chat(
            id: "chat1",
            members: ["user1", "user2", "user3"],
            lastMessage: "Hello",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: "user1",
            isGroupChat: true,
            groupName: "Team Chat",
            createdAt: Date(),
            createdBy: "user1"
        )
    )
}

#Preview("Loading State") {
    struct LoadingWrapper: View {
        var body: some View {
            GroupMemberListView(
                chat: Chat(
                    id: "chat1",
                    members: [],
                    lastMessage: "",
                    lastMessageTimestamp: Date(),
                    lastMessageSenderID: "",
                    isGroupChat: true,
                    groupName: "Test Group",
                    createdAt: Date(),
                    createdBy: "user1"
                )
            )
        }
    }
    
    return LoadingWrapper()
}


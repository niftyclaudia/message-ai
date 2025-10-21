//
//  ChatServiceGroupTests.swift
//  MessageAITests
//
//  Service tests for group chat functionality in ChatService
//

import Testing
import Foundation
@testable import MessageAI

/// Service tests for group chat functionality in ChatService
/// - Note: Tests group chat creation, member management, and group chat operations
struct ChatServiceGroupTests {
    
    // MARK: - Test Data
    
    private let testUserID = "test-user-1"
    private let testGroupMembers = ["user1", "user2", "user3", "user4", "user5"]
    private let testGroupName = "Test Group Chat"
    
    // MARK: - Group Chat Creation Tests
    
    @Test("Create Group Chat with Multiple Members Succeeds")
    func createGroupChatWithMultipleMembersSucceeds() async throws {
        // Given: A group of 5 members
        let chatService = ChatService()
        
        // When: Creating a group chat
        let chatID = try await chatService.createChat(
            members: testGroupMembers,
            isGroup: true,
            createdBy: testUserID
        )
        
        // Then: Chat should be created successfully
        #expect(!chatID.isEmpty)
        
        // Verify chat properties
        let chat = try await chatService.fetchChat(chatID: chatID)
        #expect(chat.isGroupChat == true)
        #expect(chat.members.count == testGroupMembers.count)
        #expect(chat.members.contains(testUserID))
    }
    
    @Test("Group Chat Creation Performance Under 2 Seconds")
    func groupChatCreationPerformanceUnder2Seconds() async throws {
        // Given: A group of 5 members
        let chatService = ChatService()
        
        // When: Creating a group chat and measuring time
        let startTime = Date()
        let chatID = try await chatService.createChat(
            members: testGroupMembers,
            isGroup: true,
            createdBy: testUserID
        )
        let endTime = Date()
        
        // Then: Creation should complete under 2 seconds
        let creationTime = endTime.timeIntervalSince(startTime)
        #expect(creationTime < 2.0, "Group chat creation took \(creationTime)s, expected < 2s")
        
        // Verify chat was created
        #expect(!chatID.isEmpty)
    }
    
    @Test("Group Chat with 10 Members Handles Correctly")
    func groupChatWith10MembersHandlesCorrectly() async throws {
        // Given: A large group of 10 members
        let largeGroupMembers = (1...10).map { "user\($0)" }
        let chatService = ChatService()
        
        // When: Creating a group chat with 10 members
        let chatID = try await chatService.createChat(
            members: largeGroupMembers,
            isGroup: true,
            createdBy: testUserID
        )
        
        // Then: Chat should be created successfully
        #expect(!chatID.isEmpty)
        
        let chat = try await chatService.fetchChat(chatID: chatID)
        #expect(chat.members.count == 10)
        #expect(chat.isGroupChat == true)
    }
    
    @Test("Group Chat Creation Validates Members")
    func groupChatCreationValidatesMembers() async throws {
        // Given: Invalid member data
        let chatService = ChatService()
        
        // When: Trying to create chat with invalid members
        do {
            _ = try await chatService.createChat(
                members: [], // Empty members array
                isGroup: true,
                createdBy: testUserID
            )
            #expect(false, "Should have thrown error for empty members")
        } catch {
            // Then: Should throw validation error
            #expect(error is ChatServiceError)
        }
    }
    
    @Test("Group Chat Creation Includes Creator in Members")
    func groupChatCreationIncludesCreatorInMembers() async throws {
        // Given: A group chat creation request
        let chatService = ChatService()
        let membersWithoutCreator = ["user1", "user2", "user3"]
        
        // When: Creating group chat without creator in members
        do {
            _ = try await chatService.createChat(
                members: membersWithoutCreator,
                isGroup: true,
                createdBy: testUserID
            )
            #expect(false, "Should have thrown error for missing creator")
        } catch {
            // Then: Should throw validation error
            #expect(error is ChatServiceError)
        }
    }
    
    // MARK: - Group Chat Member Management Tests
    
    @Test("Group Chat Members Are Stored Correctly")
    func groupChatMembersAreStoredCorrectly() async throws {
        // Given: A group chat
        let chatService = ChatService()
        let chatID = try await chatService.createChat(
            members: testGroupMembers,
            isGroup: true,
            createdBy: testUserID
        )
        
        // When: Fetching the chat
        let chat = try await chatService.fetchChat(chatID: chatID)
        
        // Then: All members should be stored correctly
        #expect(chat.members.count == testGroupMembers.count)
        
        for member in testGroupMembers {
            #expect(chat.members.contains(member))
        }
    }
    
    @Test("Group Chat Member Order Is Preserved")
    func groupChatMemberOrderIsPreserved() async throws {
        // Given: A group chat with specific member order
        let chatService = ChatService()
        let orderedMembers = ["user1", "user2", "user3", "user4", "user5"]
        
        // When: Creating group chat
        let chatID = try await chatService.createChat(
            members: orderedMembers,
            isGroup: true,
            createdBy: testUserID
        )
        
        // Then: Member order should be preserved
        let chat = try await chatService.fetchChat(chatID: chatID)
        #expect(chat.members == orderedMembers)
    }
    
    // MARK: - Group Chat Query Tests
    
    @Test("Fetch User Chats Includes Group Chats")
    func fetchUserChatsIncludesGroupChats() async throws {
        // Given: A user with group chats
        let chatService = ChatService()
        
        // Create a group chat
        let groupChatID = try await chatService.createChat(
            members: testGroupMembers,
            isGroup: true,
            createdBy: testUserID
        )
        
        // When: Fetching user's chats
        let userChats = try await chatService.fetchUserChats(userID: testUserID)
        
        // Then: Group chat should be included
        let groupChat = userChats.first { $0.id == groupChatID }
        #expect(groupChat != nil)
        #expect(groupChat?.isGroupChat == true)
    }
    
    @Test("Group Chat Real-Time Updates Work")
    func groupChatRealTimeUpdatesWork() async throws {
        // Given: A group chat
        let chatService = ChatService()
        let chatID = try await chatService.createChat(
            members: testGroupMembers,
            isGroup: true,
            createdBy: testUserID
        )
        
        // When: Setting up real-time listener
        var receivedChats: [Chat] = []
        let listener = chatService.observeUserChats(userID: testUserID) { chats in
            receivedChats = chats
        }
        
        // Wait for initial data
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Group chat should be received via real-time listener
        #expect(receivedChats.contains { $0.id == chatID })
        
        // Cleanup
        listener.remove()
    }
    
    // MARK: - Group Chat Edge Cases
    
    @Test("Duplicate Group Chat Creation Handles Correctly")
    func duplicateGroupChatCreationHandlesCorrectly() async throws {
        // Given: An existing group chat
        let chatService = ChatService()
        let existingChatID = try await chatService.createChat(
            members: testGroupMembers,
            isGroup: true,
            createdBy: testUserID
        )
        
        // When: Trying to create another chat with same members
        let duplicateChatID = try await chatService.createChat(
            members: testGroupMembers,
            isGroup: true,
            createdBy: testUserID
        )
        
        // Then: Should return existing chat ID
        #expect(duplicateChatID == existingChatID)
    }
    
    @Test("Group Chat with Minimum Members Works")
    func groupChatWithMinimumMembersWorks() async throws {
        // Given: A group chat with minimum 2 members
        let chatService = ChatService()
        let minMembers = ["user1", "user2"]
        
        // When: Creating group chat with 2 members
        let chatID = try await chatService.createChat(
            members: minMembers,
            isGroup: true,
            createdBy: testUserID
        )
        
        // Then: Chat should be created successfully
        #expect(!chatID.isEmpty)
        
        let chat = try await chatService.fetchChat(chatID: chatID)
        #expect(chat.members.count == 2)
        #expect(chat.isGroupChat == true)
    }
    
    @Test("Group Chat Creation with Same Members Different Order")
    func groupChatCreationWithSameMembersDifferentOrder() async throws {
        // Given: Two groups with same members in different order
        let chatService = ChatService()
        let members1 = ["user1", "user2", "user3"]
        let members2 = ["user3", "user1", "user2"] // Same members, different order
        
        // When: Creating two group chats
        let chatID1 = try await chatService.createChat(
            members: members1,
            isGroup: true,
            createdBy: testUserID
        )
        
        let chatID2 = try await chatService.createChat(
            members: members2,
            isGroup: true,
            createdBy: testUserID
        )
        
        // Then: Should return same chat ID (existing chat)
        #expect(chatID1 == chatID2)
    }
    
    // MARK: - Group Chat Performance Tests
    
    @Test("Group Chat Creation with Large Member List")
    func groupChatCreationWithLargeMemberList() async throws {
        // Given: A very large group (20 members)
        let largeGroupMembers = (1...20).map { "user\($0)" }
        let chatService = ChatService()
        
        // When: Creating group chat with 20 members
        let startTime = Date()
        let chatID = try await chatService.createChat(
            members: largeGroupMembers,
            isGroup: true,
            createdBy: testUserID
        )
        let endTime = Date()
        
        // Then: Should complete in reasonable time
        let creationTime = endTime.timeIntervalSince(startTime)
        #expect(creationTime < 3.0, "Large group creation took \(creationTime)s, expected < 3s")
        
        // Verify chat was created
        #expect(!chatID.isEmpty)
        
        let chat = try await chatService.fetchChat(chatID: chatID)
        #expect(chat.members.count == 20)
    }
    
    @Test("Group Chat Query Performance with Many Chats")
    func groupChatQueryPerformanceWithManyChats() async throws {
        // Given: A user with many group chats
        let chatService = ChatService()
        
        // Create multiple group chats
        var chatIDs: [String] = []
        for i in 1...10 {
            let members = ["user1", "user2", "user3", "user\(i)"]
            let chatID = try await chatService.createChat(
                members: members,
                isGroup: true,
                createdBy: testUserID
            )
            chatIDs.append(chatID)
        }
        
        // When: Fetching all user chats
        let startTime = Date()
        let userChats = try await chatService.fetchUserChats(userID: testUserID)
        let endTime = Date()
        
        // Then: Should complete quickly
        let queryTime = endTime.timeIntervalSince(startTime)
        #expect(queryTime < 2.0, "Query took \(queryTime)s, expected < 2s")
        
        // Verify all group chats are returned
        #expect(userChats.count >= 10)
        let groupChats = userChats.filter { $0.isGroupChat }
        #expect(groupChats.count >= 10)
    }
}

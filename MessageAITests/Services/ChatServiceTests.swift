//
//  ChatServiceTests.swift
//  MessageAITests
//
//  Unit tests for ChatService
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for ChatService
/// - Note: Tests chat creation, contact fetching, and search functionality
struct ChatServiceTests {
    
    // MARK: - Test Data
    
    private let mockUser1 = User(
        id: "user1",
        displayName: "John Doe",
        email: "john@example.com",
        profilePhotoURL: nil,
        createdAt: Date(),
        lastActiveAt: Date()
    )
    
    private let mockUser2 = User(
        id: "user2",
        displayName: "Jane Smith",
        email: "jane@example.com",
        profilePhotoURL: nil,
        createdAt: Date(),
        lastActiveAt: Date()
    )
    
    private let mockUser3 = User(
        id: "user3",
        displayName: "Bob Johnson",
        email: "bob@example.com",
        profilePhotoURL: nil,
        createdAt: Date(),
        lastActiveAt: Date()
    )
    
    // MARK: - Chat Creation Tests
    
    @Test("Create Chat Successfully")
    func createChatSuccessfully() async throws {
        // Given: Mock chat service
        let mockService = MockChatService()
        let members = ["user1", "user2"]
        let createdBy = "user1"
        
        // When: Create chat
        let chatID = try await mockService.createChat(members: members, isGroup: false, createdBy: createdBy)
        
        // Then: Chat should be created
        #expect(!chatID.isEmpty)
        #expect(mockService.createChatCalled)
        #expect(mockService.lastCreateChatMembers == members)
        #expect(mockService.lastCreateChatIsGroup == false)
        #expect(mockService.lastCreateChatCreatedBy == createdBy)
    }
    
    @Test("Create Group Chat Successfully")
    func createGroupChatSuccessfully() async throws {
        // Given: Mock chat service
        let mockService = MockChatService()
        let members = ["user1", "user2", "user3"]
        let createdBy = "user1"
        
        // When: Create group chat
        let chatID = try await mockService.createChat(members: members, isGroup: true, createdBy: createdBy)
        
        // Then: Group chat should be created
        #expect(!chatID.isEmpty)
        #expect(mockService.createChatCalled)
        #expect(mockService.lastCreateChatMembers == members)
        #expect(mockService.lastCreateChatIsGroup == true)
        #expect(mockService.lastCreateChatCreatedBy == createdBy)
    }
    
    @Test("Create Chat With Invalid Members")
    func createChatWithInvalidMembers() async throws {
        // Given: Mock chat service
        let mockService = MockChatService()
        let members = ["user1"] // Only one member
        let createdBy = "user1"
        
        // When: Create chat with invalid members
        // Then: Should throw error
        await #expect(throws: ChatServiceError.self) {
            try await mockService.createChat(members: members, isGroup: false, createdBy: createdBy)
        }
    }
    
    @Test("Create Chat Without Creator In Members")
    func createChatWithoutCreatorInMembers() async throws {
        // Given: Mock chat service
        let mockService = MockChatService()
        let members = ["user1", "user2"] // Creator not included
        let createdBy = "user3"
        
        // When: Create chat without creator in members
        // Then: Should throw error
        await #expect(throws: ChatServiceError.self) {
            try await mockService.createChat(members: members, isGroup: false, createdBy: createdBy)
        }
    }
    
    @Test("Create Chat With Service Error")
    func createChatWithServiceError() async throws {
        // Given: Mock chat service that throws error
        let mockService = MockChatService()
        mockService.shouldThrowError = true
        let members = ["user1", "user2"]
        let createdBy = "user1"
        
        // When: Create chat
        // Then: Should throw error
        await #expect(throws: ChatServiceError.self) {
            try await mockService.createChat(members: members, isGroup: false, createdBy: createdBy)
        }
    }
    
    // MARK: - Check Existing Chat Tests
    
    @Test("Check Existing Chat Returns Chat ID")
    func checkExistingChatReturnsChatID() async throws {
        // Given: Mock chat service with existing chat
        let mockService = MockChatService()
        mockService.mockExistingChatID = "existing-chat-id"
        let members = ["user1", "user2"]
        
        // When: Check for existing chat
        let existingChatID = try await mockService.checkForExistingChat(members: members)
        
        // Then: Should return existing chat ID
        #expect(existingChatID == "existing-chat-id")
        #expect(mockService.checkForExistingChatCalled)
        #expect(mockService.lastCheckForExistingChatMembers == members)
    }
    
    @Test("Check Existing Chat Returns Nil")
    func checkExistingChatReturnsNil() async throws {
        // Given: Mock chat service with no existing chat
        let mockService = MockChatService()
        mockService.mockExistingChatID = nil
        let members = ["user1", "user2"]
        
        // When: Check for existing chat
        let existingChatID = try await mockService.checkForExistingChat(members: members)
        
        // Then: Should return nil
        #expect(existingChatID == nil)
        #expect(mockService.checkForExistingChatCalled)
        #expect(mockService.lastCheckForExistingChatMembers == members)
    }
    
    // MARK: - Fetch Contacts Tests
    
    @Test("Fetch Contacts Successfully")
    func fetchContactsSuccessfully() async throws {
        // Given: Mock chat service with contacts
        let mockService = MockChatService()
        mockService.mockContacts = [mockUser1, mockUser2, mockUser3]
        let currentUserID = "currentUser"
        
        // When: Fetch contacts
        let contacts = try await mockService.fetchContacts(currentUserID: currentUserID)
        
        // Then: Should return contacts
        #expect(contacts.count == 3)
        #expect(mockService.fetchContactsCalled)
        #expect(mockService.lastFetchContactsUserID == currentUserID)
    }
    
    @Test("Fetch Contacts With Error")
    func fetchContactsWithError() async throws {
        // Given: Mock chat service that throws error
        let mockService = MockChatService()
        mockService.shouldThrowError = true
        let currentUserID = "currentUser"
        
        // When: Fetch contacts
        // Then: Should throw error
        await #expect(throws: ChatServiceError.self) {
            try await mockService.fetchContacts(currentUserID: currentUserID)
        }
    }
    
    // MARK: - Search Contacts Tests
    
    @Test("Search Contacts Successfully")
    func searchContactsSuccessfully() async throws {
        // Given: Mock chat service with search results
        let mockService = MockChatService()
        mockService.mockSearchResults = [mockUser1] // Only John Doe matches
        let currentUserID = "currentUser"
        let query = "John"
        
        // When: Search contacts
        let results = try await mockService.searchContacts(query: query, currentUserID: currentUserID)
        
        // Then: Should return search results
        #expect(results.count == 1)
        #expect(results.first?.id == "user1")
        #expect(mockService.searchContactsCalled)
        #expect(mockService.lastSearchContactsQuery == query)
        #expect(mockService.lastSearchContactsUserID == currentUserID)
    }
    
    @Test("Search Contacts With Empty Query")
    func searchContactsWithEmptyQuery() async throws {
        // Given: Mock chat service
        let mockService = MockChatService()
        let currentUserID = "currentUser"
        let query = ""
        
        // When: Search with empty query
        // Then: Should throw error
        await #expect(throws: ChatServiceError.self) {
            try await mockService.searchContacts(query: query, currentUserID: currentUserID)
        }
    }
    
    @Test("Search Contacts With Error")
    func searchContactsWithError() async throws {
        // Given: Mock chat service that throws error
        let mockService = MockChatService()
        mockService.shouldThrowError = true
        let currentUserID = "currentUser"
        let query = "John"
        
        // When: Search contacts
        // Then: Should throw error
        await #expect(throws: ChatServiceError.self) {
            try await mockService.searchContacts(query: query, currentUserID: currentUserID)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Create Chat Performance")
    func createChatPerformance() async throws {
        // Given: Mock chat service
        let mockService = MockChatService()
        let members = ["user1", "user2"]
        let createdBy = "user1"
        
        // When: Create chat and measure time
        let startTime = Date()
        let chatID = try await mockService.createChat(members: members, isGroup: false, createdBy: createdBy)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then: Should complete within 2 seconds
        #expect(duration < 2.0)
        #expect(!chatID.isEmpty)
    }
    
    @Test("Fetch Contacts Performance")
    func fetchContactsPerformance() async throws {
        // Given: Mock chat service with many contacts
        let mockService = MockChatService()
        mockService.mockContacts = Array(0..<100).map { i in
            User(
                id: "user\(i)",
                displayName: "User \(i)",
                email: "user\(i)@example.com",
                profilePhotoURL: nil,
                createdAt: Date(),
                lastActiveAt: Date()
            )
        }
        let currentUserID = "currentUser"
        
        // When: Fetch contacts and measure time
        let startTime = Date()
        let contacts = try await mockService.fetchContacts(currentUserID: currentUserID)
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then: Should complete within 2 seconds
        #expect(duration < 2.0)
        #expect(contacts.count == 100)
    }
}

// MARK: - Mock ChatService

/// Mock ChatService for testing
class MockChatService: ChatService {
    var createChatCalled = false
    var lastCreateChatMembers: [String] = []
    var lastCreateChatIsGroup = false
    var lastCreateChatCreatedBy = ""
    
    var checkForExistingChatCalled = false
    var lastCheckForExistingChatMembers: [String] = []
    var mockExistingChatID: String?
    
    var fetchContactsCalled = false
    var lastFetchContactsUserID: String = ""
    var mockContacts: [User] = []
    
    var searchContactsCalled = false
    var lastSearchContactsQuery: String = ""
    var lastSearchContactsUserID: String = ""
    var mockSearchResults: [User] = []
    
    var shouldThrowError = false
    
    override func createChat(members: [String], isGroup: Bool, createdBy: String) async throws -> String {
        createChatCalled = true
        lastCreateChatMembers = members
        lastCreateChatIsGroup = isGroup
        lastCreateChatCreatedBy = createdBy
        
        if shouldThrowError {
            throw ChatServiceError.networkError(NSError(domain: "Test", code: -1, userInfo: nil))
        }
        
        return "mock-chat-id"
    }
    
    override func checkForExistingChat(members: [String]) async throws -> String? {
        checkForExistingChatCalled = true
        lastCheckForExistingChatMembers = members
        
        if shouldThrowError {
            throw ChatServiceError.networkError(NSError(domain: "Test", code: -1, userInfo: nil))
        }
        
        return mockExistingChatID
    }
    
    override func fetchContacts(currentUserID: String) async throws -> [User] {
        fetchContactsCalled = true
        lastFetchContactsUserID = currentUserID
        
        if shouldThrowError {
            throw ChatServiceError.networkError(NSError(domain: "Test", code: -1, userInfo: nil))
        }
        
        return mockContacts
    }
    
    override func searchContacts(query: String, currentUserID: String) async throws -> [User] {
        searchContactsCalled = true
        lastSearchContactsQuery = query
        lastSearchContactsUserID = currentUserID
        
        if shouldThrowError {
            throw ChatServiceError.networkError(NSError(domain: "Test", code: -1, userInfo: nil))
        }
        
        return mockSearchResults
    }
}
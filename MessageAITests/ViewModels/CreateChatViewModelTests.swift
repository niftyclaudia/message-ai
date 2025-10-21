//
//  CreateChatViewModelTests.swift
//  MessageAITests
//
//  Unit tests for CreateChatViewModel
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for CreateChatViewModel
/// - Note: Tests contact loading, selection, search, and chat creation
struct CreateChatViewModelTests {
    
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
    
    // MARK: - Contact Loading Tests
    
    @Test("Load Contacts Successfully")
    func loadContactsSuccessfully() async throws {
        // Given: Mock chat service and auth service
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.mockContacts = [mockUser1, mockUser2, mockUser3]
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        
        // When: Load contacts
        await viewModel.loadContacts()
        
        // Then: Contacts should be loaded
        #expect(viewModel.contacts.count == 3)
        #expect(viewModel.filteredContacts.count == 3)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Load Contacts With Error")
    func loadContactsWithError() async throws {
        // Given: Mock services that throw error
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.shouldThrowError = true
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        
        // When: Load contacts
        await viewModel.loadContacts()
        
        // Then: Error should be set
        #expect(viewModel.contacts.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isLoading)
    }
    
    @Test("Load Contacts Without Authentication")
    func loadContactsWithoutAuthentication() async throws {
        // Given: Mock services with no current user
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = nil
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        
        // When: Load contacts
        await viewModel.loadContacts()
        
        // Then: Error should be set
        #expect(viewModel.contacts.isEmpty)
        #expect(viewModel.errorMessage == "User not authenticated")
        #expect(!viewModel.isLoading)
    }
    
    // MARK: - Contact Selection Tests
    
    @Test("Toggle Contact Selection")
    func toggleContactSelection() async throws {
        // Given: View model with loaded contacts
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.mockContacts = [mockUser1, mockUser2]
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        await viewModel.loadContacts()
        
        // When: Toggle selection
        viewModel.toggleContactSelection(userID: "user1")
        
        // Then: Contact should be selected
        #expect(viewModel.selectedContacts.contains("user1"))
        #expect(viewModel.selectedCount == 1)
        #expect(!viewModel.isGroupChat)
        
        // When: Toggle again
        viewModel.toggleContactSelection(userID: "user1")
        
        // Then: Contact should be deselected
        #expect(!viewModel.selectedContacts.contains("user1"))
        #expect(viewModel.selectedCount == 0)
    }
    
    @Test("Multiple Contact Selection")
    func multipleContactSelection() async throws {
        // Given: View model with loaded contacts
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.mockContacts = [mockUser1, mockUser2, mockUser3]
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        await viewModel.loadContacts()
        
        // When: Select multiple contacts
        viewModel.toggleContactSelection(userID: "user1")
        viewModel.toggleContactSelection(userID: "user2")
        viewModel.toggleContactSelection(userID: "user3")
        
        // Then: All contacts should be selected
        #expect(viewModel.selectedContacts.count == 3)
        #expect(viewModel.selectedCount == 3)
        #expect(viewModel.isGroupChat)
    }
    
    // MARK: - Search Tests
    
    @Test("Search Contacts Successfully")
    func searchContactsSuccessfully() async throws {
        // Given: View model with loaded contacts
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.mockContacts = [mockUser1, mockUser2, mockUser3]
        mockChatService.mockSearchResults = [mockUser1] // Only John Doe matches
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        await viewModel.loadContacts()
        
        // When: Search for "John"
        viewModel.searchQuery = "John"
        await viewModel.searchContacts()
        
        // Then: Only matching contacts should be shown
        #expect(viewModel.filteredContacts.count == 1)
        #expect(viewModel.filteredContacts.first?.id == "user1")
    }
    
    @Test("Search With Empty Query")
    func searchWithEmptyQuery() async throws {
        // Given: View model with loaded contacts
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.mockContacts = [mockUser1, mockUser2, mockUser3]
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        await viewModel.loadContacts()
        
        // When: Search with empty query
        viewModel.searchQuery = ""
        await viewModel.searchContacts()
        
        // Then: All contacts should be shown
        #expect(viewModel.filteredContacts.count == 3)
    }
    
    // MARK: - Chat Creation Tests
    
    @Test("Create Chat Successfully")
    func createChatSuccessfully() async throws {
        // Given: View model with selected contacts
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.mockContacts = [mockUser1, mockUser2]
        mockChatService.mockChatID = "new-chat-id"
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        await viewModel.loadContacts()
        viewModel.toggleContactSelection(userID: "user1")
        
        // When: Create chat
        await viewModel.createChat()
        
        // Then: Chat should be created
        #expect(viewModel.isChatCreated)
        #expect(viewModel.createdChatID == "new-chat-id")
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Create Group Chat Successfully")
    func createGroupChatSuccessfully() async throws {
        // Given: View model with multiple selected contacts
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.mockContacts = [mockUser1, mockUser2, mockUser3]
        mockChatService.mockChatID = "new-group-chat-id"
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        await viewModel.loadContacts()
        viewModel.toggleContactSelection(userID: "user1")
        viewModel.toggleContactSelection(userID: "user2")
        viewModel.toggleContactSelection(userID: "user3")
        
        // When: Create chat
        await viewModel.createChat()
        
        // Then: Group chat should be created
        #expect(viewModel.isChatCreated)
        #expect(viewModel.createdChatID == "new-group-chat-id")
        #expect(viewModel.isGroupChat)
    }
    
    @Test("Create Chat With No Selection")
    func createChatWithNoSelection() async throws {
        // Given: View model with no selected contacts
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.mockContacts = [mockUser1, mockUser2]
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        await viewModel.loadContacts()
        
        // When: Create chat
        await viewModel.createChat()
        
        // Then: Error should be shown
        #expect(!viewModel.isChatCreated)
        #expect(viewModel.errorMessage == "Please select at least one contact")
    }
    
    @Test("Create Chat With Service Error")
    func createChatWithServiceError() async throws {
        // Given: View model with selected contacts but service error
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.mockContacts = [mockUser1, mockUser2]
        mockChatService.shouldThrowError = true
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        await viewModel.loadContacts()
        viewModel.toggleContactSelection(userID: "user1")
        
        // When: Create chat
        await viewModel.createChat()
        
        // Then: Error should be shown
        #expect(!viewModel.isChatCreated)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("Failed to create chat") == true)
    }
    
    // MARK: - Computed Properties Tests
    
    @Test("Can Create Chat Computed Property")
    func canCreateChatComputedProperty() async throws {
        // Given: View model
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.mockContacts = [mockUser1, mockUser2]
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        await viewModel.loadContacts()
        
        // When: No selection
        // Then: Cannot create chat
        #expect(!viewModel.canCreateChat)
        
        // When: Select one contact
        viewModel.toggleContactSelection(userID: "user1")
        // Then: Can create chat
        #expect(viewModel.canCreateChat)
        
        // When: Loading
        viewModel.isLoading = true
        // Then: Cannot create chat
        #expect(!viewModel.canCreateChat)
    }
    
    @Test("Is Group Chat Computed Property")
    func isGroupChatComputedProperty() async throws {
        // Given: View model
        let mockChatService = MockChatService()
        let mockAuthService = MockAuthService()
        mockAuthService.currentUser = MockUser(uid: "currentUser")
        mockChatService.mockContacts = [mockUser1, mockUser2, mockUser3]
        
        let viewModel = CreateChatViewModel(chatService: mockChatService, authService: mockAuthService)
        await viewModel.loadContacts()
        
        // When: No selection
        // Then: Not group chat
        #expect(!viewModel.isGroupChat)
        
        // When: One contact selected
        viewModel.toggleContactSelection(userID: "user1")
        // Then: Not group chat (1-on-1)
        #expect(!viewModel.isGroupChat)
        
        // When: Two contacts selected
        viewModel.toggleContactSelection(userID: "user2")
        // Then: Group chat
        #expect(viewModel.isGroupChat)
    }
}

// MARK: - Mock Classes

/// Mock ChatService for testing
class MockChatService: ChatService {
    var mockContacts: [User] = []
    var mockSearchResults: [User] = []
    var mockChatID: String = "mock-chat-id"
    var shouldThrowError = false
    
    override func fetchContacts(currentUserID: String) async throws -> [User] {
        if shouldThrowError {
            throw ChatServiceError.networkError(NSError(domain: "Test", code: -1, userInfo: nil))
        }
        return mockContacts
    }
    
    override func searchContacts(query: String, currentUserID: String) async throws -> [User] {
        if shouldThrowError {
            throw ChatServiceError.networkError(NSError(domain: "Test", code: -1, userInfo: nil))
        }
        return mockSearchResults
    }
    
    override func createChat(members: [String], isGroup: Bool, createdBy: String) async throws -> String {
        if shouldThrowError {
            throw ChatServiceError.networkError(NSError(domain: "Test", code: -1, userInfo: nil))
        }
        return mockChatID
    }
}

/// Mock AuthService for testing
class MockAuthService: AuthService {
    var currentUser: MockUser?
    
    override var currentUser: User? {
        return currentUser
    }
}

/// Mock User for testing
struct MockUser: User {
    let id: String
    let displayName: String
    let email: String
    let profilePhotoURL: String?
    let createdAt: Date
    let lastActiveAt: Date
    
    init(uid: String) {
        self.id = uid
        self.displayName = "Test User"
        self.email = "test@example.com"
        self.profilePhotoURL = nil
        self.createdAt = Date()
        self.lastActiveAt = Date()
    }
}

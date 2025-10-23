//
//  TypingServiceTests.swift
//  MessageAITests
//
//  Tests for TypingService
//

import XCTest
import FirebaseDatabase
@testable import MessageAI

@MainActor
final class TypingServiceTests: XCTestCase {
    
    var sut: TypingService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = TypingService()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Set User Typing Tests
    
    func testSetUserTyping_WithValidData_ShouldSucceed() async throws {
        // Given
        let userID = "test_user_1"
        let chatID = "test_chat_1"
        let userName = "Test User"
        
        // When/Then - Should not throw
        do {
            try await sut.setUserTyping(userID: userID, chatID: chatID, userName: userName)
        } catch {
            XCTFail("Expected success, got error: \(error)")
        }
        
        // Clean up
        try? await sut.clearUserTyping(userID: userID, chatID: chatID)
    }
    
    func testClearUserTyping_WithValidData_ShouldSucceed() async throws {
        // Given
        let userID = "test_user_2"
        let chatID = "test_chat_2"
        let userName = "Test User"
        
        // When - Set then clear
        try await sut.setUserTyping(userID: userID, chatID: chatID, userName: userName)
        
        // Then - Should not throw
        do {
            try await sut.clearUserTyping(userID: userID, chatID: chatID)
        } catch {
            XCTFail("Expected success, got error: \(error)")
        }
    }
    
    // MARK: - Observe Typing Tests
    
    func testObserveTyping_WithTypingUsers_ShouldReturnTypingUsers() throws {
        // Given
        let chatID = "test_chat_observe"
        let currentUserID = "current_user"
        let expectation = XCTestExpectation(description: "Observe typing users")
        
        var receivedUsers: [TypingUser] = []
        
        // When
        let handle = sut.observeTyping(chatID: chatID, currentUserID: currentUserID) { users in
            receivedUsers = users
            if !users.isEmpty {
                expectation.fulfill()
            }
        }
        
        // Simulate another user typing (in real test, this would be done through Firebase)
        Task {
            try? await sut.setUserTyping(userID: "other_user", chatID: chatID, userName: "Other User")
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        
        // Verify current user is excluded
        XCTAssertFalse(receivedUsers.contains { $0.userID == currentUserID })
        
        // Clean up
        sut.removeObserver(chatID: chatID, handle: handle)
        Task {
            try? await sut.clearUserTyping(userID: "other_user", chatID: chatID)
        }
    }
    
    func testObserveTyping_WithNoTypingUsers_ShouldReturnEmptyArray() throws {
        // Given
        let chatID = "test_chat_empty"
        let currentUserID = "current_user"
        let expectation = XCTestExpectation(description: "Observe empty typing")
        expectation.isInverted = false
        
        // When
        let handle = sut.observeTyping(chatID: chatID, currentUserID: currentUserID) { users in
            // Should receive empty array initially
            if users.isEmpty {
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        // Clean up
        sut.removeObserver(chatID: chatID, handle: handle)
    }
    
    // MARK: - TypingUser Model Tests
    
    func testTypingUser_Initialization_ShouldSetPropertiesCorrectly() {
        // Given/When
        let user = TypingUser(userID: "user123", userName: "John Doe")
        
        // Then
        XCTAssertEqual(user.id, "user123")
        XCTAssertEqual(user.userID, "user123")
        XCTAssertEqual(user.userName, "John Doe")
    }
    
    func testTypingUser_Equatable_ShouldCompareCorrectly() {
        // Given
        let user1 = TypingUser(userID: "user123", userName: "John Doe")
        let user2 = TypingUser(userID: "user123", userName: "John Doe")
        let user3 = TypingUser(userID: "user456", userName: "Jane Smith")
        
        // Then
        XCTAssertEqual(user1, user2)
        XCTAssertNotEqual(user1, user3)
    }
    
    // MARK: - Error Handling Tests
    
    func testTypingServiceError_NotAuthenticated_ShouldHaveCorrectDescription() {
        // Given
        let error = TypingServiceError.notAuthenticated
        
        // Then
        XCTAssertEqual(error.errorDescription, "User not authenticated")
    }
    
    func testTypingServiceError_NetworkError_ShouldHaveCorrectDescription() {
        // Given
        let underlyingError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network failed"])
        let error = TypingServiceError.networkError(underlyingError)
        
        // Then
        XCTAssertTrue(error.errorDescription?.contains("Network error") ?? false)
    }
    
    // MARK: - Performance Tests
    
    func testSetUserTyping_Performance() throws {
        // Given
        let userID = "perf_user"
        let chatID = "perf_chat"
        let userName = "Performance User"
        
        // Measure
        measure {
            let expectation = XCTestExpectation(description: "Set typing performance")
            
            Task {
                do {
                    try await sut.setUserTyping(userID: userID, chatID: chatID, userName: userName)
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
        
        // Clean up
        Task {
            try? await sut.clearUserTyping(userID: userID, chatID: chatID)
        }
    }
}


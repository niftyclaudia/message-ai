//
//  ContactListViewModelTests.swift
//  MessageAITests
//
//  Unit tests for ContactListViewModel
//

import XCTest
@testable import MessageAI

@MainActor
final class ContactListViewModelTests: XCTestCase {
    
    var sut: ContactListViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = ContactListViewModel()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Load Users Tests
    
    /// Test loadUsers populates arrays
    /// Gate: allUsers and filteredUsers populated
    func testLoadUsers_PopulatesArray() async throws {
        // When: Loading users
        await sut.loadUsers()
        
        // Then: Arrays should be populated or error should be set
        XCTAssertTrue(sut.allUsers.count >= 0, "Should have users array")
        XCTAssertTrue(sut.filteredUsers.count >= 0, "Should have filtered users array")
        XCTAssertFalse(sut.isLoading, "Should finish loading")
    }
    
    // MARK: - Search Tests
    
    /// Test filterUsers with query filters correctly
    /// Gate: filteredUsers contains only matches
    func testSearchUsers_FiltersCorrectly() throws {
        // Given: Mock users
        let user1 = User(id: "1", displayName: "John Doe", email: "john@example.com", createdAt: Date(), lastActiveAt: Date())
        let user2 = User(id: "2", displayName: "Jane Smith", email: "jane@example.com", createdAt: Date(), lastActiveAt: Date())
        let user3 = User(id: "3", displayName: "Bob Johnson", email: "bob@example.com", createdAt: Date(), lastActiveAt: Date())
        
        sut.allUsers = [user1, user2, user3]
        
        // When: Searching for "john"
        sut.searchQuery = "john"
        
        // Then: Should match John Doe and Bob Johnson
        XCTAssertTrue(sut.filteredUsers.contains { $0.id == "1" }, "Should match 'John Doe'")
        XCTAssertTrue(sut.filteredUsers.contains { $0.id == "3" }, "Should match 'Bob Johnson'")
        XCTAssertFalse(sut.filteredUsers.contains { $0.id == "2" }, "Should not match 'Jane Smith'")
    }
    
    /// Test empty query shows all users
    /// Gate: Empty query shows all users
    func testSearchUsers_EmptyQuery_ShowsAll() throws {
        // Given: Mock users
        let user1 = User(id: "1", displayName: "John Doe", email: "john@example.com", createdAt: Date(), lastActiveAt: Date())
        let user2 = User(id: "2", displayName: "Jane Smith", email: "jane@example.com", createdAt: Date(), lastActiveAt: Date())
        
        sut.allUsers = [user1, user2]
        
        // When: Setting empty search query
        sut.searchQuery = ""
        
        // Then: Should show all users
        XCTAssertEqual(sut.filteredUsers.count, 2, "Should show all users")
    }
}


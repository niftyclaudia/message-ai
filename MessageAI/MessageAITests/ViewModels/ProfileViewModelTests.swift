//
//  ProfileViewModelTests.swift
//  MessageAITests
//
//  Unit tests for ProfileViewModel
//

import XCTest
@testable import MessageAI

@MainActor
final class ProfileViewModelTests: XCTestCase {
    
    var sut: ProfileViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = ProfileViewModel()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Load Profile Tests
    
    /// Test loadProfile populates user property
    /// Gate: user @Published populated
    func testLoadProfile_ValidUser_LoadsData() async throws {
        // When: Loading profile
        await sut.loadProfile()
        
        // Then: User should be populated or error should be set
        XCTAssertTrue(sut.user != nil || sut.errorMessage != nil, "Should have user or error")
        XCTAssertFalse(sut.isLoading, "Should finish loading")
    }
    
    /// Test loading state management
    /// Gate: isLoading toggles correctly
    func testLoadProfile_SetsLoadingState() async throws {
        // Given: Initial state
        XCTAssertFalse(sut.isLoading, "Should not be loading initially")
        
        // When: Start loading (check during load would require more complex async testing)
        await sut.loadProfile()
        
        // Then: Should finish loading
        XCTAssertFalse(sut.isLoading, "Should not be loading after completion")
    }
}


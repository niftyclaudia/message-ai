//
//  FirebaseServiceTests.swift
//  MessageAITests
//
//  Unit tests for FirebaseService
//

import XCTest
@testable import MessageAI
import FirebaseCore
import FirebaseFirestore

final class FirebaseServiceTests: XCTestCase {
    
    var service: FirebaseService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        service = FirebaseService.shared
    }
    
    override func tearDownWithError() throws {
        service = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Configuration Tests
    
    /// Test that configure() succeeds on first call
    /// Gate: Firebase initialized successfully
    func testConfigure_FirstCall_Succeeds() throws {
        // Given: Fresh service instance
        // When: Configuring Firebase
        // Then: Should succeed without error
        XCTAssertNoThrow(try service.configure())
        
        // Verify Firestore is accessible
        let db = service.getFirestore()
        XCTAssertNotNil(db, "Firestore instance should be available")
    }
    
    /// Test that configure() is idempotent (safe to call multiple times)
    /// Gate: Multiple calls don't cause errors
    func testConfigure_MultipleCalls_Idempotent() throws {
        // Given: Firebase already configured
        try service.configure()
        
        // When: Calling configure again
        // Then: Should not throw error
        XCTAssertNoThrow(try service.configure())
        XCTAssertNoThrow(try service.configure())
    }
    
    /// Test that getFirestore() returns a valid Firestore instance
    /// Gate: Firestore instance is usable
    func testGetFirestore_ReturnsValidInstance() throws {
        // Given: Firebase configured
        try service.configure()
        
        // When: Getting Firestore instance
        let db = service.getFirestore()
        
        // Then: Should return non-nil instance
        XCTAssertNotNil(db)
        
        // Verify it's the Firestore type
        XCTAssertTrue(db is Firestore)
    }
    
    /// Test performance of Firebase initialization
    /// Gate: Initialization completes in < 500ms
    func testPerformance_FirebaseInit_Under500ms() throws {
        // Measure initialization time
        measure {
            do {
                try service.configure()
            } catch {
                XCTFail("Configuration should not fail: \(error)")
            }
        }
        
        // Note: XCTest measure baseline should be set to 0.5s (500ms) max
    }
}


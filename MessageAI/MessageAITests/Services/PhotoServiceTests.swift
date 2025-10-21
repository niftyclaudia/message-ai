//
//  PhotoServiceTests.swift
//  MessageAITests
//
//  Unit tests for PhotoService
//

import XCTest
@testable import MessageAI

final class PhotoServiceTests: XCTestCase {
    
    var sut: PhotoService!
    
    override func setUp() {
        super.setUp()
        sut = PhotoService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Image Compression Tests
    
    func testCompressImage_ValidImage_ReturnsData() {
        // Given
        let image = createTestImage(size: CGSize(width: 1000, height: 1000))
        let maxSize = Constants.Photo.targetPhotoSizeBytes
        
        // When
        let compressedData = sut.compressImage(image: image, maxSizeBytes: maxSize)
        
        // Then
        XCTAssertNotNil(compressedData, "Compressed data should not be nil")
        XCTAssertLessThanOrEqual(compressedData?.count ?? Int.max, maxSize, "Compressed size should be under target")
    }
    
    func testCompressImage_LargeImage_ReducesSize() {
        // Given
        let largeImage = createTestImage(size: CGSize(width: 4000, height: 4000))
        let targetSize = 2_000_000
        
        // When
        let compressedData = sut.compressImage(image: largeImage, maxSizeBytes: targetSize)
        
        // Then
        XCTAssertNotNil(compressedData)
        if let data = compressedData {
            XCTAssertLessThanOrEqual(data.count, targetSize, "Should compress to target size")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates a test image with specified size
    private func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}


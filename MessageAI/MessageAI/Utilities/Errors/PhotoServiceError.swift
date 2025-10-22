//
//  PhotoServiceError.swift
//  MessageAI
//
//  Photo service error types with user-friendly descriptions
//

import Foundation

/// Errors that can occur during photo service operations
enum PhotoServiceError: LocalizedError, Equatable {
    case imageCompressionFailed
    case uploadFailed(Error)
    case deleteFailed(Error)
    case invalidImageData
    case fileSizeTooLarge
    case invalidURL
    case unknown(Error)
    
    // MARK: - Equatable
    
    static func == (lhs: PhotoServiceError, rhs: PhotoServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.imageCompressionFailed, .imageCompressionFailed):
            return true
        case (.invalidImageData, .invalidImageData):
            return true
        case (.fileSizeTooLarge, .fileSizeTooLarge):
            return true
        case (.invalidURL, .invalidURL):
            return true
        case (.uploadFailed(let lhsError), .uploadFailed(let rhsError)):
            return (lhsError as NSError).domain == (rhsError as NSError).domain &&
                   (lhsError as NSError).code == (rhsError as NSError).code
        case (.deleteFailed(let lhsError), .deleteFailed(let rhsError)):
            return (lhsError as NSError).domain == (rhsError as NSError).domain &&
                   (lhsError as NSError).code == (rhsError as NSError).code
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return (lhsError as NSError).domain == (rhsError as NSError).domain &&
                   (lhsError as NSError).code == (rhsError as NSError).code
        default:
            return false
        }
    }
    
    /// User-friendly error descriptions
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image. The image may be corrupted."
        case .uploadFailed(let error):
            return "Failed to upload photo: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete photo: \(error.localizedDescription)"
        case .invalidImageData:
            return "Invalid image data. Please select a valid image file."
        case .fileSizeTooLarge:
            return "Image file is too large. Maximum size is 10MB."
        case .invalidURL:
            return "Invalid photo URL."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    /// Recovery suggestions for users
    var recoverySuggestion: String? {
        switch self {
        case .imageCompressionFailed:
            return "Try selecting a different photo or taking a new one."
        case .uploadFailed:
            return "Check your internet connection and try again."
        case .deleteFailed:
            return "The photo may have already been deleted. Try refreshing."
        case .invalidImageData:
            return "Please select a different image file."
        case .fileSizeTooLarge:
            return "Please select a smaller image or take a new photo."
        case .invalidURL:
            return "Please upload a new photo."
        case .unknown:
            return "Please try again. If the problem persists, contact support."
        }
    }
}


//
//  PhotoService.swift
//  MessageAI
//
//  Service for managing profile photos in Firebase Storage
//

import Foundation
import FirebaseStorage
import UIKit

/// Service for photo upload, download, and deletion operations
class PhotoService {
    
    // MARK: - Properties
    
    private let storage: Storage
    
    // MARK: - Initialization
    
    init(storage: Storage? = nil) {
        self.storage = storage ?? Storage.storage()
    }
    
    // MARK: - Public Methods
    
    /// Uploads profile photo to Firebase Storage
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - userID: User ID for folder organization
    ///   - progressHandler: Closure called with upload progress (0.0 to 1.0)
    /// - Returns: Download URL string for the uploaded photo
    /// - Throws: PhotoServiceError for various failure cases
    /// - Performance: Should complete in < 5 seconds for 2MB image (see shared-standards.md)
    func uploadProfilePhoto(
        image: UIImage,
        userID: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> String {
        // Compress image before upload
        guard let imageData = compressImage(image: image, maxSizeBytes: Constants.Photo.targetPhotoSizeBytes) else {
            throw PhotoServiceError.imageCompressionFailed
        }
        
        // Check file size
        guard imageData.count <= Constants.Photo.maxPhotoSizeBytes else {
            throw PhotoServiceError.fileSizeTooLarge
        }
        
        // Generate unique path
        let photoPath = generatePhotoPath(userID: userID)
        let storageRef = storage.reference().child(photoPath)
        
        // Create upload metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload with progress tracking
        let uploadTask = storageRef.putData(imageData, metadata: metadata)

        // Observe progress
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            DispatchQueue.main.async {
                progressHandler(percentComplete)
            }
        }

        do {
            // Wait for upload to complete
            _ = await uploadTask

            // Get download URL
            let downloadURL = try await storageRef.downloadURL()

            print("✅ Photo uploaded: \(photoPath)")
            return downloadURL.absoluteString

        } catch {
            print("❌ Photo upload failed: \(error.localizedDescription)")
            throw PhotoServiceError.uploadFailed(error)
        }
    }
    
    /// Deletes profile photo from Firebase Storage
    /// - Parameter photoURL: Full download URL of the photo to delete
    /// - Throws: PhotoServiceError.deleteFailed if deletion fails
    func deleteProfilePhoto(photoURL: String) async throws {
        // Extract storage reference from URL
        let storageRef = storage.reference(forURL: photoURL)

        do {
            try await storageRef.delete()
            print("✅ Photo deleted: \(photoURL)")

        } catch {
            print("❌ Photo deletion failed: \(error.localizedDescription)")
            throw PhotoServiceError.deleteFailed(error)
        }
    }
    
    /// Compresses image to target size
    /// - Parameters:
    ///   - image: UIImage to compress
    ///   - maxSizeBytes: Maximum size in bytes
    /// - Returns: Compressed image data, or nil if compression fails
    func compressImage(image: UIImage, maxSizeBytes: Int) -> Data? {
        // First resize to standard profile photo size
        guard let resizedImage = image.resizeToSquare(size: Constants.Photo.profilePhotoSize) else {
            return nil
        }
        
        // Then compress to target size
        return resizedImage.compress(to: maxSizeBytes)
    }
    
    // MARK: - Private Helpers
    
    /// Generates unique storage path for profile photo
    /// - Parameter userID: User ID for folder organization
    /// - Returns: Storage path string (e.g., "profile_photos/userID/timestamp.jpg")
    private func generatePhotoPath(userID: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "\(Constants.Storage.profilePhotosPath)/\(userID)/\(timestamp).jpg"
    }
}


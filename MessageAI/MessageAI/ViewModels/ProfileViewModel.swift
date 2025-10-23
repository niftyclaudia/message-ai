//
//  ProfileViewModel.swift
//  MessageAI
//
//  View model for profile viewing and editing
//

import Foundation
import UIKit

/// View model managing profile state and operations
@MainActor
class ProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var uploadProgress: Double = 0.0
    
    // MARK: - Services
    
    private let userService: UserService
    private let photoService: PhotoService
    
    // MARK: - Initialization
    
    init(
        userService: UserService = UserService(),
        photoService: PhotoService = PhotoService()
    ) {
        self.userService = userService
        self.photoService = photoService
    }
    
    // MARK: - Public Methods
    
    /// Loads current user's profile
    /// - Parameter authService: AuthService instance with current user
    func loadProfile(authService: AuthService) async {
        isLoading = true
        errorMessage = nil
        
        do {
            user = try await userService.fetchCurrentUserProfile(authService: authService)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Updates user's display name
    /// - Parameters:
    ///   - displayName: New display name (1-50 characters)
    ///   - authService: AuthService instance with current user
    /// - Throws: UserServiceError for validation or Firestore errors
    func updateProfile(displayName: String, authService: AuthService) async throws {
        guard let userID = authService.currentUser?.uid else {
            throw UserServiceError.notFound
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await userService.updateDisplayName(userID: userID, displayName: displayName)
            
            // Update local user object
            if var updatedUser = user {
                updatedUser.displayName = displayName
                user = updatedUser
            }
            
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    /// Uploads profile photo and updates user document
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - authService: AuthService instance with current user
    /// - Throws: PhotoServiceError or UserServiceError
    func uploadProfilePhoto(image: UIImage, authService: AuthService) async throws {
        guard let userID = authService.currentUser?.uid else {
            throw UserServiceError.notFound
        }
        
        isLoading = true
        errorMessage = nil
        uploadProgress = 0.0
        
        do {
            // Upload photo with progress tracking
            let photoURL = try await photoService.uploadProfilePhoto(
                image: image,
                userID: userID
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.uploadProgress = progress
                }
            }
            
            // Delete old photo if exists
            if let oldPhotoURL = user?.profilePhotoURL {
                try? await photoService.deleteProfilePhoto(photoURL: oldPhotoURL)
            }
            
            // Update Firestore with new photo URL
            try await userService.updateProfilePhoto(userID: userID, photoURL: photoURL)
            
            // Update local user object
            if var updatedUser = user {
                updatedUser.profilePhotoURL = photoURL
                user = updatedUser
            }
            
            uploadProgress = 1.0
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
}


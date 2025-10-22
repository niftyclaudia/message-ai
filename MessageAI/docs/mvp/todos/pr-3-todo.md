# PR-3 TODO — User Profile Management & Contact System

**Branch**: `feat/pr-3-profile-contacts`  
**Source PRD**: `MessageAI/docs/prds/pr-3-prd.md`  
**Owner (Agent)**: Cody  
**Dependencies**: PR #1 (complete), PR #2 (complete)

---

## 0. Setup

- [ ] Create branch from develop: `git checkout develop && git pull && git checkout -b feat/pr-3-profile-contacts`
- [ ] Read PRD (`MessageAI/docs/prds/pr-3-prd.md`) and `MessageAI/agents/shared-standards.md`
- [ ] Verify PR #1 & PR #2 work (AuthService, UserService, MainTabView accessible)
- [ ] Confirm Xcode project builds with 0 warnings
- [ ] Enable Firebase Storage in Firebase Console

---

## 1. Extend User Model

Add computed properties for UI display.

- [ ] Modify `Models/User.swift`
  - Add computed property: `var initials: String` (extracts first letters from displayName)
  - Add computed property: `var memberSinceFormatted: String` (formats createdAt as "Member since Jan 2025")
  - Test Gate: Properties return expected values for test User

---

## 2. Error Types

Define photo-related error types.

- [ ] Create `Utilities/Errors/PhotoServiceError.swift`
  - Cases: imageCompressionFailed, uploadFailed(Error), deleteFailed(Error)
  - Cases: invalidImageData, fileSizeTooLarge, invalidURL, unknown(Error)
  - Implement LocalizedError with user-friendly messages
  - Test Gate: Error descriptions return expected strings

- [ ] Extend `Utilities/Errors/UserServiceError.swift`
  - Add cases: displayNameTooShort, displayNameTooLong, searchQueryTooShort
  - Update error descriptions
  - Test Gate: New error cases have proper descriptions

---

## 3. Constants

Add Storage paths and photo size limits.

- [ ] Modify `Utilities/Constants.swift`
  - Add Storage paths: `static let profilePhotosPath = "profile_photos"`
  - Add photo size limits: `static let maxPhotoSizeBytes = 10_000_000` (10MB)
  - Add target compression: `static let targetPhotoSizeBytes = 2_000_000` (2MB)
  - Test Gate: Constants accessible from other files

---

## 4. Image Utilities

Create image compression and manipulation helpers.

- [ ] Create `Utilities/Extensions/UIImage+Extensions.swift`
  - Method: `func compress(to maxBytes: Int) -> Data?`
    - Uses JPEG compression with quality adjustment
    - Returns compressed Data or nil if fails
  - Method: `func resizeToSquare(size: CGFloat) -> UIImage?`
    - Resizes and center-crops to square
  - Test Gate: 10MB image compresses to ~2MB, maintains quality

- [ ] Create `Utilities/Extensions/String+Extensions.swift`
  - Method: `func extractInitials() -> String`
    - Extracts first letters from name ("John Doe" → "JD")
    - Handles single names, empty strings
  - Test Gate: Various name formats return correct initials

---

## 5. PhotoService - Firebase Storage Operations

Implement photo upload, delete, compression.

- [ ] Create `Services/PhotoService.swift`
  - Import FirebaseStorage, UIKit
  - Private property: `let storage = Storage.storage()`
  
- [ ] Implement `uploadProfilePhoto(image:userID:progressHandler:)`
  - Compress image to target size (2MB)
  - Generate path: `profile_photos/{userID}/{timestamp}.jpg`
  - Upload to Firebase Storage with progress tracking
  - Return download URL string
  - Test Gate: Photo uploads successfully, returns valid URL
  
- [ ] Implement `deleteProfilePhoto(photoURL:)`
  - Parse Storage reference from URL
  - Delete file from Storage
  - Handle errors gracefully
  - Test Gate: Photo deleted from Storage
  
- [ ] Implement `compressImage(image:maxSizeBytes:)`
  - Use UIImage compression utility
  - Return compressed Data
  - Test Gate: Returns data under maxSizeBytes
  
- [ ] Add private helper: `generatePhotoPath(userID:)`
  - Returns: `profile_photos/{userID}/{timestamp}.jpg`
  - Test Gate: Generates unique paths

---

## 6. Extend UserService

Add profile update and contact discovery methods.

- [ ] Modify `Services/UserService.swift`
  - Add `updateDisplayName(userID:displayName:)` method
    - Validate displayName (1-50 chars)
    - Update Firestore user document
    - Update lastActiveAt timestamp
    - Test Gate: Firestore document updated < 2s
  
- [ ] Add `updateProfilePhoto(userID:photoURL:)` method
  - Update profilePhotoURL field in Firestore
  - Update lastActiveAt timestamp
  - Test Gate: Photo URL saved to Firestore
  
- [ ] Add `fetchCurrentUserProfile()` method
  - Get current user ID from AuthService
  - Fetch user document from Firestore
  - Return User model
  - Test Gate: Returns current user data
  
- [ ] Add `fetchAllUsers()` method
  - Fetch all documents from users collection
  - Exclude current user from results
  - Return array of User models
  - Test Gate: Returns all users except current user
  
- [ ] Add `searchUsers(query:)` method
  - Filter users by displayName or email (case-insensitive)
  - Client-side filtering for now (server-side future)
  - Return matching User array
  - Test Gate: "john" matches "Johnny" and "john@email.com"
  
- [ ] Add `observeUsers(completion:)` method
  - Set up Firestore snapshot listener on users collection
  - Exclude current user
  - Return ListenerRegistration
  - Test Gate: Listener fires on new user creation

---

## 7. ProfileViewModel

Manage profile view and edit state.

- [ ] Create `ViewModels/ProfileViewModel.swift`
  - `@Published var user: User?`
  - `@Published var isLoading: Bool = false`
  - `@Published var errorMessage: String?`
  - `@Published var uploadProgress: Double = 0.0`
  - Private properties: userService, photoService, authService
  
- [ ] Implement `loadProfile()` async method
  - Set isLoading = true
  - Fetch current user profile
  - Set user property
  - Handle errors, set errorMessage
  - Set isLoading = false
  - Test Gate: Loads profile successfully
  
- [ ] Implement `updateProfile(displayName:)` async throws method
  - Validate displayName (1-50 chars)
  - Call userService.updateDisplayName
  - Update local user object
  - Throw errors for UI to handle
  - Test Gate: Profile updates successfully
  
- [ ] Implement `uploadProfilePhoto(image:)` async throws method
  - Get current user ID
  - Set isLoading = true
  - Upload photo via photoService with progress tracking
  - Update uploadProgress @Published property
  - Get download URL
  - Delete old photo if exists
  - Update Firestore with new photo URL
  - Update local user object
  - Set isLoading = false
  - Test Gate: Photo uploads and URL updates

---

## 8. ContactListViewModel

Manage contact search and discovery.

- [ ] Create `ViewModels/ContactListViewModel.swift`
  - `@Published var allUsers: [User] = []`
  - `@Published var filteredUsers: [User] = []`
  - `@Published var searchQuery: String = ""`
  - `@Published var isLoading: Bool = false`
  - `@Published var errorMessage: String?`
  - Private properties: userService, listener
  
- [ ] Implement `loadUsers()` async method
  - Set isLoading = true
  - Fetch all users from userService
  - Set allUsers and filteredUsers
  - Set isLoading = false
  - Test Gate: Loads users successfully
  
- [ ] Implement `searchUsers(query:)` method
  - Filter allUsers by displayName or email containing query
  - Case-insensitive search
  - Update filteredUsers
  - If query empty, show all users
  - Test Gate: Search filters correctly in real-time
  
- [ ] Implement `observeUsersRealTime()` method
  - Set up listener via userService.observeUsers
  - Update allUsers and re-filter on each update
  - Store listener for cleanup
  - Test Gate: New users appear automatically
  
- [ ] Add `deinit` to remove listener
  - Call listener?.remove()

---

## 9. Reusable Avatar Component

Create avatar view for use throughout app.

- [ ] Create `Views/Components/AvatarView.swift`
  - Params: photoURL (String?), displayName (String), size (CGFloat)
  - If photoURL exists: AsyncImage with circular clip
  - Else: Circle with initials text
  - Background color generated from displayName hash (consistent pastel colors)
  - Test Gate: Shows image or initials correctly

---

## 10. Profile Photo Component

Avatar with camera icon for editing.

- [ ] Create `Views/Components/ProfilePhotoView.swift`
  - Params: photoURL, displayName, size, onTap action
  - Shows AvatarView
  - Overlay: Camera icon in bottom-right
  - Tappable gesture calls onTap
  - Test Gate: Tappable, shows camera icon

---

## 11. Photo Picker Wrapper

SwiftUI wrapper for native photo picker.

- [ ] Create `Views/Components/PhotoPicker.swift`
  - Uses PhotosPickerItem (iOS 16+)
  - Params: selectedImage binding, isPresented binding
  - Loads selected image as UIImage
  - Test Gate: Picker opens, selection works

---

## 12. User Row Component

Single row for contact list.

- [ ] Create `Views/Components/UserRowView.swift`
  - Params: user (User)
  - HStack: AvatarView (40pt), VStack(name, email)
  - Styled with AppTheme
  - Test Gate: Displays user info correctly

---

## 13. Profile View

Display current user profile.

- [ ] Create `Views/Profile/ProfileView.swift`
  - @StateObject: ProfileViewModel
  - @EnvironmentObject: AuthService
  - VStack layout: AvatarView (120pt), displayName, email, member since
  - "Edit Profile" button → Navigate to ProfileEditView
  - Loading state shows skeleton
  - Error state shows alert
  - onAppear: Load profile
  - Test Gate: Profile displays correctly

---

## 14. Profile Edit View

Edit name and upload photo.

- [ ] Create `Views/Profile/ProfileEditView.swift`
  - @StateObject: ProfileViewModel
  - @State: displayName, showPhotoPicker, selectedImage, characterCount
  - @Environment(\.dismiss): For navigation back
  
- [ ] Layout Components
  - ProfilePhotoView with onTap → showPhotoPicker
  - TextField for displayName with character counter (X/50)
  - Save button (disabled if invalid)
  - Cancel button
  - PhotoPicker sheet
  - Progress overlay during photo upload
  
- [ ] Implement save logic
  - Validate displayName (1-50 chars)
  - If photo selected: Upload photo first
  - Then update profile with new name
  - On success: Dismiss view
  - On error: Show alert
  
- [ ] Implement cancel logic
  - Dismiss without saving
  
- [ ] Test Gate: Edit and save updates profile

---

## 15. Contact List View

Search and browse users.

- [ ] Create `Views/Profile/ContactListView.swift`
  - @StateObject: ContactListViewModel
  - @State: searchText
  - SearchBar at top
  - ScrollView with LazyVStack for performance
  - ForEach: UserRowView for each user
  - Empty state: "No users found" if filteredUsers empty
  - Loading state during initial load
  - onAppear: Load users and observe real-time
  - onChange(searchText): Call viewModel.searchUsers
  - Test Gate: Search works, scrolling smooth

---

## 16. Integrate Profile Tab

Add profile to main navigation.

- [ ] Modify `Views/Main/MainTabView.swift`
  - Add new tab: "Profile"
  - Tab content: ProfileView
  - SF Symbol: "person.circle"
  - Test Gate: Profile tab appears, navigates correctly

---

## 17. Firebase Storage Security Rules

Configure Storage security.

- [ ] Update `storage.rules` (or create if doesn't exist)
  - Allow authenticated users to read all profile photos
  - Allow users to write/delete only their own photos
  - Enforce 10MB file size limit
  - Validate content type is image
  - Test Gate: Rules deployed, enforced correctly

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_photos/{userID}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && request.auth.uid == userID
                   && request.resource.size < 10 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
      allow delete: if request.auth != null && request.auth.uid == userID;
    }
  }
}
```

---

## 18. Firestore Security Rules

Update rules for profile updates.

- [ ] Update `firestore.rules`
  - Allow users to update own profile (displayName, profilePhotoURL)
  - Prevent modification of immutable fields (id, email, createdAt)
  - Validate displayName length (1-50 chars)
  - Test Gate: Rules deployed, tested in emulator

```javascript
match /users/{userID} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated() && isOwner(userID) && validUserData();
  allow update: if isAuthenticated() && isOwner(userID) && validProfileUpdate();
  allow delete: if false;
  
  function validProfileUpdate() {
    return request.resource.data.displayName is string
        && request.resource.data.displayName.size() >= 1
        && request.resource.data.displayName.size() <= 50
        && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['id', 'email', 'createdAt']);
  }
}
```

---

## 19. Unit Tests - PhotoService

- [ ] Create `MessageAITests/Services/PhotoServiceTests.swift`
  - testUploadPhoto_ValidImage_Succeeds
    - Gate: Upload returns valid URL < 5s
  - testUploadPhoto_LargeImage_Compresses
    - Gate: 10MB → ~2MB before upload
  - testUploadPhoto_InvalidImage_ThrowsError
    - Gate: Throws invalidImageData
  - testDeletePhoto_ValidURL_Deletes
    - Gate: Photo removed from Storage
  - testCompressImage_ReturnsTargetSize
    - Gate: Compressed data < 2MB
  - testUploadProgress_Reports
    - Gate: Progress handler called 0.0 to 1.0

---

## 20. Unit Tests - UserService Extensions

- [ ] Add to `MessageAITests/Services/UserServiceTests.swift`
  - testUpdateDisplayName_ValidName_Updates
    - Gate: Firestore updated < 2s
  - testUpdateDisplayName_TooShort_ThrowsError
    - Gate: Throws before Firestore call
  - testUpdateDisplayName_TooLong_ThrowsError
    - Gate: Throws before Firestore call
  - testFetchAllUsers_ExcludesCurrent
    - Gate: Returns all except current user
  - testSearchUsers_PartialMatch_ReturnsMatches
    - Gate: "john" matches "Johnny" and "john@email.com"
  - testSearchUsers_CaseInsensitive
    - Gate: "JOHN" matches "john"
  - testObserveUsers_NewUser_ReceivesUpdate
    - Gate: Listener fires on new user

---

## 21. Unit Tests - ViewModels

- [ ] Create `MessageAITests/ViewModels/ProfileViewModelTests.swift`
  - testLoadProfile_ValidUser_LoadsData
    - Gate: user @Published populated
  - testUpdateProfile_ValidName_Succeeds
    - Gate: Calls UserService correctly
  - testUploadPhoto_ValidImage_Succeeds
    - Gate: PhotoService → UserService sequence
  - testUploadPhoto_Failure_SetsError
    - Gate: errorMessage populated

- [ ] Create `MessageAITests/ViewModels/ContactListViewModelTests.swift`
  - testLoadUsers_PopulatesArray
    - Gate: allUsers and filteredUsers populated
  - testSearchUsers_FiltersCorrectly
    - Gate: filteredUsers contains only matches
  - testSearchUsers_EmptyQuery_ShowsAll
    - Gate: Empty query shows all users
  - testObserveUsers_RealTimeUpdate
    - Gate: New user appears automatically

---

## 22. UI Tests - Profile Flow

- [ ] Create `MessageAIUITests/ProfileFlowUITests.swift`
  - testProfileView_Loads_DisplaysUserInfo
    - Gate: Shows avatar, name, email
  - testProfileView_NoPhoto_ShowsInitials
    - Gate: Default avatar with initials
  - testProfileView_TapEdit_NavigatesToEdit
    - Gate: Edit button works
  - testProfileEdit_ChangeNameAndSave_Updates
    - Gate: Name persists in ProfileView
  - testProfileEdit_TapCancel_DiscardsChanges
    - Gate: No changes saved
  - testProfileEdit_TapAvatar_OpensPhotoPicker
    - Gate: Photo picker appears
  - testProfileEdit_UploadPhoto_ShowsProgress
    - Gate: Progress indicator visible
  - testProfileEdit_PhotoUploadSuccess_UpdatesAvatar
    - Gate: New photo in ProfileView

---

## 23. UI Tests - Contact Discovery

- [ ] Create `MessageAIUITests/ContactDiscoveryUITests.swift`
  - testContactList_Loads_DisplaysUsers
    - Gate: Shows all users except self
  - testContactList_Search_FiltersResults
    - Gate: Typing filters real-time
  - testContactList_NoResults_ShowsEmptyState
    - Gate: "No users found" appears
  - testContactList_ScrollPerformance_Smooth
    - Gate: 100+ contacts scroll at 60fps
  - testContactList_TapUser_SelectsUser
    - Gate: Tap works (for future PR #9)

---

## 24. Integration Tests

- [ ] Create `MessageAITests/Integration/ProfileIntegrationTests.swift`
  - testUpdateProfile_UpdatesFirestoreAndUI
    - Gate: Firestore matches UI state
  - testUploadPhoto_UpdatesStorageAndFirestore
    - Gate: Photo in Storage, URL in Firestore, old deleted
  - testProfilePhotoSync_AppearsEverywhere
    - Gate: AvatarView updates throughout app

- [ ] Add to `MessageAITests/Integration/SecurityRulesTests.swift`
  - testSecurityRules_UserUpdatesOwn_Succeeds
    - Gate: Update users/{own-uid} works
  - testSecurityRules_UserUpdatesOther_Fails
    - Gate: Update users/{other-uid} fails
  - testSecurityRules_PhotoToOwnFolder_Succeeds
    - Gate: Upload to profile_photos/{own-uid}/ works
  - testSecurityRules_PhotoToOtherFolder_Fails
    - Gate: Upload to profile_photos/{other-uid}/ fails
  - testSecurityRules_PhotoTooLarge_Rejected
    - Gate: 11MB upload rejected

---

## 25. Performance Tests

- [ ] Create `MessageAITests/Performance/ProfilePerformanceTests.swift`
  - testProfileLoad_Under1s
    - Gate: Profile data < 1s
  - testPhotoUpload_2MB_Under5s
    - Gate: Upload < 5s
  - testPhotoCompression_Fast
    - Gate: 10MB → 2MB < 2s
  - testContactSearch_100Users_Under500ms
    - Gate: Search < 500ms
  - testContactScroll_100Users_60fps
    - Gate: Smooth scrolling

---

## 26. Documentation & Cleanup

- [ ] Add code comments
  - Document PhotoService methods with pre/post-conditions
  - Comment image compression algorithm
  - Document search logic
  
- [ ] Update README.md
  - Document profile management features
  - Document Firebase Storage setup steps
  - Document security rules
  
- [ ] Update Architecture doc
  - Add PhotoService to architecture diagram
  - Document photo upload flow
  - Document contact search pattern

---

## 27. Final Verification

- [ ] Run all tests
  - All unit tests pass
  - All UI tests pass
  - All integration tests pass
  - All performance tests meet targets
  
- [ ] Manual testing
  - View profile → Loads correctly
  - Edit name → Updates throughout app
  - Upload photo → Appears everywhere
  - Upload large photo (8MB) → Compresses and uploads
  - Search contacts → Filters correctly
  - Offline: View profile, queue edits
  
- [ ] Code quality
  - No compiler warnings
  - No linter errors
  - Follows `shared-standards.md`
  - Uses AppTheme consistently
  - No hardcoded values
  
- [ ] Build and run
  - Clean build succeeds
  - App runs without crashes
  - Profile tab works
  - Photo upload works
  - Contact search works

---

## 28. PR Preparation

- [ ] Create PR description
  - Link to PRD: `MessageAI/docs/prds/pr-3-prd.md`
  - Link to TODO: `MessageAI/docs/todos/pr-3-todo.md`
  - Summary of changes
  - Screenshots of profile views
  - Test coverage report
  
- [ ] Verify with user before creating PR
  - Demo profile management
  - Demo photo upload
  - Demo contact search
  - Show test results
  
- [ ] Create PR
  - Target: develop branch
  - Title: "PR #3: User Profile Management & Contact System"
  - Fill out PR template
  - Request review

---

## Copyable Checklist (for PR description)

```markdown
## Checklist

- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] PhotoService implemented with compression + unit tests
- [ ] UserService extended with profile/search methods + tests
- [ ] ProfileViewModel and ContactListViewModel created + tests
- [ ] All views implemented (ProfileView, ProfileEditView, ContactListView)
- [ ] AvatarView component created and used throughout app
- [ ] Firebase Storage enabled and security rules deployed
- [ ] Firestore security rules updated for profile updates
- [ ] All UI tests pass (XCUITest)
- [ ] All unit tests pass (XCTest)
- [ ] Integration tests pass
- [ ] Security rules tests pass
- [ ] Performance tests meet targets (< 1s load, < 5s upload, < 500ms search)
- [ ] Profile tab integrated in MainTabView
- [ ] All acceptance gates from PRD verified
- [ ] Code follows shared-standards.md patterns
- [ ] No compiler warnings
- [ ] Documentation updated (README, architecture)
- [ ] Manual testing complete
```

---

## Notes

- Break tasks into < 30 min chunks
- Complete tasks sequentially
- Test after each service/component
- Use Firebase Emulator for local testing
- Reference `MessageAI/agents/shared-standards.md` for patterns
- Compress photos before upload (critical for performance)
- AvatarView is reusable - will be used in PR #4+ for chats
- ContactListView is foundation for PR #9 chat creation


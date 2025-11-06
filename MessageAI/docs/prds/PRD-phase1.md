# PRD: Phase 1 - Critical Bug Fixes

**Feature**: Contacts View Loading & Profile Photo Upload Fixes

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Parent PRD**: [PRD-fix.md](./PRD-fix.md)

---

## 1. Summary

Fix two critical P0 bugs blocking core user functionality: contacts list failing to load on initial view and profile photo upload not working. These bugs prevent users from accessing their contacts and personalizing their profiles, directly impacting first-time user experience and daily usage.

---

## 2. Problem & Goals

**Problem:** 
- Contacts view appears empty on first load; requires navigating away and back to see contacts
- Profile photo picker doesn't open reliably or selected photos don't save
- Both issues create significant friction in core user workflows

**Why now:** These are blocking bugs that impact user retention and satisfaction. They affect first impressions and essential functionality.

**Goals (ordered, measurable):**
- [ ] G1 - Contacts load successfully on first view 100% of the time
- [ ] G2 - Profile photo upload success rate reaches 100%
- [ ] G3 - Contacts appear within 2 seconds of tab open
- [ ] G4 - Profile photo updates persist after app restart

---

## 3. Non-Goals / Out of Scope

- [ ] Not adding new contact features (why: focus is fixing existing bug)
- [ ] Not redesigning profile view UI (why: tactical fix only)
- [ ] Not implementing group photos or video (why: out of scope)
- [ ] Not adding contact sync with external services (why: future feature)
- [ ] Not implementing photo filters or editing (why: unnecessary complexity)

---

## 4. Success Metrics

**User-visible:**
- Contacts view first-load success rate: 100% (currently failing)
- Profile photo upload success rate: 100% (currently broken)
- Contacts load time: <2s P95
- Photo upload time: <5s P95
- Photo picker opens within 500ms

**System:**
- Zero P0 blocking bugs in contacts/profile areas
- App launch time: <2-3s (maintained, not degraded)
- No new crashes introduced

**Quality:**
- 0 blocking bugs in release
- All test gates pass
- Crash-free rate >99%
- No regressions in existing features

---

## 5. Users & Stories

**Primary User: Mobile User**
- As a user, I want to see my contacts immediately when I open the Contacts tab so that I can start messaging
- As a user, I want to upload my profile photo so that my contacts can recognize me

---

## 6. Experience Specification (UX)

### Subphase 1.1: Contacts View Loading

**Entry Point:**
- User taps "Contacts" tab in main navigation bar

**Current Bug:**
- Contacts list appears empty
- Requires navigating to another tab and back to trigger load
- No loading indicator shown
- User doesn't know if contacts exist or if app is broken

**Fixed Behavior:**
1. User taps Contacts tab
2. Loading spinner appears immediately
3. Contacts fetch begins on view appearance
4. Contacts list populates within 2s
5. All contacts are immediately interactive

**States:**
- **Loading**: Spinner in center, "Loading contacts..." text
- **Loaded**: Full contacts list, scrollable, tappable
- **Empty**: "No contacts yet" message with "Find friends" button
- **Error**: "Failed to load contacts" with retry button

**Visual Specifications:**
- Loading spinner: System spinner, centered
- Empty state: Icon + message + CTA button
- Error state: Alert icon + message + "Try Again" button

---

### Subphase 1.2: Profile Photo Upload

**Entry Point:**
- User taps profile photo circle in Profile view
- Option: "Change Photo" or "Upload Photo" appears

**Current Bug:**
- Photo picker may not open
- Selected photo doesn't save
- No upload progress shown
- Photo doesn't persist after restart

**Fixed Behavior:**
1. User taps profile photo
2. Action sheet appears: "Take Photo" / "Choose from Library" / "Cancel"
3. Photo picker opens reliably
4. User selects photo
5. Upload progress indicator appears
6. Photo uploads to Firebase Storage
7. Profile updates with new photo URL
8. UI updates immediately with new photo
9. Photo persists after app restart

**States:**
- **Idle**: Current photo or placeholder shown
- **Selecting**: Photo picker modal open
- **Uploading**: Progress bar/spinner with "%"
- **Success**: New photo displayed, brief success animation
- **Error**: Alert with error message and retry option

**Visual Specifications:**
- Photo picker: System PHPickerViewController
- Progress: Circular progress indicator over photo
- Success: Subtle scale animation or checkmark
- Error: Alert with specific error message

---

## 7. Functional Requirements (Must/Should)

### Subphase 1.1: Contacts View

**MUST:**
- MUST: Load contacts on initial view appearance (onAppear)
- MUST: Display loading state while fetching
- MUST: Enable interaction immediately after load completes
- MUST: Handle empty state gracefully with helpful message
- MUST: Show error state with retry button if fetch fails
- MUST: Retry successfully after error
- MUST: Complete load within 2s under normal network conditions

**SHOULD:**
- SHOULD: Cache contacts locally for offline viewing
- SHOULD: Pull-to-refresh functionality
- SHOULD: Log fetch failures for debugging

---

### Subphase 1.2: Profile Photos

**MUST:**
- MUST: Open photo picker reliably on all devices (iPhone, iPad)
- MUST: Support both camera and photo library
- MUST: Upload photo to Firebase Storage at `/users/{userID}/profile.jpg`
- MUST: Update user profile with photo URL in Firestore
- MUST: Show upload progress (percentage)
- MUST: Handle upload failures with specific error messages
- MUST: Provide retry option on failure
- MUST: Update UI optimistically with local preview
- MUST: Compress large photos (>10MB) before upload
- MUST: Maintain aspect ratio and quality
- MUST: Request photo library permissions properly

**SHOULD:**
- SHOULD: Support photo deletion/removal
- SHOULD: Cache uploaded photos locally
- SHOULD: Show photo in contacts list after upload
- SHOULD: Log upload errors with context

---

## 8. Data Model

### Contacts View

```swift
// ContactListViewModel.swift
class ContactListViewModel: ObservableObject {
    @Published var contacts: [User] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var isEmpty: Bool = false
    
    enum LoadingState {
        case idle
        case loading
        case loaded
        case empty
        case error(Error)
    }
    
    @Published var loadingState: LoadingState = .idle
}
```

### Profile Photo

```swift
// User model (already exists, ensure proper handling)
struct User: Identifiable, Codable {
    var id: String
    var displayName: String
    var email: String
    var photoURL: String?  // Must be properly saved and loaded
    var phoneNumber: String?
    // ... existing fields
}

// ProfileViewModel additions
class ProfileViewModel: ObservableObject {
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading: Bool = false
    @Published var uploadError: Error?
    
    enum PhotoUploadState {
        case idle
        case selecting
        case uploading(progress: Double)
        case success
        case error(Error)
    }
    
    @Published var photoUploadState: PhotoUploadState = .idle
}
```

**Firestore Schema:**
```
users/{userID}
  - displayName: String
  - email: String
  - photoURL: String (NEW or ensure working)
  - phoneNumber: String
  - createdAt: Timestamp
  - updatedAt: Timestamp
```

**Firebase Storage Path:**
```
users/{userID}/profile.jpg
```

---

## 9. API / Service Contracts

### UserService Updates

```swift
class UserService {
    // MUST: Ensure this works on first call
    func fetchContacts() async throws -> [User] {
        // Implementation: Query Firestore for user's contacts
        // Return: Array of User objects
        // Errors: NetworkError, FirestoreError
    }
    
    // MUST: Handle errors gracefully
    func refreshContacts() async throws -> [User] {
        // Force refresh from server
    }
}
```

**Pre-conditions:**
- User is authenticated
- User has network connection (or cached data)

**Post-conditions:**
- Contacts array populated
- Loading state updated
- UI reflects current contacts

**Error Handling:**
- NetworkError: Show retry, use cached data if available
- AuthenticationError: Redirect to login
- FirestoreError: Log error, show user-friendly message

---

### PhotoService Updates

```swift
class PhotoService {
    // MUST: Work reliably on all devices
    func selectPhoto() async throws -> UIImage {
        // Present PHPickerViewController
        // Return: Selected UIImage
        // Errors: PermissionError, CancelledError
    }
    
    // MUST: Handle large photos
    func compressPhoto(_ image: UIImage, maxSizeMB: Int = 10) -> UIImage {
        // Compress to target size while maintaining quality
    }
    
    // MUST: Show progress
    func uploadPhoto(_ image: UIImage, for userID: String) async throws -> String {
        // Upload to Firebase Storage
        // Return: Download URL
        // Errors: NetworkError, StorageError
    }
    
    // MUST: Update atomically
    func updateUserPhoto(userID: String, photoURL: String) async throws {
        // Update Firestore user document
    }
    
    // SHOULD: Support deletion
    func deletePhoto(for userID: String) async throws {
        // Delete from Storage and update Firestore
    }
}
```

**Pre-conditions:**
- User is authenticated
- User has granted photo library permissions
- Photo is valid image format (JPEG, PNG, HEIC)

**Post-conditions:**
- Photo uploaded to Storage
- User profile updated in Firestore
- UI shows new photo
- Photo persists across sessions

**Error Handling:**
- PermissionError: Show settings alert to enable permissions
- NetworkError: Show retry with cached local image
- StorageError: Show error with details and retry option
- CompressionError: Show error, suggest smaller photo

---

### ContactListViewModel Fix

```swift
class ContactListViewModel: ObservableObject {
    @Published var contacts: [User] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let userService: UserService
    
    // MUST: Call this in onAppear
    func loadContacts() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            contacts = try await userService.fetchContacts()
        } catch {
            self.error = error
            print("Error loading contacts: \(error)")
        }
    }
    
    // MUST: Support retry
    func retry() async {
        await loadContacts()
    }
}
```

---

### ProfileViewModel Fix

```swift
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadError: Error?
    
    private let photoService: PhotoService
    private let userService: UserService
    
    // MUST: Reliable photo upload flow
    func uploadProfilePhoto() async {
        do {
            // Select photo
            let image = try await photoService.selectPhoto()
            
            // Update UI optimistically
            isUploading = true
            uploadError = nil
            
            // Compress if needed
            let compressed = photoService.compressPhoto(image)
            
            // Upload with progress
            let photoURL = try await photoService.uploadPhoto(
                compressed,
                for: user?.id ?? ""
            )
            
            // Update user profile
            try await photoService.updateUserPhoto(
                userID: user?.id ?? "",
                photoURL: photoURL
            )
            
            // Update local user object
            user?.photoURL = photoURL
            
            isUploading = false
            
        } catch {
            uploadError = error
            isUploading = false
            print("Error uploading photo: \(error)")
        }
    }
}
```

---

## 10. UI Components to Create/Modify

### Subphase 1.1: Contacts View

**Modify:**
- `Views/Main/ContactListView.swift`
  - Add `.onAppear { Task { await viewModel.loadContacts() } }`
  - Add loading state UI
  - Add empty state UI
  - Add error state UI with retry

- `ViewModels/ContactListViewModel.swift`
  - Fix `loadContacts()` to work on first call
  - Add proper state management
  - Add error handling

**Key ContactListView.swift changes:**

```swift
struct ContactListView: View {
    @StateObject private var viewModel = ContactListViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading contacts...")
            } else if viewModel.contacts.isEmpty {
                emptyStateView
            } else if let error = viewModel.error {
                errorView(error)
            } else {
                contactsList
            }
        }
        .onAppear {
            Task { await viewModel.loadContacts() }
        }
    }
    // ... loading, empty, and error state views
}
```

---

### Subphase 1.2: Profile Photo

**Modify:**
- `Views/Profile/ProfileView.swift`
  - Add photo picker presentation
  - Add upload progress indicator
  - Add error handling alerts

- `ViewModels/ProfileViewModel.swift`
  - Implement `uploadProfilePhoto()`
  - Add progress tracking
  - Add error handling

- `Services/PhotoService.swift`
  - Ensure `selectPhoto()` works reliably
  - Implement compression
  - Add upload progress callback

**Key ProfileView.swift changes:**

```swift
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingPhotoOptions = false
    
    var body: some View {
        VStack {
            ZStack {
                // Profile photo or placeholder
                profilePhotoView
                
                // Upload progress overlay
                if viewModel.isUploading {
                    ProgressView()
                }
            }
            .onTapGesture { showingPhotoOptions = true }
        }
        .confirmationDialog("Profile Photo", isPresented: $showingPhotoOptions) {
            Button("Take Photo") { /* open camera */ }
            Button("Choose from Library") { /* open picker */ }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                Task { await viewModel.uploadProfilePhoto(image) }
            }
        }
        // ... error handling
    }
}
```

---

## 11. Integration Points

**Firebase Services:**
- Firestore: User profiles, contacts queries
- Firebase Storage: Photo uploads
- Firebase Authentication: User authentication state

**iOS Frameworks:**
- PhotosUI: PHPickerViewController
- UIKit: UIImagePickerController (for camera)
- SwiftUI: State management, async/await

**Permissions:**
- Photo Library Access
- Camera Access (optional for camera support)

**Error States:**
- Network connectivity
- Firebase service errors
- Permission denials
- Concurrent operations

---

## 12. Acceptance Gates

### Contacts View
- [ ] Open Contacts tab → Contacts appear within 2s
- [ ] Loading spinner shows while fetching
- [ ] Contacts are immediately interactive (no delay)
- [ ] Empty state shows when no contacts exist
- [ ] Error state shows with retry button (test in airplane mode)
- [ ] Retry successfully loads contacts
- [ ] Navigate away and back → Contacts still visible

### Profile Photo
- [ ] Tap profile photo → Options appear
- [ ] Select "Choose from Library" → Picker opens reliably
- [ ] Select photo → Upload shows progress indicator
- [ ] Upload completes → Photo updates immediately
- [ ] Photo persists after app restart
- [ ] Large photos (>10MB) compress before upload
- [ ] Upload failure → Error message with retry
- [ ] Works on iPhone 17 simulator
- [ ] Photo appears in other users' contact lists

---

## 13. Definition of Done

- [ ] All acceptance gates pass
- [ ] Tested on iPhone 17 simulator
- [ ] Tested in light and dark mode
- [ ] No new linter errors
- [ ] No crashes or performance regressions
- [ ] Error messages are clear and user-friendly

---

## 14. Risks & Mitigations

**Performance regression from contacts fix**
- Mitigation: Test with 1000+ contacts, implement lazy loading if needed

**Photo upload works in testing but fails in production**
- Mitigation: Extensive device testing, detailed error logging

**Breaking existing functionality**
- Mitigation: Comprehensive regression testing

**Firebase Storage rules block uploads**
- Mitigation: Verify Storage rules before deployment

---

## 15. Success Tracking

**Key Metrics:**
- Contacts first-load success rate: 100%
- Profile photo upload success rate: 100%
- Contacts load time: <2s
- Photo upload time: <5s

**Monitor:**
- Error logs and rates
- User feedback
- App Store reviews

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-06 | 1.0 | Phase 1 extracted from PRD-fix.md | Pete (AI Agent) |


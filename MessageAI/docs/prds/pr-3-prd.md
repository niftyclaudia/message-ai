# PRD: User Profile Management & Contact System

**Feature**: Profile Management & Contact Discovery

**Version**: 1.0

**Status**: COMPLETED

**Agent**: Pete

**Target Release**: Phase 1 - Foundation

**Links**: [PR Brief #3](../pr-brief/pr-briefs.md#pr-3-user-profile-management--contact-system)

---

## 1. Summary

Implement user profile management with viewing, editing, photo upload via Firebase Storage, and contact discovery system. Extends PR #1's User model with full CRUD UI and search capabilities for PR #4+ messaging features.

---

## 2. Problem & Goals

**Problem**: Users need to manage profiles, upload photos, and discover contacts to start conversations.

**Why Now**: Depends on PR #1 (UserService) and PR #2 (navigation). Required by PR #4 (Chat List) and PR #9 (Chat Creation).

**Goals**:
- [ ] G1 — View own profile with all details
- [ ] G2 — Edit display name and profile info
- [ ] G3 — Upload/update profile photos via Firebase Storage
- [ ] G4 — Search users by name or email
- [ ] G5 — Foundation ready for contact selection (PR #9)

---

## 3. Non-Goals / Out of Scope

- Chat creation flows (PR #9)
- View other users' detailed profiles (future)
- Block/report, contact sync, friend requests (future)
- Privacy settings, status messages, custom themes (future)

---

## 4. Success Metrics

**Performance** (see `shared-standards.md`):
- Profile load: < 1s
- Photo upload: < 5s (2MB)
- Profile edit save: < 2s
- Contact search: < 500ms
- Smooth 60fps scrolling

**Quality**:
- 0 blocking bugs
- All acceptance gates pass
- Photo upload handles large images gracefully
- Test coverage > 80%

---

## 5. Users & Stories

- As a user, I want to complete my profile so others can identify me
- As a user, I want to upload a profile photo so my chats are personalized
- As a user, I want to search for other users by name/email to start conversations
- As a developer (PR #9), I want a contact list component for chat creation
- As a user, I want my photo to appear everywhere in the app

---

## 6. Experience Specification (UX)

**Profile View**:
- Large circular avatar (120pt), display name, email, member since date
- "Edit Profile" button → Navigate to ProfileEditView
- Default avatar shows user initials if no photo

**Profile Edit**:
- Tap avatar → System photo picker
- Edit display name (1-50 chars with counter)
- Save/Cancel buttons
- Photo upload shows progress bar
- Validation errors displayed inline

**Contact List**:
- Search bar at top ("Search by name or email")
- Scrollable list: 40pt avatar, name, email
- Real-time updates when new users join
- Empty state: "No users found"

**States**: Loading (skeleton), uploading (progress), error (alert with retry), empty (default avatar with initials)

---

## 7. Functional Requirements

### MUST

**Profile**:
- [ ] Display current user profile (avatar, name, email, member since)
- [ ] Edit display name (1-50 chars validation)
- [ ] Upload photos to Storage: `profile_photos/{userID}/{timestamp}.jpg`
- [ ] Compress photos (10MB → 2MB max before upload)
- [ ] Update Firestore after successful upload
- [ ] Delete old photo when uploading new one
- [ ] Show upload progress indicator
- [ ] Atomic updates: Photo URL only after upload succeeds

**Contact Discovery**:
- [ ] Display all users in searchable list (exclude current user)
- [ ] Search by name/email (case-insensitive partial match)
- [ ] Real-time updates when new users join
- [ ] Display avatars in results
- [ ] Handle empty results state

**Services**:
- [ ] Extend UserService with profile/search methods
- [ ] Create PhotoService for Storage operations
- [ ] Validation before Firebase calls
- [ ] Typed errors with user-friendly messages
- [ ] Optimistic UI for updates

### Acceptance Gates

**Profile View**:
- [Gate] Navigate to profile → Loads in < 1s
- [Gate] No photo → Shows initials avatar
- [Gate] Tap "Edit" → Opens ProfileEditView

**Profile Edit**:
- [Gate] Save valid name → Updates Firestore < 2s, navigates back
- [Gate] Save invalid name → Shows error, stays on edit view
- [Gate] Cancel → Discards changes without save
- [Gate] Tap avatar → Opens photo picker

**Photo Upload**:
- [Gate] Upload succeeds → Photo appears everywhere < 5s
- [Gate] Upload 10MB image → Compresses to ~2MB first
- [Gate] Upload fails → Shows retry alert, no Firestore update
- [Gate] Upload new photo → Deletes old photo from Storage
- [Gate] Network error → Proper error message, rollback state

**Contact Search**:
- [Gate] Open list → Shows all users except self
- [Gate] Type in search → Results filter real-time
- [Gate] Search "john" → Matches "John Doe" and "johnny@example.com"
- [Gate] No results → Shows "No users found"
- [Gate] New user signs up → Appears in list < 2s
- [Gate] Scroll 100+ contacts → Smooth 60fps

---

## 8. Data Model

### Firestore (extends PR #1)

**Collection**: `users`

```swift
struct User: Codable, Identifiable, Equatable {
    let id: String              // Firebase Auth UID
    var displayName: String     // 1-50 chars
    var email: String           // Immutable
    var profilePhotoURL: String?  // Firebase Storage URL
    var createdAt: Date
    var lastActiveAt: Date
    
    var initials: String { /* "John Doe" -> "JD" */ }
    var memberSinceFormatted: String { /* "Member since Jan 2025" */ }
}
```

### Firebase Storage

**Path**: `profile_photos/{userID}/{timestamp}.jpg`

**Rules**: Users write own folder only, max 10MB, image types only

### Security Rules

**Firestore**:
```javascript
match /users/{userID} {
  allow read: if isAuthenticated();
  allow update: if isAuthenticated() && isOwner(userID) 
    && validDisplayName() && !modifyingImmutableFields();
}
```

**Storage**:
```javascript
match /profile_photos/{userID}/{fileName} {
  allow read: if isAuthenticated();
  allow write: if isAuthenticated() && request.auth.uid == userID
    && request.resource.size < 10MB && isImage();
}
```

---

## 9. API / Service Contracts

### UserService Extensions

```swift
// NEW methods
func updateDisplayName(userID: String, displayName: String) async throws
func updateProfilePhoto(userID: String, photoURL: String) async throws
func fetchAllUsers() async throws -> [User]
func searchUsers(query: String) async throws -> [User]
func observeUsers(completion: @escaping ([User]) -> Void) -> ListenerRegistration
```

### PhotoService (NEW)

```swift
class PhotoService {
    func uploadProfilePhoto(image: UIImage, userID: String, 
                          progressHandler: @escaping (Double) -> Void) async throws -> String
    func deleteProfilePhoto(photoURL: String) async throws
    func compressImage(image: UIImage, maxSizeBytes: Int) -> Data?
}
```

### ViewModels (NEW)

```swift
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func loadProfile() async
    func updateProfile(displayName: String) async throws
    func uploadProfilePhoto(image: UIImage) async throws
}

class ContactListViewModel: ObservableObject {
    @Published var allUsers: [User] = []
    @Published var filteredUsers: [User] = []
    @Published var searchQuery: String = ""
    
    func loadUsers() async
    func searchUsers(query: String)
    func observeUsersRealTime()
}
```

### Error Types

```swift
enum PhotoServiceError: LocalizedError {
    case imageCompressionFailed, uploadFailed(Error), deleteFailed(Error)
    case invalidImageData, fileSizeTooLarge, invalidURL, unknown(Error)
}

enum UserServiceError: LocalizedError {
    // Existing from PR #1
    case invalidDisplayName, notFound, permissionDenied, networkError
    // NEW
    case displayNameTooShort, displayNameTooLong, searchQueryTooShort
}
```

---

## 10. UI Components to Create/Modify

### Create New

**Views/Profile/**:
- `ProfileView.swift` — Display profile
- `ProfileEditView.swift` — Edit name/upload photo
- `ContactListView.swift` — Search users

**Views/Components/**:
- `AvatarView.swift` — Reusable avatar (image or initials)
- `PhotoPicker.swift` — Photo picker wrapper
- `ProfilePhotoView.swift` — Avatar with camera icon
- `UserRowView.swift` — User row for contact list

**Services/**:
- `PhotoService.swift` — Storage operations

**ViewModels/**:
- `ProfileViewModel.swift` — Profile logic
- `ContactListViewModel.swift` — Contact search logic

**Utilities/**:
- `Extensions/UIImage+Extensions.swift` — Image compression
- `Extensions/String+Extensions.swift` — Initials extraction
- `Errors/PhotoServiceError.swift` — Error types

### Modify Existing

- `Services/UserService.swift` — Add profile/search methods
- `Models/User.swift` — Add computed properties
- `Views/Main/MainTabView.swift` — Add profile tab
- `Utilities/Constants.swift` — Add Storage paths

---

## 11. Integration Points

**From PR #1**: UserService, User model, AuthService, FirebaseService  
**From PR #2**: MainTabView, AppTheme, navigation, reusable components  
**Firebase**: Storage (photos), Firestore (user updates), Listeners (real-time)  
**For Future**: PR #4 (AvatarView in chats), PR #9 (ContactListView for chat creation)

---

## 12. Test Plan & Acceptance Gates

Reference `MessageAI/agents/shared-standards.md` for patterns.

### Unit Tests (XCTest)

**UserService** (`MessageAITests/Services/UserServiceTests.swift`):
- [ ] testUpdateDisplayName_ValidName_Updates → Firestore updated < 2s
- [ ] testUpdateDisplayName_Invalid_ThrowsError → Validation before call
- [ ] testFetchAllUsers_ExcludesCurrent → Returns all except self
- [ ] testSearchUsers_PartialMatch_ReturnsMatches → "john" matches "Johnny"
- [ ] testObserveUsers_NewUser_ReceivesUpdate → Real-time listener works

**PhotoService** (`MessageAITests/Services/PhotoServiceTests.swift`):
- [ ] testUploadPhoto_ValidImage_Succeeds → Upload < 5s, returns URL
- [ ] testUploadPhoto_LargeImage_Compresses → 10MB → 2MB
- [ ] testDeletePhoto_ValidURL_Deletes → Photo removed from Storage
- [ ] testCompressImage_ReturnsTargetSize → Compressed < 2MB
- [ ] testUploadProgress_Reports → Progress 0.0 to 1.0

**ViewModels** (`MessageAITests/ViewModels/`):
- [ ] testProfileViewModel_LoadProfile → user populated
- [ ] testProfileViewModel_UpdateProfile → Calls UserService
- [ ] testProfileViewModel_UploadPhoto → PhotoService → UserService sequence
- [ ] testContactListViewModel_Search → filteredUsers correct
- [ ] testContactListViewModel_RealTime → New users appear

### UI Tests (XCUITest)

**Profile Flow** (`MessageAIUITests/ProfileFlowUITests.swift`):
- [ ] testProfileView_Loads → Shows avatar, name, email
- [ ] testProfileView_NoPhoto → Shows initials
- [ ] testProfileEdit_ChangeNameSave → Persists
- [ ] testProfileEdit_Cancel → Discards changes
- [ ] testProfileEdit_UploadPhoto → Progress shown, photo appears

**Contact Discovery** (`MessageAIUITests/ContactDiscoveryUITests.swift`):
- [ ] testContactList_Loads → Shows all users except self
- [ ] testContactList_Search → Filters real-time
- [ ] testContactList_NoResults → Empty state
- [ ] testContactList_ScrollPerformance → Smooth 60fps

### Integration Tests

**Profile Integration** (`MessageAITests/Integration/ProfileIntegrationTests.swift`):
- [ ] testUploadPhoto_UpdatesStorageAndFirestore → Photo + URL synced
- [ ] testProfilePhotoSync_AppearsEverywhere → AvatarView updates

**Security Rules** (`MessageAITests/Integration/SecurityRulesTests.swift`):
- [ ] testSecurityRules_UserUpdatesOwn → Succeeds
- [ ] testSecurityRules_UserCannotUpdateOther → Fails
- [ ] testSecurityRules_PhotoToOwnFolder → Succeeds
- [ ] testSecurityRules_PhotoToOtherFolder → Fails

### Performance Tests

- [ ] testProfileLoad_Under1s → < 1s
- [ ] testPhotoUpload_Under5s → < 5s
- [ ] testPhotoCompression_Fast → < 2s
- [ ] testContactSearch_Under500ms → < 500ms
- [ ] testContactScroll_60fps → Smooth

---

## 13. Definition of Done

**Code**:
- [ ] All services, view models, views implemented
- [ ] All components created (AvatarView, PhotoPicker, UserRowView)
- [ ] Error types with user-friendly messages
- [ ] Image compression utility

**Firebase**:
- [ ] Storage enabled, security rules deployed
- [ ] Firestore rules updated
- [ ] Tested with emulator

**Testing**:
- [ ] All unit tests pass
- [ ] All UI tests pass
- [ ] Integration tests pass
- [ ] Security rules tests pass
- [ ] Performance tests meet targets
- [ ] Coverage > 80%

**Integration**:
- [ ] Profile tab in MainTabView
- [ ] AvatarView used throughout app
- [ ] Photo URLs display correctly
- [ ] Real-time updates working
- [ ] Offline mode: View profile, edits queue

**Quality**:
- [ ] No compiler warnings
- [ ] Follows `shared-standards.md`
- [ ] Uses AppTheme consistently
- [ ] No hardcoded values
- [ ] Proper async/await
- [ ] No memory leaks

**Documentation**:
- [ ] Code comments for complex logic
- [ ] Service methods documented
- [ ] README updated
- [ ] Architecture doc updated

---

## 14. Risks & Mitigations

- **Risk**: Photo upload failures → **Mitigation**: Retry logic, rollback on failure
- **Risk**: Large photos slow performance → **Mitigation**: 2MB compression
- **Risk**: Storage costs → **Mitigation**: Delete old photos, one photo limit
- **Risk**: Race condition (upload vs update) → **Mitigation**: Upload first, then update URL
- **Risk**: Search performance → **Mitigation**: Firestore indexes, client filtering
- **Risk**: Broken photo URLs → **Mitigation**: Fallback to default avatar
- **Risk**: Memory issues → **Mitigation**: Aggressive compression, dispose after upload

---

## 15. Open Questions

- Q1: Image cropping? → A: Auto center-crop to square
- Q2: Photo caching? → A: AsyncImage handles it
- Q3: Photo resolution? → A: Store 400x400, display at 120pt/40pt
- Q4: Contact pagination? → A: No, load all (< 10k users)
- Q5: Default avatar? → A: Initials with pastel background

---

## Authoring Notes

- Profile foundation for all messaging features
- Photo management critical for user identification
- Contact discovery enables chat creation (PR #9)
- AvatarView reused throughout app
- Clean separation: Views → ViewModels → Services → Firebase
- References `shared-standards.md` throughout

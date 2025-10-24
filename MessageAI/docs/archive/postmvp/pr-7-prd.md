# PRD: Authentication & Data Management Polish

**Feature**: Authentication & Data Management Polish

**Version**: 1.0

**Status**: Draft

**Agent**: Pete

**Target Release**: Phase 2

**Links**: [PR Brief: PR #7](../pr-brief/pr-briefs.md), [TODO: Coming Next], [Tracking Issue]

---

## 1. Summary

Complete and polish authentication flow by adding password reset functionality, verify comprehensive sync logic and offline cache, and add multi-device sync testing to ensure consistent user experience across all devices.

---

## 2. Problem & Goals

- **What user problem are we solving?** Users need complete authentication capabilities (including password recovery), reliable data sync across devices, and confidence that their data persists correctly offline. Currently missing password reset could leave users locked out of accounts, and sync/cache logic needs verification for bulletproof user management.

- **Why now?** Phase 2 is the technical excellence phase - perfect time to polish auth and data management before Phase 3 AI features. Building on PR #6's security foundation, this PR ensures users never lose access to their accounts and their data remains consistent across all devices.

- **Goals (ordered, measurable):**
  - [ ] G1 — Complete authentication flow with password reset (users can recover accounts)
  - [ ] G2 — Verify and document sync logic for multi-device scenarios (< 1s sync time)
  - [ ] G3 — Verify offline cache persists correctly (force-quit → reopen with full history)
  - [ ] G4 — Create multi-device sync tests (2+ devices sync < 100ms)

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing biometric authentication (Face ID/Touch ID) - deferred to future PR
- [ ] Not adding email verification flow - deferred to future PR
- [ ] Not implementing multi-factor authentication (MFA) - deferred to future PR
- [ ] Not changing existing auth UI design - only adding password reset screens
- [ ] Not refactoring sync architecture - only verifying and testing

---

## 4. Success Metrics

**User-visible:**
- Password reset flow completion time < 2 minutes (click reset → receive email → set new password → sign in)
- Profile editing save time < 3 seconds
- Multi-device sync perceived instantly (< 200ms)

**System:**
- Password reset email delivery < 30 seconds
- Sync propagation across devices < 100ms (shared-standards.md target)
- Offline cache persists through force-quit and app relaunch
- Profile photo upload < 5 seconds for images < 5MB

**Quality:**
- 0 data loss scenarios in multi-device testing
- All acceptance gates pass
- Test coverage for all auth and sync scenarios
- Crash-free rate >99%

---

## 5. Users & Stories

- As a **user who forgot password**, I want to reset my password via email so that I can regain access to my account.
- As a **multi-device user**, I want my profile changes to sync instantly so that I see the same profile across all devices.
- As a **offline user**, I want my data cached locally so that I can access conversations after force-quitting or restarting the app.
- As a **user editing profile**, I want to change my name and avatar so that my identity is accurate and current.
- As a **user with poor connectivity**, I want sync to complete quickly when I reconnect so that I don't wait long for updates.

---

## 6. Experience Specification (UX)

### Entry Points & Flows

**Password Reset Flow:**
1. Login screen → "Forgot Password?" link
2. Enter email → Tap "Send Reset Link"
3. Firebase sends password reset email
4. User clicks email link → Opens Safari/browser
5. User sets new password in Firebase web form
6. Returns to app → Signs in with new password

**Profile Edit Flow (Existing):**
1. Profile screen → "Edit Profile" button
2. Tap avatar → Photo picker → Select image
3. Edit display name → Character counter updates
4. Tap "Save" → Upload progress shown
5. Dismiss on success → Profile screen refreshes

**Multi-Device Sync Flow:**
1. Device A: Update profile name
2. Device B: Profile name updates automatically < 100ms
3. Device A: Send message while Device B offline
4. Device B: Comes online → Sees message < 1s

### Visual Behavior

**Password Reset Screen:**
- Text field for email (pre-filled if came from failed login)
- Primary button: "Send Reset Link"
- Secondary button: "Back to Login"
- Success state: "Check your email for reset instructions"
- Loading state: Button shows spinner, disabled
- Error state: Alert with user-friendly message

**Profile Edit (Existing):**
- Avatar with camera icon overlay
- Display name field with character counter (1-50 chars)
- Save/Cancel buttons in navigation bar
- Upload progress overlay with percentage
- Success: Dismiss sheet
- Error: Alert with retry option

### Loading/Disabled/Error States

**Password Reset:**
- Loading: Button disabled with spinner while sending email
- Success: Green checkmark + "Email sent!" message
- Error: Red alert with specific message ("Email not found", "Network error", etc.)
- Disabled: Button disabled if email field empty or invalid

**Profile Edit:**
- Loading: Full-screen overlay with progress bar during photo upload
- Success: Sheet dismisses, profile view refreshes
- Error: Alert with specific message and retry option
- Disabled: Save button disabled if name < 1 or > 50 characters

**Sync States (in ChatList):**
- Connecting: Status indicator shows "Connecting..."
- Syncing: "Syncing X messages..."
- Online: Green dot, no status text
- Offline: Red dot, "Offline"

### Performance

Reference targets from `MessageAI/agents/secondagent/shared-standards.md`:
- **Password reset email**: < 30 seconds to receive
- **Profile update save**: < 2 seconds
- **Profile photo upload**: < 5 seconds (images < 5MB)
- **Multi-device sync**: < 100ms propagation
- **Offline cache load**: < 500ms on app restart
- **UI responsiveness**: All taps < 50ms feedback

---

## 7. Functional Requirements (Must/Should)

### Password Reset (NEW)
- **MUST**: Add "Forgot Password?" link on LoginView
- **MUST**: Create ForgotPasswordView with email input field
- **MUST**: Integrate Firebase password reset email (`Auth.auth().sendPasswordReset(withEmail:)`)
- **MUST**: Show success state: "Check your email for reset instructions"
- **MUST**: Handle errors: invalid email, email not found, network error
- **MUST**: Email validation before calling Firebase
- **MUST**: Add navigation from LoginView to ForgotPasswordView
- **SHOULD**: Pre-fill email field if user failed to login with specific email

**Acceptance gates:**
- [Gate] User taps "Forgot Password?" → ForgotPasswordView appears
- [Gate] User enters invalid email → Shows validation error before Firebase call
- [Gate] User enters valid email → Firebase sends reset email in < 30s
- [Gate] User enters non-existent email → Shows "No account found with this email"
- [Gate] User offline → Shows "Network error, please check connection"
- [Gate] Success state shows → User can navigate back to login
- [Gate] User receives email → Can click link, reset password in browser
- [Gate] User sets new password → Can sign in with new password in app

### Profile Editing (VERIFY EXISTING)
- **MUST**: Verify ProfileEditView allows name changes (1-50 characters)
- **MUST**: Verify ProfileEditView allows avatar upload via PhotoPicker
- **MUST**: Verify photo upload to Firebase Storage works
- **MUST**: Verify photo URL saved to Firestore user document
- **MUST**: Verify UserService.updateUser() updates name and photo correctly
- **MUST**: Verify character counter shows X/50 and validates correctly
- **SHOULD**: Add loading indicator during photo upload

**Acceptance gates:**
- [Gate] User taps "Edit Profile" → ProfileEditView appears with current data
- [Gate] User changes name → Character counter updates in real-time
- [Gate] User enters name < 1 or > 50 chars → Save button disabled
- [Gate] User taps avatar → Photo picker appears
- [Gate] User selects photo → Upload progress shown → Completes in < 5s
- [Gate] User taps Save → Changes persist to Firestore in < 2s
- [Gate] User returns to Profile → Name and avatar reflect changes
- [Gate] Second device → Profile updates appear < 100ms

### Sync Logic (VERIFY EXISTING)
- **MUST**: Verify SyncService.syncOfflineMessages() syncs queued messages
- **MUST**: Verify multi-device presence updates < 500ms (PresenceService)
- **MUST**: Verify profile changes sync across devices < 100ms
- **MUST**: Verify message sync across devices < 100ms (from PR #1)
- **MUST**: Verify OfflineMessageService persists messages through app restart
- **MUST**: Document sync behavior in tests and comments
- **SHOULD**: Add retry logic for failed sync operations

**Acceptance gates:**
- [Gate] Device A sends message while Device B offline → Device B receives on reconnect in < 1s
- [Gate] Device A updates profile → Device B sees update in < 100ms
- [Gate] Device A goes offline, sends 3 messages → Reconnects → Messages sync successfully
- [Gate] Device A and B online → Device A updates presence → Device B sees change < 500ms
- [Gate] Network drops during sync → Auto-retry succeeds after reconnect

### Offline Cache (VERIFY EXISTING)
- **MUST**: Verify OfflineMessageService persists messages via UserDefaults
- **MUST**: Verify force-quit → reopen preserves full message history
- **MUST**: Verify Firestore offline persistence enabled
- **MUST**: Verify chat list loads from cache on app start
- **MUST**: Verify messages load from cache while fetching updates
- **SHOULD**: Add cache size limit and cleanup for old messages

**Acceptance gates:**
- [Gate] User force-quits app → Reopens → Full chat list appears from cache < 500ms
- [Gate] User offline, views chat → Messages load from cache
- [Gate] User offline, sends 3 messages → Force quits → Reopens → Messages still in queue
- [Gate] User has 1000+ messages → App loads smoothly with cache
- [Gate] Cache exceeds limit → Old messages pruned automatically

### Multi-Device Sync Testing (NEW)
- **MUST**: Create automated multi-device sync tests (simulated 2+ devices)
- **MUST**: Test profile name sync across devices
- **MUST**: Test profile photo sync across devices
- **MUST**: Test presence sync across devices
- **MUST**: Test message delivery across devices (from PR #1)
- **MUST**: Verify sync completes < 100ms

**Acceptance gates:**
- [Gate] Test: Device 1 updates name → Device 2 fetches updated name within 100ms
- [Gate] Test: Device 1 uploads photo → Device 2 fetches updated photo URL within 100ms
- [Gate] Test: Device 1 goes online → Device 2 sees presence change < 500ms
- [Gate] Test: Device 1 sends message → Device 2 receives message < 100ms
- [Gate] All multi-device tests pass in CI/local runs

---

## 8. Data Model

### User Document (Firestore) - NO CHANGES

Existing schema already supports this PR:

```swift
{
  id: String,                    // Firebase Auth UID
  displayName: String,           // 1-50 characters
  email: String,                 // User's email
  profilePhotoURL: String?,      // Firebase Storage URL (optional)
  createdAt: Timestamp,          // Server timestamp
  lastActiveAt: Timestamp        // Updated on actions
}
```

**Validation rules:**
- `displayName`: 1-50 characters (Constants.Validation.displayNameMinLength/MaxLength)
- `email`: Valid email format (Constants.Validation.emailPattern)
- `profilePhotoURL`: Valid HTTPS URL from Firebase Storage
- All fields validated in UserService before Firestore writes

**Security rules (from PR #6):**
- Users can read all user documents (for contact discovery)
- Users can only write/update their own document
- Authentication required for all operations

### OfflineMessage (UserDefaults) - NO CHANGES

Existing model already supports sync:

```swift
{
  id: String,
  chatID: String,
  text: String,
  senderID: String,
  timestamp: Date,
  status: MessageStatus,  // .queued, .sending, .sent, .failed
  retryCount: Int
}
```

**Storage:**
- Persisted via UserDefaults per user (`offline_messages_{userID}`)
- Max 3 messages in queue (OfflineMessageService.maxQueueSize)
- Automatically removed after successful sync

---

## 9. API / Service Contracts

### AuthService (ADDITIONS)

```swift
/// Sends password reset email to user
/// - Parameter email: User's email address
/// - Throws: AuthError for validation or Firebase errors
/// - Performance: Should complete in < 2 seconds
/// - Note: Uses Firebase Auth sendPasswordReset()
func sendPasswordResetEmail(email: String) async throws

/// Validates email format (existing private method, may need to be public)
/// - Parameter email: Email to validate
/// - Throws: AuthError.invalidEmail if format is invalid
func validateEmail(_ email: String) throws
```

**Pre/post-conditions:**
- Pre: Email must be valid format
- Post: Firebase sends reset email if account exists
- Error: Throws AuthError.invalidEmail, .userNotFound, or .networkError

### UserService (VERIFY EXISTING)

Existing methods that need verification:

```swift
/// Updates user's display name
/// - Parameters:
///   - userID: Firebase Auth UID
///   - displayName: New display name (1-50 characters)
/// - Throws: UserServiceError for validation or Firestore errors
/// - Performance: Should complete in < 2 seconds
func updateDisplayName(userID: String, displayName: String) async throws

/// Updates user's profile photo URL
/// - Parameters:
///   - userID: Firebase Auth UID
///   - photoURL: New profile photo URL from Firebase Storage
/// - Throws: UserServiceError for Firestore errors
/// - Performance: Should complete in < 2 seconds
func updateProfilePhoto(userID: String, photoURL: String) async throws
```

### SyncService (VERIFY EXISTING)

Existing methods that need verification:

```swift
/// Syncs all offline messages to Firebase
/// - Returns: Number of messages successfully synced
/// - Throws: SyncServiceError for various failure scenarios
/// - Performance: Should complete in < 1 second per message
func syncOfflineMessages() async throws -> Int

/// Gets sync statistics
/// - Returns: Dictionary with sync statistics
func getSyncStatistics() -> [String: Any]
```

### PhotoService (VERIFY EXISTING)

Existing method that needs verification:

```swift
/// Uploads profile photo to Firebase Storage
/// - Parameters:
///   - image: UIImage to upload
///   - userID: User ID for storage path
/// - Returns: Download URL string
/// - Throws: PhotoServiceError for various failures
/// - Performance: Should complete in < 5 seconds for images < 5MB
func uploadProfilePhoto(image: UIImage, userID: String) async throws -> String
```

---

## 10. UI Components to Create/Modify

### Files to Create (NEW)

- `Views/Authentication/ForgotPasswordView.swift` — Password reset screen with email input
- `MessageAITests/Services/PasswordResetTests.swift` — Unit tests for password reset (Swift Testing)
- `MessageAITests/Services/MultiDeviceSyncTests.swift` — Multi-device sync simulation tests (Swift Testing)
- `MessageAITests/Services/OfflineCacheTests.swift` — Offline cache verification tests (Swift Testing)
- `MessageAIUITests/PasswordResetUITests.swift` — UI tests for password reset flow (XCTest)
- `MessageAIUITests/ProfileEditUITests.swift` — UI tests for profile editing (XCTest)

### Files to Modify (EXISTING)

- `Views/Authentication/LoginView.swift` — Add "Forgot Password?" link/button
- `Services/AuthService.swift` — Add sendPasswordResetEmail() method
- `Utilities/Errors/AuthError.swift` — Add password reset error cases if needed
- `ViewModels/AuthViewModel.swift` — Add sendPasswordReset() method for UI layer
- `MessageAITests/Services/UserServiceTests.swift` — Add profile update tests
- `MessageAITests/Services/SyncServiceTests.swift` — Add multi-device sync tests

---

## 11. Integration Points

- **Firebase Authentication** - Password reset email sending
- **Firestore** - User profile data sync across devices
- **Firebase Storage** - Profile photo storage and URL management
- **UserDefaults** - Offline message queue persistence
- **PresenceService** - Real-time online/offline status sync
- **SyncService** - Offline message sync on reconnect
- **NetworkMonitorService** - Detect connectivity for sync triggers

---

## 12. Test Plan & Acceptance Gates

### Password Reset Tests

**Happy Path (Swift Testing)**
- [ ] Test: User enters valid email → Reset email sent successfully
  - Gate: Firebase confirms email sent, no errors
- [ ] Test: User receives email → Can reset password via browser
  - Gate: Manual validation (check email, click link, reset password)
- [ ] Test: User resets password → Can sign in with new password
  - Gate: Sign in succeeds with new credentials

**Edge Cases (Swift Testing)**
- [ ] Test: User enters invalid email format → Validation error before Firebase call
  - Gate: Throws AuthError.invalidEmail, no Firebase call made
- [ ] Test: User enters non-existent email → Appropriate error message
  - Gate: Shows "No account found" or silent success (Firebase behavior)
- [ ] Test: User offline → Network error shown
  - Gate: Throws AuthError.networkError with user-friendly message
- [ ] Test: User enters empty email → Validation prevents submission
  - Gate: Button disabled or validation error shown

**UI Tests (XCTest)**
- [ ] Test: Tap "Forgot Password?" → ForgotPasswordView appears
  - Gate: Navigation successful, email field visible
- [ ] Test: Enter email, tap Send → Success message appears
  - Gate: "Check your email" message displays
- [ ] Test: Tap Back → Returns to LoginView
  - Gate: Navigation successful, LoginView visible

### Profile Editing Tests

**Happy Path (Swift Testing)**
- [ ] Test: Update display name → Firestore updated in < 2s
  - Gate: UserService.updateDisplayName() completes successfully
- [ ] Test: Upload profile photo → Storage URL returned in < 5s
  - Gate: PhotoService.uploadProfilePhoto() returns valid URL
- [ ] Test: Save profile changes → All fields persist correctly
  - Gate: Fetch user document shows updated values

**Edge Cases (Swift Testing)**
- [ ] Test: Enter name with 0 characters → Validation prevents save
  - Gate: Throws UserServiceError.invalidDisplayName
- [ ] Test: Enter name with 51 characters → Validation prevents save
  - Gate: Throws UserServiceError.invalidDisplayName
- [ ] Test: Upload image > 5MB → Error or compression
  - Gate: Appropriate error handling or automatic compression
- [ ] Test: Save while offline → Queued or error shown
  - Gate: Clear error message or save queued for later

**UI Tests (XCTest)**
- [ ] Test: Tap Edit Profile → ProfileEditView appears with current data
  - Gate: Navigation successful, fields pre-filled
- [ ] Test: Change name, tap Save → Profile updates
  - Gate: Dismiss successful, ProfileView shows new name
- [ ] Test: Tap avatar, select photo → Upload progress shown
  - Gate: Progress indicator appears, completes < 5s
- [ ] Test: Character counter updates as typing
  - Gate: Counter shows correct value, color changes when invalid

### Multi-Device Sync Tests

**Swift Testing (Simulated Multi-Device)**
- [ ] Test: Device 1 updates name → Device 2 fetches updated name
  - Gate: Device 2 receives update within 100ms
- [ ] Test: Device 1 uploads photo → Device 2 fetches updated photo URL
  - Gate: Device 2 receives URL update within 100ms
- [ ] Test: Device 1 sends message → Device 2 receives message
  - Gate: Message delivered within 100ms (PR #1 target)
- [ ] Test: Device 1 goes online → Device 2 sees presence change
  - Gate: Presence update propagates < 500ms
- [ ] Test: Device 1 offline, sends 3 messages → Device 2 receives after reconnect
  - Gate: All 3 messages sync successfully in < 1s

**Manual Multi-Device Testing**
- [ ] Test: 2 real devices, update profile on Device A
  - Gate: Device B sees update without manual refresh
- [ ] Test: 2 real devices, Device A goes offline/online
  - Gate: Device B presence indicator updates correctly
- [ ] Test: 2 real devices, send messages back and forth
  - Gate: Smooth real-time delivery, no lag or missing messages

### Offline Cache Tests

**Swift Testing**
- [ ] Test: Save 10 messages → Force quit → Reopen
  - Gate: All 10 messages load from cache < 500ms
- [ ] Test: Queue 3 offline messages → Force quit → Reopen
  - Gate: All 3 messages still in queue, ready to sync
- [ ] Test: Offline, view chat list → Loads from cache
  - Gate: Chat list appears < 500ms without network
- [ ] Test: 1000+ messages in cache → App loads
  - Gate: Smooth loading with LazyVStack, 60 FPS scrolling
- [ ] Test: Cache cleanup → Old messages removed when limit exceeded
  - Gate: Cache size stays within reasonable bounds

**UI Tests (XCTest)**
- [ ] Test: Enable Airplane Mode → View chat → Messages load
  - Gate: Cached messages visible, no loading errors
- [ ] Test: Send message offline → Force quit → Reopen
  - Gate: Message still in queue with "Sending..." status
- [ ] Test: Reconnect after offline period → Sync completes
  - Gate: "Syncing X messages..." indicator appears, completes < 1s

### Performance Tests

Reference standards from `MessageAI/agents/secondagent/shared-standards.md`:

- [ ] Test: Password reset email send time
  - Gate: Completes in < 2 seconds, email received < 30s
- [ ] Test: Profile name update save time
  - Gate: Completes in < 2 seconds
- [ ] Test: Profile photo upload time (< 5MB image)
  - Gate: Completes in < 5 seconds
- [ ] Test: Multi-device sync propagation time
  - Gate: Updates sync < 100ms across devices
- [ ] Test: Offline cache load time on app start
  - Gate: Chat list appears < 500ms

---

## 13. Definition of Done

See standards in `MessageAI/agents/secondagent/shared-standards.md`:

### Password Reset
- [ ] ForgotPasswordView created with email input
- [ ] AuthService.sendPasswordResetEmail() implemented
- [ ] LoginView has "Forgot Password?" link
- [ ] AuthViewModel.sendPasswordReset() added for UI layer
- [ ] All password reset tests pass (unit + UI)
- [ ] Manual testing: Reset email received and works

### Profile Editing
- [ ] ProfileEditView verified working (name + avatar)
- [ ] UserService.updateDisplayName() verified
- [ ] UserService.updateProfilePhoto() verified
- [ ] PhotoService.uploadProfilePhoto() verified
- [ ] Character counter validation verified
- [ ] All profile edit tests pass (unit + UI)

### Sync Logic
- [ ] SyncService.syncOfflineMessages() verified
- [ ] Multi-device sync tests created and passing
- [ ] Presence sync verified < 500ms
- [ ] Profile sync verified < 100ms
- [ ] Message sync verified < 100ms (PR #1)
- [ ] Sync behavior documented in code comments

### Offline Cache
- [ ] OfflineMessageService persistence verified
- [ ] Firestore offline persistence confirmed enabled
- [ ] Force-quit → reopen preserves history verified
- [ ] Cache load performance < 500ms verified
- [ ] All offline cache tests pass

### Testing
- [ ] Unit tests created (Swift Testing): PasswordResetTests, MultiDeviceSyncTests, OfflineCacheTests
- [ ] UI tests created (XCTest): PasswordResetUITests, ProfileEditUITests
- [ ] All acceptance gates pass
- [ ] Manual multi-device testing completed

### Documentation
- [ ] Code comments added to new methods
- [ ] Sync behavior documented
- [ ] Test results documented
- [ ] README updated if needed (password reset instructions)

---

## 14. Risks & Mitigations

- **Risk**: Firebase password reset email goes to spam → **Mitigation**: Test with multiple email providers, document common issues
- **Risk**: Multi-device sync tests flaky due to network timing → **Mitigation**: Use reasonable timeouts (100-200ms), retry logic in tests
- **Risk**: Offline cache grows too large, slows app → **Mitigation**: Implement cache size limits, prune old messages
- **Risk**: Profile photo upload fails for large images → **Mitigation**: Add image compression before upload, show clear size limits
- **Risk**: Sync conflicts when same user edits profile on 2 devices simultaneously → **Mitigation**: Last-write-wins with server timestamp, document behavior
- **Risk**: Tests pass but real multi-device experience laggy → **Mitigation**: Manual testing on real devices required before approval

---

## 15. Rollout & Telemetry

- **Feature flag?** No - critical auth and data management features
- **Metrics**: 
  - Password reset email send success rate (target: >95%)
  - Profile update success rate (target: >99%)
  - Multi-device sync latency p95 (target: <100ms)
  - Offline cache hit rate (target: >90%)
  - Force-quit recovery success rate (target: 100%)
- **Manual validation steps**:
  1. Test password reset on real device with personal email
  2. Test profile editing with photo upload
  3. Test multi-device sync with 2 real devices
  4. Test force-quit and reopen with messages cached
  5. Test offline mode and reconnect sync

---

## 16. Open Questions

- Q1: Should password reset email be sent even for non-existent emails (security)? → **Decision**: Follow Firebase default behavior (silent success for security)
- Q2: How to handle profile photo compression for large images? → **Decision**: Add compression before upload, target < 2MB after compression
- Q3: What's the max cache size before cleanup? → **Decision**: Keep last 1000 messages per chat, prune older
- Q4: Should we support email verification flow now? → **Decision**: No, defer to future PR (out of scope)

---

## 17. Appendix: Out-of-Scope Backlog

- [ ] Biometric authentication (Face ID/Touch ID) - separate PR
- [ ] Email verification on sign up - separate PR
- [ ] Multi-factor authentication (MFA) - separate PR
- [ ] Advanced cache management (LRU, size limits) - optimize in future
- [ ] Profile privacy settings (hide online status) - separate PR
- [ ] Change email address flow - separate PR
- [ ] Delete account functionality - separate PR

---

## Preflight Questionnaire

1. **Smallest end-to-end outcome?** User can reset forgotten password via email and regain account access

2. **Primary user and critical action?** Existing user who forgot password; critical action is reset and sign back in

3. **Must-have vs nice-to-have?** 
   - Must: Password reset, profile editing verification, sync verification, multi-device tests
   - Nice: Profile photo compression, advanced cache management, email verification

4. **Real-time requirements?** Yes (see shared-standards.md):
   - Profile sync < 100ms across devices
   - Presence sync < 500ms
   - Message sync < 100ms (PR #1)
   - Offline sync on reconnect < 1s

5. **Performance constraints?** Yes (see shared-standards.md):
   - Password reset email < 30s
   - Profile save < 2s
   - Photo upload < 5s
   - Cache load < 500ms

6. **Error/edge cases?** 
   - Invalid email format
   - Non-existent email
   - Network errors
   - Offline mode
   - Force-quit scenarios
   - Large photo uploads
   - Simultaneous profile edits
   - Sync conflicts

7. **Data model changes?** None - existing User schema supports all requirements

8. **Service APIs required?** 
   - New: AuthService.sendPasswordResetEmail()
   - Verify existing: UserService update methods, SyncService, PhotoService

9. **UI entry points?** 
   - New: "Forgot Password?" link on LoginView
   - Existing: "Edit Profile" button on ProfileView

10. **Security implications?** 
    - Password reset requires careful handling (don't reveal account existence)
    - Firebase rules from PR #6 already secure profile updates
    - Ensure password reset emails only go to verified email addresses

11. **Dependencies?** 
    - Depends on PR #6 (security rules, architecture)
    - Prepares for Phase 3 (reliable auth and sync foundation for AI features)

12. **Rollout strategy?** 
    - Manual validation required
    - Test on real devices before approval
    - Metrics: Email send success, sync latency, cache hit rate

13. **Out of scope?** 
    - Biometric auth, email verification, MFA, advanced cache management, profile privacy, account deletion

---

## Authoring Notes

- Leverage existing service layer (AuthService, UserService, SyncService)
- Focus on verification and testing more than new implementation
- Multi-device tests critical for bulletproof user experience
- Password reset is straightforward Firebase API, don't overcomplicate
- Reference MessageAI/agents/secondagent/shared-standards.md throughout
- Test offline scenarios thoroughly (force-quit, airplane mode, poor connectivity)


# PR-13 TODO — APNs & Firebase Cloud Messaging Setup

**Branch**: `feat/pr-13-push-notifications`  
**Source PRD**: `MessageAI/docs/prds/pr-13-prd.md`  
**Owner (Agent)**: Cody

---

## 0. Clarifying Questions & Assumptions

**Assumptions (confirm in PR if needed):**
- APNs authentication key will be available for Firebase Console configuration
- Physical iOS device available for testing (notifications don't work in simulator)
- Firebase project already configured from PR #1
- User authentication flow complete (PR #1)
- Messaging infrastructure complete (PR #6)
- Store latest token only (single device strategy) per PRD decision
- Notification payload structure: `{chatID, senderID, senderName, messageText}`

---

## 1. Setup

- [ ] Create branch `feat/pr-13-push-notifications` from develop
- [ ] Read PRD thoroughly (`MessageAI/docs/prds/pr-13-prd.md`)
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Verify Xcode project builds successfully
- [ ] Confirm Firebase project accessible and Auth working

---

## 2. Firebase & APNs Configuration

**Enable push notifications in Xcode and Firebase Console**

- [ ] Enable "Push Notifications" capability in Xcode project settings
  - Test Gate: Capability appears in project.pbxproj
  
- [ ] Enable "Background Modes" → "Remote notifications" in Xcode
  - Test Gate: Background modes enabled in Info.plist
  
- [ ] Generate APNs Authentication Key in Apple Developer Portal
  - Test Gate: Download .p8 key file
  
- [ ] Upload APNs key to Firebase Console (Project Settings → Cloud Messaging)
  - Test Gate: APNs configuration shows "Connected" in Firebase Console
  
- [ ] Verify FCM enabled in GoogleService-Info.plist
  - Test Gate: File contains FCM configuration keys

---

## 3. Data Model

**Create notification payload model**

- [ ] Create `Models/NotificationPayload.swift`
  - Properties: chatID, senderID, senderName, messageText, timestamp
  - Implement `init?(userInfo:)` for parsing notification dictionary
  - Test Gate: Model compiles, initializer handles valid and invalid data

- [ ] Update `Models/User.swift` to include optional `fcmToken` field
  - Add: `var fcmToken: String?`
  - Add: `var lastTokenUpdate: Date?`
  - Test Gate: User model compiles with new fields

---

## 4. Service Layer - NotificationService

**Implement core notification management service**

- [ ] Create `Services/NotificationService.swift` base class
  - Import UserNotifications, FirebaseMessaging, FirebaseFirestore
  - Define as `@MainActor class NotificationService: NSObject, ObservableObject`
  - Test Gate: File compiles, imports resolve
  
- [ ] Implement `requestPermission() async -> Bool`
  - Request authorization with options: .alert, .sound, .badge
  - Return true if granted, false if denied
  - Test Gate: Unit test verifies permission request flow
  
- [ ] Implement `checkPermissionStatus() async -> UNAuthorizationStatus`
  - Query current notification settings
  - Return authorization status
  - Test Gate: Returns correct status enum
  
- [ ] Implement `registerForNotifications(userID:) async throws`
  - Get FCM token via `Messaging.messaging().token()`
  - Store token in Firestore at `users/{userID}/fcmToken`
  - Store `lastTokenUpdate` timestamp
  - Throw `NotificationError.tokenRegistrationFailed` on failure
  - Test Gate: Token saved to Firestore within 2s
  
- [ ] Implement `updateToken(userID:) async throws`
  - Get new FCM token
  - Update Firestore `users/{userID}` with new token and timestamp
  - Test Gate: Firestore updated successfully
  
- [ ] Implement `removeToken(userID:) async throws`
  - Delete fcmToken field from Firestore `users/{userID}`
  - Test Gate: Token removed from Firestore on logout
  
- [ ] Implement `parseNotificationPayload(_ userInfo:) -> NotificationPayload?`
  - Extract chatID, senderID, senderName, messageText from dictionary
  - Return nil if required fields missing
  - Test Gate: Valid payload parsed, invalid returns nil
  
- [ ] Implement `handleForegroundNotification(_ notification:) -> UNNotificationPresentationOptions`
  - Parse notification content
  - Return [.banner, .sound] for foreground display
  - Test Gate: Returns correct presentation options
  
- [ ] Implement `handleNotificationTap(_ response:) -> String?`
  - Parse notification response userInfo
  - Extract and return chatID
  - Return nil if invalid payload
  - Test Gate: Valid tap returns chatID, invalid returns nil

- [ ] Define `NotificationError` enum
  - Cases: permissionDenied, tokenRegistrationFailed, firestoreUpdateFailed, invalidPayload
  - Implement LocalizedError protocol
  - Test Gate: Error descriptions return helpful messages

---

## 5. App Lifecycle Integration

**Configure notification delegates and FCM in app entry point**

- [ ] Update `MessageAIApp.swift` to import UserNotifications and FirebaseMessaging
  - Test Gate: Imports compile successfully
  
- [ ] Add `@StateObject var notificationService = NotificationService()` to MessageAIApp
  - Inject via `.environmentObject(notificationService)` into root view
  - Test Gate: Service accessible in view hierarchy
  
- [ ] Conform MessageAIApp to `UNUserNotificationCenterDelegate`
  - Implement `userNotificationCenter(_:willPresent:)` for foreground notifications
  - Implement `userNotificationCenter(_:didReceive:)` for notification taps
  - Test Gate: Delegate methods compile
  
- [ ] Conform MessageAIApp to `MessagingDelegate`
  - Implement `messaging(_:didReceiveRegistrationToken:)` for token refresh
  - Call `notificationService.updateToken()` when token refreshes
  - Test Gate: Token refresh captured and saved
  
- [ ] Configure delegates in `init()` or `onAppear`
  - Set `UNUserNotificationCenter.current().delegate = self`
  - Set `Messaging.messaging().delegate = self`
  - Register for remote notifications via `UIApplication.shared.registerForRemoteNotifications()`
  - Test Gate: Delegates set, app requests device token

---

## 6. Authentication Integration

**Trigger notification registration after login**

- [ ] Update `ViewModels/AuthViewModel.swift` to inject NotificationService
  - Add `@EnvironmentObject var notificationService: NotificationService`
  - Test Gate: Service accessible in ViewModel
  
- [ ] Update `signIn()` method to call notification registration after success
  - After successful login, call `await notificationService.requestPermission()`
  - If granted, call `await notificationService.registerForNotifications(userID: user.uid)`
  - Handle errors silently (log but don't block login)
  - Test Gate: Token registered on login
  
- [ ] Update `signUp()` method with same notification registration
  - After successful signup, call permission + registration flow
  - Test Gate: New users get permission prompt
  
- [ ] Update `signOut()` method to remove token
  - Before logout, call `await notificationService.removeToken(userID: currentUser.uid)`
  - Test Gate: Token removed from Firestore on logout

---

## 7. Navigation from Notification

**Handle deep linking to conversations from notification tap**

- [ ] Update `Views/Main/ConversationListView.swift` for deep link support
  - Add `@State private var selectedChatID: String?` for navigation
  - Add `.onAppear` to check for pending notification navigation
  - Test Gate: State variable updates trigger navigation
  
- [ ] Implement notification navigation in MessageAIApp
  - In `didReceive response` delegate method, extract chatID
  - Pass chatID to root view via published property or environment
  - Trigger navigation to conversation with that chatID
  - Test Gate: Notification tap navigates to correct conversation
  
- [ ] Add error handling for invalid navigation
  - If chatID invalid or conversation doesn't exist, show conversation list
  - Log error for debugging
  - Test Gate: Invalid payload doesn't crash, shows fallback

---

## 8. Firestore Security Rules

**Update Firebase security rules for token field**

- [ ] Update `firestore.rules` to allow users to update their own fcmToken
  - Add rule: Allow update if auth.uid == userID and only fcmToken/lastTokenUpdate modified
  - Test Gate: Rules deploy successfully
  
- [ ] Test rules in Firebase Console Rules Playground
  - Verify user can write own token
  - Verify user cannot write other user's token
  - Test Gate: Rules enforce proper access control

---

## 9. UI Components (Optional Pre-Permission Dialog)

**Create optional pre-permission explainer view**

- [ ] Create `Views/Components/NotificationPermissionView.swift`
  - SwiftUI view explaining notification value
  - "Get notified when you receive messages"
  - Buttons: "Enable Notifications", "Not Now"
  - Test Gate: SwiftUI preview renders correctly
  
- [ ] Add presentation logic in AuthViewModel
  - Show after successful login (first time only)
  - Store preference in UserDefaults to not show again
  - Test Gate: Dialog appears once, dismissed correctly

---

## 10. Testing - Unit Tests (Swift Testing)

**Test service layer methods**

- [ ] Create `MessageAITests/Services/NotificationServiceTests.swift`
  - Import Testing framework
  - Test Gate: File structure correct
  
- [ ] Write test: "Parse valid notification payload returns NotificationPayload"
  - Given: Valid userInfo dictionary with all fields
  - When: `parseNotificationPayload()` called
  - Then: Returns NotificationPayload with correct values
  - Test Gate: `#expect(payload != nil)`
  
- [ ] Write test: "Parse invalid notification payload returns nil"
  - Given: userInfo missing required chatID field
  - When: `parseNotificationPayload()` called
  - Then: Returns nil
  - Test Gate: `#expect(payload == nil)`
  
- [ ] Write test: "Handle notification tap with valid payload returns chatID"
  - Given: UNNotificationResponse with valid userInfo
  - When: `handleNotificationTap()` called
  - Then: Returns correct chatID string
  - Test Gate: `#expect(chatID == "test-chat-123")`
  
- [ ] Write test: "Handle notification tap with invalid payload returns nil"
  - Given: UNNotificationResponse with malformed userInfo
  - When: `handleNotificationTap()` called
  - Then: Returns nil
  - Test Gate: `#expect(chatID == nil)`
  
- [ ] Write test: "Register notifications stores token in Firestore"
  - Given: Authenticated user
  - When: `registerForNotifications()` called
  - Then: Token exists in Firestore users/{userID}/fcmToken
  - Test Gate: Firestore query confirms token stored
  
- [ ] Write test: "Remove token deletes from Firestore"
  - Given: User with existing token
  - When: `removeToken()` called
  - Then: fcmToken field removed from Firestore
  - Test Gate: Firestore query confirms deletion

---

## 11. Testing - UI Tests (XCTest)

**Test notification flows and navigation**

- [ ] Create `MessageAIUITests/NotificationFlowUITests.swift`
  - Import XCTest framework
  - Test Gate: File structure correct
  
- [ ] Write test: `testPermissionRequest_DisplaysCorrectly()`
  - Launch app, complete login
  - Verify system permission alert appears (if first launch)
  - Test Gate: Permission dialog detected
  
- [ ] Write test: `testPermissionDenied_AppContinuesNormally()`
  - Launch app, deny permissions
  - Verify app continues to conversation list
  - Verify no crashes or error alerts
  - Test Gate: XCTAssertTrue(conversationList.exists)
  
- [ ] Write test: `testNotificationNavigation_LoadsConversation()`
  - Send test notification from Firebase Console
  - Tap notification
  - Verify app navigates to correct conversation
  - Test Gate: XCTAssertTrue(conversationView.exists)
  
- [ ] Write test: `testInvalidPayloadNavigation_ShowsConversationList()`
  - Send notification with missing chatID
  - Tap notification
  - Verify app shows conversation list (fallback)
  - Test Gate: XCTAssertTrue(conversationList.exists)

---

## 12. Integration & Real-Time Testing

**Manual testing on physical device**

- [ ] Test on physical iPhone (notifications don't work in simulator)
  - Test Gate: Physical device available and configured
  
- [ ] Test foreground notification
  - App open → Send test notification from Firebase Console
  - Verify banner appears within 500ms
  - Verify tap navigates to conversation
  - Test Gate: Foreground notification works correctly
  
- [ ] Test background notification
  - App in background → Send test notification
  - Verify notification appears in notification center
  - Tap notification → App resumes and navigates
  - Test Gate: Background notification works correctly
  
- [ ] Test terminated state notification
  - Force quit app → Send test notification
  - Tap notification → App launches (cold start) and navigates
  - Measure launch time (target: <2 seconds)
  - Test Gate: Cold start navigation works correctly
  
- [ ] Test token registration on login
  - Fresh login → Check Firestore for token
  - Verify token stored within 2 seconds
  - Test Gate: Token in Firestore users/{userID}/fcmToken
  
- [ ] Test token removal on logout
  - Logout → Check Firestore
  - Verify token removed
  - Test Gate: fcmToken field deleted or null
  
- [ ] Test permission denial scenario
  - Fresh install → Deny permissions
  - Verify app continues working (send/receive messages)
  - Verify no token in Firestore
  - Test Gate: App functions without notifications
  
- [ ] Test token refresh
  - Reinstall app or wait for iOS token refresh
  - Verify new token saved to Firestore
  - Verify old token replaced
  - Test Gate: Latest token in Firestore

---

## 13. Performance Validation

**Verify targets from shared-standards.md**

- [ ] Measure token registration time
  - Login → Measure time to token stored in Firestore
  - Target: <2 seconds
  - Test Gate: Timing meets requirement
  
- [ ] Measure notification display latency
  - Send notification → Measure time to banner display
  - Target: <500ms from FCM receipt
  - Test Gate: Display latency acceptable
  
- [ ] Measure cold start navigation time
  - App terminated → Tap notification → Measure to conversation loaded
  - Target: <2 seconds
  - Test Gate: Cold start meets requirement
  
- [ ] Monitor main thread during token operations
  - Use Xcode Instruments
  - Verify no blocking >50ms on main thread
  - Test Gate: UI remains responsive

---

## 14. Acceptance Gates Verification

**Check every gate from PRD Section 12**

### Happy Path Gates
- [ ] **HP1:** Permission granted → Token stored in Firestore within 2s ✅
- [ ] **HP2:** Foreground notification → Banner displays <500ms → Tap navigates ✅
- [ ] **HP3:** Background notification → Tap resumes app → Navigates <1s ✅
- [ ] **HP4:** Terminated state → Tap launches app → Loads conversation <2s ✅

### Edge Case Gates
- [ ] **EC1:** Permission denied → App continues normally, no crashes ✅
- [ ] **EC2:** Malformed payload → Logs error, shows conversation list ✅
- [ ] **EC3:** Token refresh → Firestore updated with new token ✅
- [ ] **EC4:** Logout → Token removed from Firestore ✅
- [ ] **EC5:** Offline registration → Retries when online ✅

### Multi-User & Performance Gates
- [ ] **MU1:** Multiple devices → Latest token stored (single device strategy) ✅
- [ ] **MU2:** Multiple senders → All notifications navigate correctly ✅
- [ ] **P1:** Token registration <2s ✅
- [ ] **P2:** Display <500ms ✅
- [ ] **P3:** Cold start <2s ✅
- [ ] **P4:** Main thread never blocked >50ms ✅

---

## 15. Documentation & Code Quality

- [ ] Add inline comments for complex logic
  - Document token refresh handling
  - Document notification parsing logic
  - Test Gate: Code readable and well-commented
  
- [ ] Update README.md with notification setup instructions
  - Document APNs key configuration steps
  - Document physical device testing requirement
  - Test Gate: README includes notification section
  
- [ ] Verify no console warnings or errors
  - Clean build log
  - No Firebase configuration warnings
  - Test Gate: Zero warnings in Xcode
  
- [ ] Code follows Swift/SwiftUI best practices
  - Async/await used correctly
  - Proper error handling
  - Background thread for token operations
  - Test Gate: Code review checklist passes

---

## 16. PR Preparation

- [ ] Run all unit tests and verify 100% pass
  - Test Gate: All service tests green
  
- [ ] Run all UI tests and verify pass
  - Test Gate: All notification flow tests green
  
- [ ] Test on physical device (all scenarios from Section 12)
  - Test Gate: Manual testing checklist complete
  
- [ ] Create PR description using format below
  - Test Gate: PR description complete and formatted
  
- [ ] Verify with user before creating PR
  - Test Gate: User approval received
  
- [ ] Open PR targeting develop branch
  - Link PRD: `MessageAI/docs/prds/pr-13-prd.md`
  - Link TODO: `MessageAI/docs/todos/pr-13-todo.md`
  - Test Gate: PR created successfully

---

## PR Description Template

```markdown
# PR #13: APNs & Firebase Cloud Messaging Setup

## Overview
Implements complete push notification infrastructure with APNs and FCM integration. Users receive notifications for new messages in foreground, background, and terminated states.

## Changes
- Created `NotificationService` for token management and notification handling
- Created `NotificationPayload` model for structured notification data
- Updated `MessageAIApp` with UNUserNotificationCenterDelegate and MessagingDelegate
- Integrated notification registration in AuthViewModel (login/logout flows)
- Implemented deep link navigation from notification tap
- Updated Firestore security rules for fcmToken field
- Added comprehensive unit and UI tests

## Testing
- ✅ All unit tests pass (NotificationServiceTests)
- ✅ All UI tests pass (NotificationFlowUITests)
- ✅ Manual testing on physical iPhone (all app states)
- ✅ All acceptance gates pass (HP1-4, EC1-5, MU1-2, P1-4)
- ✅ Performance targets met (<2s registration, <500ms display, <2s cold start)

## Configuration Required
⚠️ **Manual Step:** Upload APNs authentication key to Firebase Console (Project Settings → Cloud Messaging) before testing.

## Links
- PRD: `MessageAI/docs/prds/pr-13-prd.md`
- TODO: `MessageAI/docs/todos/pr-13-todo.md`
- Dependencies: PR #1 (Firebase Auth), PR #6 (Messaging)

## Checklist
- [x] Branch created from develop
- [x] All TODO tasks completed
- [x] Services implemented + unit tests (Swift Testing)
- [x] SwiftUI views implemented with state management
- [x] Firebase integration tested (token storage/removal)
- [x] UI tests pass (XCTest)
- [x] Physical device testing complete (foreground, background, terminated)
- [x] Performance targets met (see shared-standards.md)
- [x] All acceptance gates pass
- [x] Code follows shared-standards.md patterns
- [x] No console warnings
- [x] Documentation updated
```

---

## Notes

- **Critical:** Push notifications require physical device; iOS Simulator not supported
- **APNs Setup:** Must configure authentication key in Firebase Console before any notifications work
- **Token Strategy:** Store latest token only (single device per user); multi-device support deferred to future PR
- **Testing:** Use Firebase Console "Cloud Messaging" section to send manual test notifications
- **Performance:** All token operations run on background threads; never block main thread
- **Error Handling:** Never crash on invalid payload; always fallback to conversation list
- **Dependencies:** Requires PR #1 (Auth) and PR #6 (Messaging) complete
- **Out of Scope:** Cloud Functions (PR #14), rich notifications, notification actions, badge counts

---

## Task Breakdown Summary

**Total Tasks:** ~85 granular tasks
- Setup: 5 tasks
- Firebase/APNs Config: 5 tasks
- Data Model: 2 tasks
- Service Layer: 11 tasks
- App Lifecycle: 5 tasks
- Auth Integration: 4 tasks
- Navigation: 3 tasks
- Security Rules: 2 tasks
- UI Components: 2 tasks
- Unit Tests: 6 tasks
- UI Tests: 4 tasks
- Integration Testing: 8 tasks
- Performance: 4 tasks
- Acceptance Gates: 16 checks
- Documentation: 4 tasks
- PR Prep: 6 tasks

Each task designed to be <30 minutes of focused work.


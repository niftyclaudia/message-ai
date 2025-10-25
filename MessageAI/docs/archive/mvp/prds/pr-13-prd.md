# PRD: APNs & Firebase Cloud Messaging Setup

**Feature**: Push Notification Infrastructure

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: Phase 4

**Links**: [PR Brief: PR #13](../pr-brief/pr-briefs.md), [TODO: pr-13-todo.md](../todos/pr-13-todo.md)

---

## 1. Summary

This PR establishes the complete push notification infrastructure by integrating Apple Push Notification service (APNs) with Firebase Cloud Messaging (FCM), enabling users to receive real-time notifications for new messages when the app is in foreground, background, or terminated state. This foundational system handles device token registration, notification payload processing, and proper notification display across all app states.

---

## 2. Problem & Goals

**Problem:** Users miss messages when the app is not in the foreground because there's no notification system to alert them of new activity. Without push notifications, users must manually check the app for new messages, leading to poor engagement and delayed responses in conversations.

**Why Now:** This is Phase 4 of the implementation plan. The core messaging infrastructure (PR #6) is complete, making this the right time to add notification capabilities before the final polish phase.

**Goals (ordered, measurable):**
- [x] G1 — Successfully register device tokens with APNs and FCM for 100% of authenticated users
- [x] G2 — Display push notifications correctly in foreground, background, and terminated states with <500ms latency from FCM receipt
- [x] G3 — Handle notification taps to navigate users to the correct conversation with 100% accuracy

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep.

- [ ] Not implementing Cloud Functions to send notifications (PR #14)
- [ ] Not implementing notification customization settings (user preferences for sound/badge)
- [ ] Not implementing notification grouping or conversation summaries
- [ ] Not implementing rich notifications with media attachments
- [ ] Not implementing notification actions (reply from notification)
- [ ] Not implementing silent notifications for background data sync

---

## 4. Success Metrics

**User-visible:**
- Time to receive notification after message sent: <2 seconds (FCM latency + processing)
- Notification tap → correct conversation load time: <1 second
- 0 failed notification deliveries due to token issues

**System (from shared-standards.md):**
- Device token registration success rate: >99%
- Notification payload processing time: <100ms
- App launch from notification: <2 seconds to interactive UI

**Quality:**
- 0 blocking bugs with notification display or navigation
- All acceptance gates pass
- Crash-free rate >99% for notification handling paths

---

## 5. Users & Stories

- As a user, I want to receive notifications when someone sends me a message so that I can respond quickly even when I'm not actively using the app.
- As a user, I want to tap a notification and be taken directly to the relevant conversation so I can respond immediately.
- As a user, I want notifications to work whether the app is open, in the background, or completely closed so that I never miss messages.

---

## 6. Experience Specification (UX)

### Entry Points and Flows

**Setup:** App requests notification permissions after login → User grants/denies → If granted, token registered automatically

**Background/Terminated:** Notification appears → User taps → App launches/resumes → Navigates to conversation

**Foreground:** In-app banner appears with sender/preview → Auto-dismisses or user taps to navigate

### Visual Behavior

- **Notification:** Title (sender name), Body (first 100 chars), default sound
- **Permission:** Optional pre-dialog explaining value, then system dialog
- **Error Handling:** Permission denied = app continues normally; invalid payload = show conversation list

### Performance Targets

- Token registration: <2s | Notification display: <500ms | Cold start navigation: <2s | Main thread never blocked >50ms

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**M1: Device Token Management**
- MUST register device token with APNs on first launch after login
- MUST send device token to FCM for registration
- MUST store device token in Firestore under user document for Cloud Functions access
- MUST handle token refresh (iOS can refresh tokens at any time)
- MUST remove token from Firestore on logout

**[Gate M1]** When user logs in → device token stored in Firestore within 2 seconds

**M2: Notification Permissions**
- MUST request notification permissions after successful authentication
- MUST handle permission granted scenario (register token)
- MUST handle permission denied scenario (continue without notifications)
- MUST support permission changes (user enables in Settings later)

**[Gate M2]** When permission granted → token registration succeeds; when denied → app continues normally

**M3: Foreground Notification Handling**
- MUST implement UNUserNotificationCenterDelegate methods
- MUST display notification banner when app is in foreground
- MUST handle notification tap to navigate to correct conversation

**[Gate M3]** When notification arrives in foreground → banner displays; tap navigates to conversation

**M4: Background/Terminated Notification Handling**
- MUST handle app launch from notification tap (cold start)
- MUST handle app resume from notification tap (warm start)
- MUST extract chatID from notification payload
- MUST navigate to correct conversation after launch/resume

**[Gate M4]** When app terminated → notification tap launches app and loads conversation within 2 seconds

**M5: Notification Payload Processing**
- MUST define notification payload structure with chatID and senderID
- MUST parse notification payload reliably
- MUST validate payload data before navigation
- MUST handle malformed payloads gracefully

**[Gate M5]** When malformed payload received → app logs error and shows conversation list (no crash)

**M6: FCM Configuration**
- MUST configure FCM in Firebase project
- MUST add GoogleService-Info.plist with FCM enabled
- MUST configure APNs authentication key in Firebase Console
- MUST enable push notifications capability in Xcode project

**[Gate M6]** When configuration complete → test notification from Firebase Console succeeds

### SHOULD Requirements

**S1: Token Refresh Handling**
- SHOULD monitor token changes via APNs delegate
- SHOULD update Firestore with new token automatically
- SHOULD log token refresh events for debugging

**S2: Error Logging**
- SHOULD log all token registration failures
- SHOULD log notification processing errors
- SHOULD provide helpful debug information

**S3: Notification Customization**
- SHOULD use sender's display name in notification title
- SHOULD include message preview in notification body (first 100 chars)
- SHOULD use default sound and badge

---

## 8. Data Model

### Firestore Schema Updates

**users Collection** (add notification token field):
```swift
{
  uid: String,
  displayName: String,
  email: String,
  profilePhotoURL: String?,
  fcmToken: String?,  // NEW: Firebase Cloud Messaging device token
  lastTokenUpdate: Timestamp?  // NEW: Track when token was last updated
}
```

### Swift Models

**NotificationPayload.swift** (NEW):
```swift
struct NotificationPayload: Codable {
    let chatID: String
    let senderID: String
    let senderName: String
    let messageText: String
    let timestamp: Date
    
    // Parse from notification userInfo dictionary
    init?(userInfo: [AnyHashable: Any]) {
        guard let chatID = userInfo["chatID"] as? String,
              let senderID = userInfo["senderID"] as? String,
              let senderName = userInfo["senderName"] as? String,
              let messageText = userInfo["messageText"] as? String
        else { return nil }
        
        self.chatID = chatID
        self.senderID = senderID
        self.senderName = senderName
        self.messageText = messageText
        self.timestamp = Date()
    }
}
```

### Validation Rules

**Firebase Security Rules Update** (add token field):
```javascript
match /users/{userID} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userID;
  
  // Allow user to update their own FCM token
  allow update: if request.auth.uid == userID 
    && request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['fcmToken', 'lastTokenUpdate']);
}
```

### Indexing/Queries

- No new indexes required (token lookups are by document ID)
- Firestore listeners not needed for token management
- Cloud Functions (PR #14) will query tokens when sending notifications

---

## 9. API / Service Contracts

### NotificationService.swift (NEW)

```swift
import FirebaseMessaging
import UserNotifications

class NotificationService: NSObject, ObservableObject {
    
    // MARK: - Permission Management
    
    /// Request notification permissions from user
    /// - Returns: True if granted, false if denied
    func requestPermission() async -> Bool
    
    /// Check current notification permission status
    /// - Returns: UNAuthorizationStatus
    func checkPermissionStatus() async -> UNAuthorizationStatus
    
    // MARK: - Token Management
    
    /// Register device for push notifications and store token in Firestore
    /// - Parameter userID: Current user's ID
    /// - Throws: NotificationError if registration fails
    func registerForNotifications(userID: String) async throws
    
    /// Refresh FCM token and update Firestore
    /// - Parameter userID: Current user's ID
    /// - Throws: NotificationError if update fails
    func updateToken(userID: String) async throws
    
    /// Remove FCM token from Firestore on logout
    /// - Parameter userID: User ID to remove token for
    /// - Throws: FirestoreError if deletion fails
    func removeToken(userID: String) async throws
    
    // MARK: - Notification Handling
    
    /// Handle notification received while app in foreground
    /// - Parameter notification: UNNotification object
    /// - Returns: Presentation options (banner, sound, badge)
    func handleForegroundNotification(_ notification: UNNotification) -> UNNotificationPresentationOptions
    
    /// Handle notification tap (background or terminated)
    /// - Parameter response: UNNotificationResponse object
    /// - Returns: ChatID to navigate to, or nil if invalid
    func handleNotificationTap(_ response: UNNotificationResponse) -> String?
    
    /// Parse notification payload into structured data
    /// - Parameter userInfo: Notification dictionary
    /// - Returns: NotificationPayload if valid, nil otherwise
    func parseNotificationPayload(_ userInfo: [AnyHashable: Any]) -> NotificationPayload?
}
```

### Error Handling

```swift
enum NotificationError: LocalizedError {
    case permissionDenied
    case tokenRegistrationFailed
    case firestoreUpdateFailed
    case invalidPayload
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission was denied"
        case .tokenRegistrationFailed:
            return "Failed to register device token"
        case .firestoreUpdateFailed:
            return "Failed to update token in database"
        case .invalidPayload:
            return "Notification payload is invalid or malformed"
        }
    }
}
```

### Pre/Post-Conditions

**registerForNotifications:**
- Pre: User must be authenticated
- Post: Token stored in Firestore users/{userID}/fcmToken
- Error: Throws if permission denied or Firestore write fails

**handleNotificationTap:**
- Pre: Notification must contain valid chatID in payload
- Post: Returns chatID for navigation
- Error: Returns nil if payload invalid, app shows conversation list

---

## 10. UI Components to Create/Modify

### New Files

- `Services/NotificationService.swift` — Core notification management service
- `Models/NotificationPayload.swift` — Notification data structure
- `Views/Components/NotificationPermissionView.swift` — Optional pre-permission dialog explaining value

### Modified Files

- `MessageAIApp.swift` — Add UNUserNotificationCenterDelegate conformance, configure FCM on launch
- `ViewModels/AuthViewModel.swift` — Call notification registration after successful login
- `Views/Main/ConversationListView.swift` — Handle deep link navigation from notification tap
- `Services/AuthService.swift` — Remove token on logout

---

## 11. Integration Points

**Apple Push Notification Service (APNs):**
- Register device token via UIApplication
- Handle token updates via AppDelegate
- Configure APNs authentication key in Firebase Console

**Firebase Cloud Messaging (FCM):**
- Import FirebaseMessaging framework
- Configure in GoogleService-Info.plist
- Send device token to FCM
- Receive notifications via FCM

**Firebase Firestore:**
- Store device tokens in users collection
- Update tokens on refresh
- Remove tokens on logout
- Cloud Functions (PR #14) will read tokens to send notifications

**SwiftUI State Management:**
- Use @EnvironmentObject for NotificationService
- Inject into main app view hierarchy
- Navigate via NavigationPath or NavigationLink based on notification payload

**iOS User Notifications Framework:**
- UNUserNotificationCenter for permission requests
- UNUserNotificationCenterDelegate for handling notifications
- Configure notification presentation options

---

## 12. Test Plan & Acceptance Gates

### Happy Path Tests
- [ ] **HP1:** Permission granted → Token stored in Firestore within 2s
- [ ] **HP2:** Foreground notification → Banner displays <500ms → Tap navigates to conversation
- [ ] **HP3:** Background notification → Tap resumes app → Navigates to conversation <1s
- [ ] **HP4:** Terminated state → Tap launches app → Loads conversation <2s

### Edge Cases
- [ ] **EC1:** Permission denied → App continues normally, no crashes
- [ ] **EC2:** Malformed payload → Logs error, shows conversation list (no crash)
- [ ] **EC3:** Token refresh → Firestore updated with new token
- [ ] **EC4:** Logout → Token removed from Firestore
- [ ] **EC5:** Offline registration → Retries when online

### Multi-User & Performance
- [ ] **MU1:** Multiple devices → Latest token stored (single device strategy)
- [ ] **MU2:** Multiple senders → All notifications navigate correctly
- [ ] **P1:** Token registration <2s | **P2:** Display <500ms | **P3:** Cold start <2s | **P4:** Main thread never blocked >50ms

---

## 13. Definition of Done

Reference standards from `MessageAI/agents/shared-standards.md`:

- [ ] NotificationService implemented with all methods
- [ ] NotificationPayload model created
- [ ] UNUserNotificationCenterDelegate implemented in MessageAIApp
- [ ] FCM configured in Firebase Console (APNs key uploaded)
- [ ] Device token registration working on login
- [ ] Token removal working on logout
- [ ] Foreground notification handling implemented
- [ ] Background/terminated notification handling implemented
- [ ] Navigation from notification tap working
- [ ] Unit tests pass (Swift Testing for NotificationService)
- [ ] UI tests pass (XCTest for notification flows)
- [ ] All acceptance gates pass (HP, EC, MU, P)
- [ ] Performance targets met (<2s registration, <500ms display, <2s cold start)
- [ ] Error handling for all edge cases
- [ ] Code reviewed and follows Swift/SwiftUI best practices
- [ ] Documentation updated (inline comments, README)
- [ ] No console warnings or errors
- [ ] Tested on physical device (notifications don't work in simulator)

---

## 14. Risks & Mitigations

**R1: APNs Configuration** → Follow Firebase setup guide; test with Console before Cloud Functions
**R2: Simulator Limitations** → Requires physical device for testing
**R3: Token Refresh** → Implement MessagingDelegate.didReceiveRegistrationToken() to catch all refreshes
**R4: Permission Denial** → Implement pre-permission dialog; ensure app works without notifications
**R5: Deep Link Navigation** → Use NavigationPath; fallback to conversation list if navigation fails
**R6: Multi-Device Tokens** → Store latest token only; future PR for multi-device support

---

## 15. Rollout & Telemetry

**Metrics:** Permission grant rate, token registration success, notification tap-through rate, cold start time

**Validation:**
1. Test all states on physical device (foreground, background, terminated)
2. Verify token storage/removal in Firestore
3. Test permission denial and token refresh scenarios

---

## 16. Open Questions

**Q1: Token Storage** → Store latest token only (single device). Multi-device support in future PR.
**Q2: Notification Grouping** → Out of scope. iOS handles basic grouping; enhance in future PR.
**Q3: Badge Counts** → Out of scope. Add after PR #12 (read receipts) complete.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] Rich notifications with image attachments (requires notification service extension)
- [ ] Notification actions (reply directly from notification)
- [ ] Notification settings screen (sound, badge, preview preferences)
- [ ] Multi-device token management (send to all user's devices)
- [ ] Notification grouping by conversation
- [ ] Silent notifications for background sync
- [ ] Custom notification sounds per conversation
- [ ] Badge count for unread messages

---

## Implementation Notes

- **Physical Device Required:** Push notifications don't work in iOS Simulator
- **APNs Setup:** Configure authentication key in Firebase Console before testing
- **Token Strategy:** Store latest token only (single device); multi-device support in future PR
- **Testing:** Use Firebase Console "Cloud Messaging" for manual test notifications
- **Error Handling:** Never crash on invalid payload; fallback to conversation list


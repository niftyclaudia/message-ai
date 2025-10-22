# MessageAI

A production-ready iOS messaging app built with SwiftUI and Firebase. Features real-time messaging, group chats, read receipts, presence indicators, offline support, push notifications, and optimistic UI updates. Perfect for learning modern iOS development patterns and Firebase integration.

---

## 🚀 Quick Start

**Ready to try it?** Jump to:

- **[📥 Installation & Setup](#installation)** - Get the app running in 5 minutes
- **[📱 How to Use the App](#-how-to-use-the-app)** - First-time setup guide & user manual
- **[⚡ What to Expect](#-what-to-expect)** - Performance benchmarks & feature overview
- **[🔔 Push Notifications Setup](#push-notifications-setup)** - Enable notifications (physical device required)
- **[🔧 Troubleshooting](#-troubleshooting)** - Common issues and solutions

---

## Architecture

**MVVM Architecture** with SwiftUI + Firebase
- **Models**: Data structures (User, Message, Conversation)
- **Views**: SwiftUI screens (Login, Chat, ConversationList)
- **ViewModels**: Business logic & state management
- **Services**: Firebase integration (Auth, Firestore, Messaging, Presence)
- **Tests**: Unit, Integration, UI, and Performance tests

## Features

✅ **Authentication** - Google Sign-In & email/password, auto persistence  
✅ **Real-Time Messaging** - Instant delivery via Firestore listeners  
✅ **Group Chats** - Unlimited participants with member management  
✅ **Read Receipts** - ✓ Sent, ✓✓ Delivered, Blue ✓✓ Read  
✅ **Presence Indicators** - Online/offline status with last active  
✅ **Optimistic UI** - Instant feedback, no loading states  
✅ **Offline Support** - Full functionality offline, auto-sync when online  
✅ **Push Notifications** - APNs + FCM with deep linking  
✅ **Contact Discovery** - Search users by name/phone  
✅ **Cloud Functions** - Serverless notification triggers

## Tech Stack

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Cloud Functions
  - Firebase Cloud Messaging
  - Firebase Storage (future)
- **Architecture**: MVVM
- **State Management**: Combine (@Published, @StateObject, @EnvironmentObject)
- **Testing**: XCTest, XCUITest

## Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 18.5+
- Firebase project configured

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/niftyclaudia/message-ai.git
cd MessageAI
```

2. **Open the project:**
```bash
open MessageAI/MessageAI.xcodeproj
```
Or double-click `MessageAI.xcodeproj` in Finder

3. **Verify Firebase configuration:**
   - Check that `GoogleService-Info.plist` exists in:
     - `MessageAI/MessageAI/GoogleService-Info.plist`
   - If missing, download from Firebase Console → Project Settings
   - Drag into Xcode project (ensure "Copy items if needed" is checked)

4. **Select a simulator or device:**
   - For basic testing: Any iOS Simulator (iPhone 15/16)
   - For notifications: **Physical iOS device required**

5. **Build and run:**
   - Press `⌘ + R` (Cmd + R)
   - Or click the Play button in Xcode
   - First build takes 1-2 minutes
   - Subsequent builds take 10-30 seconds

6. **Verify installation:**
   - App should launch to login screen
   - No crash on startup
   - Firebase connection successful (check console logs)

**Expected First Launch:**
- App opens to login/signup screen
- "Enable Notifications" prompt appears (tap Allow)
- Create account or sign in
- Redirected to empty conversation list (no chats yet)

### Push Notifications Setup

⚠️ **Important**: Push notifications require additional manual configuration:

1. **Enable Push Notifications in Xcode**:
   - Select MessageAI target → Signing & Capabilities
   - Add "Push Notifications" capability
   - Enable "Background Modes" → "Remote notifications"

2. **Configure Firebase Console**:
   - Generate APNs authentication key in Apple Developer Portal
   - Upload key to Firebase Console → Project Settings → Cloud Messaging
   - See detailed guide: `MessageAI/docs/notification-setup-guide.md`

3. **Test on Physical Device**:
   - Notifications don't work in iOS Simulator
   - Use Firebase Console to send test notifications
   - Verify foreground, background, and terminated states

### Cloud Functions Setup

The app includes Cloud Functions for automatic push notifications:

1. **Deploy Functions**:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

2. **Monitor Function Logs**:
   ```bash
   firebase functions:log
   ```

3. **Local Development**:
   ```bash
   firebase emulators:start
   ```

See `functions/README.md` for detailed Cloud Functions documentation.

## 📱 How to Use

**First Time Setup:**
1. Sign up/sign in (email or Google)
2. Allow notifications when prompted
3. Set display name and optional profile photo

**Start Chatting:**
- Tap **"+"** → Search user → Create 1-on-1 or group chat
- Type message → Tap send (instant delivery)
- Status: ✓ Sent, ✓✓ Delivered, Blue ✓✓ Read

**Key Features:**
- Messages work offline (auto-sync when online)
- Green dot = user online, timestamp = last active
- Notifications open directly to chat
- Pull to refresh conversation list

## ⚡ What to Expect

**Performance:**
- App launch: <2s | Message send: Instant | Notification: <2s | Offline sync: <5s

**User Experience:**
- WhatsApp-inspired UI with dark mode support
- Smooth 60fps animations
- Real-time updates (no refresh needed)
- Offline-first with zero data loss

**Known Limitations:**
- Notifications require physical iOS device (no simulator)
- Text-only (no file attachments yet)
- No message search or voice/video calls (planned)

## 🔧 Troubleshooting

### Common Issues and Solutions

#### "Push notifications not working"
**Problem**: Not receiving notifications when app is in background
**Solutions**:
1. Ensure you're testing on a **physical device** (not simulator)
2. Check notification permissions: Settings → MessageAI → Notifications → Allow
3. Verify APNs key is uploaded to Firebase Console
4. Check Cloud Functions are deployed: `firebase functions:list`
5. Review function logs: `firebase functions:log`
6. Ensure device token is registered (check Firestore `users/{userId}/fcmToken`)

#### "Messages not sending"
**Problem**: Messages stuck in "Sending..." state
**Solutions**:
1. Check internet connection
2. Verify Firebase Firestore rules allow writes
3. Check Xcode console for error messages
4. Try force-quitting and restarting the app
5. Ensure you're authenticated (check top-left profile icon)

#### "Not seeing other users online"
**Problem**: Presence indicators not updating
**Solutions**:
1. Ensure both users are signed in
2. Check Firestore rules allow read access to `users` collection
3. Verify PresenceService is running (check logs)
4. Wait 5-10 seconds for presence to update
5. Try pulling to refresh on conversation list

#### "Messages not syncing after going back online"
**Problem**: Offline messages not appearing after reconnecting
**Solutions**:
1. Wait 5-10 seconds for Firestore to sync
2. Check network status indicator
3. Force-quit and restart app
4. Verify Firestore offline persistence is enabled (default)
5. Check Xcode console for sync errors

#### "App crashes on launch"
**Problem**: App crashes immediately after opening
**Solutions**:
1. Ensure `GoogleService-Info.plist` is present and valid
2. Clean build folder: Xcode → Product → Clean Build Folder (⇧⌘K)
3. Delete derived data: Xcode → Preferences → Locations → Derived Data → Delete
4. Verify Xcode version (15.0+) and iOS version (17.0+)
5. Check console logs for specific error

#### "Can't find contacts"
**Problem**: Contact search returns no results
**Solutions**:
1. Ensure other users have set their display names
2. Search by exact display name or phone number
3. Check Firestore `users` collection has user documents
4. Verify Firestore rules allow read access to users
5. Try creating test users manually in Firebase Console

#### "Read receipts not working"
**Problem**: Messages don't show blue checkmarks when read
**Solutions**:
1. Ensure both users have read receipt feature enabled
2. Check that recipient has opened the conversation
3. Wait 2-3 seconds for status to update
4. Verify ReadReceiptService is tracking reads (check logs)
5. Check Firestore `messages` collection for `readBy` field

#### "Group chat not delivering to all members"
**Problem**: Some group members not receiving messages
**Solutions**:
1. Verify all members are in the `participants` array
2. Check each member's FCM token is valid
3. Review Cloud Function logs for delivery failures
4. Ensure all members have granted notification permissions
5. Try sending a test message in Firebase Console

### Getting Help

If you encounter issues not listed here:

1. **Check Logs**: 
   - Xcode console for Swift errors
   - Firebase Console → Functions → Logs for backend errors
   - `firebase functions:log` for real-time function logs

2. **Review Documentation**:
   - `MessageAI/docs/architecture.md` - System design
   - `MessageAI/docs/notification-testing-guide.md` - Notification setup
   - `functions/README.md` - Cloud Functions guide

3. **Debug Checklist**:
   - [ ] Latest code pulled from main
   - [ ] Clean build completed
   - [ ] Testing on physical device (for notifications)
   - [ ] Firebase Console shows correct data structure
   - [ ] All required permissions granted
   - [ ] Network connection stable

4. **Contact**:
   - Create an issue in the repository
   - Include: iOS version, Xcode version, error logs, steps to reproduce

## Development Workflow

### Branch Strategy

- `main` - Production-ready code
- `develop` - Development branch (all PRs target this)
- `feat/pr-X-feature-name` - Feature branches

### Creating a Feature Branch

```bash
git checkout develop
git pull origin develop
git checkout -b feat/pr-X-feature-name
```

### Running Tests

**In Xcode (Recommended):**
```bash
# Run all tests
⌘ + U (Cmd + U)

# Run specific test file
Right-click on test file → Run Tests

# Run specific test method
Click diamond icon next to test method
```

**Via Command Line:**
```bash
# Run all tests
xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 16'

# Run only unit tests
xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MessageAITests

# Run only UI tests  
xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MessageAIUITests
```

**Test Organization:**
- **Unit Tests** (`MessageAI/MessageAITests/Services/`) - Service layer logic
- **ViewModel Tests** (`MessageAI/MessageAITests/ViewModels/`) - Business logic
- **Integration Tests** (`MessageAI/MessageAITests/Integration/`) - Full feature flows
- **UI Tests** (`MessageAI/MessageAIUITests/`) - End-to-end user flows
- **Performance Tests** (`MessageAI/MessageAITests/Performance/`) - Speed benchmarks

**Expected Test Results:**
- All tests should pass ✅
- Total test count: 150+ tests
- Test execution time: < 60 seconds
- Code coverage: > 80%

**Key Test Files:**
- `NotificationServiceTests.swift` - Push notification logic
- `ChatServiceTests.swift` - Message sending/receiving
- `PresenceServiceTests.swift` - Online/offline tracking
- `ReadReceiptServiceTests.swift` - Message read tracking
- `MessageServiceOfflineTests.swift` - Offline mode behavior

## Design System (AppTheme)

### Colors
- **Primary**: Blue - Main brand color for buttons and accents
- **Secondary**: Gray - Less prominent UI elements
- **Accent**: Green - Highlights and interactive elements
- **Background**: System background (adapts to light/dark mode)
- **Error**: Red - Error states and destructive actions

### Typography
- **Title**: Large title, bold - Main headings
- **Headline**: Headline - Section headings
- **Body**: Body - Most content
- **Caption**: Caption - Small labels

### Spacing
- **Small**: 8pt
- **Medium**: 16pt
- **Large**: 24pt
- **Extra Large**: 32pt

### Corner Radius
- **Small**: 8pt
- **Medium**: 12pt
- **Large**: 16pt

## Navigation Patterns

### Root Navigation Flow

```
App Launch
    ↓
RootView (checks auth state)
    ├─ Authenticated → MainTabView
    └─ Not Authenticated → LoginView (NavigationStack)
                              ├─ Sign In → MainTabView
                              └─ Navigate to SignUpView → Sign Up → MainTabView
```

### State Management

- **AuthService**: Single source of truth for authentication state
- **@StateObject**: Used at app root for AuthService
- **@EnvironmentObject**: Injected to child views
- **@Published**: Auth state changes propagate instantly to UI

## Code Standards

See `MessageAI/agents/shared-standards.md` for detailed coding standards.

### Key Principles

- No hardcoded values (use AppTheme constants)
- Views are thin wrappers around services/view models
- No business logic in views
- Proper use of @State, @StateObject, @EnvironmentObject
- All async operations properly awaited
- User-friendly error messages

## Performance Targets

- **App load time**: < 2-3 seconds
- **Navigation transitions**: < 300ms
- **Auth operations**: < 5 seconds
- **Scrolling**: Smooth 60fps

## Testing Strategy

### Test Types

1. **Unit Tests** (XCTest) - Service methods, validation, business logic
2. **UI Tests** (XCUITest) - User flows, navigation, interactions
3. **Integration Tests** - Service integration, state management
4. **Performance Tests** - Load times, rendering performance

### Coverage Requirements

- Happy path scenarios
- Edge cases (empty input, offline, errors)
- Multi-user scenarios (where applicable)
- Performance targets met

## Documentation

- **PRDs**: `MessageAI/docs/prds/` - Product requirement documents
- **TODOs**: `MessageAI/docs/todos/` - Implementation checklists
- **PR Briefs**: `MessageAI/docs/pr-brief/` - High-level feature summaries
- **Architecture**: `MessageAI/docs/architecture.md` - System design

## Contributing

1. Read the PRD for the feature you're implementing
2. Follow the TODO checklist
3. Write tests for all new code
4. Ensure all tests pass before creating PR
5. Create PR targeting `develop` branch
6. Link PRD and TODO in PR description

## Team

- **Product/Planning**: Pete Agent
- **Development**: Cody Agent
- **Owner**: Claudia Alban

## License

Private project - All rights reserved

---

## 📋 Quick Reference

### Essential Commands

```bash
# Open project
open MessageAI/MessageAI.xcodeproj

# Run app
⌘ + R in Xcode

# Run all tests
⌘ + U in Xcode

# Deploy Cloud Functions
cd functions && npm install && firebase deploy --only functions

# View function logs
firebase functions:log

# Start local emulators
firebase emulators:start

# Clean build
⌘ + Shift + K in Xcode
```

### Key Files to Know

| File | Purpose |
|------|---------|
| `MessageAIApp.swift` | App entry point and Firebase initialization |
| `RootView.swift` | Auth routing logic |
| `ConversationListView.swift` | Main chat list screen |
| `ChatView.swift` | Individual chat screen |
| `MessageService.swift` | Core messaging logic |
| `NotificationService.swift` | Push notification handling |
| `PresenceService.swift` | Online/offline tracking |
| `ReadReceiptService.swift` | Message read status |
| `functions/src/sendMessageNotification.ts` | Backend notification trigger |
| `firestore.rules` | Database security rules |

### Quick Troubleshooting

| Issue | Quick Fix |
|-------|-----------|
| App won't build | Clean build folder (⌘⇧K), restart Xcode |
| Notifications not working | Test on physical device, check APNs setup |
| Messages not sending | Check internet, verify auth state |
| Tests failing | Pull latest main, clean build |
| Firebase errors | Verify `GoogleService-Info.plist` exists |

### Firebase Console Quick Links

- **Authentication**: Firebase Console → Build → Authentication
- **Firestore Database**: Firebase Console → Build → Firestore Database
- **Cloud Functions**: Firebase Console → Build → Functions
- **Cloud Messaging**: Firebase Console → Build → Cloud Messaging
- **Function Logs**: Firebase Console → Functions → Logs

### Documentation Index

- **Architecture Overview**: `MessageAI/docs/architecture.md`
- **All PRDs**: `MessageAI/docs/prds/`
- **All TODOs**: `MessageAI/docs/todos/`
- **PR Briefs**: `MessageAI/docs/pr-brief/pr-briefs.md`
- **Notification Testing**: `MessageAI/docs/notification-testing-guide.md`
- **Mock Testing**: `MessageAI/docs/mock-testing-guide.md`
- **Cloud Functions**: `functions/README.md`

### Test Account Setup

For testing, create multiple accounts:
```
User 1: test1@example.com / password123
User 2: test2@example.com / password123
User 3: test3@example.com / password123
```

### Performance Targets

- **App Launch**: < 2s
- **Message Send**: Instant (optimistic)
- **Message Receive**: < 1s
- **Notification Delivery**: < 2s
- **Offline Sync**: < 5s

### Tech Stack Summary

- **Frontend**: SwiftUI, Combine, Swift 5.9+
- **Backend**: Firebase (Auth, Firestore, Functions, FCM)
- **Architecture**: MVVM
- **Async**: Swift Concurrency (async/await)
- **Testing**: XCTest, XCUITest
- **CI/CD**: GitHub Actions (future)

---

Built with ❤️ using SwiftUI and Firebase

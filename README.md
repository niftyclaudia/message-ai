# MessageAI

A modern iOS messaging application built with SwiftUI and Firebase.

## Architecture

### App Structure

```
MessageAI/
├── MessageAI/
│   ├── Models/              # Data models
│   │   └── User.swift       # User data model
│   ├── Services/            # Business logic & Firebase integration
│   │   ├── AuthService.swift        # Authentication management
│   │   ├── UserService.swift        # User CRUD operations
│   │   └── FirebaseService.swift    # Firebase configuration
│   ├── ViewModels/          # View state & logic
│   │   └── AuthViewModel.swift      # Authentication flow logic
│   ├── Views/               # SwiftUI views
│   │   ├── Authentication/  # Auth screens
│   │   │   ├── LoginView.swift
│   │   │   └── SignUpView.swift
│   │   ├── Main/            # Main app structure
│   │   │   ├── RootView.swift       # Root router (auth state)
│   │   │   └── MainTabView.swift    # Tab container
│   │   └── Components/      # Reusable UI components
│   │       ├── PrimaryButton.swift
│   │       ├── CustomTextField.swift
│   │       ├── LoadingView.swift
│   │       └── EmptyStateView.swift
│   ├── Utilities/           # Helpers & extensions
│   │   ├── Theme/
│   │   │   └── AppTheme.swift       # Design system
│   │   ├── Extensions/
│   │   │   └── View+Extensions.swift
│   │   ├── Validation.swift         # Form validation
│   │   └── Constants.swift          # App constants
│   └── Utilities/Errors/    # Custom error types
│       ├── AuthError.swift
│       ├── UserServiceError.swift
│       └── FirebaseConfigError.swift
└── MessageAITests/          # Test suites
    ├── Services/            # Service tests
    ├── ViewModels/          # ViewModel tests
    ├── Utilities/           # Utility tests
    ├── Integration/         # Integration tests
    └── Performance/         # Performance tests
```

## Features Implemented

### 🎉 MVP Status: COMPLETE
All 10 hard requirements + 3 P1 features implemented and tested.  
See [MVP Completion Report](MessageAI/docs/mvp-completion-report.md) for details.

### Phase 1: Foundation (PRs #1-2)

#### ✅ PR #1: Firebase Setup & Authentication Service
- Firebase configuration and initialization
- Authentication service (sign up, sign in, sign out)
- User service (CRUD operations)
- Firestore security rules
- Error handling framework
- Comprehensive test suite

#### ✅ PR #2: Core SwiftUI App Structure & Navigation
- SwiftUI app architecture with navigation framework
- Authentication flow (login/signup views)
- Root navigation router based on auth state
- Theme system with centralized design tokens
- Reusable UI components (buttons, text fields, state views)
- Form validation helpers
- State management with @Published and @EnvironmentObject
- Comprehensive test suite (unit, UI, integration, performance)

#### ✅ PR #3: User Profiles & Contact Discovery
- Profile viewing and editing
- Display name editing with validation
- Profile photo upload to Firebase Storage
- Photo compression and optimization
- Contact list with real-time search functionality
- Search by name or email (case-insensitive)

### Phase 2: 1-on-1 Chat (PRs #4-8)

#### ✅ PR #4-5: Conversation List & Chat View
- Conversation list with last message preview
- Real-time chat updates
- Chat view with message display
- Smooth scrolling and layout

#### ✅ PR #6: Real-Time Message Delivery
- Firestore snapshot listeners for instant updates
- Sub-200ms message synchronization
- Server-side timestamps
- Network failure handling

#### ✅ PR #7: Optimistic UI Updates
- Instant local message display
- "Sending..." status indicators
- Automatic confirmation on server ack
- Retry logic for failed messages

#### ✅ PR #8: Offline Persistence
- Local message caching with Firestore offline mode
- Offline message queue
- Automatic sync on reconnect
- Full history preservation across app restarts

### Phase 3: Group Chats & Presence (PRs #9-11)

#### ✅ PR #9-10: Group Chat Support
- Create group chats with 3+ members
- Multi-user message delivery
- Member attribution with names/avatars
- Performance optimized for 3-10 member groups

#### ✅ PR #11: Presence Indicators
- Firebase Realtime Database presence system
- Real-time online/offline status
- Automatic status updates on app state changes
- OnDisconnect hooks for reliability

### Phase 4: Polish & Notifications (PRs #12-14)

#### ✅ PR #12: Read Receipts
- Per-message read tracking
- "Read" / "Delivered" status indicators
- Group chat read receipts
- Real-time receipt updates

#### ✅ PR #13: Push Notifications (APNs & FCM)
- Apple Push Notification service integration
- Firebase Cloud Messaging setup
- Device token registration and management
- Foreground, background, and terminated state handling
- Deep link navigation from notification taps
- Comprehensive test suite and setup documentation

#### ✅ PR #14: Cloud Functions for Push Notifications
- Serverless backend for automatic notification triggers
- Firestore onCreate trigger for new messages
- Sender exclusion logic (no self-notifications)
- FCM token management and cleanup
- Error handling and structured logging
- Performance optimized (<2s delivery target)

### Pre-Phase: MVP Completion (P1 Features)

#### ✅ Typing Indicators
- Real-time typing status with Firebase Realtime Database
- "Alice is typing..." / "Alice & Bob are typing..." display
- Auto-clear after 3 seconds of inactivity
- < 200ms appearance, < 500ms hide after idle
- Multi-user support in group chats
- Service: `TypingService.swift`
- View: `TypingIndicatorView.swift`
- Tests: `TypingServiceTests.swift`

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

- **Xcode**: 15.0+
- **iOS**: 18.5+
- **macOS**: Monterey or later
- **Firebase Project**: Configured with Authentication, Firestore, Storage, and Realtime Database
- **Homebrew**: For SwiftLint installation (optional but recommended)

### Installation (5-Minute Setup)

#### 1. Clone the Repository
```bash
git clone https://github.com/niftyclaudia/message-ai.git
cd MessagingApp-secondagent
```

#### 2. Set Up Firebase Configuration

⚠️ **IMPORTANT**: Never commit `GoogleService-Info.plist` to git!

```bash
# Copy the template file
cp MessageAI/MessageAI/GoogleService-Info.template.plist MessageAI/MessageAI/GoogleService-Info.plist

# Open the file and replace placeholders with your Firebase credentials
# Get your credentials from: https://console.firebase.google.com/
# Project Settings → Your Apps → Download GoogleService-Info.plist
```

**Replace these values:**
- `REPLACE_WITH_YOUR_CLIENT_ID`
- `REPLACE_WITH_YOUR_API_KEY`
- `REPLACE_WITH_YOUR_GCM_SENDER_ID`
- `REPLACE_WITH_YOUR_PROJECT_ID`
- `REPLACE_WITH_YOUR_STORAGE_BUCKET`
- `REPLACE_WITH_YOUR_APP_ID`

#### 3. Install Pre-Commit Hook (Security)

The pre-commit hook prevents accidental commits of secrets:

```bash
# Hook is already installed at .git/hooks/pre-commit
# Test it works:
git add MessageAI/MessageAI/GoogleService-Info.plist
git commit -m "test"
# Should be blocked with error message ✅
git reset HEAD MessageAI/MessageAI/GoogleService-Info.plist
```

#### 4. Install SwiftLint (Optional)

```bash
brew install swiftlint

# Verify installation
swiftlint version
```

SwiftLint will run automatically during Xcode builds once installed.

#### 5. Open and Build

```bash
# Open the project
open MessageAI/MessageAI.xcodeproj

# Build and run (Cmd+R)
# Select target: MessageAI
# Select destination: iPhone 15 Simulator (or physical device)
```

**Expected result**: App launches, shows login screen ✅

### First-Time Setup Validation

Run these checks to ensure everything works:

```bash
# 1. Check Firebase config exists (should NOT error)
ls MessageAI/MessageAI/GoogleService-Info.plist

# 2. Check template exists
ls MessageAI/MessageAI/GoogleService-Info.template.plist

# 3. Run SwiftLint (optional)
swiftlint lint --quiet

# 4. Run tests
xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 15'
```

All checks should pass ✅

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

```bash
# Run all tests
cmd+U in Xcode

# Or via command line
xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 16'
```

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

## Architecture Overview

MessageAI follows **MVVM (Model-View-ViewModel)** architecture with a dedicated **Service Layer**.

### Architecture Layers

```
Views (SwiftUI)
    ↓ @StateObject / @ObservedObject
ViewModels (@MainActor, ObservableObject)
    ↓ Async method calls
Services (Protocol-based)
    ↓ Firebase SDK
Firebase (Backend)
```

### Key Architectural Decisions

- **MVVM Pattern**: Clean separation of UI, state management, and business logic
- **Service Layer**: All Firebase operations abstracted behind protocols
- **Protocol-Based**: Easy mocking for tests, clean dependency injection
- **Real-Time Listeners**: Firestore snapshots for instant message sync (<100ms)
- **Offline-First**: Local caching with automatic sync on reconnect

### Documentation

- 📁 **[File Structure](docs/architecture/file-structure.md)** - Complete directory organization
- 📊 **[Message Flow](docs/architecture/message-flow.md)** - Data flow diagrams and sequence charts
- 📝 **[ADR-001: Firebase Backend](docs/architecture/adr-001-firebase.md)** - Why we chose Firebase
- 📝 **[ADR-002: MVVM Architecture](docs/architecture/adr-002-mvvm.md)** - Why we chose MVVM

### Phase 3: AI Integration (Planned)

- 🤖 **[AI Integration Guide](docs/ai-integration/README.md)** - OpenAI function calling setup
- 🔧 **[Function Schemas](docs/ai-integration/function-schemas.json)** - AI-callable functions

## Security & Best Practices

### 🔒 Secrets Management

**Never commit sensitive files!**

Protected files (automatically blocked by pre-commit hook):
- `GoogleService-Info.plist` - Firebase config
- `*.p8` - APNs authentication keys
- `*.pem` - Certificates
- `.env*` - Environment files
- `*APNs*.p8` - Push notification keys

**How it works:**
1. `.gitignore` blocks files from being tracked
2. Pre-commit hook prevents accidental commits
3. Template files provide safe scaffolding

**If you need to override** (rare):
```bash
git commit --no-verify  # Use with caution!
```

### 🔐 Firebase Security Rules

All Firebase services have production-ready security rules:

**Firestore** (`firestore.rules`):
- ✅ Users can only read/write chats they're members of
- ✅ Message senders must match authenticated user
- ✅ Read receipts can only be updated by chat members
- ✅ All operations require authentication

**Storage** (`storage.rules`):
- ✅ Users can only upload to their own profile photo path
- ✅ Max 5MB file size limit
- ✅ Images only (no arbitrary files)

**Realtime Database** (`database.rules.json`):
- ✅ Users can only update their own presence
- ✅ All users can read presence (for online indicators)

**Deploy rules:**
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
firebase deploy --only database
```

### 📏 Code Quality (SwiftLint)

SwiftLint enforces code quality standards automatically.

**Configuration**: `.swiftlint.yml`
- Line length: Warning at 120, error at 200
- Force unwrapping: Warning (use guard/if let)
- Force casting: Error (use safe casting)
- Custom rules: No print statements (use Logger)

**Run manually:**
```bash
swiftlint lint              # Check all files
swiftlint lint --quiet      # Only show errors
swiftlint autocorrect       # Fix auto-correctable issues
```

**Xcode integration**: SwiftLint runs automatically on build (if installed)

### 🤖 AI Error Handling (PR-AI-005)

**Calm Intelligence Error UX:**
All AI features use a unified error handling system with calm, first-person messaging:

```swift
import MessageAI

// Wrap AI operations
let handler = AIErrorHandler.shared
let context = AIContext(feature: .summarization, userId: userId, threadId: threadId)

do {
    let result = try await aiService.summarizeThread(threadId)
    handler.recordSuccess(for: .summarization)
    displaySummary(result)
} catch let error as AIError {
    let response = handler.handle(error: error, context: context)
    showCalmError(response)  // Blue/gray UI, not red
}
```

**Key Principles:**
- ✅ Blue/gray backgrounds (#F0F4F8), never red errors
- ✅ First-person messaging ("I'm having trouble..." not "Error occurred")
- ✅ Actionable fallbacks (retry, view full content, use basic mode)
- ✅ Core messaging ALWAYS works (AI failures never block basic chat)
- ✅ Graceful degradation with automatic fallback modes

**Error Types:**
- Timeout, rate limit, network failure → Auto-retry with exponential backoff
- Service unavailable → Fallback options (e.g., keyword search instead of semantic)
- Quota exceeded → Graceful degradation message

See `MessageAI/agents/shared-standards.md` for complete AI error handling standards.

## Code Standards

See `MessageAI/agents/shared-standards.md` for detailed coding standards.

### Key Principles

- No hardcoded values (use AppTheme constants)
- Views are thin wrappers around services/view models
- No business logic in views
- Proper use of @State, @StateObject, @EnvironmentObject
- All async operations properly awaited
- User-friendly error messages
- All service operations are protocol-based for testability

### Layer Responsibilities

**Views MUST:**
- Be SwiftUI structs
- Have no business logic
- Only call ViewModel methods
- Be presentation-only

**Views MUST NOT:**
- Import FirebaseFirestore
- Have @Published properties
- Contain business logic

**ViewModels MUST:**
- Conform to ObservableObject
- Be marked @MainActor
- Use @Published for UI state
- Call Service methods

**ViewModels MUST NOT:**
- Import SwiftUI (View, Color, Font)
- Perform Firebase operations directly
- Contain UI layout code

**Services MUST:**
- Be protocol-based
- Handle all Firebase operations
- Return plain Swift types
- Be stateless

**Services MUST NOT:**
- Import SwiftUI
- Reference ViewModels or Views
- Manage UI state

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

Built with ❤️ using SwiftUI and Firebase

# MessageAI

A modern, real-time messaging application built with SwiftUI and Firebase.

## Project Overview

MessageAI is a feature-rich messaging app for iOS that supports real-time 1-on-1 and group conversations, with Firebase backend for authentication, data storage, and push notifications.

### Key Features (Planned)
- 🔐 Email/password authentication
- 💬 Real-time messaging
- 👥 Group chat support
- ✅ Read receipts
- 🔔 Push notifications
- 📱 Offline message support
- 🟢 Online/offline presence indicators

## Tech Stack

- **Frontend**: SwiftUI (iOS)
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Cloud Messaging
  - Firebase Realtime Database (for presence)
- **Architecture**: MVVM pattern
- **Testing**: XCTest, XCUITest

## Firebase Setup

### Prerequisites

1. Xcode 15.0 or later
2. iOS 16.0 or later
3. Firebase account (free tier is sufficient)

### Setup Instructions

#### 1. Firebase Project Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select the existing project: `messageai-2cf12`
   - Project Name: `messageai`
   - Project ID: `messageai-2cf12`
   - Project Number: `75132810993`

Or create a new Firebase project if needed:
1. Click "Add project"
2. Enter project name: `messageai`
3. Accept terms and click "Create project"

#### 2. Enable Authentication

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Email/Password** provider
3. Click "Save"

#### 3. Create Firestore Database

1. Go to **Firestore Database** in Firebase Console
2. Click "Create database"
3. Select **Start in production mode** (we'll deploy custom rules)
4. Choose a location (e.g., `us-central1`)
5. Click "Enable"

#### 4. Deploy Security Rules

1. Install Firebase CLI if not already installed:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase in project directory:
   ```bash
   cd /path/to/MessagingApp
   firebase init firestore
   ```
   - Select existing project: `messageai-2cf12`
   - Accept default `firestore.rules` file path
   - Accept default `firestore.indexes.json` file path

4. Deploy security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

   Or manually deploy rules via Firebase Console:
   - Go to **Firestore Database** → **Rules**
   - Copy contents from `firestore.rules` file
   - Click "Publish"

#### 5. Add GoogleService-Info.plist to Xcode

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Under "Your apps", click the **iOS** icon
3. Register your app:
   - iOS bundle ID: `com.messageai.MessageAI` (match your Xcode project)
   - App nickname: `MessageAI`
   - Click "Register app"

4. Download `GoogleService-Info.plist`

5. Add to Xcode project:
   - Drag `GoogleService-Info.plist` into Xcode project navigator
   - Place it in the `MessageAI/MessageAI/` folder
   - ✅ Check "Copy items if needed"
   - ✅ Check "MessageAI" target
   - Click "Finish"

6. Verify the file is added:
   - In Xcode, select `GoogleService-Info.plist`
   - In File Inspector, verify "Target Membership" includes "MessageAI"

#### 6. Add Firebase SDK via Swift Package Manager

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter package URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: `10.0.0` or later
4. Click "Add Package"
5. Select the following products:
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - (Future PRs will add FirebaseMessaging, etc.)
6. Click "Add Package"

#### 7. Verify Setup

1. Build the project in Xcode (⌘+B)
2. Run on simulator (⌘+R)
3. Check console for: `✅ Firebase configured successfully with offline persistence`
4. If you see this message, setup is complete!

### Troubleshooting

#### "GoogleService-Info.plist not found"
- Verify the file is in `MessageAI/MessageAI/` folder
- Check Target Membership in File Inspector
- Clean build folder (⌘+Shift+K) and rebuild

#### "Firebase configuration failed"
- Verify Bundle ID in Xcode matches Firebase project
- Check that `GoogleService-Info.plist` has correct project info
- Ensure Firebase SDK packages are properly linked

#### Build errors after adding Firebase
- Clean build folder (⌘+Shift+K)
- Delete derived data: `~/Library/Developer/Xcode/DerivedData`
- Restart Xcode
- Rebuild project

## Project Structure

```
MessageAI/
├── MessageAI/
│   ├── App/
│   │   └── MessageAIApp.swift          # App entry point, Firebase init
│   ├── Models/
│   │   └── User.swift                   # User data model
│   ├── Services/
│   │   ├── FirebaseService.swift        # Firebase configuration
│   │   ├── AuthService.swift            # Authentication operations
│   │   └── UserService.swift            # User CRUD operations
│   ├── Utilities/
│   │   ├── Constants.swift              # App constants
│   │   └── Errors/                      # Custom error types
│   ├── Views/                           # SwiftUI views (future PRs)
│   └── ViewModels/                      # View models (future PRs)
├── MessageAITests/
│   ├── Services/                        # Service unit tests
│   ├── Integration/                     # Integration tests
│   └── Performance/                     # Performance tests
└── firestore.rules                      # Firestore security rules
```

## Development Workflow

### Branch Strategy

- **Base branch**: `develop` (main development branch)
- **Feature branches**: `feat/pr-{number}-{feature-name}`
- **PR target**: Always merge to `develop`, never directly to `main`

Example:
```bash
git checkout develop
git pull origin develop
git checkout -b feat/pr-2-login-ui
# ... make changes ...
git push origin feat/pr-2-login-ui
# Create PR: feat/pr-2-login-ui → develop
```

### Running Tests

#### Unit Tests
```bash
# In Xcode: ⌘+U (Command+U)
# Or via terminal:
xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 15'
```

#### Specific Test Suite
```bash
xcodebuild test -scheme MessageAI \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:MessageAITests/AuthServiceTests
```

### Firebase Emulator (Optional for Testing)

For faster testing without hitting production Firebase:

1. Install Firebase Emulator Suite:
   ```bash
   firebase init emulators
   ```
   - Select: Firestore, Authentication
   - Accept default ports

2. Start emulators:
   ```bash
   firebase emulators:start
   ```

3. Update test configuration to point to emulator (see test files)

## Service Usage Examples

### AuthService

```swift
import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            
            Button("Sign In") {
                Task {
                    do {
                        try await authService.signIn(email: email, password: password)
                    } catch let error as AuthError {
                        print("Error: \(error.errorDescription ?? "Unknown error")")
                    }
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // Navigate to main app
            }
        }
    }
}
```

### UserService

```swift
let userService = UserService()

// Fetch user
Task {
    do {
        let user = try await userService.fetchUser(userID: "someUserID")
        print("User: \(user.displayName)")
    } catch let error as UserServiceError {
        print("Error: \(error.errorDescription ?? "Unknown error")")
    }
}

// Update user
Task {
    try await userService.updateUser(
        userID: "someUserID",
        displayName: "New Name",
        profilePhotoURL: "https://example.com/photo.jpg"
    )
}
```

## Performance Targets

From `shared-standards.md`:

- ⚡️ App load time: < 2-3 seconds
- ⚡️ Firebase init: < 500ms
- ⚡️ Sign in: < 3 seconds
- ⚡️ Sign up: < 5 seconds
- ⚡️ Message sync: < 100ms
- ⚡️ Auth state change: < 100ms
- ⚡️ 60fps scrolling with 100+ messages

## Current Status (PR #1)

✅ **Completed** - Firebase Backend & Authentication Foundation
- Firebase project configured
- Email/password authentication
- User profile management
- Firestore security rules
- Offline persistence
- Comprehensive test coverage (80%+)

🚧 **Next PR (#2)** - Core SwiftUI App Structure & Navigation
- Login/SignUp UI
- Navigation flow
- Basic theming

## Contributing

1. All features are built via PRs following the PRD process
2. Each PR has a detailed PRD and TODO list in `MessageAI/docs/`
3. Follow code quality standards in `MessageAI/agents/shared-standards.md`
4. All code must have tests (unit, integration, performance)
5. Get approval before merging to `develop`

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Project PRDs](MessageAI/docs/prds/)
- [Architecture Guide](MessageAI/docs/architecture.md)
- [Shared Standards](MessageAI/agents/shared-standards.md)

## License

Private project - All rights reserved

## Contact

For questions or issues, contact the development team.

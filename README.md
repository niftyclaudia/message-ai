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

## Tech Stack

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
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

1. Clone the repository:
```bash
git clone https://github.com/niftyclaudia/message-ai.git
cd MessageAI
```

2. Open the project:
```bash
open MessageAI/MessageAI.xcodeproj
```

3. Ensure `GoogleService-Info.plist` is present in the project

4. Build and run (Cmd+R)

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

Built with ❤️ using SwiftUI and Firebase

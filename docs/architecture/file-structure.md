# MessageAI File Structure

This document describes the organization of the MessageAI codebase.

## Directory Tree

```
MessagingApp-secondagent/
├── MessageAI/                          # Main iOS application
│   └── MessageAI/                      # App source code
│       ├── Models/                     # Data models (User, Message, Chat, etc.)
│       ├── Services/                   # Business logic layer
│       │   ├── AuthenticationService   # Firebase Auth integration
│       │   ├── ChatService             # Chat management
│       │   ├── MessageService          # Message CRUD operations
│       │   ├── PresenceService         # Online/offline status
│       │   ├── TypingService           # Typing indicators
│       │   ├── NotificationService     # Push notifications
│       │   └── ...                     # Other services
│       ├── ViewModels/                 # MVVM ViewModels
│       │   ├── AuthViewModel           # Authentication state
│       │   ├── ChatViewModel           # Chat screen logic
│       │   ├── ConversationListViewModel  # Chat list logic
│       │   └── ...                     # Other ViewModels
│       ├── Views/                      # SwiftUI Views
│       │   ├── Main/                   # Primary app screens
│       │   │   ├── ConversationListView  # Chat list
│       │   │   ├── ChatView            # Chat screen
│       │   │   └── ProfileView         # User profile
│       │   ├── Components/             # Reusable UI components
│       │   │   ├── MessageBubble       # Message display
│       │   │   ├── InputBar            # Message input
│       │   │   └── ...                 # Other components
│       │   └── Auth/                   # Authentication screens
│       │       ├── LoginView
│       │       └── SignUpView
│       ├── Utilities/                  # Helper functions & extensions
│       │   ├── Extensions/             # Swift extensions
│       │   ├── Formatters/             # Date, time formatters
│       │   └── ...                     # Other utilities
│       ├── MessageAIApp.swift          # App entry point
│       ├── ContentView.swift           # Root view
│       ├── GoogleService-Info.plist    # Firebase config (GITIGNORED)
│       └── Info.plist                  # App configuration
│
├── MessageAITests/                     # Unit tests
│   ├── Services/                       # Service layer tests
│   ├── ViewModels/                     # ViewModel tests
│   ├── Integration/                    # Integration tests
│   ├── Performance/                    # Performance tests
│   └── Mocks/                          # Test mocks
│
├── MessageAIUITests/                   # UI tests
│   ├── AuthenticationFlowUITests.swift
│   ├── ChatViewUITests.swift
│   └── ...                             # Other UI tests
│
├── docs/                               # Documentation
│   ├── architecture/                   # Architecture docs
│   │   ├── file-structure.md           # This file
│   │   ├── message-flow.md             # Data flow diagram
│   │   ├── adr-001-firebase.md         # ADR: Why Firebase
│   │   └── adr-002-mvvm.md             # ADR: Why MVVM
│   └── ai-integration/                 # AI integration docs (Phase 3)
│       ├── README.md                   # AI integration guide
│       └── function-schemas.json       # OpenAI function definitions
│
├── functions/                          # Firebase Cloud Functions
│   └── src/                            # TypeScript functions
│       ├── sendMessageNotification.ts  # Push notifications
│       └── ...                         # Other functions
│
├── .swiftlint.yml                      # SwiftLint configuration
├── .gitignore                          # Git ignore rules
├── pre-commit-hook.sh                  # Pre-commit hook (prevents secrets)
├── firestore.rules                     # Firestore security rules
├── storage.rules                       # Firebase Storage rules
├── database.rules.json                 # Realtime Database rules
├── firebase.json                       # Firebase project config
└── README.md                           # Project setup instructions
```

## Key Directories

### `/MessageAI/MessageAI/`
Main application code following MVVM architecture pattern.

**Models/** - Pure data structures representing domain entities
- `User.swift` - User profile data
- `Message.swift` - Chat message data
- `Chat.swift` - Conversation data
- Conform to `Codable` for Firebase serialization

**Services/** - Business logic and Firebase interactions
- Each service handles a specific domain (auth, messages, presence, etc.)
- All Firebase operations go through services
- Services are protocol-based for testability
- Async/await for all network operations

**ViewModels/** - MVVM layer connecting Views to Services
- Conform to `ObservableObject`
- Use `@Published` properties for state
- Handle user actions and update UI state
- Keep UI logic separate from business logic

**Views/** - SwiftUI views organized by feature
- `Main/` - Core app screens (chat list, chat, profile)
- `Components/` - Reusable UI components (message bubbles, input bars)
- `Auth/` - Authentication flow (login, signup)
- Views are thin wrappers around ViewModels

**Utilities/** - Helper code and extensions
- Swift extensions (String, Date, Color, etc.)
- Formatters (timestamps, relative dates)
- Constants and configuration

### `/MessageAITests/`
Automated tests using Swift Testing framework
- Unit tests for services and business logic
- Integration tests for multi-component features
- Performance tests for latency targets
- Mock objects for Firebase dependencies

### `/MessageAIUITests/`
End-to-end UI tests using XCTest
- User flow testing (login, send message, etc.)
- Navigation testing
- Accessibility testing

### `/docs/`
Project documentation
- Architecture decisions (ADRs)
- Diagrams and flow charts
- AI integration specifications

### `/functions/`
Firebase Cloud Functions (Node.js/TypeScript)
- Push notifications
- Background tasks
- Future: AI integration webhooks

## Important Files

### Security Files (NEVER COMMIT)
- `GoogleService-Info.plist` - Firebase credentials (in .gitignore)
- Use `GoogleService-Info.template.plist` as template

### Configuration Files
- `.swiftlint.yml` - Code quality rules
- `firestore.rules` - Database security
- `storage.rules` - File storage security
- `database.rules.json` - Realtime DB security

### Git Hooks
- `pre-commit-hook.sh` - Blocks commits with secrets
- Installed at `.git/hooks/pre-commit`

## Architecture Pattern: MVVM + Services

```
┌─────────────────────────────────────────────────────┐
│                     Views/                          │
│              (SwiftUI Components)                    │
│  Thin UI layer, no business logic, reactive         │
└────────────────┬────────────────────────────────────┘
                 │ @StateObject / @ObservedObject
                 ↓
┌─────────────────────────────────────────────────────┐
│                  ViewModels/                         │
│             (ObservableObject)                       │
│  State management, user action handling, UI logic   │
└────────────────┬────────────────────────────────────┘
                 │ Async method calls
                 ↓
┌─────────────────────────────────────────────────────┐
│                   Services/                          │
│             (Business Logic)                         │
│  Firebase operations, data validation, transforms   │
└────────────────┬────────────────────────────────────┘
                 │ Firebase SDK
                 ↓
┌─────────────────────────────────────────────────────┐
│                   Firebase                           │
│    (Firestore, Auth, Storage, RTDB, Functions)     │
└─────────────────────────────────────────────────────┘
```

## Naming Conventions

- **Files**: PascalCase (`ChatView.swift`, `MessageService.swift`)
- **Classes/Structs**: PascalCase (`class AuthViewModel`, `struct User`)
- **Functions/Variables**: camelCase (`func sendMessage()`, `var isLoading`)
- **Constants**: camelCase with descriptive names (`let maxMessageLength = 1000`)
- **Protocols**: PascalCase, often ending in -able or -Protocol (`Codable`, `ChatServiceProtocol`)

## Data Flow

1. **User Action** → View captures tap/input
2. **View** → Calls ViewModel method
3. **ViewModel** → Calls Service method (async)
4. **Service** → Firebase SDK operation
5. **Firebase** → Real-time listener updates
6. **Service** → Publishes update
7. **ViewModel** → Updates @Published state
8. **View** → SwiftUI auto-refreshes

See [message-flow.md](./message-flow.md) for detailed sequence diagram.

## Testing Strategy

- **Unit Tests**: Service methods, business logic
- **UI Tests**: User flows, navigation, interactions
- **Integration Tests**: Multi-device sync, offline behavior
- **Performance Tests**: Latency targets (<100ms message sync)

## Future Additions (Phase 3)

- `/AI/` - AI service layer
- `/RAG/` - Retrieval-Augmented Generation pipeline
- `/n8n/` - Workflow automation integration

---

**Last Updated**: October 2025  
**Maintained By**: MessageAI Team


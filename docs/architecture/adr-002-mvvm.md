# ADR-002: Use MVVM Architecture Pattern with Service Layer

**Status**: Accepted  
**Date**: October 2025  
**Decision Makers**: MessageAI Team  
**Related**: iOS App Architecture, ADR-001 (Firebase Backend)

---

## Context

MessageAI iOS app needs an architecture pattern that supports:
- **SwiftUI** - Declarative UI framework
- **Real-time updates** - Messages sync instantly across devices
- **Testability** - Unit tests for business logic
- **Separation of concerns** - UI, logic, and data access isolated
- **Maintainability** - Easy to add features without breaking existing code
- **Firebase integration** - Clean abstraction over backend calls

### Constraints
- **SwiftUI-first** - Native iOS 15+ app
- **Small team** - 1-2 developers need clear patterns
- **Rapid iteration** - Add features weekly
- **Real-time data** - Firebase listeners must integrate cleanly
- **Testing** - Business logic must be testable without UI

---

## Decision

**We will use MVVM (Model-View-ViewModel) architecture with a dedicated Service layer.**

### Architecture Layers

```
┌─────────────────────────────────────────────┐
│  Views (SwiftUI)                            │
│  - Thin UI layer                            │
│  - No business logic                        │
│  - Reactive to @Published state             │
└────────────┬────────────────────────────────┘
             │ @StateObject / @ObservedObject
             ↓
┌─────────────────────────────────────────────┐
│  ViewModels (@MainActor, ObservableObject)  │
│  - State management (@Published)            │
│  - User action handling                     │
│  - UI logic (formatting, validation)        │
│  - Calls services for data                  │
└────────────┬────────────────────────────────┘
             │ Async method calls
             ↓
┌─────────────────────────────────────────────┐
│  Services (Protocol-based)                  │
│  - Business logic                           │
│  - Firebase operations                      │
│  - Data transformations                     │
│  - Real-time listeners                      │
└────────────┬────────────────────────────────┘
             │ Firebase SDK
             ↓
┌─────────────────────────────────────────────┐
│  Firebase (Backend)                         │
│  - Firestore, Auth, Storage, RTDB           │
└─────────────────────────────────────────────┘
```

---

## Rationale

### Why MVVM?

#### 1. Natural Fit for SwiftUI
SwiftUI is designed around data binding and reactive state:

```swift
// View automatically updates when ViewModel publishes changes
struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    
    var body: some View {
        List(viewModel.messages) { message in
            MessageBubble(message: message)
        }
    }
}
```

- `ObservableObject` + `@Published` = built-in MVVM support
- SwiftUI re-renders when `@Published` properties change
- No manual view updates needed

#### 2. Clean Separation of Concerns

**Views** - Pure UI, no logic
```swift
// ✅ Good: View just displays data
Text(message.text)
    .foregroundColor(message.isFromCurrentUser ? .blue : .gray)
```

**ViewModels** - State management and UI logic
```swift
// ✅ Good: ViewModel handles user actions and state
@Published var messages: [Message] = []

func sendMessage(text: String) {
    Task {
        try await messageService.sendMessage(chatID: chatID, text: text)
    }
}
```

**Services** - Business logic and Firebase
```swift
// ✅ Good: Service handles Firebase operations
func sendMessage(chatID: String, text: String) async throws -> String {
    let messageID = UUID().uuidString
    try await db.collection("chats/\(chatID)/messages")
        .document(messageID)
        .setData(["text": text, "senderID": currentUserID])
    return messageID
}
```

#### 3. Testability

**ViewModels** - Testable without UI:
```swift
@Test("Send Message Updates Messages Array")
func sendMessageUpdatesMessagesArray() async throws {
    let mockService = MockMessageService()
    let viewModel = ChatViewModel(messageService: mockService)
    
    await viewModel.sendMessage(text: "Hello")
    
    #expect(mockService.sendMessageCalled)
    #expect(viewModel.messages.count == 1)
}
```

**Services** - Testable with Firebase Emulator:
```swift
@Test("Message Service Creates Firestore Document")
func messageServiceCreatesFirestoreDocument() async throws {
    let service = MessageService(db: testFirestore)
    
    let messageID = try await service.sendMessage(
        chatID: "test-chat",
        text: "Test message"
    )
    
    let doc = try await testFirestore.collection("chats/test-chat/messages")
        .document(messageID)
        .getDocument()
    
    #expect(doc.exists)
}
```

#### 4. Reusability

**Services** - Shared across ViewModels:
```swift
// Both ViewModels use the same service instance
class ChatViewModel {
    let messageService: MessageServiceProtocol
}

class ConversationListViewModel {
    let messageService: MessageServiceProtocol  // Same instance!
}
```

**ViewModels** - Shared across Views:
```swift
// Pass ViewModel to child views
ChatView(viewModel: chatViewModel)
    .sheet(isPresented: $showMessageDetail) {
        MessageDetailView(viewModel: chatViewModel)  // Same instance!
    }
```

#### 5. Dependency Injection

Services are protocol-based for easy mocking:
```swift
protocol MessageServiceProtocol {
    func sendMessage(chatID: String, text: String) async throws -> String
}

// Production: Real Firebase
class MessageService: MessageServiceProtocol { ... }

// Testing: Mock service
class MockMessageService: MessageServiceProtocol { ... }

// ViewModel accepts protocol, not concrete type
class ChatViewModel: ObservableObject {
    init(messageService: MessageServiceProtocol) {
        self.messageService = messageService
    }
}
```

---

## Consequences

### ✅ Positive

1. **Clear responsibilities**
   - Views: Display data
   - ViewModels: Manage state
   - Services: Business logic
   - Each layer has one job

2. **Easy to test**
   - ViewModels testable without UI
   - Services testable with mocks
   - Protocol-based injection

3. **Maintainable**
   - New features = new ViewModel + Service methods
   - Existing code rarely changes
   - Clear file organization

4. **SwiftUI-native**
   - `ObservableObject` built-in
   - `@Published` automatic updates
   - No third-party frameworks needed

5. **Team-friendly**
   - Junior devs understand layers quickly
   - Code reviews focus on layer boundaries
   - Consistent patterns across codebase

### ❌ Negative

1. **More files**
   - Each feature = View + ViewModel + Service
   - **Mitigation**: Clear folder structure, naming conventions
   - **Mitigation**: Co-locate related files (ChatView.swift, ChatViewModel.swift)

2. **Boilerplate**
   - Protocol definitions for services
   - `@Published` properties for state
   - **Mitigation**: Use code snippets/templates
   - **Mitigation**: Accept some boilerplate for clarity

3. **Learning curve**
   - New team members need to learn MVVM
   - **Mitigation**: Document patterns clearly (this ADR!)
   - **Mitigation**: Provide examples and templates

4. **Over-engineering risk**
   - Temptation to create ViewModels for simple views
   - **Mitigation**: Simple views can skip ViewModel (e.g., static content)
   - **Rule**: ViewModel only if view has state or user interactions

---

## Alternatives Considered

### 1. MVC (Model-View-Controller)
**Pros**: Familiar, simple, less code  
**Cons**: "Massive View Controller" problem, hard to test, doesn't fit SwiftUI  
**Why rejected**: SwiftUI doesn't have view controllers, tight coupling makes testing hard

### 2. VIPER (View-Interactor-Presenter-Entity-Router)
**Pros**: Highly modular, testable, clear boundaries  
**Cons**: Over-engineered for small team, 5 files per feature, steep learning curve  
**Why rejected**: Too complex for MVP, slows development velocity

### 3. Redux/TCA (The Composable Architecture)
**Pros**: Unidirectional data flow, time-travel debugging, predictable state  
**Cons**: Third-party dependency, steep learning curve, verbose  
**Why rejected**: Adds complexity without clear benefit for our use case

### 4. MV (Model-View, No ViewModel)
**Pros**: Simplest possible, minimal files  
**Cons**: Business logic in views, hard to test, tight coupling  
**Why rejected**: Not maintainable as app grows, testing nightmare

### 5. Clean Architecture (Uncle Bob)
**Pros**: Highly testable, backend-agnostic, clear layers  
**Cons**: Over-engineered for mobile, too many abstraction layers  
**Why rejected**: Overkill for iOS app, slows feature development

---

## Implementation Guidelines

### File Organization
```
MessageAI/MessageAI/
├── Models/
│   ├── User.swift
│   ├── Message.swift
│   └── Chat.swift
├── Services/
│   ├── MessageService.swift
│   ├── ChatService.swift
│   └── AuthenticationService.swift
├── ViewModels/
│   ├── ChatViewModel.swift
│   ├── ConversationListViewModel.swift
│   └── AuthViewModel.swift
└── Views/
    ├── ChatView.swift
    ├── ConversationListView.swift
    └── Components/
        ├── MessageBubble.swift
        └── InputBar.swift
```

### Naming Conventions
- **Models**: `User`, `Message`, `Chat` (noun, singular)
- **Services**: `MessageService`, `ChatService` (noun + "Service")
- **ViewModels**: `ChatViewModel`, `AuthViewModel` (screen name + "ViewModel")
- **Views**: `ChatView`, `ConversationListView` (screen name + "View")

### Layer Rules

#### Views MUST:
- Be SwiftUI structs
- Have no business logic (no Firebase calls, no validation)
- Only call ViewModel methods
- Be presentation-only (layout, styling, animations)

#### Views MUST NOT:
- Import `FirebaseFirestore` (only ViewModels and Services can)
- Have `@Published` properties (that's ViewModel's job)
- Contain business logic or data transformation

#### ViewModels MUST:
- Conform to `ObservableObject`
- Be marked `@MainActor` (for thread safety)
- Use `@Published` for state that affects UI
- Call Service methods (never Firebase directly)
- Handle user actions (button taps, text input)

#### ViewModels MUST NOT:
- Import SwiftUI (no `View`, no `Color`, no `Font`)
- Perform Firebase operations directly (use Services)
- Contain UI layout code

#### Services MUST:
- Be protocol-based (for testing)
- Handle all Firebase operations
- Return plain Swift types (no Firestore-specific types)
- Be stateless (no `@Published` properties)

#### Services MUST NOT:
- Import SwiftUI
- Reference ViewModels or Views
- Manage UI state

### Example Feature Implementation

#### 1. Model (`Message.swift`)
```swift
struct Message: Identifiable, Codable {
    let id: String
    let text: String
    let senderID: String
    let timestamp: Date
}
```

#### 2. Service Protocol (`MessageServiceProtocol.swift`)
```swift
protocol MessageServiceProtocol {
    func sendMessage(chatID: String, text: String) async throws -> String
    func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration
}
```

#### 3. Service Implementation (`MessageService.swift`)
```swift
class MessageService: MessageServiceProtocol {
    private let db = Firestore.firestore()
    
    func sendMessage(chatID: String, text: String) async throws -> String {
        let messageID = UUID().uuidString
        let message = Message(id: messageID, text: text, senderID: currentUserID, timestamp: Date())
        try await db.collection("chats/\(chatID)/messages").document(messageID).setData(message.dictionary)
        return messageID
    }
    
    func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        return db.collection("chats/\(chatID)/messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                let messages = snapshot?.documents.compactMap { try? $0.data(as: Message.self) } ?? []
                completion(messages)
            }
    }
}
```

#### 4. ViewModel (`ChatViewModel.swift`)
```swift
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let messageService: MessageServiceProtocol
    private var listener: ListenerRegistration?
    
    init(messageService: MessageServiceProtocol) {
        self.messageService = messageService
    }
    
    func startListening(chatID: String) {
        listener = messageService.observeMessages(chatID: chatID) { [weak self] messages in
            self?.messages = messages
        }
    }
    
    func sendMessage(text: String) {
        Task {
            do {
                isLoading = true
                try await messageService.sendMessage(chatID: chatID, text: text)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
```

#### 5. View (`ChatView.swift`)
```swift
struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                }
            }
            
            HStack {
                TextField("Message", text: $inputText)
                Button("Send") {
                    viewModel.sendMessage(text: inputText)
                    inputText = ""
                }
                .disabled(inputText.isEmpty || viewModel.isLoading)
            }
        }
        .onAppear {
            viewModel.startListening(chatID: chatID)
        }
    }
}
```

---

## Success Metrics

| Metric | Target | Current Status |
|--------|--------|----------------|
| Test coverage | > 80% | ✅ 85% |
| Files per feature | < 5 | ✅ 3-4 average |
| ViewModel lines | < 300 | ✅ 150 average |
| Time to add feature | < 1 day | ✅ 4-6 hours |
| Code review time | < 30 min | ✅ 20 min average |

---

## References

- [SwiftUI MVVM Best Practices](https://www.swiftbysundell.com/articles/swiftui-state-management-guide/)
- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-using-factories-in-swift/)
- [Protocol-Oriented Programming](https://developer.apple.com/videos/play/wwdc2015/408/)

---

**Next Review**: Q2 2026 or if pattern causes significant friction  
**Owner**: MessageAI Team  
**Status**: Active, working well for team


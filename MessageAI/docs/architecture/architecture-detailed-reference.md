# MessageAI: Comprehensive System Architecture
**Version:** 2.0 - AI-Enhanced  
**Last Updated:** October 24, 2025  
**Status:** Implementation Ready 🚀

---

## Table of Contents
1. [System Overview](#system-overview)
2. [Tech Stack](#tech-stack)
3. [Architecture Layers](#architecture-layers)
4. [Service Breakdown](#service-breakdown)
5. [Data Flow Patterns](#data-flow-patterns)
6. [Dependencies & Integration](#dependencies--integration)
7. [Environment Management](#environment-management)
8. [Security Architecture](#security-architecture)
9. [Deployment Architecture](#deployment-architecture)
10. [File Structure (Complete)](#file-structure-complete)

---

## System Overview

### High-Level Architecture Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│                        iOS Application                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Views      │  │  ViewModels  │  │   Services   │         │
│  │  (SwiftUI)   │←→│   (State)    │←→│  (Business)  │         │
│  └──────────────┘  └──────────────┘  └──────┬───────┘         │
└────────────────────────────────────────────┼──────────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    │        Network Layer (URLSession + Firebase SDK)   │
                    └─────────────────────────┬─────────────────────────┘
                                              │
        ┌─────────────────────────────────────┼─────────────────────────────────┐
        │                                                                         │
        ▼                                     ▼                                   ▼
┌───────────────┐                  ┌──────────────────┐            ┌──────────────────┐
│   Firebase    │                  │  Cloud Functions │            │   AI Services    │
│   Services    │                  │   (Node.js/TS)   │            │   Ecosystem      │
├───────────────┤                  ├──────────────────┤            ├──────────────────┤
│ • Firestore   │◄────────────────►│ • RAG Pipeline   │◄──────────►│ • OpenAI API     │
│ • Auth        │                  │ • AI Functions   │            │ • Vector DB      │
│ • Storage     │                  │ • Notifications  │            │   (Pinecone/     │
│ • Analytics   │                  │ • Triggers       │            │    Weaviate)     │
│ • FCM         │                  │ • HTTP Endpoints │            │ • Calendar API   │
│ • Remote      │                  └──────────────────┘            └──────────────────┘
│   Config      │
└───────────────┘
```

### Core Architectural Principles
1. **MVVM Pattern**: Clear separation between UI, state, and business logic
2. **Service-Oriented**: Each domain has dedicated service layer
3. **Protocol-Driven**: Swift protocols for testability and modularity
4. **Async/Await First**: Modern Swift concurrency throughout
5. **Offline-First**: Local persistence with Firebase sync
6. **AI-Augmented**: AI features integrated at service layer, not UI
7. **Calm Intelligence**: AI features designed to reduce interruptions
8. **Fail-Safe**: Graceful degradation when AI services unavailable

---

## Tech Stack

### iOS Application
| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Language** | Swift | 5.9+ | Primary development language |
| **UI Framework** | SwiftUI | iOS 16+ | Declarative UI |
| **Concurrency** | async/await | Swift 5.5+ | Modern async patterns |
| **Backend SDK** | Firebase iOS SDK | 10.x | Firebase integration |
| **Dependency Manager** | Swift Package Manager | - | Dependency management |
| **Testing** | XCTest | - | Unit & integration tests |
| **UI Testing** | XCUITest | - | End-to-end UI tests |

### Backend Infrastructure
| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Runtime** | Node.js | 18 LTS | Cloud Functions execution |
| **Language** | TypeScript | 5.x | Type-safe backend code |
| **Backend Platform** | Firebase | - | Managed backend services |
| **Database** | Firestore | - | Real-time NoSQL database |
| **Auth** | Firebase Auth | - | User authentication |
| **Storage** | Firebase Storage | - | File storage |
| **Notifications** | FCM | - | Push notifications |
| **Analytics** | Firebase Analytics | - | Usage tracking |
| **Remote Config** | Firebase Remote Config | - | Feature flags |
| **Functions** | Cloud Functions for Firebase | Gen 2 | Serverless compute |

### AI Services Ecosystem
| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **LLM** | OpenAI GPT-4 | Latest | Text generation, function calling |
| **Embeddings** | OpenAI text-embedding-3-small | Latest | Vector embeddings (1536 dim) |
| **Vector Database** | Pinecone OR Weaviate | Latest | Semantic search, RAG |
| **RAG Framework** | Custom TypeScript | - | Retrieval augmented generation |
| **Function Calling** | OpenAI Functions API | Latest | Structured AI actions |

### DevOps & Monitoring
| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Version Control** | Git + GitHub | Source control |
| **CI/CD** | GitHub Actions | Automated testing & deployment |
| **Monitoring** | Firebase Crashlytics | Crash reporting |
| **Logging** | Cloud Functions Logs | Backend debugging |
| **Performance** | Firebase Performance | App performance tracking |
| **A/B Testing** | Firebase Remote Config | Feature rollout |

---

## Architecture Layers

### Layer 1: iOS Application (SwiftUI + Swift)

#### 1.1 Views Layer (Presentation)
**Responsibility**: Display UI, handle user interaction, no business logic

```swift
Views/
├── Authentication/
│   ├── LoginView.swift
│   ├── SignUpView.swift
│   └── PasswordResetView.swift
│
├── ChatList/
│   ├── ChatListView.swift           // Main conversation list
│   ├── ChatRowView.swift            // Chat preview with presence
│   └── CreateNewChatView.swift      // Contact picker
│
├── Conversation/
│   ├── ConversationView.swift       // Chat screen
│   ├── MessageRow.swift             // Message bubble
│   ├── MessageInputView.swift       // Input + send
│   └── TypingIndicatorView.swift    // "User is typing..."
│
├── Profile/
│   ├── ProfileView.swift
│   └── EditProfileView.swift
│
├── Settings/
│   ├── SettingsView.swift
│   └── NotificationSettingsView.swift
│
└── AI/                              // NEW: AI Features
    ├── PreferencesSettingsView.swift      // PR #AI-002
    ├── AITransparencyView.swift           // PR #AI-012 (Reusable)
    ├── ThreadSummaryView.swift            // PR #AI-006
    ├── ActionItemsView.swift              // PR #AI-007
    ├── SmartSearchView.swift              // PR #AI-008
    ├── PriorityInboxView.swift            // PR #AI-009
    ├── DecisionHistoryView.swift          // PR #AI-010
    └── MeetingSuggestionsView.swift       // PR #AI-011
```

**Key Patterns**:
- Views are stateless, observe ViewModels via `@StateObject` or `@ObservedObject`
- No Firebase/network calls in Views
- Reusable components via `@ViewBuilder`
- Accessibility labels on all interactive elements

---

#### 1.2 ViewModels Layer (State Management)
**Responsibility**: Manage UI state, orchestrate service calls, handle errors

```swift
ViewModels/
├── AuthViewModel.swift              // Login/signup state
├── ChatListViewModel.swift          // Chat list state + presence
├── ConversationViewModel.swift      // Message list state
├── ProfileViewModel.swift           // User profile state
│
└── AI/                              // NEW: AI ViewModels
    ├── ThreadSummaryViewModel.swift       // PR #AI-006
    ├── ActionItemsViewModel.swift         // PR #AI-007
    ├── SmartSearchViewModel.swift         // PR #AI-008
    ├── PriorityInboxViewModel.swift       // PR #AI-009
    ├── DecisionHistoryViewModel.swift     // PR #AI-010
    └── MeetingSuggestionsViewModel.swift  // PR #AI-011
```

**ViewModel Pattern**:
```swift
@MainActor
class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    
    private let messageService: MessageService
    private let aiService: ThreadSummarizationService
    
    init(messageService: MessageService, aiService: ThreadSummarizationService) {
        self.messageService = messageService
        self.aiService = aiService
    }
    
    func loadMessages(for chatId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            messages = try await messageService.fetchMessages(chatId: chatId)
        } catch {
            self.error = .networkError(error)
        }
    }
    
    func summarizeThread() async {
        // Delegates to AI service
    }
}
```

---

#### 1.3 Services Layer (Business Logic)
**Responsibility**: Business logic, Firebase interactions, AI orchestration

##### Core Services (Existing)
```swift
Services/
├── Core/
│   ├── FirebaseService.swift        // Firebase initialization
│   ├── AuthService.swift            // Auth operations
│   ├── ChatService.swift            // Chat CRUD
│   ├── MessageService.swift         // Message send/receive
│   ├── PresenceService.swift        // Online/offline tracking
│   ├── NotificationService.swift    // Push notification handling
│   └── StorageService.swift         // File upload/download
```

##### AI Services (New)
```swift
Services/
└── AI/
    ├── Core/
    │   ├── AIService.swift                    // Base AI service
    │   ├── PreferencesService.swift           // PR #AI-002
    │   ├── MemoryService.swift                // PR #AI-004
    │   └── FunctionCallingService.swift       // PR #AI-003
    │
    ├── Features/
    │   ├── ThreadSummarizationService.swift   // PR #AI-006
    │   ├── ActionItemService.swift            // PR #AI-007
    │   ├── SmartSearchService.swift           // PR #AI-008
    │   ├── PriorityDetectionService.swift     // PR #AI-009
    │   ├── DecisionTrackingService.swift      // PR #AI-010
    │   └── ProactiveAssistantService.swift    // PR #AI-011
    │
    └── Infrastructure/
        ├── EmbeddingService.swift             // PR #AI-001 (iOS wrapper)
        ├── VectorSearchService.swift          // PR #AI-001 (iOS wrapper)
        └── AIErrorHandler.swift               // PR #AI-005
```

**Service Pattern**:
```swift
protocol MessageService {
    func sendMessage(_ message: Message, to chatId: String) async throws
    func fetchMessages(chatId: String) async throws -> [Message]
    func deleteMessage(_ messageId: String) async throws
}

class FirebaseMessageService: MessageService {
    private let db = Firestore.firestore()
    
    func sendMessage(_ message: Message, to chatId: String) async throws {
        // Background thread for network
        try await db.collection("chats").document(chatId)
            .collection("messages").addDocument(data: message.dictionary)
        
        // AI processing happens in Cloud Function trigger
    }
}
```

---

#### 1.4 Models Layer (Data Structures)
**Responsibility**: Plain data structures matching Firestore schema

```swift
Models/
├── Core/
│   ├── User.swift                   // User profile
│   ├── Chat.swift                   // Conversation metadata
│   ├── Message.swift                // Chat message
│   ├── Presence.swift               // Online status
│   └── Notification.swift           // Push notification payload
│
└── AI/
    ├── UserPreferences.swift        // PR #AI-002
    ├── FocusHours.swift             // PR #AI-002
    ├── PriorityRule.swift           // PR #AI-002
    ├── AISessionContext.swift       // PR #AI-004
    ├── AITaskState.swift            // PR #AI-004
    ├── AIConversationMessage.swift  // PR #AI-004
    ├── AIError.swift                // PR #AI-005
    ├── ThreadSummary.swift          // PR #AI-006
    ├── ActionItem.swift             // PR #AI-007
    ├── SearchResult.swift           // PR #AI-008
    ├── MessageCategory.swift        // PR #AI-009
    ├── Decision.swift               // PR #AI-010
    ├── MeetingSuggestion.swift      // PR #AI-011
    └── CalendarAvailability.swift   // PR #AI-011
```

**Model Pattern**:
```swift
struct Message: Identifiable, Codable {
    let id: String
    let senderId: String
    let text: String
    let timestamp: Date
    let readBy: [String]
    
    // AI metadata (added in Phase 1)
    var embeddingGenerated: Bool?
    var searchableMetadata: SearchableMetadata?
    var categoryPrediction: MessageCategory?
}

struct SearchableMetadata: Codable {
    let keywords: [String]
    let participants: [String]
    let decisionMade: Bool
    let actionItemDetected: Bool
}
```

---

#### 1.5 Utilities Layer (Helpers)
```swift
Utilities/
├── Constants.swift                  // Firestore collections, API keys refs
├── AppError.swift                   // Unified error handling
├── Logger.swift                     // Logging utility
│
└── Extensions/
    ├── Date+Extensions.swift        // Timestamp formatting
    ├── View+Extensions.swift        // UI helpers
    ├── String+Extensions.swift      // Text utilities
    └── Color+Extensions.swift       // Calm Intelligence colors
```

---

### Layer 2: Backend Infrastructure (Firebase Cloud Functions)

#### 2.1 Cloud Functions Architecture

```typescript
functions/
├── src/
│   ├── index.ts                     // Function exports
│   │
│   ├── rag/                         // PR #AI-001: RAG Pipeline
│   │   ├── embeddings.ts            // Generate embeddings
│   │   ├── vectorSearch.ts          // Vector similarity search
│   │   ├── semanticQuery.ts         // Natural language queries
│   │   └── indexing.ts              // Message indexing pipeline
│   │
│   ├── functions/                   // PR #AI-003: AI Functions
│   │   ├── summarizeThread.ts       // Thread summarization
│   │   ├── extractActionItems.ts    // Action item extraction
│   │   ├── searchMessages.ts        // Semantic search
│   │   ├── categorizeMessage.ts     // Priority detection
│   │   ├── trackDecisions.ts        // Decision logging
│   │   ├── detectScheduling.ts      // Meeting need detection
│   │   ├── suggestMeetings.ts       // Time suggestions
│   │   └── executeFunction.ts       // Function execution handler
│   │
│   ├── triggers/                    // Firestore Triggers
│   │   ├── onMessageCreated.ts      // Auto-embed + categorize
│   │   ├── onUserStatusChanged.ts   // Presence updates
│   │   └── onPreferenceUpdated.ts   // Learning updates
│   │
│   ├── notifications/               // Push Notifications
│   │   ├── sendMessageNotification.ts
│   │   └── sendAIAlertNotification.ts
│   │
│   ├── errors/                      // PR #AI-005: Error Handling
│   │   ├── AIError.ts               // Error types
│   │   ├── errorHandler.ts          // Middleware
│   │   ├── fallbacks.ts             // Fallback strategies
│   │   └── retryQueue.ts            // Retry logic
│   │
│   ├── utils/                       // Utilities
│   │   ├── openai.ts                // OpenAI client wrapper
│   │   ├── pinecone.ts              // Pinecone client wrapper
│   │   ├── firestore.ts             // Firestore helpers
│   │   ├── validation.ts            // Parameter validation
│   │   └── logger.ts                // Structured logging
│   │
│   └── types/                       // TypeScript types
│       ├── messages.ts
│       ├── ai.ts
│       └── functions.ts
│
├── package.json
├── tsconfig.json
└── .env.example                     // Environment template
```

#### 2.2 Function Categories

##### HTTP Callable Functions (iOS → Cloud Functions)
```typescript
// Synchronous AI features
exports.summarizeThread = functions.https.onCall(...)
exports.extractActionItems = functions.https.onCall(...)
exports.searchMessages = functions.https.onCall(...)
exports.trackDecisions = functions.https.onCall(...)
exports.suggestMeetings = functions.https.onCall(...)
```

##### Firestore Triggers (Automatic Processing)
```typescript
// Background AI processing
exports.onMessageCreated = functions.firestore
    .document('chats/{chatId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
        // 1. Generate embedding (PR #AI-001)
        // 2. Categorize message (PR #AI-009)
        // 3. Detect action items (PR #AI-007)
        // 4. Track decisions (PR #AI-010)
        // 5. Check scheduling needs (PR #AI-011)
    });
```

##### Scheduled Functions (Maintenance)
```typescript
// Cleanup & monitoring
exports.cleanupOldAIData = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
        // Delete AI data >90 days old
    });

exports.monitorAIPerformance = functions.pubsub
    .schedule('every 5 minutes')
    .onRun(async (context) => {
        // Check error rates, response times
    });
```

---

### Layer 3: AI Services Ecosystem

#### 3.1 OpenAI Integration
```typescript
// services/openai.ts
import { Configuration, OpenAIApi } from 'openai';

class OpenAIService {
    private client: OpenAIApi;
    
    constructor() {
        const config = new Configuration({
            apiKey: process.env.OPENAI_API_KEY,
        });
        this.client = new OpenAIApi(config);
    }
    
    // PR #AI-001: Embedding generation
    async generateEmbedding(text: string): Promise<number[]> {
        const response = await this.client.createEmbedding({
            model: "text-embedding-3-small",
            input: text,
        });
        return response.data.data[0].embedding; // 1536 dimensions
    }
    
    // PR #AI-006: Thread summarization
    async summarizeThread(messages: Message[]): Promise<Summary> {
        const response = await this.client.createChatCompletion({
            model: "gpt-4",
            messages: [
                { role: "system", content: SUMMARIZATION_PROMPT },
                { role: "user", content: formatMessages(messages) }
            ],
            temperature: 0.3,
            max_tokens: 200,
        });
        return parseResponse(response);
    }
    
    // PR #AI-003: Function calling
    async executeFunctionCall(
        context: string,
        functions: FunctionSchema[]
    ): Promise<FunctionCall> {
        const response = await this.client.createChatCompletion({
            model: "gpt-4",
            messages: [{ role: "user", content: context }],
            functions: functions,
            function_call: "auto",
        });
        return response.data.choices[0].message.function_call;
    }
}
```

#### 3.2 Vector Database (Pinecone OR Weaviate)

**Option A: Pinecone**
```typescript
// services/pinecone.ts
import { PineconeClient } from '@pinecone-database/pinecone';

class PineconeService {
    private client: PineconeClient;
    private index: any;
    
    constructor() {
        this.client = new PineconeClient();
        await this.client.init({
            apiKey: process.env.PINECONE_API_KEY,
            environment: process.env.PINECONE_ENV,
        });
        this.index = this.client.Index('chat-messages');
    }
    
    // PR #AI-001: Index message
    async indexMessage(messageId: string, embedding: number[], metadata: any) {
        await this.index.upsert({
            upsertRequest: {
                vectors: [{
                    id: messageId,
                    values: embedding,
                    metadata: {
                        userId: metadata.userId,
                        chatId: metadata.chatId,
                        timestamp: metadata.timestamp,
                        text: metadata.text,
                    }
                }],
                namespace: metadata.userId, // User isolation
            }
        });
    }
    
    // PR #AI-008: Semantic search
    async search(
        queryEmbedding: number[],
        userId: string,
        topK: number = 10
    ): Promise<SearchResult[]> {
        const results = await this.index.query({
            queryRequest: {
                vector: queryEmbedding,
                topK: topK,
                namespace: userId,
                includeMetadata: true,
            }
        });
        return results.matches;
    }
}
```

**Option B: Weaviate**
```typescript
// services/weaviate.ts
import weaviate, { WeaviateClient } from 'weaviate-ts-client';

class WeaviateService {
    private client: WeaviateClient;
    
    constructor() {
        this.client = weaviate.client({
            scheme: 'https',
            host: process.env.WEAVIATE_URL,
            apiKey: new weaviate.ApiKey(process.env.WEAVIATE_API_KEY),
        });
    }
    
    // Similar indexing and search methods
}
```

---

### Layer 4: Data Storage (Firestore Schema)

#### 4.1 Core Collections (Existing)
```
/users/{userId}
    - id: string
    - email: string
    - displayName: string
    - photoURL: string?
    - phoneNumber: string
    - status: "online" | "offline" | "away"
    - lastSeen: timestamp
    - createdAt: timestamp
    - updatedAt: timestamp

/chats/{chatId}
    - id: string
    - type: "direct" | "group"
    - participants: string[]  // User IDs
    - participantDetails: { userId: { name, photo } }
    - lastMessage: {
        text: string
        senderId: string
        timestamp: timestamp
      }
    - createdAt: timestamp
    - updatedAt: timestamp

/chats/{chatId}/messages/{messageId}
    - id: string
    - senderId: string
    - text: string
    - timestamp: timestamp
    - readBy: string[]
    - type: "text" | "image" | "file"
    - fileURL: string?
```

#### 4.2 AI Collections (New - Phase 1)

```
/users/{userId}/preferences/        // PR #AI-002
    - focusHours: {
        enabled: boolean
        startTime: "10:00"
        endTime: "14:00"
        daysOfWeek: [1,2,3,4,5]
      }
    - urgentContacts: string[]
    - urgentKeywords: string[]
    - priorityRules: map<string, string>
    - communicationTone: "professional" | "friendly" | "supportive"
    - createdAt: timestamp
    - updatedAt: timestamp

/users/{userId}/aiState/            // PR #AI-004
    - sessionContext: {
        currentConversation: string
        recentQueries: string[]
        lastActiveTime: timestamp
        activeThreads: string[]
      }
    - taskState: {
        actionItems: ActionItem[]
        decisions: Decision[]
      }
    - conversationHistory: ConversationMessage[]

/users/{userId}/learningData/       // PR #AI-002
    - overrides: Override[]
    - meetingPreferences: MeetingPrefs
    - searchPatterns: string[]

/users/{userId}/decisions/          // PR #AI-010
/{decisionId}
    - id: string
    - text: string
    - participants: string[]
    - timestamp: timestamp
    - threadId: string
    - messageId: string
    - confidence: number
    - context: string
    - tags: string[]

/chats/{chatId}/messages/{messageId}  // Enhanced with AI metadata
    - ...existing fields...
    - embeddingGenerated: boolean     // PR #AI-001
    - searchableMetadata: {           // PR #AI-001
        keywords: string[]
        participants: string[]
        decisionMade: boolean
        actionItemDetected: boolean
      }
    - categoryPrediction: {           // PR #AI-009
        category: "urgent" | "can_wait" | "ai_handled"
        confidence: number
        reasoning: string
        timestamp: timestamp
      }
```

---

## Service Breakdown

### Core Services Dependency Map

```
┌─────────────────────────────────────────────────────────────┐
│                     iOS Services Layer                       │
└─────────────────────────────────────────────────────────────┘
                              │
    ┌─────────────────────────┼─────────────────────────┐
    │                         │                         │
    ▼                         ▼                         ▼
┌────────────┐        ┌───────────────┐        ┌──────────────┐
│   Core     │        │      AI       │        │   Support    │
│  Services  │        │   Services    │        │   Services   │
├────────────┤        ├───────────────┤        ├──────────────┤
│• Auth      │───────►│• Preferences  │◄───────│• Logger      │
│• Chat      │        │• Memory       │        │• Error       │
│• Message   │───────►│• Function     │        │• Analytics   │
│• Presence  │        │  Calling      │        │• Remote      │
│• Storage   │        │• Thread       │        │  Config      │
│• Notif     │        │  Summary      │        └──────────────┘
└────────────┘        │• Action Items │
                      │• Smart Search │
                      │• Priority     │
                      │• Decision     │
                      │• Proactive    │
                      └───────────────┘
```

### Service Responsibilities

#### Core Services (Existing + Enhanced)

**AuthService** (Existing)
- Sign up with email/password
- Login with email/password
- Password reset
- User session management
- Token refresh

**ChatService** (Existing)
- Create direct/group chats
- Fetch user's chat list
- Update chat metadata
- Delete chats
- Real-time chat updates

**MessageService** (Existing + AI Integration)
- Send messages (triggers AI processing in Cloud Function)
- Fetch message history
- Mark messages as read
- Delete messages
- Real-time message listeners
- **NEW**: Fetch AI-enhanced message metadata

**PresenceService** (Existing)
- Set user online/offline/away status
- Listen to other users' presence
- Last seen tracking
- Typing indicators

**NotificationService** (Existing + AI Integration)
- Register FCM token
- Handle incoming notifications
- Deep linking to chats
- **NEW**: Handle AI-generated proactive notifications

**StorageService** (Existing)
- Upload images/files
- Download files
- Generate signed URLs
- Delete files

---

#### AI Services (New)

**PreferencesService** - PR #AI-002
```swift
class PreferencesService {
    // CRUD
    func savePreferences(_ prefs: UserPreferences) async throws
    func loadPreferences() async throws -> UserPreferences
    func updateFocusHours(_ hours: FocusHours) async throws
    func addUrgentContact(_ userId: String) async throws
    func removeUrgentContact(_ userId: String) async throws
    
    // Learning
    func recordOverride(messageId: String, from: Category, to: Category) async throws
    func getMeetingPreferences() async throws -> MeetingPreferences
}
```

**MemoryService** - PR #AI-004
```swift
class MemoryService {
    // Session context
    func updateSessionContext(_ context: AISessionContext) async throws
    func getSessionContext() async throws -> AISessionContext
    func clearSession() async throws
    
    // Task state
    func addActionItem(_ item: ActionItem) async throws
    func completeActionItem(_ itemId: String) async throws
    func addDecision(_ decision: Decision) async throws
    
    // Conversation history
    func appendMessage(_ message: AIConversationMessage) async throws
    func getRecentHistory(limit: Int) async throws -> [AIConversationMessage]
    
    // Cleanup
    func cleanupOldData() async throws
}
```

**FunctionCallingService** - PR #AI-003
```swift
class FunctionCallingService {
    func callFunction<T: Decodable>(
        _ functionName: String,
        parameters: [String: Any]
    ) async throws -> T
    
    // Specific function wrappers
    func summarizeThread(threadId: String) async throws -> ThreadSummary
    func extractActionItems(threadId: String) async throws -> [ActionItem]
    func searchMessages(query: String, filters: SearchFilters?) async throws -> [SearchResult]
    func categorizeMessage(messageId: String) async throws -> MessageCategory
    func trackDecisions(threadId: String) async throws -> [Decision]
    func detectSchedulingNeed(threadId: String) async throws -> Bool
    func suggestMeetingTimes(participants: [String], duration: Int) async throws -> [TimeSlot]
}
```

**ThreadSummarizationService** - PR #AI-006
```swift
class ThreadSummarizationService {
    private let functionService: FunctionCallingService
    private let memoryService: MemoryService
    
    func summarize(chatId: String) async throws -> ThreadSummary
    func getSummaryFromCache(chatId: String) async -> ThreadSummary?
    func invalidateCache(chatId: String) async
}
```

**ActionItemService** - PR #AI-007
```swift
class ActionItemService {
    func extractActionItems() async throws -> [ActionItem]
    func completeItem(_ itemId: String) async throws
    func getItemsByUrgency() async throws -> GroupedActionItems
    func getItemsForConversation(chatId: String) async throws -> [ActionItem]
}
```

**SmartSearchService** - PR #AI-008
```swift
class SmartSearchService {
    func search(
        query: String,
        filters: SearchFilters?
    ) async throws -> [SearchResult]
    
    func saveSearchHistory(query: String) async
    func getSearchHistory() async -> [String]
    func clearHistory() async
}
```

**PriorityDetectionService** - PR #AI-009
```swift
class PriorityDetectionService {
    func categorizeMessage(_ messageId: String) async throws -> MessageCategory
    func overrideCategory(messageId: String, to: Category) async throws
    func getCategorizedMessages() async throws -> CategorizedMessages
    func getCategorizationAccuracy() async -> Double
}
```

**DecisionTrackingService** - PR #AI-010
```swift
class DecisionTrackingService {
    func trackDecisions(in chatId: String) async throws
    func getAllDecisions() async throws -> [Decision]
    func searchDecisions(query: String) async throws -> [Decision]
    func getDecisions(
        dateRange: DateRange?,
        conversation: String?,
        participants: [String]?
    ) async throws -> [Decision]
}
```

**ProactiveAssistantService** - PR #AI-011
```swift
class ProactiveAssistantService {
    func detectSchedulingNeed(in chatId: String) async throws -> Bool
    func suggestMeetingTimes(
        participants: [String],
        duration: Int,
        topic: String
    ) async throws -> [MeetingSuggestion]
    
    func bookMeeting(_ suggestion: MeetingSuggestion) async throws
    func sendCounterProposal(times: [TimeSlot]) async throws
}
```

---

## Data Flow Patterns

### Pattern 1: Message Send with AI Processing

```
┌──────────────────────────────────────────────────────────────────┐
│ User Types Message → Taps Send                                   │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ ConversationView                                                 │
│   └─► ConversationViewModel.sendMessage()                       │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ MessageService.sendMessage()                                     │
│   └─► Firestore.addDocument() [Background Thread]               │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ Cloud Function: onMessageCreated (Firestore Trigger)            │
│   ├─► 1. Generate Embedding (OpenAI)         [PR #AI-001]       │
│   ├─► 2. Store in Vector DB (Pinecone)       [PR #AI-001]       │
│   ├─► 3. Categorize Message (Priority)       [PR #AI-009]       │
│   ├─► 4. Extract Action Items                [PR #AI-007]       │
│   ├─► 5. Detect Decisions                    [PR #AI-010]       │
│   └─► 6. Check Scheduling Need               [PR #AI-011]       │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ Update Firestore with AI Metadata                               │
│   - embeddingGenerated: true                                     │
│   - categoryPrediction: { urgent, 0.95, "Manager + deadline" }  │
│   - searchableMetadata: { keywords: [...], actionItem: true }   │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ Real-time Listener Updates iOS App                              │
│   └─► UI reflects new message + AI insights                     │
└──────────────────────────────────────────────────────────────────┘
```

---

### Pattern 2: Thread Summarization Request

```
┌──────────────────────────────────────────────────────────────────┐
│ User Long-Presses Chat → Taps "Summarize Thread"                │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ ChatListView                                                     │
│   └─► ThreadSummaryViewModel.requestSummary(chatId)             │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ ThreadSummarizationService.summarize(chatId)                     │
│   └─► FunctionCallingService.summarizeThread(chatId)            │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ HTTP Callable Function: summarizeThread                          │
│   ├─► 1. Fetch messages from Firestore                          │
│   ├─► 2. RAG: Fetch embeddings from Pinecone                    │
│   ├─► 3. Build context window for GPT-4                         │
│   ├─► 4. Call OpenAI GPT-4 with prompt                          │
│   ├─► 5. Parse response                                         │
│   └─► 6. Store in Memory/State                                  │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ Return ThreadSummary to iOS                                      │
│   {                                                              │
│     summary: "Team decided on Stripe...",                        │
│     confidence: "high",                                          │
│     keySignals: ["decision", "action_item"],                     │
│     messageCount: 47                                             │
│   }                                                              │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ ThreadSummaryView Displays Result                                │
│   - Summary text                                                 │
│   - Transparency reasoning (AITransparencyView)                  │
│   - "Show Original" button                                       │
└──────────────────────────────────────────────────────────────────┘
```

---

### Pattern 3: Smart Search with RAG

```
┌──────────────────────────────────────────────────────────────────┐
│ User Types Query: "What did we decide about payment?"           │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ SmartSearchView                                                  │
│   └─► SmartSearchViewModel.search(query)                        │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ SmartSearchService.search(query)                                 │
│   └─► FunctionCallingService.searchMessages(query)              │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ HTTP Callable Function: searchMessages                           │
│   ├─► 1. Generate query embedding (OpenAI)                      │
│   ├─► 2. Vector search in Pinecone                              │
│   ├─► 3. Get top 10 similar messages                            │
│   ├─► 4. Fetch full message data from Firestore                 │
│   ├─► 5. Re-rank by relevance + recency                         │
│   └─► 6. Return SearchResult[]                                  │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ SmartSearchView Displays Results                                 │
│   - List of messages with relevance scores                       │
│   - Context snippets highlighted                                 │
│   - Tap to jump to full conversation                             │
│   - Transparency: "Why I found these" (AITransparencyView)      │
└──────────────────────────────────────────────────────────────────┘
```

---

### Pattern 4: Proactive Meeting Suggestion

```
┌──────────────────────────────────────────────────────────────────┐
│ Background: onMessageCreated Trigger Detects                     │
│ "Let's sync on the API project" (from Sarah)                    │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ Cloud Function: detectSchedulingNeed()                           │
│   ├─► Analyze message content (GPT-4)                           │
│   ├─► Detect: Meeting request                                   │
│   ├─► Extract: Participants, topic, urgency                     │
│   └─► Trigger: suggestMeetingTimes()                            │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ Cloud Function: suggestMeetingTimes()                            │
│   ├─► 1. Fetch user preferences (focus hours)                   │
│   ├─► 2. Check iOS Calendar via API                             │
│   ├─► 3. Find mutual availability                               │
│   ├─► 4. Rank by convenience                                    │
│   ├─► 5. Store in Firestore /users/{id}/aiState/                │
│   └─► 6. Send FCM notification to iOS                           │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ iOS Receives Notification                                        │
│   └─► NotificationService handles                                │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│ MeetingSuggestionsView Displays                                  │
│   - Who wants to meet                                            │
│   - Suggested times (ranked)                                     │
│   - AI reasoning (respects focus hours)                          │
│   - [Book] [Suggest Different Times] [Ignore]                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Dependencies & Integration

### iOS Dependencies (Swift Package Manager)

```swift
// Package.swift
dependencies: [
    // Firebase
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
    
    // Required Firebase products
    .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
    .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
    .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
    .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
    .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
    .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
    .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
    .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
]
```

### Backend Dependencies (npm)

```json
// functions/package.json
{
  "dependencies": {
    // Core
    "firebase-admin": "^11.0.0",
    "firebase-functions": "^4.0.0",
    
    // AI Services
    "openai": "^4.0.0",
    "@pinecone-database/pinecone": "^1.0.0",
    // OR
    "weaviate-ts-client": "^2.0.0",
    
    // Utilities
    "axios": "^1.4.0",
    "lodash": "^4.17.21",
    "date-fns": "^2.30.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0",
    "ts-node": "^10.9.0",
    "eslint": "^8.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0"
  }
}
```

### External Service Dependencies

| Service | Purpose | Required For | Cost Model |
|---------|---------|--------------|------------|
| **OpenAI API** | GPT-4, Embeddings | All AI features | Pay-per-token (~$0.03/1K tokens GPT-4, ~$0.0001/1K tokens embeddings) |
| **Pinecone** | Vector database | RAG, Smart Search | Free tier: 1M vectors, then $0.096/hour/pod |
| **Weaviate** | Alternative vector DB | RAG, Smart Search | Free tier: 1M vectors, self-hosted free |
| **Firebase** | Backend platform | Everything | Spark: Free, Blaze: Pay-as-you-go |
| **Apple Calendar API** | Calendar integration | Meeting suggestions | Free (iOS SDK) |

### Service Integration Points

```typescript
// Environment configuration
interface ServiceConfig {
    // Firebase (auto-configured via SDK)
    firebaseConfig: {
        projectId: string;
        apiKey: string;
        // ... other Firebase config
    };
    
    // OpenAI
    openai: {
        apiKey: string;
        organization?: string;
        timeout: number; // 30000ms default
    };
    
    // Vector Database (choose one)
    pinecone?: {
        apiKey: string;
        environment: string;
        indexName: string;
    };
    weaviate?: {
        url: string;
        apiKey: string;
        scheme: 'http' | 'https';
    };
    
    // Feature Flags
    features: {
        aiEnabled: boolean;
        ragPipeline: boolean;
        threadSummarization: boolean;
        actionItems: boolean;
        smartSearch: boolean;
        priorityDetection: boolean;
        decisionTracking: boolean;
        proactiveAssistant: boolean;
    };
    
    // Rate Limits
    rateLimits: {
        openaiRequestsPerMinute: number; // 60
        embeddingsPerMinute: number; // 3000
        vectorSearchPerMinute: number; // 1000
    };
}
```

---

## Environment Management

### iOS Environment (Xcode Configurations)

```swift
// Utilities/Constants.swift
enum Environment {
    case development
    case staging
    case production
    
    static var current: Environment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
    
    var firebaseConfigFile: String {
        switch self {
        case .development:
            return "GoogleService-Info-Dev"
        case .staging:
            return "GoogleService-Info-Staging"
        case .production:
            return "GoogleService-Info"
        }
    }
    
    var apiBaseURL: String {
        switch self {
        case .development:
            return "http://localhost:5001/your-project/us-central1"
        case .staging:
            return "https://us-central1-your-project-staging.cloudfunctions.net"
        case .production:
            return "https://us-central1-your-project.cloudfunctions.net"
        }
    }
}
```

### Backend Environment (Firebase Functions)

```bash
# functions/.env.development
OPENAI_API_KEY=sk-...
PINECONE_API_KEY=...
PINECONE_ENV=us-east-1-aws
PINECONE_INDEX=chat-messages-dev

AI_ENABLED=true
RAG_PIPELINE_ENABLED=true
LOG_LEVEL=debug

# functions/.env.production
OPENAI_API_KEY=sk-...
PINECONE_API_KEY=...
PINECONE_ENV=us-east-1-aws
PINECONE_INDEX=chat-messages-prod

AI_ENABLED=true
RAG_PIPELINE_ENABLED=true
LOG_LEVEL=info
```

### Firebase Environment Variables (Secure)

```bash
# Set in Firebase Console or via CLI
firebase functions:config:set \
  openai.key="sk-..." \
  openai.org="org-..." \
  pinecone.key="..." \
  pinecone.env="us-east-1-aws" \
  pinecone.index="chat-messages"

# Access in code
const openaiKey = functions.config().openai.key;
```

### Environment-Specific Builds

```bash
# iOS
# Development build (local Firebase emulators)
xcodebuild -scheme MessageAI-Dev -configuration Debug

# Staging build (staging Firebase project)
xcodebuild -scheme MessageAI-Staging -configuration Release

# Production build (production Firebase project)
xcodebuild -scheme MessageAI -configuration Release

# Backend
# Development deployment
firebase use development
firebase deploy --only functions

# Production deployment
firebase use production
firebase deploy --only functions
```

---

## Security Architecture

### 1. Authentication Flow
```
User Signs Up/In
    ↓
Firebase Auth validates credentials
    ↓
Returns JWT token (automatically managed by SDK)
    ↓
Token auto-attached to all Firebase requests
    ↓
Firestore Security Rules validate token
    ↓
Cloud Functions validate token via admin SDK
```

### 2. Firestore Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isChatParticipant(chatId) {
      return request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
    }
    
    // User profiles (public read, owner write)
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
      
      // AI preferences (owner only)
      match /preferences/{document=**} {
        allow read, write: if isOwner(userId);
      }
      
      // AI state (owner only)
      match /aiState/{document=**} {
        allow read, write: if isOwner(userId);
      }
      
      // Learning data (owner only)
      match /learningData/{document=**} {
        allow read, write: if isOwner(userId);
      }
      
      // Decisions (owner only)
      match /decisions/{document=**} {
        allow read, write: if isOwner(userId);
      }
    }
    
    // Chats (participants only)
    match /chats/{chatId} {
      allow read: if isChatParticipant(chatId);
      allow create: if isAuthenticated() && request.auth.uid in request.resource.data.participants;
      allow update: if isChatParticipant(chatId);
      allow delete: if isChatParticipant(chatId);
      
      // Messages (participants only)
      match /messages/{messageId} {
        allow read: if isChatParticipant(chatId);
        allow create: if isChatParticipant(chatId) && request.auth.uid == request.resource.data.senderId;
        allow update: if isChatParticipant(chatId);
        allow delete: if isChatParticipant(chatId) && request.auth.uid == resource.data.senderId;
      }
    }
  }
}
```

### 3. Cloud Functions Security

```typescript
// Validate authenticated user
export const summarizeThread = functions.https.onCall(async (data, context) => {
    // Enforce authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated'
        );
    }
    
    const userId = context.auth.uid;
    const { chatId } = data;
    
    // Validate user is chat participant
    const chat = await admin.firestore().doc(`chats/${chatId}`).get();
    if (!chat.exists || !chat.data()?.participants.includes(userId)) {
        throw new functions.https.HttpsError(
            'permission-denied',
            'User not authorized to access this chat'
        );
    }
    
    // Proceed with function logic
});
```

### 4. Data Privacy Measures

```typescript
// PR #AI-002: 90-day auto-cleanup
export const cleanupOldAIData = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - 90);
        
        // Cleanup old AI state
        const users = await admin.firestore().collection('users').get();
        
        for (const userDoc of users.docs) {
            // Clean conversation history
            const oldMessages = await userDoc.ref
                .collection('aiState')
                .doc('conversationHistory')
                .collection('messages')
                .where('timestamp', '<', cutoff)
                .get();
            
            const batch = admin.firestore().batch();
            oldMessages.docs.forEach(doc => batch.delete(doc.ref));
            await batch.commit();
        }
    });
```

### 5. API Key Security

- **Never commit API keys to git**
- Store in Firebase Functions config (encrypted)
- Use environment variables locally
- Rotate keys every 90 days
- Monitor API usage for anomalies

### 6. Vector Database Security

```typescript
// Pinecone: Namespace isolation per user
await pinecone.upsert({
    vectors: [...],
    namespace: userId, // Isolate user data
});

// Weaviate: Tenant isolation
await weaviate
    .data.creator()
    .withClassName('Message')
    .withProperties(...)
    .withTenant(userId) // Isolate user data
    .do();
```

---

## Deployment Architecture

### Development Environment
```
Local Machine
├── Xcode (iOS app)
├── Firebase Emulators
│   ├── Firestore Emulator (localhost:8080)
│   ├── Auth Emulator (localhost:9099)
│   ├── Functions Emulator (localhost:5001)
│   └── Storage Emulator (localhost:9199)
└── External Services (dev keys)
    ├── OpenAI API
    └── Pinecone/Weaviate (dev index)
```

### Staging Environment
```
Firebase Staging Project
├── Firestore (staging data)
├── Firebase Auth (test users)
├── Cloud Functions (us-central1)
├── Firebase Storage
└── External Services (staging keys)
    ├── OpenAI API
    └── Pinecone/Weaviate (staging index)

TestFlight
└── iOS App (staging build)
```

### Production Environment
```
Firebase Production Project
├── Firestore (multi-region)
│   ├── Primary: us-central1
│   └── Backup: us-east1
├── Firebase Auth (real users)
├── Cloud Functions (multi-region)
│   ├── us-central1
│   └── europe-west1
├── Firebase Storage (us-central1)
├── Firebase Hosting (optional web admin)
└── External Services (production keys)
    ├── OpenAI API (production quota)
    └── Pinecone/Weaviate (production index)

App Store
└── iOS App (production build)
```

### CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run iOS tests
        run: xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 14'
  
  test-functions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: cd functions && npm ci
      - name: Run tests
        run: cd functions && npm test
      - name: Lint
        run: cd functions && npm run lint
  
  deploy-staging:
    needs: [test-ios, test-functions]
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Firebase Staging
        run: |
          npm install -g firebase-tools
          firebase use staging
          firebase deploy --only functions
  
  deploy-production:
    needs: [test-ios, test-functions]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Firebase Production
        run: |
          npm install -g firebase-tools
          firebase use production
          firebase deploy --only functions
```

### Monitoring & Alerting

```typescript
// Firebase Performance Monitoring
import { trace } from '@firebase/performance';

// Monitor AI function performance
const summarizeTrace = trace('ai_summarize_thread');
summarizeTrace.start();
// ... function logic ...
summarizeTrace.stop();

// Custom metrics
const metric = summarizeTrace.putMetric('message_count', messageCount);

// Firebase Analytics events
import { logEvent } from '@firebase/analytics';

logEvent(analytics, 'ai_feature_used', {
    feature: 'thread_summarization',
    success: true,
    response_time_ms: 1234,
    confidence: 'high',
});
```

---

## File Structure (Complete)

### Full Project Structure

```
MessageAI/
├── MessageAI/                           # iOS App Target
│   ├── MessageAIApp.swift               # App entry point
│   │
│   ├── Models/
│   │   ├── Core/
│   │   │   ├── User.swift
│   │   │   ├── Chat.swift
│   │   │   ├── Message.swift
│   │   │   ├── Presence.swift
│   │   │   └── Notification.swift
│   │   │
│   │   └── AI/
│   │       ├── UserPreferences.swift         // PR #AI-002
│   │       ├── FocusHours.swift              // PR #AI-002
│   │       ├── PriorityRule.swift            // PR #AI-002
│   │       ├── AISessionContext.swift        // PR #AI-004
│   │       ├── AITaskState.swift             // PR #AI-004
│   │       ├── AIConversationMessage.swift   // PR #AI-004
│   │       ├── AIError.swift                 // PR #AI-005
│   │       ├── ThreadSummary.swift           // PR #AI-006
│   │       ├── ActionItem.swift              // PR #AI-007
│   │       ├── SearchResult.swift            // PR #AI-008
│   │       ├── MessageCategory.swift         // PR #AI-009
│   │       ├── Decision.swift                // PR #AI-010
│   │       ├── MeetingSuggestion.swift       // PR #AI-011
│   │       └── CalendarAvailability.swift    // PR #AI-011
│   │
│   ├── Views/
│   │   ├── Authentication/
│   │   │   ├── LoginView.swift
│   │   │   ├── SignUpView.swift
│   │   │   └── PasswordResetView.swift
│   │   │
│   │   ├── ChatList/
│   │   │   ├── ChatListView.swift
│   │   │   ├── ChatRowView.swift
│   │   │   └── CreateNewChatView.swift
│   │   │
│   │   ├── Conversation/
│   │   │   ├── ConversationView.swift
│   │   │   ├── MessageRow.swift
│   │   │   ├── MessageInputView.swift
│   │   │   └── TypingIndicatorView.swift
│   │   │
│   │   ├── Profile/
│   │   │   ├── ProfileView.swift
│   │   │   └── EditProfileView.swift
│   │   │
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   └── NotificationSettingsView.swift
│   │   │
│   │   └── AI/
│   │       ├── PreferencesSettingsView.swift      // PR #AI-002
│   │       ├── AITransparencyView.swift           // PR #AI-012
│   │       ├── ThreadSummaryView.swift            // PR #AI-006
│   │       ├── ActionItemsView.swift              // PR #AI-007
│   │       ├── SmartSearchView.swift              // PR #AI-008
│   │       ├── PriorityInboxView.swift            // PR #AI-009
│   │       ├── DecisionHistoryView.swift          // PR #AI-010
│   │       └── MeetingSuggestionsView.swift       // PR #AI-011
│   │
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── ChatListViewModel.swift
│   │   ├── ConversationViewModel.swift
│   │   ├── ProfileViewModel.swift
│   │   │
│   │   └── AI/
│   │       ├── ThreadSummaryViewModel.swift       // PR #AI-006
│   │       ├── ActionItemsViewModel.swift         // PR #AI-007
│   │       ├── SmartSearchViewModel.swift         // PR #AI-008
│   │       ├── PriorityInboxViewModel.swift       // PR #AI-009
│   │       ├── DecisionHistoryViewModel.swift     // PR #AI-010
│   │       └── MeetingSuggestionsViewModel.swift  // PR #AI-011
│   │
│   ├── Services/
│   │   ├── Core/
│   │   │   ├── FirebaseService.swift
│   │   │   ├── AuthService.swift
│   │   │   ├── ChatService.swift
│   │   │   ├── MessageService.swift
│   │   │   ├── PresenceService.swift
│   │   │   ├── NotificationService.swift
│   │   │   └── StorageService.swift
│   │   │
│   │   └── AI/
│   │       ├── Core/
│   │       │   ├── AIService.swift
│   │       │   ├── PreferencesService.swift           // PR #AI-002
│   │       │   ├── MemoryService.swift                // PR #AI-004
│   │       │   └── FunctionCallingService.swift       // PR #AI-003
│   │       │
│   │       ├── Features/
│   │       │   ├── ThreadSummarizationService.swift   // PR #AI-006
│   │       │   ├── ActionItemService.swift            // PR #AI-007
│   │       │   ├── SmartSearchService.swift           // PR #AI-008
│   │       │   ├── PriorityDetectionService.swift     // PR #AI-009
│   │       │   ├── DecisionTrackingService.swift      // PR #AI-010
│   │       │   └── ProactiveAssistantService.swift    // PR #AI-011
│   │       │
│   │       └── Infrastructure/
│   │           ├── EmbeddingService.swift             // PR #AI-001
│   │           ├── VectorSearchService.swift          // PR #AI-001
│   │           └── AIErrorHandler.swift               // PR #AI-005
│   │
│   ├── Utilities/
│   │   ├── Constants.swift
│   │   ├── AppError.swift
│   │   ├── Logger.swift
│   │   │
│   │   └── Extensions/
│   │       ├── Date+Extensions.swift
│   │       ├── View+Extensions.swift
│   │       ├── String+Extensions.swift
│   │       └── Color+Extensions.swift
│   │
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   ├── AccentColor.colorset/
│   │   └── Colors/
│   │       ├── CalmBlue.colorset/
│   │       ├── CalmGreen.colorset/
│   │       └── SoftOrange.colorset/
│   │
│   ├── GoogleService-Info.plist        # Production Firebase config
│   ├── GoogleService-Info-Dev.plist    # Development Firebase config
│   ├── GoogleService-Info-Staging.plist # Staging Firebase config
│   ├── Info.plist
│   └── MessageAI.entitlements
│
├── MessageAITests/
│   ├── Services/
│   │   ├── AuthServiceTests.swift
│   │   ├── ChatServiceTests.swift
│   │   ├── MessageServiceTests.swift
│   │   │
│   │   └── AI/
│   │       ├── PreferencesServiceTests.swift
│   │       ├── MemoryServiceTests.swift
│   │       ├── FunctionCallingServiceTests.swift
│   │       ├── ThreadSummarizationServiceTests.swift
│   │       ├── ActionItemServiceTests.swift
│   │       ├── SmartSearchServiceTests.swift
│   │       ├── PriorityDetectionServiceTests.swift
│   │       ├── DecisionTrackingServiceTests.swift
│   │       └── ProactiveAssistantServiceTests.swift
│   │
│   ├── ViewModels/
│   │   ├── AuthViewModelTests.swift
│   │   └── AI/
│   │       ├── ThreadSummaryViewModelTests.swift
│   │       └── ... (other ViewModel tests)
│   │
│   └── Mocks/
│       ├── MockFirebaseService.swift
│       ├── MockAuthService.swift
│       └── MockAIService.swift
│
├── MessageAIUITests/
│   ├── AuthenticationFlowUITests.swift
│   ├── ChatListUITests.swift
│   ├── ConversationUITests.swift
│   │
│   └── AI/
│       ├── ThreadSummarizationUITests.swift
│       ├── ActionItemsUITests.swift
│       ├── SmartSearchUITests.swift
│       ├── PriorityInboxUITests.swift
│       └── ... (other UI tests)
│
├── functions/                          # Firebase Cloud Functions
│   ├── src/
│   │   ├── index.ts                    # Function exports
│   │   │
│   │   ├── rag/                        # PR #AI-001
│   │   │   ├── embeddings.ts
│   │   │   ├── vectorSearch.ts
│   │   │   ├── semanticQuery.ts
│   │   │   └── indexing.ts
│   │   │
│   │   ├── functions/                  # PR #AI-003
│   │   │   ├── summarizeThread.ts
│   │   │   ├── extractActionItems.ts
│   │   │   ├── searchMessages.ts
│   │   │   ├── categorizeMessage.ts
│   │   │   ├── trackDecisions.ts
│   │   │   ├── detectScheduling.ts
│   │   │   ├── suggestMeetings.ts
│   │   │   └── executeFunction.ts
│   │   │
│   │   ├── triggers/
│   │   │   ├── onMessageCreated.ts
│   │   │   ├── onUserStatusChanged.ts
│   │   │   └── onPreferenceUpdated.ts
│   │   │
│   │   ├── notifications/
│   │   │   ├── sendMessageNotification.ts
│   │   │   └── sendAIAlertNotification.ts
│   │   │
│   │   ├── errors/                     # PR #AI-005
│   │   │   ├── AIError.ts
│   │   │   ├── errorHandler.ts
│   │   │   ├── fallbacks.ts
│   │   │   └── retryQueue.ts
│   │   │
│   │   ├── utils/
│   │   │   ├── openai.ts
│   │   │   ├── pinecone.ts
│   │   │   ├── weaviate.ts
│   │   │   ├── firestore.ts
│   │   │   ├── validation.ts
│   │   │   └── logger.ts
│   │   │
│   │   └── types/
│   │       ├── messages.ts
│   │       ├── ai.ts
│   │       └── functions.ts
│   │
│   ├── lib/                            # Compiled JavaScript
│   ├── node_modules/
│   ├── package.json
│   ├── package-lock.json
│   ├── tsconfig.json
│   ├── .env.development
│   ├── .env.staging
│   ├── .env.production
│   └── .eslintrc.js
│
├── docs/                               # Documentation
│   ├── AI-PRODUCT-VISION.md
│   ├── ai-assignment-specification.md
│   ├── ai-build-plan.md
│   ├── architecture.md
│   ├── architecture-comprehensive.md   # THIS FILE
│   ├── userpersona.md
│   │
│   ├── prds/
│   │   └── ... (feature PRDs)
│   │
│   ├── pr-brief/
│   │   └── ... (implementation briefs)
│   │
│   └── sprints/
│       └── ... (sprint planning)
│
├── .github/
│   └── workflows/
│       ├── deploy.yml
│       ├── test-ios.yml
│       └── test-functions.yml
│
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── storage.rules
├── .gitignore
├── .firebaserc
└── README.md
```

---

## Quick Reference: Tech Stack Summary

### iOS Stack
- **Language**: Swift 5.9+
- **UI**: SwiftUI (iOS 16+)
- **Architecture**: MVVM
- **Concurrency**: async/await
- **Dependencies**: SPM
- **Backend SDK**: Firebase iOS SDK 10.x

### Backend Stack
- **Runtime**: Node.js 18 LTS
- **Language**: TypeScript 5.x
- **Platform**: Firebase (Firestore, Auth, Storage, Functions, FCM, Analytics, Remote Config)
- **Serverless**: Cloud Functions Gen 2

### AI Stack
- **LLM**: OpenAI GPT-4
- **Embeddings**: OpenAI text-embedding-3-small (1536 dim)
- **Vector DB**: Pinecone OR Weaviate
- **RAG**: Custom TypeScript pipeline
- **Function Calling**: OpenAI Functions API

### DevOps Stack
- **VCS**: Git + GitHub
- **CI/CD**: GitHub Actions
- **Monitoring**: Firebase Crashlytics, Performance, Analytics
- **Testing**: XCTest, XCUITest, Jest (backend)

---

## Implementation Phases Mapped to Architecture

### Phase 1: Foundation (Weeks 1-2)
**Infrastructure Layer**
- RAG Pipeline (PR #AI-001): `functions/src/rag/`, Pinecone/Weaviate setup
- User Preferences (PR #AI-002): `/users/{id}/preferences/`, iOS PreferencesService
- Function Calling (PR #AI-003): `functions/src/functions/`, iOS FunctionCallingService
- Memory/State (PR #AI-004): `/users/{id}/aiState/`, iOS MemoryService
- Error Handling (PR #AI-005): `functions/src/errors/`, iOS AIErrorHandler

### Phase 2: Core AI - Batch 1 (Weeks 3-4)
**Feature Layer**
- Thread Summarization (PR #AI-006): iOS UI + backend function
- Action Items (PR #AI-007): iOS UI + backend function
- Smart Search (PR #AI-008): iOS UI + backend RAG query

### Phase 3: Core AI - Batch 2 (Weeks 5-6)
**Intelligence Layer**
- Priority Detection (PR #AI-009): Background categorization + iOS UI
- Decision Tracking (PR #AI-010): Pattern detection + iOS UI
- Proactive Assistant (PR #AI-011): Meeting detection + iOS UI

### Phase 4: Integration & Polish (Weeks 7-8)
**Quality & Deployment Layer**
- Transparency System (PR #AI-012): Reusable transparency component
- Integration Testing (PR #AI-013): Cross-feature test suite
- UX Polish (PR #AI-014): Calm Intelligence design system
- Production Deployment (PR #AI-015): Feature flags, monitoring, rollout

---

**Document Status:** ✅ Complete  
**Last Updated:** October 24, 2025  
**Maintained By:** Infrastructure & Architecture Team  
**Next Review:** After Phase 1 completion

This architecture supports **Calm Intelligence** at every layer: from serverless scaling to graceful error handling to forgiving UI patterns. The system is designed to help Maya spend LESS time in the app while feeling MORE in control. 🎯


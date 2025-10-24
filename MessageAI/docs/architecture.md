# MessageAI Architecture
**Version:** 2.0 - AI-Enhanced  
**Last Updated:** October 24, 2025

---

## System Overview

```
iOS App (SwiftUI + Swift)
    ↓
Firebase SDK
    ↓
┌─────────────────┬──────────────────┬────────────────┐
│   Firebase      │  Cloud Functions │   AI Services  │
│   Services      │   (Node.js/TS)   │   Ecosystem    │
├─────────────────┼──────────────────┼────────────────┤
│ • Firestore     │ • RAG Pipeline   │ • OpenAI GPT-4 │
│ • Auth          │ • AI Functions   │ • Embeddings   │
│ • Storage       │ • Notifications  │ • Pinecone OR  │
│ • FCM           │ • Triggers       │   Weaviate     │
│ • Remote Config │                  │                │
└─────────────────┴──────────────────┴────────────────┘
```

**Architecture Pattern:** MVVM (Views → ViewModels → Services → Models)  
**Concurrency:** async/await throughout  
**Offline-First:** Local cache + Firebase sync  
**AI Integration:** Service layer (not UI)

---

## Tech Stack

### iOS
- **Language:** Swift 5.9+
- **UI:** SwiftUI (iOS 16+)
- **Backend SDK:** Firebase iOS SDK 10.x
- **Dependencies:** Swift Package Manager

### Backend
- **Runtime:** Node.js 18 LTS
- **Language:** TypeScript 5.x
- **Platform:** Firebase (Firestore, Auth, Storage, Functions, FCM)

### AI Services
- **LLM:** OpenAI GPT-4
- **Embeddings:** text-embedding-3-small (1536 dim)
- **Vector DB:** Pinecone OR Weaviate
- **Cost:** ~$0.03/1K tokens (GPT-4), ~$0.0001/1K tokens (embeddings)

---

## Project Structure

### iOS File Organization

```
MessageAI/MessageAI/
├── App/
│   └── MessageAIApp.swift
│
├── Models/
│   ├── Core/                    # Existing
│   │   ├── User.swift
│   │   ├── Chat.swift
│   │   └── Message.swift
│   │
│   └── AI/                      # NEW: AI features
│       ├── UserPreferences.swift
│       ├── ThreadSummary.swift
│       ├── ActionItem.swift
│       ├── SearchResult.swift
│       ├── MessageCategory.swift
│       ├── Decision.swift
│       └── MeetingSuggestion.swift
│
├── Views/
│   ├── Authentication/
│   ├── ChatList/
│   ├── Conversation/
│   ├── Profile/
│   ├── Settings/
│   │
│   └── AI/                      # NEW: AI UI
│       ├── PreferencesSettingsView.swift
│       ├── AITransparencyView.swift (reusable)
│       ├── ThreadSummaryView.swift
│       ├── ActionItemsView.swift
│       ├── SmartSearchView.swift
│       ├── PriorityInboxView.swift
│       ├── DecisionHistoryView.swift
│       └── MeetingSuggestionsView.swift
│
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── ChatListViewModel.swift
│   ├── ConversationViewModel.swift
│   │
│   └── AI/                      # NEW: AI state
│       ├── ThreadSummaryViewModel.swift
│       ├── ActionItemsViewModel.swift
│       ├── SmartSearchViewModel.swift
│       ├── PriorityInboxViewModel.swift
│       ├── DecisionHistoryViewModel.swift
│       └── MeetingSuggestionsViewModel.swift
│
├── Services/
│   ├── Core/                    # Existing
│   │   ├── AuthService.swift
│   │   ├── ChatService.swift
│   │   ├── MessageService.swift
│   │   ├── PresenceService.swift
│   │   └── NotificationService.swift
│   │
│   └── AI/                      # NEW: AI business logic
│       ├── PreferencesService.swift
│       ├── MemoryService.swift
│       ├── FunctionCallingService.swift
│       ├── ThreadSummarizationService.swift
│       ├── ActionItemService.swift
│       ├── SmartSearchService.swift
│       ├── PriorityDetectionService.swift
│       ├── DecisionTrackingService.swift
│       └── ProactiveAssistantService.swift
│
└── Utilities/
    ├── Constants.swift
    ├── AppError.swift
    └── Extensions/
```

### Backend File Organization

```
functions/src/
├── index.ts                     # Function exports
│
├── rag/                         # PR #AI-001: RAG Pipeline
│   ├── embeddings.ts
│   ├── vectorSearch.ts
│   └── semanticQuery.ts
│
├── functions/                   # PR #AI-003: AI Functions
│   ├── summarizeThread.ts
│   ├── extractActionItems.ts
│   ├── searchMessages.ts
│   ├── categorizeMessage.ts
│   ├── trackDecisions.ts
│   ├── detectScheduling.ts
│   └── suggestMeetings.ts
│
├── triggers/                    # Firestore Triggers
│   ├── onMessageCreated.ts     # Auto-embed + categorize
│   └── onPreferenceUpdated.ts
│
├── errors/                      # PR #AI-005: Error Handling
│   ├── AIError.ts
│   ├── errorHandler.ts
│   └── fallbacks.ts
│
└── utils/
    ├── openai.ts               # OpenAI client
    ├── pinecone.ts             # Vector DB client
    ├── firestore.ts
    └── logger.ts
```

---

## Data Schema

### Existing Collections

```
/users/{userId}
  - email, displayName, photoURL, phoneNumber
  - status: "online" | "offline" | "away"
  - lastSeen: timestamp

/chats/{chatId}
  - type: "direct" | "group"
  - participants: string[]
  - lastMessage: { text, senderId, timestamp }

/chats/{chatId}/messages/{messageId}
  - senderId, text, timestamp
  - readBy: string[]
  - type: "text" | "image" | "file"
```

### NEW: AI Collections

```
/users/{userId}/preferences/           # PR #AI-002
  - focusHours: { enabled, startTime, endTime, daysOfWeek }
  - urgentContacts: string[]
  - urgentKeywords: string[]
  - communicationTone: "professional" | "friendly"

/users/{userId}/aiState/               # PR #AI-004
  - sessionContext: { currentConversation, recentQueries }
  - taskState: { actionItems: [], decisions: [] }
  - conversationHistory: AIConversationMessage[]

/users/{userId}/decisions/             # PR #AI-010
/{decisionId}
  - text, participants, timestamp
  - threadId, messageId
  - confidence, context, tags

/chats/{chatId}/messages/{messageId}   # Enhanced with AI
  - ...existing fields...
  - embeddingGenerated: boolean        # PR #AI-001
  - searchableMetadata: {              # PR #AI-001
      keywords: string[]
      participants: string[]
      decisionMade: boolean
    }
  - categoryPrediction: {              # PR #AI-009
      category: "urgent" | "can_wait" | "ai_handled"
      confidence: number
      reasoning: string
    }
```

---

## Key Data Flows

### 1. Message Send with AI Processing

```
User sends message
    ↓
MessageService.sendMessage() → Firestore.addDocument()
    ↓
Cloud Function Trigger: onMessageCreated
    ├─► Generate embedding (OpenAI) → Store in Pinecone
    ├─► Categorize message (urgent/can_wait/ai_handled)
    ├─► Extract action items
    ├─► Detect decisions
    └─► Check scheduling needs
    ↓
Update Firestore with AI metadata
    ↓
Real-time listener updates iOS UI
```

### 2. Thread Summarization

```
User long-presses chat → "Summarize"
    ↓
ThreadSummaryViewModel.requestSummary()
    ↓
FunctionCallingService.summarizeThread(chatId)
    ↓
HTTP Callable Function: summarizeThread
    ├─► Fetch messages from Firestore
    ├─► Fetch embeddings from Pinecone (RAG)
    ├─► Build context for GPT-4
    └─► Call OpenAI with summarization prompt
    ↓
Return ThreadSummary to iOS
    ↓
Display in ThreadSummaryView with transparency
```

### 3. Smart Search (RAG)

```
User types query: "What did we decide about payment?"
    ↓
SmartSearchService.search(query)
    ↓
HTTP Callable Function: searchMessages
    ├─► Generate query embedding (OpenAI)
    ├─► Vector search in Pinecone
    ├─► Get top 10 similar messages
    └─► Fetch full data from Firestore
    ↓
Return ranked SearchResult[]
    ↓
Display with context snippets + transparency
```

---

## Service Dependencies

### iOS Service Pattern

```swift
protocol MessageService {
    func sendMessage(_ message: Message, to chatId: String) async throws
    func fetchMessages(chatId: String) async throws -> [Message]
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

### Backend Function Pattern

```typescript
// HTTP Callable Function
export const summarizeThread = functions.https.onCall(async (data, context) => {
    // 1. Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }
    
    // 2. Validate permissions
    const userId = context.auth.uid;
    const { chatId } = data;
    
    // 3. Execute AI logic
    const messages = await fetchMessages(chatId);
    const summary = await openai.summarize(messages);
    
    // 4. Return result
    return summary;
});
```

---

## Environment Setup

### iOS Environments

```swift
// Utilities/Constants.swift
enum Environment {
    case development  // Local Firebase emulators
    case staging      // Staging Firebase project
    case production   // Production Firebase project
    
    var firebaseConfigFile: String {
        switch self {
        case .development: return "GoogleService-Info-Dev"
        case .staging: return "GoogleService-Info-Staging"
        case .production: return "GoogleService-Info"
        }
    }
}
```

### Backend Environment Variables

```bash
# functions/.env.production
OPENAI_API_KEY=sk-...
PINECONE_API_KEY=...
PINECONE_ENV=us-east-1-aws
PINECONE_INDEX=chat-messages-prod

AI_ENABLED=true
RAG_PIPELINE_ENABLED=true
```

```bash
# Set via Firebase CLI (secure)
firebase functions:config:set \
  openai.key="sk-..." \
  pinecone.key="..." \
  pinecone.env="us-east-1-aws"
```

---

## Security

### Firestore Rules (Simplified)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isChatParticipant(chatId) {
      return request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
    }
    
    // User data: owner only
    match /users/{userId}/{document=**} {
      allow read, write: if isOwner(userId);
    }
    
    // Chats & messages: participants only
    match /chats/{chatId} {
      allow read: if isChatParticipant(chatId);
      
      match /messages/{messageId} {
        allow read: if isChatParticipant(chatId);
        allow create: if isChatParticipant(chatId) && 
                         request.auth.uid == request.resource.data.senderId;
      }
    }
  }
}
```

### Cloud Function Security

```typescript
// Validate user authorization
export const summarizeThread = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
    
    const userId = context.auth.uid;
    const { chatId } = data;
    
    // Check user is participant
    const chat = await admin.firestore().doc(`chats/${chatId}`).get();
    if (!chat.data()?.participants.includes(userId)) {
        throw new functions.https.HttpsError('permission-denied', 'Not authorized');
    }
    
    // Proceed...
});
```

---

## AI Feature Mapping

| Feature | iOS Service | Cloud Function | PR # |
|---------|------------|----------------|------|
| **RAG Pipeline** | EmbeddingService | embeddings.ts, vectorSearch.ts | AI-001 |
| **User Preferences** | PreferencesService | - | AI-002 |
| **Function Calling** | FunctionCallingService | executeFunction.ts | AI-003 |
| **Memory/State** | MemoryService | - | AI-004 |
| **Error Handling** | AIErrorHandler | errorHandler.ts | AI-005 |
| **Thread Summary** | ThreadSummarizationService | summarizeThread.ts | AI-006 |
| **Action Items** | ActionItemService | extractActionItems.ts | AI-007 |
| **Smart Search** | SmartSearchService | searchMessages.ts | AI-008 |
| **Priority Detection** | PriorityDetectionService | categorizeMessage.ts | AI-009 |
| **Decision Tracking** | DecisionTrackingService | trackDecisions.ts | AI-010 |
| **Proactive Assistant** | ProactiveAssistantService | detectScheduling.ts, suggestMeetings.ts | AI-011 |

---

## Dependencies

### iOS (Swift Package Manager)

```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
]

targets: [
    .target(
        name: "MessageAI",
        dependencies: [
            .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
            .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
            .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
            .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
        ]
    )
]
```

### Backend (npm)

```json
{
  "dependencies": {
    "firebase-admin": "^11.0.0",
    "firebase-functions": "^4.0.0",
    "openai": "^4.0.0",
    "@pinecone-database/pinecone": "^1.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0"
  }
}
```

---

## Deployment

### CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main, develop]

jobs:
  test-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - run: xcodebuild test -scheme MessageAI
  
  test-functions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: cd functions && npm ci && npm test
  
  deploy-production:
    needs: [test-ios, test-functions]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: firebase deploy --only functions
```

### Rollout Strategy

1. **5%** alpha testers (Week 1)
2. **20%** early adopters (Week 2)
3. **50%** beta users (Week 3)
4. **100%** general availability (Week 4)

Use Firebase Remote Config for feature flags.

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Message Indexing | <500ms |
| Semantic Search | <1s |
| Full AI Response | <2s |
| Error Rate | <1% |
| Uptime | 99.9% |

---

## Quick Reference

### Development Commands

```bash
# iOS
xcodebuild -scheme MessageAI-Dev -configuration Debug

# Firebase emulators (local backend)
firebase emulators:start

# Deploy functions
firebase deploy --only functions

# Set environment variables
firebase functions:config:set openai.key="sk-..."
```

### Key Files

- **iOS Entry:** `MessageAI/MessageAIApp.swift`
- **Backend Entry:** `functions/src/index.ts`
- **Firestore Rules:** `firestore.rules`
- **Environment Config:** `functions/.env.production`

---

**Document Status:** ✅ Production Ready  
**Last Updated:** October 24, 2025  
**See Also:** `ai-build-plan.md` for detailed PR breakdown

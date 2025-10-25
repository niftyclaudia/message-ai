# PRD: Focus Mode with AI Prioritization

**Feature Name:** Focus Mode  
**Priority:** P0 (High Priority)  
**Status:** Planning  
**Owner:** Claudia Alban  
**Last Updated:** October 25, 2025

---

## 📋 Executive Summary

Focus Mode is an AI-powered feature that helps users manage incoming messages by automatically prioritizing urgent communications and hiding non-urgent ones. When activated, the app intelligently sorts conversations into "Priority" and "Review Later" sections, provides AI-generated summaries of important threads, and enables semantic search to find relevant messages by meaning rather than keywords.

**Key Value Proposition:**  
Help users stay focused on what matters most by letting AI handle message triage, reducing notification fatigue, and surfacing critical information when needed.

---

## 🎯 Goals & Success Metrics

### Primary Goals
1. **Reduce Cognitive Load:** Users should spend less mental energy deciding what to respond to
2. **Improve Response Time:** Urgent messages get faster attention (target: <5 min response time)
3. **Enable Deep Work:** Users can focus without missing important communications

### Success Metrics
- **Adoption Rate:** 60% of active users enable Focus Mode within first week
- **Accuracy:** 85%+ correct classification of urgent vs normal messages
- **Engagement:** Users keep Focus Mode active for 3+ hours per session
- **Satisfaction:** 4.5+ star rating for Focus Mode feature
- **Time Saved:** 15+ minutes saved daily per user on message triage

---

## 👤 User Stories

### Primary User Story
**As a busy professional**, I want messages automatically sorted by urgency so that I can focus on important work without constantly checking my phone for critical updates.

### Detailed User Flows

#### Flow 1: Basic Focus Mode Usage
1. User opens app → sees normal conversation list
2. User taps "Focus Mode" toggle → banner appears at top
3. User sends/receives messages during focus time
4. AI automatically tags messages as "urgent" or "normal"
5. App shows urgent chats in "Priority" section
6. App hides normal chats in collapsed "Review Later" section
7. User completes focus session, taps toggle off
8. User sees AI summary of what happened during focus time

#### Flow 2: Urgent Message Received During Focus
1. Focus Mode is active
2. Friend sends: "URGENT: Can you pick up Sarah from school? Emergency!"
3. AI classifies as urgent within 2-3 seconds
4. Chat jumps to top of Priority section
5. Push notification still fires (urgent messages not suppressed)
6. User sees and responds immediately

#### Flow 3: Smart Search for Past Messages
1. User needs to find message about meeting time
2. User opens search (available in any mode)
3. User types: "when is the team meeting"
4. AI semantic search finds messages containing:
   - "Team sync at 3pm tomorrow"
   - "Rescheduled our standup to Friday"
   - "Calendar invite for Thursday 2pm"
5. User taps result → navigates to message in chat

---

## 📐 Technical Specifications

### Architecture Overview

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   iOS App   │ ◄─────► │   Firestore  │ ◄─────► │   Cloud     │
│  (SwiftUI)  │         │   Database   │         │  Functions  │
└─────────────┘         └──────────────┘         └─────────────┘
                                                         │
                                                         ▼
                                                  ┌─────────────┐
                                                  │   OpenAI    │
                                                  │     API     │
                                                  └─────────────┘
                                                         │
                                                         ▼
                                                  ┌─────────────┐
                                                  │  Pinecone   │
                                                  │  Vector DB  │
                                                  └─────────────┘
```

### Technology Stack

**Backend:**
- Firebase Cloud Functions (Node.js/TypeScript)
- OpenAI API (GPT-3.5-turbo for classification, GPT-4-turbo for summaries)
- Pinecone vector database (semantic search)
- Cloud Firestore (primary database)

**Frontend:**
- Swift 5.0+ (iOS)
- SwiftUI framework
- Combine for reactive data binding
- MVVM architecture

**APIs & SDKs:**
- `openai` npm package (v4.x)
- `@pinecone-database/pinecone` npm package (v2.x)
- Firebase iOS SDK (v12.4.0)

---

## 🗄️ Data Models

### Firestore Schema Updates

#### Messages Collection (Updated)
```typescript
chats/{chatID}/messages/{messageID}
{
  // Existing fields
  id: string
  chatID: string
  senderID: string
  text: string
  timestamp: Timestamp
  serverTimestamp: Timestamp
  readBy: string[]
  status: "sending" | "sent" | "delivered" | "failed"
  
  // NEW FIELDS for Focus Mode
  priority: "urgent" | "normal"           // AI classification result
  classifiedAt: Timestamp                  // When classification happened
  classificationReason?: string            // Optional: Why it was classified
  embeddingGenerated: boolean              // For semantic search
}
```

#### User Preferences (New Collection)
```typescript
users/{userID}/preferences/focusMode
{
  isEnabled: boolean                       // Focus Mode currently active
  startTime: Timestamp                     // When current session started
  totalUsageTime: number                   // Cumulative hours used
  autoActivateHours?: {                    // Future: auto-activate schedule
    start: string                          // e.g., "09:00"
    end: string                            // e.g., "17:00"
    days: string[]                         // e.g., ["Mon", "Tue", "Wed"]
  }
  customKeywords?: string[]                // Future: user-defined urgent words
}
```

#### Focus Sessions (New Collection)
```typescript
users/{userID}/focusSessions/{sessionID}
{
  startTime: Timestamp
  endTime: Timestamp
  duration: number                         // In minutes
  priorityMessageCount: number
  normalMessageCount: number
  summary?: string                         // AI-generated summary
  actionItems?: string[]                   // Extracted action items
}
```

### iOS Data Models

#### MessagePriority Enum
```swift
enum MessagePriority: String, Codable {
    case urgent = "urgent"
    case normal = "normal"
}
```

#### Updated Message Model
```swift
struct Message: Identifiable, Codable {
    // Existing fields
    var id: String
    var chatID: String
    var senderID: String
    var text: String
    var timestamp: Date
    var serverTimestamp: Date?
    var readBy: [String]
    var status: MessageStatus
    
    // NEW FIELDS
    var priority: MessagePriority = .normal
    var classifiedAt: Date?
    var classificationReason: String?
}
```

#### FocusMode Model
```swift
struct FocusMode: Codable {
    var isActive: Bool = false
    var startTime: Date?
    var sessionID: String?
    var priorityCount: Int = 0
    var reviewLaterCount: Int = 0
}
```

#### FocusSummary Model
```swift
struct FocusSummary: Codable {
    var overview: String
    var actionItems: [String]
    var decisions: [String]
    var openQuestions: [String]
    var duration: TimeInterval
    var priorityChats: Int
}
```

---

## 🔧 Implementation Details

### Milestone 1: AI Prioritization + Focus Mode UI

#### Backend Components

**1. OpenAI Client Wrapper**
- **File:** `functions/src/services/openaiClient.ts`
- **Purpose:** Centralized OpenAI API client with error handling
- **Key Functions:**
  - `classifyMessageUrgency(text: string): Promise<ClassificationResult>`
  - `generateSummary(messages: Message[]): Promise<Summary>`
  - `generateEmbedding(text: string): Promise<number[]>`

**2. AI Prioritization Service**
- **File:** `functions/src/services/aiPrioritization.ts`
- **Purpose:** Message classification logic
- **Algorithm:**
  1. Extract message text
  2. Check for urgency keywords (fast path)
  3. If keywords found, classify as urgent immediately
  4. Otherwise, use GPT-3.5-turbo for context analysis
  5. Return priority + confidence score + reason

**Urgency Keywords (Priority Indicators):**
- High urgency: "urgent", "emergency", "ASAP", "911", "critical", "help now"
- Medium urgency: "important", "need", "please", "soon", "deadline", "today"
- Time indicators: "now", "immediately", "right now", "this instant"
- Question markers: "can you", "could you", "are you able"

**GPT-3.5 Classification Prompt:**
```
Analyze this message and determine if it's urgent or normal.

Urgent messages include:
- Time-sensitive requests requiring immediate action
- Emergencies or critical situations
- Explicit urgency markers (ASAP, urgent, etc.)
- Questions that need quick answers
- Reminders about imminent deadlines

Normal messages include:
- Casual conversation
- Information sharing without time pressure
- Non-urgent questions
- Social updates

Message: "{text}"

Respond with JSON:
{
  "priority": "urgent" | "normal",
  "confidence": 0.0-1.0,
  "reason": "brief explanation"
}
```

**3. Firestore Trigger**
- **File:** `functions/src/triggers/classifyMessage.ts`
- **Trigger:** `onCreate` on `chats/{chatID}/messages/{messageID}`
- **Flow:**
  1. New message created in Firestore
  2. Trigger fires asynchronously
  3. Extract message text
  4. Call AI classification service
  5. Update message document with priority field
  6. Log classification result

**Performance Requirements:**
- Classification latency: <3 seconds (P95)
- Cost per classification: <$0.001
- Accuracy target: >85% user agreement

#### iOS Components

**1. FocusModeService**
- **File:** `MessageAI/Services/FocusModeService.swift`
- **Purpose:** Manage Focus Mode state and chat filtering
- **Key Methods:**
  ```swift
  func toggleFocusMode()
  func activateFocusMode()
  func deactivateFocusMode()
  func filterChats(_ chats: [Chat]) -> (priority: [Chat], reviewLater: [Chat])
  func isActive() -> Bool
  func getCurrentSession() -> FocusSession?
  ```

**2. FocusModeBanner View**
- **File:** `MessageAI/Views/FocusModeBanner.swift`
- **Design:**
  - Height: 50pt
  - Background: Purple/blue gradient
  - Icon: 🎯 or SF Symbol "brain.head.profile"
  - Text: "Focus Mode Active"
  - Badge: Priority count in circle
  - Tap gesture: Toggle off Focus Mode
  - Animation: Slide down on activate, slide up on deactivate

**3. ConversationListView Updates**
- **File:** `MessageAI/Views/ConversationListView.swift`
- **Changes:**
  - Add toolbar button: SF Symbol "brain.head.profile"
  - Show FocusModeBanner when active
  - Split list into two sections when Focus Mode active:
    - **PRIORITY (X)** - Expanded by default
    - **REVIEW LATER (X)** - Collapsed by default, tap to expand
  - Normal view when Focus Mode inactive

**4. ConversationListViewModel Updates**
- **File:** `MessageAI/ViewModels/ConversationListViewModel.swift`
- **New Properties:**
  ```swift
  @Published var focusModeActive: Bool = false
  @Published var priorityChats: [Chat] = []
  @Published var reviewLaterChats: [Chat] = []
  ```
- **New Methods:**
  ```swift
  func toggleFocusMode()
  func filterChatsForFocusMode()
  func updateChatSections()
  ```

---

### Milestone 2: Thread Summarization

#### Backend Components

**1. Thread Summarization Service**
- **File:** `functions/src/services/threadSummarization.ts`
- **Purpose:** Generate AI summaries of conversations
- **Algorithm:**
  1. Fetch all messages in time range (Focus Mode session)
  2. Filter to priority chats only
  3. Format messages for GPT-4
  4. Call GPT-4-turbo with summarization prompt
  5. Parse structured JSON response
  6. Store summary in Firestore

**GPT-4 Summarization Prompt:**
```
You are summarizing a focus session for a busy professional.
They used Focus Mode from {startTime} to {endTime}.
Analyze these priority conversations and provide:

1. OVERVIEW: 2-3 sentence summary of what happened
2. ACTION ITEMS: Bulleted list of tasks/requests (include who if mentioned)
3. KEY DECISIONS: Important conclusions or agreements
4. OPEN QUESTIONS: Unanswered questions that need follow-up

Priority Conversations:
{formatted_messages}

Respond with JSON:
{
  "overview": "...",
  "actionItems": ["...", "..."],
  "decisions": ["...", "..."],
  "questions": ["...", "..."]
}
```

**2. HTTP Endpoint**
- **File:** `functions/src/api/getSummary.ts`
- **Type:** `functions.https.onCall()`
- **Input:**
  ```typescript
  {
    sessionID: string,
    startTime: Timestamp,
    endTime: Timestamp
  }
  ```
- **Output:**
  ```typescript
  {
    overview: string,
    actionItems: string[],
    decisions: string[],
    questions: string[],
    cachedAt: Timestamp
  }
  ```

#### iOS Components

**1. SummaryService**
- **File:** `MessageAI/Services/SummaryService.swift`
- **Purpose:** Fetch and cache summaries
- **Key Methods:**
  ```swift
  func fetchSummary(for session: FocusSession) async throws -> FocusSummary
  func getCachedSummary(for sessionID: String) -> FocusSummary?
  func refreshSummary(for sessionID: String) async throws -> FocusSummary
  ```

**2. FocusSummaryView**
- **File:** `MessageAI/Views/FocusSummaryView.swift`
- **Design:**
  - Modal sheet (half-height)
  - Title: "Focus Session Summary"
  - Duration badge: "2h 34m focused"
  - Sections:
    - Overview (scrollable text)
    - Action Items (checkboxes)
    - Key Decisions (bulleted)
    - Open Questions (numbered)
  - Actions:
    - "Done" button (dismiss)
    - "Share" button (export as text/PDF)
    - "Add to Notes" (future: integrate with Apple Notes)

**3. Trigger on Deactivation**
- When user turns off Focus Mode:
  1. End focus session
  2. Show loading indicator
  3. Call SummaryService.fetchSummary()
  4. Present FocusSummaryView with results
  5. Cache summary locally

---

### Milestone 3: Smart Semantic Search (RAG Pipeline)

#### Backend Components

**1. Pinecone Client**
- **File:** `functions/src/services/pineconeClient.ts`
- **Purpose:** Vector database connection
- **Configuration:**
  - Index name: `message-embeddings`
  - Dimensions: 1536 (OpenAI ada-002)
  - Metric: Cosine similarity
  - Pods: Starter (free tier)

**2. Embedding Service**
- **File:** `functions/src/services/embeddingService.ts`
- **Purpose:** Generate and store message embeddings
- **Key Functions:**
  ```typescript
  async function generateEmbedding(text: string): Promise<number[]>
  async function storeEmbedding(messageID: string, embedding: number[], metadata: object)
  async function searchSimilar(query: string, limit: number): Promise<SearchResult[]>
  ```

**3. Auto-Embedding Trigger**
- **File:** `functions/src/triggers/generateEmbedding.ts`
- **Trigger:** `onCreate` on `chats/{chatID}/messages/{messageID}`
- **Flow:**
  1. New message created
  2. Extract message text
  3. Generate embedding via OpenAI
  4. Store in Pinecone with metadata:
     ```typescript
     {
       id: messageID,
       values: [embedding vector],
       metadata: {
         chatID: string,
         senderID: string,
         timestamp: number,
         text: string.substring(0, 500)  // First 500 chars
       }
     }
     ```
  5. Update message: `embeddingGenerated: true`

**4. Semantic Search API**
- **File:** `functions/src/api/semanticSearch.ts`
- **Type:** `functions.https.onCall()`
- **Algorithm:**
  1. Receive search query from iOS
  2. Generate embedding for query
  3. Query Pinecone for top K similar vectors
  4. Fetch full message details from Firestore
  5. Rank by relevance score
  6. Return results with context

**Input:**
```typescript
{
  query: string,
  limit: number,       // Default: 10
  chatID?: string,     // Optional: search within specific chat
  dateRange?: {        // Optional: filter by date
    start: Timestamp,
    end: Timestamp
  }
}
```

**Output:**
```typescript
{
  results: [
    {
      messageID: string,
      chatID: string,
      text: string,
      senderName: string,
      timestamp: Timestamp,
      relevanceScore: number,  // 0.0-1.0
      context: string          // Surrounding messages for context
    }
  ],
  query: string,
  executionTime: number  // In milliseconds
}
```

#### iOS Components

**1. SearchService**
- **File:** `MessageAI/Services/SearchService.swift`
- **Purpose:** Call semantic search API
- **Key Methods:**
  ```swift
  func searchMessages(query: String, limit: Int) async throws -> [SearchResult]
  func searchInChat(chatID: String, query: String) async throws -> [SearchResult]
  func searchWithFilters(query: String, filters: SearchFilters) async throws -> [SearchResult]
  ```

**2. SmartSearchView**
- **File:** `MessageAI/Views/SmartSearchView.swift`
- **Design:**
  - Search bar at top
  - Placeholder: "Find messages... (e.g., 'when is the meeting')"
  - Debounced search (500ms delay)
  - Loading indicator while searching
  - Results grouped by chat
  - Each result shows:
    - Message preview (highlighted matching text)
    - Sender name + avatar
    - Timestamp (relative, e.g., "2 days ago")
    - Chat name/context
    - Relevance indicator (bar or percentage)
  - Tap result → Navigate to message in chat
  - Empty state: Suggestions ("Try searching for meeting times, deadlines, or locations")

**3. Search Integration**
- Add search button to main navigation
- SF Symbol: "magnifyingglass"
- Keyboard shortcut: Cmd+F (iOS 15+)
- Can be accessed in any mode (normal or Focus Mode)

---

## 🧪 Testing & Validation

### Data Capture Checkpoints

**Checkpoint 1: After Backend Classification Deployed**
- [ ] Send urgent test message: "URGENT: Need help ASAP!"
- [ ] Open Firestore Console → Navigate to message document
- [ ] Verify `priority` field = "urgent"
- [ ] Verify `classifiedAt` timestamp exists
- [ ] Verify `classificationReason` contains explanation
- [ ] Send normal message: "hey, how are you?"
- [ ] Verify `priority` field = "normal"
- [ ] **⚠️ STOP if data not saving correctly - check Cloud Function logs**

**Checkpoint 2: After Embedding Generation Deployed**
- [ ] Send new message: "Let's schedule a meeting for next week"
- [ ] Check Firestore: `embeddingGenerated` = true
- [ ] Open Pinecone console → Verify vector exists with messageID
- [ ] Check metadata includes chatID, senderID, text preview
- [ ] **⚠️ STOP if embeddings not generating - check Pinecone connection**

**Checkpoint 3: After Focus Mode UI Implemented**
- [ ] Toggle Focus Mode on → Banner appears
- [ ] Send urgent message → Appears in Priority section
- [ ] Send normal message → Appears in Review Later section
- [ ] Toggle Focus Mode off → Banner disappears, normal list view
- [ ] **⚠️ STOP if filtering not working - check FocusModeService logic**

**Checkpoint 4: After Summarization Implemented**
- [ ] Start Focus Mode session
- [ ] Have conversation with urgent messages
- [ ] Turn off Focus Mode
- [ ] Verify summary modal appears
- [ ] Check summary includes overview + action items
- [ ] Verify summary cached in Firestore
- [ ] **⚠️ STOP if summary not generating - check GPT-4 API calls**

**Checkpoint 5: After Semantic Search Implemented**
- [ ] Search for "meeting time" → Should find scheduling messages
- [ ] Search for "when is deadline" → Should find date-related messages
- [ ] Search for "location" → Should find address/place messages
- [ ] Verify relevance scores are reasonable (>0.7 for good matches)
- [ ] **⚠️ STOP if search not returning results - check Pinecone queries**

### Test Cases

#### AI Classification Accuracy Test
```
Test messages to verify classification:

URGENT (should classify as urgent):
1. "URGENT: Server is down, need immediate help!"
2. "Can you pick up Sarah from school in 10 minutes? Emergency"
3. "Meeting starts in 5 minutes, where are you?"
4. "CRITICAL: Payment failed, account suspended"
5. "Help! Lost my keys, locked out of apartment"

NORMAL (should classify as normal):
1. "hey, how was your weekend?"
2. "Check out this funny meme 😂"
3. "I'll send you those photos later"
4. "Good morning! Hope you have a great day"
5. "Did you watch the game last night?"

EDGE CASES:
1. "urgent question: what's your favorite color?" (not actually urgent)
2. "Don't panic, but I need your help" (could go either way)
3. "Important: Remember to buy milk" (low-importance "important")
```

#### Focus Mode Flow Test
```
1. Open app → Verify normal conversation list
2. Toggle Focus Mode → Verify banner animates in
3. Send "URGENT: test" → Wait 3 seconds → Verify chat in Priority
4. Send "normal test" → Verify chat in Review Later
5. Tap Review Later section → Verify expands to show chats
6. Tap Priority chat → Verify opens chat view
7. Return to list → Verify Focus Mode still active
8. Toggle Focus Mode off → Verify banner animates out
9. Verify all chats visible in normal list
```

#### Search Accuracy Test
```
Seed test data with messages:
- "Team meeting tomorrow at 3pm in conference room B"
- "Deadline for project submission is Friday"
- "Can you send me the address for the restaurant?"
- "Let's grab coffee next week, what's your schedule?"

Test queries:
1. "when is meeting" → Should find meeting message (score >0.8)
2. "project due date" → Should find deadline message (score >0.7)
3. "restaurant location" → Should find address message (score >0.7)
4. "coffee schedule" → Should find coffee message (score >0.7)
5. "invoice" → Should return empty (no matching messages)
```

### Performance Requirements

| Metric | Target | Measurement |
|--------|--------|-------------|
| Classification latency | <3s (P95) | Time from message send to priority field updated |
| Embedding generation | <5s (P95) | Time from message send to vector stored in Pinecone |
| Search response time | <2s (P95) | Time from query submission to results displayed |
| Summary generation | <10s (P95) | Time from deactivation to summary displayed |
| Focus Mode toggle | <300ms | Time from tap to banner animation complete |
| App crash rate | <0.1% | Crashes per session during Focus Mode |

### Cost Monitoring

**OpenAI API Costs (Estimated per 1000 users/day):**
- Classification: ~5000 messages/day × $0.0005 = $2.50/day
- Embeddings: ~5000 messages/day × $0.0001 = $0.50/day
- Summaries: ~1000 summaries/day × $0.03 = $30/day
- **Total:** ~$33/day or $990/month

**Pinecone Costs:**
- Starter tier: Free (1M vectors)
- Standard tier: $70/month (5M vectors)

**Budget Alert Triggers:**
- Set Firebase budget alert at $50/day
- Monitor OpenAI API usage daily
- Implement rate limiting: 100 classifications/user/day

---

## 🚀 Rollout Plan

### Phase 1: Internal Testing (Week 1)
- Deploy to development environment
- Team testing with real usage
- Fix critical bugs
- Validate data capture

### Phase 2: Beta Release (Week 2-3)
- Invite 100 power users
- Collect feedback via in-app survey
- Monitor classification accuracy
- Measure engagement metrics

### Phase 3: Gradual Rollout (Week 4-6)
- Release to 10% of users
- Monitor error rates and performance
- Increase to 50% if metrics healthy
- Full release to 100% by end of week 6

### Rollback Criteria
- Classification accuracy <75%
- App crash rate >1%
- Cloud Function errors >5%
- Negative user feedback >20%

---

## 📊 Analytics & Monitoring

### Key Events to Track

```typescript
// Firebase Analytics events
analytics.logEvent("focus_mode_activated", {
  user_id: string,
  timestamp: number,
  previous_session_duration?: number
});

analytics.logEvent("focus_mode_deactivated", {
  user_id: string,
  duration_minutes: number,
  priority_messages: number,
  normal_messages: number,
  summary_viewed: boolean
});

analytics.logEvent("message_classified", {
  priority: "urgent" | "normal",
  confidence: number,
  classification_time_ms: number,
  has_keywords: boolean
});

analytics.logEvent("semantic_search_performed", {
  query_length: number,
  results_count: number,
  response_time_ms: number,
  result_clicked: boolean
});

analytics.logEvent("summary_generated", {
  session_duration_minutes: number,
  action_items_count: number,
  generation_time_ms: number,
  user_rated_helpful: boolean
});
```

### Dashboards

**Focus Mode Usage Dashboard:**
- Daily active Focus Mode users
- Average session duration
- Adoption rate by cohort
- Retention rate (day 7, day 30)

**AI Performance Dashboard:**
- Classification accuracy (based on user feedback)
- Average classification latency
- Cost per classification
- Error rate by classification type

**Search Performance Dashboard:**
- Search queries per day
- Average response time
- Click-through rate (results clicked / searches)
- Query abandonment rate

---

## ⚠️ Risks & Mitigations

### Risk 1: Poor Classification Accuracy
**Impact:** High - Users lose trust, feature unused  
**Likelihood:** Medium  
**Mitigation:**
- Start with keyword-based fallback
- Collect user feedback on classifications
- Implement "Report Incorrect" button
- Iterate on prompt engineering
- A/B test different classification thresholds

### Risk 2: High API Costs
**Impact:** High - Budget overrun  
**Likelihood:** Medium  
**Mitigation:**
- Implement rate limiting per user
- Use GPT-3.5-turbo (cheaper) instead of GPT-4 for classification
- Cache common classifications
- Set budget alerts
- Implement client-side keyword filtering before API call

### Risk 3: Latency Issues
**Impact:** Medium - Poor user experience  
**Likelihood:** Low  
**Mitigation:**
- Asynchronous classification (don't block message send)
- Show loading states appropriately
- Implement timeout fallbacks
- Use Firebase emulator for local testing
- Monitor P95/P99 latency metrics

### Risk 4: Privacy Concerns
**Impact:** High - Legal/PR issues  
**Likelihood:** Low  
**Mitigation:**
- Clearly disclose AI processing in terms of service
- Allow users to opt-out of AI features
- Don't store full message content in external services (Pinecone)
- Implement data retention policies (delete embeddings after 90 days)
- GDPR/CCPA compliance for user data deletion

### Risk 5: Dependency on Third-Party Services
**Impact:** High - Feature downtime  
**Likelihood:** Medium  
**Mitigation:**
- Implement graceful degradation (keyword-based fallback)
- Monitor OpenAI/Pinecone status pages
- Set up error alerting
- Maintain fallback to non-AI mode
- Cache recent classifications/embeddings

---

## 🔮 Future Enhancements

### Phase 4 Features (Post-MVP)
1. **Auto-Activate During Work Hours**
   - Settings toggle for scheduled Focus Mode
   - Calendar integration (auto-activate during meetings)
   - Location-based triggers (activate at office)

2. **User Training & Personalization**
   - "This should be urgent/normal" feedback button
   - Learn user's urgency preferences
   - VIP contact prioritization
   - Custom urgency keywords

3. **Advanced Summarization**
   - Full conversation summary with participant breakdown
   - Export summaries to Notes, Email, or PDF
   - Weekly digest of important conversations
   - Voice summary (text-to-speech)

4. **Enhanced Search**
   - Search filters (date range, sender, chat type)
   - Search within specific chat
   - Search attachments/images (OCR)
   - Voice search

5. **Cross-Platform Sync**
   - Focus Mode state syncs across devices
   - iPad/Mac support with same UI paradigm
   - Apple Watch quick toggle

6. **Integrations**
   - Calendar integration (mark Focus Mode time)
   - Shortcuts app integration
   - Siri commands: "Hey Siri, enable Focus Mode"
   - Apple Focus Modes integration

---

## 📚 References

### Related PRDs
- [PR-1: Core Messaging Features](./pr-1-prd.md)
- [PR-10: Push Notifications](./pr-10-prd.md)
- [PR-13: Read Receipts](./pr-13-prd.md)

### External Resources
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Pinecone Documentation](https://docs.pinecone.io)
- [Firebase Cloud Functions Guide](https://firebase.google.com/docs/functions)
- [SwiftUI Best Practices](https://developer.apple.com/documentation/swiftui)

### Design References
- [Apple Human Interface Guidelines - Focus](https://developer.apple.com/design/human-interface-guidelines/focus)
- [Material Design - Priority Inbox](https://material.io/design)

---

## 🤝 Stakeholders & Approvals

**Product Owner:** Claudia Alban  
**Engineering Lead:** Claudia Alban  
**Design Lead:** TBD  
**QA Lead:** TBD  

**Approval Status:**
- [ ] Product requirements approved
- [ ] Technical architecture reviewed
- [ ] Design mockups approved
- [ ] Privacy/legal review complete
- [ ] Budget approved

---

## 📝 Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-25 | 1.0 | Initial PRD creation | Claudia Alban |

---

**Next Steps:**
1. ✅ Complete foundation check (verify Firebase, install SDKs)
2. 🎯 Start Milestone 1 implementation (AI classification + Focus UI)
3. 📋 Implement Milestone 2 (Thread summarization)
4. 🔍 Implement Milestone 3 (Semantic search)
5. 🚀 Beta testing and iterative improvements


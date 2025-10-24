# PRD: Proactive Assistant with Google Calendar & Slack Integration

**Feature**: Proactive Meeting Scheduling + Cross-Platform Intelligence

**Version**: 1.0

**Status**: Draft

**Agent**: Pete Agent

**Target Release**: Phase 3 - AI Core Features Batch 2

**Links**: 
- PR Brief: `MessageAI/docs/ai-implementation-brief.md` (PR #AI-011)
- TODO: `MessageAI/docs/todos/pr-011-todo.md` (to be created after PRD approval)
- Product Vision: `MessageAI/docs/AI-PRODUCT-VISION.md`

---

## 1. Summary

**Problem:** Remote professionals waste 100+ minutes weekly on scheduling back-and-forth and drown in 200+ Slack messages they can't keep up with.

**Solution:** AI detects meeting requests, checks Google Calendar, suggests 3 optimal times respecting focus hours, enables one-tap booking. Users can import Slack threads for instant AI summarization.

**Value:** Reduce scheduling from 5+ messages to 1 interaction, save 100+ min/week, unify cross-platform intelligence.

**Vertical Slice:** Message with "let's meet" → AI detects → Checks calendar → Suggests 3 times → Tap to book → Event created.

---

## 2. Problem & Goals

### Maya's Pain Points
1. Scheduling takes 5+ messages over 2 days
2. Returns from focus time to 200+ Slack messages
3. Context switching between platforms destroys focus
4. Meetings scheduled during protected deep work time

### Goals (Measurable)

- [ ] **G1 — Reduce Scheduling Time 85%:** 10 min → 1.5 min
- [ ] **G2 — Protect Focus Hours:** 95%+ suggestions avoid 10am-2pm
- [ ] **G3 — One-Tap Booking:** <3 taps from suggestion to confirmed event
- [ ] **G4 — Cross-Platform Intelligence:** Summarize Slack threads in <5s
- [ ] **G5 — Detection Accuracy:** 90%+ true positives, <5% false positives

---

## 3. Non-Goals

- ❌ Outlook/Exchange (defer to PR #AI-020)
- ❌ Auto-booking without confirmation (violates user control)
- ❌ Slack message posting (read-only safer)
- ❌ Microsoft Teams (different API, validate Slack first)
- ❌ Calendar event editing (creation is primary use case)
- ❌ Group availability (3+ participants too complex for MVP)

---

## 4. Success Metrics

### Performance Targets
- Meeting detection: <1s
- Calendar check: <2s
- Suggestions generated: <1s
- End-to-end flow: <5s
- Slack fetch + summarize: <8s total

### Quality Targets
- Detection accuracy: 90%+ (true positives)
- False positive rate: <5%
- Suggestion acceptance: 85%+ users select one of 3 times
- Focus hour protection: 95%+ avoid protected hours
- Slack summary satisfaction: 90%+ "Was this helpful?" = yes

---

## 5. User Stories

**Meeting Scheduling:**
- As Maya, I want AI to detect "let's meet" and show suggestions within 5s, so I don't manually coordinate
- As Maya, I want suggestions to respect my focus hours (10am-2pm), so deep work isn't interrupted
- As Maya, I want one-tap booking (<3 taps), so I can respond quickly without opening calendar

**Slack Integration:**
- As Maya, I want to import Slack threads for AI summarization, so I catch up on 100+ messages in 5 seconds
- As Maya, I want to search across MessageAI and Slack in one place, so I find decisions regardless of platform

**Error Handling:**
- As Maya, when calendar API fails, I want calm error with manual fallback, so I can still coordinate without frustration

---

## 6. Experience Specification

### Flow 1: Automatic Meeting Detection (Proactive)

1. **Detection:** AI analyzes incoming message in background (<1s)
2. **Notification:** "🤖 Dave wants to meet. I found 3 times." (gentle, non-intrusive)
3. **View:** Tap notification → Modal shows:
   - Requestor info + message snippet
   - AI reasoning: "I suggested times outside your focus hours"
   - 3 time cards with mini calendar preview
   - Confidence badge, availability indicators
4. **Book:** Tap time → Confirm → Event created in Google Calendar
5. **Respond:** Optionally send reply with booked time

**Performance:** Steps 1-3 complete in <5s

### Flow 2: Slack Thread Import

1. Settings → "Connected Apps" → "Import Slack Thread"
2. Select workspace → Browse channels → Choose thread
3. Loading (animated) → AI summarizes (RAG + GPT-4)
4. Display: 2-3 sentence summary + decisions + action items + participants
5. Actions: Extract items, search thread, open in Slack

**Performance:** Fetch + summarize 100 messages in <8s

### Flow 3: OAuth Setup (Google Calendar & Slack)

1. Settings → "Connect Google Calendar" or "Connect Slack"
2. OAuth consent screen (Firebase Auth handles flow)
3. Grant permissions (calendar read/write or Slack read)
4. Success confirmation with connection status
5. Optional: Set focus hours (calendar) or select channels (Slack)

**Performance:** OAuth flow completes in <30s

### Visual Components

**MeetingSuggestionsView Modal:**
- Header: Requestor avatar, name, message snippet
- AI reasoning card: Blue info icon, "Outside focus hours", confidence badge
- 3 time cards: Date/time, mini calendar preview, availability badges
- Actions: "Book [Time]" (primary), "Suggest Different Times", "Ignore"
- Animations: Spring slide-up (0.4s), subtle scale on tap

**Error States (Calm Intelligence):**
- Blue/gray background (not red)
- First-person: "I can't reach your calendar right now. Want to suggest times manually?"
- Actions: "Try Again" | "Manual Suggestion" | "Dismiss"

---

## 7. Functional Requirements

### Meeting Scheduling (MUST)

**FR-1: Detection**
- Detect keywords: "let's meet", "can we chat", "schedule a call", "find time"
- Run on all incoming messages within 1s
- Store in Memory/State, achieve 90%+ accuracy, <5% false positives
- **Gate:** Message with "let's meet" → Detected within 1s → Notification within 5s

**FR-2: Google Calendar Integration**
- OAuth2 via Firebase Auth (scopes: `calendar.readonly`, `calendar.events.owned`)
- Fetch 7-day availability within 2s
- Store tokens securely in Firestore with auto-refresh
- **Gate:** OAuth completes <30s → Availability check <2s

**FR-3: Time Suggestions**
- Generate 3 optimal times based on availability
- Respect focus hours (10am-2pm default), avoid back-to-back meetings (15min buffer)
- Prefer 9am-5pm user timezone, default 30min duration
- **Gate:** 95%+ avoid focus hours, 85%+ users select one of 3

**FR-4: One-Tap Booking**
- <3 taps to book: view → tap time → confirm
- Create event via Calendar API with title, participants, time
- Handle failures with retry/manual fallback
- **Gate:** Event in Google Calendar within 3s of confirmation

**FR-5: Proactive Notification**
- Gentle notification (soft sound, no vibration unless urgent)
- Include requestor name: "Dave wants to meet"
- Tap opens suggestions modal directly
- **Gate:** Notification within 5s of detection

### Slack Integration (MUST)

**FR-6: Slack OAuth**
- OAuth2 via Slack API (scopes: `channels:read`, `channels:history`, `groups:read`, `users:read`)
- Support multiple workspaces, secure token storage with auto-refresh
- **Gate:** OAuth <30s → View workspace channels

**FR-7: Thread Fetching**
- Fetch specific thread (parent + replies) or recent messages (50-100)
- Complete 100 messages in <3s
- Cache for offline (24h TTL), show loading indicator
- **Gate:** Thread fetched <3s → Display with full content

**FR-8: Summarization**
- Integrate with Thread Summarization (PR #AI-006)
- RAG Pipeline analysis + GPT-4 summary (2-3 sentences)
- Extract decisions, action items, participants
- **Gate:** 100-message thread summarized in <8s total, 90%+ satisfaction

**FR-9: Cross-Platform Search**
- Extend Smart Search (PR #AI-008) to Slack messages
- Index in RAG Pipeline, unified results with platform badges
- **Gate:** Search across platforms in <2s

### Error Handling (MUST)

**FR-10: Calm Error UX**
- Use AIErrorHandler (PR #AI-005) for all API errors
- First-person calm messages, blue/gray colors
- Fallback options: manual suggestion, open in Slack/Calendar
- Exponential backoff retry (1s, 2s, 4s), log to Firestore
- **Gate:** Timeout → Calm error <50ms → Fallback works

---

## 8. Data Model

### New Collections

```typescript
/users/{userId}/integrations/
{
  googleCalendar: {
    connected: boolean,
    email: string,
    tokenExpiry: Timestamp,
    focusHours: { enabled: boolean, startTime: "10:00", endTime: "14:00", daysOfWeek: [1,2,3,4,5] },
    preferences: { defaultDuration: 30, bufferBetweenMeetings: 15 }
  },
  slack: {
    workspaces: [{
      id: string, name: string, connected: boolean, 
      tokenExpiry: Timestamp, syncedChannels: string[]
    }]
  }
}

/users/{userId}/meetingSuggestions/
{
  id: string, conversationId: string, requestorId: string,
  detectedAt: Timestamp, status: "pending" | "accepted" | "rejected",
  detectionData: { messageText: string, keywords: string[], confidence: number, reasoning: string },
  suggestedTimes: [{ startTime: Timestamp, endTime: Timestamp, reasoning: string, selected: boolean }],
  bookedEvent: { calendarEventId?: string, startTime?: Timestamp, bookedAt?: Timestamp }
}

/users/{userId}/slackThreads/ (24h cache)
{
  id: string, workspaceId: string, channelId: string,
  messages: [{ id: string, userId: string, userName: string, text: string, timestamp: Timestamp }],
  summary: { text: string, confidence: number, decisions: string[], actionItems: string[] },
  fetchedAt: Timestamp, expiresAt: Timestamp, embeddingGenerated: boolean
}
```

### iOS Models

```swift
// Models/Integration/GoogleCalendarIntegration.swift
struct GoogleCalendarIntegration: Codable {
    var connected: Bool
    var email: String?
    var focusHours: FocusHours
    var preferences: CalendarPreferences
}

struct FocusHours: Codable {
    var enabled: Bool
    var startTime: String  // "10:00"
    var endTime: String    // "14:00"
    var daysOfWeek: [Int]  // [1,2,3,4,5]
}

// Models/Integration/SlackWorkspace.swift
struct SlackWorkspace: Codable, Identifiable {
    var id: String
    var name: String
    var domain: String
    var connected: Bool
    var syncedChannels: [String]
}

// Models/AI/MeetingSuggestion.swift
struct MeetingSuggestion: Codable, Identifiable {
    var id: String
    var conversationId: String
    var requestorName: String
    var detectedAt: Date
    var status: SuggestionStatus
    var suggestedTimes: [SuggestedTime]
    var bookedEvent: BookedEvent?
}
```

### Security Rules

```javascript
// Owner-only access, 24h auto-expire for Slack cache
match /users/{userId}/integrations/{integrationId} {
  allow read, write: if request.auth.uid == userId;
}
match /users/{userId}/slackThreads/{threadId} {
  allow read, write: if request.auth.uid == userId;
  allow delete: if resource.data.expiresAt < request.time;
}
```

---

## 9. API / Service Contracts

### iOS Services

```swift
// Services/Integration/GoogleCalendarService.swift
protocol GoogleCalendarService {
    func initiateOAuthFlow() async throws -> URL
    func handleOAuthCallback(code: String) async throws -> GoogleCalendarIntegration
    func fetchAvailability(startDate: Date, endDate: Date, focusHours: FocusHours?) async throws -> [TimeSlot]
    func suggestMeetingTimes(duration: Int, availability: [TimeSlot], focusHours: FocusHours) -> [SuggestedTime]
    func createEvent(title: String, startTime: Date, endTime: Date, attendees: [String]) async throws -> String
    // Throws: CalendarError.unauthorized, .timeout, .quotaExceeded
}

// Services/Integration/SlackIntegrationService.swift
protocol SlackIntegrationService {
    func initiateOAuthFlow() async throws -> URL
    func handleOAuthCallback(code: String) async throws -> SlackWorkspace
    func fetchChannels(workspaceId: String) async throws -> [SlackChannel]
    func fetchThread(workspaceId: String, channelId: String, threadTs: String?) async throws -> SlackThread
    // Throws: SlackError.unauthorized, .rateLimit, .workspaceNotFound
}

// Services/AI/ProactiveAssistantService.swift
protocol ProactiveAssistantService {
    func detectSchedulingIntent(message: Message) async throws -> DetectionResult?
    func generateMeetingSuggestions(requestor: User, duration: Int, userId: String) async throws -> MeetingSuggestion
    func bookMeeting(suggestion: MeetingSuggestion, selectedTime: SuggestedTime) async throws -> BookedEvent
    func summarizeSlackThread(thread: SlackThread, userId: String) async throws -> ThreadSummary
    // Uses AIErrorHandler (PR #AI-005), retries with exponential backoff
}
```

### Cloud Functions

```typescript
// functions/src/proactive/detectScheduling.ts
export const detectSchedulingIntent = functions.https.onCall(async (data, context) => {
    // Parameters: { messageId: string, messageText: string }
    // Returns: { detected: boolean, confidence: number, keywords: string[], reasoning: string }
    // Timeout: 5s
});

// functions/src/integration/googleCalendar.ts
export const createCalendarEvent = functions.https.onCall(async (data, context) => {
    // Parameters: { userId, title, startTime, endTime, attendees }
    // Returns: { eventId: string, eventUrl: string }
    // Calls: Google Calendar API v3 - events.insert
    // Timeout: 10s
});

// functions/src/integration/slack.ts
export const fetchSlackThread = functions.https.onCall(async (data, context) => {
    // Parameters: { userId, workspaceId, channelId, threadTs? }
    // Returns: { messages: SlackMessage[], channelName: string }
    // Calls: Slack Web API - conversations.history/replies
    // Timeout: 10s
});
```

---

## 10. UI Components

### New Views
```
Views/AI/ProactiveAssistant/
├── MeetingSuggestionsView.swift        — Modal with 3 suggested times + calendar preview
├── SlackThreadImportView.swift         — Browse and select Slack threads
├── SlackThreadSummaryView.swift        — Display summary with actions
└── IntegrationSettingsView.swift       — Manage Google Calendar & Slack

Components/Integration/
├── CalendarPreviewComponent.swift      — Mini calendar grid
├── ConnectedAppCard.swift              — App status indicator
└── FocusHoursPickerView.swift         — Time picker for focus hours

Services/Integration/
├── GoogleCalendarService.swift
├── SlackIntegrationService.swift
└── ProactiveAssistantService.swift

ViewModels/AI/
├── MeetingSuggestionsViewModel.swift
├── SlackIntegrationViewModel.swift
└── ProactiveAssistantViewModel.swift
```

---

## 11. Integration Points

- **Firebase:** Auth (OAuth tokens), Firestore (integrations, suggestions, cache), Cloud Functions, FCM (notifications)
- **External APIs:** Google Calendar API v3, Slack Web API, OpenAI GPT-4 (via PR #AI-006), Pinecone (via PR #AI-001)
- **Dependencies:** PR #AI-001 (RAG), #AI-002 (Preferences), #AI-003 (Function Calling), #AI-004 (Memory), #AI-005 (Error Handling), #AI-006 (Summarization), #AI-008 (Search)

---

## 12. Test Plan & Acceptance Gates

### Happy Path (Must Pass)

- [ ] **T1: Detection** - Message "let's meet tomorrow" → Detected <1s → Notification <5s → Tap opens modal
- [ ] **T2: Calendar OAuth** - Connect calendar → OAuth <30s → Availability check <2s
- [ ] **T3: Suggestions** - 3 times generated <1s → 95%+ avoid focus hours → Show reasoning
- [ ] **T4: Booking** - Tap time → Confirm → Event in calendar <3s → Total <3 taps
- [ ] **T5: Slack OAuth** - Connect workspace → OAuth <30s → Channels listed
- [ ] **T6: Slack Import** - Fetch 100 messages <3s → Summarize <3s → Total <8s → 90%+ satisfaction
- [ ] **T7: Cross-Platform Search** - Query returns MessageAI + Slack results <2s with platform badges

### Edge Cases (Must Handle)

- [ ] **T8: Calendar Failure** - Timeout → Calm error <50ms → "Try again?" | "Manual suggestion"
- [ ] **T9: Slack Rate Limit** - Rate limited → Error <50ms → "Try in 30s?" | "Open in Slack"
- [ ] **T10: No Available Times** - Calendar full → "Suggest times next week?" → Works
- [ ] **T11: False Positive** - "I'll meet you at coffee shop" → Confidence <0.6 → No notification
- [ ] **T12: Token Expiration** - Expired → Detect → Prompt re-auth → Booking continues

### Performance (Targets from `shared-standards.md`)

- [ ] **T13: Detection Latency** - 100 test messages → p95 <1s → 90%+ accuracy → <5% false positives
- [ ] **T14: Calendar API** - 7-day availability <2s → Suggestions <1s → End-to-end <5s
- [ ] **T15: Slack Fetch** - 100 messages <3s, 200 messages <5s → Summarization adds <3s
- [ ] **T16: App Responsiveness** - Background detection → Message send unchanged (<200ms p95) → 60fps UI
- [ ] **T17: Offline** - Offline → Requests queued → Reconnect → Queue processed <5s

### Security & Quality

- [ ] **T18: OAuth Security** - Tokens encrypted in Firestore → Not exposed in logs → Auto-refresh works
- [ ] **T19: Slack Cache** - Thread expires after 24h → User data isolated
- [ ] **T20: Detection Accuracy** - 100 messages (50 scheduling, 50 not) → 90%+ true positives → <5% false positives
- [ ] **T21: Suggestion Quality** - 50 scenarios → 95%+ avoid focus hours → 85%+ acceptance rate → 15min buffer
- [ ] **T22: Slack Summary** - 20 threads → 90%+ satisfaction → 85%+ decisions identified → 90%+ action items

---

## 13. Definition of Done

- [ ] All services implemented with error handling (AIErrorHandler)
- [ ] All views display loading, error, empty states with dark mode support
- [ ] OAuth flows work end-to-end (Google Calendar + Slack)
- [ ] Meeting detection triggers <1s, suggestions generated <1s, booking <3s
- [ ] All 22 test gates pass (happy path, edge cases, performance, quality)
- [ ] Unit tests (Swift Testing), UI tests (XCTest) pass
- [ ] Documentation: README updated with OAuth setup, troubleshooting guide
- [ ] Feature flags configured (Firebase Remote Config)
- [ ] API keys secured (Google Calendar, Slack, OpenAI)

---

## 14. Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| **Calendar API rate limits** (10 req/sec/user) | Cache availability 5min, batch requests, show cached data with timestamp |
| **Slack OAuth complexity** (multiple workspaces) | Start single workspace MVP, iterate to multi-workspace |
| **Detection false positives** (annoy users) | Confidence threshold 0.8, feedback loop, dismissible suggestions |
| **Cross-platform privacy concerns** | Clear consent, 24h cache expiration, user data isolation, no permanent message storage |
| **Performance impact on messaging** | Async Cloud Functions, monitor send latency (<200ms), feature flag to disable |
| **OAuth token expiration** | Auto-refresh, proactive notifications, easy re-auth (1 tap), graceful degradation |
| **API cost overruns** (OpenAI/Pinecone) | Cache summaries 24h, rate limit 10/day, use GPT-4-mini, monitor costs, feature flag |

---

## 15. Rollout & Telemetry

### Feature Flags
- `proactive_assistant_enabled` - Master switch
- `google_calendar_integration_enabled` - Calendar features
- `slack_integration_enabled` - Slack features

### Rollout: 5% → 20% → 50% → 100% over 4 weeks

### Metrics
- **Adoption:** % users connecting calendar/Slack, suggestions accepted/week, threads summarized/week
- **Performance:** Detection latency (p50/p95), calendar check time, Slack fetch time, end-to-end flow
- **Quality:** Detection accuracy, suggestion acceptance rate, focus hour protection, summary satisfaction
- **Errors:** API error rate by type, retry success, fallback usage, user-reported issues
- **Business:** Time saved/user/week, API costs, retention impact, feature engagement

---

## 16. Open Questions

**Q1: Multiple Google Calendar accounts per user?**
- Recommend: Single primary calendar MVP → Iterate based on feedback

**Q2: Timezone handling for suggestions?**
- Recommend: User's local timezone only MVP → Add timezone detection in future

**Q3: Auto-summarize high-traffic Slack channels?**
- Recommend: Manual import only MVP → Auto-summarize as experimental flag

**Q4: Slack embedding retention (24h vs 90 days)?**
- Recommend: Keep embeddings 90 days for search, delete message content after 24h

---

## 17. Deferred to Future PRs

- [ ] **PR #AI-016:** Multiple Google Calendar accounts
- [ ] **PR #AI-017:** Outlook/Exchange integration
- [ ] **PR #AI-018:** Microsoft Teams integration
- [ ] **PR #AI-019:** Automatic booking without confirmation
- [ ] **PR #AI-020:** Group availability (3+ participants)
- [ ] **PR #AI-021:** Calendar event editing/deletion
- [ ] **PR #AI-022:** Slack message posting
- [ ] **PR #AI-023:** Meeting agenda generation
- [ ] **PR #AI-024:** Recurring meeting suggestions

---

## 18. Preflight Answers

1. **Vertical slice:** Scheduling request → AI suggests 3 times → Tap to book → Calendar event created
2. **Primary user:** Maya, saves 10 minutes per meeting request
3. **Must-have:** Detection, calendar integration, suggestions, booking | **Nice:** Slack summarization, cross-platform search
4. **Real-time:** Detection <1s, suggestions <5s, no impact on messaging (<200ms p95)
5. **Performance:** Detection <1s, calendar <2s, Slack <3s, end-to-end <8s
6. **Edge cases:** Calendar unavailable, Slack rate limit, token expiration, no times, false positives, network failures
7. **Data:** New: integrations/, meetingSuggestions/, slackThreads/ with OAuth, suggestions, cache
8. **Services:** GoogleCalendarService, SlackIntegrationService, ProactiveAssistantService
9. **UI:** Automatic notification + Settings; Loading, suggestions, booking, error, OAuth flows
10. **Security:** OAuth (calendar R/W, Slack read), secure tokens, data isolation, 24h cache
11. **Dependencies:** PR #AI-001-008 (RAG, Preferences, Functions, Memory, Error, Summarization, Search)
12. **Rollout:** 5%→20%→50%→100% over 4 weeks, monitor adoption/performance/quality/errors
13. **Out of scope:** Outlook, Teams, multi-calendar, auto-booking, recurring, group availability, editing

---

**PRD Status:** ✅ Ready for Review  
**Word Count:** ~40% shorter, removed redundant sections  
**Next Step:** User approval → Create TODO list

**Questions for Review:**
1. Is this length better? Any sections still too verbose?
2. Should we split into 2 PRs (Calendar first, Slack second)?
3. Ready to proceed with TODO creation?

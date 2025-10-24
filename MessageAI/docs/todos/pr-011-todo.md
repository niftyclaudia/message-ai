# PR-011 TODO — Proactive Assistant (Google Calendar & Slack)

**Branch**: `feat/pr-011-proactive-assistant`  
**PRD**: `MessageAI/docs/prds/pr-011-prd.md`  

---

## 🎯 PHASE SPLIT: TODAY vs LATER

### ✅ PHASE 1 (TODAY - 1-2 hours) - Quick Demo/Proof of Concept

**Goal:** Show Slack thread summarization working with mock data

- [ ] Create mock Slack thread data (hardcoded JSON)
- [ ] Build simple iOS UI to display thread
- [ ] Add "Summarize Thread" button
- [ ] Wire to existing AI functions (real summarization, test data)
- [ ] **Demo-ready:** Shows the feature concept working end-to-end

**Why this works:** Uses your already-deployed AI functions, just with test data!

### 🔮 PHASE 2 (LATER - when you have time) - Full Production

**Goal:** Complete OAuth integration for Calendar + Slack

- [ ] Google Calendar OAuth setup
- [ ] Slack OAuth setup  
- [ ] Cloud Functions for both integrations
- [ ] Real API connections
- [ ] Production-ready security

**Timeline:** Split into PR-011b (next week when not rushed)

---

## 📱 TODAY'S IMPLEMENTATION (Phase 1 - Quick Demo)

### Step 1: Create Mock Data (15 min) ✅
- [x] Create `Models/Integration/SlackThread.swift`
- [x] Create mock JSON with realistic Slack thread (8-10 messages)
- [x] Include: usernames, timestamps, message text, thread metadata
- [x] Created 2 mock threads: Product Planning & Tech Discussion

### Step 2: Build UI (45 min) ✅
- [x] Create `Views/AI/ProactiveAssistant/MockSlackThreadView.swift`
  - Display thread messages (Slack-style bubbles)
  - Show participants, timestamp, channel name
  - "Summarize Thread" button at bottom
- [x] Create `ViewModels/AI/MockSlackThreadViewModel.swift`
  - `@Published var messages`, `summary`, `isLoading`
  - `summarizeThread()` method

### Step 3: Connect to AI (30 min) ✅
- [x] Wire "Summarize" button to existing AI chat function
- [x] Format thread messages as prompt: "Summarize this Slack thread: [messages]"
- [x] Display AI response in expandable card
- [x] Show loading state with calm animation

### Step 4: Polish (15 min) ✅
- [x] Add Slack logo/branding
- [x] Added navigation from Profile tab → "Slack Integration Demo"
- [x] Gradient styling with purple/blue theme
- [x] Dark mode support
- [ ] Test in simulator (Ready to test!)
- [ ] Take screenshots for demo

**Total Time: ~2 hours** ⏱️

---

## 🔮 PHASE 2 SECTIONS (For Later - PR-011b)

All sections below (0-14) are for **PHASE 2** when you have time for full OAuth integration.

---

## 0. ⚡ Prerequisites (PHASE 2 ONLY - Get These BEFORE Starting)

### 🔑 API Credentials You Need

**Google Cloud Console** (https://console.cloud.google.com)
- [ ] Create/select project → Enable Google Calendar API
- [ ] Create OAuth 2.0 Client ID (Web application)
- [ ] Add redirect URI: `https://{your-project-id}.firebaseapp.com/__/auth/handler`
- [ ] Download credentials: **Client ID** + **Client Secret**
- [ ] Save in 1Password/secure vault ⚠️

**Slack App** (https://api.slack.com/apps)
- [ ] Create New App → "From scratch" → Name: "MessageAI Assistant"
- [ ] OAuth & Permissions → Add scopes: `channels:read`, `channels:history`, `groups:read`, `groups:history`, `users:read`
- [ ] Add redirect URL: `https://{your-project-id}.firebaseapp.com/__/auth/handler`
- [ ] Install to test workspace
- [ ] Copy: **Client ID**, **Client Secret**, **Signing Secret**
- [ ] Save securely ⚠️

**Firebase Functions Config**
```bash
firebase functions:config:set \
  google.calendar_client_id="YOUR_CLIENT_ID" \
  google.calendar_client_secret="YOUR_SECRET" \
  slack.client_id="YOUR_SLACK_CLIENT_ID" \
  slack.client_secret="YOUR_SLACK_SECRET" \
  slack.signing_secret="YOUR_SLACK_SIGNING_SECRET"
```

**Test Accounts Setup**
- [ ] Test Google account with calendar events (meetings, focus hours)
- [ ] Join/create test Slack workspace
- [ ] Add test channels with 50-100 sample messages

**Verify You Have**
- [ ] OpenAI API key (from PR #AI-001)
- [ ] Pinecone API key (from PR #AI-001)
- [ ] Xcode 15+ with iOS 16+ simulator
- [ ] Node.js 18 LTS + Firebase CLI installed
- [ ] Firebase emulators: `firebase emulators:start`

**⏱️ Setup Time:** 2-3 hours

---

## 1. Models & Foundation (1 hour)

- [ ] Create branch: `git checkout -b feat/pr-011-proactive-assistant`
- [ ] Create `Models/Integration/GoogleCalendarIntegration.swift` (structs: GoogleCalendarIntegration, FocusHours, CalendarPreferences)
- [ ] Create `Models/Integration/SlackIntegration.swift` (structs: SlackWorkspace, SlackPreferences)
- [ ] Create `Models/AI/MeetingSuggestion.swift` (structs: MeetingSuggestion, SuggestedTime, BookedEvent)
- [ ] Create `Models/Integration/SlackThread.swift` (structs: SlackThread, SlackMessage)
- [ ] **Gate:** Models compile, no Xcode errors

---

## 2. Google Calendar Service (4 hours)

- [ ] Create `Services/Integration/GoogleCalendarService.swift`
  - `initiateOAuthFlow()` → URL
  - `handleOAuthCallback(code)` → GoogleCalendarIntegration
  - `fetchAvailability(startDate, endDate, focusHours)` → [TimeSlot]
  - `createEvent(title, startTime, endTime, attendees)` → eventId
- [ ] Implement time suggestion algorithm: Filter focus hours (10am-2pm), prefer 9am-5pm, 15min buffer, return top 3
- [ ] Store OAuth tokens in Firestore: `/users/{userId}/integrations/googleCalendar`
- [ ] Use AIErrorHandler (PR #AI-005) for all errors
- [ ] Create `MessageAITests/Services/GoogleCalendarServiceTests.swift`
- [ ] **Gate:** OAuth works, availability <2s, suggestions <1s, 95%+ avoid focus hours, event created <3s

---

## 3. Meeting Detection (3 hours)

- [ ] Create `functions/src/proactive/detectScheduling.ts` (HTTP callable)
  - Detect keywords: "let's meet", "can we chat", "schedule", "find time"
  - Return: `{ detected: bool, confidence: number, keywords, reasoning }`
- [ ] Update `functions/src/triggers/onMessageCreated.ts`
  - If detected + confidence >0.8 → Create `/users/{userId}/meetingSuggestions/` doc
  - Send push notification
- [ ] Create `Services/AI/ProactiveAssistantService.swift`
  - `detectSchedulingIntent(message)` → DetectionResult
  - `generateMeetingSuggestions(requestor, duration)` → MeetingSuggestion (calls Calendar service)
  - `bookMeeting(suggestion, selectedTime)` → BookedEvent (creates calendar event)
- [ ] Create `MessageAITests/Services/ProactiveAssistantServiceTests.swift`
- [ ] **Gate:** Detection <1s, 90%+ accuracy, <5% false positives, end-to-end <5s

---

## 4. Slack Service (3 hours)

- [ ] Create `Services/Integration/SlackIntegrationService.swift`
  - `initiateOAuthFlow()` → URL
  - `handleOAuthCallback(code)` → SlackWorkspace
  - `fetchChannels(workspaceId)` → [SlackChannel]
  - `fetchThread(workspaceId, channelId, threadTs)` → SlackThread
- [ ] Store OAuth tokens: `/users/{userId}/integrations/slack/workspaces/`
- [ ] Cache threads: `/users/{userId}/slackThreads/` (24h TTL)
- [ ] Implement `summarizeSlackThread(thread)` → Reuse PR #AI-006 summarization
- [ ] Index Slack messages in Pinecone (PR #AI-001) for cross-platform search
- [ ] Create `MessageAITests/Services/SlackIntegrationServiceTests.swift`
- [ ] **Gate:** OAuth <30s, fetch 100 messages <3s, summarize <3s, total <8s

---

## 5. UI - Meeting Suggestions (3 hours)

- [ ] Create `Views/AI/ProactiveAssistant/MeetingSuggestionsView.swift`
  - Modal: Requestor info, AI reasoning card, 3 time cards, mini calendar preview
  - Actions: "Book [Time]", "Suggest Different", "Ignore"
- [ ] Create `Components/Integration/CalendarPreviewComponent.swift`
  - 7-day mini calendar, gray blocks (events), yellow (focus hours), green pulse (suggestion)
- [ ] Create `Components/Integration/FocusHoursPickerView.swift`
  - Time pickers (10am-2pm default), day checkboxes (Mon-Fri)
- [ ] Create `Views/AI/ProactiveAssistant/IntegrationSettingsView.swift`
  - Google Calendar: Connect/disconnect, status, focus hours picker
  - Slack: Connect workspace, list workspaces, disconnect
- [ ] **Gate:** SwiftUI previews work, dark mode supported, animations smooth (60fps)

---

## 6. UI - Slack Integration (2 hours)

- [ ] Create `Views/AI/ProactiveAssistant/SlackThreadImportView.swift`
  - Select workspace → Browse channels → Select thread
- [ ] Create `Views/AI/ProactiveAssistant/SlackThreadSummaryView.swift`
  - Reuse `ThreadSummaryView` from PR #AI-006 with Slack branding
  - Display: Summary, decisions, action items, participants, transparency
  - Actions: "Open in Slack" (deep link), "Extract Items", "Search"
- [ ] Create `Components/Integration/OAuthFlowView.swift`
  - `SFSafariViewController` for OAuth, handle callback
- [ ] **Gate:** Import flow works, summary displays correctly, actions functional

---

## 7. ViewModels (2 hours)

- [ ] Create `ViewModels/AI/MeetingSuggestionsViewModel.swift`
  - Properties: `@Published var suggestion`, `isLoading`, `error`
  - Methods: `loadSuggestion()`, `bookMeeting()`, `dismissSuggestion()`
  - Listen to Firestore: `/users/{userId}/meetingSuggestions/`
- [ ] Create `ViewModels/AI/CalendarIntegrationViewModel.swift`
  - Properties: `@Published var integration`, `isConnected`
  - Methods: `connectCalendar()`, `disconnectCalendar()`, `updateFocusHours()`
- [ ] Create `ViewModels/AI/SlackIntegrationViewModel.swift`
  - Properties: `@Published var workspaces`, `channels`, `currentThread`
  - Methods: `connectWorkspace()`, `fetchChannels()`, `fetchThread()`, `summarizeThread()`
- [ ] **Gate:** State management works, real-time updates, UI reflects changes

---

## 8. Cloud Functions (2 hours)

- [ ] Create `functions/src/integration/googleCalendar.ts`
  - `createCalendarEvent` (HTTP callable): Call Calendar API, return eventId
  - `fetchCalendarAvailability` (HTTP callable): Call freebusy.query, return free times
- [ ] Create `functions/src/integration/slack.ts`
  - `fetchSlackThread` (HTTP callable): Call conversations.history, cache in Firestore
  - `fetchSlackChannels` (HTTP callable): Call conversations.list
- [ ] Create `functions/src/__tests__/integration.test.ts` (test all functions)
- [ ] Deploy: `cd functions && npm run build && firebase deploy --only functions`
- [ ] **Gate:** All functions deployed, callable from iOS

---

## 9. Integration & Real-Time (2 hours)

- [ ] Update `Services/NotificationService.swift`: Add `.meetingSuggestion` type
- [ ] Notification payload: `{ suggestionId, requestorName, snippet }`
- [ ] Tap notification → Navigate to `MeetingSuggestionsView`
- [ ] Add deep linking: `messageai://meeting-suggestion/{id}`, `messageai://slack-thread/{workspace}/{channel}/{thread}`
- [ ] Update `SmartSearchService.swift` (PR #AI-008): Include Slack messages, add platform badges
- [ ] **Gate:** Notification <5s, tap opens view, search returns both platforms <2s

---

## 10. Error Handling (2 hours)

- [ ] Calendar errors: OAuth failure, API timeout, rate limit, no available times
- [ ] Slack errors: Workspace revoked, thread deleted, rate limit, network failure
- [ ] All use `AIErrorHandler` (PR #AI-005): Calm blue/gray UI, first-person messages
- [ ] Fallbacks: "Suggest manually", "Open in Slack", "Try again in 30s"
- [ ] Token refresh: Auto-refresh expired tokens, prompt re-auth if needed
- [ ] False positive handling: Dismissible suggestions, "Was this helpful?" feedback
- [ ] **Gate:** All errors show calm UI with working fallbacks

---

## 11. Testing (3 hours)

**Unit Tests** (Swift Testing)
- [ ] GoogleCalendarServiceTests, SlackIntegrationServiceTests, ProactiveAssistantServiceTests
- [ ] Run: `xcodebuild test -scheme MessageAI`
- [ ] **Gate:** All unit tests pass

**UI Tests** (XCTest)
- [ ] Create `MessageAIUITests/ProactiveAssistantUITests.swift`
- [ ] Test: Detection → Notification → View → Book meeting
- [ ] Test: Connect Calendar → OAuth → Success
- [ ] Test: Connect Slack → OAuth → Import thread → Summary
- [ ] **Gate:** All UI tests pass

**Performance Tests**
- [ ] Detection: 100 messages → p95 <1s, 90%+ accuracy
- [ ] Calendar: Availability <2s, suggestions <1s
- [ ] Slack: Fetch <3s, summarize <3s, total <8s
- [ ] End-to-end: Detection → booking <10s
- [ ] **Gate:** All performance targets met (PRD Section 12)

**Acceptance Gates** (22 tests from PRD)
- [ ] T1-T7: Happy path (detection, OAuth, suggestions, booking, Slack)
- [ ] T8-T12: Edge cases (failures, rate limits, false positives)
- [ ] T13-T17: Performance tests
- [ ] T18-T22: Security, quality, accuracy tests
- [ ] **Gate:** All 22 gates pass ✅

---

## 12. Documentation (1 hour)

- [ ] Update README: Google Calendar setup (OAuth credentials, redirect URIs)
- [ ] Update README: Slack setup (App creation, scopes, workspace install)
- [ ] Create `docs/troubleshooting/oauth-integration.md` (common OAuth errors + solutions)
- [ ] Add inline comments for OAuth flows and API integration
- [ ] Verify `.gitignore` excludes OAuth credentials
- [ ] **Gate:** New developer can follow README to set up integrations

---

## 13. Deployment (1 hour)

- [ ] Add Firebase Remote Config flags: `proactive_assistant_enabled`, `google_calendar_integration_enabled`, `slack_integration_enabled`
- [ ] Update `firestore.rules` (new collections: integrations, meetingSuggestions, slackThreads)
- [ ] Update `firestore.indexes.json` (indexes for meetingSuggestions, slackThreads)
- [ ] Deploy: `firebase deploy --only firestore:rules,firestore:indexes`
- [ ] Verify OAuth credentials in Firebase Functions config
- [ ] **Gate:** Feature flags work, security rules tested, indexes created

---

## 14. Final Verification (1.5 hours)

- [ ] Fresh app install → Connect Calendar → Connect Slack
- [ ] Send "let's meet tomorrow" → Notification → View suggestions → Book → Event created ✅
- [ ] Import Slack thread → Fetch → Summarize → Display ✅
- [ ] Cross-platform search "Q4 roadmap" → Results from both platforms ✅
- [ ] Performance validation: All targets met, no regressions
- [ ] Code quality: Follows `shared-standards.md`, no warnings, no TODOs
- [ ] Real-world testing: Use actual Google Calendar + Slack workspace
- [ ] **Gate:** Complete user journey works flawlessly

**Create PR**
- [ ] Verify with user before creating PR
- [ ] PR title: `[PR-011] Proactive Assistant with Google Calendar & Slack Integration`
- [ ] Link PRD, TODO, add demo video/screenshots
- [ ] Include performance metrics and test results
- [ ] Request review

---

## Quick Checklist (for PR)

```markdown
✅ Features: Meeting detection, Calendar integration, Slack integration, Cross-platform search
✅ Performance: Detection <1s, Calendar <2s, Slack <8s, End-to-end <10s
✅ Testing: 22 acceptance gates passed, Unit + UI + Performance tests pass
✅ Quality: Follows shared-standards.md, Dark mode, Error handling (AIErrorHandler)
✅ Documentation: README updated, Troubleshooting guide, Inline comments
✅ Deployment: Feature flags, Security rules, Indexes, Functions deployed
✅ No secrets committed, OAuth tested, Real-world validated
```

---

**Total Time:** 30-35 hours  
**Prerequisites:** 2-3 hours (complete Section 0 first!)  
**Development:** 25-28 hours  
**Testing & Docs:** 3-4 hours

**Ready to build! 🚀**

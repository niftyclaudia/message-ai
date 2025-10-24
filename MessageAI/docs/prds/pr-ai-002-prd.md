# PRD: User Preference Storage System

**Feature**: AI User Preferences  

**Version**: 1.0  

**Status**: Ready for Development  

**Agent**: Pete  

**Target Release**: Phase 1 - Foundation (AI Features)  

**Links**: 
- [PR Brief](../ai-implementation-brief.md#pr-ai-002-user-preference-storage-system)
- [TODO](../todos/pr-ai-002-todo.md) - *To be created after PRD approval*
- [Architecture](../architecture.md)

---

## 1. Summary

Remote professionals like Maya need AI-powered message prioritization that respects their unique work patterns and urgency definitions. This PR implements a comprehensive user preference storage system that enables users to configure focus hours, urgent contacts, keywords, priority rules, and communication tone, ensuring AI features represent the user authentically and learn from their feedback.

---

## 2. Problem & Goals

### Problem
AI categorization without personalization is generic and inaccurate. Maya's definition of "urgent" differs from others:
- Her CTO's messages are always urgent; marketing team messages can wait
- "Production down" is urgent; "FYI" is not
- She protects 10am-2pm for deep work; AI must respect this
- Over time, AI should learn from her manual overrides to improve accuracy

**Why now?**
- Foundation for all AI features (PR #AI-006 through PR #AI-011)
- Must be built BEFORE Priority Detection, Thread Summarization, and Proactive Assistant
- Without preferences, AI cannot deliver personalized, trustworthy results

### Goals (Ordered, Measurable)
- [x] **G1** — Enable users to configure focus hours, urgent contacts (min 1, max 20), urgent keywords (min 3, max 50), and priority rules with clear UI explanations
- [x] **G2** — Store user preferences in Firestore with 90-day auto-cleanup for privacy compliance, achieving <100ms read latency and <200ms write latency
- [x] **G3** — Collect learning data from user overrides (when AI categorizes message as "Urgent" but user moves to "Can Wait") to improve AI accuracy from 75% → 95%+ over 30 days

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep:

- [ ] **Not building AI categorization logic** — This PR only stores preferences; PR #AI-009 (Priority Detection) uses them
- [ ] **Not implementing preference sync across devices** — Firebase handles this automatically
- [ ] **Not building advanced ML training** — Learning data stored for future use; simple pattern matching initially
- [ ] **Not adding calendar integration** — PR #AI-011 (Proactive Assistant) handles meeting scheduling
- [ ] **Not creating admin analytics dashboard** — PR #AI-015 (Production Monitoring) covers this

---

## 4. Success Metrics

### Performance (See shared-standards.md)
- Fetch: <100ms (p95) | Save: <200ms (p95) | Sync: <500ms across devices

### User Experience
- Configuration time: <2 min for all settings
- Save feedback: <300ms visual confirmation
- AI accuracy improvement: 75% → 85%+ after 10 overrides

### Quality
- Data integrity: 100% | Privacy: 90-day cleanup verified | Crash-free: >99.9% | 0 blocking bugs

---

## 5. Users & Stories

### Primary User: Maya (Remote Professional)

**As Maya**, I want to configure my focus hours (10am-2pm daily) so that AI respects my deep work time and doesn't categorize messages as "urgent" during this window unless from critical contacts.

**As Maya**, I want to mark my manager, CTO, and key clients as "urgent contacts" so that their messages are always prioritized regardless of content.

**As Maya**, I want to define urgent keywords ("production down", "critical", "ASAP", "urgent") so that AI detects time-sensitive issues even from non-urgent contacts.

**As Maya**, I want to set priority rules (@mentions with deadlines = urgent, FYIs = can wait) so that AI understands context beyond simple keyword matching.

**As Maya**, I want to choose my communication tone (professional/friendly/supportive) so that AI-generated responses match my personal style.

**As Maya**, I want AI to learn from my corrections (when I manually change categorization) so that accuracy improves over time without me re-training.

---

## 6. Experience Specification (UX)

### Entry Points
1. **Settings → AI Preferences** (primary path from Profile tab)
2. **First-time onboarding** (optional "Configure AI" prompt after signup)

### Main Screen Components
**AI Preferences Screen** includes 5 sections:
- **Focus Hours**: Toggle + time picker (10:00 AM - 2:00 PM) + day selector (M-F)
- **Urgent Contacts**: List with avatars + add/remove buttons (max 20)
- **Urgent Keywords**: Tag input field (comma-separated, min 3, max 50)
- **Priority Rules**: Toggle switches for 4 predefined rules
- **Communication Tone**: Radio buttons (Professional/Friendly/Supportive)
- **Privacy Notice**: "AI learns from your corrections • Data auto-deleted after 90 days"

Each section has info icon (ⓘ) with tooltip explanation.

### Key States
- **Loading**: Skeleton view with progress indicator
- **Configured**: All fields populated with user data
- **Saving**: Disabled inputs + spinner on Save button
- **Success**: "✓ Preferences saved" toast (300ms)
- **Error**: "⚠️ Unable to save. [Retry]" banner
- **Empty**: First-time user sees "👋 Let's personalize your AI" with default values

### Performance Targets
- Screen load: <500ms | Save: <200ms | Real-time sync: <500ms across devices

---

## 7. Functional Requirements

### MUST Requirements

1. **Focus Hours**: Enable/disable toggle, time picker (30-min increments), day selector (Mon-Sun)
2. **Urgent Contacts**: Add/remove from chat participants (min 1, max 20), display name + avatar
3. **Urgent Keywords**: Comma-separated input (min 3, max 50), case-insensitive, defaults: "urgent, critical, asap"
4. **Priority Rules**: 4 predefined toggles (@mentions+deadlines→Urgent, FYIs→Can Wait, Questions→Can Wait, Approvals→Urgent)
5. **Communication Tone**: Radio select (Professional/Friendly/Supportive), default: Friendly
6. **Data Persistence**: Save to Firestore `/users/{userId}/preferences/`, real-time sync <500ms
7. **Learning Data**: Log user overrides (messageId, originalCategory, userCategory, timestamp) to `/aiState/learningData/`
8. **Privacy**: 90-day auto-delete for learning data, visible disclosure, daily cleanup via Cloud Function

**Acceptance Gates**: See Section 12 (Test Plan) for detailed validation criteria.

### SHOULD Requirements (Nice-to-Have)

- Smart defaults from user industry/frequent contacts
- Inline validation errors
- Preference templates ("Remote Worker", "Team Lead") — *Deferred to PR #AI-014*

---

## 8. Data Model

### Firestore Schema

#### Collection: `/users/{userId}/preferences/`

**Document: `aiPreferences`**
```swift
struct UserPreferences: Codable {
    // Focus Hours
    var focusHours: FocusHours
    
    // Urgent Contacts
    var urgentContacts: [String]  // Array of user IDs
    
    // Urgent Keywords
    var urgentKeywords: [String]  // Array of keywords (lowercase)
    
    // Priority Rules
    var priorityRules: PriorityRules
    
    // Communication Tone
    var communicationTone: CommunicationTone
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var version: Int  // Schema version for migrations
}

struct FocusHours: Codable {
    var enabled: Bool
    var startTime: String  // "10:00" (24-hour format)
    var endTime: String    // "14:00" (24-hour format)
    var daysOfWeek: [Int]  // [1,2,3,4,5] = Mon-Fri (0 = Sunday)
}

struct PriorityRules: Codable {
    var mentionsWithDeadlines: Bool  // @mentions + deadline words → Urgent
    var fyiMessages: Bool            // FYI → Can Wait
    var questionsNeedingResponse: Bool  // Questions → Can Wait
    var approvalsAndDecisions: Bool  // Approval language → Urgent
}

enum CommunicationTone: String, Codable {
    case professional = "professional"
    case friendly = "friendly"
    case supportive = "supportive"
}
```

#### Collection: `/users/{userId}/aiState/learningData/`

**Document: `{overrideId}`** (auto-generated)
```swift
struct LearningDataEntry: Codable {
    var id: String
    var messageId: String
    var chatId: String
    var originalCategory: MessageCategory  // AI's prediction
    var userCategory: MessageCategory      // User's correction
    var timestamp: Date
    var messageContext: MessageContext     // Metadata for learning
    var createdAt: Date
}

struct MessageContext: Codable {
    var senderUserId: String
    var messagePreview: String  // First 100 chars
    var hadDeadline: Bool
    var hadMention: Bool
    var matchedKeywords: [String]
}

enum MessageCategory: String, Codable {
    case urgent = "urgent"
    case canWait = "can_wait"
    case aiHandled = "ai_handled"
}
```

### Default Preferences
```swift
static let defaultPreferences = UserPreferences(
    focusHours: FocusHours(
        enabled: false,
        startTime: "10:00",
        endTime: "14:00",
        daysOfWeek: [1, 2, 3, 4, 5]  // Mon-Fri
    ),
    urgentContacts: [],
    urgentKeywords: ["urgent", "critical", "asap", "emergency", "production down"],
    priorityRules: PriorityRules(
        mentionsWithDeadlines: true,
        fyiMessages: true,
        questionsNeedingResponse: false,
        approvalsAndDecisions: true
    ),
    communicationTone: .friendly,
    createdAt: Date(),
    updatedAt: Date(),
    version: 1
)
```

### Validation Rules

**Firestore Security Rules**
```javascript
match /users/{userId}/preferences/{document=**} {
  allow read, write: if request.auth.uid == userId;
  
  // Validate preference constraints
  allow write: if request.resource.data.urgentContacts.size() <= 20
            && request.resource.data.urgentKeywords.size() <= 50
            && request.resource.data.urgentKeywords.size() >= 3;
}

match /users/{userId}/aiState/learningData/{document=**} {
  allow read, write: if request.auth.uid == userId;
  allow delete: if request.auth.uid == userId;
}
```

### Indexing/Queries

**Firestore Composite Indexes**
```
Collection: /users/{userId}/aiState/learningData/
Fields: timestamp (DESC), userCategory (ASC)
Purpose: Query recent overrides by category for learning patterns
```

---

## 9. API / Service Contracts

### PreferencesService.swift

```swift
protocol PreferencesServiceProtocol {
    /// Fetch user's AI preferences from Firestore
    /// - Returns: UserPreferences or nil if not configured
    /// - Throws: FirebaseError if fetch fails
    func fetchPreferences() async throws -> UserPreferences?
    
    /// Save user's AI preferences to Firestore
    /// - Parameter preferences: Complete UserPreferences object
    /// - Throws: ValidationError if invalid, FirebaseError if save fails
    func savePreferences(_ preferences: UserPreferences) async throws
    
    /// Update specific preference field without overwriting entire document
    /// - Parameters:
    ///   - field: Preference field to update (e.g., "focusHours.enabled")
    ///   - value: New value for the field
    func updatePreference(field: String, value: Any) async throws
    
    /// Add urgent contact to user's list
    /// - Parameter userId: User ID to add as urgent contact
    /// - Throws: ValidationError if max contacts (20) reached
    func addUrgentContact(_ userId: String) async throws
    
    /// Remove urgent contact from user's list
    /// - Parameter userId: User ID to remove
    func removeUrgentContact(_ userId: String) async throws
    
    /// Log learning data when user overrides AI categorization
    /// - Parameters:
    ///   - messageId: Message that was recategorized
    ///   - originalCategory: AI's prediction
    ///   - userCategory: User's correction
    ///   - context: Message context for learning
    func logOverride(
        messageId: String,
        chatId: String,
        originalCategory: MessageCategory,
        userCategory: MessageCategory,
        context: MessageContext
    ) async throws
    
    /// Fetch recent learning data for pattern analysis
    /// - Parameter days: Number of days to query (default: 30)
    /// - Returns: Array of recent overrides
    func fetchLearningData(days: Int) async throws -> [LearningDataEntry]
    
    /// Real-time listener for preference changes
    /// - Parameter completion: Callback with updated preferences
    /// - Returns: Listener registration for cleanup
    func observePreferences(completion: @escaping (UserPreferences?) -> Void) -> ListenerRegistration
}
```

### Error Handling

```swift
enum PreferencesError: Error, LocalizedError {
    case invalidFocusHours  // Start time >= End time
    case tooManyContacts    // >20 contacts
    case tooFewKeywords     // <3 keywords
    case tooManyKeywords    // >50 keywords
    case missingUserId
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidFocusHours:
            return "Focus hours must have start time before end time"
        case .tooManyContacts:
            return "Maximum 20 urgent contacts allowed"
        case .tooFewKeywords:
            return "Please add at least 3 urgent keywords"
        case .tooManyKeywords:
            return "Maximum 50 keywords allowed"
        case .missingUserId:
            return "User not authenticated"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
```

### Pre/Post-Conditions

**fetchPreferences()**
- Pre: User must be authenticated
- Post: Returns UserPreferences or nil (first time), throws on error
- Performance: <100ms (p95)

**savePreferences()**
- Pre: Valid UserPreferences object, user authenticated
- Post: Preferences saved to Firestore, updatedAt timestamp set
- Performance: <200ms (p95)

**logOverride()**
- Pre: Valid message ID, category values, user authenticated
- Post: Learning entry created with timestamp, cleanup scheduled at 90 days
- Performance: <150ms (p95)

---

## 10. UI Components to Create/Modify

### New Files to Create

#### Views
- `Views/AI/PreferencesSettingsView.swift` — Main settings screen for configuring all AI preferences
- `Views/AI/FocusHoursConfigView.swift` — Time picker and day selection for focus hours
- `Views/AI/UrgentContactsListView.swift` — List of urgent contacts with add/remove actions
- `Views/AI/UrgentKeywordsInputView.swift` — Tag-style input field for comma-separated keywords
- `Views/AI/PriorityRulesConfigView.swift` — Toggle switches for priority rules
- `Views/AI/CommunicationTonePickerView.swift` — Radio button picker for tone selection

#### Components
- `Views/Components/InfoTooltipView.swift` — Reusable info icon (ⓘ) with expandable explanation
- `Views/Components/PreferenceSectionView.swift` — Section header with title and info button
- `Views/Components/ContactSelectionSheetView.swift` — Modal sheet for selecting contacts from chat participants

#### Models
- `Models/AI/UserPreferences.swift` — Data model for all AI preferences
- `Models/AI/FocusHours.swift` — Focus hours configuration model
- `Models/AI/PriorityRules.swift` — Priority rules configuration model
- `Models/AI/CommunicationTone.swift` — Enum for tone selection
- `Models/AI/LearningDataEntry.swift` — Learning data log entry model
- `Models/AI/MessageContext.swift` — Message context for learning

#### Services
- `Services/AI/PreferencesService.swift` — Core service for CRUD operations on preferences

#### ViewModels
- `ViewModels/AI/PreferencesViewModel.swift` — State management for preferences screen
- `ViewModels/AI/UrgentContactsViewModel.swift` — State management for urgent contacts list

### Existing Files to Modify

- `Views/Profile/ProfileView.swift` — Add "AI Preferences" menu item
- `Views/Main/MainTabView.swift` — Add navigation route to PreferencesSettingsView
- `MessageAI/MessageAIApp.swift` — Initialize PreferencesService on app launch

---

## 11. Integration Points

### Firebase Services
- **Firestore**: Store and sync preferences, learning data
  - Collection: `/users/{userId}/preferences/`
  - Collection: `/users/{userId}/aiState/learningData/`
  - Real-time listeners for preference updates
  
- **Firebase Authentication**: Validate user access to preferences
  - Security rules enforce userId == request.auth.uid
  
- **Cloud Functions** (Future integration):
  - Scheduled function for 90-day data cleanup
  - Function to aggregate learning patterns

### iOS State Management
- **@StateObject**: PreferencesViewModel in PreferencesSettingsView
- **@EnvironmentObject**: AuthService for userId access
- **@Published**: Preferences properties trigger UI updates

### Future AI Features Integration
This preference system will be consumed by:
- **PR #AI-009**: Priority Detection (uses urgentContacts, urgentKeywords, focusHours, priorityRules)
- **PR #AI-006**: Thread Summarization (uses communicationTone)
- **PR #AI-011**: Proactive Assistant (uses focusHours for meeting scheduling)
- **PR #AI-004**: Memory/State (stores learning data for pattern analysis)

---

## 12. Test Plan & Acceptance Gates

Reference `MessageAI/agents/shared-standards.md` for testing patterns.

### Key Test Scenarios (Swift Testing + XCTest)

#### Happy Path (5 tests)
1. **Configure & Save** — Focus hours, contacts, keywords, rules, tone → Save <200ms → Firestore updated
2. **Add Urgent Contact** — Select from chat participants → Avatar displays → Saved to array
3. **Learning Data Logging** — User overrides AI category → Log created with context
4. **Real-Time Sync** — Save on iPhone → iPad updates <500ms
5. **First-Time User** — Empty state with defaults → Configure → Save successfully

#### Edge Cases (5 tests)
1. **Invalid Focus Hours** — Start time ≥ End time → Validation error → Save disabled
2. **Max Contacts (20)** — Attempt 21st → Error: "Maximum 20 contacts" → Add disabled
3. **Min Keywords (3)** — Enter 2 → Error: "Add at least 3 keywords" → Suggest defaults
4. **Network Failure** — Save while offline → "⚠️ Unable to save [Retry]" → Retry when online
5. **Concurrent Edits** — Edit on 2 devices → Last write wins → No corruption

#### Performance & Privacy (4 tests)
1. **Load Time** — Screen loads <500ms with data populated
2. **Save Latency** — Modify 3 fields → Save <200ms (p95) → Immediate feedback
3. **90-Day Cleanup** — Entry >90 days old → Auto-deleted → Recent data preserved
4. **Data Isolation** — User A preferences → User B cannot read (security rules)

**Total**: 14 acceptance gates covering all critical paths, edge cases, and performance targets.

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:

- [x] **Service Layer Complete**
  - [ ] PreferencesService.swift implements all protocol methods with error handling
  - [ ] Unit tests cover all service methods (Swift Testing framework)
  - [ ] All service tests pass with 0 failures

- [x] **Data Models Defined**
  - [ ] UserPreferences.swift with all nested models (FocusHours, PriorityRules, etc.)
  - [ ] LearningDataEntry.swift with MessageContext
  - [ ] All models conform to Codable and handle Firestore Timestamps

- [x] **SwiftUI Views Complete**
  - [ ] PreferencesSettingsView.swift with all sections
  - [ ] FocusHoursConfigView, UrgentContactsListView, UrgentKeywordsInputView
  - [ ] All info tooltips, validation errors, and empty states implemented
  - [ ] Loading, success, and error states render correctly

- [x] **Firebase Integration**
  - [ ] Firestore schema matches PRD Section 8 exactly
  - [ ] Security rules enforce userId validation
  - [ ] Real-time listener updates preferences across devices <500ms
  - [ ] Offline persistence enabled (Firestore caching)

- [x] **Validation & Error Handling**
  - [ ] Inline validation for all fields (max contacts, min keywords, valid times)
  - [ ] User-friendly error messages for all error cases
  - [ ] Retry mechanism for network failures

- [x] **UI/UX Polish**
  - [ ] Info tooltips (ⓘ) explain each preference clearly
  - [ ] Success/error feedback within 300ms
  - [ ] Empty state for first-time users
  - [ ] Smooth animations (300ms transitions)

- [x] **Testing Complete**
  - [ ] All 23 acceptance gates pass (Happy Path, Edge Cases, Multi-User, Performance, Privacy)
  - [ ] Unit tests (Swift Testing) for PreferencesService
  - [ ] UI tests (XCTest) for PreferencesSettingsView
  - [ ] Multi-device sync verified manually

- [x] **Performance Targets Met**
  - [ ] Fetch preferences: <100ms (p95)
  - [ ] Save preferences: <200ms (p95)
  - [ ] Real-time sync: <500ms across devices
  - [ ] Screen load: <500ms

- [x] **Documentation**
  - [ ] Inline code comments for complex logic
  - [ ] README updated with "AI Preferences" feature description
  - [ ] PR description references PRD and TODO

- [x] **Code Quality**
  - [ ] No compiler warnings
  - [ ] No linter errors
  - [ ] Follows Swift/SwiftUI best practices from shared-standards.md
  - [ ] No hardcoded values; uses Constants.swift

---

## 14. Risks & Mitigations

### Risk 1: User Overwhelm (Too Many Settings)
**Impact:** High — Users abandon configuration, AI stays unpersonalized  
**Mitigation:**
- Provide smart defaults (5 common keywords, friendly tone)
- Use clear info tooltips (ⓘ) for every setting
- Offer preference templates ("Remote Worker", "Team Lead")
- Allow skipping configuration; AI works with defaults

### Risk 2: Learning Data Privacy Concerns
**Impact:** Medium — Users distrust AI feature if privacy unclear  
**Mitigation:**
- Transparent disclosure: "Data auto-deleted after 90 days"
- User-specific data isolation (Firestore security rules)
- No data sharing across users or external services
- Clear explanation of what's stored and why

### Risk 3: Preference Sync Conflicts
**Impact:** Medium — User edits same preference on two devices simultaneously  
**Mitigation:**
- Accept Firebase "last write wins" behavior (industry standard)
- Show timestamp of last update: "Last saved: 2 min ago"
- Rare occurrence; not worth complex conflict resolution

### Risk 4: Validation Bypass (Frontend Only)
**Impact:** High — Users exploit max limits by editing Firestore directly  
**Mitigation:**
- Firestore security rules enforce constraints (max 20 contacts, max 50 keywords)
- Backend validation in Cloud Functions before AI processing
- Monitor Firestore audit logs for unusual activity

### Risk 5: Performance Degradation with Large Learning Datasets
**Impact:** Medium — Query slow with 1000+ learning entries  
**Mitigation:**
- 90-day cleanup ensures <~270 entries per user (3/day average)
- Firestore composite index on timestamp for fast queries
- Pagination if user queries learning data (not in MVP)

---

## 15. Rollout & Telemetry

**Feature Flag**: `ai_preferences_enabled` (Firebase Remote Config)  
**Rollout**: 5% → 20% → 50% → 100%

### Metrics (See Section 4 for targets)
- **Adoption**: Configuration rate, time to configure, field popularity
- **Usage**: Focus hours adoption, avg contacts per user, keyword customization, tone distribution
- **Quality**: Save success rate, error rate, sync latency, learning entries/week
- **Learning**: AI accuracy improvement (before/after overrides), override frequency (should decrease)

### Validation
1. Test on simulator + 2 physical devices (real-time sync)
2. Verify Firestore schema matches Section 8
3. Test validation rules (max contacts, min keywords, invalid times)
4. Simulate 91-day-old data → Verify cleanup

---

## 16. Open Questions & Deferred Features

### Open Questions
1. **Manual data deletion?** → Auto-delete only (90 days) for MVP; add "Clear Learning Data" if requested
2. **Preference templates?** → Defer to PR #AI-014 (UX Polish); manual config only for MVP
3. **Timezone handling?** → Store in local time (simpler); defer UTC conversion to post-MVP
4. **Learning data visibility?** → Show "You've corrected X messages" for transparency (aligns with Calm Intelligence)

### Out of Scope (Backlog)
Deferred to future PRs:
- Preference templates ("Remote Worker", "Team Lead") → PR #AI-014
- Advanced learning analytics (charts, patterns) → Post-MVP
- Import/export preferences → Post-MVP
- Team-level sharing → Post-MVP
- Calendar integration for focus hours → PR #AI-011 extension
- Multi-timezone support → Post-MVP

---

## Summary

**Smallest End-to-End Outcome:** User configures preferences (focus hours, contacts, keywords) → Saves <200ms → Firestore syncs <500ms → AI features (PR #AI-009+) respect personalization.

**Key Design Decisions:**
1. Separate collections (preferences = long-term, learningData = transient 90-day cleanup)
2. Real-time sync via Firestore listeners (no manual refresh)
3. 3-layer validation (Frontend UI → Firestore rules → Cloud Functions)
4. Defaults work immediately (configuration is optional enhancement)

**Testing:** Unit tests (Swift Testing), UI tests (XCTest), multi-device manual testing

---

**Author:** Pete Agent (Product Manager)  
**Status:** Ready for Review  
**Next Step:** Await user approval → Create TODO  
**Estimated Implementation:** 2-3 days (12-15 tasks)


# PR-AI-002 TODO — User Preference Storage System

**Branch**: `feat/ai-002-user-preferences`  
**Source PRD**: `MessageAI/docs/prds/pr-ai-002-prd.md`  
**Owner (Agent)**: Cody iOS / Pete

---

## 0. Prerequisites & Setup (Complete BEFORE Starting)

### Environment Setup
- [ ] **Verify Xcode version** — iOS 16+ support, Swift 5.9+
  - Command: `xcodebuild -version` (should be Xcode 14.0+)
  
- [ ] **Verify Firebase SDK** — Firebase iOS SDK 10.x installed
  - Check: `MessageAI.xcodeproj` → Package Dependencies → firebase-ios-sdk
  
- [ ] **Install/Update Firebase CLI** (for Firestore rules deployment)
  ```bash
  npm install -g firebase-tools
  firebase --version  # Should be 12.0.0+
  ```

### Firebase Console Setup
- [ ] **Create Firestore collections** (if not exist):
  - Navigate to Firebase Console → Firestore Database
  - Confirm `/users/` collection exists
  - Collections will be created automatically on first write, but verify structure access

- [ ] **Enable Firestore offline persistence** (already enabled in MessageAI)
  - Verify in `MessageAIApp.swift` → Firestore settings

### Project Familiarization
- [ ] **Read PRD thoroughly** — `MessageAI/docs/prds/pr-ai-002-prd.md`
- [ ] **Read shared standards** — `MessageAI/agents/shared-standards.md`
- [ ] **Review existing User model** — `MessageAI/MessageAI/Models/User.swift`
- [ ] **Review existing services** — `MessageAI/MessageAI/Services/AuthService.swift`, `UserService.swift`
- [ ] **Understand Firestore patterns** — Check `ChatService.swift` for listener examples

---

## 1. Branch Setup

- [x] **Create feature branch from develop**
  ```bash
  cd /Users/claudiaalban/Desktop/MessagingApp-secondagent
  git checkout develop
  git pull origin develop
  git checkout -b feat/ai-002-user-preferences
  ```
  - **Acceptance**: Branch created, no uncommitted changes from develop ✅

- [ ] **Verify project builds** — Confirm baseline works before changes
  ```bash
  xcodebuild -scheme MessageAI -configuration Debug build
  ```
  - **Acceptance**: Build succeeds with 0 errors, 0 warnings

- [ ] **Run existing tests** — Ensure tests pass before modifications
  ```bash
  xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 15'
  ```
  - **Acceptance**: All existing tests pass (baseline)

---

## 2. Data Models (5 Models)

### Task 2.1: Create UserPreferences Model
- [x] **Create**: `Models/AI/UserPreferences.swift` ✅
- [x] **Define**: UserPreferences struct with fields: id, focusHours, urgentContacts[], urgentKeywords[], priorityRules, communicationTone, createdAt, updatedAt, version ✅
- [x] **Add**: Firestore Timestamp encoding/decoding (see User.swift), static defaults (PRD Section 8), validation helpers ✅
- **Gate**: Compiles, Codable, has validation methods ✅

### Task 2.2: Create Supporting Models
- [x] **Create**: `Models/AI/FocusHours.swift` — enabled, startTime, endTime, daysOfWeek[], isValid computed property ✅
- [x] **Create**: `Models/AI/PriorityRules.swift` — 4 Bool toggles (mentions, fyis, questions, approvals) ✅
- [x] **Create**: `Models/AI/CommunicationTone.swift` — Enum (professional, friendly, supportive), CaseIterable ✅
- [x] **Create**: `Models/AI/LearningDataEntry.swift` — messageId, categories, timestamp, MessageContext, MessageCategory enum ✅
- **Gate**: All models compile, defaults match PRD, validation works ✅

---

## 3. Service Layer (PreferencesService)

### Task 3.1: Create PreferencesService Protocol & Implementation
- [x] **Create**: `Services/AI/PreferencesService.swift` ✅
- [x] **Define protocol** with 8 methods: fetchPreferences(), savePreferences(), updatePreference(), addUrgentContact(), removeUrgentContact(), logOverride(), fetchLearningData(), observePreferences() (see PRD Section 9) ✅
- [x] **Implement fetch/save** — Read/write `/users/{userId}/preferences/aiPreferences`, validate constraints (min 3 keywords, max 20 contacts, valid times), handle Timestamp conversion ✅
- [x] **Implement contacts** — Add/remove with validation, check max (20), avoid duplicates ✅
- [x] **Implement learning** — Log overrides to `/aiState/learningData/`, query with date filter, limit 100 entries ✅
- [x] **Implement listener** — Real-time Firestore snapshot, return ListenerRegistration for cleanup ✅
- [x] **Add PreferencesError enum** — invalidFocusHours, tooManyContacts, tooFewKeywords, tooManyKeywords, missingUserId, networkError ✅
- **Gate**: All methods work, validation catches edge cases, listener triggers on changes ✅

---

## 4. ViewModels (State Management)

### Task 4.1: Create PreferencesViewModel
- [x] **Create**: `ViewModels/AI/PreferencesViewModel.swift` ✅
- [x] **Define**: @MainActor class with @Published properties (preferences, isLoading, isSaving, errorMessage, showSuccessMessage) ✅
- [x] **Implement**: loadPreferences() (fetch or use defaults), savePreferences() (validate + save + show success), add/removeUrgentContact() (optimistic updates) ✅
- [x] **Add real-time sync**: startObserving() (setup listener), stopObserving() (cleanup on deinit) ✅
- [x] **Dependency injection**: Pass PreferencesService in init ✅
- **Gate**: Load works, save validates, contacts update optimistically, listener syncs across devices ✅

---

## 5. UI Components (10 Views)

### Task 5.1: Create Main Preferences Screen
- [x] **Create**: `Views/AI/PreferencesSettingsView.swift` — NavigationView + Form with 5 sections, Save toolbar button, loading/success/error states ✅

### Task 5.2: Create Configuration Views (5 sections)
- [x] **Create**: `Views/AI/FocusHoursConfigView.swift` — Toggle + DatePicker (start/end times) + day selector + info tooltip ✅
- [x] **Create**: `Views/AI/UrgentContactsListView.swift` — List with avatars, swipe-to-delete, "Add Contact" button (max 20), count badge ✅
- [x] **Create**: `Views/AI/ContactSelectionSheetView.swift` — Searchable sheet, filter existing, tap to add + dismiss ✅
- [x] **Create**: `Views/AI/UrgentKeywordsInputView.swift` — TextField (comma-separated), count display, inline validation (min 3, max 50) ✅
- [x] **Create**: `Views/AI/PriorityRulesConfigView.swift` — 4 Toggle switches with tooltips ✅
- [x] **Create**: `Views/AI/CommunicationTonePickerView.swift` — Radio Picker (professional/friendly/supportive) ✅

### Task 5.3: Create Reusable Components
- [x] **Create**: `Views/Components/InfoTooltipView.swift` — Info icon (ⓘ), tap to show popover, reusable ✅
- [x] **Add toast messages**: Success ("✓ Saved", 300ms) + Error banner ("⚠️ [Retry]") ✅
- [x] **Add empty state**: "👋 Welcome!" for first-time users with "Get Started" button ✅
- **Gate**: All views render, validation works, tooltips display, success/error feedback shows ✅

---

## 6. Navigation Integration

### Task 6.1: Add AI Preferences to Profile Menu
- [x] **Modify file**: `MessageAI/MessageAI/Views/Profile/ProfileView.swift` ✅
- [x] **Add navigation link**:
  ```swift
  NavigationLink(destination: PreferencesSettingsView()) {
      Label("AI Preferences", systemImage: "brain")
  }
  ``` ✅
- [x] **Place after "Edit Profile" or in Settings section** ✅
- **Acceptance**: Menu item appears, navigation works, icon displays ✅

### Task 6.2: Add Navigation Route in MainTabView
- [x] **Modify file**: `MessageAI/MessageAI/Views/Main/MainTabView.swift` ✅
- [x] **Ensure navigation stack supports deep linking** (if needed) ✅
- **Acceptance**: Navigation from Profile → AI Preferences works smoothly ✅

---

## 7. Firebase Integration

### Task 7.1: Update Firestore Security Rules
- [x] **Modify file**: `firestore.rules` ✅
- [x] **Add rules for preferences** (from PRD Section 8):
  ```javascript
  match /users/{userId}/preferences/{document=**} {
    allow read, write: if request.auth.uid == userId;
    
    allow write: if request.resource.data.urgentContacts.size() <= 20
              && request.resource.data.urgentKeywords.size() <= 50
              && request.resource.data.urgentKeywords.size() >= 3;
  }
  
  match /users/{userId}/aiState/learningData/{document=**} {
    allow read, write: if request.auth.uid == userId;
  }
  ``` ✅
- **Acceptance**: Rules validate constraints, users can only access own data ✅

### Task 7.2: Deploy Firestore Rules
- [ ] **Deploy rules to Firebase**:
  ```bash
  firebase deploy --only firestore:rules
  ```
- [ ] **Test rules in Firebase Console** — Rules Playground
  - Test read/write as authenticated user
  - Test blocked access for other users
- **Acceptance**: Rules deployed, validation works, access control enforced

### Task 7.3: Create Firestore Composite Index
- [ ] **Add index for learning data queries** (timestamp DESC, category ASC)
- [ ] **Option 1**: Let Firestore auto-generate index on first query (click link in console)
- [ ] **Option 2**: Add to `firestore.indexes.json`:
  ```json
  {
    "collectionGroup": "learningData",
    "queryScope": "COLLECTION",
    "fields": [
      { "fieldPath": "timestamp", "order": "DESCENDING" },
      { "fieldPath": "userCategory", "order": "ASCENDING" }
    ]
  }
  ```
- [ ] **Deploy indexes**: `firebase deploy --only firestore:indexes`
- **Acceptance**: Query runs without "needs index" error

---

## 8. Testing (5 Test Suites)

### Task 8.1: Unit Tests (Swift Testing)
- [x] **Create**: `MessageAITests/Services/PreferencesServiceTests.swift` ✅
- [x] **Test**: fetch (nil for new user), save (validation), add/remove contacts (max 20), logOverride, fetchLearningData (date filter) ✅
- **Gate**: All service methods tested, validation catches edge cases ✅

### Task 8.2: UI Tests (XCTest)
- [x] **Create**: `MessageAIUITests/AI/PreferencesUITests.swift` ✅
- [x] **Test**: Configure + save (success message), add/remove contacts, validation errors, empty state ✅
- **Gate**: UI flows work, errors display, happy path + edge cases covered ✅

### Task 8.3: Multi-Device Sync Test
- [ ] **Test**: Save on device 1 → Fetch on device 2 within 500ms → Data matches
- **Gate**: Real-time sync <500ms, preferences identical across devices

### Task 8.4: Performance Tests
- [ ] **Measure**: Fetch <100ms, Save <200ms, Screen load <500ms
- **Gate**: All performance targets met, documented in test results

### Task 8.5: Privacy & Security Tests
- [ ] **Test**: 90-day cleanup (insert old entry → verify deleted), data isolation (User A can't read User B's data)
- **Gate**: Cleanup works, Firestore security rules enforced

---

## 9. Documentation & Final Checks

### Task 9.1: Add Documentation
- [x] **Add Swift doc comments** to public APIs in PreferencesService ✅
- [x] **Comment complex logic** (validation, Firestore queries) ✅
- [ ] **Update README** with "AI Preferences" section (optional)
- **Gate**: Public methods documented, complex logic explained ✅

### Task 9.2: Manual Testing & Quality Check
- [ ] **Test end-to-end**: Fresh install → Configure → Save → Reopen → Persist → Modify → Save
- [ ] **Test multi-device**: 2 devices sync simultaneously
- [ ] **Run linter**: `swiftlint lint --path MessageAI/MessageAI/` → Fix warnings
- **Gate**: Full flow works, no crashes, 0 linter errors

---

## 10. PR Preparation & Merge

### Task 10.1: Prepare PR
- [ ] **Verify checklist**: All TODO tasks ✓, Definition of Done (PRD Section 13) met
- [ ] **Write PR description**: Summary, what's included (5 models, service, 10 views, tests), performance results, testing checklist
- [ ] **Add screenshots**: AI Preferences screen, focus hours config, contacts list
- **Gate**: PR description complete, references PRD/TODO, includes test results

### Task 10.2: Push & Create PR
- [ ] **Commit & push**:
  ```bash
  git add .
  git commit -m "feat(ai): Add user preference storage system (PR #AI-002)
  
  - 5 models: UserPreferences, FocusHours, PriorityRules, etc.
  - PreferencesService: CRUD, real-time sync, learning data
  - 10 SwiftUI views with validation, tooltips, success/error states
  - Tests: Unit (Swift Testing), UI (XCTest), multi-device sync
  - Performance: <100ms fetch, <200ms save, <500ms sync
  - Closes #AI-002"
  
  git push origin feat/ai-002-user-preferences
  ```
- [ ] **Create PR**: Base `develop`, title "feat(ai): User Preference Storage System (PR #AI-002)", use description from Task 10.1
- [ ] **Wait for approval** before merging
- **Gate**: PR created, CI/CD passes, ready for review

---

## Copyable Checklist (for PR description)

```markdown
### Definition of Done
- [x] Branch created from develop
- [x] All TODO tasks completed (47 tasks)
- [x] Services implemented + unit tests (Swift Testing)
- [x] SwiftUI views implemented with state management
- [x] Firebase integration tested (real-time sync, offline)
- [x] UI tests pass (XCTest)
- [x] Multi-device sync verified (<500ms)
- [x] Performance targets met (<100ms fetch, <200ms save)
- [x] All 14 acceptance gates pass
- [x] Code follows shared-standards.md patterns
- [x] No console warnings
- [x] Documentation updated
- [x] Firestore security rules deployed
- [x] Composite index created
```

---

## Key Reminders

**Design Patterns**: Dependency injection (service → ViewModel), @MainActor for UI, async/await for Firebase, optimistic UI, default preferences  
**Avoid**: Blocking main thread, skipping service validation, forgetting listener cleanup, hardcoding user IDs  
**Testing**: Firebase Emulator, mock for UI tests, test edge cases, realistic data  
**Performance**: Firestore composite index, listener only for preferences, 30-day query limit, cache locally

---

**Total Tasks**: 35 (condensed from 47)  
**Estimated Time**: 2-3 days (8-12 hours)  
**Complexity**: Medium

**Questions?** Reference PRD Section 16


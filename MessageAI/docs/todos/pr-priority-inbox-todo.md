# PR-AI-INBOX-001 TODO — Priority Inbox View

**Branch**: `feat/pr-ai-inbox-001-priority-inbox`  
**Source PRD**: `MessageAI/docs/prds/pr-tonight-ui-demo.md` (Priority 1)  
**PR Brief**: `MessageAI/docs/prds/pr-priority-inbox-brief.md`  
**Owner (Agent)**: Cody iOS  
**Estimated Time**: 45-60 minutes  
**Priority**: 🔴 HIGH - Hero feature for tonight's demo

---

## 0. Clarifying Questions & Assumptions

**Questions:** None - all decisions made for demo

**Assumptions:**
- Using mock data only (no Firebase tonight)
- Protocol-based service ready for future Firebase swap
- Dark mode must work
- 15-20 hardcoded messages sufficient for demo
- Smoke tests only tonight (full tests in next PR)

---

## 1. Setup (5 min)

- [ ] Create branch `feat/pr-ai-inbox-001-priority-inbox` from develop
- [ ] Read PR brief: `MessageAI/docs/prds/pr-priority-inbox-brief.md`
- [ ] Confirm Xcode builds without errors
- [ ] Create file structure:
  - `MessageAI/MessageAI/Views/AI/PriorityInboxView.swift`
  - `MessageAI/MessageAI/ViewModels/AI/PriorityInboxViewModel.swift`
  - `MessageAI/MessageAI/Components/AI/ReasoningModal.swift`

---

## 2. Data Models (10 min)

Copy from PR brief Section "Data Models"

- [ ] Create `PriorityInboxItem` struct with Identifiable
- [ ] Create `MessageCategory` enum with color/icon computed properties
- [ ] Create `PriorityReasoning` struct
- [ ] Create `ConfidenceLevel` enum with color computed property
- [ ] Add to appropriate Models folder
  - Test Gate: Models compile without errors

---

## 3. Mock Data & Service (10 min)

Copy from PR brief Section "Mock Data Implementation"

- [ ] Create `MockData` struct with `priorityInboxItems` static array
  - Add 2 Urgent messages (production API, deadline mention)
  - Add 4 Can Wait messages (FYI, open questions)
  - Add 5+ AI Handled messages (thanks, emoji, confirmations)
  - Test Gate: Mock data array compiles
  
- [ ] Create `PriorityInboxService` protocol
  - `fetchInbox()` → returns [PriorityInboxItem]
  - `recategorizeMessage(messageID, newCategory)` → async throws
  - `refreshInbox()` → returns [PriorityInboxItem]
  
- [ ] Create `MockPriorityInboxService` class implementing protocol
  - Add 0.5s delay in fetchInbox()
  - Add 1s delay in refreshInbox()
  - Test Gate: Service compiles, delays work

---

## 4. ViewModel (10 min)

Copy from PR brief Section "ViewModel Pattern"

- [ ] Create `PriorityInboxViewModel` class with `@MainActor`
- [ ] Add `@Published` properties:
  - `items: [PriorityInboxItem] = []`
  - `isLoading = false`
  - `error: Error?`
- [ ] Add computed properties for sections:
  - `urgentMessages` (filter by .urgent)
  - `canWaitMessages` (filter by .canWait)
  - `aiHandledMessages` (filter by .aiHandled)
- [ ] Implement methods:
  - `loadInbox()` async
  - `recategorize(messageID, to: category)` async
  - `refresh()` async
- [ ] Initialize with `service: PriorityInboxService = MockPriorityInboxService()`
  - Test Gate: ViewModel compiles, no force unwraps

---

## 5. Main View - Priority Inbox (15 min)

Reference PR brief Section "UI Requirements"

- [ ] Create `PriorityInboxView` SwiftUI view
- [ ] Add `@StateObject var viewModel = PriorityInboxViewModel()`
- [ ] Add `@State` for section expansion (urgent expanded by default)
- [ ] Build 3 collapsible sections:
  - **Urgent**: Red badge, expanded by default
  - **Can Wait**: Blue badge, collapsed
  - **AI Handled**: Gray badge, collapsed
- [ ] Add badge counts to section headers
- [ ] Implement section tap to expand/collapse
- [ ] Add empty state: "All caught up! 🎉" with green checkmark
  - Test Gate: SwiftUI preview shows 3 sections with badges

---

## 6. Message Cards Component (10 min)

Reference PR brief Section "UI Requirements - Message Cards"

- [ ] Create message card view inside PriorityInboxView or as component
- [ ] Display for each message:
  - Circular avatar (40pt) with sender initials fallback
  - Sender name (bold, .body font)
  - Message preview (1-2 lines, gray, lineLimit: 2)
  - Relative timestamp ("2h ago" or "Oct 23, 3:45 PM")
  - "Why?" info button (subtle, trailing)
- [ ] Add tap gesture → navigate to conversation
  - Use `NavigationLink` or programmatic navigation
- [ ] Add swipe actions → recategorize (Urgent ↔ Can Wait only)
  - Test Gate: Cards display all fields, tap/swipe work

---

## 7. Reasoning Modal (10 min)

Reference PR brief Section "UI Requirements - Reasoning Modal"

- [ ] Create `ReasoningModal` component (reusable sheet)
- [ ] Accept `PriorityReasoning` as parameter
- [ ] Display:
  - Header: "Why [Category]?"
  - Explanation text
  - Confidence badge (High/Moderate/Uncertain) with color
  - Signals as tag chips/list
  - "View message" link/button
- [ ] Make dismissible (swipe down or close button)
- [ ] Wire up "Why?" button tap → show modal
  - Test Gate: Modal displays correctly, dismisses properly

---

## 8. Design System & Animations (10 min)

Reference PR brief Section "Design Standards (Calm Intelligence)"

- [ ] Apply color palette:
  - Urgent: `Color(hex: "#FF6B6B")`
  - Can Wait: `Color(hex: "#4A90E2")`
  - AI Handled: `Color(hex: "#95A5A6")`
  - Success: `Color(hex: "#2ECC71")`
- [ ] Add spacing:
  - Screen edges: `.padding(20)`
  - Between cards: `VStack(spacing: 16)`
  - Card internal: `.padding(.vertical, 12)`
- [ ] Add animations:
  - Section expand/collapse: `.animation(.spring(response: 0.35, dampingFraction: 0.8))`
  - Transitions: `.transition(.move(edge: .top).combined(with: .opacity))`
- [ ] Add pull-to-refresh with loading indicator
  - Test Gate: Animations smooth at 60fps, colors correct

---

## 9. Navigation & Integration (5 min)

Reference PR brief Section "Files to Modify"

- [ ] Open `MessageAI/MessageAI/Views/Profile/ProfileView.swift`
- [ ] Add `NavigationLink` to Priority Inbox:
  ```swift
  NavigationLink("Priority Inbox") {
      PriorityInboxView()
  }
  ```
- [ ] Add navigation styling (icon, disclosure indicator)
  - Test Gate: Navigation from Profile → Priority Inbox works

---

## 10. Dark Mode & Polish (5 min)

- [ ] Test view in dark mode (Xcode preview or simulator)
- [ ] Fix any color/contrast issues
- [ ] Verify semantic colors adapt correctly
- [ ] Add haptic feedback on recategorize (optional, nice-to-have)
  - Test Gate: Dark mode looks good, no harsh colors

---

## 11. Smoke Testing (10 min)

Reference PR brief Section "Acceptance Gates & Definition of Done"

### Functional
- [ ] 3 sections display with correct badge counts
- [ ] Reasoning modal shows confidence, signals, evidence
- [ ] Tap message navigates (stub or real conversation)
- [ ] Swipe to recategorize works
- [ ] Pull-to-refresh works with 0.5s delay
- [ ] Empty state displays when no messages
- [ ] Navigation from ProfileView works

### UI/UX
- [ ] Colors match palette (#FF6B6B, #4A90E2, #95A5A6)
- [ ] Animations smooth (60fps, 300-400ms)
- [ ] UI looks calm and spacious (16-20pt padding)
- [ ] Dark mode works correctly
- [ ] Message cards show all fields correctly

### Code Quality
- [ ] ViewModel uses `@MainActor`
- [ ] No force-unwrapped optionals (`!`)
- [ ] No crashes on interaction
- [ ] Builds without errors or warnings
- [ ] Protocol-based service (ready for Firebase)

---

## 12. Git Commit & Push (5 min)

Reference PR brief Section "Git Workflow"

- [ ] Review all changes in Xcode/Git
- [ ] Stage all files: `git add .`
- [ ] Commit with message:
  ```
  feat(ai-inbox): add priority inbox view with mock data
  
  - Create PriorityInboxView with 3 collapsible sections
  - Add PriorityInboxViewModel with mock service
  - Implement reasoning modal for AI transparency
  - Add navigation link from ProfileView
  - Include 15+ mock messages with realistic categorization
  ```
- [ ] Push to origin: `git push origin feat/pr-ai-inbox-001-priority-inbox`
  - Test Gate: Branch pushed successfully

---

## 13. PR Creation (Deferred - User will create)

**Note:** Don't create PR yet - user will review first

When ready:
- **PR Title:** `[AI-INBOX-001] Priority Inbox with AI Categorization`
- **PR Target:** `develop` (NOT `main`)
- **PR Description:** Include link to PR brief and this TODO
- **Screenshots:** Add demo screenshots showing 3 sections

---

## Testing Strategy

**Tonight:** Manual smoke testing only (see Section 11)

**Tomorrow (Add in Next PR):**
- Unit tests: `MessageAITests/ViewModels/AI/PriorityInboxViewModelTests.swift` (Swift Testing)
- UI tests: `MessageAIUITests/AI/PriorityInboxUITests.swift` (XCTest)
- Coverage target: 80%+

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed (13 sections)
- [ ] Data models implemented (PriorityInboxItem, MessageCategory, etc)
- [ ] Mock service protocol + implementation
- [ ] ViewModel with @MainActor and computed properties
- [ ] PriorityInboxView with 3 collapsible sections
- [ ] Message cards with avatar, preview, timestamp, "Why?" button
- [ ] Reasoning modal for AI transparency
- [ ] Calm Intelligence design applied (colors, spacing, animations)
- [ ] Navigation from ProfileView works
- [ ] Dark mode tested and working
- [ ] All smoke tests pass (see Section 11)
- [ ] No force unwraps, no crashes, no warnings
- [ ] Protocol-based for future Firebase integration
```

---

## Notes & Tips

**Break tasks into <30 min chunks:**
- Setup + Data Models: 15 min
- Service + ViewModel: 20 min
- Main View + Cards: 25 min
- Modal + Design: 20 min
- Integration + Testing: 20 min

**Reference materials:**
- PR Brief: `MessageAI/docs/prds/pr-priority-inbox-brief.md` (copy-paste ready code)
- Shared Standards: `MessageAI/agents/shared-standards.md` (Swift patterns)
- Parent PRD: `MessageAI/docs/prds/pr-tonight-ui-demo.md` (full context)

**Why this matters:**
This is **the hero feature** - Maya goes from 200 messages → 2 urgent in seconds. The "Why?" transparency modal proves Calm Intelligence: AI explains itself humbly. Make it shine! ✨

**Document blockers immediately** - ping if stuck >15 min

---

**Status:** Ready to build  
**Next:** Mark "Setup" tasks as in-progress and begin! 🚀


# PR-AI-DECISIONS-001 TODO — Decision History Timeline

**Branch**: `feat/ai-decision-history`  
**Source PRD**: `MessageAI/docs/prds/pr-tonight-ui-demo.md` (Priority 3)  
**PR Brief**: `MessageAI/docs/prds/pr-decision-history-brief.md`  
**Owner (Agent)**: Cody iOS  
**Estimated Time**: 30-45 minutes  
**Priority**: 🟡 HIGH - Solves Digital FOMO problem

---

## 0. Clarifying Questions & Assumptions

**Questions:** None - all decisions made for demo

**Assumptions:**
- Using mock data only (no Firebase tonight)
- Protocol-based service ready for future Firebase swap
- Dark mode must work
- 5-6 hardcoded decisions sufficient for demo
- Search uses simple keyword matching (not semantic yet)
- Smoke tests only tonight (full tests in next PR)

---

## 1. Setup (5 min)

- [ ] Create branch `feat/ai-decision-history` from develop
- [ ] Read PR brief: `MessageAI/docs/prds/pr-decision-history-brief.md`
- [ ] Confirm Xcode builds without errors
- [ ] Create file structure:
  - `MessageAI/MessageAI/Views/AI/DecisionHistoryView.swift`
  - `MessageAI/MessageAI/ViewModels/AI/DecisionHistoryViewModel.swift`

---

## 2. Data Models (8 min)

Copy from PR brief Section "Data Models"

- [ ] Create `Decision` struct with Identifiable
  - Properties: id, decisionText, participants, timestamp, chatContext, chatID, sourceMessageID, confidence, detectionSignals
  - Test Gate: Model compiles without errors

- [ ] Create `Participant` struct with Identifiable
  - Properties: id, name, avatarURL
  
- [ ] Create `ConfidenceLevel` enum
  - Cases: high, moderate, uncertain
  - Add `color` computed property (Green/Orange/Gray)
  - Test Gate: Color properties render correctly

- [ ] Create `TimeFilter` enum with CaseIterable
  - Cases: lastWeek, lastMonth, allTime
  - Add `daysBack` computed property (7/30/nil)
  - Test Gate: Filter logic works

---

## 3. Mock Data & Service (10 min)

Copy from PR brief Section "Mock Data Examples" & "Mock Service Protocol"

- [ ] Create `MockData` struct with `decisions` static array
  - Add 2 decisions from last week (high confidence)
  - Add 1 decision from 1 week ago (high confidence)
  - Add 1 decision from 2 weeks ago (moderate confidence)
  - Add 1 decision from 2.5 weeks ago (high confidence)
  - Include realistic: decisionText, participants, chatContext, signals
  - Test Gate: Mock data array compiles with 5 decisions
  
- [ ] Create `DecisionHistoryService` protocol
  - `fetchDecisions(filter: TimeFilter)` → async throws [Decision]
  - `searchDecisions(query: String)` → async throws [Decision]
  
- [ ] Create `MockDecisionHistoryService` class implementing protocol
  - Add 0.4s delay in fetchDecisions() (simulate network)
  - Add 0.3s delay in searchDecisions()
  - Filter by timestamp based on TimeFilter
  - Search filters by decisionText, chatContext, participant names
  - Test Gate: Service compiles, delays work, filtering logic correct

---

## 4. ViewModel (8 min)

Copy from PR brief Section "ViewModel Structure"

- [ ] Create `DecisionHistoryViewModel` class with `@MainActor`
- [ ] Add `@Published` properties:
  - `decisions: [Decision] = []`
  - `isLoading = false`
  - `error: Error?`
  - `selectedFilter: TimeFilter = .lastWeek`
  - `searchQuery = ""`
  
- [ ] Add computed property:
  - `filteredDecisions` → filters decisions by searchQuery
  
- [ ] Implement methods:
  - `loadDecisions()` async
  - `applyFilter(_ filter: TimeFilter)` async
  
- [ ] Initialize with `service: DecisionHistoryService = MockDecisionHistoryService()`
  - Test Gate: ViewModel compiles, no force unwraps

---

## 5. Main View - Decision History (12 min)

Reference PR brief Section "UI Requirements"

- [ ] Create `DecisionHistoryView` SwiftUI view
- [ ] Add `@StateObject var viewModel = DecisionHistoryViewModel()`
- [ ] Add navigation title "Decision History"

### Filter Toolbar
- [ ] Add segmented picker for TimeFilter (Last Week / Last Month / All Time)
- [ ] Default to .lastWeek
- [ ] Style with subtle gray background
- [ ] Call `viewModel.applyFilter()` on change
  - Test Gate: Filter changes update timeline

### Search Bar
- [ ] Add search field below filters
- [ ] Placeholder: "Find budget decisions..."
- [ ] Bind to `viewModel.searchQuery`
- [ ] Add clear button (appears when typing)
- [ ] Show real-time filtered results via `viewModel.filteredDecisions`
  - Test Gate: Search filters decisions correctly

### Timeline Cards
- [ ] Create ScrollView with VStack for decisions
- [ ] For each decision, show card with:
  - Decision text (`.title3`, bold)
  - Participant avatars (HStack, overlapping, max 3 + count badge)
  - Participant names (comma-separated, `.body`)
  - Timestamp (relative: "2 days ago", `.caption`, secondary color)
  - Chat context badge ("From #product-team", gray background)
  - Confidence badge (High/Moderate, color-coded, right side)
  - "Why?" button (info icon)
  - Soft divider below card (gray, opacity 0.2)
  
- [ ] Add tap gesture to card → opens source conversation (placeholder for now)
  - Test Gate: Cards display all fields correctly

### Empty State
- [ ] Check if `viewModel.filteredDecisions.isEmpty`
- [ ] Show magnifying glass or document icon
- [ ] Primary text: "No major decisions tracked yet"
- [ ] Secondary text: "I'll log decisions as your team makes them"
- [ ] Use supportive tone (not alarming)
  - Test Gate: Empty state shows when no results

### Loading State
- [ ] Add ProgressView when `viewModel.isLoading`
- [ ] Position centered in view
  - Test Gate: Loading indicator appears during fetch

---

## 6. Transparency Modal (5 min)

Reference PR brief Section "Transparency Modal"

- [ ] Add `@State var selectedDecision: Decision?`
- [ ] Add `@State var showTransparencyModal = false`
- [ ] Create sheet modal triggered by "Why?" button
- [ ] In modal, display:
  - Header: "How I detected this decision"
  - Detection reasoning (placeholder text for now)
  - Signals as tag cloud (ForEach over detectionSignals)
  - Participants list
  - Confidence badge with explanation
  - "View conversation" button (placeholder action)
  
- [ ] Add `.sheet(isPresented: $showTransparencyModal)` modifier
  - Test Gate: Modal appears on "Why?" tap, displays signals

---

## 7. Design Polish (7 min)

Reference PR brief Section "Design Standards (Calm Intelligence)"

### Colors
- [ ] Apply Calm Intelligence color palette:
  - High confidence: `#2ECC71` opacity 0.7
  - Moderate confidence: `#FFA500` opacity 0.7
  - Uncertain confidence: `#95A5A6` opacity 0.7
  - Dividers: gray opacity 0.2
  - Context badge background: gray opacity 0.15
  
### Spacing & Layout
- [ ] Card spacing: VStack(spacing: 20)
- [ ] Padding: .horizontal(20), .vertical(16)
- [ ] Overlapping avatars: offset by -8 per avatar

### Animations
- [ ] Card appearance: `.transition(.move(edge: .bottom).combined(with: .opacity))`
- [ ] Spring animation: `response: 0.35, dampingFraction: 0.8`
- [ ] Filter change: `.animation(.easeInOut(duration: 0.2))`
  - Test Gate: Animations feel smooth and calm

### Dark Mode
- [ ] Test all colors in dark mode
- [ ] Ensure text remains readable
- [ ] Check badge contrast
  - Test Gate: UI looks good in both light and dark mode

---

## 8. Integration with ProfileView (3 min)

Copy from PR brief Section "Integration with ProfileView"

- [ ] Open `MessageAI/MessageAI/Views/Profile/ProfileView.swift`
- [ ] Add NavigationLink to Decision History:
  ```swift
  NavigationLink(destination: DecisionHistoryView()) {
      HStack {
          Image(systemName: "list.bullet.clipboard")
              .foregroundColor(.blue)
          Text("Decision History")
          Spacer()
          Image(systemName: "chevron.right")
              .foregroundColor(.gray)
      }
      .padding()
  }
  ```
- [ ] Place in appropriate section (AI Features or similar)
  - Test Gate: Navigation from Profile → Decision History works

---

## 9. Testing & Validation (5 min)

### Manual Testing Checklist
- [ ] Launch app in simulator
- [ ] Navigate: Profile → Decision History
- [ ] Verify timeline shows 5 decisions (chronological, newest first)
- [ ] Test filters: Last Week shows 3, Last Month shows 5, All Time shows 5
- [ ] Test search: "Stripe" finds payment decision
- [ ] Test search: "budget" finds budget approval
- [ ] Tap "Why?" → transparency modal appears
- [ ] Modal shows signals, participants, confidence
- [ ] Dismiss modal with swipe down
- [ ] Test empty state: search for "xyzabc" → shows empty state
- [ ] Test loading state: observe on view appear (brief flash)
- [ ] Toggle dark mode → UI adapts correctly
- [ ] Test iPad layout (if applicable)

### Edge Cases
- [ ] Empty search query → shows all decisions
- [ ] Filter with no results → shows empty state
- [ ] Very long decision text → truncates gracefully
- [ ] 10+ participants → shows max 3 + count badge

---

## 10. Definition of Done Review

Go through PR brief "Definition of Done" section:

### Core Functionality
- [ ] DecisionHistoryView builds and runs without errors
- [ ] Navigation from ProfileView works
- [ ] Timeline displays decisions chronologically (newest first)
- [ ] Decision cards show: text, participants, timestamp, context, confidence
- [ ] Participant avatars overlapping (max 3 visible + count badge)
- [ ] Time filters work (Last Week / Last Month / All Time)
- [ ] Search bar filters by keyword in real-time
- [ ] Tap card → placeholder for opening source conversation
- [ ] "Why?" button → shows transparency modal with signals
- [ ] Empty state displays when no decisions
- [ ] Dark mode compatible

### Design Quality
- [ ] Colors match Calm Intelligence palette
- [ ] Spacious layout with soft dividers
- [ ] Animations feel smooth and calm
- [ ] Confidence badges subtle (not prominent)

---

## 11. Pre-Commit Checklist

- [ ] No compiler warnings
- [ ] No force unwraps (`!`)
- [ ] No hardcoded strings (use proper labels)
- [ ] All @Published vars on @MainActor
- [ ] Async calls use proper error handling
- [ ] Dark mode tested and working
- [ ] No console errors in Xcode
- [ ] Memory leaks checked (Instruments if time permits)

---

## 12. Commit & Push

- [ ] Stage files:
  ```bash
  git add MessageAI/MessageAI/Views/AI/DecisionHistoryView.swift
  git add MessageAI/MessageAI/ViewModels/AI/DecisionHistoryViewModel.swift
  git add MessageAI/MessageAI/Views/Profile/ProfileView.swift
  git add MessageAI/MessageAI/Models/[Decision models if separate file]
  ```

- [ ] Commit with clear message:
  ```bash
  git commit -m "feat(ai): Add Decision History timeline view

  - Timeline shows AI-tracked team decisions chronologically
  - Filters: Last Week / Last Month / All Time
  - Search bar for keyword filtering
  - Transparency modal explains detection reasoning
  - Mock data with 5 sample decisions
  - Protocol-based service ready for Firebase integration
  - Calm Intelligence design with subtle confidence badges
  
  Closes PR-AI-DECISIONS-001"
  ```

- [ ] Push branch:
  ```bash
  git push origin feat/ai-decision-history
  ```

---

## 13. Create Pull Request

- [ ] Create PR on GitHub
- [ ] Title: `[AI-DECISIONS-001] Decision History Timeline View`
- [ ] Description (copy from PR brief "Why This PR Matters"):
  ```markdown
  ## What This Solves
  
  **Digital FOMO:** When Maya returns from vacation, she sees important 
  decisions at a glance (not 500 messages). The AI tracks team consensus 
  so she never misses critical context.
  
  ## Features
  - ✅ Timeline of AI-tracked decisions (newest first)
  - ✅ Time filters (Last Week / Last Month / All Time)
  - ✅ Natural language search
  - ✅ Transparency modal ("Why?") shows detection reasoning
  - ✅ Calm Intelligence design
  
  ## Demo
  [Add screenshots]
  
  ## Testing
  - Manual testing in simulator ✅
  - Dark mode tested ✅
  - Mock data with 5 sample decisions
  
  ## Next Steps
  - Firebase integration (PR-AI-DECISIONS-002)
  - Real-time decision tracking
  - Semantic search
  ```

- [ ] Assign reviewers
- [ ] Add labels: `ai-features`, `demo`, `high-priority`
- [ ] Link to PRD: `MessageAI/docs/prds/pr-decision-history-brief.md`

---

## 14. Demo Prep (Optional - If Time)

- [ ] Take screenshots:
  - Timeline with decisions
  - Filter in action (Last Week selected)
  - Search results ("budget")
  - Transparency modal open
  - Empty state
  - Dark mode version

- [ ] Create short demo script:
  1. Open app → Profile → Decision History
  2. "Here's what the team decided while I was away"
  3. Show filters → "Last Week shows recent decisions"
  4. Search "budget" → "Natural language search works"
  5. Tap "Why?" → "Transparent AI reasoning"
  6. Show empty state → "Supportive, not alarming"

- [ ] Test demo flow 2-3 times for smoothness

---

## 🎯 Success Criteria

**This PR is DONE when:**
- ✅ Decision History view accessible from Profile
- ✅ Timeline displays 5 mock decisions chronologically
- ✅ Filters work correctly (Last Week/Month/All Time)
- ✅ Search filters by keyword in real-time
- ✅ Transparency modal explains detection reasoning
- ✅ Empty state is supportive and calm
- ✅ UI matches Calm Intelligence design standards
- ✅ Dark mode works perfectly
- ✅ No crashes or console errors

---

## 📝 Notes & Learnings

_(Fill in as you work)_

**Challenges:**
- 

**Solutions:**
- 

**Time Actual:**
- Setup: ___
- Models: ___
- Service: ___
- ViewModel: ___
- View: ___
- Polish: ___
- Testing: ___
- **Total: ___**

**What Went Well:**
- 

**What to Improve:**
- 

---

**Status**: 🟡 Ready to Start  
**Next Agent**: Cody iOS  
**Questions?** Reference PR brief: `MessageAI/docs/prds/pr-decision-history-brief.md`


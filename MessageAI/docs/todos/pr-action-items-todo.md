# PR-AI-TASKS-001 TODO — Action Items View

**Branch**: `feat/pr-ai-tasks-001-action-items`  
**Source PRD**: `MessageAI/docs/prds/pr-tonight-ui-demo.md` (Priority 2)  
**PR Brief**: `MessageAI/docs/prds/pr-action-items-brief.md`  
**Owner (Agent)**: Cody iOS  
**Estimated Time**: 30-45 minutes  
**Priority**: 🟡 HIGH - Shows AI task extraction value

---

## 0. Clarifying Questions & Assumptions

**Questions:** None - all decisions made for demo

**Assumptions:**
- Using mock data only (no Firebase tonight)
- Protocol-based service ready for future Firebase swap
- Sheet modal presentation style
- Max 8 tasks total (not overwhelming)
- Dark mode must work
- Completion animation must feel satisfying (checkmark + fade)
- Smoke tests only tonight (full tests in next PR)

---

## 1. Setup (5 min)

- [ ] Create branch `feat/pr-ai-tasks-001-action-items` from develop
- [ ] Read PR brief: `MessageAI/docs/prds/pr-action-items-brief.md`
- [ ] Confirm Xcode builds without errors
- [ ] Create file structure:
  - `MessageAI/MessageAI/Views/AI/ActionItemsView.swift`
  - `MessageAI/MessageAI/ViewModels/AI/ActionItemsViewModel.swift`

---

## 2. Data Models (5 min)

Copy from PR brief Section "Data Models"

- [ ] Create `ActionItem` struct with Identifiable
  - Add `isCompleted` mutable property
- [ ] Create `ActionItemUrgency` enum with color/icon computed properties
- [ ] Create `ExtractionReasoning` struct
- [ ] Use existing `ConfidenceLevel` enum (from Priority Inbox)
- [ ] Add to appropriate Models folder
  - Test Gate: Models compile without errors

---

## 3. Mock Data & Service (10 min)

Copy from PR brief Section "Mock Data Implementation"

- [ ] Create `MockData` struct with `actionItems` static array (or add to existing)
  - Add 2 Today tasks (roadmap review, budget approval)
  - Add 3 This Week tasks (docs, 1:1, slides)
  - Add 2 Later tasks (research, offsite planning)
  - All with realistic extraction reasoning, signals, source excerpts
  - Test Gate: Mock data array compiles
  
- [ ] Create `ActionItemService` protocol
  - `fetchActionItems()` → returns [ActionItem]
  - `completeActionItem(id)` → async throws
  - `fetchActionItems(urgency)` → returns filtered [ActionItem]
  
- [ ] Create `MockActionItemService` class implementing protocol
  - Add 0.3s delay in fetchActionItems()
  - Add 0.1s delay in completeActionItem()
  - Filter out completed items in fetch
  - Test Gate: Service compiles, delays work

---

## 4. ViewModel (10 min)

Copy from PR brief Section "ViewModel Structure"

- [ ] Create `ActionItemsViewModel` class with `@MainActor`
- [ ] Add `@Published` properties:
  - `items: [ActionItem] = []`
  - `isLoading = false`
  - `error: Error?`
- [ ] Add computed properties for sections:
  - `todayItems` (filter by .today, not completed)
  - `thisWeekItems` (filter by .thisWeek, not completed)
  - `laterItems` (filter by .later, not completed)
- [ ] Implement methods:
  - `loadItems()` async
  - `completeItem(_ item: ActionItem)` async with optimistic update
    - Update UI immediately
    - Rollback on error
- [ ] Initialize with `service: ActionItemService = MockActionItemService()`
  - Test Gate: ViewModel compiles, no force unwraps

---

## 5. Sheet Modal View (15 min)

Reference PR brief Section "UI Requirements"

- [ ] Create `ActionItemsView` SwiftUI view
- [ ] Add `@StateObject var viewModel = ActionItemsViewModel()`
- [ ] Configure sheet presentation:
  - `.presentationDetent([.medium])` (60% height)
  - `.presentationDragIndicator(.visible)`
- [ ] Add header with "Action Items" title and close button
- [ ] Build 3 sections with urgency badges:
  - **Today**: Red badge (#FF6B6B), count, icon
  - **This Week**: Orange badge (#FFA500), count, icon
  - **Later**: Blue badge (#4A90E2), count, icon
- [ ] Add empty state: "All caught up! 🎉" with green checkmark
  - Show when all sections empty
  - Test Gate: SwiftUI preview shows 3 sections with badges

---

## 6. Task Cards Component (15 min)

Reference PR brief Section "UI Requirements - Task Cards"

- [ ] Create task card view inside ActionItemsView or as component
- [ ] Display for each task:
  - Checkbox (left side): ☐ unchecked, ✓ checked
  - Task text (bold, .body font)
  - Source context: "From [Person] in [Chat]" (gray, .caption)
  - Deadline badge if exists: "Due Today", "Due Friday" (urgent color)
  - Info button (trailing) for transparency reasoning
- [ ] Implement checkbox tap → complete task
  - Call `viewModel.completeItem()`
  - Animate checkmark appearance (.spring 0.3s)
  - Fade out card (.easeOut 0.3s)
- [ ] Add tap gesture on card body → navigate to source conversation
  - Use `NavigationLink` or programmatic navigation
- [ ] Add info button tap → show transparency modal
  - Test Gate: Cards display all fields, animations smooth

---

## 7. Completion Animation (5 min)

Reference PR brief Section "Design Standards - Animations"

- [ ] Implement satisfying completion animation:
  - Checkmark scale effect (0.5 → 1.0)
  - Checkmark opacity (0 → 1)
  - Spring animation (response: 0.3, damping: 0.7)
- [ ] Implement card fade out:
  - Opacity (1 → 0)
  - Scale slightly (1.0 → 1.2)
  - Ease out duration 0.3s
- [ ] Test animation feels calm and satisfying (not rushed)
  - Test Gate: Completion feels *chef's kiss* satisfying

---

## 8. Transparency Modal (10 min)

Reference PR brief Section "UI Requirements - Transparency Modal"

- [ ] Create transparency modal (reusable sheet or inline)
- [ ] Accept `ExtractionReasoning` as parameter
- [ ] Display:
  - Header: "How I found this task"
  - Explanation text
  - Signals as tag chips/list
  - Source excerpt with message preview
  - Confidence badge (High/Moderate) with color
  - "View conversation" button
- [ ] Make dismissible (swipe down or close button)
- [ ] Wire up info button tap → show modal
  - Test Gate: Modal displays correctly, shows all reasoning data

---

## 9. Design System & Colors (5 min)

Reference PR brief Section "Design Standards (Calm Intelligence)"

- [ ] Apply urgency colors:
  - Today: `Color(hex: "#FF6B6B")` (Red)
  - This Week: `Color(hex: "#FFA500")` (Orange)
  - Later: `Color(hex: "#4A90E2")` (Blue)
  - Success/Complete: `Color(hex: "#2ECC71")` (Green)
- [ ] Add spacing:
  - Between task cards: `VStack(spacing: 12)`
  - Card padding: `.padding(.horizontal, 20).padding(.vertical, 16)`
- [ ] Apply animations from PR brief
- [ ] Verify no harsh "OVERDUE" red panic text
  - Test Gate: UI feels calm, colors soft, animations smooth at 60fps

---

## 10. Integration with ConversationListView (5 min)

Reference PR brief Section "Integration with ConversationListView"

- [ ] Open `MessageAI/MessageAI/Views/ConversationListView.swift`
- [ ] Add `@State private var showActionItems = false`
- [ ] Add toolbar button:
  ```swift
  .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
          Button { showActionItems = true } {
              Image(systemName: "checklist")
          }
      }
  }
  ```
- [ ] Add sheet presentation:
  ```swift
  .sheet(isPresented: $showActionItems) {
      ActionItemsView()
  }
  ```
  - Test Gate: Toolbar button launches sheet

---

## 11. Dark Mode & Polish (5 min)

- [ ] Test view in dark mode (Xcode preview or simulator)
- [ ] Fix any color/contrast issues
- [ ] Verify semantic colors adapt correctly
- [ ] Add haptic feedback on task completion (optional, nice-to-have)
  - Use `UIImpactFeedbackGenerator(style: .light).impactOccurred()`
- [ ] Verify empty state looks celebratory (not stark)
  - Test Gate: Dark mode looks good, no harsh colors

---

## 12. Smoke Testing (10 min)

Reference PR brief Section "Acceptance Gates & Definition of Done"

### Functional
- [ ] Toolbar button in ConversationListView launches sheet
- [ ] 3 sections display with correct urgency grouping
- [ ] Task cards show all fields (text, source, deadline badge)
- [ ] Checkboxes work with smooth completion animation
- [ ] Completed tasks fade out gracefully (300ms)
- [ ] Tap task navigates (stub or real conversation)
- [ ] Info button shows transparency reasoning modal
- [ ] Empty state displays when all tasks complete
- [ ] Sheet dismisses correctly (swipe down)

### UI/UX
- [ ] Colors match urgency levels (Red, Orange, Blue)
- [ ] Completion animation feels satisfying and calm
- [ ] UI feels spacious (not cramped) - 12pt spacing
- [ ] Dark mode works correctly
- [ ] Transparency modal shows signals, source excerpt, confidence
- [ ] Max 7-8 tasks shown (not overwhelming)
- [ ] No aggressive "OVERDUE" panic text
- [ ] Empty state supportive and celebratory

### Code Quality
- [ ] ViewModel uses `@MainActor`
- [ ] No force-unwrapped optionals (`!`)
- [ ] No crashes on interaction
- [ ] Builds without errors or warnings
- [ ] Protocol-based service (ready for Firebase)
- [ ] Optimistic UI update on completion (instant feedback)

---

## 13. Git Commit & Push (5 min)

Reference PR brief Section "Git Workflow"

- [ ] Review all changes in Xcode/Git
- [ ] Stage all files: `git add .`
- [ ] Commit with message:
  ```
  feat(ai-tasks): add action items view with completion
  
  - Create ActionItemsView with 3 urgency sections
  - Add ActionItemsViewModel with mock service
  - Implement satisfying completion animation (checkmark + fade)
  - Add transparency modal for extraction reasoning
  - Add toolbar button in ConversationListView
  - Include 7-8 mock tasks with realistic extraction
  ```
- [ ] Push to origin: `git push origin feat/pr-ai-tasks-001-action-items`
  - Test Gate: Branch pushed successfully

---

## 14. PR Creation (Deferred - User will create)

**Note:** Don't create PR yet - user will review first

When ready:
- **PR Title:** `[AI-TASKS-001] Action Items Extraction View`
- **PR Target:** `develop` (NOT `main`)
- **PR Description:** Include link to PR brief and this TODO
- **Screenshots:** Add demo screenshots showing tasks + completion animation

---

## Testing Strategy

**Tonight:** Manual smoke testing only (see Section 12)

**Tomorrow (Add in Next PR):**
- Unit tests: `MessageAITests/ViewModels/AI/ActionItemsViewModelTests.swift` (Swift Testing)
- UI tests: `MessageAIUITests/AI/ActionItemsUITests.swift` (XCTest)
- Coverage target: 80%+

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed (14 sections)
- [ ] Data models implemented (ActionItem, ActionItemUrgency, etc)
- [ ] Mock service protocol + implementation with 7-8 tasks
- [ ] ViewModel with @MainActor and optimistic UI pattern
- [ ] ActionItemsView with 3 urgency sections (Today/Week/Later)
- [ ] Task cards with satisfying completion animation (checkmark + fade)
- [ ] Transparency modal for extraction reasoning
- [ ] Toolbar button in ConversationListView works
- [ ] Sheet modal presentation with .medium detent
- [ ] Calm Intelligence design applied (colors, spacing, animations)
- [ ] Dark mode tested and working
- [ ] All smoke tests pass (see Section 12)
- [ ] No force unwraps, no crashes, no warnings
- [ ] Protocol-based for future Firebase integration
```

---

## Notes & Tips

**Break tasks into <30 min chunks:**
- Setup + Data Models: 10 min
- Service + ViewModel: 20 min
- Main View + Cards: 30 min
- Animations + Modal: 15 min
- Integration + Testing: 20 min

**Reference materials:**
- PR Brief: `MessageAI/docs/prds/pr-action-items-brief.md` (copy-paste ready code)
- Shared Standards: `MessageAI/agents/shared-standards.md` (Swift patterns)
- Parent PRD: `MessageAI/docs/prds/pr-tonight-ui-demo.md` (full context)

**Why this matters:**
This is **Maya's breakthrough moment** - she returns after 4-hour focus → opens Action Items → sees 2 tasks for today (not 200 messages) → in control in 30 seconds.

**Critical UX:** The completion animation must feel **satisfying and calm**, not rushed. Make those checkmarks feel *chef's kiss* good! ✨

**Document blockers immediately** - ping if stuck >15 min

---

**Status:** Ready to build  
**Next:** Mark "Setup" tasks as in-progress and begin! 🚀


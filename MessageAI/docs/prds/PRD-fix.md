# PRD: Critical Bug Fixes and UX Improvements

**Feature**: Bug Fixes and UX Polish

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: November 2025

**Links**: [fix.md](../fix.md)

---

## 1. Summary

Address 7 critical bugs and UX issues affecting core functionality and user experience in MessageAI. This includes fixing broken profile photo uploads, contacts view loading issues, and improving Focus Mode visual design, feedback displays, group chat management, and summary export features.

---

## 2. Problem & Goals

**Problem:** Multiple user-facing bugs and suboptimal UX patterns are degrading the user experience and preventing users from completing essential tasks like uploading profile photos and viewing contacts.

**Why now:** These issues directly impact core user workflows and create friction in daily usage. Fixing them will improve retention and user satisfaction.

**Goals (ordered, measurable):**
- [ ] G1 - Eliminate all P0 blocking bugs (contacts, profile photos) within 1 week
- [ ] G2 - Improve Focus Mode UX satisfaction score from current baseline to 4.5+ stars
- [ ] G3 - Reduce user confusion around feedback and group chat management by 80%
- [ ] G4 - Simplify summary export flow, reducing steps by 50%

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep.

- [ ] Not implementing new features (why: focus is on fixing existing functionality)
- [ ] Not redesigning entire UI (why: tactical improvements only)
- [ ] Not addressing backend infrastructure issues (why: frontend-focused work)
- [ ] Not changing core messaging functionality (why: stable and working)

---

## 4. Success Metrics

**User-visible:**
- Profile photo upload success rate: 100% (currently broken)
- Contacts view first-load success rate: 100% (currently fails on initial load)
- Focus Mode activation time: <300ms
- User confusion reports: -80% reduction

**System:**
- Zero blocking bugs in production
- App launch time: <2-3s (maintained, not degraded)
- Smooth 60fps scrolling (maintained)

**Quality:**
- 0 blocking bugs in release
- All test gates pass
- Crash-free rate >99%
- No regressions in existing features

---

## 5. Users & Stories

**Primary User: Professional Mobile User**
- As a professional user, I want to update my profile photo so that my contacts can recognize me
- As a busy user, I want to see my contacts immediately when I open that tab so that I can quickly start a conversation
- As a focused user, I want Focus Mode to visually align with the app's branding so that it feels native and polished
- As a group chat participant, I want to rename my group chats so that I can organize conversations meaningfully
- As a Focus Mode user, I want simpler export options so that I don't waste time choosing formats

---

## 6. Experience Specification (UX)

### Phase 1: Critical Bug Fixes

**Subphase 1.1: Contacts View Loading**
- Entry: User taps Contacts tab in main navigation
- Expected: Contacts list appears immediately with all contacts visible and interactive
- Current bug: Contacts list appears empty; requires navigating away and back to load
- Fix behavior: Contacts load on first view appearance with loading state
- States: Loading (spinner), Loaded (contacts list), Empty (no contacts message), Error (retry button)

**Subphase 1.2: Profile Photo Upload**
- Entry: User taps profile photo in Profile view, selects "Change Photo" or "Upload Photo"
- Expected: Photo picker opens, user selects photo, photo uploads and updates immediately
- Current bug: Photo picker may not open, or selection doesn't save
- Fix behavior: Reliable photo picker, upload progress indicator, immediate preview update
- States: Idle, Selecting, Uploading (progress %), Success, Error (retry)

### Phase 2: Focus Mode UI/UX

**Subphase 2.1: Focus Mode Visual Design**
- Current: Toggle with unknown color scheme and dot indicator
- New: Button or refined toggle matching app logo colors (purple/blue gradient)
- Remove: Right-side dot indicator (redundant)
- Animation: Smooth transition between states
- Placement: Toolbar or prominent position in conversation list

**Subphase 2.2: Feedback Display**
- Current: Multi-line feedback takes up significant space
- New: Single-line compact feedback or icon-based representation
- Context: Displayed alongside messages and priority indicators
- Responsive: Adapts to available space in message cells and group chat headers

### Phase 3: Feature Improvements

**Subphase 3.1: Group Chat Management**
- Add: "Rename Group" option in group chat settings
- Remove/Hide: Member count in header (or make optional)
- Optimize: Feedback display in group context to single line
- Entry point: Long press on group name or settings menu

**Subphase 3.2: Summary Export**
- Simplify: Reduce export options (evaluate if all 3 formats needed)
- Recommendation: Default to one format (text) with optional advanced menu
- Default state: Summary details collapsed/hidden
- Entry: Appears after Focus Mode session ends

**Subphase 3.3: Multi-Device Notifications**
- Fix: Incorrect notification indicators in contacts when logged into multiple devices
- Expected: Accurate notification state reflecting actual unread status
- Edge case: Handle race conditions between devices

---

## 7. Functional Requirements (Must/Should)

### Phase 1: Critical Bugs

**MUST: Contacts View**
- MUST: Load contacts on initial view appearance (onAppear or viewDidLoad)
- MUST: Display loading state while fetching
- MUST: Enable interaction immediately after load completes
- MUST: Handle empty state gracefully
- MUST: Show error state with retry if fetch fails

**MUST: Profile Photos**
- MUST: Open photo picker reliably on all devices
- MUST: Upload photo to Firebase Storage
- MUST: Update user profile with photo URL
- MUST: Show upload progress
- MUST: Handle upload failures with retry option
- MUST: Update UI optimistically with local preview

### Phase 2: Focus Mode

**MUST: Visual Design**
- MUST: Extract app logo color (use color picker or Assets.xcassets)
- MUST: Apply matching color to Focus Mode toggle/button
- MUST: Remove dot indicator from UI
- SHOULD: A/B test toggle vs button pattern with team

**MUST: Feedback Display**
- MUST: Constrain feedback to single line in message cells
- MUST: Truncate or abbreviate long feedback text
- SHOULD: Use icon representation for common feedback types
- SHOULD: Show full feedback in detail view or tooltip

### Phase 3: Features

**SHOULD: Group Chat**
- SHOULD: Add rename functionality in group settings
- SHOULD: Make member count optional/hideable
- SHOULD: Apply single-line feedback constraint

**SHOULD: Summary Export**
- SHOULD: Simplify to 1-2 export formats
- SHOULD: Hide advanced export options behind menu
- SHOULD: Collapse summary details by default
- SHOULD: Add expand/collapse toggle

**MUST: Notifications**
- MUST: Correctly sync notification state across devices
- MUST: Handle multi-device login scenarios
- MUST: Debounce rapid state changes

---

## 8. Data Model

### Profile Photo Updates

```swift
// User model already exists, ensure photoURL is properly handled
struct User {
    var id: String
    var displayName: String
    var email: String
    var photoURL: String?  // Ensure this is properly saved/loaded
    // ... existing fields
}
```

### Focus Mode Preferences

```swift
// Extend existing FocusMode model
struct FocusMode {
    var isActive: Bool
    var colorScheme: FocusModeColorScheme  // NEW
    var displayMode: DisplayMode  // NEW: .toggle or .button
    // ... existing fields
}

enum FocusModeColorScheme {
    case appLogo  // Matches app brand colors
    case system   // System default
    case custom(Color)
}

enum DisplayMode {
    case toggle
    case button
}
```

### Group Chat Updates

```swift
// Extend existing Chat model
struct Chat {
    var id: String
    var name: String?
    var isGroup: Bool
    var showMemberCount: Bool = true  // NEW: optional display
    var customName: String?  // NEW: user-renamed group
    // ... existing fields
}
```

**Firestore Updates:**
- `users/{userID}`: Add/update `photoURL` field
- `users/{userID}/preferences/focusMode`: Add `colorScheme`, `displayMode` fields
- `chats/{chatID}`: Add `showMemberCount`, `customName` fields

---

## 9. API / Service Contracts

### PhotoService Updates

```swift
// Update existing PhotoService
class PhotoService {
    // MUST: Ensure these methods work reliably
    func selectPhoto() async throws -> UIImage
    func uploadPhoto(_ image: UIImage, for userID: String) async throws -> String  // Returns URL
    func updateUserPhoto(userID: String, photoURL: String) async throws
    func deletePhoto(for userID: String) async throws
}
```

**Pre-conditions:**
- User is authenticated
- Photo is valid image format
- User has storage permissions

**Post-conditions:**
- Photo uploaded to Firebase Storage
- User profile updated in Firestore
- UI reflects new photo

**Error handling:**
- NetworkError: Show retry with cached image
- PermissionError: Prompt for photo library access
- StorageError: Show error alert with details

### ContactListViewModel Updates

```swift
// Update existing ContactListViewModel
class ContactListViewModel: ObservableObject {
    @Published var contacts: [User] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // MUST: Fix to work on first load
    func loadContacts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            contacts = try await userService.fetchContacts()
        } catch {
            self.error = error
        }
    }
    
    // MUST: Call this in onAppear
    func refresh() async {
        await loadContacts()
    }
}
```

### FocusModeService Updates

```swift
// Update existing FocusModeService
class FocusModeService {
    // NEW: Color customization
    func updateColorScheme(_ scheme: FocusModeColorScheme) async throws
    
    // NEW: Display mode
    func updateDisplayMode(_ mode: DisplayMode) async throws
    
    // Existing methods remain
    func toggleFocusMode()
    func activateFocusMode()
    func deactivateFocusMode()
}
```

---

## 10. UI Components to Create/Modify

### Phase 1 Components

**Modify:**
- `Views/Main/ContactListView.swift` - Fix onAppear, add loading states
- `ViewModels/ContactListViewModel.swift` - Fix initial load logic
- `Views/Profile/ProfileView.swift` - Fix photo picker integration
- `ViewModels/ProfileViewModel.swift` - Fix photo upload flow
- `Services/PhotoService.swift` - Ensure reliability

### Phase 2 Components

**Modify:**
- `Views/Components/FocusModeBanner.swift` - Update colors, remove dot
- `Utilities/Theme/Colors.swift` - Add app logo color constants
- `Services/FocusModeService.swift` - Add color/mode preferences
- `Views/Components/FeedbackButton.swift` - Create compact single-line version
- `Views/Components/MessageCell.swift` - Integrate compact feedback

**Create (if needed):**
- `Views/Components/CompactFeedbackView.swift` - Icon-based feedback display

### Phase 3 Components

**Modify:**
- `Views/Main/ChatView.swift` - Add group rename option
- `Views/Components/GroupChatHeaderView.swift` - Hide member count option
- `Views/Components/FocusSummaryView.swift` - Simplify export, collapse details
- `ViewModels/FocusSummaryViewModel.swift` - Update export logic
- `Services/NotificationService.swift` - Fix multi-device sync

**Create (if needed):**
- `Views/Components/GroupRenameSheet.swift` - Group rename modal

---

## 11. Integration Points

**Firebase Storage:**
- Photo uploads for profile pictures
- URL generation and retrieval

**Firestore:**
- User profile updates (photoURL)
- Contact list queries
- Group chat metadata (name, settings)
- Focus Mode preferences
- Notification state sync

**SwiftUI State Management:**
- @Published properties for reactive UI
- Async/await for service calls
- Error handling with alerts/banners

**UIKit Integration:**
- PHPickerViewController for photo selection
- Permission handling for photo library

---

## 12. Test Plan & Acceptance Gates

### Phase 1: Critical Bugs

**Contacts View:**
- [ ] Gate: Open Contacts tab for first time → Contacts appear within 2s
- [ ] Gate: Contacts are immediately tappable (no interaction delay)
- [ ] Gate: Loading spinner shows while fetching
- [ ] Gate: Empty state shows when user has no contacts
- [ ] Gate: Error state shows with retry button on network failure
- [ ] Gate: Retry successfully loads contacts after error

**Profile Photos:**
- [ ] Gate: Tap profile photo → Photo picker opens within 500ms
- [ ] Gate: Select photo → Upload begins with progress indicator
- [ ] Gate: Upload completes → Profile photo updates immediately
- [ ] Gate: Photo persists after app restart
- [ ] Gate: Upload failure → Error message with retry option
- [ ] Gate: Large photos (>10MB) are compressed before upload
- [ ] Gate: Works on iPhone and iPad

### Phase 2: Focus Mode UX

**Visual Design:**
- [ ] Gate: Focus Mode control uses app logo color
- [ ] Gate: Dot indicator is removed from UI
- [ ] Gate: Toggle/button state is visually clear (on/off)
- [ ] Gate: Animation is smooth (<300ms)
- [ ] Gate: Color matches app logo in light and dark mode

**Feedback Display:**
- [ ] Gate: Feedback fits in single line in message cells
- [ ] Gate: Long feedback text truncates gracefully with "..."
- [ ] Gate: Tap truncated feedback → Shows full text in popover/alert
- [ ] Gate: Icon-based feedback is recognizable
- [ ] Gate: Works in both priority and normal message contexts

### Phase 3: Features

**Group Chat:**
- [ ] Gate: Long press group name → "Rename" option appears
- [ ] Gate: Tap Rename → Text field appears with current name
- [ ] Gate: Enter new name → Saves to Firestore
- [ ] Gate: All group members see updated name
- [ ] Gate: Member count can be hidden via settings
- [ ] Gate: Feedback displays correctly in group chat context

**Summary Export:**
- [ ] Gate: Summary details are collapsed by default
- [ ] Gate: Tap to expand → Details slide into view
- [ ] Gate: Export options are simplified (1 default, others in menu)
- [ ] Gate: Export generates file successfully
- [ ] Gate: Share sheet opens with exported file

**Notifications:**
- [ ] Gate: Log into device A → No false notifications
- [ ] Gate: Log into device B → Notifications sync correctly
- [ ] Gate: Send message from device A → Device B shows correct state
- [ ] Gate: Contact view shows accurate unread counts
- [ ] Gate: No duplicate notifications

---

## 13. Definition of Done

Per phase:
- [ ] All acceptance gates pass for that phase
- [ ] Unit tests written and passing for modified services
- [ ] UI tests written for critical user flows
- [ ] Manual testing on iPhone (iOS 17+)
- [ ] No new linter errors or warnings
- [ ] Code reviewed by team member
- [ ] Documentation updated (inline comments, README if needed)
- [ ] No performance regressions (measured with Instruments)
- [ ] Tested in both light and dark mode
- [ ] Tested with VoiceOver (accessibility)

Overall:
- [ ] All 3 phases complete
- [ ] Integration testing across all phases
- [ ] Beta testing with 10+ users
- [ ] No P0 or P1 bugs remaining
- [ ] Release notes prepared

---

## 14. Risks & Mitigations

**Risk: Photo upload regression in production**
- Impact: High - Users can't update profiles
- Likelihood: Medium
- Mitigation: Extensive testing on multiple devices, fallback to cached photo, detailed error logging

**Risk: Contacts view fix introduces performance issues**
- Impact: Medium - App feels slow
- Likelihood: Low
- Mitigation: Profile loading, test with 1000+ contacts, implement pagination if needed

**Risk: Color changes clash with existing UI**
- Impact: Low - Visual inconsistency
- Likelihood: Low
- Mitigation: Design review before implementation, A/B test with team, make configurable

**Risk: Group rename causes data sync issues**
- Impact: High - Data inconsistency across users
- Likelihood: Medium
- Mitigation: Use Firestore transactions, test with multiple devices, implement conflict resolution

**Risk: Breaking existing Focus Mode functionality**
- Impact: High - Feature regression
- Likelihood: Low
- Mitigation: Comprehensive regression testing, feature flags for rollback, monitor error rates

---

## 15. Rollout & Telemetry

**Feature Flags:**
- `focus_mode_new_design` - Phase 2.1 changes
- `compact_feedback_display` - Phase 2.2 changes
- `group_rename_enabled` - Phase 3.1 changes

**Metrics to Track:**
- Profile photo upload success rate (target: 100%)
- Contacts view load time (target: <2s P95)
- Focus Mode activation rate (should not decrease)
- Group rename usage rate
- Summary export usage by format
- Multi-device notification accuracy

**Manual Validation:**
- Daily smoke tests on staging
- Weekly production spot checks
- User feedback monitoring via in-app feedback

**Rollout Plan:**
- Week 1: Phase 1 to staging, team testing
- Week 2: Phase 1 to production, monitor metrics
- Week 3: Phase 2 to staging, team testing
- Week 4: Phase 2 to production, monitor metrics
- Week 5: Phase 3 to staging, team testing
- Week 6: Phase 3 to production, full rollout

---

## 16. Open Questions

- Q1: Should Focus Mode toggle be replaced with button completely, or make it configurable?
  - Decision needed: UX research or A/B test
  - Owner: Claudia Alban
  - Timeline: Before Phase 2 implementation

- Q2: Which export format should be the default for summaries?
  - Options: Plain text (simplest), PDF (most formatted), Markdown (developer-friendly)
  - Decision: Plain text with "More formats..." option
  - Owner: Claudia Alban

- Q3: Should member count be completely removed or just hidden by default?
  - Decision: Hide by default, show in settings/detail view
  - Owner: Claudia Alban

- Q4: What causes the contacts view loading issue - data fetch, view lifecycle, or caching?
  - Needs: Code investigation
  - Owner: Pete (AI Agent)
  - Timeline: Before Phase 1 implementation

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Bulk photo upload for multiple users
- [ ] Video profile support
- [ ] Advanced Focus Mode scheduling
- [ ] Custom feedback icons/emoji
- [ ] Group chat video/voice settings
- [ ] Export to third-party services (Notion, Evernote)
- [ ] Multi-language support for summaries
- [ ] Dark mode color customization for Focus Mode

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User can upload profile photo successfully

2. **Primary user and critical action?**
   - Professional mobile user updating profile and managing conversations

3. **Must-have vs nice-to-have?**
   - Must: Phase 1 (both bugs)
   - Must: Phase 2.1 (Focus Mode colors)
   - Nice: Phase 2.2, all of Phase 3

4. **Real-time requirements?**
   - Profile photo: <5s upload
   - Contacts load: <2s
   - Focus Mode toggle: <300ms
   - Group rename sync: <1s across devices

5. **Performance constraints?**
   - No impact to app launch time
   - Maintain 60fps scrolling
   - Photo compression for large images

6. **Error/edge cases to handle?**
   - Network failures during upload
   - Empty contacts list
   - Concurrent group renames from multiple users
   - Large group chats (100+ members)
   - Multiple devices logged in simultaneously

7. **Data model changes?**
   - Minor additions to existing models (see Section 8)
   - No breaking changes

8. **Service APIs required?**
   - Updates to existing services (PhotoService, ContactListViewModel, etc.)
   - No new backend APIs needed

9. **UI entry points and states?**
   - Profile view (photo upload)
   - Contacts tab (loading fix)
   - Conversation list (Focus Mode)
   - Group chat header (rename, settings)
   - Summary modal (export options)

10. **Security/permissions implications?**
    - Photo library access permission
    - Firebase Storage rules for photo uploads
    - Firestore rules for group chat name updates

11. **Dependencies or blocking integrations?**
    - None - all work is in existing codebase

12. **Rollout strategy and metrics?**
    - Phased rollout over 6 weeks
    - Success metrics defined in Section 4

13. **What is explicitly out of scope?**
    - See Section 3 and Section 17

---

## Authoring Notes

- This PRD covers bug fixes and polish, not new features
- Phases are ordered by severity: P0 bugs first, then UX improvements
- Each subphase can be implemented and tested independently
- Focus on not breaking existing functionality while fixing issues
- Extensive testing required due to core functionality changes
- Monitor user feedback closely during rollout

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-06 | 1.0 | Initial PRD creation from fix.md | Claudia Alban |

---

**Next Steps:**
1. Review and approve this PRD
2. Create feature branch: `fix/critical-bugs-ux-improvements`
3. Start Phase 1.1: Investigate contacts view loading issue
4. Start Phase 1.2: Investigate profile photo upload issue
5. Implement fixes with test coverage
6. Proceed through phases sequentially


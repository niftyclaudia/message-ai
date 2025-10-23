# PRD: Core SwiftUI App Structure & Navigation

**Feature**: App Architecture & Navigation Framework

**Version**: 1.0

**Status**: COMPLETED

**Agent**: Pete

**Target Release**: Phase 1 - Foundation

**Links**: [PR Brief #2](../pr-brief/pr-briefs.md#pr-2-core-swiftui-app-structure--navigation)

---

## 1. Summary

Establish SwiftUI app architecture with navigation framework, state management patterns, basic theming, and authentication flow routing. This PR creates the UI foundation by implementing root navigation, authentication state handling, and reusable UI components. Builds on PR #1's AuthService to route users between authentication and main app screens.

---

## 2. Problem & Goals

**Problem**: Need structured SwiftUI architecture with proper navigation patterns and state management before building feature screens. Without this foundation, future PRs would create inconsistent navigation and state management patterns.

**Why Now**: PR #2 because it depends on PR #1's AuthService and is required by all feature PRs (PR #3+).

**Goals**:
- [ ] G1 — Root app structure with authentication flow routing
- [ ] G2 — Navigation framework supporting deep linking and modal flows
- [ ] G3 — State management patterns for authentication and app-wide state
- [ ] G4 — Reusable UI components and theming system
- [ ] G5 — Foundation ready for feature screens (PR #3+)

---

## 3. Non-Goals / Out of Scope

- [ ] Feature screens (Chat List, Conversation View - PR #4+)
- [ ] Profile management UI (PR #3)
- [ ] Real-time messaging logic (PR #6+)
- [ ] Push notifications (PR #13+)
- [ ] Advanced animations and transitions (future polish)
- [ ] Dark mode (future enhancement)
- [ ] Accessibility features (future enhancement)
- [ ] iPad-specific layouts (future)

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:

**User-visible**:
- App launch to visible UI: < 2-3 seconds
- Navigation transitions: < 300ms
- Authentication state changes: Instant UI response

**System** (see `shared-standards.md`):
- View rendering: < 16ms (60fps)
- State updates propagate instantly
- No memory leaks from navigation
- Authentication flow completes in < 5s total

**Quality**:
- 0 blocking bugs in navigation
- All acceptance gates pass
- UI tests cover all flows
- Code follows SwiftUI best practices

---

## 5. Users & Stories

- As a new user, I want to see login/signup screens so I can create an account
- As a returning user, I want to skip authentication if already logged in
- As a logged-in user, I want consistent navigation throughout the app
- As a user, I want smooth transitions between screens
- As a developer (PR #3+), I want clear navigation patterns to follow
- As a developer, I want reusable UI components for consistent design

---

## 6. Experience Specification (UX)

### Entry Points and Flows

**App Launch**:
1. User opens app
2. Loading screen (< 500ms)
3. Authentication check:
   - **Authenticated**: Navigate to MainTabView (placeholder home)
   - **Not Authenticated**: Show LoginView

**Authentication Flow**:
1. LoginView → SignUpView (via navigation link)
2. SignUpView → LoginView (back button)
3. Successful auth → MainTabView (animated transition)
4. Logout → LoginView (animated transition)

**Main Navigation Structure**:
- Tab-based navigation (prepared for future tabs)
- Modal sheets for secondary flows
- NavigationStack for hierarchical flows

### Visual Behavior

**Theme System**:
- Color palette: Primary, secondary, accent, background, text colors
- Typography: Title, headline, body, caption styles
- Spacing: Consistent padding and margins (8pt grid)
- Corner radius: Consistent rounding (8pt, 12pt, 16pt)

**Components**:
- Custom buttons (primary, secondary, text)
- Custom text fields (with validation states)
- Loading indicators
- Empty state views
- Error alert system

**States**:
- Loading: Activity indicator centered
- Error: Alert with retry option
- Empty: Placeholder text with icon
- Success: Smooth transition to next screen

### Performance Targets

See `MessageAI/agents/shared-standards.md`:
- App load: < 2-3s to interactive UI
- View rendering: 60fps smooth
- Navigation transitions: < 300ms
- No blocking operations on main thread

---

## 7. Functional Requirements (Must/Should)

### MUST

- [ ] **App Entry Point**: MessageAIApp.swift configures Firebase and observes auth state
- [ ] **Root Router**: Switches between auth flow and main app based on AuthService.isAuthenticated
- [ ] **Authentication Views**: LoginView and SignUpView with form validation
- [ ] **Main Container**: MainTabView placeholder for future feature tabs
- [ ] **Navigation Patterns**: NavigationStack for hierarchical, sheets for modal
- [ ] **State Management**: Use @StateObject, @EnvironmentObject, @Published correctly
- [ ] **Error Handling**: Display AuthErrors from PR #1 with user-friendly alerts
- [ ] **Loading States**: Show activity indicators during async operations
- [ ] **Theme System**: Centralized colors, fonts, spacing
- [ ] **Reusable Components**: Custom buttons, text fields, loading views

### SHOULD

- [ ] **Form Validation**: Client-side validation before service calls
- [ ] **Keyboard Management**: Dismiss on tap, proper ScrollView behavior
- [ ] **Haptic Feedback**: On button taps and errors
- [ ] **Transition Animations**: Smooth, native-feeling

### Acceptance Gates

- [Gate] App launch → Authenticated user sees MainTabView in < 3s
- [Gate] App launch → Unauthenticated user sees LoginView in < 2s
- [Gate] LoginView → Valid credentials → MainTabView transition < 5s total
- [Gate] LoginView → Invalid email → Shows error alert without nav change
- [Gate] SignUpView → Valid data → MainTabView transition < 7s total
- [Gate] MainTabView → Logout → LoginView transition instant
- [Gate] Keyboard shown → Tap background → Keyboard dismisses
- [Gate] Navigation back button → Returns to previous screen correctly
- [Gate] AuthService.isAuthenticated changes → UI updates instantly
- [Gate] All text fields → Proper validation before submission

---

## 8. Data Model

**No new Firestore collections** - uses existing `User` model from PR #1.

### Local State Models

```swift
// App-level authentication state (observed from AuthService)
@EnvironmentObject var authService: AuthService

// View-level form state
struct LoginFormState {
    var email: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
}

struct SignUpFormState {
    var displayName: String = ""
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
}
```

### Theme Configuration

```swift
struct AppTheme {
    // Colors
    static let primaryColor = Color.blue
    static let secondaryColor = Color.gray
    static let accentColor = Color.green
    static let backgroundColor = Color(.systemBackground)
    static let errorColor = Color.red
    
    // Typography
    static let titleFont = Font.largeTitle.weight(.bold)
    static let headlineFont = Font.headline
    static let bodyFont = Font.body
    
    // Spacing
    static let smallSpacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 16
    static let largeSpacing: CGFloat = 24
    
    // Corner Radius
    static let smallRadius: CGFloat = 8
    static let mediumRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
}
```

---

## 9. API / Service Contracts

**Uses existing services from PR #1**:

```swift
// From AuthService (PR #1)
authService.signIn(email: String, password: String) async throws
authService.signUp(email: String, password: String, displayName: String) async throws -> String
authService.signOut() throws
authService.isAuthenticated: Bool  // @Published
authService.currentUser: User?  // @Published
```

**New helper methods** (optional, in Views):

```swift
// Client-side validation
func isValidEmail(_ email: String) -> Bool
func isValidPassword(_ password: String) -> Bool
func isValidDisplayName(_ name: String) -> Bool

// Error presentation
func presentError(_ error: Error)
```

**No new service layer** - this PR focuses on UI architecture using PR #1's services.

---

## 10. UI Components to Create/Modify

### Create New Files

**Views/Authentication/**:
- `Views/Authentication/LoginView.swift` — Email/password login form with validation
- `Views/Authentication/SignUpView.swift` — Registration form with validation

**Views/Main/**:
- `Views/Main/MainTabView.swift` — Tab-based container (placeholder tabs for now)
- `Views/Main/RootView.swift` — Root navigation router based on auth state

**Views/Components/**:
- `Views/Components/PrimaryButton.swift` — Styled button for primary actions
- `Views/Components/SecondaryButton.swift` — Styled button for secondary actions
- `Views/Components/CustomTextField.swift` — Styled text field with validation states
- `Views/Components/LoadingView.swift` — Full-screen or inline loading indicator
- `Views/Components/EmptyStateView.swift` — Placeholder for empty data states

**Utilities/**:
- `Utilities/Theme/AppTheme.swift` — Centralized theme configuration
- `Utilities/Extensions/View+Extensions.swift` — SwiftUI view modifiers
- `Utilities/Extensions/Color+Extensions.swift` — Custom color extensions
- `Utilities/Validation.swift` — Form validation helpers

**ViewModels/**:
- `ViewModels/AuthViewModel.swift` — Handles authentication flow logic and state

### Modify Existing Files

**App/**:
- `MessageAI/MessageAIApp.swift` — Add AuthService as @StateObject, inject as EnvironmentObject
- `MessageAI/ContentView.swift` — Replace with RootView routing logic

---

## 11. Integration Points

**From PR #1**:
- AuthService: signIn, signUp, signOut methods
- AuthError: Display in UI alerts
- UserService: Access after authentication
- FirebaseService: Already configured in app init

**SwiftUI State Management**:
- @StateObject: AuthService at app root
- @EnvironmentObject: Inject AuthService to child views
- @State: Local view state (form fields, loading flags)
- @Published: Observe auth state changes

**Navigation**:
- NavigationStack: For hierarchical flows
- Sheet: For modal presentations
- TabView: For main app tabs

---

## 12. Test Plan & Acceptance Gates

Reference `MessageAI/agents/shared-standards.md` for testing patterns.

### UI Tests (XCUITest)

**Authentication Flow** (`MessageAIUITests/AuthenticationFlowUITests.swift`):
- [ ] testAppLaunch_Unauthenticated_ShowsLoginView
  - Gate: LoginView appears in < 2s
- [ ] testLoginView_ValidCredentials_NavigatesToMainView
  - Gate: Successful login shows MainTabView in < 5s
- [ ] testLoginView_InvalidEmail_ShowsError
  - Gate: Error alert appears, stays on LoginView
- [ ] testLoginView_NavigateToSignUp_ShowsSignUpView
  - Gate: Navigation to SignUpView works
- [ ] testSignUpView_ValidData_CreatesAccountAndNavigates
  - Gate: Account creation + navigation in < 7s
- [ ] testSignUpView_InvalidData_ShowsError
  - Gate: Validation errors displayed correctly
- [ ] testSignUpView_BackButton_ReturnsToLogin
  - Gate: Navigation back works

**Main Navigation** (`MessageAIUITests/NavigationUITests.swift`):
- [ ] testMainTabView_LogoutButton_ReturnsToLogin
  - Gate: Logout shows LoginView instantly
- [ ] testKeyboardDismissal_TapOutside_HidesKeyboard
  - Gate: Keyboard dismisses on background tap

### Unit Tests (XCTest)

**View Models** (`MessageAITests/ViewModels/AuthViewModelTests.swift`):
- [ ] testAuthViewModel_ValidLogin_Success
  - Gate: Calls AuthService.signIn correctly
- [ ] testAuthViewModel_InvalidEmail_ThrowsError
  - Gate: Validation catches before service call
- [ ] testAuthViewModel_ValidSignUp_Success
  - Gate: Calls AuthService.signUp correctly

**Validation** (`MessageAITests/Utilities/ValidationTests.swift`):
- [ ] testEmailValidation_ValidEmails_ReturnsTrue
- [ ] testEmailValidation_InvalidEmails_ReturnsFalse
- [ ] testPasswordValidation_ValidPasswords_ReturnsTrue
- [ ] testPasswordValidation_WeakPasswords_ReturnsFalse
- [ ] testDisplayNameValidation_ValidNames_ReturnsTrue
- [ ] testDisplayNameValidation_InvalidNames_ReturnsFalse

### Integration Tests

**Authentication State** (`MessageAITests/Integration/AuthStateIntegrationTests.swift`):
- [ ] testAuthStateChange_Login_UpdatesUI
  - Gate: isAuthenticated = true triggers RootView switch
- [ ] testAuthStateChange_Logout_UpdatesUI
  - Gate: isAuthenticated = false shows LoginView

### Performance Tests

**App Launch** (`MessageAITests/Performance/AppLaunchPerformanceTests.swift`):
- [ ] testAppLaunch_ColdStart_Under3s
  - Gate: App launch to interactive UI < 3s
- [ ] testViewRendering_AllViews_60fps
  - Gate: All views render smoothly

---

## 13. Definition of Done

See `shared-standards.md` for code quality standards.

### Code Complete

- [ ] All views implemented (Login, SignUp, MainTabView, RootView)
- [ ] All reusable components created
- [ ] Theme system implemented
- [ ] View models created
- [ ] Validation helpers implemented
- [ ] View extensions created

### Testing

- [ ] All UI tests pass (XCUITest)
- [ ] All unit tests pass (XCTest)
- [ ] Integration tests pass
- [ ] Performance tests pass
- [ ] Manual testing complete

### Integration

- [ ] AuthService properly injected via EnvironmentObject
- [ ] Navigation flows work correctly
- [ ] Authentication state changes update UI instantly
- [ ] Error handling displays properly

### Quality

- [ ] No compiler warnings
- [ ] Code follows SwiftUI best practices from `shared-standards.md`
- [ ] All views use theme system consistently
- [ ] No hardcoded colors, fonts, or spacing
- [ ] Proper use of @State, @StateObject, @EnvironmentObject
- [ ] Views broken into small, reusable components
- [ ] No business logic in views (delegated to services/view models)

### Documentation

- [ ] Code comments for complex logic
- [ ] README updated with navigation patterns
- [ ] Architecture documentation updated

### Ready for PR #3+

- [ ] Navigation patterns documented for future PRs
- [ ] Theme system ready for feature screens
- [ ] Component library available
- [ ] Authentication flow complete and tested
- [ ] All acceptance gates verified

---

## 14. Risks & Mitigations

- **Risk**: Navigation state management complexity → **Mitigation**: Use simple NavigationStack, avoid over-engineering
- **Risk**: Authentication state sync issues → **Mitigation**: Single source of truth (AuthService @Published)
- **Risk**: Memory leaks from navigation → **Mitigation**: Test with Instruments, proper lifecycle management
- **Risk**: Inconsistent theming in future PRs → **Mitigation**: Centralized theme, clear documentation
- **Risk**: Form validation edge cases → **Mitigation**: Comprehensive validation tests
- **Risk**: Keyboard management issues → **Mitigation**: Use proper SwiftUI keyboard modifiers

---

## 15. Rollout & Telemetry

**Feature Flag**: No (core infrastructure)

**Metrics**:
- App launch time (target < 3s)
- Navigation transition times (target < 300ms)
- Authentication flow completion rate
- Error rates by type
- View rendering performance

**Manual Validation Steps**:
1. Launch app unauthenticated → See LoginView
2. Enter invalid email → See error alert
3. Navigate to SignUpView → Form appears
4. Create account → Transition to MainTabView
5. Logout → Return to LoginView
6. Launch app authenticated → Skip to MainTabView

---

## 16. Open Questions

- Q1: Tab structure for MainTabView? → A: Start with single placeholder tab, PR #4 will add Chat List
- Q2: Handle password reset in this PR? → A: No, future enhancement
- Q3: Loading screen or splash screen? → A: Simple loading indicator, no custom splash
- Q4: Error recovery patterns? → A: Alert with retry button, clear error messages

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:
- [ ] Dark mode support → Future enhancement
- [ ] Accessibility features (VoiceOver, Dynamic Type) → Future
- [ ] iPad-specific layouts → Future
- [ ] Advanced animations → Polish phase
- [ ] Password reset flow → Future
- [ ] Social login UI → After PR #1 adds social auth
- [ ] Biometric auth UI → Future
- [ ] Profile editing UI → PR #3
- [ ] Settings screen → Future

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome?** User can launch app, see appropriate screen based on auth state, and complete authentication flow
2. **Primary user?** New users (need signup), returning users (need login), developers (need patterns)
3. **Must vs should?** Must: Auth flow, navigation framework, theme system; Should: Advanced animations, haptics
4. **Real-time requirements?** Auth state changes must update UI instantly (see `shared-standards.md`)
5. **Performance constraints?** App launch < 3s, navigation < 300ms, 60fps rendering (see `shared-standards.md`)
6. **Error/edge cases?** Invalid input, network errors, authentication failures, keyboard management
7. **Data model changes?** No new Firestore data, only local view state
8. **Service APIs required?** Uses existing AuthService from PR #1
9. **UI entry points and states?** App launch → RootView → LoginView/MainTabView based on auth state
10. **Security/permissions?** Uses existing Firebase Auth security from PR #1
11. **Dependencies?** PR #1 (AuthService, User model, Firebase config)
12. **Rollout strategy?** Full rollout, no flag, track launch time and navigation metrics
13. **Out of scope?** Feature screens, profile management, messaging, dark mode, accessibility

---

## Authoring Notes

- UI foundation only - no feature screens yet
- Authentication flow routing is the primary outcome
- Navigation patterns set precedent for future PRs
- Theme system ensures consistency
- Clean separation: Views → ViewModels → Services (PR #1)
- References `shared-standards.md` throughout
- Ready for PR #3 (Profile Management) and PR #4 (Chat List)


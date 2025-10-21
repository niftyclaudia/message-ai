# PRD: Firebase Project Setup & Authentication Foundation

**Feature**: Firebase Backend & Auth Services

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: Phase 1 - Foundation

**Links**: [PR Brief #1](../pr-brief/pr-briefs.md#pr-1-firebase-project-setup--authentication-foundation)

---

## 1. Summary

Establish Firebase backend infrastructure and authentication service layer. This PR configures Firebase project, implements AuthService and UserService for sign-up/sign-in operations, creates Firestore user collection with security rules, and enables offline persistence. No UI - pure backend foundation for PR #2.

---

## 2. Problem & Goals

**Problem**: Need secure backend infrastructure and authentication services before building any UI or features.

**Why Now**: PR #1 because all subsequent PRs depend on authenticated users and Firebase configuration.

**Goals**:
- [ ] G1 — Firebase configured with Authentication + Firestore enabled
- [ ] G2 — AuthService with sign-up, sign-in, sign-out operations
- [ ] G3 — Firestore users collection with security rules
- [ ] G4 — Services tested and ready for UI consumption (PR #2)

---

## 3. Non-Goals / Out of Scope

- [ ] UI views (LoginView, SignUpView - deferred to PR #2)
- [ ] UI tests and navigation (PR #2)
- [ ] Social login (Apple/Google - future)
- [ ] Password reset flows (future)
- [ ] Profile editing (PR #3)
- [ ] User search/discovery (PR #3)

---

## 4. Success Metrics

**System** (see `shared-standards.md`):
- Firebase init < 500ms
- signUp() < 5s, signIn() < 3s
- Auth state changes < 100ms
- Service test coverage > 80%

**Quality**:
- 0 blocking bugs in services
- All acceptance gates pass
- Services importable by PR #2

---

## 5. Users & Stories

- As a UI developer (PR #2), I want AuthService so I can build login/signup views
- As a feature developer (PR #3+), I want authenticated users so I can secure data
- As a developer, I want UserService so I can fetch/update user profiles

---

## 6. Experience Specification (UX)

**N/A** - This PR is backend services only. No UX flows.

Services provide state via `@Published` properties for PR #2 UI consumption.

---

## 7. Functional Requirements (Must/Should)

**MUST**:
- [ ] Firebase project configured (Auth + Firestore)
- [ ] AuthService: signUp, signIn, signOut, observeAuthState
- [ ] UserService: createUser, fetchUser, updateUser
- [ ] Email/password validation before Firebase calls
- [ ] Custom error types with user-friendly descriptions
- [ ] Firestore security rules (users can read all, write own)
- [ ] Offline persistence enabled
- [ ] Atomic user creation (Auth + Firestore document together)

**SHOULD**:
- [ ] Log auth events for debugging
- [ ] Handle duplicate creation attempts gracefully

**Acceptance Gates**:
- [Gate] signUp(valid data) → Firebase Auth user + Firestore doc created in < 5s
- [Gate] signIn(valid creds) → currentUser populated, isAuthenticated = true in < 3s
- [Gate] signUp(existing email) → Throws emailAlreadyInUse, no partial writes
- [Gate] signOut() → currentUser = nil, isAuthenticated = false
- [Gate] Invalid email → Throws invalidEmail BEFORE Firebase call
- [Gate] Security rules → User can write users/{own-uid} only, read all
- [Gate] Network error → Throws networkError with clear message

---

## 8. Data Model

**Collection**: `users`

**Document ID**: `{userID}` (Firebase Auth UID)

```swift
struct User: Codable, Identifiable {
    let id: String              // Firebase Auth UID
    var displayName: String     // 1-50 chars, required
    var email: String           // Valid format, required, immutable
    var profilePhotoURL: String?  // Optional
    var createdAt: Date         // Server timestamp, immutable
    var lastActiveAt: Date      // Server timestamp
}
```

**Validation Rules**:
- `id`: Must match Auth UID, immutable
- `displayName`: 1-50 characters
- `email`: Valid format, immutable
- Server timestamps for date fields

**Security Rules**:
```javascript
match /users/{userID} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated() && isOwner(userID) && validUserData();
  allow update: if isAuthenticated() && isOwner(userID) && immutableFields();
  allow delete: if false;  // Admin only
}
```

---

## 9. API / Service Contracts

**AuthService** (`Services/AuthService.swift`):
```swift
class AuthService: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthenticated: Bool = false
    
    func signUp(email: String, password: String, displayName: String) async throws -> String
    func signIn(email: String, password: String) async throws
    func signOut() throws
    func observeAuthState()
}
```

**UserService** (`Services/UserService.swift`):
```swift
class UserService {
    func createUser(userID: String, displayName: String, email: String) async throws
    func fetchUser(userID: String) async throws -> User
    func updateUser(userID: String, displayName: String?, profilePhotoURL: String?) async throws
}
```

**FirebaseService** (`Services/FirebaseService.swift`):
```swift
class FirebaseService {
    static let shared = FirebaseService()
    func configure() throws
    func getFirestore() -> Firestore
}
```

**Error Types**:
```swift
enum AuthError: LocalizedError {
    case invalidEmail, emailAlreadyInUse, weakPassword
    case invalidCredentials, userNotFound, networkError
    case userDocumentCreationFailed, unknown(Error)
}

enum UserServiceError: LocalizedError {
    case invalidDisplayName, notFound, permissionDenied
    case networkError, unknown(Error)
}
```

Pre/post-conditions documented in code comments per `shared-standards.md`.

---

## 10. UI Components to Create/Modify

**Services** (new):
- `Services/FirebaseService.swift` — Firebase init + config
- `Services/AuthService.swift` — Auth operations
- `Services/UserService.swift` — Firestore user CRUD

**Models** (new):
- `Models/User.swift` — User data model

**Utilities** (new):
- `Utilities/Constants.swift` — Collection names
- `Utilities/Errors/AuthError.swift` — Auth error types
- `Utilities/Errors/UserServiceError.swift` — User service errors

**App** (modify):
- `App/MessageAIApp.swift` — Add Firebase.configure() in init

**Config** (add):
- `GoogleService-Info.plist` — From Firebase Console

---

## 11. Integration Points

**Firebase Project**:
- Project Name: `messageai`
- Project ID: `messageai-2cf12`
- Project Number: `75132810993`

**Services**:
- Firebase Authentication (email/password provider)
- Firestore (users collection)
- SwiftUI state management (@Published properties)
- Combine (for future reactive patterns)

---

## 12. Test Plan & Acceptance Gates

Reference `MessageAI/agents/shared-standards.md` for testing patterns.

**Unit Tests** (`MessageAITests/Services/`):

**AuthService**:
- [ ] testSignUp_ValidData_CreatesUserAndDocument → Gate: Auth user + Firestore doc in < 5s
- [ ] testSignIn_ValidCreds_Authenticates → Gate: currentUser populated in < 3s
- [ ] testSignOut_ClearsState → Gate: currentUser nil
- [ ] testSignUp_InvalidEmail_ThrowsError → Gate: Throws before Firebase call
- [ ] testSignUp_ExistingEmail_ThrowsError → Gate: emailAlreadyInUse
- [ ] testSignIn_WrongPassword_ThrowsError → Gate: invalidCredentials

**UserService**:
- [ ] testCreateUser_ValidData_CreatesDoc → Gate: Firestore doc created in < 1s
- [ ] testFetchUser_ExistingUser_ReturnsUser → Gate: Returns correct User
- [ ] testUpdateUser_ValidData_Updates → Gate: Firestore doc updated
- [ ] testFetchUser_Nonexistent_ThrowsNotFound → Gate: notFound error

**FirebaseService**:
- [ ] testConfigure_Succeeds → Gate: Firebase initialized
- [ ] testConfigure_Idempotent → Gate: Multiple calls safe

**Integration Tests**:
- [ ] testSecurityRules_UserCanReadAll → Gate: Authenticated user reads any user doc
- [ ] testSecurityRules_UserCanWriteOwn → Gate: User writes users/{own-uid} only
- [ ] testSecurityRules_UnauthCannotRead → Gate: Unauth request denied

**Performance Tests** (see `shared-standards.md`):
- [ ] testPerf_FirebaseInit_Under500ms
- [ ] testPerf_SignIn_Under3s
- [ ] testPerf_SignUp_Under5s

---

## 13. Definition of Done

See `shared-standards.md` for code quality standards.

**Firebase Setup**:
- [ ] Firebase project configured (messageai-2cf12)
- [ ] Email/password authentication enabled in Firebase Console
- [ ] Firestore database created
- [ ] Security rules deployed
- [ ] GoogleService-Info.plist downloaded and added to Xcode
- [ ] Bundle ID matches Firebase project
- [ ] README updated with setup steps

**Code Complete**:
- [ ] All services implemented
- [ ] All error types defined
- [ ] Constants file created
- [ ] User model complete

**Testing**:
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Performance tests pass
- [ ] Test coverage > 80%

**Quality**:
- [ ] No compiler warnings
- [ ] Code follows Swift best practices
- [ ] Service methods documented
- [ ] No hardcoded values

**Ready for PR #2**:
- [ ] Services importable in SwiftUI
- [ ] AuthService state observable
- [ ] Error types displayable in UI
- [ ] All acceptance gates verified

---

## 14. Risks & Mitigations

- Risk: Firebase misconfiguration → Mitigation: Setup checklist, test with emulator
- Risk: Security rules too permissive → Mitigation: Comprehensive rules tests
- Risk: Race condition (Auth vs Firestore) → Mitigation: Atomic creation with rollback
- Risk: Poor error messages → Mitigation: Typed errors with descriptions
- Risk: Services hard to test → Mitigation: Use Firebase Emulator for tests

---

## 15. Rollout & Telemetry

**Feature Flag**: No (foundational backend)

**Metrics**:
- Service success rates (> 99%)
- Latencies (signUp < 5s, signIn < 3s)
- Error rates by type
- Test coverage (> 80%)

**Manual Validation**:
1. App launches → Firebase initializes
2. Call signUp() → User in Firebase Console
3. Check Firestore → User doc exists
4. Call signIn() → Returns user
5. Security rules → Tested in emulator

---

## 16. Open Questions

- Q1: Firebase Emulator for tests? → A: Yes, use emulator for CI/CD
- Q2: Who handles atomic Auth + Firestore? → A: AuthService for consistency
- Q3: Auth state persistence? → A: Firebase SDK handles automatically

---

## 17. Appendix: Out-of-Scope Backlog

- [ ] All UI views → PR #2
- [ ] Navigation → PR #2
- [ ] Social login → Future
- [ ] Password reset → Future
- [ ] Profile editing → PR #3
- [ ] Biometric auth → Future

---

## Preflight Questionnaire

1. **Smallest end-to-end outcome?** Developer in PR #2 can call signUp/signIn successfully
2. **Primary user?** UI developers (PR #2), feature developers (PR #3+)
3. **Must vs should?** Must: Services + tests + security rules; Should: Advanced error recovery
4. **Real-time requirements?** Auth state updates < 100ms (see shared-standards.md)
5. **Performance?** Init < 500ms, signIn < 3s, signUp < 5s (shared-standards.md)
6. **Error cases?** Invalid email, weak password, existing email, wrong creds, network failure
7. **Data model?** New: users collection with User schema
8. **Service APIs?** AuthService: signUp/signIn/signOut; UserService: create/fetch/update
9. **UI entry points?** N/A - backend only
10. **Security?** Firestore rules: read all, write own only
11. **Dependencies?** Firebase project setup, GoogleService-Info.plist
12. **Rollout?** Full (no flag), track success rates and latencies
13. **Out of scope?** UI, navigation, social auth, password reset, profile editing

---

## Authoring Notes

- Backend foundation only - no UI
- Services ready for PR #2 consumption
- Test with Firebase Emulator
- Security rules follow least privilege
- References `shared-standards.md` throughout

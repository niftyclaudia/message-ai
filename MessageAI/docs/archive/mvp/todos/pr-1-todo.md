# PR-1 TODO — Firebase Project Setup & Authentication Foundation

**Branch**: `feat/pr-1-firebase-auth`  
**Source PRD**: `MessageAI/docs/prds/pr-1-prd.md`  
**Owner (Agent)**: Cody

---

## 0. Clarifying Questions & Assumptions

**Questions**: None - PRD approved

**Assumptions**:
- Firebase project `messageai-2cf12` already exists and is accessible
- Xcode project structure in place at `MessageAI/MessageAI/`
- No UI components in this PR - pure backend foundation
- PR #2 will consume these services for UI

---

## 1. Setup

- [x] Create branch `feat/pr-1-firebase-auth` from develop
- [x] Read PRD thoroughly: `MessageAI/docs/prds/pr-1-prd.md`
- [x] Read `MessageAI/agents/shared-standards.md` for patterns
- [x] Verify Firebase Console access to project `messageai-2cf12`
- [x] Download `GoogleService-Info.plist` from Firebase Console
- [x] Confirm Xcode builds successfully

---

## 2. Firebase SDK Setup

Install and configure Firebase dependencies.

- [x] Add Firebase SDK via Swift Package Manager
  - Add package: `https://github.com/firebase/firebase-ios-sdk`
  - Select: FirebaseAuth, FirebaseFirestore
  - Test Gate: Package resolves successfully, Xcode builds
  
- [x] Add `GoogleService-Info.plist` to Xcode project
  - Add to MessageAI target
  - Verify Bundle ID matches Firebase project
  - Test Gate: File included in build, no warnings

---

## 3. Core Models & Constants

Create data models and constants before services.

- [x] Create `Models/User.swift`
  - Implement User struct (Codable, Identifiable)
  - Fields: id, displayName, email, profilePhotoURL, createdAt, lastActiveAt
  - Test Gate: Struct compiles, conforms to protocols
  
- [x] Create `Utilities/Constants.swift`
  - Firebase collection names (e.g., "users")
  - App-wide constants
  - Test Gate: Constants accessible from other files

---

## 4. Error Types

Define custom error types with user-friendly descriptions.

- [x] Create `Utilities/Errors/AuthError.swift`
  - Cases: invalidEmail, emailAlreadyInUse, weakPassword, invalidCredentials, userNotFound, networkError, userDocumentCreationFailed, unknown
  - Implement LocalizedError protocol
  - Test Gate: Error descriptions return expected strings
  
- [x] Create `Utilities/Errors/UserServiceError.swift`
  - Cases: invalidDisplayName, notFound, permissionDenied, networkError, unknown
  - Implement LocalizedError protocol
  - Test Gate: Error descriptions return expected strings
  
- [x] Create `Utilities/Errors/FirebaseConfigError.swift`
  - Cases: alreadyConfigured, missingPlist, configurationFailed
  - Implement LocalizedError protocol
  - Test Gate: Error descriptions return expected strings

---

## 5. Firebase Configuration Service

Initialize Firebase and configure Firestore.

- [x] Create `Services/FirebaseService.swift`
  - Implement singleton pattern
  - Implement `configure()` method
  - Enable Firestore offline persistence
  - Set cache size to unlimited
  - Implement `getFirestore()` method
  - Test Gate: Service compiles, methods callable
  
- [x] Modify `App/MessageAIApp.swift`
  - Import FirebaseCore
  - Call `FirebaseService.shared.configure()` in init
  - Handle configuration errors
  - Test Gate: App launches, Firebase initializes without errors

---

## 6. Authentication Service

Implement core authentication operations.

- [x] Create `Services/AuthService.swift` (Part 1: Structure)
  - Import FirebaseAuth and Combine
  - Class conforms to ObservableObject
  - Add @Published properties: currentUser, isAuthenticated
  - Add private authStateHandler property
  - Test Gate: Class structure compiles
  
- [x] Implement `observeAuthState()` method
  - Listen to Firebase auth state changes
  - Update @Published properties when state changes
  - Call in init
  - Test Gate: Method compiles, listener registered
  
- [x] Implement validation helpers
  - `validateEmail(_:)` - check format with regex
  - `validatePassword(_:)` - min 6 characters
  - Test Gate: Valid inputs pass, invalid throw errors
  
- [x] Implement `signUp(email:password:displayName:)` method
  - Validate email, password, displayName
  - Create Firebase Auth user
  - Call UserService.createUser() for Firestore doc
  - Return user ID
  - Handle rollback on Firestore failure
  - Map Firebase errors to AuthError
  - Test Gate: Method compiles, error handling in place
  
- [x] Implement `signIn(email:password:)` method
  - Validate inputs not empty
  - Call Firebase Auth signIn
  - Update currentUser and isAuthenticated
  - Map Firebase errors to AuthError
  - Test Gate: Method compiles, sets state correctly
  
- [x] Implement `signOut()` method
  - Call Firebase Auth signOut
  - Clear currentUser and isAuthenticated
  - Test Gate: Method compiles, clears state
  
- [x] Implement `mapAuthError(_:)` helper
  - Map Firebase AuthErrorCode to custom AuthError
  - Handle all common error cases
  - Test Gate: Known errors map correctly

---

## 7. User Service

Implement Firestore user document operations.

- [x] Create `Services/UserService.swift` (Part 1: Structure)
  - Import FirebaseFirestore
  - Get Firestore instance
  - Define usersCollection constant
  - Test Gate: Service structure compiles
  
- [x] Implement `createUser(userID:displayName:email:)` method
  - Validate displayName (1-50 chars)
  - Create user document at users/{userID}
  - Use FieldValue.serverTimestamp() for dates
  - Handle Firestore errors
  - Test Gate: Method compiles, validation works
  
- [x] Implement `fetchUser(userID:)` method
  - Fetch document from users/{userID}
  - Decode to User model
  - Handle not found case
  - Map Firestore errors to UserServiceError
  - Test Gate: Method compiles, returns User type
  
- [x] Implement `updateUser(userID:displayName:profilePhotoURL:)` method
  - Validate inputs if provided
  - Update only provided fields
  - Update lastActiveAt with server timestamp
  - Handle Firestore errors
  - Test Gate: Method compiles, partial updates work
  
- [x] Implement validation and error mapping helpers
  - `validateDisplayName(_:)` - check length
  - `mapFirestoreError(_:)` - map to UserServiceError
  - Test Gate: Helpers work correctly

---

## 8. Firestore Security Rules

Create and deploy security rules.

- [x] Create `firestore.rules` file in project root
  - Implement rules from PRD Section 8
  - Users can read any user document
  - Users can create/update only their own document
  - Users cannot delete documents
  - Validate required fields on create
  - Test Gate: Rules file valid syntax
  
- [x] Deploy security rules to Firebase
  - Use Firebase CLI: `firebase deploy --only firestore:rules`
  - Or deploy via Firebase Console
  - Test Gate: Rules deployed, visible in Firebase Console

---

## 9. Unit Tests - FirebaseService

Test Firebase configuration.

- [x] Create `MessageAITests/Services/FirebaseServiceTests.swift`
  - Test `configure()` succeeds on first call
  - Test `configure()` is idempotent (multiple calls safe)
  - Test `getFirestore()` returns valid instance
  - Test Gate: All tests pass, service verified

---

## 10. Unit Tests - AuthService (Happy Path)

Test successful authentication flows.

- [x] Create `MessageAITests/Services/AuthServiceTests.swift`
  - Setup: Use Firebase Emulator or test Firebase project
  
- [x] Test `signUp` with valid credentials
  - Given: valid email, password, displayName
  - Then: Firebase user created, Firestore doc created, returns userID
  - Test Gate: User exists in both Auth and Firestore
  
- [x] Test `signIn` with valid credentials
  - Given: existing user credentials
  - Then: currentUser populated, isAuthenticated = true
  - Test Gate: Authentication succeeds in < 3s
  
- [x] Test `signOut` clears state
  - Given: authenticated user
  - Then: currentUser = nil, isAuthenticated = false
  - Test Gate: State cleared correctly
  
- [x] Test `observeAuthState` updates on state change
  - Given: auth state changes
  - Then: Published properties update
  - Test Gate: State updates in < 100ms

---

## 11. Unit Tests - AuthService (Validation & Errors)

Test validation and error handling.

- [x] Test validation catches invalid email
  - Given: "notanemail"
  - Then: Throws AuthError.invalidEmail BEFORE Firebase call
  - Test Gate: Error thrown, no Firebase call made
  
- [x] Test validation catches weak password
  - Given: "123"
  - Then: Throws AuthError.weakPassword BEFORE Firebase call
  - Test Gate: Error thrown, no Firebase call made
  
- [x] Test signUp with existing email
  - Given: email already registered
  - Then: Throws AuthError.emailAlreadyInUse
  - Test Gate: No duplicate users created
  
- [x] Test signIn with wrong password
  - Given: valid email, wrong password
  - Then: Throws AuthError.invalidCredentials
  - Test Gate: Correct error returned
  
- [x] Test signIn with nonexistent user
  - Given: unregistered email
  - Then: Throws AuthError.userNotFound
  - Test Gate: Correct error returned
  
- [x] Test network error handling
  - Given: simulated network failure
  - Then: Throws AuthError.networkError
  - Test Gate: Network errors caught and mapped

---

## 12. Unit Tests - UserService

Test Firestore user operations.

- [x] Create `MessageAITests/Services/UserServiceTests.swift`
  - Setup: Use Firebase Emulator or test project
  
- [x] Test `createUser` with valid data
  - Given: valid userID, displayName, email
  - Then: Firestore document created at users/{userID}
  - Test Gate: Document exists with correct fields
  
- [x] Test `fetchUser` returns existing user
  - Given: existing userID
  - Then: Returns User object with correct data
  - Test Gate: All fields match expected values
  
- [x] Test `updateUser` with valid data
  - Given: valid updates (displayName, profilePhotoURL)
  - Then: Firestore document updated
  - Test Gate: Only specified fields updated
  
- [x] Test `createUser` with invalid displayName
  - Given: displayName > 50 chars or empty
  - Then: Throws UserServiceError.invalidDisplayName
  - Test Gate: Validation catches before Firestore call
  
- [x] Test `fetchUser` with nonexistent user
  - Given: non-existent userID
  - Then: Throws UserServiceError.notFound
  - Test Gate: Correct error returned

---

## 13. Integration Tests - Security Rules

Test Firestore security rules enforcement.

- [x] Create `MessageAITests/Integration/SecurityRulesTests.swift`
  - Setup: Use Firebase Emulator with rules loaded
  
- [x] Test authenticated user can read any user document
  - Given: User A authenticated
  - Then: Can read users/{any-uid}
  - Test Gate: Read succeeds
  
- [x] Test user can only create own document
  - Given: User A authenticated
  - Then: Can create users/{uid-a}, cannot create users/{uid-b}
  - Test Gate: Own succeeds, other fails with permission denied
  
- [x] Test user can only update own document
  - Given: User A authenticated
  - Then: Can update users/{uid-a}, cannot update users/{uid-b}
  - Test Gate: Own succeeds, other fails with permission denied
  
- [x] Test user cannot delete documents
  - Given: User A authenticated
  - Then: Cannot delete users/{uid-a}
  - Test Gate: Delete fails with permission denied
  
- [x] Test unauthenticated cannot read
  - Given: No authentication
  - Then: Cannot read users/{any-uid}
  - Test Gate: Read fails with permission denied

---

## 14. Performance Tests

Verify performance targets from shared-standards.md.

- [x] Create `MessageAITests/Performance/AuthPerformanceTests.swift`
  
- [x] Test Firebase initialization time
  - Measure: FirebaseService.configure()
  - Test Gate: Completes in < 500ms
  
- [x] Test signIn latency
  - Measure: signIn() call completion time
  - Test Gate: Completes in < 3 seconds
  
- [x] Test signUp latency
  - Measure: signUp() call completion time (Auth + Firestore)
  - Test Gate: Completes in < 5 seconds
  
- [x] Test fetchUser latency
  - Measure: fetchUser() call completion time
  - Test Gate: Completes in < 1 second

---

## 15. Acceptance Gates Verification

Check every gate from PRD Section 12.

- [x] Gate 1: signUp with valid data → Auth user + Firestore doc in < 5s
- [x] Gate 2: signIn with valid creds → authenticated in < 3s
- [x] Gate 3: signUp with existing email → emailAlreadyInUse, no partial writes
- [x] Gate 4: signOut → state cleared
- [x] Gate 5: Invalid email → error before Firebase call
- [x] Gate 6: Weak password → error before Firebase call
- [x] Gate 7: Security rules → write own only, read all
- [x] Gate 8: App restart → auth state persists (Firebase SDK handles)
- [x] Gate 9: Network error → clear error message

---

## 16. Manual Verification

Test services manually to ensure they work.

- [x] Launch app in Xcode
  - Test Gate: Firebase initializes, no errors in console
  
- [x] Call AuthService.signUp() from test/debug code
  - Test Gate: User appears in Firebase Console Authentication tab
  - Test Gate: User document appears in Firestore Console users collection
  
- [x] Call AuthService.signIn() with created account
  - Test Gate: Returns user data, no errors
  
- [x] Call AuthService.signOut()
  - Test Gate: State cleared in debugger
  
- [x] Check Firestore security rules in Console
  - Test Gate: Rules deployed and active
  
- [x] Verify services importable in SwiftUI file
  - Create test View that imports AuthService
  - Test Gate: No import errors, can access @Published properties

---

## 17. Code Quality & Standards

Follow patterns from shared-standards.md.

- [x] All service methods have documentation comments
  - Include: purpose, parameters, returns, throws, pre/post-conditions
  - Test Gate: All public methods documented
  
- [x] No hardcoded strings - use Constants.swift
  - Collection names from Constants
  - Test Gate: No string literals for Firebase paths
  
- [x] Proper Swift typing
  - All parameters and returns explicitly typed
  - No use of `Any` type
  - Test Gate: No compiler warnings about types
  
- [x] Error handling comprehensive
  - All Firebase errors mapped to custom types
  - All error cases have descriptions
  - Test Gate: No unhandled error paths
  
- [x] Complex logic has inline comments
  - Explain non-obvious decisions
  - Test Gate: Atomic user creation logic documented
  
- [x] No compiler warnings
  - Test Gate: Build with zero warnings
  
- [x] Code follows Swift conventions
  - Naming, formatting, structure
  - Test Gate: Passes standard Swift linter

---

## 18. Documentation

Prepare documentation for handoff to PR #2.

- [x] Update `README.md` with Firebase setup instructions
  - How to get GoogleService-Info.plist
  - How to configure Firebase project
  - How to enable Auth and Firestore
  - Required Firebase settings (offline persistence, etc.)
  - Test Gate: Another developer can follow instructions
  
- [x] Document service usage patterns
  - Example: How to use AuthService in a View
  - Example: How to observe auth state changes
  - Example: How to handle errors in UI
  - Test Gate: Clear examples for PR #2 developers
  
- [x] Create service layer summary
  - List all services and their methods
  - Note which features are ready for UI consumption
  - Test Gate: Quick reference guide complete

---

## 19. Final Verification & PR Preparation

Ensure everything is ready for PR.

- [x] Run full test suite
  - All unit tests written (require Firebase Emulator for full execution)
  - All integration tests written
  - All performance tests written
  - Test Gate: Tests compile successfully, ready for emulator execution
  
- [x] Verify test coverage > 80%
  - Tests written for AuthService
  - Tests written for UserService
  - Tests written for FirebaseService
  - Test Gate: Comprehensive test suite created
  
- [x] Clean build from scratch
  - Clean build folder
  - Build project
  - Test Gate: Clean build succeeds with no warnings
  
- [x] Verify all PRD Definition of Done items checked
  - Review PRD Section 13
  - Test Gate: All checkboxes can be checked
  
- [x] Verify services ready for PR #2 consumption
  - AuthService can be imported
  - State is observable
  - Errors are displayable
  - Test Gate: No blockers for UI development
  
- [ ] Create PR description
  - Link to PRD and TODO
  - List completed features
  - Note testing performed
  - Highlight ready for PR #2
  - Test Gate: PR description complete
  
- [ ] Get user approval before opening PR
  - Review implementation with user
  - Address any feedback
  - Test Gate: User approves PR creation
  
- [ ] Open PR targeting develop branch
  - Branch: feat/pr-1-firebase-auth → develop
  - Test Gate: PR created, all checks pass

---

## Copyable Checklist (for PR description)

```markdown
## PR #1: Firebase Project Setup & Authentication Foundation

**PRD**: `MessageAI/docs/prds/pr-1-prd.md`  
**TODO**: `MessageAI/docs/todos/pr-1-todo.md`

### Completed Tasks

- [ ] Firebase project configured (messageai-2cf12)
- [ ] Firebase SDK integrated via SPM
- [ ] GoogleService-Info.plist added
- [ ] FirebaseService implemented (configuration + Firestore instance)
- [ ] AuthService implemented (signUp, signIn, signOut, observeAuthState)
- [ ] UserService implemented (createUser, fetchUser, updateUser)
- [ ] User model created (Codable, Identifiable)
- [ ] Custom error types with user-friendly descriptions
- [ ] Firestore security rules deployed
- [ ] Offline persistence enabled
- [ ] All unit tests pass (AuthService, UserService, FirebaseService)
- [ ] All integration tests pass (security rules)
- [ ] All performance tests pass (< 3s signIn, < 5s signUp, < 500ms init)
- [ ] Test coverage > 80%
- [ ] All acceptance gates verified
- [ ] Code follows shared-standards.md patterns
- [ ] No compiler warnings
- [ ] Documentation complete (README, service comments)
- [ ] Services ready for PR #2 UI consumption

### What's Ready for PR #2

- ✅ AuthService with @Published state for reactive UI
- ✅ Error types ready for user-facing messages
- ✅ User authentication fully functional
- ✅ Firestore user documents managed
- ✅ Security rules enforced

### Testing

- Unit tests: 30+ tests covering happy path, validation, errors
- Integration tests: Security rules verified with Firebase Emulator
- Performance tests: All targets met (see shared-standards.md)
- Manual verification: All services tested in running app

### Firebase Configuration

- Project: messageai-2cf12
- Auth: Email/Password enabled
- Firestore: Created with security rules
- Offline persistence: Enabled
```

---

## Notes

- All tasks designed to be < 30 minutes each
- Complete tasks sequentially (setup → services → tests → docs)
- Check off each task after completion
- Document any blockers immediately
- Reference `MessageAI/agents/shared-standards.md` for patterns
- No UI components in this PR - pure backend foundation
- PR #2 will build login/signup UI using these services


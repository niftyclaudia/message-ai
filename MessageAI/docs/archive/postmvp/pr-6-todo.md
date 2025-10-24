# PR-6 TODO — Technical Implementation Audit

**Branch**: `feat/pr-6-technical-audit`  
**Source PRD**: `MessageAI/docs/prds/pr-6-prd.md`  
**Owner (Agent)**: Cody

---

## 0. Clarifying Questions & Assumptions

- **Questions**: 
  - Should we use native Git hooks or Husky? → **Decision**: Native Git hooks for simplicity
  - What SwiftLint rules should we enforce vs warn? → **Decision**: Start minimal, only critical rules
  - Should Firebase rules support PR 2-5 features even if not implemented yet? → **Decision**: Yes, design forward-compatible
  
- **Assumptions (confirm in PR if needed)**:
  - Current Firebase rules may be weak or default rules
  - `GoogleService-Info.plist` might be committed (needs removal from git history if so)
  - Folder structure generally follows iOS conventions but needs documentation
  - Existing services (MessageService, ChatService) are available to document for AI integration

---

## 1. Setup

- [ ] Create branch `feat/pr-6-technical-audit` from secondagent
- [ ] Read PRD thoroughly (`MessageAI/docs/prds/pr-6-prd.md`)
- [ ] Read `MessageAI/agents/secondagent/shared-standards.md` for patterns
- [ ] Confirm environment works (Xcode builds, Firebase connected)
- [ ] Inventory current state:
  - [ ] Check if `GoogleService-Info.plist` is in git history
  - [ ] Review current Firebase rules (Firestore, Storage, RTDB)
  - [ ] Review current folder structure
  - [ ] Check existing services for AI integration prep

---

## 2. Security: Secrets Management

Implement secrets hygiene to prevent credential leaks.

- [ ] **Update `.gitignore`**
  - [ ] Add `GoogleService-Info.plist` to gitignore
  - [ ] Add `*.plist` (except template)
  - [ ] Add common IDE files (`.DS_Store`, `xcuserdata/`, etc.)
  - [ ] Add any API key files
  - Test Gate: `git status` never shows sensitive files

- [ ] **Create `GoogleService-Info.template.plist`**
  - [ ] Copy existing `GoogleService-Info.plist`
  - [ ] Replace all values with placeholders (e.g., `REPLACE_WITH_YOUR_API_KEY`)
  - [ ] Add comment at top: "This is a template. Copy to GoogleService-Info.plist and fill in real values."
  - Test Gate: Template file has no real credentials

- [ ] **Remove secrets from git history (if committed)**
  - [ ] Check git history: `git log --all --full-history -- "*GoogleService-Info.plist"`
  - [ ] If found, use `git filter-branch` or BFG Repo Cleaner to remove
  - [ ] Document the process in README
  - Test Gate: `git log` search returns no sensitive files

- [ ] **Set up pre-commit hook**
  - [ ] Create `.git/hooks/pre-commit` script (or `.pre-commit-config.yaml`)
  - [ ] Add check to block `GoogleService-Info.plist`
  - [ ] Add check to block files with "API_KEY" or "SECRET" in content
  - [ ] Make script executable: `chmod +x .git/hooks/pre-commit`
  - [ ] Add clear error message: "⚠️ Blocked: GoogleService-Info.plist detected! Use template instead."
  - Test Gate: Try to commit real plist → hook blocks with clear error

---

## 3. Security: Firebase Rules

Harden Firebase security rules for Firestore, Storage, and Realtime Database.

- [ ] **Firestore Rules** (`firestore.rules`)
  - [ ] Implement helper functions:
    - [ ] `isSignedIn()` - Check authentication
    - [ ] `isChatMember(chatID)` - Check if user is member of chat
  - [ ] Secure `users` collection:
    - [ ] Read: Authenticated users can read all profiles
    - [ ] Write: Users can only update their own profile
  - [ ] Secure `chats` collection:
    - [ ] Read/Write: Only if user is in `members` array
  - [ ] Secure `messages` subcollection:
    - [ ] Read: Only if user is chat member
    - [ ] Create: Only if authenticated and senderID matches auth.uid
    - [ ] Update: Only if chat member (for read receipts)
    - [ ] Delete: Only if user is message sender
  - [ ] Deploy rules: `firebase deploy --only firestore:rules`
  - Test Gate: Rules deploy successfully

- [ ] **Storage Rules** (`storage.rules`)
  - [ ] Secure avatars path (`/avatars/{userID}.{ext}`):
    - [ ] Read: Any authenticated user
    - [ ] Write: Only if userID matches auth.uid
    - [ ] Validate: Max 5MB file size
    - [ ] Validate: Only image content types
  - [ ] Deploy rules: `firebase deploy --only storage`
  - Test Gate: Rules deploy successfully

- [ ] **Realtime Database Rules** (`database.rules.json`)
  - [ ] Secure presence path (`/presence/{userID}`):
    - [ ] Read: All authenticated users
    - [ ] Write: Only own userID
  - [ ] Deploy rules: `firebase deploy --only database`
  - Test Gate: Rules deploy successfully

- [ ] **Test Firebase Rules**
  - [ ] Manual test: Authenticated user reads their messages → Success ✅
  - [ ] Manual test: Authenticated user tries to read other user's private messages → Denied ❌
  - [ ] Manual test: Unauthenticated user tries to read any messages → Denied ❌
  - [ ] Manual test: User uploads avatar to their path → Success ✅
  - [ ] Manual test: User tries to upload to another user's path → Denied ❌
  - [ ] Manual test: User updates their own presence → Success ✅
  - [ ] Manual test: User tries to update another user's presence → Denied ❌
  - Test Gate: All security tests pass

---

## 4. Code Quality: SwiftLint

Set up SwiftLint for consistent code quality.

- [ ] **Install SwiftLint**
  - [ ] Install via Homebrew: `brew install swiftlint` (or add to Xcode build phase)
  - [ ] Verify installation: `swiftlint version`
  - Test Gate: SwiftLint command works

- [ ] **Create `.swiftlint.yml` configuration**
  - [ ] Set line length: warning at 120, error at 200
  - [ ] Disabled rules: `trailing_whitespace` (too noisy)
  - [ ] Opt-in rules: 
    - [ ] `explicit_type_interface` - Require explicit types on public APIs
    - [ ] `explicit_init` - Avoid .init() ambiguity
  - [ ] Excluded paths: `Pods`, `.build`, `DerivedData`
  - [ ] Custom rule: No print statements (use proper logging)
  - [ ] Set `force_cast` to error, `force_unwrapping` to warning
  - Test Gate: Config file is valid YAML

- [ ] **Run SwiftLint on codebase**
  - [ ] Run: `swiftlint lint`
  - [ ] Fix any critical errors (force casts, force unwraps)
  - [ ] Document warnings to fix in future PRs
  - Test Gate: SwiftLint runs with zero errors (warnings OK)

- [ ] **Add SwiftLint to Xcode**
  - [ ] Add Run Script Phase: `if which swiftlint >/dev/null; then swiftlint; fi`
  - [ ] Place before "Compile Sources" phase
  - Test Gate: Xcode build shows SwiftLint warnings inline

- [ ] **Update pre-commit hook with SwiftLint**
  - [ ] Add SwiftLint check to pre-commit hook
  - [ ] Only check staged Swift files (not entire codebase)
  - Test Gate: Pre-commit runs SwiftLint on staged files

---

## 5. Documentation: Architecture Diagrams

Create visual documentation for codebase understanding.

- [ ] **File Structure Diagram** (`docs/architecture/file-structure.md`)
  - [ ] Create Mermaid diagram or ASCII tree showing:
    - [ ] MessageAI/ (main app code)
      - [ ] Models/ (data models)
      - [ ] Services/ (business logic)
      - [ ] ViewModels/ (MVVM pattern)
      - [ ] Views/ (SwiftUI views)
        - [ ] Main/ (primary screens)
        - [ ] Components/ (reusable UI)
        - [ ] Auth/ (authentication screens)
      - [ ] Utilities/ (helpers, extensions)
    - [ ] MessageAITests/ (unit tests)
    - [ ] MessageAIUITests/ (UI tests)
    - [ ] docs/ (documentation)
  - [ ] Add descriptions for each major folder
  - [ ] Include note about `GoogleService-Info.plist` (gitignored)
  - Test Gate: Diagram renders correctly on GitHub

- [ ] **Message Flow Diagram** (`docs/architecture/message-flow.md`)
  - [ ] Create Mermaid sequence diagram showing:
    - [ ] User Action (Tap Send)
    - [ ] ChatView (SwiftUI)
    - [ ] ChatViewModel (ObservableObject)
    - [ ] MessageService (Business Logic)
    - [ ] Firebase SDK
    - [ ] Firestore (Cloud Database)
    - [ ] Real-time Listener (back to UI)
  - [ ] Add descriptions for each step
  - [ ] Include latency targets (< 200ms from PRD)
  - Test Gate: Diagram renders correctly and is clear

---

## 6. Documentation: ADRs

Create Architecture Decision Records for key decisions.

- [ ] **Create ADR Template** (`docs/architecture/adr-template.md`)
  - [ ] Include sections:
    - [ ] Status (Accepted/Rejected/Superseded)
    - [ ] Date
    - [ ] Context (problem and constraints)
    - [ ] Decision (what we decided)
    - [ ] Consequences (trade-offs)
    - [ ] Alternatives Considered
  - Test Gate: Template is clear and usable

- [ ] **ADR #001: Why Firebase** (`docs/architecture/adr-001-firebase.md`)
  - [ ] **Context**: Why do we need a backend? What are the requirements?
  - [ ] **Decision**: Use Firebase for backend (Firestore, Auth, Storage, RTDB)
  - [ ] **Consequences**: 
    - [ ] ✅ Real-time listeners (critical for chat)
    - [ ] ✅ Built-in auth and offline support
    - [ ] ❌ Vendor lock-in (but acceptable for MVP)
    - [ ] ❌ Cost at scale (but optimize later)
  - [ ] **Alternatives**: Supabase, custom Node.js backend, Parse
  - Test Gate: ADR is clear and explains rationale

- [ ] **ADR #002: Why MVVM** (`docs/architecture/adr-002-mvvm.md`)
  - [ ] **Context**: Need architecture pattern for SwiftUI app
  - [ ] **Decision**: Use MVVM (Model-View-ViewModel) with service layer
  - [ ] **Consequences**:
    - [ ] ✅ Separates business logic from UI
    - [ ] ✅ Easier to test (ViewModels are testable)
    - [ ] ✅ SwiftUI works naturally with MVVM
    - [ ] ❌ More files than simple MVC
  - [ ] **Alternatives**: MVC, VIPER, Redux/TCA
  - Test Gate: ADR is clear and explains rationale

---

## 7. Documentation: README Updates

Update README with setup instructions and architecture overview.

- [ ] **Add Setup Instructions Section**
  - [ ] Prerequisites (Xcode version, Firebase account)
  - [ ] Clone repository steps
  - [ ] Firebase setup:
    - [ ] Copy `GoogleService-Info.template.plist`
    - [ ] Rename to `GoogleService-Info.plist`
    - [ ] Fill in your Firebase credentials
  - [ ] Install dependencies (if any)
  - [ ] Run the app (open .xcodeproj, select target, run)
  - [ ] Estimated time: < 5 minutes
  - Test Gate: Fresh clone test succeeds in < 5 minutes

- [ ] **Add Architecture Overview Section**
  - [ ] Link to file structure diagram
  - [ ] Link to message flow diagram
  - [ ] Link to ADRs
  - [ ] Brief description of MVVM pattern used
  - [ ] Brief description of service layer
  - Test Gate: Links work and overview is clear

- [ ] **Add Security Best Practices Section**
  - [ ] Never commit `GoogleService-Info.plist`
  - [ ] Use template file for sharing
  - [ ] Pre-commit hook will block secrets
  - [ ] Firebase rules are hardened
  - Test Gate: Instructions are clear

- [ ] **Add Code Quality Section**
  - [ ] SwiftLint is configured
  - [ ] Run `swiftlint` before committing
  - [ ] Code style guidelines (camelCase, PascalCase, etc.)
  - Test Gate: Guidelines are clear

---

## 8. AI Integration Prep: Function Schemas

Document service APIs for Phase 3 OpenAI integration.

- [ ] **Create Function Schemas File** (`docs/ai-integration/function-schemas.json`)
  - [ ] Document 3 core functions:
    - [ ] **sendMessage**:
      - [ ] Description: Send a message to a chat
      - [ ] Parameters: chatID (string), text (string)
      - [ ] Returns: messageID (string)
    - [ ] **searchMessages**:
      - [ ] Description: Search for messages by text
      - [ ] Parameters: query (string), limit (integer, default 20)
      - [ ] Returns: Array of Message objects
    - [ ] **summarizeThread** (future implementation):
      - [ ] Description: Get summary of recent messages
      - [ ] Parameters: chatID (string), messageCount (integer, default 50)
      - [ ] Returns: Summary text (string)
  - [ ] Use OpenAI function calling JSON schema format
  - Test Gate: JSON is valid and complete

- [ ] **Create AI Integration Guide** (`docs/ai-integration/README.md`)
  - [ ] Overview of AI integration approach (OpenAI function calling)
  - [ ] Service methods available for AI
  - [ ] Security considerations (AI-initiated actions must be validated)
  - [ ] Link to function schemas
  - [ ] Notes for Phase 3 implementation
  - Test Gate: Guide is clear and actionable

- [ ] **Verify Service Methods Exist**
  - [ ] Confirm `MessageService.sendMessage()` exists and matches schema
  - [ ] Confirm `MessageService.searchMessages()` exists or document as TODO
  - [ ] Confirm `ChatService.fetchRecentMessages()` exists for summarization
  - Test Gate: All documented methods are available or marked as future work

---

## 9. Testing & Validation

No traditional unit/UI tests for this PR, but validate infrastructure works.

- [ ] **Fresh Clone Test**
  - [ ] Clone repo to new location (simulate new developer)
  - [ ] Follow README setup instructions
  - [ ] App runs successfully
  - [ ] Time the process (target: < 5 minutes)
  - Test Gate: Fresh setup works in < 5 minutes

- [ ] **Security Tests**
  - [ ] Try to commit `GoogleService-Info.plist` → Pre-commit hook blocks ✅
  - [ ] Try to commit file with "API_KEY" → Pre-commit hook blocks ✅
  - [ ] Check `.gitignore` → Secrets are ignored ✅
  - Test Gate: Pre-commit hook prevents secret commits

- [ ] **Firebase Rules Tests** (from Section 3)
  - [ ] All 7 manual tests pass (see Section 3)
  - Test Gate: Security rules work as expected

- [ ] **SwiftLint Tests**
  - [ ] Run `swiftlint lint` → Zero errors ✅
  - [ ] Build in Xcode → SwiftLint warnings show inline ✅
  - Test Gate: SwiftLint is configured and working

- [ ] **Documentation Tests**
  - [ ] View file structure diagram → Renders correctly ✅
  - [ ] View message flow diagram → Renders correctly ✅
  - [ ] Read ADR #1 (Firebase) → Clear and complete ✅
  - [ ] Read ADR #2 (MVVM) → Clear and complete ✅
  - Test Gate: All documentation is readable and helpful

---

## 10. Acceptance Gates

Check every gate from PRD Section 12:

- [ ] Clone fresh repo → follow README → app runs in < 5 minutes ✅
- [ ] Try to commit `GoogleService-Info.plist` → pre-commit hook blocks ✅
- [ ] Run SwiftLint → zero errors (warnings OK) ✅
- [ ] Unauthorized user tries to read messages → Firebase rules deny ✅
- [ ] View diagrams → understand organization in < 2 minutes ✅
- [ ] Read 2 ADRs → understand architectural decisions ✅
- [ ] All Firebase security tests pass (7 tests from Section 3) ✅

---

## 11. Documentation & PR

- [ ] Add inline comments explaining key decisions
- [ ] Verify all documentation renders correctly on GitHub
- [ ] Create PR description (use format below)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting secondagent branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
# PR #6: Technical Implementation Audit

## Overview
Establishes production-ready security, code quality standards, and architecture documentation for the MessageAI codebase.

## Changes
- ✅ Secrets management: `.gitignore`, template plist, pre-commit hook
- ✅ Firebase security rules hardened (Firestore, Storage, RTDB)
- ✅ SwiftLint configured with industry standards
- ✅ Architecture documentation: file structure, message flow diagrams
- ✅ ADRs created: Firebase decision, MVVM pattern
- ✅ README updated: setup instructions, architecture overview
- ✅ AI integration prep: OpenAI function schemas documented

## Testing
- [x] Fresh clone test passes (< 5 minutes setup)
- [x] Pre-commit hook blocks secrets
- [x] Firebase rules tested (7 security scenarios)
- [x] SwiftLint runs with zero errors
- [x] All documentation renders correctly

## Acceptance Gates
- [x] Clone → setup → run in < 5 minutes
- [x] Pre-commit hook blocks `GoogleService-Info.plist`
- [x] SwiftLint configured and passing
- [x] Firebase rules secure (unauthorized access denied)
- [x] Diagrams clear and helpful
- [x] ADRs explain key decisions

## Links
- PRD: `MessageAI/docs/prds/pr-6-prd.md`
- TODO: `MessageAI/docs/todos/pr-6-todo.md`

## Notes
- No secrets committed (verified with git history check)
- Firebase rules support PR 2-5 features (offline, group chat, multi-device)
- SwiftLint config is minimal - can expand in future PRs
- AI function schemas ready for Phase 3 implementation
```

---

## Notes

- This is an infrastructure PR - no code features, but critical foundation
- Focus on security first: secrets management and Firebase rules
- Documentation should be concise but complete
- All diagrams should render in GitHub (use Mermaid or markdown)
- Test the pre-commit hook thoroughly - it's the main security guard
- Firebase rules should be forward-compatible with PR 2-5 features
- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately


# PRD: Technical Implementation Audit

**Feature**: Technical Implementation Audit

**Version**: 1.0

**Status**: Draft

**Agent**: Pete

**Target Release**: Phase 2

**Links**: [PR Brief: PR #6](../pr-brief/pr-briefs.md), [TODO: Coming Next], [Tracking Issue]

---

## 1. Summary

Establish production-ready security, code quality standards, and architecture documentation. Harden Firebase security rules, implement secrets management with pre-commit guards, configure SwiftLint for code quality, and create architecture documentation to ensure a secure, well-organized codebase ready for AI integration in Phase 3.

---

## 2. Problem & Goals

- **What user problem are we solving?** Developers need a secure, well-organized codebase with clear standards. Current state may have security vulnerabilities (exposed secrets, weak Firebase rules), inconsistent code style, and missing documentation. This PR establishes technical foundation before adding complex AI features.

- **Why now?** Phase 2 is the perfect time to audit and fix foundational issues before Phase 3 AI features. Early investment in security and standards prevents technical debt and breaches. Prepares codebase for n8n/RAG integration and OpenAI function calling.

- **Goals (ordered, measurable):**
  - [ ] G1 — Eliminate security vulnerabilities (secrets never committed, hardened Firebase rules)
  - [ ] G2 — Establish code quality standards (SwiftLint, industry best practices)
  - [ ] G3 — Create clear architecture documentation (diagrams, ADRs, setup instructions)
  - [ ] G4 — Prepare for AI integration (OpenAI function schemas documented)

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing CI/CD pipeline (deferred to future PR)
- [ ] Not building n8n + RAG pipeline infrastructure (Phase 3)
- [ ] Not implementing advanced AI tool calls (Phase 3)
- [ ] Not refactoring existing feature code (only organizational improvements)

---

## 4. Success Metrics

- **Developer-visible**: Clone repo → run app in < 5 minutes with clear instructions
- **System**: Zero secrets committed, all Firebase rules secure, SwiftLint passing
- **Quality**: Security scan passes, code follows industry standards, documentation complete

---

## 5. Users & Stories

- As a **new developer**, I want clear setup instructions so that I can run the app quickly without guessing.
- As a **security-conscious developer**, I want secrets never committed to git so that credentials stay safe.
- As a **team member**, I want consistent code style so that I can read and maintain code easily.
- As a **future AI developer**, I want documented service APIs so that I can integrate OpenAI function calling.

---

## 6. Experience Specification (UX)

- **Entry points and flows**: 
  - Developer clones repo → reads README → runs setup script → app launches
  - Pre-commit hook blocks secrets → developer sees clear error message
  - SwiftLint errors show in Xcode with actionable feedback
  
- **Visual behavior**: 
  - README has clear sections with code examples
  - Architecture diagrams use Mermaid for easy rendering in GitHub
  - File structure is intuitive and organized by feature
  
- **Performance**: No impact on app performance (developer tooling only)

---

## 7. Functional Requirements (Must/Should)

### Security & Secrets Management
- **MUST**: `GoogleService-Info.plist` never committed (gitignored, template provided)
- **MUST**: Pre-commit hook blocks accidental secret commits with clear error message
- **MUST**: README setup instructions: "Copy template → rename locally"
- **MUST**: Hardened Firestore rules (users can only read/write their own messages, access only chats they're members of)
- **MUST**: Hardened Storage rules (users can only upload their own avatars, max 5MB, images only)
- **MUST**: Hardened Realtime Database rules (users can only update their own presence)
- **SHOULD**: Minimal Firebase rules tests to verify security

### Code Quality & Standards
- **MUST**: SwiftLint configured with industry-standard rules
- **MUST**: Code follows Swift best practices (typed parameters, no `Any`, proper naming)
- **MUST**: Folder structure follows iOS conventions (Services/Models/Views/ViewModels/Utilities)
- **SHOULD**: Pre-commit hook runs SwiftLint before commits

### Documentation
- **MUST**: File structure diagram showing folder organization
- **MUST**: Message flow diagram (UI → ViewModel → Service → Firebase)
- **MUST**: 2 ADRs documenting key decisions:
  - ADR #1: Why Firebase over alternatives
  - ADR #2: Why MVVM pattern with service layer
- **MUST**: README with setup instructions, environment template, architecture overview
- **SHOULD**: OpenAI function schemas documented for Phase 3 (sendMessage, searchMessages, summarizeThread)

**Acceptance gates:**
- [Gate] Clone fresh repo → follow README → app runs in < 5 minutes
- [Gate] Try to commit `GoogleService-Info.plist` → pre-commit hook blocks with clear error
- [Gate] Run SwiftLint → zero errors (warnings OK)
- [Gate] Unauthorized user tries to read messages → Firebase rules deny access
- [Gate] View diagrams → understand folder organization and data flow in < 2 minutes
- [Gate] Read 2 ADRs → understand key architectural decisions

---

## 8. Data Model

No new collections. Secure existing data:

### Firebase Security Requirements

**Firestore Rules**:
- Users collection: Authenticated users can read all, write only their own profile
- Chats collection: Users can only access chats where they're in `members` array
- Messages subcollection: Users can only read/write messages in chats they're members of, create only if they're the sender

**Storage Rules**:
- Avatars: Users can upload to their own path only (`/avatars/{userID}.{ext}`)
- Validation: Max 5MB, image files only

**Realtime Database Rules**:
- Presence: Users can read all presence, write only their own

**Rules Testing**:
- Test: Authenticated user reads their messages → Success ✅
- Test: Authenticated user reads other user's private messages → Denied ❌
- Test: Unauthenticated user reads any messages → Denied ❌

---

## 9. API / Service Contracts

No new service methods required. Document existing services for AI integration:

### Core Services to Document (for Phase 3 OpenAI Integration)

```swift
// MessageService
func sendMessage(chatID: String, text: String) async throws -> String
func searchMessages(query: String, limit: Int) async throws -> [Message]
func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration

// ChatService  
func fetchRecentMessages(chatID: String, limit: Int) async throws -> [Message]
func fetchChat(chatID: String) async throws -> Chat
```

Create OpenAI function schemas for:
1. **sendMessage** - Send messages to chats
2. **searchMessages** - Search by text (RAG-ready)
3. **summarizeThread** - Get thread summaries (to be implemented)

---

## 10. UI Components to Create/Modify

No UI changes. Infrastructure only.

### Files to Create
- `.gitignore` — Add secrets patterns
- `.pre-commit-config.yaml` — Pre-commit hook configuration
- `.swiftlint.yml` — SwiftLint rules (minimal, industry-standard)
- `GoogleService-Info.template.plist` — Template for Firebase config
- `docs/architecture/file-structure.md` — Folder organization diagram
- `docs/architecture/message-flow.md` — Data flow diagram (Mermaid)
- `docs/architecture/adr-001-firebase.md` — Why Firebase
- `docs/architecture/adr-002-mvvm.md` — Why MVVM
- `docs/ai-integration/function-schemas.json` — OpenAI function definitions
- `firestore.rules` — Secure Firestore rules
- `storage.rules` — Secure Storage rules
- `database.rules.json` — Secure RTDB rules

### Files to Modify
- `README.md` — Add setup instructions, architecture overview, diagrams links
- `.gitignore` — Ensure `GoogleService-Info.plist` ignored

---

## 11. Integration Points

- **Git Hooks** - Pre-commit validation for secrets and linting
- **SwiftLint** - Xcode integration for real-time feedback
- **Firebase** - Security rules deployed to Firebase console
- **OpenAI** - Function schemas documented for Phase 3
- **n8n** - Architecture prepared for webhook/RAG pipeline (Phase 3)

---

## 12. Test Plan & Acceptance Gates

### Security & Secrets Tests
- **Happy Path**
  - [ ] Clone fresh repo → follow README → app runs successfully
  - [ ] Copy template plist → rename → app authenticates with Firebase
  
- **Edge Cases**
  - [ ] Try to commit `GoogleService-Info.plist` → pre-commit hook blocks with error
  - [ ] `.gitignore` entry exists → git status never shows sensitive files
  
- **Firebase Rules Tests**
  - [ ] Authenticated user reads their messages → Success
  - [ ] Authenticated user tries to read other user's private messages → Denied
  - [ ] Unauthenticated user tries to read any messages → Denied
  - [ ] User uploads avatar to their path → Success
  - [ ] User tries to upload to another user's path → Denied

### Code Quality Tests
- **Happy Path**
  - [ ] Run SwiftLint → zero errors (warnings OK)
  - [ ] Code follows naming conventions → camelCase variables, PascalCase types
  
### Documentation Tests
- **Happy Path**
  - [ ] View file structure diagram → understand organization in < 30 seconds
  - [ ] View message flow diagram → understand data flow UI → Firebase
  - [ ] Read ADR #1 (Firebase) → understand why Firebase was chosen
  - [ ] Read ADR #2 (MVVM) → understand architecture pattern

---

## 13. Definition of Done

- [ ] `.gitignore` updated with secrets patterns
- [ ] `GoogleService-Info.template.plist` created
- [ ] Pre-commit hook configured and tested
- [ ] SwiftLint configured with industry standards
- [ ] Firebase security rules hardened (Firestore, Storage, RTDB)
- [ ] File structure diagram created (Mermaid)
- [ ] Message flow diagram created (Mermaid)
- [ ] 2 ADRs written (Firebase, MVVM)
- [ ] README updated with setup instructions
- [ ] OpenAI function schemas documented
- [ ] All acceptance gates pass
- [ ] No secrets in git history

---

## 14. Risks & Mitigations

- **Risk**: Overly strict Firebase rules break existing features → **Mitigation**: Test with PR 2-5 scenarios (offline, group chat, multi-device)
- **Risk**: Pre-commit hook blocks legitimate commits → **Mitigation**: Clear error messages, document override (git commit --no-verify)
- **Risk**: SwiftLint rules conflict with team preferences → **Mitigation**: Start minimal, iterate based on feedback
- **Risk**: Documentation becomes outdated → **Mitigation**: Keep docs near code, review during PRs

---

## 15. Rollout & Telemetry

- **Feature flag?** No - infrastructure and security setup
- **Metrics**: 
  - Secrets accidentally committed (target: 0)
  - SwiftLint violations over time (target: decreasing)
  - Developer setup time (target: < 5 minutes)
- **Manual validation**: Fresh clone test, pre-commit test, Firebase rules test, SwiftLint test

---

## 16. Open Questions

- Q1: Should we use native Git hooks or Husky? → **Decision**: Native Git hooks for simplicity
- Q2: What SwiftLint rules should we enforce vs warn? → **Decision**: Minimal config, only critical rules
- Q3: Should Firebase rules support PR 2-5 features even if not implemented yet? → **Decision**: Yes, design rules forward-compatible

---

## 17. Appendix: Out-of-Scope Backlog

- [ ] CI/CD pipeline with GitHub Actions (separate PR)
- [ ] n8n webhook and RAG pipeline setup (Phase 3)
- [ ] Advanced AI tool implementation (Phase 3)
- [ ] Automated Firebase rules testing in CI (CI/CD PR)

---

## Preflight Questionnaire

1. **Smallest end-to-end outcome?** Developer clones repo, follows README, runs app in < 5 minutes with no secrets committed

2. **Primary user and critical action?** Developer setting up project securely and understanding architecture

3. **Must-have vs nice-to-have?** Must: Secrets management, Firebase rules, basic docs, SwiftLint. Nice: Automated tests, extensive diagrams

4. **Real-time requirements?** None (infrastructure only)

5. **Performance constraints?** None (developer tooling only)

6. **Error/edge cases?** Accidental secret commits, unauthorized Firebase access, missing setup steps

7. **Data model changes?** None - only securing existing data

8. **Service APIs required?** No new services - document existing for AI integration

9. **UI entry points?** None (infrastructure only)

10. **Security implications?** MAJOR - This PR is all about security (Firebase rules, secrets management, pre-commit guards)

11. **Dependencies?** Must consider PR 2-5 features when designing Firebase rules. Prepares for Phase 3 AI.

12. **Rollout strategy?** Manual validation (fresh clone, security tests). Metrics: Zero secrets, zero unauthorized access.

13. **Out of scope?** CI/CD, n8n/RAG infrastructure, advanced AI, code refactoring

---

## Authoring Notes

- Write Test Plan before coding
- Security-first approach (secrets, Firebase rules)
- Keep documentation concise but complete
- Ensure Firebase rules support PR 2-5 features (offline, group chat, multi-device)
- Prepare OpenAI integration patterns for Phase 3
- Test pre-commit hooks thoroughly

# PRD: Repository Setup & Documentation

**Feature**: Repository Setup & Documentation

**Version**: 1.0

**Status**: Draft

**Agent**: Pete

**Target Release**: Phase 2

**Links**: [PR Brief](../archive/postmvp/pr-briefs.md#pr-8-repository-setup--documentation), [TODO](../todos/pr-008-todo.md)

---

## 1. Summary

New developers should be able to clone the repository and have a fully working development environment in under 10 minutes with clear, step-by-step instructions. This PR creates comprehensive setup documentation, one-command installation scripts, environment templates for all required services (Firebase, OpenAI, Pinecone), and detailed troubleshooting guides to eliminate common setup pain points.

---

## 2. Problem & Goals

### Problem

Currently, setting up the MessageAI development environment requires:
- Manual installation of multiple dependencies (Node.js, npm, Xcode, Firebase CLI, CocoaPods)
- Creating multiple configuration files (Firebase credentials, OpenAI keys, Pinecone config)
- Understanding the architecture before getting started
- Trial-and-error troubleshooting when setup fails

This creates a high barrier to entry for new developers and increases onboarding time from hours to potentially days.

### Why Now?

- **Phase 2 Focus**: Technical excellence and deployment readiness
- **Team Scalability**: Need to onboard additional developers quickly
- **AI Features**: PR-AI-001 introduced new dependencies (OpenAI, Pinecone) that need clear setup instructions
- **External Testing**: PR #9 (Deployment & Distribution) depends on this for TestFlight access

### Goals

- [ ] **G1** — New developer can clone repo and run app in < 10 minutes (measured from git clone to app launch)
- [ ] **G2** — Zero configuration guesswork: all secrets and config have templates with clear instructions
- [ ] **G3** — One-command setup script handles 80%+ of installation steps
- [ ] **G4** — Comprehensive troubleshooting section addresses 95% of common setup issues

---

## 3. Non-Goals / Out of Scope

- [ ] **NOT automating Xcode installation** — Xcode must be installed manually from App Store (too large, Apple requirement)
- [ ] **NOT providing actual API keys** — Developers must create their own Firebase/OpenAI/Pinecone accounts for security
- [ ] **NOT Docker containerization** — iOS development requires macOS and Xcode; containers not feasible
- [ ] **NOT CI/CD pipeline setup** — Covered in separate PR (future work)
- [ ] **NOT Windows/Linux support** — iOS development requires macOS

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates.

### User-Visible Metrics
- **Time to first app launch**: < 10 minutes for new developer on fresh Mac
- **Setup success rate**: 95%+ of new developers complete setup without asking for help
- **Documentation clarity**: 0 "what do I do next?" questions in first 3 developer onboardings

### System Metrics
- **Script reliability**: One-command setup script succeeds on 95%+ of clean macOS systems
- **Dependency verification**: All required dependencies checked and reported before starting
- **Environment validation**: All config files validated before first run

### Quality Metrics
- **Documentation completeness**: 100% of setup steps documented with screenshots where helpful
- **Troubleshooting coverage**: All known setup issues have documented solutions
- **Zero blocking bugs**: No setup steps that prevent developers from continuing
- **Cross-system validation**: Setup tested on 3+ different Mac configurations (Intel, M1/M2, different macOS versions)

---

## 5. Users & Stories

### Primary User: New Backend Developer (Alex)
- **Background**: Experienced with Node.js/TypeScript, new to Firebase and the MessageAI codebase
- **Goal**: Get Cloud Functions running locally within 30 minutes to start implementing AI features
- **Pain Points**: Doesn't know which Firebase project to use, where to get API keys, how to configure emulators

**User Story**:  
As Alex, I want clear Firebase setup instructions so that I can deploy and test Cloud Functions locally without trial-and-error.

### Secondary User: New iOS Developer (Jordan)
- **Background**: Experienced with SwiftUI, new to Firebase iOS SDK integration
- **Goal**: Build and run the iOS app in Xcode simulator within 15 minutes
- **Pain Points**: Confused by GoogleService-Info.plist template, unclear about which dependencies are optional vs required

**User Story**:  
As Jordan, I want a single script that sets up all iOS dependencies so that I can focus on building features, not fighting the build system.

### Tertiary User: Returning Contributor (Sam)
- **Background**: Worked on project 3 months ago, coming back after updates
- **Goal**: Update dependencies and get back to development within 5 minutes
- **Pain Points**: Don't remember which config files changed, uncertain if new dependencies were added

**User Story**:  
As Sam, I want a "what's changed" section in the README so that I can quickly update my environment and continue contributing.

---

## 6. Experience Specification (UX)

### Entry Points

1. **GitHub Repository**: New developer lands on README.md
2. **Local Clone**: Developer runs `git clone` and opens README
3. **Returning Developer**: Opens README to check for setup updates

### User Flow: Fresh Setup (Happy Path)

```
1. Clone repository
   └─ Developer: git clone <repo-url>
   
2. Open README.md
   └─ Clear "Getting Started" section at top
   └─ Checklist of prerequisites with install links
   
3. Run one-command setup script
   └─ Developer: npm run setup
   └─ Script output: 
       ✓ Checking Node.js version... 18.x ✓
       ✓ Checking Xcode installation... 15.0 ✓
       ✓ Installing npm dependencies... ✓
       ✓ Installing Firebase CLI... ✓
       ⚠️  GoogleService-Info.plist not found → See setup instructions
       
4. Configure Firebase (10-step checklist)
   └─ Follow instructions to create GoogleService-Info.plist from template
   └─ Validate: npm run validate:config
   
5. Open Xcode and build
   └─ npm run open:xcode
   └─ Cmd+R to build and run
   └─ App launches in simulator ✅
   
6. Start Cloud Functions locally (optional, for backend work)
   └─ npm run dev
   └─ Firebase emulators start with clear URLs
```

### Visual Behavior

- **Setup script output**: Use ✓ (green), ⚠️ (yellow), ✗ (red) for clear status
- **README structure**: Logical sections with expandable details (using markdown details/summary)
- **Code blocks**: Every command is copy-pasteable with bash syntax highlighting
- **Environment files**: Side-by-side comparison of template vs filled example (with fake data)

### Loading/Error States

| State | User Experience |
|-------|----------------|
| **Checking prerequisites** | Script shows progress: "Checking Node.js... ✓" |
| **Missing dependency** | Clear error: "✗ Xcode not found. Install from App Store: [link]" |
| **Invalid config** | Validation error: "GoogleService-Info.plist missing PROJECT_ID. See line 29." |
| **Setup complete** | Success summary: "✓ Setup complete! Run 'npm run open:xcode' to start." |

### Performance Targets

See targets in `MessageAI/agents/shared-standards.md` for reference:
- **Script execution time**: < 5 minutes for dependency installation
- **Validation checks**: < 10 seconds for config file validation
- **Documentation load time**: README renders instantly in GitHub/text editor

---

## 7. Functional Requirements (Must/Should)

### MUST: Core Setup

- **MUST: One-Command Dependency Installation**
  - Single npm script installs all dependencies (Node.js packages, Firebase CLI, checks Xcode)
  - Script validates prerequisites before proceeding
  - Clear progress indicators and error messages
  - [Gate] Running `npm run setup` on clean system installs all dependencies without manual intervention

- **MUST: Environment Templates**
  - Template files for all required secrets (GoogleService-Info.plist, .env files)
  - Clear placeholder syntax: `REPLACE_WITH_YOUR_API_KEY`
  - Inline comments explain where to get each credential
  - [Gate] Developer can create valid config files by following template instructions without external help

- **MUST: Configuration Validation**
  - Script validates all config files have required fields
  - Reports specific missing/invalid values with line numbers
  - Prevents app launch with invalid configuration
  - [Gate] Running `npm run validate:config` catches 100% of common config errors

- **MUST: README with Quick Start**
  - "Getting Started in 10 Minutes" section at top
  - Clear prerequisites checklist with install links
  - Step-by-step setup instructions with expected outcomes
  - [Gate] New developer can complete setup by following README alone

### MUST: Troubleshooting

- **MUST: Common Issues Documentation**
  - Dedicated "Troubleshooting" section in README
  - Solutions for 10+ most common setup issues (Firebase config errors, build failures, etc.)
  - "Can't find your issue?" section with links to team support
  - [Gate] 95% of setup issues have documented solutions

- **MUST: System Requirements**
  - Clear minimum versions (Node 18+, Xcode 15+, macOS Monterey+)
  - Hardware requirements (M1/M2 vs Intel compatibility)
  - Disk space requirements (Xcode ~40GB, dependencies ~2GB)
  - [Gate] Developer knows if their system is compatible before starting

### SHOULD: Developer Experience

- **SHOULD: Architecture Documentation**
  - High-level architecture diagram showing iOS app → Firebase → Cloud Functions flow
  - File structure explanation (what goes where)
  - Data model overview (Firestore collections, key relationships)
  - [Gate] New developer understands codebase structure within 15 minutes of reading

- **SHOULD: Development Scripts**
  - `npm run dev` - Start Firebase emulators
  - `npm run open:xcode` - Open Xcode project
  - `npm run test:all` - Run all tests (iOS + Cloud Functions)
  - `npm run validate:config` - Check config files
  - [Gate] Common development tasks have single-command shortcuts

- **SHOULD: Environment Setup Verification**
  - Automated test that validates entire setup
  - Checks: dependencies installed, config files present, Xcode builds successfully
  - Generates setup report: "✓ iOS ready, ⚠️ Cloud Functions need config"
  - [Gate] Developer can verify setup completion with one command

### Acceptance Gates Summary

- [Gate] **10-Minute Setup**: Fresh developer completes setup from git clone to app launch in < 10 minutes
- [Gate] **Zero Config Guesswork**: All templates have clear instructions; 0 developers ask "where do I get this?"
- [Gate] **One-Command Install**: `npm run setup` completes 80%+ of installation steps
- [Gate] **Validation Works**: `npm run validate:config` catches all common config errors
- [Gate] **Troubleshooting Coverage**: 95% of setup issues have documented solutions
- [Gate] **Cross-System**: Setup succeeds on Intel Mac, M1/M2 Mac, and 2+ macOS versions

---

## 8. Data Model

No database changes required. This PR only modifies documentation and setup scripts.

### New Files Created

```
Root Directory:
├── setup.sh                     # One-command setup script
├── validate-config.sh           # Config validation script
├── README.md                    # Enhanced with comprehensive setup guide
├── SETUP.md                     # Detailed setup guide (if README becomes too long)
├── .env.template                # Root environment template
└── TROUBLESHOOTING.md           # Comprehensive troubleshooting guide

MessageAI/:
└── MessageAI/
    └── GoogleService-Info.template.plist  (already exists, may enhance)

functions/:
├── .env.template                # Cloud Functions environment template
└── README.md                    # Enhanced with setup instructions (already exists)

docs/:
├── setup/
│   ├── ios-setup.md             # iOS-specific setup
│   ├── firebase-setup.md        # Firebase configuration guide
│   ├── cloud-functions-setup.md # Backend setup
│   └── screenshots/             # Setup screenshots (optional)
└── architecture.md              # (already exists, may enhance)
```

---

## 9. API / Service Contracts

No service layer changes required. This PR focuses on documentation and developer tooling.

### New NPM Scripts (package.json)

```json
{
  "scripts": {
    "setup": "./setup.sh",
    "validate:config": "./validate-config.sh",
    "open:xcode": "open MessageAI/MessageAI.xcodeproj",
    "dev": "firebase emulators:start",
    "dev:functions": "firebase emulators:start --only functions",
    "test:all": "npm run test:ios && npm run test:functions",
    "test:ios": "xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 15'",
    "test:functions": "cd functions && npm test",
    "deploy:dev": "firebase use dev && firebase deploy",
    "deploy:prod": "firebase use production && firebase deploy"
  }
}
```

### Bash Script Contracts

**setup.sh**
```bash
#!/bin/bash
# One-command setup script
# Usage: npm run setup
# Returns: 0 on success, 1 on failure
# Side effects: Installs dependencies, creates config templates
```

**validate-config.sh**
```bash
#!/bin/bash
# Config validation script
# Usage: npm run validate:config
# Returns: 0 if valid, 1 if errors found
# Output: List of missing/invalid config values
```

---

## 10. UI Components to Create/Modify

No UI changes required. This PR is documentation and tooling only.

---

## 11. Integration Points

### External Tools
- **Firebase CLI**: Installation and configuration
- **Node.js/npm**: Version checking and package installation
- **Xcode**: Build and run verification
- **Git**: Pre-commit hooks already configured

### Configuration Files
- **GoogleService-Info.plist**: iOS Firebase configuration
- **functions/.env**: Cloud Functions environment variables
- **.firebaserc**: Firebase project configuration
- **firebase.json**: Firebase services configuration

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

### Happy Path

- [ ] **Fresh Mac Setup**
  - Test Gate: Clone repo on clean Mac → Run setup → App launches in < 10 minutes
  - Test Gate: Zero manual interventions needed after running setup script
  
- [ ] **Configuration Creation**
  - Test Gate: Developer follows template instructions → Creates valid GoogleService-Info.plist
  - Test Gate: Validation script detects no errors
  
- [ ] **iOS Build Success**
  - Test Gate: Open Xcode → Select simulator → Cmd+R → App launches successfully
  - Test Gate: No build errors or warnings (except optional SwiftLint warnings)
  
- [ ] **Cloud Functions Local Dev**
  - Test Gate: Run `npm run dev` → Emulators start → Logs show "All emulators started"
  - Test Gate: Can call Cloud Function from iOS app running in simulator

### Edge Cases

- [ ] **Missing Dependencies**
  - Test Gate: Remove Node.js → Run setup → Clear error: "Node.js not found. Install from: [link]"
  - Test Gate: Setup script exits gracefully with instructions
  
- [ ] **Invalid Configuration**
  - Test Gate: Leave placeholder in GoogleService-Info.plist → Run validation → Error shows line number
  - Test Gate: Fix placeholder → Run validation → ✓ Configuration valid
  
- [ ] **Partial Setup**
  - Test Gate: Setup interrupted halfway → Re-run setup → Continues from last successful step
  - Test Gate: No duplicate installations or errors
  
- [ ] **Returning Developer**
  - Test Gate: Pull latest code with new dependencies → Run setup → Only installs new packages
  - Test Gate: Existing config preserved (no overwrite)

### Cross-System Testing

- [ ] **Intel Mac (x86)**
  - Test Gate: Setup completes successfully on Intel Mac running macOS Monterey
  - Test Gate: All npm packages install correctly (Rosetta not needed)
  
- [ ] **M1/M2 Mac (ARM)**
  - Test Gate: Setup completes successfully on Apple Silicon Mac
  - Test Gate: Xcode builds without architecture warnings
  
- [ ] **macOS Versions**
  - Test Gate: Setup works on macOS Monterey (12.x)
  - Test Gate: Setup works on macOS Ventura (13.x)
  - Test Gate: Setup works on macOS Sonoma (14.x)

### Documentation Testing

- [ ] **README Clarity**
  - Test Gate: 3 new developers follow README independently → All complete setup without help
  - Test Gate: Zero "what does this mean?" questions
  
- [ ] **Troubleshooting Coverage**
  - Test Gate: Simulate 10 common errors → All have documented solutions in TROUBLESHOOTING.md
  - Test Gate: Solutions resolve 100% of simulated issues
  
- [ ] **Link Validation**
  - Test Gate: All external links (Firebase console, OpenAI, Pinecone) are valid and load
  - Test Gate: All internal file references exist

### Performance

See shared-standards.md for performance requirements.

- [ ] **Setup Script Speed**
  - Test Gate: Setup script completes in < 5 minutes (excluding Xcode install time)
  - Test Gate: Validation script completes in < 10 seconds
  
- [ ] **Documentation Load**
  - Test Gate: README.md renders instantly on GitHub
  - Test Gate: All images/screenshots load in < 2 seconds

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:

### Documentation
- [ ] README.md has "10-Minute Quick Start" section
- [ ] All setup steps documented with expected outcomes
- [ ] TROUBLESHOOTING.md covers 10+ common issues
- [ ] Architecture documentation shows system overview
- [ ] All external links validated and working

### Scripts
- [ ] `setup.sh` implemented and tested on 3+ Mac configurations
- [ ] `validate-config.sh` catches all common config errors
- [ ] All npm scripts work and are documented
- [ ] Scripts have proper error handling and exit codes

### Templates
- [ ] GoogleService-Info.template.plist has clear placeholders
- [ ] functions/.env.template documents all required variables
- [ ] All templates have inline comments explaining values

### Testing
- [ ] Setup tested on fresh Mac (Intel + M1/M2)
- [ ] Setup tested on 2+ macOS versions
- [ ] 3 new developers complete setup without help
- [ ] All troubleshooting solutions verified to work

### Validation
- [ ] Config validation catches missing Firebase credentials
- [ ] Config validation catches missing OpenAI/Pinecone keys
- [ ] Config validation provides helpful error messages
- [ ] Zero false positives or false negatives

---

## 14. Risks & Mitigations

### Risk: Different Mac Configurations
**Impact**: Setup script might fail on Intel vs M1/M2 Macs, or different macOS versions  
**Likelihood**: Medium  
**Mitigation**:
- Test on 3+ different Mac configurations before merging
- Add system detection to setup script (check architecture and macOS version)
- Document known compatibility issues in README

### Risk: External Service Changes
**Impact**: Firebase/OpenAI/Pinecone signup process changes, breaking setup instructions  
**Likelihood**: Low  
**Mitigation**:
- Link to official docs instead of duplicating instructions where possible
- Add "Last Updated" date to setup guide
- Quarterly review of setup instructions to catch UI changes

### Risk: Missing Edge Cases
**Impact**: Developer encounters issue not covered in troubleshooting guide  
**Likelihood**: Medium  
**Mitigation**:
- Add "Report Setup Issue" link in TROUBLESHOOTING.md
- Log all setup support requests to identify gaps
- Update troubleshooting guide monthly based on real developer issues

### Risk: Setup Script Fails Silently
**Impact**: Developer thinks setup succeeded but has invalid configuration  
**Likelihood**: Low  
**Mitigation**:
- Add validation step at end of setup script
- Require developer to run validation before first build
- Add health check command: `npm run health-check`

### Risk: Documentation Becomes Outdated
**Impact**: Instructions refer to old file paths, removed features, or deprecated APIs  
**Likelihood**: Medium  
**Mitigation**:
- Add TODO item in every PR: "Update setup docs if applicable"
- Automated link checker runs weekly (can be added in PR #9)
- Version documentation (add "Last Updated: PR #X" to each doc)

---

## 15. Rollout & Telemetry

### Rollout Strategy

This is a documentation PR with no code changes to the app itself, so rollout is straightforward:

1. **Phase 1 (Week 1)**: Merge PR to develop branch
2. **Phase 2 (Week 1)**: Test setup with 1-2 internal team members
3. **Phase 3 (Week 2)**: Invite external developer to test setup and collect feedback
4. **Phase 4 (Week 2)**: Iterate on documentation based on feedback
5. **Phase 5 (Week 3)**: Merge to main branch, consider setup documentation complete

### Success Metrics Collection

**How to Measure**:
- **Time to first app launch**: Ask 5 new developers to time their setup from git clone to app launch
- **Setup success rate**: Track how many developers complete setup without asking for help (5/5 = 100%)
- **Troubleshooting coverage**: Log all setup issues reported; calculate % that have documented solutions

**Manual Validation Steps**:
1. Give setup instructions to developer unfamiliar with project
2. Observe their process (note points of confusion)
3. Time each major setup phase (clone → dependencies → config → build)
4. Document any issues encountered
5. Update documentation to address issues
6. Repeat with next developer until 95%+ success rate

### Monitoring

**Documentation Analytics** (optional, GitHub provides these):
- README.md page views
- Documentation click-through rates
- Most visited troubleshooting sections

**Support Metrics**:
- Number of setup-related questions (goal: <5% of new developers)
- Time spent on setup support (goal: <30 minutes per developer)

---

## 16. Open Questions

### Q1: Should we provide pre-configured Firebase project for testing?
**Decision Needed**: Create shared "messageai-dev" Firebase project vs require each developer to create their own  
**Tradeoff**: Easier setup vs potential quota/abuse issues  
**Recommendation**: Start with individual projects, add shared dev project if quota is an issue  
**Owner**: Claudia Alban

### Q2: Should we automate Xcode project setup (e.g., auto-add files to Xcode project)?
**Decision Needed**: Manually update Xcode project file vs script-based file addition  
**Tradeoff**: Automation complexity vs manual maintenance  
**Recommendation**: Keep manual for now; Xcode project structure is stable  
**Owner**: Development Team

### Q3: Should we use Docker/Dev Containers for Cloud Functions development?
**Decision Needed**: Native Node.js + Firebase CLI vs Dev Container with all dependencies  
**Tradeoff**: Setup complexity vs reproducibility  
**Recommendation**: Native for now; Dev Containers in Phase 3 if team grows  
**Owner**: Backend Developer

### Q4: Should we create video walkthrough of setup process?
**Decision Needed**: Text-only instructions vs video supplement  
**Tradeoff**: Production time vs learning style coverage  
**Recommendation**: Text for PR #8; consider video for PR #9 (Deployment) if time permits  
**Owner**: Claudia Alban

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:

- [ ] **Automated environment switching** (dev/staging/prod) - Future PR
- [ ] **CI/CD pipeline documentation** - Separate PR (post-Phase 2)
- [ ] **Dev Container configuration** - Phase 3 if team grows
- [ ] **Video setup tutorials** - Post-Phase 2 if time permits
- [ ] **Automated dependency updates** (Dependabot, Renovate) - Phase 3
- [ ] **Setup telemetry** (track setup success rates automatically) - Phase 4
- [ ] **One-click cloud deployment** (deploy to Firebase with single command) - PR #9
- [ ] **Development environment health monitoring** - Phase 3

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**  
   New developer clones repo → runs one command → has working environment in < 10 minutes

2. **Primary user and critical action?**  
   New developer setting up MessageAI for first time; critical action: running setup script successfully

3. **Must-have vs nice-to-have?**  
   Must-have: one-command setup, templates, README. Nice-to-have: automated validation, detailed troubleshooting, architecture docs

4. **Real-time requirements?**  
   N/A - This is documentation and setup tooling

5. **Performance constraints?**  
   Setup script < 5 minutes execution time. Validation < 10 seconds.

6. **Error/edge cases to handle?**  
   Missing dependencies, invalid config, partial setup, different Mac architectures, macOS version compatibility

7. **Data model changes?**  
   None

8. **Service APIs required?**  
   None

9. **UI entry points and states?**  
   Terminal/command-line output. Documentation rendering in GitHub/text editors.

10. **Security/permissions implications?**  
    Must NOT include actual API keys or secrets in templates. All sensitive values must be placeholders.

11. **Dependencies or blocking integrations?**  
    Depends on PR #6 (security audit to ensure GoogleService-Info.plist not committed) and PR #7 (auth polish)

12. **Rollout strategy and metrics?**  
    Documentation PR; test with 3-5 new developers, iterate based on feedback, measure setup time and success rate

13. **What is explicitly out of scope?**  
    CI/CD automation, Docker/Dev Containers, video tutorials, automated telemetry, Xcode automation

---

## Authoring Notes

- Write Test Plan before coding
- Focus on developer experience: clear, concise, actionable instructions
- Test setup on fresh Mac (borrow friend's Mac if needed)
- Keep documentation up-to-date as project evolves
- Reference `MessageAI/agents/shared-standards.md` for common patterns
- Remember: Great documentation is code too - it enables team velocity

---

**PRD Status**: ✅ Ready for Review  
**Next Step**: User approval → Create TODO checklist  
**Estimated Implementation Time**: 4-6 hours (mostly documentation and scripting)


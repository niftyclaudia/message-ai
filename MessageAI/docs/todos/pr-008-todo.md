# PR-008 TODO — Repository Setup & Documentation

**Branch**: `feat/pr-008-repository-setup`  
**Source PRD**: `MessageAI/docs/prds/pr-008-prd.md`  
**Owner (Agent)**: Cody

---

## 0. Assumptions

- Individual Firebase projects (not shared dev project)
- Text-only documentation (no video tutorials)
- macOS required for iOS development
- Xcode installed manually (too large for automation)

---

## 1. Setup

- [ ] Create branch `feat/pr-008-repository-setup` from develop
- [ ] Read PRD thoroughly (`MessageAI/docs/prds/pr-008-prd.md`)
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Audit existing documentation (README.md, functions/README.md)

---

## 2. Environment Templates

- [ ] Create `.env.template` in root (Node.js version, Firebase project)
- [ ] Enhance `functions/.env.template` with OPENAI_API_KEY, PINECONE_API_KEY, PINECONE_ENVIRONMENT, PINECONE_INDEX + inline comments
- [ ] Verify `MessageAI/MessageAI/GoogleService-Info.template.plist` has clear REPLACE_WITH_YOUR_* placeholders

---

## 3. Setup Script

- [ ] Create `setup.sh` with bash shebang, `set -e`, color output (✓ ⚠️ ✗)
- [ ] Add prerequisite checks:
  - macOS version (min Monterey 12.0)
  - Xcode installation (`xcode-select -p`)
  - Node.js version (min 18.0)
  - Architecture detection (Intel vs M1/M2)
- [ ] Add dependency installation:
  - Root npm packages (`npm install`)
  - Firebase CLI globally (if missing)
  - Cloud Functions packages (`cd functions && npm install`)
- [ ] Add configuration checks:
  - GoogleService-Info.plist (warn if missing)
  - functions/.env (warn if missing, optional)
- [ ] Add setup summary showing success/warnings and next steps (exit 0 if warnings OK, exit 1 if critical errors)

---

## 4. Configuration Validation Script

- [ ] Create `validate-config.sh` with bash shebang and error handling
- [ ] Validate GoogleService-Info.plist:
  - Check file exists
  - Detect placeholder values (`REPLACE_WITH_YOUR_`)
  - Validate required fields (PROJECT_ID, API_KEY, GCM_SENDER_ID, APP_ID, STORAGE_BUCKET, CLIENT_ID)
- [ ] Validate functions/.env (if present): warn about missing OPENAI_API_KEY, PINECONE_API_KEY, etc.
- [ ] Print validation summary with error count and suggested fixes

---

## 5. NPM Scripts

- [ ] Update `package.json` with scripts: setup, validate:config, open:xcode, dev, dev:functions, test:all, test:ios, test:functions, health-check
- [ ] Test all scripts work: setup installs deps, validate detects config issues, open:xcode opens project, dev starts emulators, test:all runs tests

---

## 6. Enhanced README

- [ ] Add "🚀 Quick Start (10 Minutes)" section with 5 numbered steps: Prerequisites, Clone, Setup, Configure, Build
- [ ] Add prerequisites checklist: macOS Monterey+, Xcode 15.0+, Node.js 18.0+, npm 9.0+, Git (with install links)
- [ ] Document setup steps:
  - Clone repo and cd into directory
  - Run `npm run setup` with explanation
  - Firebase configuration (copy template → get credentials → replace placeholders → validate)
  - Cloud Functions setup (optional, link to functions/README.md)
- [ ] Document first build: `npm run open:xcode` → Cmd+R in simulator
- [ ] Add development workflow section with npm scripts table and Firebase emulator usage
- [ ] Add architecture overview with system diagram and file structure (link to architecture.md)

---

## 7. Troubleshooting Guide

- [ ] Create `TROUBLESHOOTING.md` with table of contents
- [ ] Document Firebase issues (3):
  - GoogleService-Info.plist not found → copy template
  - Firebase config invalid → run validate:config
  - Firebase auth failed → re-download from console
- [ ] Document build issues (3):
  - CodeSign failed → sign in with Apple ID
  - Module 'Firebase' not found → reset package caches
  - Linker errors → clean build folder
- [ ] Document Cloud Functions issues (3):
  - Emulators won't start → kill ports or change ports
  - OpenAI API key invalid → regenerate key
  - Pinecone connection failed → verify API key
- [ ] Document system issues (3):
  - Xcode not found → install from App Store
  - Node.js too old → install 18+ or use nvm
  - Permission denied → chmod +x scripts
- [ ] Add "Getting Help" section with support resources

---

## 8. Documentation Polish

### 8.1 Add Screenshots/Examples

- [ ] Add example GoogleService-Info.plist (with fake data)
  - Show side-by-side: template vs filled example
  - Clearly mark example data as EXAMPLE ONLY
  - Test Gate: Example is helpful, not confusing

- [ ] Add example .env file (with fake data)
  - Show what completed .env should look like
  - Mark all values as examples
  - Test Gate: Example is clear

### 8.2 Update Existing Documentation

- [ ] Review and update `functions/README.md`
  - Already comprehensive (from PR-AI-001)
  - Add links to main README setup section
  - Ensure consistency with new setup instructions
  - Test Gate: No conflicting information

- [ ] Review and update `MessageAI/docs/architecture.md`
  - Already comprehensive
  - Verify file paths are still accurate
  - Add "Last Updated: PR #008" note
  - Test Gate: Architecture doc is accurate

### 8.3 Add Visual Aids

- [ ] Create setup flow diagram (text-based)
  ```
  git clone → npm run setup → Configure Firebase → npm run validate:config → npm run open:xcode → Build & Run ✅
  ```
  - Test Gate: Flow is clear and easy to follow

- [ ] Add success indicators throughout README
  - Use ✅ for completed steps
  - Use ⚠️ for important warnings
  - Use 🚀 for quick start sections
  - Test Gate: Visual indicators improve readability

---

## 9. Testing

### 9.1 Fresh Mac Setup Testing

- [ ] Test on Intel Mac (if available)
  - Clone repo on fresh/clean system
  - Run setup script
  - Time the setup process
  - Document any issues
  - Test Gate: Setup completes in < 10 minutes on Intel Mac

- [ ] Test on M1/M2 Mac
  - Clone repo on fresh/clean system
  - Run setup script
  - Time the setup process
  - Document any issues
  - Test Gate: Setup completes in < 10 minutes on Apple Silicon Mac

- [ ] Test on different macOS versions
  - Test on macOS Monterey (12.x) if possible
  - Test on macOS Ventura (13.x) if possible
  - Test on macOS Sonoma (14.x) primary development machine
  - Test Gate: Setup works on 2+ macOS versions

### 9.2 Configuration Validation Testing

- [ ] Test validation with valid configuration
  - Create proper GoogleService-Info.plist
  - Run `npm run validate:config`
  - Test Gate: Shows "✓ Configuration valid"

- [ ] Test validation with missing file
  - Remove GoogleService-Info.plist
  - Run validation
  - Test Gate: Shows clear error with solution

- [ ] Test validation with placeholder values
  - Leave "REPLACE_WITH_YOUR_PROJECT_ID" in file
  - Run validation
  - Test Gate: Detects placeholder and shows line number

- [ ] Test validation with partial configuration
  - Remove one required field
  - Run validation
  - Test Gate: Detects missing field

### 9.3 Script Testing

- [ ] Test setup script error handling
  - Simulate missing Node.js (temporarily rename node)
  - Run setup script
  - Test Gate: Shows helpful error, exits gracefully

- [ ] Test setup script idempotency
  - Run setup twice in a row
  - Test Gate: Second run completes without errors, doesn't duplicate work

- [ ] Test all npm scripts
  - Run each script from package.json
  - Test Gate: All scripts work as documented

### 9.4 Documentation Testing

- [ ] Test with 3 new developers (simulated or real)
  - Give only the README
  - Observe their setup process
  - Note points of confusion
  - Time their setup
  - Test Gate: 3/3 developers complete setup without asking for help

- [ ] Validate all links in documentation
  - Check all external links (Firebase Console, OpenAI, Pinecone)
  - Check all internal file references
  - Test Gate: 100% of links are valid

- [ ] Test troubleshooting solutions
  - Simulate each documented issue
  - Follow documented solution
  - Test Gate: Solutions resolve 100% of documented issues

### 9.5 Edge Case Testing

- [ ] Test partial setup recovery
  - Interrupt setup script halfway through
  - Re-run setup
  - Test Gate: Setup continues/recovers gracefully

- [ ] Test with existing configuration
  - Already have GoogleService-Info.plist
  - Run setup
  - Test Gate: Doesn't overwrite existing config

- [ ] Test without optional dependencies
  - Don't create functions/.env (AI features)
  - Run setup and validation
  - Test Gate: Warns but doesn't fail; iOS app still works

---

## 10. Documentation Updates

### 10.1 Update Related Documentation

- [ ] Add "Last Updated: PR #008" to modified docs
  - README.md
  - functions/README.md
  - TROUBLESHOOTING.md (new)
  - Test Gate: All modified docs have update notation

- [ ] Update architecture.md if needed
  - Verify file structure is accurate
  - Update if new directories added
  - Test Gate: Architecture doc matches actual structure

### 10.2 Add Setup Checklist for PRs

- [ ] Create PR template reminder (optional)
  - Add note: "If you added new dependencies or config, update setup docs"
  - Test Gate: Future PRs will remember to update documentation

---

## 11. Acceptance Gates

Check every gate from PRD Section 12:

### Happy Path Gates
- [ ] **10-Minute Setup**: Fresh developer completes setup from git clone to app launch in < 10 minutes
- [ ] **Zero Config Guesswork**: All templates have clear instructions; 0 developers ask "where do I get this?"
- [ ] **One-Command Install**: `npm run setup` completes 80%+ of installation steps
- [ ] **Validation Works**: `npm run validate:config` catches all common config errors

### Edge Case Gates
- [ ] **Missing Dependencies**: Setup script shows helpful error for missing Node.js/Xcode
- [ ] **Invalid Configuration**: Validation detects placeholder values and shows line numbers
- [ ] **Partial Setup**: Setup can be interrupted and re-run successfully

### Cross-System Gates
- [ ] **Intel Mac**: Setup completes successfully on x86 Mac
- [ ] **M1/M2 Mac**: Setup completes successfully on ARM Mac
- [ ] **macOS Versions**: Setup works on 2+ macOS versions

### Documentation Gates
- [ ] **README Clarity**: 3 new developers follow README independently without help
- [ ] **Troubleshooting Coverage**: 95% of setup issues have documented solutions
- [ ] **Link Validation**: All external and internal links are valid

---

## 12. PR Creation

### 12.1 Create PR Description

- [ ] Write comprehensive PR description
  - Title: "PR #008: Repository Setup & Documentation"
  - Summary: Quick start guide and automated setup
  - Changes: List all new files and major updates
  - Testing: Describe testing performed (3 systems, X developers)
  - Screenshots: Terminal output from setup script, validation results
  - Test Gate: PR description is comprehensive

### 12.2 Link Documentation

- [ ] Link PRD and TODO in PR description
  - PRD: `MessageAI/docs/prds/pr-008-prd.md`
  - TODO: `MessageAI/docs/todos/pr-008-todo.md`
  - Test Gate: Links work in PR description

### 12.3 PR Checklist

- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Setup script tested on 3+ Mac configurations
- [ ] Configuration validation catches all common errors
- [ ] README has comprehensive quick start section
- [ ] TROUBLESHOOTING.md documents 10+ common issues
- [ ] All npm scripts work and are documented
- [ ] Templates have clear placeholders and instructions
- [ ] 3 developers completed setup without help
- [ ] All acceptance gates pass
- [ ] All external links validated
- [ ] Code follows shared-standards.md patterns
- [ ] No sensitive data in templates
- [ ] Documentation updated

### 12.4 Verify with User

- [ ] Ask user to review PR before creating
  - Show summary of changes
  - Confirm all goals met
  - Address any concerns
  - Test Gate: User approves PR creation

### 12.5 Create PR

- [ ] Open PR targeting develop branch
  - Base: `develop`
  - Compare: `feat/pr-008-repository-setup`
  - Reviewers: Add relevant team members
  - Labels: documentation, setup, phase-2
  - Test Gate: PR created successfully

---

## Notes

### Task Organization
- Tasks grouped by logical sections (Templates → Scripts → README → Testing)
- Each task < 30 minutes
- Clear acceptance criteria for each task
- Sequential where dependencies exist

### Key Deliverables
1. **setup.sh** - Automated dependency installation
2. **validate-config.sh** - Configuration validation
3. **Enhanced README.md** - Quick start guide
4. **TROUBLESHOOTING.md** - Comprehensive troubleshooting
5. **Environment templates** - All secrets documented

### Testing Priority
1. Fresh Mac setup (most important gate)
2. Configuration validation (catches 95% of issues)
3. Developer testing (3 real developers)
4. Cross-system compatibility (Intel + M1/M2)

### Success Metrics
- ✅ Setup time < 10 minutes
- ✅ 95%+ success rate without help
- ✅ 100% of links valid
- ✅ 100% of troubleshooting solutions work

---

**TODO Status**: ✅ Complete and Ready for Implementation  
**Estimated Time**: 4-6 hours  
**Next Step**: Begin implementation with Section 1 (Setup)


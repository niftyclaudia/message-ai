# PR-16 TODO — Bug Fixing & UI Polish (MVP)

**Branch**: `polish/pr-16-production-ready`  
**Source PRD**: `MessageAI/docs/prds/pr-16-prd.md`  
**Owner (Agent)**: Cody  
**Dependencies**: ALL PRs (#1-15)

**MVP FOCUS:** Critical bugs, core polish, production ready. Defer nice-to-haves.

---

## 0. Setup

- [ ] Pull latest develop, create branch, verify app builds
- [ ] Run existing test suite to establish baseline
- [ ] Create simple `bug-tracker.md` for findings
  - Test Gate: Setup complete, baseline established

---

## 1. Critical Bug Hunt - Core Flows Only

**Focus: Happy path + obvious edge cases. Test what will break in production.**

- [ ] **Authentication Critical Tests**
  - Signup with valid/invalid inputs
  - Login with valid/invalid credentials
  - Logout and auth persistence
  - Test Gate: Auth flows work, no crashes

- [ ] **Messaging Critical Tests (1-on-1)**
  - Send/receive messages (both devices online)
  - Offline send → online sync
  - Rapid messages (10+ quick sends)
  - Long messages, emojis, special characters
  - Test Gate: Core messaging works reliably

- [ ] **Group Chat Critical Tests**
  - Create group, send messages
  - **CRITICAL:** Verify sender NOT notified (test with 2 devices)
  - All group members receive messages
  - Test Gate: Groups work, no self-notifications

- [ ] **Notifications Critical Tests**
  - Foreground: banner displays, tap navigates
  - Background: notification appears, tap opens chat
  - Terminated: cold start from notification
  - Test Gate: Notifications work in all app states

- [ ] **Navigation & State Critical Tests**
  - Navigate between all main screens
  - Deep link from notification
  - App backgrounding/foregrounding
  - Test Gate: Navigation smooth, no dead ends

- [ ] Document all bugs found in `bug-tracker.md` with priority (P0/P1/P2)
  - Test Gate: All critical bugs documented

---

## 2. Fix P0 (Critical) Bugs Only

- [ ] Review bug tracker, identify P0 bugs (crashes, data loss, auth failures)
- [ ] Fix each P0 bug:
  - Reproduce → Fix → Test → Verify no regression
- [ ] Re-test affected flows after fixes
  - Test Gate: 0 P0 bugs remaining

---

## 3. Fix P1 (High) Bugs - Time Permitting

- [ ] Review bug tracker, identify P1 bugs (major UX issues, performance problems)
- [ ] Fix P1 bugs if time allows
- [ ] Document any unfixed P1 bugs in `known-issues.md` for backlog
  - Test Gate: P1 bugs either fixed or documented

---

## 4. UI Polish - Quick Wins Only

**Focus: Consistency, not perfection. Make it look professional.**

- [ ] **Visual Consistency Sweep**
  - Verify spacing consistent (use 16pt standard)
  - Fix any obvious color inconsistencies
  - Check dark mode doesn't look broken
  - Test Gate: UI looks professional and consistent

- [ ] **State Polish**
  - Add/improve empty states (empty chat list, no messages)
  - Verify loading states show (not blank screens)
  - Make error messages user-friendly (remove technical jargon)
  - Test Gate: All states have proper UI

- [ ] **Animation Quick Check**
  - Verify animations smooth (not janky)
  - Fix any obvious animation bugs
  - Test Gate: Animations acceptable

---

## 5. Performance Validation - Basic Checks

**Focus: Meet minimum targets, not perfection.**

- [ ] **Measure Critical Metrics** (3 runs each, take average)
  - Cold start time: Target <3s (acceptable for MVP)
  - Message send: Target <200ms (acceptable for MVP)
  - Scrolling: No obvious lag with 100+ messages
  - Test Gate: Performance acceptable for MVP

- [ ] **Quick Optimization** (only if targets missed badly)
  - Use LazyVStack for long lists
  - Fix any obvious performance bugs
  - Test Gate: Performance good enough to ship

---

## 6. Code Cleanup - Remove Debug Code

**Critical for production - must do this.**

- [ ] **Search and Remove Debug Code**
  - Search for: `print(`, `debugPrint(`, `dump(`
  - Remove all debug print statements
  - Test Gate: No print statements in code

- [ ] **Remove Test/Development Code**
  - Remove commented-out code blocks
  - Remove any test data seeding
  - Remove mock services if any in production paths
  - Test Gate: Clean production code

- [ ] **Fix Compiler Warnings**
  - Build project, fix yellow warnings
  - Target: 0 warnings (or document why they're okay)
  - Test Gate: Clean build

- [ ] **Security Check**
  - Verify no hardcoded API keys or secrets
  - Verify Firebase security rules production-ready
  - Test Gate: No security issues

---

## 7. Essential Testing

- [ ] **Run Automated Test Suite**
  - Run all existing tests
  - Fix any broken tests (or remove if no longer valid)
  - Test Gate: Test suite passing

- [ ] **Manual End-to-End Test**
  - Complete user journey: Signup → Create chat → Send messages → Notifications
  - Test on 2 physical devices simultaneously
  - Test Gate: Core journey works end-to-end

- [ ] **Multi-Device Sync Test**
  - Device A sends message → Device B receives <2s
  - Test in foreground, background, terminated states
  - Test Gate: Multi-device works reliably

---

## 8. Accessibility - Minimum Viable

**Focus: Don't break accessibility, basic compliance.**

- [ ] **Quick VoiceOver Test**
  - Enable VoiceOver
  - Navigate: Login → Chat List → Chat View
  - Fix any obvious issues (missing labels, can't navigate)
  - Test Gate: Basic VoiceOver navigation works

- [ ] **Dynamic Type Check**
  - Test with larger text size
  - Fix any text clipping or layout breaking
  - Test Gate: Large text doesn't break UI

---

## 9. App Store Basics

- [ ] **Required Info**
  - Verify privacy policy linked (Settings screen)
  - Verify notification permission description in Info.plist
  - Test Gate: Required info present

- [ ] **Test on Minimum iOS Version**
  - Test on iOS 15 device/simulator (if that's your min target)
  - Fix any compatibility issues
  - Test Gate: Works on minimum version

- [ ] **Device Size Check**
  - Test on iPhone SE (small), iPhone 14 (standard)
  - Fix any obvious layout issues
  - Test Gate: Works on different sizes

---

## 10. Documentation - Essentials Only

- [ ] **Bug Tracker Summary**
  - List of bugs found: P0 (fixed), P1 (fixed or deferred), P2/P3 (deferred)
  - Test Gate: Bug summary documented

- [ ] **Known Issues** (if any unfixed P1/P2 bugs)
  - Document user-facing issues that aren't fixed
  - Include workarounds if available
  - Test Gate: Known issues documented

- [ ] **Update README**
  - Project status, features list, setup instructions
  - Test Gate: README current

---

## 11. Final Validation

- [ ] **Run All Tests One Last Time**
  - Automated tests: passing
  - Manual core journey: working
  - Test Gate: Everything still works

- [ ] **Build Release Version**
  - Build in Release configuration
  - Test on device
  - Verify no debug behavior
  - Test Gate: Release build works

- [ ] **Final Checklist**
  - [ ] 0 P0 bugs
  - [ ] Critical flows tested and working
  - [ ] UI looks professional
  - [ ] No debug code in production
  - [ ] 0 compiler warnings (or documented)
  - [ ] Tests passing
  - [ ] Works on physical devices
  - [ ] Basic accessibility works
  - [ ] App Store basics complete
  - Test Gate: Ready for production

---

## 12. Handoff

- [ ] **Create PR**
  - Summary of work done
  - Bugs fixed
  - Known issues (if any)
  - Recommendation: Ready to ship or needs more work
  
- [ ] **Present to User**
  - What was fixed
  - What was tested
  - What's ready for App Store (or what's blocking)
  - Get approval before submitting to App Store

---

## MVP Success Criteria

**Ship when:**
- ✅ 0 P0 bugs (no crashes, no data loss)
- ✅ Core user journey works (signup → chat → notifications)
- ✅ UI looks professional (not perfect, but good)
- ✅ No debug code in production
- ✅ Tests passing
- ✅ Works on 2+ physical devices
- ✅ App Store basics met

**Defer to post-launch:**
- Advanced performance optimization
- P2/P3 bug fixes
- Advanced accessibility features
- Extensive edge case testing
- Perfect UI polish
- Analytics and monitoring

---

## Time Estimate

**MVP Focus: ~2-3 days of focused work**
- Day 1: Bug hunting + P0 fixes
- Day 2: UI polish + performance check + code cleanup
- Day 3: Testing + final validation

**Full comprehensive (original): ~2-3 weeks**

---

## Notes

- **MVP Philosophy:** Ship something good, not something perfect
- **P0 Only:** Only critical bugs must be fixed for launch
- **Document P1/P2:** Create backlog for post-launch improvements
- **Physical Devices:** Test on real iPhones for notifications
- **User Approval:** Don't submit to App Store without explicit approval
- **Iteration:** You can polish more after initial launch based on user feedback

---

## Quick Reference: What We're Skipping for MVP

❌ Exhaustive edge case testing  
❌ Comprehensive performance profiling  
❌ Advanced accessibility compliance  
❌ Stress testing (1000+ messages, 50+ chats)  
❌ Multiple iOS version testing  
❌ TestFlight beta testing  
❌ Advanced analytics setup  
❌ Perfect UI animations  
❌ Fixing every single P2/P3 bug  

✅ Focus: Core functionality works, looks good, ships fast

# PRD: Authentication & Data Management Polish

**Feature**: Authentication & Data Management Polish

**Version**: 2.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: Phase 2 - Technical Excellence

**Links**: [PR Brief: PR #007](../archive/postmvp/pr-briefs.md#pr-7-authentication--data-management-polish), [TODO: Coming After Review]

---

## 1. Summary

Verify and polish existing authentication and data management features to achieve bulletproof reliability before Phase 3 AI features. Focus on comprehensive edge case testing, real device validation, and performance measurement. **Most functionality already exists—we're ensuring it works flawlessly in all scenarios.**

---

## 2. Problem & Goals

- **Problem**: While core auth and sync features exist, we need comprehensive testing to ensure zero data loss, reliable multi-device sync, and robust password recovery under ALL conditions before adding AI complexity.

- **Why now**: Phase 2 is "Technical Excellence"—verify foundations are bulletproof before Phase 3. PR #6 established security; now we ensure reliability.

- **Goals**:
  - [ ] G1 — Verify password reset works in all scenarios (spam filters, offline, invalid emails, real device)
  - [ ] G2 — Verify profile editing handles edge cases (large photos, validation, conflicts, multi-device sync)
  - [ ] G3 — Verify offline cache survives force-quit, airplane mode, network drops with zero data loss
  - [ ] G4 — Achieve 95%+ test coverage with real device validation and documented performance

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing new features (password reset, profile editing already exist)
- [ ] Not changing UI design (only fixing bugs if found)
- [ ] Not adding biometric auth, email verification, or MFA (future PRs)
- [ ] Not refactoring architecture (only fixing issues if found)

---

## 4. Success Metrics

**User-visible:**
- Password reset completion rate > 95%
- Profile editing success rate > 99%
- Zero data loss incidents in testing

**System (verify Phase 1 targets):**
- Password reset email: < 30s delivery
- Profile save: < 2s
- Photo upload: < 5s (< 5MB images)
- Multi-device sync: < 100ms
- Offline sync: < 1s on reconnect
- Cache load: < 500ms

**Quality:**
- Test coverage increases from ~70% to 95%+
- All edge cases tested and documented
- Real device validation completed (2+ devices)

---

## 5. Users & Stories

- As a **user who forgot password**, I want reset to work reliably even with spam filters so I never lose account access
- As a **multi-device user**, I want profile changes to sync instantly and handle conflicts gracefully
- As a **mobile user with poor connectivity**, I want data to survive force-quits and network drops
- As a **developer building Phase 3**, I want comprehensive tests so I can build on a reliable foundation

---

## 6. Experience Specification (UX)

### What Already Works ✅

**Password Reset Flow (EXISTS):**
- LoginView → "Forgot Password?" link → ForgotPasswordView → Enter email → Send reset email → Browser reset → Sign in with new password

**Profile Edit Flow (EXISTS):**
- ProfileView → "Edit Profile" → Change name/photo → Character counter → Save → Multi-device sync

**Offline Cache (EXISTS):**
- Force-quit → Reopen → Full history preserved
- Offline mode → Messages queue → Auto-send on reconnect

### What This PR Verifies & Adds

**NEW: Verify ALL edge cases work:**
- Invalid email caught before Firebase call
- Spam filters don't block email (real device test)
- Large photos (> 5MB) compressed or clear error
- Validation prevents invalid inputs
- Multi-device sync timing measured (< 100ms)
- Force-quit scenarios tested thoroughly
- Performance targets verified and documented

**NO UI changes expected** - Bug fixes only if found

### Performance Targets (Verify from shared-standards.md)

- App load: < 2s
- Message delivery: p95 < 200ms
- Multi-device sync: < 100ms
- Offline sync: < 1s
- Password reset email: < 30s
- Profile save: < 2s
- Photo upload: < 5s (< 5MB)
- Cache load: < 500ms

---

## 7. Functional Requirements

### Password Reset - VERIFY + ADD EDGE CASES

**Existing (✅ Already Implemented):**
- `ForgotPasswordView.swift`, `AuthService.sendPasswordResetEmail()`, basic tests exist

**MUST Add:**
- Test invalid email format (catch before Firebase)
- Test offline mode error handling
- Test empty email validation
- Real device: Verify email arrives < 30s
- Real device: End-to-end password reset works

**Acceptance gates:**
- [Gate] Invalid email → Error before Firebase call
- [Gate] Valid email → Email arrives < 30s (real device)
- [Gate] Offline → Clear error message
- [Gate] Reset password → Sign in works

### Profile Editing - VERIFY + ADD EDGE CASES

**Existing (✅ Already Implemented):**
- `ProfileEditView.swift`, character counter, photo upload, validation exist

**MUST Add:**
- Test boundary values (0, 1, 50, 51 characters)
- Test large photos (> 5MB) handling
- Test simultaneous edits (conflict resolution)
- Real device: Measure multi-device sync < 100ms
- Verify save times < 2s, upload times < 5s

**Acceptance gates:**
- [Gate] 0 or 51+ chars → Save disabled
- [Gate] Large photo → Compressed or error
- [Gate] Device A updates → Device B syncs < 100ms (measured)
- [Gate] Simultaneous edits → No data corruption

### Sync Logic - VERIFY + MEASURE

**Existing (✅ Already Implemented):**
- `SyncService.swift`, `OfflineMessageService.swift`, `PresenceService.swift`, multi-device tests exist

**MUST Add:**
- Verify offline queue survives force-quit
- Verify 30s+ network drop recovery
- Measure actual sync latencies (not just assertions)
- Test 3 real devices simultaneously
- Document sync behavior in code

**Acceptance gates:**
- [Gate] 3 messages offline → Reconnect → Sync < 1s
- [Gate] Profile update → Sync < 100ms (measured)
- [Gate] Presence change → Propagates < 500ms (measured)
- [Gate] Force-quit during sync → Resumes successfully

### Offline Cache - VERIFY + TEST AT SCALE

**Existing (✅ Already Implemented):**
- Firestore offline persistence enabled, `OfflineMessageService` persists via UserDefaults

**MUST Add:**
- Verify force-quit with queued messages
- Test 1000+ messages smooth scrolling (60 FPS)
- Test cache load < 500ms
- Test airplane mode scenarios
- Document cache limits and behavior

**Acceptance gates:**
- [Gate] Force-quit → Reopen → Chat list < 500ms
- [Gate] Force-quit with 3 queued → All 3 still queued
- [Gate] 1000+ messages → 60 FPS scrolling
- [Gate] Airplane mode → Cached messages visible

---

## 8. Data Model

**NO SCHEMA CHANGES** - All existing schemas support this PR.

Existing models already correct:
- User document (Firestore): displayName, email, profilePhotoURL
- OfflineMessage (UserDefaults): id, chatID, text, status, retryCount

---

## 9. API / Service Contracts

**NO NEW SERVICE METHODS** - All required services exist.

Verify these work correctly:
- `AuthService.sendPasswordResetEmail()`
- `UserService.updateDisplayName()`, `updateProfilePhoto()`
- `PhotoService.uploadProfilePhoto()`
- `SyncService.syncOfflineMessages()`
- `OfflineMessageService` queue management
- `PresenceService` online/offline status

---

## 10. UI Components to Create/Modify

**NO NEW UI COMPONENTS** - All UI exists.

Verify correct:
- `ForgotPasswordView.swift` - Password reset screen
- `ProfileEditView.swift` - Profile editing
- `ConnectionStatusBanner.swift` - Network status
- `OfflineIndicatorView.swift` - Offline indicator
- `MessageQueueStatus.swift` - Queue status

**Test Files to Expand:**
- `PasswordResetTests.swift` - Add edge cases
- `MultiDeviceSyncTests.swift` - Expand coverage
- `OfflinePersistenceIntegrationTests.swift` - Add scale tests
- `PasswordResetUITests.swift` - Add edge case UI tests
- `ProfileEditUITests.swift` - Add validation UI tests

---

## 11. Test Plan & Acceptance Gates

### Testing Strategy: 4 Phases

**Phase 1: Baseline** - Run all existing tests, fix failures, establish coverage baseline

**Phase 2: Edge Cases** - Add missing edge case tests (invalid input, offline, conflicts, boundaries)

**Phase 3: Real Devices** - Test on 2+ physical devices, measure actual timing, verify email delivery

**Phase 4: Performance** - Measure all targets, document actual vs expected, optimize if needed

### Password Reset Tests

**Add Missing Edge Cases:**
- [ ] Invalid email format → Error before Firebase call
- [ ] Empty email → Validation error
- [ ] Offline mode → Network error shown
- [ ] Real device: Email arrives < 30s and works end-to-end

### Profile Editing Tests

**Add Missing Edge Cases:**
- [ ] 0 characters → Save disabled
- [ ] 51 characters → Save disabled
- [ ] 1 and 50 characters → Save succeeds
- [ ] Photo > 5MB → Compressed or error
- [ ] Save offline → Queued or error
- [ ] Simultaneous edits → Last-write-wins, no corruption
- [ ] Real device: Sync timing < 100ms (measured)

### Multi-Device Sync Tests

**Add Missing Tests:**
- [ ] Profile photo sync across devices
- [ ] Presence sync timing (< 500ms measured)
- [ ] Offline → online sync (3 messages < 1s)
- [ ] Simultaneous messages from multiple devices
- [ ] Force-quit during sync
- [ ] Network drop (30s+) recovery
- [ ] Real device: 2+ physical devices, measure latencies

### Offline Cache Tests

**Add Missing Tests:**
- [ ] Force-quit with empty queue
- [ ] Force-quit with 3 queued messages
- [ ] Cache load < 500ms (measured)
- [ ] 1000+ messages → 60 FPS scrolling
- [ ] 10+ chats, 100+ messages each
- [ ] Airplane mode scenarios

### Performance Measurement

**Measure All Targets:**
- [ ] Password reset email: < 30s (real device)
- [ ] Profile save: < 2s (measured with timestamps)
- [ ] Photo upload: < 5s for < 5MB (test 1MB, 3MB, 5MB)
- [ ] Multi-device sync: < 100ms (measure with timestamps)
- [ ] Offline sync: < 1s (3 messages)
- [ ] Cache load: < 500ms
- [ ] Document all measurements

---

## 12. Definition of Done

### Password Reset
- [ ] All edge case tests added and passing
- [ ] Real device: Email received < 30s
- [ ] Real device: Reset and sign in works
- [ ] All tests pass in CI

### Profile Editing
- [ ] Boundary validation tests added (0, 1, 50, 51 chars)
- [ ] Large photo tests added (> 5MB)
- [ ] Conflict resolution tested and documented
- [ ] Real device: Multi-device sync < 100ms verified
- [ ] All tests pass in CI

### Sync Logic
- [ ] Force-quit tests added and passing
- [ ] Network drop recovery tested
- [ ] Multi-device timing measured and documented
- [ ] 3+ real devices tested simultaneously
- [ ] Sync behavior documented in code
- [ ] All tests pass in CI

### Offline Cache
- [ ] Force-quit scenarios tested
- [ ] Scale tests added (1000+ messages)
- [ ] Cache load < 500ms verified
- [ ] Airplane mode tested
- [ ] Cache behavior documented
- [ ] All tests pass in CI

### Documentation & Quality
- [ ] Test coverage increased to 95%+
- [ ] Performance measurements documented
- [ ] Edge case handling documented
- [ ] Real device validation completed
- [ ] Zero data loss in testing
- [ ] All Phase 1 targets verified

---

## 13. Risks & Mitigations

- **Risk**: Emails go to spam → **Mitigation**: Test multiple providers (Gmail, Outlook, Yahoo), document issues
- **Risk**: Tests flaky due to timing → **Mitigation**: Reasonable timeouts (100-200ms), retry logic, CI policies
- **Risk**: Real devices reveal issues → **Mitigation**: Goal! Allocate time for fixes, prioritize critical issues
- **Risk**: Performance targets not met → **Mitigation**: Measure first, optimize if critical, document if deferred
- **Risk**: Large photos fail → **Mitigation**: Add compression (< 2MB target), clear size limits
- **Risk**: Sync conflicts → **Mitigation**: Document last-write-wins, verify no corruption

---

## 14. Rollout & Telemetry

**Feature flag**: No - Verification of existing features

**Metrics to track:**
- Password reset success rate (target: >95%)
- Profile update success rate (target: >99%)
- Multi-device sync latency p95 (target: <100ms)
- Offline cache hit rate (target: >90%)
- Zero data loss incidents

**Manual validation (REQUIRED):**
1. ✅ Test password reset on real device
2. ✅ Test profile editing with photo upload
3. ✅ Test multi-device sync (2+ real devices)
4. ✅ Measure actual sync latency
5. ✅ Test force-quit and airplane mode
6. ✅ Run full test suite locally and in CI

---

## 15. Open Questions

- **Q**: What if email takes > 30s with some providers?
  - **A**: Document as known limitation (Firebase controls delivery)

- **Q**: Implement image compression now or defer?
  - **Decision**: Basic compression (< 2MB) if time permits, otherwise defer

- **Q**: Max cache size before cleanup?
  - **Decision**: Document current behavior, implement 1000 messages/chat if time permits

- **Q**: How handle simultaneous edits?
  - **Decision**: Document last-write-wins (Firebase default), verify no corruption

---

## 16. Appendix: Out-of-Scope Backlog

Deferred to future PRs:
- [ ] Biometric authentication (Face ID/Touch ID)
- [ ] Email verification on sign up
- [ ] Multi-factor authentication (MFA)
- [ ] Advanced image compression
- [ ] Profile edit conflict detection UI
- [ ] Advanced cache management (LRU, sophisticated pruning)
- [ ] Profile privacy settings
- [ ] Delete account functionality

---

## Preflight Questionnaire

1. **Smallest end-to-end outcome?** User can rely on password reset, profile editing, and multi-device sync working flawlessly—no data loss, bulletproof reliability.

2. **Primary user and critical action?** Existing users. Critical: Password reset when locked out, profile changes sync instantly, messages survive force-quit.

3. **Must-have vs nice-to-have?**
   - Must: Verify existing features, add edge case tests, real device validation, measure performance
   - Nice: Image compression, advanced cache management, conflict UI

4. **Real-time requirements?** (see shared-standards.md)
   - Multi-device sync: < 100ms (VERIFY and MEASURE)
   - Presence: < 500ms (VERIFY and MEASURE)
   - Message sync: < 200ms p95 (VERIFY from PR #1)
   - Offline sync: < 1s (VERIFY and MEASURE)

5. **Performance constraints?** All Phase 1 targets must be VERIFIED and DOCUMENTED (see section 4)

6. **Error/edge cases?** Comprehensive: Invalid inputs, boundaries, offline, network drops, force-quit, large photos, conflicts, large datasets

7. **Data model changes?** None

8. **Service APIs required?** None - all exist, verify they work

9. **UI entry points?** All existing (verify correct)

10. **Security implications?** No new risks, verify existing security works

11. **Dependencies?** Depends on PR #6, prepares for Phase 3 AI features

12. **Rollout strategy?** Manual validation required, real device testing mandatory, document measurements

13. **Out of scope?** See Appendix section 16

---

## Authoring Notes

**Key Insight**: This PR is verification, not implementation—ensure existing features work flawlessly.

**Approach**:
1. Baseline: Run existing tests, establish coverage
2. Edge Cases: Add missing tests → 95%+ coverage
3. Real Devices: Validate real-world behavior
4. Performance: Measure and document
5. Fixes: Fix bugs found (prioritize critical)
6. Document: Code comments and measurements

**Success Criteria**:
- Zero data loss in comprehensive testing
- All Phase 1 performance targets verified
- Real device validation successful
- Test coverage ≥95%
- Behavior documented

---

**Status**: Ready for Cody (Building Agent) after user approval ✅

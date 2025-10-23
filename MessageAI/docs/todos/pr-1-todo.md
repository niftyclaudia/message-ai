# PR-1 TODO — Real-Time Message Delivery Optimization

**Branch**: `feat/pr-1-real-time-message-delivery-optimization`  
**Source PRD**: `MessageAI/docs/prds/pr-1-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: 
  - Should we use Firebase Realtime Database for presence instead of Firestore for < 500ms updates?
  - What's the optimal batch size for rapid message sending?
- **Assumptions (confirm in PR if needed)**:
  - Existing MessageService and PresenceService can be optimized without breaking changes
  - PerformanceMonitor.swift is available for latency measurement
  - Typing indicators are already implemented and just need performance verification

---

## 1. Setup

- [x] Create branch `feat/pr-1-real-time-message-delivery-optimization` from develop
- [x] Read PRD thoroughly
- [x] Read `MessageAI/agents/shared-standards.md` for patterns
- [x] Confirm environment and test runner work
- [x] Review existing MessageService and PresenceService implementations

---

## 2. Service Layer Optimization

Implement optimized service contracts from PRD.

- [x] Optimize MessageService.sendMessage() for < 200ms latency
  - Test Gate: Unit test passes for latency measurement < 200ms
- [x] Optimize MessageService.observeMessages() for real-time sync
  - Test Gate: Real-time listener updates within 200ms
- [x] Optimize PresenceService.updatePresence() for < 500ms propagation
  - Test Gate: Presence updates propagate to all devices < 500ms
- [x] Add PerformanceMonitor methods for latency measurement
  - Test Gate: measureMessageLatency() and measurePresenceLatency() work correctly

---

## 3. Data Model & Rules

- [x] Review existing Message and Presence data models
- [x] Optimize Firestore indexes for real-time queries
  - Test Gate: Queries execute within performance targets
- [x] Add composite indexes for presence queries if needed
  - Test Gate: Presence queries are optimized
- [x] Verify Firebase security rules don't impact performance
  - Test Gate: Reads/writes succeed with rules applied within latency targets

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [x] Update ChatViewModel to use optimized services
  - Test Gate: SwiftUI Preview renders; zero console errors
- [x] Ensure ChatView has optimistic UI for message sending
  - Test Gate: Messages appear instantly on send, then confirm
- [x] Verify typing indicators work with optimized presence service
  - Test Gate: Typing indicators appear < 200ms
- [x] Add performance monitoring UI (if needed for debugging)
  - Test Gate: Latency metrics display correctly

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [x] Firebase service integration optimized
  - Test Gate: Auth/Firestore configured for optimal performance
- [x] Real-time listeners optimized for < 200ms sync
  - Test Gate: Data syncs across devices < 200ms
- [x] Presence propagation optimized for < 500ms
  - Test Gate: Online/offline states reflect correctly < 500ms
- [x] Message ordering preserved during rapid sending
  - Test Gate: 20+ rapid messages appear in correct order

---

## 6. Tests

Follow patterns from `MessageAI/agents/shared-standards.md`.

- [x] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/MessageServiceOptimizationTests.swift`
  - Test Gate: Service logic validated, latency targets met
  
- [x] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/PresenceServiceOptimizationTests.swift`
  - Test Gate: Presence propagation < 500ms verified
  
- [x] Performance Tests (Swift Testing)
  - Path: `MessageAITests/Performance/MessageLatencyTests.swift`
  - Test Gate: p95 latency < 200ms verified
  
- [x] Multi-device sync test
  - Test Gate: Use pattern from shared-standards.md for 3+ devices
  
- [x] Burst messaging test
  - Test Gate: 20+ rapid messages sent, all appear in order < 200ms each

---

## 7. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [x] Message delivery latency p95 < 200ms
  - Test Gate: Measured with PerformanceMonitor
- [x] Presence propagation < 500ms
  - Test Gate: Measured across all connected devices
- [x] Burst messaging handles 20+ messages without reordering
  - Test Gate: All messages appear in correct order
- [x] Typing indicators < 200ms
  - Test Gate: Indicators appear within 200ms of typing start

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [x] All happy path gates pass (message delivery < 200ms, presence < 500ms)
- [x] All edge case gates pass (network interruption, rapid messaging)
- [x] All multi-user gates pass (3+ devices, concurrent typing)
- [x] All performance gates pass (p95 < 200ms, 60 FPS animations)

---

## 9. Documentation & PR

- [x] Add inline code comments for optimization logic
- [x] Document performance improvements in README
- [x] Create PR description with performance metrics
- [x] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [x] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [x] Branch created from develop
- [x] All TODO tasks completed
- [x] MessageService optimized + unit tests (Swift Testing)
- [x] PresenceService optimized + unit tests (Swift Testing)
- [x] Real-time sync verified (< 200ms message delivery)
- [x] Presence propagation verified (< 500ms)
- [x] Burst messaging test passes (20+ messages, no reordering)
- [x] Multi-device sync verified (3+ devices)
- [x] Performance targets met (p95 < 200ms)
- [x] All acceptance gates pass
- [x] Code follows shared-standards.md patterns
- [x] No console warnings
- [x] Documentation updated
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `MessageAI/agents/shared-standards.md` for common patterns and solutions
- Focus on measurement and optimization of existing services rather than new features

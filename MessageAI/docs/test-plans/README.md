# Test Plans Directory

This directory contains manual test specifications created by **Quincy Agent** for each PR.

---

## What Are Test Plans?

Test plans are **manual testing guides** that ensure every PR has clear, executable test scenarios you can follow to verify quality.

Each test plan includes:
- **1 Happy Trail**: The ideal user journey from start to finish
- **2 Edge Cases**: Unusual but valid scenarios (offline, empty states, etc.)
- **1 Error State**: How the app handles something going wrong

---

## How to Use Quincy Agent

### Option 1: Pre-Review (Before Implementation)

Create test plan **before** Cody builds the feature:

```
quincy pr-3 pre-review
```

**Benefits:**
- Defines test requirements upfront
- Helps Cody think through edge cases during implementation
- Catches potential issues before coding starts
- Serves as acceptance criteria

### Option 2: Post-Review (After Implementation)

Review feature **after** Cody completes implementation:

```
quincy pr-3 post-review
```

**Benefits:**
- Tests actual implementation
- Identifies bugs and conflicts
- Verifies all scenarios work
- Signs off on quality
- Checks for merge conflicts

---

## Test Plan Structure

Each test plan follows this format:

```
MessageAI/docs/test-plans/pr-{number}-test-plan.md
```

**Contents:**
1. Feature overview
2. Test environment setup
3. Test Scenario 1: Happy Trail ✨
4. Test Scenario 2: Edge Case A 🔄
5. Test Scenario 3: Edge Case B 🔄
6. Test Scenario 4: Error State ⚠️
7. Integration tests (if applicable)
8. Performance & feel checks
9. Visual verification checklist
10. Test results & sign-off

---

## Example Workflow

### Pre-Review Workflow:
```
1. pete pr-3        → Creates PRD
2. quincy pr-3 pre-review  → Creates test plan
3. cody pr-3        → Implements feature (references test plan)
4. [You manually test using test plan]
5. quincy pr-3 post-review → Verifies & signs off
```

### Post-Review Only Workflow:
```
1. pete pr-3        → Creates PRD
2. cody pr-3        → Implements feature
3. quincy pr-3 post-review → Creates test plan, tests, signs off
4. [You manually test using test plan]
```

---

## What Quincy Does NOT Do

❌ Write Swift test code (XCTest, UI tests)  
❌ Run automated tests  
❌ Create CI/CD configurations  

✅ Creates **manual test documentation**  
✅ Defines clear test scenarios  
✅ Identifies potential conflicts  
✅ Provides step-by-step testing guides  

---

## Why Manual Tests?

Manual testing allows you to:
- Verify visual appearance (colors, spacing, fonts)
- Check performance feel (smooth 60fps, responsive)
- Test on real devices
- Evaluate UX quality
- Catch subtle issues automation misses

**Automated tests** (which Cody creates) handle:
- Functional correctness
- Data persistence
- Real-time sync
- Regression prevention

**Manual tests** (which Quincy creates) handle:
- Visual quality
- Performance feel
- User experience
- Edge case discovery

---

## Other Agent Names (Q-Theme)

If you prefer a different name, here are alternatives:
- **Quest** (Testing is a quest for quality)
- **Quill** (Documents/writes test specs)
- **Quinlan**
- **Quentin**

To rename, update:
1. `MessageAI/agents/secondagent/quincy-agent-template.md` (rename file)
2. `MessageAI/agents/secondagent/agent-prompt-template.md` (update references)
3. `.cursorrules` (update agent mapping)

---

## Questions?

- **Template**: `MessageAI/agents/secondagent/quincy-agent-template.md`
- **Shared Standards**: `MessageAI/agents/secondagent/shared-standards.md`
- **Test Template**: `MessageAI/agents/test-template.md` (for Swift tests by Cody)

Happy testing! 🧪✨

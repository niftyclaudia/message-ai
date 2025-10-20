# Building Agent (Coder) — Instructions Template

**Role:** Implementation agent that builds features from PRD and TODO list

---

## 🎯 ASSIGNMENT

**PR Number:** `#___` ← **FILL THIS IN**

**PR Name:** `___________` ← Will be found in pr-briefs.md

**Branch Name:** `feat/pr-___-{feature-name}` ← Create this branch

---

**Input Documents:**
- PRD document (`messageai/docs/prds/pr-{number}-prd.md`) - READ this
- TODO list (`messageai/docs/todos/pr-{number}-todo.md`) - READ this
- PR brief (`messageai/docs/pr-briefs.md`) - READ for context
- Architecture doc (`messageai/docs/architecture.md`) - READ for codebase structure

**Documents you will CREATE:**
- Feature code (components, services, utils, etc.)
- Test files:
  - Integration tests: `messageai/tests/integration/{feature}.test.ts`
  - Service unit tests: `messageai/tests/unit/services/{service-name}.test.ts`
  - Utils unit tests: `messageai/tests/unit/utils/{util-name}.test.ts` (if applicable)

---

## Workflow Steps

### Step 1: Setup
```
FIRST: Create a new branch FROM develop
- Base branch: develop
- Branch name: feat/pr-{number}-{feature-name}
- Example: feat/pr-1-pencil-tool

Commands:
git checkout develop
git pull origin develop
git checkout -b feat/pr-1-pencil-tool
```

### Step 2: Read PRD and TODO

**IMPORTANT:** PRD and TODO have already been created. Your job is to implement them.

**Read these documents thoroughly:**
1. **PRD** (`messageai/docs/prds/pr-{number}-prd.md`)
   - Understand all requirements
   - Note acceptance gates
   - Review data model and service contracts
   - Check UI components to modify
   
2. **TODO** (`messageai/docs/todos/pr-{number}-todo.md`)
   - This is your step-by-step guide
   - Follow tasks in order
   - Check off each task as you complete it
   
3. **Architecture doc** (`messageai/docs/architecture.md`)
   - Understand codebase structure
   - Follow existing patterns

**Key questions to verify:**
- Do I understand the end-to-end user outcome?
- Do I know which files to modify/create?
- Are the acceptance gates clear?
- Do I understand the dependencies?

**If anything is unclear in the PRD/TODO, ask for clarification before proceeding.**

### Step 3: Implementation

**Follow the TODO list exactly:**
- Complete tasks in order (top to bottom)
- Check off each task as you complete it
- If blocked, document the blocker in TODO
- Keep PRD open as reference for requirements

**Code quality requirements:**
- Follow existing code patterns
- Add TypeScript types for everything
- Include comments for complex logic
- Use meaningful variable names
- Keep functions small and focused

**Real-time collaboration requirements:**
- All shape operations must sync to Firestore
- Target latency: <100ms for sync
- Include optimistic UI updates where safe
- Handle concurrent edits gracefully

**Performance requirements:**
- 60 FPS during interactions
- Smooth drawing/dragging with no lag
- Test with 50+ shapes on canvas
- Throttle expensive operations (network calls, etc.)

### Step 4: Write Tests

**Create test files following the template at `agents/test-template.md`**

**You must create these test files:**

1. **Integration tests** (mandatory for all features):
   - Path: `messageai/tests/integration/{feature-name}.test.ts`
   - Tests: User Simulation + State Inspection + Multi-user sync
   - Example: `tests/integration/pencil-tool.test.ts`

2. **Service unit tests** (mandatory if you modified/created service methods):
   - Path: `messageai/tests/unit/services/{service-name}.test.ts`
   - Tests: Service method behavior, validation, Firestore operations
   - Example: `tests/unit/services/canvasService-path.test.ts`

3. **Utils unit tests** (if you created utility functions):
   - Path: `messageai/tests/unit/utils/{util-name}.test.ts`
   - Tests: Pure function logic, edge cases
   - Example: `tests/unit/utils/lineSmoothing.test.ts`

**Example for PR #1 (Pencil Tool), you would create:**
- ✅ `tests/integration/pencil-tool.test.ts` (user can draw, path saves to Firestore)
- ✅ `tests/unit/services/canvasService-path.test.ts` (createPath, updatePath methods)
- ✅ `tests/unit/utils/lineSmoothing.test.ts` (smoothing algorithm works correctly)

**For every feature, write these 2 types of tests:**

#### A. User Simulation Test (Does it click?)
```typescript
// Example: Does the pencil tool draw when clicked?
test('user can draw with pencil tool', () => {
  // 1. Click pencil tool button
  // 2. Click and drag on canvas
  // 3. Assert: path shape created
  // 4. Assert: path visible on screen
});
```

#### B. State Inspection Test (Is the logic correct?)
```typescript
// Example: Does the path save to Firestore correctly?
test('pencil path syncs to Firestore', async () => {
  // 1. Draw a path
  // 2. Check Firestore for new shape document
  // 3. Assert: shape.type === 'path'
  // 4. Assert: shape.points.length > 0
  // 5. Assert: shape has required fields (color, strokeWidth, etc.)
  // 6. Assert: shape syncs in <100ms
});
```

**Note:** Visual appearance testing (colors, smoothness, positioning) will be verified manually by the user after implementation.

### Step 5: Multi-User Testing (Automated)

**Write automated tests that simulate multiple users (included in integration tests):**

```typescript
// This is part of your integration test file
describe('Multi-User Collaboration Tests', () => {
  it('should sync {action} across users', async () => {
    // Simulate 2 users in code
    const user1 = await createTestUser('user1');
    const user2 = await createTestUser('user2');
    
    // Render 2 canvas instances
    const canvas1 = renderWithProviders(<Canvas />, { user: user1 });
    const canvas2 = renderWithProviders(<Canvas />, { user: user2 });
    
    // User 1 performs action
    // ... interaction code ...
    
    // Assert: User 2 sees the change in <100ms
    await waitFor(() => {
      expect(canvas2.getByTestId('shape-id')).toBeInTheDocument();
    }, { timeout: 150 });
  });
});
```

**This tests real-time sync programmatically, no manual browser opening needed.**

**Note:** Manual 2-browser testing will be done by USER during PR review.

### Step 6: Verify Acceptance Gates

**Check every gate from PRD Section 12:**
- [ ] All "Happy Path" gates pass
- [ ] All "Edge Case" gates pass
- [ ] All "Multi-User" gates pass
- [ ] All "Performance" gates pass

**If any gate fails:**
1. Document the failure in TODO
2. Fix the issue
3. Re-run tests
4. Don't proceed until all gates pass

### Step 7: Verify With User (Before PR)

**BEFORE creating the PR, verify with the user:**

1. **Run the application:**
   ```bash
   npm run dev
   ```

2. **Test the feature end-to-end:**
   - Does it work as described in the PRD?
   - Are there any bugs or unexpected behaviors?
   - Does it feel smooth and responsive?

3. **Confirm with user:**
   ```
   "Feature is complete. All tests pass. All acceptance gates pass. 
   No bugs found in my testing. Ready to create PR?"
   ```

4. **Wait for user approval** before proceeding to create the PR

**If user finds issues:**
- Document them
- Fix the issues
- Re-run tests
- Verify again with user

### Step 8: Create Pull Request & Handoff

**IMPORTANT: PR must target `develop` branch, NOT `main`**

After creating the PR, the agent's work is complete. The following will be done by the user:

**Manual verification needed (USER does this):**
- [ ] Visual appearance check (colors, smoothness, positioning)
- [ ] Performance feel test (does it feel smooth at 60 FPS?)
- [ ] Multi-browser testing (Chrome, Firefox, Safari)
- [ ] Real 2-browser collaboration (open 2 windows, test sync)
- [ ] Mobile/responsive testing
- [ ] Screenshot/video for PR description

**PR title format:**
```
PR #{number}: {Feature Name}
Example: PR #1: Pencil Tool
```

**Base branch:** `develop`  
**Compare branch:** `feat/pr-{number}-{feature-name}`

**PR description must include:**

```markdown
## Summary
One sentence: what does this PR do?

## What Changed
- List all modified files
- List all new files created
- Note any breaking changes

## Testing
- [x] Integration tests created and passing
- [x] Service unit tests created and passing (if service methods added)
- [x] Utils unit tests created and passing (if utils added)
- [x] Multi-user testing complete
- [x] All acceptance gates pass
- [ ] Visual verification (USER will do this manually)
- [ ] Performance feel test (USER will do this manually)

## Screenshots/Video
[Add screenshots or screen recording of feature working]

## Checklist
- [x] All TODO items completed
- [x] Code follows existing patterns
- [x] TypeScript types added
- [x] Comments added for complex logic
- [x] No console errors
- [x] 60 FPS performance maintained
- [x] Real-time sync <100ms
- [x] Works with 50+ shapes on canvas

## Notes
Any gotchas, trade-offs, or future improvements to mention
```

---

## Testing Checklist (Run Before PR)

### Functional Tests
- [ ] Feature works as described in PRD
- [ ] All user interactions respond correctly
- [ ] Keyboard shortcuts work (if applicable)
- [ ] Error states handled gracefully
- [ ] Loading states shown appropriately

### Performance Tests
- [ ] 60 FPS during feature use
- [ ] No lag or stuttering
- [ ] Works with 50+ shapes
- [ ] Memory usage acceptable
- [ ] No console warnings/errors

### Collaboration Tests
- [ ] Changes sync to other users <100ms
- [ ] Concurrent edits don't conflict
- [ ] Works with 3+ simultaneous users
- [ ] Disconnection handled gracefully

### Browser Tests
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)

### Edge Cases
- [ ] Empty canvas
- [ ] Full canvas (50+ shapes)
- [ ] Offline mode (graceful degradation)
- [ ] Small screen (mobile viewport)
- [ ] Large screen (4K)

---

## Common Issues & Solutions

### Issue: "My changes don't sync to Firestore"
**Solution:** Make sure you're calling the service method, not just updating local state
```typescript
// ❌ Wrong - only updates local state
setShapes([...shapes, newShape]);

// ✅ Correct - saves to Firestore AND updates local state
await canvasService.createShape(newShape);
```

### Issue: "Performance is slow with many shapes"
**Solution:** Use React.memo and useMemo to prevent unnecessary re-renders
```typescript
// Memoize expensive computations
const sortedShapes = useMemo(() => 
  shapes.sort((a, b) => a.zIndex - b.zIndex),
  [shapes]
);
```

### Issue: "Tests are failing"
**Solution:** Check these common problems:
1. Async operations not awaited
2. Firestore emulator not running
3. State not updating before assertion
4. Race conditions in concurrent tests

### Issue: "Real-time sync is slow"
**Solution:** 
1. Use Firestore batch writes (not individual writes)
2. Optimize queries with indexes
3. Throttle high-frequency updates (cursor positions)

---

## Code Review Self-Checklist

Before submitting PR, review your own code:

### Architecture
- [ ] Service layer methods are deterministic
- [ ] UI components are thin wrappers around services
- [ ] State management follows existing patterns
- [ ] No business logic in UI components

### Code Quality
- [ ] No console.log statements (use proper logging)
- [ ] No commented-out code
- [ ] No hardcoded values (use constants)
- [ ] No magic numbers
- [ ] No TODO comments without tickets

### TypeScript
- [ ] No `any` types
- [ ] All function parameters typed
- [ ] All return types specified
- [ ] Interfaces defined for complex objects

### Testing
- [ ] Tests are readable and maintainable
- [ ] Tests cover happy path
- [ ] Tests cover edge cases
- [ ] Tests don't depend on each other
- [ ] Tests clean up after themselves

### Documentation
- [ ] Complex logic has comments
- [ ] Public APIs have JSDoc comments
- [ ] README updated if needed
- [ ] Migration notes added if schema changed

---

## Emergency Procedures

### If you're blocked:
1. Document the blocker in TODO
2. Try a different approach
3. Ask for help (tag senior engineer)
4. Don't merge broken code

### If tests fail in CI:
1. Run tests locally first
2. Check CI logs for specific failure
3. Fix the issue
4. Push fix to same branch
5. Wait for CI to pass before merging

### If performance regresses:
1. Use Chrome DevTools Performance tab
2. Identify bottleneck
3. Optimize hot path
4. Re-run performance tests
5. Ensure 60 FPS maintained

---

## Success Criteria

**PR is ready for USER review when:**
- ✅ All TODO items checked off
- ✅ All automated tests pass (User Simulation, State Inspection)
- ✅ All acceptance gates pass
- ✅ Multi-user sync works (<100ms)
- ✅ Performance targets met programmatically
- ✅ Code review self-checklist complete
- ✅ No console errors
- ✅ Documentation updated
- ✅ PR description complete

**USER will then verify:**
- Visual appearance (colors, spacing, fonts)
- Performance feel (smooth, responsive)
- Cross-browser compatibility
- Real multi-user testing (2+ browser windows)
- Add screenshots/video to PR

---

## Example: Complete Workflow

```bash
# 1. Create branch FROM develop
git checkout develop
git pull origin develop
git checkout -b feat/pr-1-pencil-tool

# 2. Read PRD and TODO
# READ:
# - messageai/docs/prds/pr-1-prd.md
# - messageai/docs/todos/pr-1-todo.md
# - messageai/docs/architecture.md

# 3. Implement feature (follow TODO)
# - Add tool button to ToolPalette.tsx ✓
# - Add drawing handlers to Canvas.tsx ✓
# - Add path rendering to CanvasShape.tsx ✓
# - Add createPath to canvasService.ts ✓
# - Add line smoothing utility ✓
# - etc...
npm run build

# 4. Write tests (use agents/test-template.md)
# CREATE:
# - messageai/tests/integration/pencil-tool.test.ts
#   (includes multi-user sync tests)
# - messageai/tests/unit/services/canvasService-path.test.ts
# - messageai/tests/unit/utils/lineSmoothing.test.ts
npm run test

# 5. Verify all tests pass
# All integration, service, and utils tests should pass

# 6. Verify gates
# Check PRD Section 12, all gates pass ✓

# 7. IMPORTANT: Verify with user no bugs
# Run the app, test the feature end-to-end
# Confirm with user: "Feature is complete, all tests pass, no bugs found. Ready for PR?"
# Wait for user approval before proceeding to next step

# 8. Create PR (targeting develop)
git add .
git commit -m "feat: add pencil tool for free-form drawing"
git push origin feat/pr-1-pencil-tool
# Create PR on GitHub:
#   - Base: develop
#   - Compare: feat/pr-1-pencil-tool
#   - Full description with screenshots

# 8. Merge when approved
```

---

**Remember:** Quality over speed. It's better to ship a solid feature late than a buggy feature on time.
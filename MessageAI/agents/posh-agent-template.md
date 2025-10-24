# Posh: UI/UX Polish Agent

**Mission**: Essential messaging features with Calm Intelligence principles  
**Branch**: `develop`  
**Timeline**: Complete by tomorrow night  
**Parallel Work**: Agent B building AI infrastructure in `secondagent` branch

---

## Philosophy

Building a **focus rehabilitation tool**, not just a messaging app. Every feature should support mental spaciousness.

**Read full philosophy**: `MessageAI/docs/calm-intelligence-vision.md`

---

## Your Tasks (Priority Order)

### 1. "All Caught Up" State ⭐ Quick Win (30 min)
- Empty state with green checkmark when no unread messages
- Calm design, gentle animation
- Files: Update `ConversationListView.swift`

### 2. Image Upload & Display ⭐⭐⭐ Biggest Feature (4-5 hours)
- Send/view images in conversations
- Firebase Storage upload, offline queueing, lazy loading
- Calm progress indicators (not aggressive)
- Files: `ImageUploadService.swift`, `ImageMessageView.swift`, `ImagePickerView.swift`
- Tests: `ImageUploadServiceTests.swift`, `ImageMessagingUITests.swift`

### 3. Push Notifications ⭐⭐⭐ Critical (3-4 hours)
- **Calm Intelligence**: Bundle rapid messages (3 in 30s = 1 notification)
- Gentle defaults (soft sound, no vibration)
- Deep linking to conversations
- Files: `NotificationService.swift`, `PushNotificationHandler.swift`, Cloud Function
- Tests: `NotificationServiceTests.swift`, `NotificationFlowUITests.swift`

### 4. Add Contacts 🎯 Medium Priority (2-3 hours)
- Search users by email/username
- Gentle empty states
- Files: `UserSearchService.swift`, `AddContactView.swift`
- Tests: `UserSearchServiceTests.swift`, `AddContactUITests.swift`

### 5. Delete Messages 🎯 Medium Priority (2 hours)
- Long-press to delete with gentle confirmation
- Offline queueing
- Files: Update `MessageService.swift`, `MessageRow.swift`
- Tests: Update `MessageServiceTests.swift`, `DeleteMessageUITests.swift`

---

## Calm Intelligence Principles

**Apply to ALL features:**
1. **Silence by Design**: Gentle notifications, smart bundling
2. **Ambient Reassurance**: "All caught up" states reduce FOMO
3. **Visual Design**: Calm colors, spacious layouts, slow animations
4. **Dark mode**: Plan for later (cosmos.com aesthetic)

---

## Standards & References

**Code Standards**: `MessageAI/agents/shared-standards.md`
- Swift/SwiftUI best practices
- Threading rules (background for heavy work, main for UI)
- Testing: Swift Testing (@Test) for services, XCTest for UI
- Performance: 60fps scrolling, < 2s image upload

**Study These Patterns**:
- `MessageAI/Services/AuthenticationService.swift` - Firebase patterns
- `MessageAI/Services/MessageService.swift` - Firestore operations
- `MessageAI/Views/ChatView.swift` - View patterns

**Sprint Coordination**: `MessageAI/docs/sprints/tomorrow-night-sprint-plan.md`

---

## Success Criteria

- [ ] Images send/display smoothly (< 2s upload)
- [ ] Notifications bundle correctly (3 rapid = 1 notification)
- [ ] "All caught up" provides reassurance
- [ ] All features work offline
- [ ] 60fps scrolling maintained
- [ ] All tests pass
- [ ] Features feel calm and supportive (not aggressive)

---

## Workflow

1. Start with "All Caught Up" state (quick win)
2. Implement Image Upload (biggest feature)
3. Test thoroughly, check in with user
4. Implement Notifications with bundling
5. Implement Add Contacts
6. Implement Delete Messages
7. Final polish and testing

**Check in after**: Image upload complete, Notifications working, All tasks done

---

## Quick Start

```bash
# You're on develop branch
git checkout develop
git pull origin develop

# Work and commit frequently
git add .
git commit -m "feat: Add image upload with gentle progress"

# Push when ready
git push origin develop
```

**Status Format**:
```
✅ Completed: [tasks]
🔄 In Progress: [current task with %]
⏳ Next: [next task]
⚠️ Blockers: [blockers or None]
```

Begin with "All Caught Up" state, then move to Image Upload.

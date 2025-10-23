# Debug Log - Errors & Issues Tracker

> **Purpose**: Track errors, bugs, and issues discovered during development that need to be addressed later.  
> **Status**: Active tracking  
> **Last Updated**: October 23, 2025

---

## 🔴 Critical Errors
_Errors that block functionality or cause crashes_

### Error #1: Offline Presence - No Connection Banner, Queued Messages Not Visible, Keyboard Freezes
- **Date Added**: 2025-10-23
- **Component**: Offline Mode / MessageService / PresenceIndicator / ChatView
- **Screenshots**: 
  - ![Offline queue error](./images/error%20queue%20offline.png)
- **Error Description**: 
  - Cannot see offline banner when there's no network connection
  - Cannot view queued messages
  - Message shows "sending" once, then keyboard becomes unresponsive
  - Cannot type or text anything after first send attempt
  - Issue occurs in both simulators
- **Steps to Reproduce**:
  1. Disconnect network/internet connection
  2. Open chat view
  3. Try to send a message
  4. Observe "sending" status appears once
  5. Try to type another message - keyboard is frozen/unresponsive
- **Expected Behavior**: 
  - Offline banner should be visible when no connection
  - Queued messages should be visible with "queued" status
  - Keyboard should remain functional to queue multiple messages
  - Messages should be stored and sent when connection is restored
- **Actual Behavior**: 
  - No offline banner visible
  - Queued messages not visible
  - After first "sending" message, keyboard becomes completely unresponsive
  - Cannot type or send additional messages
- **Priority**: High
- **Status**: Open
- **Notes**: Blocking core offline functionality. Affects user experience significantly as they cannot queue multiple messages while offline.

---

### [SAMPLE] Error #1: [Brief Description]
- **Date Added**: YYYY-MM-DD
- **Component**: ServiceName / ViewName
- **Screenshots**: 
  - ![Error screenshot](./images/error-001.png)
- **Error Message**: 
  ```
  Paste error message here
  ```
- **Steps to Reproduce**:
  1. Step one
  2. Step two
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Priority**: High / Medium / Low
- **Status**: Open / In Progress / Resolved
- **Notes**: Additional context

---

## 🟡 Medium Priority Issues
_Issues that affect functionality but have workarounds_

### [SAMPLE] Issue #1: [Brief Description]
- **Date Added**: YYYY-MM-DD
- **Component**: ServiceName / ViewName
- **Description**: Detailed description of the issue
- **Impact**: How this affects users/functionality
- **Workaround**: Temporary solution (if any)
- **Priority**: Medium
- **Status**: Open
- **Notes**: Additional context

---

## 🟢 Low Priority / Technical Debt
_Minor issues, optimizations, and code improvements_

### [SAMPLE] Tech Debt #1: [Brief Description]
- **Date Added**: YYYY-MM-DD
- **Component**: ServiceName / ViewName
- **Description**: What needs improvement
- **Why Later**: Reason for deferring
- **Priority**: Low
- **Status**: Backlog
- **Notes**: Additional context

---

## 📝 Quick Add Template
_Copy this template when adding new entries_

```markdown
### Error/Issue #X: [Brief Description]
- **Date Added**: YYYY-MM-DD
- **Component**: 
- **Screenshots**: (optional)
  - ![Description](./images/filename.png)
- **Error/Description**: 
- **Priority**: High / Medium / Low
- **Status**: Open
- **Notes**: 
```

---

## 🎯 Usage Guidelines

1. **Add new entries** at the top of their respective sections
2. **Update status** as work progresses (Open → In Progress → Resolved)
3. **Include stack traces** when available
4. **Link to PRs** when creating fixes
5. **Archive resolved items** after verification (move to bottom or separate file)
6. **Add screenshots/images** to document visual issues (see instructions below)

### 📸 Adding Reference Images

**Option 1: Save screenshots in backlog folder**
1. Create an `images` folder: `MessageAI/docs/backlog/images/`
2. Save your screenshot there (e.g., `error-screenshot-001.png`)
3. Reference it in markdown:
   ```markdown
   ![Description](./images/error-screenshot-001.png)
   ```

**Option 2: Direct markdown syntax**
```markdown
![Error Screenshot](./images/your-image-name.png)
![UI Bug](./images/ui-bug-example.png)
```

**Option 3: With more detail (HTML)**
```html
<img src="./images/error-screenshot.png" alt="Error description" width="600">
```

**Example Usage:**
```markdown
### Error #1: Login Button Misaligned
- **Screenshots**: 
  ![Login screen bug](./images/login-bug-001.png)
  
- **Error Message**: ...
```

---

## ✅ Recently Resolved
_Keep recent fixes here for reference, archive older ones_

---

## 📊 Statistics
- **Total Open**: 1
- **Critical**: 1
- **Medium**: 0
- **Low**: 0
- **Resolved This Month**: 0


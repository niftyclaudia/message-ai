# TODO: Phase 1 - Critical Bug Fixes

**Status**: In Progress

**Related PRD**: [PRD-phase1.md](../prds/PRD-phase1.md)

**Agent**: Pete

**Last Updated**: 2025-11-06

---

## Investigation

### Root Cause Analysis

- [ ] **Investigation: Analyze root cause of contacts view loading bug**
  - Read ContactListView.swift and ContactListViewModel.swift to understand why contacts don't load on first view appearance
  - Identify whether bug is in view lifecycle, data fetch, or state management

- [ ] **Investigation: Document findings on contacts loading issue**
  - Identify whether bug is in view lifecycle (onAppear not called), data fetch (service issue), or state management (published properties)
  - Document findings for reference during implementation

---

## Subphase 1.1: Contacts View Loading

### Implementation Tasks

- [ ] **Contacts Fix: Update ContactListViewModel.loadContacts() method**
  - Ensure method works on first call
  - Add guard against duplicate loads
  - Implement proper async/await error handling

- [ ] **Contacts Fix: Add onAppear call in ContactListView.swift**
  - Add .onAppear { Task { await viewModel.loadContacts() } } to trigger load when view appears
  - Ensure proper lifecycle timing

- [ ] **Contacts Fix: Implement loading state UI in ContactListView**
  - Add ZStack with conditional rendering for isLoading state
  - Show ProgressView with 'Loading contacts...' text
  - Center on screen

- [ ] **Contacts Fix: Implement empty state UI in ContactListView**
  - Add empty state view with person.2.slash icon
  - Add 'No contacts yet' headline
  - Add helpful subtext for user guidance

- [ ] **Contacts Fix: Implement error state UI in ContactListView**
  - Add error view with exclamationmark.triangle icon
  - Display error message from error object
  - Add 'Try Again' button that calls viewModel.retry()

- [ ] **Contacts Fix: Implement retry() method in ContactListViewModel**
  - Add retry function that calls loadContacts() again after error
  - Clear previous error state before retry

### Testing Tasks - Checkpoint 1.1

- [ ] **Testing Checkpoint 1.1: Test contacts load on first view**
  - Open simulator (iPhone 17)
  - Fresh install or clear app data
  - Navigate to Contacts tab
  - Verify contacts appear within 2 seconds

- [ ] **Testing Checkpoint 1.1: Test loading state**
  - Verify loading spinner appears
  - Verify 'Loading contacts...' text appears while fetching data
  - Verify spinner disappears when load completes

- [ ] **Testing Checkpoint 1.1: Test contact interaction**
  - Verify contacts are immediately tappable with no delay after load completes
  - Tap on a contact and verify navigation works

- [ ] **Testing Checkpoint 1.1: Test empty state**
  - Test with account that has no contacts
  - Verify empty state UI appears correctly
  - Verify icon, headline, and subtext are visible

- [ ] **Testing Checkpoint 1.1: Test error state**
  - Enable airplane mode on simulator
  - Navigate to contacts tab
  - Verify error state shows with retry button
  - Verify error message is clear and helpful

- [ ] **Testing Checkpoint 1.1: Test retry functionality**
  - After error state appears
  - Disable airplane mode
  - Tap 'Try Again' button
  - Verify contacts load successfully

- [ ] **Testing Checkpoint 1.1: Test navigation persistence**
  - Navigate away from contacts tab to another tab
  - Navigate back to contacts tab
  - Verify contacts remain visible (no regression)
  - Verify no duplicate loading

- [ ] **Testing Checkpoint 1.1: Test appearance modes**
  - Test contacts view in light mode
  - Test contacts view in dark mode
  - Verify all states (loading, empty, error, loaded) render correctly in both modes

---

## ⚠️ CHECKPOINT: Subphase 1.1 Complete

**DO NOT PROCEED to Subphase 1.2 until:**
- All acceptance gates for Contacts View have passed
- Claudia has tested and approved the contacts fixes
- No blocking issues remain

**Notify Claudia for approval before continuing.**

---

## Subphase 1.2: Profile Photo Upload

### Investigation Tasks

- [ ] **Investigation: Analyze root cause of profile photo upload bug**
  - Read ProfileView.swift, ProfileViewModel.swift, and PhotoService.swift
  - Understand why photo picker doesn't open or photos don't save
  - Test current behavior on simulator

- [ ] **Investigation: Document findings on photo upload issue**
  - Identify whether bug is in photo picker presentation, upload logic, Firestore update, or state management
  - Document findings for reference during implementation

### Implementation Tasks - PhotoService

- [ ] **Photo Fix: Fix PhotoService.selectPhoto() method**
  - Ensure PHPickerViewController or UIImagePickerController opens reliably on all devices
  - Handle async photo selection properly
  - Return selected UIImage

- [ ] **Photo Fix: Implement PhotoService.compressPhoto() method**
  - Add image compression for photos larger than 10MB
  - Maintain aspect ratio and quality
  - Target 2MB max size after compression
  - Return compressed UIImage

- [ ] **Photo Fix: Fix PhotoService.uploadPhoto() method**
  - Ensure photo uploads to Firebase Storage at /users/{userID}/profile.jpg path
  - Implement proper error handling for network issues
  - Return download URL on success

- [ ] **Photo Fix: Fix PhotoService.updateUserPhoto() method**
  - Ensure user profile in Firestore updates with photoURL field
  - Update atomically to prevent race conditions
  - Handle errors gracefully

### Implementation Tasks - ProfileViewModel

- [ ] **Photo Fix: Implement ProfileViewModel.uploadProfilePhoto() method**
  - Add complete upload flow: select photo, set isUploading, compress if needed, upload, update profile
  - Handle all steps with proper error handling
  - Update local user object after successful upload

- [ ] **Photo Fix: Add upload progress tracking to ProfileViewModel**
  - Add @Published uploadProgress property (Double, 0.0 to 1.0)
  - Update progress during upload
  - Reset progress on completion or error

- [ ] **Photo Fix: Add error handling to ProfileViewModel**
  - Add @Published uploadError property (Error?)
  - Capture errors from each step of upload process
  - Provide retry capability

### Implementation Tasks - ProfileView

- [ ] **Photo Fix: Add photo picker UI to ProfileView.swift**
  - Add confirmationDialog with 'Take Photo' and 'Choose from Library' options
  - Add 'Cancel' option
  - Present on profile photo tap

- [ ] **Photo Fix: Add upload progress indicator to ProfileView**
  - Add ZStack overlay on profile photo
  - Show ProgressView when viewModel.isUploading is true
  - Style progress indicator appropriately (circular, white on dark overlay)

- [ ] **Photo Fix: Add error alert to ProfileView**
  - Add .alert modifier that shows uploadError
  - Include 'Try Again' button that retries upload
  - Include 'Cancel' button that dismisses alert and clears error

### Permissions

- [ ] **Photo Fix: Verify photo library permissions handling**
  - Ensure Info.plist has NSPhotoLibraryUsageDescription with clear message
  - Handle permission denied gracefully with alert directing user to Settings
  - Test permission request flow

- [ ] **Photo Fix: Verify camera permissions handling (if implementing camera)**
  - Ensure Info.plist has NSCameraUsageDescription with clear message
  - Handle permission denied gracefully with alert
  - Test camera permission request flow

### Testing Tasks - Checkpoint 1.2

- [ ] **Testing Checkpoint 1.2: Test photo picker opening**
  - Tap profile photo in ProfileView
  - Verify options dialog appears
  - Select 'Choose from Library'
  - Verify picker opens reliably

- [ ] **Testing Checkpoint 1.2: Test upload with progress**
  - Select photo from library
  - Verify upload progress indicator appears
  - Verify progress indicator shows while uploading
  - Verify it completes and disappears when done

- [ ] **Testing Checkpoint 1.2: Test immediate photo update**
  - After upload completes
  - Verify profile photo updates immediately in UI
  - Verify no app restart required
  - Verify photo displays correctly

- [ ] **Testing Checkpoint 1.2: Test photo persistence**
  - After successful upload
  - Force quit app (swipe up from app switcher)
  - Relaunch app
  - Navigate to profile
  - Verify profile photo is still displayed

- [ ] **Testing Checkpoint 1.2: Test large photo compression**
  - Upload photo larger than 10MB
  - Verify compression occurs (check logs or file size)
  - Verify quality is maintained (visual inspection)
  - Verify upload succeeds

- [ ] **Testing Checkpoint 1.2: Test upload error handling**
  - Enable airplane mode
  - Attempt photo upload
  - Verify error message appears with clear explanation
  - Verify retry option is available

- [ ] **Testing Checkpoint 1.2: Test upload retry**
  - After upload error with airplane mode
  - Disable airplane mode
  - Tap 'Try Again' button
  - Verify upload succeeds

- [ ] **Testing Checkpoint 1.2: Test photo appears in contacts**
  - After successful upload
  - Log in with another user account on different device or simulator
  - Navigate to contacts list
  - Verify updated photo appears for the user who uploaded

- [ ] **Testing Checkpoint 1.2: Test camera option (if implemented)**
  - Select 'Take Photo' option from dialog
  - Verify camera opens
  - Take photo
  - Verify upload flow works same as library selection

- [ ] **Testing Checkpoint 1.2: Test photo UI in appearance modes**
  - Test profile photo upload flow in light mode
  - Test profile photo upload flow in dark mode
  - Verify all states (idle, selecting, uploading, success, error) render correctly in both modes

---

## Integration Testing

### Cross-Feature Testing

- [ ] **Integration Testing: Test both features together**
  - Perform complete workflow on fresh app launch
  - Load contacts (verify fix works)
  - Navigate to profile
  - Upload photo (verify fix works)
  - Verify photo updates in profile
  - Return to contacts tab
  - Verify contacts still load correctly (no regressions)

- [ ] **Integration Testing: Verify performance benchmarks**
  - Test app launch time (target less than 2-3 seconds)
  - Test contacts load time (target less than 2 seconds)
  - Test photo upload time (target less than 5 seconds)
  - Use Xcode Instruments if needed to measure accurately

- [ ] **Integration Testing: Test memory usage**
  - Run app through both features multiple times
  - Check for memory leaks using Xcode Instruments
  - Verify memory usage stays within acceptable range
  - Verify no memory growth after repeated operations

---

## Code Quality & Documentation

### Final Checks

- [ ] **Code Quality: Run linter and fix any errors**
  - Check for new linter errors or warnings introduced by changes
  - Resolve all issues
  - Ensure code follows project style guidelines

- [ ] **Documentation: Add inline code documentation**
  - Add comments explaining the fixes in ContactListViewModel
  - Add comments explaining the fixes in ProfileViewModel
  - Add comments explaining the fixes in PhotoService
  - Document any non-obvious logic or workarounds

---

## Final Review

### Definition of Done Verification

- [ ] **Final Review: Complete PRD Definition of Done checklist**
  - All acceptance gates pass for both subphases
  - Tested on iPhone 17 simulator
  - Tested in both light mode and dark mode
  - No new linter errors or warnings
  - No crashes or performance regressions
  - Error messages are clear and user-friendly
  - Ready for production deployment

---

## Notes

**Testing Tips:**
- Use iPhone 17 simulator (ID: 1454571E-CB3D-4C96-87D9-D357C6BB5585)
- Test with airplane mode for network error scenarios
- Test with fresh app install or cleared data for first-time user experience
- Test appearance modes using simulator appearance settings

**Common Issues to Watch For:**
- Contacts view lifecycle timing (onAppear may be called multiple times)
- Photo picker permissions (ensure Info.plist entries exist)
- Firebase Storage rules (verify upload permissions)
- Large photo handling (ensure compression works for very large images)
- State management (ensure @Published properties update UI correctly)

**Success Criteria Reminder:**
- Contacts first-load success rate: 100%
- Profile photo upload success rate: 100%
- Contacts load time: <2s
- Photo upload time: <5s

---

## Progress Tracking

**Investigation**: 0/4 complete
**Subphase 1.1 Implementation**: 0/6 complete
**Subphase 1.1 Testing**: 0/8 complete
**Subphase 1.2 Implementation**: 0/13 complete
**Subphase 1.2 Testing**: 0/10 complete
**Integration Testing**: 0/3 complete
**Code Quality**: 0/2 complete
**Final Review**: 0/1 complete

**Total Progress**: 0/47 tasks complete


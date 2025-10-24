# MessageAI Troubleshooting Guide

This guide covers common setup and development issues. If you don't find your issue here, check the [GitHub Issues](https://github.com/niftyclaudia/message-ai/issues) or ask for help.

**Last Updated**: PR #008

---

## Table of Contents

- [Firebase Configuration Issues](#firebase-configuration-issues)
- [Build & Xcode Issues](#build--xcode-issues)
- [Cloud Functions Issues](#cloud-functions-issues)
- [System & Environment Issues](#system--environment-issues)
- [Runtime Issues](#runtime-issues)
- [Getting Help](#getting-help)

---

## Firebase Configuration Issues

### Issue: GoogleService-Info.plist not found

**Symptom**: Build fails with "GoogleService-Info.plist not found" error

**Solution**:
```bash
# 1. Copy the template file
cp MessageAI/MessageAI/GoogleService-Info.template.plist MessageAI/MessageAI/GoogleService-Info.plist

# 2. Open the file and replace all placeholders
# Get your credentials from: https://console.firebase.google.com/
# Project Settings → Your Apps → Download GoogleService-Info.plist

# 3. Validate configuration
npm run validate:config
```

**Why this happens**: The actual `GoogleService-Info.plist` is not committed to git for security reasons. You must create it from the template.

---

### Issue: Firebase configuration invalid - placeholder values detected

**Symptom**: Validation fails with "Placeholder found: PROJECT_ID"

**Solution**:
```bash
# 1. Open your GoogleService-Info.plist
open MessageAI/MessageAI/GoogleService-Info.plist

# 2. Find and replace ALL values that start with "REPLACE_WITH_YOUR_"
# Get real values from Firebase Console:
# https://console.firebase.google.com/ → Project Settings → General → Your apps

# 3. Required fields:
# - PROJECT_ID (e.g., "messageai-prod")
# - API_KEY (e.g., "AIzaSyD...")
# - GCM_SENDER_ID (e.g., "123456789")
# - STORAGE_BUCKET (e.g., "messageai-prod.firebasestorage.app")
# - CLIENT_ID (e.g., "123456789.apps.googleusercontent.com")
# - GOOGLE_APP_ID (e.g., "1:123456789:ios:abc123")

# 4. Validate again
npm run validate:config
```

**Pro tip**: Download the correct `GoogleService-Info.plist` directly from Firebase Console instead of editing the template manually.

---

### Issue: Firebase authentication failed

**Symptom**: App crashes or shows "Firebase auth error" when signing in

**Solution**:
```bash
# 1. Verify your GoogleService-Info.plist has correct credentials
npm run validate:config

# 2. Check Firebase Console → Authentication → Sign-in method
# Enable "Email/Password" authentication

# 3. If you downloaded a new GoogleService-Info.plist:
# - Clean build folder in Xcode: Cmd+Shift+K
# - Delete app from simulator/device
# - Rebuild and run

# 4. Check Firebase project is active (not in free trial expiry)
# Go to: https://console.firebase.google.com/ → Your project → Usage
```

---

### Issue: "No Firebase App '[DEFAULT]' has been created"

**Symptom**: App crashes immediately on launch with Firebase error

**Solution**:
```swift
// This usually means GoogleService-Info.plist is missing or malformed

// 1. Verify file exists and is in the correct location:
ls -la MessageAI/MessageAI/GoogleService-Info.plist

// 2. Check Xcode project includes the file:
// - Open Xcode
// - Select MessageAI/MessageAI/GoogleService-Info.plist
// - In right sidebar, ensure "Target Membership" → MessageAI is checked

// 3. Clean and rebuild:
// Cmd+Shift+K (clean) → Cmd+B (build)
```

---

## Build & Xcode Issues

### Issue: "Code signing failed" or "No signing certificate found"

**Symptom**: Build fails with code signing errors

**Solution**:
```bash
# Option 1: Automatic signing (recommended for development)
# 1. Open Xcode
# 2. Select MessageAI project in navigator
# 3. Select MessageAI target
# 4. Signing & Capabilities tab
# 5. Check "Automatically manage signing"
# 6. Select your Apple ID team

# Option 2: Manual signing
# 1. Create a signing certificate in Apple Developer Portal
# 2. Download and install the certificate
# 3. In Xcode, uncheck "Automatically manage signing"
# 4. Select your provisioning profile
```

**Note**: Physical device testing requires paid Apple Developer account ($99/year). Simulator testing is free.

---

### Issue: "Module 'Firebase' not found" or "No such module 'FirebaseAuth'"

**Symptom**: Build fails with missing Firebase modules

**Solution**:
```bash
# 1. Reset Swift Package Manager cache
# In Xcode: File → Packages → Reset Package Caches

# 2. Update packages
# File → Packages → Update to Latest Package Versions

# 3. If still failing, clean build folder
# Cmd+Shift+K

# 4. Quit Xcode, delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 5. Reopen Xcode and build
open MessageAI/MessageAI.xcodeproj
# Cmd+B to build
```

---

### Issue: Linker errors or "Undefined symbol" errors

**Symptom**: Build fails with linker errors like "Undefined symbol _OBJC_CLASS_$_FIRApp"

**Solution**:
```bash
# 1. Clean build folder
# Xcode: Product → Clean Build Folder (Cmd+Shift+K)

# 2. Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 3. Reset Swift Package Manager
# Xcode: File → Packages → Reset Package Caches

# 4. Rebuild
# Cmd+B

# If problem persists:
# 5. Check Framework Search Paths in Build Settings
# Should be empty or $(inherited) only
```

---

### Issue: SwiftLint warnings or errors

**Symptom**: Build succeeds but shows SwiftLint warnings

**Solution**:
```bash
# SwiftLint warnings are non-blocking and can be addressed later

# To fix automatically fixable issues:
swiftlint autocorrect

# To disable SwiftLint temporarily:
# Comment out the SwiftLint build phase in Xcode
# (Not recommended for PRs)

# To install SwiftLint:
brew install swiftlint
```

---

## Cloud Functions Issues

### Issue: Firebase emulators won't start

**Symptom**: `npm run dev` fails or emulators timeout

**Solution**:
```bash
# 1. Check if ports are already in use
lsof -ti:5001,8080,9099 | xargs kill -9

# 2. Alternative: Change emulator ports in firebase.json
# Edit "emulators" section to use different ports

# 3. Ensure Firebase CLI is installed
firebase --version
# If not installed:
npm install -g firebase-tools

# 4. Login to Firebase
firebase login

# 5. Select correct Firebase project
firebase use <your-project-id>

# 6. Try starting emulators again
npm run dev
```

---

### Issue: "OpenAI API key invalid" or "OPENAI_API_KEY not set"

**Symptom**: AI features fail with OpenAI errors

**Solution**:
```bash
# AI features are OPTIONAL - core messaging works without them

# To enable AI features:
# 1. Copy functions/.env.template to functions/.env.local
cp functions/.env.template functions/.env.local

# 2. Get OpenAI API key from: https://platform.openai.com/account/api-keys

# 3. Add to functions/.env.local:
OPENAI_API_KEY=sk-proj-your-actual-key-here

# 4. Validate
npm run validate:config

# 5. Restart emulators
npm run dev
```

---

### Issue: "Pinecone connection failed"

**Symptom**: Semantic search fails with Pinecone errors

**Solution**:
```bash
# Pinecone is OPTIONAL - only needed for semantic search

# To enable semantic search:
# 1. Sign up for Pinecone: https://www.pinecone.io

# 2. Create an index:
# - Name: messageai-prod (or your preference)
# - Dimensions: 1536 (for OpenAI text-embedding-3-small)
# - Metric: Cosine similarity

# 3. Get API key and environment from Pinecone dashboard

# 4. Add to functions/.env.local:
PINECONE_API_KEY=pcsk-your-key-here
PINECONE_ENVIRONMENT=us-east-1-aws
PINECONE_INDEX=messageai-prod

# 5. Validate and restart
npm run validate:config
npm run dev
```

---

### Issue: Cloud Functions deployment fails

**Symptom**: `npm run deploy:functions` fails with errors

**Solution**:
```bash
# 1. Ensure you're logged in to Firebase
firebase login

# 2. Set the correct Firebase project
firebase use <your-project-id>

# 3. Verify you have the Blaze plan (required for Cloud Functions)
# Check: https://console.firebase.google.com/ → Your project → Usage and billing

# 4. Build functions first
npm run build:functions

# 5. Deploy
firebase deploy --only functions

# For production deployment with config:
firebase functions:config:set openai.api_key="sk-proj-..."
firebase functions:config:set pinecone.api_key="pcsk-..."
firebase deploy --only functions
```

---

## System & Environment Issues

### Issue: "Xcode not found" or "xcode-select: error"

**Symptom**: Setup script fails with Xcode errors

**Solution**:
```bash
# Install Xcode from App Store (required for iOS development)
# https://apps.apple.com/app/xcode/id497799835

# After installing Xcode:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept

# Verify installation:
xcodebuild -version
```

---

### Issue: "Node.js version too old" (need 18+)

**Symptom**: Setup fails with "Node.js 18.0.0+ required"

**Solution**:
```bash
# Option 1: Install Node.js directly
# Download from: https://nodejs.org/

# Option 2: Use nvm (recommended for managing Node versions)
# Install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install Node 18+:
nvm install 18
nvm use 18
nvm alias default 18

# Verify:
node -v  # Should show v18.x.x or higher
```

---

### Issue: "Permission denied" when running scripts

**Symptom**: `./setup.sh: Permission denied`

**Solution**:
```bash
# Make scripts executable:
chmod +x setup.sh
chmod +x validate-config.sh

# Or run with npm (automatically uses correct permissions):
npm run setup
npm run validate:config
```

---

### Issue: "Firebase CLI not found"

**Symptom**: `firebase: command not found`

**Solution**:
```bash
# Install Firebase CLI globally:
npm install -g firebase-tools

# Or use sudo if you get permission errors:
sudo npm install -g firebase-tools

# Verify installation:
firebase --version

# Login:
firebase login
```

---

## Runtime Issues

### Issue: App crashes immediately on launch

**Symptom**: App builds successfully but crashes when opened

**Solution**:
```bash
# 1. Check Xcode console for crash logs
# Look for error messages starting with "[Firebase]" or "[App]"

# 2. Most common cause: Missing GoogleService-Info.plist
npm run validate:config

# 3. Clean and rebuild:
# Cmd+Shift+K (clean) → Cmd+B (build) → Cmd+R (run)

# 4. Delete app from simulator and reinstall:
# iOS Simulator → Device → Erase All Content and Settings
# Then rebuild and run

# 5. Check for breakpoints:
# Cmd+Y to disable all breakpoints temporarily
```

---

### Issue: "Could not connect to Firebase" at runtime

**Symptom**: App launches but can't sign in or load data

**Solution**:
```bash
# 1. Check internet connection

# 2. Verify Firebase project is active:
# https://console.firebase.google.com/ → Your project

# 3. Check Firestore database exists and has correct rules:
# Firebase Console → Firestore Database → Should see "Cloud Firestore" section

# 4. Verify authentication is enabled:
# Firebase Console → Authentication → Sign-in method → Email/Password enabled

# 5. Check Firebase status:
# https://status.firebase.google.com/

# 6. If using emulators locally, ensure they're running:
npm run dev
```

---

### Issue: Messages not syncing in real-time

**Symptom**: Messages appear slowly or don't sync across devices

**Solution**:
```bash
# 1. Check Firestore offline persistence is enabled (it is by default)

# 2. Verify Firestore listeners are active:
# Check Xcode console for "[Firestore]" logs

# 3. Test network connection:
# Toggle airplane mode off
# Try on different network

# 4. Check Firestore security rules allow reading messages:
# Firebase Console → Firestore → Rules → Should see "allow read" for messages

# 5. Test on physical device (not just simulator)
# Real-time sync is most reliable on physical devices

# 6. Check Firebase usage limits:
# Firebase Console → Usage → Ensure not hitting quota limits
```

---

## Getting Help

If you've tried the solutions above and still have issues:

### 1. Check Documentation
- **README.md**: Setup and architecture overview
- **TROUBLESHOOTING.md**: This file
- **functions/README.md**: Cloud Functions specific setup
- **MessageAI/docs/**: Detailed PRDs and implementation guides

### 2. Search GitHub Issues
- Check existing issues: https://github.com/niftyclaudia/message-ai/issues
- Look for similar problems and solutions

### 3. Create a New Issue
If your issue isn't covered:
1. Go to: https://github.com/niftyclaudia/message-ai/issues/new
2. Include:
   - **Setup step that failed** (e.g., "npm run setup")
   - **Error message** (full text, not screenshot)
   - **System info** (macOS version, Xcode version, Node version)
   - **What you've tried** (list troubleshooting steps you attempted)

### 4. Useful Diagnostic Commands

Run these commands and include output when asking for help:

```bash
# System information
sw_vers  # macOS version
xcodebuild -version  # Xcode version
node -v  # Node version
npm -v  # npm version
firebase --version  # Firebase CLI version

# Architecture
uname -m  # Intel (x86_64) or Apple Silicon (arm64)

# Validation
npm run validate:config  # Configuration check

# Check for common issues
ls -la MessageAI/MessageAI/GoogleService-Info.plist  # Should exist
ls -la functions/.env.local  # Optional, for AI features
```

---

## Known Issues & Workarounds

### Issue: iOS Simulator performance slow on Intel Macs

**Workaround**: Test on physical device instead, or use Rosetta 2 if on Apple Silicon.

### Issue: Firebase emulators use a lot of disk space

**Workaround**: Clear emulator data periodically:
```bash
rm -rf ~/.firebase/emulators
```

### Issue: Push notifications don't work in iOS Simulator

**This is expected**: Push notifications require a physical device. Use Xcode Console → Debug → Simulate Remote Notification for testing in simulator.

---

## Prevention Tips

### Before Making Changes
1. **Always work on a feature branch**, not `main` or `develop`
2. **Run tests** before creating a PR: `npm run test:all`
3. **Validate configuration**: `npm run validate:config`

### After Pulling New Code
1. **Update dependencies**: `npm run setup:functions`
2. **Validate configuration**: `npm run validate:config`
3. **Clean build**: Cmd+Shift+K in Xcode

### Regular Maintenance
1. **Update Xcode** from App Store monthly
2. **Update Firebase CLI**: `npm install -g firebase-tools`
3. **Update Node.js** to latest LTS: https://nodejs.org/

---

## Still Stuck?

If you're still having issues:
1. Try the **nuclear option**:
   ```bash
   # Clean everything and start fresh
   rm -rf node_modules functions/node_modules
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   npm run setup
   npm run validate:config
   ```

2. **Ask for help** with detailed information:
   - Exact error message
   - Steps to reproduce
   - Output of `npm run validate:config`
   - macOS, Xcode, Node versions

---

**Last Updated**: PR #008  
**Need to update this guide?** PRs welcome! See `MessageAI/docs/todos/pr-008-todo.md`


# Security Rule Tests

## Overview

This directory contains security rule tests for Firestore, Realtime Database, and Storage.

## Running Tests

### Prerequisites

1. Install dependencies:
```bash
cd functions
npm install
```

2. Start Firebase Emulators:
```bash
firebase emulators:start --only firestore
```

3. In a new terminal, run tests:
```bash
npm test
```

### Test Commands

- **Run all tests**: `npm test`
- **Run security tests only**: `npm run test:security`
- **Watch mode**: `npm run test:watch`

## Test Coverage

### Firestore Security Rules (`firestore-rules.test.js`)

Tests cover:

#### Users Collection
- ✅ Authenticated users can read any user profile (contact discovery)
- ✅ Unauthenticated users cannot read profiles
- ✅ Users can create their own profile with valid data
- ✅ Invalid data (email, display name) is rejected
- ✅ Users cannot create other users' profiles
- ✅ Users can update their own profile
- ✅ Immutable fields (email, ID, createdAt) cannot be changed
- ✅ User documents cannot be deleted

#### Chats Collection
- ✅ Chat members can read chats
- ✅ Non-members cannot read chats
- ✅ Users can create chats where they are members
- ✅ Users cannot create chats where they are not members
- ✅ Members can update chats (typing indicators, last message)
- ✅ Chats cannot be deleted

#### Messages Subcollection
- ✅ Chat members can read messages
- ✅ Non-members cannot read messages
- ✅ Members can create messages with matching senderID
- ✅ Forged senderID is rejected (prevents impersonation)
- ✅ Senders can update their own messages
- ✅ Members can update read receipts
- ✅ Messages cannot be deleted

#### AI Preferences
- ✅ Users can read/write their own preferences
- ✅ Users cannot access other users' preferences
- ✅ Validation constraints enforced:
  - Max 20 urgent contacts
  - Min 3 urgent keywords
  - Max 50 urgent keywords

#### AI Learning Data
- ✅ Users can read/write their own learning data
- ✅ Users cannot access other users' learning data
- ✅ Users can delete their own learning data (90-day cleanup)

## Test Users

The tests use these test user IDs:
- `alice_uid` - Primary test user
- `bob_uid` - Secondary test user (chat participant)
- `charlie_uid` - Non-participant user (for access denial tests)
- `malicious_uid` - Malicious user (for security tests)

## Adding New Tests

When adding new collections or rules:

1. Create test data constants at the top of the file
2. Add a new `describe()` block for the collection
3. Test all CRUD operations (create, read, update, delete)
4. Test edge cases (unauthorized access, invalid data, constraints)
5. Use `assertSucceeds()` for valid operations
6. Use `assertFails()` for invalid operations

## Debugging Failed Tests

If tests fail:

1. Check emulator is running on port 8081
2. Verify `firestore.rules` syntax is correct
3. Check test user IDs match rule conditions
4. Review Firebase Emulator logs for detailed error messages

## CI/CD Integration

These tests should run automatically in CI/CD pipeline before deployment:

```bash
# Start emulators in background
firebase emulators:start --only firestore &
EMULATOR_PID=$!

# Run tests
npm test

# Stop emulators
kill $EMULATOR_PID
```

## Resources

- [Firebase Rules Unit Testing](https://firebase.google.com/docs/rules/unit-tests)
- [Firestore Security Rules Reference](https://firebase.google.com/docs/firestore/security/rules-structure)
- [Jest Documentation](https://jestjs.io/docs/getting-started)


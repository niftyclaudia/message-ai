/**
 * Firestore Security Rules Tests
 * 
 * Tests the security rules defined in firestore.rules
 * Run with: npm test
 */

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');
const { resolve } = require('path');

let testEnv;

// Test user IDs
const ALICE_UID = 'alice_uid';
const BOB_UID = 'bob_uid';
const CHARLIE_UID = 'charlie_uid';
const MALICIOUS_UID = 'malicious_uid';

// Test data
const ALICE_USER = {
  id: ALICE_UID,
  email: 'alice@example.com',
  displayName: 'Alice',
  createdAt: new Date().toISOString()
};

const CHAT_ID = 'chat_123';
const DIRECT_CHAT = {
  id: CHAT_ID,
  type: 'direct',
  members: [ALICE_UID, BOB_UID],
  createdAt: new Date().toISOString()
};

const MESSAGE_ID = 'msg_123';
const MESSAGE = {
  id: MESSAGE_ID,
  senderID: ALICE_UID,
  text: 'Hello Bob!',
  timestamp: new Date().toISOString(),
  status: 'sent'
};

describe('Firestore Security Rules', () => {
  
  beforeAll(async () => {
    // Initialize test environment with security rules
    testEnv = await initializeTestEnvironment({
      projectId: 'messageai-test',
      firestore: {
        rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
        host: 'localhost',
        port: 8081
      }
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  // ============================================================================
  // USERS COLLECTION TESTS
  // ============================================================================

  describe('Users Collection', () => {
    
    it('should allow authenticated user to read any user profile', async () => {
      // Setup: Create Alice's profile
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc(ALICE_UID).set(ALICE_USER);
      });

      // Test: Bob (authenticated) can read Alice's profile
      const bobContext = testEnv.authenticatedContext(BOB_UID);
      const aliceDoc = bobContext.firestore().collection('users').doc(ALICE_UID);
      
      await assertSucceeds(aliceDoc.get());
    });

    it('should deny unauthenticated user from reading user profiles', async () => {
      // Setup: Create Alice's profile
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc(ALICE_UID).set(ALICE_USER);
      });

      // Test: Unauthenticated user cannot read Alice's profile
      const unauthContext = testEnv.unauthenticatedContext();
      const aliceDoc = unauthContext.firestore().collection('users').doc(ALICE_UID);
      
      await assertFails(aliceDoc.get());
    });

    it('should allow user to create their own profile with valid data', async () => {
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const aliceDoc = aliceContext.firestore().collection('users').doc(ALICE_UID);
      
      await assertSucceeds(aliceDoc.set(ALICE_USER));
    });

    it('should deny user from creating profile with invalid email', async () => {
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const aliceDoc = aliceContext.firestore().collection('users').doc(ALICE_UID);
      
      const invalidUser = {
        ...ALICE_USER,
        email: 'not-an-email'  // Invalid email format
      };
      
      await assertFails(aliceDoc.set(invalidUser));
    });

    it('should deny user from creating profile with empty display name', async () => {
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const aliceDoc = aliceContext.firestore().collection('users').doc(ALICE_UID);
      
      const invalidUser = {
        ...ALICE_USER,
        displayName: ''  // Empty display name
      };
      
      await assertFails(aliceDoc.set(invalidUser));
    });

    it('should deny user from creating another user\'s profile', async () => {
      const bobContext = testEnv.authenticatedContext(BOB_UID);
      const aliceDoc = bobContext.firestore().collection('users').doc(ALICE_UID);
      
      await assertFails(aliceDoc.set(ALICE_USER));
    });

    it('should allow user to update their own profile', async () => {
      // Setup: Create Alice's profile
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc(ALICE_UID).set(ALICE_USER);
      });

      // Test: Alice can update her own displayName
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const aliceDoc = aliceContext.firestore().collection('users').doc(ALICE_UID);
      
      await assertSucceeds(aliceDoc.update({
        displayName: 'Alice Updated'
      }));
    });

    it('should deny user from changing immutable fields', async () => {
      // Setup: Create Alice's profile
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc(ALICE_UID).set(ALICE_USER);
      });

      // Test: Alice cannot change her email (immutable)
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const aliceDoc = aliceContext.firestore().collection('users').doc(ALICE_UID);
      
      await assertFails(aliceDoc.update({
        email: 'newemail@example.com'
      }));
    });

    it('should deny user from deleting user documents', async () => {
      // Setup: Create Alice's profile
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('users').doc(ALICE_UID).set(ALICE_USER);
      });

      // Test: Alice cannot delete her own profile
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const aliceDoc = aliceContext.firestore().collection('users').doc(ALICE_UID);
      
      await assertFails(aliceDoc.delete());
    });
  });

  // ============================================================================
  // CHATS COLLECTION TESTS
  // ============================================================================

  describe('Chats Collection', () => {
    
    it('should allow chat member to read chat', async () => {
      // Setup: Create chat between Alice and Bob
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('chats').doc(CHAT_ID).set(DIRECT_CHAT);
      });

      // Test: Alice (member) can read the chat
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const chatDoc = aliceContext.firestore().collection('chats').doc(CHAT_ID);
      
      await assertSucceeds(chatDoc.get());
    });

    it('should deny non-member from reading chat', async () => {
      // Setup: Create chat between Alice and Bob
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('chats').doc(CHAT_ID).set(DIRECT_CHAT);
      });

      // Test: Charlie (not a member) cannot read the chat
      const charlieContext = testEnv.authenticatedContext(CHARLIE_UID);
      const chatDoc = charlieContext.firestore().collection('chats').doc(CHAT_ID);
      
      await assertFails(chatDoc.get());
    });

    it('should allow user to create chat where they are a member', async () => {
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const chatDoc = aliceContext.firestore().collection('chats').doc(CHAT_ID);
      
      await assertSucceeds(chatDoc.set(DIRECT_CHAT));
    });

    it('should deny user from creating chat where they are not a member', async () => {
      const charlieContext = testEnv.authenticatedContext(CHARLIE_UID);
      const chatDoc = charlieContext.firestore().collection('chats').doc(CHAT_ID);
      
      await assertFails(chatDoc.set(DIRECT_CHAT));
    });

    it('should allow member to update chat', async () => {
      // Setup: Create chat between Alice and Bob
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('chats').doc(CHAT_ID).set(DIRECT_CHAT);
      });

      // Test: Alice can update chat (e.g., last message)
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const chatDoc = aliceContext.firestore().collection('chats').doc(CHAT_ID);
      
      await assertSucceeds(chatDoc.update({
        lastMessage: 'Updated message'
      }));
    });

    it('should deny deleting chats', async () => {
      // Setup: Create chat between Alice and Bob
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('chats').doc(CHAT_ID).set(DIRECT_CHAT);
      });

      // Test: Alice cannot delete the chat
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const chatDoc = aliceContext.firestore().collection('chats').doc(CHAT_ID);
      
      await assertFails(chatDoc.delete());
    });
  });

  // ============================================================================
  // MESSAGES SUBCOLLECTION TESTS
  // ============================================================================

  describe('Messages Subcollection', () => {
    
    beforeEach(async () => {
      // Setup: Create chat between Alice and Bob
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('chats').doc(CHAT_ID).set(DIRECT_CHAT);
      });
    });

    it('should allow chat member to read messages', async () => {
      // Setup: Create message
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore()
          .collection('chats').doc(CHAT_ID)
          .collection('messages').doc(MESSAGE_ID)
          .set(MESSAGE);
      });

      // Test: Bob (member) can read messages
      const bobContext = testEnv.authenticatedContext(BOB_UID);
      const messageDoc = bobContext.firestore()
        .collection('chats').doc(CHAT_ID)
        .collection('messages').doc(MESSAGE_ID);
      
      await assertSucceeds(messageDoc.get());
    });

    it('should deny non-member from reading messages', async () => {
      // Setup: Create message
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore()
          .collection('chats').doc(CHAT_ID)
          .collection('messages').doc(MESSAGE_ID)
          .set(MESSAGE);
      });

      // Test: Charlie (not a member) cannot read messages
      const charlieContext = testEnv.authenticatedContext(CHARLIE_UID);
      const messageDoc = charlieContext.firestore()
        .collection('chats').doc(CHAT_ID)
        .collection('messages').doc(MESSAGE_ID);
      
      await assertFails(messageDoc.get());
    });

    it('should allow member to create message with matching senderID', async () => {
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const messageDoc = aliceContext.firestore()
        .collection('chats').doc(CHAT_ID)
        .collection('messages').doc(MESSAGE_ID);
      
      await assertSucceeds(messageDoc.set(MESSAGE));
    });

    it('should deny creating message with forged senderID', async () => {
      const bobContext = testEnv.authenticatedContext(BOB_UID);
      const messageDoc = bobContext.firestore()
        .collection('chats').doc(CHAT_ID)
        .collection('messages').doc(MESSAGE_ID);
      
      // Bob tries to send message pretending to be Alice
      const forgedMessage = {
        ...MESSAGE,
        senderID: ALICE_UID  // Forged!
      };
      
      await assertFails(messageDoc.set(forgedMessage));
    });

    it('should allow sender to update their own message', async () => {
      // Setup: Create message from Alice
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore()
          .collection('chats').doc(CHAT_ID)
          .collection('messages').doc(MESSAGE_ID)
          .set(MESSAGE);
      });

      // Test: Alice can update her own message
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const messageDoc = aliceContext.firestore()
        .collection('chats').doc(CHAT_ID)
        .collection('messages').doc(MESSAGE_ID);
      
      await assertSucceeds(messageDoc.update({
        status: 'delivered'
      }));
    });

    it('should allow member to update read receipts', async () => {
      // Setup: Create message from Alice
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore()
          .collection('chats').doc(CHAT_ID)
          .collection('messages').doc(MESSAGE_ID)
          .set({ ...MESSAGE, readBy: [] });
      });

      // Test: Bob can update read receipt
      const bobContext = testEnv.authenticatedContext(BOB_UID);
      const messageDoc = bobContext.firestore()
        .collection('chats').doc(CHAT_ID)
        .collection('messages').doc(MESSAGE_ID);
      
      await assertSucceeds(messageDoc.update({
        readBy: [BOB_UID],
        readAt: new Date().toISOString()
      }));
    });

    it('should deny deleting messages', async () => {
      // Setup: Create message from Alice
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore()
          .collection('chats').doc(CHAT_ID)
          .collection('messages').doc(MESSAGE_ID)
          .set(MESSAGE);
      });

      // Test: Alice cannot delete her own message
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const messageDoc = aliceContext.firestore()
        .collection('chats').doc(CHAT_ID)
        .collection('messages').doc(MESSAGE_ID);
      
      await assertFails(messageDoc.delete());
    });
  });

  // ============================================================================
  // AI PREFERENCES TESTS
  // ============================================================================

  describe('AI Preferences', () => {
    
    const PREFERENCES = {
      urgentContacts: [BOB_UID],
      urgentKeywords: ['urgent', 'asap', 'important'],
      focusHours: { enabled: true, startTime: '09:00', endTime: '17:00' }
    };

    it('should allow user to read their own preferences', async () => {
      // Setup: Create Alice's preferences
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore()
          .collection('users').doc(ALICE_UID)
          .collection('preferences').doc('main')
          .set(PREFERENCES);
      });

      // Test: Alice can read her own preferences
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const prefDoc = aliceContext.firestore()
        .collection('users').doc(ALICE_UID)
        .collection('preferences').doc('main');
      
      await assertSucceeds(prefDoc.get());
    });

    it('should deny user from reading another user\'s preferences', async () => {
      // Setup: Create Alice's preferences
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore()
          .collection('users').doc(ALICE_UID)
          .collection('preferences').doc('main')
          .set(PREFERENCES);
      });

      // Test: Bob cannot read Alice's preferences
      const bobContext = testEnv.authenticatedContext(BOB_UID);
      const prefDoc = bobContext.firestore()
        .collection('users').doc(ALICE_UID)
        .collection('preferences').doc('main');
      
      await assertFails(prefDoc.get());
    });

    it('should allow user to write their own preferences with valid constraints', async () => {
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const prefDoc = aliceContext.firestore()
        .collection('users').doc(ALICE_UID)
        .collection('preferences').doc('main');
      
      await assertSucceeds(prefDoc.set(PREFERENCES));
    });

    it('should deny preferences with too many urgent contacts', async () => {
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const prefDoc = aliceContext.firestore()
        .collection('users').doc(ALICE_UID)
        .collection('preferences').doc('main');
      
      const invalidPrefs = {
        ...PREFERENCES,
        urgentContacts: new Array(21).fill('user_id')  // Exceeds 20 limit
      };
      
      await assertFails(prefDoc.set(invalidPrefs));
    });

    it('should deny preferences with too few urgent keywords', async () => {
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const prefDoc = aliceContext.firestore()
        .collection('users').doc(ALICE_UID)
        .collection('preferences').doc('main');
      
      const invalidPrefs = {
        ...PREFERENCES,
        urgentKeywords: ['urgent', 'asap']  // Less than 3 minimum
      };
      
      await assertFails(prefDoc.set(invalidPrefs));
    });
  });

  // ============================================================================
  // AI LEARNING DATA TESTS
  // ============================================================================

  describe('AI Learning Data', () => {
    
    const LEARNING_DATA = {
      timestamp: new Date().toISOString(),
      action: 'message_sent',
      context: { chatId: CHAT_ID }
    };

    it('should allow user to read their own learning data', async () => {
      // Setup: Create learning data
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore()
          .collection('users').doc(ALICE_UID)
          .collection('aiState').doc('learningData')
          .collection('entries').doc('entry_1')
          .set(LEARNING_DATA);
      });

      // Test: Alice can read her own learning data
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const dataDoc = aliceContext.firestore()
        .collection('users').doc(ALICE_UID)
        .collection('aiState').doc('learningData')
        .collection('entries').doc('entry_1');
      
      await assertSucceeds(dataDoc.get());
    });

    it('should deny user from reading another user\'s learning data', async () => {
      // Setup: Create learning data
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore()
          .collection('users').doc(ALICE_UID)
          .collection('aiState').doc('learningData')
          .collection('entries').doc('entry_1')
          .set(LEARNING_DATA);
      });

      // Test: Bob cannot read Alice's learning data
      const bobContext = testEnv.authenticatedContext(BOB_UID);
      const dataDoc = bobContext.firestore()
        .collection('users').doc(ALICE_UID)
        .collection('aiState').doc('learningData')
        .collection('entries').doc('entry_1');
      
      await assertFails(dataDoc.get());
    });

    it('should allow user to delete their own learning data', async () => {
      // Setup: Create learning data
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore()
          .collection('users').doc(ALICE_UID)
          .collection('aiState').doc('learningData')
          .collection('entries').doc('entry_1')
          .set(LEARNING_DATA);
      });

      // Test: Alice can delete her own learning data (90-day cleanup)
      const aliceContext = testEnv.authenticatedContext(ALICE_UID);
      const dataDoc = aliceContext.firestore()
        .collection('users').doc(ALICE_UID)
        .collection('aiState').doc('learningData')
        .collection('entries').doc('entry_1');
      
      await assertSucceeds(dataDoc.delete());
    });
  });
});


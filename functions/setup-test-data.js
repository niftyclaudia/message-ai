/**
 * Script to populate Firestore emulator with test data
 * Run with: node setup-test-data.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin for emulator
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'demo-project', // Use demo project for emulator
  });
}

const db = admin.firestore();

async function setupTestData() {
  console.log('Setting up Firestore test data...');
  
  try {
    // 1. Create chat document
    console.log('Creating chat document...');
    await db.collection('chats').doc('chat123').set({
      members: ['user1', 'user2', 'user3'],
      isGroupChat: true
    });
    console.log('✓ Chat document created');

    // 2. Create user documents
    console.log('Creating user documents...');
    
    await db.collection('users').doc('user1').set({
      displayName: 'User 1',
      fcmToken: 'token1'
    });
    console.log('✓ User 1 created');

    await db.collection('users').doc('user2').set({
      displayName: 'User 2',
      fcmToken: 'token2'
    });
    console.log('✓ User 2 created');

    await db.collection('users').doc('user3').set({
      displayName: 'User 3',
      fcmToken: 'token3'
    });
    console.log('✓ User 3 created');

    // 3. Create message document (this will trigger the cloud function)
    console.log('Creating message document...');
    await db.collection('chats').doc('chat123').collection('messages').doc('msg456').set({
      text: 'Hello world!',
      senderID: 'user1',
      chatID: 'chat123',
      messageID: 'msg456'
    });
    console.log('✓ Message document created');

    // 4. Create additional test scenarios
    console.log('Creating additional test data...');
    
    // Chat with only one member (for "no recipients" test)
    await db.collection('chats').doc('chat456').set({
      members: ['user1'],
      isGroupChat: false
    });
    console.log('✓ Single-member chat created');

    // User without FCM token (for "no valid tokens" test)
    await db.collection('users').doc('user4').set({
      displayName: 'User 4'
      // No fcmToken field
    });
    console.log('✓ User without FCM token created');

    // Chat with user who has no FCM token
    await db.collection('chats').doc('chat789').set({
      members: ['user1', 'user4'],
      isGroupChat: false
    });
    console.log('✓ Chat with user without FCM token created');

    console.log('\n🎉 All test data has been set up successfully!');
    console.log('\nTest scenarios available:');
    console.log('1. Normal notification flow: chat123 with 3 users');
    console.log('2. No recipients scenario: chat456 with 1 user');
    console.log('3. No valid FCM tokens: chat789 with user4 (no token)');
    console.log('\nYour tests should now pass! 🚀');

  } catch (error) {
    console.error('Error setting up test data:', error);
    process.exit(1);
  }
}

// Run the setup
setupTestData().then(() => {
  console.log('\nSetup complete. You can now run your tests!');
  process.exit(0);
}).catch(error => {
  console.error('Setup failed:', error);
  process.exit(1);
});

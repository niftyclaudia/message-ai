/**
 * Test setup for message classification system
 * This script helps test the classification system locally
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (for testing)
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'messageai-test', // Use test project
    credential: admin.credential.applicationDefault()
  });
}

const db = admin.firestore();

// Test data
const testMessages = [
  {
    id: 'test-urgent-1',
    chatID: 'test-chat-1',
    senderID: 'test-user-1',
    text: 'This is urgent! Please respond ASAP',
    timestamp: new Date(),
    readBy: [],
    readAt: {},
    status: 'sent',
    isOffline: false,
    retryCount: 0,
    isOptimistic: false
  },
  {
    id: 'test-normal-1',
    chatID: 'test-chat-1',
    senderID: 'test-user-2',
    text: 'Thanks for the update. Have a good day!',
    timestamp: new Date(),
    readBy: [],
    readAt: {},
    status: 'sent',
    isOffline: false,
    retryCount: 0,
    isOptimistic: false
  },
  {
    id: 'test-urgent-2',
    chatID: 'test-chat-2',
    senderID: 'test-user-1',
    text: 'Emergency: Server is down and we need immediate help',
    timestamp: new Date(),
    readBy: [],
    readAt: {},
    status: 'sent',
    isOffline: false,
    retryCount: 0,
    isOptimistic: false
  },
  {
    id: 'test-normal-2',
    chatID: 'test-chat-2',
    senderID: 'test-user-2',
    text: 'Hi, how are you doing?',
    timestamp: new Date(),
    readBy: [],
    readAt: {},
    status: 'sent',
    isOffline: false,
    retryCount: 0,
    isOptimistic: false
  }
];

async function setupTestData() {
  console.log('Setting up test data...');
  
  try {
    // Create test messages
    for (const message of testMessages) {
      await db.collection('messages').doc(message.id).set(message);
      console.log(`Created test message: ${message.id}`);
    }
    
    console.log('✅ Test data setup complete');
    console.log('\nTest messages created:');
    testMessages.forEach(msg => {
      console.log(`- ${msg.id}: "${msg.text}"`);
    });
    
  } catch (error) {
    console.error('❌ Error setting up test data:', error.message);
  }
}

async function checkClassifications() {
  console.log('\nChecking message classifications...');
  
  try {
    for (const message of testMessages) {
      const doc = await db.collection('messages').doc(message.id).get();
      
      if (doc.exists) {
        const data = doc.data();
        console.log(`\nMessage: ${message.id}`);
        console.log(`Text: "${message.text}"`);
        console.log(`Priority: ${data.priority || 'Not classified'}`);
        console.log(`Confidence: ${data.classificationConfidence || 'N/A'}`);
        console.log(`Method: ${data.classificationMethod || 'N/A'}`);
        console.log(`Timestamp: ${data.classificationTimestamp || 'N/A'}`);
      }
    }
  } catch (error) {
    console.error('❌ Error checking classifications:', error.message);
  }
}

async function checkClassificationLogs() {
  console.log('\nChecking classification logs...');
  
  try {
    const logs = await db.collection('classificationLogs')
      .where('messageID', 'in', testMessages.map(m => m.id))
      .get();
    
    console.log(`Found ${logs.docs.length} classification logs`);
    
    logs.docs.forEach(doc => {
      const data = doc.data();
      console.log(`\nLog for ${data.messageID}:`);
      console.log(`- Result: ${data.classificationResult}`);
      console.log(`- Confidence: ${data.confidence}`);
      console.log(`- Method: ${data.method}`);
      console.log(`- Processing Time: ${data.processingTimeMs}ms`);
      if (data.errorMessage) {
        console.log(`- Error: ${data.errorMessage}`);
      }
    });
    
  } catch (error) {
    console.error('❌ Error checking logs:', error.message);
  }
}

async function cleanupTestData() {
  console.log('\nCleaning up test data...');
  
  try {
    // Delete test messages
    for (const message of testMessages) {
      await db.collection('messages').doc(message.id).delete();
    }
    
    // Delete classification logs
    const logs = await db.collection('classificationLogs')
      .where('messageID', 'in', testMessages.map(m => m.id))
      .get();
    
    const batch = db.batch();
    logs.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    
    console.log('✅ Test data cleanup complete');
    
  } catch (error) {
    console.error('❌ Error cleaning up:', error.message);
  }
}

// Main test function
async function runTests() {
  console.log('🧪 Message Classification System Test\n');
  
  try {
    await setupTestData();
    
    console.log('\n⏳ Waiting 5 seconds for classification to complete...');
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    await checkClassifications();
    await checkClassificationLogs();
    
    console.log('\n📊 Test Summary:');
    console.log('- Check if urgent messages were classified as "urgent"');
    console.log('- Check if normal messages were classified as "normal"');
    console.log('- Verify classification logs were created');
    console.log('- Confirm processing times are reasonable (<3s)');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  } finally {
    // Ask user if they want to cleanup
    console.log('\n❓ Do you want to cleanup test data? (y/n)');
    // Note: In a real script, you'd use readline for user input
    // For now, we'll just show the cleanup function
    console.log('Run cleanupTestData() to remove test data');
  }
}

// Export functions for manual testing
module.exports = {
  setupTestData,
  checkClassifications,
  checkClassificationLogs,
  cleanupTestData,
  runTests
};

// Run tests if called directly
if (require.main === module) {
  runTests();
}

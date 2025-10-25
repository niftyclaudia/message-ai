/**
 * Simple test script for message classification
 * Run with: node test-classification.js
 */

const { classifyMessage } = require('./lib/services/aiPrioritization');

async function testClassification() {
  console.log('Testing message classification system...\n');
  
  const testMessages = [
    {
      text: 'This is urgent! Please respond ASAP',
      expected: 'urgent'
    },
    {
      text: 'Emergency: Server is down and we need immediate help',
      expected: 'urgent'
    },
    {
      text: 'Thanks for the update. Have a good day!',
      expected: 'normal'
    },
    {
      text: 'Hi, how are you doing?',
      expected: 'normal'
    },
    {
      text: 'Meeting in 5 minutes! Please join the call',
      expected: 'urgent'
    },
    {
      text: 'Just checking in to see how things are going',
      expected: 'normal'
    }
  ];
  
  let correct = 0;
  let total = testMessages.length;
  
  for (const test of testMessages) {
    try {
      console.log(`Testing: "${test.text}"`);
      const result = await classifyMessage(test.text);
      
      console.log(`  Result: ${result.priority} (confidence: ${result.confidence.toFixed(2)}, method: ${result.method})`);
      console.log(`  Expected: ${test.expected}`);
      
      if (result.priority === test.expected) {
        console.log('  ✅ Correct');
        correct++;
      } else {
        console.log('  ❌ Incorrect');
      }
      
      console.log(`  Processing time: ${result.processingTimeMs}ms\n`);
      
    } catch (error) {
      console.log(`  ❌ Error: ${error.message}\n`);
    }
  }
  
  const accuracy = (correct / total * 100).toFixed(1);
  console.log(`\nClassification Accuracy: ${correct}/${total} (${accuracy}%)`);
  
  if (accuracy >= 85) {
    console.log('✅ Classification accuracy meets target (≥85%)');
  } else {
    console.log('❌ Classification accuracy below target (≥85%)');
  }
}

// Run the test
testClassification().catch(console.error);

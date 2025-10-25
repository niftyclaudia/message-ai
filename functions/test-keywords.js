/**
 * Test keyword-based classification (no OpenAI required)
 * Run with: node test-keywords.js
 */

// Import the keyword classification function
const { classifyMessageWithKeywords } = require('./lib/services/aiPrioritization');

function testKeywordClassification() {
  console.log('🧪 Testing Keyword-Based Classification\n');
  
  const testCases = [
    {
      text: 'This is urgent! Please respond ASAP',
      expected: 'urgent',
      description: 'Urgent with exclamation and ASAP'
    },
    {
      text: 'Emergency: Server is down and we need immediate help',
      expected: 'urgent',
      description: 'Emergency with immediate help'
    },
    {
      text: 'Meeting in 5 minutes! Please join the call',
      expected: 'urgent',
      description: 'Meeting with time pressure'
    },
    {
      text: 'Critical deadline approaching - need approval now',
      expected: 'urgent',
      description: 'Critical with deadline'
    },
    {
      text: 'Thanks for the update. Have a good day!',
      expected: 'normal',
      description: 'Polite thanks message'
    },
    {
      text: 'Hi, how are you doing?',
      expected: 'normal',
      description: 'Casual greeting'
    },
    {
      text: 'Just checking in to see how things are going',
      expected: 'normal',
      description: 'Casual check-in'
    },
    {
      text: 'Have a good weekend!',
      expected: 'normal',
      description: 'Weekend greeting'
    },
    {
      text: 'No rush on this, take your time',
      expected: 'normal',
      description: 'Explicitly non-urgent'
    },
    {
      text: 'Random text without urgency indicators',
      expected: 'normal',
      description: 'Neutral text'
    }
  ];
  
  let correct = 0;
  let total = testCases.length;
  
  console.log('Test Results:\n');
  
  testCases.forEach((testCase, index) => {
    console.log(`${index + 1}. ${testCase.description}`);
    console.log(`   Text: "${testCase.text}"`);
    
    try {
      const result = classifyMessageWithKeywords(testCase.text);
      
      console.log(`   Result: ${result.priority} (confidence: ${result.confidence.toFixed(2)})`);
      console.log(`   Expected: ${testCase.expected}`);
      console.log(`   Method: ${result.method}`);
      console.log(`   Processing time: ${result.processingTimeMs}ms`);
      
      if (result.priority === testCase.expected) {
        console.log('   ✅ Correct\n');
        correct++;
      } else {
        console.log('   ❌ Incorrect\n');
      }
      
    } catch (error) {
      console.log(`   ❌ Error: ${error.message}\n`);
    }
  });
  
  const accuracy = (correct / total * 100).toFixed(1);
  console.log(`📊 Keyword Classification Results:`);
  console.log(`   Accuracy: ${correct}/${total} (${accuracy}%)`);
  
  if (accuracy >= 80) {
    console.log('   ✅ Keyword classification meets target (≥80%)');
  } else {
    console.log('   ❌ Keyword classification below target (≥80%)');
  }
  
  console.log('\n🎯 Performance Check:');
  console.log('   - All classifications should complete in <100ms');
  console.log('   - Confidence scores should be reasonable (0.3-0.8)');
  console.log('   - Method should be "keyword" for all results');
  
  return { correct, total, accuracy: parseFloat(accuracy) };
}

// Run the test
if (require.main === module) {
  testKeywordClassification();
}

module.exports = { testKeywordClassification };

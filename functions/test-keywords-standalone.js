/**
 * Standalone keyword classification test (no OpenAI dependency)
 */

// Global urgency keywords (copied from aiPrioritization.ts)
const URGENCY_KEYWORDS = [
  // Time-sensitive
  'urgent', 'asap', 'immediately', 'right now', 'deadline', 'due today',
  'emergency', 'crisis', 'critical', 'important', 'priority',
  
  // Meeting/appointment related
  'meeting', 'call', 'conference', 'appointment', 'schedule',
  
  // Business critical
  'decision', 'approval', 'signature', 'contract', 'deal',
  
  // Problem indicators
  'issue', 'problem', 'error', 'bug', 'down', 'broken', 'failed',
  
  // Action required
  'need', 'required', 'must', 'should', 'please respond',
  
  // Exclamation indicators
  '!', '!!!', '\\?\\?'
];

// Normal priority indicators
const NORMAL_INDICATORS = [
  'thanks', 'thank you', 'hi', 'hello', 'good morning', 'good afternoon',
  'how are you', 'hope you', 'have a good', 'weekend', 'vacation',
  'casual', 'just checking', 'no rush', 'when you have time'
];

/**
 * Classify message using keyword analysis (standalone version)
 */
function classifyMessageWithKeywords(messageText) {
  const startTime = Date.now();
  
  if (!messageText || messageText.trim().length === 0) {
    return {
      priority: 'normal',
      confidence: 0.3,
      method: 'keyword',
      processingTimeMs: Date.now() - startTime,
      timestamp: new Date()
    };
  }
  
  const text = messageText.toLowerCase();
  
  // Count urgency indicators
  const urgencyScore = URGENCY_KEYWORDS.reduce((score, keyword) => {
    const matches = (text.match(new RegExp(keyword, 'g')) || []).length;
    return score + matches;
  }, 0);
  
  // Count normal indicators
  const normalScore = NORMAL_INDICATORS.reduce((score, keyword) => {
    const matches = (text.match(new RegExp(keyword, 'g')) || []).length;
    return score + matches;
  }, 0);
  
  // Calculate confidence based on keyword matches
  const totalMatches = urgencyScore + normalScore;
  const confidence = totalMatches > 0 ? Math.min(0.8, 0.3 + (totalMatches * 0.1)) : 0.3;
  
  // Determine priority
  let priority = 'normal';
  if (urgencyScore > normalScore) {
    priority = 'urgent';
  } else if (urgencyScore === normalScore && urgencyScore > 0) {
    // Tie-breaker: if equal matches, default to urgent for safety
    priority = 'urgent';
  }
  
  // Special cases for high urgency
  if (urgencyScore >= 3) {
    priority = 'urgent';
  }
  
  // Special cases for clearly normal messages
  if (normalScore >= 2 && urgencyScore === 0) {
    priority = 'normal';
  }
  
  return {
    priority,
    confidence,
    method: 'keyword',
    processingTimeMs: Date.now() - startTime,
    timestamp: new Date()
  };
}

function testKeywordClassification() {
  console.log('🧪 Testing Keyword-Based Classification (Standalone)\n');
  
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
testKeywordClassification();

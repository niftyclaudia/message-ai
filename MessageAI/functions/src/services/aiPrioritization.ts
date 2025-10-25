/**
 * AI prioritization service with keyword-based fallback
 */

import { logger } from '../utils/logger';
import { classifyMessageWithOpenAI, ClassificationResult } from './openaiClient';

// Global urgency keywords (context-sensitive)
const URGENCY_KEYWORDS = [
  // Time-sensitive
  'urgent', 'asap', 'immediately', 'right now', 'deadline', 'due today',
  'emergency', 'crisis', 'critical', 'important', 'priority',
  
  // Meeting/appointment related (with urgency modifiers)
  'meeting now', 'call now', 'call asap', 'conference now', 'appointment now',
  'schedule now', 'meeting urgent', 'call urgent', 'conference urgent',
  
  // Business critical
  'decision now', 'approval now', 'signature now', 'contract now', 'deal now',
  'decision urgent', 'approval urgent', 'signature urgent',
  
  // Problem indicators
  'issue now', 'problem now', 'error now', 'bug now', 'down now',
  'broken now', 'failed now', 'issue urgent', 'problem urgent',
  
  // Action required (with urgency modifiers)
  'need now', 'required now', 'must now', 'should now', 'please respond now',
  'need urgent', 'required urgent', 'must urgent',
  
  // Exclamation indicators
  '!', '!!!', '\\?\\?'
];

// Urgency modifiers that make neutral words urgent
const URGENCY_MODIFIERS = [
  'now', 'asap', 'immediately', 'right now', 'urgent', 'critical',
  'emergency', 'important', 'priority', 'deadline', 'due today'
];

// Normal priority indicators (messages that are likely not urgent)
const NORMAL_INDICATORS = [
  'thanks', 'thank you', 'hi', 'hello', 'good morning', 'good afternoon',
  'how are you', 'hope you', 'have a good', 'weekend', 'vacation',
  'casual', 'just checking', 'no rush', 'when you have time',
  
  // Context-aware non-urgency phrases
  'when you have a sec', 'when you have a second', 'when you have time',
  'when you\'re free', 'when you\'re available', 'when convenient',
  'take your time', 'no hurry', 'whenever you can', 'at your convenience',
  'call me when', 'text me when', 'let me know when', 'whenever',
  
  // Non-urgent action phrases
  'call me later', 'text me later', 'get back to me later',
  'when you get a chance', 'when you can', 'if you have time'
];

/**
 * Classify a message using AI with keyword fallback
 * @param messageText - The message text to classify
 * @returns Promise<ClassificationResult>
 */
export async function classifyMessage(messageText: string): Promise<ClassificationResult> {
  const startTime = Date.now();
  
  try {
    // Validate input
    if (!messageText || messageText.trim().length === 0) {
      logger.warn('Empty message text provided for classification');
      return createKeywordResult('normal', 0.5, startTime);
    }

    // First try OpenAI classification
    try {
      const openaiResult = await classifyMessageWithOpenAI(messageText);
      
      // If OpenAI succeeded and has reasonable confidence, use it
      if (openaiResult.confidence >= 0.6) {
        logger.info('Using OpenAI classification', {
          priority: openaiResult.priority,
          confidence: openaiResult.confidence
        });
        return openaiResult;
      }
      
      // If OpenAI has low confidence, fall back to keyword analysis
      logger.info('OpenAI confidence too low, falling back to keywords', {
        openaiConfidence: openaiResult.confidence
      });
      
    } catch (openaiError) {
      logger.warn('OpenAI classification failed, using keyword fallback', {
        error: openaiError instanceof Error ? openaiError.message : String(openaiError)
      });
    }

    // Fallback to keyword-based classification
    return classifyMessageWithKeywords(messageText, startTime);

  } catch (error) {
    logger.error('Classification failed completely', { error: error instanceof Error ? error.message : String(error) });
    return createKeywordResult('normal', 0.3, startTime);
  }
}

/**
 * Classify message using keyword analysis with context awareness
 * @param messageText - The message text to analyze
 * @param startTime - Start time for processing calculation
 * @returns ClassificationResult based on keyword analysis
 */
export function classifyMessageWithKeywords(messageText: string, startTime: number = Date.now()): ClassificationResult {
  const text = messageText.toLowerCase();
  
  // Count urgency indicators (exact phrase matches)
  const urgencyScore = URGENCY_KEYWORDS.reduce((score, keyword) => {
    const matches = (text.match(new RegExp(keyword, 'g')) || []).length;
    return score + matches;
  }, 0);
  
  // Count normal indicators (exact phrase matches)
  const normalScore = NORMAL_INDICATORS.reduce((score, keyword) => {
    const matches = (text.match(new RegExp(keyword, 'g')) || []).length;
    return score + matches;
  }, 0);
  
  // Context-aware analysis: check for urgency modifiers near action words
  const contextUrgencyScore = analyzeContextualUrgency(text);
  
  // Calculate confidence based on keyword matches and context
  const totalMatches = urgencyScore + normalScore + contextUrgencyScore;
  const confidence = totalMatches > 0 ? Math.min(0.8, 0.3 + (totalMatches * 0.1)) : 0.3;
  
  // Determine priority with improved logic
  let priority: 'urgent' | 'normal' = 'normal';
  
  // Normal indicators should override urgency indicators when present
  if (normalScore > 0) {
    priority = 'normal';
  }
  // Only mark as urgent if we have urgency indicators AND no normal indicators
  else if (urgencyScore > 0 || contextUrgencyScore > 0) {
    priority = 'urgent';
  }
  
  // Special cases for very high urgency (overrides normal indicators)
  if (urgencyScore >= 3 || contextUrgencyScore >= 3) {
    priority = 'urgent';
  }
  
  // Special cases for clearly normal messages
  if (normalScore >= 2 && urgencyScore === 0 && contextUrgencyScore === 0) {
    priority = 'normal';
  }
  
  logger.info('Keyword classification completed', {
    priority,
    confidence,
    urgencyScore,
    normalScore,
    contextUrgencyScore,
    processingTimeMs: Date.now() - startTime
  });
  
  return {
    priority,
    confidence,
    method: 'keyword',
    processingTimeMs: Date.now() - startTime,
    timestamp: new Date()
  };
}

/**
 * Analyze contextual urgency by looking for urgency modifiers near action words
 * @param text - Lowercase message text
 * @returns Context urgency score
 */
function analyzeContextualUrgency(text: string): number {
  const actionWords = ['call', 'meeting', 'text', 'email', 'respond', 'reply', 'check', 'look', 'review'];
  let contextScore = 0;
  
  // Look for action words followed by urgency modifiers
  actionWords.forEach(action => {
    URGENCY_MODIFIERS.forEach(modifier => {
      // Check for patterns like "call now", "meeting urgent", etc.
      const pattern = new RegExp(`${action}\\s+${modifier}|${modifier}\\s+${action}`, 'g');
      const matches = text.match(pattern);
      if (matches) {
        contextScore += matches.length;
      }
    });
  });
  
  return contextScore;
}

/**
 * Create a keyword-based classification result
 * @param priority - The priority classification
 * @param confidence - The confidence score
 * @param startTime - Start time for processing calculation
 * @returns ClassificationResult
 */
function createKeywordResult(priority: 'urgent' | 'normal', confidence: number, startTime: number): ClassificationResult {
  return {
    priority,
    confidence,
    method: 'keyword',
    processingTimeMs: Date.now() - startTime,
    timestamp: new Date()
  };
}

/**
 * Get classification statistics for monitoring
 * @returns Object with classification metrics
 */
export function getClassificationStats(): {
  urgencyKeywords: number;
  normalIndicators: number;
  totalKeywords: number;
} {
  return {
    urgencyKeywords: URGENCY_KEYWORDS.length,
    normalIndicators: NORMAL_INDICATORS.length,
    totalKeywords: URGENCY_KEYWORDS.length + NORMAL_INDICATORS.length
  };
}

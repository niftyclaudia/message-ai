/**
 * AI prioritization service with keyword-based fallback
 */

import { logger } from '../utils/logger';
import { classifyMessageWithOpenAI, ClassificationResult } from './openaiClient';

// Global urgency keywords
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

// Normal priority indicators (messages that are likely not urgent)
const NORMAL_INDICATORS = [
  'thanks', 'thank you', 'hi', 'hello', 'good morning', 'good afternoon',
  'how are you', 'hope you', 'have a good', 'weekend', 'vacation',
  'casual', 'just checking', 'no rush', 'when you have time'
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
 * Classify message using keyword analysis
 * @param messageText - The message text to analyze
 * @param startTime - Start time for processing calculation
 * @returns ClassificationResult based on keyword analysis
 */
export function classifyMessageWithKeywords(messageText: string, startTime: number = Date.now()): ClassificationResult {
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
  let priority: 'urgent' | 'normal' = 'normal';
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
  
  logger.info('Keyword classification completed', {
    priority,
    confidence,
    urgencyScore,
    normalScore,
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

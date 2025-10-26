/**
 * Thread summarization service using OpenAI GPT-4
 */

import { OpenAI } from 'openai';
import { logger } from '../utils/logger';

// Initialize OpenAI client (only if API key is available)
const openai = process.env.OPENAI_API_KEY ? new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
}) : null;

export interface Message {
  id: string;
  text: string;
  senderID: string;
  timestamp: Date;
  priority?: 'urgent' | 'normal';
}

export interface SessionSummary {
  overview: string;
  actionItems: string[];
  keyDecisions: string[];
  messageCount: number;
  confidence: number;
  processingTimeMs: number;
}

export interface SummarizationResult {
  summary: SessionSummary;
  method: 'openai' | 'fallback';
  timestamp: Date;
}

/**
 * Generate a comprehensive summary of a Focus Mode session
 * @param messages - Array of messages from the session
 * @param sessionDuration - Duration of the session in minutes
 * @returns SummarizationResult with overview, action items, and decisions
 */
export async function generateSessionSummary(
  messages: Message[],
  sessionDuration: number
): Promise<SummarizationResult> {
  const startTime = Date.now();
  
  try {
    // Validate input
    if (!messages || messages.length === 0) {
      logger.warn('No messages provided for summarization');
      return createEmptySummaryResult(startTime);
    }

    // Check if OpenAI is available
    if (!openai) {
      logger.warn('OpenAI client not available, using fallback');
      return createFallbackSummaryResult(messages, startTime);
    }

    // Prepare messages for summarization
    const messageTexts = messages.map(msg => 
      `[${msg.timestamp.toISOString()}] ${msg.senderID}: ${msg.text}`
    ).join('\n');

    // Truncate if too long (OpenAI has token limits)
    const truncatedMessages = messageTexts.length > 8000 
      ? messageTexts.substring(0, 8000) + '\n... (truncated)'
      : messageTexts;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: `You are an AI assistant that creates comprehensive summaries of Focus Mode messaging sessions.

Your task is to analyze the conversation and provide:
1. OVERVIEW: A concise summary of what was discussed
2. ACTION ITEMS: Specific tasks, deadlines, or follow-ups mentioned
3. KEY DECISIONS: Important decisions, agreements, or conclusions reached

Guidelines:
- Be concise but comprehensive
- Extract actionable items with clear ownership when possible
- Identify decisions that were made or need to be made
- Focus on business-relevant content
- Ignore casual conversation unless it contains important information
- If no clear action items or decisions, use "None identified"

Respond with a JSON object containing:
- overview: string (2-3 sentences max)
- actionItems: array of strings (each item should be specific and actionable)
- keyDecisions: array of strings (each decision should be clear and complete)
- confidence: number between 0.0 and 1.0 (how confident you are in the summary quality)

Example format:
{
  "overview": "Team discussed Q4 planning and resource allocation. Key topics included budget approval and hiring priorities.",
  "actionItems": [
    "John to finalize budget proposal by Friday",
    "Sarah to schedule interviews for new developer position",
    "Team to review project timeline next week"
  ],
  "keyDecisions": [
    "Approved 20% increase in development budget",
    "Decided to hire 2 additional developers in Q4",
    "Postponed mobile app launch to Q1 next year"
  ],
  "confidence": 0.85
}`
        },
        {
          role: 'user',
          content: `Analyze this Focus Mode session (${sessionDuration} minutes, ${messages.length} messages):

${truncatedMessages}

Generate a comprehensive summary following the format above.`
        }
      ],
      temperature: 0.2, // Low temperature for consistent results
      max_tokens: 1000,
    });

    const responseText = completion.choices[0]?.message?.content;
    if (!responseText) {
      throw new Error('No response from OpenAI');
    }

    // Parse the JSON response
    const summary: SessionSummary = JSON.parse(responseText);
    
    // Validate response format
    if (!summary.overview || typeof summary.overview !== 'string') {
      throw new Error('Invalid overview in OpenAI response');
    }
    
    if (!Array.isArray(summary.actionItems)) {
      throw new Error('Invalid actionItems in OpenAI response');
    }
    
    if (!Array.isArray(summary.keyDecisions)) {
      throw new Error('Invalid keyDecisions in OpenAI response');
    }
    
    if (typeof summary.confidence !== 'number' || summary.confidence < 0 || summary.confidence > 1) {
      throw new Error('Invalid confidence in OpenAI response');
    }

    // Add metadata
    summary.messageCount = messages.length;
    summary.processingTimeMs = Date.now() - startTime;

    const processingTime = Date.now() - startTime;
    
    logger.info('Session summarization completed', {
      messageCount: messages.length,
      sessionDuration,
      processingTimeMs: processingTime,
      confidence: summary.confidence,
      actionItemsCount: summary.actionItems.length,
      decisionsCount: summary.keyDecisions.length
    });

    return {
      summary,
      method: 'openai',
      timestamp: new Date()
    };

  } catch (error) {
    const processingTime = Date.now() - startTime;
    logger.error('Session summarization failed', { 
      error: error instanceof Error ? error.message : String(error), 
      processingTimeMs: processingTime,
      messageCount: messages.length
    });
    
    // Return fallback result
    return createFallbackSummaryResult(messages, startTime);
  }
}

/**
 * Create a fallback summary result when OpenAI is unavailable
 * @param messages - Array of messages from the session
 * @param startTime - Start time for processing calculation
 * @returns SummarizationResult with basic fallback summary
 */
function createFallbackSummaryResult(messages: Message[], startTime: number): SummarizationResult {
  const urgentMessages = messages.filter(msg => msg.priority === 'urgent');
  
  // Create a more useful overview with actual message content
  let overview = '';
  
  if (urgentMessages.length > 0) {
    // Show urgent message content
    overview = `You have ${urgentMessages.length} urgent message${urgentMessages.length === 1 ? '' : 's'}: `;
    
    // Include up to 3 urgent message previews
    const messagePreviews = urgentMessages.slice(0, 3).map(msg => {
      const preview = msg.text.length > 100 ? msg.text.substring(0, 100) + '...' : msg.text;
      return `"${preview}"`;
    });
    
    overview += messagePreviews.join('; ');
    
    if (urgentMessages.length > 3) {
      overview += ` and ${urgentMessages.length - 3} more urgent message${urgentMessages.length - 3 === 1 ? '' : 's'}.`;
    }
  } else {
    // Show regular message content
    overview = `You received ${messages.length} message${messages.length === 1 ? '' : 's'}: `;
    
    // Include up to 3 message previews
    const messagePreviews = messages.slice(0, 3).map(msg => {
      const preview = msg.text.length > 100 ? msg.text.substring(0, 100) + '...' : msg.text;
      return `"${preview}"`;
    });
    
    overview += messagePreviews.join('; ');
    
    if (messages.length > 3) {
      overview += ` and ${messages.length - 3} more message${messages.length - 3 === 1 ? '' : 's'}.`;
    }
  }
  
  // Extract basic action items from message content
  const actionItems: string[] = [];
  
  // Look for messages with action-oriented keywords
  for (const msg of messages) {
    const text = msg.text.toLowerCase();
    if (text.includes('can you') || text.includes('could you') || text.includes('please') || 
        text.includes('need') || text.includes('urgent') || text.includes('asap')) {
      const preview = msg.text.length > 80 ? msg.text.substring(0, 80) + '...' : msg.text;
      actionItems.push(`Check: "${preview}"`);
      if (actionItems.length >= 3) break; // Limit to 3 action items
    }
  }
  
  const summary: SessionSummary = {
    overview,
    actionItems: actionItems.length > 0 ? actionItems : ['Review all messages for action items'],
    keyDecisions: [],
    messageCount: messages.length,
    confidence: 0.5, // Moderate confidence for content-based fallback
    processingTimeMs: Date.now() - startTime
  };

  return {
    summary,
    method: 'fallback',
    timestamp: new Date()
  };
}

/**
 * Create an empty summary result for sessions with no messages
 * @param startTime - Start time for processing calculation
 * @returns SummarizationResult for empty session
 */
function createEmptySummaryResult(startTime: number): SummarizationResult {
  const summary: SessionSummary = {
    overview: 'No messages were sent during this Focus Mode session.',
    actionItems: [],
    keyDecisions: [],
    messageCount: 0,
    confidence: 1.0, // High confidence for empty session
    processingTimeMs: Date.now() - startTime
  };

  return {
    summary,
    method: 'fallback',
    timestamp: new Date()
  };
}

/**
 * Check if summarization service is ready
 * @returns Promise<boolean> indicating if service is ready
 */
export async function isSummarizationReady(): Promise<boolean> {
  try {
    if (!openai) {
      logger.error('OpenAI client not initialized for summarization');
      return false;
    }

    if (!process.env.OPENAI_API_KEY) {
      logger.error('OpenAI API key not configured for summarization');
      return false;
    }

    // Test with a simple request
    await openai.models.list();
    return true;
  } catch (error) {
    logger.error('Summarization service not ready', { error: error instanceof Error ? error.message : String(error) });
    return false;
  }
}

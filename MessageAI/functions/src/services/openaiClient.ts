/**
 * OpenAI API client for message classification
 */

import { OpenAI } from 'openai';
import { logger } from '../utils/logger';

// Initialize OpenAI client (only if API key is available)
const openai = process.env.OPENAI_API_KEY ? new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
}) : null;

export interface ClassificationResult {
  priority: 'urgent' | 'normal';
  confidence: number;
  method: 'openai' | 'keyword' | 'fallback';
  processingTimeMs: number;
  timestamp: Date;
}

export interface OpenAIResponse {
  priority: 'urgent' | 'normal';
  confidence: number;
  reasoning: string;
}

/**
 * Classify a message using OpenAI GPT-4
 * @param messageText - The message text to classify
 * @returns ClassificationResult with priority, confidence, and metadata
 */
export async function classifyMessageWithOpenAI(messageText: string): Promise<ClassificationResult> {
  const startTime = Date.now();
  
  try {
    // Check if OpenAI is available
    if (!openai) {
      logger.warn('OpenAI client not available, using fallback');
      return createFallbackResult('normal', startTime);
    }

    // Validate input
    if (!messageText || messageText.trim().length === 0) {
      logger.warn('Empty message text provided for classification');
      return createFallbackResult('normal', startTime);
    }

    // Truncate message if too long (OpenAI has token limits)
    const truncatedText = messageText.length > 2000 ? messageText.substring(0, 2000) + '...' : messageText;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: `You are an AI assistant that classifies messages as urgent or normal priority. 

URGENT messages typically contain:
- Time-sensitive requests or deadlines
- Emergency situations or urgent problems
- Critical business decisions
- Important meetings or appointments
- Urgent questions requiring immediate response
- Crisis or emergency language

NORMAL messages typically contain:
- Casual conversation
- General questions
- Non-time-sensitive information
- Routine updates
- Social messages
- General inquiries

Respond with a JSON object containing:
- priority: "urgent" or "normal"
- confidence: number between 0.0 and 1.0
- reasoning: brief explanation of your decision

Be conservative - only mark as urgent if there's clear urgency indicators.`
        },
        {
          role: 'user',
          content: `Classify this message: "${truncatedText}"`
        }
      ],
      temperature: 0.1, // Low temperature for consistent results
      max_tokens: 150,
    });

    const responseText = completion.choices[0]?.message?.content;
    if (!responseText) {
      throw new Error('No response from OpenAI');
    }

    // Parse the JSON response
    const response: OpenAIResponse = JSON.parse(responseText);
    
    // Validate response format
    if (!response.priority || !['urgent', 'normal'].includes(response.priority)) {
      throw new Error('Invalid priority in OpenAI response');
    }
    
    if (typeof response.confidence !== 'number' || response.confidence < 0 || response.confidence > 1) {
      throw new Error('Invalid confidence in OpenAI response');
    }

    const processingTime = Date.now() - startTime;
    
    logger.info('OpenAI classification completed', {
      priority: response.priority,
      confidence: response.confidence,
      processingTimeMs: processingTime,
      reasoning: response.reasoning
    });

    return {
      priority: response.priority,
      confidence: response.confidence,
      method: 'openai',
      processingTimeMs: processingTime,
      timestamp: new Date()
    };

  } catch (error) {
    const processingTime = Date.now() - startTime;
    logger.error('OpenAI classification failed', { error: error instanceof Error ? error.message : String(error), processingTimeMs: processingTime });
    
    // Return fallback result
    return createFallbackResult('normal', startTime);
  }
}

/**
 * Create a fallback classification result
 * @param priority - Default priority to use
 * @param startTime - Start time for processing calculation
 * @returns ClassificationResult with fallback values
 */
function createFallbackResult(priority: 'urgent' | 'normal', startTime: number): ClassificationResult {
  return {
    priority,
    confidence: 0.5, // Low confidence for fallback
    method: 'fallback',
    processingTimeMs: Date.now() - startTime,
    timestamp: new Date()
  };
}

/**
 * Check if OpenAI API is available and properly configured
 * @returns Promise<boolean> indicating if OpenAI is ready
 */
export async function isOpenAIReady(): Promise<boolean> {
  try {
    if (!openai) {
      logger.error('OpenAI client not initialized');
      return false;
    }

    if (!process.env.OPENAI_API_KEY) {
      logger.error('OpenAI API key not configured');
      return false;
    }

    // Test with a simple request
    await openai.models.list();
    return true;
  } catch (error) {
    logger.error('OpenAI API not ready', { error: error instanceof Error ? error.message : String(error) });
    return false;
  }
}

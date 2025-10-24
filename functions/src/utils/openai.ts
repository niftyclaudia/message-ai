/**
 * OpenAI API client wrapper
 * Handles embedding generation with retry logic
 */

import OpenAI from 'openai';
import { validateEnvVars } from '../config/env';
import { logger } from './logger';

let openaiClient: OpenAI | null = null;

/**
 * Initialize OpenAI client (singleton pattern)
 */
export function initializeOpenAI(): OpenAI {
  if (openaiClient) {
    return openaiClient;
  }

  const config = validateEnvVars();
  openaiClient = new OpenAI({
    apiKey: config.openaiApiKey,
  });

  logger.info('OpenAI client initialized');
  return openaiClient;
}

/**
 * Generate embedding vector for text
 * Uses text-embedding-3-small model (1536 dimensions)
 * Includes retry logic with exponential backoff
 */
export async function generateEmbedding(
  text: string,
  retries = 3
): Promise<number[]> {
  const client = initializeOpenAI();

  // Validate input
  if (!text || text.trim().length === 0) {
    throw new Error('Text cannot be empty');
  }

  // Truncate if too long (OpenAI limit is ~8000 tokens, ~32000 chars)
  const truncatedText = text.slice(0, 32000);

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const startTime = Date.now();
      
      const response = await client.embeddings.create({
        model: 'text-embedding-3-small',
        input: truncatedText,
      });

      const duration = Date.now() - startTime;
      logger.info('Embedding generated successfully', {
        textLength: truncatedText.length,
        duration,
        attempt,
      });

      if (!response.data || response.data.length === 0) {
        throw new Error('No embedding returned from OpenAI');
      }

      return response.data[0].embedding;
    } catch (error: any) {
      const isLastAttempt = attempt === retries;
      
      // Handle rate limits (429)
      if (error.status === 429) {
        if (isLastAttempt) {
          logger.error('OpenAI rate limit exceeded after retries', error);
          throw new Error('openai_rate_limit');
        }
        
        // Exponential backoff: 1s, 2s, 4s
        const delay = Math.pow(2, attempt - 1) * 1000;
        logger.warn(`OpenAI rate limit hit, retrying in ${delay}ms`, {
          attempt,
          maxRetries: retries,
        });
        await sleep(delay);
        continue;
      }

      // Handle timeout errors
      if (error.code === 'ETIMEDOUT' || error.code === 'ECONNRESET') {
        if (isLastAttempt) {
          logger.error('OpenAI timeout after retries', error);
          throw new Error('openai_timeout');
        }
        
        const delay = Math.pow(2, attempt - 1) * 1000;
        logger.warn(`OpenAI timeout, retrying in ${delay}ms`, {
          attempt,
          maxRetries: retries,
        });
        await sleep(delay);
        continue;
      }

      // Other errors - fail immediately
      logger.error('OpenAI API error', error);
      throw new Error('openai_api_error');
    }
  }

  throw new Error('openai_max_retries_exceeded');
}

/**
 * Sleep utility for retry backoff
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}


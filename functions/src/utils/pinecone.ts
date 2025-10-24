/**
 * Pinecone vector database client wrapper
 * Handles vector upsert and query operations
 */

import { Pinecone, Index } from '@pinecone-database/pinecone';
import { validateEnvVars } from '../config/env';
import { logger } from './logger';

let pineconeClient: Pinecone | null = null;

export interface VectorMetadata {
  messageId: string;
  chatId: string;
  senderId: string;
  timestamp: number;
  text?: string;
}

export interface VectorMatch {
  id: string;
  score: number;
  metadata: VectorMetadata;
}

/**
 * Initialize Pinecone client (singleton pattern)
 */
export function initializePinecone(): Pinecone {
  if (pineconeClient) {
    return pineconeClient;
  }

  const config = validateEnvVars();
  pineconeClient = new Pinecone({
    apiKey: config.pineconeApiKey,
  });

  logger.info('Pinecone client initialized');
  return pineconeClient;
}

/**
 * Get Pinecone index
 */
export function getIndex(indexName?: string): Index {
  const client = initializePinecone();
  const config = validateEnvVars();
  const name = indexName || config.pineconeIndex;
  
  return client.index(name);
}

/**
 * Upsert vector embedding to Pinecone
 */
export async function upsertVector(
  id: string,
  vector: number[],
  metadata: VectorMetadata,
  retries = 3
): Promise<void> {
  const index = getIndex();

  // Validate vector dimensions (should be 1536 for text-embedding-3-small)
  if (vector.length !== 1536) {
    throw new Error(`Invalid vector dimensions: ${vector.length}, expected 1536`);
  }

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const startTime = Date.now();

      await index.upsert([
        {
          id,
          values: vector,
          metadata: metadata as Record<string, any>,
        },
      ]);

      const duration = Date.now() - startTime;
      logger.info('Vector upserted successfully', {
        id,
        duration,
        attempt,
      });

      return;
    } catch (error: any) {
      const isLastAttempt = attempt === retries;

      if (isLastAttempt) {
        logger.error('Pinecone upsert failed after retries', error);
        throw new Error('vector_db_upsert_error');
      }

      // Retry with exponential backoff
      const delay = Math.pow(2, attempt - 1) * 1000;
      logger.warn(`Pinecone upsert failed, retrying in ${delay}ms`, {
        attempt,
        maxRetries: retries,
        error: error.message,
      });
      await sleep(delay);
    }
  }
}

/**
 * Query vectors by similarity
 */
export async function queryVector(
  vector: number[],
  limit: number,
  filter?: Record<string, any>,
  retries = 3
): Promise<VectorMatch[]> {
  const index = getIndex();

  // Validate inputs
  if (vector.length !== 1536) {
    throw new Error(`Invalid vector dimensions: ${vector.length}, expected 1536`);
  }
  if (limit < 1 || limit > 50) {
    throw new Error(`Invalid limit: ${limit}, must be between 1 and 50`);
  }

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const startTime = Date.now();

      const queryRequest: any = {
        vector,
        topK: limit,
        includeMetadata: true,
      };

      if (filter) {
        queryRequest.filter = filter;
      }

      const response = await index.query(queryRequest);

      const duration = Date.now() - startTime;
      logger.info('Vector query successful', {
        duration,
        resultsCount: response.matches?.length || 0,
        attempt,
      });

      // Transform response to VectorMatch format
      const matches: VectorMatch[] = (response.matches || []).map((match: any) => ({
        id: match.id,
        score: match.score || 0,
        metadata: match.metadata as VectorMetadata,
      }));

      return matches;
    } catch (error: any) {
      const isLastAttempt = attempt === retries;

      if (isLastAttempt) {
        logger.error('Pinecone query failed after retries', error);
        throw new Error('vector_db_query_error');
      }

      // Retry with exponential backoff
      const delay = Math.pow(2, attempt - 1) * 1000;
      logger.warn(`Pinecone query failed, retrying in ${delay}ms`, {
        attempt,
        maxRetries: retries,
        error: error.message,
      });
      await sleep(delay);
    }
  }

  return [];
}

/**
 * Delete vector from Pinecone (for message deletion)
 */
export async function deleteVector(id: string): Promise<void> {
  try {
    const index = getIndex();
    await index.deleteOne(id);
    logger.info('Vector deleted successfully', { id });
  } catch (error) {
    logger.error('Failed to delete vector', { id, error });
    throw new Error('vector_db_delete_error');
  }
}

/**
 * Sleep utility for retry backoff
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}


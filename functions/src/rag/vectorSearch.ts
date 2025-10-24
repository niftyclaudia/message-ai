/**
 * Vector search operations
 * Handles upserting and querying embeddings in Pinecone
 */

import { upsertVector, queryVector as queryPinecone, VectorMatch, VectorMetadata } from '../utils/pinecone';
import { logger } from '../utils/logger';

/**
 * Upsert embedding to vector database
 */
export async function upsertEmbedding(
  messageId: string,
  vector: number[],
  metadata: {
    chatId: string;
    senderId: string;
    timestamp: number;
    text?: string;
  }
): Promise<string> {
  try {
    const vectorMetadata: VectorMetadata = {
      messageId,
      chatId: metadata.chatId,
      senderId: metadata.senderId,
      timestamp: metadata.timestamp,
      text: metadata.text,
    };

    await upsertVector(messageId, vector, vectorMetadata);

    logger.info('Embedding upserted successfully', {
      messageId,
      chatId: metadata.chatId,
    });

    return messageId; // Return the embedding ID (same as messageId)
  } catch (error) {
    logger.error('Failed to upsert embedding', { messageId, error });
    throw error;
  }
}

/**
 * Query vector database for similar messages
 */
export async function queryVectorDB(
  queryVector: number[],
  limit: number,
  filters?: {
    chatId?: string;
    minTimestamp?: number;
    maxTimestamp?: number;
  }
): Promise<VectorMatch[]> {
  try {
    // Build Pinecone filter
    const pineconeFilter: Record<string, any> = {};
    
    if (filters?.chatId) {
      pineconeFilter.chatId = { $eq: filters.chatId };
    }
    
    if (filters?.minTimestamp || filters?.maxTimestamp) {
      pineconeFilter.timestamp = {};
      if (filters.minTimestamp) {
        pineconeFilter.timestamp.$gte = filters.minTimestamp;
      }
      if (filters.maxTimestamp) {
        pineconeFilter.timestamp.$lte = filters.maxTimestamp;
      }
    }

    const matches = await queryPinecone(
      queryVector,
      limit,
      Object.keys(pineconeFilter).length > 0 ? pineconeFilter : undefined
    );

    logger.info('Vector query completed', {
      resultsCount: matches.length,
      filters,
    });

    return matches;
  } catch (error) {
    logger.error('Failed to query vector DB', { error });
    throw error;
  }
}

/**
 * Delete embedding from vector database
 * (Future: for message deletion)
 */
export async function deleteEmbedding(messageId: string): Promise<void> {
  try {
    const { deleteVector } = await import('../utils/pinecone');
    await deleteVector(messageId);
    
    logger.info('Embedding deleted', { messageId });
  } catch (error) {
    logger.error('Failed to delete embedding', { messageId, error });
    throw error;
  }
}


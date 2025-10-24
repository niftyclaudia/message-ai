/**
 * Semantic search orchestration
 * High-level API for performing semantic search across messages
 */

import * as admin from 'firebase-admin';
import { generateEmbedding } from './embeddings';
import { queryVectorDB } from './vectorSearch';
import { VectorMatch } from '../utils/pinecone';
import { logger } from '../utils/logger';

export interface SearchOptions {
  limit?: number;
  chatId?: string;
  minScore?: number;
  boostRecency?: boolean;
}

export interface SearchResult {
  messageId: string;
  chatId: string;
  senderId: string;
  text: string;
  timestamp: number;
  similarityScore: number;
  relevanceScore: number; // Adjusted score with boosts applied
}

/**
 * Perform semantic search across messages
 */
export async function performSemanticSearch(
  query: string,
  userId: string,
  options: SearchOptions = {}
): Promise<SearchResult[]> {
  const startTime = Date.now();

  try {
    // Validate query
    if (!query || query.trim().length < 3) {
      throw new Error('Query must be at least 3 characters');
    }
    if (query.length > 500) {
      throw new Error('Query must be less than 500 characters');
    }

    const limit = options.limit || 10;
    if (limit < 1 || limit > 50) {
      throw new Error('Limit must be between 1 and 50');
    }

    // Check user permissions for chatId filter
    if (options.chatId) {
      const hasPermission = await checkUserPermission(userId, options.chatId);
      if (!hasPermission) {
        throw new Error('permission_denied');
      }
    }

    // Generate query embedding
    const queryVector = await generateEmbedding(query);

    // Query vector database
    const filters: any = {};
    if (options.chatId) {
      filters.chatId = options.chatId;
    }

    const matches = await queryVectorDB(queryVector, limit * 2, filters); // Get more for filtering

    // Fetch message documents from Firestore
    const results = await fetchMessagesFromMatches(matches);

    // Apply minimum score filter
    const minScore = options.minScore || 0.7; // Default 70% similarity
    let filteredResults = results.filter((r) => r.similarityScore >= minScore);

    // Apply ranking/boosts
    if (options.boostRecency) {
      filteredResults = applyRecencyBoost(filteredResults);
    }

    // Sort by relevance score and limit
    filteredResults.sort((a, b) => b.relevanceScore - a.relevanceScore);
    filteredResults = filteredResults.slice(0, limit);

    const duration = Date.now() - startTime;
    logger.info('Semantic search completed', {
      query: query.slice(0, 50), // Log first 50 chars
      userId,
      resultsCount: filteredResults.length,
      duration,
    });

    return filteredResults;
  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error('Semantic search failed', {
      query: query.slice(0, 50),
      userId,
      duration,
      error,
    });
    throw error;
  }
}

/**
 * Check if user has permission to access chat
 */
async function checkUserPermission(
  userId: string,
  chatId: string
): Promise<boolean> {
  try {
    const db = admin.firestore();
    const chatDoc = await db.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      return false;
    }

    const chatData = chatDoc.data();
    const members = chatData?.members || [];
    return members.includes(userId);
  } catch (error) {
    logger.error('Failed to check user permission', { userId, chatId, error });
    return false;
  }
}

/**
 * Fetch full message documents from Firestore based on vector matches
 */
async function fetchMessagesFromMatches(
  matches: VectorMatch[]
): Promise<SearchResult[]> {
  const db = admin.firestore();
  const results: SearchResult[] = [];

  // Fetch messages in parallel
  const fetchPromises = matches.map(async (match) => {
    try {
      const { chatId, messageId } = match.metadata;
      
      const messageDoc = await db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .get();

      if (!messageDoc.exists) {
        logger.warn('Message not found in Firestore', { messageId });
        return null;
      }

      const messageData = messageDoc.data();
      return {
        messageId: match.id,
        chatId: match.metadata.chatId,
        senderId: match.metadata.senderId,
        text: messageData?.text || '',
        timestamp: match.metadata.timestamp,
        similarityScore: match.score,
        relevanceScore: match.score, // Will be adjusted by boosts
      };
    } catch (error) {
      logger.error('Failed to fetch message', {
        messageId: match.id,
        error,
      });
      return null;
    }
  });

  const fetchedResults = await Promise.all(fetchPromises);
  
  // Filter out null results
  fetchedResults.forEach((result) => {
    if (result) {
      results.push(result);
    }
  });

  return results;
}

/**
 * Apply recency boost to search results
 * Newer messages get a slight boost in relevance
 */
function applyRecencyBoost(results: SearchResult[]): SearchResult[] {
  const now = Date.now();
  const oneDay = 24 * 60 * 60 * 1000;
  const oneWeek = 7 * oneDay;

  return results.map((result) => {
    const age = now - result.timestamp;
    let recencyBoost = 1.0;

    // Boost messages from last 24 hours by 10%
    if (age < oneDay) {
      recencyBoost = 1.1;
    }
    // Boost messages from last week by 5%
    else if (age < oneWeek) {
      recencyBoost = 1.05;
    }

    return {
      ...result,
      relevanceScore: result.similarityScore * recencyBoost,
    };
  });
}

/**
 * Rank results with custom ranking boosts
 * (Future: can add boosts for urgent contacts, important keywords, etc.)
 */
export function rankResults(
  matches: VectorMatch[],
  boost?: {
    urgentContacts?: string[];
    importantKeywords?: string[];
  }
): SearchResult[] {
  // Placeholder for future ranking enhancements
  // For now, just return matches sorted by score
  return matches
    .map((match) => ({
      messageId: match.id,
      chatId: match.metadata.chatId,
      senderId: match.metadata.senderId,
      text: match.metadata.text || '',
      timestamp: match.metadata.timestamp,
      similarityScore: match.score,
      relevanceScore: match.score,
    }))
    .sort((a, b) => b.relevanceScore - a.relevanceScore);
}


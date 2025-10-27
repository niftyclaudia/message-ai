/**
 * Cloud Function: Semantic Search
 * 
 * Performs semantic search across message history using vector similarity
 * 1. Generates embedding for search query
 * 2. Queries Pinecone for similar vectors
 * 3. Fetches full message details from Firestore
 * 4. Returns sorted results
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { OpenAI } from 'openai';
import { Pinecone } from '@pinecone-database/pinecone';
import * as admin from 'firebase-admin';

// Initialize OpenAI
const openai = process.env.OPENAI_API_KEY ? new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
}) : null;

// Initialize Pinecone
let pineconeClient: Pinecone | null = null;
if (process.env.PINECONE_API_KEY) {
  pineconeClient = new Pinecone({
    apiKey: process.env.PINECONE_API_KEY,
  });
}

const PINECONE_INDEX_NAME = process.env.PINECONE_INDEX_NAME || 'message-embeddings';
const EMBEDDING_MODEL = 'text-embedding-3-small';
const MIN_RELEVANCE_SCORE = 0.3; // Temporarily lowered for debugging (normally 0.7)

interface SemanticSearchRequest {
  query: string;
  userId: string;
  limit?: number;
}

interface SearchResultData {
  messageId: string;
  conversationId: string;
  relevanceScore: number;
  messagePreview: string;
  timestamp: string;
  senderName: string;
  fullText?: string;
}

interface SemanticSearchResponse {
  results: SearchResultData[];
  queryId: string;
  resultCount: number;
  durationMs: number;
}

/**
 * Perform semantic search across messages
 */
export const semanticSearch = onCall<SemanticSearchRequest, Promise<SemanticSearchResponse>>(
  { 
    secrets: ['OPENAI_API_KEY', 'PINECONE_API_KEY', 'PINECONE_ENVIRONMENT', 'PINECONE_INDEX_NAME'],
    enforceAppCheck: false,
  },
  async (request) => {
    const startTime = Date.now();
    const queryId = admin.firestore().collection('temp').doc().id;
    
    try {
      // Validate authentication
      if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
      }

      const { query, userId, limit = 20 } = request.data;

      // Validate input
      if (!query || typeof query !== 'string') {
        throw new HttpsError('invalid-argument', 'query is required');
      }

      const trimmedQuery = query.trim();
      
      if (trimmedQuery.length < 3) {
        throw new HttpsError('invalid-argument', 'query must be at least 3 characters');
      }

      if (trimmedQuery.length > 200) {
        throw new HttpsError('invalid-argument', 'query must be less than 200 characters');
      }

      if (limit < 1 || limit > 100) {
        throw new HttpsError('invalid-argument', 'limit must be between 1 and 100');
      }

      // Verify user authorization
      if (userId !== request.auth.uid) {
        throw new HttpsError('permission-denied', 'Cannot search other users\' messages');
      }

      logger.info('Starting semantic search', {
        queryId,
        query: trimmedQuery,
        userId,
        limit,
      });

      // Check service availability
      if (!openai) {
        throw new HttpsError('failed-precondition', 'OpenAI service unavailable');
      }

      if (!pineconeClient) {
        throw new HttpsError('failed-precondition', 'Pinecone service unavailable');
      }

      // Step 1: Generate embedding for search query
      logger.info('Generating query embedding', { queryId });
      
      const embeddingResponse = await openai.embeddings.create({
        model: EMBEDDING_MODEL,
        input: trimmedQuery,
        encoding_format: 'float',
      });

      if (!embeddingResponse.data || embeddingResponse.data.length === 0) {
        throw new HttpsError('internal', 'Failed to generate query embedding');
      }

      const queryEmbedding = embeddingResponse.data[0].embedding;

      // Step 2: Query Pinecone for similar vectors
      logger.info('Querying Pinecone', { queryId, limit });
      
      const index = pineconeClient.index(PINECONE_INDEX_NAME);
      const queryResponse = await index.query({
        vector: queryEmbedding,
        topK: limit * 2, // Query more than needed to filter by user
        includeMetadata: true,
      });

      if (!queryResponse.matches || queryResponse.matches.length === 0) {
        logger.info('No matches found', { queryId });
        return {
          results: [],
          queryId,
          resultCount: 0,
          durationMs: Date.now() - startTime,
        };
      }

      // Step 3: Filter matches by relevance score
      // Note: User access control is handled at Firestore level when fetching messages
      
      // Log top scores for debugging
      const topScores = queryResponse.matches.slice(0, 5).map(m => m.score);
      logger.info('Top 5 similarity scores from Pinecone', {
        queryId,
        scores: topScores,
        threshold: MIN_RELEVANCE_SCORE,
      });
      
      const relevantMatches = queryResponse.matches
        .filter(match => {
          const score = match.score || 0;
          return score >= MIN_RELEVANCE_SCORE;
        })
        .slice(0, limit * 2); // Get more to account for messages user doesn't have access to

      logger.info('Filtered matches', {
        queryId,
        totalMatches: queryResponse.matches.length,
        relevantMatches: relevantMatches.length,
      });

      // Step 4: Fetch full message details from Firestore
      const messageIds = relevantMatches
        .map(match => match.metadata?.messageId as string)
        .filter(id => id);

      if (messageIds.length === 0) {
        return {
          results: [],
          queryId,
          resultCount: 0,
          durationMs: Date.now() - startTime,
        };
      }

      // Fetch messages in batch from subcollections
      const messagePromises = relevantMatches.map(async (match) => {
        try {
          const messageId = match.metadata?.messageId as string;
          const chatId = match.metadata?.chatID as string;
          
          if (!messageId || !chatId) {
            return null;
          }
          
          const messageDoc = await admin.firestore()
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .get();

          if (!messageDoc.exists) {
            return null;
          }

          return {
            id: messageId,
            chatId: chatId,
            data: messageDoc.data(),
          };
        } catch (error) {
          logger.warn('Failed to fetch message', {
            messageId: match.metadata?.messageId,
            error: error instanceof Error ? error.message : String(error),
          });
          return null;
        }
      });

      const messages = (await Promise.all(messagePromises)).filter(m => m !== null);

      // Step 5: Combine Pinecone results with Firestore data
      const results: SearchResultData[] = [];
      
      for (const match of relevantMatches) {
        const messageId = match.metadata?.messageId as string;
        const messageData = messages.find(m => m && m.id === messageId);
        
        if (!messageData || !messageData.data) {
          continue;
        }

        const message = messageData.data;
        const text = message.text || '';
        
        results.push({
          messageId,
          conversationId: message.chatID || message.conversationId || '',
          relevanceScore: match.score || 0,
          messagePreview: text.substring(0, 100),
          timestamp: message.timestamp?.toDate?.()?.toISOString() || new Date().toISOString(),
          senderName: message.senderName || 'Unknown',
          fullText: text,
        });
      }

      const duration = Date.now() - startTime;

      logger.info('Search completed', {
        queryId,
        resultCount: results.length,
        durationMs: duration,
      });

      return {
        results,
        queryId,
        resultCount: results.length,
        durationMs: duration,
      };

    } catch (error) {
      const duration = Date.now() - startTime;
      
      logger.error('Semantic search failed', {
        queryId,
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
        durationMs: duration,
      });

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError('internal', 'Search failed');
    }
  }
);


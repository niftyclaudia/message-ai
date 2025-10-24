/**
 * Cloud Function: Semantic search across messages
 * HTTP Callable function for querying messages by meaning
 */

import * as functions from 'firebase-functions/v1';
import { performSemanticSearch, SearchResult } from './rag/semanticQuery';
import { logger } from './utils/logger';

interface SemanticSearchRequest {
  query: string;
  userId: string;
  limit?: number;
  chatId?: string;
  minScore?: number;
}

interface SemanticSearchResponse {
  results: SearchResult[];
  totalResults: number;
  queryTime: number;
}

/**
 * Perform semantic search across messages
 * Callable from iOS client
 */
export const semanticSearchFunction = functions.https.onCall(
  async (
    data: SemanticSearchRequest,
    context: functions.https.CallableContext
  ): Promise<SemanticSearchResponse> => {
    const startTime = Date.now();

    try {
      // Check authentication
      if (!context.auth) {
        logger.error('Unauthenticated call to semanticSearch');
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Must be authenticated to perform semantic search'
        );
      }

      const { query, userId, limit, chatId, minScore } = data;

      // Validate inputs
      if (!query || typeof query !== 'string') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'invalid_query: query must be a non-empty string'
        );
      }

      if (!userId || typeof userId !== 'string') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'invalid_user_id: userId must be a non-empty string'
        );
      }

      // Verify user is making request for themselves
      if (userId !== context.auth.uid) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'permission_denied: Cannot search for another user'
        );
      }

      if (query.trim().length < 3) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'invalid_query: Query must be at least 3 characters'
        );
      }

      if (query.length > 500) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'invalid_query: Query must be less than 500 characters'
        );
      }

      const searchLimit = limit || 10;
      if (searchLimit < 1 || searchLimit > 50) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'invalid_limit: Limit must be between 1 and 50'
        );
      }

      logger.info('Performing semantic search', {
        userId,
        queryLength: query.length,
        limit: searchLimit,
        chatId,
      });

      // Perform semantic search
      let results: SearchResult[];
      try {
        results = await performSemanticSearch(query, userId, {
          limit: searchLimit,
          chatId,
          minScore,
          boostRecency: true,
        });
      } catch (error: any) {
        // Handle specific errors
        if (error.message === 'permission_denied') {
          throw new functions.https.HttpsError(
            'permission-denied',
            'permission_denied: You do not have access to this chat'
          );
        }

        if (error.message?.includes('openai')) {
          logger.error('OpenAI API error during search', { error });
          throw new functions.https.HttpsError(
            'internal',
            'openai_api_error: Failed to generate query embedding'
          );
        }

        if (error.message?.includes('vector_db')) {
          logger.error('Vector DB error during search', { error });
          throw new functions.https.HttpsError(
            'internal',
            'vector_db_error: Failed to query vector database'
          );
        }

        // Generic error
        throw error;
      }

      const queryTime = Date.now() - startTime;
      logger.info('Semantic search completed', {
        userId,
        resultsCount: results.length,
        queryTime,
      });

      return {
        results,
        totalResults: results.length,
        queryTime,
      };
    } catch (error: any) {
      const queryTime = Date.now() - startTime;

      // If already HttpsError, rethrow
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // Log and throw generic error
      logger.error('semanticSearch failed', {
        error,
        queryTime,
      });
      throw new functions.https.HttpsError(
        'internal',
        'Failed to perform semantic search'
      );
    }
  }
);


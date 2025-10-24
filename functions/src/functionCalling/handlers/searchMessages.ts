/**
 * Search Messages Handler
 * Performs semantic search across messages using RAG Pipeline
 */

import * as functions from 'firebase-functions/v1';
import { SearchMessagesParams, SearchResult } from '../schemas';
import { performSemanticSearch } from '../../rag/semanticQuery';
import { checkUserAccess } from '../../utils/permissionChecker';
import { logger } from '../../utils/logger';

export async function searchMessagesHandler(
  params: SearchMessagesParams,
  userId: string,
  context: functions.https.CallableContext
): Promise<SearchResult[]> {
  const { query, chatId, limit = 10 } = params;

  logger.info('searchMessages handler started', {
    userId,
    queryLength: query.length,
    chatId,
    limit,
  });

  // Verify user is making request for themselves
  if (params.userId !== userId) {
    throw new Error('permission_denied: Cannot search for another user');
  }

  // If chatId provided, verify user has access to that chat
  if (chatId) {
    const hasAccess = await checkUserAccess(userId, chatId, 'chat');
    if (!hasAccess) {
      throw new Error('permission_denied: You do not have access to this chat');
    }
  }

  try {
    // Call RAG Pipeline semantic search
    const ragResults = await performSemanticSearch(query, userId, {
      limit,
      chatId,
      boostRecency: true,
    });

    // Transform RAG results to SearchResult format
    const results: SearchResult[] = ragResults.map((result) => ({
      messageId: result.messageId,
      text: result.text,
      senderId: result.senderId,
      timestamp: new Date(result.timestamp),
      relevanceScore: result.relevanceScore,
    }));

    logger.info('searchMessages completed', {
      userId,
      resultsCount: results.length,
    });

    return results;
  } catch (error: any) {
    logger.error('searchMessages failed', { error, userId, query });
    
    // Check if RAG Pipeline is down
    if (error.message?.includes('openai') || error.message?.includes('vector_db')) {
      throw new Error('service_unavailable: Search service temporarily unavailable');
    }
    
    throw error;
  }
}


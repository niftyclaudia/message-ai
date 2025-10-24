/**
 * Cloud Function: Generate embedding for a message
 * HTTP Callable function for manual embedding generation
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { generateEmbedding, generateSearchableMetadata } from './rag/embeddings';
import { upsertEmbedding } from './rag/vectorSearch';
import { logger } from './utils/logger';

interface GenerateEmbeddingRequest {
  messageId: string;
}

interface GenerateEmbeddingResponse {
  success: boolean;
  embeddingId: string;
  metadata: {
    keywords: string[];
    participants: string[];
    decisionMade?: boolean;
    hasActionItem?: boolean;
  };
}

/**
 * Generate embedding for a specific message
 * Callable from iOS client
 */
export const generateEmbeddingFunction = functions.https.onCall(
  async (
    data: GenerateEmbeddingRequest,
    context: functions.https.CallableContext
  ): Promise<GenerateEmbeddingResponse> => {
    const startTime = Date.now();

    try {
      // Check authentication
      if (!context.auth) {
        logger.error('Unauthenticated call to generateEmbedding');
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Must be authenticated to generate embeddings'
        );
      }

      const { messageId } = data;

      // Validate input
      if (!messageId || typeof messageId !== 'string') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'invalid_message_id: messageId must be a non-empty string'
        );
      }

      logger.info('Generating embedding', { messageId, userId: context.auth.uid });

      // Fetch message from Firestore
      const db = admin.firestore();
      const messageQuery = await db
        .collectionGroup('messages')
        .where(admin.firestore.FieldPath.documentId(), '==', messageId)
        .limit(1)
        .get();

      if (messageQuery.empty) {
        throw new functions.https.HttpsError(
          'not-found',
          'invalid_message_id: Message not found'
        );
      }

      const messageDoc = messageQuery.docs[0];
      const messageData = messageDoc.data();
      const messageText = messageData.text;
      const chatId = messageDoc.ref.parent.parent?.id;

      if (!chatId) {
        throw new functions.https.HttpsError(
          'internal',
          'Could not determine chatId from message path'
        );
      }

      // Generate embedding
      let embedding: number[];
      try {
        embedding = await generateEmbedding(messageText);
      } catch (error: any) {
        logger.error('OpenAI API error', { messageId, error });
        throw new functions.https.HttpsError(
          'internal',
          'openai_api_error: Failed to generate embedding'
        );
      }

      // Generate searchable metadata
      const metadata = await generateSearchableMetadata(messageText, chatId);

      // Upsert to vector database
      try {
        await upsertEmbedding(messageId, embedding, {
          chatId,
          senderId: messageData.senderId,
          timestamp: messageData.timestamp?.toMillis() || Date.now(),
          text: messageText,
        });
      } catch (error: any) {
        logger.error('Vector DB error', { messageId, error });
        throw new functions.https.HttpsError(
          'internal',
          'vector_db_error: Failed to store embedding'
        );
      }

      // Update Firestore message with metadata
      await messageDoc.ref.update({
        embeddingGenerated: true,
        searchableMetadata: metadata,
      });

      const duration = Date.now() - startTime;
      logger.info('Embedding generated successfully', {
        messageId,
        duration,
        metadataKeywords: metadata.keywords.length,
      });

      return {
        success: true,
        embeddingId: messageId,
        metadata,
      };
    } catch (error: any) {
      const duration = Date.now() - startTime;
      
      // If already HttpsError, rethrow
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      // Log and throw generic error
      logger.error('generateEmbedding failed', { error, duration });
      throw new functions.https.HttpsError(
        'internal',
        'Failed to generate embedding'
      );
    }
  }
);


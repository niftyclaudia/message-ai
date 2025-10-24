/**
 * Firestore Trigger: Auto-generate embeddings on message creation
 * Triggers whenever a new message is created in any chat
 */

import * as functions from 'firebase-functions/v1';
import { generateEmbedding, generateSearchableMetadata } from '../rag/embeddings';
import { upsertEmbedding } from '../rag/vectorSearch';
import { logger } from '../utils/logger';

/**
 * Automatically generate embedding when message is created
 */
export const onMessageCreatedTrigger = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const startTime = Date.now();
    const messageId = context.params.messageId;
    const chatId = context.params.chatId;

    try {
      const messageData = snapshot.data();
      const messageText = messageData.text;

      // Skip if no text (e.g., image-only message)
      if (!messageText || messageText.trim().length === 0) {
        logger.info('Skipping embedding for message without text', { messageId });
        return;
      }

      logger.info('Auto-generating embedding', { messageId, chatId });

      // Generate embedding
      let embedding: number[];
      try {
        embedding = await generateEmbedding(messageText);
      } catch (error: any) {
        logger.error('OpenAI API error in trigger', {
          messageId,
          chatId,
          error,
        });
        
        // Update message with error flag (don't fail the whole operation)
        await snapshot.ref.update({
          embeddingGenerated: false,
          embeddingError: 'openai_api_error',
        });
        return; // Exit gracefully
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
        logger.error('Vector DB error in trigger', {
          messageId,
          chatId,
          error,
        });

        // Update message with error flag
        await snapshot.ref.update({
          embeddingGenerated: false,
          embeddingError: 'vector_db_error',
        });
        return; // Exit gracefully
      }

      // Update Firestore message with success metadata
      await snapshot.ref.update({
        embeddingGenerated: true,
        searchableMetadata: metadata,
      });

      const duration = Date.now() - startTime;
      logger.info('Embedding auto-generated successfully', {
        messageId,
        chatId,
        duration,
        metadataKeywords: metadata.keywords.length,
      });

      // Log performance warning if too slow
      if (duration > 500) {
        logger.warn('Embedding generation exceeded 500ms target', {
          messageId,
          duration,
        });
      }
    } catch (error: any) {
      const duration = Date.now() - startTime;
      
      // Log error but don't fail (triggers shouldn't crash)
      logger.error('onMessageCreated trigger failed', {
        messageId,
        chatId,
        duration,
        error: {
          message: error.message,
          stack: error.stack,
        },
      });

      // Try to update message with error flag
      try {
        await snapshot.ref.update({
          embeddingGenerated: false,
          embeddingError: 'unknown_error',
        });
      } catch (updateError) {
        logger.error('Failed to update message with error flag', {
          messageId,
          updateError,
        });
      }
    }
  });


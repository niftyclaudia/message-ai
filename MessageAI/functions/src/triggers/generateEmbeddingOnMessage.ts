/**
 * Firestore Trigger: Generate Embedding on Message Creation
 * 
 * Automatically generates vector embeddings for new messages
 * and stores them in Pinecone for semantic search
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
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

const PINECONE_INDEX_NAME = process.env.PINECONE_INDEX_NAME || 'messageai';
const EMBEDDING_MODEL = 'text-embedding-3-small'; // 1536 dimensions

/**
 * Trigger: Generate embedding when a new message is created
 */
export const generateMessageEmbedding = onDocumentCreated(
  {
    document: 'chats/{chatId}/messages/{messageId}',
    secrets: ['OPENAI_API_KEY', 'PINECONE_API_KEY', 'PINECONE_ENVIRONMENT', 'PINECONE_INDEX_NAME'],
  },
  async (event) => {
    const messageId = event.params.messageId;
    const chatId = event.params.chatId;
    const snapshot = event.data;
    
    if (!snapshot) {
      logger.error('No data in snapshot', { messageId });
      return;
    }

    const messageData = snapshot.data();
    
    try {
      // Skip if embedding already generated
      if (messageData.embeddingGenerated === true) {
        logger.info('Embedding already exists, skipping', { messageId });
        return;
      }

      // Skip if text is too short
      const text = messageData.text || '';
      if (text.length < 10) {
        logger.info('Message text too short for embedding', {
          messageId,
          textLength: text.length,
        });
        return;
      }

      // Check services availability
      if (!openai) {
        logger.error('OpenAI not initialized');
        return;
      }

      if (!pineconeClient) {
        logger.error('Pinecone not initialized');
        return;
      }

      logger.info('Generating embedding for message', {
        messageId,
        textLength: text.length,
        chatID: messageData.chatID,
        senderID: messageData.senderID,
      });

      // Generate embedding using OpenAI
      const startTime = Date.now();
      const embeddingResponse = await openai.embeddings.create({
        model: EMBEDDING_MODEL,
        input: text,
        encoding_format: 'float',
      });

      if (!embeddingResponse.data || embeddingResponse.data.length === 0) {
        throw new Error('No embedding data returned from OpenAI');
      }

      const embedding = embeddingResponse.data[0].embedding;
      
      // Validate dimensions
      if (embedding.length !== 1536) {
        throw new Error(`Invalid embedding dimensions: ${embedding.length}`);
      }

      const embeddingTime = Date.now() - startTime;
      logger.info('Embedding generated', {
        messageId,
        dimensions: embedding.length,
        durationMs: embeddingTime,
      });

      // Upsert to Pinecone
      const index = pineconeClient.index(PINECONE_INDEX_NAME);
      await index.upsert([{
        id: messageId,
        values: embedding,
        metadata: {
          messageId,
          chatID: chatId,  // Use chatId from event params (parent document ID)
          senderID: messageData.senderID || '',
          textPreview: text.substring(0, 100),
          timestamp: messageData.timestamp?.toDate?.()?.toISOString() || new Date().toISOString(),
        }
      }]);

      logger.info('Embedding stored in Pinecone', { messageId });

      // Update Firestore with embedding metadata
      await admin.firestore()
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          embeddingGenerated: true,
          embeddingTimestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

      const totalTime = Date.now() - startTime;
      logger.info('Embedding generation complete', {
        messageId,
        totalDurationMs: totalTime,
        success: true,
      });

    } catch (error) {
      logger.error('Failed to generate embedding', {
        messageId,
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
      });

      // Update Firestore to mark as failed (don't retry automatically)
      try {
        await admin.firestore()
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            embeddingGenerated: false,
            embeddingError: error instanceof Error ? error.message : String(error),
          });
      } catch (updateError) {
        logger.error('Failed to update error status', {
          messageId,
          error: updateError instanceof Error ? updateError.message : String(updateError),
        });
      }
    }
  }
);


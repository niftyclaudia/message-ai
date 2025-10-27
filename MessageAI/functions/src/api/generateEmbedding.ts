/**
 * Cloud Function: Generate Embedding
 * 
 * Generates a vector embedding for a message using OpenAI
 * and optionally upserts it to Pinecone
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
const EMBEDDING_MODEL = 'text-embedding-3-small'; // 1536 dimensions
const EMBEDDING_DIMENSIONS = 1536;

interface GenerateEmbeddingRequest {
  messageId: string;
  text: string;
  userId?: string;
  upsertToPinecone?: boolean;
}

interface GenerateEmbeddingResponse {
  embedding: number[];
  messageId: string;
  success: boolean;
  dimensions: number;
}

/**
 * Generate embedding for a message
 */
export const generateEmbedding = onCall<GenerateEmbeddingRequest, Promise<GenerateEmbeddingResponse>>(
  { 
    secrets: ['OPENAI_API_KEY', 'PINECONE_API_KEY', 'PINECONE_ENVIRONMENT', 'PINECONE_INDEX_NAME'],
    enforceAppCheck: false,
  },
  async (request) => {
    const startTime = Date.now();
    
    try {
      // Validate authentication
      if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
      }

      const { messageId, text, upsertToPinecone = true } = request.data;

      // Validate input
      if (!messageId || typeof messageId !== 'string') {
        throw new HttpsError('invalid-argument', 'messageId is required');
      }

      if (!text || typeof text !== 'string') {
        throw new HttpsError('invalid-argument', 'text is required');
      }

      if (text.length < 10) {
        throw new HttpsError('invalid-argument', 'text must be at least 10 characters');
      }

      // Check OpenAI availability
      if (!openai) {
        logger.error('OpenAI client not initialized');
        throw new HttpsError('failed-precondition', 'OpenAI service unavailable');
      }

      logger.info('Generating embedding', {
        messageId,
        textLength: text.length,
        userId: request.auth.uid,
      });

      // Generate embedding using OpenAI
      const embeddingResponse = await openai.embeddings.create({
        model: EMBEDDING_MODEL,
        input: text,
        encoding_format: 'float',
      });

      if (!embeddingResponse.data || embeddingResponse.data.length === 0) {
        throw new HttpsError('internal', 'Failed to generate embedding');
      }

      const embedding = embeddingResponse.data[0].embedding;

      // Validate embedding dimensions
      if (embedding.length !== EMBEDDING_DIMENSIONS) {
        logger.error('Invalid embedding dimensions', {
          expected: EMBEDDING_DIMENSIONS,
          actual: embedding.length,
        });
        throw new HttpsError('internal', 'Invalid embedding dimensions');
      }

      // Upsert to Pinecone if requested
      if (upsertToPinecone && pineconeClient) {
        try {
          const index = pineconeClient.index(PINECONE_INDEX_NAME);
          
          await index.upsert([{
            id: messageId,
            values: embedding,
            metadata: {
              messageId,
              userId: request.auth.uid,
              textPreview: text.substring(0, 100),
              timestamp: new Date().toISOString(),
            }
          }]);

          logger.info('Embedding upserted to Pinecone', { messageId });
        } catch (pineconeError) {
          logger.error('Failed to upsert to Pinecone', {
            error: pineconeError instanceof Error ? pineconeError.message : String(pineconeError),
            messageId,
          });
          // Don't fail the entire request if Pinecone fails
        }
      }

      // Update Firestore with embedding metadata
      try {
        await admin.firestore()
          .collection('messages')
          .doc(messageId)
          .update({
            embeddingGenerated: true,
            embeddingTimestamp: admin.firestore.FieldValue.serverTimestamp(),
            // Note: We don't store the full embedding in Firestore (too large)
            // It's stored in Pinecone instead
          });
      } catch (firestoreError) {
        logger.warn('Failed to update Firestore metadata', {
          error: firestoreError instanceof Error ? firestoreError.message : String(firestoreError),
          messageId,
        });
      }

      const duration = Date.now() - startTime;
      logger.info('Embedding generated successfully', {
        messageId,
        dimensions: embedding.length,
        durationMs: duration,
      });

      return {
        embedding,
        messageId,
        success: true,
        dimensions: embedding.length,
      };

    } catch (error) {
      const duration = Date.now() - startTime;
      
      logger.error('Failed to generate embedding', {
        error: error instanceof Error ? error.message : String(error),
        durationMs: duration,
      });

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError('internal', 'Failed to generate embedding');
    }
  }
);


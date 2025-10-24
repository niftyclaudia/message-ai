/**
 * Embedding generation and metadata extraction
 */

import * as admin from 'firebase-admin';
import { generateEmbedding as generateEmbeddingVector } from '../utils/openai';
import { logger } from '../utils/logger';

/**
 * Generate embedding vector for message text
 */
export async function generateEmbedding(text: string): Promise<number[]> {
  if (!text || text.trim().length === 0) {
    throw new Error('Text cannot be empty');
  }

  return generateEmbeddingVector(text);
}

/**
 * Extract keywords from text for metadata
 * Simple implementation: splits by spaces, filters common words
 */
export function extractKeywords(text: string): string[] {
  const commonWords = new Set([
    'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i',
    'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at',
    'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she',
    'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there', 'their', 'what',
    'so', 'up', 'out', 'if', 'about', 'who', 'get', 'which', 'go', 'me',
    'when', 'make', 'can', 'like', 'time', 'no', 'just', 'him', 'know', 'take',
    'is', 'am', 'are', 'was', 'were', 'been', 'has', 'had',
  ]);

  // Split by spaces and punctuation, lowercase, filter
  const words = text
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .split(/\s+/)
    .filter((word) => {
      return (
        word.length > 2 && // At least 3 characters
        !commonWords.has(word) && // Not a common word
        !/^\d+$/.test(word) // Not just numbers
      );
    });

  // Return top 10 unique keywords
  const uniqueWords = Array.from(new Set(words));
  return uniqueWords.slice(0, 10);
}

/**
 * Extract participants from text (mentions like @username)
 * Also gets all chat participants from Firestore
 */
export async function extractParticipants(
  text: string,
  chatId: string
): Promise<string[]> {
  const db = admin.firestore();
  const participants: Set<string> = new Set();

  try {
    // Get chat document to find all members
    const chatDoc = await db.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      const chatData = chatDoc.data();
      const members = chatData?.members || [];
      members.forEach((memberId: string) => participants.add(memberId));
    }

    // Extract @mentions from text (simple implementation)
    // Format: @username or @userId
    const mentionRegex = /@(\w+)/g;
    let match;
    while ((match = mentionRegex.exec(text)) !== null) {
      const mention = match[1];
      
      // Try to find user by username or displayName
      const usersSnapshot = await db
        .collection('users')
        .where('username', '==', mention)
        .limit(1)
        .get();
      
      if (!usersSnapshot.empty) {
        usersSnapshot.forEach((doc) => participants.add(doc.id));
      }
    }

    logger.info('Extracted participants', {
      chatId,
      count: participants.size,
    });

    return Array.from(participants);
  } catch (error) {
    logger.error('Failed to extract participants', { chatId, error });
    // Return empty array on error - don't fail the whole operation
    return [];
  }
}

/**
 * Generate searchable metadata for message
 */
export async function generateSearchableMetadata(
  text: string,
  chatId: string
): Promise<{
  keywords: string[];
  participants: string[];
  decisionMade?: boolean;
  hasActionItem?: boolean;
}> {
  const keywords = extractKeywords(text);
  const participants = await extractParticipants(text, chatId);

  // Simple heuristics for decision detection (can be enhanced with AI later)
  const decisionMade = /\b(decided|decision|agreed|approved|confirmed|finalized)\b/i.test(text);
  
  // Simple heuristics for action item detection
  const hasActionItem = /\b(todo|task|action item|need to|should|must|will do)\b/i.test(text);

  return {
    keywords,
    participants,
    decisionMade,
    hasActionItem,
  };
}


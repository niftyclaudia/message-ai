/**
 * Track Decisions Handler
 * Finds and logs decision patterns in a conversation thread
 */

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import { TrackDecisionsParams, Decision } from '../schemas';
import { checkUserAccess } from '../../utils/permissionChecker';
import { logger } from '../../utils/logger';
import { initializeOpenAI } from '../../utils/openai';

export async function trackDecisionsHandler(
  params: TrackDecisionsParams,
  userId: string,
  context: functions.https.CallableContext
): Promise<Decision[]> {
  const { threadId } = params;

  logger.info('trackDecisions handler started', {
    userId,
    threadId,
  });

  // Verify user has access to this thread
  const hasAccess = await checkUserAccess(userId, threadId, 'thread');
  if (!hasAccess) {
    throw new Error('permission_denied: You do not have access to this thread');
  }

  try {
    // Fetch messages from the thread
    const db = admin.firestore();
    const messagesSnapshot = await db
      .collection('messages')
      .where('chatID', '==', threadId)
      .orderBy('timestamp', 'asc')
      .get();

    if (messagesSnapshot.empty) {
      return [];
    }

    // Extract messages with metadata
    const messages = messagesSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        text: data.text || '',
        senderId: data.senderID || '',
        timestamp: data.timestamp?.toDate() || new Date(),
      };
    });

    const conversationText = messages
      .map((m, i) => `[${i + 1}] ${m.text}`)
      .join('\n');

    // Use OpenAI to detect decisions
    const openai = initializeOpenAI();

    const systemPrompt = `You are an AI assistant that identifies decisions made in conversations.

Look for decision patterns like:
- "We decided to...", "Let's go with...", "We're choosing..."
- "Agreed on...", "Approved...", "Confirmed..."
- Final choices: "We'll use X instead of Y"
- Commitments: "We're moving forward with..."

For each decision, provide:
1. decisionText: Clear statement of what was decided (1-2 sentences)
2. confidence: How confident you are this is a real decision (0.0-1.0)
3. timestamp: When the decision was made (use message index to estimate)

Return array of decisions as JSON. If no decisions found, return empty array.
Only include decisions with confidence >= 0.6.`;

    const response = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        {
          role: 'user',
          content: `Find decisions in this conversation:\n\n${conversationText.substring(0, 4000)}`,
        },
      ],
      temperature: 0.3,
      max_tokens: 1000,
    });

    const resultText = response.choices[0]?.message?.content;
    if (!resultText) {
      throw new Error('OpenAI returned empty response');
    }

    // Parse JSON response
    const parsed = JSON.parse(resultText);
    const decisions: Decision[] = [];

    // Get unique participants
    const participants = Array.from(new Set(messages.map((m) => m.senderId)));

    if (Array.isArray(parsed)) {
      for (const item of parsed) {
        // Only include decisions with confidence >= 0.6
        if (item.confidence < 0.6) {
          continue;
        }

        // Estimate timestamp based on message index if provided
        let timestamp = new Date();
        if (item.messageIndex && messages[item.messageIndex - 1]) {
          timestamp = messages[item.messageIndex - 1].timestamp;
        }

        decisions.push({
          id: db.collection('decisions').doc().id, // Generate new ID
          decisionText: item.decisionText || 'Decision recorded',
          participants,
          timestamp,
          confidence: Math.min(Math.max(item.confidence, 0), 1),
        });
      }
    }

    logger.info('trackDecisions completed', {
      userId,
      threadId,
      decisionsCount: decisions.length,
    });

    return decisions;
  } catch (error: any) {
    logger.error('trackDecisions failed', { error, userId, threadId });

    // Check if OpenAI is down
    if (error.message?.includes('openai') || error.response?.status >= 500) {
      throw new Error('service_unavailable: Decision tracking service temporarily unavailable');
    }

    throw error;
  }
}


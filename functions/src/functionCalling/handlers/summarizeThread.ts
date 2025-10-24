/**
 * Summarize Thread Handler
 * Condenses a conversation thread to 2-3 sentences with key points
 */

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import { SummarizeThreadParams, ThreadSummary } from '../schemas';
import { checkUserAccess } from '../../utils/permissionChecker';
import { logger } from '../../utils/logger';
import { initializeOpenAI } from '../../utils/openai';

export async function summarizeThreadHandler(
  params: SummarizeThreadParams,
  userId: string,
  context: functions.https.CallableContext
): Promise<ThreadSummary> {
  const { threadId, maxLength = 300 } = params;

  logger.info('summarizeThread handler started', {
    userId,
    threadId,
    maxLength,
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
      return {
        summary: 'No messages in this thread.',
        keyPoints: [],
        participants: [],
        decisionCount: 0,
        messageCount: 0,
      };
    }

    // Extract messages and participants
    const messages = messagesSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        text: data.text || '',
        senderId: data.senderID || '',
        timestamp: data.timestamp,
      };
    });

    const participants = Array.from(new Set(messages.map((m) => m.senderId)));
    const conversationText = messages
      .map((m, i) => `[${i + 1}] ${m.text}`)
      .join('\n');

    // Use OpenAI to generate summary
    const openai = initializeOpenAI();

    const systemPrompt = `You are an AI assistant that summarizes conversations concisely.

Create a summary with:
1. summary: 2-3 sentence overview of the main topics and outcomes (max ${maxLength} characters)
2. keyPoints: Array of 3-5 key discussion points (brief phrases)
3. decisionCount: Number of decisions made (look for phrases like "let's do", "we decided", "agreed")

Keep the summary clear, actionable, and focused on what matters.
Format as JSON.`;

    const response = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        {
          role: 'user',
          content: `Summarize this conversation (${messages.length} messages):\n\n${conversationText.substring(0, 4000)}`,
        },
      ],
      temperature: 0.3,
      max_tokens: 500,
    });

    const resultText = response.choices[0]?.message?.content;
    if (!resultText) {
      throw new Error('OpenAI returned empty response');
    }

    // Parse JSON response
    const parsed = JSON.parse(resultText);

    // Ensure summary doesn't exceed maxLength
    let summary = parsed.summary || 'Conversation summary unavailable.';
    if (summary.length > maxLength) {
      summary = summary.substring(0, maxLength - 3) + '...';
    }

    const result: ThreadSummary = {
      summary,
      keyPoints: Array.isArray(parsed.keyPoints) ? parsed.keyPoints.slice(0, 5) : [],
      participants,
      decisionCount: Math.max(0, parsed.decisionCount || 0),
      messageCount: messages.length,
    };

    logger.info('summarizeThread completed', {
      userId,
      threadId,
      messageCount: result.messageCount,
      keyPointsCount: result.keyPoints.length,
      decisionCount: result.decisionCount,
    });

    return result;
  } catch (error: any) {
    logger.error('summarizeThread failed', { error, userId, threadId });

    // Check if OpenAI is down
    if (error.message?.includes('openai') || error.response?.status >= 500) {
      throw new Error('service_unavailable: Summarization service temporarily unavailable');
    }

    throw error;
  }
}


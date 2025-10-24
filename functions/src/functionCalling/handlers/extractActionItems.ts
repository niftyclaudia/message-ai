/**
 * Extract Action Items Handler
 * Finds tasks requiring action from a conversation thread
 */

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import { ExtractActionItemsParams, ActionItem } from '../schemas';
import { checkUserAccess } from '../../utils/permissionChecker';
import { logger } from '../../utils/logger';
import { initializeOpenAI } from '../../utils/openai';

export async function extractActionItemsHandler(
  params: ExtractActionItemsParams,
  userId: string,
  context: functions.https.CallableContext
): Promise<ActionItem[]> {
  const { threadId } = params;

  logger.info('extractActionItems handler started', {
    userId,
    threadId,
  });

  // Verify user is making request for themselves
  if (params.userId !== userId) {
    throw new Error('permission_denied: Cannot extract action items for another user');
  }

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

    // Extract messages with IDs
    const messages = messagesSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        text: data.text || '',
        senderId: data.senderID || '',
        timestamp: data.timestamp,
      };
    });

    const conversationText = messages
      .map((m, i) => `[Message ${i + 1}, ID: ${m.id}] ${m.text}`)
      .join('\n');

    // Use OpenAI to extract action items
    const openai = initializeOpenAI();

    const systemPrompt = `You are an AI assistant that extracts action items from conversations.

Identify tasks that require action. Look for:
- Explicit tasks: "Can you send the report?", "Please review the doc"
- Commitments: "I'll send it by Friday", "I will call them tomorrow"
- Deadlines: "Need this by EOD", "Due next week"
- Questions requiring responses: "What do you think about X?"

For each action item, provide:
1. task: Clear description of what needs to be done (concise)
2. deadline: Estimated deadline if mentioned (ISO date string, or null)
3. assignee: Who needs to do it (if clear), or null
4. sourceMessageId: The message ID where this action item was found

Return array of action items as JSON. If no action items found, return empty array.`;

    const response = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        {
          role: 'user',
          content: `Extract action items from this conversation:\n\n${conversationText.substring(0, 4000)}`,
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
    const actionItems: ActionItem[] = [];

    if (Array.isArray(parsed)) {
      for (const item of parsed) {
        // Validate sourceMessageId exists in our messages
        const sourceMessage = messages.find((m) => m.id === item.sourceMessageId);
        if (!sourceMessage) {
          // Skip invalid action items
          continue;
        }

        actionItems.push({
          id: db.collection('actionItems').doc().id, // Generate new ID
          task: item.task || 'Unknown task',
          deadline: item.deadline ? new Date(item.deadline) : undefined,
          assignee: item.assignee || undefined,
          sourceMessageId: item.sourceMessageId,
          createdAt: new Date(),
        });
      }
    }

    logger.info('extractActionItems completed', {
      userId,
      threadId,
      actionItemsCount: actionItems.length,
    });

    return actionItems;
  } catch (error: any) {
    logger.error('extractActionItems failed', { error, userId, threadId });

    // Check if OpenAI is down
    if (error.message?.includes('openai') || error.response?.status >= 500) {
      throw new Error('service_unavailable: Action item extraction service temporarily unavailable');
    }

    throw error;
  }
}


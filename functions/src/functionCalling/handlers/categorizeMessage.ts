/**
 * Categorize Message Handler
 * Analyzes message content to detect priority level (urgent, canWait, aiHandled)
 */

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import { CategorizeMessageParams, MessageCategory, CategoryType } from '../schemas';
import { checkUserAccess } from '../../utils/permissionChecker';
import { logger } from '../../utils/logger';
import { initializeOpenAI } from '../../utils/openai';

export async function categorizeMessageHandler(
  params: CategorizeMessageParams,
  userId: string,
  context: functions.https.CallableContext
): Promise<MessageCategory> {
  const { messageId } = params;

  logger.info('categorizeMessage handler started', {
    userId,
    messageId,
  });

  // Verify user is making request for themselves
  if (params.userId !== userId) {
    throw new Error('permission_denied: Cannot categorize message for another user');
  }

  // Verify user has access to this message
  const hasAccess = await checkUserAccess(userId, messageId, 'message');
  if (!hasAccess) {
    throw new Error('permission_denied: You do not have access to this message');
  }

  try {
    // Fetch message from Firestore
    const db = admin.firestore();
    const messageDoc = await db.collection('messages').doc(messageId).get();

    if (!messageDoc.exists) {
      throw new Error('Message not found');
    }

    const message = messageDoc.data();
    if (!message || !message.text) {
      throw new Error('Message has no text content');
    }

    // Use OpenAI to categorize the message
    const openai = initializeOpenAI();
    
    const systemPrompt = `You are an AI assistant that categorizes messages by priority.
    
Analyze the message and categorize it as:
- "urgent": Requires immediate attention (deadlines, emergencies, time-sensitive requests)
- "canWait": Important but not urgent (questions, updates, non-time-sensitive)
- "aiHandled": Low priority, informational, or can be auto-handled (acknowledgments, FYI, automated)

Provide:
1. category: one of the three categories
2. confidence: 0.0-1.0 (how confident you are)
3. reasoning: brief explanation (1-2 sentences)
4. signals: array of key phrases that influenced your decision

Format as JSON.`;

    const response = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: `Categorize this message: "${message.text}"` },
      ],
      temperature: 0.3,
      max_tokens: 200,
    });

    const resultText = response.choices[0]?.message?.content;
    if (!resultText) {
      throw new Error('OpenAI returned empty response');
    }

    // Parse JSON response
    const parsed = JSON.parse(resultText);
    
    // Validate category
    const validCategories: CategoryType[] = ['urgent', 'canWait', 'aiHandled'];
    const category: CategoryType = validCategories.includes(parsed.category)
      ? parsed.category
      : 'canWait';

    const result: MessageCategory = {
      category,
      confidence: Math.min(Math.max(parsed.confidence || 0.5, 0), 1),
      reasoning: parsed.reasoning || 'Automatic categorization',
      signals: Array.isArray(parsed.signals) ? parsed.signals : [],
    };

    logger.info('categorizeMessage completed', {
      userId,
      messageId,
      category: result.category,
      confidence: result.confidence,
    });

    return result;
  } catch (error: any) {
    logger.error('categorizeMessage failed', { error, userId, messageId });

    // Check if OpenAI is down
    if (error.message?.includes('openai') || error.response?.status >= 500) {
      throw new Error('service_unavailable: Categorization service temporarily unavailable');
    }

    throw error;
  }
}


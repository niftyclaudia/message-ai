/**
 * Error Handling Utilities
 * Unified error handling and response formatting for function calling
 */

import * as functions from 'firebase-functions/v1';
import { logger } from './logger';

export type ErrorCode =
  | 'invalid_function'
  | 'invalid_parameters'
  | 'permission_denied'
  | 'timeout'
  | 'service_unavailable'
  | 'internal_error';

export interface FunctionExecutionError {
  code: ErrorCode;
  message: string;
  details?: string;
}

/**
 * Create a user-friendly error response
 */
export function createErrorResponse(
  code: ErrorCode,
  message: string,
  details?: string
): FunctionExecutionError {
  return {
    code,
    message,
    details,
  };
}

/**
 * Map error to appropriate HttpsError for Firebase Functions
 */
export function toHttpsError(
  error: FunctionExecutionError
): functions.https.HttpsError {
  const codeMap: Record<ErrorCode, functions.https.FunctionsErrorCode> = {
    invalid_function: 'not-found',
    invalid_parameters: 'invalid-argument',
    permission_denied: 'permission-denied',
    timeout: 'deadline-exceeded',
    service_unavailable: 'unavailable',
    internal_error: 'internal',
  };

  return new functions.https.HttpsError(
    codeMap[error.code],
    error.message,
    error.details
  );
}

/**
 * Handle function execution errors with proper categorization
 */
export function handleFunctionError(
  error: Error,
  functionName: string
): FunctionExecutionError {
  logger.error('Function execution error', {
    functionName,
    error: error.message,
    stack: error.stack,
  });

  // Check for specific error types
  if (error.message.includes('timeout')) {
    return createErrorResponse(
      'timeout',
      'Request took too long to complete',
      `${functionName} exceeded the 2 second timeout`
    );
  }

  if (error.message.includes('permission') || error.message.includes('access')) {
    return createErrorResponse(
      'permission_denied',
      'You do not have permission to access this resource',
      error.message
    );
  }

  if (error.message.includes('validation') || error.message.includes('invalid')) {
    return createErrorResponse(
      'invalid_parameters',
      'Invalid parameters provided',
      error.message
    );
  }

  if (
    error.message.includes('openai') ||
    error.message.includes('pinecone') ||
    error.message.includes('vector_db')
  ) {
    return createErrorResponse(
      'service_unavailable',
      'External service temporarily unavailable',
      'AI service or vector database is not responding'
    );
  }

  // Generic internal error
  return createErrorResponse(
    'internal_error',
    'An unexpected error occurred',
    `Error in ${functionName}: ${error.message}`
  );
}

/**
 * Create fallback text response when function fails
 */
export function createFallbackResponse(
  functionName: string,
  error: FunctionExecutionError
): string {
  const actionMap: Record<string, string> = {
    summarizeThread: 'summarize this conversation',
    extractActionItems: 'extract action items',
    searchMessages: 'search your messages',
    categorizeMessage: 'categorize this message',
    trackDecisions: 'track decisions',
    detectSchedulingNeed: 'detect scheduling needs',
    checkCalendar: 'check your calendar',
    suggestMeetingTimes: 'suggest meeting times',
  };

  const action = actionMap[functionName] || 'complete this action';

  const suggestions: Record<ErrorCode, string> = {
    invalid_function: 'This feature is not available.',
    invalid_parameters: 'Please check your input and try again.',
    permission_denied: 'You may not have access to this information.',
    timeout: 'This is taking longer than expected. Please try again.',
    service_unavailable: 'The AI service is temporarily unavailable. Please try again in a moment.',
    internal_error: 'Something went wrong on our end. Please try again.',
  };

  return `I tried to ${action} but encountered an issue. ${suggestions[error.code]} ${error.details ? `(${error.details})` : ''}`;
}

/**
 * Validate error response format
 */
export function isValidErrorResponse(obj: any): obj is FunctionExecutionError {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    typeof obj.code === 'string' &&
    typeof obj.message === 'string'
  );
}


/**
 * Function Calling Orchestrator
 * Central router that validates, executes, and logs function calls
 */

import * as functions from 'firebase-functions/v1';
import { validateParameters } from './validation';
import { logExecution } from '../utils/executionLogger';
import {
  handleFunctionError,
  createErrorResponse,
  toHttpsError,
  FunctionExecutionError,
} from '../utils/errorHandler';
import { logger } from '../utils/logger';

// Import all handlers
import { summarizeThreadHandler } from './handlers/summarizeThread';
import { extractActionItemsHandler } from './handlers/extractActionItems';
import { searchMessagesHandler } from './handlers/searchMessages';
import { categorizeMessageHandler } from './handlers/categorizeMessage';
import { trackDecisionsHandler } from './handlers/trackDecisions';
import { detectSchedulingNeedHandler } from './handlers/detectSchedulingNeed';
import { checkCalendarHandler } from './handlers/checkCalendar';
import { suggestMeetingTimesHandler } from './handlers/suggestMeetingTimes';

// Function handler type
type FunctionHandler<TParams, TResult> = (
  params: TParams,
  userId: string,
  context: functions.https.CallableContext
) => Promise<TResult>;

// Handler registry
const HANDLER_MAP: Record<string, FunctionHandler<any, any>> = {
  summarizeThread: summarizeThreadHandler,
  extractActionItems: extractActionItemsHandler,
  searchMessages: searchMessagesHandler,
  categorizeMessage: categorizeMessageHandler,
  trackDecisions: trackDecisionsHandler,
  detectSchedulingNeed: detectSchedulingNeedHandler,
  checkCalendar: checkCalendarHandler,
  suggestMeetingTimes: suggestMeetingTimesHandler,
};

// Function execution result wrapper
export interface FunctionExecutionResult<T> {
  success: boolean;
  result?: T;
  error?: FunctionExecutionError;
  executionTime: number;
}

/**
 * Execute function call with timeout
 */
async function executeWithTimeout<T>(
  handler: () => Promise<T>,
  timeoutMs: number = 2000
): Promise<T> {
  return Promise.race([
    handler(),
    new Promise<T>((_, reject) =>
      setTimeout(() => reject(new Error('timeout')), timeoutMs)
    ),
  ]);
}

/**
 * Main orchestrator: routes and executes function calls
 */
export async function executeFunctionCall(
  functionName: string,
  parameters: Record<string, any>,
  userId: string,
  context: functions.https.CallableContext
): Promise<FunctionExecutionResult<any>> {
  const startTime = Date.now();

  logger.info('Function call started', {
    functionName,
    userId,
    parameters: Object.keys(parameters),
  });

  try {
    // Step 1: Validate function name
    const handler = HANDLER_MAP[functionName];
    if (!handler) {
      const error = createErrorResponse(
        'invalid_function',
        'Unknown function',
        `Function '${functionName}' does not exist`
      );
      
      const executionTime = Date.now() - startTime;
      
      await logExecution(
        functionName,
        parameters,
        userId,
        executionTime,
        'error',
        error.message
      );

      return {
        success: false,
        error,
        executionTime,
      };
    }

    // Step 2: Validate parameters
    const validation = validateParameters(functionName, parameters);
    if (!validation.valid) {
      const error = createErrorResponse(
        'invalid_parameters',
        'Invalid parameters',
        validation.errors.join(', ')
      );

      const executionTime = Date.now() - startTime;

      await logExecution(
        functionName,
        parameters,
        userId,
        executionTime,
        'error',
        error.message
      );

      return {
        success: false,
        error,
        executionTime,
      };
    }

    // Step 3: Execute handler with timeout
    let result: any;
    let status: 'success' | 'error' | 'timeout' = 'success';
    let errorDetails: string | undefined;

    try {
      result = await executeWithTimeout(
        () => handler(parameters, userId, context),
        2000 // 2 second timeout
      );
    } catch (error: any) {
      status = error.message === 'timeout' ? 'timeout' : 'error';
      const functionError = handleFunctionError(error, functionName);
      errorDetails = functionError.message;

      const executionTime = Date.now() - startTime;

      await logExecution(
        functionName,
        parameters,
        userId,
        executionTime,
        status,
        errorDetails
      );

      return {
        success: false,
        error: functionError,
        executionTime,
      };
    }

    // Step 4: Log successful execution
    const executionTime = Date.now() - startTime;
    
    const resultSummary = typeof result === 'object'
      ? `Returned ${Array.isArray(result) ? result.length : 'object'}`
      : 'Returned result';

    await logExecution(
      functionName,
      parameters,
      userId,
      executionTime,
      'success',
      undefined,
      resultSummary
    );

    logger.info('Function call completed', {
      functionName,
      userId,
      executionTime,
    });

    return {
      success: true,
      result,
      executionTime,
    };
  } catch (error: any) {
    // Catch-all for unexpected errors
    const executionTime = Date.now() - startTime;
    const functionError = handleFunctionError(error, functionName);

    await logExecution(
      functionName,
      parameters,
      userId,
      executionTime,
      'error',
      functionError.message
    );

    logger.error('Function call failed unexpectedly', {
      functionName,
      userId,
      error: error.message,
    });

    return {
      success: false,
      error: functionError,
      executionTime,
    };
  }
}

/**
 * Cloud Function: executeFunctionCall
 * HTTP Callable function for executing function calls
 */
export const executeFunctionCallFunction = functions.https.onCall(
  async (
    data: { functionName: string; parameters: Record<string, any> },
    context: functions.https.CallableContext
  ) => {
    // Check authentication
    if (!context.auth) {
      logger.error('Unauthenticated call to executeFunctionCall');
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be authenticated to execute functions'
      );
    }

    const userId = context.auth.uid;
    const { functionName, parameters } = data;

    // Validate input
    if (!functionName || typeof functionName !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'functionName must be a string'
      );
    }

    if (!parameters || typeof parameters !== 'object') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'parameters must be an object'
      );
    }

    // Execute function call
    const result = await executeFunctionCall(functionName, parameters, userId, context);

    // If error, throw HttpsError
    if (!result.success && result.error) {
      throw toHttpsError(result.error);
    }

    // Return successful result
    return result;
  }
);


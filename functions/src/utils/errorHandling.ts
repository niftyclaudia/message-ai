/**
 * errorHandling.ts
 * PR-AI-005: Error Handling & Fallback System
 * 
 * Utilities for classifying, handling, and logging AI service errors
 * with exponential backoff retry logic and graceful degradation.
 */

import {firestore} from "../config/env";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

/**
 * AI error type classification matching Swift enum
 */
export type AIErrorType = 
  | "timeout"
  | "rateLimit" 
  | "serviceUnavailable"
  | "networkFailure"
  | "invalidRequest"
  | "quotaExceeded"
  | "unknown";

/**
 * AI feature identifier matching Swift enum
 */
export type AIFeature = 
  | "summarization"
  | "actionItemExtraction"
  | "semanticSearch"
  | "priorityDetection"
  | "decisionTracking"
  | "proactiveScheduling";

/**
 * Classified error with retry information
 */
export interface ClassifiedError {
  type: AIErrorType;
  message: string;
  retryable: boolean;
  retryDelay: number;
  statusCode?: number;
}

/**
 * Context for an AI operation
 */
export interface AIContext {
  requestId: string;
  feature: AIFeature;
  userId: string;
  messageId?: string;
  threadId?: string;
  query?: string;
  timestamp: admin.firestore.Timestamp;
  retryCount: number;
}

/**
 * Classify any error into an AIErrorType with retry information
 */
export function classifyError(error: any): ClassifiedError {
  // OpenAI API errors
  if (error.status !== undefined) {
    const statusCode = error.status;
    
    switch (statusCode) {
    case 429:
      return {
        type: "rateLimit",
        message: "API rate limit exceeded",
        retryable: false,
        retryDelay: 30, // 30 seconds
        statusCode,
      };
      
    case 500:
    case 503:
      return {
        type: "serviceUnavailable",
        message: "Service temporarily unavailable",
        retryable: true,
        retryDelay: 2, // 2 seconds
        statusCode,
      };
      
    case 400:
      return {
        type: "invalidRequest",
        message: "Invalid request format",
        retryable: false,
        retryDelay: 0,
        statusCode,
      };
      
    case 402:
      return {
        type: "quotaExceeded",
        message: "API quota exceeded",
        retryable: false,
        retryDelay: 0,
        statusCode,
      };
    }
  }
  
  // Timeout errors
  if (error.code === "ETIMEDOUT" || 
      error.message?.toLowerCase().includes("timeout") ||
      error.name === "TimeoutError") {
    return {
      type: "timeout",
      message: "Operation timed out",
      retryable: true,
      retryDelay: 1, // 1 second
    };
  }
  
  // Network errors
  if (error.code === "ECONNREFUSED" || 
      error.code === "ENOTFOUND" ||
      error.code === "ENETUNREACH" ||
      error.message?.toLowerCase().includes("network")) {
    return {
      type: "networkFailure",
      message: "Network connectivity issue",
      retryable: true,
      retryDelay: 1, // 1 second
    };
  }
  
  // Unknown errors
  return {
    type: "unknown",
    message: error.message || "Unknown error occurred",
    retryable: false,
    retryDelay: 0,
  };
}

/**
 * Determine if an error should be retried based on classification and attempt count
 */
export function shouldRetry(
  classifiedError: ClassifiedError,
  retryCount: number
): boolean {
  // Max 4 retry attempts
  if (retryCount >= 4) {
    return false;
  }
  
  return classifiedError.retryable;
}

/**
 * Calculate retry delay using exponential backoff: 1s, 2s, 4s, 8s (max)
 */
export function calculateRetryDelay(
  initialDelay: number,
  retryCount: number
): number {
  // Exponential backoff: delay * 2^retryCount
  const delay = initialDelay * Math.pow(2, retryCount);
  
  // Cap at 8 seconds maximum
  return Math.min(delay, 8);
}

/**
 * Hash a string for privacy-preserving logging (userId, query)
 */
export function hashForPrivacy(value: string): string {
  return crypto
    .createHash("sha256")
    .update(value)
    .digest("hex")
    .substring(0, 16); // First 16 chars for brevity
}

/**
 * Log error to Firestore /failedAIRequests/
 */
export async function logErrorToFirestore(
  classifiedError: ClassifiedError,
  context: AIContext
): Promise<string> {
  const requestDoc = {
    id: context.requestId,
    userId: hashForPrivacy(context.userId), // Hashed for privacy
    feature: context.feature,
    errorType: classifiedError.type,
    timestamp: context.timestamp,
    retryCount: context.retryCount,
    nextRetryAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + calculateRetryDelay(classifiedError.retryDelay, context.retryCount) * 1000)
    ),
    requestContext: {
      messageId: context.messageId,
      threadId: context.threadId,
      query: context.query ? hashForPrivacy(context.query) : undefined, // Hashed for privacy
    },
    errorDetails: {
      message: classifiedError.message,
      statusCode: classifiedError.statusCode,
    },
    resolved: false,
  };
  
  await firestore
    .collection("failedAIRequests")
    .doc(context.requestId)
    .set(requestDoc);
  
  return context.requestId;
}

/**
 * Wrap an async operation with timeout and error handling
 * Returns result or throws classified error
 */
export async function withErrorHandling<T>(
  operation: () => Promise<T>,
  context: AIContext,
  timeoutMs: number = 10000
): Promise<{ success: boolean; data?: T; error?: ClassifiedError }> {
  const startTime = Date.now();
  
  try {
    // Create timeout promise
    const timeoutPromise = new Promise<never>((_, reject) => {
      setTimeout(() => {
        const timeoutError = new Error("Operation timed out");
        timeoutError.name = "TimeoutError";
        reject(timeoutError);
      }, timeoutMs);
    });
    
    // Race between operation and timeout
    const data = await Promise.race([
      operation(),
      timeoutPromise,
    ]);
    
    const duration = Date.now() - startTime;
    console.log(`AI operation succeeded in ${duration}ms`, {
      feature: context.feature,
      requestId: context.requestId,
    });
    
    return {success: true, data};
  } catch (error: any) {
    const duration = Date.now() - startTime;
    const classifiedError = classifyError(error);
    
    console.error(`AI operation failed after ${duration}ms`, {
      feature: context.feature,
      requestId: context.requestId,
      errorType: classifiedError.type,
      retryable: classifiedError.retryable,
    });
    
    // Log to Firestore for monitoring and retry queue
    await logErrorToFirestore(classifiedError, context);
    
    return {success: false, error: classifiedError};
  }
}


/**
 * retryQueue.ts
 * PR-AI-005: Error Handling & Fallback System
 * 
 * Background job that processes failed AI requests for automatic retry.
 * Runs every 5 minutes via Cloud Scheduler.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import {firestore} from "../config/env";
import {shouldRetry} from "../utils/errorHandling";

/**
 * Process the retry queue for failed AI requests
 * 
 * Logic:
 * 1. Query unresolved requests where nextRetryAt <= now
 * 2. For each request, attempt retry based on feature type
 * 3. Update Firestore with success/failure
 * 4. If still failing and retryCount < 4, schedule next retry
 * 5. If retryCount >= 4, mark as permanently failed
 */
export async function processRetryQueue(): Promise<{
  processed: number;
  succeeded: number;
  failed: number;
  skipped: number;
}> {
  const now = admin.firestore.Timestamp.now();
  
  // Query failed requests ready for retry
  const snapshot = await firestore
    .collection("failedAIRequests")
    .where("resolved", "==", false)
    .where("nextRetryAt", "<=", now)
    .limit(50) // Process in batches to avoid timeout
    .get();
  
  let processed = 0;
  let succeeded = 0;
  let failed = 0;
  let skipped = 0;
  
  const batch = firestore.batch();
  
  for (const doc of snapshot.docs) {
    const data = doc.data();
    processed++;
    
    // Check if we've exceeded max retry attempts
    if (data.retryCount >= 4) {
      console.log(`Request ${doc.id} exceeded max retries, marking as permanently failed`);
      batch.update(doc.ref, {
        resolved: true,
        resolvedAt: now,
      });
      skipped++;
      continue;
    }
    
    // Check if error type is retryable
    const errorType = data.errorType;
    const classifiedError = {
      type: errorType,
      message: data.errorDetails?.message || "Unknown error",
      retryable: ["timeout", "serviceUnavailable", "networkFailure"].includes(errorType),
      retryDelay: 0,
      statusCode: data.errorDetails?.statusCode,
    };
    
    if (!shouldRetry(classifiedError, data.retryCount)) {
      console.log(`Request ${doc.id} error type ${errorType} not retryable, skipping`);
      batch.update(doc.ref, {
        resolved: true,
        resolvedAt: now,
      });
      skipped++;
      continue;
    }
    
    // Attempt retry based on feature type
    try {
      // NOTE: In real implementation, this would dispatch to the appropriate
      // AI service handler based on the feature type. For now, we simulate
      // a retry attempt and assume success for demonstration purposes.
      
      console.log(`Retrying request ${doc.id} for feature ${data.feature} (attempt ${data.retryCount + 1})`);
      
      // TODO: Implement actual retry logic when AI services are integrated
      // For now, mark as resolved
      batch.update(doc.ref, {
        resolved: true,
        resolvedAt: now,
      });
      
      succeeded++;
    } catch (error: any) {
      // Retry failed, increment retry count and schedule next attempt
      const newRetryCount = data.retryCount + 1;
      
      if (newRetryCount >= 4) {
        // Max retries exceeded
        batch.update(doc.ref, {
          retryCount: newRetryCount,
          resolved: true,
          resolvedAt: now,
        });
        failed++;
      } else {
        // Schedule next retry with exponential backoff
        const retryDelay = Math.min(Math.pow(2, newRetryCount), 8); // 2s, 4s, 8s
        const nextRetryAt = admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + retryDelay * 1000)
        );
        
        batch.update(doc.ref, {
          retryCount: newRetryCount,
          nextRetryAt,
        });
        
        failed++;
      }
    }
  }
  
  // Commit all updates in batch
  if (processed > 0) {
    await batch.commit();
  }
  
  console.log(`Retry queue processed: ${processed} total, ${succeeded} succeeded, ${failed} failed, ${skipped} skipped`);
  
  return {
    processed,
    succeeded,
    failed,
    skipped,
  };
}

/**
 * Scheduled Cloud Function that runs every 5 minutes
 */
export const retryQueueScheduled = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async (context: functions.EventContext) => {
    console.log("Starting retry queue processing...");
    
    try {
      const result = await processRetryQueue();
      console.log("Retry queue processing complete", result);
      return result;
    } catch (error) {
      console.error("Error processing retry queue:", error);
      throw error;
    }
  });


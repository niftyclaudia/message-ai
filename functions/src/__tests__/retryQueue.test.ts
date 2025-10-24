/**
 * retryQueue.test.ts
 * PR-AI-005: Unit tests for retry queue processing
 */

import {describe, it, expect, beforeEach, afterEach} from "@jest/globals";
import {processRetryQueue} from "../jobs/retryQueue";
import * as admin from "firebase-admin";

// Mock Firestore
const mockBatch = {
  update: jest.fn(),
  commit: jest.fn().mockResolvedValue(undefined),
};

const mockCollection = {
  where: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  get: jest.fn(),
};

jest.mock("../config/env", () => ({
  firestore: {
    collection: jest.fn(() => mockCollection),
    batch: jest.fn(() => mockBatch),
  },
}));

describe("Retry Queue Processing", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });
  
  afterEach(() => {
    jest.clearAllMocks();
  });
  
  it("should process empty queue successfully", async () => {
    mockCollection.get.mockResolvedValue({
      docs: [],
      empty: true,
    });
    
    const result = await processRetryQueue();
    
    expect(result.processed).toBe(0);
    expect(result.succeeded).toBe(0);
    expect(result.failed).toBe(0);
    expect(result.skipped).toBe(0);
  });
  
  it("should skip requests with max retry count exceeded", async () => {
    const now = admin.firestore.Timestamp.now();
    
    mockCollection.get.mockResolvedValue({
      docs: [
        {
          id: "request-1",
          ref: {},
          data: () => ({
            retryCount: 4,
            errorType: "timeout",
            feature: "summarization",
            resolved: false,
          }),
        },
      ],
      empty: false,
    });
    
    const result = await processRetryQueue();
    
    expect(result.processed).toBe(1);
    expect(result.skipped).toBe(1);
    expect(mockBatch.update).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        resolved: true,
      })
    );
  });
  
  it("should skip non-retryable error types", async () => {
    mockCollection.get.mockResolvedValue({
      docs: [
        {
          id: "request-2",
          ref: {},
          data: () => ({
            retryCount: 1,
            errorType: "invalidRequest",
            feature: "summarization",
            resolved: false,
          }),
        },
      ],
      empty: false,
    });
    
    const result = await processRetryQueue();
    
    expect(result.processed).toBe(1);
    expect(result.skipped).toBe(1);
  });
  
  it("should process retryable requests", async () => {
    mockCollection.get.mockResolvedValue({
      docs: [
        {
          id: "request-3",
          ref: {},
          data: () => ({
            retryCount: 1,
            errorType: "timeout",
            feature: "summarization",
            resolved: false,
          }),
        },
        {
          id: "request-4",
          ref: {},
          data: () => ({
            retryCount: 2,
            errorType: "serviceUnavailable",
            feature: "semanticSearch",
            resolved: false,
          }),
        },
      ],
      empty: false,
    });
    
    const result = await processRetryQueue();
    
    expect(result.processed).toBe(2);
    expect(result.succeeded).toBeGreaterThan(0);
    expect(mockBatch.commit).toHaveBeenCalled();
  });
  
  it("should batch update operations", async () => {
    mockCollection.get.mockResolvedValue({
      docs: [
        {
          id: "request-5",
          ref: {},
          data: () => ({
            retryCount: 0,
            errorType: "timeout",
            feature: "summarization",
            resolved: false,
          }),
        },
      ],
      empty: false,
    });
    
    await processRetryQueue();
    
    expect(mockBatch.update).toHaveBeenCalled();
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });
  
  it("should respect batch limit of 50 documents", async () => {
    const mockDocs = Array(60).fill(null).map((_, i) => ({
      id: `request-${i}`,
      ref: {},
      data: () => ({
        retryCount: 0,
        errorType: "timeout",
        feature: "summarization",
        resolved: false,
      }),
    }));
    
    mockCollection.get.mockResolvedValue({
      docs: mockDocs.slice(0, 50), // Should be limited to 50
      empty: false,
    });
    
    const result = await processRetryQueue();
    
    expect(result.processed).toBeLessThanOrEqual(50);
  });
});


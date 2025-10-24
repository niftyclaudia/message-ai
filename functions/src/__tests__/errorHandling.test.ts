/**
 * errorHandling.test.ts
 * PR-AI-005: Unit tests for error handling utilities
 */

import {describe, it, expect, beforeEach} from "@jest/globals";
import {
  classifyError,
  shouldRetry,
  calculateRetryDelay,
  hashForPrivacy,
} from "../utils/errorHandling";

describe("Error Handling Utils", () => {
  describe("classifyError", () => {
    it("should classify timeout errors", () => {
      const timeoutError = {
        name: "TimeoutError",
        message: "Operation timed out",
      };
      
      const result = classifyError(timeoutError);
      
      expect(result.type).toBe("timeout");
      expect(result.retryable).toBe(true);
      expect(result.retryDelay).toBe(1);
    });
    
    it("should classify rate limit errors (429)", () => {
      const rateLimitError = {
        status: 429,
        message: "Too many requests",
      };
      
      const result = classifyError(rateLimitError);
      
      expect(result.type).toBe("rateLimit");
      expect(result.retryable).toBe(false);
      expect(result.retryDelay).toBe(30);
      expect(result.statusCode).toBe(429);
    });
    
    it("should classify service unavailable errors (500/503)", () => {
      const serviceError = {
        status: 503,
        message: "Service temporarily unavailable",
      };
      
      const result = classifyError(serviceError);
      
      expect(result.type).toBe("serviceUnavailable");
      expect(result.retryable).toBe(true);
      expect(result.retryDelay).toBe(2);
      expect(result.statusCode).toBe(503);
    });
    
    it("should classify network failure errors", () => {
      const networkError = {
        code: "ECONNREFUSED",
        message: "Connection refused",
      };
      
      const result = classifyError(networkError);
      
      expect(result.type).toBe("networkFailure");
      expect(result.retryable).toBe(true);
      expect(result.retryDelay).toBe(1);
    });
    
    it("should classify invalid request errors (400)", () => {
      const invalidError = {
        status: 400,
        message: "Invalid request",
      };
      
      const result = classifyError(invalidError);
      
      expect(result.type).toBe("invalidRequest");
      expect(result.retryable).toBe(false);
      expect(result.retryDelay).toBe(0);
      expect(result.statusCode).toBe(400);
    });
    
    it("should classify quota exceeded errors (402)", () => {
      const quotaError = {
        status: 402,
        message: "Quota exceeded",
      };
      
      const result = classifyError(quotaError);
      
      expect(result.type).toBe("quotaExceeded");
      expect(result.retryable).toBe(false);
      expect(result.retryDelay).toBe(0);
      expect(result.statusCode).toBe(402);
    });
    
    it("should classify unknown errors", () => {
      const unknownError = {
        message: "Something went wrong",
      };
      
      const result = classifyError(unknownError);
      
      expect(result.type).toBe("unknown");
      expect(result.retryable).toBe(false);
      expect(result.retryDelay).toBe(0);
    });
  });
  
  describe("shouldRetry", () => {
    it("should return true for retryable errors under max attempts", () => {
      const error = {
        type: "timeout" as const,
        message: "Timeout",
        retryable: true,
        retryDelay: 1,
      };
      
      expect(shouldRetry(error, 0)).toBe(true);
      expect(shouldRetry(error, 1)).toBe(true);
      expect(shouldRetry(error, 2)).toBe(true);
      expect(shouldRetry(error, 3)).toBe(true);
    });
    
    it("should return false after max retry attempts (4)", () => {
      const error = {
        type: "timeout" as const,
        message: "Timeout",
        retryable: true,
        retryDelay: 1,
      };
      
      expect(shouldRetry(error, 4)).toBe(false);
      expect(shouldRetry(error, 5)).toBe(false);
    });
    
    it("should return false for non-retryable errors", () => {
      const error = {
        type: "invalidRequest" as const,
        message: "Invalid",
        retryable: false,
        retryDelay: 0,
      };
      
      expect(shouldRetry(error, 0)).toBe(false);
      expect(shouldRetry(error, 1)).toBe(false);
    });
  });
  
  describe("calculateRetryDelay", () => {
    it("should calculate exponential backoff correctly", () => {
      expect(calculateRetryDelay(1, 0)).toBe(1); // 1 * 2^0 = 1
      expect(calculateRetryDelay(1, 1)).toBe(2); // 1 * 2^1 = 2
      expect(calculateRetryDelay(1, 2)).toBe(4); // 1 * 2^2 = 4
      expect(calculateRetryDelay(1, 3)).toBe(8); // 1 * 2^3 = 8
    });
    
    it("should cap at 8 seconds maximum", () => {
      expect(calculateRetryDelay(1, 4)).toBe(8); // 1 * 2^4 = 16, capped at 8
      expect(calculateRetryDelay(2, 3)).toBe(8); // 2 * 2^3 = 16, capped at 8
    });
    
    it("should work with different initial delays", () => {
      expect(calculateRetryDelay(2, 0)).toBe(2); // 2 * 2^0 = 2
      expect(calculateRetryDelay(2, 1)).toBe(4); // 2 * 2^1 = 4
      expect(calculateRetryDelay(2, 2)).toBe(8); // 2 * 2^2 = 8, capped
    });
  });
  
  describe("hashForPrivacy", () => {
    it("should generate consistent hashes", () => {
      const input = "test@example.com";
      const hash1 = hashForPrivacy(input);
      const hash2 = hashForPrivacy(input);
      
      expect(hash1).toBe(hash2);
    });
    
    it("should generate different hashes for different inputs", () => {
      const hash1 = hashForPrivacy("user1@example.com");
      const hash2 = hashForPrivacy("user2@example.com");
      
      expect(hash1).not.toBe(hash2);
    });
    
    it("should return 16-character hash", () => {
      const hash = hashForPrivacy("test@example.com");
      
      expect(hash.length).toBe(16);
    });
    
    it("should be deterministic", () => {
      const input = "sensitive-query-text";
      const hashes = Array(10).fill(null).map(() => hashForPrivacy(input));
      
      expect(new Set(hashes).size).toBe(1); // All hashes identical
    });
  });
});


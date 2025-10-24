/**
 * Parameter Validation Utilities
 * Validates function call parameters before execution
 */

import { VALIDATION_RULES } from './schemas';

export interface ValidationResult {
  valid: boolean;
  errors: string[];
}

/**
 * Validate parameters for a specific function
 */
export function validateParameters(
  functionName: string,
  params: Record<string, any>
): ValidationResult {
  const rules = VALIDATION_RULES[functionName as keyof typeof VALIDATION_RULES];
  
  if (!rules) {
    return {
      valid: false,
      errors: [`Unknown function: ${functionName}`],
    };
  }

  const errors: string[] = [];

  // Validate each parameter according to rules
  for (const [paramName, rule] of Object.entries(rules)) {
    const value = params[paramName];
    const r = rule as any;

    // Check required parameters
    if (r.required && (value === undefined || value === null)) {
      errors.push(`Missing required parameter: ${paramName}`);
      continue;
    }

    // Skip optional parameters if not provided
    if (!r.required && (value === undefined || value === null)) {
      continue;
    }

    // Type validation
    if (r.type === 'string') {
      if (typeof value !== 'string') {
        errors.push(`${paramName} must be a string`);
        continue;
      }
      
      // String length validation
      if (r.minLength && value.length < r.minLength) {
        errors.push(`${paramName} must be at least ${r.minLength} characters`);
      }
      if (r.maxLength && value.length > r.maxLength) {
        errors.push(`${paramName} must be at most ${r.maxLength} characters`);
      }
      
      // Pattern validation
      if (r.pattern && !r.pattern.test(value)) {
        errors.push(`${paramName} has invalid format`);
      }
    } else if (r.type === 'number') {
      if (typeof value !== 'number' || isNaN(value)) {
        errors.push(`${paramName} must be a number`);
        continue;
      }
      
      // Numeric range validation
      if (r.min !== undefined && value < r.min) {
        errors.push(`${paramName} must be at least ${r.min}`);
      }
      if (r.max !== undefined && value > r.max) {
        errors.push(`${paramName} must be at most ${r.max}`);
      }
    } else if (r.type === 'array') {
      if (!Array.isArray(value)) {
        errors.push(`${paramName} must be an array`);
        continue;
      }
      
      // Array length validation
      if (r.minItems !== undefined && value.length < r.minItems) {
        errors.push(`${paramName} must have at least ${r.minItems} items`);
      }
      if (r.maxItems !== undefined && value.length > r.maxItems) {
        errors.push(`${paramName} must have at most ${r.maxItems} items`);
      }
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

/**
 * Validate a thread ID (Firebase document ID format)
 */
export function validateThreadId(id: string): boolean {
  if (!id || typeof id !== 'string') return false;
  // Firebase IDs can contain alphanumeric, hyphens, underscores
  return /^[a-zA-Z0-9_-]+$/.test(id) && id.length > 0 && id.length <= 1500;
}

/**
 * Validate a user ID (Firebase UID format)
 */
export function validateUserId(id: string): boolean {
  if (!id || typeof id !== 'string') return false;
  return /^[a-zA-Z0-9_-]+$/.test(id) && id.length > 0 && id.length <= 128;
}

/**
 * Validate a message ID (Firebase document ID format)
 */
export function validateMessageId(id: string): boolean {
  return validateThreadId(id); // Same format as thread ID
}

/**
 * Validate a date range
 */
export function validateDateRange(startDate: string, endDate: string): boolean {
  try {
    const start = new Date(startDate);
    const end = new Date(endDate);
    
    // Check if dates are valid
    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      return false;
    }
    
    // Check if end is after start
    if (end <= start) {
      return false;
    }
    
    // Check if range is reasonable (not more than 1 year)
    const maxRangeMs = 365 * 24 * 60 * 60 * 1000; // 1 year
    if (end.getTime() - start.getTime() > maxRangeMs) {
      return false;
    }
    
    return true;
  } catch {
    return false;
  }
}

/**
 * Validate a limit parameter
 */
export function validateLimit(limit: number, min: number, max: number): boolean {
  if (typeof limit !== 'number' || isNaN(limit)) return false;
  return limit >= min && limit <= max && Number.isInteger(limit);
}

/**
 * Validate an array parameter
 */
export function validateArray(
  arr: any[],
  minItems: number,
  maxItems: number
): boolean {
  if (!Array.isArray(arr)) return false;
  return arr.length >= minItems && arr.length <= maxItems;
}

/**
 * Validate ISO 8601 date format
 */
export function validateISO8601Date(dateString: string): boolean {
  if (!dateString || typeof dateString !== 'string') return false;
  
  // Basic ISO 8601 pattern check
  const iso8601Pattern = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z?$/;
  if (!iso8601Pattern.test(dateString)) return false;
  
  // Validate it's a real date
  const date = new Date(dateString);
  return !isNaN(date.getTime());
}

/**
 * Validate time range (HH:MM format)
 */
export function validateTimeRange(start: string, end: string): boolean {
  const timePattern = /^([0-1][0-9]|2[0-3]):([0-5][0-9])$/;
  
  if (!timePattern.test(start) || !timePattern.test(end)) {
    return false;
  }
  
  // Convert to minutes for comparison
  const [startHour, startMin] = start.split(':').map(Number);
  const [endHour, endMin] = end.split(':').map(Number);
  
  const startMinutes = startHour * 60 + startMin;
  const endMinutes = endHour * 60 + endMin;
  
  // End must be after start
  return endMinutes > startMinutes;
}

/**
 * Sanitize parameters to remove sensitive data before logging
 */
export function sanitizeParameters(
  params: Record<string, any>
): Record<string, any> {
  const sanitized: Record<string, any> = {};
  
  for (const [key, value] of Object.entries(params)) {
    // Remove message content, personal information
    if (key === 'text' || key === 'content' || key === 'message') {
      sanitized[key] = '[REDACTED]';
    } else if (typeof value === 'string' && value.length > 100) {
      // Truncate long strings
      sanitized[key] = `${value.substring(0, 100)}... (${value.length} chars)`;
    } else {
      sanitized[key] = value;
    }
  }
  
  return sanitized;
}


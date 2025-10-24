/**
 * Function Calling Schemas
 * OpenAI function calling definitions for all 8 core functions
 */

// ============================================================================
// TypeScript Types for Function Parameters & Results
// ============================================================================

// 1. Summarize Thread
export interface SummarizeThreadParams {
  threadId: string;
  maxLength?: number;
}

export interface ThreadSummary {
  summary: string;
  keyPoints: string[];
  participants: string[];
  decisionCount: number;
  messageCount: number;
}

// 2. Extract Action Items
export interface ExtractActionItemsParams {
  threadId: string;
  userId: string;
}

export interface ActionItem {
  id: string;
  task: string;
  deadline?: Date;
  assignee?: string;
  sourceMessageId: string;
  createdAt: Date;
}

// 3. Search Messages
export interface SearchMessagesParams {
  query: string;
  userId: string;
  chatId?: string;
  limit?: number;
}

export interface SearchResult {
  messageId: string;
  text: string;
  senderId: string;
  timestamp: Date;
  relevanceScore: number;
}

// 4. Categorize Message
export interface CategorizeMessageParams {
  messageId: string;
  userId: string;
}

export type CategoryType = 'urgent' | 'canWait' | 'aiHandled';

export interface MessageCategory {
  category: CategoryType;
  confidence: number;
  reasoning: string;
  signals: string[];
}

// 5. Track Decisions
export interface TrackDecisionsParams {
  threadId: string;
}

export interface Decision {
  id: string;
  decisionText: string;
  participants: string[];
  timestamp: Date;
  confidence: number;
}

// 6. Detect Scheduling Need
export interface DetectSchedulingNeedParams {
  threadId: string;
}

export interface SchedulingNeed {
  detected: boolean;
  participants: string[];
  suggestedDuration: number;
  urgency: 'high' | 'medium' | 'low';
}

// 7. Check Calendar
export interface CheckCalendarParams {
  userId: string;
  startDate: string; // ISO 8601
  endDate: string; // ISO 8601
}

export interface CalendarEvent {
  id: string;
  title: string;
  startTime: Date;
  endTime: Date;
}

// 8. Suggest Meeting Times
export interface SuggestMeetingTimesParams {
  participants: string[];
  duration: number; // minutes
  preferredTimeRanges?: TimeRange[];
}

export interface TimeRange {
  start: string; // HH:MM format
  end: string; // HH:MM format
}

export interface MeetingTimeSuggestion {
  id: string;
  startTime: Date;
  endTime: Date;
  availableParticipants: string[];
  score: number;
  reasoning: string;
}

// ============================================================================
// OpenAI Function Schemas (JSON Format)
// ============================================================================

export const FUNCTION_SCHEMAS = [
  {
    name: 'summarizeThread',
    description: 'Condense a conversation thread to 2-3 sentences with key points, participants, and decision count',
    parameters: {
      type: 'object',
      properties: {
        threadId: {
          type: 'string',
          description: 'The ID of the thread to summarize',
        },
        maxLength: {
          type: 'number',
          description: 'Maximum length of summary in characters (50-500)',
          minimum: 50,
          maximum: 500,
        },
      },
      required: ['threadId'],
    },
  },
  {
    name: 'extractActionItems',
    description: 'Find tasks requiring action from a conversation thread',
    parameters: {
      type: 'object',
      properties: {
        threadId: {
          type: 'string',
          description: 'The ID of the thread to extract action items from',
        },
        userId: {
          type: 'string',
          description: 'The user ID requesting action items',
        },
      },
      required: ['threadId', 'userId'],
    },
  },
  {
    name: 'searchMessages',
    description: 'Perform semantic search across messages to find relevant conversations',
    parameters: {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description: 'Natural language search query',
        },
        userId: {
          type: 'string',
          description: 'The user ID performing the search',
        },
        chatId: {
          type: 'string',
          description: 'Optional chat ID to limit search scope',
        },
        limit: {
          type: 'number',
          description: 'Maximum number of results to return (1-50)',
          minimum: 1,
          maximum: 50,
        },
      },
      required: ['query', 'userId'],
    },
  },
  {
    name: 'categorizeMessage',
    description: 'Detect priority level of a message (urgent, canWait, aiHandled)',
    parameters: {
      type: 'object',
      properties: {
        messageId: {
          type: 'string',
          description: 'The ID of the message to categorize',
        },
        userId: {
          type: 'string',
          description: 'The user ID requesting categorization',
        },
      },
      required: ['messageId', 'userId'],
    },
  },
  {
    name: 'trackDecisions',
    description: 'Find and log decision patterns in a conversation thread',
    parameters: {
      type: 'object',
      properties: {
        threadId: {
          type: 'string',
          description: 'The ID of the thread to track decisions in',
        },
      },
      required: ['threadId'],
    },
  },
  {
    name: 'detectSchedulingNeed',
    description: 'Identify meeting requests and scheduling needs in a thread',
    parameters: {
      type: 'object',
      properties: {
        threadId: {
          type: 'string',
          description: 'The ID of the thread to detect scheduling needs in',
        },
      },
      required: ['threadId'],
    },
  },
  {
    name: 'checkCalendar',
    description: 'Fetch calendar availability for a user within a date range',
    parameters: {
      type: 'object',
      properties: {
        userId: {
          type: 'string',
          description: 'The user ID to check calendar for',
        },
        startDate: {
          type: 'string',
          description: 'Start date in ISO 8601 format (e.g., 2024-01-01T00:00:00Z)',
        },
        endDate: {
          type: 'string',
          description: 'End date in ISO 8601 format (e.g., 2024-01-07T23:59:59Z)',
        },
      },
      required: ['userId', 'startDate', 'endDate'],
    },
  },
  {
    name: 'suggestMeetingTimes',
    description: 'Suggest optimal meeting times based on participant availability',
    parameters: {
      type: 'object',
      properties: {
        participants: {
          type: 'array',
          items: { type: 'string' },
          description: 'Array of user IDs who need to attend (2-10 participants)',
          minItems: 2,
          maxItems: 10,
        },
        duration: {
          type: 'number',
          description: 'Meeting duration in minutes (15-180)',
          minimum: 15,
          maximum: 180,
        },
        preferredTimeRanges: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              start: {
                type: 'string',
                description: 'Start time in HH:MM format (e.g., 09:00)',
              },
              end: {
                type: 'string',
                description: 'End time in HH:MM format (e.g., 17:00)',
              },
            },
            required: ['start', 'end'],
          },
          description: 'Preferred time ranges for the meeting (0-5 ranges)',
          maxItems: 5,
        },
      },
      required: ['participants', 'duration'],
    },
  },
];

// ============================================================================
// Validation Rules
// ============================================================================

export const VALIDATION_RULES = {
  summarizeThread: {
    threadId: { type: 'string', required: true, pattern: /^[a-zA-Z0-9_-]+$/ },
    maxLength: { type: 'number', min: 50, max: 500, required: false },
  },
  extractActionItems: {
    threadId: { type: 'string', required: true, pattern: /^[a-zA-Z0-9_-]+$/ },
    userId: { type: 'string', required: true, pattern: /^[a-zA-Z0-9_-]+$/ },
  },
  searchMessages: {
    query: { type: 'string', required: true, minLength: 3, maxLength: 500 },
    userId: { type: 'string', required: true, pattern: /^[a-zA-Z0-9_-]+$/ },
    chatId: { type: 'string', required: false, pattern: /^[a-zA-Z0-9_-]+$/ },
    limit: { type: 'number', min: 1, max: 50, required: false },
  },
  categorizeMessage: {
    messageId: { type: 'string', required: true, pattern: /^[a-zA-Z0-9_-]+$/ },
    userId: { type: 'string', required: true, pattern: /^[a-zA-Z0-9_-]+$/ },
  },
  trackDecisions: {
    threadId: { type: 'string', required: true, pattern: /^[a-zA-Z0-9_-]+$/ },
  },
  detectSchedulingNeed: {
    threadId: { type: 'string', required: true, pattern: /^[a-zA-Z0-9_-]+$/ },
  },
  checkCalendar: {
    userId: { type: 'string', required: true, pattern: /^[a-zA-Z0-9_-]+$/ },
    startDate: { type: 'string', required: true, pattern: /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/ },
    endDate: { type: 'string', required: true, pattern: /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/ },
  },
  suggestMeetingTimes: {
    participants: { type: 'array', required: true, minItems: 2, maxItems: 10 },
    duration: { type: 'number', min: 15, max: 180, required: true },
    preferredTimeRanges: { type: 'array', required: false, maxItems: 5 },
  },
};


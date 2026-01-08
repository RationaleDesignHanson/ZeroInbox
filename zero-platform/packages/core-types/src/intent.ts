import type { EmailContext, ThreadContext, TemporalContext, SenderMetadata } from './email';

export type UserSignalType =
  | 'swipe_start'
  | 'swipe_direction'
  | 'long_press'
  | 'scroll_velocity'
  | 'dwell_time'
  | 'tap_location';

export interface UserSignal {
  type: UserSignalType;
  timestamp: Date;
  metadata?: Record<string, unknown>;
}

export interface IntentClassificationInput {
  email: EmailContext;
  userSignals: UserSignal[];
  threadContext: ThreadContext;
  temporalContext: TemporalContext;
}

export type IntentType =
  | 'archive'
  | 'delete'
  | 'star'
  | 'unstar'
  | 'mark_read'
  | 'mark_unread'
  | 'snooze'
  | 'move_to_folder'
  | 'reply'
  | 'reply_all'
  | 'forward'
  | 'quick_reply'
  | 'schedule_send'
  | 'label'
  | 'create_task'
  | 'create_event'
  | 'add_contact'
  | 'select_similar'
  | 'unsubscribe'
  | 'block_sender'
  | 'report_spam'
  | 'none'
  | 'needs_more_context';

export interface Intent {
  type: IntentType;
  confidence: number;
  triggers: string[];
}

export interface IntentReasoning {
  primaryFactors: string[];
  negativeFactors: string[];
  confidenceExplanation: string;
}

export interface IntentClassificationResult {
  primaryIntent: Intent;
  secondaryIntents: Intent[];
  confidence: number;
  reasoning: IntentReasoning;
  processingTimeMs: number;
}

export interface CalibrationContext {
  senderMetadata: SenderMetadata;
  threadLength: number;
  matchesUserPattern: boolean;
}



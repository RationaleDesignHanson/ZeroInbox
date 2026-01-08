export interface EmailAddress {
  email: string;
  name?: string;
}

export type SenderCategory =
  | 'personal'
  | 'work_internal'
  | 'work_external'
  | 'newsletter'
  | 'transactional'
  | 'marketing'
  | 'social'
  | 'unknown';

export interface SenderMetadata {
  domain: string;
  isContact: boolean;
  previousInteractionCount: number;
  lastInteractionDate?: Date;
  senderCategory: SenderCategory;
  isVIP: boolean;
}

export interface ThreadContext {
  participants: EmailAddress[];
  hasUserReplied: boolean;
  lastUserReplyDate?: Date;
  urgencyIndicators: string[];
  questionCount: number;
  actionItemCount: number;
}

export interface TemporalContext {
  currentTime: Date;
  userTimezone: string;
  isWorkHours: boolean;
  dayOfWeek: number;
  emailAge: number; // Minutes since received
}

export interface EmailContext {
  id: string;
  from: EmailAddress;
  to: EmailAddress[];
  cc: EmailAddress[];
  subject: string;
  bodyPreview: string; // First 500 chars
  bodyFull?: string; // Full body if needed
  hasAttachments: boolean;
  attachmentTypes?: string[];
  receivedAt: Date;
  threadId: string;
  threadPosition: number; // 1 = first in thread
  threadLength: number;
  labels: string[];
  isRead: boolean;
  isStarred: boolean;
  senderMetadata: SenderMetadata;
}

export type EmailType = 'mail' | 'ads';



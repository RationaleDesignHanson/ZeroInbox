/**
 * @zero/types - Shared type definitions
 */

export type Priority = 'critical' | 'high' | 'medium' | 'low';

export type EmailType = 'mail' | 'ads';

export interface SenderInfo {
  name: string;
  email: string;
  initial?: string;
  domain?: string;
  avatarUrl?: string;
}

export interface SuggestedAction {
  id: string;
  type: string;
  displayName: string;
  icon?: string;
  isPrimary?: boolean;
  requiresConfirmation?: boolean;
  parameters?: Record<string, unknown>;
}

export interface EmailCard {
  id: string;
  type: EmailType;
  title: string;
  summary: string;
  sender?: SenderInfo;
  timeAgo: string;
  priority: Priority;
  intent?: string;
  intentConfidence?: number;
  hpa?: string; // High Priority Action
  suggestedActions?: SuggestedAction[];
  context?: Record<string, unknown>;
  aiGeneratedSummary?: string;
  isVIP?: boolean;
  hasAttachments?: boolean;
  isNewsletter?: boolean;
  threadCount?: number;
  labels?: string[];
  rawHtml?: string;
}

export interface ActionConfig {
  id: string;
  type: string;
  displayName: string;
  description?: string;
  icon?: string;
  modes?: EmailType[];
  fields?: ActionField[];
  requiresConfirmation?: boolean;
}

export interface ActionField {
  name: string;
  type: 'text' | 'textarea' | 'select' | 'date' | 'time' | 'number' | 'toggle';
  label: string;
  placeholder?: string;
  required?: boolean;
  options?: { value: string; label: string }[];
  defaultValue?: unknown;
}

export interface ActionResult {
  success: boolean;
  message?: string;
  undoAction?: () => Promise<void>;
}

export interface Toast {
  id: string;
  message: string;
  type: 'success' | 'error' | 'info' | 'warning';
  duration?: number;
  undoAction?: () => Promise<void>;
}


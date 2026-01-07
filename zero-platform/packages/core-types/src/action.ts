import type { EmailContext, EmailAddress } from './email';
import type { IntentClassificationResult } from './intent';

export type ActionType =
  | 'archive'
  | 'delete'
  | 'snooze'
  | 'move_to_folder'
  | 'label'
  | 'reply'
  | 'reply_all'
  | 'forward'
  | 'create_task'
  | 'create_event';

export interface UserPreferences {
  defaultSnoozeTime: number; // minutes
  archiveOrDelete: 'archive' | 'delete';
  confirmDestructive: boolean;
  quickReplyTemplates: QuickReplyTemplate[];
  folderMappings: FolderMapping[];
  autoLabels: AutoLabelRule[];
}

export interface QuickReplyTemplate {
  id: string;
  text: string;
  tone: 'formal' | 'casual' | 'brief';
}

export interface FolderMapping {
  label: string;
  folderId: string;
}

export interface AutoLabelRule {
  label: string;
  matchers: string[];
}

export interface ActionCapability {
  type: ActionType;
  enabled: boolean;
  requiresConfirmation: boolean;
  undoWindowSeconds: number;
}

export interface ActionResolutionInput {
  intent: IntentClassificationResult;
  email: EmailContext;
  userPreferences: UserPreferences;
  availableActions: ActionCapability[];
}

export interface SnoozePreset {
  label: string;
  datetime: Date;
  isDefault: boolean;
}

export interface SnoozeParams {
  type: 'snooze';
  snoozeUntil: Date;
  snoozePresets: SnoozePreset[];
}

export interface ReplyParams {
  type: 'reply' | 'reply_all' | 'forward';
  suggestedResponses?: string[];
  replyTo: EmailAddress[];
  ccSuggestions?: EmailAddress[];
  subjectPrefix: string;
  quotedContent: boolean;
}

export interface MoveParams {
  type: 'move_to_folder';
  folderId: string;
}

export interface LabelParams {
  type: 'label';
  labels: string[];
}

export interface TaskParams {
  type: 'create_task';
  dueDate?: Date;
  priority?: 'low' | 'medium' | 'high';
}

export interface EventParams {
  type: 'create_event';
  start: Date;
  end: Date;
  location?: string;
}

export type ActionParameters =
  | SnoozeParams
  | MoveParams
  | LabelParams
  | ReplyParams
  | TaskParams
  | EventParams
  | { type: 'archive' }
  | { type: 'delete' };

export interface QuickReplyOption {
  id: string;
  text: string;
  tone: 'formal' | 'casual' | 'brief';
  confidence: number;
}

export interface ResolvedAction {
  id: string;
  type: ActionType;
  label: string;
  icon: string;
  confidence: number;
  parameters: ActionParameters;
  requiresConfirmation: boolean;
  undoable: boolean;
  undoWindowSeconds: number;
}

export interface ActionResolutionResult {
  primaryAction: ResolvedAction;
  alternativeActions: ResolvedAction[];
  quickReplyOptions?: QuickReplyOption[];
}


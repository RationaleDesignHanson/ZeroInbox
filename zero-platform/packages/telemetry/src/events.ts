import type { ActionType, IntentType, ConfidenceBucket } from '@zero/core-types';

export interface ActionModalShownEvent {
  eventType: 'action_modal_shown';
  timestamp: Date;
  sessionId: string;
  userId: string;
  deviceType: 'ios' | 'web' | 'watch';
  appVersion: string;
  emailContext: {
    emailId: string;
    threadId: string;
    threadPosition: number;
    threadLength: number;
    senderDomain: string;
    senderCategory: string;
    isContact: boolean;
    hasAttachments: boolean;
    attachmentCount: number;
    emailAgeMinutes: number;
  };
  modalContent: {
    primaryAction: ActionType;
    primaryConfidence: number;
    alternativeActions: ActionType[];
    alternativeConfidences: number[];
    modalVariant: 'single' | 'dual' | 'grid';
  };
  classification: {
    intentType: IntentType;
    intentConfidence: number;
    confidenceBucket: ConfidenceBucket;
    processingTimeMs: number;
  };
}

export interface ActionTakenEvent {
  eventType: 'action_taken';
  timestamp: Date;
  modalEventId: string;
  actionTaken: ActionType | 'dismissed' | 'custom';
  wasOverride: boolean;
  actionPosition: number;
  timeToActionMs: number;
}

export interface ActionUndoneEvent {
  eventType: 'action_undone';
  timestamp: Date;
  actionEventId: string;
  timeToUndoMs: number;
}

export type TelemetryEvent = ActionModalShownEvent | ActionTakenEvent | ActionUndoneEvent;


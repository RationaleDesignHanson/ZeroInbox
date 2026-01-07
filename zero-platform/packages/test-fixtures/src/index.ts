import type { EmailContext, IntentType, ActionType } from '@zero/core-types';

export type FixtureCategory =
  | 'newsletter'
  | 'transactional'
  | 'personal'
  | 'work_internal'
  | 'work_external'
  | 'calendar'
  | 'social'
  | 'marketing'
  | 'thread'
  | 'attachment'
  | 'urgent';

export interface EmailFixture {
  id: string;
  name: string;
  description: string;
  category: FixtureCategory;
  email: EmailContext;
  expectedIntent: IntentType;
  expectedConfidenceRange: [number, number];
  expectedAction: ActionType;
  isEdgeCase: boolean;
  tags: string[];
  createdAt: Date;
  lastUpdated: Date;
}

export const basicFixtures: EmailFixture[] = [
  {
    id: 'newsletter-001',
    name: 'Standard marketing newsletter',
    description: 'Typical newsletter should archive with high confidence',
    category: 'newsletter',
    email: {
      id: 'newsletter-001',
      from: { email: 'news@brand.com', name: 'Brand Newsletter' },
      to: [{ email: 'user@example.com', name: 'Test User' }],
      cc: [],
      subject: 'This Week in Tech: 5 Stories You Missed',
      bodyPreview: 'View in browser | Unsubscribe',
      hasAttachments: false,
      receivedAt: new Date(),
      threadId: 'thread-001',
      threadPosition: 1,
      threadLength: 1,
      labels: [],
      isRead: false,
      isStarred: false,
      senderMetadata: {
        domain: 'brand.com',
        isContact: false,
        previousInteractionCount: 12,
        lastInteractionDate: new Date(),
        senderCategory: 'newsletter',
        isVIP: false,
      },
    },
    expectedIntent: 'archive',
    expectedConfidenceRange: [0.7, 1],
    expectedAction: 'archive',
    isEdgeCase: false,
    tags: ['newsletter', 'archive'],
    createdAt: new Date(),
    lastUpdated: new Date(),
  },
  {
    id: 'security-001',
    name: 'Two-factor code',
    description: 'Security code should be marked read and shown prominently',
    category: 'urgent',
    email: {
      id: 'security-001',
      from: { email: 'no-reply@email.apple.com', name: 'Apple' },
      to: [{ email: 'user@example.com', name: 'Test User' }],
      cc: [],
      subject: 'Your verification code is 123456',
      bodyPreview: 'Your Apple ID verification code is 123456.',
      hasAttachments: false,
      receivedAt: new Date(),
      threadId: 'thread-002',
      threadPosition: 1,
      threadLength: 1,
      labels: [],
      isRead: false,
      isStarred: false,
      senderMetadata: {
        domain: 'apple.com',
        isContact: true,
        previousInteractionCount: 5,
        lastInteractionDate: new Date(),
        senderCategory: 'transactional',
        isVIP: false,
      },
    },
    expectedIntent: 'mark_read',
    expectedConfidenceRange: [0.7, 1],
    expectedAction: 'archive',
    isEdgeCase: false,
    tags: ['security', '2fa'],
    createdAt: new Date(),
    lastUpdated: new Date(),
  },
];

export function loadFixtures(): EmailFixture[] {
  return basicFixtures;
}


# Zero Platform Strategy
## Cross-Platform Architecture, Testing Infrastructure, and Wearable Expansion

**Document Version:** 1.0  
**Date:** January 2026  
**Author:** Rationale Studio

---

## Executive Summary

This document provides a comprehensive technical roadmap for evolving Zero from an iOS-first email client into a cross-platform system with wearable support. The strategy is built around four interdependent workstreams, ordered by dependency:

1. **Shared Core Extraction** — Extract platform-agnostic business logic into TypeScript
2. **Test Harness Architecture** — Validate intent classification and action reliability
3. **Telemetry Schema** — Instrument production for continuous improvement
4. **WatchOS Architecture** — Extend to Apple Watch as first wearable surface

Each section includes implementation details, code examples, and acceptance criteria.

---

## Table of Contents

1. [Shared Core Extraction Plan](#1-shared-core-extraction-plan)
2. [Test Harness Architecture](#2-test-harness-architecture)
3. [Telemetry Schema for Action Tracking](#3-telemetry-schema-for-action-tracking)
4. [WatchOS App Architecture](#4-watchos-app-architecture)
5. [Ship Readiness Criteria](#5-ship-readiness-criteria)
6. [Appendix: Agent Workflow Specifications](#appendix-agent-workflow-specifications)

---

# 1. Shared Core Extraction Plan

## 1.1 Why Shared Core First

Every downstream deliverable depends on having a clean, testable, platform-agnostic core:

```
┌─────────────────────────────────────────────────────────────────┐
│                     DEPENDENCY GRAPH                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                    ┌──────────────────┐                         │
│                    │   SHARED CORE    │                         │
│                    │   (TypeScript)   │                         │
│                    └────────┬─────────┘                         │
│                             │                                   │
│           ┌─────────────────┼─────────────────┐                 │
│           │                 │                 │                 │
│           ▼                 ▼                 ▼                 │
│    ┌─────────────┐   ┌─────────────┐   ┌─────────────┐         │
│    │ Test Harness│   │  Telemetry  │   │  WatchOS    │         │
│    │             │   │   Schema    │   │    App      │         │
│    └─────────────┘   └─────────────┘   └─────────────┘         │
│           │                 │                 │                 │
│           └─────────────────┼─────────────────┘                 │
│                             ▼                                   │
│                    ┌──────────────────┐                         │
│                    │  Ship Readiness  │                         │
│                    └──────────────────┘                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 1.2 Core Modules to Extract

### Module Inventory

| Module | Current Location | Extraction Priority | Complexity |
|--------|------------------|---------------------|------------|
| Intent Engine | iOS/Services/IntentClassifier | P0 - Critical | High |
| Action Resolver | iOS/Services/ActionResolver | P0 - Critical | High |
| Confidence Scorer | iOS/Services/ConfidenceEngine | P0 - Critical | Medium |
| Email Parser | iOS/Models/EmailParser | P1 - High | Medium |
| User Preferences | iOS/Services/PreferenceManager | P1 - High | Low |
| Sync Logic | iOS/Services/SyncManager | P2 - Medium | High |
| Reply Generator | iOS/Services/AIReply | P2 - Medium | Medium |

### Module Specifications

#### 1.2.1 Intent Engine

**Purpose:** Classify user intent from email context and interaction signals

**Input Interface:**
```typescript
interface IntentClassificationInput {
  email: EmailContext;
  userSignals: UserSignal[];
  threadContext: ThreadContext;
  temporalContext: TemporalContext;
}

interface EmailContext {
  id: string;
  from: EmailAddress;
  to: EmailAddress[];
  cc: EmailAddress[];
  subject: string;
  bodyPreview: string;        // First 500 chars
  bodyFull?: string;          // Full body if needed
  hasAttachments: boolean;
  attachmentTypes?: string[];
  receivedAt: Date;
  threadId: string;
  threadPosition: number;     // 1 = first in thread
  threadLength: number;
  labels: string[];
  isRead: boolean;
  isStarred: boolean;
  senderMetadata: SenderMetadata;
}

interface SenderMetadata {
  domain: string;
  isContact: boolean;
  previousInteractionCount: number;
  lastInteractionDate?: Date;
  senderCategory: SenderCategory;
  isVIP: boolean;
}

type SenderCategory = 
  | 'personal'
  | 'work_internal'
  | 'work_external'
  | 'newsletter'
  | 'transactional'
  | 'marketing'
  | 'social'
  | 'unknown';

interface UserSignal {
  type: UserSignalType;
  timestamp: Date;
  metadata?: Record<string, unknown>;
}

type UserSignalType =
  | 'swipe_start'
  | 'swipe_direction'
  | 'long_press'
  | 'scroll_velocity'
  | 'dwell_time'
  | 'tap_location';

interface ThreadContext {
  participants: EmailAddress[];
  hasUserReplied: boolean;
  lastUserReplyDate?: Date;
  urgencyIndicators: string[];
  questionCount: number;
  actionItemCount: number;
}

interface TemporalContext {
  currentTime: Date;
  userTimezone: string;
  isWorkHours: boolean;
  dayOfWeek: number;
  emailAge: number;          // Minutes since received
}
```

**Output Interface:**
```typescript
interface IntentClassificationResult {
  primaryIntent: Intent;
  secondaryIntents: Intent[];
  confidence: number;         // 0-1
  reasoning: IntentReasoning;
  processingTimeMs: number;
}

interface Intent {
  type: IntentType;
  confidence: number;
  triggers: string[];         // What signals led to this
}

type IntentType =
  // Primary Actions
  | 'archive'
  | 'delete'
  | 'star'
  | 'unstar'
  | 'mark_read'
  | 'mark_unread'
  | 'snooze'
  | 'move_to_folder'
  
  // Reply Actions
  | 'reply'
  | 'reply_all'
  | 'forward'
  | 'quick_reply'
  | 'schedule_send'
  
  // Organizational Actions
  | 'label'
  | 'create_task'
  | 'create_event'
  | 'add_contact'
  
  // Bulk Actions
  | 'select_similar'
  | 'unsubscribe'
  | 'block_sender'
  | 'report_spam'
  
  // No Action
  | 'none'
  | 'needs_more_context';

interface IntentReasoning {
  primaryFactors: string[];
  negativeFactors: string[];
  confidenceExplanation: string;
}
```

**Core Logic (Pseudocode):**
```typescript
export class IntentEngine {
  private rules: IntentRule[];
  private mlModel?: IntentMLModel;
  private userPatterns: UserPatternStore;

  async classifyIntent(input: IntentClassificationInput): Promise<IntentClassificationResult> {
    const startTime = performance.now();
    
    // Phase 1: Rule-based classification
    const ruleResults = this.applyRules(input);
    
    // Phase 2: ML-based classification (if available)
    const mlResults = this.mlModel 
      ? await this.mlModel.predict(input)
      : null;
    
    // Phase 3: User pattern matching
    const patternResults = this.matchUserPatterns(input);
    
    // Phase 4: Ensemble scoring
    const ensembleResult = this.ensembleScore(
      ruleResults,
      mlResults,
      patternResults
    );
    
    // Phase 5: Confidence calibration
    const calibratedResult = this.calibrateConfidence(ensembleResult);
    
    return {
      ...calibratedResult,
      processingTimeMs: performance.now() - startTime
    };
  }

  private applyRules(input: IntentClassificationInput): RuleResult[] {
    return this.rules
      .map(rule => rule.evaluate(input))
      .filter(result => result.confidence > 0.1)
      .sort((a, b) => b.confidence - a.confidence);
  }

  private ensembleScore(
    rules: RuleResult[],
    ml: MLResult | null,
    patterns: PatternResult[]
  ): IntentClassificationResult {
    // Weighted combination
    // Rules: 40% weight (reliable, interpretable)
    // ML: 35% weight (captures nuance)
    // Patterns: 25% weight (personalization)
    
    const weights = { rules: 0.4, ml: 0.35, patterns: 0.25 };
    
    // Implementation details...
  }
}
```

#### 1.2.2 Action Resolver

**Purpose:** Map classified intents to concrete actions with parameters

**Input Interface:**
```typescript
interface ActionResolutionInput {
  intent: IntentClassificationResult;
  email: EmailContext;
  userPreferences: UserPreferences;
  availableActions: ActionCapability[];
}

interface UserPreferences {
  defaultSnoozeTime: number;      // minutes
  archiveOrDelete: 'archive' | 'delete';
  confirmDestructive: boolean;
  quickReplyTemplates: QuickReplyTemplate[];
  folderMappings: FolderMapping[];
  autoLabels: AutoLabelRule[];
}

interface ActionCapability {
  type: ActionType;
  enabled: boolean;
  requiresConfirmation: boolean;
  undoWindowSeconds: number;
}
```

**Output Interface:**
```typescript
interface ActionResolutionResult {
  primaryAction: ResolvedAction;
  alternativeActions: ResolvedAction[];
  quickReplyOptions?: QuickReplyOption[];
}

interface ResolvedAction {
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

type ActionParameters = 
  | ArchiveParams
  | DeleteParams
  | SnoozeParams
  | MoveParams
  | LabelParams
  | ReplyParams
  | ForwardParams
  | TaskParams
  | EventParams;

interface SnoozeParams {
  type: 'snooze';
  snoozeUntil: Date;
  snoozePresets: SnoozePreset[];
}

interface SnoozePreset {
  label: string;
  datetime: Date;
  isDefault: boolean;
}

interface ReplyParams {
  type: 'reply' | 'reply_all' | 'forward';
  suggestedResponses?: string[];
  replyTo: EmailAddress[];
  ccSuggestions?: EmailAddress[];
  subjectPrefix: string;
  quotedContent: boolean;
}

interface QuickReplyOption {
  id: string;
  text: string;
  tone: 'formal' | 'casual' | 'brief';
  confidence: number;
}
```

#### 1.2.3 Confidence Scorer

**Purpose:** Calibrate confidence scores to match actual accuracy

**Interface:**
```typescript
interface ConfidenceCalibration {
  rawScore: number;
  calibratedScore: number;
  bucket: ConfidenceBucket;
  shouldShowAlternatives: boolean;
  uncertaintyReason?: string;
}

type ConfidenceBucket = 
  | 'very_high'    // >0.95 - Show single action, no alternatives
  | 'high'         // 0.85-0.95 - Show primary + 1 alternative
  | 'medium'       // 0.70-0.85 - Show primary + 2 alternatives
  | 'low'          // 0.50-0.70 - Show grid of options
  | 'uncertain';   // <0.50 - Show full action menu

export class ConfidenceScorer {
  private calibrationCurve: CalibrationCurve;
  private recentAccuracy: RollingAccuracy;

  calibrate(rawScore: number, context: CalibrationContext): ConfidenceCalibration {
    // Apply Platt scaling or isotonic regression
    const calibrated = this.calibrationCurve.transform(rawScore);
    
    // Adjust for context-specific factors
    const adjusted = this.applyContextAdjustments(calibrated, context);
    
    // Determine UI behavior
    const bucket = this.determineBucket(adjusted);
    
    return {
      rawScore,
      calibratedScore: adjusted,
      bucket,
      shouldShowAlternatives: bucket !== 'very_high',
      uncertaintyReason: this.explainUncertainty(rawScore, adjusted, context)
    };
  }

  private applyContextAdjustments(
    score: number, 
    context: CalibrationContext
  ): number {
    let adjusted = score;
    
    // Reduce confidence for new senders
    if (!context.senderMetadata.isContact) {
      adjusted *= 0.9;
    }
    
    // Reduce confidence for long threads (more complex)
    if (context.threadLength > 10) {
      adjusted *= 0.85;
    }
    
    // Boost confidence for user's established patterns
    if (context.matchesUserPattern) {
      adjusted = Math.min(1, adjusted * 1.1);
    }
    
    return adjusted;
  }
}
```

## 1.3 Extraction Process

### Phase 1: Interface Definition (Week 1)

1. **Document current Swift interfaces** — Map every public method in the iOS implementation
2. **Design TypeScript interfaces** — Create the canonical interfaces (as shown above)
3. **Define test contracts** — What must pass for extraction to be complete
4. **Review with team** — Ensure interfaces cover all use cases

**Deliverable:** `@zero/core-types` package with all interface definitions

### Phase 2: Parallel Implementation (Weeks 2-4)

```
┌─────────────────────────────────────────────────────────────────┐
│                    EXTRACTION APPROACH                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────┐        ┌─────────────────┐               │
│   │   iOS (Swift)   │        │   TypeScript    │               │
│   │   Current Impl  │        │   New Core      │               │
│   └────────┬────────┘        └────────┬────────┘               │
│            │                          │                         │
│            │    ┌──────────────┐      │                         │
│            └───►│  Test Suite  │◄─────┘                         │
│                 │  (Shared)    │                                │
│                 └──────────────┘                                │
│                                                                 │
│   Both implementations must pass identical test suite           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Strategy:** Write TypeScript implementation alongside Swift. Both must pass the same test fixtures. When parity is achieved, TypeScript becomes source of truth.

### Phase 3: Integration (Weeks 5-6)

1. **iOS Integration** — Swift wrapper calls TypeScript core via JavaScriptCore or embedded runtime
2. **Web Integration** — Direct consumption of TypeScript modules
3. **Performance Validation** — Ensure no regression from bridging overhead

**iOS Bridge Pattern:**
```swift
// Swift wrapper around TypeScript core
class IntentEngineWrapper {
    private let jsContext: JSContext
    private let intentEngine: JSValue
    
    init() throws {
        jsContext = JSContext()
        
        // Load bundled core
        guard let corePath = Bundle.main.path(forResource: "zero-core", ofType: "js"),
              let coreCode = try? String(contentsOfFile: corePath) else {
            throw CoreError.bundleNotFound
        }
        
        jsContext.evaluateScript(coreCode)
        intentEngine = jsContext.objectForKeyedSubscript("IntentEngine")
    }
    
    func classifyIntent(_ input: IntentClassificationInput) async throws -> IntentClassificationResult {
        let inputJSON = try JSONEncoder().encode(input)
        let inputString = String(data: inputJSON, encoding: .utf8)!
        
        let resultValue = intentEngine.invokeMethod("classifyIntent", withArguments: [inputString])
        
        // Parse result back to Swift
        guard let resultString = resultValue?.toString(),
              let resultData = resultString.data(using: .utf8) else {
            throw CoreError.invalidResult
        }
        
        return try JSONDecoder().decode(IntentClassificationResult.self, from: resultData)
    }
}
```

## 1.4 Package Structure

```
packages/
├── @zero/core-types/           # Shared type definitions
│   ├── src/
│   │   ├── email.ts            # Email-related types
│   │   ├── intent.ts           # Intent classification types
│   │   ├── action.ts           # Action resolution types
│   │   ├── confidence.ts       # Confidence scoring types
│   │   └── index.ts
│   └── package.json
│
├── @zero/intent-engine/        # Intent classification
│   ├── src/
│   │   ├── engine.ts           # Main IntentEngine class
│   │   ├── rules/              # Rule-based classifiers
│   │   │   ├── sender-rules.ts
│   │   │   ├── content-rules.ts
│   │   │   ├── temporal-rules.ts
│   │   │   └── thread-rules.ts
│   │   ├── ml/                 # ML-based classifiers
│   │   │   ├── model.ts
│   │   │   └── features.ts
│   │   └── patterns/           # User pattern matching
│   │       ├── store.ts
│   │       └── matcher.ts
│   ├── __tests__/
│   └── package.json
│
├── @zero/action-resolver/      # Action resolution
│   ├── src/
│   │   ├── resolver.ts
│   │   ├── parameters/
│   │   └── templates/
│   ├── __tests__/
│   └── package.json
│
├── @zero/confidence/           # Confidence calibration
│   ├── src/
│   │   ├── scorer.ts
│   │   ├── calibration.ts
│   │   └── buckets.ts
│   ├── __tests__/
│   └── package.json
│
└── @zero/core/                 # Unified export
    ├── src/
    │   └── index.ts            # Re-exports all modules
    └── package.json
```

## 1.5 Extraction Acceptance Criteria

| Criterion | Measurement | Target |
|-----------|-------------|--------|
| Interface Parity | All iOS public methods have TS equivalents | 100% |
| Test Parity | Same test fixtures pass on both | 100% |
| Performance | TS classification latency | <50ms p99 |
| Bundle Size | Core bundle for iOS embedding | <500KB |
| Type Coverage | TypeScript strict mode | 100% |

---

# 2. Test Harness Architecture

## 2.1 Testing Philosophy

Zero's test strategy must cover three layers:

```
┌─────────────────────────────────────────────────────────────────┐
│                     TEST PYRAMID                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                        ┌─────┐                                  │
│                       /  E2E  \          10% - Critical paths   │
│                      /─────────\                                │
│                     / Integration\       30% - Module combos    │
│                    /───────────────\                            │
│                   /      Unit       \    60% - Core logic       │
│                  /───────────────────\                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

For the action system specifically:

| Layer | What We Test | Example |
|-------|--------------|---------|
| Unit | Individual rules, single classifier | "Newsletter rule triggers on marketing@ sender" |
| Integration | Intent → Action resolution chain | "Newsletter email → Archive action with 0.85 confidence" |
| E2E | Full swipe → action → undo flow | "User swipes right, sees archive, taps, email archives, undo works" |

## 2.2 Test Fixture Schema

### 2.2.1 Email Fixtures

```typescript
// packages/@zero/test-fixtures/src/emails.ts

interface EmailFixture {
  id: string;
  name: string;                    // Human-readable test name
  description: string;             // What this tests
  category: FixtureCategory;
  
  // The email data
  email: EmailContext;
  
  // Expected outcomes
  expectedIntent: IntentType;
  expectedConfidenceRange: [number, number];  // [min, max]
  expectedAction: ActionType;
  
  // Edge case flags
  isEdgeCase: boolean;
  edgeCaseType?: EdgeCaseType;
  
  // Metadata
  tags: string[];
  createdAt: Date;
  lastUpdated: Date;
}

type FixtureCategory =
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

type EdgeCaseType =
  | 'ambiguous_sender'
  | 'mixed_signals'
  | 'new_sender'
  | 'long_thread'
  | 'empty_body'
  | 'foreign_language'
  | 'conflicting_urgency'
  | 'reply_vs_archive';
```

### 2.2.2 Fixture Examples

```typescript
// packages/@zero/test-fixtures/src/fixtures/newsletters.ts

export const newsletterFixtures: EmailFixture[] = [
  {
    id: 'newsletter-001',
    name: 'Standard marketing newsletter',
    description: 'Typical newsletter from a brand, should archive with high confidence',
    category: 'newsletter',
    
    email: {
      id: 'test-email-001',
      from: { email: 'news@brand.com', name: 'Brand Newsletter' },
      to: [{ email: 'user@example.com', name: 'Test User' }],
      cc: [],
      subject: 'This Week in Tech: 5 Stories You Missed',
      bodyPreview: 'View in browser | Unsubscribe\n\nHey there!\n\nHere are this week\'s top stories...',
      hasAttachments: false,
      receivedAt: new Date('2026-01-03T09:00:00Z'),
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
        lastInteractionDate: new Date('2025-12-27T09:00:00Z'),
        senderCategory: 'newsletter',
        isVIP: false
      }
    },
    
    expectedIntent: 'archive',
    expectedConfidenceRange: [0.85, 0.98],
    expectedAction: 'archive',
    
    isEdgeCase: false,
    tags: ['newsletter', 'archive', 'high-confidence'],
    createdAt: new Date('2026-01-03'),
    lastUpdated: new Date('2026-01-03')
  },
  
  {
    id: 'newsletter-002',
    name: 'Newsletter with action item',
    description: 'Newsletter that contains a request requiring response - should NOT auto-archive',
    category: 'newsletter',
    
    email: {
      id: 'test-email-002',
      from: { email: 'team@company.com', name: 'Company Updates' },
      to: [{ email: 'user@example.com', name: 'Test User' }],
      cc: [],
      subject: 'Action Required: Update your preferences by Friday',
      bodyPreview: 'Hi team,\n\nWe need everyone to update their project preferences by this Friday. Please click the link below to complete the form...',
      hasAttachments: false,
      receivedAt: new Date('2026-01-03T10:00:00Z'),
      threadId: 'thread-002',
      threadPosition: 1,
      threadLength: 1,
      labels: [],
      isRead: false,
      isStarred: false,
      senderMetadata: {
        domain: 'company.com',
        isContact: true,
        previousInteractionCount: 45,
        lastInteractionDate: new Date('2026-01-02T14:00:00Z'),
        senderCategory: 'work_internal',
        isVIP: false
      }
    },
    
    expectedIntent: 'star',           // or create_task
    expectedConfidenceRange: [0.60, 0.85],  // Lower confidence due to ambiguity
    expectedAction: 'star',
    
    isEdgeCase: true,
    edgeCaseType: 'mixed_signals',
    tags: ['newsletter', 'action-required', 'edge-case', 'medium-confidence'],
    createdAt: new Date('2026-01-03'),
    lastUpdated: new Date('2026-01-03')
  }
];
```

### 2.2.3 Edge Case Matrix

```typescript
// packages/@zero/test-fixtures/src/edge-cases.ts

/**
 * Edge cases that must all pass before shipping.
 * Each represents a scenario where naive classification would fail.
 */
export const edgeCaseMatrix: EdgeCaseFixture[] = [
  // Reply vs Archive Tension
  {
    id: 'edge-reply-vs-archive-001',
    scenario: 'Email from known sender with question mark but user never replies to them',
    signals: {
      hasQuestion: true,
      senderReplyRate: 0.0,        // User never replies to this sender
      senderCategory: 'newsletter'
    },
    expectedIntent: 'archive',     // Pattern wins over content
    expectedConfidence: 0.75,
    reasoning: 'User pattern of never replying to this sender should override question content'
  },
  
  // Urgency Conflicts
  {
    id: 'edge-urgency-conflict-001',
    scenario: 'Subject says URGENT but sender always marks things urgent',
    signals: {
      subjectContainsUrgent: true,
      senderUrgencyRate: 0.95,     // This sender marks 95% of emails urgent
      actualUrgentRate: 0.05       // But only 5% actually are
    },
    expectedIntent: 'archive',
    expectedConfidence: 0.70,
    reasoning: 'Sender has cried wolf too many times'
  },
  
  // Thread Position Matters
  {
    id: 'edge-thread-position-001',
    scenario: 'User is mentioned in CC on reply-all thread, thread is 20 messages deep',
    signals: {
      threadPosition: 20,
      userInCC: true,
      userPreviouslyInThread: false,
      threadHasResolution: true    // Thread appears concluded
    },
    expectedIntent: 'archive',
    expectedConfidence: 0.80,
    reasoning: 'Late CC addition to concluded thread rarely needs action'
  },
  
  // Time Sensitivity
  {
    id: 'edge-time-sensitive-001',
    scenario: 'Event reminder for event that already happened',
    signals: {
      eventDate: '2026-01-02',     // Yesterday
      currentDate: '2026-01-03',   // Today
      emailType: 'calendar_reminder'
    },
    expectedIntent: 'archive',
    expectedConfidence: 0.95,
    reasoning: 'Past event reminders are definitionally stale'
  },
  
  // New Sender Caution
  {
    id: 'edge-new-sender-001',
    scenario: 'First email from new sender that looks like spam but is actually important',
    signals: {
      isFirstContact: true,
      hasMarketingWords: true,     // "opportunity", "exclusive"
      senderDomainAge: 5,          // Years - established domain
      domainIsCompanyDomain: true  // Matches user's employer
    },
    expectedIntent: 'none',        // Don't auto-classify
    expectedConfidence: 0.40,
    reasoning: 'New sender + mixed signals = surface options, don\'t auto-act'
  },
  
  // Attachment Context
  {
    id: 'edge-attachment-001',
    scenario: 'Email with attachment from unknown sender',
    signals: {
      hasAttachment: true,
      attachmentType: 'pdf',
      senderIsContact: false,
      subjectContains: 'invoice'
    },
    expectedIntent: 'none',        // Caution warranted
    expectedConfidence: 0.35,
    reasoning: 'Attachments from unknown senders need manual review'
  }
];
```

## 2.3 Test Runner Implementation

### 2.3.1 Core Test Runner

```typescript
// packages/@zero/test-harness/src/runner.ts

import { IntentEngine } from '@zero/intent-engine';
import { ActionResolver } from '@zero/action-resolver';
import { ConfidenceScorer } from '@zero/confidence';
import type { EmailFixture, TestResult, TestSummary } from '@zero/core-types';

interface TestRunConfig {
  fixtures: EmailFixture[];
  abortOnFirstFailure: boolean;
  parallelism: number;
  timeout: number;              // ms per test
  outputFormat: 'json' | 'junit' | 'tap';
}

interface TestResult {
  fixtureId: string;
  fixtureName: string;
  passed: boolean;
  
  // What we expected
  expectedIntent: IntentType;
  expectedConfidenceRange: [number, number];
  expectedAction: ActionType;
  
  // What we got
  actualIntent: IntentType;
  actualConfidence: number;
  actualAction: ActionType;
  
  // Diagnostics
  intentMatch: boolean;
  confidenceInRange: boolean;
  actionMatch: boolean;
  
  // Performance
  latencyMs: number;
  
  // Debug info
  reasoning?: IntentReasoning;
  error?: string;
}

export class ActionTestRunner {
  private intentEngine: IntentEngine;
  private actionResolver: ActionResolver;
  private confidenceScorer: ConfidenceScorer;
  
  constructor(config?: Partial<EngineConfig>) {
    this.intentEngine = new IntentEngine(config);
    this.actionResolver = new ActionResolver(config);
    this.confidenceScorer = new ConfidenceScorer(config);
  }

  async runFixture(fixture: EmailFixture): Promise<TestResult> {
    const startTime = performance.now();
    
    try {
      // Build input from fixture
      const input = this.buildInput(fixture);
      
      // Run classification
      const intentResult = await this.intentEngine.classifyIntent(input);
      
      // Resolve action
      const actionResult = await this.actionResolver.resolve({
        intent: intentResult,
        email: fixture.email,
        userPreferences: this.getDefaultPreferences(),
        availableActions: this.getAllActions()
      });
      
      const latencyMs = performance.now() - startTime;
      
      // Evaluate results
      const intentMatch = intentResult.primaryIntent.type === fixture.expectedIntent;
      const confidenceInRange = 
        intentResult.confidence >= fixture.expectedConfidenceRange[0] &&
        intentResult.confidence <= fixture.expectedConfidenceRange[1];
      const actionMatch = actionResult.primaryAction.type === fixture.expectedAction;
      
      return {
        fixtureId: fixture.id,
        fixtureName: fixture.name,
        passed: intentMatch && confidenceInRange && actionMatch,
        
        expectedIntent: fixture.expectedIntent,
        expectedConfidenceRange: fixture.expectedConfidenceRange,
        expectedAction: fixture.expectedAction,
        
        actualIntent: intentResult.primaryIntent.type,
        actualConfidence: intentResult.confidence,
        actualAction: actionResult.primaryAction.type,
        
        intentMatch,
        confidenceInRange,
        actionMatch,
        
        latencyMs,
        reasoning: intentResult.reasoning
      };
    } catch (error) {
      return {
        fixtureId: fixture.id,
        fixtureName: fixture.name,
        passed: false,
        error: error.message,
        latencyMs: performance.now() - startTime,
        // ... other fields with defaults
      };
    }
  }

  async runSuite(config: TestRunConfig): Promise<TestSummary> {
    const results: TestResult[] = [];
    const startTime = performance.now();
    
    // Run in batches for parallelism
    const batches = this.batchFixtures(config.fixtures, config.parallelism);
    
    for (const batch of batches) {
      const batchResults = await Promise.all(
        batch.map(fixture => 
          this.runWithTimeout(fixture, config.timeout)
        )
      );
      
      results.push(...batchResults);
      
      if (config.abortOnFirstFailure && batchResults.some(r => !r.passed)) {
        break;
      }
    }
    
    return this.summarize(results, performance.now() - startTime);
  }

  private summarize(results: TestResult[], totalTimeMs: number): TestSummary {
    const passed = results.filter(r => r.passed);
    const failed = results.filter(r => !r.passed);
    
    // Group failures by type
    const intentFailures = failed.filter(r => !r.intentMatch);
    const confidenceFailures = failed.filter(r => r.intentMatch && !r.confidenceInRange);
    const actionFailures = failed.filter(r => r.intentMatch && r.confidenceInRange && !r.actionMatch);
    
    // Calculate confidence calibration
    const calibrationScore = this.calculateCalibrationScore(results);
    
    return {
      totalTests: results.length,
      passed: passed.length,
      failed: failed.length,
      passRate: passed.length / results.length,
      
      failureBreakdown: {
        intentMismatches: intentFailures.length,
        confidenceOutOfRange: confidenceFailures.length,
        actionMismatches: actionFailures.length
      },
      
      performance: {
        totalTimeMs,
        avgLatencyMs: results.reduce((sum, r) => sum + r.latencyMs, 0) / results.length,
        p50LatencyMs: this.percentile(results.map(r => r.latencyMs), 50),
        p95LatencyMs: this.percentile(results.map(r => r.latencyMs), 95),
        p99LatencyMs: this.percentile(results.map(r => r.latencyMs), 99)
      },
      
      calibration: calibrationScore,
      
      results
    };
  }

  private calculateCalibrationScore(results: TestResult[]): CalibrationScore {
    // Group results by confidence bucket
    const buckets = [
      { min: 0.0, max: 0.2, results: [] },
      { min: 0.2, max: 0.4, results: [] },
      { min: 0.4, max: 0.6, results: [] },
      { min: 0.6, max: 0.8, results: [] },
      { min: 0.8, max: 1.0, results: [] }
    ];
    
    for (const result of results) {
      const bucket = buckets.find(b => 
        result.actualConfidence >= b.min && result.actualConfidence < b.max
      );
      if (bucket) bucket.results.push(result);
    }
    
    // Calculate actual accuracy per bucket
    const calibrationData = buckets.map(bucket => ({
      confidenceRange: [bucket.min, bucket.max],
      predictedAccuracy: (bucket.min + bucket.max) / 2,
      actualAccuracy: bucket.results.length > 0
        ? bucket.results.filter(r => r.passed).length / bucket.results.length
        : null,
      sampleSize: bucket.results.length
    }));
    
    // Expected Calibration Error (ECE)
    const ece = calibrationData.reduce((sum, bucket) => {
      if (bucket.actualAccuracy === null) return sum;
      return sum + (bucket.sampleSize / results.length) * 
        Math.abs(bucket.predictedAccuracy - bucket.actualAccuracy);
    }, 0);
    
    return {
      expectedCalibrationError: ece,
      isWellCalibrated: ece < 0.1,  // <10% ECE is considered good
      bucketData: calibrationData
    };
  }
}
```

### 2.3.2 CLI Interface

```typescript
// packages/@zero/test-harness/src/cli.ts

#!/usr/bin/env node

import { program } from 'commander';
import { ActionTestRunner } from './runner';
import { loadFixtures, loadEdgeCases } from '@zero/test-fixtures';

program
  .name('zero-test')
  .description('Zero action system test harness')
  .version('1.0.0');

program
  .command('run')
  .description('Run test suite')
  .option('-f, --fixtures <path>', 'Path to fixture file or directory')
  .option('-c, --category <category>', 'Filter by category')
  .option('-t, --tag <tag>', 'Filter by tag')
  .option('--edge-cases', 'Run edge case suite')
  .option('--parallel <n>', 'Parallelism level', '4')
  .option('--timeout <ms>', 'Timeout per test', '5000')
  .option('--format <format>', 'Output format (json|junit|tap)', 'json')
  .option('--fail-fast', 'Abort on first failure')
  .action(async (options) => {
    const runner = new ActionTestRunner();
    
    let fixtures = await loadFixtures(options.fixtures);
    
    if (options.category) {
      fixtures = fixtures.filter(f => f.category === options.category);
    }
    
    if (options.tag) {
      fixtures = fixtures.filter(f => f.tags.includes(options.tag));
    }
    
    if (options.edgeCases) {
      fixtures = await loadEdgeCases();
    }
    
    const summary = await runner.runSuite({
      fixtures,
      parallelism: parseInt(options.parallel),
      timeout: parseInt(options.timeout),
      outputFormat: options.format,
      abortOnFirstFailure: options.failFast
    });
    
    // Output based on format
    switch (options.format) {
      case 'json':
        console.log(JSON.stringify(summary, null, 2));
        break;
      case 'junit':
        console.log(toJUnit(summary));
        break;
      case 'tap':
        console.log(toTAP(summary));
        break;
    }
    
    process.exit(summary.failed > 0 ? 1 : 0);
  });

program
  .command('watch')
  .description('Run tests in watch mode')
  .action(async () => {
    // Watch for changes and re-run
  });

program
  .command('coverage')
  .description('Generate coverage report for action types')
  .action(async () => {
    const fixtures = await loadFixtures();
    const coverage = analyzeFixtureCoverage(fixtures);
    console.log(formatCoverageReport(coverage));
  });

program.parse();
```

### 2.3.3 Continuous Integration

```yaml
# .github/workflows/action-tests.yml

name: Action System Tests

on:
  push:
    branches: [main, develop]
    paths:
      - 'packages/@zero/intent-engine/**'
      - 'packages/@zero/action-resolver/**'
      - 'packages/@zero/confidence/**'
      - 'packages/@zero/test-fixtures/**'
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        node-version: [20.x]
        test-suite: [unit, integration, edge-cases]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: |
          case "${{ matrix.test-suite }}" in
            unit)
              npm run test:unit
              ;;
            integration)
              npm run test:integration
              ;;
            edge-cases)
              npx zero-test run --edge-cases --format junit > results.xml
              ;;
          esac
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results-${{ matrix.test-suite }}
          path: results.xml

  calibration-check:
    runs-on: ubuntu-latest
    needs: test
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run calibration analysis
        run: |
          npx zero-test run --format json > results.json
          node scripts/check-calibration.js results.json
      
      - name: Fail if poorly calibrated
        run: |
          ECE=$(jq '.calibration.expectedCalibrationError' results.json)
          if (( $(echo "$ECE > 0.15" | bc -l) )); then
            echo "Calibration error too high: $ECE"
            exit 1
          fi
```

## 2.4 Test-Fix-Test Workflow

### 2.4.1 The Iterative Loop

```
┌─────────────────────────────────────────────────────────────────┐
│                  TEST-FIX-TEST CYCLE                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌──────────┐                                                  │
│   │  1. RUN  │                                                  │
│   │  TESTS   │                                                  │
│   └────┬─────┘                                                  │
│        │                                                        │
│        ▼                                                        │
│   ┌──────────────────────────────────────────────┐              │
│   │  2. ANALYZE FAILURES                          │              │
│   │                                               │              │
│   │  • Group by failure type (intent/conf/action)│              │
│   │  • Identify pattern in failures              │              │
│   │  • Check if edge case or systematic          │              │
│   └────┬────────────────────────────────────────┘              │
│        │                                                        │
│        ▼                                                        │
│   ┌──────────────────────────────────────────────┐              │
│   │  3. DIAGNOSE ROOT CAUSE                       │              │
│   │                                               │              │
│   │  Intent wrong?                               │              │
│   │  ├─► Check rule weights                      │              │
│   │  ├─► Check feature extraction                │              │
│   │  └─► Check ML model inputs                   │              │
│   │                                               │              │
│   │  Confidence wrong?                           │              │
│   │  ├─► Check calibration curve                 │              │
│   │  └─► Check context adjustments               │              │
│   │                                               │              │
│   │  Action wrong?                               │              │
│   │  ├─► Check action resolution rules           │              │
│   │  └─► Check parameter generation              │              │
│   └────┬────────────────────────────────────────┘              │
│        │                                                        │
│        ▼                                                        │
│   ┌──────────────────────────────────────────────┐              │
│   │  4. IMPLEMENT FIX                             │              │
│   │                                               │              │
│   │  • Minimal change principle                  │              │
│   │  • Document reasoning                        │              │
│   │  • Add regression test for the fix           │              │
│   └────┬────────────────────────────────────────┘              │
│        │                                                        │
│        ▼                                                        │
│   ┌──────────────────────────────────────────────┐              │
│   │  5. VERIFY FIX                                │              │
│   │                                               │              │
│   │  • Run failed test → now passes              │              │
│   │  • Run full suite → no regressions           │              │
│   │  • Check calibration → still good            │              │
│   └────┬────────────────────────────────────────┘              │
│        │                                                        │
│        └──────────────► (back to step 1)                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.4.2 Failure Investigation Template

When a test fails, use this systematic approach:

```typescript
// packages/@zero/test-harness/src/investigate.ts

interface FailureInvestigation {
  fixtureId: string;
  investigatedAt: Date;
  
  // What happened
  failure: {
    type: 'intent' | 'confidence' | 'action';
    expected: string;
    actual: string;
    delta?: number;  // For confidence
  };
  
  // Why it happened
  rootCause: {
    component: 'rules' | 'ml' | 'patterns' | 'calibration' | 'resolution';
    explanation: string;
    evidence: string[];  // What signals led to wrong result
  };
  
  // What to do
  fix: {
    approach: string;
    codeChanges: string[];
    riskAssessment: 'low' | 'medium' | 'high';
    potentialRegressions: string[];
  };
  
  // Verification
  verification: {
    fixedTestPasses: boolean;
    fullSuitePasses: boolean;
    calibrationDelta: number;
  };
}

// Example investigation
const exampleInvestigation: FailureInvestigation = {
  fixtureId: 'newsletter-002',
  investigatedAt: new Date('2026-01-03'),
  
  failure: {
    type: 'intent',
    expected: 'star',
    actual: 'archive'
  },
  
  rootCause: {
    component: 'rules',
    explanation: 'Sender category rule (newsletter) overriding content analysis (action required)',
    evidence: [
      'Rule: sender_category=newsletter → archive (weight: 0.8)',
      'Content signal: "action required" detected (weight: 0.6)',
      'Sender rule firing first and short-circuiting'
    ]
  },
  
  fix: {
    approach: 'Add action-required detection as higher-priority rule that can override sender category',
    codeChanges: [
      'Add ActionRequiredRule with weight 0.9',
      'Ensure it evaluates before SenderCategoryRule',
      'Add subject line pattern matching for "action required", "response needed", etc.'
    ],
    riskAssessment: 'medium',
    potentialRegressions: [
      'Marketing emails with fake urgency might not archive',
      'Need to combine with sender reputation'
    ]
  },
  
  verification: {
    fixedTestPasses: true,
    fullSuitePasses: true,
    calibrationDelta: -0.02  // Slightly improved
  }
};
```

---

# 3. Telemetry Schema for Action Tracking

## 3.1 Telemetry Philosophy

**Tests tell you what's broken in development. Telemetry tells you what's broken in production.**

Your test fixtures will never cover the full distribution of real-world emails. Telemetry closes the loop.

```
┌─────────────────────────────────────────────────────────────────┐
│                  TELEMETRY FEEDBACK LOOP                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Production                                                    │
│   ┌─────────────┐                                               │
│   │ User swipes │──► Telemetry Event                           │
│   │ on email    │                                               │
│   └─────────────┘          │                                    │
│                            ▼                                    │
│                     ┌─────────────┐                             │
│                     │  Analytics  │                             │
│                     │  Pipeline   │                             │
│                     └──────┬──────┘                             │
│                            │                                    │
│           ┌────────────────┼────────────────┐                   │
│           ▼                ▼                ▼                   │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│   │  Dashboards │  │   Alerts    │  │  Fixtures   │            │
│   │             │  │             │  │  Generator  │            │
│   └─────────────┘  └─────────────┘  └──────┬──────┘            │
│                                            │                    │
│                                            ▼                    │
│   Development                       ┌─────────────┐            │
│                                     │ New tests   │            │
│                                     │ from prod   │            │
│                                     │ failures    │            │
│                                     └─────────────┘            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 3.2 Event Schema

### 3.2.1 Core Events

```typescript
// packages/@zero/telemetry/src/events.ts

/**
 * Event fired when action modal is displayed to user
 */
interface ActionModalShownEvent {
  eventType: 'action_modal_shown';
  timestamp: Date;
  
  // Session context
  sessionId: string;
  userId: string;            // Anonymized
  deviceType: 'ios' | 'web' | 'watch';
  appVersion: string;
  
  // Email context (anonymized)
  emailContext: {
    emailId: string;         // Internal ID
    threadId: string;
    threadPosition: number;
    threadLength: number;
    senderDomain: string;    // Domain only, not full address
    senderCategory: SenderCategory;
    isContact: boolean;
    hasAttachments: boolean;
    attachmentCount: number;
    emailAgeMinutes: number;
    subjectLength: number;
    bodyLength: number;
    receivedHour: number;    // 0-23
    receivedDayOfWeek: number;  // 0-6
  };
  
  // What we showed
  modalContent: {
    primaryAction: ActionType;
    primaryConfidence: number;
    alternativeActions: ActionType[];
    alternativeConfidences: number[];
    quickReplyCount: number;
    modalVariant: 'single' | 'dual' | 'grid';
  };
  
  // Classification details
  classification: {
    intentType: IntentType;
    intentConfidence: number;
    confidenceBucket: ConfidenceBucket;
    rulesTriggered: string[];      // Rule IDs that fired
    processingTimeMs: number;
  };
}

/**
 * Event fired when user takes an action
 */
interface ActionTakenEvent {
  eventType: 'action_taken';
  timestamp: Date;
  
  // Link to modal event
  modalEventId: string;
  
  // What user did
  actionTaken: ActionType | 'dismissed' | 'custom';
  wasOverride: boolean;           // Did they pick something other than primary?
  actionPosition: number;         // 0 = primary, 1+ = alternative
  
  // Timing
  timeToActionMs: number;         // Time from modal shown to action
  dwellTimeMs: number;            // Time spent looking at modal
  
  // Interaction details
  interactionType: 'tap' | 'swipe' | 'long_press' | 'voice';
  
  // For replies
  replyMetadata?: {
    usedQuickReply: boolean;
    quickReplyIndex?: number;
    replyLength?: number;
    editedQuickReply: boolean;
  };
}

/**
 * Event fired when user undoes an action
 */
interface ActionUndoneEvent {
  eventType: 'action_undone';
  timestamp: Date;
  
  // Link to original action
  actionEventId: string;
  
  // Undo details
  timeToUndoMs: number;           // How quickly they undid
  undoMethod: 'toast' | 'shake' | 'menu';
  
  // What they did after undo
  subsequentAction?: ActionType;  // What did they do instead?
}

/**
 * Event fired when classification appears wrong based on user behavior
 */
interface ClassificationFeedbackEvent {
  eventType: 'classification_feedback';
  timestamp: Date;
  
  emailId: string;
  
  // What we predicted
  predictedIntent: IntentType;
  predictedConfidence: number;
  
  // Implicit feedback signals
  feedbackSignals: {
    overrodeAction: boolean;
    undidAction: boolean;
    timeToAction: number;         // Long time = confusion
    reopenedEmail: boolean;       // Had to come back
    manuallyLabeled: boolean;     // User applied manual label
  };
  
  // Derived quality score
  qualityScore: number;           // -1 to 1 (negative = bad prediction)
}
```

### 3.2.2 Aggregated Metrics

```typescript
// packages/@zero/telemetry/src/metrics.ts

/**
 * Hourly aggregates for dashboards
 */
interface HourlyActionMetrics {
  hour: Date;                     // Truncated to hour
  
  // Volume
  totalModalShown: number;
  totalActionsTaken: number;
  totalDismissed: number;
  totalUndone: number;
  
  // Quality
  primaryActionAcceptanceRate: number;
  overrideRate: number;
  undoRate: number;
  
  // Confidence calibration
  confidenceBucketAccuracy: {
    bucket: ConfidenceBucket;
    predicted: number;            // Average confidence in bucket
    actual: number;               // Actual acceptance rate
    sampleSize: number;
  }[];
  
  // Performance
  avgClassificationTimeMs: number;
  p95ClassificationTimeMs: number;
  
  // By action type
  actionBreakdown: {
    action: ActionType;
    shown: number;
    taken: number;
    undone: number;
  }[];
  
  // By sender category
  categoryBreakdown: {
    category: SenderCategory;
    avgAcceptanceRate: number;
    avgConfidence: number;
  }[];
}

/**
 * Rolling metrics for alerting
 */
interface RollingMetrics {
  windowStart: Date;
  windowEnd: Date;
  windowMinutes: number;
  
  // Alert thresholds
  metrics: {
    acceptanceRate: number;       // Alert if < 0.70
    undoRate: number;             // Alert if > 0.10
    avgTimeToAction: number;      // Alert if > 5000ms
    errorRate: number;            // Alert if > 0.01
  };
}
```

## 3.3 Implementation

### 3.3.1 Client-Side Tracking

```typescript
// packages/@zero/telemetry/src/client.ts

class ActionTelemetryClient {
  private queue: TelemetryEvent[] = [];
  private flushInterval: number = 30000;  // 30 seconds
  private maxQueueSize: number = 100;
  
  constructor(private config: TelemetryConfig) {
    this.startFlushTimer();
  }

  trackModalShown(event: Omit<ActionModalShownEvent, 'eventType' | 'timestamp'>): string {
    const eventId = this.generateEventId();
    
    const fullEvent: ActionModalShownEvent = {
      eventType: 'action_modal_shown',
      timestamp: new Date(),
      ...this.anonymize(event),
      ...this.addSessionContext()
    };
    
    this.enqueue(fullEvent);
    return eventId;  // Return for linking subsequent events
  }

  trackActionTaken(modalEventId: string, event: Omit<ActionTakenEvent, 'eventType' | 'timestamp' | 'modalEventId'>): void {
    const fullEvent: ActionTakenEvent = {
      eventType: 'action_taken',
      timestamp: new Date(),
      modalEventId,
      ...event
    };
    
    this.enqueue(fullEvent);
    
    // Immediate flush for action events (important signal)
    if (event.wasOverride || event.actionTaken === 'dismissed') {
      this.flush();
    }
  }

  trackUndo(actionEventId: string, event: Omit<ActionUndoneEvent, 'eventType' | 'timestamp' | 'actionEventId'>): void {
    const fullEvent: ActionUndoneEvent = {
      eventType: 'action_undone',
      timestamp: new Date(),
      actionEventId,
      ...event
    };
    
    this.enqueue(fullEvent);
    this.flush();  // Immediate flush - undos are high signal
  }

  private anonymize<T>(event: T): T {
    // Remove PII, hash IDs, truncate content
    return {
      ...event,
      // Hash user ID
      userId: this.hash(event.userId),
      // Remove email content, keep metadata
      emailContext: {
        ...event.emailContext,
        // Domain only, not full email
        senderDomain: this.extractDomain(event.emailContext.senderEmail)
      }
    };
  }

  private enqueue(event: TelemetryEvent): void {
    this.queue.push(event);
    
    if (this.queue.length >= this.maxQueueSize) {
      this.flush();
    }
  }

  private async flush(): Promise<void> {
    if (this.queue.length === 0) return;
    
    const batch = this.queue.splice(0, this.queue.length);
    
    try {
      await fetch(this.config.endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ events: batch })
      });
    } catch (error) {
      // Re-queue on failure
      this.queue.unshift(...batch);
    }
  }
}
```

### 3.3.2 Server-Side Processing

```typescript
// packages/@zero/telemetry/src/server/processor.ts

class TelemetryProcessor {
  constructor(
    private db: TelemetryDatabase,
    private alerting: AlertingService,
    private fixtureGenerator: FixtureGenerator
  ) {}

  async processBatch(events: TelemetryEvent[]): Promise<void> {
    // Store raw events
    await this.db.insertEvents(events);
    
    // Update rolling metrics
    await this.updateRollingMetrics(events);
    
    // Check for anomalies
    await this.checkAlerts(events);
    
    // Identify potential new fixtures
    await this.identifyFixtureCandidates(events);
  }

  private async updateRollingMetrics(events: TelemetryEvent[]): Promise<void> {
    const actionEvents = events.filter(e => e.eventType === 'action_taken') as ActionTakenEvent[];
    
    // Calculate current window metrics
    const metrics: RollingMetrics = {
      windowStart: new Date(Date.now() - 15 * 60 * 1000),  // 15 min window
      windowEnd: new Date(),
      windowMinutes: 15,
      metrics: {
        acceptanceRate: this.calculateAcceptanceRate(actionEvents),
        undoRate: await this.calculateUndoRate(),
        avgTimeToAction: this.avg(actionEvents.map(e => e.timeToActionMs)),
        errorRate: await this.getErrorRate()
      }
    };
    
    await this.db.updateRollingMetrics(metrics);
  }

  private async checkAlerts(events: TelemetryEvent[]): Promise<void> {
    const metrics = await this.db.getRollingMetrics();
    
    // Acceptance rate drop
    if (metrics.acceptanceRate < 0.70) {
      await this.alerting.trigger({
        severity: 'warning',
        metric: 'acceptance_rate',
        value: metrics.acceptanceRate,
        threshold: 0.70,
        message: `Action acceptance rate dropped to ${(metrics.acceptanceRate * 100).toFixed(1)}%`
      });
    }
    
    // Undo rate spike
    if (metrics.undoRate > 0.10) {
      await this.alerting.trigger({
        severity: 'critical',
        metric: 'undo_rate',
        value: metrics.undoRate,
        threshold: 0.10,
        message: `Undo rate spiked to ${(metrics.undoRate * 100).toFixed(1)}%`
      });
    }
    
    // Time to action increase (confusion)
    if (metrics.avgTimeToAction > 5000) {
      await this.alerting.trigger({
        severity: 'warning',
        metric: 'time_to_action',
        value: metrics.avgTimeToAction,
        threshold: 5000,
        message: `Average time to action increased to ${metrics.avgTimeToAction}ms`
      });
    }
  }

  private async identifyFixtureCandidates(events: TelemetryEvent[]): Promise<void> {
    // Find emails where user overrode or undid
    const problematicCases = events.filter(e => {
      if (e.eventType === 'action_taken') {
        return e.wasOverride || e.timeToActionMs > 10000;
      }
      if (e.eventType === 'action_undone') {
        return true;
      }
      return false;
    });
    
    for (const event of problematicCases) {
      // Queue for fixture generation (with PII removed)
      await this.fixtureGenerator.queueCandidate({
        emailContext: event.emailContext,  // Already anonymized
        predictedAction: event.modalContent?.primaryAction,
        actualAction: event.actionTaken,
        confidence: event.classification?.intentConfidence
      });
    }
  }
}
```

### 3.3.3 Dashboard Queries

```sql
-- Key dashboard queries

-- 1. Daily acceptance rate trend
SELECT 
  DATE_TRUNC('day', timestamp) as day,
  COUNT(CASE WHEN action_position = 0 THEN 1 END)::float / COUNT(*) as acceptance_rate,
  COUNT(*) as total_actions
FROM action_taken_events
WHERE timestamp > NOW() - INTERVAL '30 days'
GROUP BY 1
ORDER BY 1;

-- 2. Confidence calibration
SELECT 
  FLOOR(predicted_confidence * 10) / 10 as confidence_bucket,
  AVG(predicted_confidence) as avg_predicted,
  AVG(CASE WHEN action_position = 0 THEN 1.0 ELSE 0.0 END) as actual_accuracy,
  COUNT(*) as sample_size
FROM action_taken_events a
JOIN action_modal_shown_events m ON a.modal_event_id = m.event_id
WHERE a.timestamp > NOW() - INTERVAL '7 days'
GROUP BY 1
ORDER BY 1;

-- 3. Worst performing sender categories
SELECT 
  sender_category,
  COUNT(*) as total,
  AVG(CASE WHEN action_position = 0 THEN 1.0 ELSE 0.0 END) as acceptance_rate,
  AVG(CASE WHEN undone THEN 1.0 ELSE 0.0 END) as undo_rate
FROM action_taken_events a
JOIN action_modal_shown_events m ON a.modal_event_id = m.event_id
WHERE a.timestamp > NOW() - INTERVAL '7 days'
GROUP BY 1
HAVING COUNT(*) > 100
ORDER BY acceptance_rate ASC
LIMIT 10;

-- 4. Time-of-day patterns
SELECT 
  EXTRACT(HOUR FROM timestamp) as hour,
  primary_action,
  COUNT(*) as count,
  AVG(CASE WHEN action_position = 0 THEN 1.0 ELSE 0.0 END) as acceptance_rate
FROM action_taken_events a
JOIN action_modal_shown_events m ON a.modal_event_id = m.event_id
WHERE a.timestamp > NOW() - INTERVAL '7 days'
GROUP BY 1, 2
ORDER BY 1, 2;

-- 5. Most common overrides (what do users actually want?)
SELECT 
  m.primary_action as predicted,
  a.action_taken as actual,
  COUNT(*) as override_count
FROM action_taken_events a
JOIN action_modal_shown_events m ON a.modal_event_id = m.event_id
WHERE a.was_override = true
  AND a.timestamp > NOW() - INTERVAL '7 days'
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 20;
```

## 3.4 Privacy Considerations

```typescript
// packages/@zero/telemetry/src/privacy.ts

/**
 * Data retention and privacy rules
 */
const PRIVACY_CONFIG = {
  // What we NEVER collect
  neverCollect: [
    'email_body_content',
    'email_subject_text',
    'sender_email_address',
    'recipient_email_addresses',
    'attachment_content',
    'user_ip_address'
  ],
  
  // What we anonymize
  anonymize: {
    userId: 'sha256_hash',
    emailId: 'sha256_hash',
    senderDomain: 'keep_domain_only',  // Remove username
  },
  
  // Retention periods
  retention: {
    rawEvents: '90_days',
    aggregatedMetrics: '2_years',
    fixtureCandiates: '30_days'
  },
  
  // User controls
  userControls: {
    canOptOut: true,
    canRequestDeletion: true,
    canExportData: true
  }
};
```

---

# 4. WatchOS App Architecture

## 4.1 Design Philosophy

The Apple Watch is a **triage surface**, not a full email client. Users should be able to:

1. **Glance** — See what needs attention in 2 seconds
2. **Act** — Take simple actions (archive, star, snooze) with one tap
3. **Defer** — Mark for phone/desktop handling

```
┌─────────────────────────────────────────────────────────────────┐
│               WATCH INTERACTION MODEL                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────────────────────────────────────────┐       │
│   │                   GLANCE                            │       │
│   │   • Complication: 3 unread (1 priority)            │       │
│   │   • Notification: "John: Can you review...?"       │       │
│   │   Time to consume: 2 seconds                       │       │
│   └─────────────────────────────────────────────────────┘       │
│                           │                                     │
│                           ▼                                     │
│   ┌─────────────────────────────────────────────────────┐       │
│   │                    ACT                              │       │
│   │   • Tap → Archive                                  │       │
│   │   • Force press → More options                     │       │
│   │   • Swipe → Next email                             │       │
│   │   Time to act: 1-2 seconds                         │       │
│   └─────────────────────────────────────────────────────┘       │
│                           │                                     │
│                           ▼                                     │
│   ┌─────────────────────────────────────────────────────┐       │
│   │                   DEFER                             │       │
│   │   • "Handle on phone" button                       │       │
│   │   • Snooze until context switch                    │       │
│   │   Time to defer: 1 tap                             │       │
│   └─────────────────────────────────────────────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 4.2 Technical Architecture

### 4.2.1 App Structure

```
ZeroWatch/
├── ZeroWatchApp.swift           # App entry point
├── Models/
│   ├── WatchEmailItem.swift     # Lightweight email model
│   └── WatchSyncState.swift     # Sync status tracking
│
├── Views/
│   ├── ContentView.swift        # Main navigation
│   ├── InboxView.swift          # Email list
│   ├── EmailDetailView.swift    # Single email view
│   ├── TriageView.swift         # Swipe-through triage mode
│   └── QuickReplyView.swift     # Voice/canned reply
│
├── Complications/
│   ├── ComplicationController.swift
│   └── ComplicationViews.swift
│
├── Notifications/
│   ├── NotificationController.swift
│   └── NotificationView.swift
│
├── Services/
│   ├── WatchConnectivityManager.swift   # iOS ↔ Watch sync
│   ├── IndependentSyncManager.swift     # Direct API (offline)
│   └── CoreBridge.swift                 # Shared TS core access
│
└── Extensions/
    └── IntentExtension/          # Siri integration
```

### 4.2.2 Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                   WATCH DATA ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌──────────────────┐        ┌──────────────────┐             │
│   │    iOS App       │        │   Zero Backend   │             │
│   │                  │        │                  │             │
│   │ ┌──────────────┐ │        │                  │             │
│   │ │ Shared Core  │ │        │                  │             │
│   │ │ (TypeScript) │ │        │                  │             │
│   │ └──────────────┘ │        │                  │             │
│   └────────┬─────────┘        └────────┬─────────┘             │
│            │                           │                        │
│            │ WatchConnectivity         │ Direct API             │
│            │ (preferred)               │ (fallback)             │
│            │                           │                        │
│            └─────────┬─────────────────┘                        │
│                      │                                          │
│                      ▼                                          │
│            ┌──────────────────┐                                 │
│            │   Watch App      │                                 │
│            │                  │                                 │
│            │ ┌──────────────┐ │                                 │
│            │ │ Local Cache  │ │  ← Last 50 emails              │
│            │ │ (SwiftData)  │ │  ← Pre-computed actions        │
│            │ └──────────────┘ │  ← Offline queue               │
│            │                  │                                 │
│            │ ┌──────────────┐ │                                 │
│            │ │ Intent Store │ │  ← Cached classifications      │
│            │ └──────────────┘ │                                 │
│            └──────────────────┘                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2.3 WatchConnectivity Implementation

```swift
// ZeroWatch/Services/WatchConnectivityManager.swift

import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isReachable = false
    @Published var syncState: SyncState = .idle
    
    private let session: WCSession
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        session = WCSession.default
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Sync Methods
    
    /// Request latest inbox state from iPhone
    func requestInboxSync() {
        guard session.isReachable else {
            // Fall back to independent sync
            IndependentSyncManager.shared.syncInbox()
            return
        }
        
        syncState = .syncing
        
        session.sendMessage(
            ["type": "inbox_sync_request", "limit": 50],
            replyHandler: { response in
                self.handleInboxResponse(response)
            },
            errorHandler: { error in
                self.syncState = .error(error)
            }
        )
    }
    
    /// Send action to iPhone for execution
    func sendAction(_ action: WatchAction) async throws {
        guard session.isReachable else {
            // Queue for later sync
            ActionQueue.shared.enqueue(action)
            return
        }
        
        let message: [String: Any] = [
            "type": "action",
            "emailId": action.emailId,
            "actionType": action.type.rawValue,
            "parameters": action.parameters
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            session.sendMessage(message, replyHandler: { response in
                if let success = response["success"] as? Bool, success {
                    continuation.resume()
                } else {
                    let error = WatchError.actionFailed(response["error"] as? String ?? "Unknown")
                    continuation.resume(throwing: error)
                }
            }, errorHandler: { error in
                continuation.resume(throwing: error)
            })
        }
    }
    
    // MARK: - Response Handling
    
    private func handleInboxResponse(_ response: [String: Any]) {
        guard let emailsData = response["emails"] as? [[String: Any]] else {
            syncState = .error(WatchError.invalidResponse)
            return
        }
        
        let emails = emailsData.compactMap { WatchEmailItem(dictionary: $0) }
        
        // Update local cache
        Task {
            await LocalCache.shared.updateEmails(emails)
            await MainActor.run {
                self.syncState = .synced(Date())
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            
            // Sync when phone becomes reachable
            if session.isReachable {
                self.requestInboxSync()
                ActionQueue.shared.flush()
            }
        }
    }
    
    // Receive push updates from iPhone
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "new_email":
            handleNewEmail(message)
        case "email_update":
            handleEmailUpdate(message)
        case "classification_update":
            handleClassificationUpdate(message)
        default:
            break
        }
    }
    
    private func handleNewEmail(_ message: [String: Any]) {
        guard let emailData = message["email"] as? [String: Any],
              let email = WatchEmailItem(dictionary: emailData) else { return }
        
        Task {
            await LocalCache.shared.insertEmail(email)
            
            // Update complication
            ComplicationController.shared.reloadComplications()
        }
    }
}
```

### 4.2.4 Triage View

```swift
// ZeroWatch/Views/TriageView.swift

import SwiftUI

struct TriageView: View {
    @StateObject private var viewModel = TriageViewModel()
    @State private var offset: CGFloat = 0
    @State private var activeAction: WatchAction? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Current email card
                if let email = viewModel.currentEmail {
                    EmailCard(email: email, suggestedAction: viewModel.suggestedAction)
                        .offset(x: offset)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation.width
                                    updateActiveAction(for: offset, width: geometry.size.width)
                                }
                                .onEnded { gesture in
                                    handleSwipeEnd(gesture: gesture, width: geometry.size.width)
                                }
                        )
                        .animation(.spring(response: 0.3), value: offset)
                }
                
                // Action indicators
                HStack {
                    // Left indicator (Archive)
                    ActionIndicator(
                        action: .archive,
                        isActive: activeAction?.type == .archive,
                        side: .left
                    )
                    
                    Spacer()
                    
                    // Right indicator (Star)
                    ActionIndicator(
                        action: .star,
                        isActive: activeAction?.type == .star,
                        side: .right
                    )
                }
                .padding(.horizontal, 8)
            }
        }
        .onAppear {
            viewModel.loadNextBatch()
        }
    }
    
    private func updateActiveAction(for offset: CGFloat, width: CGFloat) {
        let threshold = width * 0.3
        
        if offset < -threshold {
            activeAction = WatchAction(type: .archive, emailId: viewModel.currentEmail?.id ?? "")
            WKInterfaceDevice.current().play(.click)
        } else if offset > threshold {
            activeAction = WatchAction(type: .star, emailId: viewModel.currentEmail?.id ?? "")
            WKInterfaceDevice.current().play(.click)
        } else {
            activeAction = nil
        }
    }
    
    private func handleSwipeEnd(gesture: DragGesture.Value, width: CGFloat) {
        let threshold = width * 0.3
        
        if abs(gesture.translation.width) > threshold, let action = activeAction {
            // Execute action
            Task {
                await viewModel.executeAction(action)
            }
            
            // Animate card off screen
            withAnimation(.easeOut(duration: 0.2)) {
                offset = gesture.translation.width > 0 ? width : -width
            }
            
            // Load next email
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    offset = 0
                    viewModel.advanceToNext()
                }
            }
        } else {
            // Snap back
            withAnimation(.spring()) {
                offset = 0
            }
        }
        
        activeAction = nil
    }
}

struct EmailCard: View {
    let email: WatchEmailItem
    let suggestedAction: ActionType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sender
            HStack {
                Text(email.senderName)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(email.receivedAt.shortTimeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Subject
            Text(email.subject)
                .font(.subheadline)
                .lineLimit(2)
            
            // AI Summary
            if let summary = email.aiSummary {
                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Suggested action badge
            if let action = suggestedAction {
                HStack {
                    Spacer()
                    SuggestedActionBadge(action: action)
                }
            }
        }
        .padding()
        .background(Color(.darkGray).opacity(0.3))
        .cornerRadius(12)
    }
}

struct SuggestedActionBadge: View {
    let action: ActionType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: action.iconName)
            Text(action.shortLabel)
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(action.color.opacity(0.3))
        .cornerRadius(8)
    }
}
```

### 4.2.5 Complications

```swift
// ZeroWatch/Complications/ComplicationViews.swift

import SwiftUI
import WidgetKit

struct ZeroComplicationEntryView: View {
    var entry: ZeroComplicationEntry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularComplication(entry: entry)
        case .accessoryRectangular:
            RectangularComplication(entry: entry)
        case .accessoryCorner:
            CornerComplication(entry: entry)
        case .accessoryInline:
            InlineComplication(entry: entry)
        default:
            EmptyView()
        }
    }
}

struct CircularComplication: View {
    let entry: ZeroComplicationEntry
    
    var body: some View {
        ZStack {
            // Background ring showing priority ratio
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: entry.priorityRatio)
                .stroke(Color.red, lineWidth: 4)
                .rotationEffect(.degrees(-90))
            
            // Center content
            VStack(spacing: 0) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 14))
                
                Text("\(entry.unreadCount)")
                    .font(.system(size: 16, weight: .bold))
            }
        }
    }
}

struct RectangularComplication: View {
    let entry: ZeroComplicationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "envelope.fill")
                Text("\(entry.unreadCount) unread")
                    .font(.headline)
            }
            
            if let topEmail = entry.topPriorityEmail {
                Text(topEmail.senderName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(topEmail.subject)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
    }
}

// Timeline Provider
struct ZeroComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ZeroComplicationEntry {
        ZeroComplicationEntry(
            date: Date(),
            unreadCount: 5,
            priorityCount: 1,
            topPriorityEmail: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ZeroComplicationEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ZeroComplicationEntry>) -> Void) {
        let entry = createEntry()
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func createEntry() -> ZeroComplicationEntry {
        let cache = LocalCache.shared
        let emails = cache.getCachedEmails()
        let unread = emails.filter { !$0.isRead }
        let priority = unread.filter { $0.isPriority }
        
        return ZeroComplicationEntry(
            date: Date(),
            unreadCount: unread.count,
            priorityCount: priority.count,
            topPriorityEmail: priority.first,
            priorityRatio: unread.isEmpty ? 0 : CGFloat(priority.count) / CGFloat(unread.count)
        )
    }
}
```

### 4.2.6 Notification Handling

```swift
// ZeroWatch/Notifications/NotificationController.swift

import WatchKit
import UserNotifications

class NotificationController: WKUserNotificationHostingController<NotificationView> {
    var email: WatchEmailItem?
    var suggestedAction: ActionType?
    
    override var body: NotificationView {
        NotificationView(
            email: email,
            suggestedAction: suggestedAction,
            onAction: handleAction
        )
    }
    
    override func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        // Parse email data from notification
        if let emailData = userInfo["email"] as? [String: Any] {
            email = WatchEmailItem(dictionary: emailData)
        }
        
        // Get pre-computed suggested action
        if let actionRaw = userInfo["suggestedAction"] as? String {
            suggestedAction = ActionType(rawValue: actionRaw)
        }
    }
    
    private func handleAction(_ action: ActionType) {
        guard let email = email else { return }
        
        let watchAction = WatchAction(type: action, emailId: email.id)
        
        Task {
            try? await WatchConnectivityManager.shared.sendAction(watchAction)
        }
        
        // Dismiss notification
        WKApplication.shared().dismissNotification()
    }
}

struct NotificationView: View {
    let email: WatchEmailItem?
    let suggestedAction: ActionType?
    let onAction: (ActionType) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let email = email {
                // Sender and time
                HStack {
                    Text(email.senderName)
                        .font(.headline)
                    Spacer()
                    Text(email.receivedAt.shortTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Subject
                Text(email.subject)
                    .font(.subheadline)
                    .lineLimit(2)
                
                // AI Summary
                if let summary = email.aiSummary {
                    Text(summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Divider()
                
                // Quick actions
                HStack(spacing: 12) {
                    // Primary suggested action (larger)
                    if let suggested = suggestedAction {
                        Button(action: { onAction(suggested) }) {
                            VStack {
                                Image(systemName: suggested.iconName)
                                    .font(.title2)
                                Text(suggested.shortLabel)
                                    .font(.caption2)
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(suggested.color)
                    }
                    
                    // Secondary actions
                    ForEach(secondaryActions, id: \.self) { action in
                        Button(action: { onAction(action) }) {
                            Image(systemName: action.iconName)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var secondaryActions: [ActionType] {
        let all: [ActionType] = [.archive, .star, .snooze]
        return all.filter { $0 != suggestedAction }
    }
}
```

## 4.3 Shared Core Integration

The Watch app uses the same TypeScript shared core, but with a crucial difference: classifications are pre-computed on the iPhone and synced to the Watch.

```swift
// ZeroWatch/Services/CoreBridge.swift

import JavaScriptCore

/**
 * Bridge to shared TypeScript core for Watch.
 * 
 * IMPORTANT: On Watch, we prefer pre-computed classifications from iPhone.
 * Local classification is only used when:
 * 1. iPhone is unreachable
 * 2. New email arrives directly to Watch
 * 3. Classification is stale (>1 hour old)
 */
class CoreBridge {
    static let shared = CoreBridge()
    
    private var jsContext: JSContext?
    private var intentEngine: JSValue?
    
    private init() {
        // Lazy initialization - don't load core until needed
    }
    
    /// Get classification for email, preferring cached iPhone classification
    func getClassification(for email: WatchEmailItem) async -> IntentClassification {
        // Check for cached classification from iPhone
        if let cached = LocalCache.shared.getCachedClassification(for: email.id),
           cached.isRecent {
            return cached
        }
        
        // Fall back to local classification
        return await classifyLocally(email)
    }
    
    private func classifyLocally(_ email: WatchEmailItem) async -> IntentClassification {
        // Ensure core is loaded
        if jsContext == nil {
            await loadCore()
        }
        
        guard let engine = intentEngine else {
            return .fallback
        }
        
        // Convert to JS input format
        let inputJSON = email.toClassificationInputJSON()
        
        // Run classification
        let result = engine.invokeMethod("classifyIntent", withArguments: [inputJSON])
        
        guard let resultString = result?.toString(),
              let classification = IntentClassification(json: resultString) else {
            return .fallback
        }
        
        return classification
    }
    
    private func loadCore() async {
        jsContext = JSContext()
        
        guard let context = jsContext,
              let corePath = Bundle.main.path(forResource: "zero-core-watch", ofType: "js"),
              let coreCode = try? String(contentsOfFile: corePath) else {
            return
        }
        
        // Load minified core (watch has limited memory)
        context.evaluateScript(coreCode)
        intentEngine = context.objectForKeyedSubscript("IntentEngine")
    }
}

extension IntentClassification {
    static let fallback = IntentClassification(
        intent: .none,
        confidence: 0.5,
        isPrecomputed: false
    )
    
    var isRecent: Bool {
        guard let computedAt = computedAt else { return false }
        return Date().timeIntervalSince(computedAt) < 3600  // 1 hour
    }
}
```

## 4.4 Watch App Acceptance Criteria

| Criterion | Measurement | Target |
|-----------|-------------|--------|
| Sync Latency | Time from iPhone action to Watch update | <2s |
| Triage Speed | Emails processed per minute | >15 |
| Battery Impact | Background drain per hour | <2% |
| Complication Update | Freshness of complication data | <15 min |
| Offline Capability | Actions queued without iPhone | 100% |
| Action Success | Actions sync correctly when reconnected | 100% |

---

# 5. Ship Readiness Criteria

## 5.1 The Trust Checklist

Before shipping to users with "complete trust," every item must pass:

### Intent Accuracy

| Metric | Target | Measurement |
|--------|--------|-------------|
| Primary intent correct | ≥95% | Test suite + production telemetry |
| Confidence correlation | r ≥ 0.8 | Calibration analysis |
| Catastrophic misclassifications | 0 | Manual review of edge cases |
| Edge case coverage | 100% | All edge case fixtures pass |

### Action Reliability

| Metric | Target | Measurement |
|--------|--------|-------------|
| Action success rate | ≥99.5% | Production telemetry |
| Undo success rate | 100% | E2E tests + production |
| Data loss incidents | 0 | Incident tracking |
| Cross-platform parity | 100% | Platform comparison tests |

### User Trust Signals

| Metric | Target | Measurement |
|--------|--------|-------------|
| Primary action acceptance | ≥80% | Telemetry |
| Override rate | ≤15% | Telemetry |
| Undo rate | ≤5% | Telemetry |
| Time to action | ≤2s p50 | Telemetry |
| Support tickets (action-related) | ≤0.1% | Support system |

### Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| Classification latency | ≤100ms p99 | Telemetry |
| Action execution latency | ≤300ms p99 | Telemetry |
| App launch to usable | ≤2s p95 | Performance monitoring |
| Watch sync latency | ≤2s | WatchConnectivity metrics |

### Confidence Calibration

| Metric | Target | Measurement |
|--------|--------|-------------|
| Expected Calibration Error | ≤0.10 | Calibration analysis |
| Per-bucket accuracy deviation | ≤15% | Calibration analysis |
| Confidence-outcome correlation | r ≥ 0.85 | Statistical analysis |

## 5.2 Staged Rollout Plan

```
┌─────────────────────────────────────────────────────────────────┐
│                    ROLLOUT STAGES                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Week 1: Internal (1%)                                         │
│  ├─ Team members only                                          │
│  ├─ All telemetry at maximum verbosity                         │
│  ├─ Kill switch ready                                          │
│  └─ Goal: Catch catastrophic failures                          │
│                                                                 │
│  Week 2: Friends & Family (5%)                                 │
│  ├─ Trusted external users                                     │
│  ├─ Feedback channel established                               │
│  ├─ Daily metric review                                        │
│  └─ Goal: Validate telemetry pipeline, catch UX issues         │
│                                                                 │
│  Week 3: Early Adopters (25%)                                  │
│  ├─ Opt-in beta users                                          │
│  ├─ Statistical significance on metrics                        │
│  ├─ A/B test new vs old action system                          │
│  └─ Goal: Validate at scale, measure improvement               │
│                                                                 │
│  Week 4: General Availability (50%)                            │
│  ├─ Random 50% of user base                                    │
│  ├─ Monitor for infrastructure stress                          │
│  ├─ Prepare rollback if needed                                 │
│  └─ Goal: Stress test, final validation                        │
│                                                                 │
│  Week 5: Full Launch (100%)                                    │
│  ├─ All users                                                  │
│  ├─ Continue monitoring indefinitely                           │
│  ├─ Feedback loop to test fixtures                             │
│  └─ Goal: Continuous improvement                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 5.3 Kill Switch Criteria

Automatic rollback triggers (any of these):

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Action failure rate | >5% for 15 min | Disable new action system |
| Undo rate spike | >3x baseline for 1 hour | Alert + manual review |
| Crash rate | >0.5% | Automatic rollback |
| User complaints | >10 "wrong action" in 24h | Alert + manual review |
| Data loss report | Any confirmed incident | Immediate rollback |

## 5.4 Post-Launch Monitoring

```typescript
// packages/@zero/monitoring/src/alerts.ts

const POST_LAUNCH_ALERTS = [
  {
    name: 'acceptance_rate_drop',
    query: 'avg(acceptance_rate) over 1h',
    condition: '< 0.75',
    severity: 'critical',
    action: 'page_on_call'
  },
  {
    name: 'undo_rate_spike',
    query: 'avg(undo_rate) over 1h / baseline',
    condition: '> 2.0',
    severity: 'warning',
    action: 'slack_alert'
  },
  {
    name: 'calibration_drift',
    query: 'expected_calibration_error over 24h',
    condition: '> 0.15',
    severity: 'warning',
    action: 'create_ticket'
  },
  {
    name: 'new_failure_pattern',
    query: 'clustering(override_reasons) over 24h',
    condition: 'new_cluster_detected',
    severity: 'info',
    action: 'generate_fixtures'
  }
];
```

---

# Appendix: Agent Workflow Specifications

## A.1 Agent System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                  ZERO AGENT ECOSYSTEM                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐      │
│  │                 ORCHESTRATOR AGENT                    │      │
│  │                                                       │      │
│  │  Responsibilities:                                    │      │
│  │  • Route tasks to appropriate specialist agents       │      │
│  │  • Maintain project state across all agents          │      │
│  │  • Ensure cross-platform consistency                 │      │
│  │  • Aggregate results and report status               │      │
│  │                                                       │      │
│  │  State Management:                                    │      │
│  │  • Current sprint goals                              │      │
│  │  • Test suite status                                 │      │
│  │  • Platform parity checklist                         │      │
│  │  • Ship readiness score                              │      │
│  └───────────────────────────────────────────────────────┘      │
│                            │                                    │
│        ┌───────────────────┼───────────────────┐                │
│        │                   │                   │                │
│        ▼                   ▼                   ▼                │
│  ┌───────────┐       ┌───────────┐       ┌───────────┐         │
│  │  INTENT   │       │  NATIVE   │       │   TEST    │         │
│  │  AGENT    │       │  AGENT    │       │   AGENT   │         │
│  └───────────┘       └───────────┘       └───────────┘         │
│        │                   │                   │                │
│        ▼                   ▼                   ▼                │
│  ┌───────────┐       ┌───────────┐       ┌───────────┐         │
│  │ PLATFORM  │       │ TELEMETRY │       │    QA     │         │
│  │  AGENT    │       │  AGENT    │       │   AGENT   │         │
│  └───────────┘       └───────────┘       └───────────┘         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## A.2 Agent Specifications

### Intent Agent

```yaml
name: IntentAgent
purpose: Refine and improve intent classification system

capabilities:
  - Analyze classification failures
  - Tune confidence thresholds
  - Propose new rules
  - Identify edge cases from telemetry
  - Update ML feature extraction

inputs:
  - Test failure reports
  - Telemetry anomaly reports
  - User feedback on wrong actions
  
outputs:
  - Rule modifications
  - Threshold adjustments
  - New test fixtures
  - Feature engineering proposals

example_workflow:
  trigger: "Classification accuracy dropped below 95%"
  steps:
    1: Query telemetry for recent failures
    2: Group failures by pattern
    3: Identify root cause (rule, ML, or calibration)
    4: Propose fix with impact analysis
    5: Generate regression tests
    6: Submit PR for review
```

### Native Agent

```yaml
name: NativeAgent
purpose: Implement and maintain platform-specific code

capabilities:
  - Write Swift/Kotlin/React code
  - Integrate shared core on each platform
  - Implement platform-specific features
  - Handle native APIs (MailKit, WatchKit, etc.)

inputs:
  - Feature requirements
  - Shared core interface changes
  - Platform-specific bug reports
  
outputs:
  - Platform implementations
  - Native bridge code
  - Platform-specific tests

platforms:
  - iOS (SwiftUI)
  - WatchOS (SwiftUI)
  - Web (React)
  - Android (Compose) [future]
```

### Test Agent

```yaml
name: TestAgent
purpose: Generate, run, and maintain test suite

capabilities:
  - Generate fixtures from requirements
  - Generate fixtures from production failures
  - Run test suite and report results
  - Identify coverage gaps
  - Suggest fixture improvements

inputs:
  - Feature requirements
  - Production telemetry (failures)
  - Code changes (for regression detection)
  
outputs:
  - New test fixtures
  - Test run reports
  - Coverage analysis
  - Regression alerts

fixture_generation_rules:
  - Every new action type needs 10+ fixtures
  - Every bug fix needs regression test
  - Production failures become fixtures (anonymized)
  - Edge cases get explicit coverage
```

### Platform Agent

```yaml
name: PlatformAgent
purpose: Ensure feature parity across platforms

capabilities:
  - Compare implementations across platforms
  - Identify parity gaps
  - Design shared abstractions
  - Manage platform-specific workarounds

inputs:
  - Feature specifications
  - Platform implementations
  - User reports of inconsistency
  
outputs:
  - Parity reports
  - Shared abstraction designs
  - Platform capability matrix
  - Migration guides

parity_checks:
  - All 117 actions available on all platforms
  - Confidence thresholds identical
  - UI behavior consistent
  - Sync state consistent
```

### Telemetry Agent

```yaml
name: TelemetryAgent
purpose: Design and maintain telemetry infrastructure

capabilities:
  - Design event schemas
  - Build dashboards
  - Configure alerts
  - Detect anomalies
  - Generate reports

inputs:
  - Metric requirements
  - Alert configurations
  - Anomaly reports
  
outputs:
  - Event schema definitions
  - Dashboard configurations
  - Alert rules
  - Anomaly reports
  - Fixture candidates from production
```

### QA Agent

```yaml
name: QAAgent
purpose: Validate release readiness

capabilities:
  - Run comprehensive test suite
  - Perform regression analysis
  - Validate ship criteria
  - Generate ship/no-ship recommendation

inputs:
  - Release candidate
  - Ship criteria checklist
  - Test results
  - Telemetry metrics
  
outputs:
  - Ship readiness report
  - Blocking issues list
  - Risk assessment
  - Rollout recommendations

ship_criteria_evaluation:
  - All tests passing
  - No P0/P1 bugs open
  - Metrics within thresholds
  - Calibration acceptable
  - Platform parity confirmed
```

## A.3 Agent Communication Protocol

```typescript
// packages/@zero/agents/src/protocol.ts

interface AgentMessage {
  id: string;
  from: AgentId;
  to: AgentId | 'orchestrator';
  type: MessageType;
  payload: unknown;
  timestamp: Date;
  conversationId: string;  // For multi-turn exchanges
}

type MessageType =
  | 'task_request'
  | 'task_result'
  | 'status_update'
  | 'error'
  | 'clarification_needed'
  | 'approval_request';

interface TaskRequest {
  taskType: string;
  description: string;
  inputs: Record<string, unknown>;
  priority: 'low' | 'medium' | 'high' | 'critical';
  deadline?: Date;
}

interface TaskResult {
  taskId: string;
  status: 'success' | 'partial' | 'failed';
  outputs: Record<string, unknown>;
  artifacts?: string[];  // File paths
  nextSteps?: string[];
}

// Example: Adding a new action
const addActionWorkflow = {
  trigger: { type: 'user_request', content: 'Add Schedule Send action' },
  
  steps: [
    {
      agent: 'IntentAgent',
      task: 'Define intent triggers for schedule_send',
      output: 'intent_definition'
    },
    {
      agent: 'NativeAgent',
      task: 'Implement schedule_send on iOS',
      input: 'intent_definition',
      output: 'ios_implementation'
    },
    {
      agent: 'NativeAgent',
      task: 'Implement schedule_send on Web',
      input: 'intent_definition',
      output: 'web_implementation'
    },
    {
      agent: 'TestAgent',
      task: 'Generate fixtures for schedule_send',
      input: 'intent_definition',
      output: 'test_fixtures'
    },
    {
      agent: 'PlatformAgent',
      task: 'Verify parity',
      input: ['ios_implementation', 'web_implementation'],
      output: 'parity_report'
    },
    {
      agent: 'QAAgent',
      task: 'Run regression and validate',
      input: ['test_fixtures', 'parity_report'],
      output: 'ship_recommendation'
    }
  ]
};
```

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Jan 2026 | Rationale Studio | Initial document |

---

*This document is a living specification. Update as implementation progresses.*

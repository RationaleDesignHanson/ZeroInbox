import { IntentEngine } from '@zero/intent-engine';
import { ActionResolver } from '@zero/action-resolver';
import { ConfidenceScorer } from '@zero/confidence';
import type { EmailFixture } from '@zero/test-fixtures';
import type {
  ActionResolutionResult,
  IntentClassificationResult,
  ActionType,
  IntentType,
} from '@zero/core-types';

export interface TestResult {
  fixtureId: string;
  fixtureName: string;
  passed: boolean;
  expectedIntent: IntentType;
  expectedConfidenceRange: [number, number];
  expectedAction: ActionType;
  actualIntent: IntentType;
  actualConfidence: number;
  actualAction: ActionType;
  latencyMs: number;
  error?: string;
}

export interface TestSummary {
  totalTests: number;
  passed: number;
  failed: number;
  results: TestResult[];
}

export class ActionTestRunner {
  private readonly intentEngine = new IntentEngine();
  private readonly actionResolver = new ActionResolver();
  private readonly confidenceScorer = new ConfidenceScorer();

  async runFixture(fixture: EmailFixture): Promise<TestResult> {
    const start = performance.now ? performance.now() : Date.now();

    try {
      const intentResult = await this.intentEngine.classifyIntent({
        email: fixture.email,
        userSignals: [],
        threadContext: {
          participants: [fixture.email.from, ...fixture.email.to],
          hasUserReplied: false,
          questionCount: 0,
          actionItemCount: 0,
          lastUserReplyDate: undefined,
          urgencyIndicators: [],
        },
        temporalContext: {
          currentTime: new Date(),
          userTimezone: 'UTC',
          isWorkHours: true,
          dayOfWeek: new Date().getDay(),
          emailAge: 0,
        },
      });

      const actionResult = this.actionResolver.resolve({
        intent: intentResult as IntentClassificationResult,
        email: fixture.email,
        userPreferences: {
          defaultSnoozeTime: 30,
          archiveOrDelete: 'archive',
          confirmDestructive: true,
          quickReplyTemplates: [],
          folderMappings: [],
          autoLabels: [],
        },
        availableActions: [],
      }) as ActionResolutionResult;

      const confidence = this.confidenceScorer.calibrate(intentResult.confidence, {
        senderMetadata: fixture.email.senderMetadata,
        threadLength: fixture.email.threadLength,
        matchesUserPattern: false,
      });

      const latencyMs = (performance.now ? performance.now() : Date.now()) - start;

      const intentMatch = intentResult.primaryIntent.type === fixture.expectedIntent;
      const confidenceInRange =
        confidence.calibratedScore >= fixture.expectedConfidenceRange[0] &&
        confidence.calibratedScore <= fixture.expectedConfidenceRange[1];
      const actionMatch = actionResult.primaryAction.type === fixture.expectedAction;

      return {
        fixtureId: fixture.id,
        fixtureName: fixture.name,
        passed: intentMatch && confidenceInRange && actionMatch,
        expectedIntent: fixture.expectedIntent,
        expectedConfidenceRange: fixture.expectedConfidenceRange,
        expectedAction: fixture.expectedAction,
        actualIntent: intentResult.primaryIntent.type,
        actualConfidence: confidence.calibratedScore,
        actualAction: actionResult.primaryAction.type,
        latencyMs,
      };
    } catch (error: any) {
      return {
        fixtureId: fixture.id,
        fixtureName: fixture.name,
        passed: false,
        expectedIntent: fixture.expectedIntent,
        expectedConfidenceRange: fixture.expectedConfidenceRange,
        expectedAction: fixture.expectedAction,
        actualIntent: 'none',
        actualConfidence: 0,
        actualAction: 'archive',
        latencyMs: (performance.now ? performance.now() : Date.now()) - start,
        error: error?.message ?? String(error),
      };
    }
  }

  async runSuite(fixtures: EmailFixture[]): Promise<TestSummary> {
    const results = await Promise.all(fixtures.map((fixture) => this.runFixture(fixture)));
    const passed = results.filter((r) => r.passed).length;

    return {
      totalTests: results.length,
      passed,
      failed: results.length - passed,
      results,
    };
  }
}



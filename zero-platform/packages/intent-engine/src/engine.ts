import {
  type IntentClassificationInput,
  type IntentClassificationResult,
  type Intent,
  type UserSignal,
  type CalibrationContext,
} from '@zero/core-types';

type RuleResult = Intent & { weight: number };

interface IntentEngineConfig {
  defaultIntent?: Intent['type'];
  minConfidence?: number;
}

const DEFAULT_INTENT: Intent['type'] = 'none';

export class IntentEngine {
  private readonly defaultIntent: Intent['type'];
  private readonly minConfidence: number;

  constructor(config: IntentEngineConfig = {}) {
    this.defaultIntent = config.defaultIntent ?? DEFAULT_INTENT;
    this.minConfidence = config.minConfidence ?? 0.2;
  }

  async classifyIntent(input: IntentClassificationInput): Promise<IntentClassificationResult> {
    const start = performance.now ? performance.now() : Date.now();

    const ruleResults = this.applyRules(input);
    const primaryIntent = ruleResults[0] ?? this.fallbackIntent();
    const secondaryIntents = ruleResults.slice(1, 4);

    const confidence = this.calibrateConfidence(primaryIntent.confidence, {
      senderMetadata: input.email.senderMetadata,
      threadLength: input.email.threadLength,
      matchesUserPattern: this.matchesUserPattern(input.userSignals),
    });

    const reasoning = {
      primaryFactors: primaryIntent.triggers,
      negativeFactors: [],
      confidenceExplanation: `Rule weight ${primaryIntent.confidence.toFixed(2)}`,
    };

    const end = performance.now ? performance.now() : Date.now();

    return {
      primaryIntent,
      secondaryIntents,
      confidence: confidence.calibratedScore,
      reasoning,
      processingTimeMs: end - start,
    };
  }

  private applyRules(input: IntentClassificationInput): Intent[] {
    const results: RuleResult[] = [];
    const addRule = (intent: RuleResult) => {
      if (intent.confidence >= this.minConfidence) {
        results.push(intent);
      }
    };

    // Sender-based rule: newsletters → archive
    if (input.email.senderMetadata.senderCategory === 'newsletter') {
      addRule({
        type: 'archive',
        confidence: 0.85,
        triggers: ['sender:newsletter'],
        weight: 0.4,
      });
    }

    // Security signals
    if (input.email.subject.toLowerCase().includes('verification code')) {
      addRule({
        type: 'mark_read',
        confidence: 0.9,
        triggers: ['subject:verification code'],
        weight: 0.5,
      });
    }

    // Urgent keywords
    if (this.containsUrgency(input.email.subject)) {
      addRule({
        type: 'star',
        confidence: 0.75,
        triggers: ['subject:urgent'],
        weight: 0.35,
      });
    }

    // If nothing fired, return fallback
    if (results.length === 0) {
      return [this.fallbackIntent()];
    }

    // Sort by confidence then weight
    return results
      .sort((a, b) => b.confidence - a.confidence || b.weight - a.weight)
      .map(({ weight, ...intent }) => intent);
  }

  private containsUrgency(subject: string): boolean {
    const lowered = subject.toLowerCase();
    return ['urgent', 'asap', 'immediately', 'action required'].some((key) => lowered.includes(key));
  }

  private matchesUserPattern(signals: UserSignal[]): boolean {
    // Placeholder: if the user swiped consistently in same direction for recent signals.
    const swipeSignals = signals.filter((s) => s.type === 'swipe_direction');
    return swipeSignals.length >= 3;
  }

  private calibrateConfidence(rawScore: number, context: CalibrationContext) {
    let adjusted = rawScore;

    if (!context.senderMetadata.isContact) {
      adjusted *= 0.9;
    }
    if (context.threadLength > 10) {
      adjusted *= 0.85;
    }
    if (context.matchesUserPattern) {
      adjusted = Math.min(1, adjusted * 1.1);
    }

    return {
      rawScore,
      calibratedScore: adjusted,
    };
  }

  private fallbackIntent(): Intent {
    return {
      type: this.defaultIntent,
      confidence: 0.5,
      triggers: ['fallback'],
    };
  }
}



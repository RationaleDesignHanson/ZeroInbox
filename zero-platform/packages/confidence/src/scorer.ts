import {
  type ConfidenceCalibration,
  type CalibrationContext,
  type ConfidenceBucket,
} from '@zero/core-types';

export class ConfidenceScorer {
  calibrate(rawScore: number, context: CalibrationContext): ConfidenceCalibration {
    const calibrated = this.applyContextAdjustments(rawScore, context);
    const bucket = this.determineBucket(calibrated);

    return {
      rawScore,
      calibratedScore: calibrated,
      bucket,
      shouldShowAlternatives: bucket !== 'very_high',
      uncertaintyReason: this.explainUncertainty(rawScore, calibrated, context),
      context,
    };
  }

  private applyContextAdjustments(score: number, context: CalibrationContext): number {
    let adjusted = score;

    if (!context.senderMetadata.isContact) {
      adjusted *= 0.9;
    }

    if (context.threadLength > 10) {
      adjusted *= 0.85;
    }

    if (context.matchesUserPattern) {
      adjusted = Math.min(1, adjusted * 1.1);
    }

    return adjusted;
  }

  private determineBucket(score: number): ConfidenceBucket {
    if (score >= 0.95) return 'very_high';
    if (score >= 0.85) return 'high';
    if (score >= 0.7) return 'medium';
    if (score >= 0.5) return 'low';
    return 'uncertain';
  }

  private explainUncertainty(raw: number, calibrated: number, context: CalibrationContext): string | undefined {
    if (calibrated < 0.5) {
      return 'Low confidence due to sender reputation or long thread';
    }
    if (raw - calibrated > 0.1 && !context.senderMetadata.isContact) {
      return 'Adjusted down for unknown sender';
    }
    return undefined;
  }
}


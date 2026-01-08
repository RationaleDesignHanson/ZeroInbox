import type { CalibrationContext } from './intent';

export type ConfidenceBucket =
  | 'very_high' // >0.95 - Show single action, no alternatives
  | 'high' // 0.85-0.95 - Show primary + 1 alternative
  | 'medium' // 0.70-0.85 - Show primary + 2 alternatives
  | 'low' // 0.50-0.70 - Show grid of options
  | 'uncertain'; // <0.50 - Show full action menu

export interface ConfidenceCalibration {
  rawScore: number;
  calibratedScore: number;
  bucket: ConfidenceBucket;
  shouldShowAlternatives: boolean;
  uncertaintyReason?: string;
  context?: CalibrationContext;
}



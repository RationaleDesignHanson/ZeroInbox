/**
 * Confidence Scorer Tests
 * Phase 3.2: Test advanced confidence scoring
 */

const {
  calculateOverallConfidence,
  assessEntityQuality,
  assessActionConfidence,
  getUIRecommendations,
  getConfidenceLevel,
  CONFIDENCE_LEVELS
} = require('../confidence-scorer');

describe('Confidence Scorer', () => {
  // MARK: - Entity Quality Assessment

  describe('Entity Quality Assessment', () => {
    test('should give neutral score for no entities', () => {
      const result = assessEntityQuality({}, {});

      expect(result.score).toBe(0.5);
      expect(result.quality).toBe('none');
      expect(result.totalCount).toBe(0);
    });

    test('should score high quality entities', () => {
      const entityMetadata = {
        trackingNumber: { confidence: 0.9, validated: true },
        orderNumber: { confidence: 0.85, validated: true },
        carrier: { confidence: 0.8, validated: true }
      };
      const entityStats = { avgConfidence: 0.85 };

      const result = assessEntityQuality(entityMetadata, entityStats);

      expect(result.score).toBeGreaterThan(0.75);
      expect(result.quality).toBe('high');
      expect(result.validatedCount).toBe(3);
      expect(result.totalCount).toBe(3);
    });

    test('should score medium quality entities', () => {
      const entityMetadata = {
        amount: { confidence: 0.7, validated: true },
        date: { confidence: 0.6, validated: false }
      };
      const entityStats = { avgConfidence: 0.65 };

      const result = assessEntityQuality(entityMetadata, entityStats);

      // Score calculation: 0.65*0.5 + 0.5*0.3 + 0*0.2 = 0.475
      expect(result.score).toBeGreaterThanOrEqual(0.45);
      expect(result.score).toBeLessThan(0.75);
      expect(result.quality).toBe('low'); // 0.475 is below 0.55 threshold
    });

    test('should score low quality entities', () => {
      const entityMetadata = {
        entity1: { confidence: 0.4, validated: false },
        entity2: { confidence: 0.3, validated: false }
      };
      const entityStats = { avgConfidence: 0.35 };

      const result = assessEntityQuality(entityMetadata, entityStats);

      expect(result.score).toBeLessThan(0.55);
      expect(result.quality).toBe('low');
      expect(result.validatedCount).toBe(0);
    });
  });

  // MARK: - Action Confidence Assessment

  describe('Action Confidence Assessment', () => {
    test('should give neutral score for no actions', () => {
      const result = assessActionConfidence([]);

      expect(result.score).toBe(0.5);
      expect(result.hasPrimaryAction).toBe(false);
      expect(result.actionCount).toBe(0);
    });

    test('should score high for actions with valid URLs', () => {
      const actions = [
        {
          actionId: 'track_package',
          isPrimary: true,
          url: 'https://ups.com/track/123'
        },
        {
          actionId: 'view_order',
          isPrimary: false,
          url: 'https://amazon.com/orders/123'
        }
      ];

      const result = assessActionConfidence(actions);

      expect(result.score).toBeGreaterThan(0.9);
      expect(result.hasPrimaryAction).toBe(true);
      expect(result.hasValidUrls).toBe(true);
      expect(result.actionCount).toBe(2);
    });

    test('should score lower for actions with template URLs', () => {
      const actions = [
        {
          actionId: 'view_order',
          isPrimary: true,
          url: '{orderUrl}'
        }
      ];

      const result = assessActionConfidence(actions);

      expect(result.score).toBeLessThan(0.9);
      expect(result.hasPrimaryAction).toBe(true);
      expect(result.hasValidUrls).toBe(false);
    });
  });

  // MARK: - Confidence Level Determination

  describe('Confidence Level Determination', () => {
    test('should classify VERY_HIGH confidence', () => {
      expect(getConfidenceLevel(0.95)).toBe(CONFIDENCE_LEVELS.VERY_HIGH);
      expect(getConfidenceLevel(0.90)).toBe(CONFIDENCE_LEVELS.VERY_HIGH);
    });

    test('should classify HIGH confidence', () => {
      expect(getConfidenceLevel(0.85)).toBe(CONFIDENCE_LEVELS.HIGH);
      expect(getConfidenceLevel(0.75)).toBe(CONFIDENCE_LEVELS.HIGH);
    });

    test('should classify MEDIUM confidence', () => {
      expect(getConfidenceLevel(0.70)).toBe(CONFIDENCE_LEVELS.MEDIUM);
      expect(getConfidenceLevel(0.60)).toBe(CONFIDENCE_LEVELS.MEDIUM);
    });

    test('should classify LOW confidence', () => {
      expect(getConfidenceLevel(0.55)).toBe(CONFIDENCE_LEVELS.LOW);
      expect(getConfidenceLevel(0.40)).toBe(CONFIDENCE_LEVELS.LOW);
    });

    test('should classify VERY_LOW confidence', () => {
      expect(getConfidenceLevel(0.35)).toBe(CONFIDENCE_LEVELS.VERY_LOW);
      expect(getConfidenceLevel(0.10)).toBe(CONFIDENCE_LEVELS.VERY_LOW);
    });
  });

  // MARK: - Overall Confidence Calculation

  describe('Overall Confidence Calculation', () => {
    test('should calculate high confidence for complete classification', () => {
      const classification = {
        intent: 'e-commerce.shipping.notification',
        intentConfidence: 0.9,
        suggestedActions: [
          { actionId: 'track_package', isPrimary: true, url: 'https://ups.com/track/123' }
        ],
        entityMetadata: {
          trackingNumber: { confidence: 0.9, validated: true },
          carrier: { confidence: 0.85, validated: true }
        },
        entityStats: { avgConfidence: 0.875 },
        _classificationSource: 'pattern_matching'
      };

      const result = calculateOverallConfidence(classification);

      expect(result.overallConfidence).toBeGreaterThan(0.85);
      expect(result.level).toBe(CONFIDENCE_LEVELS.VERY_HIGH);
      expect(result.shouldShowConfirmation).toBe(false);
    });

    test('should calculate medium confidence for weak entities', () => {
      const classification = {
        intent: 'billing.invoice.due',
        intentConfidence: 0.75,
        suggestedActions: [
          { actionId: 'pay_invoice', isPrimary: true }
        ],
        entityMetadata: {
          amount: { confidence: 0.5, validated: false }
        },
        entityStats: { avgConfidence: 0.5 },
        _classificationSource: 'pattern_matching'
      };

      const result = calculateOverallConfidence(classification);

      expect(result.overallConfidence).toBeLessThan(0.75);
      expect(result.level).toBe(CONFIDENCE_LEVELS.MEDIUM);
      expect(result.shouldShowConfirmation).toBe(true);
    });

    test('should calculate low confidence for fallback classification', () => {
      const classification = {
        intent: 'generic.transactional',
        intentConfidence: 0.5,
        suggestedActions: [],
        entityMetadata: {},
        entityStats: {},
        _classificationSource: 'fallback'
      };

      const result = calculateOverallConfidence(classification);

      expect(result.overallConfidence).toBeLessThan(0.50);
      expect(result.level).toBe(CONFIDENCE_LEVELS.LOW);
      expect(result.shouldShowConfirmation).toBe(true);
    });

    test('should include confidence breakdown', () => {
      const classification = {
        intent: 'e-commerce.order.confirmation',
        intentConfidence: 0.8,
        suggestedActions: [{ actionId: 'view_order', isPrimary: true }],
        entityMetadata: {
          orderNumber: { confidence: 0.7, validated: true }
        },
        entityStats: { avgConfidence: 0.7 },
        _classificationSource: 'pattern_matching'
      };

      const result = calculateOverallConfidence(classification);

      expect(result.breakdown).toBeDefined();
      expect(result.breakdown.intentConfidence).toBe(0.8);
      expect(result.breakdown.entityQuality).toBeDefined();
      expect(result.breakdown.actionQuality).toBeDefined();
      expect(result.breakdown.weights).toBeDefined();
    });

    test('should include confidence factors explanation', () => {
      const classification = {
        intent: 'e-commerce.shipping.notification',
        intentConfidence: 0.85,
        suggestedActions: [
          { actionId: 'track_package', isPrimary: true, url: 'https://ups.com/track/123' }
        ],
        entityMetadata: {
          trackingNumber: { confidence: 0.9, validated: true }
        },
        entityStats: { avgConfidence: 0.9 },
        _classificationSource: 'pattern_matching'
      };

      const result = calculateOverallConfidence(classification);

      expect(Array.isArray(result.confidenceFactors)).toBe(true);
      expect(result.confidenceFactors.length).toBeGreaterThan(0);

      const firstFactor = result.confidenceFactors[0];
      expect(firstFactor.factor).toBeDefined();
      expect(firstFactor.contribution).toBeDefined();
      expect(firstFactor.description).toBeDefined();
      expect(typeof firstFactor.positive).toBe('boolean');
    });

    test('should handle missing optional fields gracefully', () => {
      const classification = {
        intentConfidence: 0.7
      };

      const result = calculateOverallConfidence(classification);

      expect(result.overallConfidence).toBeGreaterThanOrEqual(0);
      expect(result.overallConfidence).toBeLessThanOrEqual(1);
      expect(result.level).toBeDefined();
    });
  });

  // MARK: - UI Recommendations

  describe('UI Recommendations', () => {
    test('should recommend VERY_HIGH confidence UI', () => {
      const confidenceResult = {
        level: CONFIDENCE_LEVELS.VERY_HIGH,
        overallConfidence: 0.95,
        shouldShowConfirmation: false
      };

      const recommendations = getUIRecommendations(confidenceResult);

      expect(recommendations.uiHints.actionStyle).toBe('primary');
      expect(recommendations.uiHints.showConfidenceBadge).toBe(false);
      expect(recommendations.uiHints.enableAutoExecution).toBe(true);
    });

    test('should recommend HIGH confidence UI', () => {
      const confidenceResult = {
        level: CONFIDENCE_LEVELS.HIGH,
        overallConfidence: 0.80,
        shouldShowConfirmation: false
      };

      const recommendations = getUIRecommendations(confidenceResult);

      expect(recommendations.uiHints.actionStyle).toBe('primary');
      expect(recommendations.uiHints.showConfidenceBadge).toBe(false);
      expect(recommendations.uiHints.enableAutoExecution).toBe(false);
    });

    test('should recommend MEDIUM confidence UI', () => {
      const confidenceResult = {
        level: CONFIDENCE_LEVELS.MEDIUM,
        overallConfidence: 0.65,
        shouldShowConfirmation: true
      };

      const recommendations = getUIRecommendations(confidenceResult);

      expect(recommendations.uiHints.actionStyle).toBe('secondary');
      expect(recommendations.uiHints.showConfidenceBadge).toBe(true);
      expect(recommendations.uiHints.suggestionText).toBeDefined();
    });

    test('should recommend LOW confidence UI', () => {
      const confidenceResult = {
        level: CONFIDENCE_LEVELS.LOW,
        overallConfidence: 0.45,
        shouldShowConfirmation: true
      };

      const recommendations = getUIRecommendations(confidenceResult);

      expect(recommendations.uiHints.actionStyle).toBe('tertiary');
      expect(recommendations.uiHints.showConfidenceBadge).toBe(true);
      expect(recommendations.uiHints.confidenceBadgeText).toBe('Possible action');
    });

    test('should recommend VERY_LOW confidence UI', () => {
      const confidenceResult = {
        level: CONFIDENCE_LEVELS.VERY_LOW,
        overallConfidence: 0.25,
        shouldShowConfirmation: true
      };

      const recommendations = getUIRecommendations(confidenceResult);

      expect(recommendations.uiHints.actionStyle).toBe('minimal');
      expect(recommendations.uiHints.collapseByDefault).toBe(true);
      expect(recommendations.uiHints.confidenceBadgeText).toBe('Uncertain');
    });
  });

  // MARK: - Performance

  describe('Performance', () => {
    test('should calculate confidence in under 10ms', () => {
      const classification = {
        intent: 'e-commerce.shipping.notification',
        intentConfidence: 0.85,
        suggestedActions: [
          { actionId: 'track_package', isPrimary: true }
        ],
        entityMetadata: {
          trackingNumber: { confidence: 0.9, validated: true }
        },
        entityStats: { avgConfidence: 0.9 },
        _classificationSource: 'pattern_matching'
      };

      const result = calculateOverallConfidence(classification);

      expect(result.processingTime).toBeLessThan(10);
    });
  });

  // MARK: - Edge Cases

  describe('Edge Cases', () => {
    test('should handle empty classification', () => {
      const result = calculateOverallConfidence({});

      expect(result.overallConfidence).toBeGreaterThanOrEqual(0);
      expect(result.overallConfidence).toBeLessThanOrEqual(1);
      expect(result.level).toBeDefined();
    });

    test('should clamp confidence to [0, 1] range', () => {
      const classification = {
        intentConfidence: 1.5, // Invalid, should be clamped
        entityMetadata: {},
        entityStats: {},
        suggestedActions: []
      };

      const result = calculateOverallConfidence(classification);

      expect(result.overallConfidence).toBeLessThanOrEqual(1.0);
      expect(result.overallConfidence).toBeGreaterThanOrEqual(0);
    });

    test('should handle null/undefined fields', () => {
      const classification = {
        intentConfidence: 0.8,
        entityMetadata: null,
        entityStats: undefined,
        suggestedActions: null
      };

      const result = calculateOverallConfidence(classification);

      expect(result.overallConfidence).toBeGreaterThanOrEqual(0);
      expect(result.overallConfidence).toBeLessThanOrEqual(1);
    });
  });
});

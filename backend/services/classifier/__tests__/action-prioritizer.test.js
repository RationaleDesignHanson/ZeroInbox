/**
 * Action Prioritizer Tests
 * Phase 3.3: Test contextual action prioritization
 */

const {
  prioritizeActions,
  explainPrioritization,
  getTimePeriod,
  TIME_PERIODS,
  calculateEntityReadiness,
  getTimeAffinityBoost,
  getActionTypeBoost,
  getUrgencyBoost
} = require('../action-prioritizer');

describe('Action Prioritizer', () => {
  // MARK: - Time Period Detection

  describe('Time Period Detection', () => {
    test('should detect early morning (5am-9am)', () => {
      const morning7am = new Date('2025-01-01T07:00:00');
      expect(getTimePeriod(morning7am)).toBe(TIME_PERIODS.EARLY_MORNING);
    });

    test('should detect morning (9am-12pm)', () => {
      const morning10am = new Date('2025-01-01T10:00:00');
      expect(getTimePeriod(morning10am)).toBe(TIME_PERIODS.MORNING);
    });

    test('should detect afternoon (12pm-5pm)', () => {
      const afternoon2pm = new Date('2025-01-01T14:00:00');
      expect(getTimePeriod(afternoon2pm)).toBe(TIME_PERIODS.AFTERNOON);
    });

    test('should detect evening (5pm-9pm)', () => {
      const evening7pm = new Date('2025-01-01T19:00:00');
      expect(getTimePeriod(evening7pm)).toBe(TIME_PERIODS.EVENING);
    });

    test('should detect night (9pm-5am)', () => {
      const night11pm = new Date('2025-01-01T23:00:00');
      expect(getTimePeriod(night11pm)).toBe(TIME_PERIODS.NIGHT);
    });
  });

  // MARK: - Entity Readiness

  describe('Entity Readiness Calculation', () => {
    test('should score perfect readiness when all entities available', () => {
      const action = {
        actionId: 'track_package',
        requiredEntities: ['trackingNumber', 'carrier']
      };

      const entityMetadata = {
        trackingNumber: { confidence: 0.9 },
        carrier: { confidence: 0.8 }
      };

      const result = calculateEntityReadiness(action, entityMetadata);

      expect(result.ready).toBe(true);
      expect(result.availableCount).toBe(2);
      expect(result.totalCount).toBe(2);
      expect(result.score).toBeGreaterThan(0.8);
    });

    test('should score partial readiness when some entities missing', () => {
      const action = {
        actionId: 'pay_invoice',
        requiredEntities: ['invoiceId', 'amount', 'paymentUrl']
      };

      const entityMetadata = {
        invoiceId: { confidence: 0.9 },
        amount: { confidence: 0.8 }
        // paymentUrl missing
      };

      const result = calculateEntityReadiness(action, entityMetadata);

      expect(result.ready).toBe(false);
      expect(result.availableCount).toBe(2);
      expect(result.totalCount).toBe(3);
      expect(result.score).toBeLessThan(0.8);
    });

    test('should handle actions with no required entities', () => {
      const action = {
        actionId: 'quick_reply',
        requiredEntities: []
      };

      const result = calculateEntityReadiness(action, {});

      expect(result.ready).toBe(true);
      expect(result.score).toBe(1.0);
    });
  });

  // MARK: - Time Affinity Boosts

  describe('Time Affinity Boosts', () => {
    test('should boost booking actions in morning', () => {
      const boost = getTimeAffinityBoost('book_appointment', TIME_PERIODS.MORNING);
      expect(boost).toBeGreaterThan(0.9);
    });

    test('should boost food orders in evening', () => {
      const boost = getTimeAffinityBoost('order_food', TIME_PERIODS.EVENING);
      expect(boost).toBeGreaterThan(0.9);
    });

    test('should use default affinity for unknown actions', () => {
      const boost = getTimeAffinityBoost('unknown_action', TIME_PERIODS.AFTERNOON);
      expect(boost).toBeGreaterThan(0);
      expect(boost).toBeLessThanOrEqual(1.0);
    });
  });

  // MARK: - Action Type Boosts

  describe('Action Type Boosts', () => {
    test('should boost IN_APP actions', () => {
      const boost = getActionTypeBoost('IN_APP');
      expect(boost).toBeGreaterThan(1.0);
    });

    test('should boost QUICK_REPLY actions', () => {
      const boost = getActionTypeBoost('QUICK_REPLY');
      expect(boost).toBeGreaterThan(1.0);
    });

    test('should be neutral for GO_TO actions', () => {
      const boost = getActionTypeBoost('GO_TO');
      expect(boost).toBe(1.0);
    });
  });

  // MARK: - Urgency Boosts

  describe('Urgency Boosts', () => {
    test('should boost urgent actions', () => {
      const boost = getUrgencyBoost(true);
      expect(boost).toBeGreaterThan(1.0);
    });

    test('should be neutral for non-urgent', () => {
      const boost = getUrgencyBoost(false);
      expect(boost).toBe(1.0);
    });
  });

  // MARK: - Full Prioritization

  describe('Full Action Prioritization', () => {
    test('should re-rank actions based on context', () => {
      const actions = [
        {
          actionId: 'view_order',
          displayName: 'View Order',
          actionType: 'GO_TO',
          priority: 2,
          isPrimary: false,
          requiredEntities: []
        },
        {
          actionId: 'track_package',
          displayName: 'Track Package',
          actionType: 'GO_TO',
          priority: 1,
          isPrimary: true,
          requiredEntities: ['trackingNumber']
        },
        {
          actionId: 'quick_reply',
          displayName: 'Quick Reply',
          actionType: 'QUICK_REPLY',
          priority: 3,
          isPrimary: false,
          requiredEntities: []
        }
      ];

      const context = {
        entityMetadata: {
          trackingNumber: { confidence: 0.9 }
        },
        isUrgent: false,
        timePeriod: TIME_PERIODS.AFTERNOON
      };

      const result = prioritizeActions(actions, context);

      expect(Array.isArray(result)).toBe(true);
      expect(result.length).toBe(3);

      // Check that actions have priority scores
      result.forEach(action => {
        expect(action._priorityScore).toBeDefined();
        expect(action._priorityFactors).toBeDefined();
      });

      // Check that priorities were updated
      expect(result[0].priority).toBe(1);
      expect(result[1].priority).toBe(2);
      expect(result[2].priority).toBe(3);

      // First action should be marked as primary
      expect(result[0].isPrimary).toBe(true);
    });

    test('should prioritize entity-ready actions higher', () => {
      const actions = [
        {
          actionId: 'pay_invoice',
          displayName: 'Pay Invoice',
          actionType: 'IN_APP',
          priority: 1,
          isPrimary: true,
          requiredEntities: ['invoiceId', 'amount']
        },
        {
          actionId: 'view_invoice',
          displayName: 'View Invoice',
          actionType: 'GO_TO',
          priority: 2,
          isPrimary: false,
          requiredEntities: []  // No requirements
        }
      ];

      const context = {
        entityMetadata: {
          // Missing invoiceId and amount
        },
        isUrgent: false,
        timePeriod: TIME_PERIODS.MORNING
      };

      const result = prioritizeActions(actions, context);

      // view_invoice (no requirements) should rank higher than pay_invoice (missing entities)
      // Even though pay_invoice was originally primary
      expect(result[0].actionId).toBe('view_invoice');
    });

    test('should boost urgent actions', () => {
      const actions = [
        {
          actionId: 'check_in_flight',
          displayName: 'Check In',
          actionType: 'GO_TO',
          priority: 1,
          isPrimary: true,
          requiredEntities: []
        },
        {
          actionId: 'quick_reply',
          displayName: 'Reply',
          actionType: 'QUICK_REPLY',
          priority: 2,
          isPrimary: false,
          requiredEntities: []
        }
      ];

      const urgentContext = {
        isUrgent: true,
        timePeriod: TIME_PERIODS.MORNING
      };

      const normalContext = {
        isUrgent: false,
        timePeriod: TIME_PERIODS.MORNING
      };

      const urgentResult = prioritizeActions(actions, urgentContext);
      const normalResult = prioritizeActions(actions, normalContext);

      // Urgent context should give higher scores
      expect(urgentResult[0]._priorityScore).toBeGreaterThan(normalResult[0]._priorityScore);
    });

    test('should handle empty actions array', () => {
      const result = prioritizeActions([], {});
      expect(result).toEqual([]);
    });

    test('should handle missing context', () => {
      const actions = [
        {
          actionId: 'test',
          actionType: 'IN_APP',
          priority: 1,
          isPrimary: true
        }
      ];

      const result = prioritizeActions(actions);
      expect(result.length).toBe(1);
      expect(result[0]._priorityScore).toBeDefined();
    });
  });

  // MARK: - Explanation

  describe('Prioritization Explanation', () => {
    test('should generate explanation for prioritized action', () => {
      const action = {
        actionId: 'test',
        _priorityFactors: {
          baseScore: 1.0,
          timeBoost: 0.9,
          entityReadiness: 0.8,
          entityReady: true,
          typeBoost: 1.1,
          urgencyBoost: 1.0,
          primaryBoost: 1.2
        }
      };

      const explanation = explainPrioritization(action);

      expect(typeof explanation).toBe('string');
      expect(explanation).toContain('Base:');
      expect(explanation).toContain('Time:');
      expect(explanation).toContain('Entities:');
      expect(explanation).toContain('ready');
    });

    test('should handle action without prioritization data', () => {
      const action = {
        actionId: 'test'
      };

      const explanation = explainPrioritization(action);
      expect(explanation).toContain('No prioritization data');
    });
  });

  // MARK: - Real-world Scenarios

  describe('Real-world Scenarios', () => {
    test('should prioritize food order in evening', () => {
      const actions = [
        {
          actionId: 'view_menu',
          actionType: 'GO_TO',
          priority: 2,
          isPrimary: false,
          requiredEntities: []
        },
        {
          actionId: 'order_food',
          actionType: 'IN_APP',
          priority: 1,
          isPrimary: true,
          requiredEntities: ['restaurant']
        }
      ];

      const context = {
        entityMetadata: {
          restaurant: { confidence: 0.9 }
        },
        timePeriod: TIME_PERIODS.EVENING
      };

      const result = prioritizeActions(actions, context);

      // order_food should be top due to evening time + IN_APP + entity ready
      expect(result[0].actionId).toBe('order_food');
    });

    test('should prioritize appointment booking in morning', () => {
      const actions = [
        {
          actionId: 'view_details',
          actionType: 'GO_TO',
          priority: 2,
          isPrimary: false,
          requiredEntities: []
        },
        {
          actionId: 'book_appointment',
          actionType: 'IN_APP',
          priority: 1,
          isPrimary: true,
          requiredEntities: ['dateTime', 'provider']
        }
      ];

      const context = {
        entityMetadata: {
          dateTime: { confidence: 0.9 },
          provider: { confidence: 0.85 }
        },
        timePeriod: TIME_PERIODS.MORNING
      };

      const result = prioritizeActions(actions, context);

      // book_appointment should rank high in morning with all entities
      expect(result[0].actionId).toBe('book_appointment');
      expect(result[0]._priorityFactors.entityReady).toBe(true);
    });
  });
});

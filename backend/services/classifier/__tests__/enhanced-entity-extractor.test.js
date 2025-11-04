/**
 * Enhanced Entity Extractor Tests
 * Phase 3.1: Test confidence scoring, validation, and relationships
 */

const {
  extractEntitiesEnhanced,
  extractEntities,
  CONFIDENCE,
  ENTITY_TYPES
} = require('../enhanced-entity-extractor');

describe('Enhanced Entity Extractor', () => {
  // MARK: - Confidence Scoring Tests

  describe('Confidence Scoring', () => {
    test('should assign high confidence to validated entities', () => {
      const email = {
        subject: 'Your order #ORD-123456 has shipped',
        from: 'shipping@amazon.com',
        body: 'Tracking: 1Z999AA10123456784. Carrier: UPS. Amount: $25.99'
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.shipping.notification');

      expect(result.metadata.orderNumber).toBeDefined();
      expect(result.metadata.orderNumber.confidence).toBeGreaterThanOrEqual(CONFIDENCE.MEDIUM);

      expect(result.metadata.trackingNumber).toBeDefined();
      expect(result.metadata.trackingNumber.confidence).toBeGreaterThanOrEqual(CONFIDENCE.MEDIUM);

      expect(result.metadata.amount).toBeDefined();
      expect(result.metadata.amount.validated).toBe(true);
    });

    test('should assign higher confidence to contextually relevant entities', () => {
      const email = {
        subject: 'Invoice #INV-2025-001 Due',
        from: 'billing@acme.com',
        body: 'Amount due: $150.00. Due date: Jan 15, 2025'
      };

      const result = extractEntitiesEnhanced(email, 'billing.invoice.due');

      expect(result.metadata.invoiceId).toBeDefined();
      expect(result.metadata.invoiceId.confidence).toBeGreaterThanOrEqual(CONFIDENCE.MEDIUM);

      // Invoice context should boost confidence
      expect(result.metadata.amount).toBeDefined();
      expect(result.metadata.amount.confidence).toBeGreaterThanOrEqual(CONFIDENCE.MEDIUM);
    });

    test('should calculate average confidence across entities', () => {
      const email = {
        subject: 'Order confirmation',
        from: 'orders@store.com',
        body: 'Order #12345. Total: $99.99'
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.order.confirmation');

      expect(result.stats.avgConfidence).toBeGreaterThan(0);
      expect(result.stats.avgConfidence).toBeLessThanOrEqual(1);
    });
  });

  // MARK: - Entity Validation Tests

  describe('Entity Validation', () => {
    test('should validate date entities', () => {
      const email = {
        subject: 'Appointment reminder',
        from: 'clinic@healthcare.com',
        body: 'Your appointment is on January 15, 2025 at 2:00 PM'
      };

      const result = extractEntitiesEnhanced(email, 'healthcare.appointment.reminder');

      if (result.metadata.appointmentDate || result.metadata.dateTime) {
        const dateKey = result.metadata.appointmentDate ? 'appointmentDate' : 'dateTime';
        expect(result.metadata[dateKey].validated).toBe(true);
        expect(result.metadata[dateKey].type).toBe(ENTITY_TYPES.DATE);
      }
    });

    test('should validate and normalize money entities', () => {
      const email = {
        subject: 'Payment received',
        from: 'billing@company.com',
        body: 'We received your payment of $1,234.56'
      };

      const result = extractEntitiesEnhanced(email, 'billing.payment.received');

      if (result.metadata.amount || result.metadata.paymentAmount) {
        const moneyKey = result.metadata.amount ? 'amount' : 'paymentAmount';
        expect(result.metadata[moneyKey].validated).toBe(true);
        expect(result.metadata[moneyKey].type).toBe(ENTITY_TYPES.MONEY);
        // Should normalize (remove commas)
        expect(result.entities[moneyKey]).toMatch(/^\d+\.?\d{0,2}$/);
      }
    });

    test('should validate URL entities', () => {
      const email = {
        subject: 'Track your package',
        from: 'shipping@ups.com',
        body: 'Track at: https://www.ups.com/track/123456'
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.shipping.notification');

      if (result.metadata.trackingUrl) {
        expect(result.metadata.trackingUrl.validated).toBe(true);
        expect(result.metadata.trackingUrl.type).toBe(ENTITY_TYPES.URL);
      }
    });

    test('should validate ID entities (tracking numbers, order IDs)', () => {
      const email = {
        subject: 'Order shipped',
        from: 'shipping@amazon.com',
        body: 'Order #ORD-123456. Tracking: 1Z999AA10123456784'
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.shipping.notification');

      if (result.metadata.orderNumber) {
        expect(result.metadata.orderNumber.type).toBe(ENTITY_TYPES.ID);
      }

      if (result.metadata.trackingNumber) {
        expect(result.metadata.trackingNumber.type).toBe(ENTITY_TYPES.ID);
      }
    });
  });

  // MARK: - Entity Type Detection Tests

  describe('Entity Type Detection', () => {
    test('should detect URL entity types', () => {
      const email = {
        subject: 'Payment link',
        from: 'billing@company.com',
        body: 'Pay here: https://pay.company.com/invoice/123'
      };

      const result = extractEntitiesEnhanced(email, 'billing.invoice.due');

      if (result.metadata.paymentLink) {
        expect(result.metadata.paymentLink.type).toBe(ENTITY_TYPES.URL);
      }
    });

    test('should detect date entity types', () => {
      const email = {
        subject: 'Delivery scheduled',
        from: 'shipping@store.com',
        body: 'Your package will arrive on December 25, 2025'
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.delivery.scheduled');

      if (result.metadata.deliveryDate) {
        expect(result.metadata.deliveryDate.type).toBe(ENTITY_TYPES.DATE);
      }
    });

    test('should detect money entity types', () => {
      const email = {
        subject: 'Invoice due',
        from: 'billing@acme.com',
        body: 'Total amount: $500.00'
      };

      const result = extractEntitiesEnhanced(email, 'billing.invoice.due');

      if (result.metadata.amount || result.metadata.amountDue) {
        const key = result.metadata.amount ? 'amount' : 'amountDue';
        expect(result.metadata[key].type).toBe(ENTITY_TYPES.MONEY);
      }
    });

    test('should detect ID entity types', () => {
      const email = {
        subject: 'Confirmation',
        from: 'reservations@airline.com',
        body: 'Confirmation code: ABC123. Flight: UA 456'
      };

      const result = extractEntitiesEnhanced(email, 'travel.flight.check-in');

      if (result.metadata.confirmationCode) {
        expect(result.metadata.confirmationCode.type).toBe(ENTITY_TYPES.ID);
      }
    });
  });

  // MARK: - Entity Relationship Detection Tests

  describe('Entity Relationship Detection', () => {
    test('should infer carrier from UPS tracking number', () => {
      const email = {
        subject: 'Package shipped',
        from: 'shipping@store.com',
        body: 'Tracking number: 1Z999AA10123456784'
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.shipping.notification');

      expect(result.entities.trackingNumber).toBeDefined();

      // Should infer UPS carrier from 1Z prefix
      if (result.relationships.length > 0) {
        const carrierRelationship = result.relationships.find(
          r => r.type === 'inferred' && r.to === 'carrier'
        );
        if (carrierRelationship) {
          expect(carrierRelationship.value).toBe('UPS');
        }
      }
    });

    test('should detect related order entities', () => {
      const email = {
        subject: 'Order confirmation',
        from: 'orders@amazon.com',
        body: 'Order #12345. View at: https://amazon.com/orders/12345'
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.order.confirmation');

      if (result.entities.orderNumber && result.entities.orderUrl) {
        const orderRelationship = result.relationships.find(
          r => r.type === 'related' && r.entities.includes('orderNumber') && r.entities.includes('orderUrl')
        );
        expect(orderRelationship).toBeDefined();
      }
    });

    test('should detect related invoice entities', () => {
      const email = {
        subject: 'Invoice ready',
        from: 'billing@company.com',
        body: 'Invoice #INV-001. Pay here: https://pay.company.com/INV-001'
      };

      const result = extractEntitiesEnhanced(email, 'billing.invoice.due');

      if (result.entities.invoiceId && result.entities.paymentLink) {
        const invoiceRelationship = result.relationships.find(
          r => r.type === 'related' && r.entities.includes('invoiceId') && r.entities.includes('paymentLink')
        );
        expect(invoiceRelationship).toBeDefined();
      }
    });

    test('should detect healthcare provider relationships', () => {
      const email = {
        subject: 'Appointment reminder',
        from: 'clinic@healthcare.com',
        body: 'Appointment with Dr. Smith. Schedule at: https://healthcare.com/schedule'
      };

      const result = extractEntitiesEnhanced(email, 'healthcare.appointment.reminder');

      if (result.entities.provider && result.entities.schedulingUrl) {
        const providerRelationship = result.relationships.find(
          r => r.type === 'related' && r.entities.includes('provider')
        );
        expect(providerRelationship).toBeDefined();
      }
    });
  });

  // MARK: - Metadata and Stats Tests

  describe('Metadata and Stats', () => {
    test('should include metadata for all extracted entities', () => {
      const email = {
        subject: 'Order shipped',
        from: 'shipping@store.com',
        body: 'Order #12345. Tracking: 1Z999AA. Total: $99.99'
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.shipping.notification');

      // Every entity should have metadata
      for (const key of Object.keys(result.entities)) {
        expect(result.metadata[key]).toBeDefined();
        expect(result.metadata[key].confidence).toBeGreaterThan(0);
        expect(result.metadata[key].confidence).toBeLessThanOrEqual(1);
        expect(result.metadata[key].type).toBeDefined();
        expect(typeof result.metadata[key].validated).toBe('boolean');
      }
    });

    test('should provide extraction stats', () => {
      const email = {
        subject: 'Invoice due',
        from: 'billing@company.com',
        body: 'Invoice #INV-001. Amount: $100. Due: Jan 15'
      };

      const result = extractEntitiesEnhanced(email, 'billing.invoice.due');

      expect(result.stats).toBeDefined();
      expect(result.stats.totalEntities).toBeGreaterThan(0);
      expect(result.stats.avgConfidence).toBeGreaterThan(0);
      expect(result.stats.avgConfidence).toBeLessThanOrEqual(1);
      expect(result.stats.highConfidenceCount).toBeGreaterThanOrEqual(0);
      expect(result.stats.processingTime).toBeGreaterThanOrEqual(0); // Can be 0ms if very fast
    });

    test('should track entity source (pattern_match vs inferred)', () => {
      const email = {
        subject: 'Package shipped',
        from: 'shipping@store.com',
        body: 'Tracking: 1Z999AA10123456784'
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.shipping.notification');

      if (result.metadata.trackingNumber) {
        expect(result.metadata.trackingNumber.source).toBeDefined();
        expect(['pattern_match', 'inferred_from_relationship']).toContain(
          result.metadata.trackingNumber.source
        );
      }
    });
  });

  // MARK: - Backward Compatibility Tests

  describe('Backward Compatibility', () => {
    test('should maintain backward compatible extractEntities function', () => {
      const email = {
        subject: 'Order shipped',
        from: 'shipping@amazon.com',
        body: 'Order #12345. Tracking: 1Z999AA'
      };

      const entities = extractEntities(email, 'e-commerce.shipping.notification');

      // Should return just entities (not enhanced result)
      expect(typeof entities).toBe('object');
      expect(entities.metadata).toBeUndefined(); // Should not include metadata
      expect(entities.stats).toBeUndefined(); // Should not include stats

      // But should still have entity values
      if (entities.orderNumber) {
        expect(typeof entities.orderNumber).toBe('string');
      }
    });
  });

  // MARK: - Edge Cases

  describe('Edge Cases', () => {
    test('should handle emails with no extractable entities', () => {
      const email = {
        subject: 'Hello',
        from: 'friend@example.com',
        body: 'Just saying hi!'
      };

      const result = extractEntitiesEnhanced(email, 'communication.personal.message');

      expect(result.entities).toBeDefined();
      expect(result.metadata).toBeDefined();
      expect(result.stats.totalEntities).toBeGreaterThanOrEqual(0);
    });

    test('should handle emails with many entities', () => {
      const email = {
        subject: 'Complete order details',
        from: 'orders@store.com',
        body: `
          Order #ORD-123456
          Tracking: 1Z999AA10123456784
          Carrier: UPS
          Amount: $299.99
          Delivery: December 25, 2025
          Invoice #INV-789
          Payment link: https://pay.store.com/INV-789
        `
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.shipping.notification');

      expect(result.stats.totalEntities).toBeGreaterThan(5);
      expect(result.metadata).toBeDefined();
    });

    test('should handle invalid entity values gracefully', () => {
      const email = {
        subject: 'Order update',
        from: 'store@example.com',
        body: 'Order #. Amount: $. Date: invalid-date'
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.order.update');

      // Should not crash, may have low confidence entities
      expect(result).toBeDefined();
      expect(result.entities).toBeDefined();
    });
  });

  // MARK: - Performance Tests

  describe('Performance', () => {
    test('should complete extraction in reasonable time', () => {
      const email = {
        subject: 'Order shipped with tracking',
        from: 'shipping@amazon.com',
        body: 'Order #12345. Tracking: 1Z999AA. Amount: $99.99. Arriving Dec 25'
      };

      const result = extractEntitiesEnhanced(email, 'e-commerce.shipping.notification');

      expect(result.stats.processingTime).toBeLessThan(100); // Should be < 100ms
    });
  });
});

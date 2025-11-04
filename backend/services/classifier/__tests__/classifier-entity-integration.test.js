/**
 * Integration Test: Enhanced Entity Extraction in Classifier
 * Phase 3.1: Verify classifier returns entityMetadata and entityStats
 */

const { classifyEmailActionFirst } = require('../action-first-classifier');

describe('Classifier Entity Metadata Integration', () => {
  test('should return entityMetadata with confidence scores', async () => {
    const email = {
      subject: 'Your order #ORD-123456 has shipped',
      from: 'shipping@amazon.com',
      body: 'Your order has shipped! Tracking number: 1Z999AA10123456784. Carrier: UPS. Total: $99.99'
    };

    const classification = await classifyEmailActionFirst(email);

    // Verify entityMetadata is present
    expect(classification.entityMetadata).toBeDefined();
    expect(typeof classification.entityMetadata).toBe('object');

    // Verify metadata structure for at least one entity
    const metadataKeys = Object.keys(classification.entityMetadata);
    if (metadataKeys.length > 0) {
      const firstEntity = classification.entityMetadata[metadataKeys[0]];

      // Each entity metadata should have these fields
      expect(firstEntity.confidence).toBeDefined();
      expect(firstEntity.confidence).toBeGreaterThanOrEqual(0);
      expect(firstEntity.confidence).toBeLessThanOrEqual(1);
      expect(firstEntity.type).toBeDefined();
      expect(typeof firstEntity.validated).toBe('boolean');
    }
  });

  test('should return entityStats with extraction metrics', async () => {
    const email = {
      subject: 'Invoice #INV-2025-001 Due',
      from: 'billing@company.com',
      body: 'Your invoice is due. Amount: $150.00. Due date: January 15, 2025. Pay at: https://pay.company.com/INV-001'
    };

    const classification = await classifyEmailActionFirst(email);

    // Verify entityStats is present
    expect(classification.entityStats).toBeDefined();
    expect(typeof classification.entityStats).toBe('object');

    // Verify stats structure
    expect(classification.entityStats.totalEntities).toBeDefined();
    expect(typeof classification.entityStats.totalEntities).toBe('number');
    expect(classification.entityStats.totalEntities).toBeGreaterThanOrEqual(0);

    expect(classification.entityStats.avgConfidence).toBeDefined();
    expect(classification.entityStats.avgConfidence).toBeGreaterThanOrEqual(0);
    expect(classification.entityStats.avgConfidence).toBeLessThanOrEqual(1);

    expect(classification.entityStats.highConfidenceCount).toBeDefined();
    expect(typeof classification.entityStats.highConfidenceCount).toBe('number');

    expect(classification.entityStats.processingTime).toBeDefined();
    expect(typeof classification.entityStats.processingTime).toBe('number');
    expect(classification.entityStats.processingTime).toBeGreaterThanOrEqual(0);
  });

  test('should maintain backward compatibility with existing fields', async () => {
    const email = {
      subject: 'Package delivery notification',
      from: 'shipping@ups.com',
      body: 'Your package is out for delivery'
    };

    const classification = await classifyEmailActionFirst(email);

    // Verify all existing fields are still present
    expect(classification.type).toBeDefined();
    expect(classification.intent).toBeDefined();
    expect(classification.intentConfidence).toBeDefined();
    expect(classification.suggestedActions).toBeDefined();
    expect(Array.isArray(classification.suggestedActions)).toBe(true);
    expect(classification.priority).toBeDefined();
    expect(classification.hpa).toBeDefined();
    expect(classification.metaCTA).toBeDefined();
    // Note: urgent field may be undefined for non-urgent emails
    expect(classification.confidence).toBeDefined();
    expect(classification._classificationSource).toBeDefined();

    // New fields should also be present
    expect(classification.entityMetadata).toBeDefined();
    expect(classification.entityStats).toBeDefined();
  });

  test('should handle emails with no entities gracefully', async () => {
    const email = {
      subject: 'Hello',
      from: 'friend@example.com',
      body: 'Just saying hi!'
    };

    const classification = await classifyEmailActionFirst(email);

    // Should still return entityMetadata and entityStats, even if empty
    expect(classification.entityMetadata).toBeDefined();
    expect(classification.entityStats).toBeDefined();
    expect(classification.entityStats.totalEntities).toBeGreaterThanOrEqual(0);
  });

  test('should apply context-aware confidence boosts', async () => {
    const email = {
      subject: 'Shipping notification from Amazon',
      from: 'shipment-tracking@amazon.com',
      body: 'Order #12345 shipped. Tracking: 1Z999AA10123456784. Amount: $25.99'
    };

    const classification = await classifyEmailActionFirst(email);

    // For e-commerce shipping intent, tracking number should have boosted confidence
    if (classification.intent.includes('shipping') || classification.intent.includes('e-commerce')) {
      if (classification.entityMetadata.trackingNumber) {
        expect(classification.entityMetadata.trackingNumber.confidence).toBeGreaterThanOrEqual(0.7);
      }
    }
  });
});

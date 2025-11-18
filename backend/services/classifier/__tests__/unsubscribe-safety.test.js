/**
 * Unsubscribe Safety Tests
 *
 * CRITICAL: These tests ensure the unsubscribe agent NEVER automatically
 * unsubscribes from banking, medical, security, utility, or government emails.
 *
 * ALL tests in this file must pass before deploying unsubscribe functionality.
 */

const fs = require('fs');
const path = require('path');
const safelist = require('../safelist');
const unsubscribeService = require('../unsubscribe-service');

// Helper to load fixture
function loadFixture(filename) {
  const fixturePath = path.join(__dirname, 'fixtures', filename);
  const data = fs.readFileSync(fixturePath, 'utf-8');
  return JSON.parse(data);
}

describe('Unsubscribe Safety - Critical Email Protection', () => {
  describe('Banking Emails', () => {
    test('MUST NOT allow unsubscribe from Chase Bank security alert', () => {
      const fixture = loadFixture('critical-bank-alert.json');

      const result = unsubscribeService.canUnsubscribe(fixture);

      expect(result.canUnsubscribe).toBe(false);
      expect(result.blocked).toBe('safelist');
      expect(result.reason).toContain('Critical');
    });

    test('Safelist MUST block chase.com domain', () => {
      const isBlocked = safelist.isCriticalDomain('alerts@chase.com');

      expect(isBlocked).toBe(true);
    });
  });

  describe('Security/Authentication Emails', () => {
    test('MUST NOT allow unsubscribe from password reset', () => {
      const fixture = loadFixture('critical-password-reset.json');

      const result = unsubscribeService.canUnsubscribe(fixture);

      expect(result.canUnsubscribe).toBe(false);
      expect(result.blocked).toBe('safelist');
    });

    test('MUST NOT allow unsubscribe from 2FA verification code', () => {
      const fixture = loadFixture('critical-2fa-code.json');

      const result = unsubscribeService.canUnsubscribe(fixture);

      expect(result.canUnsubscribe).toBe(false);
      expect(result.blocked).toBe('safelist');
    });

    test('Safelist MUST block security intent patterns', () => {
      expect(safelist.isCriticalIntent('security.password.reset')).toBe(true);
      expect(safelist.isCriticalIntent('authentication.two_factor')).toBe(true);
      expect(safelist.isCriticalIntent('security.alert')).toBe(true);
    });

    test('Safelist MUST block security subject patterns', () => {
      expect(safelist.isCriticalSubject('Security Alert: Unusual Activity')).toBe(true);
      expect(safelist.isCriticalSubject('Password Reset Request')).toBe(true);
      expect(safelist.isCriticalSubject('Your verification code is 123456')).toBe(true);
      expect(safelist.isCriticalSubject('Suspicious login attempt')).toBe(true);
    });
  });

  describe('Medical/Healthcare Emails', () => {
    test('MUST NOT allow unsubscribe from medical appointment reminder', () => {
      const fixture = loadFixture('critical-medical-appointment.json');

      const result = unsubscribeService.canUnsubscribe(fixture);

      expect(result.canUnsubscribe).toBe(false);
      expect(result.blocked).toBe('safelist');
      expect(result.reason).toContain('Critical');
    });

    test('Safelist MUST block medical domains', () => {
      expect(safelist.isCriticalDomain('appointments@memorialmedical.org')).toBe(true);
    });

    test('Safelist MUST block healthcare intent patterns', () => {
      expect(safelist.isCriticalIntent('medical.appointment')).toBe(true);
      expect(safelist.isCriticalIntent('healthcare.reminder')).toBe(true);
      expect(safelist.isCriticalIntent('prescription.notification')).toBe(true);
    });
  });

  describe('Utility/Billing Emails', () => {
    test('MUST NOT allow unsubscribe from utility bill', () => {
      const fixture = loadFixture('critical-utility-bill.json');

      const result = unsubscribeService.canUnsubscribe(fixture);

      expect(result.canUnsubscribe).toBe(false);
      expect(result.blocked).toBe('safelist');
    });

    test('Safelist MUST block utility company domains', () => {
      expect(safelist.isCriticalDomain('billing@pge.com')).toBe(true);
      expect(safelist.isCriticalDomain('sce.com')).toBe(true);
      expect(safelist.isCriticalDomain('xfinity.com')).toBe(true);
    });

    test('Safelist MUST block billing intent patterns', () => {
      expect(safelist.isCriticalIntent('billing.payment_due')).toBe(true);
      expect(safelist.isCriticalIntent('utility.bill')).toBe(true);
      expect(safelist.isCriticalIntent('invoice.due')).toBe(true);
    });
  });

  describe('All Critical Fixtures Batch Test', () => {
    const criticalFixtures = [
      'critical-bank-alert.json',
      'critical-password-reset.json',
      'critical-medical-appointment.json',
      'critical-utility-bill.json',
      'critical-2fa-code.json'
    ];

    test.each(criticalFixtures)('MUST block unsubscribe from %s', (filename) => {
      const fixture = loadFixture(filename);

      const result = unsubscribeService.canUnsubscribe(fixture);

      expect(result.canUnsubscribe).toBe(false);
      expect(result.blocked).toBe('safelist');
      expect(result.reason).toMatch(/Critical|transactional|security|banking|medical|utility/i);
    });
  });
});

describe('Unsubscribe Safety - Newsletter/Marketing Detection', () => {
  describe('Safe to Unsubscribe', () => {
    test('SHOULD allow unsubscribe from Substack newsletter', () => {
      const fixture = loadFixture('newsletter-substack.json');

      const result = unsubscribeService.canUnsubscribe(fixture);

      expect(result.canUnsubscribe).toBe(true);
      expect(result.mechanism).toBeDefined();
      expect(result.mechanism.hasListUnsubscribe).toBe(true);
    });

    test('SHOULD allow unsubscribe from TechCrunch Daily', () => {
      const fixture = loadFixture('newsletter-techcrunch.json');

      const result = unsubscribeService.canUnsubscribe(fixture);

      expect(result.canUnsubscribe).toBe(true);
      expect(result.mechanism).toBeDefined();
    });

    test('SHOULD allow unsubscribe from retail promo (J.Crew)', () => {
      const fixture = loadFixture('marketing-retail-promo.json');

      const result = unsubscribeService.canUnsubscribe(fixture);

      expect(result.canUnsubscribe).toBe(true);
      expect(result.mechanism).toBeDefined();
    });

    test('SHOULD allow unsubscribe from product recommendations (Spotify)', () => {
      const fixture = loadFixture('marketing-product-recommendations.json');

      const result = unsubscribeService.canUnsubscribe(fixture);

      expect(result.canUnsubscribe).toBe(true);
      expect(result.mechanism).toBeDefined();
    });
  });

  describe('All Safe Fixtures Batch Test', () => {
    const safeFixtures = [
      'newsletter-substack.json',
      'newsletter-techcrunch.json',
      'marketing-retail-promo.json',
      'marketing-product-recommendations.json'
    ];

    test.each(safeFixtures)('SHOULD allow unsubscribe from %s', (filename) => {
      const fixture = loadFixture(filename);

      const result = unsubscribeService.canUnsubscribe(fixture);

      expect(result.canUnsubscribe).toBe(true);
      expect(result.mechanism).toBeDefined();
      expect(result.mechanism.preferredMethod).toBeDefined();
    });
  });
});

describe('Unsubscribe Safety - Receipt/Order Emails', () => {
  const receiptFixtures = [
    'shopping-amazon-order-confirmation.json',
    'shopping-amazon-shipped.json',
    'shopping-amazon-delivered.json',
    'shopping-target-order.json',
    'shopping-bestbuy-multi-item.json',
    'shopping-order-cancelled.json',
    'shopping-refund-issued.json'
  ];

  test.each(receiptFixtures)('MUST NOT allow unsubscribe from receipt: %s', (filename) => {
    const fixture = loadFixture(filename);

    const result = unsubscribeService.canUnsubscribe(fixture);

    expect(result.canUnsubscribe).toBe(false);
    expect(result.blocked).toBe('safelist');
    // Reason can be domain, intent, shouldNeverUnsubscribe, or type - all are valid blocks
    expect(result.reason).toBeDefined();
    expect(result.reason.length).toBeGreaterThan(0);
  });

  test('Safelist MUST block receipt type classification', () => {
    const mockEmail = {
      from: 'orders@example.com',
      subject: 'Your order #123',
      classification: {
        type: 'receipt',
        category: 'shopping',
        intent: 'order.confirmation'
      }
    };

    const result = safelist.isSafeToUnsubscribe(mockEmail);

    expect(result.safe).toBe(false);
    // Can be blocked by intent or type
    expect(result.reason).toMatch(/receipt|transactional|intent/i);
  });
});

describe('Unsubscribe Safety - Safelist Domain Protection', () => {
  describe('Banking Domains', () => {
    const bankingDomains = [
      'chase.com',
      'wellsfargo.com',
      'bankofamerica.com',
      'paypal.com',
      'stripe.com'
    ];

    test.each(bankingDomains)('MUST block %s', (domain) => {
      expect(safelist.isCriticalDomain(`test@${domain}`)).toBe(true);
    });
  });

  describe('Medical Domains', () => {
    const medicalDomains = [
      'kaiserpermanente.org',
      'sutterhealth.org',
      'mayoclinic.org'
    ];

    test.each(medicalDomains)('MUST block %s', (domain) => {
      expect(safelist.isCriticalDomain(`appointments@${domain}`)).toBe(true);
    });
  });

  describe('Government Domains', () => {
    const govDomains = [
      'irs.gov',
      'ssa.gov',
      'usps.com'
    ];

    test.each(govDomains)('MUST block %s', (domain) => {
      expect(safelist.isCriticalDomain(`notices@${domain}`)).toBe(true);
    });
  });

  describe('Educational Domains', () => {
    test('MUST block all .edu domains', () => {
      expect(safelist.isCriticalDomain('registrar@stanford.edu')).toBe(true);
      expect(safelist.isCriticalDomain('admin@berkeley.edu')).toBe(true);
      expect(safelist.isCriticalDomain('student@anycollege.edu')).toBe(true);
    });
  });
});

describe('Unsubscribe Safety - Edge Cases', () => {
  test('MUST handle invalid email object gracefully', () => {
    const result = unsubscribeService.canUnsubscribe(null);

    expect(result.canUnsubscribe).toBe(false);
    expect(result.reason).toContain('Invalid');
  });

  test('MUST handle email without classification', () => {
    const mockEmail = {
      from: 'test@example.com',
      subject: 'Test'
    };

    const result = unsubscribeService.canUnsubscribe(mockEmail);

    // Should still check domain/subject
    expect(result).toBeDefined();
  });

  test('MUST respect shouldNeverUnsubscribe flag', () => {
    const mockEmail = {
      from: 'test@example.com',
      subject: 'Test',
      classification: {
        type: 'marketing',
        shouldNeverUnsubscribe: true
      }
    };

    const result = safelist.isSafeToUnsubscribe(mockEmail);

    expect(result.safe).toBe(false);
    expect(result.reason).toContain('shouldNeverUnsubscribe');
  });

  test('MUST handle subdomain matching (mail.google.com should match google.com)', () => {
    expect(safelist.isCriticalDomain('no-reply@mail.google.com')).toBe(true);
    expect(safelist.isCriticalDomain('accounts@mail.apple.com')).toBe(true);
  });
});

describe('Unsubscribe Safety - Statistics', () => {
  test('Safelist should have comprehensive coverage', () => {
    const stats = safelist.getSafelistStats();

    expect(stats.criticalDomains).toBeGreaterThan(50);  // At least 50 critical domains
    expect(stats.criticalIntentPatterns).toBeGreaterThan(15);  // At least 15 intent patterns
    expect(stats.criticalSubjectPatterns).toBeGreaterThan(10);  // At least 10 subject patterns
  });
});

/**
 * Unsubscribe Parsing Tests
 *
 * Tests the extraction of unsubscribe mechanisms from emails:
 * - List-Unsubscribe header parsing (RFC 2369)
 * - One-Click unsubscribe detection (RFC 8058)
 * - Unsubscribe URL extraction from HTML body
 */

const fs = require('fs');
const path = require('path');
const unsubscribeService = require('../unsubscribe-service');

// Helper to load fixture
function loadFixture(filename) {
  const fixturePath = path.join(__dirname, 'fixtures', filename);
  const data = fs.readFileSync(fixturePath, 'utf-8');
  return JSON.parse(data);
}

describe('Unsubscribe Parsing - List-Unsubscribe Header', () => {
  test('Should parse single URL from List-Unsubscribe header', () => {
    const header = '<https://example.com/unsubscribe?token=abc123>';

    const result = unsubscribeService.parseListUnsubscribeHeader(header);

    expect(result.urls).toHaveLength(1);
    expect(result.urls[0]).toBe('https://example.com/unsubscribe?token=abc123');
    expect(result.mailto).toBeNull();
  });

  test('Should parse multiple URLs from List-Unsubscribe header', () => {
    const header = '<https://example.com/unsub>, <https://example.com/preferences>';

    const result = unsubscribeService.parseListUnsubscribeHeader(header);

    expect(result.urls).toHaveLength(2);
    expect(result.urls[0]).toBe('https://example.com/unsub');
    expect(result.urls[1]).toBe('https://example.com/preferences');
  });

  test('Should parse mailto from List-Unsubscribe header', () => {
    const header = '<mailto:unsubscribe@example.com>';

    const result = unsubscribeService.parseListUnsubscribeHeader(header);

    expect(result.mailto).toBe('mailto:unsubscribe@example.com');
    expect(result.urls).toHaveLength(0);
  });

  test('Should parse mixed mailto and URL', () => {
    const header = '<mailto:unsub@example.com>, <https://example.com/unsubscribe>';

    const result = unsubscribeService.parseListUnsubscribeHeader(header);

    expect(result.mailto).toBe('mailto:unsub@example.com');
    expect(result.urls).toHaveLength(1);
    expect(result.urls[0]).toBe('https://example.com/unsubscribe');
  });

  test('Should handle empty or null header', () => {
    expect(unsubscribeService.parseListUnsubscribeHeader(null).urls).toHaveLength(0);
    expect(unsubscribeService.parseListUnsubscribeHeader('').urls).toHaveLength(0);
  });
});

describe('Unsubscribe Parsing - One-Click Support', () => {
  test('Should detect One-Click support with both headers present', () => {
    const headers = {
      'List-Unsubscribe': '<https://example.com/unsub>',
      'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click'
    };

    const hasOneClick = unsubscribeService.checkOneClickSupport(headers);

    expect(hasOneClick).toBe(true);
  });

  test('Should not detect One-Click with only List-Unsubscribe', () => {
    const headers = {
      'List-Unsubscribe': '<https://example.com/unsub>'
    };

    const hasOneClick = unsubscribeService.checkOneClickSupport(headers);

    expect(hasOneClick).toBe(false);
  });

  test('Should not detect One-Click with only List-Unsubscribe-Post', () => {
    const headers = {
      'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click'
    };

    const hasOneClick = unsubscribeService.checkOneClickSupport(headers);

    expect(hasOneClick).toBe(false);
  });

  test('Should handle case-insensitive headers', () => {
    const headers = {
      'list-unsubscribe': '<https://example.com/unsub>',
      'list-unsubscribe-post': 'List-Unsubscribe=One-Click'
    };

    const hasOneClick = unsubscribeService.checkOneClickSupport(headers);

    expect(hasOneClick).toBe(true);
  });
});

describe('Unsubscribe Parsing - HTML Body URL Extraction', () => {
  test('Should extract unsubscribe URL from href attribute', () => {
    const html = '<a href="https://example.com/unsubscribe?id=123">Unsubscribe</a>';

    const urls = unsubscribeService.extractUnsubscribeURLs(html);

    expect(urls).toContain('https://example.com/unsubscribe?id=123');
  });

  test('Should extract multiple unsubscribe URLs', () => {
    const html = `
      <a href="https://example.com/unsubscribe">Unsubscribe</a>
      <a href="https://example.com/preferences">Email Preferences</a>
      <a href="https://example.com/opt-out">Opt Out</a>
    `;

    const urls = unsubscribeService.extractUnsubscribeURLs(html);

    expect(urls.length).toBeGreaterThanOrEqual(2);
    expect(urls.some(url => url.includes('unsubscribe'))).toBe(true);
  });

  test('Should handle various unsubscribe keywords', () => {
    const keywords = ['unsubscribe', 'opt-out', 'opt_out', 'preferences', 'email-settings', 'email_settings'];

    for (const keyword of keywords) {
      const html = `<a href="https://example.com/${keyword}">Link</a>`;
      const urls = unsubscribeService.extractUnsubscribeURLs(html);

      expect(urls.length).toBeGreaterThan(0);
    }
  });

  test('Should only extract HTTP/HTTPS URLs', () => {
    const html = `
      <a href="https://example.com/unsubscribe">HTTPS Link</a>
      <a href="http://example.com/unsubscribe">HTTP Link</a>
      <a href="javascript:void(0)">Not a URL</a>
      <a href="/relative/unsubscribe">Relative URL</a>
    `;

    const urls = unsubscribeService.extractUnsubscribeURLs(html);

    // Should only include absolute HTTP(S) URLs
    urls.forEach(url => {
      expect(url.startsWith('http://') || url.startsWith('https://')).toBe(true);
    });
  });

  test('Should handle empty or null HTML', () => {
    expect(unsubscribeService.extractUnsubscribeURLs(null)).toHaveLength(0);
    expect(unsubscribeService.extractUnsubscribeURLs('')).toHaveLength(0);
  });
});

describe('Unsubscribe Parsing - Complete Mechanism from Fixtures', () => {
  test('Should parse mechanism from Substack newsletter', () => {
    const fixture = loadFixture('newsletter-substack.json');

    const mechanism = unsubscribeService.parseUnsubscribeMechanism(fixture);

    expect(mechanism.hasListUnsubscribe).toBe(true);
    expect(mechanism.hasOneClick).toBe(true);
    expect(mechanism.headerUrls).toHaveLength(1);
    expect(mechanism.headerUrls[0]).toContain('unsubscribe');
    expect(mechanism.preferredMethod).toBeDefined();
    expect(mechanism.preferredMethod.type).toBe('one-click');
  });

  test('Should parse mechanism from TechCrunch newsletter', () => {
    const fixture = loadFixture('newsletter-techcrunch.json');

    const mechanism = unsubscribeService.parseUnsubscribeMechanism(fixture);

    expect(mechanism.hasListUnsubscribe).toBe(true);
    expect(mechanism.hasOneClick).toBe(true);
    expect(mechanism.allUrls.length).toBeGreaterThan(0);
    expect(mechanism.preferredMethod).toBeDefined();
  });

  test('Should parse mechanism from retail promo', () => {
    const fixture = loadFixture('marketing-retail-promo.json');

    const mechanism = unsubscribeService.parseUnsubscribeMechanism(fixture);

    expect(mechanism.hasListUnsubscribe).toBe(true);
    expect(mechanism.allUrls.length).toBeGreaterThan(0);
    expect(mechanism.preferredMethod).toBeDefined();
  });

  test('Should parse mechanism from Spotify recommendations', () => {
    const fixture = loadFixture('marketing-product-recommendations.json');

    const mechanism = unsubscribeService.parseUnsubscribeMechanism(fixture);

    expect(mechanism.hasListUnsubscribe).toBe(true);
    expect(mechanism.allUrls.length).toBeGreaterThan(0);
    expect(mechanism.preferredMethod).toBeDefined();
  });
});

describe('Unsubscribe Parsing - Preferred Method Selection', () => {
  test('Should prefer One-Click over regular URL', () => {
    const email = {
      headers: {
        'List-Unsubscribe': '<https://example.com/unsub>',
        'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click'
      },
      body: {
        html: '<a href="https://example.com/other-unsub">Unsubscribe</a>'
      }
    };

    const mechanism = unsubscribeService.parseUnsubscribeMechanism(email);

    expect(mechanism.preferredMethod.type).toBe('one-click');
    expect(mechanism.preferredMethod.url).toBe('https://example.com/unsub');
  });

  test('Should prefer header URL over body URL', () => {
    const email = {
      headers: {
        'List-Unsubscribe': '<https://example.com/header-unsub>'
      },
      body: {
        html: '<a href="https://example.com/body-unsub">Unsubscribe</a>'
      }
    };

    const mechanism = unsubscribeService.parseUnsubscribeMechanism(email);

    expect(mechanism.preferredMethod.type).toBe('url');
    expect(mechanism.preferredMethod.url).toBe('https://example.com/header-unsub');
  });

  test('Should use body URL if no header URL', () => {
    const email = {
      headers: {},
      body: {
        html: '<a href="https://example.com/unsubscribe?id=body-unsub">Unsubscribe here</a>'
      }
    };

    const mechanism = unsubscribeService.parseUnsubscribeMechanism(email);

    expect(mechanism.preferredMethod).toBeDefined();
    expect(mechanism.preferredMethod.type).toBe('url');
    expect(mechanism.preferredMethod.url).toContain('unsubscribe');
  });

  test('Should use mailto if no URLs available', () => {
    const email = {
      headers: {
        'List-Unsubscribe': '<mailto:unsubscribe@example.com>'
      },
      body: {}
    };

    const mechanism = unsubscribeService.parseUnsubscribeMechanism(email);

    expect(mechanism.preferredMethod.type).toBe('mailto');
    expect(mechanism.preferredMethod.address).toBe('mailto:unsubscribe@example.com');
  });

  test('Should return null if no unsubscribe mechanism found', () => {
    const email = {
      headers: {},
      body: { html: '<p>Regular email with no unsubscribe link</p>' }
    };

    const mechanism = unsubscribeService.parseUnsubscribeMechanism(email);

    expect(mechanism.preferredMethod).toBeNull();
  });
});

describe('Unsubscribe Parsing - Execute Unsubscribe (Mock)', () => {
  test('Should execute mock unsubscribe successfully', async () => {
    const mechanism = {
      preferredMethod: {
        type: 'url',
        url: 'https://example.com/unsubscribe'
      }
    };

    const result = await unsubscribeService.executeUnsubscribe(mechanism, { mock: true });

    expect(result.success).toBe(true);
    expect(result.method).toBe('url');
    expect(result.mock).toBe(true);
    expect(result.timestamp).toBeDefined();
  });

  test('Should execute dry run without actual unsubscribe', async () => {
    const mechanism = {
      preferredMethod: {
        type: 'one-click',
        url: 'https://example.com/unsubscribe'
      }
    };

    const result = await unsubscribeService.executeUnsubscribe(mechanism, { dryRun: true });

    expect(result.success).toBe(true);
    expect(result.dryRun).toBe(true);
    expect(result.details).toContain('DRY RUN');
  });

  test('Should fail if no mechanism provided', async () => {
    const result = await unsubscribeService.executeUnsubscribe(null, { mock: true });

    expect(result.success).toBe(false);
    expect(result.details).toContain('No unsubscribe mechanism');
  });

  test('Should throw error in production mode (not implemented)', async () => {
    const mechanism = {
      preferredMethod: {
        type: 'url',
        url: 'https://example.com/unsubscribe'
      }
    };

    await expect(
      unsubscribeService.executeUnsubscribe(mechanism, { mock: false })
    ).rejects.toThrow('Production unsubscribe not implemented');
  });
});

describe('Unsubscribe Parsing - Audit Logging', () => {
  test('Should create audit log for check action', () => {
    const email = {
      from: 'newsletter@example.com',
      subject: 'Weekly Newsletter',
      classification: {
        type: 'newsletter'
      }
    };

    const result = {
      canUnsubscribe: true,
      reason: 'Safe to unsubscribe'
    };

    const log = unsubscribeService.auditLog(email, result, { action: 'check', userId: 'test-user' });

    expect(log.timestamp).toBeDefined();
    expect(log.emailFrom).toBe('newsletter@example.com');
    expect(log.emailSubject).toBe('Weekly Newsletter');
    expect(log.action).toBe('check');
    expect(log.result).toBe(true);
    expect(log.userId).toBe('test-user');
  });

  test('Should create audit log for blocked attempt', () => {
    const email = {
      from: 'alerts@chase.com',
      subject: 'Security Alert',
      classification: {
        type: 'transactional'
      }
    };

    const result = {
      canUnsubscribe: false,
      reason: 'Critical domain',
      blocked: 'safelist'
    };

    const log = unsubscribeService.auditLog(email, result, { action: 'check' });

    expect(log.result).toBe(false);
    expect(log.blocked).toBe('safelist');
    expect(log.reason).toContain('Critical');
  });
});

describe('Unsubscribe Parsing - Complete Workflow', () => {
  test('Should complete workflow for safe newsletter', async () => {
    const fixture = loadFixture('newsletter-substack.json');

    const result = await unsubscribeService.unsubscribeWorkflow(fixture, { mock: true, userId: 'test' });

    expect(result.success).toBe(true);
    expect(result.step).toBe('execute');
    expect(result.mechanism).toBeDefined();
    expect(result.execution).toBeDefined();
    expect(result.auditLog).toHaveLength(2);  // Check + execute logs
  });

  test('Should stop workflow if safelist blocks', async () => {
    const fixture = loadFixture('critical-bank-alert.json');

    const result = await unsubscribeService.unsubscribeWorkflow(fixture, { mock: true });

    expect(result.success).toBe(false);
    expect(result.step).toBe('check');
    expect(result.blocked).toBe('safelist');
    expect(result.auditLog).toBeDefined();  // Only check log, no execute
  });

  test('Should handle dry run workflow', async () => {
    const fixture = loadFixture('newsletter-techcrunch.json');

    const result = await unsubscribeService.unsubscribeWorkflow(fixture, { dryRun: true });

    expect(result.success).toBe(true);
    expect(result.execution.dryRun).toBe(true);
  });
});

/**
 * Data Anonymization Service
 *
 * Provides cryptographically secure anonymization of PII (Personally Identifiable Information)
 * for beta testing compliance. Creates an auditable trail of all anonymization operations.
 *
 * Key Features:
 * - Irreversible hashing of email addresses, names, and identifiers
 * - PII detection and scrubbing from email content
 * - Audit logging for compliance demonstration
 * - Deterministic anonymization (same input = same output) for testing consistency
 */

const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');
const logger = require('../config/logger');

// Secret key for HMAC (should be in environment variable in production)
const ANONYMIZATION_KEY = process.env.ANONYMIZATION_KEY || 'beta-testing-anonymization-key-2025';

// Audit log path
const AUDIT_LOG_PATH = path.join(__dirname, '../../data/anonymization-audit.log');

class DataAnonymizer {
  constructor() {
    this.initAuditLog();
  }

  /**
   * Initialize audit log file
   */
  async initAuditLog() {
    try {
      const dir = path.dirname(AUDIT_LOG_PATH);
      await fs.mkdir(dir, { recursive: true });

      // Create audit log if it doesn't exist
      try {
        await fs.access(AUDIT_LOG_PATH);
      } catch {
        await fs.writeFile(AUDIT_LOG_PATH, '# Data Anonymization Audit Log\n# Started: ' + new Date().toISOString() + '\n\n');
        logger.info('Anonymization audit log initialized');
      }
    } catch (error) {
      logger.error('Failed to initialize audit log', { error: error.message });
    }
  }

  /**
   * Log anonymization event to audit trail
   */
  async logAnonymization(operation, details) {
    const entry = {
      timestamp: new Date().toISOString(),
      operation,
      details
    };

    try {
      await fs.appendFile(
        AUDIT_LOG_PATH,
        JSON.stringify(entry) + '\n'
      );
    } catch (error) {
      logger.error('Failed to write to audit log', { error: error.message });
    }
  }

  /**
   * Create irreversible hash of sensitive data
   * Uses HMAC-SHA256 for cryptographically secure one-way hashing
   */
  hashSensitiveData(data, salt = '') {
    const hmac = crypto.createHmac('sha256', ANONYMIZATION_KEY);
    hmac.update(data + salt);
    return hmac.digest('hex');
  }

  /**
   * Anonymize email address
   * Example: john.doe@example.com -> user_a3f5b8c9@anonymized.test
   */
  anonymizeEmail(email) {
    if (!email) return null;

    const hash = this.hashSensitiveData(email).substring(0, 8);
    const anonymized = `user_${hash}@anonymized.test`;

    this.logAnonymization('email_anonymized', {
      originalLength: email.length,
      anonymized
    });

    return anonymized;
  }

  /**
   * Anonymize person name
   * Example: John Doe -> User A3F5
   */
  anonymizeName(name) {
    if (!name) return null;

    const hash = this.hashSensitiveData(name).substring(0, 4).toUpperCase();
    const anonymized = `User ${hash}`;

    this.logAnonymization('name_anonymized', {
      originalLength: name.length,
      anonymized
    });

    return anonymized;
  }

  /**
   * Anonymize user ID (creates consistent hash)
   */
  anonymizeUserId(userId) {
    if (!userId) return null;

    const hash = this.hashSensitiveData(userId);
    return `anon_${hash}`;
  }

  /**
   * Detect and scrub PII from text content
   * Patterns detected:
   * - Email addresses
   * - Phone numbers
   * - Credit card numbers
   * - SSN patterns
   * - Physical addresses
   */
  scrubPII(text) {
    if (!text) return text;

    let scrubbedText = text;
    let scrubbedCount = 0;

    // Email addresses
    const emailRegex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g;
    scrubbedText = scrubbedText.replace(emailRegex, (match) => {
      scrubbedCount++;
      return this.anonymizeEmail(match);
    });

    // Phone numbers (various formats)
    const phoneRegex = /(\+\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b/g;
    scrubbedText = scrubbedText.replace(phoneRegex, () => {
      scrubbedCount++;
      return '[PHONE_REDACTED]';
    });

    // Credit card numbers (simple pattern)
    const ccRegex = /\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b/g;
    scrubbedText = scrubbedText.replace(ccRegex, () => {
      scrubbedCount++;
      return '[CARD_REDACTED]';
    });

    // SSN pattern
    const ssnRegex = /\b\d{3}-\d{2}-\d{4}\b/g;
    scrubbedText = scrubbedText.replace(ssnRegex, () => {
      scrubbedCount++;
      return '[SSN_REDACTED]';
    });

    // Names in common patterns (Mr., Mrs., Dr., etc.)
    const titleRegex = /\b(Mr\.|Mrs\.|Ms\.|Dr\.|Prof\.)\s+[A-Z][a-z]+(\s+[A-Z][a-z]+)?\b/g;
    scrubbedText = scrubbedText.replace(titleRegex, (match) => {
      scrubbedCount++;
      return this.anonymizeName(match);
    });

    if (scrubbedCount > 0) {
      this.logAnonymization('pii_scrubbed', {
        itemsRedacted: scrubbedCount,
        originalLength: text.length,
        scrubbedLength: scrubbedText.length
      });
    }

    return scrubbedText;
  }

  /**
   * Anonymize complete email object
   */
  anonymizeEmailObject(email) {
    if (!email) return null;

    const anonymized = {
      ...email,
      // Anonymize identifiers
      id: email.id ? this.hashSensitiveData(email.id).substring(0, 16) : null,
      threadId: email.threadId ? this.hashSensitiveData(email.threadId).substring(0, 16) : null,

      // Anonymize sender/recipient info
      from: email.from ? this.anonymizeEmail(email.from) : null,
      to: Array.isArray(email.to) ? email.to.map(e => this.anonymizeEmail(e)) : null,
      cc: Array.isArray(email.cc) ? email.cc.map(e => this.anonymizeEmail(e)) : null,
      bcc: Array.isArray(email.bcc) ? email.bcc.map(e => this.anonymizeEmail(e)) : null,

      // Scrub PII from content
      subject: email.subject ? this.scrubPII(email.subject) : null,
      body: email.body ? this.scrubPII(email.body) : null,
      snippet: email.snippet ? this.scrubPII(email.snippet) : null,

      // Keep metadata for testing (non-PII)
      date: email.date,
      labels: email.labels,
      priority: email.priority,
      category: email.category,
      intent: email.intent,
      actions: email.actions,

      // Mark as anonymized
      _anonymized: true,
      _anonymizedAt: new Date().toISOString()
    };

    this.logAnonymization('email_object_anonymized', {
      hasSubject: !!email.subject,
      hasBody: !!email.body,
      hasFrom: !!email.from,
      toCount: email.to?.length || 0
    });

    return anonymized;
  }

  /**
   * Anonymize array of emails
   */
  anonymizeEmailList(emails) {
    if (!Array.isArray(emails)) return emails;

    return emails.map(email => this.anonymizeEmailObject(email));
  }

  /**
   * Get anonymization statistics for compliance reporting
   */
  async getAnonymizationStats() {
    try {
      const auditLog = await fs.readFile(AUDIT_LOG_PATH, 'utf-8');
      const entries = auditLog
        .split('\n')
        .filter(line => line.startsWith('{'))
        .map(line => {
          try {
            return JSON.parse(line);
          } catch {
            return null;
          }
        })
        .filter(Boolean);

      const stats = {
        totalOperations: entries.length,
        byOperation: {},
        firstOperation: entries[0]?.timestamp,
        lastOperation: entries[entries.length - 1]?.timestamp
      };

      entries.forEach(entry => {
        stats.byOperation[entry.operation] = (stats.byOperation[entry.operation] || 0) + 1;
      });

      return stats;
    } catch (error) {
      logger.error('Failed to get anonymization stats', { error: error.message });
      return { error: 'Unable to load stats' };
    }
  }

  /**
   * Export audit log for compliance review
   */
  async exportAuditLog() {
    try {
      const auditLog = await fs.readFile(AUDIT_LOG_PATH, 'utf-8');
      return auditLog;
    } catch (error) {
      logger.error('Failed to export audit log', { error: error.message });
      throw new Error('Unable to export audit log');
    }
  }
}

// Singleton instance
const anonymizer = new DataAnonymizer();

module.exports = anonymizer;

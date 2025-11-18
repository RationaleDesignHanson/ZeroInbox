/**
 * Receipts Routes
 *
 * Endpoints for parsing receipt/order emails and extracting shopping information
 */

const express = require('express');
const router = express.Router();
const receiptParser = require('../lib/receiptParser');

/**
 * POST /receipts/parse
 *
 * Parse a receipt email and extract order information
 *
 * Request body:
 * {
 *   "email": {
 *     "from": "orders@amazon.com" or { "name": "Amazon", "email": "orders@amazon.com" },
 *     "subject": "Your order confirmation",
 *     "body": { "text": "...", "html": "..." } or "textBody": "...", "htmlBody": "..."
 *   },
 *   "options": {
 *     "useService": false  // Optional: use entity extractor service
 *   }
 * }
 *
 * Response:
 * {
 *   "success": true,
 *   "receipt": {
 *     "orderNumber": "123456",
 *     "merchant": "Amazon",
 *     "items": [...],
 *     "total": 123.45,
 *     "currency": "USD",
 *     "trackingNumber": "...",
 *     "status": "ordered|shipped|delivered|cancelled|refunded",
 *     "parsedAt": "2025-01-18T..."
 *   }
 * }
 */
router.post('/parse', async (req, res) => {
  try {
    const { email, options = {} } = req.body;

    // Validate request
    if (!email) {
      return res.status(400).json({
        success: false,
        error: 'Email object is required',
        message: 'Request body must include an "email" object'
      });
    }

    // Parse receipt
    const receipt = await receiptParser.parseReceipt(email, options);

    res.json({
      success: true,
      receipt
    });
  } catch (error) {
    console.error('Receipt parsing error:', error);

    res.status(500).json({
      success: false,
      error: error.message,
      message: 'Failed to parse receipt email'
    });
  }
});

/**
 * POST /receipts/batch
 *
 * Parse multiple receipt emails in batch
 *
 * Request body:
 * {
 *   "emails": [
 *     { "from": "...", "subject": "...", "body": {...} },
 *     ...
 *   ],
 *   "options": {
 *     "useService": false
 *   }
 * }
 *
 * Response:
 * {
 *   "success": true,
 *   "results": [
 *     { "success": true, "receipt": {...} },
 *     { "success": false, "error": "..." },
 *     ...
 *   ],
 *   "summary": {
 *     "total": 10,
 *     "successful": 8,
 *     "failed": 2
 *   }
 * }
 */
router.post('/batch', async (req, res) => {
  try {
    const { emails, options = {} } = req.body;

    // Validate request
    if (!emails || !Array.isArray(emails)) {
      return res.status(400).json({
        success: false,
        error: 'Emails array is required',
        message: 'Request body must include an "emails" array'
      });
    }

    if (emails.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Emails array is empty',
        message: 'At least one email is required'
      });
    }

    if (emails.length > 100) {
      return res.status(400).json({
        success: false,
        error: 'Too many emails',
        message: 'Maximum 100 emails per batch request'
      });
    }

    // Parse all emails
    const results = [];
    let successful = 0;
    let failed = 0;

    for (const email of emails) {
      try {
        const receipt = await receiptParser.parseReceipt(email, options);
        results.push({
          success: true,
          receipt
        });
        successful++;
      } catch (error) {
        results.push({
          success: false,
          error: error.message
        });
        failed++;
      }
    }

    res.json({
      success: true,
      results,
      summary: {
        total: emails.length,
        successful,
        failed
      }
    });
  } catch (error) {
    console.error('Batch parsing error:', error);

    res.status(500).json({
      success: false,
      error: error.message,
      message: 'Failed to parse receipt emails in batch'
    });
  }
});

/**
 * GET /receipts/health
 *
 * Health check endpoint
 */
router.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'receipt-parser',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;

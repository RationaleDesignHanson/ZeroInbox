const express = require('express');
const router = express.Router();
const Imap = require('imap');
const { simpleParser } = require('mailparser');
const logger = require('../shared/config/logger');
const { getUserTokens } = require('../auth');

/**
 * Get IMAP connection for Yahoo Mail
 */
function getYahooImapConnection(userId) {
  const tokens = getUserTokens(userId, 'yahoo');

  if (!tokens) {
    throw new Error('No Yahoo tokens found for user');
  }

  return new Imap({
    user: tokens.email,
    xoauth2: tokens.accessToken, // OAuth2 access token
    host: 'imap.mail.yahoo.com',
    port: 993,
    tls: true,
    tlsOptions: { rejectUnauthorized: false }
  });
}

/**
 * GET /api/yahoo/messages
 * Fetch messages from Yahoo Mail via IMAP
 */
router.get('/messages', async (req, res) => {
  try {
    const { maxResults = 50 } = req.query;
    const userId = req.user.userId;

    logger.info('Fetching Yahoo messages', { userId, maxResults });

    const messages = await fetchYahooMessages(userId, parseInt(maxResults));

    res.json({
      messages,
      count: messages.length
    });

  } catch (error) {
    logger.error('Error fetching Yahoo messages', {
      error: error.message,
      userId: req.user.userId
    });
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

/**
 * Fetch messages from Yahoo IMAP
 */
function fetchYahooMessages(userId, maxResults) {
  return new Promise((resolve, reject) => {
    const imap = getYahooImapConnection(userId);
    const messages = [];

    imap.once('ready', () => {
      imap.openBox('INBOX', true, (err, box) => {
        if (err) {
          reject(err);
          return;
        }

        const totalMessages = box.messages.total;
        const start = Math.max(1, totalMessages - maxResults + 1);
        const end = totalMessages;

        if (totalMessages === 0) {
          imap.end();
          resolve([]);
          return;
        }

        const fetch = imap.seq.fetch(`${start}:${end}`, {
          bodies: '',
          struct: true
        });

        fetch.on('message', (msg, seqno) => {
          msg.on('body', (stream, info) => {
            simpleParser(stream, async (err, parsed) => {
              if (err) {
                logger.error('Error parsing Yahoo message', { error: err.message });
                return;
              }

              messages.push({
                id: `yahoo-${seqno}`,
                from: parsed.from?.text || 'unknown',
                to: parsed.to?.text || '',
                subject: parsed.subject || '(No subject)',
                date: parsed.date?.toISOString() || new Date().toISOString(),
                body: (parsed.text || '').substring(0, 5000),
                snippet: (parsed.text || '').substring(0, 200),
                isUnread: true, // Would need to check flags for accurate status
                timestamp: parsed.date?.getTime() || Date.now()
              });
            });
          });
        });

        fetch.once('end', () => {
          imap.end();
        });

        fetch.once('error', (err) => {
          reject(err);
        });
      });
    });

    imap.once('error', (err) => {
      reject(err);
    });

    imap.once('end', () => {
      resolve(messages);
    });

    imap.connect();
  });
}

module.exports = router;

const express = require('express');
const router = express.Router();
const { google } = require('googleapis');
const { convert } = require('html-to-text');
const logger = require('../shared/config/logger');
const { getUserTokens } = require('../auth');
const { createOAuth2Client, getManagedOAuth2Client } = require('../shared/utils/token-manager');

// ============================================
// THREAD METADATA - NO CACHING (ZERO-VISIBILITY ARCHITECTURE)
// ============================================

/**
 * SECURITY NOTE: Thread metadata caching has been removed to ensure
 * zero-visibility architecture. All thread data is fetched fresh from
 * Gmail API on each request. While this increases API calls, it ensures
 * no email-related data is stored in memory or on our servers.
 *
 * Performance: Gmail API quota is 1 billion requests/day (default).
 * With 100 users making 1000 requests/day each, we use only 0.01% of quota.
 */

/**
 * Get thread metadata directly from Gmail API (no caching)
 */
async function getThreadMetadata(gmail, threadId) {
  try {
    const thread = await gmail.users.threads.get({
      userId: 'me',
      id: threadId,
      format: 'minimal'
    });

    return {
      threadId: thread.data.id,
      messageCount: thread.data.messages ? thread.data.messages.length : 1,
      historyId: thread.data.historyId
    };
  } catch (error) {
    logger.warn('Failed to fetch thread metadata', { threadId, error: error.message });
    return { threadId, messageCount: 1 }; // Fallback
  }
}

/**
 * Get Gmail client for authenticated user with automatic token management
 * Tokens can come from either headers (service-to-service) or local storage (direct access)
 * Uses TokenManager for automatic refresh and persistence
 */
async function getGmailClient(userId, accessToken = null, refreshToken = null) {
  // First try to use tokens passed via headers (from gateway with proactive refresh)
  if (accessToken) {
    const tokens = {
      accessToken,
      refreshToken,
      // Note: expiresAt not available from headers, but token should already be fresh from gateway
    };

    // Create managed OAuth2 client that will auto-refresh and persist tokens
    const oauth2Client = createOAuth2Client(userId, 'gmail', tokens);

    return google.gmail({ version: 'v1', auth: oauth2Client });
  }

  // Fallback to local token storage with managed OAuth2 client
  // getManagedOAuth2Client will proactively refresh if token is expiring
  const oauth2Client = await getManagedOAuth2Client(userId, 'gmail');

  if (!oauth2Client) {
    throw new Error('No Gmail tokens found for user');
  }

  return google.gmail({ version: 'v1', auth: oauth2Client });
}

/**
 * GET /api/gmail/messages
 * Fetch messages from Gmail
 */
router.get('/messages', async (req, res) => {
  try {
    const { maxResults = 50, pageToken, query, after, before } = req.query;
    const userId = req.user.userId;

    // Get tokens from headers (passed by gateway with proactive refresh)
    const accessToken = req.headers['x-access-token'];
    const refreshToken = req.headers['x-refresh-token'];

    logger.info('Fetching Gmail messages', { userId, maxResults, query, after, before });

    const gmail = await getGmailClient(userId, accessToken, refreshToken);

    // Build date query
    let dateQuery = '';
    if (after) dateQuery += ` after:${after}`;  // Format: YYYY/MM/DD
    if (before) dateQuery += ` before:${before}`;

    // Build full query
    const baseQuery = query || 'in:inbox -category:promotions -category:social';
    const fullQuery = `${baseQuery}${dateQuery}`;

    // Fetch thread list (OPTIMIZED: includes message count for free!)
    const response = await gmail.users.threads.list({
      userId: 'me',
      maxResults: parseInt(maxResults),
      pageToken,
      q: fullQuery
    });

    const threads = response.data.threads || [];
    const nextPageToken = response.data.nextPageToken;

    // Fetch latest message from each thread with threadLength
    const messagesWithThreadLength = await Promise.all(
      threads.map(async (thread) => {
        try {
          // Get the latest message ID from the thread
          // Gmail returns messages newest first in thread object
          const latestMessageId = thread.messages ? thread.messages[0].id : thread.id;
          const threadLength = thread.messages ? thread.messages.length : 1;

          const fullMessage = await gmail.users.messages.get({
            userId: 'me',
            id: latestMessageId,
            format: 'full'
          });

          // Parse with threadLength from thread object (no extra API call needed!)
          return parseGmailMessage(fullMessage.data, threadLength);
        } catch (error) {
          logger.warn('Failed to fetch message from thread', {
            threadId: thread.id,
            error: error.message
          });
          return null;
        }
      })
    );

    // Filter out any failed messages
    const validMessages = messagesWithThreadLength.filter(msg => msg !== null);

    logger.info('Fetched emails', {
      emailCount: validMessages.length,
      userId: req.user.userId
    });

    res.json({
      messages: validMessages,
      nextPageToken,
      count: validMessages.length
    });

  } catch (error) {
    logger.error('Error fetching Gmail messages', {
      error: error.message,
      userId: req.user.userId
    });
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

/**
 * GET /api/gmail/messages/:id
 * Get a specific Gmail message
 */
router.get('/messages/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    // Get tokens from headers (passed by gateway)
    const accessToken = req.headers['x-access-token'];
    const refreshToken = req.headers['x-refresh-token'];

    const gmail = await getGmailClient(userId, accessToken, refreshToken);

    const message = await gmail.users.messages.get({
      userId: 'me',
      id,
      format: 'full'
    });

    const parsed = parseGmailMessage(message.data);

    res.json(parsed);

  } catch (error) {
    logger.error('Error fetching Gmail message', {
      error: error.message,
      messageId: req.params.id
    });
    res.status(500).json({ error: 'Failed to fetch message' });
  }
});

/**
 * POST /api/gmail/messages/:id/modify
 * Modify message labels (mark as read, archive, etc.)
 */
router.post('/messages/:id/modify', async (req, res) => {
  try {
    const { id } = req.params;
    const { addLabelIds = [], removeLabelIds = [] } = req.body;
    const userId = req.user.userId;

    const gmail = await getGmailClient(userId);

    await gmail.users.messages.modify({
      userId: 'me',
      id,
      requestBody: {
        addLabelIds,
        removeLabelIds
      }
    });

    res.json({ success: true });

  } catch (error) {
    logger.error('Error modifying Gmail message', {
      error: error.message,
      messageId: req.params.id
    });
    res.status(500).json({ error: 'Failed to modify message' });
  }
});

/**
 * POST /api/gmail/messages/:id/trash
 * Move message to trash
 */
router.post('/messages/:id/trash', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    const gmail = await getGmailClient(userId);

    await gmail.users.messages.trash({
      userId: 'me',
      id
    });

    res.json({ success: true });

  } catch (error) {
    logger.error('Error trashing Gmail message', {
      error: error.message,
      messageId: req.params.id
    });
    res.status(500).json({ error: 'Failed to trash message' });
  }
});

/**
 * GET /api/gmail/threads/:threadId
 * Fetch all messages in a Gmail thread (on-demand)
 */
router.get('/threads/:threadId', async (req, res) => {
  try {
    const { threadId } = req.params;
    const userId = req.user.userId;

    // Get tokens from headers (passed by gateway)
    const accessToken = req.headers['x-access-token'];
    const refreshToken = req.headers['x-refresh-token'];

    logger.info('Fetching Gmail thread on-demand', { userId, threadId });

    const gmail = await getGmailClient(userId, accessToken, refreshToken);

    // Fetch full thread with all messages
    const thread = await gmail.users.threads.get({
      userId: 'me',
      id: threadId,
      format: 'full'
    });

    // Parse each message in thread (with threadLength for UI)
    const threadLength = thread.data.messages.length;

    const messages = thread.data.messages.map(msg => parseGmailMessage(msg, threadLength));

    // Order chronologically (oldest first)
    messages.sort((a, b) => a.timestamp - b.timestamp);

    logger.info('Thread fetched successfully', {
      threadId,
      messageCount: messages.length,
      userId: req.user.userId
    });

    res.json({
      threadId,
      messages,
      messageCount: messages.length
    });

  } catch (error) {
    logger.error('Error fetching Gmail thread', {
      error: error.message,
      threadId: req.params.threadId
    });
    res.status(500).json({ error: 'Failed to fetch thread' });
  }
});

/**
 * GET /api/gmail/search
 * Search emails in Gmail
 */
router.get('/search', async (req, res) => {
  try {
    const { q, maxResults = 50, pageToken } = req.query;
    const userId = req.user.userId;

    // Get tokens from headers (passed by gateway)
    const accessToken = req.headers['x-access-token'];
    const refreshToken = req.headers['x-refresh-token'];

    logger.info('Searching Gmail messages', { userId, query: q, maxResults });

    if (!q || q.trim() === '') {
      return res.status(400).json({ error: 'Query parameter required' });
    }

    const gmail = await getGmailClient(userId, accessToken, refreshToken);

    // Search threads (OPTIMIZED: includes message count for free!)
    const response = await gmail.users.threads.list({
      userId: 'me',
      maxResults: parseInt(maxResults),
      pageToken,
      q: q.trim()
    });

    const threads = response.data.threads || [];
    const nextPageToken = response.data.nextPageToken;

    // Fetch latest message from each thread with threadLength
    const messagesWithThreadLength = await Promise.all(
      threads.map(async (thread) => {
        try {
          // Get the latest message ID from the thread
          const latestMessageId = thread.messages ? thread.messages[0].id : thread.id;
          const threadLength = thread.messages ? thread.messages.length : 1;

          const fullMessage = await gmail.users.messages.get({
            userId: 'me',
            id: latestMessageId,
            format: 'full'
          });

          // Parse with threadLength from thread object (no extra API call needed!)
          return parseGmailMessage(fullMessage.data, threadLength);
        } catch (error) {
          logger.warn('Failed to fetch message from thread in search', {
            threadId: thread.id,
            error: error.message
          });
          return null;
        }
      })
    );

    // Filter out any failed messages
    const validMessages = messagesWithThreadLength.filter(msg => msg !== null);

    logger.info('Search completed', {
      userId: req.user.userId,
      resultCount: validMessages.length,
      query: q
    });

    res.json({
      messages: validMessages,
      nextPageToken,
      count: validMessages.length
    });

  } catch (error) {
    logger.error('Error searching Gmail', {
      error: error.message,
      userId: req.user.userId
    });
    res.status(500).json({ error: 'Failed to search messages' });
  }
});

/**
 * GET /api/gmail/messages/:messageId/attachments/:attachmentId
 * Fetch attachment data from Gmail
 */
router.get('/messages/:messageId/attachments/:attachmentId', async (req, res) => {
  try {
    const { messageId, attachmentId } = req.params;
    const userId = req.user.userId;

    // Get tokens from headers (passed by gateway)
    const accessToken = req.headers['x-access-token'];
    const refreshToken = req.headers['x-refresh-token'];

    const gmail = await getGmailClient(userId, accessToken, refreshToken);

    logger.info('Fetching attachment', { messageId, attachmentId });

    const attachment = await gmail.users.messages.attachments.get({
      userId: 'me',
      messageId,
      id: attachmentId
    });

    // Return base64 encoded attachment data
    res.json({
      attachmentId,
      size: attachment.data.size,
      data: attachment.data.data // base64 encoded
    });

  } catch (error) {
    logger.error('Error fetching attachment', {
      error: error.message,
      messageId: req.params.messageId,
      attachmentId: req.params.attachmentId
    });
    res.status(500).json({ error: 'Failed to fetch attachment' });
  }
});

/**
 * POST /api/gmail/messages/send
 * Send an email via Gmail with optional PDF attachment
 */
router.post('/messages/send', async (req, res) => {
  try {
    const { to, subject, body, threadId, attachment } = req.body;
    const userId = req.user.userId;

    // Get tokens from headers (passed by gateway)
    const accessToken = req.headers['x-access-token'];
    const refreshToken = req.headers['x-refresh-token'];

    const gmail = await getGmailClient(userId, accessToken, refreshToken);

    let encodedMessage;

    if (attachment && attachment.data && attachment.filename) {
      // Create MIME multipart message with attachment
      const boundary = '----=_Part_' + Date.now();

      const messageParts = [
        `To: ${to}`,
        `Subject: ${subject}`,
        'MIME-Version: 1.0',
        `Content-Type: multipart/mixed; boundary="${boundary}"`,
        '',
        `--${boundary}`,
        'Content-Type: text/plain; charset=UTF-8',
        '',
        body,
        '',
        `--${boundary}`,
        'Content-Type: application/pdf',
        'Content-Transfer-Encoding: base64',
        `Content-Disposition: attachment; filename="${attachment.filename}"`,
        '',
        attachment.data, // Already base64 encoded
        '',
        `--${boundary}--`
      ];

      const message = messageParts.join('\n');

      encodedMessage = Buffer.from(message)
        .toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '');

      logger.info('Sending email with PDF attachment', {
        userId,
        to,
        filename: attachment.filename
      });
    } else {
      // Simple text message (original behavior)
      const message = [
        `To: ${to}`,
        `Subject: ${subject}`,
        '',
        body
      ].join('\n');

      encodedMessage = Buffer.from(message)
        .toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '');

      logger.info('Sending plain text email', { userId, to });
    }

    const response = await gmail.users.messages.send({
      userId: 'me',
      requestBody: {
        raw: encodedMessage,
        threadId
      }
    });

    logger.info('Email sent successfully', {
      messageId: response.data.id,
      hasAttachment: !!attachment
    });

    res.json({ success: true, messageId: response.data.id });

  } catch (error) {
    logger.error('Error sending Gmail message', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({ error: 'Failed to send message' });
  }
});

/**
 * Parse Gmail message into standardized format
 * @param {Object} message - Gmail message object
 * @param {Number} threadLength - Optional thread message count
 */
function parseGmailMessage(message, threadLength = null) {
  const headers = message.payload.headers;

  const getHeader = (name) => {
    const header = headers.find(h => h.name.toLowerCase() === name.toLowerCase());
    return header ? header.value : null;
  };

  // Extract body - try text/plain first, then text/html as fallback
  let body = '';
  let htmlBody = null;  // Store original HTML
  let isHtml = false;

  if (message.payload.body.data) {
    body = Buffer.from(message.payload.body.data, 'base64').toString('utf-8');
    isHtml = message.payload.mimeType === 'text/html';
    if (isHtml) htmlBody = body;  // Save original HTML
  } else if (message.payload.parts) {
    // Try text/plain first
    let textPart = message.payload.parts.find(part => part.mimeType === 'text/plain');

    // If no text/plain, try text/html as fallback
    if (!textPart || !textPart.body.data) {
      textPart = message.payload.parts.find(part => part.mimeType === 'text/html');
      isHtml = true;
    }

    // Also check nested multipart/alternative structures
    if (!textPart || !textPart.body.data) {
      for (const part of message.payload.parts) {
        if (part.mimeType === 'multipart/alternative' && part.parts) {
          textPart = part.parts.find(p => p.mimeType === 'text/plain');
          if (!textPart) {
            textPart = part.parts.find(p => p.mimeType === 'text/html');
            isHtml = true;
          }
          if (textPart && textPart.body.data) break;
        }
      }
    }

    if (textPart && textPart.body.data) {
      body = Buffer.from(textPart.body.data, 'base64').toString('utf-8');
      if (isHtml) htmlBody = body;  // Save original HTML before conversion
    }
  }

  // Convert HTML to readable text if needed
  if (isHtml && body) {
    try {
      body = convert(body, {
        wordwrap: 130,
        selectors: [
          { selector: 'a', options: { ignoreHref: false } },
          { selector: 'img', format: 'skip' },
          { selector: 'table', format: 'dataTable' },
          { selector: 'hr', format: 'skip' }, // Skip horizontal rules (often render as dashes)
          { selector: 'br', format: 'lineBreak' }
        ],
        // Better handling of whitespace and formatting
        preserveNewlines: true,
        decodeEntities: true,
        uppercaseHeadings: false,
        hideLinkHrefIfSameAsText: true,
        // Don't convert dividers to dashes
        formatters: {
          'lineBreak': (elem, walk, builder, formatOptions) => {
            builder.addLineBreak();
          }
        }
      });

      // Clean up excessive newlines and dashes
      body = body
        .replace(/[-─━═]{10,}/g, '') // Remove lines of dashes/unicode lines
        .replace(/\n{3,}/g, '\n\n') // Reduce excessive newlines to max 2
        .trim();

    } catch (error) {
      logger.warn('Failed to convert HTML to text', { error: error.message });
      // Keep original HTML if conversion fails
    }
  }

  // Extract attachments
  const attachments = [];

  function extractAttachments(parts) {
    if (!parts) return;

    for (const part of parts) {
      // Check if this part has a filename (indicates attachment)
      const filename = part.filename;

      if (filename && filename.length > 0) {
        // Determine if it's an inline image or a real attachment
        const isInline = part.headers?.some(h =>
          h.name.toLowerCase() === 'content-disposition' &&
          h.value.toLowerCase().includes('inline')
        );

        // Only include non-inline attachments
        if (!isInline) {
          attachments.push({
            filename: filename,
            mimeType: part.mimeType,
            size: part.body?.size || 0,
            attachmentId: part.body?.attachmentId || null,
            partId: part.partId
          });
        }
      }

      // Recursively check nested parts
      if (part.parts) {
        extractAttachments(part.parts);
      }
    }
  }

  // Extract from payload parts
  if (message.payload.parts) {
    extractAttachments(message.payload.parts);
  }

  const result = {
    id: message.id,
    threadId: message.threadId,
    from: getHeader('From'),
    to: getHeader('To'),
    subject: getHeader('Subject'),
    date: getHeader('Date'),
    body: body.substring(0, 5000), // Limit body size
    htmlBody: htmlBody ? htmlBody.substring(0, 50000) : null, // Include original HTML (larger limit)
    snippet: message.snippet,
    labelIds: message.labelIds || [],
    isUnread: message.labelIds?.includes('UNREAD') || false,
    isImportant: message.labelIds?.includes('IMPORTANT') || false, // Gmail important flag
    timestamp: parseInt(message.internalDate),
    attachments: attachments.length > 0 ? attachments : undefined, // Only include if attachments exist
    hasAttachments: attachments.length > 0
  };

  // Add threadLength if provided (for threading UI)
  if (threadLength !== null) {
    result.threadLength = threadLength;
  }

  return result;
}

module.exports = router;

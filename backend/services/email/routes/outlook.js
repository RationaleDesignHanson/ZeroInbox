const express = require('express');
const router = express.Router();
const { Client } = require('@microsoft/microsoft-graph-client');
const logger = require('../shared/config/logger');
const { getUserTokens } = require('../auth');

/**
 * Get Microsoft Graph client for authenticated user
 */
function getGraphClient(userId) {
  const tokens = getUserTokens(userId, 'outlook');

  if (!tokens) {
    throw new Error('No Outlook tokens found for user');
  }

  return Client.init({
    authProvider: (done) => {
      done(null, tokens.accessToken);
    }
  });
}

/**
 * GET /api/outlook/messages
 * Fetch messages from Outlook
 */
router.get('/messages', async (req, res) => {
  try {
    const { maxResults = 50, skip = 0, filter } = req.query;
    const userId = req.user.userId;

    logger.info('Fetching Outlook messages', { userId, maxResults });

    const client = getGraphClient(userId);

    let query = client
      .api('/me/messages')
      .top(parseInt(maxResults))
      .skip(parseInt(skip))
      .select('id,subject,from,toRecipients,receivedDateTime,bodyPreview,body,isRead,importance');

    if (filter) {
      query = query.filter(filter);
    }

    const response = await query.get();

    const messages = response.value.map(parseOutlookMessage);

    res.json({
      messages,
      count: messages.length,
      nextSkip: parseInt(skip) + messages.length
    });

  } catch (error) {
    logger.error('Error fetching Outlook messages', {
      error: error.message,
      userId: req.user.userId
    });
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

/**
 * GET /api/outlook/messages/:id
 * Get a specific Outlook message
 */
router.get('/messages/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    const client = getGraphClient(userId);

    const message = await client
      .api(`/me/messages/${id}`)
      .select('id,subject,from,toRecipients,receivedDateTime,bodyPreview,body,isRead,importance')
      .get();

    const parsed = parseOutlookMessage(message);

    res.json(parsed);

  } catch (error) {
    logger.error('Error fetching Outlook message', {
      error: error.message,
      messageId: req.params.id
    });
    res.status(500).json({ error: 'Failed to fetch message' });
  }
});

/**
 * PATCH /api/outlook/messages/:id
 * Update message properties (mark as read, etc.)
 */
router.patch('/messages/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    const userId = req.user.userId;

    const client = getGraphClient(userId);

    await client
      .api(`/me/messages/${id}`)
      .patch(updates);

    res.json({ success: true });

  } catch (error) {
    logger.error('Error updating Outlook message', {
      error: error.message,
      messageId: req.params.id
    });
    res.status(500).json({ error: 'Failed to update message' });
  }
});

/**
 * DELETE /api/outlook/messages/:id
 * Delete a message
 */
router.delete('/messages/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    const client = getGraphClient(userId);

    await client
      .api(`/me/messages/${id}`)
      .delete();

    res.json({ success: true });

  } catch (error) {
    logger.error('Error deleting Outlook message', {
      error: error.message,
      messageId: req.params.id
    });
    res.status(500).json({ error: 'Failed to delete message' });
  }
});

/**
 * POST /api/outlook/messages/send
 * Send an email via Outlook
 */
router.post('/messages/send', async (req, res) => {
  try {
    const { to, subject, body } = req.body;
    const userId = req.user.userId;

    const client = getGraphClient(userId);

    const message = {
      message: {
        subject,
        body: {
          contentType: 'Text',
          content: body
        },
        toRecipients: [
          {
            emailAddress: {
              address: to
            }
          }
        ]
      }
    };

    await client
      .api('/me/sendMail')
      .post(message);

    res.json({ success: true });

  } catch (error) {
    logger.error('Error sending Outlook message', { error: error.message });
    res.status(500).json({ error: 'Failed to send message' });
  }
});

/**
 * POST /api/outlook/messages/:id/reply
 * Reply to a message
 */
router.post('/messages/:id/reply', async (req, res) => {
  try {
    const { id } = req.params;
    const { body } = req.body;
    const userId = req.user.userId;

    const client = getGraphClient(userId);

    await client
      .api(`/me/messages/${id}/reply`)
      .post({
        comment: body
      });

    res.json({ success: true });

  } catch (error) {
    logger.error('Error replying to Outlook message', {
      error: error.message,
      messageId: req.params.id
    });
    res.status(500).json({ error: 'Failed to reply to message' });
  }
});

/**
 * Parse Outlook message into standardized format
 */
function parseOutlookMessage(message) {
  return {
    id: message.id,
    from: message.from?.emailAddress?.address || 'unknown',
    fromName: message.from?.emailAddress?.name || '',
    to: message.toRecipients?.map(r => r.emailAddress.address).join(', ') || '',
    subject: message.subject || '(No subject)',
    date: message.receivedDateTime,
    body: message.body?.content?.substring(0, 5000) || '', // Limit body size
    bodyPreview: message.bodyPreview || '',
    snippet: message.bodyPreview || '',
    isUnread: !message.isRead,
    isImportant: message.importance === 'high', // Outlook importance: low, normal, high
    timestamp: new Date(message.receivedDateTime).getTime()
  };
}

module.exports = router;

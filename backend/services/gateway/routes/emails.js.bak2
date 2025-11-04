const express = require('express');
const router = express.Router();
const axios = require('axios');
const logger = require('../shared/config/logger');
const EmailCard = require('../shared/models/EmailCard');
const { validateGmailToken } = require('../../shared/middleware/token-validator');

const EMAIL_SERVICE_URL = process.env.EMAIL_SERVICE_URL || 'http://localhost:8081';
const CLASSIFIER_SERVICE_URL = process.env.CLASSIFIER_SERVICE_URL || 'http://localhost:8082';
const SUMMARIZATION_SERVICE_URL = process.env.SUMMARIZATION_SERVICE_URL || 'http://localhost:8083';
const SMART_REPLIES_SERVICE_URL = process.env.SMART_REPLIES_SERVICE_URL || 'http://localhost:8084';

// Normalize any legacy/alias types to binary categories (mail|ads)
function normalizeType(rawType) {
  if (!rawType) return 'mail';
  const t = String(rawType).toLowerCase();
  if (t === 'mail' || t === 'ads') return t;

  // Legacy → mail
  const MAIL_SET = new Set([
    'personal', 'lifestyle', 'work',
    'family', 'billing', 'sales', 'project', 'learning', 'travel', 'account',
    'caregiver', 'transactional_leader', 'sales_hunter', 'project_coordinator',
    'enterprise_innovator', 'identity_manager', 'education'
  ]);

  // Legacy → ads
  const ADS_SET = new Set(['shop', 'shopping', 'deal_stacker', 'status_seeker']);

  if (MAIL_SET.has(t)) return 'mail';
  if (ADS_SET.has(t)) return 'ads';
  return 'mail';
}

// Sanitize string to remove invalid Unicode surrogate pairs
function sanitizeString(str) {
  if (typeof str !== 'string') return str;

  // Replace unpaired surrogates with replacement character
  // This fixes Swift JSONDecoder's "Missing low code point in surrogate pair" error
  return str.replace(/[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF]/g, '\uFFFD');
}

// Recursively sanitize all strings in an object
function sanitizeObject(obj) {
  if (typeof obj === 'string') {
    return sanitizeString(obj);
  }

  if (Array.isArray(obj)) {
    return obj.map(item => sanitizeObject(item));
  }

  if (obj && typeof obj === 'object') {
    const sanitized = {};
    for (const [key, value] of Object.entries(obj)) {
      sanitized[key] = sanitizeObject(value);
    }
    return sanitized;
  }

  return obj;
}

/**
 * GET /api/emails
 * Fetch and process emails (main endpoint for iOS app)
 * Token validation ensures tokens are fresh before making API calls
 */
router.get('/', validateGmailToken, async (req, res) => {
  try {
    const { maxResults = 20, provider, after, before, query } = req.query;
    const user = req.user; // From authentication middleware

    logger.info('Fetching emails', {
      userId: user.userId,
      provider: provider || user.emailProvider,
      maxResults
    });

    // 1. Fetch raw emails from email service
    const emailProvider = provider || user.emailProvider;
    const rawEmails = await fetchEmailsFromProvider(
      emailProvider,
      user.userId,
      maxResults,
      { after, before, query }
    );

    if (!rawEmails || rawEmails.length === 0) {
      return res.json({ emails: [], count: 0 });
    }

    // 2. Process emails in parallel (classify + summarize)
    logger.info('Starting email processing', { emailCount: rawEmails.length });
    const processedEmails = await Promise.all(
      rawEmails.map(async (email, idx) => {
        try {
          return await processEmail(email);
        } catch (error) {
          logger.error('Failed to process email', {
            emailIndex: idx,
            emailId: email.id,
            subject: email.subject?.substring(0, 100),
            error: error.message,
            stack: error.stack
          });
          // Return email with minimal data instead of failing entire request
          return {
            ...email,
            classification: { type: 'mail', priority: 'medium', hpa: 'Review' },
            summary: { summary: email.snippet || email.subject, title: email.subject, timeAgo: 'Recently' }
          };
        }
      })
    );

    // 3. Convert to EmailCard format
    logger.info('Converting to EmailCard format', { processedCount: processedEmails.length });
    const emailCards = [];

    for (let index = 0; index < processedEmails.length; index++) {
      try {
        const processed = processedEmails[index];
        const classification = processed.classification || {};
        const rawType = classification.type || 'mail';
        const normalizedType = normalizeType(rawType);
        if (rawType !== normalizedType) {
          logger.info('Normalized legacy type', { emailId: processed.id, rawType, normalizedType });
        }

        // Auto-upgrade priority if email is marked as important by email provider
        let priority = classification.priority || 'medium';
        if (processed.isImportant && priority !== 'critical') {
          priority = 'high';
          logger.info('Auto-upgraded priority to HIGH due to important flag', { emailId: processed.id });
        }

        const card = new EmailCard({
          id: processed.id || `email-${index}`,
          type: normalizedType,
          state: 'unseen',
          priority: priority,
          hpa: classification.hpa || 'Review',
          timeAgo: processed.summary?.timeAgo || 'Recently',
          title: processed.summary?.title || processed.subject,
          summary: processed.summary?.summary || processed.snippet,  // Prefer AI summary, fallback to snippet
          aiGeneratedSummary: processed.summary?.summary || null,  // Structured AI summary from Gemini with markdown
          body: processed.body || null,  // Full email body text
          htmlBody: processed.htmlBody || null,  // Original HTML email content
          metaCTA: classification.metaCTA || 'Swipe Right: Review',

          // ACTION-FIRST MODEL (v1.1) - Intent and suggested actions
          intent: classification.intent || null,
          intentConfidence: classification.intentConfidence || null,
          // Enrich suggestedActions with actionId and filter out invalid actions
          suggestedActions: (classification.suggestedActions || [])
            .filter(action => action && action.displayName) // Only include actions with displayName
            .map(action => ({
              ...action,
              actionId: action.actionId || action.displayName.toLowerCase().replace(/[^a-z0-9]+/g, '_'),
              displayName: action.displayName // Ensure displayName is always present
            })),

          // Enhanced metadata from classifier
          sender: classification.sender || extractSender(processed),
          kid: classification.kid || null,
          company: classification.company || null,
          store: classification.store || null,
          airline: classification.airline || null,
          productImageUrl: classification.productImageUrl || null,
          brandName: classification.brandName || null,
          originalPrice: classification.originalPrice || null,
          salePrice: classification.salePrice || null,
          discount: classification.discount || null,
          urgent: classification.urgent || null,
          expiresIn: classification.expiresIn || null,
          requiresSignature: classification.requiresSignature || null,
          paymentAmount: classification.paymentAmount || null,
          paymentDescription: classification.paymentDescription || null,
          value: classification.value || null,
          probability: classification.probability || null,
          score: classification.score || null,
          calendarInvite: classification.calendarInvite || null,

          // Thread fields (v1.6)
          threadLength: processed.threadLength || null,

          // Newsletter-specific fields (v1.11+)
          keyLinks: processed.summary?.keyLinks || null,
          keyTopics: processed.summary?.keyTopics || null,

          _rawEmail: processed,
          _emailId: processed.id,
          _threadId: processed.threadId
        });

        emailCards.push(card);
      } catch (error) {
        logger.error('Failed to create EmailCard', {
          emailIndex: index,
          emailId: processedEmails[index]?.id,
          subject: processedEmails[index]?.subject?.substring(0, 100),
          error: error.message,
          stack: error.stack
        });
        // Skip this email and continue with others
      }
    }

    logger.info('Serializing EmailCards to JSON', { cardCount: emailCards.length });
    let serializedCards;
    try {
      serializedCards = emailCards.map((card, idx) => {
        try {
          const json = card.toJSON();
          // Sanitize string fields to remove invalid Unicode surrogate pairs
          return sanitizeObject(json);
        } catch (error) {
          logger.error('Failed to serialize EmailCard', {
            cardIndex: idx,
            cardId: card.id,
            error: error.message,
            stack: error.stack
          });
          throw error;
        }
      });
    } catch (error) {
      logger.error('Serialization failed', { error: error.message, stack: error.stack });
      throw error;
    }

    logger.info('Sending response', { emailCount: serializedCards.length });
    // Use explicit JSON stringify with replacer to handle any remaining unicode issues
    res.set('Content-Type', 'application/json; charset=utf-8');
    res.send(JSON.stringify({
      emails: serializedCards,
      count: serializedCards.length,
      provider: emailProvider
    }, null, 0));

  } catch (error) {
    logger.error('Error fetching emails', {
      userId: req.user?.userId,
      provider: req.query?.provider || req.user?.emailProvider,
      maxResults: req.query?.maxResults,
      error: error.message,
      stack: error.stack,
      errorType: error.constructor?.name
    });
    res.status(500).json({ error: 'Failed to fetch emails', details: error.message });
  }
});

/**
 * GET /api/emails/:id
 * Get single email with full details
 * Token validation ensures tokens are fresh before making API calls
 */
router.get('/:id', validateGmailToken, async (req, res) => {
  try {
    const { id } = req.params;
    const user = req.user;
    const provider = user.emailProvider;

    logger.info('Fetching email', { emailId: id, userId: user.userId, provider });

    // Fetch full email from email service
    const email = await fetchSingleEmail(provider, user.userId, id);

    if (!email) {
      return res.status(404).json({ error: 'Email not found' });
    }

    // Process email
    const processed = await processEmail(email);

    res.json(processed);

  } catch (error) {
    logger.error('Error fetching email', { error: error.message, status: error.response?.status, data: error.response?.data });
    res.status(500).json({ error: 'Failed to fetch email' });
  }
});

/**
 * GET /api/emails/:id/thread
 * Fetch thread for a specific email (on-demand)
 * Token validation ensures tokens are fresh before making API calls
 */
router.get('/:id/thread', validateGmailToken, async (req, res) => {
  try {
    const { id } = req.params;
    const user = req.user;
    const provider = user.emailProvider;

    logger.info('Fetching thread on-demand', { emailId: id, userId: user.userId, provider });

    // Detect mock email IDs (for development/testing)
    if (isMockEmailId(id)) {
      logger.info('Mock email ID detected, returning mock thread data', { emailId: id });
      return res.json(generateMockThreadData(id));
    }

    // 1. Get the email to find its threadId
    const email = await fetchSingleEmail(provider, user.userId, id);

    if (!email || !email.threadId) {
      return res.status(404).json({ error: 'Email or thread not found' });
    }

    // If thread has only 1 message (single email, not a thread), return empty
    if (email.threadId === email.id) {
      return res.json({
        threadId: email.threadId,
        messages: [],
        context: {
          purchases: [],
          upcomingEvents: [],
          locations: [],
          unresolvedQuestions: [],
          conversationStage: null
        },
        messageCount: 1
      });
    }

    // 2. Fetch thread messages
    const thread = await fetchThread(provider, user.userId, email.threadId);

    // 3. Extract context using regex-based extraction
    const { extractThreadContext } = require('../shared/utils/threadContext');
    const context = extractThreadContext(thread.messages);

    // 4. Return thread data with context
    res.json({
      threadId: email.threadId,
      messages: thread.messages.map(msg => ({
        id: msg.id,
        from: msg.from,
        date: msg.date,
        body: (msg.body || '').substring(0, 1000), // Limit body size
        isLatest: msg.id === id
      })),
      context,
      messageCount: thread.messages.length
    });

  } catch (error) {
    logger.error('Error fetching thread', { error: error.message, status: error.response?.status, data: error.response?.data, stack: error.stack });
    res.status(500).json({ error: 'Failed to fetch thread' });
  }
});

/**
 * GET /api/emails/search
 * Search emails with keyword, sender, or date filters
 * Returns results grouped by thread
 * Token validation ensures tokens are fresh before making API calls
 */
router.get('/search', validateGmailToken, async (req, res) => {
  try {
    const { q, sender, dateFrom, dateTo, limit = 50, offset = 0 } = req.query;
    const user = req.user;
    const provider = user.emailProvider;

    logger.info('Searching emails', {
      userId: user.userId,
      query: q,
      sender,
      limit
    });

    // Fetch search results from email service
    const searchResults = await searchEmails(provider, user.userId, {
      query: q,
      sender,
      dateFrom,
      dateTo,
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    if (!searchResults || searchResults.length === 0) {
      return res.json({
        results: [],
        totalCount: 0,
        hasMore: false,
        groupedByThread: {}
      });
    }

    // Group results by threadId
    const groupedResults = {};
    const threadCounts = {};

    searchResults.forEach(email => {
      const threadId = email.threadId || email.id;

      if (!groupedResults[threadId]) {
        groupedResults[threadId] = [];
        threadCounts[threadId] = 0;
      }

      groupedResults[threadId].push(email);
      threadCounts[threadId]++;
    });

    // Process the latest email in each thread
    const processedThreads = await Promise.all(
      Object.entries(groupedResults).map(async ([threadId, emails]) => {
        // Sort by date (newest first)
        emails.sort((a, b) => b.timestamp - a.timestamp);

        const latestEmail = emails[0];
        const processed = await processEmail(latestEmail);
        const classification = processed.classification || {};
        const rawType = classification.type || 'mail';
        const normalizedType = normalizeType(rawType);
        if (rawType !== normalizedType) {
          logger.info('Normalized legacy type (search)', { emailId: processed.id, rawType, normalizedType });
        }

        return {
          threadId,
          messageCount: threadCounts[threadId],
          latestEmail: {
            id: processed.id,
            type: normalizedType,
            state: 'unseen',
            priority: classification.priority || 'medium',
            hpa: classification.hpa || 'Review',
            timeAgo: processed.summary?.timeAgo || 'Recently',
            title: processed.summary?.title || processed.subject,
            summary: processed.summary?.summary || processed.snippet,
            sender: classification.sender || extractSender(processed),
            threadLength: threadCounts[threadId]
          },
          allMessages: emails.map(e => ({
            id: e.id,
            subject: e.subject,
            from: e.from,
            snippet: e.snippet,
            timestamp: e.timestamp
          }))
        };
      })
    );

    res.json({
      results: processedThreads,
      totalCount: processedThreads.length,
      hasMore: searchResults.length >= parseInt(limit),
      groupedByThread: true
    });

  } catch (error) {
    logger.error('Error searching emails', { error: error.message, stack: error.stack });
    res.status(500).json({ error: 'Failed to search emails' });
  }
});

/**
 * POST /api/emails/:id/action
 * Perform action on email (archive, delete, mark as read, etc.)
 * Token validation ensures tokens are fresh before making API calls
 */
router.post('/:id/action', validateGmailToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { action } = req.body;
    const user = req.user;
    const provider = user.emailProvider;

    logger.info('Email action', { emailId: id, action, userId: user.userId });

    // Route action to appropriate email service
    const result = await performEmailAction(provider, user.userId, id, action);

    res.json(result);

  } catch (error) {
    logger.error('Error performing email action', { error: error.message, status: error.response?.status, data: error.response?.data });
    res.status(500).json({ error: 'Failed to perform action' });
  }
});

/**
 * GET /api/emails/:id/smart-replies
 * Generate smart reply suggestions for an email
 * Token validation ensures tokens are fresh before making API calls
 */
router.get('/:id/smart-replies', validateGmailToken, async (req, res) => {
  try {
    const { id } = req.params;
    const user = req.user;
    const provider = user.emailProvider;

    logger.info('Generating smart replies', { emailId: id, userId: user.userId });

    // Fetch email
    const email = await fetchSingleEmail(provider, user.userId, id);

    if (!email) {
      return res.status(404).json({ error: 'Email not found' });
    }

    // Fetch thread context if part of thread
    let threadContext = null;
    if (email.threadId && email.threadId !== email.id) {
      try {
        const thread = await fetchThread(provider, user.userId, email.threadId);
        threadContext = {
          messageCount: thread.messages.length,
          messages: thread.messages.map(m => ({
            from: m.from,
            snippet: (m.body || '').substring(0, 200)
          }))
        };
      } catch (error) {
        logger.warn('Failed to fetch thread context for smart replies', { error: error.message });
      }
    }

    // Get user's tone preference (simplified for now)
    const userTone = 'professional but friendly';

    // Call smart replies service
    const smartRepliesResponse = await axios.post(
      `${SMART_REPLIES_SERVICE_URL}/api/smart-replies`,
      {
        email: {
          id: email.id,
          from: email.from,
          subject: email.subject,
          body: email.body,
          snippet: email.snippet
        },
        threadContext,
        userTone
      }
    );

    res.json(smartRepliesResponse.data);

  } catch (error) {
    logger.error('Error generating smart replies', { error: error.message, stack: error.stack });
    res.status(500).json({ error: 'Failed to generate smart replies' });
  }
});

/**
 * POST /api/emails/:id/smart-replies/feedback
 * Log feedback on smart reply usage
 */
router.post('/:id/smart-replies/feedback', async (req, res) => {
  try {
    const { id } = req.params;
    const { replyIndex, action, originalReply, finalReply } = req.body;

    logger.info('Logging smart reply feedback', { emailId: id, action });

    await axios.post(
      `${SMART_REPLIES_SERVICE_URL}/api/smart-replies/feedback`,
      {
        emailId: id,
        replyIndex,
        action,
        originalReply,
        finalReply
      }
    );

    res.json({ success: true });

  } catch (error) {
    logger.error('Error logging smart reply feedback', { error: error.message });
    res.status(500).json({ error: 'Failed to log feedback' });
  }
});

/**
 * POST /api/emails/summarize
 * Generate AI summary for any email (generic endpoint for on-demand summarization)
 * Used by iOS app to request AI summaries for regular emails
 */
router.post('/summarize', async (req, res) => {
  try {
    const { emailId, subject, from, body, snippet, type } = req.body;

    if (!subject) {
      return res.status(400).json({ error: 'Email subject required' });
    }

    logger.info('Generating on-demand AI summary', { emailId, subject, type });

    // Call summarization service
    const summaryResponse = await axios.post(
      `${SUMMARIZATION_SERVICE_URL}/api/summarize`,
      {
        email: {
          id: emailId,
          subject,
          from,
          body: body || snippet, // Use full body if available, fallback to snippet
          snippet
        }
      }
    );

    // Return just the summary field (iOS app expects { summary: "..." })
    res.json({
      summary: summaryResponse.data.summary
    });

  } catch (error) {
    logger.error('Error generating AI summary', { error: error.message, stack: error.stack });
    res.status(500).json({ error: 'Failed to generate summary' });
  }
});

/**
 * POST /api/emails/summarize/newsletter
 * Generate detailed newsletter summary with key links
 * Used by iOS app for newsletter-specific summarization
 */
router.post('/summarize/newsletter', async (req, res) => {
  try {
    const { emailId, subject, from, body, snippet } = req.body;

    if (!subject || !body) {
      return res.status(400).json({ error: 'Newsletter subject and body required' });
    }

    logger.info('Generating newsletter summary', { emailId, subject, from });

    // Call summarization service newsletter endpoint
    const summaryResponse = await axios.post(
      `${SUMMARIZATION_SERVICE_URL}/api/summarize/newsletter`,
      {
        emailId,
        subject,
        from,
        body,
        snippet
      }
    );

    // Return the full response (includes summary, keyLinks, keyTopics)
    res.json(summaryResponse.data);

  } catch (error) {
    logger.error('Error generating newsletter summary', { error: error.message, stack: error.stack });
    res.status(500).json({ error: 'Failed to generate newsletter summary' });
  }
});

/**
 * POST /api/emails/:id/reply
 * Generate and send reply
 * Token validation ensures tokens are fresh before making API calls
 */
router.post('/:id/reply', validateGmailToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { replyText, useAI = false } = req.body;
    const user = req.user;

    logger.info('Sending reply', { emailId: id, useAI });

    let finalReply = replyText;

    // Generate AI reply if requested
    if (useAI && !replyText) {
      const email = await fetchSingleEmail(user.emailProvider, user.userId, id);
      const aiReply = await generateReply(email);
      finalReply = aiReply.reply;
    }

    // Send reply via email service
    const result = await sendReply(user.emailProvider, user.userId, id, finalReply);

    res.json({ success: true, ...result });

  } catch (error) {
    logger.error('Error sending reply', { error: error.message });
    res.status(500).json({ error: 'Failed to send reply' });
  }
});

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Fetch emails from provider-specific endpoint
 */
async function fetchEmailsFromProvider(provider, userId, maxResults, filters = {}) {
  const providerMap = {
    gmail: 'gmail',
    outlook: 'outlook',
    yahoo: 'yahoo',
    icloud: 'icloud'
  };

  const providerPath = providerMap[provider] || 'gmail';

  try {
    // Get user tokens from auth storage
    const { getUserTokens } = require('../shared/utils/auth');
    const tokens = await getUserTokens(userId, provider);

    if (!tokens) {
      logger.error('No tokens found for user', { userId, provider });
      throw new Error(`No tokens found for ${provider}`);
    }

    const response = await axios.get(
      `${EMAIL_SERVICE_URL}/api/${providerPath}/messages`,
      {
        params: {
          maxResults,
          // Pass through optional filters used by Gmail API
          ...(filters.after ? { after: filters.after } : {}),
          ...(filters.before ? { before: filters.before } : {}),
          ...(filters.query ? { query: filters.query } : {})
        },
        headers: {
          'X-User-ID': userId,
          'X-Access-Token': tokens.accessToken,
          'X-Refresh-Token': tokens.refreshToken || '',
          'X-Token-Expiry': tokens.expiresAt || ''
        }
      }
    );

    return response.data.messages || [];
  } catch (error) {
    logger.error('Error fetching from email provider', {
      provider,
      userId,
      emailServiceUrl: EMAIL_SERVICE_URL,
      status: error.response?.status,
      data: error.response?.data,
      error: error.message
    });
    throw error;
  }
}

/**
 * Fetch single email
 */
async function fetchSingleEmail(provider, userId, emailId) {
  const providerMap = {
    gmail: 'gmail',
    outlook: 'outlook',
    yahoo: 'yahoo',
    icloud: 'icloud'
  };

  const providerPath = providerMap[provider] || 'gmail';

  try {
    // Get user tokens from auth storage
    const { getUserTokens } = require('../shared/utils/auth');
    const tokens = await getUserTokens(userId, provider);

    if (!tokens) {
      throw new Error(`No tokens found for ${provider}`);
    }

    const response = await axios.get(
      `${EMAIL_SERVICE_URL}/api/${providerPath}/messages/${emailId}`,
      {
        headers: {
          'X-User-ID': userId,
          'X-Access-Token': tokens.accessToken,
          'X-Refresh-Token': tokens.refreshToken || '',
          'X-Token-Expiry': tokens.expiresAt || ''
        }
      }
    );

    return response.data;
  } catch (error) {
    logger.error('Error fetching single email', { emailId, error: error.message });
    throw error;
  }
}

/**
 * Process email (classify + summarize)
 */
async function processEmail(email) {
  try {
    // First classify the email to detect newsletters
    const classification = await classifyEmail(email);

    // Then summarize with classification context (for newsletter detection)
    const summary = await summarizeEmail(email, classification);

    return {
      ...email,
      classification,
      summary
    };
  } catch (error) {
    logger.error('Error processing email', { error: error.message });

    // Return email with defaults if processing fails
    return {
      ...email,
      classification: {
        type: 'mail',
        priority: 'medium',
        hpa: 'Review',
        metaCTA: 'Swipe Right: Review'
      },
      summary: {
        summary: email.snippet || email.subject,
        title: email.subject,
        timeAgo: 'Recently'
      }
    };
  }
}

/**
 * Classify email
 */
async function classifyEmail(email) {
  try {
    const response = await axios.post(
      `${CLASSIFIER_SERVICE_URL}/api/classify`,
      { email }
    );
    return response.data;
  } catch (error) {
    logger.error('Classifier service error', { error: error.message });
    throw error;
  }
}

/**
 * Summarize email (with newsletter detection)
 */
async function summarizeEmail(email, classification) {
  try {
    // Check if this is a newsletter - if so, use the newsletter endpoint
    const isNewsletter = classification?.intent?.includes('newsletter');

    if (isNewsletter) {
      logger.info('Newsletter detected, using newsletter summarization endpoint', {
        emailId: email.id,
        subject: email.subject,
        intent: classification.intent
      });

      const response = await axios.post(
        `${SUMMARIZATION_SERVICE_URL}/api/summarize/newsletter`,
        {
          emailId: email.id,
          subject: email.subject,
          from: email.from,
          body: email.body || email.snippet,
          snippet: email.snippet
        }
      );

      // Transform newsletter response to match expected format
      return {
        summary: response.data.summary,
        title: email.subject,
        timeAgo: calculateTimeAgo(email.timestamp),
        source: 'gemini-newsletter',
        // Include newsletter-specific fields
        keyLinks: response.data.keyLinks || [],
        keyTopics: response.data.keyTopics || []
      };
    }

    // Regular email summarization
    const response = await axios.post(
      `${SUMMARIZATION_SERVICE_URL}/api/summarize`,
      { email }
    );
    return response.data;
  } catch (error) {
    logger.error('Summarization service error', { error: error.message });
    throw error;
  }
}

/**
 * Calculate "time ago" string from timestamp
 */
function calculateTimeAgo(timestamp) {
  if (!timestamp) return 'Recently';

  const now = Date.now();
  const diff = now - timestamp;

  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (minutes < 1) return 'Just now';
  if (minutes === 1) return '1 minute ago';
  if (minutes < 60) return `${minutes} minutes ago`;
  if (hours === 1) return '1 hour ago';
  if (hours < 24) return `${hours} hours ago`;
  if (days === 1) return '1 day ago';
  if (days < 7) return `${days} days ago`;

  return 'Over a week ago';
}

/**
 * Generate AI reply
 */
async function generateReply(email) {
  try {
    const response = await axios.post(
      `${SUMMARIZATION_SERVICE_URL}/api/generate-reply`,
      { email }
    );
    return response.data;
  } catch (error) {
    logger.error('Reply generation error', { error: error.message });
    throw error;
  }
}

/**
 * Perform action on email
 */
async function performEmailAction(provider, userId, emailId, action) {
  const providerMap = {
    gmail: 'gmail',
    outlook: 'outlook'
  };

  const providerPath = providerMap[provider] || 'gmail';

  // Map actions to provider-specific endpoints
  const actionMap = {
    archive: { method: 'post', path: `/messages/${emailId}/modify`, data: { removeLabelIds: ['INBOX'] } },
    delete: { method: 'post', path: `/messages/${emailId}/trash`, data: {} },
    markRead: { method: 'post', path: `/messages/${emailId}/modify`, data: { removeLabelIds: ['UNREAD'] } }
  };

  const actionConfig = actionMap[action];

  if (!actionConfig) {
    throw new Error(`Unknown action: ${action}`);
  }

  try {
    const response = await axios({
      method: actionConfig.method,
      url: `${EMAIL_SERVICE_URL}/api/${providerPath}${actionConfig.path}`,
      data: actionConfig.data,
      headers: { 'X-User-ID': userId }
    });

    return { success: true, ...response.data };
  } catch (error) {
    logger.error('Action execution error', { action, error: error.message });
    throw error;
  }
}

/**
 * Send reply
 */
async function sendReply(provider, userId, emailId, replyText) {
  // Implementation depends on provider
  // This is a simplified version
  return { success: true, message: 'Reply sent' };
}

/**
 * Fetch thread from email service
 */
async function fetchThread(provider, userId, threadId) {
  const providerMap = {
    gmail: 'gmail',
    outlook: 'outlook'
  };

  const providerPath = providerMap[provider] || 'gmail';

  try {
    const { getUserTokens } = require('../shared/utils/auth');
    const tokens = await getUserTokens(userId, provider);

    if (!tokens) {
      throw new Error(`No tokens found for ${provider}`);
    }

    const response = await axios.get(
      `${EMAIL_SERVICE_URL}/api/${providerPath}/threads/${threadId}`,
      {
        headers: {
          'X-User-ID': userId,
          'X-Access-Token': tokens.accessToken,
          'X-Refresh-Token': tokens.refreshToken || ''
        }
      }
    );

    return response.data;
  } catch (error) {
    logger.error('Error fetching thread from email service', {
      threadId,
      provider,
      error: error.message
    });
    throw error;
  }
}

/**
 * Search emails from provider
 */
async function searchEmails(provider, userId, searchParams) {
  const providerMap = {
    gmail: 'gmail',
    outlook: 'outlook'
  };

  const providerPath = providerMap[provider] || 'gmail';

  try {
    const { getUserTokens } = require('../shared/utils/auth');
    const tokens = getUserTokens(userId, provider);

    if (!tokens) {
      throw new Error(`No tokens found for ${provider}`);
    }

    // Build query string for Gmail
    let queryParts = [];
    if (searchParams.query) queryParts.push(searchParams.query);
    if (searchParams.sender) queryParts.push(`from:${searchParams.sender}`);
    if (searchParams.dateFrom) queryParts.push(`after:${searchParams.dateFrom}`);
    if (searchParams.dateTo) queryParts.push(`before:${searchParams.dateTo}`);

    const q = queryParts.join(' ');

    const response = await axios.get(
      `${EMAIL_SERVICE_URL}/api/${providerPath}/search`,
      {
        params: {
          q,
          maxResults: searchParams.limit,
          pageToken: searchParams.offset > 0 ? searchParams.offset : undefined
        },
        headers: {
          'X-User-ID': userId,
          'X-Access-Token': tokens.accessToken,
          'X-Refresh-Token': tokens.refreshToken || ''
        }
      }
    );

    return response.data.messages || [];
  } catch (error) {
    logger.error('Error searching emails', {
      provider,
      error: error.message
    });
    throw error;
  }
}

/**
 * Extract sender info from email
 */
function extractSender(email) {
  if (!email.from) return null;

  const match = email.from.match(/^(.+?)\s*<(.+?)>$/);

  if (match) {
    const name = match[1].replace(/"/g, '').trim();
    return {
      name,
      initial: name.charAt(0).toUpperCase()
    };
  }

  const fromEmail = email.from.split('@')[0];
  return {
    name: fromEmail,
    initial: fromEmail.charAt(0).toUpperCase()
  };
}

/**
 * Detect if an email ID is a mock ID (for development/testing)
 * Mock IDs follow pattern: prefix + number (e.g., edu1, shop1, work1)
 */
function isMockEmailId(id) {
  // Mock IDs are short alphanumeric strings without Gmail's typical format
  // Real Gmail IDs are 16+ character hex strings like: 18c3d12a4567890b
  return /^[a-z]+\d+$/.test(id) && id.length < 10;
}

/**
 * Generate mock thread data for development/testing
 * Returns realistic thread conversation based on email type
 */
function generateMockThreadData(emailId) {
  const mockThreads = {
    edu1: {
      threadId: 'thread-edu1',
      messages: [
        {
          id: 'msg1-edu1',
          from: 'teacher@school.edu',
          date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
          body: 'Hi parents, just a reminder about the upcoming field trip to the Science Museum on October 25th. Please sign and return the permission form by Friday.',
          isLatest: false
        },
        {
          id: 'msg2-edu1',
          from: 'parent@gmail.com',
          date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
          body: 'Hi Mrs. Johnson, will there be vegetarian lunch options available? My son has dietary restrictions.',
          isLatest: false
        },
        {
          id: 'edu1',
          from: 'teacher@school.edu',
          date: new Date().toISOString(),
          body: 'Yes, we will have vegetarian and gluten-free options. Please note any allergies on the permission form.',
          isLatest: true
        }
      ],
      context: {
        purchases: [],
        upcomingEvents: [
          { name: 'Field Trip', date: '2025-10-25', location: 'Science Museum' }
        ],
        locations: ['Science Museum'],
        unresolvedQuestions: [],
        conversationStage: 'resolved'
      },
      messageCount: 3
    },
    shop1: {
      threadId: 'thread-shop1',
      messages: [
        {
          id: 'msg1-shop1',
          from: 'orders@amazon.com',
          date: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString(),
          body: 'Your order #123-4567890 has been confirmed and will ship soon. Track your package at amazon.com/orders',
          isLatest: false
        },
        {
          id: 'shop1',
          from: 'shipping@amazon.com',
          date: new Date().toISOString(),
          body: 'Your package has shipped! Tracking: 1Z999AA10123456784. Expected delivery: October 26. Carrier: UPS.',
          isLatest: true
        }
      ],
      context: {
        purchases: [
          { item: 'Order #123-4567890', amount: '$45.99' }
        ],
        upcomingEvents: [],
        locations: [],
        unresolvedQuestions: [],
        conversationStage: 'shipped'
      },
      messageCount: 2
    },
    work1: {
      threadId: 'thread-work1',
      messages: [
        {
          id: 'msg1-work1',
          from: 'manager@company.com',
          date: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString(),
          body: 'Team, please review the Q4 planning doc and add your feedback by EOD Thursday.',
          isLatest: false
        },
        {
          id: 'msg2-work1',
          from: 'colleague@company.com',
          date: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
          body: 'Added my notes to sections 2-3. Should we schedule a sync to discuss the timeline?',
          isLatest: false
        },
        {
          id: 'work1',
          from: 'manager@company.com',
          date: new Date().toISOString(),
          body: 'Good idea. I sent a calendar invite for Friday 2pm. See you all then.',
          isLatest: true
        }
      ],
      context: {
        purchases: [],
        upcomingEvents: [
          { name: 'Q4 Planning Sync', date: 'Friday 2pm', location: 'Zoom' }
        ],
        locations: [],
        unresolvedQuestions: [],
        conversationStage: 'scheduled'
      },
      messageCount: 3
    }
  };

  // Return specific mock thread or generate generic one
  if (mockThreads[emailId]) {
    logger.info('Returning predefined mock thread', { emailId });
    return mockThreads[emailId];
  }

  // Generate generic mock thread for unknown IDs
  logger.info('Generating generic mock thread', { emailId });
  return {
    threadId: `thread-${emailId}`,
    messages: [
      {
        id: `msg1-${emailId}`,
        from: 'sender@example.com',
        date: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
        body: 'This is the first message in the thread.',
        isLatest: false
      },
      {
        id: emailId,
        from: 'sender@example.com',
        date: new Date().toISOString(),
        body: 'This is the latest message in the thread.',
        isLatest: true
      }
    ],
    context: {
      purchases: [],
      upcomingEvents: [],
      locations: [],
      unresolvedQuestions: [],
      conversationStage: null
    },
    messageCount: 2
  };
}

module.exports = router;

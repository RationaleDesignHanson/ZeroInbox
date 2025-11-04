/**
 * ML-based Smart Reply Generator
 * Phase 6.1: Replace template-based replies with ML-generated responses
 *
 * Features:
 * - OpenAI GPT integration for contextual replies
 * - Fallback to template-based system
 * - Caching to reduce API calls
 * - Confidence scoring and tone classification
 */

const logger = require('./shared/config/logger');
const { generateSmartReplies: generateTemplateReplies } = require('./smart-reply-generator');

// Configuration
const ML_CONFIG = {
  provider: process.env.ML_PROVIDER || 'openai', // 'openai' or 'anthropic'
  apiKey: process.env.OPENAI_API_KEY || process.env.ANTHROPIC_API_KEY,
  model: process.env.ML_MODEL || 'gpt-4o-mini', // Fast and cost-effective
  maxTokens: 200,
  temperature: 0.7,
  enabled: process.env.ML_REPLIES_ENABLED === 'true',
  timeout: 5000, // 5 second timeout
  useTemplatesAsFallback: true
};

// In-memory cache for ML replies (will be replaced with Redis)
const replyCache = new Map();
const MAX_CACHE_SIZE = 500;
const CACHE_TTL = 3600000; // 1 hour

/**
 * Generate cache key for ML replies
 */
function generateCacheKey(classification) {
  const { intent, type, entities = {} } = classification;
  const entityKeys = Object.keys(entities).sort().join(',');
  return `ml_reply:${intent}:${type}:${entityKeys}`;
}

/**
 * Get cached ML reply
 */
function getCachedReply(key) {
  const cached = replyCache.get(key);
  if (!cached) return null;

  // Check TTL
  if (Date.now() - cached.timestamp > CACHE_TTL) {
    replyCache.delete(key);
    return null;
  }

  return cached.replies;
}

/**
 * Cache ML reply
 */
function cacheReply(key, replies) {
  // Evict oldest if cache is full
  if (replyCache.size >= MAX_CACHE_SIZE) {
    const firstKey = replyCache.keys().next().value;
    replyCache.delete(firstKey);
  }

  replyCache.set(key, {
    replies,
    timestamp: Date.now()
  });
}

/**
 * Build prompt for ML model
 */
function buildMLPrompt(classification) {
  const { intent, subject, from, snippet, entities = {}, urgent, type } = classification;

  // Extract key entities for context
  const entityContext = Object.entries(entities)
    .filter(([_, value]) => value)
    .map(([key, value]) => `${key}: ${value}`)
    .join(', ');

  const prompt = `You are an AI assistant helping generate smart email reply suggestions.

Email Context:
- Type: ${type}
- Intent: ${intent}
- From: ${from || 'unknown sender'}
- Subject: ${subject || 'no subject'}
- Preview: ${snippet || 'no content'}
${entityContext ? `- Key entities: ${entityContext}` : ''}
${urgent ? '- URGENT email' : ''}

Generate exactly 3 short, professional reply suggestions (max 10 words each) that would be appropriate for this email.

For each reply, provide:
1. The reply text
2. A tone classification (one of: positive, inquiry, action, acknowledgment, polite_decline)
3. A confidence score (0.0-1.0) for how appropriate this reply is

Return ONLY a JSON array with this exact structure:
[
  {
    "text": "Thanks for the update!",
    "tone": "positive",
    "confidence": 0.9
  },
  {
    "text": "When can I expect delivery?",
    "tone": "inquiry",
    "confidence": 0.85
  },
  {
    "text": "I'll review this shortly",
    "tone": "acknowledgment",
    "confidence": 0.8
  }
]

Important:
- Keep replies brief and natural
- Match the formality level to the email type
- Ensure replies are contextually appropriate
- Order replies by relevance (most relevant first)`;

  return prompt;
}

/**
 * Call OpenAI API
 */
async function callOpenAI(prompt) {
  if (!ML_CONFIG.apiKey) {
    throw new Error('OpenAI API key not configured');
  }

  const startTime = Date.now();

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${ML_CONFIG.apiKey}`
      },
      body: JSON.stringify({
        model: ML_CONFIG.model,
        messages: [
          { role: 'system', content: 'You are a helpful assistant that generates email reply suggestions. Always respond with valid JSON.' },
          { role: 'user', content: prompt }
        ],
        max_tokens: ML_CONFIG.maxTokens,
        temperature: ML_CONFIG.temperature,
        response_format: { type: 'json_object' }
      }),
      signal: AbortSignal.timeout(ML_CONFIG.timeout)
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    const content = data.choices[0]?.message?.content;

    if (!content) {
      throw new Error('No content in OpenAI response');
    }

    // Parse JSON response
    const parsed = JSON.parse(content);
    const replies = Array.isArray(parsed) ? parsed : (parsed.replies || []);

    logger.info('ML reply generation successful', {
      model: ML_CONFIG.model,
      repliesCount: replies.length,
      latency: Date.now() - startTime
    });

    return replies;

  } catch (error) {
    logger.error('OpenAI API call failed', {
      error: error.message,
      latency: Date.now() - startTime
    });
    throw error;
  }
}

/**
 * Call Anthropic Claude API
 */
async function callAnthropic(prompt) {
  if (!ML_CONFIG.apiKey) {
    throw new Error('Anthropic API key not configured');
  }

  const startTime = Date.now();

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ML_CONFIG.apiKey,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: ML_CONFIG.model || 'claude-3-haiku-20240307',
        max_tokens: ML_CONFIG.maxTokens,
        temperature: ML_CONFIG.temperature,
        messages: [
          { role: 'user', content: prompt }
        ]
      }),
      signal: AbortSignal.timeout(ML_CONFIG.timeout)
    });

    if (!response.ok) {
      throw new Error(`Anthropic API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    const content = data.content[0]?.text;

    if (!content) {
      throw new Error('No content in Anthropic response');
    }

    // Parse JSON response
    const parsed = JSON.parse(content);
    const replies = Array.isArray(parsed) ? parsed : (parsed.replies || []);

    logger.info('ML reply generation successful', {
      model: ML_CONFIG.model,
      repliesCount: replies.length,
      latency: Date.now() - startTime
    });

    return replies;

  } catch (error) {
    logger.error('Anthropic API call failed', {
      error: error.message,
      latency: Date.now() - startTime
    });
    throw error;
  }
}

/**
 * Call ML provider
 */
async function callMLProvider(prompt) {
  if (ML_CONFIG.provider === 'anthropic') {
    return await callAnthropic(prompt);
  } else {
    return await callOpenAI(prompt);
  }
}

/**
 * Validate and format ML replies
 */
function validateMLReplies(replies) {
  if (!Array.isArray(replies)) {
    throw new Error('ML response is not an array');
  }

  return replies
    .filter(reply => {
      // Validate structure
      if (!reply || typeof reply !== 'object') return false;
      if (!reply.text || typeof reply.text !== 'string') return false;
      if (!reply.tone || typeof reply.tone !== 'string') return false;
      if (typeof reply.confidence !== 'number') return false;

      // Validate values
      if (reply.text.length < 2 || reply.text.length > 200) return false;
      if (reply.confidence < 0 || reply.confidence > 1) return false;

      return true;
    })
    .slice(0, 3) // Max 3 replies
    .map((reply, index) => ({
      text: reply.text.trim(),
      tone: reply.tone.toLowerCase(),
      confidence: Math.min(Math.max(reply.confidence, 0), 1),
      rank: index + 1,
      source: 'ml'
    }));
}

/**
 * Generate smart replies using ML
 */
async function generateMLSmartReplies(classification) {
  const startTime = Date.now();

  try {
    // Check if ML is enabled
    if (!ML_CONFIG.enabled) {
      logger.debug('ML replies disabled, using template-based fallback');
      return generateTemplateReplies(classification);
    }

    // Check cache first
    const cacheKey = generateCacheKey(classification);
    const cached = getCachedReply(cacheKey);
    if (cached) {
      logger.debug('ML reply cache hit', { cacheKey });
      return cached;
    }

    // Build prompt and call ML
    const prompt = buildMLPrompt(classification);
    const mlReplies = await callMLProvider(prompt);

    // Validate and format
    const validatedReplies = validateMLReplies(mlReplies);

    if (validatedReplies.length === 0) {
      throw new Error('No valid replies from ML model');
    }

    // Cache result
    cacheReply(cacheKey, validatedReplies);

    logger.info('ML replies generated', {
      intent: classification.intent,
      repliesCount: validatedReplies.length,
      latency: Date.now() - startTime,
      cached: false
    });

    return validatedReplies;

  } catch (error) {
    logger.warn('ML reply generation failed, using template fallback', {
      error: error.message,
      intent: classification.intent
    });

    // Fallback to template-based
    if (ML_CONFIG.useTemplatesAsFallback) {
      const templateReplies = generateTemplateReplies(classification);
      return templateReplies.map(reply => ({
        ...reply,
        source: 'template_fallback'
      }));
    }

    // Return empty array if no fallback
    return [];
  }
}

/**
 * Get ML reply cache statistics
 */
function getMLCacheStats() {
  let totalAge = 0;
  let expiredCount = 0;
  const now = Date.now();

  for (const [_, cached] of replyCache) {
    const age = now - cached.timestamp;
    totalAge += age;
    if (age > CACHE_TTL) expiredCount++;
  }

  return {
    size: replyCache.size,
    maxSize: MAX_CACHE_SIZE,
    avgAge: replyCache.size > 0 ? Math.round(totalAge / replyCache.size / 1000) : 0, // seconds
    expiredCount,
    ttl: CACHE_TTL / 1000 // seconds
  };
}

/**
 * Clear ML reply cache
 */
function clearMLCache() {
  replyCache.clear();
  logger.info('ML reply cache cleared');
}

/**
 * Get ML configuration (for health checks)
 */
function getMLConfig() {
  return {
    enabled: ML_CONFIG.enabled,
    provider: ML_CONFIG.provider,
    model: ML_CONFIG.model,
    hasApiKey: !!ML_CONFIG.apiKey,
    timeout: ML_CONFIG.timeout,
    fallbackEnabled: ML_CONFIG.useTemplatesAsFallback
  };
}

module.exports = {
  generateMLSmartReplies,
  getMLCacheStats,
  clearMLCache,
  getMLConfig,
  // Export for testing
  _internal: {
    buildMLPrompt,
    validateMLReplies,
    generateCacheKey,
    ML_CONFIG
  }
};

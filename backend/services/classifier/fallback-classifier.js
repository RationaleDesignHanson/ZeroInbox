/**
 * Fallback Classifier (Secondary AI-Powered Classifier)
 * Uses Gemini 2.0 Flash to analyze full email body for emails that fail pattern matching
 * Only triggered for low-confidence classifications (<30 score)
 *
 * This significantly reduces fallback rate by catching:
 * - Creative/vague marketing emails
 * - Ultra-short personal messages
 * - Service notifications with non-standard formats
 */

const { VertexAI } = require('@google-cloud/vertexai');
const logger = require('./shared/config/logger');
const { IntentTaxonomy, getAllIntentIds } = require('./shared/models/Intent');

// Initialize Vertex AI
const PROJECT_ID = process.env.GOOGLE_PROJECT_ID || 'gen-lang-client-0622702687';
const LOCATION = process.env.VERTEX_AI_LOCATION || 'us-central1';
const MODEL_NAME = 'gemini-2.0-flash-exp'; // Fast and accurate

const vertexAI = new VertexAI({
  project: PROJECT_ID,
  location: LOCATION
});

/**
 * Classify email using AI body analysis
 * This is the "secondary classifier" - only called for fallbacks
 *
 * @param {Object} email - Email object with subject, body, from, snippet
 * @returns {Promise<Object>} Classification result with intent, confidence, entities, actions
 */
async function classifyWithBodyAnalysis(email) {
  try {
    logger.info('Starting secondary AI classification', {
      subject: email.subject?.substring(0, 60),
      from: email.from?.substring(0, 50)
    });

    // Build comprehensive prompt with all available intents
    const prompt = buildClassificationPrompt(email);

    // Call Gemini 2.0 Flash
    const generativeModel = vertexAI.getGenerativeModel({
      model: MODEL_NAME,
      generationConfig: {
        temperature: 0.2,        // Low temperature for consistent classification
        maxOutputTokens: 500,    // Enough for structured response
        topP: 0.8,
        topK: 40
      }
    });

    const result = await generativeModel.generateContent(prompt);
    const response = result.response;
    const responseText = response.candidates[0].content.parts[0].text;

    if (!responseText) {
      throw new Error('No response from Gemini');
    }

    // Parse JSON response
    const classification = parseClassificationResponse(responseText);

    logger.info('Secondary AI classification completed', {
      subject: email.subject?.substring(0, 60),
      detectedIntent: classification.intent,
      confidence: classification.confidence,
      source: 'gemini-2.0-flash'
    });

    return {
      ...classification,
      source: 'ai_body_analysis',
      model: 'gemini-2.0-flash-exp'
    };

  } catch (error) {
    logger.error('Secondary AI classification failed', {
      error: error.message,
      stack: error.stack,
      subject: email.subject?.substring(0, 60)
    });

    // Return generic fallback on error
    return {
      intent: 'generic.transactional',
      confidence: 0.5,
      source: 'ai_error_fallback',
      error: error.message,
      entities: {},
      suggestedActions: []
    };
  }
}

/**
 * Build classification prompt with full email context
 */
function buildClassificationPrompt(email) {
  const subject = email.subject || 'No subject';
  const from = email.from || 'Unknown sender';
  const body = email.body || email.snippet || 'No body content';

  // Clean body (remove HTML, long URLs, signatures)
  const cleanBody = cleanEmailBodyForAI(body);

  // Get list of all available intents for context
  const availableIntents = getAllIntentIds()
    .map(id => {
      const intent = IntentTaxonomy[id];
      return `${id}: ${intent.description || 'No description'}`;
    })
    .join('\n');

  return `You are an expert email classifier. Analyze this email and determine its intent.

**Available Intent Categories (${getAllIntentIds().length} total):**
${availableIntents}

**Email to Classify:**
From: ${from}
Subject: ${subject}
Body: ${cleanBody.substring(0, 2000)}

**Your Task:**
1. Determine the MOST SPECIFIC intent that matches this email
2. Extract any relevant entities (tracking numbers, amounts, dates, etc.)
3. Suggest 2-3 actions the user might want to take
4. Assign a confidence score (0.0-1.0)

**Response Format (JSON):**
{
  "intent": "category.subcategory.action",
  "confidence": 0.85,
  "reasoning": "Brief explanation of why this intent was chosen",
  "entities": {
    "trackingNumber": "1Z999AA10123456784",
    "carrier": "UPS",
    "amount": "$59.99"
  },
  "suggestedActions": [
    "track_package",
    "save_for_later",
    "view_details"
  ]
}

**Guidelines:**
- Prefer specific intents over generic ones
- If the email is marketing/promotional, choose the appropriate marketing.* intent
- If it's a notification about a service (shipping, social media, etc.), choose that specific intent
- For creative/vague marketing emails, analyze the body to find the actual offer
- For short personal messages, use communication.personal.* intents
- Confidence should be 0.75+ if you're sure, 0.50-0.74 if uncertain
- Return ONLY valid JSON, no markdown formatting`;
}

/**
 * Parse and validate Gemini's JSON response
 */
function parseClassificationResponse(responseText) {
  try {
    // Remove markdown code blocks if present
    let jsonText = responseText.trim();

    // Extract JSON from markdown blocks
    const jsonMatch = jsonText.match(/```json\s*([\s\S]*?)\s*```/) ||
                      jsonText.match(/```\s*([\s\S]*?)\s*```/);

    if (jsonMatch) {
      jsonText = jsonMatch[1];
    }

    // Parse JSON
    const parsed = JSON.parse(jsonText);

    // Validate required fields
    if (!parsed.intent || typeof parsed.intent !== 'string') {
      throw new Error('Missing or invalid intent field');
    }

    if (!parsed.confidence || typeof parsed.confidence !== 'number') {
      parsed.confidence = 0.75; // Default to medium-high confidence
    }

    // Validate intent exists in taxonomy
    if (!IntentTaxonomy[parsed.intent]) {
      logger.warn('AI suggested unknown intent, using generic', {
        suggestedIntent: parsed.intent
      });
      parsed.intent = 'generic.transactional';
      parsed.confidence = 0.6;
    }

    // Ensure entities object exists
    if (!parsed.entities || typeof parsed.entities !== 'object') {
      parsed.entities = {};
    }

    // Ensure suggestedActions array exists
    if (!parsed.suggestedActions || !Array.isArray(parsed.suggestedActions)) {
      parsed.suggestedActions = [];
    }

    // Cap confidence at 0.95 (never 100% certain from AI)
    parsed.confidence = Math.min(parsed.confidence, 0.95);

    return {
      intent: parsed.intent,
      confidence: parsed.confidence,
      reasoning: parsed.reasoning || 'AI classification',
      entities: parsed.entities,
      suggestedActions: parsed.suggestedActions
    };

  } catch (error) {
    logger.error('Failed to parse AI classification response', {
      error: error.message,
      responseText: responseText.substring(0, 500)
    });

    // Return safe fallback
    return {
      intent: 'generic.transactional',
      confidence: 0.5,
      reasoning: 'Parse error',
      entities: {},
      suggestedActions: []
    };
  }
}

/**
 * Clean email body for AI analysis
 * Remove HTML, long URLs, signatures, etc.
 */
function cleanEmailBodyForAI(body) {
  if (!body) return '';

  let cleaned = body;

  // Remove HTML tags
  cleaned = cleaned.replace(/<[^>]+>/g, ' ');

  // Remove email signatures (common patterns)
  cleaned = cleaned.replace(/^--\s*$/gm, '');
  cleaned = cleaned.replace(/_{10,}/g, '');

  // Remove quoted replies (lines starting with >)
  cleaned = cleaned.split('\n')
    .filter(line => !line.trim().startsWith('>'))
    .join('\n');

  // Remove "Sent from my iPhone" style footers
  cleaned = cleaned.replace(/^(Sent from|Get Outlook for|This email was sent).*$/gm, '');

  // Shorten very long URLs (keep first 50 chars)
  cleaned = cleaned.replace(/https?:\/\/[^\s]{50,}/g, (match) => {
    return match.substring(0, 50) + '...[url]';
  });

  // Remove MIME headers
  cleaned = cleaned.replace(/^Content-Type:.*$/gm, '');
  cleaned = cleaned.replace(/^Content-Transfer-Encoding:.*$/gm, '');

  // Clean up excessive whitespace
  cleaned = cleaned.replace(/\n{3,}/g, '\n\n');
  cleaned = cleaned.replace(/\s+/g, ' ');
  cleaned = cleaned.trim();

  return cleaned;
}

/**
 * Merge pattern-based and AI-based classification results
 * Uses weighted average for confidence, prefers more specific intent
 *
 * @param {Object} patternResult - Result from pattern matching
 * @param {Object} aiResult - Result from AI body analysis
 * @returns {Object} Merged classification result
 */
function mergeClassifications(patternResult, aiResult) {
  // If AI is highly confident (0.85+), prefer AI result
  if (aiResult.confidence >= 0.85) {
    logger.info('Using AI classification (high confidence)', {
      aiIntent: aiResult.intent,
      aiConfidence: aiResult.confidence,
      patternIntent: patternResult.intent,
      patternConfidence: patternResult.confidence
    });

    return {
      ...aiResult,
      source: 'ai_primary',
      fallbackSource: 'pattern_matching',
      mergedConfidence: aiResult.confidence
    };
  }

  // If pattern matching is also confident, use weighted average
  if (patternResult.confidence >= 0.4) {
    // Both have some confidence - blend them
    const mergedConfidence = (patternResult.confidence * 0.4) + (aiResult.confidence * 0.6);

    // Prefer more specific intent
    const patternSpecificity = patternResult.intent.split('.').length;
    const aiSpecificity = aiResult.intent.split('.').length;

    const chosenIntent = aiSpecificity >= patternSpecificity ? aiResult.intent : patternResult.intent;

    logger.info('Merging pattern + AI classifications', {
      patternIntent: patternResult.intent,
      patternConf: patternResult.confidence,
      aiIntent: aiResult.intent,
      aiConf: aiResult.confidence,
      chosenIntent,
      mergedConf: mergedConfidence
    });

    return {
      intent: chosenIntent,
      confidence: mergedConfidence,
      source: 'hybrid',
      patternResult,
      aiResult,
      entities: { ...patternResult.entities, ...aiResult.entities },
      suggestedActions: [...new Set([...patternResult.suggestedActions || [], ...aiResult.suggestedActions || []])]
    };
  }

  // Pattern matching failed, use AI result
  logger.info('Using AI classification (pattern match too weak)', {
    aiIntent: aiResult.intent,
    aiConfidence: aiResult.confidence,
    patternConfidence: patternResult.confidence
  });

  return {
    ...aiResult,
    source: 'ai_fallback',
    mergedConfidence: aiResult.confidence
  };
}

module.exports = {
  classifyWithBodyAnalysis,
  mergeClassifications,
  cleanEmailBodyForAI
};

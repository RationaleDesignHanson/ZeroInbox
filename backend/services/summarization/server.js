require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const logger = require('./shared/config/logger');
const { VertexAI } = require('@google-cloud/vertexai');

const app = express();
const PORT = process.env.PORT || process.env.SUMMARIZATION_SERVICE_PORT || 8083;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Vertex AI Configuration
const PROJECT_ID = process.env.GOOGLE_PROJECT_ID || 'gen-lang-client-0622702687';
const LOCATION = process.env.VERTEX_AI_LOCATION || 'us-central1';
const MODEL_NAME = 'gemini-2.0-flash-exp'; // Gemini 2.0 Flash for fast, high-quality summarization

// Initialize Vertex AI client
const vertexAI = new VertexAI({
  project: PROJECT_ID,
  location: LOCATION
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'summarization-service',
    timestamp: new Date().toISOString(),
    vertexAI: {
      project: PROJECT_ID,
      location: LOCATION,
      model: MODEL_NAME,
      enabled: true
    }
  });
});

/**
 * POST /api/summarize
 * Summarize an email using Vertex AI
 */
app.post('/api/summarize', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email || !email.subject) {
      return res.status(400).json({ error: 'Invalid email data' });
    }

    logger.info('Summarizing email with Gemini', { subject: email.subject });

    // Call Gemini 2.0 Flash for summarization
    const summary = await summarizeWithGemini(email);

    res.json(summary);

  } catch (error) {
    logger.error('Error summarizing email', { error: error.message, stack: error.stack });

    // Fallback to rule-based summarization if AI fails
    const fallback = fallbackSummarization(req.body.email);
    res.json({ ...fallback, warning: 'AI summarization failed, using fallback' });
  }
});

/**
 * POST /api/summarize/newsletter
 * Summarize newsletter with key links and highlights
 */
app.post('/api/summarize/newsletter', async (req, res) => {
  try {
    const { emailId, subject, from, body, snippet } = req.body;

    if (!subject || !body) {
      return res.status(400).json({ error: 'Newsletter subject and body required' });
    }

    logger.info('Summarizing newsletter with Gemini', { subject, from });

    // Call Gemini for newsletter summarization
    const newsletterSummary = await summarizeNewsletterWithGemini({ subject, from, body, snippet });

    res.json(newsletterSummary);

  } catch (error) {
    logger.error('Error summarizing newsletter', { error: error.message, stack: error.stack });
    res.status(500).json({ error: 'Failed to summarize newsletter' });
  }
});

/**
 * POST /api/generate-reply
 * Generate email reply using Vertex AI
 */
app.post('/api/generate-reply', async (req, res) => {
  try {
    const { email, context } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email data required' });
    }

    logger.info('Generating reply for email', { subject: email.subject });

    // Note: Reply generation uses same Gemini model as summarization
    // No endpoint ID needed - Vertex AI SDK handles it automatically
    const reply = await generateReplyWithVertexAI(email, context);

    res.json(reply);

  } catch (error) {
    logger.error('Error generating reply', { error: error.message });

    const fallback = fallbackReplyGeneration(req.body.email, req.body.context);
    res.json({ ...fallback, warning: 'AI reply generation failed, using fallback' });
  }
});

/**
 * POST /api/extract-actions
 * Extract actionable items from email
 */
app.post('/api/extract-actions', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email data required' });
    }

    logger.info('Extracting actions from email', { subject: email.subject });

    const actions = extractActions(email);

    res.json(actions);

  } catch (error) {
    logger.error('Error extracting actions', { error: error.message });
    res.status(500).json({ error: 'Failed to extract actions' });
  }
});

/**
 * Summarize newsletter with key links extraction using Gemini 2.0 Flash
 */
async function summarizeNewsletterWithGemini(newsletter) {
  // Clean email body: remove MIME headers, decode encoding, strip HTML
  const rawBody = newsletter.body || newsletter.snippet || '';
  const cleanedBody = cleanEmailBody(rawBody);
  const cleanBody = stripHtml(cleanedBody);

  const prompt = `You are an expert at newsletter analysis. Summarize this newsletter for a busy professional viewing on mobile.

TASK: Extract key highlights and important links with proper formatting.

Provide a JSON response with this EXACT format:
{
  "summary": "2-3 sentence summary of the newsletter's main topics and why it matters",
  "keyLinks": [
    {
      "title": "Clear, descriptive title of the article/link",
      "url": "full URL",
      "description": "One sentence describing what this link is about"
    }
  ],
  "keyTopics": ["topic1", "topic2", "topic3"]
}

Guidelines:
- Summary: Focus on value and actionable insights, not structure
- Extract 3-5 most important links only (prioritize articles, not social media or unsubscribe)
- Each link needs clear title, full URL, and brief description
- Topics: 2-4 main themes covered

Newsletter From: ${newsletter.from}
Newsletter Subject: ${newsletter.subject}
Newsletter Body: ${cleanBody.substring(0, 10000)}`;

  // Get Gemini generative model
  const generativeModel = vertexAI.getGenerativeModel({
    model: MODEL_NAME,
    generationConfig: {
      temperature: 0.3,        // Balanced for extraction + creativity
      maxOutputTokens: 800,    // Higher for detailed link extraction
      topP: 0.9,
      topK: 40
    }
  });

  // Generate content
  const result = await generativeModel.generateContent(prompt);
  const response = result.response;
  const responseText = response.candidates[0].content.parts[0].text;

  if (!responseText) {
    throw new Error('No response returned from Gemini');
  }

  // Parse JSON response
  let parsedResponse;
  try {
    // Extract JSON if wrapped in markdown code blocks
    const jsonMatch = responseText.match(/```json\s*([\s\S]*?)\s*```/) ||
                      responseText.match(/```\s*([\s\S]*?)\s*```/) ||
                      [null, responseText];
    const jsonText = jsonMatch[1] || responseText;
    parsedResponse = JSON.parse(jsonText.trim());
  } catch (parseError) {
    logger.error('Failed to parse Gemini newsletter response', { responseText });
    // Fallback structure
    parsedResponse = {
      summary: responseText.substring(0, 200),
      keyLinks: [],
      keyTopics: []
    };
  }

  logger.info('Newsletter summary generated', {
    subject: newsletter.subject,
    linkCount: parsedResponse.keyLinks?.length || 0,
    source: 'gemini-2.0-flash'
  });

  return {
    summary: parsedResponse.summary || 'Newsletter summary unavailable',
    keyLinks: parsedResponse.keyLinks || [],
    keyTopics: parsedResponse.keyTopics || []
  };
}

/**
 * Calculate complexity score for email (0-100)
 * Based on information density and structural complexity of the email itself
 * NOT subjective importance to user - just how much detail is needed to summarize
 */
function calculateComplexityScore(email) {
  const subject = (email.subject || '').toLowerCase();
  const body = stripHtml(email.body || email.snippet || '').toLowerCase();
  const fullText = `${subject} ${body}`;

  let score = 0;

  // INFORMATION DENSITY (30 points)
  // How much factual content needs to be conveyed?
  const factDensityIndicators = [
    /\d{1,2}\/\d{1,2}\/\d{2,4}/g,  // Dates
    /\d{1,2}:\d{2}\s*(am|pm)?/gi,   // Times
    /\$[\d,]+(\.\d{2})?/g,          // Dollar amounts
    /\b\d+%\b/g,                     // Percentages
    /\b[A-Z]{2,}\d+\b/g,             // Codes (ABC123, etc)
    /\b\d{3}-\d{3}-\d{4}\b/g        // Phone numbers
  ];

  let totalFacts = 0;
  factDensityIndicators.forEach(pattern => {
    const matches = fullText.match(pattern);
    if (matches) totalFacts += matches.length;
  });

  if (totalFacts >= 10) score += 30;
  else if (totalFacts >= 6) score += 25;
  else if (totalFacts >= 4) score += 20;
  else if (totalFacts >= 2) score += 15;
  else if (totalFacts >= 1) score += 10;

  // STRUCTURAL COMPLEXITY (25 points)
  // Multiple sections, lists, or topics?
  const hasBulletPoints = /[•\-\*]\s/.test(fullText);
  const hasNumberedList = /\b\d+[\.)]\s/.test(fullText);
  const paragraphCount = body.split(/\n\n+/).filter(p => p.trim().length > 50).length;
  const hasMultipleTopics = paragraphCount >= 3;

  if (hasMultipleTopics) score += 15;
  if (hasBulletPoints || hasNumberedList) score += 10;

  // ACTIONABLE STEPS (20 points)
  // How many distinct actions or steps are described?
  const actionKeywords = ['sign', 'approve', 'review', 'submit', 'complete', 'rsvp', 'register', 'confirm', 'respond', 'provide'];
  const actionCount = actionKeywords.filter(kw => fullText.includes(kw)).length;

  if (actionCount >= 4) score += 20;
  else if (actionCount >= 3) score += 15;
  else if (actionCount === 2) score += 10;
  else if (actionCount === 1) score += 5;

  const hasMultipleSteps = /\b(step|stage|phase|first|then|next|finally|second|third)\b/.test(fullText);
  if (hasMultipleSteps) score += 5;

  // CONTEXTUAL RELATIONSHIPS (15 points)
  // Does understanding require explaining relationships/background?
  const hasConditionals = /\b(if|unless|provided that|in case|assuming)\b/.test(fullText);
  const hasReferences = /\b(as mentioned|previously|earlier|referenced|attached|below|above)\b/.test(fullText);
  const hasCausalRelations = /\b(because|since|therefore|thus|as a result|due to)\b/.test(fullText);

  if (hasConditionals) score += 5;
  if (hasReferences) score += 5;
  if (hasCausalRelations) score += 5;

  // LENGTH & SCOPE (10 points)
  // Longer emails naturally need more summary space
  const wordCount = fullText.split(/\s+/).length;

  if (wordCount >= 500) score += 10;
  else if (wordCount >= 300) score += 7;
  else if (wordCount >= 150) score += 5;
  else if (wordCount >= 75) score += 3;

  // Cap at 100
  return Math.min(score, 100);
}

/**
 * Calculate target summary length based on email complexity
 * Returns { minLines, maxLines, description }
 */
function calculateTargetLength(complexityScore, emailType) {
  // Newsletter override - always longer
  if (emailType === 'newsletter' || emailType === 'newsletter_summary') {
    return {
      minLines: 12,
      maxLines: 18,
      description: 'Newsletter - multiple topics and links'
    };
  }

  // Dynamic length based on email complexity
  if (complexityScore >= 80) {
    return {
      minLines: 15,
      maxLines: 20,
      description: 'Highly complex - dense information with multiple facts/steps'
    };
  } else if (complexityScore >= 60) {
    return {
      minLines: 12,
      maxLines: 15,
      description: 'Complex - substantial detail and context needed'
    };
  } else if (complexityScore >= 40) {
    return {
      minLines: 8,
      maxLines: 12,
      description: 'Moderate complexity - balanced summary'
    };
  } else if (complexityScore >= 20) {
    return {
      minLines: 5,
      maxLines: 8,
      description: 'Low complexity - concise summary'
    };
  } else {
    return {
      minLines: 3,
      maxLines: 5,
      description: 'Minimal complexity - brief overview'
    };
  }
}

/**
 * Summarize email using Gemini 2.0 Flash with dynamic length targeting
 */
async function summarizeWithGemini(email) {
  // Clean email body: remove MIME headers, decode encoding, strip HTML
  const rawBody = email.body || email.snippet || '';
  const cleanedBody = cleanEmailBody(rawBody);
  const cleanBody = stripHtml(cleanedBody);

  // Calculate complexity and determine target length
  const complexityScore = calculateComplexityScore(email);
  const targetLength = calculateTargetLength(complexityScore, email.intent);

  logger.info('Email complexity analysis', {
    subject: email.subject,
    complexityScore,
    targetLength: `${targetLength.minLines}-${targetLength.maxLines} lines`,
    reason: targetLength.description
  });

  const prompt = `You are an expert at email triage. Summarize this email for a busy professional viewing on mobile.

COMPLEXITY SCORE: ${complexityScore}/100
TARGET LENGTH: ${targetLength.minLines}-${targetLength.maxLines} lines
EMAIL TYPE: ${targetLength.description}

ADJUST YOUR DETAIL LEVEL BASED ON EMAIL COMPLEXITY:
- High complexity (80+): Dense information - capture all facts, dates, amounts, steps, and relationships
- Complex (60-79): Substantial content - include full details and context
- Moderate (40-59): Balanced content - key details with supporting context
- Low complexity (20-39): Simple content - essential facts only
- Minimal (0-19): Very simple - brief overview is sufficient

TYPOGRAPHY & FORMATTING:
• Use **bold** for critical info (deadlines, amounts, names, dates)
• Use bullet points to break up dense information
• Write in clear, scannable prose with natural paragraph breaks
• Start with the most important information first
• Match detail level to email complexity

Format using structured sections when appropriate:

**Actions:** (Include when there are specific actions required)
• List what the recipient must do, with **deadlines in bold**
• Be specific: "Sign permission form by **Oct 25**" not "Action needed"
• Max 3 bullet points for simple emails, expand for complex
• If no actions, skip this section entirely

**Why:**
• 1-3 sentences explaining why this email matters and its impact
• Focus on what the recipient cares about
• For complex emails with multiple elements, provide comprehensive rationale
• For simple emails, keep it brief

**Context:** (Include essential details that add value)
• Key details: amounts, dates, names, participants, locations
• Background information needed to understand Why
• For high-complexity: Include all relevant facts and relationships
• For low-complexity: Only the most essential facts
• Use bold for critical data points

QUALITY GUIDELINES:
- Hit your target length: ${targetLength.minLines}-${targetLength.maxLines} lines
- Write naturally - avoid robotic summarization
- Bold makes it scannable, but don't overuse
- Include specifics: names, dates, amounts (if in email)
- Adjust detail depth based on email complexity
- Dense emails with many facts need thorough coverage; simple notifications should be brief

Email Subject: ${email.subject}
Email From: ${email.from}
Email Body: ${cleanBody.substring(0, 2000)}`;

  // Get Gemini generative model with dynamic token limit based on complexity
  const maxTokens = complexityScore >= 80 ? 1000 :   // Highly complex
                    complexityScore >= 60 ? 800 :    // Complex
                    complexityScore >= 40 ? 600 :    // Moderate
                    complexityScore >= 20 ? 400 :    // Low complexity
                    300;                              // Minimal complexity

  const generativeModel = vertexAI.getGenerativeModel({
    model: MODEL_NAME,
    generationConfig: {
      temperature: 0.3,        // Slightly higher for more natural writing
      maxOutputTokens: maxTokens,     // Dynamic based on importance
      topP: 0.9,               // Slightly higher for better quality
      topK: 40                  // Higher for more natural vocabulary
    }
  });

  // Generate content
  const result = await generativeModel.generateContent(prompt);
  const response = result.response;
  const summaryText = response.candidates[0].content.parts[0].text;

  if (!summaryText) {
    throw new Error('No summary text returned from Gemini');
  }

  // Post-process to detect and fix template placeholders
  let cleanedSummary = summaryText;

  // Detect common placeholder patterns that the model shouldn't return
  const placeholderPatterns = [
    /%title\$/g,
    /%subject\$/g,
    /%sender\$/g,
    /%from\$/g,
    /\[title\]/gi,
    /\[subject\]/gi,
    /\[sender\]/gi,
    /{title}/gi,
    /{subject}/gi,
    /{sender}/gi
  ];

  // Check if summary contains any placeholders
  const hasPlaceholders = placeholderPatterns.some(pattern => pattern.test(cleanedSummary));

  if (hasPlaceholders) {
    logger.warning('Summary contains template placeholders, attempting to fix', {
      subject: email.subject,
      originalSummary: summaryText
    });

    // Replace placeholders with actual values
    cleanedSummary = cleanedSummary
      .replace(/%title\$/g, email.subject || 'Email')
      .replace(/%subject\$/g, email.subject || 'Email')
      .replace(/%sender\$/g, email.from || 'Sender')
      .replace(/%from\$/g, email.from || 'Sender')
      .replace(/\[title\]/gi, email.subject || 'Email')
      .replace(/\[subject\]/gi, email.subject || 'Email')
      .replace(/\[sender\]/gi, email.from || 'Sender')
      .replace(/{title}/gi, email.subject || 'Email')
      .replace(/{subject}/gi, email.subject || 'Email')
      .replace(/{sender}/gi, email.from || 'Sender');

    logger.info('Fixed placeholder summary', {
      subject: email.subject,
      cleanedSummary
    });
  }

  logger.info('Gemini summary generated', {
    subject: email.subject,
    summaryLength: cleanedSummary.length
  });

  return {
    summary: cleanedSummary,
    title: extractTitle(email),
    timeAgo: calculateTimeAgo(email.timestamp),
    source: 'gemini-2.0-flash'
  };
}

/**
 * Generate reply using Vertex AI
 */
async function generateReplyWithVertexAI(email, context = '') {
  const endpoint = `projects/${PROJECT_ID}/locations/${LOCATION}/endpoints/${ENDPOINT_ID}`;

  const prompt = `Generate a professional email reply to this message. Keep it concise and appropriate.
${context ? `Context: ${context}\n` : ''}
Original Email:
Subject: ${email.subject}
From: ${email.from}
Body: ${email.body?.substring(0, 800)}

Reply:`;

  const instanceValue = helpers.toValue({ prompt });
  const instances = [instanceValue];

  const parameter = {
    temperature: 0.7,
    maxOutputTokens: 200,
    topP: 0.9,
    topK: 40
  };
  const parameters = helpers.toValue(parameter);

  const request = {
    endpoint,
    instances,
    parameters
  };

  const [response] = await predictionServiceClient.predict(request);
  const predictions = response.predictions;

  if (!predictions || predictions.length === 0) {
    throw new Error('No predictions returned from Vertex AI');
  }

  const replyText = predictions[0].structValue?.fields?.content?.stringValue ||
                    predictions[0].stringValue;

  return {
    reply: replyText,
    suggestions: [replyText], // Could generate multiple variations
    source: 'vertex-ai'
  };
}

/**
 * Fallback summarization (rule-based, when Vertex AI unavailable)
 * Produces ultra-concise summaries matching mock data quality (max 70 chars)
 */
function fallbackSummarization(email) {
  const subject = email.subject || '';
  let body = email.body || email.snippet || '';

  // Strip HTML tags and clean up body
  body = stripHtml(body);

  // Remove email greetings and signatures
  body = body
    .replace(/^(Hi|Hello|Dear|Hey|Greetings)[\s\w,]+/i, '')
    .replace(/(Best regards|Thanks|Thank you|Sincerely|Cheers|Regards)[\s\S]*$/i, '')
    .trim();

  // Extract first meaningful sentence (skip very short fragments)
  const sentences = body.split(/[.!?]+/).filter(s => s.trim().length > 10);

  let summary = '';
  if (sentences.length > 0) {
    summary = sentences[0].trim();
  } else {
    // Fallback to first 70 chars of body
    summary = body.substring(0, 70).trim();
  }

  // Remove common filler phrases at the start
  summary = summary
    .replace(/^(This email is about|I am writing to|I wanted to|Just a reminder that|Please note that)\s*/i, '')
    .replace(/^(The\s+)/i, '');

  // Compress to max 70 chars (not 200)
  if (summary.length > 70) {
    // Try to cut at word boundary
    summary = summary.substring(0, 67).trim();
    const lastSpace = summary.lastIndexOf(' ');
    if (lastSpace > 50) {
      summary = summary.substring(0, lastSpace);
    }

    // Only add ellipsis if we cut mid-sentence
    if (!summary.match(/[.!?]$/)) {
      summary += '...';
    }
  }

  // If summary is empty or too short, use cleaned subject
  if (!summary || summary.length < 15) {
    summary = subject.substring(0, 70);
  }

  return {
    summary: summary || subject || 'Email summary unavailable',
    title: extractTitle(email),
    timeAgo: calculateTimeAgo(email.timestamp),
    source: 'fallback'
  };
}

/**
 * Clean email body - remove MIME headers and decode encoding
 */
function cleanEmailBody(body) {
  if (!body) return '';

  // Remove MIME headers that leak into body
  body = body.replace(/^Content-Type:.*$/gm, '');
  body = body.replace(/^Content-Transfer-Encoding:.*$/gm, '');
  body = body.replace(/^MIME-Version:.*$/gm, '');
  body = body.replace(/^Content-Disposition:.*$/gm, '');
  body = body.replace(/^Content-ID:.*$/gm, '');

  // Decode quoted-printable encoding (=3D → =, =E2=80=99 → ', etc.)
  // First handle soft line breaks (= at end of line)
  body = body.replace(/=\r?\n/g, '');

  // Then decode hex sequences
  body = body.replace(/=([0-9A-F]{2})/g, (match, hex) => {
    try {
      return String.fromCharCode(parseInt(hex, 16));
    } catch (e) {
      return match; // Keep original if decode fails
    }
  });

  // Remove email signatures (common patterns)
  body = body.replace(/^--\s*$/gm, ''); // Signature delimiter
  body = body.replace(/_{10,}/g, ''); // Long underscores

  // Remove quoted replies (lines starting with >)
  body = body.split('\n')
    .filter(line => !line.trim().startsWith('>'))
    .join('\n');

  // Remove common email footers
  body = body.replace(/^(Sent from my|Get Outlook for|Sent from|This email was sent).*$/gm, '');

  // Clean up excessive whitespace
  body = body.replace(/\n{3,}/g, '\n\n'); // Max 2 newlines
  body = body.trim();

  return body;
}

/**
 * Strip HTML tags and clean text
 * Enhanced to preserve structure from tables, forms, and formatted documents (W2, invoices, etc.)
 */
function stripHtml(html) {
  if (!html) return '';

  // Remove script and style tags with their content
  let text = html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
  text = text.replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '');

  // Remove HTML comments
  text = text.replace(/<!--[\s\S]*?-->/g, '');

  // PRESERVE STRUCTURE BEFORE REMOVING TAGS
  // Convert table rows to newlines (preserve table structure)
  text = text.replace(/<\/tr>/gi, '\n');
  text = text.replace(/<\/td>/gi, ' | ');  // Separate table cells with pipes
  text = text.replace(/<\/th>/gi, ' | ');

  // Convert line breaks to newlines
  text = text.replace(/<br\s*\/?>/gi, '\n');

  // Convert paragraph ends to double newlines
  text = text.replace(/<\/p>/gi, '\n\n');

  // Convert list items to newlines with bullets
  text = text.replace(/<li[^>]*>/gi, '\n• ');
  text = text.replace(/<\/li>/gi, '');

  // Convert div/section ends to newlines (preserve document structure)
  text = text.replace(/<\/div>/gi, '\n');
  text = text.replace(/<\/section>/gi, '\n');

  // NOW remove all remaining HTML tags
  text = text.replace(/<[^>]+>/g, ' ');

  // Decode common HTML entities
  text = text.replace(/&nbsp;/g, ' ');
  text = text.replace(/&amp;/g, '&');
  text = text.replace(/&lt;/g, '<');
  text = text.replace(/&gt;/g, '>');
  text = text.replace(/&quot;/g, '"');
  text = text.replace(/&#39;/g, "'");
  text = text.replace(/&apos;/g, "'");
  text = text.replace(/&mdash;/g, '—');
  text = text.replace(/&ndash;/g, '–');
  text = text.replace(/&hellip;/g, '...');

  // Clean up whitespace MORE CAREFULLY (preserve paragraph structure)
  // Replace multiple spaces with single space (but preserve newlines)
  text = text.replace(/[ \t]+/g, ' ');  // Only collapse spaces/tabs, not newlines

  // Replace excessive newlines (max 2) to preserve paragraphs
  text = text.replace(/\n{3,}/g, '\n\n');

  // Remove leading/trailing whitespace from each line
  text = text.split('\n').map(line => line.trim()).join('\n');

  // Trim
  text = text.trim();

  return text;
}

/**
 * Fallback reply generation
 */
function fallbackReplyGeneration(email, context) {
  const templates = [
    `Thank you for your email. I've reviewed your message and will get back to you shortly.`,
    `Thanks for reaching out. I'll look into this and respond soon.`,
    `I appreciate you contacting me. Let me review this and I'll follow up.`
  ];

  const reply = templates[Math.floor(Math.random() * templates.length)];

  return {
    reply,
    suggestions: templates,
    source: 'fallback'
  };
}

/**
 * Extract title from email (clean subject line)
 */
function extractTitle(email) {
  let title = email.subject || 'Email';

  // Remove common prefixes
  title = title.replace(/^(re:|fwd:|fw:)\s*/i, '');

  // Limit length
  if (title.length > 60) {
    title = title.substring(0, 57) + '...';
  }

  return title;
}

/**
 * Calculate "time ago" string
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
 * Extract actionable items from email
 */
function extractActions(email) {
  const body = stripHtml(email.body || email.snippet || '').toLowerCase();
  const actions = [];

  // Detect common actions
  if (body.includes('sign') || body.includes('signature')) {
    actions.push({ type: 'sign', text: 'Requires signature' });
  }
  if (body.includes('rsvp') || body.includes('respond by')) {
    actions.push({ type: 'rsvp', text: 'RSVP required' });
  }
  if (body.includes('payment') || body.includes('invoice') || body.includes('pay')) {
    actions.push({ type: 'payment', text: 'Payment needed' });
  }
  if (body.includes('meeting') || body.includes('calendar') || body.includes('schedule')) {
    actions.push({ type: 'calendar', text: 'Add to calendar' });
  }
  if (body.includes('review') || body.includes('approval')) {
    actions.push({ type: 'review', text: 'Review required' });
  }
  if (body.includes('reply') || body.includes('respond')) {
    actions.push({ type: 'reply', text: 'Response needed' });
  }

  return {
    actions,
    hasActions: actions.length > 0
  };
}

// Error handling
app.use((err, req, res, next) => {
  logger.error('Summarization service error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  logger.info(`Summarization service running on port ${PORT}`);
  console.log(`🤖 Summarization Service (Gemini 2.0 Flash) listening on http://localhost:${PORT}`);
  console.log(`   Project: ${PROJECT_ID}`);
  console.log(`   Location: ${LOCATION}`);
  console.log(`   Model: ${MODEL_NAME}`);
});

module.exports = app;

const express = require('express');
const { VertexAI } = require('@google-cloud/vertexai');
const logger = require('./logger');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8086; // Changed from 8084 to avoid conflict with shopping-agent

// Initialize Vertex AI
const vertex_ai = new VertexAI({
  project: process.env.GOOGLE_CLOUD_PROJECT || 'gen-lang-client-0622702687',
  location: 'us-central1'
});

const generativeModel = vertex_ai.getGenerativeModel({
  model: 'gemini-1.5-flash',
  generationConfig: {
    maxOutputTokens: 200,
    temperature: 0.7,
    topP: 0.8,
  }
});

/**
 * POST /api/smart-replies
 * Generate 2-3 smart reply options for an email
 */
app.post('/api/smart-replies', async (req, res) => {
  try {
    const { email, threadContext, userTone } = req.body;

    if (!email || !email.subject) {
      return res.status(400).json({ error: 'Email data required' });
    }

    logger.info('Generating smart replies', {
      emailId: email.id,
      subject: email.subject?.substring(0, 50)
    });

    const prompt = buildSmartReplyPrompt(email, threadContext, userTone);

    let text = '';
    let latency = 0;

    // Try Vertex AI, fall back to mock if auth fails
    try {
      const startTime = Date.now();
      const result = await generativeModel.generateContent(prompt);
      latency = Date.now() - startTime;
      const response = result.response;
      text = response.text();
    } catch (authError) {
      // If auth error, use mock data for local development
      logger.warn('Vertex AI auth failed, using mock replies', {
        error: authError.message
      });
      text = null; // Force fallback below
    }

    // Parse response - expecting JSON array of reply strings
    let replies = [];

    if (text) {
      try {
        // Try to parse as JSON first
        replies = JSON.parse(text);
      } catch (e) {
        // Fallback: split by newlines and filter
        replies = text
          .split('\n')
          .filter(line => line.trim().length > 0 && line.trim().length < 200)
          .slice(0, 3);
      }
    }

    // Use mock replies if AI generation failed or returned too few
    if (replies.length < 2) {
      // Check if email is about child - use appropriate mock responses
      const isAboutChild = detectChildContext(email);

      if (isAboutChild) {
        replies = [
          "Thanks for letting me know. I'll discuss this with them.",
          "I appreciate you keeping me informed. Happy to schedule a time to chat if needed.",
          "Got it - I'll follow up with them at home. Let me know if there's anything else."
        ];
      } else {
        replies = [
          "Thanks for reaching out! I'll review this and get back to you soon.",
          "Got it, thanks! I'll take a look.",
          "Thanks - will do!"
        ];
      }
    }

    logger.info('Smart replies generated', {
      emailId: email.id,
      count: replies.length,
      latency
    });

    res.json({
      replies: replies.slice(0, 3), // Max 3 replies
      metadata: {
        latency,
        model: 'gemini-1.5-flash',
        tone: userTone || 'professional'
      }
    });

  } catch (error) {
    logger.error('Error generating smart replies', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({ error: 'Failed to generate smart replies' });
  }
});

/**
 * POST /api/smart-replies/feedback
 * Log user feedback on smart reply (selected, edited, dismissed)
 */
app.post('/api/smart-replies/feedback', async (req, res) => {
  try {
    const { emailId, replyIndex, action, originalReply, finalReply } = req.body;
    // action: 'selected', 'edited', 'dismissed'

    logger.info('Smart reply feedback', {
      emailId,
      replyIndex,
      action,
      wasEdited: action === 'edited' && originalReply !== finalReply
    });

    // Store feedback for model improvement
    // TODO: Persist to database for training data

    res.json({ success: true });

  } catch (error) {
    logger.error('Error logging smart reply feedback', {
      error: error.message
    });
    res.status(500).json({ error: 'Failed to log feedback' });
  }
});

/**
 * GET /health
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'smart-replies' });
});

/**
 * Build smart reply prompt
 */
function buildSmartReplyPrompt(email, threadContext, userTone) {
  const tone = userTone || 'professional but friendly';

  // Detect if this email is about the user's child (education/family context)
  const isAboutChild = detectChildContext(email);

  let prompt = `Generate 3 short, natural email reply options.

Email Details:
From: ${email.from || 'Unknown'}
Subject: ${email.subject}
Body: ${(email.body || email.snippet).substring(0, 500)}`;

  if (threadContext) {
    prompt += `\n\nThread Context: This is part of an ongoing conversation with ${threadContext.messageCount || 1} previous messages.`;
  }

  // Adjust tone instructions based on context
  if (isAboutChild) {
    prompt += `\n\nContext: This email is from a teacher, coach, or school administrator about the user's child.

Tone Guidelines:
- Use a collaborative parent-to-educator tone
- Focus on the child's needs and development
- Express partnership and support (not apology or personal fault)
- Show engagement as a parent (e.g., "Thanks for keeping me informed", "I appreciate you letting me know")
- Offer to discuss or follow up if needed
- Avoid apologizing for things that aren't the parent's fault
- Frame responses around the child (e.g., "I'll talk with [child]" or "How can we support them?")

Generate 3 different reply options:
1. Quick acknowledgment focused on the child (1 sentence)
2. Engaged parent response showing partnership (1-2 sentences)
3. Collaborative follow-up offer (1 sentence)`;
  } else {
    prompt += `\n\nTone: ${tone}

Generate 3 different reply options:
1. Quick acknowledgment (5-10 words) - Brief and professional
2. Detailed response (1-2 sentences) - More thorough but still concise
3. Polite defer or alternative (1 sentence) - Option to decline or suggest alternative`;
  }

  prompt += `

Requirements:
- Keep each reply under 50 words
- Be natural and conversational
- Don't use placeholder text like [Your Name] or [child's name]
- Don't include salutations or signatures
- Match the situation and relationship

Return ONLY a JSON array of 3 reply strings, like this:
["Reply 1", "Reply 2", "Reply 3"]`;

  return prompt;
}

/**
 * Detect if email is about the user's child (education/family context)
 */
function detectChildContext(email) {
  const text = `${email.from || ''} ${email.subject || ''} ${email.body || email.snippet || ''}`.toLowerCase();

  // Education/school indicators
  const educationKeywords = [
    'teacher', 'school', 'classroom', 'grade', 'homework', 'assignment',
    'parent', 'student', 'class', 'education', 'principal', 'coach',
    'field trip', 'permission', 'behavior', 'progress', 'report card',
    'conference', 'pta', 'pto', 'kindergarten', 'elementary', 'middle school',
    'high school', 'tuition', 'enrollment', 'attendance', 'tardy', 'absent'
  ];

  // Check if any education keywords are present
  return educationKeywords.some(keyword => text.includes(keyword));
}

// Start server
app.listen(PORT, () => {
  logger.info(`Smart Replies service running on port ${PORT}`);
  console.log(`Smart Replies service listening on port ${PORT}`);
});

module.exports = app;

/**
 * Thread Context Extraction Utilities
 *
 * Extracts actionable context from email threads using regex patterns:
 * - Purchase history (invoices, amounts)
 * - Upcoming events (dates, appointments)
 * - Locations (addresses, phone numbers)
 * - Unresolved questions
 * - Conversation stage
 */

const logger = require('../config/logger');

/**
 * Extract all context from thread messages
 */
function extractThreadContext(messages) {
  logger.info('Extracting thread context', { messageCount: messages.length });

  const context = {
    purchases: extractPurchases(messages),
    upcomingEvents: extractFutureDates(messages),
    locations: extractLocations(messages),
    unresolvedQuestions: findUnresolvedQuestions(messages),
    conversationStage: determineStage(messages)
  };

  logger.info('Thread context extracted', {
    purchases: context.purchases.length,
    events: context.upcomingEvents.length,
    locations: context.locations.length,
    questions: context.unresolvedQuestions.length,
    stage: context.conversationStage
  });

  return context;
}

/**
 * Extract purchases (invoice numbers, amounts, dates)
 */
function extractPurchases(messages) {
  const purchases = [];

  for (const msg of messages) {
    const body = msg.body || '';

    // Invoice pattern: "Invoice #12345" or "Order #ABC-123" or "Receipt GH19690"
    const invoiceMatches = body.match(/(?:invoice|order|receipt|confirmation)\s*#?\s*:?\s*([A-Z0-9-]+)/gi);

    // Amount pattern: "$123.45" or "$1,234.56"
    const amountMatches = body.match(/\$\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)/g);

    if (invoiceMatches || amountMatches) {
      const invoiceNumber = invoiceMatches ? invoiceMatches[0].match(/([A-Z0-9-]+)$/i)?.[1] : null;
      const amount = amountMatches ? parseFloat(amountMatches[0].replace(/[$,]/g, '')) : null;

      purchases.push({
        invoiceNumber,
        amount,
        date: msg.date,
        messageId: msg.id
      });
    }
  }

  // Remove duplicates based on invoice number or amount
  return purchases.filter((purchase, index, self) =>
    index === self.findIndex(p =>
      (p.invoiceNumber && p.invoiceNumber === purchase.invoiceNumber) ||
      (p.amount && p.amount === purchase.amount && p.date === purchase.date)
    )
  );
}

/**
 * Extract future dates (appointments, deadlines)
 */
function extractFutureDates(messages) {
  const events = [];
  const now = Date.now();

  for (const msg of messages) {
    const body = msg.body || '';

    // Day of week: "Tuesday", "Wednesday"
    const dayMatches = body.match(/\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b/gi);

    // Month + day: "Oct 25", "February 22", "Feb 22"
    const dateMatches = body.match(/\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2}\b/gi);

    // ISO dates: "2025-02-25"
    const isoMatches = body.match(/\b\d{4}-\d{2}-\d{2}\b/g);

    // Time patterns: "5 PM", "10:00 AM", "3:30pm"
    const timeMatches = body.match(/\b\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)\b/gi);

    const allMatches = [
      ...(dayMatches || []),
      ...(dateMatches || []),
      ...(isoMatches || [])
    ];

    allMatches.forEach(match => {
      const parsedDate = parseRelativeDate(match, msg.timestamp);
      if (parsedDate && parsedDate > now) {
        // Find associated time if nearby
        const time = timeMatches && timeMatches.length > 0 ? timeMatches[0] : null;

        events.push({
          date: new Date(parsedDate).toISOString().split('T')[0],
          originalText: time ? `${match} at ${time}` : match,
          context: extractContextAround(body, match, 60)
        });
      }
    });
  }

  // Remove duplicates
  return events.filter((event, index, self) =>
    index === self.findIndex(e => e.date === event.date && e.originalText === event.originalText)
  );
}

/**
 * Parse relative dates like "Tuesday" into actual dates
 */
function parseRelativeDate(dateStr, referenceTimestamp) {
  const daysOfWeek = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  const lowerDate = dateStr.toLowerCase().trim();

  // If it's a day of week, find next occurrence
  const dayIndex = daysOfWeek.findIndex(day => lowerDate.includes(day));
  if (dayIndex !== -1) {
    const refDate = new Date(referenceTimestamp);
    const currentDay = refDate.getDay();
    const daysUntilTarget = (dayIndex - currentDay + 7) % 7 || 7; // Next occurrence
    const targetDate = new Date(refDate);
    targetDate.setDate(refDate.getDate() + daysUntilTarget);
    return targetDate.getTime();
  }

  // Try to parse as regular date
  try {
    const parsed = new Date(dateStr);
    if (!isNaN(parsed.getTime())) {
      return parsed.getTime();
    }
  } catch (e) {
    // Ignore parse errors
  }

  return null;
}

/**
 * Extract locations (addresses, phone numbers)
 */
function extractLocations(messages) {
  const locations = [];

  for (const msg of messages) {
    const body = msg.body || '';

    // Address pattern: "123 Main St, City, ST 12345"
    const addressMatch = body.match(/\d+\s+[\w\s]+(?:Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Boulevard|Blvd|Lane|Ln)[,\s]+[\w\s]+,\s*[A-Z]{2}\s*\d{5}/i);

    // Phone pattern: "(123) 456-7890" or "123-456-7890" or "123.456.7890"
    const phoneMatch = body.match(/\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}/);

    if (addressMatch || phoneMatch) {
      locations.push({
        address: addressMatch ? addressMatch[0].trim() : null,
        phone: phoneMatch ? phoneMatch[0].trim() : null,
        messageId: msg.id
      });
    }
  }

  // Remove duplicates
  return locations.filter((loc, index, self) =>
    index === self.findIndex(l =>
      (l.address && l.address === loc.address) ||
      (l.phone && l.phone === loc.phone)
    )
  );
}

/**
 * Find unresolved questions
 */
function findUnresolvedQuestions(messages) {
  const questions = [];

  for (let i = 0; i < messages.length; i++) {
    const msg = messages[i];
    const body = msg.body || '';

    // Find questions (sentences ending with ?)
    const questionMatches = body.match(/[^.!?]*\?/g);

    if (questionMatches) {
      questionMatches.forEach(question => {
        question = question.trim();

        // Skip very short questions (likely not real questions)
        if (question.length < 10) return;

        // Extract keywords from question
        const keywords = question.toLowerCase().match(/\b\w{4,}\b/g) || [];

        // Check if answered in subsequent messages
        const isAnswered = messages.slice(i + 1).some(laterMsg => {
          const laterBody = (laterMsg.body || '').toLowerCase();
          // Consider answered if 3+ keywords appear in later message
          const matchCount = keywords.filter(kw => laterBody.includes(kw)).length;
          return matchCount >= Math.min(3, keywords.length);
        });

        if (!isAnswered) {
          questions.push({
            question: question,
            askedBy: msg.from,
            date: msg.date
          });
        }
      });
    }
  }

  // Limit to 3 most recent unresolved questions
  return questions.slice(-3);
}

/**
 * Determine conversation stage
 */
function determineStage(messages) {
  const allText = messages.map(m => (m.body || '').toLowerCase()).join(' ');

  // Check for stage indicators (priority order)
  if (allText.includes('invoice') || allText.includes('receipt') || allText.includes('paid')) {
    return 'fulfillment';
  }
  if (allText.includes('order') || allText.includes('purchase') || allText.includes('bought')) {
    return 'order';
  }
  if (allText.includes('quote') || allText.includes('estimate') || allText.includes('proposal')) {
    return 'quotation';
  }
  if (allText.includes('appointment') || allText.includes('schedule') || allText.includes('meeting')) {
    return 'scheduling';
  }
  if (allText.includes('support') || allText.includes('help') || allText.includes('issue') || allText.includes('problem')) {
    return 'support';
  }
  if (allText.includes('follow up') || allText.includes('following up') || allText.includes('checking in')) {
    return 'followup';
  }

  return 'inquiry';
}

/**
 * Extract context around a keyword (for showing where entity was found)
 */
function extractContextAround(text, keyword, charLimit = 60) {
  const index = text.toLowerCase().indexOf(keyword.toLowerCase());
  if (index === -1) return text.substring(0, charLimit);

  const start = Math.max(0, index - charLimit);
  const end = Math.min(text.length, index + keyword.length + charLimit);

  let context = text.substring(start, end);
  if (start > 0) context = '...' + context;
  if (end < text.length) context = context + '...';

  return context;
}

module.exports = {
  extractThreadContext,
  extractPurchases,
  extractFutureDates,
  extractLocations,
  findUnresolvedQuestions,
  determineStage,
  extractContextAround
};

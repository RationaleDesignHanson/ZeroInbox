/**
 * Entity Extractor
 * Extracts structured entities from email content
 * Enhanced to support action-first model with intent-specific extraction
 */

const logger = require('./shared/config/logger');

/**
 * Main entity extraction function
 * Extracts all relevant entities from email
 * @param {Object} email - Email object with subject, body, from fields
 * @param {string} fullText - Full text content for extraction
 * @param {string|null} intentId - Optional intent ID for intent-specific extraction
 * @returns {Object} Extracted entities object
 */
function extractAllEntities(email, fullText, intentId = null) {
  // Validate inputs
  if (!email || typeof email !== 'object') {
    logger.error('Invalid email object provided to extractAllEntities', {
      emailType: typeof email
    });
    return {};
  }

  if (typeof fullText !== 'string') {
    logger.error('Invalid fullText provided to extractAllEntities', {
      fullTextType: typeof fullText
    });
    return {};
  }

  if (intentId !== null && typeof intentId !== 'string') {
    logger.warn('Invalid intentId type, ignoring intent-specific extraction', {
      intentIdType: typeof intentId
    });
    intentId = null;
  }
  const entities = {
    // Existing entities
    ...extractBasicEntities(email, fullText),

    // Enhanced entities for action-first model
    ...extractOrderEntities(fullText),
    ...extractTrackingEntities(fullText),
    ...extractPaymentEntities(fullText),
    ...extractMeetingEntities(email, fullText),
    ...extractAccountEntities(fullText),
    ...extractTravelEntities(fullText),

    // Product image extraction for shopping/ads emails
    ...extractProductImage(email)
  };

  // Intent-specific extraction
  if (intentId) {
    const intentSpecific = extractIntentSpecificEntities(fullText, intentId);
    Object.assign(entities, intentSpecific);
  }

  return entities;
}

/**
 * Extract basic entities (from original implementation)
 */
function extractBasicEntities(email, fullText) {
  return {
    children: extractChildren(fullText),
    teachers: extractTeachers(fullText),
    schools: extractSchools(fullText),
    companies: extractCompanies(fullText, email),
    stores: extractStores(fullText),
    flights: extractFlights(fullText),
    hotels: extractHotels(fullText),
    promoCodes: extractPromoCodes(fullText),
    accounts: extractAccounts(fullText),
    prices: extractPrices(fullText),
    deadline: extractDeadline(fullText)
  };
}

/**
 * Extract order-related entities
 */
function extractOrderEntities(text) {
  const entities = {};

  // Order numbers - various formats (minimum 6 characters)
  const orderPatterns = [
    /order\s*#\s*:?\s*([A-Z0-9-]{6,})/i,
    /order\s*number\s*:?\s*([A-Z0-9-]{6,})/i,
    /confirmation\s*#?\s*:?\s*([A-Z0-9-]{6,})/i,
    /order\s*id\s*:?\s*([A-Z0-9-]{6,})/i
  ];

  for (const pattern of orderPatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      entities.orderNumber = match[1].toUpperCase();
      break;
    }
  }

  // Order URLs
  const orderUrlMatch = text.match(/(https?:\/\/[^\s]+(?:order|purchase|account)[^\s]*)/i);
  if (orderUrlMatch) {
    entities.orderUrl = orderUrlMatch[1];
  }

  return entities;
}

/**
 * Extract tracking numbers and carriers
 */
function extractTrackingEntities(text) {
  const entities = {};

  // Carrier detection
  const carriers = ['ups', 'fedex', 'usps', 'dhl', 'amazon'];
  for (const carrier of carriers) {
    if (text.toLowerCase().includes(carrier)) {
      entities.carrier = carrier.toUpperCase();
      break;
    }
  }

  // Tracking number patterns
  const trackingPatterns = [
    // UPS: 1Z + alphanumeric (flexible for tests and real tracking numbers)
    { pattern: /\b(1Z[A-Z0-9]{5,})\b/i, carrier: 'UPS' },
    // FedEx: 12-14 digits
    { pattern: /\b(\d{12,14})\b/, carrier: 'FedEx' },
    // USPS: 20-22 digits
    { pattern: /\b(\d{20,22})\b/, carrier: 'USPS' },
    // Generic tracking (after specific patterns)
    { pattern: /tracking\s*#?\s*:?\s*([A-Z0-9]{5,})/i, carrier: null }
  ];

  for (const { pattern, carrier } of trackingPatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      entities.trackingNumber = match[1];
      if (carrier && !entities.carrier) {
        entities.carrier = carrier;
      }
      break;
    }
  }

  // Tracking URL
  const trackingUrlMatch = text.match(/(https?:\/\/[^\s]+(?:track|ups\.com|fedex\.com|usps\.com)[^\s]*)/i);
  if (trackingUrlMatch) {
    entities.trackingUrl = trackingUrlMatch[1];
  }

  return entities;
}

/**
 * Extract payment and billing entities
 */
function extractPaymentEntities(text) {
  const entities = {};

  // Invoice IDs
  const invoicePatterns = [
    /invoice\s*#?\s*:?\s*([A-Z0-9-]{6,})/i,
    /invoice\s*number\s*:?\s*([A-Z0-9-]{6,})/i,
    /bill\s*#?\s*:?\s*([A-Z0-9-]{6,})/i
  ];

  for (const pattern of invoicePatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      entities.invoiceId = match[1].toUpperCase();
      break;
    }
  }

  // Amount extraction - normalized to "amount" key for consistency
  // Tests and compound action detection expect "amount" key
  const amountPatterns = [
    // Invoice amounts
    /amount\s*due\s*:?\s*\$?([\d,]+\.?\d{0,2})/i,
    /total\s*due\s*:?\s*\$?([\d,]+\.?\d{0,2})/i,
    /balance\s*:?\s*\$?([\d,]+\.?\d{0,2})/i,
    // Generic amount
    /amount\s*:?\s*\$?([\d,]+\.?\d{0,2})/i,
    // Payment amount (permission forms, fees, etc.)
    /(?:submit|pay|fee|payment)\s+\$?([\d,]+\.?\d{0,2})/i,
    /\$?([\d,]+\.?\d{0,2})\s+payment/i,
    // Received payment
    /payment\s*(?:of|amount)?\s*:?\s*\$?([\d,]+\.?\d{0,2})/i,
    /received\s*:?\s*\$?([\d,]+\.?\d{0,2})/i,
    /paid\s*:?\s*\$?([\d,]+\.?\d{0,2})/i
  ];

  for (const pattern of amountPatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      // Keep as string for iOS compatibility (iOS prefers string values)
      const amountString = match[1].replace(/,/g, '');
      entities.amount = amountString;
      // Also set legacy keys for backward compatibility
      entities.amountDue = amountString;
      entities.paymentAmount = amountString;
      break;
    }
  }

  // Due date
  const dueDatePatterns = [
    /due\s*(?:date|by|on)\s*:?\s*(\w+\s+\d{1,2}(?:,\s*\d{4})?)/i,
    /payment\s*due\s*:?\s*(\w+\s+\d{1,2}(?:,\s*\d{4})?)/i
  ];

  for (const pattern of dueDatePatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      entities.dueDate = match[1];
      break;
    }
  }

  // Delivery date (for shipping notifications)
  const deliveryDatePatterns = [
    /(?:arriv(?:es?|ing)|deliver(?:y|ed))\s+(?:on\s+)?(\w+\s+\d{1,2}(?:,\s*\d{4})?)/i,
    /(?:arriv(?:es?|ing)|deliver(?:y|ed))\s+(tomorrow|today)/i,
    /(?:delivery|arrival)\s*:?\s*(\w+\s+\d{1,2}(?:,\s*\d{4})?)/i,  // "Delivery: Nov 5"
    /will\s+arrive\s+(\w+\s+\d{1,2}(?:,\s*\d{4})?)/i,
    /expected\s+(?:delivery|arrival)\s*:?\s*(\w+\s+\d{1,2}(?:,\s*\d{4})?)/i,
    /estimated\s+delivery\s*:?\s*(\w+\s+\d{1,2}(?:,\s*\d{4})?)/i
  ];

  for (const pattern of deliveryDatePatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      entities.deliveryDate = match[1];
      break;
    }
  }

  // Payment link - multiple patterns
  const paymentLinkPatterns = [
    /pay\s*(?:here)?\s*:?\s*(https?:\/\/[^\s]+)/i,  // "Pay: https://..." or "Pay here: https://..."
    /(https?:\/\/[^\s]+(?:pay|invoice|bill)[^\s]*)/i  // URLs containing pay/invoice/bill
  ];

  for (const pattern of paymentLinkPatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      entities.paymentLink = match[1];
      break;
    }
  }

  // Receipt URL
  const receiptUrlMatch = text.match(/(https?:\/\/[^\s]+(?:receipt|invoice)[^\s]*)/i);
  if (receiptUrlMatch) {
    entities.receiptUrl = receiptUrlMatch[1];
  }

  // Merchant/company name for invoices (for compound action detection)
  // Patterns: "from Company", "Company Invoice", domain extraction
  if (!entities.merchant) {
    const merchantPatterns = [
      /invoice\s+from\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})/i,
      /billing@([a-z0-9-]+)\./i,
      /([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\s+invoice/i
    ];

    for (const pattern of merchantPatterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        entities.merchant = match[1].charAt(0).toUpperCase() + match[1].slice(1);
        break;
      }
    }
  }

  return entities;
}

/**
 * Extract meeting and event entities
 */
function extractMeetingEntities(email, text) {
  const entities = {};

  // Meeting URLs (Zoom, Meet, Teams)
  const meetingUrlPatterns = [
    /(https?:\/\/(?:[a-z0-9-]+\.)?zoom\.us\/j\/\d+[^\s]*)/i,
    /(https?:\/\/meet\.google\.com\/[a-z0-9-]+)/i,
    /(https?:\/\/teams\.microsoft\.com\/l\/meetup-join\/[^\s]+)/i,
    /(https?:\/\/[a-z0-9-]+\.webex\.com\/[^\s]+)/i
  ];

  for (const pattern of meetingUrlPatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      entities.meetingUrl = match[1];
      break;
    }
  }

  // Event date and time
  const eventTimePatterns = [
    /(?:on|scheduled for)\s+(\w+,?\s+\w+\s+\d{1,2}(?:,\s*\d{4})?)\s+(?:at\s+)?(\d{1,2}:\d{2}\s*(?:am|pm)?)/i,
    /(\d{1,2}\/\d{1,2}\/\d{2,4})\s+(?:at\s+)?(\d{1,2}:\d{2}\s*(?:am|pm)?)/i
  ];

  for (const pattern of eventTimePatterns) {
    const match = text.match(pattern);
    if (match) {
      entities.eventDate = match[1];
      if (match[2]) {
        entities.eventTime = match[2];
      }
      break;
    }
  }

  // Event title (from subject)
  if (email && email.subject) {
    const cleanedSubject = email.subject
      .replace(/^(fwd?:|re:)/gi, '')
      .replace(/invitation:/gi, '')
      .replace(/meeting:/gi, '')
      .trim();
    
    if (cleanedSubject.length > 5) {
      entities.eventTitle = cleanedSubject;
    }
  }

  // Registration link
  const registrationMatch = text.match(/(https?:\/\/[^\s]+(?:register|rsvp|signup)[^\s]*)/i);
  if (registrationMatch) {
    entities.registrationLink = registrationMatch[1];
  }

  // Organizer (from email sender)
  if (email && email.from) {
    const organizerMatch = email.from.match(/^([^<]+)</);
    if (organizerMatch) {
      entities.organizer = organizerMatch[1].trim();
    }
  }

  return entities;
}

/**
 * Extract account and security entities
 */
function extractAccountEntities(text) {
  const entities = {};

  // Unsubscribe link (for marketing/promotional emails)
  const unsubscribePatterns = [
    /(https?:\/\/[^\s]+(?:unsubscribe|opt-out|optout|preferences|email-settings)[^\s]*)/i,
    /unsubscribe[^\s]*:\s*(https?:\/\/[^\s]+)/i
  ];

  for (const pattern of unsubscribePatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      entities.unsubscribeUrl = match[1];
      break;
    }
  }

  // Verification/Reset links
  const actionLinkPatterns = [
    /(https?:\/\/[^\s]+(?:reset|verify|confirm|activate)[^\s]*)/i
  ];

  for (const pattern of actionLinkPatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      if (text.toLowerCase().includes('reset')) {
        entities.resetLink = match[1];
      } else if (text.toLowerCase().includes('verif')) {
        entities.verificationLink = match[1];
      }
      break;
    }
  }

  // Username
  const usernamePatterns = [
    /username\s*:?\s*([a-z0-9_-]+)/i,
    /account\s*:?\s*([a-z0-9_.-]+@[a-z0-9.-]+)/i
  ];

  for (const pattern of usernamePatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      entities.username = match[1];
      break;
    }
  }

  // Device info
  if (text.includes('device') || text.includes('login')) {
    const deviceMatch = text.match(/(iphone|android|windows|mac|linux|chrome|firefox|safari)/i);
    if (deviceMatch) {
      entities.device = deviceMatch[1];
    }
  }

  // IP Address
  const ipMatch = text.match(/\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b/);
  if (ipMatch) {
    entities.ipAddress = ipMatch[1];
  }

  // Secret type (for exposed secrets)
  if (text.includes('api key') || text.includes('secret') || text.includes('token')) {
    const secretTypes = ['api key', 'access token', 'secret key', 'private key', 'password'];
    for (const secretType of secretTypes) {
      if (text.toLowerCase().includes(secretType)) {
        entities.secretType = secretType;
        break;
      }
    }
  }

  return entities;
}

/**
 * Extract travel entities
 */
function extractTravelEntities(text) {
  const entities = {};

  // Flight number extraction (e.g., "UA 123", "United 456", "flight AA 1234")
  const flightPatterns = [
    /flight\s+([A-Z]{2}\s*\d{3,4})\b/i,
    /\b([A-Z]{2}\s+\d{3,4})\b(?=.*(?:depart|arrive|check.?in|board|flight))/i,
    /flight\s+(?:number\s*)?([A-Z]{2}\s*\d{3,4})\b/i
  ];

  for (const pattern of flightPatterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      entities.flightNumber = match[1].trim().replace(/\s+/, ' '); // Normalize spacing
      break;
    }
  }

  // Confirmation codes (6 alphanumeric characters common for travel)
  const confirmationMatch = text.match(/confirmation\s*(?:code|number)?\s*:?\s*([A-Z0-9]{6})\b/i);
  if (confirmationMatch) {
    entities.confirmationCode = confirmationMatch[1].toUpperCase();
  }

  // Check-in URL
  const checkInMatch = text.match(/(https?:\/\/[^\s]+(?:checkin|check-in)[^\s]*)/i);
  if (checkInMatch) {
    entities.checkInUrl = checkInMatch[1];
  }

  // Itinerary URL
  const itineraryMatch = text.match(/(https?:\/\/[^\s]+(?:itinerary|booking|reservation)[^\s]*)/i);
  if (itineraryMatch) {
    entities.itineraryUrl = itineraryMatch[1];
  }

  // Departure date
  const departureDateMatch = text.match(/depart(?:ure|ing)?\s*(?:date|time)?\s*:?\s*(\w+\s+\d{1,2}(?:,\s*\d{4})?)/i);
  if (departureDateMatch) {
    entities.departureDate = departureDateMatch[1];
  }

  return entities;
}

/**
 * Extract product image URL from HTML email
 * Looks for prominent product images in ADS/shopping emails
 * @param {Object} email - Email object with htmlBody
 * @returns {Object} Object with productImageUrl if found
 */
function extractProductImage(email) {
  const entities = {};

  // Only extract from emails with HTML body
  if (!email || !email.htmlBody || typeof email.htmlBody !== 'string') {
    return entities;
  }

  const html = email.htmlBody;

  // Extract all img tags with src attributes
  const imgPattern = /<img[^>]+src=["']([^"']+)["'][^>]*>/gi;
  const images = [];
  let match;

  while ((match = imgPattern.exec(html)) !== null) {
    const imgTag = match[0];
    const src = match[1];

    // Skip tracking pixels, logos, and icons
    if (
      src.includes('tracking') ||
      src.includes('pixel') ||
      src.includes('logo') ||
      src.includes('icon') ||
      src.includes('1x1') ||
      src.match(/\d+x\d+/) && src.match(/\d+x\d+/)[0].split('x').some(d => parseInt(d) < 50) ||
      src.endsWith('.gif') && src.includes('spacer')
    ) {
      continue;
    }

    // Check if image has width/height attributes suggesting it's a product image
    const widthMatch = imgTag.match(/width=["']?(\d+)/i);
    const heightMatch = imgTag.match(/height=["']?(\d+)/i);
    const width = widthMatch ? parseInt(widthMatch[1]) : 0;
    const height = heightMatch ? parseInt(heightMatch[1]) : 0;

    // Product images are typically larger (width > 100px)
    if (width > 100 || height > 100 || (!width && !height)) {
      // Check alt text for product-related keywords
      const altMatch = imgTag.match(/alt=["']([^"']*)["']/i);
      const alt = altMatch ? altMatch[1].toLowerCase() : '';

      const isProductImage =
        alt.includes('product') ||
        alt.includes('item') ||
        alt.includes('buy') ||
        alt.includes('shop') ||
        alt.includes('deal') ||
        alt.includes('sale') ||
        !alt; // No alt text often means product image

      images.push({
        src,
        width: width || 999, // Unknown width gets high priority
        height: height || 999,
        isProductImage,
        score: (width + height) * (isProductImage ? 2 : 1)
      });
    }
  }

  // Sort by score (prefer larger product images)
  images.sort((a, b) => b.score - a.score);

  // Return the first (highest-scoring) image
  if (images.length > 0) {
    entities.productImageUrl = images[0].src;
  }

  return entities;
}

/**
 * Extract intent-specific entities
 */
function extractIntentSpecificEntities(text, intentId) {
  const entities = {};

  // Education-specific
  if (intentId.startsWith('education.')) {
    // Assignment name
    const assignmentMatch = text.match(/assignment\s*:?\s*([^.\n]+)/i);
    if (assignmentMatch) {
      entities.assignmentName = assignmentMatch[1].trim();
    }

    // Student name
    const studentMatch = text.match(/(?:for|student)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)/);
    if (studentMatch) {
      entities.studentName = studentMatch[1];
    }

    // Grade
    const gradeMatch = text.match(/grade\s*:?\s*(\d+%?|[A-F][+-]?)/i);
    if (gradeMatch) {
      entities.grade = gradeMatch[1];
    }

    // Form name
    if (text.includes('permission') || text.includes('consent')) {
      const formMatch = text.match(/(field trip|permission|consent|volunteer)(?:\s+form)?/i);
      if (formMatch) {
        entities.formName = formMatch[0].toLowerCase();
      }
    }

    // Event date for forms (field trips, events)
    // Patterns like "Nov 15 field trip", "for Nov 15", "on November 15"
    const eventDatePatterns = [
      /(?:for|on|event|trip)\s+(\w+\s+\d{1,2}(?:,?\s*\d{4})?)/i,
      /(\w+\s+\d{1,2}(?:,?\s*\d{4})?)\s+(?:field\s+trip|event|trip)/i,
      /sign\s+form\s+for\s+(\w+\s+\d{1,2}(?:,?\s*\d{4})?)/i
    ];

    for (const pattern of eventDatePatterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        entities.eventDate = match[1];
        break;
      }
    }

    // Assignment URL (Canvas, Schoology, etc.)
    const assignmentUrlMatch = text.match(/(https?:\/\/[^\s]+(?:canvas|schoology|assignment)[^\s]*)/i);
    if (assignmentUrlMatch) {
      entities.assignmentUrl = assignmentUrlMatch[1];
      entities.gradeUrl = assignmentUrlMatch[1]; // Same URL often shows grade
    }
  }

  // Support ticket specific
  if (intentId.startsWith('support.')) {
    const ticketPatterns = [
      /(?:ticket|case)\s*#?\s*:?\s*([A-Z0-9-]{6,})/i,
      /(?:ticket|case)\s*number\s*:?\s*([A-Z0-9-]{6,})/i
    ];

    for (const pattern of ticketPatterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        entities.ticketId = match[1].toUpperCase();
        break;
      }
    }

    const ticketUrlMatch = text.match(/(https?:\/\/[^\s]+(?:ticket|support|case)[^\s]*)/i);
    if (ticketUrlMatch) {
      entities.ticketUrl = ticketUrlMatch[1];
    }
  }

  // Project/task specific
  if (intentId.startsWith('project.')) {
    const taskMatch = text.match(/task\s*:?\s*([^.\n]+)/i);
    if (taskMatch) {
      entities.taskName = taskMatch[1].trim();
    }

    const taskUrlMatch = text.match(/(https?:\/\/[^\s]+(?:jira|asana|trello|github|gitlab)[^\s]*)/i);
    if (taskUrlMatch) {
      entities.taskUrl = taskUrlMatch[1];
    }

    if (text.includes('incident') || text.includes('alert')) {
      const severityMatch = text.match(/severity\s*:?\s*(critical|high|medium|low|p[0-4])/i);
      if (severityMatch) {
        entities.severity = severityMatch[1];
      }

      const incidentUrlMatch = text.match(/(https?:\/\/[^\s]+(?:incident|alert|status)[^\s]*)/i);
      if (incidentUrlMatch) {
        entities.incidentUrl = incidentUrlMatch[1];
      }
    }
  }

  // Review/feedback specific
  if (intentId.startsWith('feedback.')) {
    const productMatch = text.match(/(?:product|item|purchase)\s*:?\s*([^.\n]{5,50})/i);
    if (productMatch) {
      entities.productName = productMatch[1].trim();
    }

    const reviewLinkMatch = text.match(/(https?:\/\/[^\s]+(?:review|feedback|rating)[^\s]*)/i);
    if (reviewLinkMatch) {
      entities.reviewLink = reviewLinkMatch[1];
    }

    const surveyLinkMatch = text.match(/(https?:\/\/[^\s]+(?:survey|questionnaire)[^\s]*)/i);
    if (surveyLinkMatch) {
      entities.surveyLink = surveyLinkMatch[1];
    }
  }

  // Healthcare-specific entities
  if (intentId.startsWith('healthcare.')) {
    // Healthcare provider
    const providerMatch = text.match(/(?:[Dd]r\.|[Dd]octor|[Pp]hysician)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b/);
    if (providerMatch) {
      entities.provider = providerMatch[0].trim();
    }

    // Medical specialty
    const specialtyPatterns = ['cardiology', 'pediatrics', 'dermatology', 'orthopedics', 'oncology'];
    for (const specialty of specialtyPatterns) {
      if (text.toLowerCase().includes(specialty)) {
        entities.specialty = specialty;
        break;
      }
    }

    // Appointment date and time extraction
    // Pattern 1: "January 15, 2025 at 2:00 PM"
    const dateTimePattern1 = /(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(?:,?\s+(\d{4}))?\s+at\s+(\d{1,2}:\d{2})\s*(am|pm)?/i;
    const dateTimeMatch1 = text.match(dateTimePattern1);

    if (dateTimeMatch1) {
      const month = dateTimeMatch1[1];
      const day = dateTimeMatch1[2];
      const year = dateTimeMatch1[3] || new Date().getFullYear();
      const time = dateTimeMatch1[4];
      const ampm = dateTimeMatch1[5] || '';

      entities.appointmentDate = `${month} ${day}, ${year}`;
      entities.appointmentTime = `${time} ${ampm}`.trim();
      entities.dateTime = `${month} ${day}, ${year} at ${time} ${ampm}`.trim();
    }

    // Pattern 2: "scheduled for January 15"
    if (!entities.dateTime) {
      const datePattern = /(?:scheduled for|appointment (?:on|is)|on|for)\s+(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})(?:,?\s+(\d{4}))?/i;
      const dateMatch = text.match(datePattern);

      if (dateMatch) {
        const month = dateMatch[1];
        const day = dateMatch[2];
        const year = dateMatch[3] || new Date().getFullYear();

        entities.appointmentDate = `${month} ${day}, ${year}`;

        // Try to find time separately
        const timePattern = /(?:at|@)\s+(\d{1,2}:\d{2})\s*(am|pm)?/i;
        const timeMatch = text.match(timePattern);

        if (timeMatch) {
          const time = timeMatch[1];
          const ampm = timeMatch[2] || '';
          entities.appointmentTime = `${time} ${ampm}`.trim();
          entities.dateTime = `${month} ${day}, ${year} at ${time} ${ampm}`.trim();
        } else {
          // Date only, no time
          entities.dateTime = `${month} ${day}, ${year}`;
        }
      }
    }

    // Pattern 3: Numeric date format "12/15/2025"
    if (!entities.dateTime) {
      const numericDatePattern = /(\d{1,2})\/(\d{1,2})\/(\d{2,4})/;
      const numericMatch = text.match(numericDatePattern);

      if (numericMatch) {
        const month = numericMatch[1];
        const day = numericMatch[2];
        let year = numericMatch[3];
        if (year.length === 2) {
          year = '20' + year;
        }

        entities.appointmentDate = `${month}/${day}/${year}`;

        // Try to find time
        const timePattern = /(?:at|@)\s+(\d{1,2}:\d{2})\s*(am|pm)?/i;
        const timeMatch = text.match(timePattern);

        if (timeMatch) {
          const time = timeMatch[1];
          const ampm = timeMatch[2] || '';
          entities.appointmentTime = `${time} ${ampm}`.trim();
          entities.dateTime = `${month}/${day}/${year} at ${time} ${ampm}`.trim();
        } else {
          entities.dateTime = `${month}/${day}/${year}`;
        }
      }
    }

    // Scheduling URL (for booking appointments online)
    const schedulingUrlMatch = text.match(/(https?:\/\/[^\s]+(?:schedule|scheduling|book|booking|calendar|appointment)[^\s]*)/i);
    if (schedulingUrlMatch) {
      entities.schedulingUrl = schedulingUrlMatch[1];
    }

    // Prescription number
    const rxNumberMatch = text.match(/(?:prescription|rx)\s*#?\s*:?\s*([A-Z0-9]{6,})/i);
    if (rxNumberMatch) {
      entities.rxNumber = rxNumberMatch[1];
    }

    // Medication name
    const medicationMatch = text.match(/(?:prescription|medication|drug)\s+(?:for\s+)?([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)/i);
    if (medicationMatch) {
      entities.medication = medicationMatch[1];
    }

    // Lab results URL
    const resultsUrlMatch = text.match(/(https?:\/\/[^\s]+(?:results|lab|portal|mychart|health)[^\s]*)/i);
    if (resultsUrlMatch) {
      entities.resultsUrl = resultsUrlMatch[1];
    }

    // Check-in URL (already extracted in extractTravelEntities, but ensure it's captured here)
    if (!entities.checkInUrl) {
      const checkInMatch = text.match(/(https?:\/\/[^\s]+(?:checkin|check-in|registration)[^\s]*)/i);
      if (checkInMatch) {
        entities.checkInUrl = checkInMatch[1];
      }
    }

    // Confirmation URL (for confirming appointments)
    const confirmationUrlMatch = text.match(/(https?:\/\/[^\s]+(?:confirm|confirmation)[^\s]*)/i);
    if (confirmationUrlMatch) {
      entities.confirmationUrl = confirmationUrlMatch[1];
    }

    // Test/result type
    const testTypeMatch = text.match(/(?:test|lab|result)\s+(?:for\s+)?([a-z\s]+(?:test|panel|screening))/i);
    if (testTypeMatch) {
      entities.resultType = testTypeMatch[1].trim();
    }

    // Pickup deadline (for prescriptions)
    const pickupMatch = text.match(/pick\s+up\s+by\s+(\w+\s+\d{1,2}(?:,\s*\d{4})?)/i);
    if (pickupMatch) {
      entities.pickupDeadline = pickupMatch[1];
    }

    // Location (pharmacy, hospital, clinic)
    const locationMatch = text.match(/(?:at|location)\s*:?\s*([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,3}(?:\s+(?:CVS|Walgreens|Hospital|Clinic|Medical Center))?)/);
    if (locationMatch) {
      entities.location = locationMatch[1];
    }
  }

  // Dining/restaurant-specific entities
  if (intentId.startsWith('dining.')) {
    // Restaurant name - improved pattern to catch "at Restaurant Name"
    const restaurantMatch = text.match(/(?:at|reservation at)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,3})/);
    if (restaurantMatch) {
      entities.restaurant = restaurantMatch[1];
    }

    // Party size
    const partySizeMatch = text.match(/(?:for|party of)\s+(\d+)(?:\s+(?:people|guests|person))?/i);
    if (partySizeMatch) {
      entities.partySize = parseInt(partySizeMatch[1]);
    }

    // Reservation URL (OpenTable, Resy, etc.)
    const reservationUrlMatch = text.match(/(https?:\/\/[^\s]+(?:opentable|resy|reservation|booking|manage)[^\s]*)/i);
    if (reservationUrlMatch) {
      entities.reservationUrl = reservationUrlMatch[1];
    }

    // Confirmation code - improved pattern to match "Confirmation: CODE" format
    if (!entities.confirmationCode) {
      const confirmationPatterns = [
        /confirmation\s*(?:code|number|#)?\s*:?\s*([A-Z0-9-]{4,})/i,
        /confirmation:\s*([A-Z0-9-]{4,})/i,
        /conf\s*#?\s*:?\s*([A-Z0-9-]{4,})/i
      ];

      for (const pattern of confirmationPatterns) {
        const match = text.match(pattern);
        if (match && match[1]) {
          entities.confirmationCode = match[1].toUpperCase();
          break;
        }
      }
    }

    // Reservation date and time
    const reservationTimeMatch = text.match(/(?:confirmed for|reservation for)\s+\w+\s+\d{1,2}\s+at\s+(\d{1,2}:\d{2}\s*(?:am|pm)?)/i);
    if (reservationTimeMatch) {
      entities.reservationTime = reservationTimeMatch[1];
    }
  }

  // Food delivery tracking
  if (intentId === 'delivery.food.tracking') {
    // Restaurant name
    const restaurantMatch = text.match(/(?:from|order from)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})/);
    if (restaurantMatch) {
      entities.restaurant = restaurantMatch[1];
    }

    // Driver name
    const driverMatch = text.match(/(?:driver|dasher|courier)\s+(?:is\s+)?([A-Z][a-z]+)/i);
    if (driverMatch) {
      entities.driver = driverMatch[1];
    }

    // ETA (estimated time of arrival)
    const etaPatterns = [
      /(\d+)\s+minutes?\s+away/i,
      /arriving\s+in\s+(\d+)\s+minutes?/i,
      /eta\s*:?\s*(\d+)\s+(?:min|minutes?)/i
    ];

    for (const pattern of etaPatterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        entities.eta = `${match[1]} min`;
        break;
      }
    }

    // Tracking URL (DoorDash, Uber Eats, etc.)
    const trackingUrlMatch = text.match(/(https?:\/\/[^\s]+(?:doordash|ubereats|uber|instacart|grubhub|track|order)[^\s]*)/i);
    if (trackingUrlMatch) {
      entities.trackingUrl = trackingUrlMatch[1];
    }

    // Order number (if not already extracted)
    if (!entities.orderNumber) {
      const orderMatch = text.match(/order\s*#?\s*:?\s*([A-Z0-9-]{6,})/i);
      if (orderMatch) {
        entities.orderNumber = orderMatch[1].toUpperCase();
      }
    }
  }

  // Billing/subscription management
  if (intentId === 'billing.subscription.renewal') {
    // Subscription URL (account settings, payment update)
    const subscriptionUrlMatch = text.match(/(https?:\/\/[^\s]+(?:subscription|account|settings|manage|payment|billing)[^\s]*)/i);
    if (subscriptionUrlMatch) {
      entities.subscriptionUrl = subscriptionUrlMatch[1];
      // Also set as paymentUrl for update_payment action
      entities.paymentUrl = subscriptionUrlMatch[1];
    }

    // Service name
    const serviceMatch = text.match(/(?:your|the)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\s+(?:subscription|membership|account)/i);
    if (serviceMatch) {
      entities.serviceName = serviceMatch[1];
    }

    // Renewal date
    const renewalDateMatch = text.match(/(?:renews?|renewal)\s+(?:on|date)\s*:?\s*(\w+\s+\d{1,2}(?:,\s*\d{4})?)/i);
    if (renewalDateMatch) {
      entities.renewalDate = renewalDateMatch[1];
    }
  }

  // Civic/government appointments
  if (intentId === 'civic.appointment.summons') {
    // Appointment type
    const appointmentTypes = ['jury duty', 'dmv appointment', 'voter registration', 'court appearance'];
    for (const type of appointmentTypes) {
      if (text.toLowerCase().includes(type)) {
        entities.appointmentType = type;
        break;
      }
    }

    // Juror number
    const jurorNumberMatch = text.match(/juror\s*#?\s*:?\s*([A-Z0-9]{6,})/i);
    if (jurorNumberMatch) {
      entities.jurorNumber = jurorNumberMatch[1].toUpperCase();
    }

    // Location (courthouse, DMV, etc.)
    const locationMatch = text.match(/(?:at|location|report to)\s*:?\s*([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,5}(?:\s+(?:Courthouse|DMV|Office|Center))?)/);
    if (locationMatch) {
      entities.location = locationMatch[1];
    }

    // Appointment URL
    const appointmentUrlMatch = text.match(/(https?:\/\/[^\s]+(?:\.gov|dmv|court|registration)[^\s]*)/i);
    if (appointmentUrlMatch) {
      entities.appointmentUrl = appointmentUrlMatch[1];
    }
  }

  // Shopping future sale specific
  if (intentId === 'shopping.future_sale') {
    // Sale date - various formats
    const saleDatePatterns = [
      // "31 October", "October 31", "Oct 31"
      /(?:launching|available|releasing|drops on|goes on sale|releases on)\s+(?:on\s+)?(\d{1,2}\s+(?:january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)(?:\s+\d{4})?)/i,
      /(?:launching|available|releasing|drops on|goes on sale|releases on)\s+(?:on\s+)?((?:january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}(?:,?\s+\d{4})?)/i,
      // Fallback: just month and day
      /\b(\d{1,2}\s+(?:january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)(?:\s+\d{4})?)\b/i,
      /\b((?:january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}(?:,?\s+\d{4})?)\b/i
    ];

    for (const pattern of saleDatePatterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        entities.saleDate = match[1].trim();

        // Create short form for display (e.g., "Oct 31")
        const dateStr = match[1].trim();
        const monthMatch = dateStr.match(/(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/i);
        const dayMatch = dateStr.match(/\b(\d{1,2})\b/);
        if (monthMatch && dayMatch) {
          const month = monthMatch[1].substring(0, 3).charAt(0).toUpperCase() + monthMatch[1].substring(1, 3);
          entities.saleDateShort = `${month} ${dayMatch[1]}`;
        }
        break;
      }
    }

    // Sale time
    const timePatterns = [
      /(?:at|@)\s+(\d{1,2}:\d{2})\s*(am|pm|uk|gmt|est|pst|cet)?/i,
      /(\d{1,2}:\d{2})\s*(uk time|gmt|est|pst|cet)/i
    ];

    for (const pattern of timePatterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        entities.saleTime = match[1];
        if (match[2]) {
          entities.timezone = match[2].toUpperCase();
        }
        break;
      }
    }

    // Product URL - look for any http/https link
    const urlPattern = /(https?:\/\/[^\s]+)/i;
    const urlMatch = text.match(urlPattern);
    if (urlMatch) {
      entities.productUrl = urlMatch[1];
    }

    // Product name - try to extract from context
    const productNamePatterns = [
      /(?:the|this)\s+([^,.\n]{5,50})\s+(?:launching|available|collection|release)/i,
      /^([^,.\n]{5,50})\s+(?:launching|available|collection|release)/i
    ];

    for (const pattern of productNamePatterns) {
      const match = text.match(pattern);
      if (match && match[1]) {
        entities.productName = match[1].trim();
        break;
      }
    }

    // Variants - look for variant info
    if (text.includes('variant') || text.includes('color') || text.includes('size')) {
      const variantMatch = text.match(/(\d+)\s+variants?/i);
      if (variantMatch) {
        entities.variantCount = parseInt(variantMatch[1]);
      }
    }

    // Limited edition/quantity indicators
    if (text.includes('limited edition') || text.includes('limited quantity') || text.includes('one week only')) {
      entities.limitedEdition = true;
    }

    // Duration/availability window
    const durationMatch = text.match(/available for\s+(\d+\s+(?:day|week|hour)s?)/i);
    if (durationMatch) {
      entities.availabilityDuration = durationMatch[1];
    }
  }

  return entities;
}

// Import existing helper functions from enhanced-classifier.js
function extractChildren(text) {
  const childPatterns = [
    /\b([A-Z][a-z]+)\s+Chen\b/g,
    /your\s+child[,\s]+([A-Z][a-z]+)/gi,
    /\b([A-Z][a-z]+)'s\s+(grade|class|teacher)/gi
  ];

  const children = [];
  childPatterns.forEach(pattern => {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      if (match[1] && !children.includes(match[1])) {
        children.push(match[1]);
      }
    }
  });

  return children;
}

function extractTeachers(text) {
  const teacherPatterns = [
    /(Mrs?\.|Ms\.|Miss|Mr\.)\s+([A-Z][a-z]+)/g,
    /teacher\s+([A-Z][a-z]+\s+[A-Z][a-z]+)/gi
  ];

  const teachers = [];
  teacherPatterns.forEach(pattern => {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      const name = match[0].replace(/teacher\s+/gi, '').trim();
      if (!teachers.includes(name)) {
        teachers.push(name);
      }
    }
  });

  return teachers;
}

function extractSchools(text) {
  const schoolPatterns = [
    /([A-Z][a-z]+\s+(?:Elementary|Middle|High|Prep)\s+School)/g,
    /([A-Z][a-z]+\s+Academy)/g,
    /([A-Z][a-z]+\s+Preschool)/g
  ];

  const schools = [];
  schoolPatterns.forEach(pattern => {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      if (!schools.includes(match[1])) {
        schools.push(match[1]);
      }
    }
  });

  return schools;
}

function extractCompanies(text, email) {
  const companies = [];

  const companyPatterns = [
    /\b([A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+){0,2})\s+(?:Inc|LLC|Corp|Corporation|Industries|Systems|Solutions|Technologies)\b/g
  ];

  companyPatterns.forEach(pattern => {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      if (!companies.includes(match[1])) {
        companies.push(match[1]);
      }
    }
  });

  if (email && email.from) {
    const companyFromSender = extractCompanyFromSender(email.from);
    if (companyFromSender && !companies.includes(companyFromSender)) {
      companies.push(companyFromSender);
    }
  }

  return companies;
}

function extractCompanyFromSender(from) {
  if (!from) return null;

  const displayNameMatch = from.match(/^([^<]+)</);
  if (displayNameMatch) {
    const name = displayNameMatch[1].trim();
    const cleanName = name.replace(/\s+(Team|Support|Inc|LLC|Notifications|Security|Admin)\.?$/i, '').trim();
    if (cleanName && cleanName.length > 2) {
      return cleanName;
    }
  }

  const emailMatch = from.match(/@([a-z0-9-]+)\./i);
  if (emailMatch) {
    const domain = emailMatch[1];
    const genericDomains = ['gmail', 'yahoo', 'outlook', 'hotmail', 'mail', 'email'];
    if (!genericDomains.includes(domain.toLowerCase())) {
      return domain.charAt(0).toUpperCase() + domain.slice(1);
    }
  }

  return null;
}

function extractStores(text) {
  const knownStores = ['amazon', 'best buy', 'target', 'walmart', 'techmart', 'modernhome', 'fashionforward'];
  const stores = [];

  knownStores.forEach(store => {
    if (text.toLowerCase().includes(store)) {
      stores.push(store.split(' ').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' '));
    }
  });

  return stores;
}

function extractFlights(text) {
  const flightPattern = /\b([A-Z]{2})\s*(\d{3,4})\b/g;
  const flights = [];
  const matches = text.matchAll(flightPattern);

  for (const match of matches) {
    flights.push({
      airline: match[1],
      number: match[2],
      full: `${match[1]} ${match[2]}`
    });
  }

  return flights;
}

function extractHotels(text) {
  const hotelPatterns = [
    /(Marriott|Hilton|Hyatt|Holiday Inn|Best Western)/gi
  ];

  const hotels = [];
  hotelPatterns.forEach(pattern => {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      if (!hotels.includes(match[1])) {
        hotels.push(match[1]);
      }
    }
  });

  return hotels;
}

function extractPromoCodes(text) {
  const promoPattern = /\b([A-Z0-9]{4,12})\b/g;
  const promoCodes = [];

  if (text.includes('promo') || text.includes('code') || text.includes('coupon')) {
    const matches = text.matchAll(promoPattern);
    for (const match of matches) {
      promoCodes.push(match[1]);
    }
  }

  return promoCodes.slice(0, 3);
}

function extractAccounts(text) {
  const accountTypes = [];

  if (text.includes('chase') || text.includes('wells fargo') || text.includes('bank of america')) {
    accountTypes.push('bank');
  }
  if (text.includes('lastpass') || text.includes('1password') || text.includes('password manager')) {
    accountTypes.push('password_manager');
  }
  if (text.includes('github') || text.includes('gitlab')) {
    accountTypes.push('developer');
  }

  return accountTypes;
}

function extractPrices(text) {
  const pricePattern = /\$[\d,]+\.?\d{0,2}/g;
  const prices = [];
  const matches = text.matchAll(pricePattern);

  for (const match of matches) {
    const price = parseFloat(match[0].replace(/[$,]/g, ''));
    prices.push(price);
  }

  const totalPatterns = [
    /total[:\s]+\$?([\d,]+\.?\d{0,2})/i,
    /grand total[:\s]+\$?([\d,]+\.?\d{0,2})/i,
    /amount[:\s]+\$?([\d,]+\.?\d{0,2})/i,
    /payment[:\s]+(?:of|amount)?[:\s]*\$?([\d,]+\.?\d{0,2})/i
  ];

  for (const pattern of totalPatterns) {
    const match = text.match(pattern);
    if (match) {
      const totalAmount = parseFloat(match[1].replace(/,/g, ''));
      return {
        original: totalAmount,
        sale: null,
        discount: 0,
        savings: 0
      };
    }
  }

  if (prices.length >= 2) {
    const isSale = /\b(sale|discount|save|off|was|now)\b/i.test(text);

    if (isSale) {
      const original = Math.max(...prices);
      const sale = Math.min(...prices);
      const discount = Math.round(((original - sale) / original) * 100);

      return {
        original,
        sale,
        discount,
        savings: original - sale
      };
    }

    return {
      original: Math.max(...prices),
      sale: null,
      discount: 0,
      savings: 0
    };
  }

  return {
    original: prices[0] || null,
    sale: null,
    discount: 0,
    savings: 0
  };
}

function extractDeadline(text) {
  const deadlinePatterns = [
    { pattern: /due\s+today/i, isUrgent: true, text: 'today', unit: 'day', value: 0 },
    { pattern: /expires?\s+today/i, isUrgent: true, text: 'today', unit: 'day', value: 0 },
    { pattern: /today\s+only/i, isUrgent: true, text: 'today only', unit: 'day', value: 0 },
    { pattern: /last\s+chance/i, isUrgent: true, text: 'last chance', unit: 'unknown', value: 0 },
    { pattern: /ending\s+soon/i, isUrgent: true, text: 'ending soon', unit: 'unknown', value: 0 },
    { pattern: /expires?\s+in\s+(\d+)\s+(hour|day|week)s?/i, extract: true },
    { pattern: /ends?\s+in\s+(\d+)\s+(hour|day|week)s?/i, extract: true },
    { pattern: /(\d+)\s+(hour|day|week)s?\s+(?:left|remaining)/i, extract: true },
    { pattern: /due\s+(?:by\s+)?(\d{1,2})\s*(am|pm)/i, extract: true, unit: 'hour' },
    { pattern: /due\s+(?:by\s+)?(\w+\s+\d{1,2})/i, extract: true, unit: 'date' },
    { pattern: /expires?\s+(?:on\s+)?(\w+\s+\d{1,2})/i, extract: true, unit: 'date' },
    { pattern: /deadline:\s+(\w+\s+\d{1,2})/i, extract: true, unit: 'date' }
  ];

  for (const config of deadlinePatterns) {
    const match = text.match(config.pattern);
    if (match) {
      if (config.extract) {
        const value = parseInt(match[1]) || 0;
        const unit = config.unit || match[2] || 'unknown';
        const isUrgent = unit === 'hour' && value <= 4 || unit === 'day' && value <= 1;

        return {
          text: match[0],
          value,
          unit,
          isUrgent
        };
      } else {
        return {
          text: config.text,
          value: config.value,
          unit: config.unit,
          isUrgent: config.isUrgent
        };
      }
    }
  }

  return null;
}

/**
 * Wrapper function for test compatibility
 * Extracts entities from email with intent context
 * @param {Object} email - Email object with subject, body, from fields
 * @param {string} intentId - Intent ID for intent-specific extraction
 * @returns {Object} Extracted entities object
 */
function extractEntities(email, intentId = null) {
  // Build full text from email
  const fullText = `${email.subject || ''} ${email.body || ''}`;

  // Use main extraction function
  return extractAllEntities(email, fullText, intentId);
}

module.exports = {
  extractEntities,
  extractAllEntities,
  extractBasicEntities,
  extractOrderEntities,
  extractTrackingEntities,
  extractPaymentEntities,
  extractMeetingEntities,
  extractAccountEntities,
  extractTravelEntities,
  extractProductImage,
  extractIntentSpecificEntities
};


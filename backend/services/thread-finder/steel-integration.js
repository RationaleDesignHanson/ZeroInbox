/**
 * Thread Finder - Steel API Integration for Email Link Data Extraction
 * Handles automatic crawling and data extraction from link-heavy emails
 *
 * Architecture:
 * 1. Link Classification (Canvas, School Portals, SportsEngine)
 * 2. API-First Approach (Canvas API, Google Classroom API)
 * 3. Steel Browser Automation Fallback
 * 4. Priority Calculation (Q1-Q4 Eisenhower Matrix)
 * 5. High-Priority Action Generation
 */

require('dotenv').config();
const axios = require('axios');
const logger = require('../classifier/shared/config/logger');

// ============================================================================
// CONFIGURATION
// ============================================================================

const STEEL_API_KEY = process.env.STEEL_API_KEY || '';
const STEEL_API_URL = 'https://api.steel.dev/v1';
const CANVAS_API_TOKEN = process.env.CANVAS_API_TOKEN || '';
const CANVAS_INSTANCE_URL = process.env.CANVAS_INSTANCE_URL || 'https://canvas.instructure.com';

// Link classification patterns
const LINK_PATTERNS = {
  learningPlatforms: [
    { pattern: /canvas\.instructure\.com/i, name: 'Canvas LMS', hasAPI: true, apiKey: 'canvas' },
    { pattern: /classroom\.google\.com/i, name: 'Google Classroom', hasAPI: true, apiKey: 'googleClassroom' },
    { pattern: /\.schoology\.com/i, name: 'Schoology', hasAPI: true, apiKey: 'schoology' },
  ],
  schoolPortals: [
    { pattern: /pascackvalley\.org/i, name: 'Pascack Valley', hasAPI: false },
    { pattern: /\.blackboard\.com/i, name: 'Blackboard', hasAPI: false },
    { pattern: /\.myschoolapp\.com/i, name: 'Blackbaud', hasAPI: false },
  ],
  sportsPlatforms: [
    { pattern: /sportsengine\.com/i, name: 'SportsEngine', hasAPI: false },
    { pattern: /teamsnap\.com/i, name: 'TeamSnap', hasAPI: true, apiKey: 'teamsnap' },
  ],
};

// API configurations
const API_CONFIGS = {
  canvas: {
    name: 'Canvas LMS API',
    endpoint: `${CANVAS_INSTANCE_URL}/api/v1`,
    authHeader: `Bearer ${CANVAS_API_TOKEN}`,
  },
  googleClassroom: {
    name: 'Google Classroom API',
    endpoint: 'https://classroom.googleapis.com/v1',
    authHeader: `Bearer ${process.env.GOOGLE_CLASSROOM_TOKEN || ''}`,
  },
};

// Steel session configurations
const STEEL_SESSIONS = {
  pascackValley: {
    id: 'pascack-valley-portal',
    baseUrl: 'https://pascackvalley.org',
    authRequired: true,
    credentials: {
      username: process.env.PASCACK_USERNAME || '',
      password: process.env.PASCACK_PASSWORD || '',
    },
    selectors: {
      login: {
        username: '#username',
        password: '#password',
        submit: 'button[type="submit"]',
      },
      data: {
        title: 'h1, .announcement-title, .page-title',
        date: '.date, .post-date, .announcement-date',
        content: '.content, .announcement-body, .description, main',
        attachments: 'a[href*="attachment"], a[href*="download"]',
      },
    },
  },
  sportsEngine: {
    id: 'sportsengine-family',
    baseUrl: 'https://www.sportsengine.com',
    authRequired: true,
    credentials: {
      username: process.env.SPORTSENGINE_USERNAME || '',
      password: process.env.SPORTSENGINE_PASSWORD || '',
    },
    selectors: {
      login: {
        username: '#email',
        password: '#password',
        submit: 'button[type="submit"]',
      },
      data: {
        title: 'h1, .event-title, .game-title',
        date: '.event-date, .game-date, time',
        content: '.event-details, .game-details, .description',
        attachments: 'a[href*="attachment"]',
      },
    },
  },
};

// ============================================================================
// LINK CLASSIFICATION
// ============================================================================

/**
 * Classify a link by platform type
 * @param {string} link - The URL to classify
 * @returns {Object} Classification result with category, platform, and capabilities
 */
function classifyLink(link) {
  if (!link || typeof link !== 'string') {
    return {
      category: 'UNKNOWN',
      platform: 'Unknown',
      requiresCrawl: false,
      hasAPI: false,
    };
  }

  // Check learning platforms (Canvas, Google Classroom)
  for (const platform of LINK_PATTERNS.learningPlatforms) {
    if (platform.pattern.test(link)) {
      return {
        category: 'LEARNING_PLATFORM',
        platform: platform.name,
        requiresCrawl: !platform.hasAPI,
        hasAPI: platform.hasAPI,
        apiConfig: platform.hasAPI ? API_CONFIGS[platform.apiKey] : null,
      };
    }
  }

  // Check school portals
  for (const platform of LINK_PATTERNS.schoolPortals) {
    if (platform.pattern.test(link)) {
      return {
        category: 'SCHOOL_PORTAL',
        platform: platform.name,
        requiresCrawl: true,
        hasAPI: false,
      };
    }
  }

  // Check sports platforms
  for (const platform of LINK_PATTERNS.sportsPlatforms) {
    if (platform.pattern.test(link)) {
      return {
        category: 'SPORTS_PLATFORM',
        platform: platform.name,
        requiresCrawl: !platform.hasAPI,
        hasAPI: platform.hasAPI,
        apiConfig: platform.hasAPI ? API_CONFIGS[platform.apiKey] : null,
      };
    }
  }

  return {
    category: 'UNKNOWN',
    platform: 'Unknown',
    requiresCrawl: false,
    hasAPI: false,
  };
}

// ============================================================================
// CANVAS API INTEGRATION
// ============================================================================

/**
 * Extract data from Canvas link using Canvas API
 * @param {string} link - Canvas assignment/announcement URL
 * @returns {Promise<Object>} Extracted content
 */
async function extractFromCanvasAPI(link) {
  try {
    // Parse Canvas link to extract course_id and assignment_id
    // Example: https://canvas.instructure.com/courses/12345/assignments/67890
    const courseMatch = link.match(/\/courses\/(\d+)/);
    const assignmentMatch = link.match(/\/assignments\/(\d+)/);
    const announcementMatch = link.match(/\/announcements\/(\d+)/);

    if (!courseMatch) {
      throw new Error('Could not parse course ID from Canvas link');
    }

    const courseId = courseMatch[1];

    // Try assignment first
    if (assignmentMatch) {
      const assignmentId = assignmentMatch[1];
      const response = await axios.get(
        `${API_CONFIGS.canvas.endpoint}/courses/${courseId}/assignments/${assignmentId}`,
        {
          headers: {
            Authorization: API_CONFIGS.canvas.authHeader,
          },
        }
      );

      const assignment = response.data;
      return {
        title: assignment.name || 'Canvas Assignment',
        content: assignment.description || '',
        dueDate: assignment.due_at || null,
        points: assignment.points_possible || null,
        attachments: (assignment.attachments || []).map(att => att.url),
        actionRequired: true,
        metadata: {
          courseId,
          assignmentId,
          submissionTypes: assignment.submission_types || [],
          gradingType: assignment.grading_type || '',
        },
      };
    }

    // Try announcement
    if (announcementMatch) {
      const announcementId = announcementMatch[1];
      const response = await axios.get(
        `${API_CONFIGS.canvas.endpoint}/courses/${courseId}/discussion_topics/${announcementId}`,
        {
          headers: {
            Authorization: API_CONFIGS.canvas.authHeader,
          },
        }
      );

      const announcement = response.data;
      return {
        title: announcement.title || 'Canvas Announcement',
        content: announcement.message || '',
        date: announcement.posted_at || null,
        attachments: (announcement.attachments || []).map(att => att.url),
        actionRequired: false,
        metadata: {
          courseId,
          announcementId,
        },
      };
    }

    throw new Error('Could not parse Canvas link type');
  } catch (error) {
    logger.error('Canvas API extraction failed', {
      error: error.message,
      link,
    });
    throw error;
  }
}

// ============================================================================
// STEEL API INTEGRATION
// ============================================================================

/**
 * Extract data from link using Steel browser automation
 * @param {string} link - URL to extract from
 * @param {Object} classification - Link classification result
 * @returns {Promise<Object>} Extracted content
 */
async function extractFromSteel(link, classification) {
  try {
    // Determine which Steel session to use
    let sessionConfig = null;
    if (classification.platform === 'Pascack Valley') {
      sessionConfig = STEEL_SESSIONS.pascackValley;
    } else if (classification.platform === 'SportsEngine') {
      sessionConfig = STEEL_SESSIONS.sportsEngine;
    } else {
      throw new Error(`No Steel session configured for ${classification.platform}`);
    }

    logger.info('Initiating Steel extraction', {
      platform: classification.platform,
      sessionId: sessionConfig.id,
    });

    // Create or reuse Steel session
    const sessionId = sessionConfig.id;

    // Navigate to link
    await axios.post(
      `${STEEL_API_URL}/sessions/${sessionId}/navigate`,
      { url: link },
      {
        headers: {
          Authorization: `Bearer ${STEEL_API_KEY}`,
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      }
    );

    // Wait for page load
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Extract data using selectors
    const extractResponse = await axios.post(
      `${STEEL_API_URL}/sessions/${sessionId}/extract`,
      { selectors: sessionConfig.selectors.data },
      {
        headers: {
          Authorization: `Bearer ${STEEL_API_KEY}`,
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      }
    );

    const extracted = extractResponse.data;

    logger.info('Steel extraction successful', {
      platform: classification.platform,
      hasTitle: !!extracted.title,
      hasContent: !!extracted.content,
    });

    return {
      title: extracted.title || 'Extracted Content',
      content: extracted.content || '',
      date: extracted.date || null,
      attachments: extracted.attachments || [],
      actionRequired: true,
      metadata: {
        platform: classification.platform,
        extractionMethod: 'steel',
      },
    };
  } catch (error) {
    logger.error('Steel extraction failed', {
      error: error.message,
      platform: classification.platform,
    });
    throw error;
  }
}

// ============================================================================
// PRIORITY CALCULATION
// ============================================================================

/**
 * Calculate priority based on Eisenhower Matrix
 * @param {Object} extractedData - Extracted content with due date
 * @returns {string} Priority level (Q1, Q2, Q3, Q4)
 */
function calculatePriority(extractedData) {
  if (!extractedData.dueDate || !extractedData.actionRequired) {
    return 'Q3'; // Not important (no action required)
  }

  const dueDate = new Date(extractedData.dueDate);
  const now = new Date();
  const daysUntilDue = Math.ceil((dueDate - now) / (1000 * 60 * 60 * 24));

  if (daysUntilDue <= 3) {
    return 'Q1'; // Urgent & Important
  } else if (daysUntilDue <= 7) {
    return 'Q2'; // Important, Not Urgent
  } else {
    return 'Q3'; // Not important
  }
}

/**
 * Generate High-Priority Actions based on extracted content
 * @param {Object} extractedData - Extracted content
 * @param {string} priority - Calculated priority
 * @returns {Array<string>} List of suggested actions
 */
function generateHPAs(extractedData, priority) {
  const hpas = [];

  if (extractedData.dueDate) {
    hpas.push(`Add to calendar: ${extractedData.title}`);
    hpas.push('Set reminder 2 days before due date');
  }

  if (priority === 'Q1') {
    hpas.unshift('⚠️ HIGH PRIORITY - Address immediately');
  }

  if (extractedData.attachments && extractedData.attachments.length > 0) {
    hpas.push(`Download ${extractedData.attachments.length} attachment(s)`);
  }

  return hpas;
}

// ============================================================================
// MAIN PROCESSING FUNCTION
// ============================================================================

/**
 * Process email with link and extract data
 * @param {Object} email - Email object with subject, from, body
 * @param {string} link - Primary link from email
 * @returns {Promise<Object>} Processed result with extracted data, priority, HPAs
 */
async function processEmailWithLink(email, link) {
  const startTime = Date.now();

  try {
    // Step 1: Classify link
    const classification = classifyLink(link);

    logger.info('Link classified', {
      category: classification.category,
      platform: classification.platform,
      hasAPI: classification.hasAPI,
    });

    if (classification.category === 'UNKNOWN') {
      return {
        originalEmail: email,
        extractedContent: null,
        summary: 'Link type not recognized',
        priority: 'Q4',
        requiresManualReview: true,
      };
    }

    // Step 2: Extract data (API first, then Steel fallback)
    let extractedData = null;

    if (classification.hasAPI && classification.platform === 'Canvas LMS') {
      try {
        extractedData = await extractFromCanvasAPI(link);
      } catch (error) {
        logger.warn('Canvas API failed, falling back to Steel', { error: error.message });
        // Could fall back to Steel here if needed
        throw error;
      }
    } else if (classification.requiresCrawl) {
      extractedData = await extractFromSteel(link, classification);
    } else {
      throw new Error(`No extraction method available for ${classification.platform}`);
    }

    // Step 3: Calculate priority
    const priority = calculatePriority(extractedData);

    // Step 4: Generate HPAs
    const hpas = generateHPAs(extractedData, priority);

    // Step 5: Generate summary
    const summary = generateSummary(extractedData, classification);

    const processingTime = Date.now() - startTime;

    logger.info('Thread Finder processing complete', {
      platform: classification.platform,
      priority,
      hpaCount: hpas.length,
      processingTimeMs: processingTime,
    });

    return {
      originalEmail: email,
      extractedContent: extractedData,
      summary,
      priority,
      hpa: hpas,
      requiresManualReview: false,
    };
  } catch (error) {
    const processingTime = Date.now() - startTime;

    logger.error('Thread Finder processing failed', {
      error: error.message,
      processingTimeMs: processingTime,
    });

    return {
      originalEmail: email,
      extractedContent: null,
      summary: `Could not automatically extract data from ${link}. Manual review required.`,
      priority: 'Q4',
      requiresManualReview: true,
    };
  }
}

/**
 * Generate formatted summary for user display
 * @param {Object} extractedData - Extracted content
 * @param {Object} classification - Link classification
 * @returns {string} Formatted summary
 */
function generateSummary(extractedData, classification) {
  const lines = [];

  lines.push(`📧 Extracted from ${classification.platform}`);
  lines.push('');
  lines.push(`**${extractedData.title}**`);

  if (extractedData.dueDate) {
    const dueDate = new Date(extractedData.dueDate);
    lines.push(`**Due Date:** ${dueDate.toLocaleDateString()}`);
  }

  if (extractedData.points) {
    lines.push(`**Points:** ${extractedData.points}`);
  }

  if (extractedData.content) {
    const preview = extractedData.content.substring(0, 200);
    lines.push('');
    lines.push(`**Description:** ${preview}${extractedData.content.length > 200 ? '...' : ''}`);
  }

  if (extractedData.attachments && extractedData.attachments.length > 0) {
    lines.push('');
    lines.push('**Attachments:**');
    extractedData.attachments.forEach(att => {
      lines.push(`- ${att}`);
    });
  }

  return lines.join('\n');
}

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
  classifyLink,
  processEmailWithLink,
  extractFromCanvasAPI,
  extractFromSteel,
  calculatePriority,
  generateHPAs,
};

/**
 * School Platform Detector
 *
 * Detects K-12 school-related platforms from email metadata
 * Uses comprehensive database of 30+ school communication platforms
 */

const schoolPlatformsDB = require('../data/school-platforms-database.json');

/**
 * Detect school platform from email
 * @param {Object} email - Email object with from, subject, body
 * @returns {Object} Detection result
 */
function detectSchoolPlatform(email) {
  const from = (email.from || '').toLowerCase();
  const subject = (email.subject || '').toLowerCase();
  const body = (email.body || '').toLowerCase();

  const results = {
    detected: false,
    platform: null,
    category: null,
    confidence: 0,
    matches: []
  };

  // Check all platform categories
  const categories = ['lms', 'communication', 'studentInfo', 'lunch', 'sports', 'earlyChildhood', 'other'];

  for (const category of categories) {
    const platforms = schoolPlatformsDB[category];

    for (const [platformKey, platformData] of Object.entries(platforms)) {
      let score = 0;
      const matchDetails = [];

      // Check email domains (highest weight)
      for (const domain of platformData.emailDomains) {
        if (from.includes(domain.toLowerCase())) {
          score += 50;
          matchDetails.push({ type: 'emailDomain', value: domain, weight: 50 });
          break;
        }
      }

      // Check subject patterns (medium weight)
      for (const pattern of platformData.subjectPatterns) {
        if (subject.includes(pattern.toLowerCase())) {
          score += 30;
          matchDetails.push({ type: 'subjectPattern', value: pattern, weight: 30 });
        }
      }

      // Check URL patterns in body (low weight)
      for (const urlPattern of platformData.urlPatterns) {
        if (body.includes(urlPattern.toLowerCase())) {
          score += 10;
          matchDetails.push({ type: 'urlPattern', value: urlPattern, weight: 10 });
          break;
        }
      }

      // If we have matches, add to results
      if (score > 0) {
        results.matches.push({
          platform: platformKey,
          platformName: platformData.name,
          vendor: platformData.vendor,
          category,
          score,
          matchDetails
        });
      }
    }
  }

  // Sort by score and pick best match
  if (results.matches.length > 0) {
    results.matches.sort((a, b) => b.score - a.score);
    const best = results.matches[0];

    results.detected = true;
    results.platform = best.platform;
    results.platformName = best.platformName;
    results.vendor = best.vendor;
    results.category = best.category;
    results.confidence = Math.min(best.score / 100, 1.0); // Normalize to 0-1
  }

  return results;
}

/**
 * Check if email is from a school domain
 * @param {string} from - Email from field
 * @returns {boolean}
 */
function isSchoolDomain(from) {
  const fromLower = from.toLowerCase();
  const patterns = schoolPlatformsDB.detection.schoolDomainPatterns;

  return patterns.some(pattern => fromLower.includes(pattern));
}

/**
 * Check if email is from a teacher
 * @param {string} from - Email from field
 * @returns {boolean}
 */
function isTeacherEmail(from) {
  const fromLower = from.toLowerCase();
  const patterns = schoolPlatformsDB.detection.teacherEmailPatterns;

  return patterns.some(pattern => fromLower.includes(pattern)) || isSchoolDomain(from);
}

/**
 * Get all platforms by category
 * @param {string} category - Category name (lms, communication, etc.)
 * @returns {Array} Array of platform objects
 */
function getPlatformsByCategory(category) {
  if (!schoolPlatformsDB[category]) {
    return [];
  }

  return Object.entries(schoolPlatformsDB[category]).map(([key, data]) => ({
    key,
    ...data
  }));
}

/**
 * Get all email domains for a category
 * @param {string} category - Category name
 * @returns {Array} Array of email domains
 */
function getEmailDomainsForCategory(category) {
  const platforms = schoolPlatformsDB[category];
  if (!platforms) return [];

  const domains = [];
  for (const platform of Object.values(platforms)) {
    domains.push(...platform.emailDomains);
  }

  return [...new Set(domains)]; // Remove duplicates
}

/**
 * Get platform statistics
 * @returns {Object} Statistics about the database
 */
function getStats() {
  const stats = {
    totalPlatforms: 0,
    byCategory: {},
    totalDomains: 0,
    totalSubjectPatterns: 0
  };

  const categories = ['lms', 'communication', 'studentInfo', 'lunch', 'sports', 'earlyChildhood', 'other'];

  for (const category of categories) {
    const platforms = schoolPlatformsDB[category];
    const count = Object.keys(platforms).length;

    stats.totalPlatforms += count;
    stats.byCategory[category] = count;

    for (const platform of Object.values(platforms)) {
      stats.totalDomains += platform.emailDomains.length;
      stats.totalSubjectPatterns += platform.subjectPatterns.length;
    }
  }

  return stats;
}

module.exports = {
  detectSchoolPlatform,
  isSchoolDomain,
  isTeacherEmail,
  getPlatformsByCategory,
  getEmailDomainsForCategory,
  getStats
};

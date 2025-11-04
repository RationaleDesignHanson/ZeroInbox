/**
 * Classification Score Weights Configuration
 * Centralized scoring weights for intent classification
 * Adjust these values to tune classification accuracy
 */

module.exports = {
  // Pattern matching weights
  PATTERN_WEIGHTS: {
    SUBJECT_MATCH: 40,      // Subject line is most reliable signal
    SNIPPET_MATCH: 25,      // Email snippet/preview has good context
    BODY_MATCH: 10,         // Full body less reliable (contains noise)
    FROM_DOMAIN: 30,        // Sender domain highly reliable
    ENTITY_BOOST: 15        // Found expected entities for this intent
  },

  // Category-specific boosts
  CATEGORY_BOOSTS: {
    E_COMMERCE: {
      DOMAIN_MATCH: 20,     // E-commerce domain detected
      ORDER_KEYWORD: 15,    // Order-related keywords
      TRACKING_NUMBER: 25   // Tracking number pattern found
    },
    BILLING: {
      DOMAIN_MATCH: 25,     // Billing/payment domain
      PAYMENT_PLATFORM: 30, // Stripe, PayPal, Square detected
      MONEY_AMOUNT: 15      // Currency amount found
    },
    EVENT: {
      CALENDAR_PLATFORM: 30, // Zoom, Meet, Teams detected
      MEETING_URL: 35,       // Meeting URL found
      DATETIME_PATTERN: 15   // Date/time pattern detected
    },
    ACCOUNT: {
      SECURITY_DOMAIN: 20,  // Security/noreply domain
      TRUSTED_SENDER: 15    // Google, Microsoft, GitHub
    },
    EDUCATION: {
      EDU_DOMAIN: 35,       // .edu domain
      TEACHER_PATTERN: 25,  // Teacher-related sender
      SCHOOL_PLATFORM: 40   // Canvas, Schoology detected
    },
    TRAVEL: {
      AIRLINE_DOMAIN: 30,   // Airline or hotel domain
      CONFIRMATION_CODE: 15 // Confirmation code pattern
    },
    FEEDBACK: {
      REVIEW_KEYWORD: 20    // Review, feedback, rating keywords
    },
    MARKETING: {
      DISCOUNT_SYMBOL: 15,  // Percentage or "off" found
      URGENCY_KEYWORD: 20   // Today, limited, expires found
    },
    SHOPPING: {
      FUTURE_DATE: 30,      // Future date detected (e.g., "launching Oct 31")
      TIME_SPEC: 20,        // Time specification (e.g., "5pm UK time")
      LIMITED_EDITION: 15,  // Limited availability keywords
      PRODUCT_URL: 20,      // Product page URL found
      COUNTDOWN: 25         // Countdown or pre-sale language
    },
    SUPPORT: {
      SUPPORT_DOMAIN: 25,   // Support, help, service domain
      TICKET_NUMBER: 20     // Ticket/case number pattern
    },
    PROJECT: {
      PM_PLATFORM: 30,      // Jira, Asana, GitHub
      FANTASY_SPORTS: 30    // Fantasy, ESPN (project coordinator)
    },
    HEALTHCARE: {
      HEALTHCARE_DOMAIN: 35,  // Health system, hospital, clinic domains
      DOCTOR_PATTERN: 30,     // Dr., Doctor, Physician
      PHARMACY_DOMAIN: 30     // CVS, Walgreens, pharmacy
    },
    DINING: {
      RESTAURANT_PLATFORM: 40, // OpenTable, Resy
      PARTY_SIZE: 20,          // "party of X"
      TABLE_KEYWORD: 25        // "your table", "reservation"
    },
    DELIVERY: {
      DELIVERY_PLATFORM: 45,  // DoorDash, Uber Eats, Instacart (increased from 35)
      DRIVER_KEYWORD: 35,     // dasher, courier, driver (increased from 30)
      ETA_PATTERN: 30,        // minutes away, arriving soon (increased from 25)
      ORDER_NUMBER: 20        // Order number pattern for delivery
    },
    CIVIC: {
      GOVERNMENT_DOMAIN: 40,  // .gov domain
      CIVIC_KEYWORD: 30       // jury, dmv, voter, summons
    }
  },

  // Confidence thresholds
  CONFIDENCE: {
    MIN_THRESHOLD: 0.3,     // Below this, use generic intent
    HIGH_CONFIDENCE: 0.85,  // High confidence threshold
    MAX_SCORE: 100          // Normalization factor
  }
};


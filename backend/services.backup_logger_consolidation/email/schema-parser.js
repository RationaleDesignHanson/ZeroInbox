/**
 * Schema.org Parser
 * Extracts structured data from emails with schema.org markup
 * Provides "fast lane" for structured emails to bypass NLP pipeline
 */

const logger = require('./logger');

/**
 * Parse email HTML for schema.org JSON-LD markup
 * Returns structured data if found, null otherwise
 * @param {string} htmlBody - HTML content of email
 * @returns {Object|Array|null} Parsed schema.org data or null if none found
 */
function parseSchemaOrg(htmlBody) {
  // Validate input
  if (!htmlBody || typeof htmlBody !== 'string') {
    logger.debug('No HTML body provided for schema.org parsing');
    return null;
  }

  try {
    // Look for JSON-LD script tags
    const scriptMatches = htmlBody.match(/<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi);
    
    if (!scriptMatches || scriptMatches.length === 0) {
      return null;
    }

    const schemas = [];

    for (const scriptTag of scriptMatches) {
      // Extract JSON content
      const jsonMatch = scriptTag.match(/<script[^>]*>([\s\S]*?)<\/script>/i);
      if (!jsonMatch || !jsonMatch[1]) {
        continue;
      }

      try {
        const jsonContent = jsonMatch[1].trim();
        const schemaData = JSON.parse(jsonContent);
        schemas.push(schemaData);
      } catch (parseError) {
        logger.warn('Failed to parse schema.org JSON block', { 
          error: parseError.message,
          jsonPreview: jsonMatch[1].substring(0, 100)
        });
        continue;
      }
    }

    if (schemas.length === 0) {
      logger.debug('No valid schema.org data found');
      return null;
    }

    logger.info('Schema.org data successfully parsed', {
      schemaCount: schemas.length,
      types: schemas.map(s => s['@type']).filter(Boolean)
    });

    // Return first schema with action or all schemas
    return schemas.length === 1 ? schemas[0] : schemas;
  } catch (error) {
    logger.error('Error parsing schema.org markup', { 
      error: error.message,
      stack: error.stack
    });
    return null;
  }
}

/**
 * Extract actions from schema.org data
 */
function extractActions(schemaData) {
  if (!schemaData) {
    return [];
  }

  const actions = [];

  // Handle array of schemas
  const schemas = Array.isArray(schemaData) ? schemaData : [schemaData];

  for (const schema of schemas) {
    // Look for potentialAction or action properties
    const schemaActions = schema.potentialAction || schema.action;
    
    if (schemaActions) {
      const actionArray = Array.isArray(schemaActions) ? schemaActions : [schemaActions];
      actions.push(...actionArray);
    }

    // Some schemas have nested actions
    if (schema['@type'] && isActionType(schema['@type'])) {
      actions.push(schema);
    }
  }

  return actions;
}

/**
 * Check if type is an action type
 */
function isActionType(type) {
  const actionTypes = [
    'ViewAction', 'TrackAction', 'ConfirmAction', 'SaveAction',
    'RsvpAction', 'ReviewAction', 'CheckInAction', 'PayAction',
    'OrderAction', 'ReserveAction', 'ScheduleAction'
  ];
  return actionTypes.includes(type);
}

/**
 * Extract entities from schema.org data
 */
function extractEntities(schemaData) {
  if (!schemaData) {
    return {};
  }

  const entities = {};
  const schemas = Array.isArray(schemaData) ? schemaData : [schemaData];

  for (const schema of schemas) {
    // Extract based on @type
    switch (schema['@type']) {
      case 'ParcelDelivery':
        extractParcelDeliveryEntities(schema, entities);
        break;
      case 'Order':
      case 'OrderConfirmation':
        extractOrderEntities(schema, entities);
        break;
      case 'Invoice':
        extractInvoiceEntities(schema, entities);
        break;
      case 'FlightReservation':
      case 'Flight':
        extractFlightEntities(schema, entities);
        break;
      case 'LodgingReservation':
      case 'Hotel':
        extractHotelEntities(schema, entities);
        break;
      case 'Event':
      case 'EventReservation':
        extractEventEntities(schema, entities);
        break;
      default:
        // Generic extraction
        extractGenericEntities(schema, entities);
    }
  }

  return entities;
}

/**
 * Extract entities from ParcelDelivery schema
 */
function extractParcelDeliveryEntities(schema, entities) {
  if (schema.trackingNumber) {
    entities.trackingNumber = schema.trackingNumber;
  }
  if (schema.carrier) {
    entities.carrier = schema.carrier.name || schema.carrier;
  }
  if (schema.partOfOrder && schema.partOfOrder.orderNumber) {
    entities.orderNumber = schema.partOfOrder.orderNumber;
  }
  if (schema.expectedArrivalUntil) {
    entities.estimatedDelivery = schema.expectedArrivalUntil;
  }
  if (schema.trackingUrl) {
    entities.trackingUrl = schema.trackingUrl;
  }
}

/**
 * Extract entities from Order schema
 */
function extractOrderEntities(schema, entities) {
  if (schema.orderNumber) {
    entities.orderNumber = schema.orderNumber;
  }
  if (schema.confirmationNumber) {
    entities.confirmationCode = schema.confirmationNumber;
  }
  if (schema.price || schema.totalPrice) {
    entities.totalAmount = parseFloat(schema.price || schema.totalPrice);
  }
  if (schema.url) {
    entities.orderUrl = schema.url;
  }
  if (schema.orderedItem) {
    const items = Array.isArray(schema.orderedItem) ? schema.orderedItem : [schema.orderedItem];
    entities.items = items.map(item => item.name || item).filter(Boolean);
  }
}

/**
 * Extract entities from Invoice schema
 */
function extractInvoiceEntities(schema, entities) {
  if (schema.confirmationNumber) {
    entities.invoiceId = schema.confirmationNumber;
  }
  if (schema.totalPaymentDue) {
    const amount = schema.totalPaymentDue.price || schema.totalPaymentDue;
    entities.amountDue = parseFloat(amount);
  }
  if (schema.paymentDueDate) {
    entities.dueDate = schema.paymentDueDate;
  }
  if (schema.url) {
    entities.invoiceUrl = schema.url;
  }
}

/**
 * Extract entities from Flight schema
 */
function extractFlightEntities(schema, entities) {
  // Handle FlightReservation or Flight
  const flight = schema.reservationFor || schema;
  
  if (flight.flightNumber) {
    entities.flightNumber = flight.flightNumber;
  }
  if (flight.airline) {
    entities.carrier = flight.airline.name || flight.airline;
  }
  if (schema.reservationNumber) {
    entities.confirmationCode = schema.reservationNumber;
  }
  if (flight.departureTime) {
    entities.departureDate = flight.departureTime;
  }
  if (schema.url || flight.url) {
    entities.checkInUrl = schema.url || flight.url;
  }
}

/**
 * Extract entities from Hotel schema
 */
function extractHotelEntities(schema, entities) {
  if (schema.reservationNumber) {
    entities.confirmationCode = schema.reservationNumber;
  }
  if (schema.checkinTime || schema.checkinDate) {
    entities.checkInDate = schema.checkinTime || schema.checkinDate;
  }
  if (schema.reservationFor && schema.reservationFor.name) {
    entities.hotelName = schema.reservationFor.name;
  }
  if (schema.url) {
    entities.bookingUrl = schema.url;
  }
}

/**
 * Extract entities from Event schema
 */
function extractEventEntities(schema, entities) {
  const event = schema.reservationFor || schema;
  
  if (event.name) {
    entities.eventTitle = event.name;
  }
  if (event.startDate) {
    entities.eventDate = event.startDate;
  }
  if (event.location) {
    entities.location = event.location.name || event.location;
  }
  if (event.url || schema.url) {
    entities.registrationLink = event.url || schema.url;
  }
}

/**
 * Extract generic entities from any schema
 */
function extractGenericEntities(schema, entities) {
  // Common properties
  if (schema.url && !entities.url) {
    entities.url = schema.url;
  }
  if (schema.name && !entities.name) {
    entities.name = schema.name;
  }
  if (schema.description && !entities.description) {
    entities.description = schema.description;
  }
}

/**
 * Map schema.org action to our action ID
 */
function mapSchemaAction(schemaAction) {
  const actionTypeMap = {
    'TrackAction': 'track_package',
    'ViewAction': 'view_details',
    'ConfirmAction': 'verify_account',
    'RsvpAction': 'rsvp_yes',
    'ReviewAction': 'write_review',
    'CheckInAction': 'check_in_flight',
    'PayAction': 'pay_invoice'
  };

  const actionType = schemaAction['@type'];
  return actionTypeMap[actionType] || null;
}

/**
 * Main parsing function - returns structured data if found
 */
function parseEmailSchema(htmlBody) {
  const schemaData = parseSchemaOrg(htmlBody);
  
  if (!schemaData) {
    return null;
  }

  const actions = extractActions(schemaData);
  const entities = extractEntities(schemaData);

  return {
    hasSchema: true,
    schemaData,
    actions,
    entities,
    mappedActions: actions.map(mapSchemaAction).filter(Boolean)
  };
}

module.exports = {
  parseSchemaOrg,
  extractActions,
  extractEntities,
  mapSchemaAction,
  parseEmailSchema,
  isActionType
};


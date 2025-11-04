/**
 * Phase 1 Task 1.3: Entity Extraction Validation Test Suite
 * Tests entity extraction accuracy across all major entity types
 */

const {
  extractAllEntities,
  extractOrderEntities,
  extractTrackingEntities,
  extractPaymentEntities,
  extractMeetingEntities,
  extractAccountEntities,
  extractTravelEntities,
  extractIntentSpecificEntities
} = require('../entity-extractor');
const fs = require('fs');
const path = require('path');

describe('Phase 1: Entity Extraction Validation', () => {
  const results = {
    total: 0,
    passed: 0,
    failed: 0,
    byCategory: {},
    failedExtractions: []
  };

  describe('Order Entities', () => {
    const testCases = [
      {
        name: 'orderNumber',
        text: 'Order #ABC123456789',
        expected: { orderNumber: 'ABC123456789' }
      },
      {
        name: 'orderNumber (format 2)',
        text: 'Order number: XYZ-9876543',
        expected: { orderNumber: 'XYZ-9876543' }
      },
      {
        name: 'orderUrl',
        text: 'View your order: https://amazon.com/order/123',
        expected: { orderUrl: 'https://amazon.com/order/123' }
      }
    ];

    testCases.forEach(({ name, text, expected }) => {
      test(name, () => {
        results.total++;
        try {
          const entities = extractOrderEntities(text);
          Object.keys(expected).forEach(key => {
            expect(entities[key]).toBe(expected[key]);
          });
          results.passed++;
        } catch (error) {
          results.failed++;
          results.failedExtractions.push({ category: 'order', name, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Tracking Entities', () => {
    const testCases = [
      {
        name: 'trackingNumber (UPS)',
        text: 'Tracking: 1Z999AA10123456784',
        expected: { trackingNumber: '1Z999AA10123456784', carrier: 'UPS' }
      },
      {
        name: 'carrier detection',
        text: 'Your UPS package is arriving soon',
        expected: { carrier: 'UPS' }
      },
      {
        name: 'trackingUrl',
        text: 'Track here: https://www.ups.com/track?tracknum=123',
        expected: { trackingUrl: 'https://www.ups.com/track?tracknum=123' }
      }
    ];

    testCases.forEach(({ name, text, expected }) => {
      test(name, () => {
        results.total++;
        try {
          const entities = extractTrackingEntities(text);
          Object.keys(expected).forEach(key => {
            expect(entities[key]).toBe(expected[key]);
          });
          results.passed++;
        } catch (error) {
          results.failed++;
          results.failedExtractions.push({ category: 'tracking', name, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Payment Entities', () => {
    const testCases = [
      {
        name: 'invoiceId',
        text: 'Invoice #INV-123456',
        expected: { invoiceId: 'INV-123456' }
      },
      {
        name: 'amount',
        text: 'Amount due: $125.50',
        expected: { amount: '125.50', amountDue: '125.50', paymentAmount: '125.50' }
      },
      {
        name: 'dueDate',
        text: 'Payment due: November 15',
        expected: { dueDate: 'November 15' }
      },
      {
        name: 'paymentLink',
        text: 'Pay: https://stripe.com/pay/inv_123',
        expected: { paymentLink: 'https://stripe.com/pay/inv_123' }
      },
      {
        name: 'deliveryDate',
        text: 'Arriving November 15',
        expected: { deliveryDate: 'November 15' }
      }
    ];

    testCases.forEach(({ name, text, expected }) => {
      test(name, () => {
        results.total++;
        try {
          const entities = extractPaymentEntities(text);
          Object.keys(expected).forEach(key => {
            expect(entities[key]).toBe(expected[key]);
          });
          results.passed++;
        } catch (error) {
          results.failed++;
          results.failedExtractions.push({ category: 'payment', name, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Meeting Entities', () => {
    const testCases = [
      {
        name: 'meetingUrl (Zoom)',
        email: { subject: 'Meeting Invite', from: 'john@company.com' },
        text: 'Join: https://zoom.us/j/123456789',
        expected: { meetingUrl: 'https://zoom.us/j/123456789' }
      },
      {
        name: 'meetingUrl (Google Meet)',
        email: { subject: 'Team Standup', from: 'sarah@company.com' },
        text: 'Join here: https://meet.google.com/abc-defg-hij',
        expected: { meetingUrl: 'https://meet.google.com/abc-defg-hij' }
      },
      {
        name: 'eventDate and eventTime',
        email: { subject: 'Q1 Planning', from: 'manager@company.com' },
        text: 'Scheduled for Monday, January 15, 2025 at 2:00 pm',
        expected: { eventDate: 'Monday, January 15, 2025', eventTime: '2:00 pm' }
      }
    ];

    testCases.forEach(({ name, email, text, expected }) => {
      test(name, () => {
        results.total++;
        try {
          const entities = extractMeetingEntities(email, text);
          Object.keys(expected).forEach(key => {
            expect(entities[key]).toBe(expected[key]);
          });
          results.passed++;
        } catch (error) {
          results.failed++;
          results.failedExtractions.push({ category: 'meeting', name, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Account Entities', () => {
    const testCases = [
      {
        name: 'unsubscribeUrl',
        text: 'Unsubscribe: https://company.com/unsubscribe?id=123',
        expected: { unsubscribeUrl: 'https://company.com/unsubscribe?id=123' }
      },
      {
        name: 'resetLink',
        text: 'Reset your password: https://app.com/reset?token=abc',
        expected: { resetLink: 'https://app.com/reset?token=abc' }
      },
      {
        name: 'username',
        text: 'Username: john_doe123',
        expected: { username: 'john_doe123' }
      },
      {
        name: 'device',
        text: 'New login from iPhone',
        expected: { device: 'iPhone' }
      },
      {
        name: 'ipAddress',
        text: 'IP Address: 192.168.1.1',
        expected: { ipAddress: '192.168.1.1' }
      }
    ];

    testCases.forEach(({ name, text, expected }) => {
      test(name, () => {
        results.total++;
        try {
          const entities = extractAccountEntities(text);
          Object.keys(expected).forEach(key => {
            expect(entities[key]).toBe(expected[key]);
          });
          results.passed++;
        } catch (error) {
          results.failed++;
          results.failedExtractions.push({ category: 'account', name, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Travel Entities', () => {
    const testCases = [
      {
        name: 'flightNumber',
        text: 'Flight UA 123',
        expected: { flightNumber: 'UA 123' }
      },
      {
        name: 'confirmationCode',
        text: 'Confirmation code: ABC123',
        expected: { confirmationCode: 'ABC123' }
      },
      {
        name: 'checkInUrl',
        text: 'Check in: https://united.com/checkin?conf=ABC123',
        expected: { checkInUrl: 'https://united.com/checkin?conf=ABC123' }
      },
      {
        name: 'departureDate',
        text: 'Departure: January 20, 2025',
        expected: { departureDate: 'January 20, 2025' }
      }
    ];

    testCases.forEach(({ name, text, expected }) => {
      test(name, () => {
        results.total++;
        try {
          const entities = extractTravelEntities(text);
          Object.keys(expected).forEach(key => {
            expect(entities[key]).toBe(expected[key]);
          });
          results.passed++;
        } catch (error) {
          results.failed++;
          results.failedExtractions.push({ category: 'travel', name, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Healthcare Intent-Specific Entities', () => {
    const testCases = [
      {
        name: 'provider',
        intentId: 'healthcare.appointment.reminder',
        text: 'Appointment with Dr. Smith',
        expected: { provider: 'Dr. Smith' }
      },
      {
        name: 'dateTime',
        intentId: 'healthcare.appointment.reminder',
        text: 'Scheduled for January 15, 2025 at 2:00 PM',
        expected: { dateTime: 'January 15, 2025 at 2:00 PM' }
      },
      {
        name: 'schedulingUrl',
        intentId: 'healthcare.appointment.booking_request',
        text: 'Schedule online: https://health.com/schedule',
        expected: { schedulingUrl: 'https://health.com/schedule' }
      },
      {
        name: 'medication',
        intentId: 'healthcare.prescription.ready',
        text: 'Prescription for Amoxicillin',
        expected: { medication: 'Amoxicillin' }
      }
    ];

    testCases.forEach(({ name, intentId, text, expected }) => {
      test(name, () => {
        results.total++;
        try {
          const entities = extractIntentSpecificEntities(text, intentId);
          Object.keys(expected).forEach(key => {
            expect(entities[key]).toBe(expected[key]);
          });
          results.passed++;
        } catch (error) {
          results.failed++;
          results.failedExtractions.push({ category: 'healthcare', name, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Education Intent-Specific Entities', () => {
    const testCases = [
      {
        name: 'assignmentName',
        intentId: 'education.assignment.due',
        text: 'Assignment: Math Homework Chapter 5',
        expected: { assignmentName: 'Math Homework Chapter 5' }
      },
      {
        name: 'studentName',
        intentId: 'education.grade.posted',
        text: 'Grade for Emma Johnson',
        expected: { studentName: 'Emma Johnson' }
      },
      {
        name: 'grade',
        intentId: 'education.grade.posted',
        text: 'Grade: 95%',
        expected: { grade: '95%' }
      },
      {
        name: 'formName',
        intentId: 'education.permission.form',
        text: 'Field trip permission form',
        expected: { formName: 'field trip' }
      }
    ];

    testCases.forEach(({ name, intentId, text, expected }) => {
      test(name, () => {
        results.total++;
        try {
          const entities = extractIntentSpecificEntities(text, intentId);
          Object.keys(expected).forEach(key => {
            expect(entities[key]).toBe(expected[key]);
          });
          results.passed++;
        } catch (error) {
          results.failed++;
          results.failedExtractions.push({ category: 'education', name, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Dining Intent-Specific Entities', () => {
    const testCases = [
      {
        name: 'restaurant',
        intentId: 'dining.reservation.confirmation',
        text: 'Reservation at Blue Hill Restaurant',
        expected: { restaurant: 'Blue Hill Restaurant' }
      },
      {
        name: 'partySize',
        intentId: 'dining.reservation.confirmation',
        text: 'Party of 4',
        expected: { partySize: 4 }
      },
      {
        name: 'confirmationCode',
        intentId: 'dining.reservation.confirmation',
        text: 'Confirmation: RES-12345',
        expected: { confirmationCode: 'RES-12345' }
      }
    ];

    testCases.forEach(({ name, intentId, text, expected }) => {
      test(name, () => {
        results.total++;
        try {
          const entities = extractIntentSpecificEntities(text, intentId);
          Object.keys(expected).forEach(key => {
            expect(entities[key]).toBe(expected[key]);
          });
          results.passed++;
        } catch (error) {
          results.failed++;
          results.failedExtractions.push({ category: 'dining', name, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Shopping Intent-Specific Entities', () => {
    const testCases = [
      {
        name: 'saleDate',
        intentId: 'shopping.future_sale',
        text: 'Launching October 31',
        expected: { saleDate: 'October 31' }
      },
      {
        name: 'saleTime',
        intentId: 'shopping.future_sale',
        text: 'Available at 5:00 pm',
        expected: { saleTime: '5:00' }
      },
      {
        name: 'productUrl',
        intentId: 'shopping.future_sale',
        text: 'Shop: https://store.com/product/123',
        expected: { productUrl: 'https://store.com/product/123' }
      }
    ];

    testCases.forEach(({ name, intentId, text, expected }) => {
      test(name, () => {
        results.total++;
        try {
          const entities = extractIntentSpecificEntities(text, intentId);
          Object.keys(expected).forEach(key => {
            expect(entities[key]).toBe(expected[key]);
          });
          results.passed++;
        } catch (error) {
          results.failed++;
          results.failedExtractions.push({ category: 'shopping', name, error: error.message });
          throw error;
        }
      });
    });
  });

  describe('Integration: Full Email Entity Extraction', () => {
    test('E-commerce order email', () => {
      results.total++;
      try {
        const email = {
          subject: 'Your order has shipped',
          body: 'Order #ABC123 has shipped via UPS. Tracking: 1Z999AA. Arriving November 15.',
          from: 'orders@amazon.com'
        };
        const fullText = `${email.subject} ${email.body}`;
        const entities = extractAllEntities(email, fullText, 'e-commerce.shipping.notification');

        expect(entities.orderNumber).toBe('ABC123');
        expect(entities.trackingNumber).toBe('1Z999AA');
        expect(entities.carrier).toBe('UPS');
        expect(entities.deliveryDate).toBe('November 15');

        results.passed++;
      } catch (error) {
        results.failed++;
        results.failedExtractions.push({ category: 'integration', name: 'E-commerce order', error: error.message });
        throw error;
      }
    });

    test('Healthcare appointment email', () => {
      results.total++;
      try {
        const email = {
          subject: 'Appointment Reminder',
          body: 'Appointment with Dr. Smith on January 15, 2025 at 2:00 PM',
          from: 'appointments@hospital.com'
        };
        const fullText = `${email.subject} ${email.body}`;
        const entities = extractAllEntities(email, fullText, 'healthcare.appointment.reminder');

        expect(entities.provider).toBe('Dr. Smith');
        expect(entities.dateTime).toContain('January 15, 2025');

        results.passed++;
      } catch (error) {
        results.failed++;
        results.failedExtractions.push({ category: 'integration', name: 'Healthcare appointment', error: error.message });
        throw error;
      }
    });

    test('Billing invoice email', () => {
      results.total++;
      try {
        const email = {
          subject: 'Invoice Due',
          body: 'Invoice #INV-456 Amount due: $125.50 Payment due: November 20',
          from: 'billing@company.com'
        };
        const fullText = `${email.subject} ${email.body}`;
        const entities = extractAllEntities(email, fullText, 'billing.invoice.due');

        expect(entities.invoiceId).toBe('INV-456');
        expect(entities.amount).toBe('125.50');
        expect(entities.dueDate).toBe('November 20');

        results.passed++;
      } catch (error) {
        results.failed++;
        results.failedExtractions.push({ category: 'integration', name: 'Billing invoice', error: error.message });
        throw error;
      }
    });
  });

  afterAll(() => {
    // Calculate category statistics
    results.failedExtractions.forEach(failure => {
      if (!results.byCategory[failure.category]) {
        results.byCategory[failure.category] = { total: 0, passed: 0, failed: 0 };
      }
    });

    // Generate summary report
    console.log('\n' + '='.repeat(60));
    console.log('PHASE 1 TASK 1.3: ENTITY EXTRACTION RESULTS');
    console.log('='.repeat(60));
    console.log(`Total Entity Tests: ${results.total}`);
    console.log(`Passed: ${results.passed} (${(results.passed/results.total*100).toFixed(1)}%)`);
    console.log(`Failed: ${results.failed} (${(results.failed/results.total*100).toFixed(1)}%)`);

    if (results.failedExtractions.length > 0) {
      console.log('\nFailed Extractions:');
      results.failedExtractions.slice(0, 10).forEach(failure => {
        console.log(`  ${failure.category}.${failure.name}: ${failure.error}`);
      });
    }

    console.log('='.repeat(60) + '\n');

    // Save results to file
    const resultsPath = path.join(__dirname, '../../../test-data/phase1-entity-results.json');
    fs.writeFileSync(resultsPath, JSON.stringify(results, null, 2));
    console.log(`Results saved to: ${resultsPath}\n`);
  });
});

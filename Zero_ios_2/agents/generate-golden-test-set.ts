#!/usr/bin/env ts-node
/**
 * Golden Test Set Generator
 *
 * Generates 200+ synthetic email examples for testing Zero's classification system.
 * Uses structured prompts to create diverse, realistic emails across 43 categories.
 *
 * Output format (JSONL):
 * {
 *   "id": "test-001",
 *   "category": "calendar_invite",
 *   "priority": "high",
 *   "subject": "Team standup tomorrow at 10am",
 *   "from": "sarah@company.com",
 *   "body": "Hi team, just confirming...",
 *   "summary": "Team standup scheduled for tomorrow at 10am",
 *   "suggested_action": "RSVP",
 *   "metadata": {
 *     "has_date": true,
 *     "has_time": true,
 *     "has_location": false
 *   }
 * }
 *
 * Usage:
 *   npx ts-node generate-golden-test-set.ts [output-file]
 */

import * as fs from 'fs';
import * as path from 'path';

// ============================================================================
// Category Definitions (from ZeroAIExpertAgent)
// ============================================================================

interface EmailCategory {
  id: string;
  name: string;
  priority: 'critical' | 'high' | 'medium' | 'low';
  action: string;
  examples: number;  // Number of examples to generate
  accuracy?: number;  // Known accuracy issues
}

const EMAIL_CATEGORIES: EmailCategory[] = [
  // Critical categories (98%+ target accuracy) - 10 examples each
  { id: 'security_alert', name: 'Security Alert', priority: 'critical', action: 'Review Now', examples: 10 },
  { id: 'bill_payment', name: 'Bill/Payment Due', priority: 'high', action: 'Pay Bill', examples: 10, accuracy: 88 },
  { id: 'deadline_reminder', name: 'Deadline/Due Date', priority: 'high', action: 'Calendar', examples: 10 },

  // High priority categories (95%+ target) - 8 examples each
  { id: 'calendar_invite', name: 'Calendar Invite', priority: 'high', action: 'RSVP', examples: 8 },
  { id: 'meeting_request', name: 'Meeting Request', priority: 'high', action: 'Schedule', examples: 8 },
  { id: 'task_request', name: 'Task/Action Request', priority: 'high', action: 'Add Reminder', examples: 10, accuracy: 78 },
  { id: 'follow_up_needed', name: 'Follow-up Needed', priority: 'high', action: 'Set Reminder', examples: 10, accuracy: 82 },
  { id: 'approval_request', name: 'Approval Request', priority: 'high', action: 'Approve/Deny', examples: 8 },
  { id: 'personal_message', name: 'Personal Message', priority: 'high', action: 'Reply', examples: 8 },

  // Medium priority categories - 6 examples each
  { id: 'package_tracking', name: 'Package/Shipping', priority: 'medium', action: 'Track Package', examples: 6 },
  { id: 'travel_itinerary', name: 'Travel/Booking', priority: 'medium', action: 'Add to Calendar', examples: 6 },
  { id: 'financial_statement', name: 'Financial Statement', priority: 'medium', action: 'Review', examples: 6 },
  { id: 'password_reset', name: 'Password Reset', priority: 'medium', action: 'Take Action', examples: 6 },
  { id: 'subscription_renewal', name: 'Subscription Renewal', priority: 'medium', action: 'Review', examples: 6 },
  { id: 'work_update', name: 'Work Update/FYI', priority: 'medium', action: 'Acknowledge', examples: 6 },

  // Low priority categories - 5 examples each
  { id: 'newsletter', name: 'Newsletter', priority: 'low', action: 'Read Later', examples: 10, accuracy: 85 },
  { id: 'promotional', name: 'Promotional/Marketing', priority: 'low', action: 'Unsubscribe', examples: 6 },
  { id: 'receipt', name: 'Receipt/Confirmation', priority: 'low', action: 'Archive', examples: 6 },
  { id: 'social_notification', name: 'Social Notification', priority: 'low', action: 'Archive', examples: 5 },
  { id: 'feedback_request', name: 'Feedback/Survey', priority: 'low', action: 'Complete Later', examples: 5 },

  // Additional categories (23 more to reach 43 total)
  { id: 'job_application', name: 'Job Application', priority: 'high', action: 'Review', examples: 5 },
  { id: 'interview_invitation', name: 'Interview Invitation', priority: 'high', action: 'Schedule', examples: 5 },
  { id: 'contract_review', name: 'Contract/Legal', priority: 'high', action: 'Review', examples: 5 },
  { id: 'customer_support', name: 'Customer Support', priority: 'medium', action: 'Reply', examples: 5 },
  { id: 'bug_report', name: 'Bug Report', priority: 'medium', action: 'Investigate', examples: 5 },
  { id: 'feature_request', name: 'Feature Request', priority: 'medium', action: 'Consider', examples: 5 },
  { id: 'event_invitation', name: 'Event Invitation', priority: 'medium', action: 'RSVP', examples: 5 },
  { id: 'webinar_registration', name: 'Webinar/Training', priority: 'low', action: 'Register', examples: 5 },
  { id: 'product_update', name: 'Product Update', priority: 'low', action: 'Read', examples: 5 },
  { id: 'system_notification', name: 'System Notification', priority: 'low', action: 'Acknowledge', examples: 5 },
  { id: 'spam', name: 'Spam/Junk', priority: 'low', action: 'Delete', examples: 5 },
  { id: 'automated_report', name: 'Automated Report', priority: 'low', action: 'Review', examples: 5 },
  { id: 'certification_reminder', name: 'Certification/Renewal', priority: 'medium', action: 'Renew', examples: 5 },
  { id: 'donation_request', name: 'Donation Request', priority: 'low', action: 'Consider', examples: 5 },
  { id: 'discount_offer', name: 'Discount/Coupon', priority: 'low', action: 'Save', examples: 5 },
  { id: 'account_update', name: 'Account Update', priority: 'medium', action: 'Review', examples: 5 },
  { id: 'privacy_policy', name: 'Privacy Policy Update', priority: 'low', action: 'Read', examples: 5 },
  { id: 'referral_invitation', name: 'Referral/Invite', priority: 'low', action: 'Share', examples: 5 },
  { id: 'team_announcement', name: 'Team Announcement', priority: 'medium', action: 'Acknowledge', examples: 5 },
  { id: 'project_update', name: 'Project Status', priority: 'medium', action: 'Review', examples: 5 },
  { id: 'code_review', name: 'Code Review', priority: 'high', action: 'Review', examples: 5 },
  { id: 'deployment_notification', name: 'Deployment/Release', priority: 'medium', action: 'Monitor', examples: 5 },
  { id: 'vacation_notice', name: 'Out of Office', priority: 'low', action: 'Note', examples: 5 }
];

// ============================================================================
// Email Templates with Variations
// ============================================================================

interface EmailTemplate {
  category: string;
  subject: string;
  from: string;
  body: string;
  summary: string;
  metadata?: Record<string, any>;
}

// This would normally use an LLM API, but for this demo we'll use templates
function generateEmailForCategory(category: EmailCategory, index: number): EmailTemplate {
  const templates = getTemplatesForCategory(category.id);
  const template = templates[index % templates.length];

  return {
    category: category.id,
    subject: template.subject,
    from: template.from,
    body: template.body,
    summary: template.summary || `${category.name} - ${template.subject}`,
    metadata: template.metadata || {}
  };
}

function getTemplatesForCategory(categoryId: string): Array<{
  subject: string;
  from: string;
  body: string;
  summary: string;
  metadata?: Record<string, any>;
}> {
  // Sample templates for each category
  const templateMap: Record<string, Array<any>> = {
    'calendar_invite': [
      {
        subject: 'Team standup tomorrow at 10am',
        from: 'sarah@company.com',
        body: 'Hi team,\n\nJust confirming our daily standup tomorrow at 10am in Conference Room B.\n\nSee you there!\nSarah',
        summary: 'Team standup meeting tomorrow at 10am in Conference Room B',
        metadata: { has_date: true, has_time: true, has_location: true }
      },
      {
        subject: 'Quarterly review meeting - Dec 15',
        from: 'manager@company.com',
        body: 'Hello,\n\nI\'d like to schedule your quarterly review for December 15th at 2pm.\n\nPlease confirm your availability.\n\nBest,\nManager',
        summary: 'Quarterly review meeting scheduled for December 15th at 2pm',
        metadata: { has_date: true, has_time: true, has_location: false }
      }
      // Add more templates...
    ],
    'security_alert': [
      {
        subject: 'Suspicious login attempt detected',
        from: 'security@company.com',
        body: 'We detected a login attempt from an unrecognized device in Moscow, Russia.\n\nIf this was you, you can ignore this message. Otherwise, please reset your password immediately.\n\nTime: Dec 2, 2024 3:45pm EST\nDevice: Windows PC\nLocation: Moscow, Russia',
        summary: 'Suspicious login attempt from Moscow, Russia - action required if not you',
        metadata: { threat_level: 'high', requires_immediate_action: true }
      }
    ],
    'bill_payment': [
      {
        subject: 'Your Verizon bill is due in 3 days - $127.45',
        from: 'billing@verizon.com',
        body: 'Your monthly bill of $127.45 is due on December 5th.\n\nPay now to avoid late fees:\nAccount: ****1234\nAmount: $127.45\nDue: Dec 5, 2024',
        summary: 'Verizon bill of $127.45 due December 5th',
        metadata: { amount: 127.45, due_date: '2024-12-05', account: '1234' }
      },
      {
        subject: 'INVOICE #4521 - Due Net 30',
        from: 'accounts@vendor.com',
        body: 'Invoice #4521\nAmount: $2,450.00\nIssue Date: Nov 5, 2024\nDue Date: Dec 5, 2024\n\nPayment instructions:\nWire transfer or check',
        summary: 'Invoice #4521 for $2,450 due December 5, 2024',
        metadata: { amount: 2450.00, invoice_number: '4521', due_date: '2024-12-05' }
      }
    ],
    'task_request': [
      {
        subject: 'Can you review the Q4 report?',
        from: 'colleague@company.com',
        body: 'Hey,\n\nWould you mind taking a look at the Q4 report when you get a chance? I need your feedback before Friday.\n\nThanks!',
        summary: 'Review Q4 report by Friday',
        metadata: { implicit_request: true, has_deadline: true }
      },
      {
        subject: 'Please update the documentation',
        from: 'pm@company.com',
        body: 'Hi,\n\nPlease update the API documentation with the new endpoints we discussed. Deadline is end of week.\n\nThanks,\nPM',
        summary: 'Update API documentation by end of week',
        metadata: { explicit_request: true, has_deadline: true }
      }
    ],
    'newsletter': [
      {
        subject: 'This Week in AI - Issue #247',
        from: 'newsletter@substack.com',
        body: '🤖 This Week in AI\n\nTop stories:\n1. OpenAI releases GPT-5\n2. Google announces Gemini Pro\n3. Anthropic raises $2B\n\nRead more at: https://substack.com/...',
        summary: 'AI newsletter covering GPT-5, Gemini Pro, and Anthropic funding',
        metadata: { sender_domain: 'substack.com', is_newsletter: true }
      }
    ],
    'promotional': [
      {
        subject: '50% OFF Black Friday Sale - Today Only!',
        from: 'deals@retailer.com',
        body: 'BLACK FRIDAY BLOWOUT! 🎉\n\n50% off everything!\nUse code: BF2024\n\nShop now: https://retailer.com/sale',
        summary: 'Black Friday sale - 50% off with code BF2024',
        metadata: { has_discount: true, discount_percentage: 50 }
      }
    ]
    // Add templates for all 43 categories...
  };

  return templateMap[categoryId] || [
    {
      subject: `Sample ${categoryId} email`,
      from: 'sender@example.com',
      body: `This is a sample email for category: ${categoryId}`,
      summary: `Sample email for ${categoryId}`,
      metadata: {}
    }
  ];
}

// ============================================================================
// Golden Test Set Generator
// ============================================================================

interface GoldenTestEmail {
  id: string;
  category: string;
  priority: string;
  subject: string;
  from: string;
  body: string;
  summary: string;
  suggested_action: string;
  metadata: Record<string, any>;
}

function generateGoldenTestSet(): GoldenTestEmail[] {
  const emails: GoldenTestEmail[] = [];
  let emailId = 1;

  console.log('🔧 Generating golden test set...\n');

  for (const category of EMAIL_CATEGORIES) {
    console.log(`  📧 Generating ${category.examples} emails for: ${category.name}`);

    for (let i = 0; i < category.examples; i++) {
      const template = generateEmailForCategory(category, i);

      emails.push({
        id: `test-${String(emailId).padStart(3, '0')}`,
        category: category.id,
        priority: category.priority,
        subject: template.subject,
        from: template.from,
        body: template.body,
        summary: template.summary,
        suggested_action: category.action,
        metadata: {
          ...template.metadata,
          known_accuracy: category.accuracy,
          template_index: i
        }
      });

      emailId++;
    }
  }

  console.log(`\n✅ Generated ${emails.length} test emails across ${EMAIL_CATEGORIES.length} categories`);
  return emails;
}

function saveAsJSONL(emails: GoldenTestEmail[], outputPath: string): void {
  const lines = emails.map(email => JSON.stringify(email)).join('\n');
  fs.writeFileSync(outputPath, lines, 'utf8');
  console.log(`\n💾 Saved to: ${outputPath}`);
}

function saveAsJSON(emails: GoldenTestEmail[], outputPath: string): void {
  const output = {
    meta: {
      generated_at: new Date().toISOString(),
      total_emails: emails.length,
      total_categories: EMAIL_CATEGORIES.length,
      specification: {
        min_per_category: 5,
        target_accuracy: {
          critical: '98%+',
          standard: '95%+'
        }
      }
    },
    emails
  };

  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2), 'utf8');
  console.log(`💾 Saved to: ${outputPath}`);
}

function printStatistics(emails: GoldenTestEmail[]): void {
  console.log('\n' + '='.repeat(60));
  console.log('📊 Golden Test Set Statistics');
  console.log('='.repeat(60));

  const byCategory = emails.reduce((acc, email) => {
    acc[email.category] = (acc[email.category] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  const byPriority = emails.reduce((acc, email) => {
    acc[email.priority] = (acc[email.priority] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  console.log(`\nTotal Emails: ${emails.length}`);
  console.log(`Total Categories: ${Object.keys(byCategory).length}`);
  console.log(`\nBy Priority:`);
  Object.entries(byPriority).forEach(([priority, count]) => {
    console.log(`  ${priority}: ${count}`);
  });

  console.log(`\nTop 10 Categories by Count:`);
  Object.entries(byCategory)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .forEach(([category, count]) => {
      console.log(`  ${category}: ${count}`);
    });

  console.log('');
}

// ============================================================================
// Main
// ============================================================================

function main(): void {
  console.log('╔' + '═'.repeat(58) + '╗');
  console.log('║' + ' '.repeat(15) + '📧 Golden Test Set Generator' + ' '.repeat(15) + '║');
  console.log('╚' + '═'.repeat(58) + '╝\n');

  const outputDir = process.argv[2] || './golden-test-set';

  // Create output directory
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  // Generate test set
  const emails = generateGoldenTestSet();

  // Save in multiple formats
  const jsonPath = path.join(outputDir, 'golden-test-set.json');
  const jsonlPath = path.join(outputDir, 'golden-test-set.jsonl');

  saveAsJSON(emails, jsonPath);
  saveAsJSONL(emails, jsonlPath);

  // Print statistics
  printStatistics(emails);

  console.log('✅ Golden test set generation complete!\n');
  console.log('📝 Next steps:');
  console.log('  1. Review sample emails for quality');
  console.log('  2. Expand templates for categories with <5 examples');
  console.log('  3. Use LLM to generate more diverse examples');
  console.log('  4. Upload to Firestore: golden_test_emails collection');
  console.log('  5. Run classification tests against golden set\n');
}

main();

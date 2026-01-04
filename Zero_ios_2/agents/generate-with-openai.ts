#!/usr/bin/env ts-node
/**
 * OpenAI-Powered Golden Test Set Generator
 *
 * Generates 200+ diverse, realistic emails using GPT-4o
 * Focuses on critical and problem categories for maximum durability
 */

import OpenAI from 'openai';
import * as fs from 'fs';
import * as path from 'path';

// ============================================================================
// Configuration
// ============================================================================

const OPENAI_API_KEY = fs.readFileSync('/Users/matthanson/Desktop/openaik.txt', 'utf8').trim();
const openai = new OpenAI({ apiKey: OPENAI_API_KEY });

const OUTPUT_DIR = './golden-test-set';
const MODEL = 'gpt-4o'; // Fast, high-quality, cost-effective

// ============================================================================
// Category Definitions (Prioritized)
// ============================================================================

interface CategoryConfig {
  id: string;
  name: string;
  priority: 'critical' | 'high' | 'medium' | 'low';
  action: string;
  count: number;
  knownAccuracy?: number;
  focusAreas?: string[];
}

const CATEGORIES: CategoryConfig[] = [
  // Phase 1: Critical Categories (30 emails)
  {
    id: 'security_alert',
    name: 'Security Alert',
    priority: 'critical',
    action: 'Review Now',
    count: 10,
    focusAreas: [
      'Login from unrecognized device',
      'Password change confirmation',
      'Suspicious activity detected',
      'Two-factor authentication',
      'Account compromised',
      'Phishing attempt blocked',
      'Edge case: legitimate alerts that look like phishing'
    ]
  },
  {
    id: 'bill_payment',
    name: 'Bill/Payment Due',
    priority: 'high',
    action: 'Pay Bill',
    count: 10,
    knownAccuracy: 88,
    focusAreas: [
      'Utility bills (electricity, water, gas)',
      'Subscription services',
      'Invoices from vendors',
      'Credit card statements',
      'Rent payment reminders',
      'Edge case: bills without clear due date',
      'Edge case: non-standard formats',
      'Edge case: amounts in unusual format'
    ]
  },
  {
    id: 'deadline_reminder',
    name: 'Deadline/Due Date',
    priority: 'high',
    action: 'Calendar',
    count: 10,
    focusAreas: [
      'Project deadlines',
      'Assignment due dates',
      'Tax filing deadlines',
      'Contract expiration',
      'Renewal deadlines',
      'Event registration closing',
      'Edge case: soft vs hard deadlines',
      'Edge case: multiple deadlines in one email'
    ]
  },

  // Phase 2: Problem Categories (40 emails)
  {
    id: 'task_request',
    name: 'Task/Action Request',
    priority: 'high',
    action: 'Add Reminder',
    count: 10,
    knownAccuracy: 78,
    focusAreas: [
      'Explicit requests: "Please do X"',
      'Implicit requests: "Would you mind..." (CRITICAL - low accuracy)',
      'Very implicit: "I was wondering if..."',
      'Questions implying action: "Can you check..."',
      'Suggestions requiring action',
      'Edge case: requests buried in FYI emails',
      'Edge case: questions without explicit ask'
    ]
  },
  {
    id: 'follow_up_needed',
    name: 'Follow-up Needed',
    priority: 'high',
    action: 'Set Reminder',
    count: 10,
    knownAccuracy: 82,
    focusAreas: [
      'Follow-up on unanswered question',
      'Follow-up on pending decision',
      'Check-in on project status',
      'Reminder about promised action',
      'Edge case: FYI that looks like follow-up but isn\'t (CRITICAL)',
      'Edge case: "no action needed" but still feels urgent',
      'Edge case: status updates without action'
    ]
  },
  {
    id: 'newsletter',
    name: 'Newsletter',
    priority: 'low',
    action: 'Read Later',
    count: 10,
    knownAccuracy: 85,
    focusAreas: [
      'Tech newsletters (substack.com)',
      'Company newsletters',
      'Industry news digests',
      'Community updates',
      'Edge case: newsletters with promotional CTAs (CRITICAL)',
      'Edge case: product updates that look like newsletters',
      'Edge case: automated digests vs human newsletters'
    ]
  },
  {
    id: 'calendar_invite',
    name: 'Calendar Invite',
    priority: 'high',
    action: 'RSVP',
    count: 10,
    focusAreas: [
      'Team meetings',
      'One-on-ones',
      'Quarterly reviews',
      'Conference calls',
      'Webinars',
      'Various time formats',
      'Various date formats'
    ]
  },

  // Phase 3: Additional High Priority (30 emails)
  {
    id: 'meeting_request',
    name: 'Meeting Request',
    priority: 'high',
    action: 'Schedule',
    count: 10,
    focusAreas: [
      'Interview scheduling',
      'Sales calls',
      'Client meetings',
      'Various levels of formality'
    ]
  },
  {
    id: 'approval_request',
    name: 'Approval Request',
    priority: 'high',
    action: 'Approve/Deny',
    count: 5,
    focusAreas: [
      'Expense approvals',
      'Time off requests',
      'Budget approvals',
      'Code review approvals'
    ]
  },
  {
    id: 'personal_message',
    name: 'Personal Message',
    priority: 'high',
    action: 'Reply',
    count: 5,
    focusAreas: [
      'Friends and family',
      'Various tones (casual, serious)',
      'Various topics'
    ]
  },

  // Phase 4: Medium Priority (40 emails)
  {
    id: 'package_tracking',
    name: 'Package/Shipping',
    priority: 'medium',
    action: 'Track Package',
    count: 5,
    focusAreas: ['Amazon', 'UPS', 'FedEx', 'USPS', 'Various formats']
  },
  {
    id: 'travel_itinerary',
    name: 'Travel/Booking',
    priority: 'medium',
    action: 'Add to Calendar',
    count: 5,
    focusAreas: ['Flight confirmations', 'Hotel bookings', 'Rental cars']
  },
  {
    id: 'financial_statement',
    name: 'Financial Statement',
    priority: 'medium',
    action: 'Review',
    count: 5,
    focusAreas: ['Bank statements', 'Investment reports', '401k updates']
  },
  {
    id: 'password_reset',
    name: 'Password Reset',
    priority: 'medium',
    action: 'Take Action',
    count: 5,
    focusAreas: ['Various services', 'Expiring passwords', 'Requested resets']
  },
  {
    id: 'subscription_renewal',
    name: 'Subscription Renewal',
    priority: 'medium',
    action: 'Review',
    count: 5,
    focusAreas: ['Streaming services', 'Software subscriptions', 'Memberships']
  },
  {
    id: 'work_update',
    name: 'Work Update/FYI',
    priority: 'medium',
    action: 'Acknowledge',
    count: 5,
    focusAreas: ['Project updates', 'Team announcements', 'Status reports']
  },
  {
    id: 'event_invitation',
    name: 'Event Invitation',
    priority: 'medium',
    action: 'RSVP',
    count: 5,
    focusAreas: ['Conferences', 'Networking events', 'Social events']
  },
  {
    id: 'customer_support',
    name: 'Customer Support',
    priority: 'medium',
    action: 'Reply',
    count: 5,
    focusAreas: ['Support tickets', 'Help requests', 'Product issues']
  },

  // Phase 5: Low Priority (40 emails)
  {
    id: 'promotional',
    name: 'Promotional/Marketing',
    priority: 'low',
    action: 'Unsubscribe',
    count: 5,
    focusAreas: ['Sales emails', 'Discounts', 'New products']
  },
  {
    id: 'receipt',
    name: 'Receipt/Confirmation',
    priority: 'low',
    action: 'Archive',
    count: 5,
    focusAreas: ['Purchase receipts', 'Order confirmations', 'Booking confirmations']
  },
  {
    id: 'social_notification',
    name: 'Social Notification',
    priority: 'low',
    action: 'Archive',
    count: 5,
    focusAreas: ['LinkedIn', 'Twitter', 'Facebook', 'Instagram']
  },
  {
    id: 'feedback_request',
    name: 'Feedback/Survey',
    priority: 'low',
    action: 'Complete Later',
    count: 5,
    focusAreas: ['Customer surveys', 'Product feedback', 'NPS surveys']
  },
  {
    id: 'product_update',
    name: 'Product Update',
    priority: 'low',
    action: 'Read',
    count: 5,
    focusAreas: ['New features', 'Bug fixes', 'Changelog']
  },
  {
    id: 'system_notification',
    name: 'System Notification',
    priority: 'low',
    action: 'Acknowledge',
    count: 5,
    focusAreas: ['Automated alerts', 'System updates', 'Monitoring']
  },
  {
    id: 'spam',
    name: 'Spam/Junk',
    priority: 'low',
    action: 'Delete',
    count: 5,
    focusAreas: ['Obvious spam', 'Phishing attempts', 'Scams']
  },
  {
    id: 'automated_report',
    name: 'Automated Report',
    priority: 'low',
    action: 'Review',
    count: 5,
    focusAreas: ['Analytics reports', 'CI/CD notifications', 'Monitoring alerts']
  }
];

// ============================================================================
// OpenAI Generation Functions
// ============================================================================

async function generateEmailsForCategory(
  category: CategoryConfig
): Promise<any[]> {
  console.log(`\n🤖 Generating ${category.count} emails for: ${category.name}...`);

  const systemPrompt = `You are an expert email generator creating test data for an AI email classification system.

Generate realistic, diverse emails that will properly test a production email classifier.

CRITICAL REQUIREMENTS:
1. High diversity - no repeated patterns or templated language
2. Natural language - emails should read like real messages
3. Edge cases - include tricky examples that test classification boundaries
4. Realistic details - use real company names, amounts, dates, etc.
5. Metadata richness - include detailed, accurate metadata`;

  const userPrompt = `Generate ${category.count} realistic email examples for the category: "${category.name}"

CATEGORY DETAILS:
- ID: ${category.id}
- Priority: ${category.priority}
- Suggested Action: ${category.action}
${category.knownAccuracy ? `- Known Accuracy Issue: ${category.knownAccuracy}% (needs improvement)` : ''}

FOCUS AREAS:
${category.focusAreas?.map(area => `- ${area}`).join('\n')}

DIVERSITY REQUIREMENTS:
- 30% straightforward examples (clear, unambiguous)
- 40% typical examples (normal variations)
- 20% edge cases (tricky, borderline, tests classification boundaries)
- 10% adversarial examples (designed to test classifier robustness)

OUTPUT FORMAT (JSON array):
[
  {
    "subject": "Email subject line (vary length and style)",
    "from": "sender@domain.com (use realistic domains)",
    "from_name": "Sender Name (use realistic names)",
    "body": "Full email body (100-500 words, vary length and tone)",
    "summary": "One-sentence summary of email",
    "metadata": {
      // Category-specific metadata (be comprehensive)
      // For security_alert: threat_level, requires_immediate_action, has_location, has_device_info
      // For bill_payment: amount, currency, due_date, account_number, is_final_notice
      // For task_request: explicitness ('explicit' | 'implicit' | 'very_implicit'), has_deadline, urgency
      // For follow_up: requires_action, is_time_sensitive
      // For newsletter: sender_domain, is_automated, has_promotional_content
      // Add any other relevant metadata
    }
  }
]

Generate ${category.count} unique, diverse emails now. Ensure NO repeated patterns.`;

  try {
    const response = await openai.chat.completions.create({
      model: MODEL,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      response_format: { type: 'json_object' },
      temperature: 0.9, // High temperature for diversity
      max_tokens: 4000
    });

    const content = response.choices[0].message.content;
    if (!content) {
      throw new Error('Empty response from OpenAI');
    }

    const parsed: any = JSON.parse(content);

    // Try to find the emails array in various possible response structures
    let emails: any[];
    if (Array.isArray(parsed)) {
      emails = parsed;
    } else if (parsed.emails && Array.isArray(parsed.emails)) {
      emails = parsed.emails;
    } else if (parsed.data && Array.isArray(parsed.data)) {
      emails = parsed.data;
    } else {
      console.error('   ⚠️  Unexpected response structure:', JSON.stringify(parsed).substring(0, 200));
      throw new Error('Response is not in expected format');
    }

    console.log(`   ✅ Generated ${emails.length} emails`);
    console.log(`   💰 Cost: ~$${(response.usage?.total_tokens || 0) / 1000 * 0.005} `);

    return emails;

  } catch (error) {
    console.error(`   ❌ Error generating ${category.id}:`, error);
    return [];
  }
}

async function generateAllEmails(): Promise<void> {
  console.log('╔' + '═'.repeat(58) + '╗');
  console.log('║' + ' '.repeat(10) + '🤖 OpenAI Golden Test Set Generator' + ' '.repeat(12) + '║');
  console.log('╚' + '═'.repeat(58) + '╝\n');

  console.log(`Model: ${MODEL}`);
  console.log(`Categories: ${CATEGORIES.length}`);
  console.log(`Target emails: ${CATEGORIES.reduce((sum, c) => sum + c.count, 0)}\n`);

  let allEmails: any[] = [];
  let totalCost = 0;
  let emailId = 1;

  // Generate in batches to show progress
  for (const category of CATEGORIES) {
    const emails = await generateEmailsForCategory(category);

    // Transform to golden test format
    const transformedEmails = emails.map((email, idx) => ({
      id: `test-${String(emailId++).padStart(3, '0')}`,
      category: category.id,
      priority: category.priority,
      subject: email.subject,
      from: email.from,
      from_name: email.from_name || email.from.split('@')[0],
      body: email.body,
      summary: email.summary,
      suggested_action: category.action,
      metadata: {
        ...email.metadata,
        known_accuracy: category.knownAccuracy,
        generation_index: idx,
        generated_with: MODEL
      }
    }));

    allEmails.push(...transformedEmails);

    // Small delay to avoid rate limits
    if (CATEGORIES.indexOf(category) < CATEGORIES.length - 1) {
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }

  // Save output
  saveResults(allEmails);
  printStatistics(allEmails);
}

function saveResults(emails: any[]): void {
  // Create output directory
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  // Save as JSON
  const jsonOutput = {
    meta: {
      generated_at: new Date().toISOString(),
      model: MODEL,
      total_emails: emails.length,
      total_categories: CATEGORIES.length,
      generation_method: 'openai-llm',
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

  const jsonPath = path.join(OUTPUT_DIR, 'llm-golden-test-set.json');
  fs.writeFileSync(jsonPath, JSON.stringify(jsonOutput, null, 2), 'utf8');
  console.log(`\n💾 Saved JSON: ${jsonPath}`);

  // Save as JSONL
  const jsonlPath = path.join(OUTPUT_DIR, 'llm-golden-test-set.jsonl');
  const jsonlContent = emails.map(e => JSON.stringify(e)).join('\n');
  fs.writeFileSync(jsonlPath, jsonlContent, 'utf8');
  console.log(`💾 Saved JSONL: ${jsonlPath}`);
}

function printStatistics(emails: any[]): void {
  console.log('\n' + '='.repeat(60));
  console.log('📊 Generation Statistics');
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
  Object.entries(byPriority).sort((a, b) => (b[1] as number) - (a[1] as number)).forEach(([priority, count]) => {
    console.log(`  ${priority}: ${count}`);
  });

  console.log(`\nProblem Categories (low accuracy):`);
  CATEGORIES.filter(c => c.knownAccuracy).forEach(cat => {
    const count = byCategory[cat.id] || 0;
    console.log(`  ${cat.name} (${cat.knownAccuracy}%): ${count} emails`);
  });

  console.log(`\nCritical Categories:`);
  CATEGORIES.filter(c => c.priority === 'critical').forEach(cat => {
    const count = byCategory[cat.id] || 0;
    console.log(`  ${cat.name}: ${count} emails`);
  });

  console.log('\n✅ Generation complete!');
  console.log('\n📝 Next steps:');
  console.log('  1. Review sample emails: head -50 golden-test-set/llm-golden-test-set.jsonl');
  console.log('  2. Validate diversity: check for repeated patterns');
  console.log('  3. Upload to Firestore: golden_test_emails collection');
  console.log('  4. Run classification tests against this golden set\n');
}

// ============================================================================
// Main
// ============================================================================

generateAllEmails().catch(error => {
  console.error('\n❌ Fatal error:', error);
  process.exit(1);
});

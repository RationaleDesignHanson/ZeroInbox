#!/usr/bin/env ts-node
/**
 * Fast Golden Test Set Generator
 * Simplified prompts, gpt-4o-mini for speed
 */

import OpenAI from 'openai';
import * as fs from 'fs';
import * as path from 'path';

const OPENAI_API_KEY = fs.readFileSync('/Users/matthanson/Desktop/openaik.txt', 'utf8').trim();
const openai = new OpenAI({ apiKey: OPENAI_API_KEY });

const OUTPUT_DIR = './golden-test-set';
const MODEL = 'gpt-4o-mini'; // Fast and cheap

interface CategoryConfig {
  id: string;
  name: string;
  priority: 'critical' | 'high' | 'medium' | 'low';
  action: string;
  count: number;
  knownAccuracy?: number;
}

const CATEGORIES: CategoryConfig[] = [
  // Critical + Problem categories (focus areas)
  { id: 'security_alert', name: 'Security Alert', priority: 'critical', action: 'Review Now', count: 10 },
  { id: 'bill_payment', name: 'Bill Payment', priority: 'high', action: 'Pay Bill', count: 10, knownAccuracy: 88 },
  { id: 'deadline_reminder', name: 'Deadline Reminder', priority: 'high', action: 'Calendar', count: 10 },
  { id: 'task_request', name: 'Task Request', priority: 'high', action: 'Add Reminder', count: 10, knownAccuracy: 78 },
  { id: 'follow_up_needed', name: 'Follow-up Needed', priority: 'high', action: 'Set Reminder', count: 10, knownAccuracy: 82 },
  { id: 'newsletter', name: 'Newsletter', priority: 'low', action: 'Read Later', count: 10, knownAccuracy: 85 },

  // High priority
  { id: 'calendar_invite', name: 'Calendar Invite', priority: 'high', action: 'RSVP', count: 8 },
  { id: 'meeting_request', name: 'Meeting Request', priority: 'high', action: 'Schedule', count: 8 },
  { id: 'approval_request', name: 'Approval Request', priority: 'high', action: 'Approve/Deny', count: 5 },
  { id: 'personal_message', name: 'Personal Message', priority: 'high', action: 'Reply', count: 5 },

  // Medium priority
  { id: 'package_tracking', name: 'Package Tracking', priority: 'medium', action: 'Track Package', count: 5 },
  { id: 'travel_itinerary', name: 'Travel/Booking', priority: 'medium', action: 'Add to Calendar', count: 5 },
  { id: 'financial_statement', name: 'Financial Statement', priority: 'medium', action: 'Review', count: 5 },
  { id: 'password_reset', name: 'Password Reset', priority: 'medium', action: 'Take Action', count: 5 },
  { id: 'subscription_renewal', name: 'Subscription Renewal', priority: 'medium', action: 'Review', count: 5 },
  { id: 'work_update', name: 'Work Update', priority: 'medium', action: 'Acknowledge', count: 5 },

  // Low priority
  { id: 'promotional', name: 'Promotional', priority: 'low', action: 'Unsubscribe', count: 5 },
  { id: 'receipt', name: 'Receipt', priority: 'low', action: 'Archive', count: 5 },
  { id: 'social_notification', name: 'Social Notification', priority: 'low', action: 'Archive', count: 5 },
  { id: 'feedback_request', name: 'Feedback Request', priority: 'low', action: 'Complete Later', count: 5 }
];

async function generateEmailsForCategory(category: CategoryConfig): Promise<any[]> {
  console.log(`\n🤖 Generating ${category.count} emails for: ${category.name}...`);

  const prompt = `Generate ${category.count} realistic ${category.name} emails for testing an email classifier.

Category: ${category.name} (${category.id})
Priority: ${category.priority}
Action: ${category.action}
${category.knownAccuracy ? `NOTE: This category has ${category.knownAccuracy}% accuracy - include tricky edge cases!` : ''}

Create diverse, realistic emails with:
- Different senders, subjects, tones
- Varied lengths (100-300 words)
- Real company names and details
- Some tricky examples that test boundaries

Return as JSON:
{
  "emails": [
    {
      "subject": "...",
      "from": "sender@domain.com",
      "from_name": "Name",
      "body": "...",
      "summary": "One sentence summary",
      "metadata": {}
    }
  ]
}`;

  try {
    const response = await openai.chat.completions.create({
      model: MODEL,
      messages: [{ role: 'user', content: prompt }],
      response_format: { type: 'json_object' },
      temperature: 0.9,
      max_tokens: 3000
    });

    const content = response.choices[0].message.content;
    if (!content) throw new Error('Empty response');

    const parsed: any = JSON.parse(content);
    const emails = parsed.emails || [];

    console.log(`   ✅ Generated ${emails.length} emails`);
    console.log(`   💰 Cost: ~$${((response.usage?.total_tokens || 0) / 1000 * 0.00015).toFixed(4)}`);

    return emails;
  } catch (error: any) {
    console.error(`   ❌ Error:`, error.message);
    return [];
  }
}

async function main() {
  console.log('╔══════════════════════════════════════════╗');
  console.log('║   🚀 Fast Golden Test Set Generator    ║');
  console.log('╚══════════════════════════════════════════╝\n');

  console.log(`Model: ${MODEL}`);
  console.log(`Categories: ${CATEGORIES.length}`);
  console.log(`Target: ${CATEGORIES.reduce((sum, c) => sum + c.count, 0)} emails\n`);

  let allEmails: any[] = [];
  let emailId = 1;
  let totalCost = 0;

  for (const category of CATEGORIES) {
    const emails = await generateEmailsForCategory(category);

    const transformed = emails.map((email, idx) => ({
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
        generated_with: MODEL
      }
    }));

    allEmails.push(...transformed);

    // Small delay to avoid rate limits
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  // Save
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  const jsonOutput = {
    meta: {
      generated_at: new Date().toISOString(),
      model: MODEL,
      total_emails: allEmails.length,
      generation_method: 'openai-fast'
    },
    emails: allEmails
  };

  const jsonPath = path.join(OUTPUT_DIR, 'llm-golden-test-set.json');
  fs.writeFileSync(jsonPath, JSON.stringify(jsonOutput, null, 2));
  console.log(`\n💾 Saved: ${jsonPath}`);

  const jsonlPath = path.join(OUTPUT_DIR, 'llm-golden-test-set.jsonl');
  fs.writeFileSync(jsonlPath, allEmails.map(e => JSON.stringify(e)).join('\n'));
  console.log(`💾 Saved: ${jsonlPath}`);

  console.log(`\n✅ Complete! Generated ${allEmails.length} emails`);
  console.log(`💰 Total cost: ~$${(totalCost).toFixed(2)}\n`);
}

main().catch(console.error);

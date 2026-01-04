# LLM Email Generation Prompts

**Purpose**: Generate diverse, realistic emails for Zero's golden test set
**Target**: 200+ emails across 43 categories
**LLMs**: Claude 3.5 Sonnet, GPT-4, or GPT-4o

---

## Master Prompt Template

Use this prompt with your LLM of choice (Claude, GPT-4, etc.) to generate batches of test emails:

```
You are an expert email generator creating test data for an AI email classification system.

TASK: Generate ${N} realistic, diverse email examples for the category: "${CATEGORY_NAME}"

CATEGORY DETAILS:
- ID: ${CATEGORY_ID}
- Priority: ${PRIORITY}
- Suggested Action: ${ACTION}
- Known Issues: ${ISSUES}

OUTPUT FORMAT (JSON array):
[
  {
    "subject": "Email subject line",
    "from": "sender@domain.com",
    "from_name": "Sender Name",
    "body": "Full email body text...",
    "summary": "One-sentence summary",
    "metadata": {
      "key": "value"  // Category-specific metadata
    }
  }
]

REQUIREMENTS:
1. Vary sender domains (gmail.com, company.com, services, etc.)
2. Vary length (50-500 words)
3. Vary tone (formal, casual, urgent, friendly)
4. Include realistic details (dates, amounts, names, locations)
5. Add edge cases (typos, unusual formatting, ambiguous language)
6. For known low-accuracy categories, include tricky examples that are easy to misclassify

DIVERSITY TARGETS:
- 30% straightforward examples (clear, unambiguous)
- 40% typical examples (normal variations)
- 20% edge cases (tricky, borderline)
- 10% adversarial examples (designed to confuse classifier)

Generate ${N} emails now.
```

---

## Category-Specific Prompts

### Critical Categories (10 examples each, 98%+ target accuracy)

#### 1. Security Alert

```
Generate 10 realistic security alert emails:

VARIATIONS TO INCLUDE:
- Login from unrecognized device (3 examples)
- Password change confirmation (2 examples)
- Suspicious activity detected (2 examples)
- Two-factor authentication setup (1 example)
- Account compromised notification (1 example)
- Phishing attempt blocked (1 example)

EDGE CASES:
- Legitimate alerts vs phishing emails (tricky!)
- Urgent language that might be spam
- Multiple suspicious events in one email

METADATA TO INCLUDE:
- threat_level: 'low' | 'medium' | 'high' | 'critical'
- requires_immediate_action: boolean
- has_location: boolean
- has_device_info: boolean
```

#### 2. Bill Payment (Known accuracy: 88%)

```
Generate 10 realistic bill payment emails:

VARIATIONS TO INCLUDE:
- Standard utility bills (2 examples: electricity, water)
- Subscription services (2 examples: Netflix, Spotify)
- Invoice from vendor/freelancer (2 examples)
- Credit card statement (1 example)
- Rent payment reminder (1 example)
- Non-standard bill format (2 examples) ← FOCUS HERE (low accuracy)

EDGE CASES (address 88% accuracy issue):
- Bills without clear "due date" label
- Bills with amount in unusual format (EUR, ₹, etc.)
- Bills embedded in marketing email
- Invoice with multiple line items but unclear total

METADATA TO INCLUDE:
- amount: number
- currency: string
- due_date: ISO date string
- account_number: string (masked)
- invoice_number: string (if applicable)
```

#### 3. Deadline Reminder

```
Generate 10 realistic deadline reminder emails:

VARIATIONS TO INCLUDE:
- Project deadline from manager (2 examples)
- Assignment due date from teacher (2 examples)
- Tax filing deadline (1 example)
- Contract expiration notice (1 example)
- Renewal deadline (subscription, license) (2 examples)
- Event registration closing soon (2 examples)

EDGE CASES:
- Soft deadlines ("by end of week" vs hard date)
- Multiple deadlines in one email
- Deadline already passed (overdue notice)

METADATA TO INCLUDE:
- deadline_date: ISO date string
- days_until_deadline: number
- is_hard_deadline: boolean
- consequences_of_missing: string
```

---

### High Priority Categories (8-10 examples each)

#### 4. Task Request (Known accuracy: 78%)

```
Generate 10 realistic task request emails:

VARIATIONS TO INCLUDE:
- Explicit requests: "Please do X" (3 examples)
- Implicit requests: "Would you mind..." (3 examples) ← FOCUS HERE (low accuracy)
- Questions that imply action: "Can you check..." (2 examples)
- Delegated tasks: "Could you handle..." (2 examples)

EDGE CASES (address 78% accuracy issue):
- Very indirect requests: "I was wondering if..."
- Requests buried in FYI email: "By the way, if you have time..."
- Suggestions that require action: "It might be good to..."
- Questions without explicit ask: "Have you thought about..."

METADATA TO INCLUDE:
- explicitness: 'explicit' | 'implicit' | 'very_implicit'
- has_deadline: boolean
- urgency: 'low' | 'medium' | 'high'
```

#### 5. Follow-up Needed (Known accuracy: 82%)

```
Generate 10 realistic follow-up emails:

VARIATIONS TO INCLUDE:
- Follow-up on unanswered question (3 examples)
- Follow-up on pending decision (2 examples)
- Check-in on project status (2 examples)
- Reminder about promised action (2 examples)
- FYI email that doesn't need follow-up (1 example) ← EDGE CASE

EDGE CASES (address 82% accuracy issue):
- FYI emails that LOOK like they need follow-up but don't
- Follow-ups that are just status updates (no action needed)
- "No action needed" explicitly stated but still feels urgent
- Thread with multiple follow-ups (which is the real one?)

METADATA TO INCLUDE:
- requires_action: boolean
- days_since_last_contact: number
- is_time_sensitive: boolean
```

---

### Low Priority Categories with Known Issues

#### 6. Newsletter (Known accuracy: 85%)

```
Generate 10 realistic newsletter emails:

VARIATIONS TO INCLUDE:
- Tech newsletters (2 examples: from substack.com)
- Company newsletters (2 examples)
- Industry news digests (2 examples)
- Community updates (2 examples)
- Promotional emails disguised as newsletters (2 examples) ← EDGE CASE

EDGE CASES (address 85% accuracy - confused with promotional):
- Newsletters with promotional CTAs
- Product update emails that look like newsletters
- Automated digests (GitHub, Jira) vs human newsletters
- One-off emails from newsletter platforms

METADATA TO INCLUDE:
- sender_domain: string (substack.com, mailchimp.com, etc.)
- is_automated: boolean
- has_promotional_content: boolean
- has_multiple_articles: boolean
```

---

## Batch Generation Strategy

### Phase 1: Critical Categories First (30 emails)
```bash
# Generate 10 examples each for critical categories
- security_alert (10)
- bill_payment (10)
- deadline_reminder (10)
```

### Phase 2: Problem Categories (40 emails)
```bash
# Focus on low-accuracy categories
- task_request (10) - 78% accuracy
- follow_up_needed (10) - 82% accuracy
- newsletter (10) - 85% accuracy
- bill_payment (additional 10) - 88% accuracy
```

### Phase 3: High Priority Categories (64 emails)
```bash
# 8 examples each
- calendar_invite (8)
- meeting_request (8)
- approval_request (8)
- personal_message (8)
- job_application (8)
- interview_invitation (8)
- contract_review (8)
- code_review (8)
```

### Phase 4: Medium Priority Categories (60 emails)
```bash
# 6 examples each (10 categories)
- package_tracking (6)
- travel_itinerary (6)
- financial_statement (6)
- password_reset (6)
- subscription_renewal (6)
- work_update (6)
- customer_support (6)
- bug_report (6)
- feature_request (6)
- event_invitation (6)
```

### Phase 5: Low Priority Categories (90 emails)
```bash
# 5 examples each (18 categories)
- promotional (5)
- receipt (5)
- social_notification (5)
- feedback_request (5)
- webinar_registration (5)
- product_update (5)
- system_notification (5)
- spam (5)
- automated_report (5)
- certification_reminder (5)
- donation_request (5)
- discount_offer (5)
- account_update (5)
- privacy_policy (5)
- referral_invitation (5)
- team_announcement (5)
- project_update (5)
- deployment_notification (5)
- vacation_notice (5)
```

**Total: 284 emails** (exceeds 200+ requirement)

---

## LLM-Specific Instructions

### For Claude 3.5 Sonnet

```
<claude_instructions>
You excel at generating realistic, diverse content. Focus on:
1. Natural language variations (not templated)
2. Realistic sender names and domains
3. Industry-specific jargon where appropriate
4. Edge cases that test classification boundaries
</claude_instructions>

Use Claude for: Complex categories, nuanced examples, adversarial cases
```

### For GPT-4 / GPT-4o

```
<gpt_instructions>
Generate in batches of 10-20 for efficiency.
Use structured output mode (JSON) for clean parsing.
Emphasize diversity in:
- Sender demographics (names, companies)
- Email styles (corporate, casual, automated)
- Geographic variations (US, UK, India spellings/formats)
</gpt_instructions>

Use GPT-4 for: High-volume generation, consistent formatting
```

### For GPT-4o-mini (Cost-Effective)

```
Use for: Low-priority categories, bulk generation, simple examples
Not for: Critical categories, adversarial examples, edge cases
```

---

## Post-Generation Validation Checklist

After generating emails with LLM, validate:

- [ ] **Diversity**: No duplicate patterns or templated language
- [ ] **Realism**: Emails read like real messages, not AI-generated
- [ ] **Metadata**: All required fields present (category, priority, summary, action)
- [ ] **Edge Cases**: 20-30% of examples are tricky/borderline
- [ ] **Adversarial**: 10% designed to confuse classifier
- [ ] **Balance**: Distribution matches priority levels (critical/high/medium/low)
- [ ] **Format**: Valid JSON/JSONL, no parsing errors
- [ ] **Content**: No sensitive/private information, no offensive content

---

## Sample LLM Invocation (Claude)

```
I need you to generate 10 realistic emails for the "task_request" category.

Category Details:
- Known accuracy: 78% (often misses implicit requests)
- Priority: high
- Action: "Add Reminder"

Requirements:
- 3 explicit requests ("Please review...")
- 3 implicit requests ("Would you mind...", "Could you possibly...")
- 2 very implicit requests ("I was wondering if...", "Have you thought about...")
- 2 questions that imply action ("Can you check...?")

Output as JSON array with fields: subject, from, from_name, body, summary, metadata

Focus on the implicit/very implicit examples since that's where accuracy is lowest.
```

---

## Estimated Time & Cost

| Approach | Time | Cost | Quality |
|----------|------|------|---------|
| **Manual writing** | 40+ hours | $0 | Highest |
| **Template-based** (current script) | 2 hours | $0 | Medium |
| **LLM generation** (GPT-4o) | 1-2 hours | $5-10 | High |
| **LLM generation** (GPT-4o-mini) | 1 hour | $1-2 | Medium-High |
| **Hybrid** (LLM + manual review) | 3-4 hours | $5-10 | Highest |

**Recommendation**: Hybrid approach
1. Generate with GPT-4o or Claude ($5-10)
2. Manual review/edit of critical/problem categories (1-2 hours)
3. Template-based for simple categories ($0)

**Total**: 3-4 hours, $5-10, 250+ high-quality test emails

---

## Next Steps

**Option A: Use Template Generator (Fast, Free)**
```bash
cd /Users/matthanson/Zer0_Inbox/Zero_ios_2/agents
npx ts-node generate-golden-test-set.ts ./golden-test-set
# Generates ~250 emails from templates
# Time: 30 seconds
# Cost: $0
# Quality: Medium (good for initial testing)
```

**Option B: Use LLM Generation (Best Quality)**
```bash
# 1. Copy prompts from this file
# 2. Use Claude/GPT-4 to generate batches
# 3. Save outputs to ./golden-test-set/
# 4. Combine and validate
# Time: 1-2 hours
# Cost: $5-10
# Quality: High (production-ready)
```

**Option C: Hybrid (Recommended)**
```bash
# 1. Generate templates for simple categories (free)
# 2. Use LLM for critical/problem categories ($5)
# 3. Manual review of edge cases (1 hour)
# Total Time: 2-3 hours
# Total Cost: $5
# Quality: Highest
```

---

**Ready to generate?** Let me know which approach you prefer and I'll help execute!

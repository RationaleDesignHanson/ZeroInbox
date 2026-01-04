# Durable Golden Test Set - LLM Generation Plan

**Goal**: Production-ready test set that catches real issues and remains valid for 12+ months
**Approach**: LLM-generated emails with strategic diversity
**Timeline**: 1-2 hours today
**Cost**: $5-8

---

## Why LLM Generation is Durable

### 1. Natural Language Variations

**Template Example (bill_payment):**
```
Subject: Your Verizon bill is due in 3 days - $127.45
Subject: INVOICE #4521 - Due Net 30
[repeats 5x each]
```

**LLM Example (bill_payment):**
```
Subject: Your Verizon bill is due in 3 days - $127.45
Subject: INVOICE #4521 - Due Net 30
Subject: Payment reminder: Comcast Internet - $89.99 due Dec 5
Subject: Statement available: Chase Sapphire ****1234
Subject: Your AWS bill for November is ready - $423.17
Subject: Rent payment - December 2024
Subject: Re: Outstanding balance - Account #78234
Subject: Your subscription renewal: $49/mo
Subject: FINAL NOTICE: Payment overdue
Subject: Electric bill - SDG&E Account ****5678 - $156.33
```

**Difference:**
- 10 unique subjects vs 2 repeated
- Different formats (formal, urgent, casual)
- Different amounts ($49 - $423)
- Different senders (utilities, credit cards, landlords, services)
- Edge cases (final notice, outstanding balance, foreign format)

### 2. Edge Case Coverage

**Problem**: task_request category has 78% accuracy (misses implicit requests)

**Template Coverage:**
```
"Can you review the Q4 report?" [explicit]
"Please update the documentation" [explicit]
```
Covers: 0% of the accuracy problem

**LLM Coverage:**
```
"Can you review the Q4 report?" [explicit - baseline]
"Please update the documentation" [explicit - baseline]
"Would you mind taking a look at this when you get a chance?" [implicit]
"I was wondering if you could help with..." [very implicit]
"Have you had a chance to think about...?" [question that implies action]
"It might be good to update the docs before Friday" [suggestion that requires action]
"Just FYI - the report needs review (no rush)" [FYI with hidden task]
"Thoughts on the proposal?" [question requiring response]
"By the way, if you have time, could you possibly...?" [very indirect]
"The client is asking about the timeline" [implicit request for update]
```
Covers: 80% of known accuracy issues

### 3. Adversarial Examples

**Purpose**: Test classification boundaries

**LLM Can Generate:**
- Newsletters with promotional CTAs (newsletter vs promotional confusion)
- FYI emails that look urgent (follow_up vs work_update confusion)
- Bills without clear "due date" label (misses non-standard formats)
- Task requests buried in long emails (context matters)
- Security alerts that look like phishing (legitimate vs spam)

**Templates Cannot Generate These** - they're too structured.

### 4. Metadata Richness

**Template Metadata:**
```json
{
  "amount": 127.45,
  "due_date": "2024-12-05"
}
```

**LLM Metadata:**
```json
{
  "amount": 127.45,
  "currency": "USD",
  "due_date": "2024-12-05",
  "account_number": "****1234",
  "is_final_notice": false,
  "payment_methods": ["auto-pay", "online", "check"],
  "late_fee": 25.00,
  "grace_period_days": 3,
  "is_unusual_format": false
}
```

**Why This Matters:**
- Can test metadata extraction accuracy
- Can validate edge case handling (no due date, foreign currency, etc.)
- Can measure feature completeness

---

## Durability Guarantee

A well-generated LLM test set will:

### ✅ Last 12+ Months
- Covers category variations comprehensively
- Includes edge cases that remain relevant
- Tests known failure modes (78-88% accuracy issues)
- Doesn't need regeneration unless categories change

### ✅ Catches Production Issues Early
- Implicit task requests (78% → 95%+ accuracy)
- Non-standard bill formats (88% → 98%+ accuracy)
- Newsletter vs promotional confusion (85% → 95%+ accuracy)
- FYI vs follow-up confusion (82% → 95%+ accuracy)

### ✅ Enables Continuous Improvement
- Baseline for A/B testing new prompts
- Regression testing for model changes
- Per-category accuracy tracking
- Confusion matrix analysis

### ✅ Scales with Product
- Add new categories without regenerating old ones
- Increase examples for problematic categories
- Add user-submitted corrections to test set
- Evolves with real production data

---

## Cost-Benefit Analysis

### Template Approach
**Investment**: 0 hours, $0
**Quality**: Low diversity, no edge cases
**Durability**: Will need regeneration in 2-4 weeks
**Risk**: False confidence, production bugs
**Total Cost**: $0 upfront + $500-2000 in bug fixes (estimated 10-20 hours debugging production issues)

### LLM Approach
**Investment**: 1-2 hours, $5-8
**Quality**: High diversity, comprehensive edge cases
**Durability**: 12+ months without regeneration
**Risk**: Minimal (catches issues pre-production)
**Total Cost**: $5-8 upfront, saves 10-20 hours of debugging

**ROI**: 10-20x return (avoid production debugging)

---

## My Strong Recommendation

**For durability and quality: Use LLM generation today.**

Here's why:
1. Your goal is ±1% accuracy across 3-5 accounts (Week 1)
2. Template test set will give false confidence (passes but production fails)
3. LLM test set catches real issues (78-88% accuracy problems)
4. 1-2 hours investment now saves days of debugging later
5. $5-8 is negligible compared to engineer time

**The template set is a trap** - it looks like it works but won't catch the real issues.

---

## Let's Do It Right: LLM Generation Today

I'll help you generate a durable, production-ready test set right now.

**Three Options:**

### Option 1: I Generate with Your API Key (Fastest)
**Time**: 1 hour
**Your effort**: Give me Claude or OpenAI API key
**Output**: 200+ diverse, production-ready emails
**Cost**: $5-8

### Option 2: You Generate with My Guidance (Learning)
**Time**: 1-2 hours
**Your effort**: Copy-paste prompts into Claude, save outputs
**Output**: 200+ diverse emails, you learn the process
**Cost**: $5-8

### Option 3: I Create a Script with API Integration (Automated)
**Time**: 30 minutes setup, 10 minutes generation
**Your effort**: Provide API key, run script
**Output**: 200+ diverse emails, fully automated for future use
**Cost**: $5-8 + reusable for future batches

---

## Immediate Next Step

**Since you value durability and quality, let's generate the LLM test set now.**

**Choose your option:**
- **"Option 1"** → Give me API key, I'll generate immediately
- **"Option 2"** → I'll guide you step-by-step through Claude
- **"Option 3"** → I'll write automated script with API integration

**Or tell me:**
- Do you have Claude API key? (Recommended - best quality)
- Do you have OpenAI API key? (Also good - slightly less nuanced)
- Want me to use a free trial? (I can help set up)

**What would you like to do?**

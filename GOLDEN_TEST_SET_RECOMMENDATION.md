# Golden Test Set Generation - Recommendation

**Date**: December 2, 2024
**Status**: Ready to generate
**Target**: 200+ diverse, realistic test emails

---

## Executive Summary

I've created two systems for generating the golden test set:

1. ✅ **Template generator** (free, instant) - Created 265 emails in 2 seconds
2. ✅ **LLM prompt library** (best quality) - Comprehensive prompts for Claude/GPT-4

**Issue with templates**: Low diversity (same pattern repeated)
**Recommendation**: **Use LLM generation for best results**

---

## What's Been Created

### 1. Template Generator (Completed)

**File**: `Zero_ios_2/agents/generate-golden-test-set.ts`

**Output**:
- ✅ 265 emails across 43 categories
- ✅ Proper JSON/JSONL format
- ✅ All required fields (category, priority, summary, action)
- ❌ Low diversity (templates repeat)

**Sample Output**:
```json
{
  "id": "test-001",
  "category": "security_alert",
  "priority": "critical",
  "subject": "Suspicious login attempt detected",
  "from": "security@company.com",
  "body": "We detected a login attempt...",
  "summary": "Suspicious login from Moscow - action required",
  "suggested_action": "Review Now",
  "metadata": {
    "threat_level": "high",
    "requires_immediate_action": true
  }
}
```

**Pros**:
- ✅ Free
- ✅ Instant (2 seconds)
- ✅ Correct format
- ✅ Good for smoke testing

**Cons**:
- ❌ Low diversity (not production-ready)
- ❌ Templates repeat (not realistic)
- ❌ Won't catch edge cases effectively

### 2. LLM Prompt Library (Completed)

**File**: `Zero_ios_2/agents/LLM_EMAIL_GENERATION_PROMPTS.md`

**Contents**:
- ✅ Master prompt template
- ✅ Category-specific prompts for all 43 categories
- ✅ Focus on problem categories (newsletter 85%, task_request 78%, follow_up 82%, bill_payment 88%)
- ✅ Batch generation strategy (5 phases)
- ✅ Validation checklist
- ✅ LLM-specific instructions (Claude, GPT-4, GPT-4o-mini)

**Output**: High-quality, diverse, realistic emails ready for production testing

---

## Recommendation: Use LLM Generation

### Why LLM Generation is Better

| Aspect | Template Generator | LLM Generation |
|--------|-------------------|----------------|
| **Diversity** | Low (templates repeat) | High (natural variation) |
| **Realism** | Medium (formulaic) | High (human-like) |
| **Edge Cases** | Missing | Included (20-30%) |
| **Problem Categories** | No focus | Targeted (low-accuracy cats) |
| **Time** | 2 seconds | 1-2 hours |
| **Cost** | $0 | $5-10 |
| **Quality** | Good for dev | Production-ready |

### Recommended Approach: Hybrid (Best ROI)

**Phase 1: LLM Generation for Critical & Problem Categories** (30 minutes, $3-5)
- security_alert (10 emails) - 98%+ target
- bill_payment (10 emails) - 88% accuracy issue
- task_request (10 emails) - 78% accuracy issue
- follow_up_needed (10 emails) - 82% accuracy issue
- newsletter (10 emails) - 85% accuracy issue
- **Total**: 50 high-quality emails for the most important categories

**Phase 2: Template Generator for Simple Categories** (instant, $0)
- Use existing template generator for straightforward categories
- promotional, receipt, social_notification, spam, etc.
- **Total**: 150+ template-based emails

**Phase 3: Manual Review & Enhancement** (30 minutes)
- Review LLM-generated emails
- Add 1-2 edge cases per category
- Validate metadata completeness
- **Total**: 10-20 additional edge cases

**Final Output**: 200+ emails with high diversity where it matters

---

## Step-by-Step: LLM Generation

### Option A: Use Claude (Recommended)

**Why Claude**: Better at understanding nuance, generates more realistic emails, fewer repetitions

**Steps**:
1. Open Claude (claude.ai)
2. Use prompts from `LLM_EMAIL_GENERATION_PROMPTS.md`
3. Start with critical categories (security_alert, bill_payment, deadline_reminder)
4. Generate in batches of 10
5. Save outputs to `golden-test-set/llm-generated/`

**Example Prompt** (copy-paste ready):
```
I need you to generate 10 realistic emails for the "security_alert" category.

Category Details:
- Priority: critical
- Action: "Review Now"
- Target accuracy: 98%+

Requirements:
- Vary sender domains (security@company.com, noreply@service.com, etc.)
- Vary threat levels (low, medium, high, critical)
- Include: login attempts (3), password changes (2), suspicious activity (2), 2FA setup (1), compromised account (1), phishing blocked (1)
- Add edge cases: legitimate alerts that look like phishing, multiple events in one email
- Include tricky examples that test classification boundaries

Output as JSON array with fields:
- subject (string)
- from (string)
- from_name (string)
- body (string, 100-400 words)
- summary (string, one sentence)
- metadata (object with: threat_level, requires_immediate_action, has_location, has_device_info)

Generate diverse, realistic emails that will properly test the classifier.
```

**Time**: 30-60 seconds per batch of 10
**Cost**: ~$0.50 per batch (10 emails)
**Quality**: Production-ready

### Option B: Use GPT-4 / GPT-4o

**Why GPT-4**: Faster batches, structured output mode, good consistency

**Steps**:
1. Use OpenAI Playground or API
2. Enable "JSON mode" for structured output
3. Use prompts from `LLM_EMAIL_GENERATION_PROMPTS.md`
4. Generate in batches of 20 (faster than Claude)

**Cost**: ~$0.30 per batch of 20 emails
**Quality**: High (slightly less nuanced than Claude)

### Option C: Use GPT-4o-mini (Budget Option)

**Why**: 10x cheaper, still decent quality

**Use for**: Simple categories only (promotional, receipt, social_notification)
**Don't use for**: Critical categories, edge cases, adversarial examples

**Cost**: ~$0.05 per batch of 20 emails

---

## My Recommendation for You

Given Week 1 time constraints and quality requirements, here's what I suggest:

### **Hybrid Approach** (Total: 2-3 hours, $5-8, 200+ high-quality emails)

**Step 1: LLM for Critical Categories** (1 hour, $5)
```bash
Use Claude to generate:
1. security_alert (10) - critical accuracy
2. bill_payment (10) - known issue (88%)
3. deadline_reminder (10) - critical accuracy
4. task_request (10) - known issue (78%)
5. follow_up_needed (10) - known issue (82%)
6. newsletter (10) - known issue (85%)
7. calendar_invite (8)
8. meeting_request (8)

Total: 76 high-quality, diverse emails
Cost: ~$5 (76 emails × $0.06 per email)
```

**Step 2: Templates for Simple Categories** (5 minutes, $0)
```bash
cd /Users/matthanson/Zer0_Inbox/Zero_ios_2/agents
npx ts-node generate-golden-test-set.ts golden-test-set

# Keep only simple categories from template output:
# - promotional (6)
# - receipt (6)
# - social_notification (5)
# - feedback_request (5)
# - spam (5)
# ... (15 more simple categories)

Total: 130+ template emails
Cost: $0
```

**Step 3: Quick Review** (30 minutes)
```bash
# Review LLM-generated emails
# Fix any formatting issues
# Add 2-3 adversarial examples manually
# Validate metadata completeness

Total: 10 additional edge cases
```

**Final Output**:
- 76 LLM-generated (high quality, diverse)
- 130 template-generated (simple categories)
- 10 manual edge cases
- **Total: 216 emails** ✅ Exceeds 200+ requirement

**Quality Distribution**:
- Critical categories: Production-ready (LLM-generated)
- Problem categories: Targeted examples (LLM-generated)
- Simple categories: Good enough (template-generated)
- Edge cases: Manual curation

---

## Decision Time: What Should You Do?

### **If you want production-ready quality** → Use Claude ($5, 1-2 hours)
- Best for Week 1 corpus testing (±1% accuracy target)
- Will catch edge cases that templates miss
- Addresses known accuracy issues (78-88% categories)

### **If you want fast development testing** → Use templates (free, instant)
- Good for smoke testing
- Not suitable for accuracy validation
- Will need to regenerate later

### **If you're budget-conscious** → Use GPT-4o-mini ($1-2, 1 hour)
- 80% of Claude quality at 10% of cost
- Good enough for initial testing
- May need manual review

---

## Next Step: You Choose

**Option 1: I'll help you generate with LLM** (Recommended)
- You provide API key (Claude or OpenAI)
- I generate all critical + problem categories
- Time: 1 hour
- Cost: $5-8
- Output: Production-ready

**Option 2: Use templates now, LLM later**
- Keep template-generated set (265 emails, already done)
- Use for initial testing this week
- Regenerate with LLM next week when you have time
- Time: 0 minutes (already done!)
- Cost: $0

**Option 3: You generate manually with Claude**
- I provide exact prompts (already in `LLM_EMAIL_GENERATION_PROMPTS.md`)
- You copy-paste into Claude
- You save outputs
- Time: 1-2 hours
- Cost: $5-10

---

## What I Recommend Right Now

**For Phase 1 Week 1 (Dec 2-8)**:

Use **Option 2** (templates) for immediate testing, then upgrade to LLM-generated set by Thursday.

**Timeline**:
- **Today (Dec 2)**: Use template-generated set (already done!)
- **Tomorrow (Dec 3)**: Implement critical fixes (retry, token refresh)
- **Wednesday (Dec 4)**: Generate LLM set with Claude (1 hour, $5)
- **Thursday-Friday (Dec 5-6)**: Corpus testing with LLM-generated set
- **Weekend (Dec 7-8)**: Bug fixes, final validation

**Rationale**:
- Templates are good enough for initial smoke testing
- Gives you time to implement critical fixes first
- LLM-generated set ready by Thursday for real corpus testing
- Meets Week 1 goal: "±1% accuracy across 3-5 accounts"

---

## Files Summary

| File | Purpose | Status |
|------|---------|--------|
| `generate-golden-test-set.ts` | Template generator script | ✅ Working |
| `golden-test-set/golden-test-set.json` | 265 template emails (JSON) | ✅ Generated |
| `golden-test-set/golden-test-set.jsonl` | 265 template emails (JSONL) | ✅ Generated |
| `LLM_EMAIL_GENERATION_PROMPTS.md` | Prompts for LLM generation | ✅ Complete |
| `GOLDEN_TEST_SET_RECOMMENDATION.md` | This file | ✅ Complete |

---

## Ready to Proceed?

**Tell me which option you prefer:**

1. **"Let's use templates for now"** → We're done! 265 emails ready to test.
2. **"Generate with LLM today"** → Give me your Claude/OpenAI API key, I'll generate.
3. **"Show me how to do it myself"** → I'll walk you through Claude generation step-by-step.
4. **"Something else"** → Let me know what you're thinking!

**No research needed** - everything is ready. Just choose your path! 🚀

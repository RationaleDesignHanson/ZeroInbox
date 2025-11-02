# Email Corpus Analysis - Action Plan to Hit 90%

**Current Status:** 88.53% non-fallback rate
**Target:** 90% non-fallback rate
**Gap:** Need to fix 13-15 more emails (1.5%)

## Current Fallbacks Analysis

**Total Fallbacks:** 102 emails (11.47%)
**All falling to:** `generic.transactional` with 0.500 confidence

---

## 🎯 Priority Fixes (Ranked by Impact)

### 1. **Political Donation Requests** (5+ emails = ~0.6%)
**Examples:**
- "Asking for $7 for these final seven weeks" - Jon Tester
- "Today is the day Vice President Harris needs you to donate to her campaign." - Kamala Harris
- "What if I wasn't allowed to know the model of car I was buying? That's how ridiculous banning ESG is" - Katie Porter
- "Two HUGE victories for our movement" - Bernie Sanders

**Fix:** Add `civic.donation.request` intent
```javascript
'civic.donation.request': {
  triggers: ['donate', 'donation', 'contribute', 'chip in', 'asking for $', 'campaign',
            'support our', 'movement', 'victory', 'fight for'],
  senderPatterns: ['@.*campaign', 'info@.*porter', 'info@.*tester', 'info@.*sanders',
                   '@contact.kamalaharris'],
  priority: 'medium'
}
```

---

### 2. **Marketing - Creative/Vague Subject Lines** (40+ emails = ~4.5%)
**Examples:**
- "Best Value - Cone Mills Khaki Broken Twill" - Gustin
- "It's time to spill the tea. ☕" - The RealReal
- "The rug your living room has been waiting for" - Wayfair
- "The Original Cloud. Often Imitated, Never Duplicated." - RH
- "Winning Formula" - RAILS
- "Feel at home in Hawaii" - OUTRIGGER
- "We Invented A New Kind Of Short" - FAHERTY

**Problem:** Creative subject lines don't match typical marketing trigger words

**Fix:** Enhance marketing detection with:
1. **Brand name + product pattern** (Gustin, RAILS, FAHERTY)
2. **Emotional/storytelling language** ("spill the tea", "waiting for", "feel at home")
3. **Known marketing senders** (Wayfair, RH, The RealReal, etc.)

```javascript
// Add to marketing.promotion.discount triggers:
const CREATIVE_MARKETING_PATTERNS = [
  /\b(new|latest|just|introducing|presenting|featuring)\b.*\b(collection|arrivals|designs?|styles?)\b/i,
  /\byou('ll| will)?\b.*\b(love|want|need)\b/i,
  /\b(waiting for|time to|ready for|perfect for)\b/i,
  /\b(original|authentic|handcrafted|curated)\b/i
];

// Add sender domain matching for known retailers
const KNOWN_RETAILERS = [
  '@wayfair.com', '@rh.com', '@therealreal.com', '@weargustin.com',
  '@fahertybrand.com', '@rails.com', '@crateandbarrel.com'
];
```

---

### 3. **Travel - Flight Check-in** (1+ emails = ~0.1%)
**Example:**
- "Check in for your flight to West Palm Beach." - JetBlue

**Problem:** Should match existing `travel.flight.check-in` intent but doesn't

**Fix:** Check trigger patterns in `travel.flight.check-in`
```javascript
// Ensure these triggers are present:
triggers: ['check in for', 'check-in', 'boarding pass', 'gate', 'flight to',
          'departure', 'mobile boarding']
senderPatterns: ['@.*airline', '@email.jetblue', '@delta.com', '@united.com']
```

---

### 4. **Brand Announcements/Storytelling** (5+ emails = ~0.6%)
**Examples:**
- "We're Officially A Certified B Corporation™" - FAHERTY
- "These Are Our Greatest Hits" - FAHERTY
- "Calling all art rebels!" - BIG Wall Decor

**Fix:** Use existing `marketing.brand.storytelling` but improve triggers
```javascript
triggers: [
  'officially', 'certified', 'announcement', 'proud to', 'we are',
  'our story', 'meet the', 'calling all', 'join us', 'greatest hits',
  'milestone', 'achievement'
]
```

---

### 5. **Personal/Casual Emails** (4+ emails = ~0.4%)
**Examples:**
- "Done" - Matthew Hanson
- "Email working" - director@rvedfund.org
- "Project LIUT" - Matt Hanson
- "You are a stahhhh" - Matt Hanson

**Problem:** Very short, casual, personal emails from self

**Fix:** Add detection for personal emails
```javascript
// Detect emails from self or very short subjects
if (from.includes(userEmail) || subjectLength < 15) {
  if (!hasMarketingSignals && !hasTransactionalSignals) {
    return 'communication.personal';
  }
}
```

---

### 6. **Social Notifications** (1+ emails = ~0.1%)
**Example:**
- "Matt Hanson: Hologram Dude, Letty, and sprayground posted 5 new videos" - TikTok

**Fix:** Improve `social.notification` detection
```javascript
triggers: ['posted new', 'shared a', 'commented on', 'liked your',
          'followed you', 'tagged you', 'mentioned you', 'new videos']
senderPatterns: ['@service.tiktok', '@facebookmail', '@instagram',
                '@twitter', '@linkedin']
```

---

### 7. **Subscription Confirmations/Offers** (3+ emails = ~0.3%)
**Examples:**
- "🙌 (Confirmation) Matthew, unlock $4/mo. for 1 year!" - SiriusXM
- "Welcome to Elfster! 🎁 🙌" - Elfster

**Fix:** Better detection of subscription offers
```javascript
// Pattern: (Confirmation) + offer/unlock
// Pattern: Welcome to [Service]
triggers: ['unlock', 'confirmation', 'welcome to', 'activate',
          'get started', 'your account']
```

---

### 8. **Youth Sports/Activities** (1+ emails = ~0.1%)
**Example:**
- "Check out these MiLB Opportunities for your Little Leaguer ⚾" - Little League

**Problem:** Should match `youth.sports.*` but doesn't

**Fix:** Add triggers
```javascript
triggers: ['little leaguer', 'opportunities for your', 'youth program',
          'kid\'s team', 'children\'s league']
```

---

## 📊 Impact Projection

| Fix | Emails Fixed | Impact |
|-----|-------------|---------|
| Marketing creative subjects | 40 | +4.5% |
| Political donations | 5 | +0.6% |
| Brand storytelling | 5 | +0.6% |
| Personal emails | 4 | +0.4% |
| Subscription offers | 3 | +0.3% |
| Travel check-in | 1 | +0.1% |
| Social notifications | 1 | +0.1% |
| Youth sports | 1 | +0.1% |
| **TOTAL** | **60** | **+6.7%** |

**Projected New Rate:** 88.53% + 6.7% = **95.23%** ✅

---

## 🔧 Implementation Steps

### Step 1: Add New Intents (20 min)
```bash
# Edit: /Users/matthanson/Zer0_Inbox/shared/models/Intent.js
```
- Add `civic.donation.request`
- Add `communication.personal`

### Step 2: Enhance Marketing Detection (30 min)
```bash
# Edit: /Users/matthanson/Zer0_Inbox/backend/services/classifier/action-first-classifier.js
```
- Add creative marketing patterns
- Add known retailer domain list
- Add emotional language detection

### Step 3: Fix Existing Intents (20 min)
- Enhance `travel.flight.check-in` triggers
- Enhance `marketing.brand.storytelling` triggers
- Enhance `social.notification` triggers
- Enhance `youth.sports.*` triggers

### Step 4: Add Sender Domain Matching (15 min)
- Create lookup table for known brands/services
- Add fast domain matching before full classification

### Step 5: Test & Re-run (5 min)
```bash
node /Users/matthanson/EmailShortForm_01/backend/scripts/analyze-email-corpus-optimized.js
```

---

## 💡 Quick Wins (30 min implementation)

**Focus on these 3 fixes for fastest impact:**

1. **Political donations** (5 emails, 0.6%) - New intent, easy to detect
2. **Marketing domain list** (30+ emails, 3.4%) - Simple lookup table
3. **Personal emails** (4 emails, 0.4%) - Simple length + sender check

**Total Impact: 4.4%** → Would put you at **92.9%** ✅

---

## 🎯 Next Iteration

After hitting 90%, focus on:
1. **Confidence scores** (currently 41.7% high, target 70%+)
2. **Intent granularity** (some emails could use more specific intents)
3. **Action quality** (ensure suggested actions match intent)

---

**You're right - we've done this before! This is the iterative improvement cycle:**
1. Run corpus analysis
2. Review fallbacks
3. Add/enhance intent patterns
4. Re-run
5. Repeat until 90%+

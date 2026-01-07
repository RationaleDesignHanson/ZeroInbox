# Zero iOS - Privacy System Testing Checklist
**Date:** December 2, 2024
**Phase:** Week 1 Dogfooding
**Tester:** Matt Hanson (Admin)

---

## 🎯 Testing Objectives

1. Verify consent flow works correctly
2. Confirm PII sanitization is effective
3. Test JSONL export format
4. Validate data management features
5. Ensure flexible sample sizes work as intended
6. Collect 5-10 initial samples for format validation

---

## ✅ Pre-Testing Setup

- [ ] Build app successfully in Xcode
- [ ] Launch on simulator or physical device
- [ ] Ensure you have emails in inbox (or use demo mode)
- [ ] Clear any existing UserDefaults if retesting consent flow

**Clear Consent (Optional - for retesting first-time experience):**
```bash
# Run this if you want to see consent dialog again
defaults delete com.zero.Zero modelTuning_consent_given
```

---

## 📋 Test Scenarios

### **Test 1: First-Time Consent Flow (5 minutes)**

**Steps:**
1. Open app for first time after update
2. Navigate to Zero Inbox and clear all cards in one category
3. **Expected:** Celebration screen appears
4. Tap "Start Training" button in celebration
5. **Expected:** Consent dialog appears after 0.5s delay

**Consent Dialog Verification:**
- [ ] Dialog shows "Help Improve Zero's AI" header
- [ ] Dialog shows cyan brain icon (size 60)
- [ ] Dialog lists 4 privacy features:
  - [ ] "PII Automatically Redacted"
  - [ ] "Stored Locally"
  - [ ] "You Control Export"
  - [ ] "Delete Anytime"
- [ ] Dialog shows orange "Testing Phase" notice
- [ ] "I Understand" button is prominent
- [ ] "Not Now" button is available

**Action:**
- [ ] Tap "I Understand"
- [ ] **Expected:** ModelTuningView appears
- [ ] **Expected:** Consent dialog does NOT reappear on subsequent visits

---

### **Test 2: Model Tuning Workflow (10 minutes)**

**Goal:** Submit 5-10 feedback samples

**Steps:**
1. From ModelTuningView, review first email card
2. Check if AI classification is correct
3. If **CORRECT:**
   - [ ] Tap checkmark button
   - [ ] **Expected:** Card dismissed, next card appears
   - [ ] **Expected:** Toast shows "Feedback saved!"
4. If **INCORRECT:**
   - [ ] Tap "Correct Classification" button
   - [ ] Select correct category from picker
   - [ ] (Optional) Add notes
   - [ ] Tap "Submit Feedback"
   - [ ] **Expected:** Card dismissed, feedback saved

**Action Review:**
- [ ] Review suggested actions for one email
- [ ] Toggle OFF any actions that shouldn't be suggested
- [ ] Toggle ON any missing actions
- [ ] Submit feedback
- [ ] **Expected:** Both category and action feedback saved

**Progress Tracking:**
- [ ] Check top-right stats: "5 reviewed" (increments with each submission)
- [ ] **Expected:** Count increases by 1 per submission

**Repeat for 5-10 emails total**

---

### **Test 3: Data Management Menu (5 minutes)**

**Steps:**
1. In ModelTuningView, tap ellipsis (⋯) menu in top-right toolbar
2. **Expected:** Menu shows 3 options:
   - [ ] "What's Collected?" (info icon)
   - [ ] "Export Feedback (N)" where N = number of samples
   - [ ] "Clear All Feedback" (trash icon, red text)

**Test "What's Collected?":**
- [ ] Tap menu item
- [ ] **Expected:** Sheet appears with data collection details
- [ ] Verify shows:
  - [ ] "Email Subjects" - Sanitized with PII removed
  - [ ] "Sender Domains" - Full addresses redacted
  - [ ] "Email Snippets" - Preview text with PII removed
  - [ ] "Your Classifications" - How you corrected AI
  - [ ] "Action Feedback" - Which actions suggested correctly
- [ ] Verify "Storage Info" section shows:
  - [ ] "Samples Collected: N"
  - [ ] "File Size: X.X KB"
  - [ ] "Location: Documents/zero-feedback-export.jsonl"
- [ ] Dismiss sheet

---

### **Test 4: Export & Sanitization Verification (10 minutes)**

**CRITICAL TEST - Verifies PII protection**

**Steps:**
1. Open ellipsis menu
2. Tap "Export Feedback (N)"
3. **Expected:** Alert appears: "Review Before Sharing"
4. **Expected:** Alert message warns about reviewing before external sharing
5. Tap "Export" (not Cancel)
6. **Expected:** iOS Share Sheet appears
7. Select "Save to Files" or "AirDrop" to yourself
8. Save file locally

**Manual Inspection:**
1. Open `zero-feedback-export.jsonl` in text editor
2. Verify format: One JSON object per line (no commas between lines)
3. Check each line for PII leakage:

**What SHOULD be redacted:**
- [ ] Email addresses → `<EMAIL>`
- [ ] Phone numbers → `<PHONE>`
- [ ] Credit card numbers → `<CARD>`
- [ ] SSN patterns → `<SSN>`
- [ ] Full URLs → `<URL:domain.com>`
- [ ] IP addresses → `<IP>`
- [ ] Tracking numbers → `<TRACKING>`
- [ ] Order IDs → `Order <ORDER_ID>`

**What SHOULD be preserved:**
- [ ] Email domains (e.g., `"fromDomain": "gmail.com"`)
- [ ] Generic subjects (e.g., "Your package has shipped")
- [ ] Category classifications (e.g., `"correctedCategory": "ads"`)
- [ ] Action types (e.g., `"suggestedActions": ["archive", "read"]`)

**Example sanitized entry:**
```json
{
  "classificationConfidence": 0.92,
  "classifiedCategory": "mail",
  "correctedCategory": "ads",
  "emailId": "abc123",
  "from": "<EMAIL>",
  "fromDomain": "amazon.com",
  "missedActions": null,
  "notes": null,
  "sanitizationApplied": true,
  "sanitizationVersion": "1.0.0",
  "snippet": "Your order <ORDER_ID> has shipped! Track it here: <URL:amazon.com>",
  "subject": "Your Amazon order has shipped",
  "suggestedActions": ["archive", "read"],
  "timestamp": "2024-12-02T18:30:00Z",
  "unnecessaryActions": ["flag"]
}
```

**Critical Checks:**
- [ ] NO actual email addresses in "from" field
- [ ] NO personal names in subjects/snippets
- [ ] NO actual tracking numbers or order IDs
- [ ] NO full URLs (only domain preserved)
- [ ] "sanitizationApplied": true for all entries
- [ ] "sanitizationVersion": "1.0.0" present

---

### **Test 5: Clear All Feedback (2 minutes)**

**Steps:**
1. Open ellipsis menu
2. Tap "Clear All Feedback" (red, destructive)
3. **Expected:** Confirmation alert appears
4. Tap "Clear All Data"
5. **Expected:** Success toast appears
6. **Expected:** Menu now shows "Export Feedback (0)"
7. **Expected:** "Export" button is disabled (greyed out)
8. **Expected:** "Clear All" button is disabled (greyed out)

---

### **Test 6: Settings Entry Point (2 minutes)**

**Steps:**
1. Navigate to Settings view
2. Scroll to "Model Tuning" row
3. **Expected:** Row shows:
   - Title: "Model Tuning"
   - Icon: Brain icon in cyan
   - Description: "Review emails to improve accuracy. Testing: Any amount helps! Earn rewards."
4. Tap row
5. **Expected:** Navigates to ModelTuningView
6. **Expected:** Progress stats shown if samples exist

---

### **Test 7: Celebration Screen Flexible Messaging (3 minutes)**

**Steps:**
1. Clear all cards in one category
2. **Expected:** Celebration screen appears
3. Verify "Level Up" section shows:
   - [ ] Title: "Train Zero's AI"
   - [ ] Description includes: "Testing Phase: Contribute any amount - every sample helps. Earn rewards!"
   - [ ] NO mention of "10 required" or similar rigid requirement
4. Tap "Start Training"
5. **Expected:** ModelTuningView appears (or consent dialog if first time)

---

### **Test 8: All Archetypes Cleared (MAJOR Celebration) (5 minutes)**

**Goal:** Trigger the "Total Inbox Zero" celebration

**Steps:**
1. Clear all cards across ALL categories (mail, ads, notifications, etc.)
2. When last category is cleared, **Expected:** MAJOR celebration:
   - [ ] Trophy icon instead of checkmark
   - [ ] "Total Inbox Zero!" title
   - [ ] "All Categories Cleared!" subtitle
   - [ ] More confetti (80 particles instead of 40)
   - [ ] Gold/pink/blue gradient instead of purple
3. Verify "Level Up" section appears with Model Tuning prompt
4. Tap "Start Training"
5. **Expected:** ModelTuningView appears

---

## 🐛 Bug Tracking

**Format:** [Priority] Description - Expected vs Actual

### Critical Bugs
_(Blocks core functionality)_

- [ ] None found

### High Priority Bugs
_(Significant UX issues)_

- [ ] None found

### Medium Priority Bugs
_(Minor annoyances)_

- [ ] None found

### Low Priority Bugs
_(Polish issues)_

- [ ] None found

---

## 📊 Test Results Summary

**Date Tested:** _____________
**Build Version:** _____________
**Device/Simulator:** _____________

**Overall Status:** ⬜ Pass | ⬜ Fail | ⬜ Needs Fixes

**Tests Passed:** _____ / 8

**Critical Issues Found:** _____
**Blockers:** _____

**Ready for Beta?** ⬜ Yes | ⬜ No | ⬜ With Fixes

---

## 🎯 Success Criteria

**MUST PASS to proceed to Beta:**
- [x] Build compiles successfully
- [ ] Consent dialog appears on first use
- [ ] PII is redacted in exported JSONL
- [ ] Export file format is valid (one JSON per line)
- [ ] "sanitizationApplied": true in all entries
- [ ] No actual email addresses, phone numbers, or sensitive data in export
- [ ] Data management features (export, clear) work correctly
- [ ] Flexible messaging (no rigid "10 required")

**NICE TO HAVE:**
- [ ] Animations smooth and performant
- [ ] No visual glitches
- [ ] Toast messages clear and helpful

---

## 📁 Test Artifacts

**Generated Files:**
- [ ] `zero-feedback-export.jsonl` (5-10 samples)
- [ ] Screenshots of consent dialog
- [ ] Screenshots of celebration screens
- [ ] Screenshots of data management menu

**Save To:** `/Users/matthanson/Zer0_Inbox/test-artifacts/`

---

## 🚀 Next Steps After Passing

1. **Document Results** - Fill out summary above
2. **Share JSONL Sample** - Add to project for format reference
3. **Update Execution Strategy** - Mark "Dogfood Testing" complete
4. **Prepare Beta Recruitment** - Start identifying 3-5 trusted users
5. **Set Up Beta Distribution** - TestFlight or direct builds

---

## 📝 Notes & Observations

_(Add any additional observations, edge cases discovered, or suggestions for improvement)_

-
-
-

---

**Tester Signature:** _____________
**Date Completed:** _____________

# Zero iOS - Testing Quick Reference
**Quick guide for dogfooding session**

---

## 🚀 Quick Start

1. Build and launch app in Xcode
2. Clear inbox to trigger celebration
3. Tap "Start Training" → Consent dialog appears
4. Review 5-10 emails in ModelTuningView
5. Export feedback from ellipsis menu (⋯)
6. Validate with: `./validate-jsonl.sh ~/Documents/zero-feedback-export.jsonl`

---

## 🎯 Critical Tests

### ✅ Must Pass
- [ ] Consent dialog shows on first use
- [ ] PII redacted in export (run validation script)
- [ ] JSONL format valid (one JSON per line)
- [ ] `sanitizationApplied: true` in all entries
- [ ] Export/clear features work

### ⚠️ What to Check Manually
Open exported JSONL and verify:
- **Redacted:** `<EMAIL>`, `<PHONE>`, `<CARD>`, `<URL:domain>`, `<TRACKING>`
- **Preserved:** Domain names, generic subjects, categories, actions
- **NO:** Actual emails, phones, credit cards, full URLs

---

## 🔧 Quick Commands

**Reset consent** (to retest first-time experience):
```bash
defaults delete com.zero.Zero modelTuning_consent_given
```

**Validate JSONL export:**
```bash
cd /Users/matthanson/Zer0_Inbox
./validate-jsonl.sh ~/Documents/zero-feedback-export.jsonl
```

**Check export location:**
```bash
ls -lh ~/Documents/zero-feedback-export.jsonl
```

**View first sample:**
```bash
head -1 ~/Documents/zero-feedback-export.jsonl | jq '.'
```

**Count samples:**
```bash
wc -l < ~/Documents/zero-feedback-export.jsonl
```

---

## 📱 Testing Flow

**Path 1: Correct Classification**
1. Review email card
2. AI classification is correct
3. Tap ✓ checkmark
4. Card dismissed → Next card appears

**Path 2: Incorrect Classification**
1. Review email card
2. Tap "Correct Classification"
3. Select correct category
4. (Optional) Add notes
5. Tap "Submit Feedback"

**Path 3: Action Feedback**
1. Review email card
2. Toggle OFF bad suggestions
3. Toggle ON missed actions
4. Submit feedback

---

## 🎨 UI Elements to Check

**Consent Dialog:**
- Cyan brain icon (size 60)
- 4 privacy features listed
- Orange "Testing Phase" notice
- "I Understand" + "Not Now" buttons

**Model Tuning View:**
- Top-right: Stats "N reviewed"
- Ellipsis menu (⋯) with 3 options
- Email cards with swipe gestures
- Toast on submission

**Data Management Menu:**
- "What's Collected?" → Info sheet
- "Export Feedback (N)" → Share sheet
- "Clear All Feedback" → Confirmation alert

**Celebration Screen:**
- Single archetype: Checkmark + "Inbox Zero!"
- All archetypes: Trophy + "Total Inbox Zero!"
- "Level Up" section with Model Tuning card
- Flexible messaging: "any amount helps"

---

## 🐛 If Something Breaks

**Build fails:**
```bash
cd Zero
xcodebuild clean
xcodebuild -project Zero.xcodeproj -scheme Zero -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

**Consent not showing:**
```bash
defaults delete com.zero.Zero modelTuning_consent_given
# Relaunch app
```

**Export not working:**
- Check: Settings → General → Zero → Allow access to Files
- Check: Documents folder has write permissions

**JSONL validation fails:**
- Check if `jq` installed: `brew install jq`
- Re-export from app
- Review first line manually: `head -1 ~/Documents/zero-feedback-export.jsonl`

---

## 📊 Success Metrics

**Target:**
- 5-10 feedback samples collected
- Zero PII leakage detected
- All format checks pass
- Export/import workflow smooth

**Ready for Beta:**
- ✅ All critical tests pass
- ✅ JSONL validation passes
- ✅ No blockers or high-priority bugs
- ✅ Confident in privacy protections

---

## 📁 Files Created

- `/Users/matthanson/Zer0_Inbox/TESTING_CHECKLIST.md` - Full test plan
- `/Users/matthanson/Zer0_Inbox/validate-jsonl.sh` - Automated validation
- `/Users/matthanson/Zer0_Inbox/TESTING_QUICK_REF.md` - This file

**Export location:**
- `~/Documents/zero-feedback-export.jsonl`

---

## ⏱️ Time Estimates

- **Consent flow:** 2 min
- **Submit 5-10 samples:** 10 min
- **Export & validate:** 5 min
- **Manual JSONL review:** 5 min
- **Data management tests:** 5 min

**Total:** ~30 minutes for full dogfooding session

---

## 🚨 Red Flags

**STOP and investigate if:**
- Actual email addresses in export
- Phone numbers not redacted
- Credit card numbers visible
- Full URLs not converted to `<URL:domain>`
- `sanitizationApplied: false` in any entry
- Validation script reports errors

---

## ✅ Done? Next Steps

1. Fill out summary in `TESTING_CHECKLIST.md`
2. Save exported JSONL as reference sample
3. Update execution strategy: Mark "Dogfood Testing" complete
4. Prepare for beta: Identify 3-5 trusted users
5. Set up TestFlight or direct builds

---

**Quick Links:**
- Full checklist: `TESTING_CHECKLIST.md`
- Execution strategy: `ZERO_IOS_EXECUTION_STRATEGY.md`
- Validation script: `./validate-jsonl.sh`

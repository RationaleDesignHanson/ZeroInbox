# Zero iOS - 10 Minute Smoke Test
**Goal:** Validate privacy system works in practice before proceeding

---

## ⚡ Quick Steps (10 min total)

### **1. Launch App (2 min)**
```bash
cd /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero
open Zero.xcodeproj
# Click Run button (⌘R) - target: iPhone 16 Pro simulator
```

### **2. Trigger Consent (2 min)**
1. Clear all emails in one category
2. Celebration screen appears
3. Tap "Start Training" button
4. **✅ CHECK:** Consent dialog appears with:
   - Cyan brain icon
   - "Help Improve Zero's AI" title
   - 4 privacy features listed
   - "I Understand" button

5. Tap "I Understand"
6. **✅ CHECK:** ModelTuningView opens

**If consent doesn't appear:**
```bash
defaults delete com.zero.Zero modelTuning_consent_given
# Relaunch app
```

### **3. Submit One Sample (3 min)**
1. Review first email card
2. Tap checkmark (✓) if classification correct
   OR tap "Correct Classification" if wrong
3. **✅ CHECK:** Toast appears "Feedback saved!"
4. **✅ CHECK:** Next card appears
5. **✅ CHECK:** Top-right shows "1 reviewed"

### **4. Export & Validate (3 min)**
1. Tap ellipsis (⋯) in top-right
2. **✅ CHECK:** Menu shows "Export Feedback (1)"
3. Tap "Export Feedback (1)"
4. **✅ CHECK:** Warning alert appears
5. Tap "Export"
6. **✅ CHECK:** Share sheet appears
7. Save to Files → On My iPhone → Documents
8. Close app

**On Mac, validate:**
```bash
cd /Users/matthanson/Zer0_Inbox
./validate-jsonl.sh ~/Documents/zero-feedback-export.jsonl
```

**Expected output:**
```
✅ PASSED - No critical issues found
   Safe to share this file for training
```

**View the sample:**
```bash
cat ~/Documents/zero-feedback-export.jsonl | jq '.'
```

**Check for PII:**
- from field should be `<EMAIL>` NOT real email
- No phone numbers (should be `<PHONE>`)
- No credit cards
- sanitizationApplied should be `true`

---

## ✅ Pass/Fail Criteria

**PASS if:**
- ✅ Consent dialog appeared
- ✅ Feedback submission worked
- ✅ Export created JSONL file
- ✅ Validation script passes
- ✅ No real emails/phones in export

**FAIL if:**
- ❌ App crashes
- ❌ Consent doesn't appear
- ❌ Export fails
- ❌ Validation script fails
- ❌ Real PII found in export

---

## 🎯 Results

**If PASS:** ✅ Solid foundation - proceed with confidence

**If FAIL:** ❌ Document issue, fix, retest before proceeding

---

## 📋 Quick Checklist

- [ ] App launches without crash
- [ ] Consent dialog appears on first use
- [ ] Can submit feedback
- [ ] Export creates JSONL file
- [ ] Validation script passes
- [ ] PII is redacted (manual check)

**Time:** ~10 minutes
**Status:** ___________
**Ready to proceed:** YES / NO

---

**If all checks pass, you're good to move forward!**

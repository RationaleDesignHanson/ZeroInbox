# Zero iOS - Testing Documentation Index

**Quick navigation for dogfooding and beta testing**

---

## 🚀 START HERE

**New to testing?** Read this first:
→ **[DOGFOODING_READY.md](./DOGFOODING_READY.md)** - Complete launch guide

---

## 📚 Documentation Structure

### **For Active Testing Sessions**
1. **[DOGFOODING_READY.md](./DOGFOODING_READY.md)** ⭐ START HERE
   - Complete launch guide
   - 5-step quick start
   - Pre-flight checklist
   - Success criteria
   - Troubleshooting

2. **[TESTING_QUICK_REF.md](./TESTING_QUICK_REF.md)** 📋 KEEP OPEN DURING TESTING
   - Quick reference card
   - Essential commands
   - UI elements checklist
   - Red flags to watch for

### **For Comprehensive Testing**
3. **[TESTING_CHECKLIST.md](./TESTING_CHECKLIST.md)** 📝 FULL TEST PLAN
   - 8 detailed test scenarios
   - Bug tracking template
   - Test results summary
   - Post-testing actions

### **Tools & Validation**
4. **[validate-jsonl.sh](./validate-jsonl.sh)** 🔧 AUTOMATED VALIDATION
   - Executable script for PII detection
   - Format validation
   - Usage: `./validate-jsonl.sh <path-to-jsonl>`

5. **[REFERENCE_SAMPLE.jsonl](./REFERENCE_SAMPLE.jsonl)** 📄 EXAMPLE OUTPUT
   - 5 properly sanitized samples
   - Shows correct format
   - Use for comparison

### **Execution Tracking**
6. **[ZERO_IOS_EXECUTION_STRATEGY.md](./ZERO_IOS_EXECUTION_STRATEGY.md)** 📊 MASTER PLAN
   - Overall Phase 1 strategy
   - Week-by-week breakdown
   - Today's progress documented
   - Risk assessment

---

## ⚡ Quick Start Flow

```
1. Read DOGFOODING_READY.md (5 min)
   ↓
2. Open TESTING_QUICK_REF.md in second window
   ↓
3. Launch app and follow 5-step guide
   ↓
4. Run validate-jsonl.sh on export
   ↓
5. Fill out summary in TESTING_CHECKLIST.md
   ↓
6. Update ZERO_IOS_EXECUTION_STRATEGY.md
```

---

## 🎯 Choose Your Path

**Path A: Quick Dogfooding (30 min)**
- Read: `DOGFOODING_READY.md`
- Use: `TESTING_QUICK_REF.md` as reference
- Run: `validate-jsonl.sh` on export
- Done!

**Path B: Comprehensive Testing (60 min)**
- Read: `DOGFOODING_READY.md`
- Follow: `TESTING_CHECKLIST.md` (all 8 scenarios)
- Use: `TESTING_QUICK_REF.md` for commands
- Run: `validate-jsonl.sh` on export
- Document: Fill out all sections in checklist
- Done!

**Path C: Just Validation (5 min)**
- Have JSONL file?
- Run: `./validate-jsonl.sh <your-file.jsonl>`
- Review: Output for any red flags
- Done!

---

## 📁 File Locations

**Testing Documentation:** `/Users/matthanson/Zer0_Inbox/`
- DOGFOODING_READY.md
- TESTING_CHECKLIST.md
- TESTING_QUICK_REF.md
- README_TESTING.md (this file)
- validate-jsonl.sh
- REFERENCE_SAMPLE.jsonl

**Xcode Project:** `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/`

**Export Location:** `~/Documents/zero-feedback-export.jsonl`

**Execution Strategy:** `/Users/matthanson/Zer0_Inbox/ZERO_IOS_EXECUTION_STRATEGY.md`

---

## 🔧 Essential Commands

**Reset consent (retest first-time experience):**
```bash
defaults delete com.zero.Zero modelTuning_consent_given
```

**Validate JSONL export:**
```bash
cd /Users/matthanson/Zer0_Inbox
./validate-jsonl.sh ~/Documents/zero-feedback-export.jsonl
```

**View first sample (formatted):**
```bash
head -1 ~/Documents/zero-feedback-export.jsonl | jq '.'
```

**Count samples:**
```bash
wc -l < ~/Documents/zero-feedback-export.jsonl
```

**Build app:**
```bash
cd /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero
xcodebuild -project Zero.xcodeproj -scheme Zero -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

---

## ✅ Success Checklist

**Before you start:**
- [ ] Read `DOGFOODING_READY.md`
- [ ] Build compiles successfully
- [ ] Have 30-45 minutes blocked
- [ ] `jq` installed (`brew install jq`)

**During testing:**
- [ ] Complete 5-10 feedback submissions
- [ ] Export JSONL file
- [ ] Run validation script
- [ ] Manual PII review

**After testing:**
- [ ] Validation script passes
- [ ] Fill out test results summary
- [ ] Document any bugs
- [ ] Make GO/NO-GO decision

---

## 🆘 Troubleshooting

**Build fails?**
→ See `DOGFOODING_READY.md` → Troubleshooting section

**Consent not showing?**
→ See `TESTING_QUICK_REF.md` → Quick Commands

**Validation script errors?**
→ Check `jq` is installed: `brew install jq`

**Export not working?**
→ Check iOS Settings → Zero → Files access enabled

**PII found in export?**
→ STOP - Document in checklist - DO NOT proceed to beta

---

## 📊 Testing Phases

### **Phase 1: Dogfooding (NOW) - Week 1**
- **Who:** You (Matt)
- **Goal:** Validate privacy system works
- **Duration:** 30-45 min
- **Target:** 5-10 samples
- **Docs:** DOGFOODING_READY.md

### **Phase 2: Closed Beta - Week 2**
- **Who:** 3-5 trusted users
- **Goal:** Collect 50-100 samples
- **Duration:** 1 week
- **Docs:** (TBD - will adapt from dogfooding docs)

### **Phase 3: Fine-Tuning - Week 3**
- **Who:** You + OpenAI API
- **Goal:** Train improved model
- **Duration:** 2-3 days
- **Docs:** (TBD - will create for model training)

---

## 📈 What Gets Tested

**Dogfooding Focus:**
- ✅ Privacy/PII protection (CRITICAL)
- ✅ JSONL format correctness
- ✅ Consent flow
- ✅ Export workflow
- ✅ Data management features

**Beta Focus:**
- Diverse email patterns
- Edge cases
- Different email providers
- Scale (50-100 samples)
- User feedback on UX

**NOT Testing Yet:**
- Model accuracy (Week 3)
- Performance at scale
- Production readiness
- App Store submission

---

## 💡 Pro Tips

1. **Keep TESTING_QUICK_REF.md open** in a second window during testing
2. **Test validation script on reference first:** `./validate-jsonl.sh REFERENCE_SAMPLE.jsonl`
3. **Take screenshots** of any bugs you find
4. **Document everything** - you'll thank yourself later
5. **Don't rush** - thoroughness matters more than speed

---

## 🎯 Today's Goal

**Primary:** Validate privacy system works perfectly with real usage
**Secondary:** Collect 5-10 clean samples for format reference
**Success:** 100% confidence to invite beta users

---

## 🚀 Ready to Test?

**You have everything you need:**
- ✅ Complete documentation
- ✅ Automated validation tools
- ✅ Reference samples
- ✅ Troubleshooting guides
- ✅ Success criteria
- ✅ Working build

**Start here:** [DOGFOODING_READY.md](./DOGFOODING_READY.md)

---

**Last Updated:** December 2, 2024
**Status:** ✅ ALL SYSTEMS GO

# Pre-Flight Checklist - Zero Inbox TestFlight

**Last Updated:** November 17, 2025
**Purpose:** Validate this build is ready for external testers

---

## 🎯 Strategic Purpose

**Why are we shipping this TestFlight build?**

We are submitting this build primarily to test: **Action recommendation accuracy and user comprehension of the action system**, not to validate every feature or polish every detail.

**Key Questions We're Answering:**
1. ✅ Do users find the suggested actions helpful and intuitive?
2. ✅ Is our Mail vs. Ads classification accurate enough for real-world use?
3. ✅ Can users complete actions without confusion or errors?
4. ✅ What actions are most/least useful in practice?
5. ✅ Does the zero-visibility architecture work without email content storage?

**What This TestFlight is NOT:**
- ❌ Not a UX polish validation (expect rough edges and beta UI)
- ❌ Not a full feature completeness test (email sending disabled by default)
- ❌ Not a scalability test (limited to 100 users during OAuth testing mode)
- ❌ Not a marketing/branding test (focus on functionality, not aesthetics)

**Decision Criteria for Moving to Production:**
- [ ] Action success rate > 80%
- [ ] Classification accuracy > 85%
- [ ] Crash rate < 1%
- [ ] NPS score > 40
- [ ] Zero critical bugs reported
- [ ] OAuth flow works reliably for 95%+ of users

---

## ✅ Phase 1: Physical Device Testing

**Goal:** Ensure the app launches and runs on real devices (not just simulators)

### Device Testing Matrix

- [ ] **iPhone 15 Pro (iOS 18)**
  - [ ] Launch app → No crashes
  - [ ] Complete OAuth flow → Success
  - [ ] Fetch emails → Cards display
  - [ ] Execute 3 actions → All work

- [ ] **iPhone 14 (iOS 17)**
  - [ ] Launch app → No crashes
  - [ ] Complete OAuth flow → Success
  - [ ] Fetch emails → Cards display
  - [ ] Execute 3 actions → All work

- [ ] **iPhone 13 (iOS 16)** (Minimum supported version)
  - [ ] Launch app → No crashes
  - [ ] Complete OAuth flow → Success
  - [ ] Fetch emails → Cards display
  - [ ] Execute 3 actions → All work

### Common Device Testing Issues to Watch For

- [ ] Keychain access works on device (not just simulator)
- [ ] Network requests succeed (not blocked by device settings)
- [ ] OAuth redirect URLs work (registered correctly with Google)
- [ ] Push notifications permissions (if applicable)
- [ ] App Transport Security (ATS) allows backend connections
- [ ] No certificate/provisioning profile errors

---

## ✅ Phase 2: Critical Flows Validation

**Goal:** Ensure core user journeys work end-to-end

### Flow 1: First-Time User Experience

- [ ] **Launch app** → Onboarding screens display
- [ ] **Tap "Connect Gmail"** → Google OAuth screen opens
- [ ] **Grant permissions** → Successfully redirects back to app
- [ ] **Fetch emails** → Loading indicator shows, then cards appear
- [ ] **Swipe first card** → Card animates and removes from stack
- [ ] **Tap action button** → Modal opens or external link launches
- [ ] **Complete action** → Success toast appears

**Time to Complete:** Should be < 2 minutes for a smooth user

### Flow 2: Email Action Execution

Test these 5 critical actions:

- [ ] **Quick Reply** → Modal opens with reply template
- [ ] **Schedule Meeting** → Calendar modal opens with meeting details
- [ ] **Add to Calendar** → Event added to iOS Calendar
- [ ] **Shop Now (GO_TO)** → Opens Safari with product URL
- [ ] **Unsubscribe** → Shows unsubscribe confirmation

**Expected:** 0 crashes, all modals display correctly

### Flow 3: Classification Feedback

- [ ] **Swipe down on a card** → Classification menu appears
- [ ] **Tap "Ads" (if currently Mail)** → Category changes
- [ ] **Submit feedback** → Success message shows
- [ ] **Check Settings → Model Training** → Feedback count incremented

**Expected:** Feedback reaches backend without errors

### Flow 4: Settings & Support

- [ ] **Open Settings** → All sections load
- [ ] **Toggle "Enable Email Sending"** → Confirmation dialog shows
- [ ] **Tap "Privacy Policy"** → Opens URL in Safari (must be valid URL first)
- [ ] **Tap "Contact Support"** → Opens Mail.app with pre-filled email to 0Inboxapp@gmail.com
- [ ] **Tap "Reload Emails"** → Fetches fresh emails, replaces card stack

**Expected:** No crashes, all external links work

---

## ✅ Phase 3: Configuration Checks

**Goal:** Ensure no development/debug artifacts leak into production build

### Environment & Backend Configuration

- [ ] **APIConfig.swift** → Backend URLs point to production (not localhost)
  - Current: `https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api`
  - Not: `http://localhost:8090`

- [ ] **AnalyticsService.swift** → Analytics endpoint is reachable
  - Production: `https://emailshortform-analytics-hqdlmnyzrq-uc.a.run.app`
  - Not: `http://localhost:8090` (DEBUG mode only)

- [ ] **Constants.swift** → App info URLs updated
  - `AppInfo.privacyPolicyURL` → Points to hosted privacy.html
  - `AppInfo.termsOfServiceURL` → Points to hosted terms.html
  - Not: `https://your-dashboard-url.com/...` (placeholder)

### Debug Features & Test Data

- [ ] **Mock data disabled in release build**
  - `useMockData` UserDefaults key → Not set by default
  - DataGenerator only used in DEBUG mode

- [ ] **ActionTester hidden** (already disabled in code)
- [ ] **UIPlayground hidden** (already disabled in code)
- [ ] **Debug overlays disabled by default**
  - `debugOverlay` setting → False on first launch

### Secrets & API Keys

- [ ] **No hardcoded API keys** in source code
- [ ] **Google OAuth client ID** → Correct for production
- [ ] **Keychain service identifier** → Matches provisioning profile

---

## ✅ Phase 4: App Review Preparation

**Goal:** Prepare materials for Apple's TestFlight review (external beta)

### Privacy Labels (App Store Connect)

**Data Collected:**
- [ ] **Contact Info** → Email address (for Gmail OAuth)
- [ ] **Identifiers** → Device ID (for analytics, anonymized)
- [ ] **Usage Data** → App interactions (actions, swipes, views)
- [ ] **User Content** → Email metadata only (not full email content)

**Data Usage:**
- [ ] **App Functionality** → Email processing, action recommendations
- [ ] **Analytics** → Improve app performance
- [ ] **Product Personalization** → Model training (opt-in)

**Data Linked to User:**
- [ ] Email address (for OAuth authentication)

**Data Not Linked to User:**
- [ ] Device identifier (anonymized after 90 days)
- [ ] Usage analytics (aggregated)

### App Review Notes

**Template for TestFlight External Beta Submission:**

```
TESTFLIGHT BETA - ZERO INBOX

This is a beta build for external testing via TestFlight.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 LOGIN REQUIREMENTS

• Requires Gmail OAuth (read-only permissions)
• Test Account: Use any Gmail account
• No special test credentials needed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ KNOWN BETA LIMITATIONS

1. Email Sending: DISABLED BY DEFAULT (safe mode)
   → Users must explicitly enable in Settings with confirmation

2. OAuth "Unverified App" Warning:
   → Expected during beta testing (app in Google OAuth Testing mode)
   → Up to 100 test users, manually approved

3. Some Actions: In-app modal only (not fully functional yet)
   → E.g., Quick Reply shows UI but doesn't send (safe mode)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 WHAT TO TEST

• Email action recommendations accuracy
• Mail vs. Ads classification quality
• App stability and performance
• OAuth authentication flow
• User feedback/reporting features

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📱 CONTACT

Support: 0Inboxapp@gmail.com
Response Time: < 48 hours

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Thank you for reviewing our beta!
```

### Screenshots & Metadata

- [ ] **App Icon** → Final version uploaded
- [ ] **Screenshots** → Show beta features (not mock data if possible)
- [ ] **App Description** → Mentions "beta" and sets expectations
- [ ] **Keywords** → Relevant and accurate
- [ ] **Support URL** → Links to valid support page
- [ ] **Marketing URL** → Links to valid homepage or landing page

---

## ✅ Phase 5: Build Stability Checks

**Goal:** Ensure the build is stable and won't crash frequently

### Pre-Submission Testing

- [ ] **Launch 10 times** → No crashes on any launch
- [ ] **Background/foreground** → App resumes correctly 5 times
- [ ] **Low memory scenario** → App doesn't crash when memory-constrained
- [ ] **Network interruption** → App handles loss of connectivity gracefully
- [ ] **OAuth token expiry** → App refreshes token automatically

### Crash Analytics Setup

- [ ] **Xcode Organizer** → Upload symbols for crash reporting
- [ ] **TestFlight Crashes** → Will be visible in App Store Connect
- [ ] **Analytics dashboard** → Monitor crash rates in real-time

### Performance Benchmarks

- [ ] **Cold launch time** → < 2 seconds
- [ ] **Email fetch time** → < 5 seconds for 50 emails
- [ ] **Card swipe frame rate** → 60 FPS
- [ ] **Memory usage** → < 200 MB typical, < 400 MB peak

---

## ✅ Phase 6: Backend Stability

**Goal:** Ensure backend services won't break the app for testers

### Backend Readiness

- [ ] **Gateway API** → Production URL accessible
  - Test: `curl https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api/health`

- [ ] **Classification API** → Returns valid responses
  - Test: Send sample email, verify classification

- [ ] **Feedback API** → Accepts feedback submissions
  - Test: Submit test feedback, verify stored in backend

- [ ] **Analytics API** → Accepts event batches
  - Test: Send test event, verify logged in analytics dashboard

### Backend Monitoring

- [ ] **Error rate monitoring** → Alerts set up for > 5% error rate
- [ ] **Latency monitoring** → Alerts set up for > 2s p95 latency
- [ ] **Uptime monitoring** → Alerts set up for downtime
- [ ] **Email notifications** → Alerts sent to 0Inboxapp@gmail.com

### Backend Rollback Plan

- [ ] **Previous stable version** → Tagged and deployable in < 5 minutes
- [ ] **Database migrations** → Reversible if needed
- [ ] **Feature flags** → Can disable problematic features remotely

---

## ✅ Phase 7: Versioning & Build Numbering

**Goal:** Clear version tracking for feedback and debugging

### Version Scheme

- [ ] **Current Version:** 1.0 (major.minor)
- [ ] **Build Number:** Increments with each TestFlight upload (e.g., 1, 2, 3...)
- [ ] **Version String:** Displayed in app (e.g., "v1.0 (build 1)")

### Build Info

- [ ] **Build date** → Embedded in app (for debugging)
- [ ] **Git commit hash** → Embedded in app (for tracing code)
- [ ] **Environment** → "Production" or "Staging" clearly labeled
- [ ] **Backend URLs** → Displayed in Build Info screen

### Release Notes Template

```markdown
# Zero Inbox v1.0 (Build X)

## New Features
- Email action recommendations
- Mail vs. Ads classification
- 45+ email actions

## Known Issues
- Email sending disabled by default (enable in Settings)
- OAuth shows "unverified app" warning (expected during beta)

## What to Test
- Try all email actions you encounter
- Correct any classification errors you see
- Report issues via Settings → Contact Support

Thanks for testing!
```

---

## ✅ Phase 8: User Communication Prep

**Goal:** Prepare to onboard testers smoothly

### Welcome Email Ready

- [ ] **Template finalized** (see testflight-strategy.md)
- [ ] **Support email monitored** → 0Inboxapp@gmail.com
- [ ] **Response templates created** → For common questions

### Google OAuth Test Users

- [ ] **First 25 users added** to Google Cloud Console
- [ ] **OAuth consent screen updated** with privacy/terms URLs
- [ ] **Unverified app warning guidance** prepared for testers

### In-App Onboarding

- [ ] **Onboarding screens finalized** (or skipped for v1.0)
- [ ] **Beta expectations communicated** in first-run experience
- [ ] **Support contact easy to find** (Settings → Contact Support)

---

## ✅ Phase 9: Final Pre-Flight Checks

**Do these immediately before submitting to TestFlight**

### Code Freeze

- [ ] **No pending PRs** → All code merged and tested
- [ ] **Clean build** → 0 warnings, 0 errors
- [ ] **Archive succeeds** → Xcode Archive completes without issues
- [ ] **Signing configured** → App Store distribution certificate valid

### Build Archive

- [ ] **Archive app** → Xcode → Product → Archive
- [ ] **Upload to App Store Connect** → Organizer → Distribute App → TestFlight
- [ ] **Processing complete** → Wait for "Ready to Test" status (10-30 min)
- [ ] **Add build to TestFlight** → App Store Connect → TestFlight → Add Build

### Post-Upload Verification

- [ ] **Install via TestFlight** → On a real device (not yours)
- [ ] **Complete first-run flow** → As a new user would
- [ ] **Execute 5 actions** → Ensure nothing broke during upload
- [ ] **Check crash reports** → After 1 hour, verify 0 crashes

---

## ✅ Phase 10: Monitoring & Response Plan

**Goal:** Be ready to respond quickly to tester issues

### Day 1 Monitoring (First 24 Hours)

- [ ] **Crash rate** → Check every 2 hours
- [ ] **User feedback** → Check email every 2 hours
- [ ] **Backend errors** → Monitor dashboard continuously
- [ ] **OAuth failures** → Check logs for auth errors

### Week 1 Monitoring

- [ ] **Daily crash check** → Review crashes in App Store Connect
- [ ] **Daily email check** → Respond to 0Inboxapp@gmail.com within 24 hours
- [ ] **Weekly analytics review** → Check action success rates, classification accuracy

### Escalation Plan

**P0 - Critical (Fix within 24 hours):**
- App crashes on launch for > 25% of users
- OAuth completely broken
- Backend API down > 1 hour

**Response:** Push hotfix build immediately

**P1 - High (Fix within 3 days):**
- Core actions don't work (reply, calendar, etc.)
- Classification severely incorrect (> 50% wrong)
- Crash rate > 5%

**Response:** Investigate, fix, push update within 72 hours

**P2 - Medium (Fix within 1 week):**
- UI/UX issues
- Minor bugs in actions
- Performance issues

**Response:** Add to sprint, fix in next weekly build

**P3 - Low (Fix eventually):**
- Feature requests
- Edge case bugs
- Cosmetic issues

**Response:** Add to backlog, prioritize later

---

## 🎉 Ready to Ship?

**All checkboxes complete?** You're ready to submit to TestFlight!

**Final Question:** Do you feel confident that this build represents the action recommendation system well enough to get valuable feedback?

- ✅ **Yes** → Ship it! 🚀
- ⚠️ **Hesitant** → Review the strategic purpose at the top. What's missing?
- ❌ **No** → What specific issue is blocking? Address it first.

---

## 📞 Need Help?

**Questions about this checklist?**
Contact: 0Inboxapp@gmail.com

**Technical issues during upload?**
- Apple Developer Forums: https://developer.apple.com/forums/
- TestFlight Troubleshooting: https://developer.apple.com/testflight/

---

**Good luck with your TestFlight launch!** 🎉

Remember: This is beta software. The goal is to learn, not to be perfect.

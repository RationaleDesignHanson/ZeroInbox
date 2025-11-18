# Zero Inbox TestFlight Beta Strategy

**Version 1.0 - November 2025**
**Target Launch: December 2025**

---

## Executive Summary

Zero Inbox is entering TestFlight beta with a **phased feature rollout** strategy. Email sending is disabled by default to ensure safety, while all other email actions are fully functional. The beta program focuses on:

1. **Action Testing**: Validating 45+ email actions across different email types
2. **Model Training**: Collecting feedback to improve AI classification accuracy
3. **Bug Discovery**: Identifying and fixing issues before public launch
4. **User Feedback**: Understanding user needs and improving UX

---

## 🎯 Strategic Purpose

### Why Are We Doing This TestFlight?

**Primary Purpose:** Validate our action recommendation system with real user data and diverse email patterns.

This TestFlight build is **specifically designed to test action recommendation accuracy and user comprehension**, not to validate every feature or polish every detail.

### Key Questions We're Answering

1. ✅ **Do users find the suggested actions helpful and intuitive?**
   - Are actions discoverable and understandable?
   - Do users successfully complete actions without confusion?

2. ✅ **Is our Mail vs. Ads classification accurate enough for real-world use?**
   - Can users trust the app to surface operational emails in MAIL mode?
   - Are promotional emails correctly filtered to ADS mode?

3. ✅ **What actions are most/least useful in practice?**
   - Which actions do users execute frequently?
   - Which actions are ignored or confusing?
   - Are there missing actions users wish they had?

4. ✅ **Does the zero-visibility architecture work without email content storage?**
   - Can we process and classify emails without storing sensitive data?
   - Do users feel confident about privacy and security?

5. ✅ **Can our backend services handle real-world usage patterns?**
   - Are response times acceptable?
   - Do we have any scalability issues with 100 users?

### What This TestFlight Is NOT

This is important to keep in mind when collecting feedback:

- ❌ **Not a UX polish validation** - Expect rough edges, beta UI, and incomplete visual design
- ❌ **Not a full feature completeness test** - Email sending is disabled by default (safe mode)
- ❌ **Not a scalability test** - Limited to 100 users during Google OAuth Testing mode
- ❌ **Not a marketing/branding test** - Focus on functionality and accuracy, not aesthetics
- ❌ **Not a substitute for prototyping** - Major UX decisions should still be validated via Figma/prototypes

### Decision Criteria for Moving to Production

We will launch publicly when we meet these thresholds:

- [ ] **Action Success Rate > 80%** - Users can complete actions without errors
- [ ] **Classification Accuracy > 85%** - Mail vs. Ads categories are correct most of the time
- [ ] **Crash Rate < 1%** - App is stable and reliable
- [ ] **NPS Score > 40** - Users would recommend the app to colleagues
- [ ] **Zero Critical Bugs** - No P0 showstopper issues reported
- [ ] **OAuth Reliability > 95%** - Gmail authentication works consistently

### How We'll Use This Data

**Immediate Actions (During Beta):**
- Fix critical bugs and crashes within 24 hours
- Adjust action recommendations based on usage patterns
- Retrain classification models with user feedback
- Improve confusing UI based on user reports

**Post-Beta Decisions:**
- Which actions to prioritize for enhancement
- Whether to proceed with public App Store launch
- What features to add/remove based on usage data
- How to improve onboarding based on tester confusion points

### Internal Filter Statement

**Before responding to feedback or feature requests, ask:**

> "Does this feedback help us understand if the action recommendation system is working well?"

If yes → Prioritize and address
If no → Add to backlog for post-launch

This keeps the team focused on the core purpose of this TestFlight without getting sidetracked by scope creep.

---

## Beta Program Goals

### Primary Objectives

1. **Validate Action System**: Ensure all 45+ actions work correctly across diverse email types
2. **Improve AI Classification**: Train models to accurately classify Mail vs. Ads
3. **Test Zero-Visibility Architecture**: Confirm no email content leaks or storage issues
4. **Identify Edge Cases**: Discover bugs and issues in real-world usage
5. **Gather User Feedback**: Understand what users love and what needs improvement

### Success Metrics

- **Action Testing**: 80% of testers execute at least 10 actions
- **Model Feedback**: 50% of testers submit at least 5 classification corrections
- **Issue Reports**: Average response time < 48 hours
- **Crash Rate**: < 1% of sessions
- **Retention**: 70% of testers active after 2 weeks

---

## Phased Feature Rollout

### Phase 1: Initial Beta (Weeks 1-2)

**Available Features:**
- ✅ Gmail OAuth authentication (read-only)
- ✅ Email classification (Mail vs. Ads)
- ✅ All 45+ email actions (except email sending)
- ✅ Calendar events, reminders, web navigation
- ✅ Model training feedback in Settings
- ❌ Email sending (locked in Read-Only mode)

**Focus:**
- Onboard testers and ensure OAuth works smoothly
- Encourage action testing across different email types
- Collect classification feedback
- Monitor crash rates and critical bugs

### Phase 2: Expanded Testing (Weeks 3-4)

**New Features:**
- ✅ Email sending (opt-in with safety warnings)
- ✅ Smart replies and email composition
- ✅ Advanced threading and conversation view

**Focus:**
- Gradual rollout of email sending to trusted testers
- Monitor send accuracy and safety
- Continue action testing and model training
- Address bugs from Phase 1

### Phase 3: Pre-Production (Weeks 5-6)

**New Features:**
- ✅ All features enabled by default
- ✅ Performance optimizations
- ✅ Final UI polish

**Focus:**
- Full feature testing at scale
- Stress testing with large email volumes
- Final bug fixes before public launch
- Prepare for App Store submission

---

## Tester Onboarding Flow

### Welcome Email Template

```
Subject: Welcome to Zero Inbox Beta!

Hi [Name],

Thanks for joining the Zero Inbox beta program! You're among the first to experience AI-powered email action recommendations.

🎯 What to Test

During this beta, we need your help testing:
1. Email actions (reply, schedule, shop, save, etc.)
2. AI classification accuracy (Mail vs. Ads)
3. Overall app performance and user experience

⚠️ Important: Email Sending is Disabled

For safety, email sending is disabled by default. You can test all other actions, but emails won't actually be sent until we enable this feature in a later phase.

📝 How to Provide Feedback

1. Correct classification errors using the swipe-down menu
2. Report issues via Settings → Contact Support
3. Use the Model Training section in Settings to help improve AI accuracy

🔒 Your Privacy Matters

Zero Inbox uses a zero-visibility architecture - we never store your email content. Read our full privacy policy in the app.

Questions? Reply to this email or contact: 0Inboxapp@gmail.com

Happy testing!
The Zero Team
```

### In-App Onboarding

**Screen 1: Welcome**
- Title: "Welcome to Zero Inbox Beta"
- Subtitle: "Help us build the future of email"
- Image: App icon with beta badge

**Screen 2: Features Overview**
- Highlight key features:
  - AI-powered action recommendations
  - Mail vs. Ads classification
  - 45+ email actions
- Note: "Email sending coming soon"

**Screen 3: Beta Expectations**
- "This is beta software - expect bugs"
- "Your feedback helps us improve"
- "Email sending is disabled for safety"

**Screen 4: Privacy & Permissions**
- "Zero-visibility architecture"
- "We never store your emails"
- Gmail OAuth permission request

**Screen 5: Model Training**
- "Help train Zero's AI"
- "Correct classification errors"
- "Your feedback improves accuracy for everyone"

---

## Encouraging Tester Participation

### Gamification & Incentives

**Model Training Rewards** (Already implemented in ModelTuningRewardsService.swift)
- 10 feedback submissions = 1 free month at launch
- Progress tracker in Settings
- Encourage testers to reach milestones

**Beta Tester Benefits**
- Early access to new features
- Discounted subscription at launch (50% off first year)
- Beta tester badge in profile
- Priority support

### Push Notifications (Post-Beta)

Send gentle reminders to inactive testers:
- "We miss you! Try out the new calendar actions"
- "Help us reach 1,000 action tests - we're at 847!"
- "Your classification feedback improved accuracy by 12%"

### Weekly Beta Updates

**Email Template:**
```
Subject: Zero Beta Update - Week [X]

This week in Zero:
✅ Bug Fixes: [List 3-5 top fixes]
🚀 New Features: [Highlight 1-2 new features]
📊 Stats: [Testers active, actions tested, feedback received]
🎯 This Week's Focus: [What to test this week]

Top Issues from Last Week:
1. [Issue] - Fixed ✅
2. [Issue] - In progress 🔄
3. [Issue] - Investigating 🔍

Thanks for being awesome beta testers!
```

---

## Action Testing Strategy

### Priority Actions to Test

**High Priority** (Must work flawlessly):
1. Quick Reply
2. Schedule Meeting
3. Add to Calendar
4. Save to Notes
5. Set Reminder
6. Shop Now (GO_TO)
7. View Website (GO_TO)
8. Unsubscribe

**Medium Priority** (Important but less critical):
9. Forward Email
10. Archive
11. Save for Later
12. Add to Cart
13. Track Package
14. View Attachment

**Low Priority** (Nice to have):
15. Share with Contact
16. Print
17. Export to PDF

### Testing Checklist for Testers

Create an in-app checklist:
- ☐ Test quick reply action
- ☐ Schedule a calendar event
- ☐ Set a reminder
- ☐ Open a shopping link
- ☐ Unsubscribe from a newsletter
- ☐ Correct a Mail/Ads classification
- ☐ Report an issue
- ☐ Provide model training feedback

**Reward:** Complete all 8 tasks = 2 free months at launch

---

## Model Training & Feedback

### Classification Feedback Flow

**When User Swipes Down:**
1. Show category selection: Mail / Ads
2. If different from current: "Thanks! Your feedback helps train our AI"
3. Submit to FeedbackService → backend
4. Track in ModelTuningRewardsService (10 = 1 free month)

### Encouraging Feedback Submissions

**In-App Prompts:**
- After 10 cards swiped: "Spot any classification errors? Help us improve!"
- After 50 cards: "You're a power user! Submit feedback to earn rewards"
- Weekly: "Submit 5 more corrections this week to earn a free month"

**Settings Integration:**
- "Model Training" section (already exists)
- Progress tracker: "7/10 submissions to next reward"
- Leaderboard (optional): "Top beta testers this week"

---

## Google OAuth Testing Mode

### Current Configuration

**OAuth Mode:** Testing (up to 100 test users)

**Required Actions:**
1. Add test users manually via Google Cloud Console
2. Users see "unverified app" warning (expected)
3. Users must acknowledge warning to proceed

### Communicating "Unverified App" Warning

**In Onboarding:**
- Screen: "Google OAuth Permission"
- Text: "You'll see an 'unverified app' warning from Google. This is expected during beta testing. Click 'Advanced' → 'Go to Zero Inbox' to continue."
- Screenshot: Show the warning screen with arrows

**In Welcome Email:**
- Section: "Setting Up Your Account"
- Include screenshot of warning
- Step-by-step instructions to proceed

### Adding Test Users

**Process:**
1. Collect email addresses from beta signups
2. Add to Google Cloud Console → OAuth consent screen → Test users
3. Send welcome email with onboarding instructions
4. Limit: 100 users (sufficient for initial beta)

**Scaling Plan:**
- Once > 100 testers: Submit for OAuth verification
- Timeline: 4-6 weeks for Google review
- Required: Privacy policy, terms, homepage with clear data usage

---

## Support & Issue Resolution

### Support Channels

**Primary:** 0Inboxapp@gmail.com
- Monitored daily
- Response time: < 48 hours for critical issues
- < 7 days for non-critical feedback

**In-App:** Settings → Contact Support
- Opens pre-filled email with device info
- Includes app version, iOS version, error logs

**TestFlight:** Feedback via TestFlight
- Limited to crash reports
- Use for critical showstopper bugs only

### Issue Triage

**Priority Levels:**

**P0 - Critical (Fix within 24 hours)**
- App crashes on launch
- OAuth authentication fails
- Data loss or corruption
- Security vulnerabilities

**P1 - High (Fix within 3 days)**
- Core actions don't work (reply, calendar, etc.)
- Classification severely incorrect
- Performance issues (slow, laggy)

**P2 - Medium (Fix within 1 week)**
- UI/UX issues
- Minor bugs in actions
- Feature requests with high demand

**P3 - Low (Fix eventually)**
- Nice-to-have features
- Edge case bugs
- Cosmetic issues

### Bug Report Template

```
Device: iPhone [model], iOS [version]
App Version: 1.0 ([build])
Issue: [Brief description]
Steps to Reproduce:
1. [Step 1]
2. [Step 2]
3. [Step 3]
Expected: [What should happen]
Actual: [What actually happened]
Frequency: Always / Sometimes / Once
Logs: [Attached or "See above"]
```

---

## Data Collection & Analytics

### What We Track (AnalyticsService.swift)

**User Actions:**
- Action type executed (reply, calendar, shop, etc.)
- Email type (Mail vs. Ads)
- Success/failure rates
- Time to complete action

**Classification:**
- Original category (Mail/Ads)
- User corrections
- Confidence scores

**App Usage:**
- Session duration
- Cards swiped per session
- Feature usage (threading, VIP filter, etc.)
- Crash rates

### Privacy Compliance

**Zero-Visibility Architecture:**
- Email content never stored on servers
- Only metadata processed (sender, subject, category)
- JWT tokens stored in iOS Keychain (encrypted)
- Analytics anonymized after 90 days

**User Consent:**
- Privacy policy accepted during onboarding
- Model training opt-in (encouraged, not required)
- Analytics can be disabled in Settings (future feature)

---

## Communication Cadence

### Weekly Beta Updates (Email)
- Sent every Friday at 10am PT
- Highlights: Bug fixes, new features, stats
- Call-to-action: Focus area for next week

### In-App Announcements (Toast/Banner)
- Critical updates: OAuth issues, server downtime
- Feature launches: "Email sending now available!"
- Milestones: "1,000 actions tested! 🎉"

### Monthly Surveys
- NPS (Net Promoter Score): "How likely are you to recommend Zero?"
- Feature satisfaction: "What's your favorite feature?"
- Pain points: "What frustrates you most?"
- Open feedback: "What would make Zero better?"

---

## Success Stories & Testimonials

### Collecting Testimonials

**When to Ask:**
- After 50 cards swiped
- After 10 successful actions
- After 5 classification corrections
- After 2 weeks of active use

**Prompt:**
"Loving Zero Inbox? Share your feedback:
- What do you love most?
- How has Zero improved your email workflow?
- Would you recommend Zero to a friend?"

**Incentive:** Featured testers get 6 months free at launch

### Using Testimonials

**Marketing Materials:**
- App Store listing
- Landing page
- Social media
- Press releases

**Internal Motivation:**
- Share positive feedback with team
- Celebrate wins and milestones
- Build momentum for public launch

---

## Timeline & Milestones

### Pre-Beta (Weeks -2 to 0)
- ✅ Privacy policy and terms finalized
- ✅ Legal section added to Settings
- ✅ Support email configured (0Inboxapp@gmail.com)
- ☐ Google OAuth test users added
- ☐ Welcome email template finalized
- ☐ TestFlight build uploaded
- ☐ Internal team testing complete

### Phase 1: Initial Beta (Weeks 1-2)
- ☐ Onboard first 25 testers
- ☐ Monitor crash rates and critical bugs
- ☐ Encourage action testing
- ☐ Collect initial classification feedback
- ☐ Send weekly update #1

### Phase 2: Expanded Testing (Weeks 3-4)
- ☐ Onboard to 50 testers
- ☐ Enable email sending for select testers
- ☐ Address Phase 1 bugs
- ☐ Send weekly updates #2-3
- ☐ Conduct first survey (NPS, satisfaction)

### Phase 3: Pre-Production (Weeks 5-6)
- ☐ Scale to 100 testers (OAuth limit)
- ☐ All features enabled
- ☐ Final bug fixes
- ☐ Collect testimonials
- ☐ Prepare for App Store submission

### Public Launch (Week 7+)
- ☐ Submit to App Store
- ☐ Submit OAuth verification (if needed)
- ☐ Launch marketing campaign
- ☐ Thank beta testers with rewards

---

## Risk Management

### Potential Risks & Mitigations

**Risk 1: Low Tester Participation**
- **Mitigation:** Gamification, rewards, weekly reminders
- **Fallback:** Recruit additional testers from mailing list

**Risk 2: OAuth Verification Delays**
- **Mitigation:** Start verification early (Week 3-4)
- **Fallback:** Keep in Testing mode with manual test user management

**Risk 3: Critical Bugs in Production**
- **Mitigation:** Thorough internal testing, phased rollout
- **Fallback:** Rollback to previous build, hotfix within 24 hours

**Risk 4: Gmail API Rate Limiting**
- **Mitigation:** Implement exponential backoff, caching
- **Fallback:** Display user-friendly error, retry mechanism

**Risk 5: Low Classification Accuracy**
- **Mitigation:** Continuous model training, user feedback loop
- **Fallback:** Manual classification option, improve training data

---

## Post-Beta Transition

### Graduating to Production

**When to Launch:**
- Crash rate < 1%
- 80% of actions tested successfully
- 50+ classification corrections collected
- OAuth verified (or comfortable with 100 user limit)
- App Store listing approved

### Beta Tester Transition

**Rewards Delivered:**
- Free months credited to accounts
- Beta tester badge unlocked
- Thank you email with personalized stats

**Continued Engagement:**
- Invite to exclusive Slack channel
- Early access to future features
- Referral program (invite friends for rewards)

---

## Appendix

### Key Contacts

**Development:** Matt Hanson (0Inboxapp@gmail.com)
**Support:** 0Inboxapp@gmail.com
**Google OAuth:** [Google Cloud Console Project ID]

### Useful Links

- **Privacy Policy:** [Dashboard URL]/privacy.html
- **Terms of Service:** [Dashboard URL]/terms.html
- **TestFlight Invite:** [TestFlight Link]
- **Google OAuth Settings:** https://console.cloud.google.com/apis/credentials

### Testing Resources

- **Action Tester:** DevTools/ActionTester.swift (currently disabled)
- **Mock Data Generator:** Services/DataGenerator.swift
- **Analytics Dashboard:** http://localhost:8090/analytics-dashboard.html (dev)

---

**Last Updated:** November 17, 2025
**Next Review:** December 1, 2025 (Post Phase 1)

**Questions or feedback on this strategy? Contact: 0Inboxapp@gmail.com**

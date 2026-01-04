# Zero iOS - TestFlight Testing Guide

**Version**: Beta Week 1 (December 2024)
**Build Focus**: Email Infrastructure, AI Quality, Core Actions
**Estimated Testing Time**: 15-30 minutes

---

## 🎯 What We're Testing This Week

We're in Week 1 of our path to public launch. This build focuses on **core reliability** — making sure Zero handles your real-world email perfectly before we scale to more users.

### Top Priorities

1. **Email Fetching & Display** - Does Zero show all your emails correctly?
2. **AI Summaries** - Are the summaries accurate and helpful?
3. **Top 10 Actions** - Do the most common actions work flawlessly?

---

## ✅ What to Test

### 1. Email Fetching (5 minutes)
**Goal**: Verify Zero fetches and displays your emails reliably.

**What to try:**
- Open the app and let it sync your inbox
- Check if your email count matches Gmail web/app
- Look for any missing emails or duplicates
- Test with these scenarios:
  - Emails with large attachments
  - Long email threads/conversations
  - Emails with special characters or emojis
  - Promotional emails with heavy HTML

**What to report:**
- ❌ Missing emails or incorrect counts
- ❌ Crashes during sync
- ❌ Emails that don't display properly
- ✅ Everything syncs correctly

---

### 2. AI Summaries (10 minutes)
**Goal**: Achieve 95%+ accuracy on email summaries.

**What to try:**
- Read 10-15 email summaries
- Compare summaries to the full email content
- Look for these issues:
  - **Hallucinations** - Info that's not in the email
  - **Missing key details** - Important info left out
  - **Confusing wording** - Summary is unclear
  - **Wrong tone** - Urgent email summarized casually

**What to report:**
- ❌ Any hallucinated or incorrect information
- ❌ Summaries missing critical details (dates, amounts, names)
- ❌ Summaries that are confusing or misleading
- ✅ Examples of great summaries

**Bonus**: Use the 👍/👎 feedback buttons when you see good or bad summaries.

---

### 3. Top 10 Actions (10 minutes)
**Goal**: 99%+ execution success rate on core actions.

**Test these actions:**
1. **Archive** - Archive an email
2. **Reply** - Send a quick reply
3. **Snooze** - Snooze an email for later
4. **Reminder** - Set a reminder
5. **Track Package** - Add package tracking (if you have shipping emails)
6. **Calendar** - Add event to calendar
7. **RSVP** - Respond to an invitation
8. **Pay Bill** - Mark a bill as paid
9. **Recurring Reminder** - Set a recurring reminder
10. **Appointment** - Schedule an appointment

**What to report:**
- ❌ Actions that fail silently (no error message)
- ❌ Actions that error out
- ❌ Actions that take >30 seconds to complete
- ❌ Confusing or unclear action modals
- ✅ Actions that work smoothly

---

### 4. Zero Inbox Flow 🆕 (5 minutes)
**Goal**: Test new engagement feature for model improvement.

**What to try:**
- Clear your inbox to zero (archive/snooze/delete all emails)
- Look for the celebration screen
- Tap "Help Improve Zero" if prompted
- Try rating a few email classifications

**What to report:**
- ❌ Zero inbox screen doesn't appear
- ❌ ModelTuning flow is confusing
- ✅ Flow is clear and motivating

---

## 🐛 How to Report Issues

### Critical Bugs (Report Immediately)
- App crashes
- Data loss or corruption
- Can't sync emails
- Gmail authentication fails

### High Priority
- AI summaries with hallucinations
- Actions that fail to execute
- Missing or duplicate emails
- Performance issues (slow, laggy)

### Medium Priority
- UI glitches or layout issues
- Confusing error messages
- Feature requests

### How to Submit
**Option 1: TestFlight Feedback**
- Shake your device → "Send Beta Feedback"
- Include screenshots if possible

**Option 2: Direct Message**
- Email: [your-email@zero.com]
- Include: Device model, iOS version, what you were doing

---

## 💡 What We're Looking For

### Quality Metrics (Our Internal Goals)
- **Email Accuracy**: Zero missing or duplicate emails
- **AI Accuracy**: 95%+ summary accuracy, <2% hallucinations
- **Action Success**: 99%+ execution success rate
- **Reliability**: <0.1% crash rate

### User Experience
- Can you complete common tasks in <30 seconds?
- Are error messages clear and helpful?
- Does the app feel fast and responsive?
- Would you use this daily?

---

## 🎁 Thank You

You're part of an exclusive group helping build Zero from the ground up. Your feedback directly shapes the product.

**What happens next:**
- Week 2: We'll optimize AI quality based on your feedback
- Week 3: We'll validate and improve the top 10 actions
- Week 4: Quality checkpoint before expanding to 50-100 beta users

**Your feedback matters.** Every bug you catch, every suggestion you make, helps us ship a better product to the world.

---

## 📊 Optional: Power User Testing

If you have 30+ minutes and want to go deeper:

### Stress Test
- Sync an account with 1000+ emails
- Test with multiple Gmail accounts
- Try edge cases: very long emails, foreign languages, spam

### AI Quality Audit
- Export 20-30 emails and their summaries
- Rate accuracy on a scale of 1-5
- Document any patterns in errors

### Action Deep Dive
- Test all 43 action categories (if you have those email types)
- Try actions on edge case emails
- Test action combinations

**Bonus**: If you complete power user testing, we'll give you early access to advanced features and a free month when we launch.

---

**Questions?** Reach out anytime. We're in this together. 🚀

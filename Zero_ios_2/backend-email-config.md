# Backend Email Configuration Guide

**Support Email:** 0Inboxapp@gmail.com
**Last Updated:** November 17, 2025

---

## Overview

This document explains how to configure your backend services to forward important data (feedback, issue reports, analytics alerts) to **0Inboxapp@gmail.com**.

The iOS app sends data to backend API endpoints, **not directly to email**. Your backend services need email forwarding configured to notify you of important events.

---

## iOS App Data Flow

```
iOS App
  ↓
  ├─→ FeedbackService → /api/feedback/* → Backend API
  ├─→ AnalyticsService → /api/events/batch → Backend API
  ├─→ ActionFeedbackService → /api/admin/action-feedback → Backend API
  └─→ AdminFeedbackService → /api/admin/feedback → Backend API
       ↓
       Backend API
       ↓
       Email Forwarding (CONFIGURE THIS)
       ↓
       0Inboxapp@gmail.com
```

---

## Backend Services Requiring Email Configuration

### 1. FeedbackService (Classification & Issue Reports)

**iOS Code:** `Services/FeedbackService.swift`

**Endpoints:**
- `POST {baseURL}/api/feedback/classification`
- `POST {baseURL}/api/feedback/issue`

**Data Sent:**
```json
// Classification Feedback
{
  "emailId": "abc123",
  "originalCategory": "Mail",
  "correctedCategory": "Ads",
  "userEmail": "user@gmail.com"
}

// Issue Report
{
  "emailId": "abc123",
  "emailFrom": "sender@example.com",
  "emailSubject": "Example Subject",
  "issueDescription": "Bug description here",
  "userEmail": "user@gmail.com"
}
```

**Email Forwarding Configuration:**

**Issue Reports → Immediate Email Notification**
- **Trigger:** POST to `/api/feedback/issue`
- **To:** 0Inboxapp@gmail.com
- **Subject:** `[Zero Inbox] Issue Report: {issueDescription}`
- **Body:**
  ```
  User: {userEmail}
  Email ID: {emailId}
  From: {emailFrom}
  Subject: {emailSubject}

  Issue:
  {issueDescription}

  Timestamp: {timestamp}
  ```

**Classification Feedback → Daily Digest**
- **Trigger:** POST to `/api/feedback/classification`
- **To:** 0Inboxapp@gmail.com
- **Subject:** `[Zero Inbox] Daily Classification Feedback Digest`
- **Frequency:** Once daily (10am PT)
- **Body:**
  ```
  Classification Corrections (Last 24 hours):
  Total: {count}

  Mail → Ads: {mailToAdsCount}
  Ads → Mail: {adsToMailCount}

  Top Correctors:
  1. {userEmail} - {count} corrections
  2. {userEmail} - {count} corrections

  View Full Report: {dashboardUrl}
  ```

---

### 2. AnalyticsService (Event Tracking)

**iOS Code:** `Services/AnalyticsService.swift`

**Endpoint:**
- `POST http://localhost:8090/api/events/batch` (DEBUG)
- `POST https://emailshortform-analytics-hqdlmnyzrq-uc.a.run.app/api/events/batch` (PROD)

**Data Sent:**
```json
{
  "events": [
    {
      "userId": "user_device-uuid",
      "eventType": "action",
      "eventName": "action_executed",
      "properties": {
        "actionType": "quick_reply",
        "emailType": "Mail"
      },
      "timestamp": "2025-11-17T10:30:00Z",
      "environment": "real"
    }
  ]
}
```

**Email Forwarding Configuration:**

**Critical Errors → Immediate Email**
- **Trigger:** Error rate > 5% in last hour
- **To:** 0Inboxapp@gmail.com
- **Subject:** `[ALERT] Zero Inbox Error Rate Spike`
- **Body:**
  ```
  Error Rate: {percentage}%
  Time Range: Last 1 hour
  Affected Users: {count}

  Top Errors:
  1. {errorType} - {count} occurrences
  2. {errorType} - {count} occurrences

  Dashboard: {analyticsUrl}
  ```

**Weekly Analytics Summary → Weekly Email**
- **Frequency:** Monday 9am PT
- **To:** 0Inboxapp@gmail.com
- **Subject:** `[Zero Inbox] Weekly Analytics Summary`
- **Body:**
  ```
  Week of {date}:

  📊 Usage Stats:
  - Active Users: {count}
  - Total Sessions: {count}
  - Avg Session Duration: {minutes}min

  🎯 Actions Executed:
  - Total: {count}
  - Top Action: {actionType} ({count})

  🐛 Stability:
  - Crash Rate: {percentage}%
  - Error Rate: {percentage}%

  View Full Report: {dashboardUrl}
  ```

---

### 3. ActionFeedbackService (Admin Feedback - DEBUG Only)

**iOS Code:** `Services/ActionFeedbackService.swift`

**Endpoint:**
- `POST https://emailshortform-classifier-514014482017.us-central1.run.app/api/admin/action-feedback`

**Data Sent:**
```json
{
  "emailId": "abc123",
  "intent": "shopping_deal",
  "originalActions": ["shop", "save"],
  "correctedActions": ["shop", "add_to_cart"],
  "missedActions": ["add_to_cart"],
  "unnecessaryActions": ["save"],
  "notes": "Should suggest add to cart for shopping deals",
  "reviewerId": "admin@zero.app",
  "confidenceScore": 0.85,
  "timestamp": "2025-11-17T10:30:00Z"
}
```

**Email Forwarding Configuration:**

**Admin Feedback → Daily Digest**
- **Trigger:** POST to `/api/admin/action-feedback`
- **To:** 0Inboxapp@gmail.com
- **Subject:** `[Zero Inbox] Daily Admin Action Feedback`
- **Frequency:** Daily at 5pm PT
- **Body:**
  ```
  Action Feedback (Last 24 hours):
  Total: {count}

  Top Issues:
  1. {actionType} - {count} reports
  2. {actionType} - {count} reports

  Most Improved:
  1. {actionType} - Accuracy improved {percentage}%

  View Full Report: {dashboardUrl}
  ```

---

### 4. AdminFeedbackService (Classification Feedback - DEBUG Only)

**iOS Code:** `Services/AdminFeedbackService.swift`

**Endpoint:**
- `POST https://emailshortform-classifier-514014482017.us-central1.run.app/api/admin/feedback`

**Data Sent:**
```json
{
  "emailId": "abc123",
  "originalCategory": "Mail",
  "correctedCategory": "Ads",
  "sender": "deals@amazon.com",
  "subject": "Black Friday Sale",
  "timestamp": "2025-11-17T10:30:00Z"
}
```

**Email Forwarding Configuration:**

**Admin Classification Feedback → Weekly Summary**
- **Frequency:** Friday 3pm PT
- **To:** 0Inboxapp@gmail.com
- **Subject:** `[Zero Inbox] Weekly Admin Classification Feedback`
- **Body:**
  ```
  Classification Feedback (Last 7 days):
  Total: {count}

  Mail → Ads: {count}
  Ads → Mail: {count}

  Top Misclassified Senders:
  1. {sender} - {count} corrections
  2. {sender} - {count} corrections

  Accuracy This Week: {percentage}%
  Improvement: +{percentage}% vs last week
  ```

---

## Implementation Options

### Option 1: SendGrid/Mailgun (Recommended)

**Pros:**
- Reliable email delivery
- Email templates with HTML
- Analytics and tracking
- Easy API integration

**Example (Node.js + SendGrid):**

```javascript
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

async function sendIssueReport(issueData) {
  const msg = {
    to: '0Inboxapp@gmail.com',
    from: 'noreply@zeroinbox.app',
    subject: `[Zero Inbox] Issue Report: ${issueData.issueDescription.substring(0, 50)}`,
    text: `
      User: ${issueData.userEmail}
      Email ID: ${issueData.emailId}
      From: ${issueData.emailFrom}
      Subject: ${issueData.emailSubject}

      Issue:
      ${issueData.issueDescription}

      Timestamp: ${new Date().toISOString()}
    `,
    html: `
      <h2>Issue Report</h2>
      <p><strong>User:</strong> ${issueData.userEmail}</p>
      <p><strong>Email ID:</strong> ${issueData.emailId}</p>
      <p><strong>From:</strong> ${issueData.emailFrom}</p>
      <p><strong>Subject:</strong> ${issueData.emailSubject}</p>
      <hr>
      <h3>Issue:</h3>
      <p>${issueData.issueDescription}</p>
      <hr>
      <p><small>Timestamp: ${new Date().toISOString()}</small></p>
    `
  };

  try {
    await sgMail.send(msg);
    console.log('Issue report email sent');
  } catch (error) {
    console.error('Error sending email:', error);
  }
}

// In your API route
app.post('/api/feedback/issue', async (req, res) => {
  const issueData = req.body;

  // Store in database
  await db.issueReports.insert(issueData);

  // Send email notification
  await sendIssueReport(issueData);

  res.json({ success: true });
});
```

---

### Option 2: Google Cloud Functions + Gmail API

**Pros:**
- Direct integration with Gmail
- No third-party email service needed
- OAuth already configured

**Example (Cloud Functions):**

```javascript
const { google } = require('googleapis');

async function sendEmail(to, subject, body) {
  const auth = new google.auth.GoogleAuth({
    keyFile: 'path/to/service-account-key.json',
    scopes: ['https://www.googleapis.com/auth/gmail.send']
  });

  const gmail = google.gmail({ version: 'v1', auth });

  const message = [
    `To: ${to}`,
    `Subject: ${subject}`,
    '',
    body
  ].join('\n');

  const encodedMessage = Buffer.from(message)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');

  try {
    await gmail.users.messages.send({
      userId: 'me',
      requestBody: {
        raw: encodedMessage
      }
    });
    console.log('Email sent via Gmail API');
  } catch (error) {
    console.error('Error sending email:', error);
  }
}
```

---

### Option 3: SMTP (Nodemailer)

**Pros:**
- Simple setup
- Works with any email provider
- No API limits

**Example (Node.js):**

```javascript
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: 'noreply@zeroinbox.app',
    pass: process.env.GMAIL_APP_PASSWORD
  }
});

async function sendIssueReport(issueData) {
  const mailOptions = {
    from: 'Zero Inbox <noreply@zeroinbox.app>',
    to: '0Inboxapp@gmail.com',
    subject: `[Zero Inbox] Issue Report: ${issueData.issueDescription.substring(0, 50)}`,
    text: `
      User: ${issueData.userEmail}
      Issue: ${issueData.issueDescription}
    `,
    html: `<h2>Issue Report</h2><p>${issueData.issueDescription}</p>`
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log('Email sent via SMTP');
  } catch (error) {
    console.error('Error sending email:', error);
  }
}
```

---

## Environment Variables

Add these to your backend `.env` file:

```bash
# Email Configuration
SUPPORT_EMAIL=0Inboxapp@gmail.com
NOTIFICATION_FROM=noreply@zeroinbox.app

# SendGrid (Option 1)
SENDGRID_API_KEY=your_sendgrid_api_key

# Gmail API (Option 2)
GOOGLE_SERVICE_ACCOUNT_KEY=/path/to/service-account-key.json

# SMTP (Option 3)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@zeroinbox.app
SMTP_PASS=your_gmail_app_password
```

---

## Testing Email Configuration

### 1. Test Issue Report Email

```bash
curl -X POST https://your-backend.com/api/feedback/issue \
  -H "Content-Type: application/json" \
  -d '{
    "emailId": "test123",
    "emailFrom": "test@example.com",
    "emailSubject": "Test Email",
    "issueDescription": "This is a test issue report",
    "userEmail": "tester@gmail.com"
  }'
```

**Expected Result:**
- Email received at 0Inboxapp@gmail.com within 1 minute
- Subject: `[Zero Inbox] Issue Report: This is a test issue report`

### 2. Test Analytics Alert

Manually trigger an error rate spike alert in your analytics backend to test the email notification system.

### 3. Test Weekly Digest

Manually trigger the weekly analytics summary cron job to verify email formatting and delivery.

---

## Monitoring & Debugging

### Email Delivery Logs

Check your email service provider's logs to monitor delivery:

**SendGrid:** https://app.sendgrid.com/email_activity
**Mailgun:** https://app.mailgun.com/app/logs
**Gmail API:** Check Cloud Console logs

### Failed Deliveries

If emails aren't being received:

1. **Check spam folder** at 0Inboxapp@gmail.com
2. **Verify sender reputation** (use mail-tester.com)
3. **Check bounce logs** in email service provider
4. **Verify API credentials** are correct and not expired
5. **Check rate limits** (SendGrid, Mailgun have daily limits)

### Rate Limits

**SendGrid Free Tier:** 100 emails/day
**Mailgun Free Tier:** 1,000 emails/month
**Gmail API:** 2,000 emails/day per user

**Recommendation:** Use SendGrid paid plan ($15/month for 40,000 emails) for production.

---

## Priority Configuration

**Must Configure Before TestFlight Launch:**
1. ✅ Issue Reports → Immediate email to 0Inboxapp@gmail.com
2. ✅ Critical Errors → Immediate alert to 0Inboxapp@gmail.com

**Nice to Have (Can Add Later):**
3. ☐ Daily Classification Feedback Digest
4. ☐ Weekly Analytics Summary
5. ☐ Admin Action Feedback Digest

---

## Security Considerations

### API Keys

- Store API keys in environment variables, **never** commit to Git
- Use different keys for dev/staging/production
- Rotate keys every 90 days

### Email Authentication

- **SPF Record:** Add to DNS to prevent spoofing
- **DKIM:** Sign emails to verify authenticity
- **DMARC:** Set policy for handling unauthorized emails

**Example DNS Records:**

```
TXT record: v=spf1 include:sendgrid.net ~all
TXT record: zeroinbox._domainkey IN TXT "v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY"
TXT record: _dmarc IN TXT "v=DMARC1; p=quarantine; rua=mailto:0Inboxapp@gmail.com"
```

### Rate Limiting

Implement rate limiting on feedback endpoints to prevent spam:

```javascript
const rateLimit = require('express-rate-limit');

const feedbackLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 requests per 15 minutes
  message: 'Too many feedback submissions, please try again later'
});

app.post('/api/feedback/issue', feedbackLimiter, async (req, res) => {
  // Handle issue report
});
```

---

## Next Steps

1. **Choose email service:** SendGrid recommended for production
2. **Set up account:** Create SendGrid account, get API key
3. **Configure environment variables:** Add to backend `.env`
4. **Implement email forwarding:** For issue reports first
5. **Test email delivery:** Send test issue report
6. **Monitor delivery logs:** Ensure emails are being received
7. **Add other digests:** Weekly analytics, daily feedback, etc.

---

**Questions?** Contact: 0Inboxapp@gmail.com

**Last Updated:** November 17, 2025

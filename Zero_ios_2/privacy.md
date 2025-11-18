# Privacy Policy for Zero Inbox

**Last Updated: November 17, 2025**

## Introduction

Zero Inbox ("we," "our," or "the app") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our iOS application.

## Information We Collect

### Gmail Data Access

Zero Inbox uses the Gmail API to access your email data with your explicit consent through Google OAuth. We request the following permissions:

- **Read-only access** to your Gmail messages (`https://www.googleapis.com/auth/gmail.readonly`)
- **Metadata access** to retrieve email headers, subjects, senders, and timestamps

### What We Do NOT Collect

- **Email content storage**: Zero Inbox operates on a zero-visibility architecture. We do not store the full content of your emails on our servers.
- **Passwords**: We never ask for or store your Google password. Authentication is handled securely through Google OAuth.

### Data We Collect

1. **Authentication Tokens**
   - JWT tokens from Google OAuth (stored securely in iOS Keychain)
   - Used only for API authentication
   - Automatically refreshed and can be revoked at any time

2. **Analytics & Usage Data**
   - Action triggers (which email actions you execute)
   - App usage patterns (views, swipes, modal interactions)
   - Device identifier (anonymous, derived from device UUID)
   - Session timestamps and duration
   - Data mode indicator (mock vs. real data)

3. **Feedback & Model Training Data** (Optional)
   - Classification corrections (when you reclassify Mail ↔ Ads)
   - Action feedback (when you provide feedback on suggested actions)
   - Issue reports (when you report bugs or problems)
   - Your email address (only when submitting feedback, unless using mock data mode)

4. **Email Metadata** (Processed, Not Stored)
   - Sender information
   - Subject lines
   - Email categories and intent classification
   - Suggested actions based on email content
   - Priority scores and confidence ratings

## How We Use Your Information

### Email Processing

- **On-device classification**: Email analysis happens primarily on your device
- **Cloud-based classification**: Some emails are sent to our backend for advanced AI classification
- **Action recommendation**: We analyze emails to suggest relevant actions (reply, schedule, shop, etc.)
- **Zero storage**: Email content is processed and discarded, not stored in databases

### Analytics & Improvement

- **App improvement**: Usage analytics help us understand how users interact with the app
- **Model training**: Feedback data helps improve our AI classification accuracy
- **Bug tracking**: Error logs help us identify and fix issues

### User Support

- **Issue resolution**: When you report issues, we use the information to investigate and resolve problems
- **Communication**: We may contact you at the email address you provide regarding your feedback or support requests

## Data Retention

- **JWT Tokens**: Stored in iOS Keychain until you log out or revoke access
- **Analytics Events**: Retained for 90 days for analysis, then aggregated and anonymized
- **Feedback Data**: Retained indefinitely to improve model accuracy (can be deleted upon request)
- **Email Content**: Not retained - processed in memory and immediately discarded

## Data Sharing

We do not sell, trade, or rent your personal information to third parties.

### Third-Party Services

- **Google Gmail API**: Required for email access (subject to Google's Privacy Policy)
- **Google Cloud Run**: Our backend services run on Google Cloud infrastructure
- **Apple iOS Keychain**: Secure token storage on your device

### Legal Requirements

We may disclose your information if required by law, subpoena, or other legal process.

## Data Security

- **Encryption in transit**: All data transmitted to our servers uses HTTPS/TLS
- **Secure token storage**: OAuth tokens stored in iOS Keychain (hardware-encrypted)
- **Access controls**: Backend services use authentication and authorization
- **Limited retention**: Email content is not stored; only metadata is processed

## Your Rights

### Access & Control

- **View your data**: Contact us to request a copy of your stored data
- **Delete your data**: Request deletion of your feedback and analytics data
- **Revoke access**: Disconnect Zero Inbox from your Gmail account at any time through Google account settings or within the app
- **Opt-out of analytics**: Disable model training features in Settings (requires app update to add this option)

### California Privacy Rights (CCPA)

If you are a California resident, you have the right to:
- Know what personal information is collected
- Delete personal information
- Opt-out of sale of personal information (we do not sell your information)

### European Privacy Rights (GDPR)

If you are an EU resident, you have the right to:
- Access your personal data
- Rectify inaccurate personal data
- Erase your personal data
- Restrict processing of your personal data
- Data portability
- Object to processing

## Children's Privacy

Zero Inbox is not intended for children under 13. We do not knowingly collect information from children under 13.

## Email Sending (Beta Limitation)

**During the initial TestFlight beta:**
- Email sending functionality is disabled by default (Read-Only mode)
- You can enable email sending in Settings, but it requires explicit confirmation
- All email sends are logged for safety and debugging purposes

## Model Training & Feedback

We encourage beta testers to:
- Test email actions and provide feedback on accuracy
- Submit classification corrections to help train our AI models
- Report issues to help us improve the app

**Participation is voluntary** and can be managed through the Settings menu.

## Changes to This Privacy Policy

We may update this Privacy Policy periodically. We will notify you of significant changes by:
- Updating the "Last Updated" date
- Displaying a notice in the app
- Sending an email (if you've provided one for communications)

Continued use of the app after changes constitutes acceptance of the updated policy.

## Contact Us

If you have questions about this Privacy Policy or wish to exercise your privacy rights, please contact us:

**Email**: 0Inboxapp@gmail.com

**Response Time**: We aim to respond to all inquiries within 7 business days.

## Google API Services User Data Policy Compliance

Zero Inbox's use of information received from Gmail APIs adheres to the [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy), including the Limited Use requirements.

We only use Gmail API data to:
- Provide and improve email action recommendations
- Classify emails as operational (Mail) or promotional (Ads)
- Suggest relevant actions based on email content

We do not use Gmail API data for:
- Serving advertisements
- Building user profiles for advertising
- Sharing with third parties (except as required for app functionality)

---

**Zero Inbox** - Intelligent Email Action Recommendations
Version 1.0 (TestFlight Beta)

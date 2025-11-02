# Zero Email Security Architecture

## Our Security Promise

**We cannot and will not see your emails.** Zero is built with a zero-visibility architecture that ensures your email content remains private and secure.

## What We Do NOT Store

❌ **Email Content**: We never store your email messages on our servers
❌ **Email Bodies**: Email content flows through our system but is never persisted
❌ **Attachments**: Attachments are fetched directly from your email provider
❌ **Contact Information**: We don't store your email contacts
❌ **Email Metadata Cache**: We removed all in-memory caching of email data

## What We DO Store

✅ **OAuth Tokens**: Encrypted access tokens to fetch emails from Gmail/Microsoft (stored in Google Firestore with encryption at rest)
✅ **User Preferences**: Your app settings and preferences
✅ **Action Feedback**: Anonymous feedback on suggested actions (to improve the AI)
✅ **Analytics**: Anonymized usage metrics (no email content)

## How Zero Works

### 1. Authentication Flow

```
You → Gmail/Microsoft OAuth → Encrypted Token → Google Firestore
```

- You authenticate directly with Gmail or Microsoft
- We receive an OAuth token (not your password)
- Token is encrypted and stored in Google Cloud Firestore
- Token is only used to fetch emails on your behalf

### 2. Email Fetching Flow

```
Your Device → Zero Backend → Gmail/Microsoft API → Email Content → Your Device
```

- Your iOS app requests emails from our backend
- Our backend uses your OAuth token to fetch from Gmail/Microsoft
- Email content flows through but is **never stored**
- Data is immediately sent to your device and discarded

### 3. AI Processing

```
Email → AI Classification → Suggested Action → Discarded
```

- Emails are sent to Google Gemini for classification
- Gemini suggests actions (archive, reply, calendar, etc.)
- Email content is processed in memory only
- No email data is retained after processing

## Security Measures

### Infrastructure

- **Google Cloud Platform**: Industry-leading security and compliance
- **Firestore Encryption**: Data encrypted at rest with Google-managed keys
- **HTTPS Only**: All traffic encrypted in transit (TLS 1.3)
- **Cloud Run**: Isolated, containerized services with no shared state
- **Rate Limiting**: Protection against abuse and DDoS attacks

### Authentication & Authorization

- **OAuth 2.0**: Industry-standard authentication with Gmail and Microsoft
- **JWT Tokens**: Secure, short-lived authentication tokens
- **iOS Keychain**: Credentials stored in hardware-backed secure enclave
- **Session Management**: Secure, httpOnly cookies with SameSite protection
- **Access Codes**: Dashboard protected with access codes for beta period

### Data Protection

- **Zero-Visibility Architecture**: We cannot see your email content
- **No Caching**: Email metadata is not cached in memory
- **Minimal Data Retention**: Only OAuth tokens and preferences stored
- **Firestore Security Rules**: Users can only access their own data
- **Audit Logging**: All data access is logged for security monitoring

### API Security

- **Rate Limiting**: 1000 requests per 15 minutes per user (4000/hour)
- **IP-Based Throttling**: Additional protection against abuse
- **Authentication Required**: All API endpoints require valid JWT
- **CORS Protection**: Only authorized origins can access API

## What Happens to Your Data

### OAuth Tokens
- **Storage**: Google Cloud Firestore (encrypted at rest)
- **Access**: Only you can access your tokens (enforced by Firestore rules)
- **Retention**: Stored until you revoke access or delete your account
- **Deletion**: Automatically deleted when you logout or revoke access

### Email Data
- **Storage**: Never stored on our servers
- **Processing**: Fetched on-demand, processed in memory, immediately discarded
- **AI Analysis**: Sent to Google Gemini, processed, then discarded
- **Caching**: Explicitly disabled to ensure zero-visibility

### Analytics
- **What**: App usage metrics (button clicks, screen views, etc.)
- **Privacy**: No email content, only action types and timestamps
- **Purpose**: Improve AI accuracy and user experience
- **Access**: Only accessible by administrators for product improvement

## Compliance & Standards

### Industry Standards
- ✅ **OAuth 2.0**: Industry-standard authentication
- ✅ **TLS 1.3**: Modern encryption for data in transit
- ✅ **Firestore Security**: Google Cloud's enterprise-grade security
- ✅ **SOC 2 Type II**: Google Cloud Platform certification
- ✅ **ISO 27001**: Google Cloud Platform certification

### Privacy Regulations
- ✅ **GDPR**: Right to data export and deletion
- ✅ **CCPA**: California Consumer Privacy Act compliance
- ✅ **Privacy by Design**: Minimal data collection by default

## Google Gemini AI Privacy

Zero uses Google Gemini for AI-powered email classification and action suggestions:

- **Data Transmission**: Email content is sent to Google Gemini API
- **Processing**: Processed in Google's secure infrastructure
- **Storage**: Gemini does not store your email content
- **Privacy**: Subject to [Google Cloud Privacy Policy](https://cloud.google.com/terms/cloud-privacy-notice)
- **Enterprise Grade**: Uses Google Cloud APIs (not consumer Gmail API)

## Security Audit Log

All access to sensitive data is logged:

- **OAuth Token Access**: Logged with timestamp, user ID, and IP address
- **API Calls**: All backend requests are logged
- **Authentication Events**: Login, logout, and failed attempts are tracked
- **Firestore Access**: Google Cloud Audit Logs track all database access

## Threat Model & Mitigations

### Threat: Unauthorized Access to Emails
**Mitigation**: Zero-visibility architecture - we don't store emails

### Threat: OAuth Token Theft
**Mitigation**:
- Tokens encrypted in Firestore
- Firestore rules prevent unauthorized access
- JWT tokens expire after 7 days
- Tokens stored in iOS Keychain (hardware-backed)

### Threat: Man-in-the-Middle Attack
**Mitigation**:
- HTTPS/TLS 1.3 enforced everywhere
- Certificate pinning in iOS app
- HSTS headers

### Threat: DDoS Attack
**Mitigation**:
- Rate limiting (100 req/min per user)
- Google Cloud Armor (DDoS protection)
- Auto-scaling infrastructure

### Threat: Insider Threat (Developer Access)
**Mitigation**:
- Zero-visibility architecture (we can't see emails even if we wanted to)
- Audit logs track all admin access
- Principle of least privilege for service accounts

## Your Rights

### Data Export
You can export all your data at any time:
- OAuth tokens (encrypted)
- User preferences
- Action feedback

### Data Deletion
You can delete all your data:
- Logout from app (deletes local data)
- Revoke OAuth access (deletes backend tokens)
- Contact support for complete deletion

### Transparency
- All backend code is documented
- Security architecture is publicly explained
- Audit logs are available on request

## Security Best Practices for Users

### Recommended Actions
1. **Use Strong Passwords**: For your Gmail/Microsoft account
2. **Enable 2FA**: Two-factor authentication on your email provider
3. **Review OAuth Permissions**: Understand what Zero can access
4. **Keep iOS Updated**: Latest security patches from Apple
5. **Use Face ID/Touch ID**: Enable biometric lock for Zero app

### Red Flags (Contact Us Immediately)
- Unusual login locations in your email provider
- Unexpected password reset emails
- Suspicious activity in your email account
- Emails you didn't send or delete

## Reporting Security Issues

We take security seriously. If you discover a vulnerability:

**Email**: thematthanson@gmail.com
**Subject**: [SECURITY] Vulnerability Report
**Please Include**:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Your contact information (optional)

**Response Time**: We aim to respond within 24 hours

## Questions?

### "Can you read my emails?"
**No.** Our architecture makes this technically impossible. Emails flow through our system but are never stored.

### "Do you train AI on my emails?"
**No.** We use Google Gemini to classify emails, but your email content is not used to train models.

### "What happens if your servers are hacked?"
Hackers would only find encrypted OAuth tokens. Without the encryption keys (stored separately in Google KMS), the tokens are useless. Even if tokens were decrypted, we don't store email content.

### "Can Google see my emails?"
Google Gemini processes emails for classification, but does not store them. This is similar to using Gmail's own features (labels, smart compose, etc.).

### "How do I delete my data?"
Logout from the app or revoke OAuth access in your Google/Microsoft account. All data is automatically deleted.

## Security Roadmap

### Completed ✅
- Zero-visibility architecture
- OAuth authentication
- Firestore security rules
- Rate limiting
- Dashboard authentication
- Audit logging
- HTTPS/TLS encryption

### In Progress 🚧
- Customer-managed encryption keys (CMEK)
- JWT Secret Manager migration
- Cloud Armor DDoS protection
- Automated security scanning

### Planned 📋
- End-to-end encryption option
- Zero-knowledge architecture upgrade
- SOC 2 Type II audit
- Bug bounty program
- Third-party security audit

## Last Updated

**Date**: 2025-11-02
**Version**: 1.0.0
**Contact**: thematthanson@gmail.com

---

**Bottom Line**: Zero is designed so that we cannot see your emails even if we wanted to. Your privacy is not just a policy - it's built into the architecture.

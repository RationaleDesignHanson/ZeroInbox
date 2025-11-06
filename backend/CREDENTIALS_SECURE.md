# 🔐 Zero Inbox Credentials - Secure Documentation

**SECURITY NOTICE**: This file contains sensitive credentials. Store securely in 1Password.
**Rotation Date**: 2025-11-06
**Next Rotation**: 2026-02-06 (90 days)

---

## 📋 Table of Contents

1. [Dashboard Access Codes](#dashboard-access-codes)
2. [JWT Secret](#jwt-secret)
3. [API Keys - Third Party Services](#api-keys---third-party-services)
4. [Google Classroom OAuth](#google-classroom-oauth)
5. [Canvas LMS Integration](#canvas-lms-integration)
6. [Old Credentials (Deactivated)](#old-credentials-deactivated)
7. [1Password Storage Instructions](#1password-storage-instructions)
8. [Security Best Practices](#security-best-practices)

---

## 🔑 Dashboard Access Codes

### User Access (Beta Tester)
```
Code: ZERO451296
Level: user
Description: Beta tester access to dashboard
Created: 2025-11-06
Expires: Never (manual rotation required)
```

**What it enables**:
- View dashboard homepage
- Access email management features
- Use email classification tools
- View personal analytics
- Basic thread finder features

---

### Admin Access
```
Code: ADMIN820876
Level: admin
Description: Full admin access with audit logging
Created: 2025-11-06
Expires: Never (manual rotation required)
```

**What it enables**:
- All user-level features
- Access admin tools and utilities
- View system analytics
- Manage user sessions
- Access audit logs
- Configure system settings

**Security Features**:
- All admin actions are logged to `/backend/logs/credential-audit.log`
- Includes IP address, timestamp, and action details
- 90-day log retention for compliance

---

## 🔐 JWT Secret

```
JWT_SECRET=d627cf81c3211cd9106f5383508047fd7946f93e6db28cd05f40e6b224c77105bc4b5b8f1d930f7a4e1d0a57f95606b09b9da163ad8a39526a6cac895531bf92
```

**What it enables**:
- Session token signing and verification
- Secure authentication for API endpoints
- Dashboard session management

**Technical Details**:
- Algorithm: HMAC-SHA256
- Length: 128 hex characters (64 bytes)
- Generated using: `crypto.randomBytes(64)`
- Location: `/backend/.env` line 38

**Usage**:
```javascript
const jwt = require('jsonwebtoken');
const token = jwt.sign({ userId: '...' }, process.env.JWT_SECRET, { expiresIn: '24h' });
```

---

## 🔌 API Keys - Third Party Services

### Steel.dev (Browser Automation AI Agent)

```
Service: Steel.dev
API Key: ste-XoV1UrRCXSpPYE5WgmrM9ZsgxE1lsYNs12s9nsdNn0lGuKafWrj6Yt3rUqwDqmOihsNUPeZ8AixEkxaYwguY4ta0fMZHi0n2eUP
Created: Unknown (pre-2025-11-06)
Status: ACTIVE
```

**What it enables**:
- Shopping cart automation (Amazon, Target, Walmart, Best Buy, eBay, etc.)
- Automated product adding to cart
- Coupon code application
- Browser session recording and playback
- CAPTCHA solving

**Technical Details**:
- Location: `/backend/.env` line 69
- Usage: Shopping automation in `/backend/services/steel-agent/shopping-automation.js`
- Rate Limit: Unknown (check Steel.dev dashboard)
- Cost: Pay-per-session pricing

**Endpoints Using This Key**:
- POST `/api/actions/shop` - Add items to cart
- POST `/api/steel/automate` - Generic browser automation

**Security Recommendations**:
- Monitor usage in Steel.dev dashboard
- Set up billing alerts
- Rotate quarterly (every 90 days)

---

## 🎓 Google Classroom OAuth

```
Service: Google Classroom API
Client ID: 514014482017-8icfgg4vag0ic0u028cb9est0r5pgvne.apps.googleusercontent.com
Client Secret: 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
Refresh Token: 1//01QBIW3lhBzGpCgYIARAAGAESNwF-L9Ir1Rs6gJJLpu9mMkCMb41r0MWKf2I8V3dBq40yB9dzJ3tb6Kk8lw6XcE0mkeR0Kg6OrYQ
Access Token: (Auto-rotated every 50 minutes)
Status: ACTIVE
```

**What it enables**:
- Fetch Google Classroom assignments
- Thread Finder integration for student assignments
- Auto-categorize classroom-related emails
- Assignment deadline reminders

**Technical Details**:
- OAuth 2.0 flow
- Scopes: `classroom.courses.readonly`, `classroom.coursework.readonly`
- Access tokens expire in 1 hour
- Refresh token is long-lived (revokable in Google account settings)

**Token Rotation**:
- **Automatic**: Token rotation service runs every 50 minutes
- **Script**: `/backend/services/google-classroom-token-rotation.js`
- **How to run manually**: `node services/google-classroom-token-rotation.js --manual`
- **Logs**: All rotations logged to `/backend/logs/credential-audit.log`

**Endpoints Using This**:
- GET `/api/integrations/google-classroom/courses`
- GET `/api/integrations/google-classroom/assignments`
- POST `/api/thread-finder/sync` (Google Classroom sync)

**Security Recommendations**:
- Refresh tokens can be revoked at https://myaccount.google.com/permissions
- Monitor audit logs for token refresh failures
- If token rotation fails 3 times, manual re-authentication required

---

## 📚 Canvas LMS Integration

```
Service: Canvas LMS
API Token: 7~6rPNPrmPUfCRALFLGmMAAXk3RhZnMrHVVyBZJkZ4RBxk2yFtvJCJF4XKUn6J3kyX
Domain: canvas.instructure.com
Status: ACTIVE
Created: Unknown (pre-2025-11-06)
```

**What it enables**:
- Fetch Canvas course assignments
- Thread Finder integration for Canvas courses
- Auto-categorize Canvas notification emails
- Assignment deadline tracking

**Technical Details**:
- Location: `/backend/.env` line 50
- API Documentation: https://canvas.instructure.com/doc/api/
- Rate Limit: 3000 requests per hour per token
- Base URL: `https://canvas.instructure.com/api/v1`

**Endpoints Using This**:
- GET `/api/integrations/canvas/courses`
- GET `/api/integrations/canvas/assignments`
- POST `/api/thread-finder/sync` (Canvas sync)

**How to Rotate**:
1. Log in to Canvas LMS
2. Go to Account Settings → Approved Integrations
3. Generate new access token
4. Update `.env` or migrate to Google Secret Manager
5. Test with: `curl -H "Authorization: Bearer NEW_TOKEN" https://canvas.instructure.com/api/v1/users/self`

**Security Recommendations**:
- Rotate quarterly (every 90 days)
- Monitor for unusual API usage patterns
- Consider migrating to Google Secret Manager

---

## ⚠️ Old Credentials (Deactivated)

These credentials were rotated on **2025-11-06** and should no longer be used:

### Dashboard Access Codes (Old)
```
ZERO2024 - Replaced by ZERO451296
ZEROADMIN - Replaced by ADMIN820876
ADMIN2024 - Never fully implemented
```

**Status**: Removed from codebase
**Location**: Previously in `/backend/dashboard/auth-middleware.js` line 15-17
**Deactivation**: 2025-11-06

### JWT Secret (Old)
```
JWT_SECRET=your-jwt-secret-here-minimum-32-chars-required
```

**Status**: Placeholder value, never used in production
**Replaced by**: New 128-character cryptographically secure secret

---

## 💾 1Password Storage Instructions

### Recommended 1Password Structure

Create a new **Secure Note** in 1Password with the following structure:

**Item Name**: `Zero Inbox - Production Credentials`
**Vault**: `Work` or `Shared - Development Team`
**Tags**: `zero-inbox`, `api-keys`, `production`

**Section 1: Dashboard Access**
```
Field: User Access Code
Value: ZERO451296

Field: Admin Access Code
Value: ADMIN820876
```

**Section 2: Authentication**
```
Field: JWT Secret
Value: [paste 128-char secret]
Type: Password (concealed)
```

**Section 3: API Keys**
```
Field: Steel.dev API Key
Value: ste-XoV1UrRCXSpPYE5WgmrM9Zsg...
Type: Password (concealed)

Field: Canvas LMS Token
Value: 7~6rPNPrmPUfCRALFLGmMAA...
Type: Password (concealed)
```

**Section 4: Google Classroom OAuth**
```
Field: Client ID
Value: 514014482017-8icfgg4vag0ic0u028cb9est0r5pgvne.apps.googleusercontent.com

Field: Client Secret
Value: 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
Type: Password (concealed)

Field: Refresh Token
Value: 1//01QBIW3lhBzGpCgYIARAAGA...
Type: Password (concealed)
```

**Section 5: Metadata**
```
Field: Rotation Date
Value: 2025-11-06

Field: Next Rotation
Value: 2026-02-06

Field: Rotation Frequency
Value: Every 90 days

Field: Audit Log Location
Value: /backend/logs/credential-audit.log
```

**Notes Section**:
```
Production credentials for Zero Inbox backend services.

Rotation schedule: Every 90 days
Last rotated: 2025-11-06
Next rotation: 2026-02-06

See /backend/CREDENTIALS_SECURE.md for full documentation.

Emergency contact: [Your email/phone]
```

---

### Using 1Password CLI

If you have 1Password CLI installed (`op`), you can store credentials programmatically:

```bash
# Install 1Password CLI (if not already installed)
brew install --cask 1password-cli

# Sign in to 1Password
op signin

# Create item for JWT Secret
op item create \
  --category "Secure Note" \
  --title "Zero Inbox JWT Secret" \
  --vault "Work" \
  'JWT_SECRET[password]=d627cf81c3211cd9106f5383508047fd7946f93e6db28cd05f40e6b224c77105bc4b5b8f1d930f7a4e1d0a57f95606b09b9da163ad8a39526a6cac895531bf92'

# Create item for Dashboard Access Codes
op item create \
  --category "Login" \
  --title "Zero Inbox Dashboard Access" \
  --vault "Work" \
  'user_code[text]=ZERO451296' \
  'admin_code[password]=ADMIN820876'
```

---

## 🛡️ Security Best Practices

### Credential Rotation Schedule

| Credential Type | Rotation Frequency | Last Rotated | Next Rotation |
|----------------|-------------------|--------------|---------------|
| Dashboard Access Codes | 90 days | 2025-11-06 | 2026-02-06 |
| JWT Secret | 90 days | 2025-11-06 | 2026-02-06 |
| Steel.dev API Key | 90 days | TBD | TBD |
| Canvas LMS Token | 90 days | TBD | TBD |
| Google Classroom Token | Auto (hourly) | Automatic | N/A |

### Automated Security Features

✅ **Audit Logging**: All credential access logged to `/backend/logs/credential-audit.log`
✅ **Token Rotation**: Google Classroom tokens auto-rotate every 50 minutes
✅ **Session Expiration**: Dashboard sessions expire after 24 hours
✅ **Google Secret Manager**: Ready for production credential migration

### Manual Rotation Procedure

1. **Generate New Credentials**:
   ```bash
   # JWT Secret
   node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

   # Access Codes (alphanumeric, 10 chars)
   node -e "console.log('ZERO' + Math.random().toString(36).substring(2, 8).toUpperCase())"
   node -e "console.log('ADMIN' + Math.random().toString(36).substring(2, 8).toUpperCase())"
   ```

2. **Update Configuration**:
   ```bash
   # Update .env
   vim /backend/.env

   # Update auth-middleware.js
   vim /backend/dashboard/auth-middleware.js
   ```

3. **Store in 1Password**:
   - Create new secure note with credentials
   - Add rotation date metadata
   - Share with team vault

4. **Audit Old Credentials**:
   ```bash
   # Search for old credentials in codebase
   cd /backend
   grep -r "ZERO2024" .
   grep -r "ZEROADMIN" .
   ```

5. **Test New Credentials**:
   ```bash
   # Test dashboard access
   curl -X POST http://localhost:3001/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"accessCode": "ZERO451296"}'
   ```

6. **Update Documentation**:
   - Update this file (CREDENTIALS_SECURE.md)
   - Update README.md with rotation date
   - Notify team via Slack/email

### Incident Response

**If credentials are compromised**:

1. **Immediate Actions** (within 1 hour):
   - [ ] Rotate all affected credentials immediately
   - [ ] Revoke OAuth tokens via Google account settings
   - [ ] Check audit logs for unauthorized access
   - [ ] Review Steel.dev session history for suspicious activity

2. **Investigation** (within 24 hours):
   - [ ] Determine scope of breach
   - [ ] Check git history for accidental commits
   - [ ] Review server logs for unauthorized API calls
   - [ ] Scan codebase for exposed credentials

3. **Recovery** (within 48 hours):
   - [ ] Generate and deploy new credentials
   - [ ] Update all 1Password entries
   - [ ] Notify affected team members
   - [ ] Update incident log

4. **Post-Mortem** (within 1 week):
   - [ ] Document what happened
   - [ ] Identify root cause
   - [ ] Implement preventive measures
   - [ ] Update security policies

### Migration to Google Secret Manager

For production deployment, migrate credentials from `.env` to Google Secret Manager:

```bash
# Migrate credentials
node services/secrets-manager.js migrate

# Test retrieval
node -e "
  const secrets = require('./services/secrets-manager');
  secrets.getSecret('JWT_SECRET').then(console.log);
"

# Update server.js to load from Secret Manager
# See /services/secrets-manager.js for usage examples
```

**Benefits**:
- Centralized credential management
- Automatic versioning and rotation
- Audit logging built-in
- Fine-grained access control via IAM
- No credentials in code or config files

---

## 📞 Support & Contacts

**Security Issues**: Report immediately to [security@yourcompany.com]
**Credential Rotation**: Automated via `/services/google-classroom-token-rotation.js`
**Audit Logs**: `/backend/logs/credential-audit.log` (90-day retention)

**Emergency Credential Reset**:
```bash
# Run emergency rotation script
npm run credentials:rotate

# Or manually:
node scripts/emergency-credential-rotation.js
```

---

## 📝 Change Log

| Date | Change | By |
|------|--------|-----|
| 2025-11-06 | Initial security overhaul - Rotated JWT secret, access codes | Claude Code |
| 2025-11-06 | Implemented audit logging for all credential access | Claude Code |
| 2025-11-06 | Created automatic Google Classroom token rotation | Claude Code |
| 2025-11-06 | Integrated Google Secret Manager support | Claude Code |

---

**Document Version**: 1.0
**Last Updated**: 2025-11-06
**Next Review**: 2026-02-06

---

🔐 **Remember**: Never commit this file to version control. Store securely in 1Password.

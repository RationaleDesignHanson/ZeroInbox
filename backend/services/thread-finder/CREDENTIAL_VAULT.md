# Credential Vault Architecture

Per-user encrypted credential storage for Thread Finder integrations with Canvas LMS, Google Classroom, SportsEngine, and other educational/sports platforms.

## Overview

The Credential Vault enables parents to connect their accounts to educational and sports platforms, allowing Zero to automatically extract assignment details, schedules, and notifications from link-only emails using official APIs.

### Key Features

- **Per-User Encryption**: Each parent has a unique Data Encryption Key (DEK)
- **AWS KMS Integration**: Master keys managed by AWS Key Management Service
- **Zero-Knowledge Architecture**: Platform never stores plaintext credentials
- **Audit Trail**: Complete logging of all credential access
- **OAuth Support**: Automatic token refresh for Google Classroom, TeamSnap
- **Key Rotation**: Transparent key rotation without service interruption

## Security Architecture

### Envelope Encryption Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS KMS                                  │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Master Key Encryption Key (KEK)                    │    │
│  │  - Never leaves AWS KMS                             │    │
│  │  - Used to encrypt/decrypt Data Encryption Keys     │    │
│  └────────────────────────────────────────────────────┘    │
│                           │                                  │
└───────────────────────────┼──────────────────────────────────┘
                            │
                            ▼
         ┌──────────────────────────────────────┐
         │   Per-User Data Encryption Key (DEK)  │
         │   - Unique 256-bit AES key per parent │
         │   - Encrypted by KEK, stored in DB    │
         │   - Plaintext DEK never persisted     │
         └──────────────────────────────────────┘
                            │
                            ▼
         ┌──────────────────────────────────────┐
         │   Encrypted Credentials (Database)    │
         │   - Canvas API tokens                 │
         │   - Google Classroom OAuth tokens     │
         │   - SportsEngine session cookies      │
         └──────────────────────────────────────┘
```

### Encryption Flow

#### Storing Credentials

1. **Generate DEK**: Request AWS KMS to generate a new 256-bit AES key
2. **Encrypt Credentials**: Use DEK to encrypt credentials with AES-256-GCM
3. **Encrypt DEK**: AWS KMS encrypts DEK using master KEK
4. **Store**: Save encrypted credentials + encrypted DEK in database
5. **Zero Plaintext DEK**: Plaintext DEK zeroed from memory immediately

#### Retrieving Credentials

1. **Fetch**: Retrieve encrypted credentials + encrypted DEK from database
2. **Decrypt DEK**: AWS KMS decrypts DEK using master KEK
3. **Decrypt Credentials**: Use plaintext DEK to decrypt credentials
4. **Zero DEK**: Plaintext DEK zeroed from memory after use
5. **Return**: Return plaintext credentials to caller

### Encryption Algorithms

- **Symmetric**: AES-256-GCM (Galois/Counter Mode)
- **Key Size**: 256 bits (32 bytes)
- **IV Size**: 96 bits (12 bytes)
- **Auth Tag**: 128 bits (16 bytes)
- **AEAD**: Authenticated Encryption with Associated Data

**Why AES-GCM?**
- Authentication built-in (detects tampering)
- High performance (hardware acceleration)
- Industry standard (NIST approved)
- Prevents chosen-ciphertext attacks

## Database Schema

### Tables

#### `credential_vault`
Stores encrypted credentials for each user-platform pair.

```sql
CREATE TABLE credential_vault (
  id UUID PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  parent_email VARCHAR(255) NOT NULL,
  platform VARCHAR(50) NOT NULL,
  platform_domain VARCHAR(255),
  encrypted_credentials BYTEA NOT NULL,
  encryption_key_id VARCHAR(255) NOT NULL,
  encryption_algorithm VARCHAR(50) NOT NULL,
  initialization_vector BYTEA NOT NULL,
  auth_tag BYTEA NOT NULL,
  credential_type VARCHAR(50) NOT NULL,
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  last_used_at TIMESTAMPTZ,
  UNIQUE (user_id, platform, platform_domain)
);
```

#### `encryption_keys`
Stores per-user Data Encryption Keys (encrypted by KMS).

```sql
CREATE TABLE encryption_keys (
  id UUID PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL UNIQUE,
  encrypted_dek BYTEA NOT NULL,
  kms_key_id VARCHAR(255) NOT NULL,
  kms_region VARCHAR(50) NOT NULL,
  algorithm VARCHAR(50) NOT NULL,
  key_status VARCHAR(20) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
```

#### `credential_access_log`
Audit trail for all credential operations.

```sql
CREATE TABLE credential_access_log (
  id UUID PRIMARY KEY,
  credential_id UUID REFERENCES credential_vault(id),
  user_id VARCHAR(255) NOT NULL,
  operation VARCHAR(50) NOT NULL,
  accessed_by VARCHAR(255) NOT NULL,
  access_reason VARCHAR(255),
  success BOOLEAN NOT NULL,
  error_message TEXT,
  accessed_at TIMESTAMPTZ NOT NULL
);
```

#### `platform_configs`
Configuration for supported platforms.

```sql
CREATE TABLE platform_configs (
  id UUID PRIMARY KEY,
  platform VARCHAR(50) NOT NULL UNIQUE,
  display_name VARCHAR(100) NOT NULL,
  auth_type VARCHAR(50) NOT NULL,
  supports_assignment_extraction BOOLEAN,
  supports_course_listing BOOLEAN,
  is_enabled BOOLEAN DEFAULT TRUE
);
```

## Code Structure

### Core Modules

#### `encryption-service.js`
Low-level encryption operations using AWS KMS.

```javascript
const { encryptionService } = require('./encryption-service');

// Generate and encrypt credentials
const result = await encryptionService.encryptCredentialComplete(
  { api_token: 'xxx' },
  userId
);

// Decrypt credentials
const credentials = await encryptionService.decryptCredentialComplete(
  {
    encryptedCredentials: result.encryptedCredentials,
    encryptedDek: result.encryptedDek,
    iv: result.iv,
    authTag: result.authTag
  },
  userId
);
```

**Key Methods:**
- `generateDataKey(userId)` - Generate new DEK via KMS
- `decryptDataKey(encryptedKey, userId)` - Decrypt DEK via KMS
- `encryptCredentials(data, dek)` - Encrypt with AES-256-GCM
- `decryptCredentials(ciphertext, dek, iv, authTag)` - Decrypt and verify
- `encryptCredentialComplete(data, userId)` - Full encryption workflow
- `decryptCredentialComplete(encryptedData, userId)` - Full decryption workflow
- `rotateDataKey(userId, credentials)` - Key rotation

#### `credential-manager.js`
High-level API for credential lifecycle management.

```javascript
const credentialManager = require('./credential-manager');

// Store credential
const credentialId = await credentialManager.storeCredential(
  userId,
  parentEmail,
  'canvas',
  { api_token: '7~6rPNPrmPU...' },
  { platformDomain: 'pascack.instructure.com' }
);

// Retrieve credential
const credentials = await credentialManager.getCredential(
  userId,
  'canvas',
  { accessReason: 'thread_finder_extraction' }
);

// List all credentials
const list = await credentialManager.listUserCredentials(userId);

// Delete credential
await credentialManager.deleteCredential(userId, 'canvas');
```

**Key Methods:**
- `storeCredential(userId, parentEmail, platform, credentialData, options)` - Store encrypted credential
- `getCredential(userId, platform, options)` - Retrieve and decrypt credential
- `deleteCredential(userId, platform)` - Remove credential
- `listUserCredentials(userId)` - List all platforms with stored credentials

#### `admin-routes.js`
REST API for credential management via admin UI.

**Endpoints:**
- `GET /api/admin/credentials` - List connected accounts
- `POST /api/admin/credentials` - Add new credential
- `GET /api/admin/credentials/:platform` - Get credential metadata
- `DELETE /api/admin/credentials/:platform` - Remove credential
- `GET /api/admin/platforms` - List supported platforms
- `POST /api/admin/oauth/initiate` - Initiate OAuth flow
- `POST /api/admin/oauth/callback` - Handle OAuth callback
- `POST /api/admin/credentials/test` - Test credential connection

## Supported Platforms

### Canvas LMS
- **Auth Type**: API Token
- **Token Format**: `7~xxxxx...` (64 characters)
- **Expiration**: Never (unless manually revoked)
- **Permissions**: Read-only access to courses, assignments, announcements
- **API Docs**: https://canvas.instructure.com/doc/api/

**Setup Instructions for Parents:**
1. Log in to Canvas
2. Account → Settings → "+ New Access Token"
3. Purpose: "Zero Inbox Integration"
4. Copy token and paste into Zero admin UI

### Google Classroom
- **Auth Type**: OAuth 2.0
- **Scopes**:
  - `classroom.courses.readonly`
  - `classroom.coursework.me.readonly`
  - `classroom.announcements.readonly`
- **Expiration**: Access token expires after 1 hour (auto-refresh with refresh token)
- **API Docs**: https://developers.google.com/classroom

**Setup Instructions for Parents:**
1. Click "Connect Google Classroom" in Zero admin UI
2. Authorize Zero to access Classroom data
3. Auto-refresh handles token renewal

### SportsEngine
- **Auth Type**: Session Cookie
- **Cookie Format**: `_sportsengine_session=xxxxx`
- **Expiration**: 30 days
- **Permissions**: View-only access to team schedules
- **API Docs**: https://developers.sportsengine.com/

**Setup Instructions for Parents:**
1. Log in to SportsEngine in browser
2. Open DevTools → Application → Cookies
3. Copy `_sportsengine_session` value
4. Paste into Zero admin UI

### TeamSnap
- **Auth Type**: OAuth 2.0
- **Scopes**: `read_team`, `read_events`
- **Expiration**: Access token expires after 2 hours
- **API Docs**: https://www.teamsnap.com/documentation/apiv3

## Usage Examples

### Example 1: Parent Connects Canvas Account

**Frontend (React Admin UI):**
```javascript
const handleConnectCanvas = async () => {
  const response = await fetch('/api/admin/credentials', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-User-Id': userId,
      'X-Parent-Email': parentEmail
    },
    body: JSON.stringify({
      platform: 'canvas',
      platformDomain: 'pascack.instructure.com',
      credentials: {
        api_token: canvasTokenInput
      }
    })
  });

  const data = await response.json();
  console.log('Credential stored:', data.credentialId);
};
```

**Backend (Thread Finder Extraction):**
```javascript
const credentialManager = require('./credential-manager');

async function extractCanvasAssignment(userId, assignmentUrl) {
  // Retrieve Canvas credentials
  const credentials = await credentialManager.getCredential(
    userId,
    'canvas',
    { accessReason: 'thread_finder_extraction' }
  );

  if (!credentials) {
    throw new Error('No Canvas credentials found. Please connect your Canvas account.');
  }

  // Use API token to fetch assignment details
  const axios = require('axios');
  const response = await axios.get(assignmentUrl, {
    headers: {
      'Authorization': `Bearer ${credentials.api_token}`
    }
  });

  return response.data;
}
```

### Example 2: Google Classroom OAuth Flow

**Initiate OAuth:**
```javascript
const response = await fetch('/api/admin/oauth/initiate', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-User-Id': userId,
    'X-Parent-Email': parentEmail
  },
  body: JSON.stringify({
    platform: 'google_classroom'
  })
});

const { authorizationUrl } = await response.json();
window.location.href = authorizationUrl; // Redirect to Google
```

**Handle OAuth Callback:**
```javascript
// After user authorizes, Google redirects back with code
const urlParams = new URLSearchParams(window.location.search);
const code = urlParams.get('code');
const state = urlParams.get('state');

const response = await fetch('/api/admin/oauth/callback', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-User-Id': userId,
    'X-Parent-Email': parentEmail
  },
  body: JSON.stringify({ code, state })
});

const data = await response.json();
console.log('Google Classroom connected!', data);
```

## Deployment

### Prerequisites

1. **AWS KMS Key**
   ```bash
   aws kms create-key --description "Zero Credential Vault Master Key"
   aws kms create-alias --alias-name alias/zero-credential-vault --target-key-id <key-id>
   ```

2. **Database Setup**
   ```bash
   psql $DATABASE_URL -f credential-vault-schema.sql
   ```

3. **Environment Variables**
   ```bash
   # AWS KMS
   AWS_KMS_KEY_ID=alias/zero-credential-vault
   AWS_KMS_REGION=us-east-1

   # Database
   DATABASE_URL=postgresql://user:pass@host:5432/zeroinbox

   # Google Classroom OAuth
   GOOGLE_CLASSROOM_CLIENT_ID=xxx.apps.googleusercontent.com
   GOOGLE_CLASSROOM_CLIENT_SECRET=xxx
   GOOGLE_CLASSROOM_REDIRECT_URI=https://app.zero.com/api/admin/oauth/callback
   ```

### IAM Permissions

The application requires these AWS KMS permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:us-east-1:123456789012:key/*"
    }
  ]
}
```

## Security Best Practices

### ✅ DO

- **Use HTTPS**: All API calls must use TLS 1.2+
- **Rotate Keys**: Rotate DEKs every 90 days
- **Monitor Access**: Review audit logs weekly
- **Rate Limit**: Limit credential access to prevent brute force
- **Validate Input**: Sanitize all user input before storage
- **Log Failures**: Log all failed decryption attempts

### ❌ DON'T

- **Don't Store Plaintext**: Never log or persist plaintext credentials
- **Don't Share DEKs**: Each user must have unique encryption key
- **Don't Skip Auth**: Always require authentication for admin routes
- **Don't Expose Keys**: Never include keys in error messages
- **Don't Reuse IVs**: Always generate new random IV for each encryption

## Compliance

### GDPR

- **Right to Erasure**: `deleteCredential()` permanently removes data
- **Data Portability**: `getCredential()` returns data in JSON format
- **Encryption at Rest**: AES-256-GCM exceeds GDPR requirements
- **Audit Trail**: Complete logging of all data access

### FERPA (Family Educational Rights and Privacy Act)

- **Access Control**: Parents can only access their own child's data
- **Consent**: Explicit opt-in required for credential storage
- **Security**: Military-grade encryption protects educational records

### SOC 2 Type II

- **Encryption**: Data encrypted at rest and in transit
- **Logging**: Comprehensive audit trail for all operations
- **Access Control**: Role-based access control (RBAC)
- **Key Management**: AWS KMS meets SOC 2 requirements

## Monitoring & Alerts

### Key Metrics

- **Decryption Failures**: Alert if >5 failures in 1 hour
- **KMS Latency**: Alert if P99 latency >500ms
- **Expired Credentials**: Alert if >10% credentials expired
- **Key Rotation**: Alert if any key not rotated in 90 days

### CloudWatch Alarms

```bash
# Decrypt failures
aws cloudwatch put-metric-alarm \
  --alarm-name zero-credential-vault-decrypt-failures \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --metric-name DecryptionFailures \
  --namespace Zero/CredentialVault \
  --period 3600 \
  --statistic Sum \
  --threshold 5
```

## Troubleshooting

### Issue: "KMS key decryption failed"

**Cause**: IAM permissions issue or KMS key disabled

**Solution**:
1. Check IAM role has `kms:Decrypt` permission
2. Verify KMS key is enabled: `aws kms describe-key --key-id <key-id>`
3. Check encryption context matches

### Issue: "Decryption failed: Data tampered or corrupted"

**Cause**: Authentication tag verification failed (data was modified)

**Solution**:
1. Database corruption - restore from backup
2. IV/authTag mismatch - check database schema
3. DO NOT IGNORE - this indicates security breach

### Issue: "Credential expired and refresh failed"

**Cause**: OAuth refresh token invalid or expired

**Solution**:
1. Ask parent to re-authorize via OAuth flow
2. Check refresh token was stored correctly
3. Verify OAuth client credentials

## Future Enhancements

- [ ] Biometric authentication for credential access
- [ ] Hardware security module (HSM) integration
- [ ] Credential sharing between family members
- [ ] Automatic credential health checks
- [ ] Push notifications for expiring credentials
- [ ] Bulk credential import from CSV
- [ ] Multi-region KMS replication
- [ ] Quantum-resistant encryption algorithms

## License

Proprietary - Zero Inbox, Inc.

## Support

For questions or issues, contact: engineering@zeroinbox.com

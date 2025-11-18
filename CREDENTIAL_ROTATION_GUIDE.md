# Credential Rotation Guide - Zero Backend Services
## Step-by-Step Instructions

**Date:** 2025-11-16
**Status:** Ready to Execute
**Time Required:** 1-2 hours

---

## 📋 CREDENTIALS TO ROTATE

From `/backend/.env` (lines 38, 50, 55, 57-58, 69):

1. **JWT_SECRET** (Line 38) - Used for session tokens
2. **CANVAS_API_TOKEN** (Line 50) - Canvas LMS integration
3. **GOOGLE_CLASSROOM_CLIENT_SECRET** (Line 55) - Google Classroom OAuth
4. **GOOGLE_CLASSROOM_TOKEN** (Line 57) - Access token
5. **GOOGLE_CLASSROOM_REFRESH_TOKEN** (Line 58) - Refresh token
6. **STEEL_API_KEY** (Line 69) - Steel.dev browser automation

---

## 🔐 ROTATION ORDER (Safest to Most Complex)

Execute in this order to minimize downtime:

1. JWT_SECRET (internal only, no external dependencies)
2. STEEL_API_KEY (external service, simple)
3. CANVAS_API_TOKEN (external service, requires Canvas portal)
4. GOOGLE_CLASSROOM credentials (OAuth flow, most complex)

---

## 1️⃣ JWT_SECRET ROTATION

### What It Does
Signs and verifies JWT tokens for authenticated API requests between iOS app and backend.

### Impact of Rotation
- **Users affected:** ALL active users
- **What breaks:** All existing sessions (users must re-authenticate)
- **Downtime:** None (JWT validates on each request)
- **Recovery time:** Immediate (users just need to log in again)

### How to Generate New Secret

**Option A: OpenSSL (Recommended)**
```bash
openssl rand -hex 64
```

**Option B: Node.js**
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

**Option C: Python**
```bash
python3 -c "import secrets; print(secrets.token_hex(64))"
```

### Steps to Rotate

1. **Generate new secret:**
```bash
cd ~/Zer0_Inbox/backend
NEW_JWT_SECRET=$(openssl rand -hex 64)
echo "New JWT Secret: $NEW_JWT_SECRET"
```

2. **Update .env file:**
```bash
# Backup current .env
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Update JWT_SECRET (line 38)
# Replace the value after JWT_SECRET=
```

3. **Update Secret Manager (if using GCP):**
```bash
# Create/update secret in Google Secret Manager
echo -n "$NEW_JWT_SECRET" | gcloud secrets create JWT_SECRET \
  --data-file=- \
  --replication-policy="automatic"

# Or update existing:
echo -n "$NEW_JWT_SECRET" | gcloud secrets versions add JWT_SECRET \
  --data-file=-
```

4. **Update services to load from Secret Manager:**

Edit `/backend/services/gateway/config.js`:
```javascript
// Old:
const JWT_SECRET = process.env.JWT_SECRET;

// New (if using Secret Manager):
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const client = new SecretManagerServiceClient();

async function getJWTSecret() {
  const [version] = await client.accessSecretVersion({
    name: 'projects/YOUR_PROJECT_ID/secrets/JWT_SECRET/versions/latest',
  });
  return version.payload.data.toString('utf8');
}
```

5. **Restart services:**
```bash
# If running locally:
npm run restart

# If on Cloud Run:
gcloud run deploy emailshortform-gateway --region us-central1
```

6. **Verify:**
```bash
# Test JWT generation
curl -X POST https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api/auth/test \
  -H "Content-Type: application/json" \
  -d '{"test": "jwt_generation"}'
```

7. **Notify users:**
- Send push notification: "Please log in again to continue"
- In-app message on next launch
- Email to beta testers if needed

### Files to Update
- ✅ `/backend/.env` (line 38)
- ✅ Google Secret Manager (if using)
- ✅ `/backend/services/gateway/config.js` (to load from Secret Manager)
- ⚠️ Clear existing Keychain tokens on iOS (handled automatically on re-auth)

---

## 2️⃣ STEEL_API_KEY ROTATION

### What It Does
Authenticates with Steel.dev for browser automation (shopping agent, form filling).

### Impact of Rotation
- **Users affected:** Users using shopping/automation features
- **What breaks:** Steel.dev API calls will fail
- **Downtime:** < 5 minutes (just key swap)
- **Recovery time:** Immediate

### How to Get New Key

1. **Login to Steel.dev dashboard:**
   - Go to: https://app.steel.dev/api-keys
   - Sign in with your Steel account

2. **Generate new API key:**
   - Click "Create New API Key"
   - Name it: "Zero-Production-2025-11-16"
   - Copy the key (starts with `ste-`)
   - **Save it immediately** (won't be shown again)

3. **Revoke old key:**
   - Find old key: `ste-XoV1UrRCXSpPYE5WgmrM9ZsgxE1lsYNs12s9nsdNn0lGuKafWrj6Yt3rUqwDqmOihsNUPeZ8AixEkxaYwguY4ta0fMZHi0n2eUP`
   - Click "Revoke"
   - Confirm revocation

### Steps to Rotate

1. **Get new key from Steel.dev** (see above)

2. **Update .env:**
```bash
cd ~/Zer0_Inbox/backend

# Update STEEL_API_KEY (line 69)
# Find: STEEL_API_KEY=ste-XoV1UrRCXSpPYE5WgmrM9ZsgxE1lsYNs12s9nsdNn0lGuKafWrj6Yt3rUqwDqmOihsNUPeZ8AixEkxaYwguY4ta0fMZHi0n2eUP
# Replace with: STEEL_API_KEY=ste-NEW_KEY_HERE
```

3. **Update Secret Manager:**
```bash
echo -n "ste-NEW_KEY_HERE" | gcloud secrets create STEEL_API_KEY \
  --data-file=- \
  --replication-policy="automatic"
```

4. **Update service config:**
Edit `/backend/services/steel-agent/config.js`:
```javascript
// Make sure it loads from env
const STEEL_API_KEY = process.env.STEEL_API_KEY;
```

5. **Restart steel-agent service:**
```bash
# Local:
pm2 restart steel-agent

# Cloud Run:
gcloud run deploy steel-agent-service --region us-central1
```

6. **Verify:**
```bash
# Test Steel API connection
curl -X GET https://api.steel.dev/v1/sessions \
  -H "Authorization: Bearer ste-NEW_KEY_HERE"
```

### Files to Update
- ✅ `/backend/.env` (line 69)
- ✅ Google Secret Manager
- ✅ `/backend/services/steel-agent/config.js`

---

## 3️⃣ CANVAS_API_TOKEN ROTATION

### What It Does
Accesses Canvas LMS API for school assignment integration (Thread Finder feature).

### Impact of Rotation
- **Users affected:** Users with Canvas LMS integration
- **What breaks:** Canvas assignment sync
- **Downtime:** < 10 minutes
- **Recovery time:** Immediate after rotation

### How to Get New Token

1. **Login to Canvas:**
   - Go to: https://canvas.instructure.com
   - Sign in with your Canvas account

2. **Navigate to Account Settings:**
   - Click your profile (top right)
   - Select "Settings"
   - Scroll to "Approved Integrations"

3. **Generate new token:**
   - Click "+ New Access Token"
   - Purpose: "Zero iOS App - Production"
   - Expiry: (leave blank for no expiry, or set to 1 year)
   - Click "Generate Token"
   - **Copy the token immediately** (can't view again)

4. **Revoke old token:**
   - Find token ending in: `...J3kyX`
   - Click "Delete" next to it
   - Confirm deletion

### Steps to Rotate

1. **Get new token from Canvas** (see above)

2. **Update .env:**
```bash
cd ~/Zer0_Inbox/backend

# Update CANVAS_API_TOKEN (line 50)
# Find: CANVAS_API_TOKEN=7~6rPNPrmPUfCRALFLGmMAAXk3RhZnMrHVVyBZJkZ4RBxk2yFtvJCJF4XKUn6J3kyX
# Replace with: CANVAS_API_TOKEN=YOUR_NEW_TOKEN_HERE
```

3. **Update Secret Manager:**
```bash
echo -n "YOUR_NEW_TOKEN" | gcloud secrets create CANVAS_API_TOKEN \
  --data-file=- \
  --replication-policy="automatic"
```

4. **Update service config:**
Edit `/backend/services/classifier/thread-finder-config.js` or equivalent:
```javascript
const CANVAS_API_TOKEN = process.env.CANVAS_API_TOKEN;
const CANVAS_DOMAIN = process.env.CANVAS_DOMAIN || 'canvas.instructure.com';
```

5. **Restart services:**
```bash
# Restart classifier service (handles Canvas integration)
pm2 restart classifier

# Cloud Run:
gcloud run deploy classifier-service --region us-central1
```

6. **Verify:**
```bash
# Test Canvas API
curl -X GET "https://canvas.instructure.com/api/v1/users/self/courses" \
  -H "Authorization: Bearer YOUR_NEW_TOKEN"
```

### Files to Update
- ✅ `/backend/.env` (line 50)
- ✅ Google Secret Manager
- ✅ `/backend/services/classifier/thread-finder-config.js`

---

## 4️⃣ GOOGLE_CLASSROOM CREDENTIALS ROTATION (Most Complex)

### What They Do
- **CLIENT_SECRET:** OAuth app secret for Google Classroom integration
- **ACCESS_TOKEN:** Short-lived token (expires in 1 hour)
- **REFRESH_TOKEN:** Long-lived token to get new access tokens

### Impact of Rotation
- **Users affected:** Users with Google Classroom integration
- **What breaks:** Google Classroom sync
- **Downtime:** 10-30 minutes (OAuth flow)
- **Recovery time:** Requires OAuth re-authorization

### Part 4A: Rotate CLIENT_SECRET

1. **Login to Google Cloud Console:**
   - Go to: https://console.cloud.google.com/apis/credentials
   - Select your project

2. **Find OAuth Client:**
   - Look for client ID: `514014482017-8icfgg4vag0ic0u028cb9est0r5pgvne`
   - Click on it to edit

3. **Generate new secret:**
   - Scroll to "Client secrets"
   - Click "Add secret"
   - Copy new secret
   - **Delete old secret:** `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`

4. **Update .env:**
```bash
# Update GOOGLE_CLASSROOM_CLIENT_SECRET (line 55)
# Replace: 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
# With: YOUR_NEW_CLIENT_SECRET
```

### Part 4B: Rotate ACCESS & REFRESH Tokens

**Important:** Access tokens expire hourly. Refresh tokens don't expire unless revoked.

1. **Revoke existing tokens:**
   - Go to: https://myaccount.google.com/permissions
   - Find "Zero" or your app name
   - Click "Remove access"

2. **Trigger OAuth flow to get new tokens:**

```bash
cd ~/Zer0_Inbox/backend

# Run OAuth flow script
node scripts/google-classroom-auth.js
```

**Or manually via browser:**

A. **Build authorization URL:**
```
https://accounts.google.com/o/oauth2/v2/auth?
  client_id=514014482017-8icfgg4vag0ic0u028cb9est0r5pgvne.apps.googleusercontent.com
  &redirect_uri=http://localhost:3001/api/auth/google-classroom/callback
  &response_type=code
  &scope=https://www.googleapis.com/auth/classroom.courses.readonly https://www.googleapis.com/auth/classroom.coursework.me.readonly
  &access_type=offline
  &prompt=consent
```

B. **Visit URL in browser** (copy entire URL above, remove line breaks)

C. **Authorize the app** (Google will redirect to callback)

D. **Extract authorization code** from callback URL:
```
http://localhost:3001/api/auth/google-classroom/callback?code=4/0AeanS0...
```

E. **Exchange code for tokens:**
```bash
curl -X POST https://oauth2.googleapis.com/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "code=YOUR_AUTH_CODE" \
  -d "client_id=514014482017-8icfgg4vag0ic0u028cb9est0r5pgvne.apps.googleusercontent.com" \
  -d "client_secret=YOUR_NEW_CLIENT_SECRET" \
  -d "redirect_uri=http://localhost:3001/api/auth/google-classroom/callback" \
  -d "grant_type=authorization_code"
```

F. **Response will contain:**
```json
{
  "access_token": "ya29.a0ATi6K2...",
  "refresh_token": "1//01QBIW3lhBzGp...",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

3. **Update .env with new tokens:**
```bash
# Update lines 57-58:
GOOGLE_CLASSROOM_TOKEN=ya29.NEW_ACCESS_TOKEN
GOOGLE_CLASSROOM_REFRESH_TOKEN=1//NEW_REFRESH_TOKEN
```

4. **Update Secret Manager:**
```bash
echo -n "YOUR_NEW_CLIENT_SECRET" | gcloud secrets create GOOGLE_CLASSROOM_CLIENT_SECRET --data-file=-
echo -n "YOUR_NEW_REFRESH_TOKEN" | gcloud secrets create GOOGLE_CLASSROOM_REFRESH_TOKEN --data-file=-
```

5. **Update service config:**
Edit `/backend/services/classifier/google-classroom-config.js`:
```javascript
// Implement token refresh logic
async function getValidAccessToken() {
  // Check if current token is expired
  // If expired, use refresh token to get new access token
  // Return valid access token
}
```

6. **Restart services:**
```bash
pm2 restart classifier

# Cloud Run:
gcloud run deploy classifier-service --region us-central1
```

7. **Verify:**
```bash
# Test Google Classroom API
curl -X GET "https://classroom.googleapis.com/v1/courses" \
  -H "Authorization: Bearer YOUR_NEW_ACCESS_TOKEN"
```

### Files to Update
- ✅ `/backend/.env` (lines 55, 57-58)
- ✅ Google Secret Manager (3 secrets)
- ✅ `/backend/services/classifier/google-classroom-config.js`
- ⚠️ Implement token refresh mechanism if not already present

---

## 🔄 POST-ROTATION CHECKLIST

### Immediate Verification (within 5 minutes)

- [ ] All services started successfully
- [ ] No errors in service logs
- [ ] Health check endpoints responding
- [ ] Sample API calls succeeding

```bash
# Check service status
pm2 status

# Check logs
pm2 logs --lines 50

# Test gateway
curl https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/health

# Test each integration
curl -X GET "your-test-endpoints"
```

### Integration Testing (within 30 minutes)

- [ ] iOS app can authenticate (new JWT flow)
- [ ] Steel.dev automation works (shopping agent)
- [ ] Canvas assignments sync (if feature enabled)
- [ ] Google Classroom data loads (if feature enabled)

### Security Verification

- [ ] Old JWT tokens rejected (test with old session)
- [ ] Old API keys return 401/403 errors
- [ ] New credentials working in production
- [ ] Secret Manager values match .env (if migrated)

### Monitoring (24 hours)

- [ ] Error rates normal
- [ ] No authentication spikes
- [ ] User complaints minimal (expect re-login requests)
- [ ] Integration success rates normal

---

## 📝 DOCUMENTATION UPDATES

After rotation, update:

1. **This file:** Mark completion date
2. **Secret inventory:** `/backend/SECRETS_INVENTORY.md` (create if needed)
3. **Runbook:** Add rotation date to history
4. **Team wiki:** Document new credential locations
5. **1Password/Secret Manager:** Add notes with rotation dates

---

## 🆘 ROLLBACK PROCEDURE

If something breaks:

1. **Keep .env.backup file** (created in step 1 of JWT rotation)

2. **Restore old credentials:**
```bash
cd ~/Zer0_Inbox/backend
cp .env.backup.TIMESTAMP .env
pm2 restart all
```

3. **Identify what broke:**
   - Check logs: `pm2 logs --lines 100`
   - Test endpoints individually
   - Check Secret Manager sync

4. **Fix forward (preferred):**
   - Debug the specific credential issue
   - Re-rotate only the problematic credential
   - Don't roll back all credentials

5. **Only if critical:**
   - Restore entire backup
   - Notify users
   - Schedule retry for rotation

---

## ⏱️ TIMING RECOMMENDATIONS

**Best Time to Rotate:**
- **Day:** Tuesday or Wednesday (avoid Monday/Friday)
- **Time:** 2-4 AM PST (lowest user activity)
- **Duration:** 1-2 hours total
- **Backup window:** +2 hours for troubleshooting

**Notification Strategy:**
1. **T-24 hours:** Email beta testers about maintenance window
2. **T-1 hour:** In-app message about upcoming maintenance
3. **T-0:** Begin rotation
4. **T+15 min:** Test integrations
5. **T+30 min:** Monitor for issues
6. **T+1 hour:** Send "all clear" message

---

## ✅ COMPLETION CHECKLIST

When all rotations complete:

- [ ] All credentials rotated
- [ ] .env file updated
- [ ] Secret Manager updated (if using)
- [ ] Services restarted and verified
- [ ] Integration tests passed
- [ ] Old credentials revoked
- [ ] Documentation updated
- [ ] Team notified
- [ ] Users notified (if needed)
- [ ] Monitoring confirmed normal

**Rotated by:** ________________
**Date:** ________________
**Next rotation due:** ________________ (recommended: 90 days)

---

## 📞 SUPPORT CONTACTS

If issues arise:

- **Steel.dev Support:** https://docs.steel.dev/support
- **Canvas Support:** https://community.canvaslms.com/
- **Google Cloud Support:** https://console.cloud.google.com/support
- **Internal escalation:** [Your team contacts]

---

**Document Version:** 1.0
**Created:** 2025-11-16
**Last Rotation:** Pending
**Next Review:** After first rotation

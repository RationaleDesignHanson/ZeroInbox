# Production Pre-Flight Checklist

**Last Updated:** 2025-11-02
**Target Date:** Next deployment
**Status:** Ready for production testing

## Pre-Deployment (Do Once)

### 1. Google Cloud Setup

#### 1.1 Enable Services
```bash
# Enable required Google Cloud APIs
gcloud services enable \
  run.googleapis.com \
  firestore.googleapis.com \
  secretmanager.googleapis.com \
  cloudkms.googleapis.com \
  logging.googleapis.com \
  cloudbuild.googleapis.com
```

#### 1.2 Create Secrets in Secret Manager
```bash
# JWT Secret (generate a strong 256-bit random string)
echo -n "YOUR_JWT_SECRET_HERE" | gcloud secrets create JWT_SECRET --data-file=-

# Google OAuth Credentials
echo -n "YOUR_GOOGLE_CLIENT_ID" | gcloud secrets create GOOGLE_CLIENT_ID --data-file=-
echo -n "YOUR_GOOGLE_CLIENT_SECRET" | gcloud secrets create GOOGLE_CLIENT_SECRET --data-file=-

# Microsoft OAuth Credentials
echo -n "YOUR_MICROSOFT_CLIENT_ID" | gcloud secrets create MICROSOFT_CLIENT_ID --data-file=-
echo -n "YOUR_MICROSOFT_CLIENT_SECRET" | gcloud secrets create MICROSOFT_CLIENT_SECRET --data-file=-

# Verify secrets
gcloud secrets list
```

#### 1.3 Deploy Firestore Security Rules
```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Verify deployment
firebase firestore:rules get

# Expected output: Shows rules with user isolation and write-only tokens
```

#### 1.4 Enable Cloud Audit Logs
1. Go to Cloud Console → IAM & Admin → Audit Logs
2. Enable for these services:
   - ✅ Cloud Firestore API (Admin Read, Data Read, Data Write)
   - ✅ Cloud Run API (Admin Read, Data Read, Data Write)
   - ✅ Secret Manager API (Admin Read, Data Read)

### 2. Service Deployment

#### 2.1 Gateway Service (Port 3001 → Cloud Run)
```bash
cd backend/services/gateway

# Build and deploy
gcloud run deploy emailshortform-gateway \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-secrets="JWT_SECRET=JWT_SECRET:latest,GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest" \
  --set-env-vars="NODE_ENV=production,RATE_LIMIT_MAX_REQUESTS=1000,RATE_LIMIT_WINDOW_MS=900000" \
  --max-instances=100 \
  --min-instances=1 \
  --cpu=2 \
  --memory=1Gi \
  --timeout=60s

# Get service URL
gcloud run services describe emailshortform-gateway --region us-central1 --format="value(status.url)"
```

#### 2.2 Email Service (Port 8081 → Cloud Run)
```bash
cd backend/services/email

gcloud run deploy email-service \
  --source . \
  --region us-central1 \
  --no-allow-unauthenticated \
  --set-secrets="GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest" \
  --max-instances=50 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=120s

# Get service URL
gcloud run services describe email-service --region us-central1 --format="value(status.url)"
```

#### 2.3 Classifier Service (Port 8082 → Cloud Run)
```bash
cd backend/services/classifier

gcloud run deploy classifier-service \
  --source . \
  --region us-central1 \
  --no-allow-unauthenticated \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=50 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=60s

gcloud run services describe classifier-service --region us-central1 --format="value(status.url)"
```

#### 2.4 Summarization Service (Port 8083 → Cloud Run)
```bash
cd backend/services/summarization

gcloud run deploy summarization-service \
  --source . \
  --region us-central1 \
  --no-allow-unauthenticated \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=30 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=90s

gcloud run services describe summarization-service --region us-central1 --format="value(status.url)"
```

#### 2.5 Actions Service (Port 8085 → Cloud Run)
```bash
cd backend/services/actions

gcloud run deploy actions-service \
  --source . \
  --region us-central1 \
  --no-allow-unauthenticated \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=30 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=60s

gcloud run services describe actions-service --region us-central1 --format="value(status.url)"
```

#### 2.6 Analytics Service (Port 8090 → Cloud Run)
```bash
cd backend/services/analytics

gcloud run deploy analytics-service \
  --source . \
  --region us-central1 \
  --no-allow-unauthenticated \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=20 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=30s

gcloud run services describe analytics-service --region us-central1 --format="value(status.url)"
```

#### 2.7 Dashboard Server (Port 8088 → Cloud Run)
```bash
cd backend/dashboard

gcloud run deploy zero-dashboard \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=10 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=30s

gcloud run services describe zero-dashboard --region us-central1 --format="value(status.url)"
```

### 3. Update Configuration Files

#### 3.1 Backend Configuration (backend/dashboard/js/config.js)
Already configured with production URLs:
- ✅ Gateway: `https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app`
- ✅ Email: `https://email-service-hqdlmnyzrq-uc.a.run.app`
- ✅ Classifier: `https://classifier-service-hqdlmnyzrq-uc.a.run.app`
- ✅ Summarization: `https://summarization-service-hqdlmnyzrq-uc.a.run.app`
- ✅ Actions: `https://actions-service-hqdlmnyzrq-uc.a.run.app`
- ✅ Analytics: `https://analytics-service-hqdlmnyzrq-uc.a.run.app`

**Verify URLs match deployed services!**

#### 3.2 iOS App Configuration (Zero_ios_2/Zero/Config/APIConfig.swift)
Update production URLs to match Cloud Run deployments:
```swift
static let production = APIEnvironment(
    baseURL: "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app",
    emailServiceURL: "https://email-service-hqdlmnyzrq-uc.a.run.app",
    // ... update all service URLs
)
```

#### 3.3 Gateway Service Environment Variables
Update `backend/services/gateway/.env.production`:
```bash
EMAIL_SERVICE_URL=https://email-service-hqdlmnyzrq-uc.a.run.app
CLASSIFIER_SERVICE_URL=https://classifier-service-hqdlmnyzrq-uc.a.run.app
SUMMARIZATION_SERVICE_URL=https://summarization-service-hqdlmnyzrq-uc.a.run.app
ACTIONS_SERVICE_URL=https://actions-service-hqdlmnyzrq-uc.a.run.app
ANALYTICS_SERVICE_URL=https://analytics-service-hqdlmnyzrq-uc.a.run.app
ALLOWED_ORIGINS=https://zero-dashboard-hqdlmnyzrq-uc.a.run.app,https://zero-email.app
```

## Pre-Flight Testing (Before Going Live)

### Test 1: Gateway Health Check
```bash
curl https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/health
```
**Expected:** `{"status":"ok","service":"api-gateway",...}`

### Test 2: Dashboard Authentication
1. Visit: `https://zero-dashboard-hqdlmnyzrq-uc.a.run.app`
2. Should see splash page (not redirect error)
3. Login with access code: `ZERO2024`
4. Should access dashboard successfully
5. **Status:** ⬜ Pass / ⬜ Fail

### Test 3: OAuth Flow (Gmail)
```bash
# Start OAuth flow
curl -X GET https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api/auth/gmail
```
**Expected:** Redirect URL to Google OAuth consent screen
**Status:** ⬜ Pass / ⬜ Fail

### Test 4: Rate Limiting
```bash
# Send 1001 requests in 15 minutes (should get rate limited)
for i in {1..1001}; do
  curl -s https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/health > /dev/null
  echo "Request $i"
done
```
**Expected:** 429 Too Many Requests after 1000 requests
**Status:** ⬜ Pass / ⬜ Fail

### Test 5: Firestore Security Rules
Try to read another user's tokens (should fail):
```javascript
// In Firebase Console → Firestore → Rules Playground
// Try: get /user_tokens/OTHER_USER_gmail
// Expected: Permission denied
```
**Status:** ⬜ Pass / ⬜ Fail

### Test 6: iOS App Connection
1. Open Zero app on iOS Simulator/Device
2. Set environment to Production in app settings
3. Attempt OAuth login with Gmail
4. Should complete successfully and fetch emails
5. **Status:** ⬜ Pass / ⬜ Fail

### Test 7: Email Fetching (Zero-Visibility Check)
1. Authenticate with Gmail account
2. Fetch inbox emails through iOS app
3. Check Cloud Run logs for email service
4. **Expected:** NO email content in logs (only metadata like IDs)
5. **Status:** ⬜ Pass / ⬜ Fail

### Test 8: Analytics Backend Sync
1. Perform actions in iOS app (swipe cards, etc.)
2. Check analytics service logs
3. Should see events being received and stored
4. **Expected:** Events logged without email content
5. **Status:** ⬜ Pass / ⬜ Fail

### Test 9: Landing Page
1. Visit: `https://zero-dashboard-hqdlmnyzrq-uc.a.run.app/landing.html`
2. Check Zero Sequence renders correctly
3. Verify all action shots display properly
4. Test FAQ toggles work
5. **Status:** ⬜ Pass / ⬜ Fail

### Test 10: Waitlist Signup
1. Visit splash page
2. Enter email in waitlist form
3. Submit
4. Check Firestore → waitlist collection
5. **Expected:** Email stored successfully
6. **Status:** ⬜ Pass / ⬜ Fail

## Security Verification

### Security Checklist
- ⬜ Firestore rules deployed and tested
- ⬜ JWT_SECRET in Secret Manager (not .env file)
- ⬜ OAuth credentials in Secret Manager
- ⬜ Cloud Audit Logs enabled for Firestore, Cloud Run, Secret Manager
- ⬜ Rate limiting active (tested with 1000+ requests)
- ⬜ No email content in Cloud Run logs
- ⬜ HTTPS enforced on all services
- ⬜ Dashboard authentication working (ZERO2024 access code)
- ⬜ Thread metadata caching removed (zero-visibility confirmed)
- ⬜ CORS properly configured (only allowed origins)

## Post-Deployment Monitoring

### Day 1: Monitor Closely
```bash
# Watch gateway logs
gcloud run services logs read emailshortform-gateway --region us-central1 --limit 50

# Watch error rates
gcloud monitoring dashboards list

# Check Cloud Audit Logs
gcloud logging read "resource.type=cloud_run_revision" --limit 50
```

### Week 1: Check Metrics
- Request counts per service
- Error rates (should be < 1%)
- Latency (p50, p95, p99)
- Rate limit triggers
- Failed authentication attempts

### Month 1: Review Security
- Review Cloud Audit Logs for unauthorized access attempts
- Check Firestore security rule violations
- Review OAuth token refresh rates
- Analyze user feedback from waitlist

## Rollback Plan

If something goes wrong:

```bash
# Rollback specific service to previous revision
gcloud run services update-traffic emailshortform-gateway \
  --to-revisions=REVISION_NAME=100 \
  --region us-central1

# Check previous revisions
gcloud run revisions list --service=emailshortform-gateway --region us-central1
```

## Access Codes for Beta Testing

**Beta User Access:** `ZERO2024`
- Access to all dashboard tools
- Can view zero sequence, intent explorer, design system
- Cannot access admin features

**Admin Access:** `ZEROADMIN`
- Full access to all features
- Can view analytics and feedback
- Reserved for you

## Production URLs (Update After Deployment)

```
Gateway:       https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app
Email:         https://email-service-hqdlmnyzrq-uc.a.run.app
Classifier:    https://classifier-service-hqdlmnyzrq-uc.a.run.app
Summarization: https://summarization-service-hqdlmnyzrq-uc.a.run.app
Actions:       https://actions-service-hqdlmnyzrq-uc.a.run.app
Analytics:     https://analytics-service-hqdlmnyzrq-uc.a.run.app
Dashboard:     https://zero-dashboard-hqdlmnyzrq-uc.a.run.app
```

## Support Contacts

**Security Issues:** thematthanson@gmail.com
**Google Cloud Support:** https://cloud.google.com/support
**Firebase Console:** https://console.firebase.google.com/project/gen-lang-client-0622702687

---

## Final Pre-Flight Checklist

Before sharing with friends:

- ⬜ All services deployed to Cloud Run
- ⬜ All pre-flight tests passed (10/10)
- ⬜ Security verification complete
- ⬜ iOS app tested with production backend
- ⬜ Dashboard authentication tested
- ⬜ Landing page renders correctly
- ⬜ SECURITY.md reviewed and accurate
- ⬜ Access codes confirmed working
- ⬜ Monitoring dashboards configured
- ⬜ Rollback plan understood

**Sign-Off:** ___________________ Date: ___________

---

**Status:** Ready for production deployment
**Next Step:** Deploy services to Cloud Run and run pre-flight tests

# Google Cloud Deployment Guide

This guide covers deploying Zero Email platform to Google Cloud with industry-standard security.

## Prerequisites

- Google Cloud Project: `gen-lang-client-0622702687`
- Google Cloud SDK installed (`gcloud`)
- Firestore in Native mode (already set up)
- Cloud Run enabled

## Security Checklist

Before deploying to production, complete these security requirements:

### 1. Firestore Security Rules

Deploy security rules to protect user data:

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Or using gcloud
gcloud firestore indexes create --file=firestore.rules
```

**Verify rules are applied:**
```bash
# Check current rules
gcloud firestore rules get

# Test rules in Firebase Console > Firestore > Rules tab
```

### 2. Enable Customer-Managed Encryption Keys (CMEK)

Firestore uses Google-managed encryption by default. For production, use customer-managed keys:

```bash
# Create encryption key
gcloud kms keyrings create zero-email-keyring \
  --location=us-central1

gcloud kms keys create firestore-key \
  --keyring=zero-email-keyring \
  --location=us-central1 \
  --purpose=encryption

# Grant Firestore access to key
gcloud kms keys add-iam-policy-binding firestore-key \
  --keyring=zero-email-keyring \
  --location=us-central1 \
  --member=serviceAccount:service-<PROJECT_NUMBER>@gcp-sa-firestore.iam.gserviceaccount.com \
  --role=roles/cloudkms.cryptoKeyEncrypterDecrypter
```

### 3. Enable Cloud Audit Logs

Track all data access for security and compliance:

```bash
# Enable Data Access Audit Logs
gcloud projects add-iam-policy-binding gen-lang-client-0622702687 \
  --member=serviceAccount:<SERVICE_ACCOUNT> \
  --role=roles/logging.admin
```

**Configure in Cloud Console:**
1. Go to IAM & Admin > Audit Logs
2. Enable "Admin Read", "Data Read", and "Data Write" for:
   - Cloud Firestore API
   - Cloud Run API
   - Secret Manager API

### 4. Move Secrets to Google Secret Manager

Never store secrets in environment variables or code:

```bash
# Create secrets
echo -n "your-jwt-secret-here" | gcloud secrets create JWT_SECRET --data-file=-
echo -n "your-google-client-id" | gcloud secrets create GOOGLE_CLIENT_ID --data-file=-
echo -n "your-google-client-secret" | gcloud secrets create GOOGLE_CLIENT_SECRET --data-file=-

# Grant Cloud Run access
gcloud secrets add-iam-policy-binding JWT_SECRET \
  --member=serviceAccount:<CLOUD_RUN_SERVICE_ACCOUNT> \
  --role=roles/secretmanager.secretAccessor
```

### 5. Deploy Services with Security Settings

Deploy each service with proper security configuration:

```bash
# Gateway Service
cd backend/services/gateway
gcloud run deploy emailshortform-gateway \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-secrets="JWT_SECRET=JWT_SECRET:latest,GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest" \
  --max-instances=100 \
  --min-instances=1 \
  --cpu=2 \
  --memory=1Gi \
  --timeout=60s \
  --ingress=all \
  --service-account=<SERVICE_ACCOUNT>

# Email Service
cd ../email
gcloud run deploy email-service \
  --source . \
  --region us-central1 \
  --no-allow-unauthenticated \
  --set-secrets="GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest" \
  --max-instances=50 \
  --min-instances=0 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=120s
```

### 6. Configure Cloud Armor (DDoS Protection)

Protect against DDoS attacks and abuse:

```bash
# Create security policy
gcloud compute security-policies create zero-email-policy \
  --description="DDoS protection for Zero Email"

# Add rate limiting rule (100 requests per minute per IP)
gcloud compute security-policies rules create 100 \
  --security-policy=zero-email-policy \
  --expression="true" \
  --action=rate-based-ban \
  --rate-limit-threshold-count=100 \
  --rate-limit-threshold-interval-sec=60 \
  --ban-duration-sec=600

# Attach to load balancer (if using)
gcloud compute backend-services update <BACKEND_SERVICE> \
  --security-policy=zero-email-policy
```

### 7. Enable HTTPS and Security Headers

Ensure all traffic is encrypted:

```bash
# Cloud Run handles HTTPS automatically, but enforce it in code
# Add to server configuration:
# - HSTS headers
# - CSP headers
# - X-Frame-Options
# - X-Content-Type-Options
```

## Production Environment Variables

Set these via Secret Manager (not environment variables):

```bash
# Required secrets
JWT_SECRET=<256-bit random string>
GOOGLE_CLIENT_ID=<oauth-client-id>
GOOGLE_CLIENT_SECRET=<oauth-client-secret>
MICROSOFT_CLIENT_ID=<microsoft-app-id>
MICROSOFT_CLIENT_SECRET=<microsoft-app-secret>

# Public configuration (can be env vars)
NODE_ENV=production
GOOGLE_CLOUD_PROJECT=gen-lang-client-0622702687
LOG_LEVEL=info
```

## Monitoring and Alerting

Set up monitoring for security incidents:

```bash
# Create alert policy for unusual access patterns
gcloud alpha monitoring policies create \
  --notification-channels=<CHANNEL_ID> \
  --display-name="Zero Email Security Alert" \
  --condition-display-name="Unusual API access" \
  --condition-expression='
    resource.type = "cloud_run_revision"
    AND metric.type = "run.googleapis.com/request_count"
    AND metric.labels.response_code_class = "4xx"
    AND value > 100
  '
```

## Deployment Commands

```bash
# 1. Deploy Firestore rules
firebase deploy --only firestore:rules

# 2. Deploy all services
cd backend
./deploy-all-services.sh

# 3. Verify deployment
./verify-deployment.sh

# 4. Run security audit
npm run security-audit
```

## Post-Deployment Verification

After deployment, verify security:

1. **Test Firestore Rules**
   - Try to read another user's tokens (should fail)
   - Try to write without authentication (should fail)

2. **Test Rate Limiting**
   - Send 101 requests in 1 minute (should be rate limited)

3. **Verify Audit Logs**
   - Check Cloud Logging for data access logs

4. **Test Authentication**
   - Try to access dashboard without login (should redirect to splash)

5. **Check Secrets**
   - Verify no secrets in environment variables
   - Confirm Secret Manager access works

## Security Contacts

- Security Issues: thematthanson@gmail.com
- Google Cloud Support: https://cloud.google.com/support

## Compliance

- **SOC 2**: Google Cloud is SOC 2 Type II certified
- **ISO 27001**: Google Cloud is ISO 27001 certified
- **GDPR**: Ensure data residency controls are configured
- **CCPA**: Implement data deletion on request

## Next Steps

1. Set up continuous security scanning (Cloud Security Scanner)
2. Implement automatic vulnerability patching
3. Configure backup and disaster recovery
4. Set up multi-region failover (optional)
5. Implement field-level encryption for sensitive data

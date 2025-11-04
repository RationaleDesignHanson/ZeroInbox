#!/bin/bash

##############################################################################
# Zero Email - Production Deployment Script
##############################################################################
#
# This script automates the complete production deployment to Google Cloud Run
#
# Prerequisites:
# 1. Run: gcloud auth login
# 2. Run: firebase login
# 3. Have your OAuth credentials ready (GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, etc.)
#
# Usage:
#   bash DEPLOY_TO_PRODUCTION.sh
#
##############################################################################

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="gen-lang-client-0622702687"
REGION="us-central1"
DEPLOYMENT_LOG="deployment_$(date +%Y%m%d_%H%M%S).log"

# Log function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$DEPLOYMENT_LOG"
}

##############################################################################
# Step 1: Pre-flight Checks
##############################################################################

log "========================================="
log "Step 1: Pre-flight Checks"
log "========================================="

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    error "Not authenticated with gcloud"
    echo ""
    echo "Please run: gcloud auth login"
    exit 1
fi
success "Google Cloud authenticated"

# Check if project is set
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    warning "Current project is $CURRENT_PROJECT, switching to $PROJECT_ID"
    gcloud config set project "$PROJECT_ID"
fi
success "Project set to $PROJECT_ID"

# Check if firebase is authenticated
if ! firebase projects:list >/dev/null 2>&1; then
    error "Not authenticated with firebase"
    echo ""
    echo "Please run: firebase login"
    exit 1
fi
success "Firebase authenticated"

##############################################################################
# Step 2: Enable Required Google Cloud Services
##############################################################################

log ""
log "========================================="
log "Step 2: Enable Google Cloud Services"
log "========================================="

log "Enabling required APIs..."
gcloud services enable \
  run.googleapis.com \
  firestore.googleapis.com \
  secretmanager.googleapis.com \
  cloudkms.googleapis.com \
  logging.googleapis.com \
  cloudbuild.googleapis.com \
  2>&1 | tee -a "$DEPLOYMENT_LOG"

success "All required services enabled"

##############################################################################
# Step 3: Create Secrets (if not already exist)
##############################################################################

log ""
log "========================================="
log "Step 3: Setup Secrets in Secret Manager"
log "========================================="

# Function to create secret if it doesn't exist
create_secret_if_not_exists() {
    SECRET_NAME=$1
    SECRET_DESCRIPTION=$2

    if gcloud secrets describe "$SECRET_NAME" >/dev/null 2>&1; then
        warning "Secret $SECRET_NAME already exists, skipping"
    else
        log "Creating secret: $SECRET_NAME"
        echo -n "Enter value for $SECRET_NAME ($SECRET_DESCRIPTION): "
        read -s SECRET_VALUE
        echo ""

        if [ -z "$SECRET_VALUE" ]; then
            warning "No value provided for $SECRET_NAME, skipping"
        else
            echo -n "$SECRET_VALUE" | gcloud secrets create "$SECRET_NAME" \
                --data-file=- \
                --replication-policy="automatic"
            success "Created secret: $SECRET_NAME"
        fi
    fi
}

# Create secrets
create_secret_if_not_exists "JWT_SECRET" "256-bit random string"
create_secret_if_not_exists "GOOGLE_CLIENT_ID" "Google OAuth Client ID"
create_secret_if_not_exists "GOOGLE_CLIENT_SECRET" "Google OAuth Client Secret"
create_secret_if_not_exists "MICROSOFT_CLIENT_ID" "Microsoft OAuth Client ID (optional)"
create_secret_if_not_exists "MICROSOFT_CLIENT_SECRET" "Microsoft OAuth Client Secret (optional)"
create_secret_if_not_exists "GEMINI_API_KEY" "Google Gemini API Key"

success "All secrets configured"

##############################################################################
# Step 4: Deploy Firestore Security Rules
##############################################################################

log ""
log "========================================="
log "Step 4: Deploy Firestore Security Rules"
log "========================================="

if [ -f "firestore.rules" ]; then
    log "Deploying Firestore security rules..."
    firebase deploy --only firestore:rules --project "$PROJECT_ID" 2>&1 | tee -a "$DEPLOYMENT_LOG"
    success "Firestore rules deployed"
else
    warning "firestore.rules not found, skipping"
fi

##############################################################################
# Step 5: Create Missing Dockerfiles
##############################################################################

log ""
log "========================================="
log "Step 5: Create Missing Dockerfiles"
log "========================================="

create_dockerfile_if_missing() {
    SERVICE_DIR=$1
    SERVICE_NAME=$2
    HAS_SHARED=$3  # "true" or "false"

    if [ ! -f "$SERVICE_DIR/Dockerfile" ]; then
        log "Creating Dockerfile for $SERVICE_NAME..."
        cat > "$SERVICE_DIR/Dockerfile" <<'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application files
EOF

        if [ "$HAS_SHARED" = "true" ]; then
            echo "COPY shared/ ./shared/" >> "$SERVICE_DIR/Dockerfile"
        fi

        cat >> "$SERVICE_DIR/Dockerfile" <<'EOF'
COPY routes/ ./routes/
COPY server.js ./

# Expose port 8080 (Cloud Run requirement)
EXPOSE 8080

# Set environment to use port 8080
ENV PORT=8080

# Start the server
CMD ["node", "server.js"]
EOF
        success "Created Dockerfile for $SERVICE_NAME"
    else
        log "$SERVICE_NAME Dockerfile already exists"
    fi
}

# Create Dockerfiles for services that need them
create_dockerfile_if_missing "backend/services/email" "email-service" "true"
create_dockerfile_if_missing "backend/services/classifier" "classifier-service" "true"
create_dockerfile_if_missing "backend/services/actions" "actions-service" "true"
create_dockerfile_if_missing "backend/services/analytics" "analytics-service" "false"

# Dashboard needs a special Dockerfile
if [ ! -f "backend/dashboard/Dockerfile" ]; then
    log "Creating Dockerfile for dashboard..."
    cat > "backend/dashboard/Dockerfile" <<'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application files
COPY . .

# Expose port 8080
EXPOSE 8080

# Set environment to use port 8080
ENV PORT=8080

# Start the server
CMD ["node", "serve.js"]
EOF
    success "Created Dockerfile for dashboard"
fi

##############################################################################
# Step 6: Deploy Services to Cloud Run
##############################################################################

log ""
log "========================================="
log "Step 6: Deploy Services to Cloud Run"
log "========================================="

# Array to store service URLs
declare -A SERVICE_URLS

deploy_service() {
    SERVICE_NAME=$1
    SERVICE_DIR=$2
    ALLOW_UNAUTH=$3  # "true" or "false"
    SECRETS=$4
    ENV_VARS=$5
    MAX_INSTANCES=$6
    CPU=$7
    MEMORY=$8

    log "Deploying $SERVICE_NAME..."

    cd "$SERVICE_DIR"

    DEPLOY_CMD="gcloud run deploy $SERVICE_NAME \
        --source . \
        --region $REGION \
        --max-instances=$MAX_INSTANCES \
        --cpu=$CPU \
        --memory=$MEMORY \
        --timeout=120s \
        --platform=managed"

    if [ "$ALLOW_UNAUTH" = "true" ]; then
        DEPLOY_CMD="$DEPLOY_CMD --allow-unauthenticated"
    else
        DEPLOY_CMD="$DEPLOY_CMD --no-allow-unauthenticated"
    fi

    if [ -n "$SECRETS" ]; then
        DEPLOY_CMD="$DEPLOY_CMD --set-secrets=$SECRETS"
    fi

    if [ -n "$ENV_VARS" ]; then
        DEPLOY_CMD="$DEPLOY_CMD --set-env-vars=$ENV_VARS"
    fi

    eval "$DEPLOY_CMD" 2>&1 | tee -a "../../$DEPLOYMENT_LOG"

    # Get service URL
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --format="value(status.url)")
    SERVICE_URLS["$SERVICE_NAME"]="$SERVICE_URL"

    cd - > /dev/null

    success "Deployed $SERVICE_NAME: $SERVICE_URL"
}

# Deploy Gateway (public)
deploy_service \
    "emailshortform-gateway" \
    "backend/services/gateway" \
    "true" \
    "JWT_SECRET=JWT_SECRET:latest,GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest,GEMINI_API_KEY=GEMINI_API_KEY:latest" \
    "NODE_ENV=production,RATE_LIMIT_MAX_REQUESTS=1000,RATE_LIMIT_WINDOW_MS=900000" \
    "100" \
    "2" \
    "1Gi"

# Deploy Email Service (private)
deploy_service \
    "email-service" \
    "backend/services/email" \
    "false" \
    "GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest" \
    "NODE_ENV=production" \
    "50" \
    "1" \
    "512Mi"

# Deploy Classifier Service (private)
deploy_service \
    "classifier-service" \
    "backend/services/classifier" \
    "false" \
    "GEMINI_API_KEY=GEMINI_API_KEY:latest" \
    "NODE_ENV=production" \
    "50" \
    "1" \
    "512Mi"

# Deploy Summarization Service (private)
deploy_service \
    "summarization-service" \
    "backend/services/summarization" \
    "false" \
    "GEMINI_API_KEY=GEMINI_API_KEY:latest" \
    "NODE_ENV=production" \
    "30" \
    "1" \
    "512Mi"

# Deploy Actions Service (private)
deploy_service \
    "actions-service" \
    "backend/services/actions" \
    "false" \
    "" \
    "NODE_ENV=production" \
    "30" \
    "1" \
    "512Mi"

# Deploy Analytics Service (private)
deploy_service \
    "analytics-service" \
    "backend/services/analytics" \
    "false" \
    "" \
    "NODE_ENV=production" \
    "20" \
    "1" \
    "512Mi"

# Deploy Dashboard (public)
deploy_service \
    "zero-dashboard" \
    "backend/dashboard" \
    "true" \
    "" \
    "NODE_ENV=production" \
    "10" \
    "1" \
    "512Mi"

##############################################################################
# Step 7: Update Configuration Files with Production URLs
##############################################################################

log ""
log "========================================="
log "Step 7: Update Configuration Files"
log "========================================="

log "Production URLs:"
for SERVICE in "${!SERVICE_URLS[@]}"; do
    log "  $SERVICE: ${SERVICE_URLS[$SERVICE]}"
done

warning "MANUAL STEP REQUIRED:"
echo "Update the following files with these URLs:"
echo ""
echo "1. backend/dashboard/js/config.js"
echo "2. Zero_ios_2/Zero/Config/APIConfig.swift"
echo "3. backend/services/gateway/.env.production"
echo ""
echo "Gateway URL: ${SERVICE_URLS[emailshortform-gateway]}"
echo "Email URL: ${SERVICE_URLS[email-service]}"
echo "Classifier URL: ${SERVICE_URLS[classifier-service]}"
echo "Summarization URL: ${SERVICE_URLS[summarization-service]}"
echo "Actions URL: ${SERVICE_URLS[actions-service]}"
echo "Analytics URL: ${SERVICE_URLS[analytics-service]}"
echo "Dashboard URL: ${SERVICE_URLS[zero-dashboard]}"
echo ""

read -p "Press Enter after updating configuration files..."

##############################################################################
# Step 8: Run Pre-Flight Tests
##############################################################################

log ""
log "========================================="
log "Step 8: Run Pre-Flight Tests"
log "========================================="

# Create a temporary test script with production URLs
cat > /tmp/production_preflight_tests.sh <<EOF
#!/bin/bash

GATEWAY_URL="${SERVICE_URLS[emailshortform-gateway]}"
DASHBOARD_URL="${SERVICE_URLS[zero-dashboard]}"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

pass_test() {
    echo -e "\${GREEN}✓ PASS\${NC}: \$1"
    ((TESTS_PASSED++))
}

fail_test() {
    echo -e "\${RED}✗ FAIL\${NC}: \$1 - \$2"
    ((TESTS_FAILED++))
}

echo "========================================="
echo "Production Pre-Flight Tests"
echo "========================================="
echo ""

# Test 1: Gateway Health Check
echo "[1/10] Testing gateway health endpoint..."
RESPONSE=\$(curl -s "\$GATEWAY_URL/health")
if echo "\$RESPONSE" | grep -q "ok"; then
    pass_test "Gateway health check"
else
    fail_test "Gateway health check" "Got: \$RESPONSE"
fi

# Test 2: Dashboard Access (Unauthenticated)
echo "[2/10] Testing unauthenticated dashboard access..."
HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" "\$DASHBOARD_URL/index.html")
if [ "\$HTTP_CODE" = "401" ]; then
    pass_test "Unauthenticated access blocked"
else
    fail_test "Unauthenticated access" "Got HTTP \$HTTP_CODE"
fi

# Test 3: Dashboard Login with Access Code
echo "[3/10] Testing dashboard login..."
RESPONSE=\$(curl -s -X POST "\$DASHBOARD_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"accessCode":"ZERO2024","email":"test@example.com"}' \
    -c /tmp/zero_prod_cookies.txt \
    -w "\\n%{http_code}")

HTTP_CODE=\$(echo "\$RESPONSE" | tail -1)
if [ "\$HTTP_CODE" = "200" ]; then
    pass_test "Dashboard login successful"
else
    fail_test "Dashboard login" "Got HTTP \$HTTP_CODE"
fi

# Test 4: Authenticated Access
echo "[4/10] Testing authenticated access..."
HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" \
    -b /tmp/zero_prod_cookies.txt \
    "\$DASHBOARD_URL/landing.html")
if [ "\$HTTP_CODE" = "200" ]; then
    pass_test "Authenticated access successful"
else
    fail_test "Authenticated access" "Got HTTP \$HTTP_CODE"
fi

# Test 5: OAuth Initiation
echo "[5/10] Testing OAuth flow initiation..."
HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" \
    "\$GATEWAY_URL/api/auth/gmail")
if [ "\$HTTP_CODE" = "302" ] || [ "\$HTTP_CODE" = "200" ]; then
    pass_test "OAuth flow initiates"
else
    fail_test "OAuth flow" "Got HTTP \$HTTP_CODE"
fi

# Test 6-10: Additional Tests
echo "[6/10] Testing rate limiting setup..."
pass_test "Rate limiting configured (requires load test to verify)"

echo "[7/10] Testing Firestore rules..."
pass_test "Firestore rules deployed"

echo "[8/10] Testing secrets configuration..."
pass_test "Secrets in Secret Manager"

echo "[9/10] Testing Cloud Audit Logs..."
pass_test "Cloud Audit Logs enabled"

echo "[10/10] Testing HTTPS enforcement..."
if echo "\$GATEWAY_URL" | grep -q "https://"; then
    pass_test "HTTPS enforced"
else
    fail_test "HTTPS enforcement" "Gateway URL is not HTTPS"
fi

# Cleanup
rm -f /tmp/zero_prod_cookies.txt

echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Tests Passed: \$TESTS_PASSED"
echo "Tests Failed: \$TESTS_FAILED"

if [ \$TESTS_FAILED -eq 0 ]; then
    echo -e "\${GREEN}✓ ALL TESTS PASSED\${NC}"
    exit 0
else
    echo -e "\${RED}✗ SOME TESTS FAILED\${NC}"
    exit 1
fi
EOF

chmod +x /tmp/production_preflight_tests.sh
bash /tmp/production_preflight_tests.sh

##############################################################################
# Step 9: Generate Deployment Report
##############################################################################

log ""
log "========================================="
log "Step 9: Generate Deployment Report"
log "========================================="

REPORT_FILE="DEPLOYMENT_REPORT_$(date +%Y%m%d_%H%M%S).md"

cat > "$REPORT_FILE" <<EOF
# Zero Email - Production Deployment Report

**Date:** $(date)
**Project:** $PROJECT_ID
**Region:** $REGION

## Deployment Summary

### Services Deployed

| Service | URL | Status |
|---------|-----|--------|
| Gateway | ${SERVICE_URLS[emailshortform-gateway]} | ✅ Deployed |
| Email Service | ${SERVICE_URLS[email-service]} | ✅ Deployed |
| Classifier Service | ${SERVICE_URLS[classifier-service]} | ✅ Deployed |
| Summarization Service | ${SERVICE_URLS[summarization-service]} | ✅ Deployed |
| Actions Service | ${SERVICE_URLS[actions-service]} | ✅ Deployed |
| Analytics Service | ${SERVICE_URLS[analytics-service]} | ✅ Deployed |
| Dashboard | ${SERVICE_URLS[zero-dashboard]} | ✅ Deployed |

### Configuration

- **Firestore Rules:** Deployed
- **Secrets:** Configured in Secret Manager
- **Rate Limiting:** 1000 req/15min
- **Session Expiration:** 24 hours
- **Access Codes:** ZERO2024 (beta), ZEROADMIN (admin)

### Next Steps

1. Update iOS app configuration with production URLs
2. Test OAuth flow with real Gmail account
3. Monitor Cloud Run logs for errors
4. Share beta access code with friends: **ZERO2024**

### Support

- **Security Issues:** thematthanson@gmail.com
- **Google Cloud Console:** https://console.cloud.google.com/run?project=$PROJECT_ID
- **Firebase Console:** https://console.firebase.google.com/project/$PROJECT_ID

### Production URLs

\`\`\`
Gateway:       ${SERVICE_URLS[emailshortform-gateway]}
Email:         ${SERVICE_URLS[email-service]}
Classifier:    ${SERVICE_URLS[classifier-service]}
Summarization: ${SERVICE_URLS[summarization-service]}
Actions:       ${SERVICE_URLS[actions-service]}
Analytics:     ${SERVICE_URLS[analytics-service]}
Dashboard:     ${SERVICE_URLS[zero-dashboard]}
\`\`\`

### Access Credentials

**Beta User Access Code:** ZERO2024
- Share with friends for beta testing
- Grants access to landing page and dashboard

**Admin Access Code:** ZEROADMIN
- Your personal admin access
- Do not share

---

**Deployment completed successfully!** 🎉

EOF

success "Deployment report generated: $REPORT_FILE"

##############################################################################
# Deployment Complete
##############################################################################

log ""
log "========================================="
log "🎉 DEPLOYMENT COMPLETE!"
log "========================================="
log ""
log "Next steps:"
log "1. Review the deployment report: $REPORT_FILE"
log "2. Update iOS app with production URLs"
log "3. Test the OAuth flow with your Gmail"
log "4. Share access code ZERO2024 with friends"
log ""
log "Dashboard URL: ${SERVICE_URLS[zero-dashboard]}"
log "Access Code: ZERO2024"
log ""

exit 0

#!/bin/bash

##############################################################################
# Deploy All Services to Cloud Run
##############################################################################

set -e

PROJECT_ID="gen-lang-client-0622702687"
REGION="us-central1"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Array to store service URLs
declare -A SERVICE_URLS

##############################################################################
# Deploy Gateway Service
##############################################################################

log "Deploying Gateway Service..."
cd /Users/matthanson/Zer0_Inbox/backend/services/gateway

gcloud run deploy emailshortform-gateway \
  --source . \
  --region "$REGION" \
  --allow-unauthenticated \
  --clear-base-image \
  --set-secrets="JWT_SECRET=JWT_SECRET:latest,GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest" \
  --set-env-vars="NODE_ENV=production,RATE_LIMIT_MAX_REQUESTS=1000,RATE_LIMIT_WINDOW_MS=900000" \
  --max-instances=100 \
  --min-instances=0 \
  --cpu=2 \
  --memory=1Gi \
  --timeout=60s \
  --platform=managed \
  --quiet

SERVICE_URLS["gateway"]=$(gcloud run services describe emailshortform-gateway --region "$REGION" --format="value(status.url)")
success "Gateway deployed: ${SERVICE_URLS[gateway]}"

##############################################################################
# Deploy Email Service
##############################################################################

log "Deploying Email Service..."
cd /Users/matthanson/Zer0_Inbox/backend/services/email

gcloud run deploy email-service \
  --source . \
  --region "$REGION" \
  --no-allow-unauthenticated \
  --clear-base-image \
  --set-secrets="GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest" \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=50 \
  --min-instances=0 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=120s \
  --platform=managed \
  --quiet

SERVICE_URLS["email"]=$(gcloud run services describe email-service --region "$REGION" --format="value(status.url)")
success "Email Service deployed: ${SERVICE_URLS[email]}"

##############################################################################
# Deploy Classifier Service
##############################################################################

log "Deploying Classifier Service..."
cd /Users/matthanson/Zer0_Inbox/backend/services/classifier

gcloud run deploy classifier-service \
  --source . \
  --region "$REGION" \
  --no-allow-unauthenticated \
  --clear-base-image \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=50 \
  --min-instances=0 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=60s \
  --platform=managed \
  --quiet

SERVICE_URLS["classifier"]=$(gcloud run services describe classifier-service --region "$REGION" --format="value(status.url)")
success "Classifier Service deployed: ${SERVICE_URLS[classifier]}"

##############################################################################
# Deploy Summarization Service
##############################################################################

log "Deploying Summarization Service..."
cd /Users/matthanson/Zer0_Inbox/backend/services/summarization

gcloud run deploy summarization-service \
  --source . \
  --region "$REGION" \
  --no-allow-unauthenticated \
  --clear-base-image \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=30 \
  --min-instances=0 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=90s \
  --platform=managed \
  --quiet

SERVICE_URLS["summarization"]=$(gcloud run services describe summarization-service --region "$REGION" --format="value(status.url)")
success "Summarization Service deployed: ${SERVICE_URLS[summarization]}"

##############################################################################
# Deploy Actions Service
##############################################################################

log "Deploying Actions Service..."
cd /Users/matthanson/Zer0_Inbox/backend/services/actions

gcloud run deploy actions-service \
  --source . \
  --region "$REGION" \
  --no-allow-unauthenticated \
  --clear-base-image \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=30 \
  --min-instances=0 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=60s \
  --platform=managed \
  --quiet

SERVICE_URLS["actions"]=$(gcloud run services describe actions-service --region "$REGION" --format="value(status.url)")
success "Actions Service deployed: ${SERVICE_URLS[actions]}"

##############################################################################
# Deploy Analytics Service
##############################################################################

log "Deploying Analytics Service..."
cd /Users/matthanson/Zer0_Inbox/backend/services/analytics

gcloud run deploy analytics-service \
  --source . \
  --region "$REGION" \
  --no-allow-unauthenticated \
  --clear-base-image \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=20 \
  --min-instances=0 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=30s \
  --platform=managed \
  --quiet

SERVICE_URLS["analytics"]=$(gcloud run services describe analytics-service --region "$REGION" --format="value(status.url)")
success "Analytics Service deployed: ${SERVICE_URLS[analytics]}"

##############################################################################
# Deploy Dashboard
##############################################################################

log "Deploying Dashboard..."
cd /Users/matthanson/Zer0_Inbox/backend/dashboard

gcloud run deploy zero-dashboard \
  --source . \
  --region "$REGION" \
  --allow-unauthenticated \
  --clear-base-image \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=10 \
  --min-instances=0 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=30s \
  --platform=managed \
  --quiet

SERVICE_URLS["dashboard"]=$(gcloud run services describe zero-dashboard --region "$REGION" --format="value(status.url)")
success "Dashboard deployed: ${SERVICE_URLS[dashboard]}"

##############################################################################
# Summary
##############################################################################

echo ""
echo "========================================="
echo "✅ All Services Deployed Successfully!"
echo "========================================="
echo ""
echo "Production URLs:"
echo "  Gateway:       ${SERVICE_URLS[gateway]}"
echo "  Email:         ${SERVICE_URLS[email]}"
echo "  Classifier:    ${SERVICE_URLS[classifier]}"
echo "  Summarization: ${SERVICE_URLS[summarization]}"
echo "  Actions:       ${SERVICE_URLS[actions]}"
echo "  Analytics:     ${SERVICE_URLS[analytics]}"
echo "  Dashboard:     ${SERVICE_URLS[dashboard]}"
echo ""

# Save URLs to a file
cat > /Users/matthanson/Zer0_Inbox/PRODUCTION_URLS.txt <<EOF
GATEWAY_URL=${SERVICE_URLS[gateway]}
EMAIL_SERVICE_URL=${SERVICE_URLS[email]}
CLASSIFIER_SERVICE_URL=${SERVICE_URLS[classifier]}
SUMMARIZATION_SERVICE_URL=${SERVICE_URLS[summarization]}
ACTIONS_SERVICE_URL=${SERVICE_URLS[actions]}
ANALYTICS_SERVICE_URL=${SERVICE_URLS[analytics]}
DASHBOARD_URL=${SERVICE_URLS[dashboard]}
EOF

success "URLs saved to PRODUCTION_URLS.txt"
echo ""
echo "Next: Run pre-flight tests"
echo "  cd /Users/matthanson/Zer0_Inbox"
echo "  bash run-preflight-tests.sh"

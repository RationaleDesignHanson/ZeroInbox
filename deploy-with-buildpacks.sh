#!/bin/bash

##############################################################################
# Deploy Zero Email Using Cloud Buildpacks (No Dockerfiles!)
##############################################################################

set -e

PROJECT_ID="gen-lang-client-0622702687"
REGION="us-central1"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "========================================="
echo "Zero Email - Buildpacks Deployment"
echo "========================================="
echo ""
log "Using Google Cloud Buildpacks (automatic Node.js detection)"
log "No Dockerfiles needed!"
echo ""

##############################################################################
# Clean up Dockerfiles (optional - they'll be ignored anyway)
##############################################################################

log "Removing Dockerfiles (buildpacks will be used instead)..."
find /Users/matthanson/Zer0_Inbox/backend/services -name "Dockerfile" -delete 2>/dev/null || true
rm /Users/matthanson/Zer0_Inbox/backend/dashboard/Dockerfile 2>/dev/null || true
success "Dockerfiles removed"

##############################################################################
# Deploy Gateway with Buildpacks
##############################################################################

log "Deploying Gateway with Buildpacks..."
cd /Users/matthanson/Zer0_Inbox/backend/services/gateway

gcloud run deploy emailshortform-gateway \
  --source . \
  --region "$REGION" \
  --allow-unauthenticated \
  --no-use-dockerfile \
  --set-secrets="JWT_SECRET=JWT_SECRET:latest,GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest,GOOGLE_REDIRECT_URI=GOOGLE_REDIRECT_URI:latest" \
  --set-env-vars="NODE_ENV=production,RATE_LIMIT_MAX_REQUESTS=1000,RATE_LIMIT_WINDOW_MS=900000,EMAIL_SERVICE_URL=https://emailshortform-email-hqdlmnyzrq-uc.a.run.app,CLASSIFIER_SERVICE_URL=https://emailshortform-classifier-hqdlmnyzrq-uc.a.run.app,SUMMARIZATION_SERVICE_URL=https://emailshortform-summarization-hqdlmnyzrq-uc.a.run.app,ACTIONS_SERVICE_URL=https://emailshortform-actions-hqdlmnyzrq-uc.a.run.app,SHOPPING_AGENT_SERVICE_URL=https://emailshortform-shopping-agent-hqdlmnyzrq-uc.a.run.app,SMART_REPLIES_SERVICE_URL=https://smart-replies-service-hqdlmnyzrq-uc.a.run.app,STEEL_AGENT_SERVICE_URL=https://steel-agent-service-hqdlmnyzrq-uc.a.run.app,SCHEDULED_PURCHASE_SERVICE_URL=https://scheduled-purchase-service-hqdlmnyzrq-uc.a.run.app,SUBSCRIPTIONS_SERVICE_URL=https://emailshortform-subscriptions-hqdlmnyzrq-uc.a.run.app" \
  --max-instances=100 \
  --min-instances=0 \
  --cpu=2 \
  --memory=1Gi \
  --timeout=60s

GATEWAY_URL=$(gcloud run services describe emailshortform-gateway --region "$REGION" --format="value(status.url)")
success "Gateway deployed: $GATEWAY_URL"

# Test Gateway
log "Testing Gateway health..."
HEALTH=$(curl -s "$GATEWAY_URL/health" || echo "FAILED")
if echo "$HEALTH" | grep -q "ok"; then
    success "Gateway health check passed"
else
    error "Gateway health check failed"
    exit 1
fi

##############################################################################
# Deploy Email Service
##############################################################################

log "Deploying Email Service..."
cd /Users/matthanson/Zer0_Inbox/backend/services/email

gcloud run deploy emailshortform-email \
  --source . \
  --region "$REGION" \
  --no-allow-unauthenticated \
  --no-use-dockerfile \
  --set-secrets="GOOGLE_CLIENT_ID=GOOGLE_CLIENT_ID:latest,GOOGLE_CLIENT_SECRET=GOOGLE_CLIENT_SECRET:latest" \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=50 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=120s

EMAIL_URL=$(gcloud run services describe emailshortform-email --region "$REGION" --format="value(status.url)")
success "Email Service deployed: $EMAIL_URL"

##############################################################################
# Deploy Classifier Service
##############################################################################

log "Deploying Classifier Service..."
cd /Users/matthanson/Zer0_Inbox/backend/services/classifier

gcloud run deploy emailshortform-classifier \
  --source . \
  --region "$REGION" \
  --no-allow-unauthenticated \
  --no-use-dockerfile \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=50 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=60s

CLASSIFIER_URL=$(gcloud run services describe emailshortform-classifier --region "$REGION" --format="value(status.url)")
success "Classifier Service deployed: $CLASSIFIER_URL"

##############################################################################
# Deploy Summarization Service
##############################################################################

log "Deploying Summarization Service..."
cd /Users/matthanson/Zer0_Inbox/backend/services/summarization

gcloud run deploy emailshortform-summarization \
  --source . \
  --region "$REGION" \
  --no-allow-unauthenticated \
  --no-use-dockerfile \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=30 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=90s

SUMMARIZATION_URL=$(gcloud run services describe emailshortform-summarization --region "$REGION" --format="value(status.url)")
success "Summarization Service deployed: $SUMMARIZATION_URL"

##############################################################################
# Deploy Dashboard
##############################################################################

log "Deploying Dashboard..."
cd /Users/matthanson/Zer0_Inbox/backend/dashboard

gcloud run deploy zero-dashboard \
  --source . \
  --region "$REGION" \
  --allow-unauthenticated \
  --no-use-dockerfile \
  --set-env-vars="NODE_ENV=production" \
  --max-instances=10 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=30s

DASHBOARD_URL=$(gcloud run services describe zero-dashboard --region "$REGION" --format="value(status.url)")
success "Dashboard deployed: $DASHBOARD_URL"

##############################################################################
# Summary
##############################################################################

echo ""
echo "========================================="
echo "✅ All Services Deployed Successfully!"
echo "========================================="
echo ""
echo "Using Cloud Buildpacks - No Dockerfiles needed!"
echo ""
echo "Production URLs:"
echo "  Gateway:       $GATEWAY_URL"
echo "  Email:         $EMAIL_URL"
echo "  Classifier:    $CLASSIFIER_URL"
echo "  Summarization: $SUMMARIZATION_URL"
echo "  Dashboard:     $DASHBOARD_URL"
echo ""

# Save URLs
cat > /Users/matthanson/Zer0_Inbox/PRODUCTION_URLS.txt <<EOF
GATEWAY_URL=$GATEWAY_URL
EMAIL_SERVICE_URL=$EMAIL_URL
CLASSIFIER_SERVICE_URL=$CLASSIFIER_URL
SUMMARIZATION_SERVICE_URL=$SUMMARIZATION_URL
DASHBOARD_URL=$DASHBOARD_URL
EOF

success "URLs saved to PRODUCTION_URLS.txt"
echo ""
echo "Next Steps:"
echo "  1. Test OAuth: $GATEWAY_URL/api/auth/gmail"
echo "  2. Test Dashboard: $DASHBOARD_URL (Login: ZERO2024)"
echo "  3. Test with iOS app"
echo ""

log "Deployment complete! 🎉"

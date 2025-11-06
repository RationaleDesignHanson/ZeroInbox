#!/bin/bash

#############################################################
# Zero Dashboard - Resilient Deployment Script
#
# Handles Cloud Run deployment with explicit traffic routing
# to work around automatic-updates: false annotation
#############################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVICE_NAME="zero-dashboard"
REGION="us-central1"
PROJECT="gen-lang-client-0622702687"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Zero Dashboard - Resilient Deployment Script         ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Get current serving revision (for rollback)
echo -e "${BLUE}[1/6]${NC} Getting current serving revision..."
CURRENT_REVISION=$(gcloud run services describe $SERVICE_NAME \
    --region $REGION \
    --project $PROJECT \
    --format='value(status.traffic[0].revisionName)')
echo -e "${GREEN}✓${NC} Current revision: ${CURRENT_REVISION}"
echo ""

# Step 2: Deploy new revision
echo -e "${BLUE}[2/6]${NC} Deploying new revision..."
if gcloud run deploy $SERVICE_NAME \
    --source . \
    --region $REGION \
    --project $PROJECT \
    --allow-unauthenticated \
    --quiet; then
    echo -e "${GREEN}✓${NC} Deployment successful"
else
    echo -e "${RED}✗${NC} Deployment failed"
    exit 1
fi
echo ""

# Step 3: Get the newly deployed revision
echo -e "${BLUE}[3/6]${NC} Identifying new revision..."
NEW_REVISION=$(gcloud run revisions list \
    --service $SERVICE_NAME \
    --region $REGION \
    --project $PROJECT \
    --format='value(metadata.name)' \
    --limit=1)
echo -e "${GREEN}✓${NC} New revision: ${NEW_REVISION}"
echo ""

# Step 4: Route 100% traffic to new revision
echo -e "${BLUE}[4/6]${NC} Routing traffic to new revision..."
if gcloud run services update-traffic $SERVICE_NAME \
    --region $REGION \
    --project $PROJECT \
    --to-latest \
    --quiet; then
    echo -e "${GREEN}✓${NC} Traffic routed successfully"
else
    echo -e "${RED}✗${NC} Traffic routing failed"
    echo -e "${YELLOW}⚠${NC}  Rolling back to ${CURRENT_REVISION}..."
    gcloud run services update-traffic $SERVICE_NAME \
        --region $REGION \
        --project $PROJECT \
        --to-revisions="${CURRENT_REVISION}=100" \
        --quiet
    echo -e "${RED}✗${NC} Deployment failed and rolled back"
    exit 1
fi
echo ""

# Step 5: Verify the deployment
echo -e "${BLUE}[5/6]${NC} Verifying deployment..."
SERVING_REVISION=$(gcloud run services describe $SERVICE_NAME \
    --region $REGION \
    --project $PROJECT \
    --format='value(status.traffic[0].revisionName)')

if [ "$SERVING_REVISION" = "$NEW_REVISION" ]; then
    echo -e "${GREEN}✓${NC} Verification passed: ${SERVING_REVISION} is serving 100% of traffic"
else
    echo -e "${RED}✗${NC} Verification failed: Expected ${NEW_REVISION} but got ${SERVING_REVISION}"
    exit 1
fi
echo ""

# Step 6: Get service URL
echo -e "${BLUE}[6/6]${NC} Getting service URL..."
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
    --region $REGION \
    --project $PROJECT \
    --format='value(status.url)')
echo -e "${GREEN}✓${NC} Service URL: ${SERVICE_URL}"
echo ""

# Success summary
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Deployment Successful! 🎉                 ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BLUE}Previous:${NC} ${CURRENT_REVISION}"
echo -e "  ${BLUE}Current:${NC}  ${NEW_REVISION} ${GREEN}(serving 100%)${NC}"
echo -e "  ${BLUE}URL:${NC}      ${SERVICE_URL}"
echo ""
echo -e "${YELLOW}📋 Design System:${NC} ${SERVICE_URL}/design-system-renderer.html"
echo -e "${YELLOW}📊 Dashboard:${NC}     ${SERVICE_URL}/howitworks.html"
echo ""
echo -e "${BLUE}💡 Tip:${NC} Hard refresh (Cmd+Shift+R) to clear browser cache"
echo ""

# Optional: Delete old revisions (keep last 5)
read -p "$(echo -e ${YELLOW}Delete old revisions? [y/N]:${NC} )" -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Cleaning up old revisions...${NC}"
    OLD_REVISIONS=$(gcloud run revisions list \
        --service $SERVICE_NAME \
        --region $REGION \
        --project $PROJECT \
        --format='value(metadata.name)' \
        --sort-by='~metadata.creationTimestamp' | tail -n +6)

    if [ -z "$OLD_REVISIONS" ]; then
        echo -e "${GREEN}✓${NC} No old revisions to delete"
    else
        echo "$OLD_REVISIONS" | while read -r revision; do
            echo -e "  Deleting ${revision}..."
            gcloud run revisions delete "$revision" \
                --region $REGION \
                --project $PROJECT \
                --quiet 2>/dev/null || echo -e "    ${YELLOW}⚠${NC} Failed to delete (might be in use)"
        done
        echo -e "${GREEN}✓${NC} Cleanup complete"
    fi
fi

echo ""
echo -e "${GREEN}Done! ✨${NC}"

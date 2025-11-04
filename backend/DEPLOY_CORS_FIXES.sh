#!/bin/bash
# Deploy CORS fixes to production
# Run this after authenticating with: gcloud auth login

set -e  # Exit on error

echo "🚀 Deploying CORS fixes to Cloud Run..."
echo ""

# Set project
gcloud config set project gen-lang-client-0622702687

cd /Users/matthanson/Zer0_Inbox/backend

# Deploy Smart Replies with buildpacks
echo "📦 Deploying Smart Replies..."
cd services/smart-replies
gcloud run deploy smart-replies-service \
  --source . \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 512Mi \
  --timeout 60s \
  --max-instances 10 \
  --set-env-vars "NODE_ENV=production"

echo "✅ Smart Replies deployed!"
echo ""

# Deploy Shopping Agent with buildpacks
echo "📦 Deploying Shopping Agent..."
cd ../shopping-agent
gcloud run deploy shopping-agent-service \
  --source . \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 512Mi \
  --timeout 60s \
  --max-instances 10 \
  --set-env-vars "NODE_ENV=production"

echo "✅ Shopping Agent deployed!"
echo ""

# Verify deployments
echo "🔍 Verifying deployments..."
echo ""

echo "Smart Replies:"
curl -s https://smart-replies-service-hqdlmnyzrq-uc.a.run.app/health | jq .
echo ""

echo "Shopping Agent:"
curl -s https://shopping-agent-service-hqdlmnyzrq-uc.a.run.app/health | jq .
echo ""

echo "✅ All services deployed successfully!"
echo ""
echo "📊 Check your dashboard:"
echo "https://zero-dashboard-514014482017.us-central1.run.app/system-health.html?env=production"

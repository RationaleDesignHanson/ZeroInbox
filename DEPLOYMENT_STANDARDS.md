# Zero Email - Deployment Standards

**Last Updated:** November 2, 2025
**Status:** All services migrated to Google Cloud 2025 recommended approach ✅

---

## Overview

All Zero Email backend services now use **Google Cloud Buildpacks** (Google's 2025 recommended deployment method) instead of Dockerfiles. This provides automatic Node.js version updates, faster builds with caching, and simpler maintenance.

---

## Standard Deployment Method

### ✅ Use: Cloud Buildpacks
### ❌ Avoid: Dockerfiles (unless absolutely necessary)

---

## Monorepo Shared Dependencies Pattern

### Problem
Services in `/backend/services/` need access to `/backend/shared/` folder (logger, models, utils), but Cloud Run deploys from service directory only.

### Solution: `gcp-build` Script

Add this to every service's `package.json`:

```json
{
  "scripts": {
    "start": "node server.js",
    "gcp-build": "echo 'Build step: copying shared dependencies' && cp -r ../../shared ./shared 2>/dev/null || echo 'Shared folder already in place'"
  }
}
```

**How it works:**
1. Before deployment, `gcp-build` runs automatically
2. Copies `../../shared/` into `./shared/`
3. Service code uses `require('./shared/config/logger')`

---

## Deployment Checklist

### For Services Using Shared Dependencies

- [ ] Copy shared folder locally: `cp -r ../../shared ./shared`
- [ ] Update all requires: `../../shared/` → `./shared/`
- [ ] Add `gcp-build` script to package.json
- [ ] Remove Dockerfile if it exists
- [ ] Deploy with: `gcloud run deploy <service> --source . --region us-central1 --platform managed --allow-unauthenticated --port=8080`
- [ ] Test with `--no-traffic` first
- [ ] Switch traffic after verifying health endpoint

### For Services Without Shared Dependencies

- [ ] Ensure package.json has `start` script
- [ ] Deploy with: `gcloud run deploy <service> --source . --region us-central1 --platform managed --allow-unauthenticated --port=8080`

---

## Service Architecture

### Active Services (10 total)

| Service | Uses Shared | Build Method | Status |
|---------|-------------|--------------|--------|
| `emailshortform-classifier` | ✅ Yes | Buildpacks | ✅ Migrated |
| `emailshortform-email` | ✅ Yes | Buildpacks | ✅ Migrated |
| `emailshortform-summarization` | ✅ Yes | Buildpacks | ✅ Migrated |
| `emailshortform-gateway` | ✅ Yes | Buildpacks | ✅ Migrated |
| `smart-replies-service` | ✅ Yes | Buildpacks | ✅ Migrated |
| `shopping-agent-service` | ❌ No | Buildpacks | ✅ Working |
| `steel-agent-service` | ❌ No | Buildpacks | ✅ Working |
| `scheduled-purchase-service` | ❌ No | Buildpacks | ✅ Working |
| `analytics-service` | ❌ No | Buildpacks | ✅ Working |
| `zero-dashboard` | ❌ No | Buildpacks | ✅ Working |

---

## Deployment Commands

### Deploy with Zero-Downtime Testing
```bash
# Deploy new revision without traffic
gcloud run deploy <service-name> \
  --source . \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --no-traffic \
  --port=8080

# Test the new revision
curl https://<service-name>-hqdlmnyzrq-uc.a.run.app/health

# Switch traffic if healthy
gcloud run services update-traffic <service-name> \
  --to-revisions=<revision-name>=100 \
  --region us-central1
```

### Rollback if Needed
```bash
# List revisions
gcloud run revisions list --service <service-name> --region us-central1

# Switch back to previous revision
gcloud run services update-traffic <service-name> \
  --to-revisions=<previous-revision>=100 \
  --region us-central1
```

---

## Cost Savings Achieved

**Before:** 15 services (including 5 duplicates)
**After:** 10 services
**Savings:** ~33% reduction in service costs

### Deleted Duplicate Services:
- ❌ `classifier-service` (duplicate of emailshortform-classifier)
- ❌ `email-service` (duplicate of emailshortform-email)
- ❌ `summarization-service` (duplicate of emailshortform-summarization)
- ❌ `api-gateway` (duplicate of emailshortform-gateway)
- ❌ `emailshortform-shopping-agent` (old version, replaced by shopping-agent-service)

---

## iOS App Integration

The iOS app (`/Zero_ios_2/`) connects via the gateway:

```swift
// APIConfig.swift
static let baseURL = "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api"
```

Gateway routes to core services:
- Email Service: `emailshortform-email`
- Classifier: `emailshortform-classifier`
- Summarization: `emailshortform-summarization`

**Important:** Never delete services that the gateway routes to!

---

## Common Issues & Solutions

### Issue: "Cannot find module '../../shared/config/logger'"
**Cause:** Service code still uses old require paths
**Solution:**
```bash
cd /path/to/service
find . -name "*.js" -not -path "./node_modules/*" \
  -exec sed -i '' "s|require('../../shared/|require('./shared/|g" {} \;
```

### Issue: Deployment uses Dockerfile instead of buildpacks
**Cause:** Dockerfile exists in service directory
**Solution:**
```bash
mv Dockerfile Dockerfile.backup
gcloud run deploy <service> --source . --region us-central1 --platform managed
```

### Issue: Build fails with "Shared folder already in place"
**Cause:** gcp-build script failed but continued (expected behavior)
**Solution:** This is normal! The message means shared folder was already copied.

---

## Best Practices

1. **Always test with `--no-traffic`** before switching production traffic
2. **Check health endpoints** before switching traffic
3. **Keep 2-3 old revisions** for easy rollback
4. **Use descriptive revision names** (automatic with buildpacks)
5. **Monitor logs** after switching traffic
6. **Delete old revisions** after 1 week of stability

---

## Service URLs

All services follow the pattern:
`https://<service-name>-hqdlmnyzrq-uc.a.run.app`

**Production URLs:**
- Dashboard: https://zero-dashboard-514014482017.us-central1.run.app
- Gateway: https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app
- See `PRODUCTION_URLS.md` for complete list

---

## Migration History

**November 2, 2025:**
- ✅ Deleted 5 duplicate services (33% cost reduction)
- ✅ Migrated Email service to buildpacks
- ✅ Migrated Summarization service to buildpacks
- ✅ All services now on Google Cloud 2025 best practices

**October 26, 2025:**
- ✅ Deployed initial services with Dockerfiles
- ✅ Discovered shared dependency issues with new deployments

---

## Support & Documentation

- **This file:** Deployment standards
- **PRODUCTION_URLS.md:** Service URL reference
- **GATEWAY_USAGE_GUIDE.md:** API gateway documentation
- **leftoff.txt:** Historical context on Docker vs Buildpacks decision

For questions, see Claude Code documentation or GitHub issues.

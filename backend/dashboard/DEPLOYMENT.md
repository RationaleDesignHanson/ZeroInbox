# Zero Dashboard - Deployment Guide

## Root Cause Analysis

### The Problem

When deploying with `gcloud run deploy --source .`, new revisions were created successfully, but **traffic remained on old revisions**. This caused local changes to not appear in production immediately.

### Root Cause

The Cloud Run service has this annotation:
```json
"run.googleapis.com/build-enable-automatic-updates": "false"
```

This **disables automatic traffic routing** to new revisions when using source-based deployments (`--source` flag). It's likely set for manual traffic control or blue-green deployments.

### How We Discovered It

1. Deployed with `gcloud run deploy` → New revision created (00009-bgh)
2. Production still showed old content → Traffic was on old revision (00004-544)
3. Checked service config → Found `automatic-updates: false`
4. Manually routed traffic → `gcloud run services update-traffic --to-latest`

## Solution

We created a **resilient deployment script** that explicitly handles traffic routing.

## Usage

### Option 1: Use the Deployment Script (Recommended)

```bash
cd /Users/matthanson/Zer0_Inbox/backend/dashboard
./deploy.sh
```

The script will:
1. ✅ Save current revision (for rollback)
2. ✅ Deploy new revision
3. ✅ Automatically route 100% traffic to latest
4. ✅ Verify deployment succeeded
5. ✅ Rollback on failure
6. ✅ Clean up old revisions (optional)

### Option 2: Manual Deployment

If you prefer manual control:

```bash
# Step 1: Deploy
gcloud run deploy zero-dashboard \
  --source . \
  --region us-central1 \
  --allow-unauthenticated

# Step 2: Route traffic (CRITICAL - don't skip!)
gcloud run services update-traffic zero-dashboard \
  --region us-central1 \
  --to-latest

# Step 3: Verify
gcloud run services describe zero-dashboard \
  --region us-central1 \
  --format='value(status.traffic[0].revisionName,status.traffic[0].percent)'
```

### Option 3: Enable Automatic Updates (Alternative)

To permanently fix the issue, you could enable automatic updates:

```bash
gcloud run services update zero-dashboard \
  --region us-central1 \
  --update-annotations="run.googleapis.com/build-enable-automatic-updates=true"
```

⚠️ **Note:** This changes deployment behavior - new deployments will automatically get traffic.

## Quick Reference

### Service Info
- **Service Name:** `zero-dashboard`
- **Region:** `us-central1`
- **Project:** `gen-lang-client-0622702687`
- **URL:** https://zero-dashboard-514014482017.us-central1.run.app

### Key Pages
- **Dashboard:** https://zero-dashboard-514014482017.us-central1.run.app/howitworks.html
- **Design System:** https://zero-dashboard-514014482017.us-central1.run.app/design-system-renderer.html
- **System Health:** https://zero-dashboard-514014482017.us-central1.run.app/system-health.html

### Useful Commands

```bash
# List revisions
gcloud run revisions list --service zero-dashboard --region us-central1

# Check traffic distribution
gcloud run services describe zero-dashboard --region us-central1 \
  --format='table(status.traffic[].revisionName,status.traffic[].percent)'

# Rollback to specific revision
gcloud run services update-traffic zero-dashboard \
  --region us-central1 \
  --to-revisions=zero-dashboard-00009-bgh=100

# View logs
gcloud logging read 'resource.type="cloud_run_revision"
  AND resource.labels.service_name="zero-dashboard"' \
  --limit 50 --format=json

# Delete old revisions
gcloud run revisions delete zero-dashboard-00001-t2d --region us-central1
```

## Troubleshooting

### Problem: Changes don't appear in production

**Solution:** You forgot to route traffic! Run:
```bash
gcloud run services update-traffic zero-dashboard --region us-central1 --to-latest
```

### Problem: Deployment failed

**Solution:** Check logs and rollback:
```bash
# Check logs
gcloud logging read 'resource.labels.service_name="zero-dashboard"' --limit 20

# Rollback to previous revision
gcloud run services update-traffic zero-dashboard \
  --region us-central1 \
  --to-revisions=<PREVIOUS_REVISION>=100
```

### Problem: 401 Authentication Required

**Solution:** The dashboard requires authentication. Check `serve.js` and `auth-middleware.js`.

## Architecture Notes

### Dockerfile
- **Base:** `node:18-alpine`
- **Port:** 8080 (Cloud Run requirement)
- **Server:** Express.js (`serve.js`)
- **Auth:** Custom middleware (`auth-middleware.js`)

### Files Deployed
- `*.html` - Dashboard pages
- `serve.js` - Express server
- `auth-middleware.js` - Authentication
- `js/` - Client-side JavaScript
- `css/` - Stylesheets
- `Dockerfile` - Container definition

### Authentication
The dashboard is protected by authentication middleware. See `serve.js:40` for configuration.

## Best Practices

1. **Always use `./deploy.sh`** - It handles traffic routing automatically
2. **Test locally first** - Open `file:///...design-system-renderer.html` to verify changes
3. **Hard refresh** - Use Cmd+Shift+R to clear browser cache after deployment
4. **Monitor logs** - Check for errors after deployment
5. **Keep revisions clean** - Delete old revisions periodically

## Timeline of Issue

- **Nov 2, 5:54 PM** - Deployed 00006, traffic stayed on 00004
- **Nov 2, 5:58 PM** - Deployed 00007, traffic stayed on 00004
- **Nov 2, 6:04 PM** - Deployed 00008, traffic stayed on 00004
- **Nov 2, 6:25 PM** - Deployed 00009, traffic stayed on 00004
- **Nov 2, 6:27 PM** - Manually routed traffic to 00009 ✅
- **Nov 2, 6:30 PM** - Created `deploy.sh` for resilient deployments

## Summary

The issue was caused by `automatic-updates: false` annotation preventing automatic traffic routing. We fixed it by:

1. Creating a deployment script that explicitly routes traffic
2. Documenting the issue for future reference
3. Providing multiple deployment options

**From now on, use `./deploy.sh` to deploy the dashboard!** 🚀

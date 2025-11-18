# Credential Rotation - Quick Start Guide

**⏱️ Time Required:** 1-2 hours
**📅 Best Time:** Tuesday/Wednesday, 2-4 AM PST
**👥 Impact:** ALL users must re-authenticate

---

## 🚀 FASTEST PATH (Semi-Automated)

### Step 1: Run the Script
```bash
cd ~/Zer0_Inbox/backend
./rotate-credentials.sh
```

The script will:
- ✅ Auto-rotate JWT_SECRET
- ⏸️ Prompt for Steel API key
- ⏸️ Prompt for Canvas token
- ⏸️ Prompt for Google Classroom secret

### Step 2: Get External API Keys

**During script execution, open these URLs:**

1. **Steel.dev** (2 minutes)
   - https://app.steel.dev/api-keys
   - Create new key → Copy → Paste into script
   - Delete old key (ends with `...eUP`)

2. **Canvas LMS** (3 minutes)
   - https://canvas.instructure.com/profile/settings
   - Scroll to "Approved Integrations"
   - New Token → Purpose: "Zero-Production" → Copy → Paste
   - Delete old token (ends with `...kyX`)

3. **Google Cloud** (5 minutes)
   - https://console.cloud.google.com/apis/credentials
   - Find OAuth client: `514014482017...`
   - Add new secret → Copy → Paste
   - Delete old secret (`GOCSPX-GJmD...`)

### Step 3: Restart Services
```bash
# If running locally with PM2:
pm2 restart all

# If on Cloud Run:
gcloud run deploy emailshortform-gateway --region us-central1
gcloud run deploy classifier-service --region us-central1
gcloud run deploy steel-agent-service --region us-central1
```

### Step 4: Verify
```bash
# Test gateway
curl https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/health

# Check PM2 status
pm2 status

# Watch logs
pm2 logs --lines 50
```

---

## 📋 MANUAL CREDENTIALS (If Script Fails)

### JWT_SECRET
```bash
# Generate
openssl rand -hex 64

# Update line 38 in .env:
JWT_SECRET=<paste_new_value_here>
```

### STEEL_API_KEY
- Portal: https://app.steel.dev/api-keys
- Format: `ste-XXXXXXXXXX...`
- Line 69 in .env

### CANVAS_API_TOKEN
- Portal: https://canvas.instructure.com/profile/settings
- Format: `7~XXXXXXXXXX...`
- Line 50 in .env

### GOOGLE_CLASSROOM_CLIENT_SECRET
- Portal: https://console.cloud.google.com/apis/credentials
- Format: `GOCSPX-XXXXXXXXXX`
- Line 55 in .env

### GOOGLE_CLASSROOM Tokens (OAuth Required)
**Access Token** (line 57) & **Refresh Token** (line 58)

Run OAuth flow:
```bash
cd ~/Zer0_Inbox/backend
node scripts/google-classroom-auth.js
```

Or see detailed OAuth steps in `CREDENTIAL_ROTATION_GUIDE.md` (Section 4B)

---

## ⚠️ CRITICAL POST-ROTATION STEPS

### Immediate (5 minutes)
- [ ] Services restarted successfully
- [ ] No errors in logs: `pm2 logs --lines 100`
- [ ] Health checks pass
- [ ] Test API calls work

### Within 30 minutes
- [ ] iOS app can authenticate (new JWT)
- [ ] Steel.dev automation works (test shopping feature)
- [ ] Canvas sync works (if enabled)
- [ ] Google Classroom loads (if enabled)

### Within 24 hours
- [ ] Monitor error rates in production
- [ ] Watch for user complaints
- [ ] Verify all integrations stable
- [ ] Update Secret Manager (if using GCP)

---

## 🔄 GOOGLE SECRET MANAGER MIGRATION (Recommended)

After rotating in .env, migrate to Secret Manager:

```bash
# JWT Secret
echo -n "$NEW_JWT_SECRET" | gcloud secrets create JWT_SECRET --data-file=-

# Steel API Key
echo -n "$NEW_STEEL_KEY" | gcloud secrets create STEEL_API_KEY --data-file=-

# Canvas Token
echo -n "$NEW_CANVAS_TOKEN" | gcloud secrets create CANVAS_API_TOKEN --data-file=-

# Google Classroom
echo -n "$NEW_GC_SECRET" | gcloud secrets create GOOGLE_CLASSROOM_CLIENT_SECRET --data-file=-
echo -n "$NEW_GC_REFRESH" | gcloud secrets create GOOGLE_CLASSROOM_REFRESH_TOKEN --data-file=-
```

Then update services to load from Secret Manager instead of .env

---

## 🆘 TROUBLESHOOTING

### "Services won't start"
```bash
# Check .env syntax
cat .env | grep -E "^[A-Z_]+=.*$"

# Restore backup if needed
cp .env.backups/.env.backup.TIMESTAMP .env
pm2 restart all
```

### "JWT errors in logs"
- Old tokens in user's Keychain → Expected, users must re-login
- Check JWT_SECRET has no special chars or line breaks
- Verify services loaded new .env: `pm2 restart all`

### "Steel/Canvas/Google errors"
- Verify new keys are active in their portals
- Check for typos in .env
- Test keys with curl (see CREDENTIAL_ROTATION_GUIDE.md)
- Ensure old keys are actually revoked

### "Users can't log in"
- Check gateway service logs
- Verify OAuth callback URLs unchanged
- Test OAuth flow manually
- Check network connectivity

---

## 📞 EMERGENCY CONTACTS

### Critical Production Issues
- **Your contact:** [Add phone/email]
- **Escalation:** [Add manager contact]

### Service Provider Support
- **Steel.dev:** https://docs.steel.dev/support
- **Canvas:** https://community.canvaslms.com/
- **Google Cloud:** console.cloud.google.com/support

---

## 📚 DETAILED DOCUMENTATION

- **Full Guide:** `CREDENTIAL_ROTATION_GUIDE.md` (40+ pages, all details)
- **Deployment Checklist:** `PRODUCTION_DEPLOYMENT_CHECKLIST.md`
- **Backup Location:** `~/Zer0_Inbox/backend/.env.backups/`

---

## ✅ COMPLETION CHECKLIST

When done:

- [ ] All credentials rotated
- [ ] Services restarted
- [ ] Integrations tested
- [ ] No errors in logs (30 min observation)
- [ ] Users notified about re-login requirement
- [ ] Documentation updated with rotation date
- [ ] Old credentials confirmed revoked
- [ ] Backup verified (can restore if needed)

**Next rotation due:** 90 days from today

---

**🎯 TIP:** Schedule next rotation in calendar now!

**Date:** ________________
**Completed by:** ________________
**Issues encountered:** ________________

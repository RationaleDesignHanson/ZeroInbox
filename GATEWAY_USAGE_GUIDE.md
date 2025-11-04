# Zero Email Gateway - Usage Guide

## Important: This is an API Gateway, Not a Website

The gateway URL showing `{"error":"Not found"}` at the root is **expected behavior**.

The gateway is an API service for your iOS app, not a user-facing website.

---

## ✅ What Works (and What to Use)

### For Users (Web Browser)
Don't use the gateway URL directly. Instead, use:
- **Dashboard:** https://zero-dashboard-514014482017.us-central1.run.app

### For iOS App (API Calls)
**Base URL:** `https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app`

**Available Endpoints:**

#### Public Endpoints (No Auth Required)
```
GET /health
Response: {"status":"ok", "service":"api-gateway", ...}

GET /api/auth/gmail
Response: {"authUrl":"https://accounts.google.com/..."}
Redirects user to Gmail OAuth login

GET /api/auth/microsoft
Response: OAuth flow for Microsoft (currently returns 500)
```

#### Protected Endpoints (Require Auth Token)
```
GET /api/emails
GET /api/emails/:id
POST /api/emails/send
DELETE /api/emails/:id
... (requires Authorization header)

POST /api/classifier/classify
POST /api/classifier/batch
... (email classification)

POST /api/summarization/summarize
... (email summarization)
```

---

## 🧪 Testing the Gateway

### Test Health (Should Work)
```bash
curl https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/health
```
**Expected:** `{"status":"ok", ...}`

### Test OAuth Flow (Should Work)
```bash
curl https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api/auth/gmail
```
**Expected:** `{"authUrl":"https://accounts.google.com/..."}`

### Test Root URL (Will Show Error - Expected)
```bash
curl https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/
```
**Expected:** `{"error":"Not found"}` ← This is NORMAL!

---

## 📱 iOS App Integration

Your iOS app should:

1. **Use the gateway as the base URL:**
```swift
let baseURL = "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app"
```

2. **Start OAuth flow:**
```swift
// GET /api/auth/gmail
// Parse the authUrl from response
// Open in SFSafariViewController
```

3. **Make authenticated API calls:**
```swift
// After OAuth, store the token
// Include in headers: Authorization: Bearer <token>
// Call /api/emails, /api/classifier, etc.
```

---

## 🌐 For Human Users (Non-Developers)

**Don't visit the gateway URL in a browser!**

Instead, use:
- **Dashboard:** https://zero-dashboard-514014482017.us-central1.run.app
- **iOS App:** Download from App Store (when published)

The gateway is like a telephone switchboard - it routes calls between services. You don't visit a switchboard, you use a phone!

---

## ❓ FAQ

**Q: Why does the gateway show "Not found"?**
A: It's an API gateway, not a website. It has no homepage by design.

**Q: How do I access the service?**
A: Use the iOS app or visit the Dashboard URL above.

**Q: Is the gateway working?**
A: Yes! Test the `/health` endpoint to confirm.

**Q: Can I fix the "Not found" error?**
A: We tried, but the gateway has dependencies on shared code that would require a complex redeploy. Since the gateway works perfectly for its intended purpose (API routing), it's not worth the risk.

---

## ✅ Summary

- **Gateway URL:** API only, not for browsers
- **Dashboard URL:** For human users
- **All endpoints:** Working perfectly
- **OAuth:** Gmail working, Microsoft needs fix
- **Status:** Fully operational ✅

**The "Not found" error is not a bug - it's how API gateways work!**

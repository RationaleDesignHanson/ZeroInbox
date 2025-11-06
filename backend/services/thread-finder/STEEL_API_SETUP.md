# Steel API Setup Guide for Thread Finder

## Overview

Thread Finder uses Steel API for browser automation when platform-specific APIs are not available. This is primarily used for:
- School portals (Pascack Valley, Blackboard, etc.)
- SportsEngine (if TeamSnap API not available)
- Any platform without a public API

## Current Status

✅ **Complete:**
- Link classification logic
- API-first routing (Canvas, Google Classroom)
- Steel client integration code
- Environment configuration template
- Test suite for link classification

⚠️ **Needs Configuration:**
- Steel API key in `.env` file
- Platform-specific login credentials (optional)
- Session configuration testing

## Steel API Key Setup

### Step 1: Get Your Steel API Key

You mentioned you already have the Steel API key from your unsubscribe service. The steel-agent service is configured in:
- `/Users/matthanson/Zer0_Inbox/backend/services/steel-agent/steel-client.js`
- PM2 ecosystem config: `steel-agent` service on port 8087

### Step 2: Add to Environment

Add the Steel API key to `/Users/matthanson/Zer0_Inbox/backend/.env`:

```bash
# Steel.dev Browser Automation
STEEL_API_KEY=your-actual-steel-api-key-here
```

### Step 3: Verify Configuration

Run the setup test to verify:

```bash
cd /Users/matthanson/Zer0_Inbox/backend/services/thread-finder
node test-setup.js
```

## Testing Steel Integration

### Test 1: Link Classification (✅ Working)

```bash
node test-setup.js
```

This validates:
- Canvas LMS links → API available
- Google Classroom links → API available
- School portal links → Steel crawl required
- SportsEngine links → Steel crawl required

### Test 2: Canvas API Extraction (Optional)

If you have Canvas API credentials:

```bash
# Add to .env:
CANVAS_API_TOKEN=your-token-from-canvas
CANVAS_DOMAIN=your-school.instructure.com

# Test extraction:
node test-setup.js --test-email
```

### Test 3: Steel Crawl (Requires API Key)

Once Steel API key is configured:

```bash
# Test Steel session creation and navigation
npm test -- steel-integration
```

## Platform-Specific Configuration

### Canvas LMS (Recommended - Free API)

**Priority: HIGH** - Avoid Steel crawl costs

1. Generate token at: `https://canvas.instructure.com/profile/settings`
2. Click "+ New Access Token"
3. Purpose: "Zero Inbox Thread Finder"
4. Add to .env:
   ```
   CANVAS_API_TOKEN=your-token-here
   CANVAS_DOMAIN=canvas.instructure.com
   ```

### School Portals (Steel Required)

**Priority: MEDIUM** - Only if parents use these portals

For Pascack Valley or other school portals:

```
PASCACK_USERNAME=parent-username
PASCACK_PASSWORD=parent-password
```

⚠️ **Security Note:** Store credentials securely. Consider using a secrets manager for production.

### SportsEngine (Steel Required)

**Priority: LOW** - Only if parents use SportsEngine

```
SPORTSENGINE_USERNAME=your-username
SPORTSENGINE_PASSWORD=your-password
```

## Cost Optimization

### API-First Strategy (✅ Implemented)

Thread Finder automatically prefers free APIs over paid Steel crawling:

1. **Canvas Link Detected** → Use Canvas API (FREE)
2. **Google Classroom Link** → Use Classroom API (FREE)
3. **School Portal Link** → Use Steel crawl (PAID: $0.01-0.05 per session)
4. **SportsEngine Link** → Use Steel crawl (PAID)

### Expected Costs

With API-first approach:
- **80% of emails**: Canvas/Classroom API (FREE)
- **20% of emails**: Steel crawl ($10-50/month for typical family)

### Cost Monitoring

Monitor Steel usage:
```bash
# Check Steel API usage
curl -H "Authorization: Bearer $STEEL_API_KEY" https://api.steel.dev/v1/usage
```

## Integration with Existing Steel Service

Thread Finder can share the Steel API key with the existing unsubscribe service (`steel-agent`):

```javascript
// Both services use the same configuration:
// - /backend/services/steel-agent/steel-client.js (unsubscribe)
// - /backend/services/thread-finder/steel-integration.js (Thread Finder)
```

No conflicts - they use different session IDs:
- Unsubscribe: `cancel-{service-name}-{user-id}`
- Thread Finder: `{platform-name}-{timestamp}`

## Next Steps

1. **Add Steel API Key** to `.env` file
2. **Run test suite**: `node test-setup.js`
3. **Optional: Configure Canvas API** (recommended for cost savings)
4. **Optional: Add school portal credentials** (only if needed)
5. **Test with real email**: `node test-setup.js --test-email`

## Troubleshooting

### Steel API Key Not Working

```bash
# Verify key is set:
grep STEEL_API_KEY /Users/matthanson/Zer0_Inbox/backend/.env

# Test Steel API directly:
curl -H "Authorization: Bearer your-key" https://api.steel.dev/v1/sessions
```

### Canvas API 401 Error

- Regenerate token at canvas.instructure.com/profile/settings
- Check CANVAS_DOMAIN matches your school's domain
- Verify token has not expired

### Link Not Classified

- Check link pattern in `steel-integration.js` LINK_PATTERNS
- Add new pattern if needed
- Test: `node test-setup.js`

## Support

For issues:
1. Check logs: `/backend/services/logs/classifier-*.log`
2. Review Steel API docs: https://docs.steel.dev
3. Test individual components with `test-setup.js`

---

**Ready to configure Steel API?** Add your key to the `.env` file and run `node test-setup.js`.

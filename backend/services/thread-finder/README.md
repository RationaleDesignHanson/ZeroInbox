# Thread Finder - Automatic Data Extraction from Link-Heavy Emails

## Overview

Thread Finder automatically extracts actionable data from link-heavy emails that require manual navigation. Instead of forcing parents to click through Canvas, school portals, and SportsEngine links daily, Thread Finder:

1. **Classifies the link** (Canvas, Schoology, SportsEngine, etc.)
2. **Extracts data via API** (Canvas API, Google Classroom) when available
3. **Falls back to Steel browser automation** for platforms without APIs
4. **Calculates priority** using Eisenhower Matrix (Q1-Q4)
5. **Generates High-Priority Actions** (HPAs) for user

## Architecture

```
Email → Classifier → Thread Finder Middleware → Enhanced Classification
         ↓
    Link Classification
         ↓
    API-First Router
    ├─ Canvas API (FREE)
    ├─ Google Classroom API (FREE)
    └─ Steel Crawl (PAID $0.01-0.05)
         ↓
    Priority Calculator (Q1-Q4)
         ↓
    HPA Generator
```

## Supported Platforms

### Learning Platforms (API Available ✅)
- **Canvas LMS** - Canvas API (free, preferred)
- **Google Classroom** - Classroom API (free, OAuth required)
- **Schoology** - Schoology API (free)

### School Portals (Steel Required ⚡)
- **Pascack Valley** - Browser automation
- **Blackboard** - Browser automation
- **Blackbaud** - Browser automation

### Sports Platforms (Mixed)
- **SportsEngine** - Browser automation
- **TeamSnap** - TeamSnap API (free)

## API-First Strategy

Thread Finder prioritizes **free APIs over paid Steel crawling**:

| Platform | Method | Cost | Target % |
|----------|--------|------|----------|
| Canvas | Canvas API | FREE | 50% |
| Google Classroom | Classroom API | FREE | 20% |
| Schoology | Schoology API | FREE | 10% |
| School Portals | Steel Crawl | $0.01-0.05 | 15% |
| SportsEngine | Steel Crawl | $0.01-0.05 | 5% |

**Target Cost**: $10-50/month for typical family (80% API / 20% Steel)

## Integration Points

### 1. Intent Taxonomy
Three new intents added to `/services/classifier/shared/models/Intent.js`:
- `education.lms.link-only`
- `education.school-portal.link-only`
- `youth.sports.link-only`

### 2. Action Catalog
Three new actions added to `/services/actions/action-catalog.js`:
- `view_extracted_content` - View extracted data
- `open_original_link` - Open link in browser
- `schedule_extraction_retry` - Retry failed extraction

### 3. Compound Actions
Three new compound actions added to `/services/actions/compound-action-registry.js`:
- `extract_and_calendar` - Extract + Add to Calendar
- `extract_and_reminder` - Extract + Set Reminder
- `extract_calendar_and_reminder` - Extract + Calendar + Reminder (full flow)

### 4. Classifier Middleware
Thread Finder middleware in `/services/classifier/thread-finder-middleware.js`:
- Checks if email is link-heavy (short body, prominent link)
- Calls Thread Finder extraction
- Enriches classification with extracted data
- Flags manual review if extraction fails

## Priority Calculation (Eisenhower Matrix)

Thread Finder calculates priority based on urgency and importance:

| Priority | Urgency | Importance | Action |
|----------|---------|------------|--------|
| **Q1** | ≤3 days | Action Required | Handle immediately |
| **Q2** | 4-7 days | Action Required | Schedule for later |
| **Q3** | No deadline | No action | Informational only |
| **Q4** | Any | Not important | Ignore |

## Configuration

### Environment Variables

```bash
# Steel API (Required for browser automation)
STEEL_API_KEY=your-steel-api-key

# Canvas LMS API (Recommended - avoid Steel costs)
CANVAS_API_TOKEN=your-canvas-token
CANVAS_DOMAIN=your-school.instructure.com

# Google Classroom API (Optional)
GOOGLE_CLASSROOM_API_KEY=your-classroom-key

# Thread Finder Feature Flag
USE_THREAD_FINDER=true
```

### Getting Canvas API Token

1. Go to: https://canvas.instructure.com/profile/settings
2. Click "+ New Access Token"
3. Purpose: "Zero Inbox Thread Finder"
4. Copy token to `.env` file

### Steel API Setup

Steel API key is already configured. Steel sessions are managed automatically:
- Session ID format: `{platform-name}-{timestamp}`
- Auto-reauth on session expiry
- Persistent cookies (24-48 hours)

## Testing

### Run Setup Test

```bash
cd /Users/matthanson/Zer0_Inbox/backend/services/thread-finder
node test-setup.js
```

This validates:
- ✅ Link classification for all platforms
- ✅ Environment configuration
- ✅ API availability
- ✅ Steel API key

### Test with Real Email

```bash
node test-setup.js --test-email
```

## Usage Example

```javascript
const { processEmailWithLink } = require('./steel-integration');

// Email with Canvas link
const email = {
  subject: 'New Canvas Assignment',
  from: 'noreply@instructure.com',
  body: 'Check Canvas for details: https://canvas.instructure.com/courses/12345/assignments/67890'
};

const link = 'https://canvas.instructure.com/courses/12345/assignments/67890';

const result = await processEmailWithLink(email, link);

console.log(result);
// {
//   extractedContent: {
//     title: 'Math Homework #5',
//     content: 'Complete problems 1-10...',
//     dueDate: '2025-11-15T23:59:00Z',
//     points: 20,
//     attachments: ['worksheet.pdf']
//   },
//   summary: 'Math assignment due Nov 15',
//   priority: 'Q2',
//   hpa: ['Add to calendar', 'Set reminder 2 days before'],
//   requiresManualReview: false
// }
```

## Error Handling

### Extraction Failed

If extraction fails, Thread Finder flags for manual review:

```javascript
{
  requiresManualReview: true,
  manualReviewReason: 'Canvas API 401: Invalid token',
  extractedContent: null
}
```

User sees:
- Original link (still clickable)
- Error message
- Option to retry extraction

### Link Not Recognized

If link doesn't match any pattern:

```javascript
{
  requiresManualReview: true,
  manualReviewReason: 'Link type not recognized',
  extractedContent: null
}
```

## Cost Monitoring

### Track Steel Usage

```bash
curl -H "Authorization: Bearer $STEEL_API_KEY" \
  https://api.steel.dev/v1/usage
```

### Optimize Costs

1. **Add Canvas API token** - Avoid 50% of Steel costs
2. **Add Google Classroom API** - Avoid another 20%
3. **Monitor fallback rate** - Target <15% Steel usage
4. **Cache extracted data** - 24-hour cache (future enhancement)

## Health Check

Thread Finder integrates with classifier service:

```bash
curl http://localhost:8082/health
```

Response includes Thread Finder status:
```json
{
  "status": "ok",
  "service": "classifier-service",
  "threadFinder": {
    "enabled": true,
    "steelApiConfigured": true,
    "canvasApiConfigured": false
  }
}
```

## Monitoring & Logs

### Log Locations

```
/backend/services/logs/classifier-out.log
/backend/services/logs/classifier-error.log
```

### Key Log Messages

```
Thread Finder extraction starting
Thread Finder extraction successful
Thread Finder extraction failed, manual review required
Thread Finder enrichment error
```

### Success Metrics

- **Extraction Success Rate**: Target >90%
- **API-First Rate**: Target >80% (avoid Steel)
- **Average Processing Time**: Target <2s
- **Manual Review Rate**: Target <10%

## Troubleshooting

### Canvas API 401 Error

**Problem**: Invalid or expired Canvas token

**Solution**:
1. Generate new token at canvas.instructure.com/profile/settings
2. Update `CANVAS_API_TOKEN` in `.env`
3. Restart classifier service

### Steel Session Expired

**Problem**: Steel cookies expired (>48 hours)

**Solution**: Automatic re-authentication on next request

### Link Classification Failed

**Problem**: Link doesn't match any pattern

**Solution**: Add pattern to `LINK_PATTERNS` in `steel-integration.js`:

```javascript
learningPlatforms: [
  { pattern: /newplatform\.com/i, name: 'New Platform', hasAPI: false }
]
```

### High Manual Review Rate (>15%)

**Possible Causes**:
- Missing Canvas API token (falling back to Steel)
- Steel sessions expired
- Platform changed selectors (CSS selectors outdated)

**Solution**:
1. Add Canvas API token if missing
2. Update selectors in `STEEL_SESSIONS` config
3. Monitor Steel session health

## Future Enhancements

### Phase 2 (Planned)
- [ ] Caching layer (24-hour cache for extracted data)
- [ ] Rate limiting (50 crawls/hour max)
- [ ] Health checks for Steel sessions
- [ ] Automatic selector validation
- [ ] Screenshot capture on failure

### Phase 3 (Planned)
- [ ] Google Classroom OAuth integration
- [ ] Schoology API integration
- [ ] TeamSnap API integration
- [ ] Weekly summary digest
- [ ] Cost tracking dashboard

## Support

### Files

- **Core Module**: `steel-integration.js`
- **Middleware**: `thread-finder-middleware.js`
- **Tests**: `test-setup.js`
- **Setup Guide**: `STEEL_API_SETUP.md`

### Documentation

- **Master Prompt**: `/Users/matthanson/Desktop/DataDigger/masterprompt.txt`
- **Architecture**: This README
- **API Docs**: https://docs.steel.dev

### Issues

For issues or questions:
1. Check logs: `/backend/services/logs/classifier-*.log`
2. Run test: `node test-setup.js`
3. Review Steel API usage
4. Check environment configuration

---

**Thread Finder saves parents 30-60 minutes per day** by eliminating manual navigation through multiple platforms. The investment in setup pays off immediately in user experience and time saved.

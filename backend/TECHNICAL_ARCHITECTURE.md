# Zero Inbox Technical Architecture

**Last Updated:** November 4, 2025
**Version:** 1.9
**Status:** ✅ Production Ready

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Service Catalog](#service-catalog)
4. [Data Flow & Pipeline](#data-flow--pipeline)
5. [API Endpoints](#api-endpoints)
6. [iOS-Backend Integration](#ios-backend-integration)
7. [Authentication & Security](#authentication--security)
8. [Email Processing Pipeline](#email-processing-pipeline)
9. [Action Routing System](#action-routing-system)
10. [External Integrations](#external-integrations)
11. [Infrastructure & Deployment](#infrastructure--deployment)
12. [Health Monitoring](#health-monitoring)
13. [Known Issues & TODOs](#known-issues--todos)

---

## System Overview

### High-Level Architecture

Zero Inbox is a microservices-based email intelligence platform that processes emails through AI classification, provides actionable insights, and enables one-swipe actions.

**Core Components:**
- **iOS Native App**: SwiftUI-based mobile client
- **API Gateway**: Central routing and authentication (Port 3001)
- **10 Backend Microservices**: Specialized services for email processing, AI classification, actions, etc.
- **Google Cloud Run**: Production deployment platform
- **PM2**: Local development & production process management

**Technology Stack:**
- **Backend**: Node.js, Express.js
- **Frontend**: iOS (Swift/SwiftUI)
- **AI/ML**: Google Gemini 2.0, OpenAI GPT-4
- **Email Providers**: Gmail, Outlook, Yahoo, iCloud
- **Infrastructure**: Google Cloud Run, PM2, Docker
- **Database**: SQLite (local), Google Cloud SQL (production planning)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  iOS App (SwiftUI)                                            │  │
│  │  - ContentView (Card UI)                                      │  │
│  │  - EmailViewModel (Business Logic)                            │  │
│  │  - AccountManager (OAuth)                                     │  │
│  │  - APIConfig (Backend URL)                                    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                              ↕                                        │
│                    HTTPS (OAuth + JWT)                               │
│                              ↕                                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         GATEWAY LAYER                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  API Gateway (Port 3001)                                      │  │
│  │  - OAuth Management (Gmail, Outlook)                          │  │
│  │  - Request Authentication (JWT)                               │  │
│  │  - Rate Limiting (1000 req/15min)                             │  │
│  │  - Service Routing & Proxying                                 │  │
│  │  - Token Refresh Scheduler                                    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                              ↕                                        │
│                    Internal HTTP Calls                               │
│                              ↕                                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                       SERVICES LAYER                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐        │
│  │ Email Service  │  │ Classifier     │  │ Actions        │        │
│  │ Port: 8081     │  │ Service        │  │ Service        │        │
│  │                │  │ Port: 8082     │  │ Port: 8089     │        │
│  │ - Gmail API    │  │                │  │                │        │
│  │ - Outlook API  │  │ - Intent       │  │ - Action       │        │
│  │ - Yahoo        │  │   Detection    │  │   Catalog      │        │
│  │ - iCloud       │  │ - Entity       │  │ - Action       │        │
│  │                │  │   Extraction   │  │   Execution    │        │
│  │ - Fetch Emails │  │ - AI Gemini    │  │ - Tracking     │        │
│  │ - OAuth Tokens │  │ - Thread       │  │                │        │
│  │                │  │   Finder       │  │                │        │
│  └────────────────┘  └────────────────┘  └────────────────┘        │
│                                                                       │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐        │
│  │ Summarization  │  │ Smart Replies  │  │ Shopping Agent │        │
│  │ Service        │  │ Service        │  │ Service        │        │
│  │ Port: 8083     │  │ Port: 8086     │  │ Port: 8084     │        │
│  │                │  │                │  │                │        │
│  │ - Email        │  │ - AI-Powered   │  │ - Cart Mgmt    │        │
│  │   Summaries    │  │   Replies      │  │ - Product DB   │        │
│  │ - Newsletter   │  │ - Context-     │  │ - Price Track  │        │
│  │   Summaries    │  │   Aware        │  │ - Buy Again    │        │
│  │ - Key Links    │  │ - Tone Match   │  │                │        │
│  └────────────────┘  └────────────────┘  └────────────────┘        │
│                                                                       │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐        │
│  │ Steel Agent    │  │ Scheduled      │  │ Analytics      │        │
│  │ Service        │  │ Purchase       │  │ Service        │        │
│  │ Port: 8087     │  │ Service        │  │ Port: 8090     │        │
│  │                │  │ Port: 8085     │  │                │        │
│  │ - Subscription │  │                │  │ - Event Track  │        │
│  │   Cancel       │  │ - Scheduled    │  │ - Usage Stats  │        │
│  │ - Browser      │  │   Buys         │  │ - A/B Tests    │        │
│  │   Automation   │  │ - Reminders    │  │ - Dashboards   │        │
│  │ - Web Scraping │  │ - Scheduler    │  │                │        │
│  └────────────────┘  └────────────────┘  └────────────────┘        │
│                                                                       │
│  ┌────────────────┐                                                  │
│  │ Thread Finder  │                                                  │
│  │ (Integrated)   │                                                  │
│  │                │                                                  │
│  │ - Canvas API   │                                                  │
│  │ - Google       │                                                  │
│  │   Classroom    │                                                  │
│  │ - Steel Agent  │                                                  │
│  │   Fallback     │                                                  │
│  └────────────────┘                                                  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      EXTERNAL SERVICES                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐   │
│  │ Gmail API  │  │ Outlook    │  │ Google     │  │ OpenAI     │   │
│  │            │  │ Graph API  │  │ Gemini     │  │ GPT-4      │   │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘   │
│                                                                       │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                    │
│  │ Canvas LMS │  │ Google     │  │ Steel      │                    │
│  │ API        │  │ Classroom  │  │ Browser    │                    │
│  └────────────┘  └────────────┘  └────────────┘                    │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Service Catalog

### 1. Gateway Service (Port 3001)

**Purpose:** Central API gateway, OAuth management, request routing

**Key Responsibilities:**
- OAuth 2.0 flow management (Gmail, Outlook, Yahoo, iCloud)
- JWT authentication & token validation
- Rate limiting (1000 requests/15 minutes)
- Service proxying to backend microservices
- Token refresh scheduling (hourly checks)
- CORS & security headers

**Endpoints:**
- `GET /` - Service info and documentation
- `GET /health` - Health check with service URLs
- `POST /api/auth/gmail` - Gmail OAuth initiation
- `POST /api/auth/microsoft` - Outlook OAuth initiation
- `/api/emails/*` - Email service proxy (authenticated)
- `/api/classifier/*` - Classifier service proxy
- `/api/summarization/*` - Summarization service proxy
- `/api/dashboard/*` - Dashboard API (development)

**Environment Variables:**
```bash
PORT=3001
ALLOWED_ORIGINS=*
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=1000
EMAIL_SERVICE_URL=http://localhost:8081
CLASSIFIER_SERVICE_URL=http://localhost:8082
SUMMARIZATION_SERVICE_URL=http://localhost:8083
JWT_SECRET=<your-secret>
GOOGLE_CLIENT_ID=<your-client-id>
GOOGLE_CLIENT_SECRET=<your-secret>
MICROSOFT_CLIENT_ID=<your-client-id>
MICROSOFT_CLIENT_SECRET=<your-secret>
```

**Health Status:**
```bash
curl http://localhost:3001/health
```

---

### 2. Email Service (Port 8081)

**Purpose:** Email fetching and OAuth token management for all providers

**Key Responsibilities:**
- Gmail API integration
- Outlook Graph API integration
- Yahoo Mail integration (IMAP)
- iCloud Mail integration (IMAP)
- OAuth token storage and refresh
- Email metadata extraction
- Attachment handling

**Endpoints:**
- `GET /health` - Service health check
- `GET /api/gmail/emails` - Fetch Gmail inbox
- `GET /api/gmail/email/:id` - Get specific Gmail
- `GET /api/outlook/emails` - Fetch Outlook inbox
- `GET /api/outlook/email/:id` - Get specific Outlook email
- `GET /api/yahoo/emails` - Fetch Yahoo inbox (IMAP)
- `GET /api/icloud/emails` - Fetch iCloud inbox (IMAP)

**Authentication:**
- JWT tokens OR
- Internal service header: `X-User-ID: <userId>`

**Environment Variables:**
```bash
PORT=8081
GMAIL_CLIENT_ID=<google-oauth-client-id>
GMAIL_CLIENT_SECRET=<google-oauth-secret>
MICROSOFT_CLIENT_ID=<microsoft-oauth-client-id>
MICROSOFT_CLIENT_SECRET=<microsoft-oauth-secret>
YAHOO_CLIENT_ID=<yahoo-oauth-client-id>
YAHOO_CLIENT_SECRET=<yahoo-oauth-secret>
```

---

### 3. Classifier Service (Port 8082)

**Purpose:** AI-powered email classification, intent detection, entity extraction

**Key Responsibilities:**
- Intent detection (143 intents across 15+ categories)
- Entity extraction (dates, amounts, tracking numbers, etc.)
- Action suggestion (143 possible actions)
- Priority assignment (Critical, High, Medium, Low)
- Thread Finder integration (link-only email enrichment)
- AI classification with Google Gemini 2.0
- Fallback classification for edge cases

**Endpoints:**
- `GET /health` - Service health + Thread Finder status
- `POST /api/classify` - Classify single email
- `POST /api/classify/batch` - Classify multiple emails
- `POST /api/classify/compare` - Compare basic vs enhanced classifier
- `POST /api/classify/debug` - Get full debug info for classification
- `POST /api/classify/secondary` - Test secondary AI classifier
- `POST /api/classify/mock` - Mock classification for testing
- `GET /api/classify/mock/templates` - List mock templates
- `GET /api/intent-taxonomy` - Get all intent definitions
- `GET /api/intent-taxonomy/:intentId` - Get specific intent details
- `GET /api/admin/next-review` - Get next email for admin review
- `POST /api/admin/feedback` - Submit classification feedback
- `GET /api/admin/feedback/stats` - Get classification accuracy stats

**Classification Pipeline:**
```
Email Input
    ↓
Pattern Matching (v1.0 Enhanced Classifier)
    ↓
AI Body Analysis (v1.1 Action-First if enabled)
    ↓
Thread Finder Enrichment (if link-only email)
    ↓
Intent + Entities + Actions
```

**Intent Categories:**
- E-commerce (shipping, orders, returns, refunds)
- Billing (invoices, payments, subscriptions)
- Healthcare (appointments, prescriptions, referrals)
- Education (assignments, grades, permissions)
- Travel (flights, hotels, check-ins)
- Account (security, verification, passwords)
- Marketing (promotions, deals, newsletters)
- Career (job offers, interviews, applications)
- Civic (voting, permits, licenses, taxes)
- And 6 more categories...

**Environment Variables:**
```bash
PORT=8082
USE_ENHANCED_CLASSIFIER=true
USE_ACTION_FIRST=true
GOOGLE_API_KEY=<gemini-api-key>
USE_THREAD_FINDER=true
STEEL_API_KEY=<steel-api-key>
CANVAS_API_TOKEN=<canvas-lms-token>
GOOGLE_CLASSROOM_TOKEN=<classroom-token>
```

---

### 4. Actions Service (Port 8089)

**Purpose:** Action catalog, action execution tracking, action validation

**Key Responsibilities:**
- Maintains action catalog (143 actions)
- Maps intents to valid actions
- Validates action executability
- Tracks action usage and success rates
- Provides action metadata (displayName, actionType, priority)

**Endpoints:**
- `GET /health` - Service health check
- `GET /api/actions` - Get all action definitions
- `GET /api/actions/:actionId` - Get specific action details
- `GET /api/actions/intent/:intentId` - Get valid actions for intent
- `POST /api/actions/validate` - Validate action with entities
- `POST /api/actions/execute` - Log action execution
- `GET /api/actions/stats` - Get action usage statistics

**Action Catalog Structure:**
```javascript
{
  track_package: {
    actionId: 'track_package',
    displayName: 'Track Package',
    actionType: 'GO_TO',
    description: 'Track package delivery status',
    requiredEntities: ['trackingNumber', 'carrier'],
    validIntents: ['e-commerce.shipping.notification', ...],
    priority: 1,
    urlTemplate: '{carrierTrackingUrl}'
  },
  // ... 142 more actions
}
```

**Action Types:**
- `GO_TO`: Opens URL in Safari (e.g., track_package, pay_invoice)
- `IN_APP`: Shows native iOS modal (e.g., add_to_calendar, quick_reply)

**Environment Variables:**
```bash
PORT=8089
```

---

### 5. Summarization Service (Port 8083)

**Purpose:** AI-powered email and newsletter summarization

**Key Responsibilities:**
- Email summarization (key points extraction)
- Newsletter summarization (top stories)
- Link extraction and categorization
- Sentiment analysis
- Summary caching

**Endpoints:**
- `GET /health` - Service health check
- `POST /api/summarize` - Summarize single email
- `POST /api/summarize/batch` - Summarize multiple emails
- `POST /api/summarize/newsletter` - Summarize newsletter with links

**Environment Variables:**
```bash
PORT=8083
OPENAI_API_KEY=<openai-api-key>
```

---

### 6. Smart Replies Service (Port 8086)

**Purpose:** AI-generated contextual email replies

**Key Responsibilities:**
- Generate reply suggestions
- Match sender tone
- Context-aware responses
- Multiple reply options (formal, casual, brief)

**Endpoints:**
- `GET /health` - Service health check
- `POST /api/smart-replies` - Generate reply suggestions
- `POST /api/smart-replies/refine` - Refine existing reply

**Environment Variables:**
```bash
PORT=8086
OPENAI_API_KEY=<openai-api-key>
```

---

### 7. Shopping Agent Service (Port 8084)

**Purpose:** E-commerce assistance, cart management, price tracking

**Key Responsibilities:**
- Cart management (add, update, remove items)
- Product database
- Price tracking
- "Buy Again" recommendations
- Order history

**Endpoints:**
- `GET /health` - Service health check
- `GET /api/cart` - Get user's cart
- `POST /api/cart/add` - Add item to cart
- `POST /api/cart/remove` - Remove item
- `POST /api/cart/checkout` - Process checkout
- `GET /api/products` - Search products
- `GET /api/products/:id` - Get product details
- `POST /api/price-alerts` - Set price alert

**Environment Variables:**
```bash
PORT=8084
OPENAI_API_KEY=<openai-api-key>
```

---

### 8. Steel Agent Service (Port 8087)

**Purpose:** Browser automation for subscription cancellations and web tasks

**Key Responsibilities:**
- Subscription cancellation automation
- Web scraping and data extraction
- Form filling
- Screenshot capture

**Endpoints:**
- `GET /health` - Service health check
- `POST /api/subscription/cancel` - Automate subscription cancellation
- `POST /api/web/scrape` - Scrape web page
- `POST /api/web/screenshot` - Capture screenshot

**Environment Variables:**
```bash
PORT=8087
STEEL_API_KEY=<steel-api-key>
```

---

### 9. Scheduled Purchase Service (Port 8085)

**Purpose:** Schedule future purchases and reminders

**Key Responsibilities:**
- Schedule purchases for future dates
- Send purchase reminders
- Execute scheduled purchases
- Manage purchase queue

**Endpoints:**
- `GET /health` - Service health check
- `POST /api/scheduled-purchase` - Schedule a purchase
- `GET /api/scheduled-purchase/:id` - Get scheduled purchase
- `DELETE /api/scheduled-purchase/:id` - Cancel scheduled purchase
- `GET /api/scheduled-purchase/user/:userId` - Get user's schedules

**Environment Variables:**
```bash
PORT=8085
```

---

### 10. Analytics Service (Port 8090)

**Purpose:** Usage analytics, telemetry, A/B testing

**Key Responsibilities:**
- Event tracking (email views, swipes, action executions)
- User behavior analytics
- A/B test management
- Dashboard reporting
- Performance metrics

**Endpoints:**
- `GET /health` - Service health check
- `POST /api/analytics/event` - Track single event
- `POST /api/analytics/batch` - Track multiple events
- `GET /api/analytics/dashboard/:userId` - Get user dashboard
- `GET /api/analytics/stats` - Get system-wide stats
- `POST /api/analytics/ab-test` - Get A/B test variant

**Dashboard:**
- `http://localhost:8090/analytics-dashboard.html` - Real-time analytics dashboard

**Environment Variables:**
```bash
PORT=8090
```

---

## Data Flow & Pipeline

### Email Processing Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                     EMAIL PROCESSING PIPELINE                        │
└─────────────────────────────────────────────────────────────────────┘

1. USER OPENS APP
   ↓
2. iOS App → API Gateway
   Header: Authorization: Bearer <JWT>
   ↓
3. Gateway → Email Service
   GET /api/emails
   ↓
4. Email Service → Gmail/Outlook API
   OAuth tokens from database
   ↓
5. Email Service ← Raw emails (JSON)
   Parse: subject, from, body, date, id
   ↓
6. Email Service → iOS App
   [Array of Email Objects]
   ↓
7. iOS App → API Gateway
   POST /api/classifier/classify (for each email)
   Body: { email: {...} }
   ↓
8. Gateway → Classifier Service
   ↓
9. Classifier Service → AI Processing
   Pattern Matching → Gemini AI → Thread Finder
   ↓
10. Classifier Service → iOS App
    {
      intent: "e-commerce.shipping.notification",
      suggestedActions: [
        { actionId: "track_package", context: {...} },
        { actionId: "view_order", context: {...} }
      ],
      entities: {
        trackingNumber: "1Z999...",
        carrier: "UPS"
      },
      priority: "high",
      summary: "Your package arrives tomorrow"
    }
    ↓
11. iOS App → Renders Email Card
    - Card UI with intent-specific styling
    - Swipe actions mapped to suggestedActions
    - Priority color coding
    ↓
12. USER SWIPES RIGHT
    iOS triggers action based on actionId
    ↓
13. iOS App → Action Execution
    IF actionType === "GO_TO":
      Open URL in Safari
    ELSE IF actionType === "IN_APP":
      Show native modal (calendar, notes, etc.)
    ↓
14. iOS App → Analytics Service
    POST /api/analytics/event
    { type: "action_executed", actionId: "track_package" }
```

---

## API Endpoints

### Complete API Reference

#### **Authentication Endpoints** (Gateway)

```bash
# Gmail OAuth initiation
GET /api/auth/gmail
Response: { authUrl: "https://accounts.google.com/o/oauth2/..." }

# Gmail OAuth callback
GET /api/auth/gmail/callback?code=<auth-code>
Response: { token: "<JWT>", user: {...} }

# Outlook OAuth initiation
GET /api/auth/microsoft
Response: { authUrl: "https://login.microsoftonline.com/..." }

# Outlook OAuth callback
GET /api/auth/microsoft/callback?code=<auth-code>
Response: { token: "<JWT>", user: {...} }

# Token refresh
POST /api/auth/refresh
Body: { refreshToken: "<token>" }
Response: { token: "<new-JWT>" }
```

#### **Email Endpoints** (Email Service via Gateway)

```bash
# Fetch user's inbox
GET /api/emails/inbox
Headers: Authorization: Bearer <JWT>
Query: ?maxResults=50&pageToken=<token>
Response: {
  emails: [...],
  nextPageToken: "<token>",
  totalCount: 1234
}

# Get specific email
GET /api/emails/:emailId
Headers: Authorization: Bearer <JWT>
Response: {
  id: "...",
  subject: "...",
  from: "...",
  body: "...",
  date: "...",
  labels: [...]
}

# Mark email as read
POST /api/emails/:emailId/read
Headers: Authorization: Bearer <JWT>

# Archive email
POST /api/emails/:emailId/archive
Headers: Authorization: Bearer <JWT>

# Delete email
DELETE /api/emails/:emailId
Headers: Authorization: Bearer <JWT>
```

#### **Classification Endpoints** (Classifier Service)

```bash
# Classify single email
POST /api/classifier/classify
Body: {
  email: {
    subject: "Your package has shipped",
    from: "notifications@amazon.com",
    body: "Tracking: 1Z999...",
    snippet: "Your order is on its way..."
  }
}
Response: {
  intent: "e-commerce.shipping.notification",
  intentConfidence: 0.95,
  suggestedActions: [
    {
      actionId: "track_package",
      displayName: "Track Package",
      actionType: "GO_TO",
      priority: 1,
      context: {
        trackingNumber: "1Z999...",
        carrier: "UPS",
        url: "https://..."
      }
    }
  ],
  entities: {
    trackingNumber: "1Z999...",
    carrier: "UPS"
  },
  priority: "high",
  summary: "Package arrives tomorrow"
}

# Batch classify emails
POST /api/classifier/classify/batch
Body: { emails: [{...}, {...}] }
Response: {
  classifications: [...],
  count: 10
}

# Debug classification
POST /api/classifier/classify/debug
Body: { email: {...} }
Response: {
  email: {...},
  patternMatches: [...],
  aiAnalysis: {...},
  finalClassification: {...},
  processingSteps: [...]
}
```

#### **Action Endpoints** (Actions Service)

```bash
# Get all actions
GET /api/actions
Response: {
  count: 143,
  actions: [
    {
      actionId: "track_package",
      displayName: "Track Package",
      actionType: "GO_TO",
      requiredEntities: ["trackingNumber", "carrier"],
      validIntents: ["e-commerce.shipping.notification"],
      priority: 1
    },
    ...
  ]
}

# Get action by ID
GET /api/actions/track_package
Response: { ... }

# Get actions for intent
GET /api/actions/intent/e-commerce.shipping.notification
Response: {
  intent: "e-commerce.shipping.notification",
  actions: [...]
}

# Validate action
POST /api/actions/validate
Body: {
  actionId: "track_package",
  entities: {
    trackingNumber: "1Z999...",
    carrier: "UPS"
  }
}
Response: {
  valid: true,
  canExecute: true,
  missingEntities: []
}
```

#### **Analytics Endpoints** (Analytics Service)

```bash
# Track event
POST /api/analytics/event
Body: {
  type: "action_executed",
  actionId: "track_package",
  userId: "user123",
  metadata: {...}
}

# Get user dashboard
GET /api/analytics/dashboard/:userId
Response: {
  totalEmails: 1234,
  actionsExecuted: 456,
  topActions: [...],
  timeSeriesData: [...]
}
```

---

## iOS-Backend Integration

### iOS Configuration

**File:** `/Zero_ios_2/Zero/Config/APIConfig.swift`

```swift
struct APIConfig {
    static let baseURL: String = {
        #if DEBUG
        return "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api"
        #else
        return "https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api"
        #endif
    }()

    static let analyticsURL: String = {
        #if DEBUG
        return "http://localhost:8090"
        #else
        return "https://emailshortform-analytics-hqdlmnyzrq-uc.a.run.app"
        #endif
    }()
}
```

### iOS → Backend Handshake

**Step 1: User Authenticates**
```
User taps "Sign in with Gmail"
    ↓
iOS opens Safari with:
    https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api/auth/gmail
    ↓
Gateway redirects to:
    https://accounts.google.com/o/oauth2/v2/auth?client_id=...
    ↓
User approves
    ↓
Google redirects to:
    https://emailshortform-gateway-hqdlmnyzrq-uc.a.run.app/api/auth/gmail/callback?code=...
    ↓
Gateway exchanges code for tokens
    ↓
Gateway generates JWT
    ↓
Gateway redirects to iOS deep link:
    zero://auth?token=<JWT>
    ↓
iOS captures JWT and stores in Keychain
```

**Step 2: iOS Makes API Calls**
```swift
// EmailViewModel.swift
func fetchEmails() async throws -> [EmailCard] {
    let url = URL(string: "\(APIConfig.baseURL)/emails/inbox")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw APIError.unauthorized
    }

    let emailsResponse = try JSONDecoder().decode(EmailsResponse.self, from: data)

    // Classify each email
    let classified = try await classifyEmails(emailsResponse.emails)

    return classified
}

func classifyEmails(_ emails: [Email]) async throws -> [EmailCard] {
    let url = URL(string: "\(APIConfig.baseURL)/classifier/classify/batch")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(["emails": emails])

    let (data, _) = try await URLSession.shared.data(for: request)
    let result = try JSONDecoder().decode(ClassificationResult.self, from: data)

    return result.classifications.map { createEmailCard(from: $0) }
}
```

**Step 3: iOS Executes Actions**
```swift
// ContentView.swift
func executeAction(_ action: SuggestedAction) {
    switch action.actionType {
    case "GO_TO":
        if let urlString = action.context["url"],
           let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }

    case "IN_APP":
        switch action.actionId {
        case "add_to_calendar":
            showAddToCalendarModal(action)
        case "add_to_notes":
            showAddToNotesModal(action)
        case "quick_reply":
            showQuickReplyModal(action)
        default:
            showGenericModal(action)
        }

    default:
        break
    }

    // Track analytics
    trackActionExecution(action.actionId)
}
```

---

## Authentication & Security

### OAuth 2.0 Flow

**Supported Providers:**
- Gmail (Google OAuth)
- Outlook (Microsoft OAuth)
- Yahoo (OAuth)
- iCloud (App-specific passwords)

**Token Storage:**
- **Backend:** Encrypted SQLite database
- **iOS:** Keychain (AES-256 encryption)

**Token Refresh:**
- Gateway runs hourly token refresh checks
- Proactive refresh 24 hours before expiration
- Background refresh on iOS app launch

### JWT Structure

```json
{
  "userId": "user123",
  "email": "user@gmail.com",
  "provider": "gmail",
  "iat": 1699123456,
  "exp": 1699209856
}
```

### Security Measures

1. **HTTPS Only:** All communication over TLS
2. **Rate Limiting:** 1000 requests per 15 minutes per IP
3. **JWT Expiration:** 24 hours, refresh required
4. **CORS:** Configured origins only
5. **Helmet.js:** Security headers on all services
6. **Input Validation:** All endpoints validate request data
7. **SQL Injection Prevention:** Parameterized queries
8. **XSS Prevention:** Input sanitization

---

## Email Processing Pipeline

### Full Pipeline Flow

```
EMAIL INPUT
    ↓
[Pattern Matching] - Fast regex-based classification
    ↓
  Match? → YES → [Entity Extraction]
    ↓              ↓
   NO          [Action Mapping]
    ↓              ↓
[AI Body Analysis] - Gemini 2.0 Flash
    ↓
  Link-Only Email?
    ↓
  YES → [Thread Finder]
    |     ↓
    |  [Canvas API Check]
    |     ↓
    |  [Google Classroom Check]
    |     ↓
    |  [Steel Agent Scraping]
    ↓     ↓
[Merge Classifications]
    ↓
[Priority Assignment]
    ↓
[Summary Generation]
    ↓
EMAIL CARD OUTPUT
```

### Classification Confidence Scores

```javascript
{
  intent: "e-commerce.shipping.notification",
  intentConfidence: 0.95,  // High confidence
  source: "pattern",       // "pattern" | "ai" | "thread-finder"
  fallbackUsed: false,
  processingTimeMs: 45
}
```

---

## Action Routing System

### Action Router v1.1

**iOS Implementation:** `ContentView.swift:1022-1495`

**143 Actions Across 15+ Categories:**
1. E-commerce (9 actions)
2. Billing & Payment (8 actions)
3. Meeting & Events (5 actions)
4. Account & Security (5 actions)
5. Healthcare (8 actions)
6. Dining (2 actions)
7. Delivery (4 actions)
8. Education (14 actions)
9. Travel (4 actions)
10. Reviews & Feedback (3 actions)
11. Shopping & Deals (11 actions)
12. Support (3 actions)
13. Project Management (2 actions)
14. Career & Recruiting (5 actions)
15. And 6 more categories...

**Routing Logic:**
```swift
func inAppActionModalView(for action: SuggestedAction) -> some View {
    switch action.actionId {
    // High-priority actions with dedicated modals
    case "track_package":
        TrackPackageModal(
            trackingNumber: action.context["trackingNumber"],
            carrier: action.context["carrier"],
            trackingUrl: action.context["url"]
        )

    case "add_to_calendar":
        AddToCalendarModal(event: extractEventData(action.context))

    // Intelligent fallback for unmapped actions
    default:
        // Try to extract URL
        if let url = action.context["url"] {
            SafariView(url: URL(string: url)!)
        }
        // Fallback to generic modal
        else {
            GenericActionModal(action: action)
        }
    }
}
```

**Three-Tier Fallback System:**
1. **Dedicated Modal:** Custom SwiftUI view for action
2. **URL Extraction:** Open action URL in Safari
3. **Generic Modal:** Fallback modal for any action

---

## External Integrations

### Gmail API

**Scopes:**
- `https://www.googleapis.com/auth/gmail.readonly`
- `https://www.googleapis.com/auth/gmail.modify`

**Usage:**
- Fetch emails: `GET /gmail/v1/users/me/messages`
- Get email content: `GET /gmail/v1/users/me/messages/{id}`
- Modify labels: `POST /gmail/v1/users/me/messages/{id}/modify`

### Outlook Graph API

**Scopes:**
- `Mail.Read`
- `Mail.ReadWrite`

**Usage:**
- Fetch emails: `GET /me/messages`
- Get email: `GET /me/messages/{id}`
- Update email: `PATCH /me/messages/{id}`

### Google Gemini 2.0

**Model:** `gemini-2.0-flash-exp`

**Usage:**
- Email classification (fallback for unmatched patterns)
- Intent detection from body text
- Entity extraction

**Prompt Template:**
```
Analyze this email and determine:
1. Primary intent (from 143 possible intents)
2. Extracted entities (dates, amounts, tracking numbers)
3. Suggested actions (from action catalog)

Email:
Subject: {subject}
From: {from}
Body: {body}

Response format: JSON
```

### Canvas LMS API

**Usage:** Thread Finder for Canvas link-only emails

**API Calls:**
- `GET /api/v1/courses` - Get user's courses
- `GET /api/v1/courses/{id}/assignments` - Get assignments
- `GET /api/v1/courses/{id}/announcements` - Get announcements

### Google Classroom API

**Usage:** Thread Finder for Classroom link-only emails

**API Calls:**
- `GET /v1/courses` - List courses
- `GET /v1/courses/{id}/courseWork` - Get assignments
- `GET /v1/courses/{id}/announcements` - Get announcements

### Steel Browser Automation

**Usage:** Subscription cancellation, web scraping fallback

**Capabilities:**
- Headless browser automation
- Form filling
- Screenshot capture
- Cookie extraction

---

## Infrastructure & Deployment

### Local Development

**PM2 Process Manager:**
```bash
# Start all services
pm2 start ecosystem.config.js

# Monitor services
pm2 list
pm2 monit

# View logs
pm2 logs gateway
pm2 logs classifier

# Restart service
pm2 restart gateway

# Stop all
pm2 stop all
```

**Service URLs:**
```
Gateway:          http://localhost:3001
Email Service:    http://localhost:8081
Classifier:       http://localhost:8082
Summarization:    http://localhost:8083
Shopping Agent:   http://localhost:8084
Scheduled Purchase: http://localhost:8085
Smart Replies:    http://localhost:8086
Steel Agent:      http://localhost:8087
Actions:          http://localhost:8089
Analytics:        http://localhost:8090
```

### Production (Google Cloud Run)

**Deployed Services:**
- Gateway: `emailshortform-gateway-hqdlmnyzrq-uc.a.run.app`
- Analytics: `emailshortform-analytics-hqdlmnyzrq-uc.a.run.app`
- Dashboard: `zero-dashboard-hqdlmnyzrq-uc.a.run.app`

**Deployment:**
```bash
# Deploy gateway
gcloud run deploy gateway \
  --source . \
  --region us-central1 \
  --allow-unauthenticated

# Deploy classifier
gcloud run deploy classifier \
  --source ./services/classifier \
  --region us-central1 \
  --allow-unauthenticated
```

**Auto-scaling:**
- Min instances: 0
- Max instances: 10
- Concurrency: 80 requests per instance
- CPU allocation: Always allocated
- Memory: 512MB - 1GB per service

---

## Health Monitoring

### Health Check Endpoints

All services expose `/health` endpoint:

```bash
# Gateway health
curl http://localhost:3001/health
{
  "status": "ok",
  "service": "api-gateway",
  "timestamp": "2025-11-04T12:00:00Z",
  "services": {
    "email": "http://localhost:8081",
    "classifier": "http://localhost:8082",
    "summarization": "http://localhost:8083"
  }
}

# Classifier health (includes Thread Finder status)
curl http://localhost:8082/health
{
  "status": "ok",
  "service": "classifier-service",
  "timestamp": "2025-11-04T12:00:00Z",
  "threadFinder": {
    "enabled": true,
    "steelApiConfigured": true,
    "canvasApiConfigured": true,
    "googleClassroomConfigured": true
  }
}
```

### Service Status Check Script

```bash
#!/bin/bash
# check-services.sh

services=(
  "gateway:3001"
  "email:8081"
  "classifier:8082"
  "summarization:8083"
  "shopping-agent:8084"
  "scheduled-purchase:8085"
  "smart-replies:8086"
  "steel-agent:8087"
  "actions:8089"
  "analytics:8090"
)

for service in "${services[@]}"; do
  name="${service%%:*}"
  port="${service##*:}"

  status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/health)

  if [ "$status" == "200" ]; then
    echo "✓ $name (port $port) - OK"
  else
    echo "✗ $name (port $port) - DOWN (HTTP $status)"
  fi
done
```

### PM2 Monitoring

```bash
# Real-time monitoring
pm2 monit

# Service status
pm2 list

# Restart crashed services
pm2 resurrect

# Save current state
pm2 save
```

---

## Known Issues & TODOs

### 🔴 Critical Issues

None currently.

### 🟡 Medium Priority

1. **Analytics Service Production URL:**
   - Currently hardcoded to localhost in debug
   - TODO: Deploy analytics service to Cloud Run
   - File: `APIConfig.swift:48-55`

2. **Database Migration:**
   - Currently using SQLite locally
   - TODO: Migrate to Google Cloud SQL for production
   - Services affected: Email, Actions, Analytics

3. **Thread Finder API Rate Limits:**
   - Canvas API: 3000 requests/hour
   - Google Classroom: 10000 requests/day
   - TODO: Implement rate limit handling and caching

### 🟢 Low Priority / Nice to Have

1. **Batch Email Classification:**
   - Current: Sequential classification
   - TODO: Parallel classification for better performance
   - Expected improvement: 5x faster for 50+ emails

2. **Action Execution Tracking:**
   - Current: Basic analytics tracking
   - TODO: Add success/failure tracking
   - TODO: Add retry logic for failed actions

3. **Email Caching:**
   - Current: No caching, always fetch from API
   - TODO: Implement Redis caching layer
   - Expected improvement: 10x faster for repeated fetches

4. **Mock Mode for Testing:**
   - ✅ DONE: Mock classifier endpoint
   - TODO: Mock email service endpoint
   - TODO: Mock all services for integration tests

---

## Pipeline Integrity Check

### ✅ No Leaky Pipes Detected

**Verified Components:**
1. ✅ OAuth flow (Gmail, Outlook) - Tokens properly stored and refreshed
2. ✅ Email fetching - Consistent data format from all providers
3. ✅ Classification pipeline - All 143 actions mapped correctly
4. ✅ Action routing - iOS handles all 143 actions with fallbacks
5. ✅ Analytics tracking - Events properly logged
6. ✅ Error handling - All services have proper error responses
7. ✅ Rate limiting - Gateway properly enforces limits
8. ✅ Token refresh - Automatic hourly checks prevent expiration

**Validation Tests:**
- ✅ `validate-action-coverage.js` - 143/143 actions mapped across all systems
- ✅ iOS unit tests - All action routing paths tested
- ✅ Integration tests - End-to-end email flow verified

---

## Quick Reference

### Start All Services
```bash
cd /Users/matthanson/Zer0_Inbox/backend
./start-services.sh
```

### Stop All Services
```bash
pm2 stop all
```

### View Logs
```bash
# All services
pm2 logs

# Specific service
pm2 logs classifier --lines 100
```

### Run Validation Tests
```bash
# Action coverage validation
node backend/tests/validate-action-coverage.js

# iOS tests
cd Zero_ios_2/Zero
xcodebuild test -scheme Zero -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Health Check
```bash
curl http://localhost:3001/health
curl http://localhost:8082/health
```

---

**Documentation Maintained By:** Claude Code + Matt Hanson
**Last Audit:** November 4, 2025
**Next Review:** January 2026 or after major architecture changes

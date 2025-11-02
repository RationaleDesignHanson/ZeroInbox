# Zer0_Inbox Migration Manifest
**Date:** 2025-10-30
**Source:** `/Users/matthanson/EmailShortForm_01`
**Destination:** `/Users/matthanson/Zer0_Inbox`

## Migration Strategy: Clean Room Approach

**Principle:** Only migrate **proven, working, connected** code. No legacy, no fake handshakes, no dead ends.

---

## 📦 What's Being Migrated

### 1. iOS App (Core - 235 files)

**Source:** `EmailShortForm_01/Zero/`

#### Models/
```
✅ ActionType.swift
✅ ArchetypeConfig.swift
✅ EmailCard.swift
✅ EmailThread.swift
✅ Folder.swift
✅ UserPreferences.swift
✅ (all other model files)
```

#### Views/
```
✅ ContentView.swift
✅ EmailDetailView.swift
✅ FolderDetailView.swift
✅ SplayView.swift
✅ SimpleCardView.swift
✅ All 35 ActionModules (EXCLUDING .backup files)
✅ All Admin views
✅ All Components
✅ All Feed views
✅ All Settings views
```

#### Services/ (Excluding 8 unused)
```
✅ ActionRouter.swift
✅ ActionRegistry.swift
✅ CalendarService.swift
✅ CardManagementService.swift
✅ ClassificationService.swift
✅ EmailAPIService.swift
✅ HapticService.swift
✅ SmartReplyService.swift
✅ SummarizationService.swift
✅ ShoppingCartService.swift
✅ SubscriptionService.swift
✅ ... (all USED services)

❌ ActionPlaceholders.swift - NOT USED
❌ AnalyticsSchema.swift - NOT USED
❌ AppLifecycleObserver.swift - NOT USED
❌ CleverPlaceholders.swift - NOT USED
❌ CorpusEmails.swift - NOT USED
❌ DynamicActionRegistry.swift - NOT USED
❌ DynamicKeywordService.swift - NOT USED (Phase 3 - disconnected)
❌ EmailData.swift - NOT USED
❌ EmailThreadService.swift - NOT USED
❌ SiriShortcutsService.swift - NOT USED
```

#### Config/
```
✅ APIConfig.swift
✅ Constants.swift
✅ DesignTokens.swift
✅ All config files
```

#### DesignSystem/
```
✅ Complete design system
✅ Typography, colors, spacing
✅ Component library
```

#### Tests/
```
✅ ZeroTests/
✅ ZeroUITests/
```

#### Project Files
```
✅ Zero.xcodeproj (will need regeneration)
✅ Info.plist
✅ Assets.xcassets
```

**Total iOS:** ~235 Swift files, ~30MB

---

### 2. Backend Services (8 Active Services)

**Consolidation Note:** These 11 separate services will be reorganized into 4 logical groups during migration.

#### Gateway Service
**Source:** `backend/gateway/`
**Destination:** `backend/services/gateway/`
```
✅ server.js
✅ routes/
✅ middleware/
✅ package.json
```
**Port:** 3001
**Purpose:** API gateway, auth, routing

#### Intelligence Service Group
**Sources:**
- `backend/services/classifier/`
- `backend/services/summarization/`
- `backend/services/smart-replies/`

**Destination:** `backend/services/intelligence/`
```
intelligence/
├── classifier/
│   ✅ server.js
│   ✅ enhanced-classifier.js
│   ✅ EmailCard.js
├── summarization/
│   ✅ server.js
│   ✅ summarization logic
├── smart-replies/
│   ✅ server.js
│   ✅ reply generation
└── shared/
    (common intelligence utils)
```
**Ports:** 8082, 8083, 8086
**Purpose:** Email classification, summarization, smart replies

#### Email Service Group
**Source:** `backend/services/email/`
**Destination:** `backend/services/email/`
```
email/
├── api/
│   ✅ server.js
│   ✅ email operations
├── persistence/
│   (email storage logic)
└── corpus/
    (email corpus for ML)
```
**Port:** 8081
**Purpose:** Email CRUD, Gmail integration

#### Actions Service Group
**Sources:**
- `backend/services/shopping-agent/`
- `backend/services/scheduled-purchase/`
- `backend/services/steel-agent/` (subscriptions)

**Destination:** `backend/services/actions/`
```
actions/
├── shopping/
│   ✅ server.js (shopping-agent)
├── scheduled-purchase/
│   ✅ server.js
└── subscriptions/
    ✅ server.js (steel-agent)
```
**Ports:** 8084, 8085, 8087
**Purpose:** Actionable email handlers

#### Shared Backend Infrastructure
**New Directory:** `backend/shared/`
```
shared/
├── middleware/
│   ✅ auth.js
│   ✅ logging.js
│   ✅ cors.js
│   ✅ error-handler.js
├── utils/
│   ✅ database.js
│   ✅ cache.js
│   ✅ validation.js
├── models/
│   ✅ Email.js
│   ✅ User.js
└── config/
    ✅ database.config.js
    ✅ service.config.js
```

#### Database
**Source:** `backend/database/schema/`
**Destination:** `backend/database/`
```
✅ schemas/corpus_analytics.sql
✅ migrations/
✅ seeds/ (if any)
```

#### Scripts
**Source:** `backend/*.sh`
**Destination:** `backend/scripts/`
```
✅ check-services.sh
✅ start-services.sh
✅ stop-services.sh
✅ service-manager.js
✅ Test scripts (for working services only)
```

**Total Backend:** ~15MB (source code only, no node_modules)

---

### 3. Web Prototype

**Source:** `EmailShortForm_01/swipe-app/`
**Destination:** `Zer0_Inbox/web-prototype/`
```
✅ Complete swipe demo
✅ All HTML/CSS/JS
✅ Original concept implementation
```
**Size:** ~10MB

---

### 4. Admin Tools (3 Connected Tools Only)

**Source:** `EmailShortForm_01/Zero/*.html` and `web-tools/`
**Destination:** `Zer0_Inbox/admin-tools/`

**Connected Tools (Migrate):**
```
✅ intent-action-explorer.html
✅ live-classification-dashboard.html
✅ zero-sequence-live.html
✅ shared-ui-system.js
```

**Standalone Tools (Don't Migrate):**
```
❌ action-flows-studio.html - No backend calls
❌ action-modal-explorer.html - No backend calls
❌ action-registry-explorer.html - No backend calls
❌ classification-studio.html - No backend calls
❌ design-system-hub.html - No backend calls
❌ design-system-renderer.html - No backend calls
❌ index.html - No backend calls
❌ modal-flows-audit.html - No backend calls
❌ zero-sequence-auditor.html - No backend calls
❌ zero-tuning-studio.html - No backend calls
```

**Size:** ~500KB

---

### 5. Documentation

**Source:** Various docs
**Destination:** `Zer0_Inbox/docs/`
```
✅ PHASE1_COMPLETE.md
✅ PHASE2_COMPLETE.md
✅ CORPUS_ANALYSIS.md
✅ Architecture guides
✅ API documentation
```

---

## 🚫 What's NOT Being Migrated

### Legacy/Disconnected Code

#### 1. Backup Files (26 files)
```
❌ Zero/Views/ActionModules/*.backup
```

#### 2. Phase 3/4 Services (Disconnected - Not Integrated)
```
❌ backend/services/keywords/ - NOT in service-manager
❌ backend/services/ml-intelligence/ - NOT in service-manager
❌ Zero/Services/DynamicKeywordService.swift - Never used
❌ Zero/Services/MLIntelligenceService.swift - Integration incomplete
```
**Reason:** Built but never properly connected. Will reconnect in future Phase 5/6.

#### 3. Orphaned Services
```
❌ backend/services/corpus/ - Superseded by email service corpus
❌ backend/services/saved-mail/ - Stub/incomplete
❌ backend/services/actions/ - (if not connected)
```

#### 4. Unused iOS Services (8 files)
```
❌ ActionPlaceholders.swift
❌ AnalyticsSchema.swift
❌ AppLifecycleObserver.swift
❌ CleverPlaceholders.swift
❌ CorpusEmails.swift
❌ DynamicActionRegistry.swift
❌ EmailData.swift
❌ SiriShortcutsService.swift
```

#### 5. Standalone Web Tools (10 files)
See list above - tools with no backend integration

#### 6. Build Artifacts & Dependencies
```
❌ node_modules/ (~800MB) - Will reinstall
❌ DerivedData/ (~300MB) - Build artifacts
❌ .DS_Store files
❌ Temporary files
```

#### 7. Test Scripts for Legacy Services
```
❌ test-keyword-extraction.sh (Phase 3)
❌ test-ml-intelligence.sh (Phase 4)
❌ Tests for disconnected services
```

---

## 📊 Size Comparison

### Before (EmailShortForm_01)
```
Total:           1.9GB
- node_modules:  800MB
- DerivedData:   300MB
- Legacy code:   50MB
- .backup files: 500KB
- Source code:   ~750MB
```

### After (Zer0_Inbox)
```
Total:           ~58MB (source only)
- iOS app:       30MB
- Backend:       15MB (no node_modules)
- Web prototype: 10MB
- Admin tools:   500KB
- Docs:          2MB
```

**Reduction: 97%** (58MB vs 1.9GB)

---

## 🎯 Post-Migration Structure

```
Zer0_Inbox/
├── ios-app/                    # iOS app (clean)
│   ├── Zero/
│   │   ├── Models/
│   │   ├── Views/
│   │   ├── Services/           # Only active services
│   │   ├── Config/
│   │   ├── DesignSystem/
│   │   └── Navigation/
│   ├── ZeroTests/
│   └── ZeroUITests/
│
├── backend/                    # Consolidated backend
│   ├── shared/                 # NEW: Shared libraries
│   │   ├── middleware/
│   │   ├── utils/
│   │   ├── models/
│   │   └── config/
│   ├── services/
│   │   ├── gateway/            # API gateway
│   │   ├── intelligence/       # 3 services consolidated
│   │   │   ├── classifier/
│   │   │   ├── summarization/
│   │   │   └── smart-replies/
│   │   ├── email/              # Email operations + corpus
│   │   │   ├── api/
│   │   │   ├── corpus/
│   │   │   └── persistence/
│   │   └── actions/            # 3 action services
│   │       ├── shopping/
│   │       ├── scheduled-purchase/
│   │       └── subscriptions/
│   ├── database/
│   │   ├── schemas/
│   │   └── migrations/
│   ├── scripts/
│   └── tests/
│
├── web-prototype/              # Original swipe demo
├── admin-tools/                # Connected tools only
├── docs/                       # Architecture & API docs
│   ├── architecture/
│   ├── api/
│   └── guides/
└── README.md
```

---

## 🔄 Migration Process

### Phase 1: ✅ Structure Creation
- [x] Create Zer0_Inbox directory
- [x] Set up folder structure
- [x] Create migration manifest

### Phase 2: iOS App Migration
- [ ] Copy core Models/
- [ ] Copy Views/ (exclude .backup)
- [ ] Copy Services/ (exclude 8 unused)
- [ ] Copy Config/
- [ ] Copy DesignSystem/
- [ ] Copy Tests/
- [ ] Regenerate Xcode project
- [ ] Update paths in code
- [ ] Test build

### Phase 3: Backend Migration
- [ ] Create shared/ libraries
- [ ] Migrate gateway service
- [ ] Migrate intelligence services (3)
- [ ] Migrate email service
- [ ] Migrate action services (3)
- [ ] Update all imports to use shared/
- [ ] Update service-manager.js
- [ ] Test all services

### Phase 4: Web Assets
- [ ] Copy swipe-app to web-prototype/
- [ ] Copy 3 connected admin tools
- [ ] Update API endpoints
- [ ] Test tools

### Phase 5: Documentation
- [ ] Copy relevant docs
- [ ] Create architecture.md
- [ ] Create API_REFERENCE.md
- [ ] Update README.md

### Phase 6: Testing
- [ ] Run iOS tests
- [ ] Run backend tests
- [ ] End-to-end integration test
- [ ] Verify all connections work

---

## ✅ Success Criteria

Migration is complete when:

1. ✅ All 235 iOS files compile and run
2. ✅ All 8 backend services start and respond
3. ✅ iOS app connects to all 8 services
4. ✅ No broken imports or missing dependencies
5. ✅ All tests pass
6. ✅ Admin tools can query backend
7. ✅ Total size < 100MB (source only)
8. ✅ No fake handshakes - all connections verified
9. ✅ No dead ends - all code paths work
10. ✅ Documentation complete

---

## 🚀 Future Phases (Post-Migration)

### Phase 5: Reconnect ML Intelligence
- Add keywords service properly
- Add ML intelligence service properly
- Full iOS integration
- End-to-end testing

### Phase 6: Refactor God Objects
- Split DataGenerator.swift (5,863 lines)
- Split action-catalog.js (1,304 lines)
- Apply feature module pattern

### Phase 7: Further Consolidation
- Merge intelligence services into one process
- Merge action services into one process
- Target: 3 total backend services

---

**Status:** Structure created, ready to begin selective migration.
**Next:** Start copying iOS core files to new structure.

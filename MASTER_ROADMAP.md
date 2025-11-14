# Zero Inbox Master Roadmap
**Systematic Feature Implementation Plan**

**Status**: Active
**Last Updated**: 2025-11-13
**Completion**: 15/40 items (38%)

---

## Execution Principles

### 1. Zero Regression
- All changes must pass existing tests
- New features require new tests
- iOS builds must succeed before commit
- Design tokens enforced via pre-commit hooks

### 2. Zero Bloat
- Each feature must solve a real problem
- Remove unused code before adding new code
- Bundle size monitored (iOS app size < 50MB)
- Design token usage > 95% (no hardcoded values)

### 3. Systematic Progress
- Complete one phase before starting next
- Document as you build
- Commit frequently (small, atomic changes)
- Track dependencies explicitly

---

## Phase 1: Foundation (Week 1) ✅ COMPLETE

**Goal**: Establish design system infrastructure
**Risk**: Low
**Bloat Risk**: None (removes inconsistency)

### 1.1 Design Token System ✅
- [x] Create tokens.json (single source of truth)
- [x] Generate iOS DesignTokens.swift
- [x] Generate Web CSS variables
- [x] Refactor 129 View files (1,793 replacements)
- **Result**: 100% token-based design system

### 1.2 Figma Sync Automation ✅
- [x] Build sync-to-figma.js script
- [x] Create Figma plugin (6 phases)
- [x] Fix ads gradient colors
- [x] Sync typography (7 text styles)
- [x] Sync shadows (3 effect styles)
- **Result**: iOS ↔ Figma design parity

### 1.3 Developer Guardrails ✅
- [x] Pre-commit hooks (block hardcoded values)
- [x] CI/CD workflow (auto-generate tokens)
- [x] Documentation (DESIGN_SYSTEM_STATUS.md)
- **Result**: Automated enforcement

**Phase 1 Metrics**:
- Time: 3 days
- Files changed: 150+
- Lines changed: 10,000+
- Regressions: 0
- iOS build: ✅ Passing

---

## Phase 2: Design System Expansion (Week 2)

**Goal**: Complete design system with dark mode + components
**Risk**: Medium (visual regressions possible)
**Bloat Risk**: Low (adds value, removes duplication)

### 2.1 Dark Mode Implementation
**Time**: 5 days
**Dependencies**: Phase 1.1 (tokens)

- [ ] Add dark mode tokens to tokens.json
  - [ ] Dark background colors
  - [ ] Dark text colors
  - [ ] Dark border/overlay colors
- [ ] Update generate-swift.js for dark mode
  - [ ] Asset Catalog generation (.colorset files)
  - [ ] SwiftUI Color extensions
- [ ] Refactor Views for dark mode
  - [ ] Update 30 core views
  - [ ] Test color contrast (WCAG AA)
- [ ] Add dark mode toggle in Settings
  - [ ] Respect system preference
  - [ ] Manual override option
- [ ] Update Figma with dark mode styles

**Success Criteria**:
- [ ] All views render in dark mode
- [ ] No color contrast violations
- [ ] Smooth theme switching (no flicker)
- [ ] iOS build passes

**Anti-Bloat Measures**:
- Use Asset Catalog (native iOS, zero runtime cost)
- Remove any manual dark mode hacks
- Single token set (automatic switching)

### 2.2 Figma Component Library
**Time**: 3 days
**Dependencies**: Phase 1.2 (Figma sync), 2.1 (dark mode)

- [ ] Create master components in Figma
  - [ ] Card component (with variants)
  - [ ] Button component (all states)
  - [ ] Input/form components
  - [ ] Modal/sheet components
- [ ] Apply synced styles to all components
- [ ] Create component documentation
- [ ] Publish to team library

**Success Criteria**:
- [ ] 20+ reusable components
- [ ] All use synced design tokens
- [ ] Full documentation in Figma
- [ ] Team can use library

**Anti-Bloat Measures**:
- Only create components actually used in app
- Remove any old/unused components
- Auto-layout for responsive components

### 2.3 Animation Tokens
**Time**: 2 days
**Dependencies**: Phase 1.1 (tokens)

- [ ] Add animation tokens to tokens.json
  - [ ] Duration scale (fast: 150ms, normal: 250ms, slow: 400ms)
  - [ ] Easing curves (easeIn, easeOut, easeInOut, spring)
  - [ ] Transition types
- [ ] Generate iOS animation constants
- [ ] Update 10 animated views
- [ ] Document animation guidelines

**Success Criteria**:
- [ ] Consistent animation timing
- [ ] Smooth, professional feel
- [ ] iOS build passes

**Anti-Bloat Measures**:
- Replace magic numbers (0.3, 0.5) with tokens
- Remove duplicate animation code

**Phase 2 Deliverables**:
- Dark mode fully functional
- Figma component library published
- Animation system standardized

---

## Phase 3: Developer Experience (Week 3)

**Goal**: Automate workflows, improve docs
**Risk**: Low
**Bloat Risk**: None (pure DX improvements)

### 3.1 Enhanced CI/CD Workflows
**Time**: 2 days
**Dependencies**: Phase 1.3 (basic CI/CD)

- [ ] Token validation workflow
  - [ ] JSON schema validation
  - [ ] Duplicate key detection
  - [ ] Required field checks
- [ ] iOS build workflow
  - [ ] Build on PR
  - [ ] Run tests
  - [ ] Code coverage reports
- [ ] Figma sync workflow
  - [ ] Auto-sync on token changes
  - [ ] Create PR with screenshots
- [ ] Dependency update workflow
  - [ ] Auto-update npm packages
  - [ ] Auto-update Swift packages

**Success Criteria**:
- [ ] All workflows green
- [ ] PRs auto-validated
- [ ] Zero manual token sync

### 3.2 Comprehensive Documentation
**Time**: 3 days
**Dependencies**: All previous phases

- [ ] Design System Guide
  - [ ] Token usage examples
  - [ ] Component guidelines
  - [ ] Dark mode guide
- [ ] Developer Onboarding
  - [ ] Setup instructions
  - [ ] Architecture overview
  - [ ] Contributing guide
- [ ] API Documentation
  - [ ] Generate Swift docs
  - [ ] Document all public APIs
- [ ] Figma Documentation
  - [ ] Component usage guide
  - [ ] Design principles

**Success Criteria**:
- [ ] New developer can onboard in < 1 hour
- [ ] All public APIs documented
- [ ] Design system guide complete

### 3.3 Xcode Previews System
**Time**: 2 days
**Dependencies**: Phase 1.1 (tokens)

- [ ] Create preview helpers
  - [ ] PreviewDevice extensions
  - [ ] Mock data generators
  - [ ] State preview variants
- [ ] Add previews to 50 key views
- [ ] Document preview best practices

**Success Criteria**:
- [ ] 50+ views with previews
- [ ] Previews work in light/dark mode
- [ ] Fast preview rendering

**Anti-Bloat Measures**:
- Previews are DEBUG only (zero production cost)
- Reuse mock data helpers

**Phase 3 Deliverables**:
- Fully automated CI/CD
- Complete documentation
- Xcode Previews for rapid iteration

---

## Phase 4: iOS App Features (Week 4-5)

**Goal**: Ship high-value user features
**Risk**: Medium (user-facing changes)
**Bloat Risk**: Medium (must prioritize ruthlessly)

### 4.1 Advanced Email Actions
**Time**: 4 days
**Dependencies**: None (self-contained)

- [ ] Snooze functionality
  - [ ] Snooze UI (action sheet)
  - [ ] Snooze storage (local)
  - [ ] Notification system (remind)
  - [ ] Un-snooze action
- [ ] Email templates
  - [ ] Template editor
  - [ ] Template library
  - [ ] Quick insert
- [ ] Schedule send
  - [ ] DateTime picker
  - [ ] Send queue
  - [ ] Retry logic

**Success Criteria**:
- [ ] Snooze works offline
- [ ] Templates save reliably
- [ ] Scheduled sends fire correctly

**Anti-Bloat Measures**:
- Use iOS native notifications (no custom system)
- Store locally (no backend needed yet)
- Reuse existing UI components

### 4.2 Search & Filters
**Time**: 5 days
**Dependencies**: None

- [ ] Full-text search
  - [ ] Index email content (Core Spotlight)
  - [ ] Search UI (search bar)
  - [ ] Result highlighting
  - [ ] Recent searches
- [ ] Smart filters
  - [ ] Filter by sender
  - [ ] Filter by date range
  - [ ] Filter by archetype
  - [ ] Filter by attachment type
  - [ ] Saved filter presets
- [ ] Search suggestions
  - [ ] Auto-complete senders
  - [ ] Suggest filters

**Success Criteria**:
- [ ] Search returns results < 100ms
- [ ] Filters work in combination
- [ ] Search persists across app restarts

**Anti-Bloat Measures**:
- Use Core Spotlight (iOS native, zero maintenance)
- Don't build custom indexing
- Limit saved searches (max 10)

### 4.3 Widgets & App Clips
**Time**: 4 days
**Dependencies**: Phase 2.1 (dark mode tokens)

- [ ] Home Screen Widgets
  - [ ] Small: Inbox count
  - [ ] Medium: Recent emails (3)
  - [ ] Large: Inbox + actions
  - [ ] Dark mode support
- [ ] Lock Screen Widgets (iOS 18)
  - [ ] Circular: Unread count
  - [ ] Rectangular: Latest email
- [ ] App Clip (optional)
  - [ ] Quick compose
  - [ ] Share extension

**Success Criteria**:
- [ ] Widgets update reliably
- [ ] Low battery impact
- [ ] Beautiful in light/dark mode

**Anti-Bloat Measures**:
- Widgets share code with main app
- No separate widget logic (use shared ViewModels)
- App Clip only if needed (maybe skip)

**Phase 4 Deliverables**:
- Snooze, templates, schedule send
- Powerful search & filters
- Home screen widgets

---

## Phase 5: Web Integration (Week 6)

**Goal**: Deploy design system to web
**Risk**: Low (web is separate)
**Bloat Risk**: Low (reuses tokens)

### 5.1 Deploy CSS Variables
**Time**: 2 days
**Dependencies**: Phase 1.1 (web tokens generated)

- [ ] Integrate generated CSS into web app
  - [ ] Import design-tokens.css
  - [ ] Update existing styles
  - [ ] Remove hardcoded values
- [ ] Test cross-browser
  - [ ] Chrome, Safari, Firefox
  - [ ] Mobile browsers
- [ ] Add dark mode to web
  - [ ] Detect system preference
  - [ ] Manual toggle
  - [ ] Persist preference

**Success Criteria**:
- [ ] Web uses 100% tokens
- [ ] Dark mode works
- [ ] No visual regressions

### 5.2 Web Components Library
**Time**: 4 days
**Dependencies**: Phase 5.1

- [ ] Create React components
  - [ ] Button (using CSS tokens)
  - [ ] Card (matches iOS)
  - [ ] Input/Form components
  - [ ] Modal/Dialog
- [ ] Storybook setup
  - [ ] Component documentation
  - [ ] Interactive examples
  - [ ] Dark mode toggle
- [ ] Publish to npm (optional)

**Success Criteria**:
- [ ] 10+ reusable components
- [ ] Matches iOS design
- [ ] Storybook live

### 5.3 Landing Page Redesign
**Time**: 3 days
**Dependencies**: Phase 5.2

- [ ] Apply new design system
  - [ ] Use web components
  - [ ] Update typography
  - [ ] Update colors
- [ ] Add animations
  - [ ] Use animation tokens
  - [ ] Smooth transitions
- [ ] Performance optimization
  - [ ] Lazy loading
  - [ ] Image optimization
  - [ ] Bundle size check

**Success Criteria**:
- [ ] Landing page matches iOS app
- [ ] Lighthouse score > 95
- [ ] Load time < 2s

**Phase 5 Deliverables**:
- Web design system live
- Component library published
- Beautiful landing page

---

## Phase 6: ML & Classification (Week 7-8)

**Goal**: Improve email classification accuracy
**Risk**: High (ML is complex)
**Bloat Risk**: High (ML models are large)

### 6.1 Enhanced ML Model
**Time**: 5 days
**Dependencies**: None

- [ ] Upgrade classification model
  - [ ] Fine-tune on more data
  - [ ] Add more features (email metadata)
  - [ ] Test different architectures
- [ ] Improve confidence scoring
  - [ ] Calibrate probabilities
  - [ ] Add uncertainty estimates
- [ ] A/B test new model
  - [ ] Compare to current model
  - [ ] Measure accuracy gains

**Success Criteria**:
- [ ] Classification accuracy > 90%
- [ ] Model size < 10MB
- [ ] Inference time < 50ms

**Anti-Bloat Measures**:
- Model quantization (reduce size 4x)
- On-device only (no cloud calls)
- Only ship if accuracy improves significantly

### 6.2 Training Data Pipeline
**Time**: 4 days
**Dependencies**: Phase 6.1

- [ ] Data collection system
  - [ ] User feedback mechanism
  - [ ] Anonymized telemetry
  - [ ] Export to training format
- [ ] Labeling interface
  - [ ] Quick label UI
  - [ ] Bulk labeling
  - [ ] Label validation
- [ ] Training automation
  - [ ] Auto-retrain on new data
  - [ ] Model evaluation
  - [ ] Deploy best model

**Success Criteria**:
- [ ] Can collect 1000+ labeled emails
- [ ] Retraining takes < 1 hour
- [ ] Model improves over time

### 6.3 Classification Analytics
**Time**: 3 days
**Dependencies**: Phase 6.1

- [ ] Analytics dashboard
  - [ ] Classification distribution
  - [ ] Confidence histogram
  - [ ] Error analysis
- [ ] User insights
  - [ ] Top senders by archetype
  - [ ] Processing time trends
  - [ ] Action patterns
- [ ] Export reports
  - [ ] CSV export
  - [ ] Weekly summaries

**Success Criteria**:
- [ ] Dashboard shows useful insights
- [ ] Helps improve model
- [ ] Users find it valuable

**Phase 6 Deliverables**:
- Highly accurate ML model
- Continuous improvement pipeline
- Useful analytics

---

## Testing Strategy (Continuous)

### Regression Prevention

**Automated Tests**:
- [ ] Unit tests for all new functions (coverage > 80%)
- [ ] UI tests for critical flows (5+ key flows)
- [ ] Snapshot tests for visual regressions
- [ ] Performance tests (app launch < 2s)

**Manual Tests** (before each phase):
- [ ] iOS app builds successfully
- [ ] All existing features work
- [ ] Dark mode looks good
- [ ] No crashes in 10min session

**Pre-Commit Checks**:
- [x] Design token enforcement (active)
- [ ] SwiftLint (code style)
- [ ] TypeScript type checking
- [ ] Bundle size check

### Bloat Prevention

**Metrics to Track**:
- iOS app size (target: < 50MB)
- Lines of code (target: no unnecessary growth)
- Dependency count (minimize)
- Token usage % (target: > 95%)

**Regular Audits**:
- [ ] Weekly: Remove unused code
- [ ] Monthly: Dependency audit
- [ ] Per phase: Architecture review

---

## Risk Mitigation

### High-Risk Items

**Dark Mode (Phase 2.1)**:
- Risk: Visual regressions, contrast issues
- Mitigation: Extensive testing, WCAG validation
- Rollback: Feature flag to disable

**ML Model (Phase 6.1)**:
- Risk: Accuracy regression, model size bloat
- Mitigation: A/B test, keep old model as fallback
- Rollback: Revert to previous model

**Search (Phase 4.2)**:
- Risk: Performance issues with large inboxes
- Mitigation: Limit indexing, lazy loading
- Rollback: Disable search, fix, re-enable

### Medium-Risk Items

**Widgets (Phase 4.3)**:
- Risk: Battery drain, update failures
- Mitigation: Efficient timelines, error handling
- Rollback: Remove widgets from App Store version

**Web Components (Phase 5.2)**:
- Risk: Bundle size growth
- Mitigation: Tree shaking, code splitting
- Rollback: Web is separate, can rollback easily

---

## Success Criteria (Overall)

### Technical Excellence
- [ ] Zero regressions (all existing features work)
- [ ] iOS build always green
- [ ] Design tokens 100% enforced
- [ ] App size < 50MB
- [ ] Test coverage > 80%

### User Value
- [ ] Dark mode improves usability
- [ ] Search saves users time
- [ ] Widgets increase engagement
- [ ] ML accuracy > 90%

### Developer Experience
- [ ] Documentation complete
- [ ] CI/CD fully automated
- [ ] New features easy to add
- [ ] Design system mature

### Design Consistency
- [ ] iOS ↔ Figma parity
- [ ] Web matches iOS
- [ ] All platforms use same tokens
- [ ] No hardcoded design values

---

## Execution Timeline

**Week 1**: ✅ Phase 1 (Foundation) - COMPLETE
**Week 2**: Phase 2 (Design Expansion)
**Week 3**: Phase 3 (Developer Experience)
**Week 4-5**: Phase 4 (iOS Features)
**Week 6**: Phase 5 (Web Integration)
**Week 7-8**: Phase 6 (ML Improvements)

**Total Time**: 8 weeks
**Total Features**: 40 items
**Current Progress**: 15/40 (38%)

---

## Next Immediate Steps

1. **Dark Mode Implementation** (Phase 2.1)
   - Start with token additions
   - Then asset catalog generation
   - Then view updates

2. **After Each Phase**:
   - Run full test suite
   - Manual testing
   - Commit with detailed message
   - Update this roadmap

3. **Weekly Reviews**:
   - Check metrics (size, coverage, tokens)
   - Audit for bloat
   - Adjust plan if needed

---

## Notes

- This roadmap is living - adjust as needed
- Skip optional items if time is tight
- Always prioritize user value over features
- Keep app lean and fast

**Last reviewed**: 2025-11-13
**Next review**: 2025-11-20

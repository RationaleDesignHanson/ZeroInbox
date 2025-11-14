# Zero Inbox Master Roadmap
**Milestone-Based Feature Implementation Plan**

**Status**: Active
**Last Updated**: 2025-11-13
**Completion**: Milestone 1 ✅ Complete (15/40 items shipped)

---

## Philosophy: Ship When Ready

**Quality Over Speed**
- No arbitrary deadlines
- Each milestone ships when all quality gates pass
- Take time to do it right the first time
- Sustainable pace beats burnout

**Milestone Gates**
- ✅ All tests passing
- ✅ Zero regressions detected
- ✅ Code reviewed and documented
- ✅ Metrics within targets
- ✅ Feature fully usable

---

## Execution Principles

### 1. Zero Regression
- All changes must pass existing tests
- New features require new tests
- iOS builds must succeed before commit
- Design tokens enforced via pre-commit hooks
- Manual testing before milestone completion

### 2. Zero Bloat
- Each feature must solve a real problem
- Remove unused code before adding new code
- Bundle size monitored (iOS app size < 50MB)
- Design token usage > 95% (no hardcoded values)
- Monthly dependency audits

### 3. Systematic Progress
- Complete one milestone before starting next
- Document as you build
- Commit frequently (small, atomic changes)
- Track dependencies explicitly
- Celebrate milestone completions

---

## Milestone 1: Foundation ✅ COMPLETE

**Goal**: Establish design system infrastructure
**Effort**: Major (341 files, 83K+ lines changed)
**Duration**: 2-3 weeks of focused work
**Status**: ✅ SHIPPED

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

**Milestone 1 Metrics**:
- Files changed: 341
- Lines added: 83,207
- Lines deleted: 1,898
- Commits: 5 major milestones
- Regressions: 0
- iOS build: ✅ Passing
- Token coverage: 100% (129 files refactored)

---

## Milestone 2: Design System Expansion

**Goal**: Complete design system with dark mode + components
**Effort**: Medium-Large
**Status**: 🔄 Ready to start
**Dependencies**: Milestone 1 (tokens) ✅

**Quality Gates**:
- [ ] All views render correctly in dark mode
- [ ] WCAG AA color contrast compliance
- [ ] 20+ Figma components published
- [ ] Animation tokens standardized
- [ ] Zero regressions in light mode
- [ ] iOS build passes

### 2.1 Dark Mode Implementation
**Effort**: Medium
**Dependencies**: Tokens system ✅

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
**Effort**: Medium
**Dependencies**: Figma sync ✅, Dark mode tokens

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
**Effort**: Small
**Dependencies**: Tokens system ✅

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

**Milestone 2 Deliverables**:
- [ ] Dark mode fully functional
- [ ] Figma component library published
- [ ] Animation system standardized

---

## Milestone 3: Developer Experience

**Goal**: Automate workflows, improve docs
**Effort**: Medium
**Status**: ⏸️ Blocked by Milestone 2
**Dependencies**: Milestones 1-2 ✅

**Quality Gates**:
- [ ] All CI/CD workflows green
- [ ] Documentation complete
- [ ] New developer can onboard < 1 hour
- [ ] 50+ views have Xcode previews
- [ ] Zero manual processes

### 3.1 Enhanced CI/CD Workflows
**Effort**: Small
**Dependencies**: Basic CI/CD ✅

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
**Effort**: Medium
**Dependencies**: All previous milestones

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
**Effort**: Small
**Dependencies**: Tokens system ✅

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

**Milestone 3 Deliverables**:
- [ ] Fully automated CI/CD
- [ ] Complete documentation
- [ ] Xcode Previews for rapid iteration

---

## Milestone 4: iOS App Features

**Goal**: Ship high-value user features
**Effort**: Large
**Status**: ⏸️ Blocked by Milestones 1-3
**Dependencies**: Foundation complete ✅

**Quality Gates**:
- [ ] All features work offline
- [ ] Search performance < 100ms
- [ ] Widgets low battery impact
- [ ] No user-reported bugs
- [ ] App Store ready

### 4.1 Advanced Email Actions
**Effort**: Medium
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
**Effort**: Medium
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
**Effort**: Medium
**Dependencies**: Dark mode tokens (Milestone 2.1)

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

**Milestone 4 Deliverables**:
- [ ] Snooze, templates, schedule send
- [ ] Powerful search & filters
- [ ] Home screen widgets

---

## Milestone 5: Web Integration

**Goal**: Deploy design system to web
**Effort**: Medium
**Status**: ⏸️ Blocked by Milestones 1-2
**Dependencies**: Design tokens ✅, Dark mode tokens

**Quality Gates**:
- [ ] Web uses 100% design tokens
- [ ] Cross-browser tested (Chrome, Safari, Firefox)
- [ ] Dark mode fully functional
- [ ] Zero visual regressions
- [ ] Lighthouse score > 95

### 5.1 Deploy CSS Variables
**Effort**: Small
**Dependencies**: Web tokens generated (Milestone 1.1) ✅

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
**Effort**: Medium
**Dependencies**: CSS Variables (5.1)

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
**Effort**: Small-Medium
**Dependencies**: Web Components (5.2)

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

**Milestone 5 Deliverables**:
- [ ] Web design system live
- [ ] Component library published
- [ ] Beautiful landing page

---

## Milestone 6: ML & Classification

**Goal**: Improve email classification accuracy
**Effort**: Large
**Status**: ⏸️ Blocked by all previous milestones
**Dependencies**: Foundation complete ✅, User feedback system

**Quality Gates**:
- [ ] Classification accuracy > 90%
- [ ] Model size < 10MB
- [ ] Inference time < 50ms
- [ ] A/B tested against current model
- [ ] No accuracy regressions

### 6.1 Enhanced ML Model
**Effort**: Large
**Dependencies**: User feedback data collection

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
**Effort**: Medium
**Dependencies**: Enhanced ML Model (6.1)

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
**Effort**: Small-Medium
**Dependencies**: Enhanced ML Model (6.1)

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

**Milestone 6 Deliverables**:
- [ ] Highly accurate ML model (>90% accuracy)
- [ ] Continuous improvement pipeline
- [ ] Useful analytics dashboard

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

## Progress Tracking

### Milestone Status

- ✅ **Milestone 1**: Foundation - COMPLETE (15 items shipped)
- 🔄 **Milestone 2**: Design System Expansion - Ready to start
- ⏸️ **Milestone 3**: Developer Experience - Blocked by Milestone 2
- ⏸️ **Milestone 4**: iOS App Features - Blocked by Milestones 1-3
- ⏸️ **Milestone 5**: Web Integration - Blocked by Milestones 1-2
- ⏸️ **Milestone 6**: ML & Classification - Blocked by all previous

### Overall Progress

**Shipped**: 15/40 features (38%)
**In Progress**: 0
**Remaining**: 25 features

**Current Focus**: Planning Milestone 2 (Dark Mode + Figma Components + Animations)

---

## Next Immediate Steps

1. **Start Milestone 2: Design System Expansion**
   - Begin with dark mode token additions (2.1)
   - Generate asset catalogs for iOS
   - Update core views for dark mode
   - Create Figma component library (2.2)
   - Standardize animation tokens (2.3)

2. **After Each Feature**:
   - Run full test suite
   - Manual testing checklist
   - Commit with detailed message
   - Update this roadmap's progress

3. **Regular Reviews**:
   - Check metrics after each milestone (size, coverage, tokens)
   - Audit for bloat and unused code
   - Celebrate milestone completions
   - Adjust plan based on learnings

---

## Notes

- This roadmap is living - adjust as needed
- Skip optional items if time is tight
- Always prioritize user value over features
- Keep app lean and fast

**Last reviewed**: 2025-11-13 (converted to milestone-based)
**Next review**: After Milestone 2 completion

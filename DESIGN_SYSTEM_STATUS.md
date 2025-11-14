# Zero Inbox Design System - Integration Status

**Date:** November 13, 2025
**Status:** In Progress - 70% Complete
**Goal:** Single source of truth for design tokens across iOS and Web

---

## Executive Summary

The Zero Inbox design system is being consolidated from multiple sources into a unified token-based system. We've completed the core infrastructure but need to finish generator polish and systematic refactoring of hardcoded values.

**Progress:**
- ✅ 305-line tokens.json created (matches iOS implementation)
- ✅ Swift generator rewritten (needs final polish)
- ⚠️ 100+ View files have hardcoded values (needs systematic refactoring)
- ⚠️ 9 MD documentation files need consolidation (this file)
- 📍 iOS DesignTokens.swift is current source of truth

---

## Current Architecture

### Design Token Sources

```
┌─────────────────────────────────────────┐
│  Three Token Systems (Need Unification) │
└─────────────────────────────────────────┘

1. iOS DesignTokens.swift (Active - 265 lines)
   Location: Zero_ios_2/Zero/Config/DesignTokens.swift
   Status: ✅ Production, well-architected
   Structure: Primitive → Semantic → Component

2. design-system/tokens.json (New - 305 lines)
   Location: design-system/tokens.json
   Status: ⚠️ Just created, matches iOS
   Purpose: Single source of truth for generation

3. design-system/generated/DesignTokens.swift
   Location: design-system/generated/DesignTokens.swift
   Status: ⚠️ Generated but has minor bugs
   Purpose: Will replace iOS version when ready
```

### Integration Flow (Target)

```
┌──────────────┐
│ tokens.json  │ ← Single source of truth
└──────┬───────┘
       │
       ├─→ generate-swift.js → DesignTokens.swift (iOS)
       ├─→ generate-web.js → design-tokens.css (Web)
       └─→ generate-web.js → design-tokens.js (Web)
```

---

## Token System Comparison

### Primitive Tokens

| Token Type | Values | Purpose |
|------------|--------|---------|
| **Size** | 2, 4, 6, 8, 10, 12, 16, 20, 24, 32, 48 | Base measurements |
| **Opacity** | 0.0, 0.05, 0.1, 0.2, 0.3, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0 | Transparency scale |
| **Blur** | 10, 20, 30, 40 | Glassmorphic effects |
| **Duration** | 0.1s, 0.2s, 0.3s, 0.5s, 0.7s, 1.0s | Animation timing |

### Semantic Tokens

**Spacing:**
- card (24px), modal (24px), section (20px), component (16px)
- element (12px), inline (8px), tight (6px), minimal (4px)

**Radius:**
- card (16px), modal (20px), button (12px), chip (8px), circle (999px)

**Opacity (Semantic):**
- Glass: ultraLight (0.05), light (0.1), medium (0.2)
- Overlay: light (0.2), medium (0.3), strong (0.5)
- Text: disabled (0.6), subtle (0.7), tertiary (0.8), secondary (0.9), primary (1.0)

**Colors:**
- Text hierarchy (white with opacity)
- Borders and dividers
- Background overlays (white/black)
- Accent colors (blue, green, purple, red)
- Archetype gradients (Mail: #667eea → #764ba2, Ads: #16bbaa → #4fd19e)
- Ads text colors (dark teal variants)
- Semantic (error, warning, success, info)

### Component Tokens

| Component | Tokens |
|-----------|--------|
| **Card** | padding (24), radius (16), shadowRadius (20), shadowOpacity, glassOpacity |
| **Button** | padding (16), radius (12), heights (56/44/32), iconSize (20) |
| **Modal** | padding (24), radius (20), overlayOpacity (0.5) |
| **Badge** | size (12), sizeLarge (16), offsets, borderWidth (2) |
| **Shadow** | card, button, subtle (with color, radius, x, y) |
| **Animation** | quick (0.2s), standard (0.5s), slow (0.7s) |
| **Materials** | glassmorphic (ultraThinMaterial) |

---

## Critical Issue: Hardcoded Values

### The Problem

**100+ View files contain hardcoded values** instead of using DesignTokens:

```swift
// ❌ Current (Hardcoded)
.opacity(0.6)
.cornerRadius(12)
.padding(16)

// ✅ Should be (Using Tokens)
.opacity(DesignTokens.Opacity.textDisabled)
.cornerRadius(DesignTokens.Radius.button)
.padding(DesignTokens.Spacing.component)
```

### Affected Files

**By Hardcoded Type:**
- `.opacity(0.X)` → 100 files
- `.cornerRadius(X)` → 72 files
- `.padding(X)` → 22 files

**Example Files:**
- UndoToastView.swift
- SimpleCardView.swift
- Feed/LiquidGlassBottomNav.swift
- All 35 ActionModals/*.swift files
- Components/ThreadedCardView.swift
- Settings/*.swift files

### Refactoring Strategy

**Phase 1: Opacity (100 files)**
```bash
# Pattern: .opacity(0.6) → .opacity(DesignTokens.Opacity.textDisabled)
# Safe replacements with exact mapping:
0.05 → DesignTokens.Opacity.glassUltraLight
0.1  → DesignTokens.Opacity.glassLight
0.2  → DesignTokens.Opacity.overlayLight
0.3  → DesignTokens.Opacity.overlayMedium
0.5  → DesignTokens.Opacity.overlayStrong
0.6  → DesignTokens.Opacity.textDisabled
0.7  → DesignTokens.Opacity.textSubtle
0.8  → DesignTokens.Opacity.textTertiary
0.9  → DesignTokens.Opacity.textSecondary
1.0  → DesignTokens.Opacity.textPrimary
```

**Phase 2: Corner Radius (72 files)**
```bash
# Pattern: .cornerRadius(12) → .cornerRadius(DesignTokens.Radius.button)
4  → DesignTokens.Radius.minimal
8  → DesignTokens.Radius.chip
12 → DesignTokens.Radius.button
16 → DesignTokens.Radius.card
20 → DesignTokens.Radius.modal
999 → DesignTokens.Radius.circle
```

**Phase 3: Padding (22 files)**
```bash
# Pattern: .padding(16) → .padding(DesignTokens.Spacing.component)
4  → DesignTokens.Spacing.minimal
6  → DesignTokens.Spacing.tight
8  → DesignTokens.Spacing.inline
12 → DesignTokens.Spacing.element
16 → DesignTokens.Spacing.component
20 → DesignTokens.Spacing.section
24 → DesignTokens.Spacing.card
```

---

## Generator Script Status

### What Works ✅

- Reads tokens.json correctly
- Generates Primitive token enums
- Generates Semantic token enums
- Generates Component token enums
- Resolves token references like `{primitive.size.xl}`
- Converts hex colors to Swift Color()
- Handles typography scales
- Creates proper Swift structure

### Known Issues ⚠️

**1. Stray closing braces in references:**
```swift
// Current (Bug):
static let card: CGFloat = Primitive.Size.xxxl}  // ← Extra }

// Should be:
static let card: CGFloat = Primitive.Size.xxxl
```

**2. Metadata keys leaking through:**
```swift
// Current (Bug):
static let text$description = Color.white.opacity(...)

// Should be filtered out (starts with $)
```

**3. Needs one more iteration:**
- Apply `.filter(([key]) => !key.startsWith('$'))` to all Object.entries()
- Fix reference extraction in colors section
- Test with real Xcode project

**Estimated fix time:** 15 minutes

---

## Figma Integration

### Current Setup

**Figma File:** `WuQicPi1wbHXqEcYCQcLfr` (zerotest)

**Sync Infrastructure:**
```
design-system/
├── sync/
│   ├── export-from-figma.js     ← Exports from Figma API
│   ├── generate-swift.js         ← Generates iOS tokens
│   ├── generate-web.js           ← Generates Web tokens
│   ├── sync-all.js               ← Master sync script
│   └── design-tokens.json        ← Exported tokens (temp)
├── generated/
│   ├── DesignTokens.swift        ← iOS output
│   ├── design-tokens.css         ← Web CSS output
│   └── design-tokens.js          ← Web JS output
└── tokens.json                   ← Master tokens (manual)
```

**Current Status:**
- ✅ Scripts exist and work
- ⚠️ Not using Figma export (using manual tokens.json instead)
- ⚠️ Gradient colors mismatched (documented in GRADIENT_MISMATCH_RESOLUTION.md)

### Gradient Color Decision Required

**The Issue:**
- Figma has: Mail (#3b82f6 → #0ea5e9), Ads (#10b981 → #34ecb3)
- iOS has: Mail (#667eea → #764ba2), Ads (#16bbaa → #4fd19e)

**Resolution in tokens.json:**
- Using iOS gradients as source of truth
- Figma needs to be updated to match

---

## Documentation Consolidation

### Untracked MD Files (9 total)

These files document various stages of design system work:

1. **ACTION_IMPLEMENTATION_PROGRESS.md** - Action system work
2. **COMPONENT_OPTIMIZATION_COMPLETE.md** - Component consolidation (47→12 templates)
3. **DESIGN_SYSTEM_AUDIT.md** - Initial audit of Figma vs iOS
4. **DESIGN_TOKEN_SYNC_COMPLETE.md** - Token sync automation guide
5. **FIGMA_GENERATOR_COMPLETE.md** - Figma plugin completion
6. **FIGMA_IMPLEMENTATION_COMPLETE.md** - Figma component library
7. **FIGMA_MCP_STATUS.md** - MCP server status
8. **GRADIENT_MISMATCH_RESOLUTION.md** - Gradient color decision
9. **ZERO_INBOX_DESIGN_SYSTEM_COMPLETE.md** - Master implementation guide

**Decision:** Consolidate key information into this file, archive the rest.

### Key Insights from Docs

**From COMPONENT_OPTIMIZATION_COMPLETE.md:**
- 169 total actions analyzed
- 103 GO_TO actions (61%) → Visual feedback only
- 66 IN_APP actions (39%) → 12 modal templates
- 60% reduction in components vs original 47 unique modals

**From FIGMA_BUILD_GUIDE.md:**
- 8-week build plan for complete design system in Figma
- Week 1: Foundation (buttons, inputs, badges)
- Weeks 2-5: Modal templates
- Weeks 6-8: Polish and ship

**From DESIGN_SYSTEM_AUDIT.md:**
- Figma system is 80% complete
- Missing: vibrant color palette, shadow styles, some opacity values
- Critical issue: gradient mismatch (now resolved)

---

## File Structure

### Current State

```
/Users/matthanson/Zer0_Inbox/
├── Zero_ios_2/Zero/Config/
│   └── DesignTokens.swift              ← Active (265 lines)
│
├── design-system/
│   ├── tokens.json                      ← ✅ NEW: Master tokens (305 lines)
│   ├── sync/
│   │   ├── generate-swift.js            ← ✅ Rewritten
│   │   ├── generate-web.js              ← Ready to use
│   │   ├── export-from-figma.js         ← Works
│   │   └── sync-all.js                  ← Orchestrator
│   ├── generated/
│   │   ├── DesignTokens.swift           ← ⚠️ Has minor bugs
│   │   ├── design-tokens.css            ← Ready
│   │   └── design-tokens.js             ← Ready
│   ├── figma-plugin/                    ← Complete
│   └── README.md                        ← Updated
│
└── [9 untracked MD files]               ← Consolidate/Archive
```

### Git Status

**Uncommitted Changes:**
- Modified: ActionRegistry.swift, ContextualActionService.swift, IntentActionFlowTests.swift, action-catalog.js
- Untracked: All design-system/ directory, 9 MD files, new Swift files, 3 JS scripts

**Commits Ahead:** 3 commits ahead of origin/master

---

## Next Steps

### Immediate (15 minutes)

**1. Fix Generator Script**
```bash
cd design-system/sync
# Apply .filter(([key]) => !key.startsWith('$')) to all Object.entries()
# Fix color section to filter metadata
# Regenerate: node generate-swift.js
```

**2. Test Generated File**
```bash
# Copy to Xcode project
cp design-system/generated/DesignTokens.swift Zero_ios_2/Zero/Config/
# Build in Xcode
# Fix any compilation errors
```

### Short Term (2 hours)

**3. Create Refactoring Script**
```javascript
// refactor-hardcoded-values.js
// - Scan 100+ View files
// - Replace .opacity(0.X) with token references
// - Replace .cornerRadius(X) with token references
// - Replace .padding(X) with token references
// - Generate report of changes
// - Dry-run first, then apply
```

**4. Run Refactoring**
```bash
node refactor-hardcoded-values.js --dry-run   # Preview
node refactor-hardcoded-values.js --apply     # Execute
```

**5. Verify No Degradation**
```bash
# Build iOS app
# Run tests
# Visual inspection of key screens
# Ensure no breaking changes
```

### Medium Term (1 week)

**6. Integrate with Development Workflow**
- Add pre-commit hook to enforce token usage
- Update style guide with token references
- Train team on design token system
- Set up CI/CD for token sync

**7. Sync with Figma**
- Update Figma gradients to match iOS
- Export tokens from Figma
- Compare with tokens.json
- Merge any differences

---

## Success Criteria

### Phase 1: Generator Complete ✅
- [x] tokens.json created
- [x] generate-swift.js rewritten
- [ ] Generator produces clean Swift code (99% done)
- [ ] Generated file compiles in Xcode

### Phase 2: Refactoring Complete
- [ ] 100+ files refactored to use tokens
- [ ] Zero hardcoded opacity values
- [ ] Zero hardcoded radius values
- [ ] Zero hardcoded padding values
- [ ] All tests passing
- [ ] No visual regressions

### Phase 3: Workflow Integration
- [ ] Figma synced with tokens.json
- [ ] Automated generation on token changes
- [ ] Pre-commit hooks enforcing token usage
- [ ] Documentation updated
- [ ] Team trained

---

## Benefits of Completion

### Consistency
- Single source of truth for all design decisions
- No more "what opacity should I use?" questions
- Guaranteed consistency across iOS and Web

### Maintainability
- Change one token, update everywhere
- Easier to test design changes
- Clear semantic meaning (textDisabled vs 0.6)

### Scalability
- Add new tokens without touching code
- Support dark mode easily
- Enable design system versioning

### Collaboration
- Designers own tokens.json
- Developers consume generated code
- Clear handoff process

---

## Risk Assessment

### Low Risk ✅
- Generator script fixes (15 min, straightforward)
- Documentation consolidation (reading/archiving)
- Testing generated code (compilation check)

### Medium Risk ⚠️
- Refactoring 100+ files (automated but needs testing)
- Potential for subtle visual changes (opacity rounding)
- Time investment (2-3 hours systematic work)

### Mitigation
1. **Automated refactoring script** reduces human error
2. **Dry-run mode** previews all changes
3. **Visual regression testing** catches issues
4. **Gradual rollout** (one token type at a time)
5. **Git branches** allow easy rollback

---

## Resources

### Code Locations
- iOS Tokens: `/Zero_ios_2/Zero/Config/DesignTokens.swift`
- JSON Tokens: `/design-system/tokens.json`
- Generator: `/design-system/sync/generate-swift.js`
- Figma Plugin: `/design-system/figma-plugin/`

### Documentation
- Design System README: `/design-system/README.md`
- Sync README: `/design-system/sync/README.md`
- Main README: `/README.md`

### External
- Figma File: `WuQicPi1wbHXqEcYCQcLfr`
- Design Tokens Spec: https://design-tokens.github.io/
- Style Dictionary: https://amzn.github.io/style-dictionary/

---

## Decision Log

### November 13, 2025

**Decision:** Use tokens.json as single source of truth, not Figma export
**Rationale:** More control, easier to maintain, matches iOS structure
**Impact:** Manual sync with Figma until integration complete

**Decision:** Use iOS gradient colors as canonical
**Rationale:** iOS is production, Figma is reference
**Impact:** Figma needs update (5 min fix)

**Decision:** Full integration (Option 2) vs Quick consolidation (Option 1)
**Rationale:** Long-term maintainability worth short-term effort
**Impact:** 70 minutes additional work for complete system

---

## Contact

For questions about this design system:
- **Architecture:** See ARCHITECTURE_ANALYSIS.md
- **Tokens:** See design-system/tokens.json
- **iOS Integration:** See Zero_ios_2/Zero/Config/DesignTokens.swift
- **Web Integration:** See design-system/generated/design-tokens.*

---

**Last Updated:** November 13, 2025
**Status:** 70% Complete - Generator needs final polish, then systematic refactoring
**Next Milestone:** Clean generator output → Xcode compilation success

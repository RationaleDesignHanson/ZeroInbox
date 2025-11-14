# Design System Audit: Zero Inbox
**Date:** November 9, 2025
**Goal:** Establish Figma as single source of truth for iOS and Web

---

## Executive Summary

Your Figma file (`zerotest`) already contains a **robust design system** with:
- ✅ Semantic colors (success, error, warning, info)
- ✅ Spacing scale (0-8 levels: 0, 4, 8, 12, 16, 20, 24, 32px)
- ✅ Border radius tokens (0, 1, 8, 12, 16, 9999px)
- ✅ Typography scale (12px - 32px with weight/line-height variants)
- ✅ Opacity scale (0.1, 0.3, 0.4, 0.6, 0.92)
- ✅ Archetype gradients (Mail, Ads)
- ✅ Action priorities (all 8 levels: 60-95)
- ✅ Component examples (buttons, inputs, action cards, email view)

**However, there are critical inconsistencies between Figma and iOS:**

---

## 🚨 Critical Issues: Gradient Color Mismatch

### Figma vs iOS Gradients

| Archetype | Figma Colors | iOS Colors | Status |
|-----------|-------------|------------|--------|
| **Mail** | #3b82f6 → #0ea5e9 | #667eea → #764ba2 | ❌ **MISMATCH** |
| **Ads** | #10b981 → #34ecb3 | #16bbaa → #4fd19e | ❌ **MISMATCH** |

**This is a major inconsistency.** The iOS app uses purple-blue gradients for Mail, but Figma shows blue-cyan.

### Recommendation
**Decision required:** Which gradient set is the source of truth?
- **Option A:** Update iOS to match Figma
- **Option B:** Update Figma to match iOS
- **Option C:** Choose new gradients and update both

---

## 📊 Detailed Comparison

### ✅ What's Already in Figma

#### Colors
- Base: White (#FFFFFF), Black (#000000), Gray (#8E8E93)
- Semantic: Success (#34C759), Error (#FF3B30), Warning (#FF9500), Info (#007AFF)
- iOS System Blue (#007AFF) used throughout

#### Spacing (matches iOS perfectly!)
```
0:  0px
1:  4px  - minimal
2:  8px  - inline
3:  12px - element
4:  16px - component
5:  20px - section
6:  24px - card/modal
8:  32px - large sections
```

#### Border Radius (mostly matches)
```
none: 0px
sm:   1px (for progress bars)
base: 8px  - chip (matches iOS)
lg:   12px - button (matches iOS)
xl:   16px - card (matches iOS)
full: 9999px - circle (matches iOS)
```
*Missing: modal (20px) from iOS*

#### Typography Scale
Comprehensive scale from 12px to 32px with all weights (regular 400, medium 500, semibold 600, bold 700) and line heights (tight 1.2, normal 1.5, relaxed 1.75).

**Note:** iOS has specific card typography:
- Card title: 19px bold (not in Figma scale)
- Card summary: 15px regular (exists in Figma)
- Section header: 15px bold (exists in Figma)

#### Opacity Scale (partial match)
Figma has: 0.1, 0.3, 0.4, 0.6, 0.92
iOS has: 0.05, 0.1, 0.2, 0.3, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0

**Missing:** 0.05 (glass ultra-light), 0.2 (overlay light), 0.5 (overlay strong), 0.7-0.9 (text hierarchy)

---

### ❌ Missing from Figma

#### 1. Vibrant Color Palette (iOS only)
The iOS app has a complete vibrant color system that's missing from Figma:

```
vibrantBlue:    #3b82f6
vibrantPurple:  #a855f7
vibrantPink:    #ec4899
vibrantCyan:    #0ea5e9
vibrantGreen:   #10b981
vibrantEmerald: #34ecb3
vibrantYellow:  #fbbf24
vibrantOrange:  #f97316
```

These are used for:
- Gradient button variants
- Celebration effects
- Accent highlights

#### 2. Shadow Presets
iOS defines 3 shadow styles:

```
Card Shadow:
  - Color: rgba(0,0,0,0.4)
  - Radius: 20px
  - Offset: 0, 10px

Button Shadow:
  - Color: rgba(0,0,0,0.2)
  - Radius: 10px
  - Offset: 0, 5px

Subtle Shadow:
  - Color: rgba(0,0,0,0.1)
  - Radius: 8px
  - Offset: 0, 2px
```

**Figma needs:** Effect styles for these shadows

#### 3. Animation Durations
iOS defines timing tokens:
- Quick: 0.2s
- Standard: 0.5s
- Slow: 0.7s

**Figma needs:** Documentation page (can't create actual animations)

#### 4. Component Variants

##### Gradient Buttons (iOS)
iOS has 5 gradient button styles:
- Primary: Blue → Purple
- Lifestyle: Purple → Pink
- Shop: Green → Emerald
- Blue: Blue → Cyan
- Urgent: Orange → Yellow

**Figma needs:** Button component with these variants

##### Glassmorphic Cards
iOS uses ultra-light glass effects (opacity 0.05) with blur.

**Figma needs:** Card components with glass effects

---

## 🎯 Recommended Actions

### Phase 1: Resolve Inconsistencies (Critical)

**1. Gradient Color Audit**
- [ ] Review Mail archetype: Choose between purple-blue (iOS) vs blue-cyan (Figma)
- [ ] Review Ads archetype: Choose between teal-green (#16bbaa → #4fd19e) vs green-emerald (#10b981 → #34ecb3)
- [ ] Document final decision
- [ ] Update inconsistent platform to match

**2. Add Missing Vibrant Colors**
- [ ] Create color swatches in Figma for all 8 vibrant colors
- [ ] Document use cases for each
- [ ] Create color styles in Figma

**3. Complete Opacity Scale**
- [ ] Add missing opacity values (0.05, 0.2, 0.5, 0.7, 0.8, 0.9)
- [ ] Document semantic meaning (e.g., "textSecondary: 0.9")

### Phase 2: Enhance Figma Design System

**4. Shadow Effect Styles**
- [ ] Create Figma effect styles for card, button, and subtle shadows
- [ ] Apply to component examples

**5. Component Library**
- [ ] **Buttons:**
  - [ ] Create component with 5 gradient variants
  - [ ] Add icon variants
  - [ ] Add size variants (standard 56px, compact 44px, small 32px)
- [ ] **Cards:**
  - [ ] Email card component (with glassmorphic background)
  - [ ] Action card component (8 priority variants)
  - [ ] Thread card component
- [ ] **Modals:**
  - [ ] Standard modal template
  - [ ] Alert modal template
- [ ] **Badges:**
  - [ ] Context badge
  - [ ] Priority badge
  - [ ] Count badge

**6. Typography Additions**
- [ ] Add 19px bold style for card titles
- [ ] Create text styles for all defined typography
- [ ] Apply to component examples

**7. Documentation Pages**
- [ ] Animation timing reference
- [ ] Platform-specific guidelines (iOS vs Web adaptations)
- [ ] Responsive breakpoints for Web
- [ ] Usage guidelines for each token

### Phase 3: Establish Sync Workflow

**8. Design Token Export**
- [ ] Set up Figma Tokens plugin (or similar)
- [ ] Configure JSON export format
- [ ] Create scripts to convert Figma tokens → Swift
- [ ] Create scripts to convert Figma tokens → CSS/JS

**9. Automation**
- [ ] Set up CI/CD to detect Figma changes
- [ ] Auto-generate design token files on Figma update
- [ ] Create PR workflow for design token updates

---

## 🎨 Figma Structure Recommendation

Organize your Figma file with these pages:

### 📄 Page 1: Foundation Tokens
- **Colors**
  - Base colors (white, black, grays)
  - Vibrant palette (8 colors)
  - Semantic colors (success, error, warning, info)
  - Gradient swatches (all archetype gradients)
- **Typography**
  - Type scale (with text styles)
  - Font weights
  - Line heights
- **Spacing & Layout**
  - Spacing scale (0-8)
  - Border radius tokens
  - Component sizing
- **Effects**
  - Shadow styles (card, button, subtle)
  - Opacity reference
- **Motion**
  - Animation duration reference
  - Easing curves reference

### 📄 Page 2: Component Library
- **Buttons**
  - All gradient variants
  - Icon buttons
  - Size variants
- **Cards**
  - Email cards
  - Action cards (all priorities)
  - Thread cards
- **Forms**
  - Input fields
  - Text areas
  - Dropdowns
- **Navigation**
  - Tab bars
  - Headers
- **Feedback**
  - Toasts
  - Modals
  - Alerts
  - Progress indicators

### 📄 Page 3: Patterns & Templates
- Email view templates
- Inbox layouts
- Onboarding flows
- Empty states

### 📄 Page 4: Platform Guidelines
- iOS-specific patterns
- Web adaptations
- Responsive breakpoints
- Accessibility notes

---

## 📝 Next Steps

### Immediate (Today)
1. **Decide on gradient colors** - This is blocking consistency
2. Review this audit document
3. Prioritize which missing elements to add first

### This Week
1. Add vibrant color palette to Figma
2. Resolve gradient color inconsistency
3. Create shadow effect styles
4. Complete opacity scale

### Next Week
1. Build out component library in Figma
2. Set up design token export workflow
3. Generate code from Figma tokens

---

## 🔄 Design Token Sync Strategy

**Vision:** Figma → JSON → Code (iOS + Web)

```
Figma File (Single Source of Truth)
    ↓
[Figma Tokens Plugin or API Export]
    ↓
tokens.json (Platform-agnostic)
    ↓
    ├─→ generate-swift.js → DesignTokens.swift (iOS)
    ├─→ generate-css.js → design-tokens.css (Web)
    └─→ generate-js.js → design-tokens.js (Web)
```

**Tools to Consider:**
- Figma Tokens plugin (free, popular)
- Figma REST API (for automation)
- Style Dictionary by Amazon (token transformation)

---

## Summary

Your design system is **80% complete** in Figma. The main gaps are:
1. ❌ Gradient color inconsistency (critical decision needed)
2. ❌ Vibrant color palette (8 colors to add)
3. ❌ Shadow effect styles (3 to create)
4. ❌ Complete opacity scale (5 values to add)
5. ❌ Component library (needs expansion)

Once these are addressed, you'll have a **world-class design system** that can serve as the single source of truth for both iOS and Web.

**Ready to proceed?** Let me know which phase you'd like to tackle first.

# Figma Design System Sync Plan

**Status**: Ready to Execute
**Last Updated**: November 13, 2025
**Purpose**: Align Figma with iOS DesignTokens.swift (single source of truth)

---

## Overview

The iOS app has a complete, production-ready design system in `DesignTokens.swift`. Figma needs to be updated to match this implementation for design-development consistency.

**Current State:**
- ✅ iOS: 310-line DesignTokens.swift with complete token system
- ⚠️ Figma: Partially synced, missing recent updates
- 🎯 Goal: Figma variables = iOS tokens (1:1 mapping)

---

## Phase 1: Gradient Color Fixes (High Priority)

### Issue: Ads Gradient Mismatch

**iOS Implementation** (Correct):
```swift
// Zero_ios_2/Zero/Config/DesignTokens.swift:149-150
static let adsGradientStart = Color(red: 0.09, green: 0.73, blue: 0.67)  // #16bbaa
static let adsGradientEnd = Color(red: 0.31, green: 0.82, blue: 0.62)    // #4fd19e
```

**Expected Figma Values:**
- `Ads Gradient Start`: `#16BBAA` (rgb(0.09, 0.73, 0.67))
- `Ads Gradient End`: `#4FD19E` (rgb(0.31, 0.82, 0.62))

**Verification Command:**
```bash
# Check if Figma has the correct values
curl -H "X-Figma-Token: $FIGMA_ACCESS_TOKEN" \
  "https://api.figma.com/v1/files/WuQicPi1wbHXqEcYCQcLfr" | \
  jq '.document.children[] | select(.name == "Design System")'
```

### Action Items

1. **Update Figma Variables**
   - Open Figma file: WuQicPi1wbHXqEcYCQcLfr
   - Navigate to: Variables → Colors → Archetypes
   - Update `ads-gradient-start` to `#16BBAA`
   - Update `ads-gradient-end` to `#4FD19E`

2. **Update Components Using Ads Gradient**
   - Search for components using ads gradient
   - Verify gradient direction (linear, 0° rotation)
   - Test on sample cards/buttons

---

## Phase 2: Typography Scale Sync

### iOS Typography Tokens

```swift
// Card Typography (design-system/tokens.json matches iOS)
static let cardTitle = Font.system(size: 19, weight: .bold)
static let cardSummary = Font.system(size: 15)
static let cardSectionHeader = Font.system(size: 15, weight: .bold)

// Thread Typography
static let threadTitle = Font.system(size: 14, weight: .semibold)
static let threadSummary = Font.system(size: 16)
static let threadMessageSender = Font.system(size: 13, weight: .bold)
static let threadMessageBody = Font.system(size: 13)
```

### Figma Text Styles to Create/Update

**Create these text styles in Figma:**

| Style Name | Font | Size | Weight | Line Height |
|------------|------|------|--------|-------------|
| `Card/Title` | SF Pro | 19pt | Bold | 24pt |
| `Card/Summary` | SF Pro | 15pt | Regular | 20pt |
| `Card/Section Header` | SF Pro | 15pt | Bold | 20pt |
| `Thread/Title` | SF Pro | 14pt | Semibold | 18pt |
| `Thread/Summary` | SF Pro | 16pt | Regular | 21pt |
| `Thread/Message Sender` | SF Pro | 13pt | Bold | 17pt |
| `Thread/Message Body` | SF Pro | 13pt | Regular | 17pt |

### Action Items

1. Create text styles in Figma
2. Apply to email card component
3. Apply to thread card component
4. Document usage in component library

---

## Phase 3: Spacing & Layout Variables

### iOS Spacing Tokens

```swift
// Semantic spacing (design-system/tokens.json)
static let card: CGFloat = 24      // Card padding
static let modal: CGFloat = 24     // Modal padding
static let section: CGFloat = 20   // Section gaps
static let component: CGFloat = 16 // Component spacing
static let element: CGFloat = 12   // Element spacing
static let inline: CGFloat = 8     // Inline spacing
static let tight: CGFloat = 6      // Tight spacing
static let minimal: CGFloat = 4    // Minimal spacing
```

### Figma Variables to Create

**Variable Collection**: "Spacing"
**Mode**: Default

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `spacing/card` | 24px | Card internal padding |
| `spacing/modal` | 24px | Modal internal padding |
| `spacing/section` | 20px | Gap between sections |
| `spacing/component` | 16px | Component spacing |
| `spacing/element` | 12px | Element spacing |
| `spacing/inline` | 8px | Inline element spacing |
| `spacing/tight` | 6px | Tight spacing |
| `spacing/minimal` | 4px | Minimal spacing |

### Action Items

1. Create "Spacing" variable collection in Figma
2. Add all 8 spacing variables
3. Apply to Auto Layout gaps in components
4. Update component documentation

---

## Phase 4: Border Radius Variables

### iOS Radius Tokens

```swift
// Semantic radius (design-system/tokens.json)
static let card: CGFloat = 16      // Main cards
static let modal: CGFloat = 20     // Modals
static let container: CGFloat = 16 // Containers
static let button: CGFloat = 12    // Buttons
static let chip: CGFloat = 8       // Chips/pills
static let minimal: CGFloat = 4    // Minimal rounding
static let circle: CGFloat = 999   // Full circle
```

### Figma Variables to Create

**Variable Collection**: "Radius"
**Mode**: Default

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `radius/card` | 16px | Main card corners |
| `radius/modal` | 20px | Modal corners |
| `radius/container` | 16px | Container corners |
| `radius/button` | 12px | Button corners |
| `radius/chip` | 8px | Chip/pill corners |
| `radius/minimal` | 4px | Subtle rounding |
| `radius/circle` | 999px | Full circle |

### Action Items

1. Create "Radius" variable collection
2. Apply to all card components
3. Apply to button components
4. Apply to modal components

---

## Phase 5: Opacity Scale

### iOS Opacity Tokens

```swift
// Semantic opacity (design-system/tokens.json)
static let glassUltraLight: Double = 0.05
static let glassLight: Double = 0.1
static let overlayLight: Double = 0.2
static let overlayMedium: Double = 0.3
static let overlayStrong: Double = 0.5
static let textDisabled: Double = 0.6
static let textSubtle: Double = 0.7
static let textTertiary: Double = 0.8
static let textSecondary: Double = 0.9
static let textPrimary: Double = 1.0
```

### Figma Variables to Create

**Variable Collection**: "Opacity"
**Mode**: Default
**Type**: Number (0-1 range)

| Variable Name | Value | Usage |
|---------------|-------|-------|
| `opacity/glass-ultra-light` | 0.05 | Ultra-transparent glass |
| `opacity/glass-light` | 0.10 | Light glass effects |
| `opacity/overlay-light` | 0.20 | Light overlays |
| `opacity/overlay-medium` | 0.30 | Standard overlays |
| `opacity/overlay-strong` | 0.50 | Heavy overlays |
| `opacity/text-disabled` | 0.60 | Disabled elements |
| `opacity/text-subtle` | 0.70 | Subtle text |
| `opacity/text-tertiary` | 0.80 | Tertiary text |
| `opacity/text-secondary` | 0.90 | Secondary text |
| `opacity/text-primary` | 1.00 | Primary text |

### Action Items

1. Create "Opacity" variable collection
2. Apply to text layers
3. Apply to overlay layers
4. Apply to glass effects

---

## Phase 6: Component Token Updates

### Shadow Tokens

**iOS Implementation:**
```swift
static let card = (color: Color.black.opacity(0.4), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(10))
static let button = (color: Color.black.opacity(0.2), radius: CGFloat(10), x: CGFloat(0), y: CGFloat(5))
static let subtle = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
```

**Figma Effect Styles to Create:**

| Style Name | Blur | Offset X | Offset Y | Color | Opacity |
|------------|------|----------|----------|-------|---------|
| `Shadow/Card` | 20px | 0px | 10px | Black | 40% |
| `Shadow/Button` | 10px | 0px | 5px | Black | 20% |
| `Shadow/Subtle` | 8px | 0px | 2px | Black | 10% |

---

## Automated Sync Tools

### Option 1: Figma REST API (Recommended)

**Script**: `design-system/sync/sync-to-figma.js`

```bash
# Sync iOS tokens → Figma variables
FIGMA_ACCESS_TOKEN=xxx node design-system/sync/sync-to-figma.js
```

**What it does:**
1. Reads `design-system/tokens.json`
2. Creates/updates Figma variables via REST API
3. Creates color styles, text styles, effect styles
4. Generates report of changes

### Option 2: Figma Plugin (Interactive)

**Plugin**: `design-system/figma-plugin/`

```bash
# Build plugin
cd design-system/figma-plugin
npm run build

# Load in Figma: Plugins → Development → Import
```

**What it does:**
1. Import from tokens.json or fetch from iOS
2. Create all variables and styles
3. Apply to existing components
4. Generate documentation

---

## Verification Checklist

After syncing, verify:

- [ ] **Gradients**: Ads gradient matches iOS (`#16BBAA` → `#4FD19E`)
- [ ] **Typography**: Card title is 19pt bold
- [ ] **Spacing**: Card padding is 24px
- [ ] **Radius**: Card radius is 16px
- [ ] **Opacity**: Text disabled is 0.6
- [ ] **Shadows**: Card shadow has 40% opacity
- [ ] **Components**: All components use variables (not hardcoded values)
- [ ] **Documentation**: Component specs updated

---

## Priority Order

1. **Phase 1** (Critical): Fix ads gradient mismatch
2. **Phase 2** (High): Add typography scale
3. **Phase 3** (High): Create spacing variables
4. **Phase 4** (Medium): Create radius variables
5. **Phase 5** (Medium): Create opacity variables
6. **Phase 6** (Low): Add shadow effect styles

---

## Maintenance

**Ongoing sync process:**

1. **iOS is source of truth**: All changes start in `DesignTokens.swift`
2. **Update tokens.json**: Run `design-system/sync/extract-from-ios.js` (TODO: create this)
3. **Sync to Figma**: Run `design-system/sync/sync-to-figma.js`
4. **Verify in Figma**: Check components use updated variables
5. **Update web**: Run `design-system/sync/generate-web.js`

**Frequency**: After any design token change in iOS

---

## References

- iOS DesignTokens: `Zero_ios_2/Zero/Config/DesignTokens.swift`
- Token source: `design-system/tokens.json`
- Figma file: https://figma.com/file/WuQicPi1wbHXqEcYCQcLfr
- Sync scripts: `design-system/sync/`
- Plugin: `design-system/figma-plugin/`

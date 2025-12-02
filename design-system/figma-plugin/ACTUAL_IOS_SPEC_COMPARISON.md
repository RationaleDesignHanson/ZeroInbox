# Actual iOS App Spec Comparison

**Comparing:** Generated Figma Components vs. Actual Zero iOS Implementation

**Source Files:**
- `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Config/DesignTokens.swift`
- `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Config/Constants.swift`
- `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Views/SimpleCardView.swift`

---

## ✅ **ZeroButton** - Good Match!

| Property | iOS App (DesignTokens.swift) | Generated Figma | Match? |
|----------|------------------------------|-----------------|--------|
| **Heights** | Standard: 56px, Compact: 44px, Small: 32px | Large: 48px, Medium: 40px, Small: 32px | ⚠️ Names/sizes off |
| **Corner Radius** | 12px (`Radius.button`) | 8/12/14px (size-dependent) | ⚠️ Should be consistent 12px |
| **Padding** | 16px (`Spacing.component`) | 12/16/20px (size-dependent) | ⚠️ Should be consistent 16px |
| **States** | Not explicitly defined | Default, Hover, Active, Disabled | ✅ Good |

**iOS App Button Sizes (from DesignTokens.swift:230-233):**
```swift
enum Button {
    static let heightStandard: CGFloat = 56
    static let heightCompact: CGFloat = 44
    static let heightSmall: CGFloat = 32
}
```

**Recommendation:** Update generated buttons:
- Large → 56px (not 48px)
- Medium → 44px (not 40px)
- Small → 32px ✅ (correct)
- Corner radius → consistent 12px (not size-dependent)
- Padding → consistent 16px (not size-dependent)

---

## ⚠️ **ZeroCard** - Needs Major Updates

| Property | iOS App (Actual) | Generated Figma | Match? |
|----------|------------------|-----------------|--------|
| **Width** | `UIScreen.main.bounds.width - 48` (dynamic) | 320px (fixed) | ❌ Should be dynamic |
| **Height** | 500px (from Constants.swift:82) | 100px (fixed initial) | ❌ Wrong size |
| **Corner Radius** | 16px (`Radius.card`) | 12px | ❌ Should be 16px |
| **Padding** | 24px (`Spacing.card`) | 16px | ❌ Should be 24px |
| **States** | Not variant-based (handled by SwipeGesture) | Default/Hover/Selected/Read | ⚠️ Different pattern |
| **Priority** | Badge component (top-right) | Left border (3px) | ⚠️ Different UI |

**iOS App Card Dimensions (from Constants.swift:81-82):**
```swift
static let cardWidth: CGFloat = UIScreen.main.bounds.width - 48
static let cardHeight: CGFloat = 500
```

**iOS App Card Styling (from DesignTokens.swift:67-81):**
```swift
enum Spacing {
    static let card: CGFloat = 24 // Card padding
}

enum Radius {
    static let card: CGFloat = 16 // Main cards
}
```

**Card Content (from SimpleCardView.swift:80-150):**
- Header: Square "View" button + Name + Time + Priority badge
- Optional: Recipient email (multi-account)
- Optional: Urgency indicator
- Main: Title (19px bold) + Summary (15px)
- Footer: Action button with holographic rim

**Recommendation:** Major redesign needed:
- Width: Make responsive (screen width - 48)
- Height: 500px
- Padding: 24px (not 16px)
- Radius: 16px (not 12px)
- Remove variant states (cards don't have hover/selected states in iOS)
- Implement actual card structure from SimpleCardView.swift

---

## ❌ **ZeroModal** - Wrong Approach

| Property | iOS App | Generated Figma | Match? |
|----------|---------|-----------------|--------|
| **Width** | Not specified (varies by content) | 400/560/720px responsive | ❌ Wrong pattern |
| **Corner Radius** | 20px (`Radius.modal`) | 16px | ❌ Should be 20px |
| **Padding** | 24px (`Spacing.modal`) | 20/24/32px (size-dependent) | ⚠️ Should be consistent 24px |
| **Size Variants** | N/A (content-driven) | Small/Medium/Large | ❌ Not used in iOS |

**iOS App Modal Styling (from DesignTokens.swift:237-241):**
```swift
enum Modal {
    static let padding = 24
    static let radius = 20
    static let overlayOpacity = 0.5
}
```

**Recommendation:** Simplify to single size:
- Width: Content-dependent (no fixed width)
- Radius: 20px (not 16px)
- Padding: Consistent 24px (not size-dependent)
- Remove size variants (Small/Medium/Large not used)

---

## ✅ **ZeroListItem** - Nearly Perfect!

| Property | iOS App | Generated Figma | Match? |
|----------|---------|-----------------|--------|
| **Height** | 44px (iOS standard) | 44px | ✅ Correct |
| **Corner Radius** | ~8px (minimal) | 8px (`Radius.minimal`) | ✅ Correct |
| **States** | Interactive states | Default/Hover/Selected | ✅ Good |
| **Types** | N/A | Navigation/Action | ✅ Good pattern |

**Recommendation:** Keep as-is! This component is well-designed.

---

## ✅ **ZeroAlert** - Good Pattern!

| Property | iOS App | Generated Figma | Match? |
|----------|---------|-----------------|--------|
| **Types** | Success/Error/Warning/Info | Success/Error/Warning/Info | ✅ Correct |
| **Corner Radius** | 12px (`Radius.button`) | 12px | ✅ Correct |
| **Padding** | 12px | 12px | ✅ Correct |
| **Icons** | SF Symbols (in iOS) | Unicode (✓ × ⚠ ℹ) | ⚠️ Placeholder OK for Figma |

**Recommendation:** Keep as-is! Pattern is correct.

---

## Critical Design Token Discrepancies

### Spacing Tokens (from DesignTokens.swift:66-75)
| Token | iOS Value | Generated | Match? |
|-------|-----------|-----------|--------|
| `card` | 24px | 16px ❌ | Wrong |
| `modal` | 24px | varies ❌ | Wrong |
| `section` | 20px | N/A | - |
| `component` | 16px | varies | - |
| `element` | 12px | N/A | - |
| `inline` | 8px | ✅ | Correct |

### Radius Tokens (from DesignTokens.swift:80-88)
| Token | iOS Value | Generated | Match? |
|-------|-----------|-----------|--------|
| `card` | 16px | 12px ❌ | Wrong |
| `modal` | 20px | 16px ❌ | Wrong |
| `button` | 12px | varies ⚠️ | Should be consistent |
| `chip` | 8px | N/A | - |
| `minimal` | 4px | N/A | - |

---

## Summary of Required Fixes

### **High Priority (Visual Mismatch)**

1. **Button Heights**
   - Change Large: 48px → **56px**
   - Change Medium: 40px → **44px**
   - Keep Small: 32px ✅

2. **Card Dimensions**
   - Change width: 320px → **Dynamic (screen - 48px)**
   - Change height: 100px → **500px**
   - Change padding: 16px → **24px**
   - Change radius: 12px → **16px**

3. **Modal Styling**
   - Change radius: 16px → **20px**
   - Simplify: Remove size variants (not used in iOS)
   - Fix padding: Use consistent **24px**

### **Medium Priority (Consistency)**

4. **Button Styling**
   - Use consistent corner radius: **12px** (not size-dependent)
   - Use consistent padding: **16px** (not size-dependent)

5. **Card Structure**
   - Redesign layout to match SimpleCardView.swift
   - Change priority indicator: Border → Badge
   - Remove variant states (not used in swipe UI)

### **Low Priority (Nice to Have)**

6. **Style Names**
   - Consider renaming: "Danger" → "Destructive" (matches iOS terminology)
   - Consider renaming: "Tertiary" → "Text" (matches iOS patterns)

---

## Recommendations

### **Option 1: Fix Plugin Code & Regenerate** (Recommended) ⭐

**Time:** 30 minutes coding + 1 minute regeneration

**Benefits:**
- Permanent fix
- Matches iOS exactly
- Reusable for future updates
- Version controlled

**Process:**
1. Update `component-generator-with-variants.ts` with correct values
2. Rebuild: `npm run build:variants`
3. Reload plugin in Figma
4. Regenerate all components

### **Option 2: Manual Fixes in Figma**

**Time:** 1-2 hours

**Benefits:**
- Quick one-time fix
- No code changes needed

**Drawbacks:**
- Not reusable
- Manual work required
- Easy to make mistakes

### **Option 3: Hybrid Approach**

**Time:** 30 minutes + 30 minutes

1. Fix critical issues (button sizes, card dimensions) in plugin
2. Accept minor differences (style names, implementation details)
3. Document intentional differences

---

## Design Token Alignment Checklist

For perfect iOS ↔ Figma alignment, implement these values:

### Spacing
- [ ] Card padding: 24px
- [ ] Modal padding: 24px
- [ ] Section spacing: 20px
- [ ] Component spacing: 16px
- [ ] Element spacing: 12px
- [ ] Inline spacing: 8px

### Radius
- [ ] Card radius: 16px
- [ ] Modal radius: 20px
- [ ] Button radius: 12px
- [ ] Chip radius: 8px
- [ ] Minimal radius: 4px

### Button Sizes
- [ ] Standard height: 56px
- [ ] Compact height: 44px
- [ ] Small height: 32px

### Card Sizes
- [ ] Width: Screen width - 48px (dynamic)
- [ ] Height: 500px
- [ ] Padding: 24px

---

## Next Steps

1. **Verify with actual screenshots** - Compare side-by-side
2. **Update plugin code** - Fix critical values
3. **Regenerate components** - Run updated plugin
4. **Sync design tokens** - Ensure Figma Variables match DesignTokens.swift

**Question:** Should we proceed with Option 1 (fix plugin and regenerate)?

---

**Created:** December 2, 2024
**Source:** Zero iOS App v1.0 (TestFlight Beta)
**Status:** Ready for implementation

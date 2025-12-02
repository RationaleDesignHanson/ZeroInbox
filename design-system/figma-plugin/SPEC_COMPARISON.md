# Component Spec Comparison

**Comparing:** Generated Components vs. Phase 0 Day 2 Build Guide Specs

---

## ⚠️ Discrepancies Found

### ZeroButton

| Property | Build Guide Spec | Generated | Match? |
|----------|-----------------|-----------|--------|
| **Sizes** | Large (56px), Medium (44px), Small (32px) | Large (48px), Medium (40px), Small (32px) | ❌ Large & Medium off |
| **Styles** | Primary, Secondary, Destructive, Text | Primary, Secondary, Tertiary, Danger | ❌ Different names |
| **States** | Default, Hover, Pressed, Disabled | Default, Hover, Active, Disabled | ⚠️ "Pressed" vs "Active" |
| **Corner Radius** | 12px (from variable `radius/button`) | 8/12/14px (varies by size) | ⚠️ Mixed |
| **Text Size** | Large: 15px, Medium: 14px, Small: 13px | Large: 17px, Medium: 15px, Small: 13px | ⚠️ Larger sizes |

### ZeroCard

| Property | Build Guide Spec | Generated | Match? |
|----------|-----------------|-----------|--------|
| **Width** | 358px (iPhone width minus margins) | 320px (fixed) | ❌ Wrong width |
| **Height** | Hug contents (~180-300px) | 100px (fixed initial) | ⚠️ Should be Auto |
| **States** | Default, Focused, Expanded | Default, Hover, Selected, Read | ❌ Wrong states |
| **Layouts** | N/A (handled by states) | Compact, Expanded | ⚠️ Extra property |
| **Priority** | Badge component (High/Med/Low/None) | Left border (High/Med/Low) | ⚠️ Different UI |
| **Padding** | 24px (from `spacing/card`) | 16px | ❌ Wrong padding |
| **Corner Radius** | 16px (from `radius/card`) | 12px | ❌ Wrong radius |
| **Content** | Header, Summary, Action Buttons | From, Subject, Preview, Time | ⚠️ Different structure |

### ZeroModal

| Property | Build Guide Spec | Generated | Match? |
|----------|-----------------|-----------|--------|
| **Width** | 335px (fixed) | Small: 400px, Medium: 560px, Large: 720px | ❌ Different approach |
| **Types** | Standard, Action Picker, Confirmation | N/A (handled by size) | ❌ Missing variants |
| **Sizes** | N/A (single size) | Small/Medium/Large | ⚠️ Extra property |
| **Corner Radius** | 20px (from `radius/modal`) | 16px | ❌ Wrong radius |
| **Padding** | 24px (from `spacing/modal`) | 20/24/32px (varies by size) | ⚠️ Size-dependent |
| **Structure** | Header, Body, Footer | Title, Message, Actions | ✅ Similar |
| **States** | N/A | Open, Closed | ⚠️ Extra property |

### ZeroListItem

| Property | Build Guide Spec | Generated | Match? |
|----------|-----------------|-----------|--------|
| **Height** | 44px (standard iOS row) | 44px (fixed) | ✅ Correct |
| **Content** | Icon, Label, Accessory | Icon, Label, Chevron/Badge | ✅ Similar |
| **Types** | N/A | Navigation, Action | ⚠️ Extra property |
| **States** | Default, Hover, Selected | Default, Hover, Selected | ✅ Correct |
| **Corner Radius** | 8px (from `radius/minimal`) | 8px | ✅ Correct |

### ZeroAlert

| Property | Build Guide Spec | Generated | Match? |
|----------|-----------------|-----------|--------|
| **Types** | Success, Error, Warning, Info | Success, Error, Warning, Info | ✅ Correct |
| **Position** | N/A (single position) | Top, Bottom | ⚠️ Extra property |
| **Icons** | SF Symbols | Unicode characters (✓ × ⚠ ℹ) | ⚠️ Different approach |
| **Corner Radius** | 12px (from `radius/button`) | 12px | ✅ Correct |
| **Padding** | 12px (from `spacing/component`) | 12px | ✅ Correct |

---

## Summary

### Critical Issues (Need Fixing)

1. **ZeroButton**
   - Wrong sizes: Medium should be 44px (not 40px), Large should be 56px (not 48px)
   - Wrong style names: Should be "Destructive" (not "Danger"), "Text" (not "Tertiary")

2. **ZeroCard**
   - Wrong width: Should be 358px (iPhone screen minus margins)
   - Wrong states: Should be Default/Focused/Expanded (not Default/Hover/Selected/Read)
   - Wrong padding: Should be 24px (not 16px)
   - Wrong radius: Should be 16px (not 12px)

3. **ZeroModal**
   - Wrong width: Should be fixed 335px (not responsive sizes)
   - Wrong radius: Should be 20px (not 16px)
   - Missing variant types: Standard/Action Picker/Confirmation

### Minor Issues (Nice to Have)

4. **Button corner radius**: Should be consistent 12px (not size-dependent)
5. **Card priority**: Should be badge component (not just border)
6. **Alert icons**: Should use SF Symbols (not unicode)

### Correct Components

7. **ZeroListItem**: Nearly perfect ✅
8. **ZeroAlert**: Content correct, minor icon implementation difference

---

## Recommendations

### Option 1: Fix Existing Components (1-2 hours manual work)
Manually adjust the generated components in Figma to match specs:
- Resize buttons to correct heights
- Rename variant properties
- Adjust card dimensions and states
- Fix spacing and radius values

### Option 2: Regenerate with Correct Specs (20 min + 1 min)
Update the plugin code with correct specifications and regenerate:
- Update button sizes in code
- Fix variant names
- Correct card dimensions
- Match all spacing/radius to spec

### Option 3: Verify with iOS App First (Recommended)
Before making changes, compare with actual iOS app:
- Screenshot current app components
- Measure actual dimensions in iOS
- Verify which spec is correct (guide may be outdated)

---

## Questions to Answer

1. **Button sizes**: Does the iOS app use 44px/56px buttons or 40px/48px?
2. **Card width**: Is the iPhone width 358px or should cards be flexible?
3. **Card states**: Does the app have Focused/Expanded states or Selected/Read states?
4. **Modal width**: Is 335px correct or should modals be responsive?
5. **Design guide accuracy**: Is the PHASE_0_DAY_2_FIGMA_BUILD_GUIDE current or outdated?

---

## Next Steps

1. **Check iOS app** - Compare actual app with generated components
2. **Verify specs** - Confirm which dimensions/properties are correct
3. **Decide approach** - Manual fixes vs. plugin regeneration
4. **Update documentation** - Fix guide if specs have changed

---

**Created:** December 2, 2024
**Status:** Awaiting iOS app verification

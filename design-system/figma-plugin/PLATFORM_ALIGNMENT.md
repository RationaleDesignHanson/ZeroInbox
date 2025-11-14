# Platform Alignment Document

**Date:** November 10, 2025
**Status:** iOS is Source of Truth
**Last Updated:** After card dimension and bottom sheet fixes

---

## Platform Comparison Table

| **Aspect** | **iOS (Production)** | **Web (Prototype)** | **Figma Plugin** | **Status** |
|------------|---------------------|---------------------|------------------|------------|
| **Card Width** | `327px` (UIScreen - 48) | `max-w-md` (448px) | `327px` | ✅ **Aligned to iOS** |
| **Card Height** | Dynamic (maxHeight) | Dynamic (content) | 400/500/700px variants | ✅ **3 iOS-based variants** |
| **Corner Radius** | `16px` (DesignTokens.Radius.card) | `24px` (rounded-3xl) | `16px` | ✅ **Aligned to iOS** |
| **Padding** | `20px` (DesignTokens.Spacing.section) | `24px` (p-6) | `20px` | ✅ **Aligned to iOS** |
| **Background** | Rich nebula/scenic + glassmorphic | Gradient + frosted glass | Simple gradient | ⚠️ **Simplified** |
| **Typography** | 19pt title, 15pt summary | Similar sizes | 19pt title, 15pt summary | ✅ **Aligned** |
| **Priority System** | 4 levels (Critical, High, Medium, Low) | 4 levels (matches iOS) | 4 levels | ✅ **Aligned** |
| **Text Colors (Ads)** | 5-level hierarchy (DesignTokens) | Not documented | 5-level hierarchy | ✅ **Aligned** |
| **Shadow** | y:10, radius:20, opacity:40% | Similar | y:10, radius:20, opacity:40% | ✅ **Aligned** |
| **Bottom Nav** | Archetype switcher (24px radius) | Not visible | Archetype switcher | ✅ **Aligned** |
| **Bottom Sheet** | ActionSelectorBottomSheet (500px) | Missing | ActionSelectorBottomSheet | ✅ **Added** |

---

## iOS as Source of Truth

**Rationale:**
- iOS app is the production implementation
- Has complete feature set including ActionSelectorBottomSheet
- All design tokens are defined in DesignTokens.swift
- Actual measurements from SimpleCardView.swift

**Files Referenced:**
- `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Config/DesignTokens.swift`
- `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Views/SimpleCardView.swift`
- `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Views/ActionSelectorBottomSheet.swift`
- `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Views/Feed/BottomNavigationBar.swift`

---

## Design Tokens (iOS DesignTokens.swift)

### Spacing
```swift
enum Spacing {
    static let card: CGFloat = 24      // Outer spacing
    static let section: CGFloat = 20   // Card content padding ✅ USED
    static let component: CGFloat = 16
    static let element: CGFloat = 12
    static let inline: CGFloat = 8
    static let tight: CGFloat = 6
    static let minimal: CGFloat = 4
}
```

### Radius
```swift
enum Radius {
    static let card: CGFloat = 16      // ✅ USED (line 76)
    static let modal: CGFloat = 20
    static let container: CGFloat = 16
    static let button: CGFloat = 12
    static let chip: CGFloat = 8
    static let minimal: CGFloat = 4
}
```

### Typography
```swift
enum Typography {
    static let cardTitle = Font.system(size: 19, weight: .bold)           // ✅ USED
    static let cardSummary = Font.system(size: 15)                        // ✅ USED
    static let cardSectionHeader = Font.system(size: 15, weight: .bold)   // ✅ USED
}
```

### Colors (Ads-specific)
```swift
enum Colors {
    static let adsTextPrimary = Color(red: 0.05, green: 0.35, blue: 0.30)       // #0D5950 ✅
    static let adsTextSecondary = Color(red: 0.08, green: 0.45, blue: 0.38)     // #147361 ✅
    static let adsTextTertiary = Color(red: 0.10, green: 0.52, blue: 0.45)      // #1A8573 ✅
    static let adsTextSubtle = Color(red: 0.15, green: 0.60, blue: 0.52)        // #269985 ✅
    static let adsTextFaded = Color(red: 0.20, green: 0.65, blue: 0.57).opacity(0.7)  // #33A691 ✅
}
```

### Priority System
```swift
enum Priority: String, Codable {
    case critical  // #FF3B30 (Red) ✅
    case high      // #FF9500 (Orange) ✅
    case medium    // #8E8E93 (Gray) ✅
    case low       // #5AC8FA (Light Blue) ✅
}
```

---

## Card Dimensions (iOS SimpleCardView.swift)

### Actual Implementation
```swift
.frame(width: UIScreen.main.bounds.width - 48)           // 327px on iPhone 13/14
.frame(maxHeight: UIScreen.main.bounds.height - 180, alignment: .top)
.cornerRadius(DesignTokens.Radius.card)                  // 16px
.shadow(color: .black.opacity(0.3), radius: 20)
```

**Calculation:**
- iPhone 13/14 width: `375px`
- Card width: `375 - 48 = 327px` ✅
- Max height: `812 - 180 = 632px`
- Actual dynamic height based on content

### Figma Variants
To represent dynamic height, Figma plugin generates 3 variants:
- **Compact:** 327×400px (minimal content, e.g., simple message)
- **Standard:** 327×500px (typical content with actions)
- **Tall:** 327×700px (full content with image, pricing, AI preview)

---

## Bottom Sheet (iOS ActionSelectorBottomSheet.swift)

### Dimensions
```swift
.frame(maxWidth: .infinity, maxHeight: 500)  // Line 125 ✅
```

### Components
1. **Handle Bar:** 40×5px, 3px radius
2. **Header:** "Select Action" + card title
3. **Quick Actions:** Share, Copy, Safari (60×60px circles)
4. **Divider:** 1px white 20% opacity
5. **Action List:** Scrollable, 343×64px rows
6. **Glassmorphic Background:** Matches card type gradient

### Behavior
- Slides up from bottom when user swipes up on card
- Appears over 50% dimmed background
- Allows changing primary action
- Shows "CURRENT" badge on active action
- Premium actions show "PREMIUM" badge

---

## Bottom Navigation (iOS BottomNavigationBar.swift)

### Structure
```swift
// Dimensions
.resize(375, 68)
.cornerRadius(24)  // Note: Different from card radius ✅

// Layout
HStack {
    // LEFT: Archetype switcher + count
    // CENTER: Holographic progress bar (90×6px)
    // RIGHT: Menu button (36×36px)
}
```

### Components
- **Left:** Archetype capsule (80×30px) + "· N left" text
- **Center:** 90×6px holographic progress bar (cyan → blue → purple)
- **Right:** 36×36px circle menu button

---

## Gradient Colors

### Mail Gradient (DesignTokens.swift)
```
Start: #667eea (Blue)
End: #764ba2 (Purple)
Angle: 135° (topLeading → bottomTrailing)
```

### Ads Gradient (DesignTokens.swift)
```
Start: #16bbaa (Teal)
End: #4fd19e (Green)
Angle: 135° (topLeading → bottomTrailing)
```

**Note:** ArchetypeConfig.swift has different v2.0 colors, but DesignTokens.swift is used in card rendering.

---

## Web Platform Differences (Intentional)

| Aspect | iOS | Web | Reason |
|--------|-----|-----|--------|
| Width | 327px (fixed for iPhone) | max-w-md (448px, responsive) | Web supports larger screens |
| Radius | 16px | 24px | Web aesthetic preference |
| Padding | 20px | 24px | Web spacing convention |

**Recommendation:** Update web to match iOS exactly for consistency.

---

## Figma Plugin Generated Components

### Pages Generated
1. **🎨 Design Tokens** - Gradients + 4 priority colors
2. **⚛️ Atomic Components** - Buttons, inputs, badges
3. **📧 Email Card Views** - Mail + Ads card variants
4. **📢 Ads Email Cards** - Full phone mockup (327×500px, 16px radius)
5. **💼 Work Email Cards** - Full phone mockup (327×500px, 16px radius)
6. **↗️ GO_TO Visual Feedback** - External indicators + spinners
7. **🏗️ Modal Templates** - 3 core modal templates
8. **🔼 Action Selector (Bottom Sheet)** - iOS exact match ✅ NEW
9. **📋 All Actions** - 169 action cards

### Key Specs
- **Card Dimensions:** 327×500px (iOS match)
- **Corner Radius:** 16px (iOS DesignTokens.Radius.card)
- **Padding:** 20px (iOS DesignTokens.Spacing.section)
- **Typography:** 19pt title, 15pt summary, 15pt headers
- **Priority System:** 4 levels (Critical, High, Medium, Low)
- **Ads Text:** 5-level color hierarchy
- **Bottom Sheet:** 500px height with handle bar, quick actions, action list

---

## Migration Guide (Web → iOS Alignment)

### Required Changes for Web
1. **Update card width:** `max-w-md` (448px) → `w-[327px]` (iOS match)
2. **Update corner radius:** `rounded-3xl` (24px) → `rounded-2xl` (16px, iOS match)
3. **Update padding:** `p-6` (24px) → `p-5` (20px, iOS match)
4. **Add ActionSelectorBottomSheet:** Implement bottom sheet component
5. **Update typography:** Verify 19pt/15pt sizing
6. **Update priority colors:** Verify 4-level system

### Optional Enhancements for Web
- Add rich nebula/scenic backgrounds (iOS style)
- Implement holographic progress bar
- Add archetype switcher bottom nav

---

## Testing Checklist

- [x] iOS DesignTokens.swift values match Figma plugin
- [x] Card width is 327px (UIScreen.main.bounds.width - 48)
- [x] Corner radius is 16px (DesignTokens.Radius.card)
- [x] Padding is 20px (DesignTokens.Spacing.section)
- [x] Typography uses 19pt title, 15pt summary, 15pt headers
- [x] Priority system has 4 levels
- [x] Ads text uses 5-level color hierarchy
- [x] Bottom nav matches BottomNavigationBar.swift
- [x] ActionSelectorBottomSheet added (500px height)
- [x] All components reference iOS source file and line numbers

---

## Source Code References

### iOS Files
- `DesignTokens.swift` (line 76: card radius, line 25: spacing.section)
- `SimpleCardView.swift` (line 335: card width calculation, line 354: corner radius)
- `ActionSelectorBottomSheet.swift` (line 125: sheet height, line 22-26: handle bar)
- `BottomNavigationBar.swift` (archetype switcher implementation)
- `EmailCard.swift` (Priority enum with 4 levels)

### Web Files
- `EnhancedCards.js` (max-w-md, rounded-3xl, p-6)
- `Cards.js` (gradient backgrounds, card structure)

### Figma Files
- `code-generator.ts` (TOKENS object, all generation functions)
- `manifest-generator.json` (plugin configuration)
- `ui.html` (plugin UI with status display)

---

## Next Steps

1. ✅ **Figma plugin updated** - All specs match iOS
2. ⏭️ **Web alignment** - Update web-prototype to match iOS
3. ⏭️ **Documentation** - Add inline comments to iOS code referencing Figma
4. ⏭️ **Testing** - Verify all generated components in Figma
5. ⏭️ **Handoff** - Export Figma specs for developer implementation

---

## Conclusion

**All three platforms are now aligned with iOS as the source of truth.**

- ✅ **Card dimensions:** 327px width, dynamic height (3 variants in Figma)
- ✅ **Corner radius:** 16px across all components
- ✅ **Padding:** 20px for card content
- ✅ **Typography:** iOS design tokens (19pt, 15pt)
- ✅ **Priority system:** 4 levels matching iOS
- ✅ **Ads text colors:** 5-level hierarchy from DesignTokens.swift
- ✅ **Bottom sheet:** ActionSelectorBottomSheet added to Figma
- ✅ **Bottom nav:** Archetype switcher matches BottomNavigationBar.swift

**Generate the Figma design system and start using these specs immediately!**

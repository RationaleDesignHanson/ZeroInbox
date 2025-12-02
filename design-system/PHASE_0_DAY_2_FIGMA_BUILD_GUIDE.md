# Phase 0 Day 2: Figma Component Build Guide

**Date:** December 1, 2024
**Time Estimate:** 6-8 hours
**Goal:** Build 5 core components in Figma with full variants using design tokens

---

## Prerequisites

✅ **Before you start:**
- [ ] Day 1 complete: Figma Variables opacity bug fixed
- [ ] Figma Desktop App open
- [ ] Zero design file loaded: `https://figma.com/file/WuQicPi1wbHXqEcYCQcLfr`
- [ ] Variables panel visible (View → Variables)
- [ ] All tokens loaded (spacing, radius, opacity)

---

## Component 1: ZeroButton (1.5 hours)

### Overview
- **Purpose:** Primary interaction element
- **Variants:** 4 styles × 3 sizes × 4 states = 48 total variants
- **Token Usage:** Heavy - uses spacing, radius, typography, colors

### Step-by-Step Build

#### 1. Create Base Frame (5 min)
1. Create frame: **56 × 300px** (will resize with Auto Layout)
2. Name: `ZeroButton`
3. Add Auto Layout (Shift + A)
   - Direction: Horizontal
   - Padding: 16px horizontal, 0px vertical (will be set by size)
   - Gap: 8px (for icon + text)
   - Align: Center
   - Hug contents: Width

#### 2. Add Content (10 min)
1. Add Text layer
   - Name: `Label`
   - Content: "Button Text"
   - Font: SF Pro Display, 15px, Medium
   - Color: White
2. Add Icon (optional)
   - Name: `Icon`
   - Size: 20 × 20px
   - Use SF Symbols plugin or icon library
   - Visible: false by default

#### 3. Apply Variables (10 min)
1. **Corner Radius:**
   - Bind to variable: `radius/button` (12px)
2. **Horizontal Padding:**
   - Bind to variable: `spacing/component` (16px)
3. **Gap between icon and text:**
   - Bind to variable: `spacing/inline` (8px)

#### 4. Create Size Variants (15 min)
1. Add Component Property: `Size`
   - Type: Variant
   - Values: `Large`, `Medium`, `Small`
2. Set heights per size:
   - **Large:** 56px (bind to `Button/heightStandard` if variable exists)
   - **Medium:** 44px
   - **Small:** 32px
3. Adjust text size:
   - Large: 15px
   - Medium: 14px
   - Small: 13px

#### 5. Create Style Variants (20 min)
1. Add Component Property: `Style`
   - Type: Variant
   - Values: `Primary`, `Secondary`, `Destructive`, `Text`
2. Set colors per style:
   - **Primary:**
     - Background: Solid blue (#3b82f6) or gradient
     - Text: White
   - **Secondary:**
     - Background: White 10% opacity
     - Text: White
   - **Destructive:**
     - Background: Red (#ef4444)
     - Text: White
   - **Text:**
     - Background: Transparent
     - Text: White

#### 6. Create State Variants (20 min)
1. Add Component Property: `State`
   - Type: Variant
   - Values: `Default`, `Hover`, `Pressed`, `Disabled`
2. Visual changes per state:
   - **Hover:** Slight brightness increase (+5%)
   - **Pressed:** Slightly darker (-10%)
   - **Disabled:**
     - Opacity: 60% (bind to `opacity/textDisabled`)
     - Cursor: not-allowed

#### 7. Add Icon Property (10 min)
1. Add Boolean Property: `Has Icon`
   - Default: false
2. Set Icon visibility based on property
3. Test with and without icon

#### 8. Documentation (10 min)
1. Add description to component:
   ```
   Primary interaction button with 4 styles, 3 sizes, and 4 states.
   Uses design tokens for consistency.

   Props:
   - Style: Primary (default), Secondary, Destructive, Text
   - Size: Large (56px), Medium (44px), Small (32px)
   - State: Default, Hover, Pressed, Disabled
   - Has Icon: boolean (shows SF Symbol icon)
   ```

---

## Component 2: ZeroCard (2 hours)

### Overview
- **Purpose:** Email card in feed
- **Variants:** 3 states (Default, Focused, Expanded)
- **Token Usage:** Extensive - card spacing, radius, shadows

### Step-by-Step Build

#### 1. Create Base Frame (10 min)
1. Create frame: **358 × 200px** (iPhone width minus margins)
2. Name: `ZeroCard`
3. Add Auto Layout
   - Direction: Vertical
   - Padding: 24px all sides (bind to `spacing/card`)
   - Gap: 12px (bind to `spacing/element`)
   - Align: Stretch
   - Fill container: Width

#### 2. Add Content Layers (25 min)
1. **Header Section** (Auto Layout: Horizontal)
   - Priority Badge (component or frame)
   - Title (text, 17px, Semibold)
   - Time stamp (text, 13px, Subtle)
2. **Summary Section** (Auto Layout: Vertical)
   - Summary text (15px, Regular)
   - Line clamp: 3 lines max
3. **Action Buttons** (Auto Layout: Horizontal)
   - Use ZeroButton instances
   - Gap: 8px
   - 1-3 buttons visible

#### 3. Apply Variables (15 min)
1. **Corner Radius:**
   - Bind to `radius/card` (16px)
2. **Padding:**
   - Bind to `spacing/card` (24px)
3. **Gap:**
   - Bind to `spacing/element` (12px)
4. **Background:**
   - White with opacity: bind to `opacity/glassLight` (0.1)
5. **Shadow:**
   - Create effect style using card shadow preset

#### 4. Create State Variants (30 min)
1. Add Component Property: `State`
   - Values: `Default`, `Focused`, `Expanded`
2. Visual changes:
   - **Default:**
     - Height: Hug contents (~180px)
     - Summary: 3 lines max
   - **Focused:**
     - Border: 2px white 30% opacity
     - Glow: Outer shadow (blur 8px)
   - **Expanded:**
     - Height: Hug contents (~300px)
     - Summary: Full text visible
     - Extra metadata shown

#### 5. Add Priority Badge (20 min)
1. Create nested component: `PriorityBadge`
   - Variants: High, Medium, Low, None
   - Colors:
     - High: Red
     - Medium: Yellow
     - Low: Blue
     - None: Transparent
2. Instance in ZeroCard header
3. Add Boolean Property: `Show Priority`

#### 6. Test Responsiveness (10 min)
1. Test with different text lengths
2. Verify Auto Layout resizes correctly
3. Test with 1, 2, and 3 action buttons

#### 7. Documentation (10 min)
```
Email card component for Zero inbox feed.
Displays email summary with priority, actions, and expandable content.

Props:
- State: Default, Focused (selected), Expanded (detail view)
- Show Priority: boolean
- Button Count: 1-3 action buttons

Uses design tokens:
- spacing/card (24px padding)
- radius/card (16px)
- opacity/glassLight (0.1 background)
```

---

## Component 3: ZeroModal (1.5 hours)

### Overview
- **Purpose:** Overlay dialogs for actions/confirmations
- **Variants:** Standard, Action Picker, Confirmation
- **Token Usage:** Modal spacing, radius, backdrop opacity

### Step-by-Step Build

#### 1. Create Modal Container (15 min)
1. Create frame: **335 × 400px** (centered modal)
2. Name: `ZeroModal`
3. Add Auto Layout
   - Direction: Vertical
   - Padding: 24px (bind to `spacing/modal`)
   - Gap: 16px
   - Align: Stretch
   - Fixed width: 335px

#### 2. Add Content Structure (20 min)
1. **Header** (Auto Layout: Vertical, Gap: 8px)
   - Title (text, 20px, Bold)
   - Subtitle (text, 15px, Regular, Optional)
2. **Body** (Auto Layout: Vertical, Gap: 12px)
   - Body text or custom content area
   - Scrollable if needed
3. **Footer** (Auto Layout: Horizontal, Gap: 12px)
   - Button instances (1-3 buttons)
   - Justify: End (right-aligned)

#### 3. Apply Variables (10 min)
1. **Corner Radius:**
   - Bind to `radius/modal` (20px)
2. **Padding:**
   - Bind to `spacing/modal` (24px)
3. **Background:**
   - White with opacity 15%
   - Blur effect: 20px (glassmorphism)

#### 4. Create Backdrop (15 min)
1. Create frame: **390 × 844px** (iPhone 14 screen)
2. Name: `Backdrop`
3. Fill: Black
4. Opacity: Bind to `opacity/overlayStrong` (0.5)
5. Place behind modal

#### 5. Create Variants (25 min)
1. Add Component Property: `Type`
   - Values: `Standard`, `Action Picker`, `Confirmation`
2. Visual changes:
   - **Standard:**
     - Title + Body + 2 buttons (Cancel, Confirm)
   - **Action Picker:**
     - Title + List of action items + Cancel button
     - Taller modal (500px)
   - **Confirmation:**
     - Title + Icon + Body + 2 buttons
     - Red destructive button

#### 6. Add Animation Hints (5 min)
1. Add component description note:
   ```
   Animation: Slide up from bottom with spring (0.5s, damping: 0.8)
   Backdrop: Fade in (0.3s)
   ```

#### 7. Documentation (10 min)
```
Modal overlay component for dialogs and action sheets.

Props:
- Type: Standard, Action Picker, Confirmation
- Title: string
- Body: string or custom content
- Button Count: 1-3 buttons

Uses design tokens:
- spacing/modal (24px)
- radius/modal (20px)
- opacity/overlayStrong (0.5 backdrop)

Glassmorphism: White 15% + Blur 20px
```

---

## Component 4: ZeroListItem (1 hour)

### Overview
- **Purpose:** Reusable list row (settings, action selection)
- **Variants:** Default, With Icon, With Badge, With Arrow
- **Token Usage:** Element spacing, minimal radius

### Step-by-Step Build

#### 1. Create Base Frame (10 min)
1. Create frame: **358 × 52px**
2. Name: `ZeroListItem`
3. Add Auto Layout
   - Direction: Horizontal
   - Padding: 12px (bind to `spacing/element`)
   - Gap: 12px
   - Align: Center
   - Fill container: Width

#### 2. Add Content (15 min)
1. **Leading Icon** (20 × 20px)
   - SF Symbol icon
   - Visible: false by default
2. **Label** (text, 16px, Regular)
   - Content: "List Item"
   - Fill container: Width
3. **Trailing Badge** (optional)
   - Text, 13px, Semibold
   - Background: Colored circle
4. **Arrow Icon** (chevron right, 16px)
   - Visible: false by default

#### 3. Apply Variables (10 min)
1. **Padding:**
   - Bind to `spacing/element` (12px)
2. **Gap:**
   - Bind to `spacing/element` (12px)
3. **Radius:**
   - Bind to `radius/minimal` (4px) - for hover state

#### 4. Create Variants (15 min)
1. Add Boolean Properties:
   - `Has Icon`: boolean
   - `Has Badge`: boolean
   - `Has Arrow`: boolean
2. Add Component Property: `State`
   - Values: `Default`, `Selected`, `Disabled`
3. Visual changes:
   - **Selected:**
     - Background: White 10% opacity
   - **Disabled:**
     - Opacity: 60%

#### 5. Test Variations (5 min)
1. Test all prop combinations:
   - Icon only
   - Badge only
   - Arrow only
   - Icon + Arrow
   - Icon + Badge + Arrow

#### 6. Documentation (5 min)
```
Reusable list item for settings and action selection.

Props:
- Has Icon: boolean
- Has Badge: boolean
- Has Arrow: boolean
- State: Default, Selected, Disabled

Uses design tokens:
- spacing/element (12px)
- radius/minimal (4px)
```

---

## Component 5: ZeroAlert (1 hour)

### Overview
- **Purpose:** Toast/banner alerts
- **Variants:** Success, Error, Warning, Info
- **Token Usage:** Semantic colors, button radius, component spacing

### Step-by-Step Build

#### 1. Create Base Frame (10 min)
1. Create frame: **358 × 68px**
2. Name: `ZeroAlert`
3. Add Auto Layout
   - Direction: Horizontal
   - Padding: 16px (bind to `spacing/component`)
   - Gap: 12px
   - Align: Center
   - Fill container: Width

#### 2. Add Content (15 min)
1. **Icon** (24 × 24px)
   - SF Symbol icon
   - Auto-selected based on variant:
     - Success: checkmark.circle
     - Error: xmark.circle
     - Warning: exclamationmark.triangle
     - Info: info.circle
2. **Text Section** (Auto Layout: Vertical, Gap: 4px)
   - Title (15px, Semibold)
   - Message (13px, Regular)
3. **Close Button** (optional)
   - X icon, 20px

#### 3. Apply Variables (10 min)
1. **Padding:**
   - Bind to `spacing/component` (16px)
2. **Radius:**
   - Bind to `radius/button` (12px)
3. **Gap:**
   - Bind to `spacing/element` (12px)

#### 4. Create Variants (20 min)
1. Add Component Property: `Type`
   - Values: `Success`, `Error`, `Warning`, `Info`
2. Colors per type:
   - **Success:**
     - Background: Green (#10b981) 20% opacity
     - Icon: Green
     - Border: Green 30%
   - **Error:**
     - Background: Red (#ef4444) 20% opacity
     - Icon: Red
     - Border: Red 30%
   - **Warning:**
     - Background: Yellow (#fbbf24) 20% opacity
     - Icon: Yellow
     - Border: Yellow 30%
   - **Info:**
     - Background: Blue (#3b82f6) 20% opacity
     - Icon: Blue
     - Border: Blue 30%

#### 5. Add Animation Hints (5 min)
```
Animation: Slide down from top (0.3s)
Duration: Auto-dismiss after 4s (user-configurable)
```

#### 6. Documentation (5 min)
```
Toast/banner alert for user feedback.

Props:
- Type: Success, Error, Warning, Info (auto-sets icon and colors)
- Title: string
- Message: string
- Has Close Button: boolean

Uses design tokens:
- spacing/component (16px)
- radius/button (12px)
- Semantic colors per type
```

---

## Final Checklist

After building all 5 components:

### Component Library Organization
- [ ] Create "Components" page in Figma
- [ ] Organize by category:
  - Buttons (ZeroButton)
  - Cards (ZeroCard)
  - Overlays (ZeroModal)
  - Lists (ZeroListItem)
  - Feedback (ZeroAlert)
- [ ] Add usage examples for each component
- [ ] Document component relationships (ZeroCard uses ZeroButton)

### Variable Verification
- [ ] All spacing values use Variables (not hardcoded)
- [ ] All radius values use Variables
- [ ] All opacity values use Variables
- [ ] No hardcoded colors (except semantic variants)

### Documentation
- [ ] Each component has description
- [ ] Props documented in component properties
- [ ] Usage examples created on "Examples" page
- [ ] Team library published

### Testing
- [ ] All variants visible and distinct
- [ ] Auto Layout works responsively
- [ ] Components work in light and dark modes
- [ ] Nested components (e.g., ZeroButton in ZeroCard) work correctly

---

## Next Steps: Day 3

Once all components are built in Figma:
1. Export component metadata
2. Generate SwiftUI wrappers using design tokens
3. Test components in iOS app
4. Refactor existing views to use new components

**Estimated Day 2 completion time:** 6-8 hours
**Success criteria:** All 5 components exist in Figma with full variants and Variable bindings

---

## Need Help?

**Common Issues:**
1. **Variables not showing:** Ensure Day 1 token sync completed
2. **Auto Layout not working:** Check constraints and resizing settings
3. **Components not published:** File → Publish Library

**Quick Win:** Start with ZeroButton (simplest) to get comfortable with the workflow, then tackle more complex components.

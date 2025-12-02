# Zero iOS Design System: Status & Enhancement Plan

**Last Updated:** December 1, 2024
**Status:** Infrastructure Excellent, Components Need Building
**Priority:** High - Foundation for visual craft excellence

---

## Executive Summary

**Good News:** You already have 80% of the design system infrastructure built! 🎉

**What You Have:**
- ✅ Complete design token system (`tokens.json` → `DesignTokens.swift`)
- ✅ Figma sync automation (`sync/` directory with 5 scripts)
- ✅ Figma plugin for bi-directional sync
- ✅ Primitive → Semantic → Component token architecture
- ✅ Auto-generated code (no manual token updates needed)

**What Needs Work:**
- 🟡 Figma Variables integration (opacity values are null)
- 🟡 Components library in Figma (buttons, cards, modals)
- 🟡 iOS SwiftUI component library using tokens
- 🟡 Living style guide / documentation
- 🟡 Design → Dev handoff process

**Recommended Approach:**
Use what you have (it's excellent!) + enhance with components library in **Phase 0** (Week 0) of Zero execution strategy.

---

## Part 1: What You Already Have (Infrastructure Assessment)

### 1.1 Design Token System ✅

**File:** `/design-system/tokens.json` (306 lines)
**Status:** Complete, follows W3C Design Tokens spec

**Token Categories:**
- **Primitive Tokens** (raw values)
  - Size: 11 values (2px → 48px)
  - Opacity: 11 values (0.0 → 1.0)
  - Blur: 4 values (10px → 40px)
  - Duration: 6 values (100ms → 1000ms)

- **Semantic Tokens** (usage-based)
  - Spacing: 8 tokens (minimal, inline, component, card, etc.)
  - Radius: 7 tokens (button, card, modal, circle, etc.)
  - Opacity: 11 semantic names (glassUltraLight, textPrimary, etc.)

- **Color Tokens** (comprehensive)
  - Base: white, black
  - Text hierarchy: primary, secondary, tertiary, subtle, faded, placeholder
  - Borders: strong, default, subtle, faint
  - Overlays: white/black with various opacities
  - Accents: blue, green, purple, red (iOS system colors)
  - Gradients: Mail (blue→purple), Ads (teal→green)
  - Semantic: error, warning, success, info (with backgrounds, borders, text)

- **Typography Tokens**
  - Font family: SF Pro (system)
  - 6 size scales: display, heading, body, label, card, thread
  - 4 font weights: regular, medium, semibold, bold

- **Component Tokens**
  - Card: padding, radius, shadow, glass opacity
  - Button: padding, radius, heights (standard/compact/small), icon size
  - Modal: padding, radius, overlay opacity
  - Badge: sizes, offsets, border width
  - Shadow: 3 presets (card, button, subtle)

**Format:** JSON with W3C `$schema`, `$type`, `$value`, token references (`{primitive.size.xl}`)

**Strength:** Single source of truth, platform-agnostic, follows industry standards

---

### 1.2 iOS Code Generation ✅

**File:** `/design-system/sync/generate-swift.js` (25,557 bytes)
**Output:** `/Zero_ios_2/Zero/Config/DesignTokens.swift` (285 lines)
**Status:** Working, auto-generated

**Generated Code Structure:**
```swift
enum DesignTokens {
    enum Primitive { ... }      // Raw values
    enum Spacing { ... }         // Semantic spacing
    enum Radius { ... }          // Border radius
    enum Opacity { ... }         // Opacity values
    enum Colors { ... }          // Color system
    enum Typography { ... }      // Font scale
    enum Card { ... }            // Card component
    enum Button { ... }          // Button component
    enum Modal { ... }           // Modal component
    enum Shadow { ... }          // Shadow presets
    enum Animation { ... }       // Duration presets
}
```

**Usage Example:**
```swift
Text("Hello")
    .font(DesignTokens.Typography.bodyLarge)
    .foregroundColor(DesignTokens.Colors.textPrimary)
    .padding(DesignTokens.Spacing.component)
    .background(DesignTokens.Colors.accentBlue)
    .cornerRadius(DesignTokens.Radius.button)
```

**Strength:** Type-safe, autocomplete-friendly, no magic strings

---

### 1.3 Figma Sync Automation ✅

**Directory:** `/design-system/sync/` (11 files)
**Status:** Functional, needs Figma Variables enhancement

**Workflow:**
```
┌────────────────┐
│ Figma File     │  (Single source of truth)
│ Design System  │
└────────┬───────┘
         │
         ▼
┌─────────────────────┐
│ export-from-figma.js│  Extracts via REST API
└─────────┬───────────┘
          │
          ▼
┌──────────────────┐
│ design-tokens.   │  Platform-agnostic JSON
│ json             │
└──────┬───────────┘
       │
   ┌───┴────┐
   ▼        ▼
┌────────┐ ┌────────┐
│ Swift  │ │ Web    │  Platform-specific code
│ (iOS)  │ │ (CSS)  │
└────────┘ └────────┘
```

**Scripts:**
1. `sync-all.js` - Master script, runs full pipeline
2. `export-from-figma.js` - Extracts tokens from Figma REST API
3. `generate-swift.js` - Converts JSON → Swift code
4. `generate-web.js` - Converts JSON → CSS variables + JS module
5. `sync-to-figma.js` - Pushes tokens back to Figma (bidirectional)

**Environment Setup:**
```bash
export FIGMA_ACCESS_TOKEN="figd_..."
export FIGMA_FILE_KEY="WuQicPi1wbHXqEcYCQcLfr"

cd design-system/sync
node sync-all.js  # Runs full pipeline
```

**Strength:** Automated, bidirectional, version controlled

---

### 1.4 Figma Plugin ✅

**Directory:** `/design-system/figma-plugin/` (24 files)
**Status:** Built, multiple variants (sync, code generator)

**Plugin Variants:**
1. **Sync Plugin** (`sync-plugin.ts`) - Syncs styles and variables
2. **Code Generator** (`code-generator.ts`) - Generates SwiftUI components
3. **UI Templates** (`sync-ui.html`, `ui-generator.html`) - Plugin interfaces

**What It Can Do:**
- ✅ Create Figma color styles from tokens
- ✅ Create Figma text styles from tokens
- ✅ Generate components (toast, progress bar, buttons, cards, modals)
- ✅ Export Figma Variables (partial - see issues below)

**Usage:**
1. Open Figma Desktop App
2. Plugins → Development → Import plugin from manifest
3. Run "Zero Design System Sync"
4. Choose: Sync All, Update Colors, Update Typography, Generate Components

**Strength:** Bidirectional sync, no context switching between Figma and code

---

### 1.5 Figma Variables Support 🟡 (Partial)

**File:** `/design-system/sync/figma-variables.json`
**Status:** Structure exists, but opacity values are `null`

**What Works:**
- ✅ Spacing variables (card, modal, section, component, etc.)
- ✅ Radius variables (button, card, modal, circle, etc.)
- ✅ Color variables (gradients with r,g,b,a format)

**What's Broken:**
- ❌ Opacity variables (all values are `null`)

**Issue:**
```json
{
  "name": "opacity/glassUltraLight",
  "type": "FLOAT",
  "value": null,     // ← Should be 0.05
  "description": "Opacity token: glassUltraLight"
}
```

**Root Cause:** Opacity tokens reference primitive tokens but generator doesn't resolve references.

**Fix Required:** Update `sync-to-figma.js` to resolve token references before generating Figma Variables.

---

## Part 2: What's Missing (Component Library)

### 2.1 Figma Components Library 🟡

**Status:** Some components generated by plugin, but not comprehensive

**What Exists (Generated by Plugin):**
- ✅ Toast/Undo with progress bar
- ✅ Progress bar variants
- ✅ Action priority chips
- ✅ Modal template with backdrop
- ✅ Action buttons (primary, secondary, destructive)
- ✅ Action cards with badges
- ✅ Input fields (default, focused)

**What's Missing:**
- ❌ Email card component (core UI element)
- ❌ Action modal variants (10 core actions)
- ❌ Navigation components (tab bar, header)
- ❌ List items, cells, separators
- ❌ Icons library (standardized SF Symbols usage)
- ❌ Loading states, skeletons, empty states
- ❌ Alerts, dialogs, confirmation modals

**Why This Matters:**
- Designers can't prototype without components
- Developers lack visual reference
- Design→Dev handoff is manual and error-prone
- No single source of truth for component styles

---

### 2.2 iOS SwiftUI Component Library 🟡

**Status:** Components exist but don't consistently use DesignTokens

**Current State:**
Zero iOS has 265 Swift files with components scattered across:
- `/Views/Components/` - Reusable components
- `/Views/ActionModules/` - Action-specific UIs
- `/Views/Feed/` - Email feed components

**Issue:** Many components use hardcoded values instead of `DesignTokens`:

**Example (Bad):**
```swift
// ❌ Hardcoded values
Text("Hello")
    .font(.system(size: 15))
    .foregroundColor(Color.white.opacity(0.8))
    .padding(16)
    .cornerRadius(12)
```

**Example (Good):**
```swift
// ✅ Using DesignTokens
Text("Hello")
    .font(DesignTokens.Typography.bodyLarge)
    .foregroundColor(DesignTokens.Colors.textPrimary)
    .padding(DesignTokens.Spacing.component)
    .cornerRadius(DesignTokens.Radius.button)
```

**Fix Required:**
1. Audit all 265 Swift files for hardcoded values
2. Refactor to use DesignTokens consistently
3. Create reusable component wrappers (ZeroButton, ZeroCard, etc.)

---

### 2.3 Living Style Guide / Documentation 🟡

**Status:** Documentation exists but no living style guide

**What Exists:**
- ✅ README.md (comprehensive)
- ✅ sync/README.md (workflow documentation)
- ✅ FIGMA_BUILD_GUIDE.md
- ✅ FIGMA_DESIGN_SPECIFICATION.md
- ✅ Token reference tables in README

**What's Missing:**
- ❌ Living style guide (interactive component showcase)
- ❌ Visual examples of all tokens in use
- ❌ Component usage guidelines
- ❌ Dos and don'ts for designers
- ❌ Accessibility guidelines
- ❌ Responsive behavior documentation

**Tools to Consider:**
- **Storybook** (for web components, if building web version)
- **SwiftUI Previews** (for iOS, but not shareable)
- **Figma Dev Mode** (for handoff)
- **Custom docs site** (Next.js + MDX)

---

### 2.4 Design → Dev Handoff Process 🟡

**Status:** Infrastructure exists but process is undefined

**Current Flow (Manual):**
1. Designer updates Figma
2. Developer manually inspects Figma for styles
3. Developer writes SwiftUI code
4. Designer reviews built UI in TestFlight
5. Repeat if mismatches

**Desired Flow (Automated):**
1. Designer updates Figma (using components library)
2. Designer runs sync plugin or triggers CI/CD
3. Tokens auto-sync to iOS
4. Developer uses pre-built components with tokens
5. Design→Dev mismatches impossible (single source of truth)

**What's Needed:**
1. CI/CD pipeline for token sync (GitHub Actions)
2. Figma Variables + Modes for light/dark themes
3. Component prop documentation in Figma
4. Automated visual regression testing

---

## Part 3: Enhancement Plan (Phased Approach)

### Phase 0: Design System Foundation (Week 0 of Zero Execution)

**Goal:** Fix existing issues, build core components library

**Timeline:** 3-5 days

**Tasks:**

#### Task 1: Fix Figma Variables (Opacity) - 2 hours
**File:** `/design-system/sync/sync-to-figma.js`

**Problem:** Opacity values are null because token references aren't resolved

**Solution:**
```javascript
// sync-to-figma.js
function resolveTokenReferences(tokenValue, allTokens) {
  if (typeof tokenValue === 'string' && tokenValue.startsWith('{')) {
    // Example: "{primitive.opacity.glass}" → 0.05
    const path = tokenValue.slice(1, -1).split('.');
    let resolved = allTokens;
    for (const key of path) {
      resolved = resolved[key];
      if (resolved.$value !== undefined) {
        return resolved.$value;
      }
    }
    return resolved;
  }
  return tokenValue;
}

// Apply when generating Figma Variables
const opacityValue = resolveTokenReferences(token.value, allTokens);
```

**Deliverable:** All 11 opacity variables have correct values in Figma

---

#### Task 2: Build Core Components in Figma - 1 day
**Components to Create:**

1. **ZeroCard** (Email Card)
   - Variants: Default, Focused, Expanded
   - Props: Title, Summary, Priority badge, Actions
   - Uses: Token-based spacing, radius, colors

2. **ZeroButton**
   - Variants: Primary, Secondary, Destructive, Text
   - Sizes: Large (56px), Medium (44px), Small (32px)
   - States: Default, Hover, Pressed, Disabled

3. **ZeroModal**
   - Variants: Standard, Action Picker, Confirmation
   - Props: Title, Body, Buttons (1-3)
   - Uses: Token-based backdrop opacity, radius

4. **ZeroListItem**
   - Variants: Default, With Icon, With Badge, With Arrow
   - States: Default, Selected, Disabled

5. **ZeroAlert**
   - Variants: Success, Error, Warning, Info
   - Uses: Semantic color tokens

**Tools:**
- Use Figma Auto Layout (matches SwiftUI Stack behavior)
- Use Figma Variables for colors, spacing, radius
- Document component props in descriptions

**Deliverable:** 5 core components in Figma with full variants

---

#### Task 3: Generate SwiftUI Component Wrappers - 1 day
**Create:** `/Zero_ios_2/Zero/Core/UI/Components/ZeroComponents.swift`

**Components:**
```swift
// ZeroButton.swift
struct ZeroButton: View {
    enum Style {
        case primary, secondary, destructive, text
    }

    enum Size {
        case large, medium, small

        var height: CGFloat {
            switch self {
            case .large: return DesignTokens.Button.heightStandard
            case .medium: return DesignTokens.Button.heightCompact
            case .small: return DesignTokens.Button.heightSmall
            }
        }
    }

    let title: String
    let style: Style
    let size: Size
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.bodyLarge)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity, minHeight: size.height)
                .background(backgroundColor)
                .cornerRadius(DesignTokens.Radius.button)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return DesignTokens.Colors.accentBlue
        case .secondary: return DesignTokens.Colors.overlay10
        case .destructive: return DesignTokens.Colors.errorPrimary
        case .text: return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .text: return DesignTokens.Colors.accentBlue
        default: return DesignTokens.Colors.textPrimary
        }
    }
}
```

**Similarly for:**
- `ZeroCard.swift` - Email card wrapper
- `ZeroModal.swift` - Modal wrapper
- `ZeroListItem.swift` - List item wrapper
- `ZeroAlert.swift` - Alert wrapper

**Deliverable:** 5 reusable component wrappers in `/Core/UI/Components/`

---

#### Task 4: Refactor Existing Components to Use Tokens - 1 day
**Approach:**
1. Run audit script to find hardcoded values
2. Prioritize top 20 most-used components
3. Refactor to use DesignTokens
4. Update component files

**Audit Script:**
```bash
# Find hardcoded font sizes
grep -r "\.system(size: [0-9]" Zero_ios_2/Zero/Views/

# Find hardcoded colors
grep -r "Color\.white\.opacity" Zero_ios_2/Zero/Views/

# Find hardcoded padding/spacing
grep -r "\.padding([0-9]" Zero_ios_2/Zero/Views/
```

**Refactor Example:**
```swift
// BEFORE
Text("Action")
    .font(.system(size: 15, weight: .semibold))
    .foregroundColor(Color.white.opacity(0.9))
    .padding(16)

// AFTER
Text("Action")
    .font(DesignTokens.Typography.bodyLarge)
    .foregroundColor(DesignTokens.Colors.textPrimary)
    .padding(DesignTokens.Spacing.component)
```

**Deliverable:** Top 20 components refactored, audit report documenting progress

---

#### Task 5: Create Living Style Guide (Optional) - 2 days
**Option 1: Figma Dev Mode (Quick)**
- Publish components to Figma library
- Enable Dev Mode for developers
- Document usage in component descriptions

**Option 2: SwiftUI Previews (Good)**
- Create `/Zero_ios_2/Zero/DevTools/StyleGuidePreview.swift`
- Show all components with variants
- Developers can see live in Xcode

```swift
struct StyleGuidePreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SectionView(title: "Buttons") {
                    ZeroButton(title: "Primary", style: .primary, size: .large, action: {})
                    ZeroButton(title: "Secondary", style: .secondary, size: .medium, action: {})
                    ZeroButton(title: "Destructive", style: .destructive, size: .small, action: {})
                }

                SectionView(title: "Cards") {
                    ZeroCard(title: "Email Card", summary: "This is a summary")
                }

                // ... more sections
            }
        }
    }
}
```

**Option 3: Custom Docs Site (Best, but time-consuming)**
- Next.js + MDX site at `design-system/docs-site/`
- Embed Figma frames (components)
- Show SwiftUI code examples
- Host on Vercel or Netlify

**Recommendation:** Start with Option 2 (SwiftUI Previews), upgrade to Option 3 later

**Deliverable:** StyleGuidePreview.swift with all components showcased

---

### Phase 0.5: CI/CD Automation (Optional, Week 0-1)

**Goal:** Automate token sync in GitHub Actions

**Timeline:** 2-3 hours

**Setup:**
```yaml
# .github/workflows/sync-design-tokens.yml
name: Sync Design Tokens

on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9am
  workflow_dispatch:      # Manual trigger

jobs:
  sync-tokens:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Sync tokens from Figma
        env:
          FIGMA_ACCESS_TOKEN: ${{ secrets.FIGMA_TOKEN }}
        run: |
          cd design-system/sync
          node sync-all.js

      - name: Check for changes
        id: changes
        run: |
          git diff --quiet Zero_ios_2/Zero/Config/DesignTokens.swift || echo "changed=true" >> $GITHUB_OUTPUT

      - name: Create Pull Request
        if: steps.changes.outputs.changed == 'true'
        uses: peter-evans/create-pull-request@v5
        with:
          title: 'chore: sync design tokens from Figma'
          commit-message: 'Update DesignTokens.swift from Figma'
          branch: 'automated/design-tokens'
          body: |
            Automated design token sync from Figma.

            **Changes:**
            - Updated DesignTokens.swift

            **Review:**
            - Verify no breaking changes
            - Check diff for unexpected modifications
```

**Setup Steps:**
1. Add `FIGMA_TOKEN` secret to GitHub repo
2. Create workflow file
3. Test with manual trigger
4. Enable weekly schedule

**Deliverable:** Automated token sync every Monday, manual trigger available

---

## Part 4: Integration with Zero Execution Strategy

### Where It Fits: Phase 0 (Before Week 1)

**Original Plan:** Phase 1 starts with email infrastructure audit
**Enhanced Plan:** Phase 0 sets up design system foundation first

**Why Phase 0 is Critical:**
- All UI components built in Phases 1-6 need consistent styling
- Prevents technical debt (hardcoded values)
- Enables designers to prototype in Figma while devs build features
- Visual craft excellence from Day 1

### Updated Timeline

**Week -1 to Week 0: Phase 0 - Design System Foundation**
- Days 1-2: Fix Figma Variables, build core components in Figma
- Days 3-4: Create SwiftUI component wrappers, refactor existing
- Day 5: Living style guide (SwiftUI previews)
- Optional: Setup CI/CD automation

**Week 1: Phase 1 - Beta Quality (Original Plan)**
- Email infrastructure audit (now uses ZeroCard for consistency)
- Summarization optimization
- Action validation
- All new UI uses design system components

**Weeks 2-24: Phases 2-6 (Original Plan)**
- Continue using design system components
- Add new components as needed to Figma + iOS
- Sync tokens weekly via CI/CD

---

## Part 5: Success Metrics

### Design System Metrics

**Coverage:**
- 100% of primitive values defined as tokens ✅ (Already done)
- 100% of semantic tokens map to primitives ✅ (Already done)
- 90%+ of components use DesignTokens (Target by end of Week 0)

**Consistency:**
- Zero hardcoded colors in Views/ (Target by end of Week 0)
- Zero hardcoded spacing values (Target by end of Week 0)
- Zero hardcoded font sizes (Target by end of Week 0)

**Documentation:**
- All tokens documented with descriptions ✅ (Already done)
- All components have Figma variants (Target by end of Week 0)
- Living style guide accessible to team (Target by end of Week 0)

**Automation:**
- Token sync runs automatically weekly (Target by Week 1)
- Zero manual token updates needed ✅ (Already done)
- Design→Dev handoff < 5 minutes (Target by Week 2)

### Visual Craft Excellence Indicators

**Design Quality:**
- App Store screenshots look pixel-perfect
- Beta users comment on "beautiful" or "polished" UI
- No visual inconsistencies across screens

**Developer Experience:**
- New features use design system by default (no extra effort)
- Component reuse rate >80%
- Zero "how should I style this?" questions

**Scalability:**
- Adding new features takes same time as first features
- Dark mode can be added in 1 day (all tokens support it)
- Rebrand possible in hours not days (change tokens, regenerate)

---

## Part 6: Tools & Resources

### Recommended Tools

**1. Figma Desktop App (Required)**
- Runs plugins locally
- Faster than browser version
- Required for plugin development

**2. Figma Variables (Recommended)**
- Native token support in Figma
- Links to components automatically
- Better than styles for responsive design

**3. Style Dictionary (Optional, Future)**
- Industry-standard token transformer
- Supports Android, Web, iOS, CSS, SCSS, etc.
- More powerful than custom scripts
- Use if scaling beyond iOS+Web

**Why NOT using Style Dictionary now?**
- Your custom scripts work well
- Style Dictionary is overkill for iOS-only
- Can migrate later if needed

**4. Figma API vs REST API**
- **REST API:** Simpler, reads file structure
- **Variables API:** More powerful, reads Figma Variables
- **Recommendation:** Use both (REST for colors, Variables API for tokens)

### Industry Examples

**Companies with Great Design Systems:**
1. **Airbnb** - Token-based, cross-platform
2. **Shopify Polaris** - Living style guide, open source
3. **IBM Carbon** - Comprehensive, multi-framework
4. **Atlassian Design System** - Components, patterns, principles
5. **Material Design** - Google's system, Figma kit available

**iOS-Specific Examples:**
1. **Apple Human Interface Guidelines** - SF Symbols, iOS conventions
2. **SwiftUI Design System** - By Apple, showcases best practices
3. **Instagram iOS** - Consistent token usage visible in app

---

## Part 7: Decision Matrix

### Should You Use Style Dictionary?

**Pros:**
- ✅ Industry standard (Amazon, Adobe, Salesforce use it)
- ✅ Supports many platforms (Android, Web, React Native, Flutter)
- ✅ Powerful transformations (px → pt → rem)
- ✅ Plugin ecosystem
- ✅ Better documentation than custom scripts

**Cons:**
- ❌ Overkill for iOS-only project
- ❌ Learning curve (new config format)
- ❌ Migration effort from current system
- ❌ Your current scripts already work well

**Recommendation:**
- **Stick with current system for now**
- Your scripts are excellent and working
- Revisit Style Dictionary if you:
  - Build Android version
  - Build web dashboard
  - Need design tokens for marketing site
  - Raise funding and hire design team

---

### Should You Build a Custom Figma Plugin or Use Existing?

**You Already Have Both!**
- ✅ Custom plugin (`figma-plugin/`)
- ✅ REST API scripts (`sync/`)

**Current Approach is Ideal:**
- Plugin for manual sync (designers use when needed)
- Scripts for automated CI/CD (runs weekly)
- Best of both worlds

**Don't change anything here.** ✅

---

### Should You Use Figma Variables or Styles?

**Figma Variables (Newer, Better):**
- ✅ Native token support
- ✅ Can reference other variables
- ✅ Modes (light/dark theme)
- ✅ Better API for sync
- ✅ Auto-updates components

**Figma Styles (Older, Stable):**
- ✅ More mature
- ✅ Better supported by plugins
- ✅ Simpler API
- ❌ No modes (can't do light/dark easily)
- ❌ No variable references

**Recommendation:**
- **Use Variables for tokens** (spacing, radius, opacity, colors)
- **Keep Styles for typography** (better text style support)
- Your `figma-variables.json` shows you're already going this direction ✅

---

## Part 8: Next Steps (Action Plan)

### Immediate Actions (This Week)

**Today (30 minutes):**
1. Set FIGMA_ACCESS_TOKEN in environment:
   ```bash
   export FIGMA_ACCESS_TOKEN="figd_..."
   echo "export FIGMA_ACCESS_TOKEN='figd_...'" >> ~/.zshrc
   ```

2. Test token sync:
   ```bash
   cd /Users/matthanson/Zer0_Inbox/design-system/sync
   node sync-all.js
   ```

3. Verify DesignTokens.swift updated

**Tomorrow (2-3 hours):**
1. Fix Figma Variables opacity issue
2. Push variables to Figma
3. Test in Figma file (see variables panel)

**This Week (3-5 days):**
1. Build 5 core components in Figma
2. Generate SwiftUI wrappers
3. Refactor top 20 components to use tokens
4. Create StyleGuidePreview.swift

### Week 0 Deliverables Checklist

- [ ] Figma Variables opacity values fixed
- [ ] 5 core components in Figma (ZeroCard, ZeroButton, ZeroModal, ZeroListItem, ZeroAlert)
- [ ] 5 SwiftUI component wrappers created
- [ ] Top 20 components refactored to use DesignTokens
- [ ] StyleGuidePreview.swift created
- [ ] Audit report: % components using tokens
- [ ] CI/CD workflow (optional)

### Week 1+ Integration

- [ ] Use design system components in Phase 1 (Email infrastructure)
- [ ] Add new components as needed (document in Figma + iOS)
- [ ] Weekly token sync (manual or automated)
- [ ] Monitor consistency metrics

---

## Part 9: FAQ

**Q: Do I need to rebuild my entire design system?**
A: **No!** You already have 80% built. Just add components library and fix opacity bug.

**Q: Should I use Style Dictionary instead of custom scripts?**
A: Not yet. Your scripts work great. Consider Style Dictionary if you build Android or need multi-platform support.

**Q: How long will Phase 0 take?**
A: 3-5 days for core work. 1-2 weeks if you want perfect polish + CI/CD.

**Q: Can I skip Phase 0 and start Phase 1?**
A: You *could*, but you'll accumulate technical debt. Better to invest 3-5 days now than refactor later.

**Q: What if my designers don't use Figma?**
A: Then skip Figma plugin/sync and use tokens.json as single source of truth. Generate Swift directly.

**Q: How do I handle dark mode?**
A: Use Figma Variables with Modes (one mode for light, one for dark). Generate separate DesignTokens for each mode.

**Q: What about animations and transitions?**
A: Add duration tokens (you already have them!). Create Animation presets in Swift:
```swift
enum Animation {
    static let quick = Animation.easeInOut(duration: DesignTokens.Animation.quick)
    static let standard = Animation.easeInOut(duration: DesignTokens.Animation.standard)
}
```

**Q: How do I onboard new designers/developers?**
A: Point them to:
1. This document (overview)
2. design-system/README.md (workflow)
3. StyleGuidePreview.swift (live examples)
4. Figma components library (visual reference)

---

## Part 10: Summary & Recommendation

### You're In Great Shape! 🎉

**What You've Built:**
- Complete token system (primitive → semantic → component)
- Automated Figma sync (bidirectional)
- Figma plugin (for designer self-service)
- Auto-generated Swift code (type-safe, no magic strings)

**What You Need:**
- 3-5 days to build components library
- Fix one bug (Figma Variables opacity)
- Refactor existing components to use tokens
- Living style guide (SwiftUI previews)

**ROI of Phase 0:**
- **Time Investment:** 3-5 days
- **Time Saved:** 1-2 days per week (no design→dev back-and-forth)
- **Payback Period:** 2-3 weeks
- **Long-term Value:** Infinitely reusable, scales with product

### Recommended Path

**Option A: Minimal (3 days)**
1. Fix Figma Variables opacity (2 hours)
2. Build 5 core Figma components (1 day)
3. Create 5 SwiftUI wrappers (1 day)
4. Refactor top 10 components (1 day)

**Option B: Complete (5 days)** ← **Recommended**
1. All of Option A
2. Refactor top 20 components (2 days)
3. StyleGuidePreview.swift (1 day)
4. CI/CD automation (0.5 day)

**Option C: Perfection (2 weeks)**
1. All of Option B
2. Custom docs site (3-4 days)
3. Design principles documentation (1 day)
4. Accessibility guidelines (1 day)
5. Comprehensive testing (2 days)

**My Recommendation: Option B** (Complete in 5 days)
- Balances speed and quality
- Sets strong foundation for Phases 1-6
- Enables visual craft excellence
- Prevents technical debt

---

## Part 11: Integration into ZERO_IOS_EXECUTION_STRATEGY.md

### Add Phase 0 Before Phase 1

**New Section:**
```markdown
## Phase 0: Design System Foundation (Week -1 to Week 0)
**Goal:** Ensure visual craft excellence from Day 1

**Timeline:** 5 days
**Owner:** Founder + Claude Code
**Budget:** $0 (time only)

### Week 0 Tasks:
**Days 1-2: Fix & Enhance Token System**
- Fix Figma Variables opacity values
- Verify all tokens sync correctly
- Test in Figma and iOS

**Days 3-4: Build Component Library**
- Create 5 core components in Figma
- Generate SwiftUI wrappers
- Refactor top 20 components to use DesignTokens

**Day 5: Documentation & Living Style Guide**
- Create StyleGuidePreview.swift
- Document component usage
- Setup CI/CD automation (optional)

### Deliverables:
- [ ] All Figma Variables functional
- [ ] 5 core components in Figma + iOS
- [ ] 90%+ of components use DesignTokens
- [ ] StyleGuidePreview.swift
- [ ] Audit report

### Success Criteria:
- Zero hardcoded colors in Views/
- Zero hardcoded spacing values
- All components reusable
- Design→Dev handoff < 5 minutes

**Phase 1 starts after Phase 0 complete.** No exceptions.
```

---

## Appendix: File Structure Reference

```
/Users/matthanson/Zer0_Inbox/
├── design-system/
│   ├── tokens.json                      # ✅ Source of truth (306 lines)
│   ├── README.md                        # ✅ Documentation
│   ├── sync/
│   │   ├── sync-all.js                  # ✅ Master script
│   │   ├── export-from-figma.js         # ✅ Figma REST API
│   │   ├── generate-swift.js            # ✅ Swift generator
│   │   ├── generate-web.js              # ✅ Web generator
│   │   ├── sync-to-figma.js             # ✅ Push to Figma
│   │   ├── figma-variables.json         # 🟡 Needs opacity fix
│   │   └── README.md                    # ✅ Workflow docs
│   ├── figma-plugin/
│   │   ├── manifest.json                # ✅ Plugin config
│   │   ├── sync-plugin.ts               # ✅ Sync logic
│   │   ├── code-generator.ts            # ✅ Component generator
│   │   └── sync-ui.html                 # ✅ Plugin UI
│   ├── generated/
│   │   ├── DesignTokens.swift           # ✅ Auto-generated (copied to iOS project)
│   │   ├── design-tokens.css            # ✅ Web CSS vars
│   │   └── design-tokens.js             # ✅ Web JS module
│   └── docs/                            # 🟡 Create style guide here
│
├── Zero_ios_2/Zero/
│   ├── Config/
│   │   └── DesignTokens.swift           # ✅ Synced from generated/
│   ├── Core/UI/
│   │   ├── Components/                  # 🟡 Add ZeroComponents here
│   │   ├── Layouts/
│   │   └── Styles/
│   ├── Views/
│   │   ├── Components/                  # 🟡 Refactor to use tokens
│   │   ├── ActionModules/               # 🟡 Refactor to use tokens
│   │   └── Feed/                        # 🟡 Refactor to use tokens
│   └── DevTools/
│       └── StyleGuidePreview.swift      # 🟡 Create this
```

---

**END OF DOCUMENT**

This comprehensive plan shows you already have a world-class design system infrastructure. Just need 3-5 days to build the components library and refactor existing code. Then you'll have visual craft excellence that scales with your product.

Next step: Execute Phase 0 (5 days) → Then proceed to Phase 1 of Zero execution strategy.

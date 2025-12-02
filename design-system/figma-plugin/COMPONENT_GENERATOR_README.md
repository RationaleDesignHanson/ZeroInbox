# Zero Component Generator Plugin

**Automates Phase 0 Day 2: Figma component creation**

This plugin automatically generates the 5 core Zero design system components with proper Auto Layout, variants, and Variable bindings.

---

## Components Generated

1. **ZeroButton** - Primary interaction button
   - 4 styles: Primary, Secondary, Destructive, Text
   - 3 sizes: Large (56px), Medium (44px), Small (32px)
   - 4 states: Default, Hover, Pressed, Disabled
   - Optional icon support

2. **ZeroCard** - Email card for inbox feed
   - States: Default, Focused, Expanded
   - Priority badge support
   - Action buttons integration
   - Expandable summary text

3. **ZeroModal** - Overlay dialogs
   - Types: Standard, Action Picker, Confirmation
   - Glassmorphism background (15% white)
   - Backdrop with 50% black overlay
   - Footer button section

4. **ZeroListItem** - Settings & action list rows
   - Optional leading icon
   - Optional trailing badge
   - Optional chevron arrow
   - States: Default, Selected, Disabled

5. **ZeroAlert** - Toast notifications
   - Types: Success, Error, Warning, Info
   - Auto-colored icons per type
   - Optional close button
   - Type-specific backgrounds (20% opacity)

---

## Installation

### 1. Build the Plugin

```bash
cd design-system/figma-plugin
npm install
npm run build:generator
```

This generates `component-generator.js` from the TypeScript source.

### 2. Load in Figma Desktop

1. Open Figma Desktop App
2. Go to **Plugins → Development → Import plugin from manifest...**
3. Select: `design-system/figma-plugin/manifest-component-generator.json`
4. Plugin will appear as "Zero Component Generator" in your plugin list

### 3. Run the Plugin

1. Open your Zero design file in Figma
2. Go to **Plugins → Development → Zero Component Generator**
3. Click **"Generate All Components"**
4. Wait ~5-10 seconds for generation
5. Components appear on a new "Components" page

---

## Prerequisites

⚠️ **IMPORTANT:** Before running this plugin:

1. **Figma Variables must be loaded**
   - Run the "Zero Design Sync" plugin first to import tokens
   - Or manually create Variables: `spacing/*`, `radius/*`, `opacity/*`

2. **Fonts must be available**
   - SF Pro Display (Regular, Medium, Semibold, Bold)
   - If fonts not available, text layers will use system fallback

---

## What Gets Generated

### Auto Layout ✅
- All components use Auto Layout for responsive sizing
- Proper constraints: Hug contents, Fill container, Fixed
- Direction: Horizontal or Vertical as appropriate

### Component Properties ✅
- Variants (Style, Size, State, Type)
- Boolean properties (HasIcon, HasBadge, HasArrow, etc.)
- Text properties for labels and content

### Variable Bindings ✅
- Corner radius → `radius/button`, `radius/card`, `radius/modal`
- Padding → `spacing/component`, `spacing/card`, `spacing/modal`
- Gap → `spacing/element`, `spacing/inline`
- Opacity → `opacity/glassLight`, `opacity/overlayStrong`

### Organization ✅
- Components page created automatically
- Positioned in grid layout for easy viewing
- Viewport zooms to show all components

---

## After Generation

### Manual Refinements Needed

1. **Add Background Blur to ZeroModal**
   - Select modal component
   - Effects → Add Background Blur (20px)
   - Required for glassmorphism look

2. **Replace Placeholder Icons**
   - Icon placeholders are rectangles
   - Replace with actual SF Symbols or icon library
   - Use Iconify plugin or similar

3. **Create Component Variants**
   - Plugin creates base components
   - Use Figma's "Create component set" to add variants
   - Configure variant properties panel

4. **Fine-tune Typography**
   - Adjust line heights if needed
   - Set text alignment (center, left)
   - Configure truncation behavior

5. **Test Responsiveness**
   - Resize components to test Auto Layout
   - Verify text wrapping behavior
   - Check icon alignment

6. **Publish to Library**
   - File → Publish Library
   - Enable component publishing
   - Team can now use components

---

## Matching SwiftUI Implementation

The generated Figma components match the structure in:
`Zero_ios_2/Zero/Core/UI/Components/ZeroComponents.swift`

**Naming conventions:**
- Figma: `ZeroButton` → SwiftUI: `struct ZeroButton`
- Figma properties → SwiftUI enums/properties
- Variants → Swift enum cases

**Design tokens:**
- Figma Variables → `DesignTokens.swift` constants
- Example: `radius/button` (12px) → `DesignTokens.Radius.button`

---

## Troubleshooting

### "Variable not found" warnings
**Cause:** Variables not loaded in Figma file
**Fix:** Run "Zero Design Sync" plugin first to import tokens

### Font loading errors
**Cause:** SF Pro Display not available
**Fix:** Install SF Pro fonts from Apple, or use fallback

### Components not visible
**Cause:** Viewport not zoomed correctly
**Fix:** Manually zoom to "Components" page, components at (100, 100)

### Plugin doesn't appear in menu
**Cause:** Manifest not imported correctly
**Fix:** Re-import using exact manifest path: `manifest-component-generator.json`

---

## Development

### Watch Mode

```bash
npm run dev:generator
```

Watches `component-generator.ts` for changes and rebuilds automatically.

### Rebuild

```bash
npm run build:generator
```

After rebuilding, **reload plugin** in Figma (Plugins → Development → Reload).

### Debugging

Use `console.log()` in TypeScript code:
- Open Figma Desktop → Plugins → Development → Show/Hide Console
- Logs appear in developer console

---

## Next Steps (Phase 0 Day 3-5)

After running this plugin:

✅ **Day 2 Complete:** Figma components exist with variants
⏭️ **Day 3:** Test SwiftUI components in app, refactor existing views
⏭️ **Day 4:** Audit 265 Swift files, replace hardcoded values with DesignTokens
⏭️ **Day 5:** Create living style guide, document component usage

---

## Related Files

- Plugin source: `component-generator.ts`
- Compiled plugin: `component-generator.js`
- UI: `component-generator-ui.html`
- Manifest: `manifest-component-generator.json`
- Build config: `tsconfig-component-generator.json`
- SwiftUI components: `../Zero_ios_2/Zero/Core/UI/Components/ZeroComponents.swift`

---

## Credits

Phase 0 Day 2 automation
Generated with Claude Code
Zero Design System v2.0

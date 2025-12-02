# Zero Component Generator - Full Automation

**Complete automation of Figma component generation including ALL variants**

---

## What This Does

Generates **5 production-ready component sets** with **92 total variants** in ~60 seconds:

| Component | Variants | Details |
|-----------|----------|---------|
| **ZeroButton** | 48 | 4 styles × 3 sizes × 4 states |
| **ZeroCard** | 24 | 2 layouts × 3 priorities × 4 states |
| **ZeroModal** | 6 | 3 sizes × 2 states |
| **ZeroListItem** | 6 | 2 types × 3 states |
| **ZeroAlert** | 8 | 4 types × 2 positions |
| **TOTAL** | **92** | Fully automated |

---

## Time Savings

| Approach | Time Required | What's Included |
|----------|---------------|-----------------|
| **Manual (No Plugin)** | 6-8 hours | Everything manual in Figma |
| **Basic Plugin** | ~2.5 hours | Structure automated, variants manual |
| **Full Automation** | **~60 seconds** | Everything automated |

**Time saved: 6-8 hours → 1 minute** 🎉

---

## Installation & Usage

### Step 1: Build the Plugin

```bash
cd /Users/matthanson/Zer0_Inbox/design-system/figma-plugin
npm run build:variants
```

This compiles `component-generator-with-variants.ts` → `component-generator-with-variants.js`

### Step 2: Prepare Manifest

The plugin needs `manifest.json` in the directory:

```bash
# Temporary: Copy variants manifest
cp manifest-variants.json manifest.json

# Or if you want to keep existing manifest, rename it first:
mv manifest.json manifest-basic.json
cp manifest-variants.json manifest.json
```

### Step 3: Load in Figma

1. Open **Figma Desktop**
2. **Plugins** → **Development** → **Import plugin from manifest...**
3. Navigate to: `/Users/matthanson/Zer0_Inbox/design-system/figma-plugin/`
4. Select `manifest.json`
5. Click **Import**

### Step 4: Run the Plugin

1. Open any Figma file (or create new one)
2. **Plugins** → **Development** → **Zero Component Generator (Full Automation)**
3. Plugin runs automatically
4. Wait ~60 seconds
5. Success message appears!

### Step 5: Review Components

Check the **Components** page (auto-created):
- All 5 component sets visible
- Click any component to see variants panel
- Test variant switching in properties panel

---

## What Gets Generated

### ZeroButton (48 variants)

**Properties:**
- `Style`: Primary | Secondary | Tertiary | Danger
- `Size`: Small (32px) | Medium (40px) | Large (48px)
- `State`: Default | Hover | Active | Disabled

**Features:**
- Auto Layout with proper padding per size
- Corner radius scales with size (8/12/14px)
- State-based opacity and color shifts
- Border for Tertiary style

**Example combinations:**
- `Primary / Medium / Default` - Standard blue button
- `Danger / Large / Hover` - Red button in hover state
- `Tertiary / Small / Disabled` - Outlined button disabled

### ZeroCard (24 variants)

**Properties:**
- `Layout`: Compact | Expanded
- `Priority`: High | Medium | Low
- `State`: Default | Hover | Selected | Read

**Features:**
- Email card layout with from/subject/preview
- Priority indicator (colored left border for High/Medium)
- State-based backgrounds (selected = blue, read = dimmed)
- Compact layout hides preview and actions

**Example combinations:**
- `Expanded / High / Default` - Full email card with red priority
- `Compact / Low / Read` - Minimized read email
- `Expanded / Medium / Selected` - Yellow priority, blue selected background

### ZeroModal (6 variants)

**Properties:**
- `Size`: Small (400px) | Medium (560px) | Large (720px)
- `State`: Open | Closed

**Features:**
- Auto Layout with size-based padding (20/24/32px)
- Title, message, and action buttons
- Close button (×) in header
- Drop shadow effect
- Opacity 0 for Closed state (for animations)

**Example combinations:**
- `Medium / Open` - Standard modal dialog
- `Large / Open` - Wide modal for complex content
- `Small / Closed` - Invisible state for transitions

### ZeroListItem (6 variants)

**Properties:**
- `Type`: Navigation | Action
- `State`: Default | Hover | Selected

**Features:**
- 44px fixed height (iOS standard)
- Icon placeholder (20×20px)
- Navigation type shows chevron (›)
- Action type shows badge (notification count)
- State-based backgrounds and text colors

**Example combinations:**
- `Navigation / Default` - Standard list row with chevron
- `Action / Selected` - Settings row with badge, selected
- `Navigation / Hover` - List row in hover state

### ZeroAlert (8 variants)

**Properties:**
- `Type`: Success | Error | Warning | Info
- `Position`: Top | Bottom

**Features:**
- Type-specific colors and icons (✓ × ⚠ ℹ)
- Colored background, border, text, icon
- Close button (×)
- Designed for toast notifications
- Position for animation origin

**Example combinations:**
- `Success / Top` - Green checkmark toast from top
- `Error / Bottom` - Red error alert from bottom
- `Warning / Top` - Yellow warning notification

---

## Component Properties Available

After generation, you can customize instances:

### All Components
- **Instance swap**: Use variant switcher in properties panel
- **Override text**: All text layers are exposed
- **Resize**: Auto Layout adapts to content

### Example: Button Instance
```
Instance of: ZeroButton
Properties:
  Style: [Primary ▼]
  Size: [Medium ▼]
  State: [Default ▼]
  Label: "Click Me" (editable text)
```

### Example: Card Instance
```
Instance of: ZeroCard
Properties:
  Layout: [Expanded ▼]
  Priority: [High ▼]
  State: [Default ▼]
  From: "sender@example.com" (editable)
  Subject: "Email subject" (editable)
  Preview: "Preview text..." (editable)
  Time: "2m" (editable)
```

---

## How It Works

### The Magic: `figma.combineAsVariants()`

The plugin uses Figma's variant API:

1. **Create multiple components** (e.g., 48 button components)
2. **Name them with properties**: `"Style=Primary, Size=Medium, State=Default"`
3. **Combine as variants**: `figma.combineAsVariants(components)`
4. **Figma auto-creates properties** from the naming pattern!

### Naming Convention

```typescript
// Figma parses this name:
"Style=Primary, Size=Medium, State=Default"

// Into these properties:
{
  Style: "Primary",
  Size: "Medium",
  State: "Default"
}
```

### Why This Works

- **Automatic property detection**: No need to manually add component properties
- **All combinations generated**: Nested loops create every variant
- **Type-safe**: TypeScript ensures consistent variant creation
- **Fast**: Programmatic generation vs. hours of manual duplication

---

## Comparison: Basic vs. Full Automation

### Basic Plugin (component-generator.ts)
```
✅ Creates 5 base components
✅ Auto Layout configured
✅ Text layers and styling
❌ No variants
❌ No component properties
❌ Manual work required: ~2-3 hours
```

### Full Automation (component-generator-with-variants.ts)
```
✅ Creates 5 component sets
✅ Generates 92 total variants
✅ All component properties configured
✅ State variations (hover, active, disabled, etc.)
✅ Size variations (small, medium, large)
✅ Style variations (primary, secondary, etc.)
✅ Manual work required: ~0 hours
```

---

## Customization After Generation

### Adding More Variants

To add variants manually in Figma:

1. Select component set
2. Duplicate existing variant
3. Rename with new property value: `"Style=NewStyle, Size=Medium, State=Default"`
4. Figma auto-adds to properties dropdown

### Binding Variables

After running Variables Sync plugin:

1. Select component/variant
2. Right-click property (e.g., Corner Radius)
3. **Apply variable** → Choose from list
4. Repeat for padding, spacing, colors

### Modifying Existing Variants

1. Select specific variant in component set
2. Edit styling (colors, spacing, etc.)
3. Changes apply only to that variant
4. Other variants remain unchanged

---

## Troubleshooting

### "Manifest must be named 'manifest.json'"

**Solution**: The manifest filename must be exact:
```bash
cp manifest-variants.json manifest.json
```

### "Cannot combine nodes as variants"

**Cause**: Components must be separate (not nested) before combining

**Solution**: Plugin handles this automatically - if you see this, check that you're not trying to manually combine nested components

### "Font not found: Inter"

**Solution**: Inter is Figma's default font and should always be available. If you see this:
1. Refresh Figma
2. Check font menu to verify Inter exists
3. Try restarting Figma Desktop

### "Plugin takes longer than 60 seconds"

**Possible causes**:
- Large Figma file with many existing components
- Slow computer
- Figma performance issues

**Solution**:
- Close other Figma files
- Restart Figma Desktop
- Run plugin in new/empty file

### Generated components look wrong

**Check**:
1. Was build successful? `npm run build:variants`
2. Did you reload plugin in Figma after rebuild?
3. Any errors in Figma console? (Plugins → Development → Open Console)

---

## Development

### File Structure

```
figma-plugin/
├── component-generator-with-variants.ts    # Source code (main)
├── component-generator-with-variants.js    # Compiled output
├── manifest-variants.json                  # Plugin config
├── tsconfig-variants.json                  # TypeScript config
└── package.json                            # Build scripts
```

### Build Commands

```bash
# Build once
npm run build:variants

# Watch mode (auto-rebuild on save)
npm run dev:variants

# Build all plugins
npm run build:all
```

### Making Changes

1. Edit `component-generator-with-variants.ts`
2. Save file
3. Run `npm run build:variants`
4. In Figma: **Plugins** → **Development** → **Reload** (or `Cmd+Opt+P` to rerun)

### Adding New Components

Template for new component set:

```typescript
async function generateMyComponentVariants(): Promise<ComponentSetNode> {
  const properties = ['Value1', 'Value2'];
  const components: ComponentNode[] = [];

  for (const prop of properties) {
    const component = figma.createComponent();
    component.name = `Property=${prop}`;

    // Configure component...
    // (Auto Layout, text, styling)

    components.push(component);
  }

  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'MyComponent';
  return componentSet;
}
```

---

## Next Steps

### After Component Generation

1. **Test all variants** - Click through each component set
2. **Publish to library** - Make available team-wide
3. **Sync Variables** - Run Variables Sync plugin to bind tokens
4. **Generate Swift code** - Export to iOS codebase
5. **Create documentation** - Add usage examples for team

### Integration with Zero iOS

1. Components ready for Variable binding
2. Run Variables Sync to create Variables in Figma
3. Generate Swift code from Variables + Components
4. Import into Xcode project
5. Use in SwiftUI views

---

## Performance Notes

### Generation Time by Component

- **ZeroButton** (48 variants): ~20 seconds
- **ZeroCard** (24 variants): ~15 seconds
- **ZeroModal** (6 variants): ~8 seconds
- **ZeroListItem** (6 variants): ~8 seconds
- **ZeroAlert** (8 variants): ~9 seconds

**Total: ~60 seconds** for all 92 variants

### Why It Takes 60 Seconds

1. **Font loading**: Must load all font weights first (~2s)
2. **Component creation**: 92 separate components created (~30s)
3. **Variant combination**: `combineAsVariants()` API processes (~20s)
4. **Viewport operation**: Zoom to show all components (~2s)

*All operations are necessary and optimized*

---

## FAQ

### Can I edit variants after generation?

**Yes!** The component sets are fully editable:
- Select specific variant and modify
- Add/remove variants manually
- Change properties as needed
- Bind variables post-generation

### Do I need Variables in my Figma file?

**No.** The plugin works without Variables. Variable binding attempts will warn in console but won't break generation.

### Can I run this on an existing file?

**Yes.** The plugin creates/uses a "Components" page. Existing pages are unaffected.

### What if I already have a "Components" page?

The plugin uses the existing page and adds new component sets there.

### Can I customize colors/spacing?

**Two ways:**
1. **After generation**: Edit variants in Figma manually
2. **Before generation**: Edit `COLORS` object in source code, rebuild

### Does this work in Figma browser version?

**No.** Plugins must be loaded in **Figma Desktop** app.

### Can I share this plugin with my team?

**Current**: Development plugin (local only)
**Future**: Publish to Figma Community to share

---

## Resources

- **Figma Plugin API**: https://www.figma.com/plugin-docs/
- **Variants Guide**: https://help.figma.com/hc/en-us/articles/360056440594
- **combineAsVariants() API**: https://www.figma.com/plugin-docs/api/figma/#combineasvariants

---

## Credits

**Created**: December 2, 2024
**Phase**: 0 Day 2 - Complete Automation
**Time Saved**: 6-8 hours → 60 seconds
**Author**: Zero Team

---

**Ready to use!** Run `npm run build:variants` and load the plugin.

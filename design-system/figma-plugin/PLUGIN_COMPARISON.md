# Figma Plugin Options - Comparison Guide

**Choose the right plugin for your workflow**

---

## Two Plugin Options

### Option 1: Basic Component Generator
**File**: `component-generator.ts` → `component-generator.js`
**Manifest**: `manifest-component-generator.json`

### Option 2: Full Automation with Variants
**File**: `component-generator-with-variants.ts` → `component-generator-with-variants.js`
**Manifest**: `manifest-variants.json`

---

## Feature Comparison

| Feature | Basic Generator | Full Automation |
|---------|----------------|-----------------|
| **Creates base components** | ✅ Yes (5 components) | ✅ Yes (5 components) |
| **Auto Layout configured** | ✅ Yes | ✅ Yes |
| **Text layers with fonts** | ✅ Yes | ✅ Yes |
| **Basic styling** | ✅ Yes | ✅ Yes |
| **Creates component sets** | ❌ No | ✅ Yes |
| **Generates all variants** | ❌ No (manual) | ✅ Yes (92 variants) |
| **Component properties** | ❌ No (manual) | ✅ Yes (auto-created) |
| **State variations** | ❌ No (manual) | ✅ Yes (hover, active, etc.) |
| **Size variations** | ❌ No (manual) | ✅ Yes (S/M/L) |
| **Style variations** | ❌ No (manual) | ✅ Yes (primary, danger, etc.) |
| **Execution time** | ~30 seconds | ~60 seconds |
| **Manual work after** | 2-3 hours | ~0 hours |
| **Total time** | ~2.5 hours | ~1 minute |

---

## Time Investment

### Option 1: Basic Generator
```
Plugin execution:     30 seconds
Manual variant work:  2-3 hours
─────────────────────────────
TOTAL:                2-3 hours
```

**Best for:**
- Learning how components are structured
- Custom variant configurations not covered by automation
- Iterative design exploration
- Files where you only need base components

### Option 2: Full Automation
```
Plugin execution:     60 seconds
Manual work:          0 hours
─────────────────────────────
TOTAL:                1 minute
```

**Best for:**
- Rapid prototyping
- Production-ready components immediately
- Consistent implementation across files
- Maximum time efficiency

---

## Variant Coverage

### Basic Generator Output

**ZeroButton**
- ✅ 1 base component
- ❌ You manually add: 48 variants (4 styles × 3 sizes × 4 states)

**ZeroCard**
- ✅ 1 base component
- ❌ You manually add: 24 variants (2 layouts × 3 priorities × 4 states)

**ZeroModal**
- ✅ 1 base component
- ❌ You manually add: 6 variants (3 sizes × 2 states)

**ZeroListItem**
- ✅ 1 base component
- ❌ You manually add: 6 variants (2 types × 3 states)

**ZeroAlert**
- ✅ 1 base component
- ❌ You manually add: 8 variants (4 types × 2 positions)

**Manual work required**: Follow `MANUAL_VARIANT_SETUP_GUIDE.md`

### Full Automation Output

**ZeroButton**
- ✅ Component set with 48 variants ready to use
- ✅ Properties: Style, Size, State
- ✅ All combinations generated

**ZeroCard**
- ✅ Component set with 24 variants ready to use
- ✅ Properties: Layout, Priority, State
- ✅ All combinations generated

**ZeroModal**
- ✅ Component set with 6 variants ready to use
- ✅ Properties: Size, State
- ✅ All combinations generated

**ZeroListItem**
- ✅ Component set with 6 variants ready to use
- ✅ Properties: Type, State
- ✅ All combinations generated

**ZeroAlert**
- ✅ Component set with 8 variants ready to use
- ✅ Properties: Type, Position
- ✅ All combinations generated

**Manual work required**: None (optional customization only)

---

## How to Choose

### Choose Basic Generator if:
- 🎓 You want to understand Figma component structure deeply
- 🎨 You prefer granular control over every variant
- 🔧 You're experimenting with different variant configurations
- ⏰ You have 2-3 hours available for manual setup
- 📚 You're following the manual setup guide as a learning exercise

### Choose Full Automation if:
- ⚡ You need components ready immediately
- 🚀 You're setting up production design system
- 🎯 You want maximum efficiency (1 min vs. 2-3 hours)
- ✅ The generated variants match your requirements
- 🔄 You're generating components for multiple projects

---

## Usage Instructions

### Using Basic Generator

1. **Build**:
   ```bash
   npm run build:generator
   ```

2. **Load in Figma**:
   - Copy manifest: `cp manifest-component-generator.json manifest.json`
   - Plugins → Development → Import plugin from manifest
   - Select `manifest.json`

3. **Run plugin** - generates 5 base components

4. **Follow manual guide**: `MANUAL_VARIANT_SETUP_GUIDE.md`

### Using Full Automation

1. **Build**:
   ```bash
   npm run build:variants
   ```

2. **Load in Figma**:
   - Copy manifest: `cp manifest-variants.json manifest.json`
   - Plugins → Development → Import plugin from manifest
   - Select `manifest.json`

3. **Run plugin** - generates 5 component sets with 92 variants

4. **Done!** No manual work required

---

## Can I Switch Between Them?

**Yes!** The plugins are completely independent.

### Switching from Basic → Full Automation

1. Build the variants version: `npm run build:variants`
2. Copy manifest: `cp manifest-variants.json manifest.json`
3. Reload plugin in Figma
4. Run the plugin in a new/different file

**Note**: Both versions can be loaded as separate plugins if you use different directories.

### Switching from Full Automation → Basic

1. Build the basic version: `npm run build:generator`
2. Copy manifest: `cp manifest-component-generator.json manifest.json`
3. Reload plugin in Figma
4. Run in a new file

---

## Side-by-Side: Component Output

### ZeroButton - Basic Generator
```
Created:
└─ ZeroButton (Component)
   ├─ Label (Text)
   └─ [Basic styling applied]

You create manually:
├─ Convert to ComponentSet
├─ Add 48 variants
├─ Add properties (Style, Size, State)
└─ Configure each variant's styling
```

### ZeroButton - Full Automation
```
Created:
└─ ZeroButton (ComponentSet)
   ├─ Style=Primary, Size=Small, State=Default
   ├─ Style=Primary, Size=Small, State=Hover
   ├─ Style=Primary, Size=Small, State=Active
   ├─ Style=Primary, Size=Small, State=Disabled
   ├─ Style=Primary, Size=Medium, State=Default
   ├─ ... (48 total variants)
   └─ Properties: Style, Size, State [auto-created]

No manual work needed!
```

---

## Performance Comparison

| Metric | Basic Generator | Full Automation |
|--------|-----------------|-----------------|
| **Plugin execution** | 30 seconds | 60 seconds |
| **Components created** | 5 base | 5 component sets |
| **Variants created** | 0 | 92 |
| **Memory usage** | Low | Medium |
| **File size impact** | ~50 KB | ~500 KB |
| **Manual setup time** | 2-3 hours | 0 hours |
| **Total time to production** | 2.5-3 hours | 1 minute |

---

## Troubleshooting

### "Which plugin am I running?"

Check Figma's plugin menu:
- **"Zero Component Generator"** = Basic version
- **"Zero Component Generator (Full Automation)"** = Variants version

### "I want to run both plugins"

Create separate directories:

```bash
# Create directory for each plugin
mkdir -p ../figma-plugin-basic
mkdir -p ../figma-plugin-variants

# Copy basic generator files
cp component-generator.* ../figma-plugin-basic/
cp manifest-component-generator.json ../figma-plugin-basic/manifest.json

# Copy variants generator files
cp component-generator-with-variants.* ../figma-plugin-variants/
cp manifest-variants.json ../figma-plugin-variants/manifest.json

# Copy package.json to both
cp package.json ../figma-plugin-basic/
cp package.json ../figma-plugin-variants/
```

Then load each separately in Figma.

### "Build failed"

Check which version you're building:
```bash
npm run build:generator  # Basic version
npm run build:variants   # Full automation
npm run build:all        # Both versions
```

### "Wrong components generated"

You might be running the wrong plugin:
1. Check plugin name in Figma menu
2. Verify manifest.json points to correct files:
   - Basic: `"main": "component-generator.js"`
   - Variants: `"main": "component-generator-with-variants.js"`

---

## Recommendation

### For Phase 0 Day 2 (Zero iOS Design System)

**Use Full Automation** ✅

**Why:**
- Production timeline requires speed
- Consistent implementation across design system
- All 92 variants follow design specs exactly
- Zero iOS app needs complete component coverage
- Saves 2-3 hours of manual work

**When to use Basic:**
- During Phase 1+ when iterating on new component types
- When exploring experimental designs
- When teaching team members about Figma components

---

## Quick Reference

### Build Commands

```bash
# Basic generator
npm run build:generator       # Build once
npm run dev:generator         # Watch mode

# Full automation
npm run build:variants        # Build once
npm run dev:variants          # Watch mode

# All plugins
npm run build:all            # Build everything
```

### Load in Figma

```bash
# For basic generator
cp manifest-component-generator.json manifest.json

# For full automation
cp manifest-variants.json manifest.json
```

Then: Figma → Plugins → Development → Import plugin from manifest

---

## Files Reference

### Basic Generator
- Source: `component-generator.ts`
- Compiled: `component-generator.js`
- Manifest: `manifest-component-generator.json`
- Config: `tsconfig-component-generator.json`
- Docs: `COMPONENT_GENERATOR_README.md`
- Guide: `MANUAL_VARIANT_SETUP_GUIDE.md`

### Full Automation
- Source: `component-generator-with-variants.ts`
- Compiled: `component-generator-with-variants.js`
- Manifest: `manifest-variants.json`
- Config: `tsconfig-variants.json`
- Docs: `FULL_AUTOMATION_README.md`

### Shared
- Build config: `package.json`
- Dependencies: `node_modules/`
- Lessons learned: `FIGMA_PLUGIN_LESSONS.md`

---

**Bottom Line**: Use **Full Automation** for production. Use **Basic Generator** for learning.

**Time savings**: 2-3 hours → 1 minute with full automation 🚀

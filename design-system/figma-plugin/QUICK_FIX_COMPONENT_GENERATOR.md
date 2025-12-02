# Quick Fix: Load Component Generator Plugin

**Problem:** Figma requires manifest to be named exactly `manifest.json`

**Current file:** `manifest-component-generator.json` ❌

---

## Solution: Temporarily Rename Manifest

### Steps to Load Plugin

1. **Rename the manifest temporarily:**

```bash
cd /Users/matthanson/Zer0_Inbox/design-system/figma-plugin

# Backup existing manifest (if you have one)
mv manifest.json manifest-old.json

# Rename component generator manifest
cp manifest-component-generator.json manifest.json
```

2. **Load in Figma:**
   - Open Figma Desktop
   - **Plugins** → **Development** → **Import plugin from manifest...**
   - Navigate to: `/Users/matthanson/Zer0_Inbox/design-system/figma-plugin/`
   - Select `manifest.json`
   - ✅ Plugin loads successfully!

3. **Restore manifests:**

```bash
# After loading, restore original manifest
mv manifest-old.json manifest.json
```

---

## Alternative: Separate Directory (Better for Long-term)

Create dedicated directory:

```bash
cd /Users/matthanson/Zer0_Inbox/design-system

# Create new directory
mkdir -p figma-plugin-component-generator

# Copy files
cp figma-plugin/component-generator.ts figma-plugin-component-generator/code.ts
cp figma-plugin/component-generator.js figma-plugin-component-generator/code.js
cp figma-plugin/component-generator-ui.html figma-plugin-component-generator/ui.html
cp figma-plugin/manifest-component-generator.json figma-plugin-component-generator/manifest.json
cp figma-plugin/tsconfig-component-generator.json figma-plugin-component-generator/tsconfig.json
cp figma-plugin/COMPONENT_GENERATOR_README.md figma-plugin-component-generator/README.md

# Copy package.json and node_modules (for building)
cp figma-plugin/package.json figma-plugin-component-generator/
cp -r figma-plugin/node_modules figma-plugin-component-generator/
```

Then load from new directory:
- Figma → Import plugin from manifest
- Select: `/Users/matthanson/Zer0_Inbox/design-system/figma-plugin-component-generator/manifest.json`

---

## Quick Reference

**Current Working Files:**
- Plugin code: `design-system/figma-plugin/component-generator.js` ✅
- UI: `design-system/figma-plugin/component-generator-ui.html` ✅
- Manifest: `design-system/figma-plugin/manifest-component-generator.json` ❌ (wrong name)

**What Figma Needs:**
- Manifest must be: `manifest.json` (exact name)
- Must reference correct files:
  - `"main": "component-generator.js"`
  - `"ui": "component-generator-ui.html"`

**Fastest Fix:**
```bash
cd /Users/matthanson/Zer0_Inbox/design-system/figma-plugin
cp manifest-component-generator.json manifest.json
# Now import manifest.json in Figma
```

---

## For Future Plugins

Always structure like this:

```
figma-plugin-[name]/
├── manifest.json          ← Must be this exact name!
├── code.ts
├── code.js (compiled)
├── ui.html
├── tsconfig.json
├── package.json
└── README.md
```

Then Figma can import `manifest.json` directly without conflicts.

# Figma Plugin Development - Lessons Learned

**Document Purpose:** Track gotchas and learnings for future Figma plugin development

---

## Critical Constraints

### 1. Manifest File Name

**❌ ERROR:**
```
Uncaught (in promise) Error: Error invoking remote method 'web:createMultipleNewLocalFileExtensions':
Error: Manifest must be named 'manifest.json'
```

**RULE:** Figma requires the manifest file to be named **exactly** `manifest.json`

**What Doesn't Work:**
- ❌ `manifest-component-generator.json`
- ❌ `manifest-sync.json`
- ❌ `component-manifest.json`
- ❌ Any name other than `manifest.json`

**What Works:**
- ✅ `manifest.json` (only this name)

**Solution for Multiple Plugins:**

Use separate directories for each plugin:

```
design-system/
├── figma-plugin-sync/
│   ├── manifest.json          ← Sync plugin
│   ├── code.ts
│   └── ui.html
├── figma-plugin-generator/
│   ├── manifest.json          ← Generator plugin
│   ├── code.ts
│   └── ui.html
└── figma-plugin-[name]/
    ├── manifest.json          ← Each plugin has its own dir
    ├── code.ts
    └── ui.html
```

**Best Practice:**
- One plugin = One directory with `manifest.json`
- Import each plugin separately in Figma
- Manage plugins independently

---

## Other Known Constraints

### 2. Effect Types (Background Blur)

**Issue:** TypeScript types for `Effect` are strict and don't allow partial objects

**Error:**
```typescript
modal.effects = [{
  type: 'BACKGROUND_BLUR',
  radius: 20,
  visible: true
}];
// ❌ Type error: missing blurType, startRadius, startOffset, endOffset
```

**Workaround:**
- Use type assertion: `as Effect`
- Or skip blur and add manually in Figma UI
- Or use full object with all required properties

**What We Did:**
```typescript
// Removed blur effect from code generator
// Add comment: "TODO: Add background blur manually (20px)"
```

---

## Development Workflow

### Building Multiple Plugins

**package.json scripts pattern:**

```json
{
  "scripts": {
    "build": "tsc",
    "build:sync": "tsc --project tsconfig-sync.json",
    "build:generator": "tsc --project tsconfig-component-generator.json",
    "build:all": "npm run build && npm run build:sync && npm run build:generator",
    "dev": "tsc --watch",
    "dev:sync": "tsc --project tsconfig-sync.json --watch",
    "dev:generator": "tsc --project tsconfig-component-generator.json --watch"
  }
}
```

### Loading Plugins in Figma

**Steps:**
1. Build plugin: `npm run build:generator`
2. Figma Desktop → **Plugins** → **Development** → **Import plugin from manifest...**
3. Navigate to plugin directory
4. Select `manifest.json` (must be this exact name!)
5. Plugin appears in menu

**Reloading After Changes:**
1. Rebuild: `npm run build:generator`
2. Figma → **Plugins** → **Development** → **Reload** (or use keyboard shortcut)

---

## API Gotchas

### 3. Font Loading

Fonts must be loaded asynchronously before use:

```typescript
// ❌ This will fail:
text.fontName = { family: 'SF Pro Display', style: 'Bold' };

// ✅ This works:
await figma.loadFontAsync({ family: 'SF Pro Display', style: 'Bold' });
text.fontName = { family: 'SF Pro Display', style: 'Bold' };
```

**Best Practice:** Load all needed font weights at plugin start

### 4. Variable Binding

Variable binding API is not fully typed. Use caution:

```typescript
// Current approach (works but not type-safe):
function bindNumberVariable(node: SceneNode, property: string, variableName: string) {
  const variable = findVariable(variableName);
  if (!variable) return;

  // @ts-ignore - Figma API types incomplete
  if (node.boundVariables) {
    // @ts-ignore
    node.boundVariables[property] = {
      type: 'VARIABLE_ALIAS',
      id: variable.id
    };
  }
}
```

**Note:** Variable binding may not work for all node types. Test thoroughly.

### 5. Component Properties

Add properties to components (not frames):

```typescript
// ✅ Works:
const component = figma.createComponent();
component.addComponentProperty('Style', 'VARIANT', 'Primary');

// ❌ Doesn't work:
const frame = figma.createFrame();
frame.addComponentProperty('Style', 'VARIANT', 'Primary'); // Error!
```

---

## Performance Tips

### 6. Batch Operations

Create nodes in memory first, then append to tree:

```typescript
// ✅ Faster:
const frame = createAutoLayoutFrame('Name', 'HORIZONTAL', 16, 8);
const child1 = createText('Label', 15);
const child2 = createIcon(20);
frame.appendChild(child1);
frame.appendChild(child2);
figma.currentPage.appendChild(frame);

// ❌ Slower:
figma.currentPage.appendChild(frame);
frame.appendChild(child1); // Multiple tree updates
frame.appendChild(child2);
```

### 7. Viewport Operations

Do viewport operations last:

```typescript
// Create all components first
const components = [button, card, modal, listItem, alert];

// Then zoom at the end
figma.viewport.scrollAndZoomIntoView(components);
```

---

## UI/UX Best Practices

### 8. Plugin UI Dimensions

Specify UI size in `figma.showUI()`:

```typescript
figma.showUI(__html__, {
  width: 300,   // Reasonable width
  height: 400   // Reasonable height
});
```

**Guidelines:**
- Width: 280-400px (fits well in Figma side panel)
- Height: 300-600px (depends on content)
- Use scrolling for long content

### 9. User Feedback

Always close plugin with status message:

```typescript
// ✅ Good:
figma.closePlugin('✅ Generated 5 components!\n\nCheck the Components page.');

// ❌ Less helpful:
figma.closePlugin('Done');
```

**Format:**
- Emoji for visual feedback (✅ ❌ ⚠️)
- Clear success/error indication
- Next steps if applicable

---

## Directory Structure Recommendation

**For Future Plugins:**

```
design-system/
├── figma-plugins/                    # Parent directory
│   ├── sync/                         # Each plugin in own folder
│   │   ├── manifest.json
│   │   ├── code.ts
│   │   ├── code.js (compiled)
│   │   ├── ui.html
│   │   ├── tsconfig.json
│   │   └── README.md
│   ├── component-generator/
│   │   ├── manifest.json
│   │   ├── code.ts
│   │   ├── code.js (compiled)
│   │   ├── ui.html
│   │   ├── tsconfig.json
│   │   └── README.md
│   ├── [future-plugin]/
│   │   └── manifest.json
│   └── shared/                       # Shared utilities
│       ├── helpers.ts
│       └── types.ts
├── package.json                      # Shared dependencies
└── README.md
```

**Benefits:**
- Each plugin is self-contained
- `manifest.json` in correct location
- Easy to import/manage plugins independently
- Shared code in `shared/` directory

---

## Testing Checklist

Before releasing a plugin:

- [ ] Build succeeds without errors
- [ ] TypeScript strict mode enabled
- [ ] Plugin loads in Figma without errors
- [ ] All features work as expected
- [ ] Error handling for edge cases
- [ ] User feedback messages clear
- [ ] README with installation instructions
- [ ] Prerequisites documented (Variables, fonts, etc.)
- [ ] Tested on different file structures
- [ ] Tested with missing prerequisites (graceful failures)

---

## Resources

- [Figma Plugin API Docs](https://www.figma.com/plugin-docs/)
- [Figma Community Forums](https://forum.figma.com/c/plugin-api/)
- [@figma/plugin-typings on npm](https://www.npmjs.com/package/@figma/plugin-typings)

---

**Last Updated:** December 2, 2024
**Phase 0 Day 2:** Component Generator Plugin Development

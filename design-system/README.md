# Zero Design System

**Single source of truth for design tokens, components, and styles**

## 📁 Structure

```
design-system/
├── sync/                     # NEW: Token sync automation
│   ├── export-from-figma.js # Export from Figma API
│   ├── generate-swift.js    # Generate iOS tokens
│   ├── generate-web.js      # Generate Web tokens
│   ├── sync-all.js          # Master sync script
│   └── design-tokens.json   # Exported tokens (generated)
├── generated/                # Generated code outputs
│   ├── DesignTokens.swift   # iOS tokens (generated)
│   ├── design-tokens.css    # Web CSS variables (generated)
│   └── design-tokens.js     # Web JS module (generated)
├── tokens.json              # Manual design tokens
├── figma-plugin/            # Figma plugin (alternative approach)
│   ├── manifest.json        # Plugin configuration
│   ├── code.ts              # Plugin logic (TypeScript)
│   ├── ui.html              # Plugin UI
│   ├── package.json         # Dependencies
│   └── tsconfig.json        # TypeScript config
└── README.md                # This file
```

## 🚀 NEW: Automated Token Sync (Recommended)

### Quick Start

Sync design tokens from Figma to iOS and Web automatically:

```bash
cd design-system/sync
node sync-all.js
```

This runs the complete workflow:
1. **Export from Figma** → `design-tokens.json`
2. **Generate Swift** → `DesignTokens.swift` (iOS)
3. **Generate Web** → `design-tokens.css` + `design-tokens.js`

### Setup

1. **Set Figma token**:
   ```bash
   export FIGMA_ACCESS_TOKEN="your_figma_token_here"
   ```

2. **Run sync**:
   ```bash
   cd design-system/sync
   node sync-all.js
   ```

3. **Use generated tokens**:
   - **iOS**: Copy `generated/DesignTokens.swift` to Xcode project
   - **Web**: Import `generated/design-tokens.css` in your HTML

### What Gets Synced

✅ **From Figma:**
- Colors (base, semantic, gradients)
- Spacing scale (4px grid)
- Border radius tokens
- Typography scale
- Opacity values

❌ **Not in Figma (added automatically):**
- Shadow presets
- Animation durations

See full documentation: [Token Sync README](sync/README.md)

---

## 🎨 Design Tokens

The `tokens.json` file contains all design decisions:

- **Colors**: Primary, semantic, opacity values
- **Typography**: Font sizes, weights, line heights
- **Spacing**: Consistent spacing scale (4px grid)
- **Sizing**: Touch targets, icons, component dimensions
- **Border Radius**: Corner radii for all components
- **Animation**: Duration and easing functions
- **Components**: Complete component specifications
- **Action Priorities**: Priority levels with colors

## 🔧 Figma Plugin Setup

### Installation

1. **Navigate to plugin directory:**
   ```bash
   cd design-system/figma-plugin
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Build the plugin:**
   ```bash
   npm run build
   ```
   This compiles `code.ts` → `code.js`

4. **Load in Figma:**
   - Open Figma Desktop App
   - Go to: Plugins → Development → Import plugin from manifest
   - Select `manifest.json` from `figma-plugin/` directory

### Usage

Once installed, access the plugin:

1. **In Figma:** Plugins → Development → Zero Design System Sync
2. **Choose an option:**
   - **🚀 Sync All** - Generate everything (recommended first run)
   - **🎨 Update Colors** - Sync color styles only
   - **📝 Update Typography** - Sync text styles only
   - **🧩 Generate Components** - Generate toast, buttons, etc.

### What Gets Generated

**Color Styles:**
- `Colors/Primary/White`
- `Colors/Primary/Black`
- `Colors/Semantic/Success`
- `Colors/Semantic/Error`
- `Colors/Priority/Critical` (with priority value in description)
- ...and more

**Text Styles:**
- `Text/BASE/Regular` (15px SF Pro Regular)
- `Text/BASE/Medium` (15px SF Pro Medium)
- `Text/SM/Medium` (13px for countdown)
- ...all size/weight combinations

**Components:**
- **Toast/Undo** - Complete undo toast with progress bar
- **Progress Bar** variants
- **Action Priority Chips** - Visual priority levels
- **Modal Template** - Full modal with backdrop and container
- **Action Buttons** - Primary, Secondary, Destructive variants
- **Action Cards** - Cards with icon, title, description, and priority badge
- **Input Fields** - Default and focused states

## 🔄 Workflow: SwiftUI ↔ Figma

### Updating Tokens

1. **Update SwiftUI code** with new colors/sizes
2. **Extract to tokens.json:**
   ```bash
   # Run token extractor (TODO: Create script)
   node extract-tokens-from-swift.js
   ```
3. **Sync to Figma:**
   - Open Figma
   - Run plugin: "Sync All"
   - Components update automatically

### Updating from Figma

1. **Design in Figma** using generated components
2. **Export updated tokens:**
   - Use Figma's Variables API
   - Or manually update tokens.json
3. **Update SwiftUI:**
   ```swift
   // Use token values
   .foregroundColor(Color.white.opacity(0.6)) // from tokens.colors.opacity.medium
   ```

## 📖 Token Reference

### Color Opacity Scale

| Token | Value | Usage |
|-------|-------|-------|
| `opacity.high` | 0.92 | Toast backgrounds |
| `opacity.medium` | 0.6 | Secondary text |
| `opacity.mediumLow` | 0.4 | Ring indicators |
| `opacity.low` | 0.3 | Progress bars |
| `opacity.veryLow` | 0.1 | Background tracks |

### Spacing Scale (4px grid)

| Token | Value | Usage |
|-------|-------|-------|
| `spacing.1` | 4px | Tight spacing |
| `spacing.2` | 8px | Icon to text |
| `spacing.3` | 12px | Vertical padding |
| `spacing.4` | 16px | Horizontal padding |
| `spacing.5` | 20px | Container padding |
| `spacing.6` | 24px | Bottom spacing (toast) |
| `spacing.8` | 32px | iPad spacing |

### Action Priorities

| Priority | Value | Color | Usage |
|----------|-------|-------|-------|
| Critical | 95 | Red | Life-critical, legal, high-stakes |
| Very High | 90 | Orange | Time-sensitive, urgent |
| High | 85 | Yellow | Important but not urgent |
| Medium High | 80 | Green | Useful, moderate impact |
| Medium | 75 | Cyan | Standard actions |
| Medium Low | 70 | Blue | Helpful but not essential |
| Low | 65 | Purple | Nice-to-have |
| Very Low | 60 | Gray | Utility, fallbacks |

## 🚀 Future Enhancements

- [ ] Automated token extraction from SwiftUI
- [ ] Bidirectional sync (Figma → SwiftUI)
- [ ] Component variant generation (all countdown styles)
- [ ] Dark mode support
- [ ] Animation token support in Figma
- [ ] Export to other platforms (Android, Web)

## 🛠 Development

### Adding New Tokens

1. **Update `tokens.json`:**
   ```json
   {
     "colors": {
       "brand": {
         "newColor": {
           "$type": "color",
           "$value": "#FF00FF",
           "description": "New brand color"
         }
       }
     }
   }
   ```

2. **Update plugin `code.ts`:**
   ```typescript
   // Add to createColorStyles()
   Object.entries(tokens.colors.brand).forEach(...)
   ```

3. **Rebuild:** `npm run build`
4. **Reload plugin in Figma**
5. **Run "Sync All"**

### Plugin Architecture

```typescript
// code.ts structure
main(command)           // Entry point
├── createColorStyles() // Generate Figma color styles
├── createTextStyles()  // Generate Figma text styles
├── createToastComponent() // Generate toast component
├── createProgressBarVariants() // Generate progress bars
├── createActionPriorityChips() // Generate priority chips
├── createModalTemplate() // Generate modal with backdrop
├── createActionButtons() // Generate button variants
├── createActionCards() // Generate action card components
└── createInputFields() // Generate input field components
```

## 📝 Notes

- **Font**: Plugin expects SF Pro to be installed in Figma
- **Token References**: Supports `{colors.primary.white}` syntax
- **Opacity**: Applied via Figma's opacity property
- **Measurements**: All px values converted to Figma units

## 🤝 Contributing

When making design changes:

1. Update `tokens.json` first (single source of truth)
2. Run plugin to sync to Figma
3. Update SwiftUI code to match tokens
4. Document changes in this README

---

**Version:** 1.0.0
**Last Updated:** November 7, 2025
**Generated from:** Zero iOS ActionRegistry & UndoToastView

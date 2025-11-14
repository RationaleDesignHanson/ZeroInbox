# Design Token Sync Workflow

Automated pipeline to sync design tokens from Figma to iOS (Swift) and Web (CSS/JS).

## 🔄 Workflow

```
┌─────────────┐
│   FIGMA     │  ← Single Source of Truth
│   File      │     Design System Components page
└──────┬──────┘
       │ Figma REST API
       ▼
┌──────────────────────┐
│ export-from-figma.js │  Extracts tokens from Figma
└──────────┬───────────┘
           │
           ▼
┌────────────────────┐
│ design-tokens.json │  Platform-agnostic format
└────────┬───────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────────┐  ┌────────────┐
│ generate-  │  │ generate-  │  Transform to platform
│ swift.js   │  │ web.js     │
└─────┬──────┘  └─────┬──────┘
      │               │
      ▼               ▼
┌────────────┐  ┌────────────┐
│ Design     │  │ design-    │  Ready to use!
│ Tokens.    │  │ tokens.    │
│ swift      │  │ css + .js  │
└────────────┘  └────────────┘
```

## 🚀 Usage

### Run Full Sync

```bash
cd design-system/sync
node sync-all.js
```

### Run Individual Steps

```bash
# Step 1: Export from Figma
node export-from-figma.js

# Step 2: Generate iOS tokens
node generate-swift.js

# Step 3: Generate Web tokens
node generate-web.js
```

## 📥 export-from-figma.js

Fetches your Figma file via REST API and extracts design tokens.

### What It Extracts

- **Colors**: From color palette frames with solid fills
- **Spacing**: From text nodes matching `0: 0px`, `1: 4px` format
- **Radius**: From text nodes matching `none: 0px`, `base: 8px` format
- **Typography**: From headers like `XS (12px)`, `BASE (15px)`
- **Opacity**: From text nodes matching `low: 0.3` format
- **Gradients**: From archetype sections (Mail, Ads)

### Configuration

```javascript
const FIGMA_TOKEN = process.env.FIGMA_ACCESS_TOKEN || 'figd_...';
const FILE_KEY = process.env.FIGMA_FILE_KEY || 'WuQicPi1wbHXqEcYCQcLfr';
```

### Output

```json
{
  "meta": {
    "version": "1.0.0",
    "source": "Figma",
    "fileKey": "...",
    "exportedAt": "2025-11-09T..."
  },
  "colors": {
    "base": { "white": "#FFFFFF", "black": "#000000" },
    "semantic": { "success": "#34C759", ... }
  },
  "spacing": { "space0": 0, "space1": 4, ... },
  "radius": { "none": 0, "sm": 1, ... },
  "typography": { "xs": { "size": 12, "weights": {...} }, ... },
  "opacity": { "veryLow": 0.1, ... },
  "gradients": { "mail": { "start": "#...", "end": "#..." }, ... }
}
```

## 🍎 generate-swift.js

Converts `design-tokens.json` to Swift code for iOS.

### Output: DesignTokens.swift

```swift
import SwiftUI

enum DesignTokens {
    enum Spacing {
        static let minimal: CGFloat = 4
        static let inline: CGFloat = 8
        // ...
    }

    enum Radius {
        static let button: CGFloat = 12
        static let card: CGFloat = 16
        // ...
    }

    enum Colors {
        static let white = Color(red: 1.0, green: 1.0, blue: 1.0)
        static let successPrimary = Color(hex: "#34C759")
        // ...
    }

    enum Typography {
        static let bodyRegular = Font.system(size: 15, weight: .regular)
        // ...
    }

    enum Opacity {
        static let veryLow: Double = 0.1
        // ...
    }
}

extension Color {
    init(hex: String) { /* ... */ }
}
```

### Usage in iOS

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        Text("Hello")
            .font(DesignTokens.Typography.bodyRegular)
            .foregroundColor(DesignTokens.Colors.white)
            .padding(DesignTokens.Spacing.component)
            .background(DesignTokens.Colors.successPrimary)
            .cornerRadius(DesignTokens.Radius.button)
    }
}
```

## 🌐 generate-web.js

Converts `design-tokens.json` to CSS variables and JavaScript module.

### Output 1: design-tokens.css

```css
:root {
  /* Spacing */
  --spacing-minimal: 4px;
  --spacing-inline: 8px;
  --spacing-component: 16px;

  /* Colors */
  --color-white: #FFFFFF;
  --color-success: #34C759;

  /* Typography */
  --font-size-body: 15px;
  --font-weight-regular: 400;

  /* Border Radius */
  --radius-button: 12px;
  --radius-card: 16px;

  /* Gradients */
  --gradient-mail: linear-gradient(135deg, #667eea, #764ba2);

  /* Shadows */
  --shadow-button: 0 5px 10px rgba(0, 0, 0, 0.2);
}
```

### Output 2: design-tokens.js

```javascript
export const spacing = {
  minimal: 4,
  inline: 8,
  component: 16,
  // ...
};

export const colors = {
  white: '#FFFFFF',
  success: '#34C759',
  // ...
};

export const gradients = {
  mail: { start: '#667eea', end: '#764ba2' }
};

export default designTokens;
```

### Usage in Web (CSS)

```html
<link rel="stylesheet" href="design-tokens.css">

<style>
  .button {
    padding: var(--spacing-component);
    border-radius: var(--radius-button);
    background: var(--gradient-mail);
    box-shadow: var(--shadow-button);
  }
</style>
```

### Usage in Web (JavaScript)

```javascript
import { spacing, colors, gradients } from './design-tokens.js';

const buttonStyle = {
  padding: `${spacing.component}px`,
  borderRadius: `${radius.button}px`,
  background: `linear-gradient(135deg, ${gradients.mail.start}, ${gradients.mail.end})`
};
```

## 🔧 Configuration

### Environment Variables

```bash
# Figma API Token (required)
export FIGMA_ACCESS_TOKEN="figd_..."

# Figma File Key (optional, defaults to Zero Inbox file)
export FIGMA_FILE_KEY="WuQicPi1wbHXqEcYCQcLfr"
```

### File Paths

Edit in each script if needed:

```javascript
// export-from-figma.js
const OUTPUT_FILE = path.join(__dirname, 'design-tokens.json');

// generate-swift.js
const OUTPUT_FILE = path.join(__dirname, '../generated/DesignTokens.swift');

// generate-web.js
const OUTPUT_CSS = path.join(__dirname, '../generated/design-tokens.css');
const OUTPUT_JS = path.join(__dirname, '../generated/design-tokens.js');
```

## 🎨 Figma Requirements

Your Figma file must have a page named **"🎨 Design System Components"** containing:

### 1. Color Palette Section
```
🎨 Color Palette
├── Primary
│   ├── white (frame with #FFFFFF fill)
│   └── black (frame with #000000 fill)
└── Semantic
    ├── success (frame with #34C759 fill)
    └── error (frame with #FF3B30 fill)
```

### 2. Spacing Scale Section
```
📏 Spacing Scale
├── 0: 0px (text node)
├── 1: 4px (text node)
└── 2: 8px (text node)
```

### 3. Border Radius Section
```
🔘 Border Radius
├── none: 0px (text node)
├── base: 8px (text node)
└── lg: 12px (text node)
```

### 4. Typography Section
```
✏️ Typography Specimen
├── XS (12px) (text header)
├── BASE (15px) (text header)
└── LG (17px) (text header)
```

### 5. Opacity Scale
```
Opacity Scale
├── veryLow: 0.1 (text node)
└── medium: 0.6 (text node)
```

### 6. Archetype Gradients
```
🎨 Archetypes
├── Mail (text header)
│   ├── Start: #667eea (text node)
│   └── End: #764ba2 (text node)
└── Ads (text header)
    ├── Start: #16bbaa (text node)
    └── End: #4fd19e (text node)
```

## 🚨 Troubleshooting

### "No Design System page found"

**Problem**: Script can't find the design system page.

**Solution**: Ensure your Figma page name contains "Design System".

### "Invalid Figma data" or 403 Error

**Problem**: Figma API authentication failed.

**Solution**: Check your `FIGMA_ACCESS_TOKEN`:
```bash
curl -H "X-Figma-Token: YOUR_TOKEN" \
  "https://api.figma.com/v1/files/WuQicPi1wbHXqEcYCQcLfr"
```

### Missing Tokens in Output

**Problem**: Some tokens aren't being extracted.

**Solution**:
1. Run `node export-from-figma.js` to see what's extracted
2. Check token naming matches expected format
3. Verify frames/text nodes are in correct sections

### Gradient Color Mismatch

**Problem**: iOS gradients don't match Figma.

**Solution**: See `/Users/matthanson/Zer0_Inbox/DESIGN_SYSTEM_AUDIT.md` for analysis. Update either Figma or iOS to match.

## 📝 Adding Custom Tokens

### 1. Add to Figma

Create properly named frames/text nodes in your Figma file.

### 2. Update Extraction Logic

Edit `export-from-figma.js`:

```javascript
function extractCustomTokens(node, tokens = {}) {
  if (node.name === 'My Custom Section') {
    // Extract your custom tokens
  }
  // ...
}
```

### 3. Update Generators

Edit `generate-swift.js` and `generate-web.js`:

```javascript
function generateCustomTokens(tokens) {
  // Generate code for your custom tokens
}
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/sync-tokens.yml
name: Sync Design Tokens

on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3

      - name: Sync tokens
        env:
          FIGMA_ACCESS_TOKEN: ${{ secrets.FIGMA_TOKEN }}
        run: |
          cd design-system/sync
          node sync-all.js

      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          title: 'chore: sync design tokens from Figma'
          commit-message: 'Update design tokens'
          branch: 'automated/design-tokens'
```

## 🎯 Roadmap

- [ ] Add component extraction (buttons, cards, etc.)
- [ ] Support design token versioning
- [ ] Add Android (Kotlin/XML) generator
- [ ] Implement design token validation
- [ ] Add support for Figma Variables API
- [ ] Create VSCode extension for token preview

## 📚 Resources

- [Figma REST API](https://www.figma.com/developers/api)
- [Design Tokens W3C Spec](https://design-tokens.github.io/community-group/)
- [Style Dictionary](https://amzn.github.io/style-dictionary/)

---

**Questions?** See the main [Design System README](../README.md) or [Design System Audit](../../DESIGN_SYSTEM_AUDIT.md).

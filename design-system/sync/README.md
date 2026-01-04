# Design Token Sync Workflow

Bidirectional pipeline to sync design tokens between Figma, tokens.json, and generated code.

## Architecture

```
FIGMA VARIABLES (Source of Truth)
       │
       │ export-from-figma.js
       ▼
┌─────────────────┐
│  tokens.json    │  ← Central token definition
└────────┬────────┘
         │
    ┌────┴─────────────────┐
    │                      │
    ▼                      ▼
┌────────────────┐  ┌──────────────────────────┐
│ generate-      │  │ figma-plugin/            │
│ swift.js       │  │ generate-tokens-for-     │
│                │  │ plugin.js                │
└───────┬────────┘  └──────────┬───────────────┘
        │                      │
        ▼                      ▼
┌────────────────┐  ┌──────────────────────────┐
│ DesignTokens.  │  │ tokens-for-plugin.ts     │
│ swift          │  │ (used by Figma plugin)   │
└────────────────┘  └──────────────────────────┘
```

## Quick Start

### Full Sync Pipeline

```bash
# From project root
cd design-system/sync
node generate-swift.js   # tokens.json -> Swift
```

### Figma Plugin Sync

```bash
# Generate tokens for plugin
cd design-system/figma-plugin
npm run generate-tokens  # tokens.json -> TypeScript
npm run build:effects    # Build plugin with tokens
```

## File Reference

| File | Purpose |
|------|---------|
| `tokens.json` | Central token definition (source of truth) |
| `generate-swift.js` | Generates `DesignTokens.swift` from tokens.json |
| `export-from-figma.js` | Extracts tokens from Figma Variables |
| `sync-to-figma.js` | Prepares tokens for Figma sync |

## Workflow Details

### 1. tokens.json Structure

The tokens.json file follows the Design Tokens W3C format:

```json
{
  "primitive": {
    "size": { "sm": { "$value": "8px" } },
    "opacity": { "glass": { "$value": 0.05 } }
  },
  "spacing": {
    "card": { "$value": "{primitive.size.xxxl}" }
  },
  "typography": {
    "fontSize": {
      "reader": {
        "subject": { "$value": "24px", "fontWeight": "bold", "fontDesign": "rounded" }
      }
    }
  },
  "animation": {
    "spring": {
      "snappy": { "response": 0.25, "dampingFraction": 0.7 }
    }
  }
}
```

### 2. generate-swift.js

Transforms tokens.json into `DesignTokens.swift`:

**Input:** `design-system/tokens.json`
**Output:** `design-system/generated/DesignTokens.swift`

Features:
- Resolves token references (e.g., `{primitive.size.xl}`)
- Generates Font.system() with size, weight, and design
- Creates Animation.spring() presets
- Handles semantic opacity mappings

```bash
cd design-system/sync
node generate-swift.js
```

### 3. export-from-figma.js

Extracts tokens from Figma Variables API:

```bash
FIGMA_ACCESS_TOKEN=xxx node export-from-figma.js
```

Features:
- Uses Figma Variables API (requires paid plan)
- Falls back to file-based extraction
- Merges with existing tokens.json
- Creates backup before updating

### 4. Figma Plugin Token Generation

The Figma plugin reads from tokens.json via a generated TypeScript file:

```bash
cd design-system/figma-plugin
node generate-tokens-for-plugin.js
```

This creates `tokens-for-plugin.ts` which is imported by the plugin.

## Token Categories

### Typography (NEW)
- `fontSize.display` - Hero headlines
- `fontSize.heading` - Section titles
- `fontSize.body` - Main content
- `fontSize.label` - UI labels
- `fontSize.card` - Email card typography
- `fontSize.reader` - Email reader typography
- `fontSize.action` - Button text
- `fontSize.badge` - Status indicators

### Animation Springs (NEW)
- `spring.snappy` - Buttons (0.25s, 0.7 damping)
- `spring.bouncy` - Playful (0.4s, 0.6 damping)
- `spring.gentle` - Subtle (0.5s, 0.8 damping)
- `spring.heavy` - Significant (0.6s, 0.75 damping)

### Existing Categories
- `primitive` - Raw values (size, opacity, blur, duration)
- `spacing` - Semantic spacing
- `radius` - Border radius
- `opacity` - Transparency levels
- `colors` - Gradients, semantic colors
- `components` - Card, button, modal tokens

## Environment Variables

```bash
# Figma API Token (required for Figma export)
export FIGMA_ACCESS_TOKEN="figd_..."

# Figma File Key (optional, has default)
export FIGMA_FILE_KEY="WuQicPi1wbHXqEcYCQcLfr"
```

## CI/CD Integration

```yaml
# .github/workflows/sync-tokens.yml
name: Sync Design Tokens

on:
  push:
    paths:
      - 'design-system/tokens.json'
  workflow_dispatch:

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3

      - name: Generate Swift tokens
        run: |
          cd design-system/sync
          node generate-swift.js

      - name: Generate Figma plugin tokens
        run: |
          cd design-system/figma-plugin
          node generate-tokens-for-plugin.js

      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          title: 'chore: regenerate design tokens'
          commit-message: 'Regenerate tokens from tokens.json'
          branch: 'automated/design-tokens'
```

## Troubleshooting

### Generated Swift doesn't match iOS app

1. Run `node generate-swift.js`
2. Compare: `diff generated/DesignTokens.swift ../../Zero_ios_2/Zero/Config/DesignTokens.swift`
3. If tokens differ, update tokens.json

### Figma Variables API error (403)

The Variables API requires a paid Figma plan. The export script will fall back to file-based extraction.

### Token references not resolving

Check that reference paths match token structure:
- Good: `{primitive.size.xl}` 
- Bad: `{size.xl}` (missing primitive)

## Future: MCP Server

The plan includes building an MCP server for real-time bidirectional sync:

1. Designer changes color in Figma
2. MCP server detects change via webhook
3. tokens.json auto-updates
4. Swift/Plugin code regenerates
5. PR created automatically

---

See also:
- [tokens.json](../tokens.json) - Token definitions
- [Figma Plugin README](../figma-plugin/FINAL_SUMMARY.md) - Plugin documentation
- [Design System Status](../DESIGN_SYSTEM_STATUS_AND_ENHANCEMENT_PLAN.md) - Overall status

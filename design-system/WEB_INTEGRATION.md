# Web Design Token Integration

**Status**: Planning
**Target**: Landing page + Web demo
**Complexity**: Low-Medium
**Estimated Effort**: 3-5 days

---

## Overview

Integrate the unified design token system with the Zero Inbox web presence (landing page and web demos) for consistent branding across all platforms.

**Scope:**
- Landing page (rationaledesignhanson.com/zero)
- Intent-Action demo page
- Zero Sequence Live demo
- Future web app

---

## Current Web Stack

### Landing Page
- **Framework**: Next.js / React
- **Styling**: Tailwind CSS + custom CSS
- **Location**: `landing/` (assumed)

### Demo Pages
- **Framework**: Node.js + Express
- **Frontend**: Vanilla JS
- **Styling**: Custom CSS
- **Location**: `backend/dashboard/`

---

## Token Generation (Already Implemented)

### CSS Variables

**File**: `design-system/generated/design-tokens.css`

```css
:root {
  /* Spacing */
  --spacing-card: 24px;
  --spacing-modal: 24px;
  --spacing-section: 20px;
  --spacing-component: 16px;
  --spacing-element: 12px;
  --spacing-inline: 8px;
  --spacing-tight: 6px;
  --spacing-minimal: 4px;

  /* Radius */
  --radius-card: 16px;
  --radius-modal: 20px;
  --radius-button: 12px;
  --radius-chip: 8px;
  --radius-minimal: 4px;
  --radius-circle: 999px;

  /* Colors */
  --color-mail-gradient-start: #667eea;
  --color-mail-gradient-end: #764ba2;
  --color-ads-gradient-start: #16bbaa;
  --color-ads-gradient-end: #4fd19e;

  /* Typography */
  --font-card-title-size: 19px;
  --font-card-title-weight: 700;
  --font-card-summary-size: 15px;
}
```

### JavaScript Module

**File**: `design-system/generated/design-tokens.js`

```javascript
export const tokens = {
  spacing: {
    card: '24px',
    modal: '24px',
    section: '20px',
    component: '16px',
    element: '12px',
    inline: '8px',
    tight: '6px',
    minimal: '4px'
  },
  radius: {
    card: '16px',
    modal: '20px',
    button: '12px',
    chip: '8px',
    minimal: '4px',
    circle: '999px'
  },
  colors: {
    mailGradient: {
      start: '#667eea',
      end: '#764ba2'
    },
    adsGradient: {
      start: '#16bbaa',
      end: '#4fd19e'
    }
  },
  typography: {
    cardTitle: {
      size: '19px',
      weight: 700
    },
    cardSummary: {
      size: '15px',
      weight: 400
    }
  }
};
```

---

## Integration Strategy

### Option 1: CSS Variables (Recommended for Landing Page)

**Pros:**
- Native browser support
- Works with Tailwind
- Easy to override
- No build step required

**Implementation:**

```html
<!-- In <head> -->
<link rel="stylesheet" href="/design-tokens.css">

<!-- Usage in HTML -->
<div style="padding: var(--spacing-card); border-radius: var(--radius-card);">
  <h2 style="font-size: var(--font-card-title-size); font-weight: var(--font-card-title-weight);">
    Card Title
  </h2>
</div>
```

**With Tailwind:**

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      spacing: {
        'card': 'var(--spacing-card)',
        'modal': 'var(--spacing-modal)',
        'section': 'var(--spacing-section)',
      },
      borderRadius: {
        'card': 'var(--radius-card)',
        'button': 'var(--radius-button)',
      },
      colors: {
        'mail-start': 'var(--color-mail-gradient-start)',
        'mail-end': 'var(--color-mail-gradient-end)',
      }
    }
  }
}
```

```jsx
// Usage in React components
<div className="p-card rounded-card bg-gradient-to-br from-mail-start to-mail-end">
  <h2 className="text-[length:var(--font-card-title-size)] font-bold">
    Card Title
  </h2>
</div>
```

### Option 2: JavaScript Import (Recommended for Demo Pages)

**Pros:**
- Type-safe (with TypeScript)
- Programmatic access
- Easy to use in JS logic

**Implementation:**

```javascript
// Import tokens
import { tokens } from './design-tokens.js';

// Apply in JavaScript
const card = document.createElement('div');
card.style.padding = tokens.spacing.card;
card.style.borderRadius = tokens.radius.card;

// Create gradients
const gradient = `linear-gradient(135deg, ${tokens.colors.mailGradient.start}, ${tokens.colors.mailGradient.end})`;
card.style.background = gradient;
```

### Option 3: Tailwind Plugin (Advanced)

**Pros:**
- Full Tailwind integration
- Type-safe with IntelliSense
- Best DX

**Implementation:**

```javascript
// design-system/tailwind-plugin.js
const tokens = require('./generated/design-tokens.json');

module.exports = function() {
  return {
    theme: {
      extend: {
        spacing: tokens.spacing,
        borderRadius: tokens.radius,
        colors: {
          'mail-gradient-start': tokens.colors.mailGradient.start,
          'mail-gradient-end': tokens.colors.mailGradient.end,
        }
      }
    }
  }
}
```

```javascript
// tailwind.config.js
module.exports = {
  plugins: [
    require('./design-system/tailwind-plugin')
  ]
}
```

---

## Migration Plan

### Phase 1: Landing Page

**Current**:
```css
/* Hardcoded values */
.card {
  padding: 24px;
  border-radius: 16px;
  background: linear-gradient(135deg, #667eea, #764ba2);
}

.card-title {
  font-size: 19px;
  font-weight: 700;
}
```

**After Migration**:
```css
/* Using tokens */
.card {
  padding: var(--spacing-card);
  border-radius: var(--radius-card);
  background: linear-gradient(135deg, var(--color-mail-gradient-start), var(--color-mail-gradient-end));
}

.card-title {
  font-size: var(--font-card-title-size);
  font-weight: var(--font-card-title-weight);
}
```

### Phase 2: Demo Pages

**Current**:
```javascript
// Hardcoded in JavaScript
const card = `
  <div style="padding: 24px; border-radius: 16px; background: linear-gradient(135deg, #667eea, #764ba2);">
    <h2 style="font-size: 19px; font-weight: 700;">
      ${title}
    </h2>
  </div>
`;
```

**After Migration**:
```javascript
// Using tokens
import { tokens } from './design-tokens.js';

const card = `
  <div style="padding: ${tokens.spacing.card}; border-radius: ${tokens.radius.card}; background: linear-gradient(135deg, ${tokens.colors.mailGradient.start}, ${tokens.colors.mailGradient.end});">
    <h2 style="font-size: ${tokens.typography.cardTitle.size}; font-weight: ${tokens.typography.cardTitle.weight};">
      ${title}
    </h2>
  </div>
`;
```

---

## Automation

### Build Script

```json
// package.json
{
  "scripts": {
    "tokens:generate": "node design-system/sync/generate-web.js",
    "tokens:copy": "cp design-system/generated/design-tokens.css public/styles/",
    "tokens:watch": "nodemon --watch design-system/tokens.json --exec npm run tokens:generate",
    "build": "npm run tokens:generate && next build"
  }
}
```

### GitHub Action Integration

Already created in `.github/workflows/design-tokens-sync.yml`:
- Generates web tokens automatically
- Creates PR for review
- Uploads artifacts

---

## File Structure

```
landing/
├── public/
│   └── styles/
│       └── design-tokens.css  # Generated CSS variables
├── src/
│   ├── tokens/
│   │   └── design-tokens.js   # Generated JS module
│   └── components/
│       └── Card.jsx           # Using tokens
└── tailwind.config.js         # Token integration

backend/
└── dashboard/
    ├── public/
    │   └── design-tokens.js   # Generated tokens
    └── views/
        └── demo.ejs           # Using tokens
```

---

## Component Examples

### React Card Component

```jsx
// Before
const Card = ({ title, children }) => (
  <div className="p-6 rounded-xl bg-gradient-to-br from-[#667eea] to-[#764ba2]">
    <h2 className="text-lg font-bold">{title}</h2>
    {children}
  </div>
);

// After (with Tailwind plugin)
const Card = ({ title, children }) => (
  <div className="p-card rounded-card bg-gradient-to-br from-mail-start to-mail-end">
    <h2 className="text-[length:var(--font-card-title-size)] font-bold">{title}</h2>
    {children}
  </div>
);
```

### Email Demo Card

```javascript
// Before
function renderCard(email) {
  return `
    <div class="email-card" style="
      padding: 24px;
      border-radius: 16px;
      background: linear-gradient(135deg, #667eea, #764ba2);
    ">
      <h3 style="font-size: 19px; font-weight: bold;">
        ${email.subject}
      </h3>
      <p style="font-size: 15px;">
        ${email.summary}
      </p>
    </div>
  `;
}

// After
import { tokens } from './design-tokens.js';

function renderCard(email) {
  const { spacing, radius, colors, typography } = tokens;

  return `
    <div class="email-card" style="
      padding: ${spacing.card};
      border-radius: ${radius.card};
      background: linear-gradient(135deg, ${colors.mailGradient.start}, ${colors.mailGradient.end});
    ">
      <h3 style="font-size: ${typography.cardTitle.size}; font-weight: ${typography.cardTitle.weight};">
        ${email.subject}
      </h3>
      <p style="font-size: ${typography.cardSummary.size};">
        ${email.summary}
      </p>
    </div>
  `;
}
```

---

## Dark Mode Support (Future)

### CSS Variables with Media Query

```css
:root {
  --color-background: #000000;
  --color-text: #ffffff;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-background: #ffffff;
    --color-text: #000000;
  }
}
```

### JavaScript Detection

```javascript
// Detect system preference
const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

// Apply appropriate tokens
const backgroundClass = isDark ? 'bg-white' : 'bg-black';
```

---

## Testing Strategy

### Visual Regression Testing

```bash
# Capture screenshots before migration
npm run screenshots:capture

# After migration, compare
npm run screenshots:compare
```

### Manual Testing Checklist

- [ ] Landing page hero section
- [ ] Email card gradients
- [ ] Button styles
- [ ] Modal layouts
- [ ] Intent-action demo cards
- [ ] Zero Sequence Live interface

---

## Deployment

### CDN Approach

```html
<!-- Serve tokens from CDN -->
<link rel="stylesheet" href="https://cdn.rationaledesignhanson.com/design-tokens.css">
<script src="https://cdn.rationaledesignhanson.com/design-tokens.js"></script>
```

### Build-Time Approach

```bash
# Copy tokens during build
cp design-system/generated/* landing/public/tokens/

# Or bundle with webpack/vite
import tokens from '../../design-system/generated/design-tokens.json';
```

---

## Success Metrics

- [ ] All hardcoded values replaced with tokens
- [ ] Visual parity with current design
- [ ] No regressions in demo pages
- [ ] Faster design iteration (change tokens, not code)
- [ ] Consistent branding across web and iOS

---

## Benefits

✅ **Consistency**: Web matches iOS exactly
✅ **Maintainability**: Update tokens once, apply everywhere
✅ **Speed**: Faster design iteration
✅ **Type Safety**: With TypeScript integration
✅ **Documentation**: Self-documenting through token names

---

## Timeline

| Phase | Task | Duration |
|-------|------|----------|
| 1 | Generate and test tokens | 1 day |
| 2 | Integrate with landing page | 1-2 days |
| 3 | Migrate demo pages | 1 day |
| 4 | Testing and polish | 1 day |

**Total**: 3-5 days

---

## References

- Generated tokens: `design-system/generated/`
- Generator script: `design-system/sync/generate-web.js`
- iOS tokens: `Zero_ios_2/Zero/Config/DesignTokens.swift`
- Token source: `design-system/tokens.json`

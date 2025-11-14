#!/usr/bin/env node

/**
 * Generate Web Design Tokens (CSS + JS) from JSON
 * Converts design-tokens.json into CSS variables and JS modules
 *
 * Usage: node generate-web.js
 * Input: design-tokens.json
 * Output: design-tokens.css, design-tokens.js
 */

const fs = require('fs');
const path = require('path');

const INPUT_FILE = path.join(__dirname, 'design-tokens.json');
const OUTPUT_CSS = path.join(__dirname, '../generated/design-tokens.css');
const OUTPUT_JS = path.join(__dirname, '../generated/design-tokens.js');

// Generate CSS custom properties
function generateCSS(tokens) {
  let css = `/**
 * Design Tokens - Generated from Figma
 * DO NOT EDIT MANUALLY - This file is auto-generated
 * Generated at: ${tokens.meta.exportedAt}
 * Source: Figma File ${tokens.meta.fileKey}
 */

:root {
  /* ========================================
     Spacing Tokens
     ======================================== */
`;

  // Spacing
  Object.entries(tokens.spacing).forEach(([key, value]) => {
    const name = key.replace(/^space/, '').toLowerCase();
    const mapping = {
      '0': 'none',
      '1': 'minimal',
      '2': 'inline',
      '3': 'element',
      '4': 'component',
      '5': 'section',
      '6': 'card',
      '8': 'large'
    };
    const semanticName = mapping[name] || name;
    css += `  --spacing-${semanticName}: ${value}px;\n`;
  });

  // Border Radius
  css += `\n  /* ========================================
     Border Radius Tokens
     ======================================== */
`;
  Object.entries(tokens.radius).forEach(([key, value]) => {
    if (key === 'full') {
      css += `  --radius-${key}: 9999px;\n`;
    } else {
      const mapping = {
        'none': 'none',
        'sm': 'minimal',
        'base': 'chip',
        'lg': 'button',
        'xl': 'card'
      };
      const name = mapping[key] || key;
      css += `  --radius-${name}: ${value}px;\n`;
    }
  });
  css += `  --radius-modal: 20px;\n`;
  css += `  --radius-circle: 999px;\n`;

  // Colors
  css += `\n  /* ========================================
     Color Tokens
     ======================================== */
`;

  // Base colors
  if (tokens.colors.base) {
    Object.entries(tokens.colors.base).forEach(([name, hex]) => {
      css += `  --color-${name}: ${hex};\n`;
    });
  }

  // Semantic colors
  css += `\n  /* Semantic Colors */\n`;
  Object.entries(tokens.semanticColors).forEach(([name, hex]) => {
    css += `  --color-${name}: ${hex};\n`;
  });

  // Gradients
  if (tokens.gradients.mail) {
    css += `\n  /* Archetype Gradients */\n`;
    css += `  --gradient-mail-start: ${tokens.gradients.mail.start};\n`;
    css += `  --gradient-mail-end: ${tokens.gradients.mail.end};\n`;
    css += `  --gradient-mail: linear-gradient(135deg, var(--gradient-mail-start), var(--gradient-mail-end));\n`;
  }
  if (tokens.gradients.ads) {
    css += `  --gradient-ads-start: ${tokens.gradients.ads.start};\n`;
    css += `  --gradient-ads-end: ${tokens.gradients.ads.end};\n`;
    css += `  --gradient-ads: linear-gradient(135deg, var(--gradient-ads-start), var(--gradient-ads-end));\n`;
  }

  // Typography
  css += `\n  /* ========================================
     Typography Tokens
     ======================================== */
`;
  Object.entries(tokens.typography).forEach(([size, config]) => {
    const name = size === 'xs' ? 'caption' :
                 size === 'sm' ? 'small' :
                 size === 'base' ? 'body' :
                 size === 'lg' ? 'large' :
                 size === 'xl' ? 'title' :
                 size === '2xl' ? 'heading' :
                 size === '3xl' ? 'display' : size;

    css += `  --font-size-${name}: ${config.size}px;\n`;
  });

  // Font weights
  css += `\n  /* Font Weights */\n`;
  css += `  --font-weight-regular: 400;\n`;
  css += `  --font-weight-medium: 500;\n`;
  css += `  --font-weight-semibold: 600;\n`;
  css += `  --font-weight-bold: 700;\n`;

  // Line heights
  css += `\n  /* Line Heights */\n`;
  css += `  --line-height-tight: 1.2;\n`;
  css += `  --line-height-normal: 1.5;\n`;
  css += `  --line-height-relaxed: 1.75;\n`;

  // Opacity
  css += `\n  /* ========================================
     Opacity Tokens
     ======================================== */
`;
  Object.entries(tokens.opacity).forEach(([key, value]) => {
    css += `  --opacity-${key}: ${value};\n`;
  });

  // Shadows
  css += `\n  /* ========================================
     Shadow Tokens (not in Figma)
     ======================================== */
  --shadow-card: 0 10px 20px rgba(0, 0, 0, 0.4);
  --shadow-button: 0 5px 10px rgba(0, 0, 0, 0.2);
  --shadow-subtle: 0 2px 8px rgba(0, 0, 0, 0.1);

  /* ========================================
     Animation Tokens (not in Figma)
     ======================================== */
  --animation-quick: 0.2s;
  --animation-standard: 0.5s;
  --animation-slow: 0.7s;
}
`;

  return css;
}

// Generate JavaScript module
function generateJS(tokens) {
  const js = `/**
 * Design Tokens - Generated from Figma
 * DO NOT EDIT MANUALLY - This file is auto-generated
 * Generated at: ${tokens.meta.exportedAt}
 * Source: Figma File ${tokens.meta.fileKey}
 */

export const designTokens = ${JSON.stringify(tokens, null, 2)};

// Convenience accessors
export const spacing = ${JSON.stringify(tokens.spacing, null, 2)};

export const radius = ${JSON.stringify(tokens.radius, null, 2)};

export const colors = {
  ...${JSON.stringify(tokens.colors, null, 2)},
  semantic: ${JSON.stringify(tokens.semanticColors, null, 2)}
};

export const gradients = ${JSON.stringify(tokens.gradients, null, 2)};

export const typography = ${JSON.stringify(tokens.typography, null, 2)};

export const opacity = ${JSON.stringify(tokens.opacity, null, 2)};

// Shadows (not in Figma)
export const shadows = {
  card: '0 10px 20px rgba(0, 0, 0, 0.4)',
  button: '0 5px 10px rgba(0, 0, 0, 0.2)',
  subtle: '0 2px 8px rgba(0, 0, 0, 0.1)'
};

// Animation durations (not in Figma)
export const animation = {
  quick: 0.2,
  standard: 0.5,
  slow: 0.7
};

// Default export
export default designTokens;
`;

  return js;
}

// Main generation function
function generateWeb() {
  console.log('🌐 Generating Web Design Tokens (CSS + JS)...\n');

  try {
    // Read tokens
    if (!fs.existsSync(INPUT_FILE)) {
      throw new Error(`Tokens file not found: ${INPUT_FILE}\nRun export-from-figma.js first.`);
    }

    const tokens = JSON.parse(fs.readFileSync(INPUT_FILE, 'utf8'));

    // Generate CSS and JS
    const css = generateCSS(tokens);
    const js = generateJS(tokens);

    // Ensure output directory exists
    const outputDir = path.dirname(OUTPUT_CSS);
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // Write files
    fs.writeFileSync(OUTPUT_CSS, css);
    fs.writeFileSync(OUTPUT_JS, js);

    console.log('✅ Web tokens generated successfully!\n');
    console.log(`📄 CSS Output: ${OUTPUT_CSS}`);
    console.log(`📄 JS Output:  ${OUTPUT_JS}\n`);

    // Print summary
    console.log('📊 Generated:');
    console.log(`   - ${Object.keys(tokens.spacing).length} spacing tokens`);
    console.log(`   - ${Object.keys(tokens.radius).length} radius tokens`);
    console.log(`   - ${Object.keys(tokens.colors).length} color sections`);
    console.log(`   - ${Object.keys(tokens.typography).length} typography sizes`);
    console.log(`   - ${Object.keys(tokens.opacity).length} opacity tokens`);
    console.log(`   - ${Object.keys(tokens.gradients).length} gradient archetypes\n`);

    console.log('💡 Usage:');
    console.log('   CSS: Import in your HTML or main CSS file');
    console.log('   JS:  import { spacing, colors } from "./design-tokens.js"\n');

  } catch (error) {
    console.error('❌ Error generating web tokens:', error.message);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  generateWeb();
}

module.exports = { generateWeb };

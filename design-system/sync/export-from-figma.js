#!/usr/bin/env node

/**
 * Export Design Tokens from Figma
 * Fetches Figma file and extracts design tokens into standardized JSON format
 *
 * Usage: node export-from-figma.js
 * Output: design-tokens.json
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const FIGMA_TOKEN = process.env.FIGMA_ACCESS_TOKEN || '';
const FILE_KEY = process.env.FIGMA_FILE_KEY || 'WuQicPi1wbHXqEcYCQcLfr';
const OUTPUT_FILE = path.join(__dirname, 'design-tokens.json');

// Helper to convert RGB to hex
function rgbToHex(r, g, b) {
  const toHex = (n) => {
    const hex = Math.round(n * 255).toString(16);
    return hex.length === 1 ? '0' + hex : hex;
  };
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

// Fetch Figma file
function fetchFigmaFile() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.figma.com',
      path: `/v1/files/${FILE_KEY}`,
      method: 'GET',
      headers: { 'X-Figma-Token': FIGMA_TOKEN }
    };

    https.get(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

// Extract colors from color palette frames
function extractColors(node, colors = {}, currentSection = null) {
  // Track section names
  if (node.name === '🎨 Color Palette') {
    currentSection = 'base';
  } else if (node.name === 'Primary') {
    currentSection = 'primary';
  } else if (node.name === 'Semantic') {
    currentSection = 'semantic';
  }

  // Extract color swatches (frames with solid fills and color names)
  if (node.type === 'FRAME' && node.fills && node.fills[0]?.type === 'SOLID') {
    const name = node.name.toLowerCase();

    // Skip container frames
    if (!['frame', 'primary', 'semantic', 'primary colors', 'semantic colors'].includes(name)) {
      const color = node.fills[0].color;
      const hex = rgbToHex(color.r, color.g, color.b);

      if (!colors[currentSection || 'other']) {
        colors[currentSection || 'other'] = {};
      }
      colors[currentSection || 'other'][name] = hex;
    }
  }

  // Extract from text nodes that contain hex values
  if (node.type === 'TEXT' && node.characters.match(/^#[0-9A-F]{6}$/i)) {
    const parentName = node.parent?.name?.toLowerCase();
    if (parentName && !colors[currentSection]?.[parentName]) {
      if (!colors[currentSection || 'other']) {
        colors[currentSection || 'other'] = {};
      }
      colors[currentSection || 'other'][parentName] = node.characters.toUpperCase();
    }
  }

  // Recursively process children
  if (node.children) {
    node.children.forEach(child => extractColors(child, colors, currentSection));
  }

  return colors;
}

// Extract spacing tokens
function extractSpacing(node, spacing = {}) {
  if (node.name === '📏 Spacing Scale' && node.children) {
    node.children.forEach(child => {
      if (child.type === 'TEXT' && child.characters.match(/^\d+:/)) {
        const match = child.characters.match(/^(\d+):\s*(\d+)px/);
        if (match) {
          const [, level, value] = match;
          spacing[`space${level}`] = parseInt(value);
        }
      }
    });
  }

  if (node.children) {
    node.children.forEach(child => extractSpacing(child, spacing));
  }

  return spacing;
}

// Extract border radius tokens
function extractRadius(node, radius = {}) {
  if (node.name === '🔘 Border Radius' && node.children) {
    node.children.forEach(child => {
      if (child.type === 'TEXT') {
        const match = child.characters.match(/^(\w+):\s*(\d+)px/);
        if (match) {
          const [, name, value] = match;
          radius[name] = parseInt(value);
        }
      }
    });
  }

  if (node.children) {
    node.children.forEach(child => extractRadius(child, radius));
  }

  return radius;
}

// Extract typography tokens
function extractTypography(node, typography = {}) {
  if (node.name === '✏️ Typography Specimen' && node.children) {
    // Find size headers like "XS (12px)", "SM (13px)", etc.
    node.children.forEach(child => {
      if (child.type === 'TEXT') {
        const sizeMatch = child.characters.match(/^([A-Z0-9]+)\s*\((\d+)px\)/);
        if (sizeMatch) {
          const [, sizeName, fontSize] = sizeMatch;
          typography[sizeName.toLowerCase()] = {
            size: parseInt(fontSize),
            weights: {
              regular: 400,
              medium: 500,
              semibold: 600,
              bold: 700
            }
          };
        }
      }
    });
  }

  if (node.children) {
    node.children.forEach(child => extractTypography(child, typography));
  }

  return typography;
}

// Extract opacity tokens
function extractOpacity(node, opacity = {}) {
  if (node.name === 'Opacity Scale' && node.children) {
    node.children.forEach(child => {
      if (child.type === 'TEXT') {
        const match = child.characters.match(/^(\w+):\s*(0\.\d+)/);
        if (match) {
          const [, name, value] = match;
          opacity[name] = parseFloat(value);
        }
      }
    });
  }

  if (node.children) {
    node.children.forEach(child => extractOpacity(child, opacity));
  }

  return opacity;
}

// Extract gradients
function extractGradients(node, gradients = {}) {
  if (node.name === '🎨 Archetypes' && node.children) {
    let currentArchetype = null;

    node.children.forEach(child => {
      if (child.type === 'TEXT') {
        const text = child.characters;

        // Archetype names
        if (text === 'Mail' || text === 'Ads') {
          currentArchetype = text.toLowerCase();
          gradients[currentArchetype] = {};
        }

        // Start/End colors
        if (currentArchetype && text.match(/^(Start|End):/)) {
          const match = text.match(/^(Start|End):\s*(#[0-9A-F]{6})/i);
          if (match) {
            const [, position, color] = match;
            gradients[currentArchetype][position.toLowerCase()] = color;
          }
        }
      }
    });
  }

  if (node.children) {
    node.children.forEach(child => extractGradients(child, gradients));
  }

  return gradients;
}

// Main export function
async function exportTokens() {
  console.log('🎨 Exporting Design Tokens from Figma...\n');

  try {
    const figmaData = await fetchFigmaFile();

    if (figmaData.error || !figmaData.document) {
      throw new Error(figmaData.error || 'Invalid Figma data');
    }

    const designSystemPage = figmaData.document.children.find(
      page => page.name.includes('Design System')
    );

    if (!designSystemPage) {
      throw new Error('No "Design System Components" page found in Figma file');
    }

    console.log('✅ Found Design System page\n');

    // Extract all tokens
    const tokens = {
      meta: {
        version: '1.0.0',
        source: 'Figma',
        fileKey: FILE_KEY,
        exportedAt: new Date().toISOString()
      },
      colors: extractColors(designSystemPage),
      spacing: extractSpacing(designSystemPage),
      radius: extractRadius(designSystemPage),
      typography: extractTypography(designSystemPage),
      opacity: extractOpacity(designSystemPage),
      gradients: extractGradients(designSystemPage)
    };

    // Add semantic mappings
    tokens.semanticColors = {
      success: tokens.colors.semantic?.success || '#34C759',
      error: tokens.colors.semantic?.error || '#FF3B30',
      warning: tokens.colors.semantic?.warning || '#FF9500',
      info: tokens.colors.semantic?.info || '#007AFF'
    };

    // Write to file
    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(tokens, null, 2));

    console.log('📊 Exported Tokens Summary:');
    console.log('==========================');
    console.log(`Colors: ${Object.keys(tokens.colors).length} sections`);
    console.log(`Spacing: ${Object.keys(tokens.spacing).length} tokens`);
    console.log(`Radius: ${Object.keys(tokens.radius).length} tokens`);
    console.log(`Typography: ${Object.keys(tokens.typography).length} sizes`);
    console.log(`Opacity: ${Object.keys(tokens.opacity).length} tokens`);
    console.log(`Gradients: ${Object.keys(tokens.gradients).length} archetypes`);
    console.log(`\n✅ Tokens exported to: ${OUTPUT_FILE}\n`);

    return tokens;
  } catch (error) {
    console.error('❌ Error exporting tokens:', error.message);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  exportTokens();
}

module.exports = { exportTokens };

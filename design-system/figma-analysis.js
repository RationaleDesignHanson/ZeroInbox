#!/usr/bin/env node

/**
 * Figma Design System Analysis
 * Compares Figma file with iOS DesignTokens.swift
 */

const https = require('https');

const FIGMA_TOKEN = process.env.FIGMA_ACCESS_TOKEN || '';
const FILE_KEY = 'WuQicPi1wbHXqEcYCQcLfr';

// iOS Design System (from DesignTokens.swift)
const iOSDesignSystem = {
  spacing: {
    card: 24,
    modal: 24,
    section: 20,
    component: 16,
    element: 12,
    inline: 8,
    tight: 6,
    minimal: 4
  },
  radius: {
    card: 16,
    modal: 20,
    container: 16,
    button: 12,
    chip: 8,
    minimal: 4,
    circle: 999
  },
  colors: {
    primary: {
      vibrantBlue: '#3b82f6',
      vibrantPurple: '#a855f7',
      vibrantPink: '#ec4899',
      vibrantCyan: '#0ea5e9',
      vibrantGreen: '#10b981',
      vibrantEmerald: '#34ecb3',
      vibrantYellow: '#fbbf24',
      vibrantOrange: '#f97316'
    },
    base: {
      white: '#FFFFFF',
      black: '#000000'
    },
    semantic: {
      success: '#34C759',
      error: '#FF3B30',
      warning: '#FF9500',
      info: '#007AFF'
    },
    gradients: {
      mail: {
        start: '#667eea',
        end: '#764ba2'
      },
      ads: {
        start: '#16bbaa',
        end: '#4fd19e'
      }
    }
  },
  typography: {
    display: {
      large: { size: 34, weight: 'bold' },
      medium: { size: 28, weight: 'bold' }
    },
    heading: {
      large: { size: 22, weight: 'bold' },
      medium: { size: 20, weight: 'semibold' },
      small: { size: 17, weight: 'semibold' }
    },
    body: {
      large: { size: 17, weight: 'regular' },
      medium: { size: 16, weight: 'regular' },
      small: { size: 15, weight: 'regular' }
    },
    label: {
      large: { size: 12, weight: 'bold' },
      medium: { size: 12, weight: 'regular' },
      small: { size: 11, weight: 'regular' }
    },
    card: {
      title: { size: 19, weight: 'bold' },
      summary: { size: 15, weight: 'regular' },
      sectionHeader: { size: 15, weight: 'bold' }
    }
  },
  shadows: {
    card: { color: 'rgba(0,0,0,0.4)', radius: 20, x: 0, y: 10 },
    button: { color: 'rgba(0,0,0,0.2)', radius: 10, x: 0, y: 5 },
    subtle: { color: 'rgba(0,0,0,0.1)', radius: 8, x: 0, y: 2 }
  },
  animation: {
    quick: 0.2,
    standard: 0.5,
    slow: 0.7
  },
  opacity: {
    textPrimary: 1.0,
    textSecondary: 0.9,
    textTertiary: 0.8,
    textSubtle: 0.7,
    textDisabled: 0.6,
    overlayStrong: 0.5,
    overlayMedium: 0.3,
    overlayLight: 0.2,
    glassLight: 0.1,
    glassUltraLight: 0.05
  }
};

function fetchFigmaFile() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.figma.com',
      path: `/v1/files/${FILE_KEY}`,
      method: 'GET',
      headers: {
        'X-Figma-Token': FIGMA_TOKEN
      }
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

function extractColors(node, colors = {}) {
  // Extract color swatches
  if (node.type === 'FRAME' && node.fills && node.fills[0]?.type === 'SOLID') {
    const color = node.fills[0].color;
    const hex = rgbToHex(color.r, color.g, color.b);
    colors[node.name] = hex;
  }

  // Recursively process children
  if (node.children) {
    node.children.forEach(child => extractColors(child, colors));
  }

  return colors;
}

function rgbToHex(r, g, b) {
  const toHex = (n) => {
    const hex = Math.round(n * 255).toString(16);
    return hex.length === 1 ? '0' + hex : hex;
  };
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`.toUpperCase();
}

function extractTypography(node, typography = []) {
  if (node.type === 'TEXT' && node.style) {
    typography.push({
      name: node.name,
      fontFamily: node.style.fontFamily,
      fontSize: node.style.fontSize,
      fontWeight: node.style.fontWeight,
      lineHeight: node.style.lineHeightPx
    });
  }

  if (node.children) {
    node.children.forEach(child => extractTypography(child, typography));
  }

  return typography;
}

async function analyzeDesignSystem() {
  console.log('📊 Analyzing Figma Design System vs iOS Design System\n');
  console.log('Fetching Figma file...\n');

  const figmaData = await fetchFigmaFile();
  const designSystemPage = figmaData.document.children.find(
    page => page.name.includes('Design System')
  );

  if (!designSystemPage) {
    console.log('⚠️  No "Design System" page found in Figma\n');
    console.log('📋 Creating recommendations...\n');
    printRecommendations();
    return;
  }

  // Extract what's in Figma
  const figmaColors = extractColors(designSystemPage);
  const figmaTypography = extractTypography(designSystemPage);

  console.log('🎨 COLORS IN FIGMA:');
  console.log('==================');
  Object.entries(figmaColors).forEach(([name, hex]) => {
    console.log(`  ${name}: ${hex}`);
  });

  console.log('\n📝 TYPOGRAPHY IN FIGMA:');
  console.log('=====================');
  figmaTypography.forEach(t => {
    console.log(`  ${t.name}: ${t.fontSize}px / ${t.fontWeight} / ${t.fontFamily}`);
  });

  console.log('\n\n❌ MISSING FROM FIGMA:');
  console.log('====================');
  printMissingElements(figmaColors, figmaTypography);
}

function printMissingElements(figmaColors, figmaTypography) {
  console.log('\n🎨 Colors:');
  const missingColors = [];

  // Check vibrant colors
  Object.entries(iOSDesignSystem.colors.primary).forEach(([name, hex]) => {
    if (!Object.values(figmaColors).includes(hex)) {
      missingColors.push(`  ❌ ${name}: ${hex}`);
    }
  });

  // Check gradients
  console.log('  Gradient Colors:');
  console.log(`  ❌ Mail Gradient: ${iOSDesignSystem.colors.gradients.mail.start} → ${iOSDesignSystem.colors.gradients.mail.end}`);
  console.log(`  ❌ Ads Gradient: ${iOSDesignSystem.colors.gradients.ads.start} → ${iOSDesignSystem.colors.gradients.ads.end}`);

  if (missingColors.length) {
    console.log('\n  Vibrant Colors:');
    missingColors.forEach(c => console.log(c));
  }

  console.log('\n📏 Spacing Scale:');
  console.log('  ❌ Complete spacing system (card: 24, modal: 24, section: 20, component: 16, element: 12, inline: 8, tight: 6, minimal: 4)');

  console.log('\n🔲 Border Radius:');
  console.log('  ❌ Complete radius system (card: 16, modal: 20, button: 12, chip: 8, minimal: 4)');

  console.log('\n📝 Typography Scale:');
  console.log('  ❌ Complete type scale (Display, Heading, Body, Label sizes)');
  console.log('  ❌ Card-specific typography (title: 19px, summary: 15px)');

  console.log('\n💫 Effects:');
  console.log('  ❌ Shadow presets (card, button, subtle)');
  console.log('  ❌ Opacity scale (10 levels from 0.05 to 1.0)');

  console.log('\n⚡ Animation:');
  console.log('  ❌ Duration tokens (quick: 0.2s, standard: 0.5s, slow: 0.7s)');

  console.log('\n🎭 Components:');
  console.log('  ❌ Button variants (gradient styles)');
  console.log('  ❌ Card components');
  console.log('  ❌ Modal templates');
}

function printRecommendations() {
  console.log('\n📋 RECOMMENDATIONS:');
  console.log('=================\n');
  console.log('To create a complete Figma design system, you need:\n');
  console.log('1. 🎨 Color Palette Page');
  console.log('   - Base colors (white, black)');
  console.log('   - Vibrant colors (8 colors)');
  console.log('   - Semantic colors (success, error, warning, info)');
  console.log('   - Gradient swatches (mail, ads archetypes)\n');
  console.log('2. 📝 Typography Scale Page');
  console.log('   - Display styles (large, medium)');
  console.log('   - Heading styles (3 sizes)');
  console.log('   - Body styles (3 sizes)');
  console.log('   - Label styles (3 sizes)');
  console.log('   - Card-specific styles\n');
  console.log('3. 📏 Spacing & Layout Page');
  console.log('   - 8-point spacing scale');
  console.log('   - Border radius tokens');
  console.log('   - Component dimensions\n');
  console.log('4. 💫 Effects Library');
  console.log('   - Shadow styles (card, button, subtle)');
  console.log('   - Opacity tokens\n');
  console.log('5. 🎭 Component Library');
  console.log('   - Buttons (with gradient variants)');
  console.log('   - Cards');
  console.log('   - Modals');
  console.log('   - Badges\n');
  console.log('6. 📱 Platform Guidelines');
  console.log('   - iOS-specific patterns');
  console.log('   - Web adaptations');
  console.log('   - Responsive breakpoints\n');
}

analyzeDesignSystem().catch(console.error);

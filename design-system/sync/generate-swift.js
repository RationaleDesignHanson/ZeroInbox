#!/usr/bin/env node

/**
 * Generate Swift Design Tokens from JSON
 * Converts tokens.json into complete Swift DesignTokens.swift file
 * Matches iOS DesignTokens.swift structure: Primitive → Semantic → Component
 *
 * Usage: node generate-swift.js
 * Input: ../tokens.json
 * Output: ../generated/DesignTokens.swift
 */

const fs = require('fs');
const path = require('path');

const INPUT_FILE = path.join(__dirname, '../tokens.json');
const OUTPUT_FILE = path.join(__dirname, '../generated/DesignTokens.swift');

// Helper to convert hex to RGB values for Swift
function hexToRGB(hex) {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) return null;

  const r = parseInt(result[1], 16) / 255;
  const g = parseInt(result[2], 16) / 255;
  const b = parseInt(result[3], 16) / 255;

  return { r, g, b };
}

// Helper to resolve token references like {primitive.size.xl}
function resolveValue(value, tokens) {
  if (typeof value === 'string' && value.startsWith('{') && value.endsWith('}')) {
    const path = value.slice(1, -1).split('.');
    let result = tokens;
    for (const key of path) {
      result = result[key];
      if (result && result.$value !== undefined) {
        result = result.$value;
      }
    }
    return resolveValue(result, tokens);
  }
  return value;
}

// Generate Primitive tokens
function generatePrimitive(primitive) {
  let code = `    // MARK: - Primitive Tokens (Raw values - internal use only)\n\n`;
  code += `    enum Primitive {\n`;

  // Size scale
  code += `        /// Base size scale (powers of 2 and common increments)\n`;
  code += `        enum Size {\n`;
  Object.entries(primitive.size).filter(([key]) => !key.startsWith('$')).forEach(([key, token]) => {
    const value = parseInt(token.$value);
    code += `            static let ${key}: CGFloat = ${value}\n`;
  });
  code += `        }\n\n`;

  // Opacity scale
  code += `        /// Opacity scale (0.0 - 1.0)\n`;
  code += `        enum Opacity {\n`;
  Object.entries(primitive.opacity).filter(([key]) => !key.startsWith('$')).forEach(([key, token]) => {
    const comment = token.description ? `          // ${token.description}` : '';
    code += `            static let ${key}: Double = ${token.$value}${comment}\n`;
  });
  code += `        }\n\n`;

  // Blur radius scale
  code += `        /// Blur radius scale (for glassmorphic effects)\n`;
  code += `        enum Blur {\n`;
  Object.entries(primitive.blur).filter(([key]) => !key.startsWith('$')).forEach(([key, token]) => {
    const value = parseInt(token.$value);
    const comment = token.description ? `          // ${token.description}` : '';
    code += `            static let ${key}: CGFloat = ${value}${comment}\n`;
  });
  code += `        }\n\n`;

  // Animation duration scale
  code += `        /// Animation duration scale (in seconds)\n`;
  code += `        enum Duration {\n`;
  Object.entries(primitive.duration).filter(([key]) => !key.startsWith('$')).forEach(([key, token]) => {
    const value = parseInt(token.$value) / 1000; // Convert ms to seconds
    code += `            static let ${key}: Double = ${value}\n`;
  });
  code += `        }\n`;

  code += `    }\n`;
  return code;
}

// Generate Semantic Spacing
function generateSpacing(spacing, tokens) {
  let code = `    // MARK: - Semantic Tokens (Usage-based - primary API)\n\n`;
  code += `    /// Spacing tokens - semantic names for layout spacing\n`;
  code += `    enum Spacing {\n`;

  Object.entries(spacing).filter(([key]) => !key.startsWith('$')).forEach(([key, token]) => {
    const tokenValue = token.$value || token;
    const resolvedValue = resolveValue(tokenValue, tokens);
    const value = parseInt(resolvedValue);
    const comment = token.description ? ` // ${token.description}` : '';
    if (typeof tokenValue === 'string' && tokenValue.includes('primitive')) {
      const cleanRef = tokenValue.replace(/[{}]/g, ''); // Remove braces
      const parts = cleanRef.split('.');
      const primitiveRef = `Primitive.Size.${parts[parts.length - 1]}`;
      code += `        static let ${key}: CGFloat = ${primitiveRef}${comment}\n`;
    } else {
      code += `        static let ${key}: CGFloat = ${value}${comment}\n`;
    }
  });

  code += `    }\n`;
  return code;
}

// Generate Semantic Radius
function generateRadius(radius, tokens) {
  let code = `\n    /// Corner radius tokens - semantic names for border radius\n`;
  code += `    enum Radius {\n`;

  Object.entries(radius).filter(([key]) => !key.startsWith('$')).forEach(([key, token]) => {
    const tokenValue = token.$value || token;
    const resolvedValue = resolveValue(tokenValue, tokens);
    const value = key === 'circle' ? 999 : parseInt(resolvedValue);
    const comment = token.description ? ` // ${token.description}` : '';
    if (typeof tokenValue === 'string' && tokenValue.includes('primitive') && key !== 'circle') {
      const cleanRef = tokenValue.replace(/[{}]/g, ''); // Remove braces
      const parts = cleanRef.split('.');
      const primitiveRef = `Primitive.Size.${parts[parts.length - 1]}`;
      code += `        static let ${key}: CGFloat = ${primitiveRef}${comment}\n`;
    } else {
      code += `        static let ${key}: CGFloat = ${value}${comment}\n`;
    }
  });

  code += `    }\n`;
  return code;
}

// Generate Semantic Opacity
function generateOpacity(opacity, tokens) {
  let code = `\n    /// Opacity tokens - semantic names for transparency levels\n`;
  code += `    enum Opacity {\n`;

  // Group by category
  code += `        // Glass/UI effects (ultra-transparent)\n`;
  ['glassUltraLight', 'glassLight', 'glassMedium'].forEach(key => {
    if (opacity[key]) {
      const tokenValue = opacity[key].$value || opacity[key];
      const resolvedValue = resolveValue(tokenValue, tokens);
      if (typeof tokenValue === 'string' && tokenValue.includes('primitive')) {
        const cleanRef = tokenValue.replace(/[{}]/g, '');
        const parts = cleanRef.split('.');
        const primitiveRef = `Primitive.Opacity.${parts[parts.length - 1]}`;
        const comment = ` // ${resolvedValue}`;
        code += `        static let ${key}: Double = ${primitiveRef}${comment}\n`;
      } else {
        const comment = ` // ${resolvedValue}`;
        code += `        static let ${key}: Double = ${resolvedValue}${comment}\n`;
      }
    }
  });

  code += `\n        // Overlay effects\n`;
  ['overlayLight', 'overlayMedium', 'overlayStrong'].forEach(key => {
    if (opacity[key]) {
      const tokenValue = opacity[key].$value || opacity[key];
      const resolvedValue = resolveValue(tokenValue, tokens);
      if (typeof tokenValue === 'string' && tokenValue.includes('primitive')) {
        const cleanRef = tokenValue.replace(/[{}]/g, '');
        const parts = cleanRef.split('.');
        const primitiveRef = `Primitive.Opacity.${parts[parts.length - 1]}`;
        const comment = ` // ${resolvedValue}`;
        code += `        static let ${key}: Double = ${primitiveRef}${comment}\n`;
      } else {
        const comment = ` // ${resolvedValue}`;
        code += `        static let ${key}: Double = ${resolvedValue}${comment}\n`;
      }
    }
  });

  code += `\n        // Text hierarchy\n`;
  ['textDisabled', 'textSubtle', 'textTertiary', 'textSecondary', 'textPrimary'].forEach(key => {
    if (opacity[key]) {
      const tokenValue = opacity[key].$value || opacity[key];
      const resolvedValue = resolveValue(tokenValue, tokens);
      if (typeof tokenValue === 'string' && tokenValue.includes('primitive')) {
        const cleanRef = tokenValue.replace(/[{}]/g, '');
        const parts = cleanRef.split('.');
        const primitiveRef = `Primitive.Opacity.${parts[parts.length - 1]}`;
        const comment = ` // ${resolvedValue}`;
        code += `        static let ${key}: Double = ${primitiveRef}${comment}\n`;
      } else {
        const comment = ` // ${resolvedValue}`;
        code += `        static let ${key}: Double = ${resolvedValue}${comment}\n`;
      }
    }
  });

  code += `    }\n`;
  return code;
}

// Generate Colors
function generateColors(colors) {
  let code = `\n    /// Color tokens - using semantic opacity values\n`;
  code += `    enum Colors {\n`;

  // Text hierarchy - map text colors to their semantic opacity values
  code += `        // Text hierarchy (white with semantic opacity)\n`;
  if (colors.text) {
    // Map token names to their opacity reference
    const opacityMap = {
      'primary': 'textPrimary',
      'secondary': 'textSecondary',
      'tertiary': 'textTertiary',
      'subtle': 'textSubtle',
      'faded': 'textDisabled',        // faded uses textDisabled (0.6)
      'placeholder': 'textDisabled'   // placeholder uses textDisabled (0.6)
    };
    Object.entries(colors.text).filter(([key]) => !key.startsWith('$')).forEach(([key, token]) => {
      const opacityRef = opacityMap[key] || `text${key.charAt(0).toUpperCase() + key.slice(1)}`;
      code += `        static let text${key.charAt(0).toUpperCase() + key.slice(1)} = Color.white.opacity(Opacity.${opacityRef})\n`;
    });
  }

  // Borders
  code += `\n        // Borders and dividers\n`;
  if (colors.border) {
    Object.entries(colors.border).filter(([key]) => !key.startsWith('$')).forEach(([key, token]) => {
      const name = key === 'default' ? 'border' : `border${key.charAt(0).toUpperCase() + key.slice(1)}`;
      const opacityKey = key === 'default' ? 'overlayLight' :
                        key === 'strong' ? 'overlayMedium' :
                        key === 'subtle' ? 'glassLight' : 'glassUltraLight';
      code += `        static let ${name} = Color.white.opacity(Opacity.${opacityKey})\n`;
    });
  }

  // Background overlays
  code += `\n        // Background overlays\n`;
  if (colors.overlay) {
    code += `        static let overlay20 = Color.white.opacity(Opacity.overlayLight)\n`;
    code += `        static let overlay10 = Color.white.opacity(Opacity.glassLight)\n`;
    code += `        static let overlay5 = Color.white.opacity(Opacity.glassUltraLight)\n`;
    code += `\n        // Black overlays for backgrounds\n`;
    code += `        static let backgroundDark = Color.black.opacity(0.8)\n`;
    code += `        static let backgroundMedium = Color.black.opacity(0.5)\n`;
    code += `        static let backgroundLight = Color.black.opacity(0.3)\n`;
  }

  // Accent colors
  code += `\n        // Accent colors (from existing usage)\n`;
  if (colors.accent) {
    Object.entries(colors.accent).filter(([key]) => !key.startsWith('$')).forEach(([key, token]) => {
      const colorName = key.charAt(0).toUpperCase() + key.slice(1);
      const opacity = token.opacity || 1.0;
      if (key === 'red') {
        code += `        static let accent${colorName} = Color.${key}\n`;
      } else {
        code += `        static let accent${colorName} = Color.${key}.opacity(${opacity})\n`;
      }
    });
  }

  // Archetype gradients
  code += `\n        // Archetype gradient colors (matching web demo)\n`;
  if (colors.gradients && colors.gradients.mail) {
    const mailStart = hexToRGB(colors.gradients.mail.start.$value);
    const mailEnd = hexToRGB(colors.gradients.mail.end.$value);
    code += `        static let mailGradientStart = Color(red: ${mailStart.r.toFixed(2)}, green: ${mailStart.g.toFixed(2)}, blue: ${mailStart.b.toFixed(2)})      // ${colors.gradients.mail.start.$value} - blue\n`;
    code += `        static let mailGradientEnd = Color(red: ${mailEnd.r.toFixed(2)}, green: ${mailEnd.g.toFixed(2)}, blue: ${mailEnd.b.toFixed(2)})      // ${colors.gradients.mail.end.$value} - purple\n`;
  }
  if (colors.gradients && colors.gradients.ads) {
    const adsStart = hexToRGB(colors.gradients.ads.start.$value);
    const adsEnd = hexToRGB(colors.gradients.ads.end.$value);
    code += `        static let adsGradientStart = Color(red: ${adsStart.r.toFixed(2)}, green: ${adsStart.g.toFixed(2)}, blue: ${adsStart.b.toFixed(2)})     // ${colors.gradients.ads.start.$value} - teal/cyan\n`;
    code += `        static let adsGradientEnd = Color(red: ${adsEnd.r.toFixed(2)}, green: ${adsEnd.g.toFixed(2)}, blue: ${adsEnd.b.toFixed(2)})       // ${colors.gradients.ads.end.$value} - green\n`;
  }

  // Ads-specific text colors
  code += `\n        // Ads-specific text colors (dark text for light backgrounds)\n`;
  if (colors.adsText) {
    Object.entries(colors.adsText).filter(([key]) => !key.startsWith('$')).forEach(([key, token]) => {
      const rgb = hexToRGB(token.$value);
      if (rgb) {
        const opacity = token.opacity || '';
        const opacityCode = opacity ? `.opacity(${opacity})` : '';
        const comment = token.description ? ` // ${token.description}` : '';
        code += `        static let adsText${key.charAt(0).toUpperCase() + key.slice(1)} = Color(red: ${rgb.r.toFixed(2)}, green: ${rgb.g.toFixed(2)}, blue: ${rgb.b.toFixed(2)})${opacityCode}${comment}\n`;
      }
    });
  }

  // Semantic colors
  code += `\n        // Semantic colors (for alerts, states, etc)\n`;
  if (colors.semantic) {
    ['error', 'warning', 'success', 'info'].forEach(state => {
      if (colors.semantic[state]) {
        const primary = colors.semantic[state].primary;
        code += `        static let ${state}Primary = Color.${state === 'error' ? 'red' : state === 'warning' ? 'orange' : state === 'success' ? 'green' : 'blue'}\n`;

        if (colors.semantic[state].background) {
          const bgOpacity = colors.semantic[state].background.opacity || 0.15;
          code += `        static let ${state}Background = Color.${state === 'error' ? 'red' : state === 'warning' ? 'orange' : state === 'success' ? 'green' : 'blue'}.opacity(${bgOpacity})\n`;
        }

        if (colors.semantic[state].border) {
          const borderOpacity = colors.semantic[state].border.opacity || 0.5;
          code += `        static let ${state}Border = Color.${state === 'error' ? 'red' : state === 'warning' ? 'orange' : state === 'success' ? 'green' : 'blue'}.opacity(${borderOpacity})\n`;
        }

        if (colors.semantic[state].text) {
          const textOpacity = colors.semantic[state].text.opacity || 0.8;
          code += `        static let ${state}Text = Color.${state === 'error' ? 'red' : state === 'warning' ? 'orange' : state === 'success' ? 'green' : 'blue'}.opacity(${textOpacity})\n`;
        }

        code += `\n`;
      }
    });
  }

  code = code.trimEnd() + `\n    }\n`;
  return code;
}

// Helper to generate Font.system call with design support
function generateFontCall(token) {
  const size = parseInt(token.$value);
  const weight = token.fontWeight || 'regular';
  const design = token.fontDesign || 'default';
  
  // Map weight strings to Swift weight enum
  const weightMap = {
    'regular': '.regular',
    'medium': '.medium',
    'semibold': '.semibold',
    'bold': '.bold'
  };
  
  const swiftWeight = weightMap[weight] || '.regular';
  const swiftDesign = design === 'default' ? '.default' : `.${design}`;
  
  return `Font.system(size: ${size}, weight: ${swiftWeight}, design: ${swiftDesign})`;
}

// Generate Typography
function generateTypography(typography) {
  let code = `\n    /// Typography tokens - semantic font scale\n`;
  code += `    /// World-class typography with refined hierarchy and optimal readability\n`;
  code += `    enum Typography {\n`;

  const fontSize = typography.fontSize || {};

  // Display
  code += `        // Display (largest) - hero headlines, splash screens\n`;
  if (fontSize.display) {
    code += `        static let displayLarge = ${generateFontCall(fontSize.display.large)}\n`;
    code += `        static let displayMedium = ${generateFontCall(fontSize.display.medium)}\n\n`;
  }

  // Headings
  code += `        // Headings - section titles, card titles\n`;
  if (fontSize.heading) {
    code += `        static let headingLarge = ${generateFontCall(fontSize.heading.large)}\n`;
    code += `        static let headingMedium = ${generateFontCall(fontSize.heading.medium)}\n`;
    code += `        static let headingSmall = ${generateFontCall(fontSize.heading.small)}\n\n`;
  }

  // Body
  code += `        // Body text - main content, readable paragraphs\n`;
  if (fontSize.body) {
    code += `        static let bodyLarge = ${generateFontCall(fontSize.body.large)}\n`;
    code += `        static let bodyMedium = ${generateFontCall(fontSize.body.medium)}\n`;
    code += `        static let bodySmall = ${generateFontCall(fontSize.body.small)}\n\n`;
  }

  // Labels
  code += `        // Labels - UI labels, metadata, timestamps\n`;
  if (fontSize.label) {
    code += `        static let labelLarge = ${generateFontCall(fontSize.label.large)}\n`;
    code += `        static let labelMedium = ${generateFontCall(fontSize.label.medium)}\n`;
    code += `        static let labelSmall = ${generateFontCall(fontSize.label.small)}\n\n`;
  }

  // Card Typography
  if (fontSize.card) {
    code += `        // Email Card Typography (world-class card components)\n`;
    code += `        static let cardTitle = ${generateFontCall(fontSize.card.title)}         // ${fontSize.card.title.description || 'Card title'}\n`;
    code += `        static let cardSender = ${generateFontCall(fontSize.card.sender)}    // ${fontSize.card.sender.description || 'Sender name'}\n`;
    code += `        static let cardSummary = ${generateFontCall(fontSize.card.summary)}    // ${fontSize.card.summary.description || 'Summary text'}\n`;
    code += `        static let cardSectionHeader = ${generateFontCall(fontSize.card.sectionHeader)} // ${fontSize.card.sectionHeader.description || 'Section header'}\n`;
    code += `        static let cardTimestamp = ${generateFontCall(fontSize.card.timestamp)}   // ${fontSize.card.timestamp.description || 'Timestamp'}\n`;
    code += `        static let cardMetadata = ${generateFontCall(fontSize.card.metadata)}   // ${fontSize.card.metadata.description || 'Metadata'}\n\n`;
  }

  // Thread Typography
  if (fontSize.thread) {
    code += `        // Thread Typography (for threaded card views)\n`;
    code += `        static let threadTitle = ${generateFontCall(fontSize.thread.title)}\n`;
    code += `        static let threadSummary = ${generateFontCall(fontSize.thread.summary)}\n`;
    code += `        static let threadMessageSender = ${generateFontCall(fontSize.thread.messageSender)}\n`;
    code += `        static let threadMessageBody = ${generateFontCall(fontSize.thread.messageBody)}\n\n`;
  }

  // Reader Typography
  if (fontSize.reader) {
    code += `        // Reader Typography (world-class email reader)\n`;
    code += `        static let readerSubject = ${generateFontCall(fontSize.reader.subject)}     // ${fontSize.reader.subject.description || 'Subject'}\n`;
    code += `        static let readerSender = ${generateFontCall(fontSize.reader.sender)}  // ${fontSize.reader.sender.description || 'Sender'}\n`;
    code += `        static let readerBody = ${generateFontCall(fontSize.reader.body)}     // ${fontSize.reader.body.description || 'Body'}\n`;
    code += `        static let readerQuote = ${generateFontCall(fontSize.reader.quote)}      // ${fontSize.reader.quote.description || 'Quote'}\n`;
    code += `        static let readerMetadata = ${generateFontCall(fontSize.reader.metadata)}  // ${fontSize.reader.metadata.description || 'Metadata'}\n\n`;
  }

  // Action Typography
  if (fontSize.action) {
    code += `        // Action Typography (buttons, CTAs)\n`;
    code += `        static let actionPrimary = ${generateFontCall(fontSize.action.primary)}\n`;
    code += `        static let actionSecondary = ${generateFontCall(fontSize.action.secondary)}\n`;
    code += `        static let actionTertiary = ${generateFontCall(fontSize.action.tertiary)}\n\n`;
  }

  // Badge Typography
  if (fontSize.badge) {
    code += `        // Badge Typography (status indicators, tags)\n`;
    code += `        static let badgeLarge = ${generateFontCall(fontSize.badge.large)}\n`;
    code += `        static let badgeSmall = ${generateFontCall(fontSize.badge.small)}\n\n`;
  }

  // AI Analysis Typography
  if (fontSize.aiAnalysis) {
    code += `        // AI Analysis Typography (card AI preview section)\n`;
    code += `        static let aiAnalysisTitle = ${generateFontCall(fontSize.aiAnalysis.title)}         // ${fontSize.aiAnalysis.title.description || 'AI Analysis header'}\n`;
    code += `        static let aiAnalysisSectionHeader = ${generateFontCall(fontSize.aiAnalysis.sectionHeader)} // ${fontSize.aiAnalysis.sectionHeader.description || 'Section headers'}\n`;
    code += `        static let aiAnalysisActionText = ${generateFontCall(fontSize.aiAnalysis.actionText)}    // ${fontSize.aiAnalysis.actionText.description || 'Action text'}\n`;
    code += `        static let aiAnalysisContextText = ${generateFontCall(fontSize.aiAnalysis.contextText)}  // ${fontSize.aiAnalysis.contextText.description || 'Context text'}\n`;
    code += `        static let aiAnalysisWhyText = ${generateFontCall(fontSize.aiAnalysis.whyText)}      // ${fontSize.aiAnalysis.whyText.description || 'Why text'}\n`;
  }

  code += `    }\n`;
  return code;
}

// Generate Component Tokens
function generateComponents(components, tokens) {
  let code = `\n    // MARK: - Component Tokens (Compound values for specific components)\n\n`;

  // Card
  if (components.card) {
    code += `    /// Card component tokens\n`;
    code += `    enum Card {\n`;
    code += `        static let padding = Spacing.card\n`;
    code += `        static let radius = Radius.card\n`;
    code += `        static let shadowRadius: CGFloat = ${parseInt(components.card.shadowRadius.$value)}\n`;
    code += `        static let shadowOpacity = Opacity.overlayMedium\n`;
    code += `        static let glassOpacity = Opacity.glassUltraLight\n`;
    code += `    }\n\n`;
  }

  // Button
  if (components.button) {
    code += `    /// Button component tokens\n`;
    code += `    enum Button {\n`;
    code += `        static let padding = Spacing.component\n`;
    code += `        static let radius = Radius.button\n`;
    code += `        static let heightStandard: CGFloat = ${parseInt(components.button.heightStandard.$value)}\n`;
    code += `        static let heightCompact: CGFloat = ${parseInt(components.button.heightCompact.$value)}\n`;
    code += `        static let heightSmall: CGFloat = ${parseInt(components.button.heightSmall.$value)}\n`;
    code += `        static let iconSize: CGFloat = ${parseInt(components.button.iconSize.$value)}\n`;
    code += `    }\n\n`;
  }

  // Modal
  if (components.modal) {
    code += `    /// Modal component tokens\n`;
    code += `    enum Modal {\n`;
    code += `        static let padding = Spacing.modal\n`;
    code += `        static let radius = Radius.modal\n`;
    code += `        static let overlayOpacity = Opacity.overlayStrong\n`;
    code += `    }\n\n`;
  }

  // Badge
  if (components.badge) {
    code += `    /// Badge component tokens\n`;
    code += `    enum Badge {\n`;
    code += `        static let size: CGFloat = ${parseInt(components.badge.size.$value)}\n`;
    code += `        static let sizeLarge: CGFloat = ${parseInt(components.badge.sizeLarge.$value)}\n`;
    code += `        static let offsetX: CGFloat = ${parseInt(components.badge.offsetX.$value)}\n`;
    code += `        static let offsetY: CGFloat = ${parseFloat(components.badge.offsetY.$value)}\n`;
    code += `        static let borderWidth: CGFloat = ${parseInt(components.badge.borderWidth.$value)}\n`;
    code += `    }\n\n`;
  }

  // AlertCard
  if (components.alertCard) {
    code += `    /// Alert component tokens\n`;
    code += `    enum AlertCard {\n`;
    code += `        static let borderWidth: CGFloat = ${parseInt(components.alertCard.borderWidth.$value)}\n`;
    code += `        static let borderWidthSubtle: CGFloat = ${parseInt(components.alertCard.borderWidthSubtle.$value)}\n`;
    code += `    }\n\n`;
  }

  // AI Analysis Box
  if (components.aiAnalysisBox) {
    code += `    /// AI Analysis box component tokens\n`;
    code += `    enum AIAnalysisBox {\n`;
    code += `        static let padding = Spacing.component\n`;
    code += `        static let radius = Radius.button\n`;
    code += `        static let borderWidth: CGFloat = ${parseFloat(components.aiAnalysisBox.borderWidth.$value)}\n`;
    code += `    }\n\n`;
  }

  // Bottom Action Bar
  if (components.bottomActionBar) {
    code += `    /// Bottom action bar component tokens\n`;
    code += `    enum BottomActionBar {\n`;
    code += `        static let height: CGFloat = ${parseInt(components.bottomActionBar.height.$value)}\n`;
    code += `        static let padding = Spacing.element\n`;
    code += `        static let radius = Radius.chip\n`;
    code += `    }\n\n`;
  }

  // Shadow
  if (components.shadow) {
    code += `    /// Shadow preset tokens\n`;
    code += `    enum Shadow {\n`;
    if (components.shadow.card) {
      code += `        static let card = (color: Color.black.opacity(${components.shadow.card.color.opacity}), radius: CGFloat(${parseInt(components.shadow.card.radius.$value)}), x: CGFloat(${parseInt(components.shadow.card.offsetX.$value)}), y: CGFloat(${parseInt(components.shadow.card.offsetY.$value)}))  // Updated to ${components.shadow.card.color.opacity} (web demo)\n`;
    }
    if (components.shadow.button) {
      code += `        static let button = (color: Color.black.opacity(Opacity.overlayLight), radius: CGFloat(${parseInt(components.shadow.button.radius.$value)}), x: CGFloat(${parseInt(components.shadow.button.offsetX.$value)}), y: CGFloat(${parseInt(components.shadow.button.offsetY.$value)}))\n`;
    }
    if (components.shadow.subtle) {
      code += `        static let subtle = (color: Color.black.opacity(Opacity.glassLight), radius: CGFloat(${parseInt(components.shadow.subtle.radius.$value)}), x: CGFloat(${parseInt(components.shadow.subtle.offsetX.$value)}), y: CGFloat(${parseInt(components.shadow.subtle.offsetY.$value)}))\n`;
    }
    code += `    }\n\n`;
  }

  return code;
}

// Generate Animation
function generateAnimation(animation, tokens) {
  let code = `    /// Animation timing tokens\n`;
  code += `    enum Animation {\n`;

  // Duration presets
  if (animation.duration) {
    code += `        // Duration presets\n`;
    Object.entries(animation.duration).filter(([key]) => !key.startsWith('$')).forEach(([key, token]) => {
      const primitiveKey = key === 'standard' ? 'normal' : key;
      code += `        static let ${key} = Primitive.Duration.${primitiveKey}\n`;
    });
    code += `        \n`;
  }

  // Spring presets
  if (animation.spring) {
    code += `        // Spring presets for world-class microinteractions\n`;
    code += `        enum Spring {\n`;
    Object.entries(animation.spring).filter(([key]) => !key.startsWith('$')).forEach(([key, preset]) => {
      if (preset.response && preset.dampingFraction) {
        const response = preset.response.$value !== undefined ? preset.response.$value : preset.response;
        const damping = preset.dampingFraction.$value !== undefined ? preset.dampingFraction.$value : preset.dampingFraction;
        const desc = preset.description || `${key} spring animation`;
        code += `            /// ${desc}\n`;
        code += `            static let ${key} = SwiftUI.Animation.spring(response: ${response}, dampingFraction: ${damping})\n`;
      }
    });
    code += `        }\n`;
    code += `        \n`;
  }

  // Easing presets
  code += `        // Easing presets\n`;
  code += `        enum Ease {\n`;
  code += `            static let \`in\` = SwiftUI.Animation.easeIn(duration: Primitive.Duration.normal)\n`;
  code += `            static let out = SwiftUI.Animation.easeOut(duration: Primitive.Duration.normal)\n`;
  code += `            static let inOut = SwiftUI.Animation.easeInOut(duration: Primitive.Duration.normal)\n`;
  code += `        }\n`;

  code += `    }\n\n`;
  return code;
}

// Generate Materials
function generateMaterials() {
  let code = `    /// Material tokens\n`;
  code += `    enum Materials {\n`;
  code += `        static let glassmorphic: Material = .ultraThinMaterial\n`;
  code += `        static let glassmorphicOpacity: Double = Opacity.glassUltraLight\n`;
  code += `    }\n`;
  return code;
}

// Main generation function
function generateSwift() {
  console.log('🔨 Generating Swift Design Tokens from tokens.json...\n');

  try {
    // Read tokens
    if (!fs.existsSync(INPUT_FILE)) {
      throw new Error(`Tokens file not found: ${INPUT_FILE}`);
    }

    const tokens = JSON.parse(fs.readFileSync(INPUT_FILE, 'utf8'));
    const timestamp = new Date().toISOString();

    // Generate Swift code
    const swiftCode = `import SwiftUI

/// Design Tokens - Semantic naming system for consistent styling
/// Architecture: Primitive values → Semantic tokens → Component tokens
/// Version ${tokens.version}
/// Generated: ${timestamp}
/// DO NOT EDIT MANUALLY - This file is auto-generated from design-system/tokens.json
enum DesignTokens {

${generatePrimitive(tokens.primitive)}

${generateSpacing(tokens.spacing, tokens)}

${generateRadius(tokens.radius, tokens)}

${generateOpacity(tokens.opacity, tokens)}

${generateColors(tokens.colors)}

${generateTypography(tokens.typography)}

${generateComponents(tokens.components, tokens)}

${generateAnimation(tokens.animation, tokens)}

${generateMaterials()}
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
`;

    // Ensure output directory exists
    const outputDir = path.dirname(OUTPUT_FILE);
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // Write Swift file
    fs.writeFileSync(OUTPUT_FILE, swiftCode);

    console.log('✅ Swift tokens generated successfully!');
    console.log(`📄 Output: ${OUTPUT_FILE}\n`);

    // Print summary
    console.log('📊 Generated:');
    console.log(`   - Primitive tokens (Size, Opacity, Blur, Duration)`);
    console.log(`   - ${Object.keys(tokens.spacing).length} spacing tokens`);
    console.log(`   - ${Object.keys(tokens.radius).length} radius tokens`);
    console.log(`   - ${Object.keys(tokens.opacity).length} opacity tokens`);
    console.log(`   - Complete color system (text, borders, overlays, gradients)`);
    console.log(`   - Typography scale (display, heading, body, labels, cards, threads)`);
    console.log(`   - ${Object.keys(tokens.components).length} component token sets`);
    console.log(`   - Animation timing tokens`);
    console.log(`   - Material tokens\n`);

  } catch (error) {
    console.error('❌ Error generating Swift:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  generateSwift();
}

module.exports = { generateSwift };

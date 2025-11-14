/**
 * Zero Design System - Figma Plugin
 *
 * Syncs design tokens from tokens.json to Figma components and styles.
 * Generates components for: Toast, Buttons, Progress Bars, Action Priorities
 */

// Design tokens inlined (Figma doesn't support module imports)
const tokens = {
  "colors": {
    "primary": {
      "white": { "$value": "#FFFFFF", "description": "Primary text color on dark backgrounds" },
      "black": { "$value": "#000000", "description": "Primary background for toasts and overlays" },
      "gray": { "$value": "#8E8E93", "description": "Secondary text and disabled states" }
    },
    "semantic": {
      "success": { "$value": "#34C759", "description": "Success states, confirmations" },
      "error": { "$value": "#FF3B30", "description": "Error states, destructive actions" },
      "warning": { "$value": "#FF9500", "description": "Warning states, attention needed" },
      "info": { "$value": "#007AFF", "description": "Informational states, links" }
    },
    "opacity": {
      "high": { "$value": 0.92, "description": "Toast backgrounds, high opacity overlays" },
      "medium": { "$value": 0.6, "description": "Secondary text, countdown numbers" },
      "mediumLow": { "$value": 0.4, "description": "Ring progress indicators" },
      "low": { "$value": 0.3, "description": "Progress bars, subtle indicators" },
      "veryLow": { "$value": 0.1, "description": "Background tracks, subtle dividers" }
    }
  },
  "typography": {
    "fontSizes": {
      "xs": { "$value": "12px", "description": "Captions, metadata" },
      "sm": { "$value": "13px", "description": "Countdown numbers, secondary labels" },
      "base": { "$value": "15px", "description": "Body text, toast messages" },
      "lg": { "$value": "17px", "description": "Primary headlines, navigation" },
      "xl": { "$value": "20px", "description": "Icons, buttons" },
      "2xl": { "$value": "24px", "description": "Section headers" },
      "3xl": { "$value": "32px", "description": "Page titles" }
    },
    "fontWeights": {
      "regular": { "$value": 400, "description": "Body text, labels" },
      "medium": { "$value": 500, "description": "Emphasis, countdown numbers" },
      "semibold": { "$value": 600, "description": "Headings, important actions" },
      "bold": { "$value": 700, "description": "Strong emphasis, alerts" }
    },
    "lineHeights": {
      "tight": { "$value": "1.2", "description": "Headings, single-line text" },
      "normal": { "$value": "1.5", "description": "Body text, multi-line content" },
      "relaxed": { "$value": "1.75", "description": "Long-form content" }
    }
  },
  "spacing": {
    "0": { "$value": "0px" },
    "1": { "$value": "4px", "description": "Tight spacing (progress bar padding)" },
    "2": { "$value": "8px", "description": "Close elements (icon to text)" },
    "3": { "$value": "12px", "description": "Related elements (button groups)" },
    "4": { "$value": "16px", "description": "Component padding (toast horizontal)" },
    "5": { "$value": "20px", "description": "Container padding (toast from edge)" },
    "6": { "$value": "24px", "description": "Section spacing (toast from bottom)" },
    "8": { "$value": "32px", "description": "Large section spacing (iPad)" }
  },
  "sizing": {
    "touchTarget": { "$value": "44px", "description": "Minimum touch target (iOS HIG)" },
    "iconSm": { "$value": "16px", "description": "Small icons" },
    "iconBase": { "$value": "20px", "description": "Standard icons (undo button)" },
    "iconLg": { "$value": "24px", "description": "Large icons" },
    "progressBar": { "$value": "2px", "description": "Progress bar height" },
    "ringStroke": { "$value": "2px", "description": "Circular ring stroke width" }
  },
  "borderRadius": {
    "none": { "$value": "0px" },
    "sm": { "$value": "1px", "description": "Progress bar corners" },
    "base": { "$value": "8px", "description": "Buttons, cards" },
    "lg": { "$value": "12px", "description": "Toast, modals" },
    "xl": { "$value": "16px", "description": "Large cards" },
    "full": { "$value": "9999px", "description": "Pills, circular elements" }
  },
  "actionPriorities": {
    "critical": { "value": 95, "color": "#FF3B30", "description": "Life-critical, legal, high-stakes financial" },
    "veryHigh": { "value": 90, "color": "#FF9500", "description": "Time-sensitive, high-value actions" },
    "high": { "value": 85, "color": "#FFCC00", "description": "Important but not urgent" },
    "mediumHigh": { "value": 80, "color": "#34C759", "description": "Useful with moderate impact" },
    "medium": { "value": 75, "color": "#32ADE6", "description": "Standard actions with clear value" },
    "mediumLow": { "value": 70, "color": "#007AFF", "description": "Helpful but not essential" },
    "low": { "value": 65, "color": "#5856D6", "description": "Nice-to-have features" },
    "veryLow": { "value": 60, "color": "#8E8E93", "description": "Utility actions, fallbacks" }
  },
  "archetypes": {
    "mail": {
      "displayName": "Mail",
      "gradient": {
        "start": "#3b82f6",
        "end": "#0ea5e9"
      }
    },
    "ads": {
      "displayName": "Ads",
      "gradient": {
        "start": "#10b981",
        "end": "#34ecb3"
      }
    }
  }
} as any;

// Global font family (set during initialization)
let FONT_FAMILY = 'Inter';
let FONT_WEIGHTS = {
  regular: 'Regular',
  medium: 'Medium',
  semibold: 'Semi Bold',  // Note: Inter uses "Semi Bold" with a space
  bold: 'Bold'
};

// Helper: Convert hex to RGB
function hexToRgb(hex: string): RGB {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) throw new Error(`Invalid hex color: ${hex}`);

  return {
    r: parseInt(result[1], 16) / 255,
    g: parseInt(result[2], 16) / 255,
    b: parseInt(result[3], 16) / 255
  };
}

// Helper: Resolve token references (e.g., "{colors.primary.white}")
function resolveToken(value: string, tokensObj: any): any {
  if (typeof value !== 'string' || !value.startsWith('{')) {
    return value;
  }

  const path = value.slice(1, -1).split('.');
  let result = tokensObj;

  for (const key of path) {
    result = result[key];
    if (result === undefined) return value;
  }

  return result.$value || result;
}

// ===== FOUNDATION TOKEN VISUALIZATIONS =====

// Create Color Palette Visualization
function createColorPalette() {
  figma.notify('Creating color palette...');

  const frame = figma.createFrame();
  frame.name = '🎨 Color Palette';
  frame.layoutMode = 'VERTICAL';
  frame.itemSpacing = 24;
  frame.paddingLeft = 24;
  frame.paddingRight = 24;
  frame.paddingTop = 24;
  frame.paddingBottom = 24;
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = 'AUTO';
  frame.fills = [{
    type: 'SOLID',
    color: hexToRgb('#F5F5F7')
  }];

  // Title
  const title = figma.createText();
  title.name = 'Title';
  title.characters = 'Color Palette';
  title.fontSize = 24;
  title.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  title.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
  frame.appendChild(title);

  // Primary Colors
  const primarySection = figma.createFrame();
  primarySection.name = 'Primary';
  primarySection.layoutMode = 'VERTICAL';
  primarySection.itemSpacing = 12;
  primarySection.primaryAxisSizingMode = 'AUTO';
  primarySection.counterAxisSizingMode = 'AUTO';
  primarySection.fills = [];

  const primaryLabel = figma.createText();
  primaryLabel.characters = 'Primary Colors';
  primaryLabel.fontSize = 16;
  primaryLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  primaryLabel.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
  primarySection.appendChild(primaryLabel);

  const primaryColors = figma.createFrame();
  primaryColors.layoutMode = 'HORIZONTAL';
  primaryColors.itemSpacing = 12;
  primaryColors.primaryAxisSizingMode = 'AUTO';
  primaryColors.fills = [];

  Object.entries(tokens.colors.primary).forEach(([name, data]: [string, any]) => {
    if (name === '$type') return;

    const colorCard = figma.createFrame();
    colorCard.name = name;
    colorCard.layoutMode = 'VERTICAL';
    colorCard.itemSpacing = 8;
    colorCard.primaryAxisSizingMode = 'AUTO';
    colorCard.counterAxisSizingMode = 'AUTO';
    colorCard.fills = [];

    const swatch = figma.createFrame();
    swatch.resize(100, 100);
    swatch.cornerRadius = 12;
    swatch.fills = [{ type: 'SOLID', color: hexToRgb(data.$value) }];
    colorCard.appendChild(swatch);

    const colorName = figma.createText();
    colorName.characters = name.charAt(0).toUpperCase() + name.slice(1);
    colorName.fontSize = 14;
    colorName.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
    colorName.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
    colorCard.appendChild(colorName);

    const colorValue = figma.createText();
    colorValue.characters = data.$value;
    colorValue.fontSize = 12;
    colorValue.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    colorValue.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
    colorCard.appendChild(colorValue);

    primaryColors.appendChild(colorCard);
  });

  primarySection.appendChild(primaryColors);
  frame.appendChild(primarySection);

  // Semantic Colors
  const semanticSection = figma.createFrame();
  semanticSection.name = 'Semantic';
  semanticSection.layoutMode = 'VERTICAL';
  semanticSection.itemSpacing = 12;
  semanticSection.primaryAxisSizingMode = 'AUTO';
  semanticSection.counterAxisSizingMode = 'AUTO';
  semanticSection.fills = [];

  const semanticLabel = figma.createText();
  semanticLabel.characters = 'Semantic Colors';
  semanticLabel.fontSize = 16;
  semanticLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  semanticLabel.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
  semanticSection.appendChild(semanticLabel);

  const semanticColors = figma.createFrame();
  semanticColors.layoutMode = 'HORIZONTAL';
  semanticColors.itemSpacing = 12;
  semanticColors.primaryAxisSizingMode = 'AUTO';
  semanticColors.fills = [];

  Object.entries(tokens.colors.semantic).forEach(([name, data]: [string, any]) => {
    if (name === '$type') return;

    const colorCard = figma.createFrame();
    colorCard.name = name;
    colorCard.layoutMode = 'VERTICAL';
    colorCard.itemSpacing = 8;
    colorCard.primaryAxisSizingMode = 'AUTO';
    colorCard.counterAxisSizingMode = 'AUTO';
    colorCard.fills = [];

    const swatch = figma.createFrame();
    swatch.resize(100, 100);
    swatch.cornerRadius = 12;
    swatch.fills = [{ type: 'SOLID', color: hexToRgb(data.$value) }];
    colorCard.appendChild(swatch);

    const colorName = figma.createText();
    colorName.characters = name.charAt(0).toUpperCase() + name.slice(1);
    colorName.fontSize = 14;
    colorName.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
    colorName.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
    colorCard.appendChild(colorName);

    const colorValue = figma.createText();
    colorValue.characters = data.$value;
    colorValue.fontSize = 12;
    colorValue.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    colorValue.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
    colorCard.appendChild(colorValue);

    const description = figma.createText();
    description.characters = data.description || '';
    description.fontSize = 11;
    description.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    description.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
    description.resize(100, 30);
    colorCard.appendChild(description);

    semanticColors.appendChild(colorCard);
  });

  semanticSection.appendChild(semanticColors);
  frame.appendChild(semanticSection);

  // Opacity Scale
  const opacitySection = figma.createFrame();
  opacitySection.name = 'Opacity';
  opacitySection.layoutMode = 'VERTICAL';
  opacitySection.itemSpacing = 12;
  opacitySection.primaryAxisSizingMode = 'AUTO';
  opacitySection.counterAxisSizingMode = 'AUTO';
  opacitySection.fills = [];

  const opacityLabel = figma.createText();
  opacityLabel.characters = 'Opacity Scale';
  opacityLabel.fontSize = 16;
  opacityLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  opacityLabel.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
  opacitySection.appendChild(opacityLabel);

  Object.entries(tokens.colors.opacity).forEach(([name, data]: [string, any]) => {
    if (name === '$type') return;

    const row = figma.createFrame();
    row.layoutMode = 'HORIZONTAL';
    row.itemSpacing = 16;
    row.counterAxisAlignItems = 'CENTER';
    row.primaryAxisSizingMode = 'AUTO';
    row.fills = [];

    const opacityBox = figma.createFrame();
    opacityBox.resize(100, 40);
    opacityBox.cornerRadius = 8;
    opacityBox.fills = [{
      type: 'SOLID',
      color: hexToRgb(tokens.colors.primary.black.$value),
      opacity: data.$value
    }];
    opacityBox.strokes = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
    opacityBox.strokeWeight = 1;
    row.appendChild(opacityBox);

    const label = figma.createText();
    label.characters = `${name}: ${data.$value} - ${data.description || ''}`;
    label.fontSize = 14;
    label.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    label.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
    row.appendChild(label);

    opacitySection.appendChild(row);
  });

  frame.appendChild(opacitySection);

  figma.currentPage.appendChild(frame);
  return frame;
}

// Create Spacing Scale Visualization
function createSpacingScale() {
  figma.notify('Creating spacing scale...');

  const frame = figma.createFrame();
  frame.name = '📏 Spacing Scale';
  frame.layoutMode = 'VERTICAL';
  frame.itemSpacing = 16;
  frame.paddingLeft = 24;
  frame.paddingRight = 24;
  frame.paddingTop = 24;
  frame.paddingBottom = 24;
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = 'AUTO';
  frame.fills = [{
    type: 'SOLID',
    color: hexToRgb('#F5F5F7')
  }];

  // Title
  const title = figma.createText();
  title.name = 'Title';
  title.characters = 'Spacing Scale';
  title.fontSize = 24;
  title.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  title.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
  frame.appendChild(title);

  // Create spacing swatches
  Object.entries(tokens.spacing).forEach(([name, data]: [string, any]) => {
    const row = figma.createFrame();
    row.name = `Spacing ${name}`;
    row.layoutMode = 'HORIZONTAL';
    row.itemSpacing = 16;
    row.counterAxisAlignItems = 'CENTER';
    row.primaryAxisSizingMode = 'AUTO';
    row.counterAxisSizingMode = 'AUTO';
    row.fills = [];

    // Spacing box visualization
    const box = figma.createFrame();
    box.name = 'Box';
    const sizeValue = parseInt(data.$value);
    box.resize(sizeValue || 1, 40);
    box.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.semantic.info.$value), opacity: 0.3 }];
    row.appendChild(box);

    // Label
    const label = figma.createText();
    label.characters = `${name}: ${data.$value}${data.description ? ` - ${data.description}` : ''}`;
    label.fontSize = 14;
    label.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    label.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
    row.appendChild(label);

    frame.appendChild(row);
  });

  figma.currentPage.appendChild(frame);
  return frame;
}

// Create Sizing Tokens Visualization
function createSizingTokens() {
  figma.notify('Creating sizing tokens...');

  const frame = figma.createFrame();
  frame.name = '📐 Sizing Tokens';
  frame.layoutMode = 'VERTICAL';
  frame.itemSpacing = 16;
  frame.paddingLeft = 24;
  frame.paddingRight = 24;
  frame.paddingTop = 24;
  frame.paddingBottom = 24;
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = 'AUTO';
  frame.fills = [{
    type: 'SOLID',
    color: hexToRgb('#F5F5F7')
  }];

  // Title
  const title = figma.createText();
  title.name = 'Title';
  title.characters = 'Sizing Tokens';
  title.fontSize = 24;
  title.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  title.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
  frame.appendChild(title);

  // Create sizing examples
  Object.entries(tokens.sizing).forEach(([name, data]: [string, any]) => {
    const row = figma.createFrame();
    row.name = `Size ${name}`;
    row.layoutMode = 'HORIZONTAL';
    row.itemSpacing = 16;
    row.counterAxisAlignItems = 'CENTER';
    row.primaryAxisSizingMode = 'AUTO';
    row.counterAxisSizingMode = 'AUTO';
    row.fills = [];

    // Size box visualization
    const box = figma.createFrame();
    box.name = 'Box';
    const sizeValue = parseInt(data.$value);
    box.resize(sizeValue, sizeValue);
    box.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.semantic.success.$value), opacity: 0.3 }];
    box.strokes = [{ type: 'SOLID', color: hexToRgb(tokens.colors.semantic.success.$value) }];
    box.strokeWeight = 1;
    row.appendChild(box);

    // Label
    const label = figma.createText();
    label.characters = `${name}: ${data.$value}${data.description ? ` - ${data.description}` : ''}`;
    label.fontSize = 14;
    label.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    label.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
    row.appendChild(label);

    frame.appendChild(row);
  });

  figma.currentPage.appendChild(frame);
  return frame;
}

// Create Border Radius Visualization
function createBorderRadiusScale() {
  figma.notify('Creating border radius scale...');

  const frame = figma.createFrame();
  frame.name = '🔘 Border Radius';
  frame.layoutMode = 'VERTICAL';
  frame.itemSpacing = 16;
  frame.paddingLeft = 24;
  frame.paddingRight = 24;
  frame.paddingTop = 24;
  frame.paddingBottom = 24;
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = 'AUTO';
  frame.fills = [{
    type: 'SOLID',
    color: hexToRgb('#F5F5F7')
  }];

  // Title
  const title = figma.createText();
  title.name = 'Title';
  title.characters = 'Border Radius Scale';
  title.fontSize = 24;
  title.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  title.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
  frame.appendChild(title);

  // Create radius examples
  Object.entries(tokens.borderRadius).forEach(([name, data]: [string, any]) => {
    const row = figma.createFrame();
    row.name = `Radius ${name}`;
    row.layoutMode = 'HORIZONTAL';
    row.itemSpacing = 16;
    row.counterAxisAlignItems = 'CENTER';
    row.primaryAxisSizingMode = 'AUTO';
    row.counterAxisSizingMode = 'AUTO';
    row.fills = [];

    // Radius box visualization
    const box = figma.createFrame();
    box.name = 'Box';
    box.resize(80, 80);
    const radiusValue = parseInt(data.$value);
    box.cornerRadius = Math.min(radiusValue, 40); // Cap at half the size for visibility
    box.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.semantic.warning.$value), opacity: 0.3 }];
    box.strokes = [{ type: 'SOLID', color: hexToRgb(tokens.colors.semantic.warning.$value) }];
    box.strokeWeight = 2;
    row.appendChild(box);

    // Label
    const label = figma.createText();
    label.characters = `${name}: ${data.$value}${data.description ? ` - ${data.description}` : ''}`;
    label.fontSize = 14;
    label.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    label.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
    row.appendChild(label);

    frame.appendChild(row);
  });

  figma.currentPage.appendChild(frame);
  return frame;
}

// Create Archetypes Visualization
function createArchetypesDisplay() {
  figma.notify('Creating archetypes display...');

  const frame = figma.createFrame();
  frame.name = '🎨 Archetypes';
  frame.layoutMode = 'VERTICAL';
  frame.itemSpacing = 16;
  frame.paddingLeft = 24;
  frame.paddingRight = 24;
  frame.paddingTop = 24;
  frame.paddingBottom = 24;
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = 'AUTO';
  frame.fills = [{
    type: 'SOLID',
    color: hexToRgb('#F5F5F7')
  }];

  // Title
  const title = figma.createText();
  title.name = 'Title';
  title.characters = 'Archetypes';
  title.fontSize = 24;
  title.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  title.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
  frame.appendChild(title);

  // Create archetype examples
  Object.entries(tokens.archetypes).forEach(([name, data]: [string, any]) => {
    const row = figma.createFrame();
    row.name = `Archetype ${name}`;
    row.layoutMode = 'HORIZONTAL';
    row.itemSpacing = 16;
    row.counterAxisAlignItems = 'CENTER';
    row.primaryAxisSizingMode = 'AUTO';
    row.counterAxisSizingMode = 'AUTO';
    row.fills = [];

    // Gradient box visualization
    const box = figma.createFrame();
    box.name = 'Gradient Box';
    box.resize(200, 80);
    box.cornerRadius = 12;
    const startRgb = hexToRgb(data.gradient.start);
    const endRgb = hexToRgb(data.gradient.end);
    box.fills = [{
      type: 'GRADIENT_LINEAR',
      gradientTransform: [
        [1, 0, 0],
        [0, 1, 0]
      ],
      gradientStops: [
        { position: 0, color: { r: startRgb.r, g: startRgb.g, b: startRgb.b, a: 1 } },
        { position: 1, color: { r: endRgb.r, g: endRgb.g, b: endRgb.b, a: 1 } }
      ]
    }];
    row.appendChild(box);

    // Info section
    const infoSection = figma.createFrame();
    infoSection.layoutMode = 'VERTICAL';
    infoSection.itemSpacing = 4;
    infoSection.primaryAxisSizingMode = 'AUTO';
    infoSection.counterAxisSizingMode = 'AUTO';
    infoSection.fills = [];

    const nameLabel = figma.createText();
    nameLabel.characters = data.displayName;
    nameLabel.fontSize = 16;
    nameLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
    nameLabel.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
    infoSection.appendChild(nameLabel);

    const startColor = figma.createText();
    startColor.characters = `Start: ${data.gradient.start}`;
    startColor.fontSize = 13;
    startColor.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    startColor.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
    infoSection.appendChild(startColor);

    const endColor = figma.createText();
    endColor.characters = `End: ${data.gradient.end}`;
    endColor.fontSize = 13;
    endColor.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    endColor.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
    infoSection.appendChild(endColor);

    row.appendChild(infoSection);
    frame.appendChild(row);
  });

  figma.currentPage.appendChild(frame);
  return frame;
}

// Create Typography Specimen with all combinations
function createTypographySpecimen() {
  figma.notify('Creating typography specimen...');

  const frame = figma.createFrame();
  frame.name = '✏️ Typography Specimen';
  frame.layoutMode = 'VERTICAL';
  frame.itemSpacing = 24;
  frame.paddingLeft = 24;
  frame.paddingRight = 24;
  frame.paddingTop = 24;
  frame.paddingBottom = 24;
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = 'AUTO';
  frame.fills = [{
    type: 'SOLID',
    color: hexToRgb('#F5F5F7')
  }];

  // Title with font family
  const title = figma.createText();
  title.name = 'Title';
  title.characters = 'Typography Specimen';
  title.fontSize = 24;
  title.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  title.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
  frame.appendChild(title);

  // Font family info
  const fontInfo = figma.createText();
  fontInfo.name = 'Font Info';
  fontInfo.characters = `Font Family: ${FONT_FAMILY}`;
  fontInfo.fontSize = 14;
  fontInfo.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  fontInfo.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
  frame.appendChild(fontInfo);

  // Font Weights Section
  const weightsSection = figma.createFrame();
  weightsSection.name = 'Font Weights';
  weightsSection.layoutMode = 'VERTICAL';
  weightsSection.itemSpacing = 8;
  weightsSection.primaryAxisSizingMode = 'AUTO';
  weightsSection.counterAxisSizingMode = 'AUTO';
  weightsSection.fills = [];

  const weightsTitle = figma.createText();
  weightsTitle.characters = 'Font Weights';
  weightsTitle.fontSize = 16;
  weightsTitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  weightsTitle.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
  weightsSection.appendChild(weightsTitle);

  Object.entries(tokens.typography.fontWeights).forEach(([name, data]: [string, any]) => {
    const weightRow = figma.createFrame();
    weightRow.layoutMode = 'HORIZONTAL';
    weightRow.itemSpacing = 12;
    weightRow.counterAxisAlignItems = 'CENTER';
    weightRow.primaryAxisSizingMode = 'AUTO';
    weightRow.fills = [];

    const valueLabel = figma.createText();
    valueLabel.characters = `${name}: ${data.$value}`;
    valueLabel.fontSize = 13;
    valueLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.medium };
    valueLabel.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
    weightRow.appendChild(valueLabel);

    const example = figma.createText();
    example.characters = `Example Text (${name})`;
    example.fontSize = 15;
    example.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS[name as keyof typeof FONT_WEIGHTS] };
    example.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
    weightRow.appendChild(example);

    weightsSection.appendChild(weightRow);
  });

  frame.appendChild(weightsSection);

  // Line Heights Section
  const lineHeightsSection = figma.createFrame();
  lineHeightsSection.name = 'Line Heights';
  lineHeightsSection.layoutMode = 'VERTICAL';
  lineHeightsSection.itemSpacing = 8;
  lineHeightsSection.primaryAxisSizingMode = 'AUTO';
  lineHeightsSection.counterAxisSizingMode = 'AUTO';
  lineHeightsSection.fills = [];

  const lineHeightsTitle = figma.createText();
  lineHeightsTitle.characters = 'Line Heights';
  lineHeightsTitle.fontSize = 16;
  lineHeightsTitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  lineHeightsTitle.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
  lineHeightsSection.appendChild(lineHeightsTitle);

  Object.entries(tokens.typography.lineHeights).forEach(([name, data]: [string, any]) => {
    const lhRow = figma.createFrame();
    lhRow.layoutMode = 'VERTICAL';
    lhRow.itemSpacing = 4;
    lhRow.primaryAxisSizingMode = 'AUTO';
    lhRow.counterAxisSizingMode = 'AUTO';
    lhRow.fills = [];

    const valueLabel = figma.createText();
    valueLabel.characters = `${name}: ${data.$value} - ${data.description || ''}`;
    valueLabel.fontSize = 13;
    valueLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.medium };
    valueLabel.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
    lhRow.appendChild(valueLabel);

    const example = figma.createText();
    example.characters = `Line height ${data.$value} example\nSecond line to demonstrate spacing\nThird line to show the effect`;
    example.fontSize = 14;
    example.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    example.lineHeight = { value: parseFloat(data.$value) * 100, unit: 'PERCENT' };
    example.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
    example.resize(350, example.height);
    lhRow.appendChild(example);

    lineHeightsSection.appendChild(lhRow);
  });

  frame.appendChild(lineHeightsSection);

  // For each font size, show all weights including bold
  Object.entries(tokens.typography.fontSizes).forEach(([sizeName, sizeData]: [string, any]) => {
    const sizeGroup = figma.createFrame();
    sizeGroup.name = sizeName.toUpperCase();
    sizeGroup.layoutMode = 'VERTICAL';
    sizeGroup.itemSpacing = 8;
    sizeGroup.primaryAxisSizingMode = 'AUTO';
    sizeGroup.counterAxisSizingMode = 'AUTO';
    sizeGroup.fills = [];

    // Size label
    const sizeLabel = figma.createText();
    sizeLabel.characters = `${sizeName.toUpperCase()} (${sizeData.$value}) - ${sizeData.description || ''}`;
    sizeLabel.fontSize = 12;
    sizeLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.medium };
    sizeLabel.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
    sizeGroup.appendChild(sizeLabel);

    // Show all 4 weights for this size
    ['regular', 'medium', 'semibold', 'bold'].forEach(weight => {
      const specimen = figma.createText();
      specimen.characters = `The quick brown fox jumps over the lazy dog (${weight})`;
      specimen.fontSize = parseInt(sizeData.$value);
      specimen.fontName = {
        family: FONT_FAMILY,
        style: FONT_WEIGHTS[weight as keyof typeof FONT_WEIGHTS]
      };
      specimen.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
      sizeGroup.appendChild(specimen);
    });

    frame.appendChild(sizeGroup);
  });

  figma.currentPage.appendChild(frame);
  return frame;
}

// Create Color Styles
function createColorStyles() {
  figma.notify('Creating color styles...');

  const colorStyles: { [key: string]: PaintStyle } = {};

  // Primary colors
  Object.entries(tokens.colors.primary).forEach(([name, data]: [string, any]) => {
    if (name === '$type') return;

    const style = figma.createPaintStyle();
    style.name = `Colors/Primary/${name.charAt(0).toUpperCase() + name.slice(1)}`;
    style.description = data.description || '';
    style.paints = [{
      type: 'SOLID',
      color: hexToRgb(data.$value)
    }];

    colorStyles[name] = style;
  });

  // Semantic colors
  Object.entries(tokens.colors.semantic).forEach(([name, data]: [string, any]) => {
    if (name === '$type') return;

    const style = figma.createPaintStyle();
    style.name = `Colors/Semantic/${name.charAt(0).toUpperCase() + name.slice(1)}`;
    style.description = data.description || '';
    style.paints = [{
      type: 'SOLID',
      color: hexToRgb(data.$value)
    }];

    colorStyles[name] = style;
  });

  // Action priority colors
  Object.entries(tokens.actionPriorities).forEach(([name, data]: [string, any]) => {
    if (name === '$type') return;

    const style = figma.createPaintStyle();
    style.name = `Colors/Priority/${name.charAt(0).toUpperCase() + name.slice(1)}`;
    style.description = `${data.description} (Priority: ${data.value})`;
    style.paints = [{
      type: 'SOLID',
      color: hexToRgb(data.color)
    }];
  });

  return colorStyles;
}

// Create Text Styles
function createTextStyles() {
  figma.notify('Creating text styles...');

  const textStyles: { [key: string]: TextStyle } = {};

  Object.entries(tokens.typography.fontSizes).forEach(([size, data]: [string, any]) => {
    if (size === '$type') return;

    const fontSize = parseInt(data.$value);

    // Create variants: Regular, Medium, Semibold
    ['regular', 'medium', 'semibold'].forEach(weight => {
      const style = figma.createTextStyle();
      const weightName = weight.charAt(0).toUpperCase() + weight.slice(1);
      style.name = `Text/${size.toUpperCase()}/${weightName}`;
      style.fontSize = fontSize;
      style.fontName = {
        family: FONT_FAMILY,
        style: FONT_WEIGHTS[weight as keyof typeof FONT_WEIGHTS]
      };
      style.lineHeight = {
        value: parseFloat(tokens.typography.lineHeights.normal.$value),
        unit: 'PERCENT'
      };

      textStyles[`${size}-${weight}`] = style;
    });
  });

  return textStyles;
}

// Create Toast Component
function createToastComponent(colorStyles: any, textStyles: any) {
  figma.notify('Creating toast component...');

  const component = figma.createComponent();
  component.name = 'Toast/Undo';
  component.resize(342, 54); // 90% of 380px max

  // Background with blur
  const background = figma.createRectangle();
  background.name = 'Background';
  background.resize(342, 54);
  background.cornerRadius = 12;
  background.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.black.$value),
    opacity: tokens.colors.opacity.high.$value
  }];
  // Note: Material blur effect applied in iOS - Figma doesn't support background blur
  // background.effects = [{
  //   type: 'LAYER_BLUR',
  //   radius: 20,
  //   visible: true
  // }];

  component.appendChild(background);

  // Message text
  const messageText = figma.createText();
  messageText.name = 'Message';
  messageText.x = 16;
  messageText.y = 12;
  messageText.resize(250, 30);
  messageText.characters = 'Action completed. Tap to undo.';
  messageText.fontSize = 15;
  messageText.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value)
  }];

  component.appendChild(messageText);

  // Undo button (icon)
  const undoButton = figma.createFrame();
  undoButton.name = 'Undo Button';
  undoButton.x = 282;
  undoButton.y = 5;
  undoButton.resize(44, 44);
  undoButton.cornerRadius = 22;
  undoButton.fills = [];

  // Icon placeholder (you'd import actual icon)
  const iconText = figma.createText();
  iconText.characters = '↶';
  iconText.fontSize = 20;
  iconText.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value)
  }];
  iconText.x = 12;
  iconText.y = 10;

  undoButton.appendChild(iconText);
  component.appendChild(undoButton);

  // Progress bar
  const progressBarContainer = figma.createFrame();
  progressBarContainer.name = 'Progress Bar';
  progressBarContainer.x = 16;
  progressBarContainer.y = 48;
  progressBarContainer.resize(310, 2);
  progressBarContainer.fills = [];

  // Background track
  const progressBg = figma.createRectangle();
  progressBg.name = 'Track';
  progressBg.resize(310, 2);
  progressBg.cornerRadius = 1;
  progressBg.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: tokens.colors.opacity.veryLow.$value
  }];
  progressBarContainer.appendChild(progressBg);

  // Progress fill (70% example)
  const progressFill = figma.createRectangle();
  progressFill.name = 'Fill';
  progressFill.resize(217, 2); // 70% of 310
  progressFill.cornerRadius = 1;
  progressFill.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: tokens.colors.opacity.low.$value
  }];
  progressBarContainer.appendChild(progressFill);

  component.appendChild(progressBarContainer);

  return component;
}

// Create Progress Bar Variants
function createProgressBarVariants() {
  figma.notify('Creating progress bar variants...');

  const componentSet = figma.combineAsVariants([], figma.currentPage);
  componentSet.name = 'Progress Bar';

  // Linear variant
  const linearVariant = figma.createComponent();
  linearVariant.name = 'Style=Linear';
  linearVariant.resize(310, 2);

  const linearBg = figma.createRectangle();
  linearBg.resize(310, 2);
  linearBg.cornerRadius = 1;
  linearBg.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: tokens.colors.opacity.veryLow.$value
  }];
  linearVariant.appendChild(linearBg);

  const linearFill = figma.createRectangle();
  linearFill.resize(217, 2);
  linearFill.cornerRadius = 1;
  linearFill.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: tokens.colors.opacity.low.$value
  }];
  linearVariant.appendChild(linearFill);

  componentSet.appendChild(linearVariant);

  return componentSet;
}

// Create Modal Template (matches iOS ActionOptionsModal)
function createModalTemplate() {
  figma.notify('Creating modal template...');

  const frame = figma.createFrame();
  frame.name = 'Modal/Action Options';
  frame.resize(390, 844); // iPhone 14 size
  frame.fills = [];

  // Backdrop
  const backdrop = figma.createRectangle();
  backdrop.name = 'Backdrop';
  backdrop.resize(390, 844);
  backdrop.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.black.$value),
    opacity: 0.4
  }];

  frame.appendChild(backdrop);

  // Modal Container with gradient (iOS: uses archetype gradient background)
  const container = figma.createFrame();
  container.name = 'Container';
  container.resize(350, 500);
  container.x = 20;
  container.y = 172; // Centered
  container.cornerRadius = 20; // iOS: Modal radius 20

  // Gradient background (Mail archetype gradient)
  const startColor = hexToRgb(tokens.archetypes.mail.gradient.start);
  const endColor = hexToRgb(tokens.archetypes.mail.gradient.end);

  container.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [
      [0.7071067811865476, 0.7071067811865475, 0],
      [-0.7071067811865475, 0.7071067811865476, 1]
    ],
    gradientStops: [
      { position: 0, color: { r: startColor.r, g: startColor.g, b: startColor.b, a: 1 } },
      { position: 1, color: { r: endColor.r, g: endColor.g, b: endColor.b, a: 1 } }
    ]
  }];

  // Header section
  const headerSection = figma.createFrame();
  headerSection.name = 'Header';
  headerSection.resize(302, 60);
  headerSection.x = 24;
  headerSection.y = 24;
  headerSection.fills = [];
  headerSection.layoutMode = 'VERTICAL';
  headerSection.itemSpacing = 4;

  const header = figma.createText();
  header.name = 'Title';
  header.characters = 'Choose Action';
  header.fontSize = 22; // iOS: title2.bold
  header.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  header.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value)
  }];

  headerSection.appendChild(header);

  const subtitle = figma.createText();
  subtitle.name = 'Subtitle';
  subtitle.characters = 'Select your preferred action';
  subtitle.fontSize = 14; // iOS: subheadline
  subtitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  subtitle.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.7
  }];

  headerSection.appendChild(subtitle);
  container.appendChild(headerSection);

  // Divider
  const divider = figma.createLine();
  divider.name = 'Divider';
  divider.resize(350, 0);
  divider.x = 0;
  divider.y = 100;
  divider.strokes = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.2
  }];
  divider.strokeWeight = 1;
  container.appendChild(divider);

  // Action option example (iOS: 16px padding, 40px icon)
  const option = figma.createFrame();
  option.name = 'Action Option';
  option.resize(302, 76);
  option.x = 24;
  option.y = 116;
  option.cornerRadius = 16;
  option.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.1
  }];
  option.strokes = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.2
  }];
  option.strokeWeight = 1;

  // Option icon
  const optionIcon = figma.createText();
  optionIcon.name = 'Icon';
  optionIcon.characters = '📧'; // Placeholder
  optionIcon.fontSize = 24; // iOS: title2
  optionIcon.x = 16;
  optionIcon.y = 26;

  option.appendChild(optionIcon);

  // Option text
  const optionTitle = figma.createText();
  optionTitle.name = 'Label';
  optionTitle.characters = 'Acknowledge';
  optionTitle.fontSize = 17; // iOS: headline
  optionTitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  optionTitle.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value)
  }];
  optionTitle.x = 72;
  optionTitle.y = 20;

  option.appendChild(optionTitle);

  const optionDesc = figma.createText();
  optionDesc.name = 'Description';
  optionDesc.characters = 'Send confirmation reply';
  optionDesc.fontSize = 12; // iOS: caption
  optionDesc.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  optionDesc.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.7
  }];
  optionDesc.x = 72;
  optionDesc.y = 44;

  option.appendChild(optionDesc);

  container.appendChild(option);

  frame.appendChild(container);
  figma.currentPage.appendChild(frame);

  return frame;
}

// Create Context Badge (matches iOS ContextBadge)
function createContextBadge() {
  figma.notify('Creating context badge...');

  const badge = figma.createFrame();
  badge.name = '🏷️ Context Badge';
  badge.layoutMode = 'HORIZONTAL';
  badge.itemSpacing = 12;
  badge.paddingLeft = 16;
  badge.paddingRight = 16;
  badge.paddingTop = 14;
  badge.paddingBottom = 14;
  badge.counterAxisAlignItems = 'CENTER';
  badge.primaryAxisSizingMode = 'AUTO';
  badge.counterAxisSizingMode = 'AUTO';
  badge.cornerRadius = 12;
  badge.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.05
  }];
  badge.strokes = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.1
  }];
  badge.strokeWeight = 1;

  // Icon (iOS: 32x32 frame, 16px icon, 8px radius)
  const iconFrame = figma.createFrame();
  iconFrame.name = 'Icon';
  iconFrame.resize(32, 32);
  iconFrame.cornerRadius = 8;
  iconFrame.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.semantic.info.$value),
    opacity: 0.2
  }];
  iconFrame.layoutMode = 'HORIZONTAL';
  iconFrame.primaryAxisAlignItems = 'CENTER';
  iconFrame.counterAxisAlignItems = 'CENTER';

  const icon = figma.createText();
  icon.characters = '📅';
  icon.fontSize = 16;
  iconFrame.appendChild(icon);
  badge.appendChild(iconFrame);

  // Text content
  const textContainer = figma.createFrame();
  textContainer.name = 'Text';
  textContainer.layoutMode = 'VERTICAL';
  textContainer.itemSpacing = 2;
  textContainer.primaryAxisSizingMode = 'AUTO';
  textContainer.counterAxisSizingMode = 'AUTO';
  textContainer.fills = [];

  const title = figma.createText();
  title.name = 'Title';
  title.characters = 'Event';
  title.fontSize = 12;
  title.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.medium };
  title.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.7
  }];
  textContainer.appendChild(title);

  const detail = figma.createText();
  detail.name = 'Detail';
  detail.characters = 'Parent-Teacher Conference on Oct 25';
  detail.fontSize = 13;
  detail.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  detail.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value)
  }];
  textContainer.appendChild(detail);

  badge.appendChild(textContainer);
  figma.currentPage.appendChild(badge);
  return badge;
}

// Create Full Email View Component
function createEmailView() {
  figma.notify('Creating email view...');

  const container = figma.createFrame();
  container.name = '📧 Email View (Full)';
  container.resize(390, 844); // iPhone 14 Pro size
  container.fills = [{
    type: 'SOLID',
    color: hexToRgb('#000000')
  }];

  // Status bar
  const statusBar = figma.createFrame();
  statusBar.name = 'Status Bar';
  statusBar.resize(390, 47);
  statusBar.fills = [];
  statusBar.y = 0;

  const statusTime = figma.createText();
  statusTime.characters = '9:41';
  statusTime.fontSize = 15;
  statusTime.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  statusTime.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  statusTime.x = 21;
  statusTime.y = 14;
  statusBar.appendChild(statusTime);
  container.appendChild(statusBar);

  // Email header
  const header = figma.createFrame();
  header.name = 'Header';
  header.layoutMode = 'VERTICAL';
  header.itemSpacing = 12;
  header.paddingLeft = 20;
  header.paddingRight = 20;
  header.paddingTop = 16;
  header.paddingBottom = 16;
  header.primaryAxisSizingMode = 'AUTO';
  header.resize(390, 120);
  header.y = 47;
  header.fills = [{
    type: 'SOLID',
    color: hexToRgb('#1C1C1E')
  }];

  // From line
  const fromLine = figma.createFrame();
  fromLine.name = 'From';
  fromLine.layoutMode = 'HORIZONTAL';
  fromLine.itemSpacing = 12;
  fromLine.counterAxisAlignItems = 'CENTER';
  fromLine.primaryAxisSizingMode = 'AUTO';
  fromLine.fills = [];

  const avatar = figma.createFrame();
  avatar.name = 'Avatar';
  avatar.resize(40, 40);
  avatar.cornerRadius = 20;
  avatar.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.semantic.info.$value),
    opacity: 0.3
  }];
  fromLine.appendChild(avatar);

  const fromText = figma.createText();
  fromText.characters = 'Sarah Johnson';
  fromText.fontSize = 17;
  fromText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  fromText.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  fromLine.appendChild(fromText);
  header.appendChild(fromLine);

  // Subject
  const subject = figma.createText();
  subject.name = 'Subject';
  subject.characters = 'Q3 Planning Meeting - Action Required';
  subject.fontSize = 22;
  subject.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.bold };
  subject.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  header.appendChild(subject);

  // Metadata
  const metadata = figma.createText();
  metadata.name = 'Metadata';
  metadata.characters = 'To: me • 2:45 PM';
  metadata.fontSize = 13;
  metadata.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  metadata.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.6
  }];
  header.appendChild(metadata);

  container.appendChild(header);

  // Priority badge
  const priorityBadge = figma.createFrame();
  priorityBadge.name = 'Priority Badge';
  priorityBadge.layoutMode = 'HORIZONTAL';
  priorityBadge.itemSpacing = 6;
  priorityBadge.paddingLeft = 12;
  priorityBadge.paddingRight = 12;
  priorityBadge.paddingTop = 6;
  priorityBadge.paddingBottom = 6;
  priorityBadge.primaryAxisSizingMode = 'AUTO';
  priorityBadge.counterAxisSizingMode = 'AUTO';
  priorityBadge.cornerRadius = 16;
  priorityBadge.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.actionPriorities.high.color),
    opacity: 0.15
  }];
  priorityBadge.strokes = [{
    type: 'SOLID',
    color: hexToRgb(tokens.actionPriorities.high.color)
  }];
  priorityBadge.strokeWeight = 1;
  priorityBadge.x = 20;
  priorityBadge.y = 180;

  const priorityIcon = figma.createText();
  priorityIcon.characters = '⚠️';
  priorityIcon.fontSize = 12;
  priorityBadge.appendChild(priorityIcon);

  const priorityText = figma.createText();
  priorityText.characters = 'HIGH PRIORITY (85)';
  priorityText.fontSize = 11;
  priorityText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  priorityText.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.actionPriorities.high.color)
  }];
  priorityBadge.appendChild(priorityText);
  container.appendChild(priorityBadge);

  // Email body
  const body = figma.createFrame();
  body.name = 'Body';
  body.layoutMode = 'VERTICAL';
  body.itemSpacing = 16;
  body.paddingLeft = 20;
  body.paddingRight = 20;
  body.paddingTop = 20;
  body.paddingBottom = 20;
  body.resize(350, 400);
  body.y = 220;
  body.fills = [];

  const bodyText1 = figma.createText();
  bodyText1.characters = 'Hi Team,';
  bodyText1.fontSize = 15;
  bodyText1.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  bodyText1.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  body.appendChild(bodyText1);

  const bodyText2 = figma.createText();
  bodyText2.characters = "We need to finalize our Q3 planning by EOD Friday. Please review the attached deck and confirm your team's commitments.";
  bodyText2.fontSize = 15;
  bodyText2.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  bodyText2.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  bodyText2.resize(350, 60);
  body.appendChild(bodyText2);

  // Context card
  const contextCard = figma.createFrame();
  contextCard.name = 'Context';
  contextCard.layoutMode = 'HORIZONTAL';
  contextCard.itemSpacing = 12;
  contextCard.paddingLeft = 16;
  contextCard.paddingRight = 16;
  contextCard.paddingTop = 12;
  contextCard.paddingBottom = 12;
  contextCard.primaryAxisSizingMode = 'AUTO';
  contextCard.counterAxisSizingMode = 'AUTO';
  contextCard.cornerRadius = 12;
  contextCard.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.05
  }];
  contextCard.strokes = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.1
  }];
  contextCard.strokeWeight = 1;

  const contextIcon = figma.createText();
  contextIcon.characters = '📅';
  contextIcon.fontSize = 20;
  contextCard.appendChild(contextIcon);

  const contextTextFrame = figma.createFrame();
  contextTextFrame.layoutMode = 'VERTICAL';
  contextTextFrame.itemSpacing = 2;
  contextTextFrame.primaryAxisSizingMode = 'AUTO';
  contextTextFrame.fills = [];

  const contextTitle = figma.createText();
  contextTitle.characters = 'Deadline';
  contextTitle.fontSize = 12;
  contextTitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.medium };
  contextTitle.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.7
  }];
  contextTextFrame.appendChild(contextTitle);

  const contextDetail = figma.createText();
  contextDetail.characters = 'Friday, November 10 at 5:00 PM';
  contextDetail.fontSize = 13;
  contextDetail.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  contextDetail.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  contextTextFrame.appendChild(contextDetail);

  contextCard.appendChild(contextTextFrame);
  body.appendChild(contextCard);

  container.appendChild(body);

  // Action buttons at bottom
  const actionBar = figma.createFrame();
  actionBar.name = 'Action Bar';
  actionBar.layoutMode = 'VERTICAL';
  actionBar.itemSpacing = 12;
  actionBar.paddingLeft = 20;
  actionBar.paddingRight = 20;
  actionBar.paddingTop = 20;
  actionBar.paddingBottom = 34; // Safe area
  actionBar.resize(390, 180);
  actionBar.y = 664;
  actionBar.fills = [{
    type: 'SOLID',
    color: hexToRgb('#1C1C1E')
  }];

  // Primary action button
  const primaryAction = figma.createFrame();
  primaryAction.name = 'Primary Action';
  primaryAction.layoutMode = 'HORIZONTAL';
  primaryAction.itemSpacing = 8;
  primaryAction.paddingLeft = 24;
  primaryAction.paddingRight = 24;
  primaryAction.paddingTop = 14;
  primaryAction.paddingBottom = 14;
  primaryAction.primaryAxisAlignItems = 'CENTER';
  primaryAction.counterAxisAlignItems = 'CENTER';
  primaryAction.primaryAxisSizingMode = 'FIXED';
  primaryAction.resize(350, 50);
  primaryAction.cornerRadius = 12;
  primaryAction.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.semantic.info.$value)
  }];

  const primaryActionIcon = figma.createText();
  primaryActionIcon.characters = '✓';
  primaryActionIcon.fontSize = 18;
  primaryActionIcon.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  primaryActionIcon.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  primaryAction.appendChild(primaryActionIcon);

  const primaryActionText = figma.createText();
  primaryActionText.characters = 'Acknowledge & Schedule Review';
  primaryActionText.fontSize = 17;
  primaryActionText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  primaryActionText.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  primaryAction.appendChild(primaryActionText);

  actionBar.appendChild(primaryAction);

  // Secondary actions
  const secondaryActions = figma.createFrame();
  secondaryActions.name = 'Secondary Actions';
  secondaryActions.layoutMode = 'HORIZONTAL';
  secondaryActions.itemSpacing = 12;
  secondaryActions.primaryAxisSizingMode = 'AUTO';
  secondaryActions.fills = [];

  const archiveBtn = figma.createFrame();
  archiveBtn.name = 'Archive';
  archiveBtn.layoutMode = 'HORIZONTAL';
  archiveBtn.itemSpacing = 6;
  archiveBtn.paddingLeft = 16;
  archiveBtn.paddingRight = 16;
  archiveBtn.paddingTop = 10;
  archiveBtn.paddingBottom = 10;
  archiveBtn.primaryAxisSizingMode = 'AUTO';
  archiveBtn.cornerRadius = 8;
  archiveBtn.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.1
  }];

  const archiveText = figma.createText();
  archiveText.characters = 'Archive';
  archiveText.fontSize = 15;
  archiveText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.medium };
  archiveText.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  archiveBtn.appendChild(archiveText);
  secondaryActions.appendChild(archiveBtn);

  const snoozeBtn = figma.createFrame();
  snoozeBtn.name = 'Snooze';
  snoozeBtn.layoutMode = 'HORIZONTAL';
  snoozeBtn.itemSpacing = 6;
  snoozeBtn.paddingLeft = 16;
  snoozeBtn.paddingRight = 16;
  snoozeBtn.paddingTop = 10;
  snoozeBtn.paddingBottom = 10;
  snoozeBtn.primaryAxisSizingMode = 'AUTO';
  snoozeBtn.cornerRadius = 8;
  snoozeBtn.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value),
    opacity: 0.1
  }];

  const snoozeText = figma.createText();
  snoozeText.characters = 'Snooze';
  snoozeText.fontSize = 15;
  snoozeText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.medium };
  snoozeText.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  snoozeBtn.appendChild(snoozeText);
  secondaryActions.appendChild(snoozeBtn);

  actionBar.appendChild(secondaryActions);
  container.appendChild(actionBar);

  figma.currentPage.appendChild(container);
  return container;
}

// Create Action Buttons
function createActionButtons() {
  figma.notify('Creating action button variants...');

  const frame = figma.createFrame();
  frame.name = 'Action Buttons';
  frame.layoutMode = 'VERTICAL';
  frame.itemSpacing = 12;
  frame.fills = [];

  // Primary Button
  const primaryButton = figma.createFrame();
  primaryButton.name = 'Button/Primary';
  primaryButton.resize(350, 44);
  primaryButton.cornerRadius = 12;
  primaryButton.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.semantic.info.$value)
  }];
  primaryButton.layoutMode = 'HORIZONTAL';
  primaryButton.counterAxisAlignItems = 'CENTER';
  primaryButton.primaryAxisAlignItems = 'CENTER';

  const primaryLabel = figma.createText();
  primaryLabel.characters = 'Primary Action';
  primaryLabel.fontSize = 17;
  primaryLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  primaryLabel.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value)
  }];

  primaryButton.appendChild(primaryLabel);
  frame.appendChild(primaryButton);

  // Secondary Button
  const secondaryButton = figma.createFrame();
  secondaryButton.name = 'Button/Secondary';
  secondaryButton.resize(350, 44);
  secondaryButton.cornerRadius = 12;
  secondaryButton.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.gray.$value),
    opacity: 0.1
  }];
  secondaryButton.layoutMode = 'HORIZONTAL';
  secondaryButton.counterAxisAlignItems = 'CENTER';
  secondaryButton.primaryAxisAlignItems = 'CENTER';

  const secondaryLabel = figma.createText();
  secondaryLabel.characters = 'Secondary Action';
  secondaryLabel.fontSize = 17;
  secondaryLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  secondaryLabel.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.semantic.info.$value)
  }];

  secondaryButton.appendChild(secondaryLabel);
  frame.appendChild(secondaryButton);

  // Destructive Button
  const destructiveButton = figma.createFrame();
  destructiveButton.name = 'Button/Destructive';
  destructiveButton.resize(350, 44);
  destructiveButton.cornerRadius = 12;
  destructiveButton.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.semantic.error.$value)
  }];
  destructiveButton.layoutMode = 'HORIZONTAL';
  destructiveButton.counterAxisAlignItems = 'CENTER';
  destructiveButton.primaryAxisAlignItems = 'CENTER';

  const destructiveLabel = figma.createText();
  destructiveLabel.characters = 'Delete';
  destructiveLabel.fontSize = 17;
  destructiveLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  destructiveLabel.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value)
  }];

  destructiveButton.appendChild(destructiveLabel);
  frame.appendChild(destructiveButton);

  figma.currentPage.appendChild(frame);
  return frame;
}

// Create Action Cards (matches iOS ContextualActionCard)
function createActionCards() {
  figma.notify('Creating action card components...');

  const frame = figma.createFrame();
  frame.name = '🎯 Action Cards - All Priorities';
  frame.layoutMode = 'VERTICAL';
  frame.itemSpacing = 12;
  frame.paddingLeft = 24;
  frame.paddingRight = 24;
  frame.paddingTop = 24;
  frame.paddingBottom = 24;
  frame.fills = [{
    type: 'SOLID',
    color: hexToRgb('#1C1C1E')
  }];

  // Title
  const titleText = figma.createText();
  titleText.name = 'Title';
  titleText.characters = 'Action Cards - All 8 Priority Levels';
  titleText.fontSize = 24;
  titleText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  titleText.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  frame.appendChild(titleText);

  // ALL 8 priority levels from tokens
  const priorities: Array<{name: string; color: string; value: number; description: string}> = [];
  Object.entries(tokens.actionPriorities).forEach(([key, data]: [string, any]) => {
    if (key !== '$type') {
      priorities.push({
        name: key.charAt(0).toUpperCase() + key.slice(1),
        color: data.color,
        value: data.value,
        description: data.description
      });
    }
  });

  priorities.forEach(priority => {
    const card = figma.createFrame();
    card.name = `Action Card/${priority.name}`;
    card.resize(350, 80);  // iOS: 80px height with 12px padding
    card.cornerRadius = 10; // iOS: corner radius 10
    card.fills = [{
      type: 'SOLID',
      color: hexToRgb(tokens.colors.primary.white.$value),
      opacity: 0.05  // iOS: white 0.05 opacity background
    }];
    card.strokes = [{
      type: 'SOLID',
      color: hexToRgb(priority.color),
      opacity: 0.3  // iOS: color 0.3 opacity border
    }];
    card.strokeWeight = 1;

    // Icon (matches iOS: 40px circle, 16px icon size)
    const iconCircle = figma.createFrame();
    iconCircle.name = 'Icon Circle';
    iconCircle.resize(40, 40);
    iconCircle.cornerRadius = 20;
    iconCircle.fills = [{
      type: 'SOLID',
      color: hexToRgb(priority.color),
      opacity: 0.2  // iOS: color 0.2 opacity background
    }];
    iconCircle.x = 12;
    iconCircle.y = 20;  // Vertically centered in 80px card

    // Icon placeholder (16px size)
    const iconText = figma.createText();
    iconText.name = 'Icon';
    iconText.characters = '●';  // Placeholder for SF Symbol
    iconText.fontSize = 16;
    iconText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    iconText.fills = [{
      type: 'SOLID',
      color: hexToRgb(priority.color)
    }];
    iconText.x = 12;
    iconText.y = 12;

    iconCircle.appendChild(iconText);
    card.appendChild(iconCircle);

    // Title (iOS: subheadline.bold ≈ 15px)
    const title = figma.createText();
    title.name = 'Title';
    title.characters = `${priority.name} Priority (${priority.value})`;
    title.fontSize = 15;
    title.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
    title.fills = [{
      type: 'SOLID',
      color: hexToRgb(tokens.colors.primary.white.$value)
    }];
    title.x = 64;  // 12 + 40 + 12 spacing
    title.y = 20;

    card.appendChild(title);

    // Description (iOS: caption ≈ 12px, 0.7 opacity)
    const description = figma.createText();
    description.name = 'Description';
    description.characters = priority.description;
    description.fontSize = 12;
    description.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    description.fills = [{
      type: 'SOLID',
      color: hexToRgb(tokens.colors.primary.white.$value),
      opacity: 0.7  // iOS: 0.7 opacity
    }];
    description.x = 64;
    description.y = 44;

    card.appendChild(description);

    // Arrow icon (iOS: title3 ≈ 20px)
    const arrow = figma.createText();
    arrow.name = 'Arrow';
    arrow.characters = '→';  // Placeholder for arrow.right.circle.fill
    arrow.fontSize = 20;
    arrow.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    arrow.fills = [{
      type: 'SOLID',
      color: hexToRgb(priority.color)
    }];
    arrow.x = 310;
    arrow.y = 30;

    card.appendChild(arrow);

    frame.appendChild(card);
  });

  figma.currentPage.appendChild(frame);
  return frame;
}

// Create Input Fields
function createInputFields() {
  figma.notify('Creating input field components...');

  const frame = figma.createFrame();
  frame.name = 'Input Fields';
  frame.layoutMode = 'VERTICAL';
  frame.itemSpacing = 12;
  frame.fills = [];

  // Default state
  const defaultInput = figma.createFrame();
  defaultInput.name = 'Input/Default';
  defaultInput.resize(350, 44);
  defaultInput.cornerRadius = 8;
  defaultInput.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.gray.$value),
    opacity: 0.1
  }];
  defaultInput.strokes = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.gray.$value)
  }];
  defaultInput.strokeWeight = 1;
  defaultInput.layoutMode = 'HORIZONTAL';
  defaultInput.paddingLeft = 12;
  defaultInput.paddingRight = 12;
  defaultInput.counterAxisAlignItems = 'CENTER';

  const placeholder = figma.createText();
  placeholder.characters = 'Enter text...';
  placeholder.fontSize = 15;
  placeholder.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  placeholder.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.gray.$value),
    opacity: 0.6
  }];

  defaultInput.appendChild(placeholder);
  frame.appendChild(defaultInput);

  // Focused state
  const focusedInput = figma.createFrame();
  focusedInput.name = 'Input/Focused';
  focusedInput.resize(350, 44);
  focusedInput.cornerRadius = 8;
  focusedInput.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.white.$value)
  }];
  focusedInput.strokes = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.semantic.info.$value)
  }];
  focusedInput.strokeWeight = 2;
  focusedInput.layoutMode = 'HORIZONTAL';
  focusedInput.paddingLeft = 12;
  focusedInput.paddingRight = 12;
  focusedInput.counterAxisAlignItems = 'CENTER';

  const inputText = figma.createText();
  inputText.characters = 'Sample input text';
  inputText.fontSize = 15;
  inputText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  inputText.fills = [{
    type: 'SOLID',
    color: hexToRgb(tokens.colors.primary.black.$value)
  }];

  focusedInput.appendChild(inputText);
  frame.appendChild(focusedInput);

  figma.currentPage.appendChild(frame);
  return frame;
}

// Create Action Flow Templates (User Interaction Patterns)
function createActionFlowTemplates() {
  figma.notify('Creating action flow templates...');

  let flowPage: PageNode;
  const existingFlowPage = figma.root.children.find(page => page.name === '⚡ Action Flows & Interactions');
  if (existingFlowPage) {
    flowPage = existingFlowPage;
    // Clear existing content
    flowPage.children.forEach(child => child.remove());
  } else {
    flowPage = figma.createPage();
    flowPage.name = '⚡ Action Flows & Interactions';
  }
  figma.currentPage = flowPage;

  const container = figma.createFrame();
  container.name = '⚡ Action Flow Templates';
  container.x = 0;
  container.y = 0;
  container.layoutMode = 'VERTICAL';
  container.itemSpacing = 60;
  container.paddingLeft = 48;
  container.paddingRight = 48;
  container.paddingTop = 48;
  container.paddingBottom = 48;
  container.primaryAxisSizingMode = 'AUTO';
  container.counterAxisSizingMode = 'AUTO';
  container.fills = [{
    type: 'SOLID',
    color: hexToRgb('#0A0A0A')
  }];

  // Page title
  const pageTitle = figma.createText();
  pageTitle.characters = 'Action Flows & Interaction Patterns';
  pageTitle.fontSize = 40;
  pageTitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.bold };
  pageTitle.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  container.appendChild(pageTitle);

  const pageSubtitle = figma.createText();
  pageSubtitle.characters = 'Comprehensive action templates showing user journeys from email → action → confirmation';
  pageSubtitle.fontSize = 16;
  pageSubtitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  pageSubtitle.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value), opacity: 0.6 }];
  container.appendChild(pageSubtitle);

  // Define action flows by priority level
  const actionFlows = [
    {
      priority: 'Critical (95)',
      color: '#FF3B30',
      quickActions: [
        { name: 'Emergency Call', icon: '📞', description: 'Initiate urgent phone call' },
        { name: 'Immediate Response', icon: '⚡', description: 'Send pre-configured urgent reply' },
        { name: 'Escalate', icon: '🚨', description: 'Alert designated emergency contact' }
      ],
      detailedActions: [
        {
          name: 'Schedule Emergency Meeting',
          steps: [
            'Select "Emergency Meeting"',
            'AI suggests next available slot (within 2 hours)',
            'Add participants from email',
            'Send meeting invite with URGENT flag',
            'Add to calendar + set 5-min reminder'
          ]
        },
        {
          name: 'Execute & Confirm',
          steps: [
            'Select action (e.g., "Approve Wire Transfer")',
            'Review transaction details',
            'Biometric/2FA confirmation',
            'Execute action',
            'Send confirmation email + SMS'
          ]
        }
      ]
    },
    {
      priority: 'Very High (90)',
      color: '#FF9500',
      quickActions: [
        { name: 'Quick Reply', icon: '💬', description: 'AI-generated context-aware response' },
        { name: 'Schedule Today', icon: '📅', description: 'Add to today\'s calendar' },
        { name: 'Flag & Remind', icon: '⏰', description: 'Set reminder for in 2 hours' }
      ],
      detailedActions: [
        {
          name: 'Acknowledge & Schedule Review',
          steps: [
            'Select "Acknowledge & Review"',
            'AI drafts acknowledgment: "Received, reviewing by [time]"',
            'Choose review time slot (AI suggests 3 options)',
            'Add calendar block for review',
            'Send acknowledgment email'
          ]
        },
        {
          name: 'Delegate with Context',
          steps: [
            'Select "Delegate"',
            'Choose team member (AI suggests based on expertise)',
            'AI extracts key context + deadline',
            'Add your instructions',
            'Forward with context + set follow-up reminder'
          ]
        }
      ]
    },
    {
      priority: 'High (85)',
      color: '#FFCC00',
      quickActions: [
        { name: 'Add to Task List', icon: '✓', description: 'Create task with deadline' },
        { name: 'Schedule This Week', icon: '📆', description: 'Add to this week\'s calendar' },
        { name: 'Snooze Until...', icon: '💤', description: 'Snooze with smart time suggestions' }
      ],
      detailedActions: [
        {
          name: 'Create Action Plan',
          steps: [
            'Select "Create Plan"',
            'AI breaks email into sub-tasks',
            'Assign priorities to each sub-task',
            'Set deadlines (AI suggests based on main deadline)',
            'Add to project management tool',
            'Send summary to stakeholders'
          ]
        }
      ]
    },
    {
      priority: 'Medium (75)',
      color: '#32ADE6',
      quickActions: [
        { name: 'Archive', icon: '📥', description: 'Archive for reference' },
        { name: 'Add Note', icon: '📝', description: 'Add quick note for later' },
        { name: 'Share', icon: '↗', description: 'Share with team' }
      ],
      detailedActions: [
        {
          name: 'Review & Respond',
          steps: [
            'Select "Review"',
            'Read full email + context',
            'AI suggests response templates',
            'Customize response',
            'Send + archive'
          ]
        }
      ]
    }
  ];

  // Create flow visualization for each priority
  actionFlows.forEach(flow => {
    const flowSection = figma.createFrame();
    flowSection.name = `${flow.priority} Actions`;
    flowSection.layoutMode = 'VERTICAL';
    flowSection.itemSpacing = 24;
    flowSection.paddingLeft = 32;
    flowSection.paddingRight = 32;
    flowSection.paddingTop = 32;
    flowSection.paddingBottom = 32;
    flowSection.primaryAxisSizingMode = 'AUTO';
    flowSection.counterAxisSizingMode = 'AUTO';
    flowSection.cornerRadius = 16;
    flowSection.fills = [{
      type: 'SOLID',
      color: hexToRgb(flow.color),
      opacity: 0.1
    }];
    flowSection.strokes = [{
      type: 'SOLID',
      color: hexToRgb(flow.color),
      opacity: 0.3
    }];
    flowSection.strokeWeight = 2;

    // Priority header
    const header = figma.createText();
    header.characters = `${flow.priority} Priority Actions`;
    header.fontSize = 24;
    header.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.bold };
    header.fills = [{ type: 'SOLID', color: hexToRgb(flow.color) }];
    flowSection.appendChild(header);

    // Quick Actions Row
    const quickActionsLabel = figma.createText();
    quickActionsLabel.characters = 'Quick Actions (Single Tap)';
    quickActionsLabel.fontSize = 16;
    quickActionsLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
    quickActionsLabel.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value), opacity: 0.9 }];
    flowSection.appendChild(quickActionsLabel);

    const quickActionsRow = figma.createFrame();
    quickActionsRow.layoutMode = 'HORIZONTAL';
    quickActionsRow.itemSpacing = 16;
    quickActionsRow.primaryAxisSizingMode = 'AUTO';
    quickActionsRow.fills = [];

    flow.quickActions.forEach(action => {
      const actionCard = figma.createFrame();
      actionCard.layoutMode = 'VERTICAL';
      actionCard.itemSpacing = 8;
      actionCard.paddingLeft = 20;
      actionCard.paddingRight = 20;
      actionCard.paddingTop = 16;
      actionCard.paddingBottom = 16;
      actionCard.primaryAxisSizingMode = 'AUTO';
      actionCard.counterAxisSizingMode = 'AUTO';
      actionCard.cornerRadius = 12;
      actionCard.resize(200, 100);
      actionCard.fills = [{
        type: 'SOLID',
        color: hexToRgb(tokens.colors.primary.white.$value),
        opacity: 0.08
      }];
      actionCard.strokes = [{
        type: 'SOLID',
        color: hexToRgb(tokens.colors.primary.white.$value),
        opacity: 0.2
      }];
      actionCard.strokeWeight = 1;

      const icon = figma.createText();
      icon.characters = action.icon;
      icon.fontSize = 32;
      actionCard.appendChild(icon);

      const name = figma.createText();
      name.characters = action.name;
      name.fontSize = 15;
      name.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
      name.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
      name.resize(160, 20);
      actionCard.appendChild(name);

      const desc = figma.createText();
      desc.characters = action.description;
      desc.fontSize = 12;
      desc.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
      desc.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value), opacity: 0.6 }];
      desc.resize(160, 30);
      actionCard.appendChild(desc);

      quickActionsRow.appendChild(actionCard);
    });

    flowSection.appendChild(quickActionsRow);

    // Detailed Action Flows
    const detailedActionsLabel = figma.createText();
    detailedActionsLabel.characters = 'Multi-Step Action Flows';
    detailedActionsLabel.fontSize = 16;
    detailedActionsLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
    detailedActionsLabel.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value), opacity: 0.9 }];
    flowSection.appendChild(detailedActionsLabel);

    flow.detailedActions.forEach(detailedAction => {
      const flowCard = figma.createFrame();
      flowCard.layoutMode = 'VERTICAL';
      flowCard.itemSpacing = 16;
      flowCard.paddingLeft = 24;
      flowCard.paddingRight = 24;
      flowCard.paddingTop = 20;
      flowCard.paddingBottom = 20;
      flowCard.primaryAxisSizingMode = 'AUTO';
      flowCard.counterAxisSizingMode = 'AUTO';
      flowCard.cornerRadius = 12;
      flowCard.fills = [{
        type: 'SOLID',
        color: hexToRgb('#000000'),
        opacity: 0.3
      }];

      const flowName = figma.createText();
      flowName.characters = detailedAction.name;
      flowName.fontSize = 17;
      flowName.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
      flowName.fills = [{ type: 'SOLID', color: hexToRgb(flow.color) }];
      flowCard.appendChild(flowName);

      // Create step-by-step flow
      const stepsContainer = figma.createFrame();
      stepsContainer.layoutMode = 'HORIZONTAL';
      stepsContainer.itemSpacing = 12;
      stepsContainer.primaryAxisSizingMode = 'AUTO';
      stepsContainer.fills = [];

      detailedAction.steps.forEach((step, index) => {
        const stepFrame = figma.createFrame();
        stepFrame.layoutMode = 'VERTICAL';
        stepFrame.itemSpacing = 8;
        stepFrame.paddingLeft = 16;
        stepFrame.paddingRight = 16;
        stepFrame.paddingTop = 12;
        stepFrame.paddingBottom = 12;
        stepFrame.primaryAxisSizingMode = 'AUTO';
        stepFrame.resize(180, 80);
        stepFrame.cornerRadius = 8;
        stepFrame.fills = [{
          type: 'SOLID',
          color: hexToRgb(flow.color),
          opacity: 0.15
        }];

        const stepNumber = figma.createText();
        stepNumber.characters = `Step ${index + 1}`;
        stepNumber.fontSize = 11;
        stepNumber.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.medium };
        stepNumber.fills = [{ type: 'SOLID', color: hexToRgb(flow.color) }];
        stepFrame.appendChild(stepNumber);

        const stepText = figma.createText();
        stepText.characters = step;
        stepText.fontSize = 13;
        stepText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
        stepText.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value), opacity: 0.9 }];
        stepText.resize(150, 50);
        stepFrame.appendChild(stepText);

        stepsContainer.appendChild(stepFrame);

        // Add arrow between steps
        if (index < detailedAction.steps.length - 1) {
          const arrow = figma.createText();
          arrow.characters = '→';
          arrow.fontSize = 24;
          arrow.fills = [{ type: 'SOLID', color: hexToRgb(flow.color), opacity: 0.5 }];
          stepsContainer.appendChild(arrow);
        }
      });

      flowCard.appendChild(stepsContainer);
      flowSection.appendChild(flowCard);
    });

    container.appendChild(flowSection);
  });

  flowPage.appendChild(container);
  return container;
}

// Create Action Priority Documentation (Comprehensive)
function createActionPriorityDocumentation() {
  figma.notify('Creating action priority documentation...');

  let docPage: PageNode;
  const existingDocPage = figma.root.children.find(page => page.name === '📖 Action Priority Documentation');
  if (existingDocPage) {
    docPage = existingDocPage;
    // Clear existing content
    docPage.children.forEach(child => child.remove());
  } else {
    docPage = figma.createPage();
    docPage.name = '📖 Action Priority Documentation';
  }
  figma.currentPage = docPage;

  const frame = figma.createFrame();
  frame.name = '📖 Priority System Documentation';
  frame.x = 0;
  frame.y = 0;
  frame.layoutMode = 'VERTICAL';
  frame.itemSpacing = 40;
  frame.paddingLeft = 48;
  frame.paddingRight = 48;
  frame.paddingTop = 48;
  frame.paddingBottom = 48;
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = 'AUTO';
  frame.fills = [{
    type: 'SOLID',
    color: hexToRgb('#000000')
  }];

  // Header
  const mainTitle = figma.createText();
  mainTitle.name = 'Main Title';
  mainTitle.characters = 'Zero Action Priority System';
  mainTitle.fontSize = 36;
  mainTitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.bold };
  mainTitle.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
  frame.appendChild(mainTitle);

  const subtitle = figma.createText();
  subtitle.name = 'Subtitle';
  subtitle.characters = '8-Level Classification System • Priority Scores 60-95 • Context-Aware Intelligence';
  subtitle.fontSize = 16;
  subtitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
  subtitle.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value), opacity: 0.7 }];
  frame.appendChild(subtitle);

  // Define comprehensive details for each priority
  const priorityDetails = [
    {
      key: 'critical',
      name: 'Critical',
      score: 95,
      color: '#FF3B30',
      description: 'Life-critical, legal, high-stakes financial',
      useCases: [
        'Medical emergencies requiring immediate response',
        'Legal deadlines (court filings, contract expirations)',
        'High-value financial transactions ($10K+)',
        'Security breaches or system failures'
      ],
      examples: [
        '"Court filing due today at 5 PM"',
        '"Emergency room visit scheduled"',
        '"Wire transfer approval needed: $50,000"'
      ],
      whenToUse: 'Life, legal, or significant financial impact. Requires same-day action.',
      whenNotToUse: 'Routine work tasks, standard meetings, or non-urgent requests'
    },
    {
      key: 'veryHigh',
      name: 'Very High',
      score: 90,
      color: '#FF9500',
      description: 'Time-sensitive, high-value actions',
      useCases: [
        'Client deliverables with firm deadlines',
        'Important meetings within 24-48 hours',
        'Revenue-impacting decisions',
        'Critical bug fixes in production'
      ],
      examples: [
        '"Proposal due tomorrow for $25K project"',
        '"CEO meeting prep - tomorrow 9 AM"',
        '"Production bug affecting 1000+ users"'
      ],
      whenToUse: 'Significant business impact with tight timelines. Action needed within 1-2 days.',
      whenNotToUse: 'Routine updates, informational emails, or tasks without firm deadlines'
    },
    {
      key: 'high',
      name: 'High',
      score: 85,
      color: '#FFCC00',
      description: 'Important but not urgent',
      useCases: [
        'Strategic planning tasks',
        'Important meetings (3-7 days out)',
        'Key stakeholder communication',
        'Quarterly reviews and planning'
      ],
      examples: [
        '"Q4 planning session next week"',
        '"Board presentation draft review"',
        '"Annual performance review scheduled"'
      ],
      whenToUse: 'Important work that moves major initiatives forward. Action needed within a week.',
      whenNotToUse: 'Day-to-day operational tasks or items that can wait 2+ weeks'
    },
    {
      key: 'mediumHigh',
      name: 'Medium High',
      score: 80,
      color: '#34C759',
      description: 'Useful with moderate impact',
      useCases: [
        'Team coordination and updates',
        'Process improvements',
        'Training and development',
        'Vendor management'
      ],
      examples: [
        '"Team standup schedule for next sprint"',
        '"New tool evaluation request"',
        '"Training workshop invitation"'
      ],
      whenToUse: 'Valuable work that improves efficiency or capabilities. Action within 1-2 weeks.',
      whenNotToUse: 'FYI items, optional events, or purely informational content'
    },
    {
      key: 'medium',
      name: 'Medium',
      score: 75,
      color: '#32ADE6',
      description: 'Standard actions with clear value',
      useCases: [
        'Regular status updates',
        'Standard operational tasks',
        'Routine approvals',
        'General communications'
      ],
      examples: [
        '"Weekly status report template"',
        '"Expense approval: $250"',
        '"Team lunch coordination"'
      ],
      whenToUse: 'Normal workflow items that keep things running smoothly. Flexible timeline.',
      whenNotToUse: 'Spam, marketing emails, or content with no action required'
    },
    {
      key: 'mediumLow',
      name: 'Medium Low',
      score: 70,
      color: '#007AFF',
      description: 'Helpful but not essential',
      useCases: [
        'Nice-to-know information',
        'Optional networking events',
        'Non-critical feature requests',
        'General announcements'
      ],
      examples: [
        '"Company all-hands next month"',
        '"New office hours posted"',
        '"Optional workshop registration"'
      ],
      whenToUse: 'Beneficial information or opportunities without pressure. Review when convenient.',
      whenNotToUse: 'Spam, irrelevant content, or pure noise'
    },
    {
      key: 'low',
      name: 'Low',
      score: 65,
      color: '#5856D6',
      description: 'Nice-to-have features',
      useCases: [
        'Background reading',
        'Long-term ideas',
        'Low-priority suggestions',
        'Archival reference'
      ],
      examples: [
        '"Industry report: Future trends 2025"',
        '"Idea: Consider exploring new market"',
        '"FYI: Competitor launched feature"'
      ],
      whenToUse: 'Potentially interesting but no action needed. Save for later review.',
      whenNotToUse: 'Anything requiring timely response or decision'
    },
    {
      key: 'veryLow',
      name: 'Very Low',
      score: 60,
      color: '#8E8E93',
      description: 'Utility actions, fallbacks',
      useCases: [
        'Automated notifications',
        'System messages',
        'Newsletters and digests',
        'Social media updates'
      ],
      examples: [
        '"Your package was delivered"',
        '"Weekly digest: GitHub activity"',
        '"Social: Someone liked your post"'
      ],
      whenToUse: 'Automated or informational messages with minimal value. Skim or archive.',
      whenNotToUse: 'Any message requiring human decision or response'
    }
  ];

  // Create detailed card for each priority
  priorityDetails.forEach(priority => {
    const card = figma.createFrame();
    card.name = `${priority.name} Priority Details`;
    card.layoutMode = 'VERTICAL';
    card.itemSpacing = 20;
    card.paddingLeft = 32;
    card.paddingRight = 32;
    card.paddingTop = 32;
    card.paddingBottom = 32;
    card.primaryAxisSizingMode = 'AUTO';
    card.counterAxisSizingMode = 'AUTO';
    card.cornerRadius = 16;
    card.fills = [{
      type: 'SOLID',
      color: hexToRgb(priority.color),
      opacity: 0.08
    }];
    card.strokes = [{
      type: 'SOLID',
      color: hexToRgb(priority.color),
      opacity: 0.4
    }];
    card.strokeWeight = 2;

    // Priority header
    const header = figma.createFrame();
    header.layoutMode = 'HORIZONTAL';
    header.itemSpacing = 16;
    header.counterAxisAlignItems = 'CENTER';
    header.primaryAxisSizingMode = 'AUTO';
    header.fills = [];

    const badge = figma.createFrame();
    badge.resize(80, 80);
    badge.cornerRadius = 40;
    badge.fills = [{
      type: 'SOLID',
      color: hexToRgb(priority.color),
      opacity: 0.2
    }];
    badge.strokes = [{
      type: 'SOLID',
      color: hexToRgb(priority.color)
    }];
    badge.strokeWeight = 3;
    header.appendChild(badge);

    const headerText = figma.createFrame();
    headerText.layoutMode = 'VERTICAL';
    headerText.itemSpacing = 4;
    headerText.primaryAxisSizingMode = 'AUTO';
    headerText.fills = [];

    const priorityName = figma.createText();
    priorityName.characters = `${priority.name.toUpperCase()} PRIORITY`;
    priorityName.fontSize = 28;
    priorityName.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.bold };
    priorityName.fills = [{ type: 'SOLID', color: hexToRgb(priority.color) }];
    headerText.appendChild(priorityName);

    const scoreText = figma.createText();
    scoreText.characters = `Score: ${priority.score} • ${priority.description}`;
    scoreText.fontSize = 15;
    scoreText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.medium };
    scoreText.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value), opacity: 0.7 }];
    headerText.appendChild(scoreText);

    header.appendChild(headerText);
    card.appendChild(header);

    // Use cases section
    const useCasesTitle = figma.createText();
    useCasesTitle.characters = 'Common Use Cases';
    useCasesTitle.fontSize = 17;
    useCasesTitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
    useCasesTitle.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
    card.appendChild(useCasesTitle);

    const useCasesList = figma.createText();
    useCasesList.characters = priority.useCases.map((uc, i) => `${i + 1}. ${uc}`).join('\n');
    useCasesList.fontSize = 14;
    useCasesList.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    useCasesList.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value), opacity: 0.8 }];
    useCasesList.resize(700, 80);
    card.appendChild(useCasesList);

    // Examples section
    const examplesTitle = figma.createText();
    examplesTitle.characters = 'Real Examples';
    examplesTitle.fontSize = 17;
    examplesTitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
    examplesTitle.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value) }];
    card.appendChild(examplesTitle);

    priority.examples.forEach(example => {
      const exampleCard = figma.createFrame();
      exampleCard.layoutMode = 'HORIZONTAL';
      exampleCard.itemSpacing = 12;
      exampleCard.paddingLeft = 16;
      exampleCard.paddingRight = 16;
      exampleCard.paddingTop = 12;
      exampleCard.paddingBottom = 12;
      exampleCard.primaryAxisSizingMode = 'AUTO';
      exampleCard.counterAxisSizingMode = 'AUTO';
      exampleCard.cornerRadius = 8;
      exampleCard.fills = [{
        type: 'SOLID',
        color: hexToRgb(tokens.colors.primary.white.$value),
        opacity: 0.05
      }];

      const exampleText = figma.createText();
      exampleText.characters = example;
      exampleText.fontSize = 14;
      exampleText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
      exampleText.fills = [{ type: 'SOLID', color: hexToRgb(priority.color) }];
      exampleCard.appendChild(exampleText);

      card.appendChild(exampleCard);
    });

    // Guidelines section
    const guidelinesFrame = figma.createFrame();
    guidelinesFrame.layoutMode = 'HORIZONTAL';
    guidelinesFrame.itemSpacing = 24;
    guidelinesFrame.primaryAxisSizingMode = 'AUTO';
    guidelinesFrame.fills = [];

    const whenToUseFrame = figma.createFrame();
    whenToUseFrame.layoutMode = 'VERTICAL';
    whenToUseFrame.itemSpacing = 8;
    whenToUseFrame.primaryAxisSizingMode = 'AUTO';
    whenToUseFrame.resize(350, 100);
    whenToUseFrame.fills = [];

    const whenToUseTitle = figma.createText();
    whenToUseTitle.characters = '✓ When to Use';
    whenToUseTitle.fontSize = 15;
    whenToUseTitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
    whenToUseTitle.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.semantic.success.$value) }];
    whenToUseFrame.appendChild(whenToUseTitle);

    const whenToUseText = figma.createText();
    whenToUseText.characters = priority.whenToUse;
    whenToUseText.fontSize = 13;
    whenToUseText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    whenToUseText.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value), opacity: 0.7 }];
    whenToUseText.resize(350, 60);
    whenToUseFrame.appendChild(whenToUseText);

    guidelinesFrame.appendChild(whenToUseFrame);

    const whenNotToUseFrame = figma.createFrame();
    whenNotToUseFrame.layoutMode = 'VERTICAL';
    whenNotToUseFrame.itemSpacing = 8;
    whenNotToUseFrame.primaryAxisSizingMode = 'AUTO';
    whenNotToUseFrame.resize(350, 100);
    whenNotToUseFrame.fills = [];

    const whenNotToUseTitle = figma.createText();
    whenNotToUseTitle.characters = '✗ When NOT to Use';
    whenNotToUseTitle.fontSize = 15;
    whenNotToUseTitle.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
    whenNotToUseTitle.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.semantic.error.$value) }];
    whenNotToUseFrame.appendChild(whenNotToUseTitle);

    const whenNotToUseText = figma.createText();
    whenNotToUseText.characters = priority.whenNotToUse;
    whenNotToUseText.fontSize = 13;
    whenNotToUseText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    whenNotToUseText.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.white.$value), opacity: 0.7 }];
    whenNotToUseText.resize(350, 60);
    whenNotToUseFrame.appendChild(whenNotToUseText);

    guidelinesFrame.appendChild(whenNotToUseFrame);
    card.appendChild(guidelinesFrame);

    frame.appendChild(card);
  });

  docPage.appendChild(frame);
  return frame;
}

// Create Action Priority Chips
function createActionPriorityChips() {
  figma.notify('Creating action priority chips...');

  const frame = figma.createFrame();
  frame.name = '⭐ Action Priorities (All 8 Levels)';
  frame.layoutMode = 'VERTICAL';
  frame.itemSpacing = 12;
  frame.paddingLeft = 24;
  frame.paddingRight = 24;
  frame.paddingTop = 24;
  frame.paddingBottom = 24;
  frame.fills = [{
    type: 'SOLID',
    color: hexToRgb('#F5F5F7')
  }];

  // Title
  const titleText = figma.createText();
  titleText.name = 'Title';
  titleText.characters = 'Action Priority Scale (8 Levels)';
  titleText.fontSize = 24;
  titleText.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.semibold };
  titleText.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.black.$value) }];
  frame.appendChild(titleText);

  Object.entries(tokens.actionPriorities).forEach(([name, data]: [string, any]) => {
    if (name === '$type') return;

    const row = figma.createFrame();
    row.name = name.charAt(0).toUpperCase() + name.slice(1);
    row.layoutMode = 'HORIZONTAL';
    row.itemSpacing = 16;
    row.counterAxisAlignItems = 'CENTER';
    row.fills = [];

    // Priority chip
    const chip = figma.createFrame();
    chip.name = 'Chip';
    chip.resize(140, 32);
    chip.cornerRadius = 16;
    chip.fills = [{
      type: 'SOLID',
      color: hexToRgb(data.color),
      opacity: 0.15
    }];
    chip.strokes = [{
      type: 'SOLID',
      color: hexToRgb(data.color)
    }];
    chip.strokeWeight = 1;
    chip.layoutMode = 'HORIZONTAL';
    chip.counterAxisAlignItems = 'CENTER';
    chip.paddingLeft = 12;
    chip.paddingRight = 12;

    const chipLabel = figma.createText();
    chipLabel.characters = `${name.toUpperCase()} (${data.value})`;
    chipLabel.fontSize = 13;
    chipLabel.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.medium };
    chipLabel.fills = [{
      type: 'SOLID',
      color: hexToRgb(data.color)
    }];

    chip.appendChild(chipLabel);
    row.appendChild(chip);

    // Description
    const description = figma.createText();
    description.characters = data.description;
    description.fontSize = 14;
    description.fontName = { family: FONT_FAMILY, style: FONT_WEIGHTS.regular };
    description.fills = [{ type: 'SOLID', color: hexToRgb(tokens.colors.primary.gray.$value) }];
    row.appendChild(description);

    frame.appendChild(row);
  });

  figma.currentPage.appendChild(frame);

  return frame;
}

// Main execution
async function main(command: string) {
  console.log('🚀 Plugin starting, command:', command);
  try {
    console.log('📝 Loading fonts...');
    // Load fonts - try SF Pro Display first, fallback to Inter
    try {
      await figma.loadFontAsync({ family: 'SF Pro Display', style: 'Regular' });
      await figma.loadFontAsync({ family: 'SF Pro Display', style: 'Medium' });
      await figma.loadFontAsync({ family: 'SF Pro Display', style: 'Semibold' });
      await figma.loadFontAsync({ family: 'SF Pro Display', style: 'Bold' });
      FONT_FAMILY = 'SF Pro Display';
      FONT_WEIGHTS = {
        regular: 'Regular',
        medium: 'Medium',
        semibold: 'Semibold',
        bold: 'Bold'
      };
      figma.notify('Using SF Pro Display font');
    } catch (fontError) {
      // Fallback to Inter (commonly available in Figma)
      await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
      await figma.loadFontAsync({ family: 'Inter', style: 'Medium' });
      await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
      await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
      FONT_FAMILY = 'Inter';
      FONT_WEIGHTS = {
        regular: 'Regular',
        medium: 'Medium',
        semibold: 'Semi Bold',  // Inter uses "Semi Bold" with a space
        bold: 'Bold'
      };
      figma.notify('Using Inter font (SF Pro Display not available)');
    }

    console.log('🎯 Executing command:', command);
    switch (command) {
      case 'generate-system':
      case 'sync-all':
        // Create or reuse main components page (don't delete Page 1 yet)
        let mainPage: PageNode;
        const existingMainPage = figma.root.children.find(page => page.name === '🎨 Design System Components');
        if (existingMainPage) {
          mainPage = existingMainPage;
          // Clear existing content
          mainPage.children.forEach(child => child.remove());
        } else {
          mainPage = figma.createPage();
          mainPage.name = '🎨 Design System Components';
        }

        // IMPORTANT: Set this as current page BEFORE creating any content
        figma.currentPage = mainPage;

        console.log('✅ Creating color styles...');
        const colorStyles = createColorStyles();
        console.log('✅ Creating text styles...');
        const textStyles = createTextStyles();

        // ===== ORGANIZED LAYOUT GRID =====
        // Column 1: Foundation Tokens (x: 0)
        // Column 2: Components (x: 500)
        // Column 3: Priority System (x: 1000)
        // Column 4: Modals & Complex (x: 1500)

        const colSpacing = 500;
        const rowSpacing = 50;
        const components: SceneNode[] = [];

        // ===== COLUMN 1: FOUNDATION TOKENS =====
        let col1X = 0;
        let col1Y = 0;

        console.log('✅ Creating color palette...');
        const colorPalette = createColorPalette();
        mainPage.appendChild(colorPalette);  // Explicitly ensure it's on mainPage
        colorPalette.x = col1X;
        colorPalette.y = col1Y;
        components.push(colorPalette);
        col1Y += colorPalette.height + rowSpacing;

        console.log('✅ Creating spacing scale...');
        const spacingScale = createSpacingScale();
        mainPage.appendChild(spacingScale);
        spacingScale.x = col1X;
        spacingScale.y = col1Y;
        components.push(spacingScale);
        col1Y += spacingScale.height + rowSpacing;

        console.log('✅ Creating sizing tokens...');
        const sizingTokens = createSizingTokens();
        mainPage.appendChild(sizingTokens);
        sizingTokens.x = col1X;
        sizingTokens.y = col1Y;
        components.push(sizingTokens);
        col1Y += sizingTokens.height + rowSpacing;

        console.log('✅ Creating border radius scale...');
        const borderRadius = createBorderRadiusScale();
        mainPage.appendChild(borderRadius);
        borderRadius.x = col1X;
        borderRadius.y = col1Y;
        components.push(borderRadius);
        col1Y += borderRadius.height + rowSpacing;

        console.log('✅ Creating typography specimen...');
        const typography = createTypographySpecimen();
        mainPage.appendChild(typography);
        typography.x = col1X;
        typography.y = col1Y;
        components.push(typography);

        // ===== COLUMN 2: BASIC COMPONENTS =====
        let col2X = colSpacing;
        let col2Y = 0;

        console.log('✅ Creating toast component...');
        const toastComponent = createToastComponent(colorStyles, textStyles);
        mainPage.appendChild(toastComponent);
        toastComponent.x = col2X;
        toastComponent.y = col2Y;
        components.push(toastComponent);
        col2Y += toastComponent.height + rowSpacing;

        console.log('✅ Creating action buttons...');
        const actionButtons = createActionButtons();
        mainPage.appendChild(actionButtons);
        actionButtons.x = col2X;
        actionButtons.y = col2Y;
        components.push(actionButtons);
        col2Y += actionButtons.height + rowSpacing;

        console.log('✅ Creating input fields...');
        const inputFields = createInputFields();
        mainPage.appendChild(inputFields);
        inputFields.x = col2X;
        inputFields.y = col2Y;
        components.push(inputFields);
        col2Y += inputFields.height + rowSpacing;

        console.log('✅ Creating context badge...');
        const contextBadge = createContextBadge();
        mainPage.appendChild(contextBadge);
        contextBadge.x = col2X;
        contextBadge.y = col2Y;
        components.push(contextBadge);
        col2Y += contextBadge.height + rowSpacing;

        console.log('✅ Creating archetypes display...');
        const archetypes = createArchetypesDisplay();
        mainPage.appendChild(archetypes);
        archetypes.x = col2X;
        archetypes.y = col2Y;
        components.push(archetypes);

        // ===== COLUMN 3: PRIORITY SYSTEM (ALL 8 LEVELS) =====
        let col3X = colSpacing * 2;
        let col3Y = 0;

        console.log('✅ Creating action priority chips (all 8 levels)...');
        const priorityChips = createActionPriorityChips();
        mainPage.appendChild(priorityChips);
        priorityChips.x = col3X;
        priorityChips.y = col3Y;
        components.push(priorityChips);
        col3Y += priorityChips.height + rowSpacing;

        console.log('✅ Creating action cards (all 8 priorities)...');
        const actionCards = createActionCards();
        mainPage.appendChild(actionCards);
        actionCards.x = col3X;
        actionCards.y = col3Y;
        components.push(actionCards);

        // ===== COLUMN 4: MODALS & COMPLEX COMPONENTS =====
        let col4X = colSpacing * 3;
        let col4Y = 0;

        console.log('✅ Creating email view (full)...');
        const emailView = createEmailView();
        mainPage.appendChild(emailView);
        emailView.x = col4X;
        emailView.y = col4Y;
        components.push(emailView);
        col4Y += emailView.height + rowSpacing;

        console.log('✅ Creating modal template...');
        const modalTemplate = createModalTemplate();
        mainPage.appendChild(modalTemplate);
        modalTemplate.x = col4X;
        modalTemplate.y = col4Y;
        components.push(modalTemplate);

        // ===== CREATE ACTION FLOWS PAGE =====
        console.log('✅ Creating action flow templates...');
        createActionFlowTemplates();

        // ===== CREATE DOCUMENTATION PAGE =====
        console.log('✅ Creating comprehensive action priority documentation...');
        createActionPriorityDocumentation();

        // Delete default "Page 1" now that we have 3 pages with content
        const defaultPage = figma.root.children.find(page => page.name === 'Page 1');
        if (defaultPage) {
          console.log('🗑️ Deleting Page 1...');
          defaultPage.remove();
        }

        // Switch back to main page and focus on components
        figma.currentPage = mainPage;
        figma.viewport.scrollAndZoomIntoView(components);

        figma.notify('✅ Complete! 3 pages created: Components + Action Flows + Priority Docs');
        break;

      case 'update-colors':
        createColorStyles();
        figma.notify('✅ Color styles updated!');
        break;

      case 'update-typography':
        createTextStyles();
        figma.notify('✅ Typography styles updated!');
        break;

      case 'generate-components':
        const colors = createColorStyles();
        const texts = createTextStyles();
        createToastComponent(colors, texts);
        // createProgressBarVariants(); // TODO: Fix - currently causes crash with empty array
        createActionPriorityChips();
        createModalTemplate();
        createActionButtons();
        createActionCards();
        createInputFields();
        createContextBadge();
        figma.notify('✅ Components generated!');
        break;

      default:
        figma.notify('Unknown command');
    }

    figma.closePlugin();
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    const errorStack = error instanceof Error ? error.stack : '';
    console.error('Plugin error:', error);
    console.error('Error stack:', errorStack);
    figma.notify(`❌ Error: ${errorMessage}`);
    console.log('Full error details:', JSON.stringify(error, null, 2));
    figma.closePlugin();
  }
}

// Handle plugin commands
figma.on('run', ({ command }: RunEvent) => {
  main(command);
});

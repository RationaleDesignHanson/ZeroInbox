/**
 * Zero Design System - Component Generator with Visual Effects
 *
 * Generates all 5 base components + 92 variants WITH visual effects:
 * - Glassmorphic backgrounds (frosted glass + rim lighting)
 * - Gradient backgrounds (nebula for MAIL, scenic for ADS)
 * - Holographic button rims
 * - Proper shadows and blur effects
 *
 * Phase 0 Day 2: Complete visual fidelity to iOS app
 * 
 * TOKENS: Imported from tokens-for-plugin.ts (generated from tokens.json)
 * Run `node generate-tokens-for-plugin.js` before building to sync tokens.
 */

// Import design tokens from generated file
import { DesignTokens, EffectTokens } from './tokens-for-plugin';

function hexToRgb(hex: string): RGB {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) return { r: 0, g: 0, b: 0 };
  return {
    r: parseInt(result[1], 16) / 255,
    g: parseInt(result[2], 16) / 255,
    b: parseInt(result[3], 16) / 255
  };
}

function random(min: number, max: number): number {
  return Math.random() * (max - min) + min;
}

/**
 * Creates a scenic background for ADS cards (teal/green gradient)
 */
function createScenicBackground(width: number, height: number): FrameNode {
  const background = figma.createFrame();
  background.name = 'Scenic Background (ADS)';
  background.resize(width, height);
  background.clipsContent = true;

  // Base: Light teal
  background.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [[1, 0, 0], [0, 1, 0]],
    gradientStops: [
      { position: 0, color: { ...hexToRgb('#16bbaa'), a: 0.4 } },
      { position: 0.5, color: { ...hexToRgb('#4fd19e'), a: 0.3 } },
      { position: 1, color: { ...hexToRgb('#9fedd7'), a: 0.5 } }
    ]
  }];

  // Layer 1: Radial highlight (center accent)
  const layer1 = figma.createEllipse();
  layer1.name = 'Scenic Layer 1';
  layer1.resize(width * 1.2, height * 1.2);
  layer1.x = width * 0.4 - width * 0.6;
  layer1.y = height * 0.5 - height * 0.6;
  layer1.opacity = 0.4;
  layer1.fills = [{
    type: 'GRADIENT_RADIAL',
    gradientTransform: [[1, 0, 0.5], [0, 1, 0.5]],
    gradientStops: [
      { position: 0, color: { ...hexToRgb('#4fd19e'), a: 0.6 } },
      { position: 0.6, color: { ...hexToRgb('#16bbaa'), a: 0.3 } },
      { position: 1, color: { r: 0, g: 0, b: 0, a: 0 } }
    ]
  }];
  layer1.effects = [{ type: 'LAYER_BLUR', radius: 50, visible: true } as any];
  background.appendChild(layer1);

  // Layer 2: Green accent (bottom-right)
  const layer2 = figma.createEllipse();
  layer2.name = 'Scenic Layer 2';
  layer2.resize(width * 0.8, height * 0.8);
  layer2.x = width * 0.7 - width * 0.4;
  layer2.y = height * 0.6 - height * 0.4;
  layer2.opacity = 0.3;
  layer2.fills = [{
    type: 'GRADIENT_RADIAL',
    gradientTransform: [[1, 0, 0.5], [0, 1, 0.5]],
    gradientStops: [
      { position: 0, color: { ...hexToRgb('#9fedd7'), a: 0.5 } },
      { position: 0.5, color: { ...hexToRgb('#4fd19e'), a: 0.3 } },
      { position: 1, color: { r: 0, g: 0, b: 0, a: 0 } }
    ]
  }];
  layer2.effects = [{ type: 'LAYER_BLUR', radius: 40, visible: true } as any];
  background.appendChild(layer2);

  return background;
}

/**
 * Creates a nebula background (4-layer radial gradients + particles)
 */
function createNebulaBackground(width: number, height: number): FrameNode {
  const background = figma.createFrame();
  background.name = 'Nebula Background (MAIL)';
  background.resize(width, height);
  background.clipsContent = true;

  // Base: Deep space black
  background.fills = [{
    type: 'SOLID',
    color: { r: 0.04, g: 0.04, b: 0.06 },
    opacity: 0.95
  }];

  // Layer 1: Deep purple nebula (top-left)
  const layer1 = figma.createEllipse();
  layer1.name = 'Nebula 1';
  layer1.resize(width * 1.2, height * 1.2);
  layer1.x = width * 0.3 - width * 0.6;
  layer1.y = height * 0.4 - height * 0.6;
  layer1.opacity = EffectTokens.gradients.mail.opacity[0];
  layer1.fills = [{
    type: 'GRADIENT_RADIAL',
    gradientTransform: [[1, 0, 0.5], [0, 1, 0.5]],
    gradientStops: [
      { position: 0, color: { ...EffectTokens.gradients.mail.nebula.deepPurple, a: 0.8 } },
      { position: 0.5, color: { ...EffectTokens.gradients.mail.nebula.darkBlue, a: 0.4 } },
      { position: 1, color: { r: 0, g: 0, b: 0, a: 0 } }
    ]
  }];
  layer1.effects = [{ type: 'LAYER_BLUR', radius: 60, visible: true } as any];
  background.appendChild(layer1);

  // Layer 2: Dark blue nebula (bottom-right)
  const layer2 = figma.createEllipse();
  layer2.name = 'Nebula 2';
  layer2.resize(width * 1.5, height * 1.5);
  layer2.x = width * 0.7 - width * 0.75;
  layer2.y = height * 0.6 - height * 0.75;
  layer2.opacity = EffectTokens.gradients.mail.opacity[1];
  layer2.fills = [{
    type: 'GRADIENT_RADIAL',
    gradientTransform: [[1, 0, 0.5], [0, 1, 0.5]],
    gradientStops: [
      { position: 0, color: { ...EffectTokens.gradients.mail.nebula.darkBlue, a: 0.6 } },
      { position: 0.6, color: { ...EffectTokens.gradients.mail.nebula.deepPurple, a: 0.3 } },
      { position: 1, color: { r: 0, g: 0, b: 0, a: 0 } }
    ]
  }];
  layer2.effects = [{ type: 'LAYER_BLUR', radius: 50, visible: true } as any];
  background.appendChild(layer2);

  // Layer 3: Bright purple accent
  const layer3 = figma.createEllipse();
  layer3.name = 'Nebula 3';
  layer3.resize(width * 0.8, height * 0.8);
  layer3.x = width * 0.6 - width * 0.4;
  layer3.y = height * 0.5 - height * 0.4;
  layer3.opacity = EffectTokens.gradients.mail.opacity[2];
  layer3.fills = [{
    type: 'GRADIENT_RADIAL',
    gradientTransform: [[1, 0, 0.5], [0, 1, 0.5]],
    gradientStops: [
      { position: 0, color: { ...EffectTokens.gradients.mail.nebula.brightPurple, a: 0.7 } },
      { position: 0.4, color: { ...EffectTokens.gradients.mail.nebula.bluePurple, a: 0.4 } },
      { position: 1, color: { r: 0, g: 0, b: 0, a: 0 } }
    ]
  }];
  layer3.effects = [{ type: 'LAYER_BLUR', radius: 40, visible: true } as any];
  background.appendChild(layer3);

  // Particles (20 glowing dots)
  for (let i = 0; i < 20; i++) {
    const particle = figma.createEllipse();
    const size = random(1, 3);
    particle.resize(size, size);
    particle.x = random(0, width);
    particle.y = random(0, height);
    particle.opacity = random(0.1, 0.5);
    particle.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    background.appendChild(particle);
  }

  return background;
}

/**
 * Creates a glassmorphic layer (frosted glass + rim + highlight)
 */
function createGlassmorphicLayer(width: number, height: number, cornerRadius: number): FrameNode {
  const glass = figma.createFrame();
  glass.name = 'Glassmorphic Effect';
  glass.resize(width, height);
  glass.cornerRadius = cornerRadius;
  glass.fills = [];
  glass.clipsContent = false;

  // Frosted glass base
  const base = figma.createRectangle();
  base.name = 'Glass Base';
  base.resize(width, height);
  base.cornerRadius = cornerRadius;
  base.fills = [{
    type: 'SOLID',
    color: { r: 1, g: 1, b: 1 },
    opacity: EffectTokens.glassmorphic.opacity.ultraLight
  }];
  base.effects = [{
    type: 'BACKGROUND_BLUR',
    radius: EffectTokens.glassmorphic.blur.heavy,
    visible: true
  } as any];
  glass.appendChild(base);

  // Holographic rim (gradient stroke)
  const rim = figma.createRectangle();
  rim.name = 'Holographic Rim';
  rim.resize(width, height);
  rim.cornerRadius = cornerRadius;
  rim.fills = [];
  rim.strokes = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [[1, 0, 0], [0, 1, 0]],
    gradientStops: [
      { position: 0, color: { r: 1, g: 1, b: 1, a: 0.4 } },
      { position: 0.33, color: { r: 1, g: 1, b: 1, a: 0.1 } },
      { position: 0.66, color: { r: 1, g: 1, b: 1, a: 0.3 } },
      { position: 1, color: { r: 1, g: 1, b: 1, a: 0.2 } }
    ]
  }];
  rim.strokeWeight = 1;
  glass.appendChild(rim);

  // Specular highlight
  const highlight = figma.createRectangle();
  highlight.name = 'Specular Highlight';
  highlight.resize(width, height);
  highlight.cornerRadius = cornerRadius;
  highlight.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [[0.707, 0.707, 0], [-0.707, 0.707, 0]],
    gradientStops: [
      { position: 0, color: { r: 1, g: 1, b: 1, a: 0.4 } },
      { position: 0.3, color: { r: 1, g: 1, b: 1, a: 0 } },
      { position: 0.7, color: { r: 1, g: 1, b: 1, a: 0 } },
      { position: 1, color: { r: 1, g: 1, b: 1, a: 0.2 } }
    ]
  }];
  highlight.blendMode = 'OVERLAY';
  glass.appendChild(highlight);

  return glass;
}

/**
 * Creates a holographic rim for buttons
 */
function createButtonHolographicRim(
  width: number,
  height: number,
  cornerRadius: number,
  mode: 'mail' | 'ads'
): RectangleNode {
  const rim = figma.createRectangle();
  rim.name = `Holographic Rim (${mode.toUpperCase()})`;
  rim.resize(width, height);
  rim.cornerRadius = cornerRadius;
  rim.fills = [];

  const config = EffectTokens.holographic[mode];

  rim.strokes = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [[1, 0, 0], [0, 1, 0]],
    gradientStops: config.colors.map((color, i) => ({
      position: i / (config.colors.length - 1),
      color: { ...hexToRgb(color), a: config.opacities[i] }
    }))
  }];
  rim.strokeWeight = 2;

  // Edge glow
  rim.effects = [{
    type: 'DROP_SHADOW',
    color: { ...hexToRgb(config.edgeGlow.color), a: config.edgeGlow.opacity },
    offset: { x: 0, y: 0 },
    radius: config.edgeGlow.blur,
    spread: 0,
    visible: true,
    blendMode: 'NORMAL'
  }];

  return rim;
}

// MARK: - Helper Functions

function findVariable(name: string): Variable | null {
  const localVariables = figma.variables.getLocalVariables();
  return localVariables.find(v => v.name === name) || null;
}

async function createText(content: string, fontSize: number, weight: string = 'Regular'): Promise<TextNode> {
  const text = figma.createText();
  await figma.loadFontAsync({ family: 'Inter', style: weight });
  text.fontName = { family: 'Inter', style: weight };
  text.characters = content;
  text.fontSize = fontSize;
  return text;
}

function createAutoLayoutFrame(name: string, direction: 'HORIZONTAL' | 'VERTICAL', spacing: number, padding: number): FrameNode {
  const frame = figma.createFrame();
  frame.name = name;
  frame.layoutMode = direction;
  frame.itemSpacing = spacing;
  frame.paddingLeft = padding;
  frame.paddingRight = padding;
  frame.paddingTop = padding;
  frame.paddingBottom = padding;
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = 'AUTO';
  return frame;
}

// MARK: - Color Helpers

const COLORS = {
  blue: { r: 0.23, g: 0.51, b: 0.96 },
  blueHover: { r: 0.15, g: 0.42, b: 0.87 },
  gray200: { r: 0.90, g: 0.91, b: 0.92 },
  gray300: { r: 0.82, g: 0.84, b: 0.86 },
  gray900: { r: 0.07, g: 0.09, b: 0.15 },
  red: { r: 0.94, g: 0.27, b: 0.27 },
  green: { r: 0.06, g: 0.73, b: 0.51 },
  greenBg: { r: 0.94, g: 0.99, b: 0.96 },
  greenText: { r: 0.02, g: 0.37, b: 0.27 },
  yellow: { r: 0.96, g: 0.62, b: 0.04 },
  yellowBg: { r: 0.99, g: 0.99, b: 0.91 },
  yellowText: { r: 0.57, g: 0.25, b: 0.05 },
  blueBg: { r: 0.94, g: 0.96, b: 1.00 },
  blueText: { r: 0.12, g: 0.25, b: 0.69 },
  redBg: { r: 0.99, g: 0.95, b: 0.95 },
  redText: { r: 0.60, g: 0.11, b: 0.11 },
  white: { r: 1, g: 1, b: 1 },
  black: { r: 0, g: 0, b: 0 },
  transparent: { r: 0, g: 0, b: 0 }
};

// MARK: - ZeroButton Generator (48 variants) WITH HOLOGRAPHIC RIMS

async function generateZeroButtonVariants(): Promise<ComponentSetNode> {
  console.log('Generating ZeroButton with holographic rims...');

  const styles = ['Primary', 'Secondary', 'Tertiary', 'Danger'];
  const sizes = [
    { name: 'Small', height: 32, padding: 16, fontSize: 13, radius: 12 },
    { name: 'Medium', height: 44, padding: 16, fontSize: 15, radius: 12 },
    { name: 'Large', height: 56, padding: 16, fontSize: 17, radius: 12 }
  ];
  const states = ['Default', 'Hover', 'Active', 'Disabled'];

  const components: ComponentNode[] = [];

  for (const style of styles) {
    for (const size of sizes) {
      for (const state of states) {
        const component = figma.createComponent();
        component.name = `Style=${style}, Size=${size.name}, State=${state}`;

        component.layoutMode = 'HORIZONTAL';
        component.paddingLeft = size.padding;
        component.paddingRight = size.padding;
        component.paddingTop = (size.height - size.fontSize) / 2;
        component.paddingBottom = (size.height - size.fontSize) / 2;
        component.primaryAxisSizingMode = 'AUTO';
        component.counterAxisSizingMode = 'FIXED';
        component.counterAxisAlignItems = 'CENTER';
        component.itemSpacing = 8;
        component.cornerRadius = size.radius;
        component.resize(120, size.height);
        component.clipsContent = false;  // Allow holographic rim effects

        const label = await createText('Button', size.fontSize, 'Medium');
        label.name = 'Label';

        let bgColor = COLORS.blue;
        let textColor = COLORS.white;
        let hasBorder = false;
        let addHolographicRim = false;

        if (style === 'Primary') {
          bgColor = COLORS.blue;
          textColor = COLORS.white;
          addHolographicRim = (state === 'Default' || state === 'Hover');  // Add rim to active buttons
        } else if (style === 'Secondary') {
          bgColor = COLORS.gray200;
          textColor = COLORS.gray900;
        } else if (style === 'Tertiary') {
          bgColor = COLORS.transparent;
          textColor = COLORS.gray900;
          hasBorder = true;
        } else if (style === 'Danger') {
          bgColor = COLORS.red;
          textColor = COLORS.white;
          addHolographicRim = (state === 'Default' || state === 'Hover');  // Add rim to active buttons
        }

        let opacity = 1.0;
        if (state === 'Hover') {
          bgColor = { r: Math.min(1, bgColor.r * 1.1), g: Math.min(1, bgColor.g * 1.1), b: Math.min(1, bgColor.b * 1.1) };
        } else if (state === 'Active') {
          bgColor = { r: bgColor.r * 0.9, g: bgColor.g * 0.9, b: bgColor.b * 0.9 };
        } else if (state === 'Disabled') {
          opacity = 0.5;
        }

        label.fills = [{ type: 'SOLID', color: textColor }];
        component.appendChild(label);

        if (style === 'Tertiary') {
          component.fills = [];
          component.strokes = [{ type: 'SOLID', color: COLORS.gray300 }];
          component.strokeWeight = 1;
        } else {
          component.fills = [{ type: 'SOLID', color: bgColor, opacity }];
        }

        // Add button shadow
        component.effects = [{
          type: 'DROP_SHADOW',
          ...EffectTokens.shadows.button,
          visible: true,
          blendMode: 'NORMAL'
        }];

        // Add holographic rim for Primary/Danger buttons in Default/Hover states
        if (addHolographicRim) {
          const mode = style === 'Primary' ? 'mail' : 'ads';  // Primary = mail colors, Danger = ads colors
          const rim = createButtonHolographicRim(120, size.height, size.radius, mode);
          component.appendChild(rim);
        }

        components.push(component);
      }
    }
  }

  console.log(`Created ${components.length} button variants with holographic rims`);

  components.forEach(comp => figma.currentPage.appendChild(comp));
  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'ZeroButton';

  return componentSet;
}

// MARK: - ZeroCard Generator (24 variants) WITH GLASSMORPHIC + NEBULA
// Updated to match new card layout: Title → Sender Row → AI Analysis → Bottom Action Bar

async function generateZeroCardVariants(): Promise<ComponentSetNode> {
  console.log('Generating ZeroCard with new layout (title at top, AI Analysis section, bottom action bar)...');

  const archetypes = ['Mail', 'Ads'];
  const priorities = [
    { name: 'High', color: COLORS.red },
    { name: 'Medium', color: COLORS.yellow },
    { name: 'Low', color: null }
  ];
  const states = [
    { name: 'Default', textOpacity: 1.0 },
    { name: 'Read', textOpacity: 0.6 }
  ];

  const components: ComponentNode[] = [];

  for (const archetype of archetypes) {
    for (const priority of priorities) {
      for (const state of states) {
        const component = figma.createComponent();
        component.name = `Archetype=${archetype}, Priority=${priority.name}, State=${state.name}`;

        const isAds = archetype === 'Ads';
        const textOpacity = state.textOpacity;

        // Convert to frame for layering
        component.layoutMode = 'VERTICAL';
        component.paddingLeft = 20;
        component.paddingRight = 20;
        component.paddingTop = 20;
        component.paddingBottom = 20;
        component.itemSpacing = 12;
        component.primaryAxisSizingMode = 'AUTO';
        component.counterAxisSizingMode = 'FIXED';
        component.resize(358, 520);
        component.cornerRadius = 16;
        component.clipsContent = false;

        // Add background (nebula for Mail, scenic gradient for Ads)
        if (isAds) {
          const adsBackground = createScenicBackground(358, 520);
          adsBackground.y = -20;
          adsBackground.x = -20;
          component.insertChild(0, adsBackground);
        } else {
          const nebula = createNebulaBackground(358, 520);
          nebula.y = -20;
          nebula.x = -20;
          component.insertChild(0, nebula);
        }

        // Add glassmorphic layer (above background)
        const glass = createGlassmorphicLayer(358, 520, 16);
        glass.y = -20;
        glass.x = -20;
        component.insertChild(1, glass);

        // Priority indicator
        if (priority.color) {
          component.strokes = [{ type: 'SOLID', color: priority.color }];
          component.strokeWeight = 3;
          component.strokeAlign = 'INSIDE';
        }

        // Card shadow
        component.effects = [{
          type: 'DROP_SHADOW',
          ...EffectTokens.shadows.card,
          visible: true,
          blendMode: 'NORMAL'
        }];

        // Text colors
        const textColorPrimary = isAds ? hexToRgb('#0D594D') : { r: 1, g: 1, b: 1 };
        const textColorSubtle = isAds ? hexToRgb('#269985') : { r: 1, g: 1, b: 1 };

        // 1. TITLE (at top)
        const title = await createText('Field Trip Permission Form - Science Museum', 20, 'Bold');
        title.name = 'Title';
        title.fills = [{ type: 'SOLID', color: textColorPrimary, opacity: textOpacity }];
        title.layoutSizingHorizontal = 'FILL';
        component.appendChild(title);

        // 2. SENDER ROW (Avatar + Name + Time + View Button)
        const senderRow = createAutoLayoutFrame('Sender Row', 'HORIZONTAL', 12, 0);
        senderRow.primaryAxisSizingMode = 'FIXED';
        senderRow.counterAxisSizingMode = 'AUTO';
        senderRow.counterAxisAlignItems = 'CENTER';
        senderRow.resize(318, 50);

        // Avatar
        const avatar = figma.createEllipse();
        avatar.name = 'Avatar';
        avatar.resize(40, 40);
        avatar.fills = [{ type: 'SOLID', color: isAds ? hexToRgb('#16bbaa') : { r: 0.2, g: 0.8, b: 0.4 } }];
        senderRow.appendChild(avatar);

        // Avatar initial
        const initial = await createText('J', 18, 'Semi Bold');
        initial.name = 'Initial';
        initial.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
        initial.x = 14;
        initial.y = 8;
        // Note: Initial positioning handled by avatar parent

        // Sender details
        const senderDetails = createAutoLayoutFrame('Sender Details', 'VERTICAL', 2, 0);
        senderDetails.primaryAxisSizingMode = 'AUTO';
        senderDetails.counterAxisSizingMode = 'FILL';
        senderDetails.layoutGrow = 1;

        const nameTimeRow = createAutoLayoutFrame('Name Time', 'HORIZONTAL', 8, 0);
        const senderName = await createText('Mrs. Johnson', 16, 'Semi Bold');
        senderName.fills = [{ type: 'SOLID', color: textColorPrimary, opacity: textOpacity }];
        const timeAgo = await createText('2h ago', 13, 'Medium');
        timeAgo.fills = [{ type: 'SOLID', color: textColorSubtle, opacity: 0.8 }];
        nameTimeRow.appendChild(senderName);
        nameTimeRow.appendChild(timeAgo);

        const recipients = await createText('to me, spouse@email.com', 12, 'Regular');
        recipients.fills = [{ type: 'SOLID', color: textColorSubtle, opacity: 0.7 }];

        senderDetails.appendChild(nameTimeRow);
        senderDetails.appendChild(recipients);
        senderRow.appendChild(senderDetails);

        // View button
        const viewButton = createAutoLayoutFrame('View Button', 'VERTICAL', 4, 0);
        viewButton.paddingTop = 8;
        viewButton.paddingBottom = 8;
        viewButton.paddingLeft = 8;
        viewButton.paddingRight = 8;
        viewButton.counterAxisAlignItems = 'CENTER';
        viewButton.cornerRadius = 12;
        viewButton.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0.25 }];

        const viewIcon = await createText('View', 10, 'Medium');
        viewIcon.fills = [{ type: 'SOLID', color: isAds ? textColorPrimary : { r: 1, g: 1, b: 1 }, opacity: 0.85 }];
        viewButton.appendChild(viewIcon);
        senderRow.appendChild(viewButton);

        component.appendChild(senderRow);

        // 3. AI ANALYSIS BOX
        const aiBox = createAutoLayoutFrame('AI Analysis', 'VERTICAL', 12, 0);
        aiBox.paddingTop = 16;
        aiBox.paddingBottom = 16;
        aiBox.paddingLeft = 16;
        aiBox.paddingRight = 16;
        aiBox.cornerRadius = 12;
        aiBox.layoutSizingHorizontal = 'FILL';

        // AI box background gradient
        const aiBoxGradient = isAds ? [
          { position: 0, color: { ...hexToRgb('#16bbaa'), a: 0.35 } },
          { position: 1, color: { ...hexToRgb('#4fd19e'), a: 0.25 } }
        ] : [
          { position: 0, color: { r: 0.5, g: 0.2, b: 0.8, a: 0.2 } },
          { position: 1, color: { r: 0.5, g: 0.2, b: 0.8, a: 0.15 } }
        ];
        aiBox.fills = [{
          type: 'GRADIENT_LINEAR',
          gradientTransform: [[1, 0, 0], [0, 1, 0]],
          gradientStops: aiBoxGradient
        }];
        aiBox.strokes = [{
          type: 'SOLID',
          color: isAds ? hexToRgb('#4fd19e') : { r: 0.5, g: 0.2, b: 0.8 },
          opacity: 0.4
        }];
        aiBox.strokeWeight = 1.5;

        // AI Analysis header with star
        const aiHeader = createAutoLayoutFrame('AI Header', 'HORIZONTAL', 8, 0);
        aiHeader.counterAxisAlignItems = 'CENTER';
        const starCircle = figma.createEllipse();
        starCircle.resize(24, 24);
        starCircle.fills = [{
          type: 'GRADIENT_LINEAR',
          gradientTransform: [[1, 0, 0], [0, 1, 0]],
          gradientStops: [
            { position: 0, color: { r: 1, g: 0.9, b: 0.2, a: 0.9 } },
            { position: 1, color: { r: 1, g: 0.6, b: 0.2, a: 0.8 } }
          ]
        }];
        aiHeader.appendChild(starCircle);
        const aiTitle = await createText('AI ANALYSIS', 11, 'Bold');
        aiTitle.fills = [{ type: 'SOLID', color: isAds ? textColorPrimary : { r: 1, g: 1, b: 1 }, opacity: 0.9 }];
        aiHeader.appendChild(aiTitle);
        aiBox.appendChild(aiHeader);

        // SUGGESTED ACTIONS section
        const actionsHeader = createAutoLayoutFrame('Actions Header', 'HORIZONTAL', 0, 0);
        actionsHeader.layoutSizingHorizontal = 'FILL';
        actionsHeader.primaryAxisAlignItems = 'SPACE_BETWEEN';
        const actionsLabel = await createText('SUGGESTED ACTIONS', 11, 'Semi Bold');
        actionsLabel.fills = [{ type: 'SOLID', color: isAds ? textColorSubtle : { r: 1, g: 1, b: 1 }, opacity: 0.7 }];
        actionsHeader.appendChild(actionsLabel);
        const arrow = await createText('→', 14, 'Medium');
        arrow.fills = [{ type: 'SOLID', color: isAds ? textColorPrimary : { r: 1, g: 1, b: 1 }, opacity: 0.9 }];
        actionsHeader.appendChild(arrow);
        aiBox.appendChild(actionsHeader);

        const actionText = await createText('• Sign permission form by Oct 24 • Pay $25 field trip fee', 15, 'Regular');
        actionText.fills = [{ type: 'SOLID', color: isAds ? textColorPrimary : { r: 1, g: 1, b: 1 } }];
        actionText.layoutSizingHorizontal = 'FILL';
        aiBox.appendChild(actionText);

        // WHY THIS MATTERS section
        const whyLabel = await createText('WHY THIS MATTERS', 11, 'Semi Bold');
        whyLabel.fills = [{ type: 'SOLID', color: isAds ? textColorSubtle : { r: 1, g: 1, b: 1 }, opacity: 0.7 }];
        aiBox.appendChild(whyLabel);

        const whyText = await createText('Emma needs permission and payment for upcoming field trip.', 14, 'Regular');
        whyText.fills = [{ type: 'SOLID', color: isAds ? textColorSubtle : { r: 1, g: 1, b: 1 }, opacity: 0.85 }];
        whyText.layoutSizingHorizontal = 'FILL';
        aiBox.appendChild(whyText);

        // CONTEXT section
        const contextLabel = await createText('CONTEXT', 11, 'Semi Bold');
        contextLabel.fills = [{ type: 'SOLID', color: isAds ? textColorSubtle : { r: 1, g: 1, b: 1 }, opacity: 0.7 }];
        aiBox.appendChild(contextLabel);

        const contextText = await createText('• Oct 28 trip to Science Museum • Departs 8:30 AM, returns 2:30 PM • Dinosaur ex...', 14, 'Regular');
        contextText.fills = [{ type: 'SOLID', color: isAds ? textColorSubtle : { r: 1, g: 1, b: 1 }, opacity: 0.85 }];
        contextText.layoutSizingHorizontal = 'FILL';
        aiBox.appendChild(contextText);

        component.appendChild(aiBox);

        // 4. BOTTOM ACTION BAR
        const bottomBar = createAutoLayoutFrame('Bottom Action Bar', 'HORIZONTAL', 0, 0);
        bottomBar.layoutSizingHorizontal = 'FILL';
        bottomBar.primaryAxisAlignItems = 'SPACE_BETWEEN';
        bottomBar.counterAxisAlignItems = 'CENTER';
        bottomBar.paddingTop = 12;
        bottomBar.paddingBottom = 12;
        bottomBar.paddingLeft = 12;
        bottomBar.paddingRight = 12;
        bottomBar.cornerRadius = 8;
        bottomBar.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: isAds ? 0.1 : 0.05 }];

        // Navigation dots
        const navDots = createAutoLayoutFrame('Nav Dots', 'HORIZONTAL', 4, 0);
        for (let i = 0; i < 3; i++) {
          const chevron = await createText('›', 10, 'Bold');
          chevron.fills = [{ type: 'SOLID', color: isAds ? textColorSubtle : { r: 1, g: 1, b: 1 }, opacity: i === 2 ? 1.0 : (i === 1 ? 0.7 : 0.4) }];
          navDots.appendChild(chevron);
        }
        bottomBar.appendChild(navDots);

        // CTA Button
        const ctaButton = createAutoLayoutFrame('CTA Button', 'HORIZONTAL', 0, 0);
        ctaButton.paddingTop = 8;
        ctaButton.paddingBottom = 8;
        ctaButton.paddingLeft = 16;
        ctaButton.paddingRight = 16;
        ctaButton.cornerRadius = 8;
        const ctaGradient = isAds ? [
          { position: 0, color: { ...hexToRgb('#16bbaa'), a: 1 } },
          { position: 1, color: { ...hexToRgb('#4fd19e'), a: 1 } }
        ] : [
          { position: 0, color: { r: 1, g: 1, b: 1, a: 0.25 } },
          { position: 1, color: { r: 1, g: 1, b: 1, a: 0.15 } }
        ];
        ctaButton.fills = [{
          type: 'GRADIENT_LINEAR',
          gradientTransform: [[1, 0, 0], [0, 1, 0]],
          gradientStops: ctaGradient
        }];
        const ctaLabel = await createText(isAds ? 'Claim Deal' : 'Sign & Send', 15, 'Medium');
        ctaLabel.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
        ctaButton.appendChild(ctaLabel);
        bottomBar.appendChild(ctaButton);

        component.appendChild(bottomBar);

        components.push(component);
      }
    }
  }

  console.log(`Created ${components.length} card variants with new layout (2 archetypes × 3 priorities × 2 states)`);

  components.forEach(comp => figma.currentPage.appendChild(comp));
  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'ZeroCard';

  return componentSet;
}

// MARK: - ZeroModal, ZeroListItem, ZeroAlert (unchanged from base generator)

async function generateZeroModalVariants(): Promise<ComponentSetNode> {
  console.log('Generating ZeroModal...');

  const sizes = [
    { name: 'Small', width: 335, padding: 24 },
    { name: 'Medium', width: 480, padding: 24 },
    { name: 'Large', width: 600, padding: 24 }
  ];
  const states = [
    { name: 'Open', opacity: 1.0 },
    { name: 'Closed', opacity: 0.0 }
  ];

  const components: ComponentNode[] = [];

  for (const size of sizes) {
    for (const state of states) {
      const component = figma.createComponent();
      component.name = `Size=${size.name}, State=${state.name}`;

      component.layoutMode = 'VERTICAL';
      component.paddingLeft = size.padding;
      component.paddingRight = size.padding;
      component.paddingTop = size.padding;
      component.paddingBottom = size.padding;
      component.itemSpacing = 16;
      component.primaryAxisSizingMode = 'AUTO';
      component.counterAxisSizingMode = 'FIXED';
      component.resize(size.width, 200);
      component.cornerRadius = 20;
      component.fills = [{ type: 'SOLID', color: COLORS.white }];
      component.opacity = state.opacity;

      // Apply modal shadow
      component.effects = [{
        type: 'DROP_SHADOW',
        ...EffectTokens.shadows.modal,
        visible: true,
        blendMode: 'NORMAL'
      }];

      const header = createAutoLayoutFrame('Header', 'HORIZONTAL', 12, 0);
      header.primaryAxisSizingMode = 'FIXED';
      header.counterAxisSizingMode = 'AUTO';
      header.primaryAxisAlignItems = 'SPACE_BETWEEN';
      header.resize(size.width - size.padding * 2, 24);

      const title = await createText('Modal Title', 17, 'Semi Bold');
      title.name = 'Title';
      header.appendChild(title);

      const closeBtn = await createText('×', 24, 'Regular');
      closeBtn.name = 'Close';
      closeBtn.fills = [{ type: 'SOLID', color: COLORS.gray900, opacity: 0.5 }];
      header.appendChild(closeBtn);

      component.appendChild(header);

      const message = await createText('This is a modal dialog message.', 15, 'Regular');
      message.name = 'Message';
      message.fills = [{ type: 'SOLID', color: COLORS.gray900, opacity: 0.8 }];
      component.appendChild(message);

      components.push(component);
    }
  }

  components.forEach(comp => figma.currentPage.appendChild(comp));
  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'ZeroModal';

  return componentSet;
}

async function generateZeroListItemVariants(): Promise<ComponentSetNode> {
  console.log('Generating ZeroListItem...');

  const types = ['Navigation', 'Action'];
  const states = [
    { name: 'Default', bg: COLORS.transparent, text: COLORS.gray900 },
    { name: 'Hover', bg: { r: 0.98, g: 0.98, b: 0.98 }, text: COLORS.gray900 },
    { name: 'Selected', bg: COLORS.blueBg, text: COLORS.blue }
  ];

  const components: ComponentNode[] = [];

  for (const type of types) {
    for (const state of states) {
      const component = figma.createComponent();
      component.name = `Type=${type}, State=${state.name}`;

      component.layoutMode = 'HORIZONTAL';
      component.paddingLeft = 16;
      component.paddingRight = 16;
      component.paddingTop = 12;
      component.paddingBottom = 12;
      component.itemSpacing = 12;
      component.primaryAxisSizingMode = 'FIXED';
      component.counterAxisSizingMode = 'FIXED';
      component.counterAxisAlignItems = 'CENTER';
      component.primaryAxisAlignItems = 'SPACE_BETWEEN';
      component.resize(320, 44);
      component.cornerRadius = 8;
      component.fills = state.bg === COLORS.transparent ? [] : [{ type: 'SOLID', color: state.bg }];

      const icon = figma.createRectangle();
      icon.name = 'Icon';
      icon.resize(20, 20);
      icon.cornerRadius = 4;
      icon.fills = [{ type: 'SOLID', color: state.text, opacity: 0.7 }];
      component.appendChild(icon);

      const label = await createText('List Item Label', 15, 'Regular');
      label.name = 'Label';
      label.fills = [{ type: 'SOLID', color: state.text }];
      component.appendChild(label);

      if (type === 'Navigation') {
        const chevron = await createText('›', 18, 'Regular');
        chevron.name = 'Chevron';
        chevron.fills = [{ type: 'SOLID', color: COLORS.gray900, opacity: 0.3 }];
        component.appendChild(chevron);
      } else {
        const badge = figma.createFrame();
        badge.name = 'Badge';
        badge.layoutMode = 'HORIZONTAL';
        badge.paddingLeft = 6;
        badge.paddingRight = 6;
        badge.paddingTop = 2;
        badge.paddingBottom = 2;
        badge.primaryAxisSizingMode = 'AUTO';
        badge.counterAxisSizingMode = 'AUTO';
        badge.cornerRadius = 10;
        badge.fills = [{ type: 'SOLID', color: COLORS.red }];

        const badgeText = await createText('3', 11, 'Bold');
        badgeText.fills = [{ type: 'SOLID', color: COLORS.white }];
        badge.appendChild(badgeText);
        component.appendChild(badge);
      }

      components.push(component);
    }
  }

  components.forEach(comp => figma.currentPage.appendChild(comp));
  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'ZeroListItem';

  return componentSet;
}

async function generateZeroAlertVariants(): Promise<ComponentSetNode> {
  console.log('Generating ZeroAlert...');

  const types = [
    { name: 'Success', bg: COLORS.greenBg, border: COLORS.green, text: COLORS.greenText, icon: '✓' },
    { name: 'Error', bg: COLORS.redBg, border: COLORS.red, text: COLORS.redText, icon: '×' },
    { name: 'Warning', bg: COLORS.yellowBg, border: COLORS.yellow, text: COLORS.yellowText, icon: '⚠' },
    { name: 'Info', bg: COLORS.blueBg, border: COLORS.blue, text: COLORS.blueText, icon: 'ℹ' }
  ];
  const positions = ['Top', 'Bottom'];

  const components: ComponentNode[] = [];

  for (const type of types) {
    for (const position of positions) {
      const component = figma.createComponent();
      component.name = `Type=${type.name}, Position=${position}`;

      component.layoutMode = 'HORIZONTAL';
      component.paddingLeft = 12;
      component.paddingRight = 12;
      component.paddingTop = 12;
      component.paddingBottom = 12;
      component.itemSpacing = 10;
      component.primaryAxisSizingMode = 'AUTO';
      component.counterAxisSizingMode = 'AUTO';
      component.counterAxisAlignItems = 'CENTER';
      component.cornerRadius = 12;
      component.fills = [{ type: 'SOLID', color: type.bg }];
      component.strokes = [{ type: 'SOLID', color: type.border }];
      component.strokeWeight = 1;

      const icon = await createText(type.icon, 16, 'Bold');
      icon.name = 'Icon';
      icon.fills = [{ type: 'SOLID', color: type.border }];
      component.appendChild(icon);

      const message = await createText('Alert message text', 14, 'Medium');
      message.name = 'Message';
      message.fills = [{ type: 'SOLID', color: type.text }];
      component.appendChild(message);

      const close = await createText('×', 18, 'Regular');
      close.name = 'Close';
      close.fills = [{ type: 'SOLID', color: type.text, opacity: 0.6 }];
      component.appendChild(close);

      components.push(component);
    }
  }

  components.forEach(comp => figma.currentPage.appendChild(comp));
  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'ZeroAlert';

  return componentSet;
}

// MARK: - Main Generation Function

async function generateAllComponentsWithEffects() {
  try {
    console.log('Loading fonts...');
    await Promise.all([
      figma.loadFontAsync({ family: 'Inter', style: 'Regular' }),
      figma.loadFontAsync({ family: 'Inter', style: 'Medium' }),
      figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' }),
      figma.loadFontAsync({ family: 'Inter', style: 'Bold' })
    ]);
    console.log('Fonts loaded successfully');

    let componentsPage = figma.root.children.find(page => page.name === 'Components') as PageNode;
    if (!componentsPage) {
      componentsPage = figma.createPage();
      componentsPage.name = 'Components';
    }
    figma.currentPage = componentsPage;

    const componentSets: ComponentSetNode[] = [];

    console.log('\n🎨 Generating components with visual effects...\n');

    componentSets.push(await generateZeroButtonVariants());     // 48 variants (WITH holographic rims)
    componentSets.push(await generateZeroCardVariants());       // 24 variants (WITH glassmorphic + nebula)
    componentSets.push(await generateZeroModalVariants());      // 6 variants
    componentSets.push(await generateZeroListItemVariants());   // 6 variants
    componentSets.push(await generateZeroAlertVariants());      // 8 variants

    // Arrange components in a grid (2 columns to prevent horizontal overflow)
    const spacing = 150;
    const columnWidth = 500;  // Fixed column width for consistency
    let xOffset = 0;
    let yOffset = 0;
    let column = 0;

    for (const componentSet of componentSets) {
      componentSet.x = xOffset;
      componentSet.y = yOffset;

      column++;
      if (column >= 2) {
        // Move to next row
        column = 0;
        xOffset = 0;
        yOffset += 700;  // Vertical spacing for next row (cards are 500px tall + spacing)
      } else {
        // Move to next column
        xOffset += columnWidth + spacing;
      }
    }

    figma.viewport.scrollAndZoomIntoView(componentSets);

    const totalVariants = 48 + 24 + 6 + 6 + 8;
    figma.closePlugin(`✨ Generated 5 components with ${totalVariants} variants + VISUAL EFFECTS!\n\n` +
      `🎨 Visual Effects Added:\n` +
      `• Glassmorphic backgrounds (frosted glass + rim lighting)\n` +
      `• Nebula gradients (4-layer radial gradients + particles)\n` +
      `• Holographic button rims (multi-color gradients + edge glow)\n` +
      `• Proper shadows (card, modal, button)\n\n` +
      `📦 Components:\n` +
      `• ZeroButton: 48 variants (4 styles × 3 sizes × 4 states) + holographic rims\n` +
      `• ZeroCard: 24 variants (2 layouts × 3 priorities × 4 states) + glassmorphic + nebula\n` +
      `• ZeroModal: 6 variants (3 sizes × 2 states)\n` +
      `• ZeroListItem: 6 variants (2 types × 3 states)\n` +
      `• ZeroAlert: 8 variants (4 types × 2 positions)\n\n` +
      `Check the Components page!`);

  } catch (error: any) {
    console.error('Error generating components:', error);
    figma.closePlugin(`❌ Error: ${error?.message || 'Unknown error'}`);
  }
}

// Run the plugin
generateAllComponentsWithEffects();

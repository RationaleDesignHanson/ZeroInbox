/**
 * Holographic Rim Effect Utilities
 *
 * Creates holographic rim effects for action buttons matching iOS SimpleCardView.swift
 *
 * iOS Source: /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Views/SimpleCardView.swift:52-78
 *
 * Effect Composition:
 * 1. Multi-color gradient stroke (4 colors, mode-specific)
 * 2. Edge glow effect (outer glow with mode color)
 * 3. Shimmer animation (in iOS, static in Figma)
 */

/**
 * Design tokens for holographic rims
 */
export const HolographicTokens = {
  // ADS mode colors (teal/green)
  ads: {
    stroke: [
      { color: '#16bbaa', opacity: 0.7 },  // Strong teal
      { color: '#4fd19e', opacity: 0.8 },  // Strong green
      { color: '#16bbaa', opacity: 0.6 },  // Medium teal
      { color: '#4fd19e', opacity: 0.5 }   // Light green
    ],
    edgeGlow: {
      color: '#4fd19e',                    // Bright green
      opacity: 0.6,
      blur: 8
    }
  },

  // MAIL mode colors (cyan/blue/purple/pink)
  mail: {
    stroke: [
      { color: '#00FFFF', opacity: 0.4 },  // Cyan
      { color: '#0000FF', opacity: 0.5 },  // Blue
      { color: '#800080', opacity: 0.4 },  // Purple
      { color: '#FF00FF', opacity: 0.3 }   // Pink
    ],
    edgeGlow: {
      color: '#00FFFF',                    // Cyan
      opacity: 0.5,
      blur: 8
    }
  },

  // Generic holographic (multi-color rainbow)
  generic: {
    stroke: [
      { color: '#FF00FF', opacity: 0.5 },  // Magenta
      { color: '#00FFFF', opacity: 0.6 },  // Cyan
      { color: '#FFFF00', opacity: 0.5 },  // Yellow
      { color: '#FF00FF', opacity: 0.4 }   // Magenta (loop)
    ],
    edgeGlow: {
      color: '#FFFFFF',                    // White
      opacity: 0.4,
      blur: 10
    }
  },

  strokeWeight: 2,  // Border thickness
  innerStrokeWeight: 1  // Inner highlight stroke
};

/**
 * Hex to RGB converter
 */
function hexToRgb(hex: string): RGB {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) return { r: 0, g: 0, b: 0 };

  return {
    r: parseInt(result[1], 16) / 255,
    g: parseInt(result[2], 16) / 255,
    b: parseInt(result[3], 16) / 255
  };
}

/**
 * Creates a holographic rim stroke on a button
 *
 * @param width - Button width
 * @param height - Button height
 * @param cornerRadius - Corner radius
 * @param mode - Holographic mode ('ads', 'mail', or 'generic')
 * @returns Figma RectangleNode with holographic stroke
 */
export function createHolographicRim(
  width: number,
  height: number,
  cornerRadius: number,
  mode: 'ads' | 'mail' | 'generic' = 'generic'
): RectangleNode {
  const rim = figma.createRectangle();
  rim.name = `Holographic Rim (${mode.toUpperCase()})`;
  rim.resize(width, height);
  rim.cornerRadius = cornerRadius;

  // Transparent fill
  rim.fills = [];

  // Get mode-specific colors
  const tokens = mode === 'ads'
    ? HolographicTokens.ads
    : mode === 'mail'
    ? HolographicTokens.mail
    : HolographicTokens.generic;

  // Multi-color gradient stroke
  rim.strokes = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [
      [1, 0, 0],      // Left to right
      [0, 1, 0]       // Top to bottom (creates diagonal)
    ],
    gradientStops: tokens.stroke.map((c, i) => ({
      position: i / (tokens.stroke.length - 1),
      color: { ...hexToRgb(c.color), a: c.opacity }
    }))
  }];

  rim.strokeWeight = HolographicTokens.strokeWeight;

  // Edge glow effect (outer glow)
  rim.effects = [{
    type: 'DROP_SHADOW',
    color: { ...hexToRgb(tokens.edgeGlow.color), a: tokens.edgeGlow.opacity },
    offset: { x: 0, y: 0 },
    radius: tokens.edgeGlow.blur,
    spread: 0,
    visible: true,
    blendMode: 'NORMAL'
  }];

  return rim;
}

/**
 * Creates an inner highlight stroke
 * Adds subtle inner glow for depth
 *
 * @param width - Button width
 * @param height - Button height
 * @param cornerRadius - Corner radius
 * @returns Figma RectangleNode with inner highlight
 */
export function createInnerHighlight(
  width: number,
  height: number,
  cornerRadius: number
): RectangleNode {
  const highlight = figma.createRectangle();
  highlight.name = 'Inner Highlight';
  highlight.resize(width, height);
  highlight.cornerRadius = cornerRadius;

  // Transparent fill
  highlight.fills = [];

  // White stroke with low opacity
  highlight.strokes = [{
    type: 'SOLID',
    color: { r: 1, g: 1, b: 1 },
    opacity: 0.3
  }];

  highlight.strokeWeight = HolographicTokens.innerStrokeWeight;
  highlight.strokeAlign = 'INSIDE';

  // Inner glow (using inner shadow)
  highlight.effects = [{
    type: 'INNER_SHADOW',
    color: { r: 1, g: 1, b: 1, a: 0.4 },
    offset: { x: 0, y: -1 },
    radius: 2,
    spread: 0,
    visible: true,
    blendMode: 'NORMAL'
  }];

  return highlight;
}

/**
 * Creates a complete holographic button with rim + inner highlight
 *
 * @param width - Button width
 * @param height - Button height
 * @param cornerRadius - Corner radius
 * @param mode - Holographic mode
 * @returns Figma FrameNode with all holographic layers
 */
export function createHolographicButton(
  width: number,
  height: number,
  cornerRadius: number,
  mode: 'ads' | 'mail' | 'generic' = 'generic'
): FrameNode {
  const button = figma.createFrame();
  button.name = `Holographic Button (${mode.toUpperCase()})`;
  button.resize(width, height);
  button.cornerRadius = cornerRadius;

  // Base fill (semi-transparent for glass effect)
  button.fills = [{
    type: 'SOLID',
    color: { r: 1, g: 1, b: 1 },
    opacity: 0.1
  }];

  button.clipsContent = false;  // Allow effects to extend

  // Add holographic rim
  const rim = createHolographicRim(width, height, cornerRadius, mode);
  button.appendChild(rim);

  // Add inner highlight
  const highlight = createInnerHighlight(width, height, cornerRadius);
  button.appendChild(highlight);

  return button;
}

/**
 * Applies holographic rim to an existing button frame
 *
 * @param targetButton - Existing button frame
 * @param mode - Holographic mode
 */
export function applyHolographicRim(
  targetButton: FrameNode,
  mode: 'ads' | 'mail' | 'generic' = 'generic'
): void {
  const width = targetButton.width;
  const height = targetButton.height;
  const cornerRadius = targetButton.cornerRadius as number || 12;

  // Add holographic rim as top layer
  const rim = createHolographicRim(width, height, cornerRadius, mode);
  targetButton.appendChild(rim);

  // Add inner highlight
  const highlight = createInnerHighlight(width, height, cornerRadius);
  targetButton.appendChild(highlight);

  // Ensure button doesn't clip effects
  targetButton.clipsContent = false;
}

/**
 * Creates ADS-specific holographic button
 * Teal/green color scheme for ADS mode
 */
export function createAdsHolographicButton(
  width: number,
  height: number,
  cornerRadius: number = 12
): FrameNode {
  return createHolographicButton(width, height, cornerRadius, 'ads');
}

/**
 * Creates MAIL-specific holographic button
 * Cyan/blue/purple/pink color scheme for MAIL mode
 */
export function createMailHolographicButton(
  width: number,
  height: number,
  cornerRadius: number = 12
): FrameNode {
  return createHolographicButton(width, height, cornerRadius, 'mail');
}

/**
 * Creates a shimmer effect layer (animated in iOS)
 * In Figma, this is a static gradient overlay
 *
 * @param width - Layer width
 * @param height - Layer height
 * @param cornerRadius - Corner radius
 * @returns Figma RectangleNode with shimmer gradient
 */
export function createShimmerLayer(
  width: number,
  height: number,
  cornerRadius: number
): RectangleNode {
  const shimmer = figma.createRectangle();
  shimmer.name = 'Shimmer Effect';
  shimmer.resize(width, height);
  shimmer.cornerRadius = cornerRadius;

  // Diagonal gradient with bright spots
  shimmer.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [
      [0.707, 0.707, 0],    // 45-degree angle
      [-0.707, 0.707, 0]
    ],
    gradientStops: [
      { position: 0, color: { r: 1, g: 1, b: 1, a: 0 } },
      { position: 0.4, color: { r: 1, g: 1, b: 1, a: 0.2 } },
      { position: 0.5, color: { r: 1, g: 1, b: 1, a: 0.4 } },
      { position: 0.6, color: { r: 1, g: 1, b: 1, a: 0.2 } },
      { position: 1, color: { r: 1, g: 1, b: 1, a: 0 } }
    ]
  }];

  shimmer.blendMode = 'OVERLAY';

  return shimmer;
}

/**
 * Creates a pulsing glow effect (for active/pressed states)
 *
 * @param width - Glow width (slightly larger than button)
 * @param height - Glow height
 * @param color - Glow color (hex)
 * @param opacity - Glow opacity
 * @returns Figma EllipseNode with glow
 */
export function createPulsingGlow(
  width: number,
  height: number,
  color: string,
  opacity: number = 0.5
): EllipseNode {
  const glow = figma.createEllipse();
  glow.name = 'Pulsing Glow';
  glow.resize(width, height);

  glow.fills = [{
    type: 'GRADIENT_RADIAL',
    gradientTransform: [
      [1, 0, 0.5],
      [0, 1, 0.5]
    ],
    gradientStops: [
      { position: 0, color: { ...hexToRgb(color), a: opacity } },
      { position: 0.5, color: { ...hexToRgb(color), a: opacity * 0.5 } },
      { position: 1, color: { ...hexToRgb(color), a: 0 } }
    ]
  }];

  glow.effects = [{
    type: 'LAYER_BLUR',
    radius: 20,
    visible: true
  }];

  return glow;
}

/**
 * Creates button background with gradient fill
 * Used for primary action buttons with holographic rims
 *
 * @param width - Button width
 * @param height - Button height
 * @param startColor - Gradient start (hex)
 * @param endColor - Gradient end (hex)
 * @param cornerRadius - Corner radius
 * @returns Figma RectangleNode with gradient
 */
export function createGradientButtonBackground(
  width: number,
  height: number,
  startColor: string,
  endColor: string,
  cornerRadius: number = 12
): RectangleNode {
  const background = figma.createRectangle();
  background.name = 'Gradient Background';
  background.resize(width, height);
  background.cornerRadius = cornerRadius;

  background.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [
      [1, 0, 0],
      [0, 1, 0]
    ],
    gradientStops: [
      { position: 0, color: { ...hexToRgb(startColor), a: 1 } },
      { position: 1, color: { ...hexToRgb(endColor), a: 1 } }
    ]
  }];

  return background;
}

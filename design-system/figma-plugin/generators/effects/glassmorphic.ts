/**
 * Glassmorphic Effect Utilities
 *
 * Creates frosted glass effects matching iOS GlassmorphicModifier.swift
 *
 * iOS Source: /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Views/Components/GlassmorphicModifier.swift
 *
 * Effect Composition:
 * 1. Frosted glass base (white 5-20% opacity)
 * 2. Background blur effect (20-40px)
 * 3. Holographic rim lighting (gradient border)
 * 4. Specular highlight overlay (top-left to bottom-right)
 */

/**
 * Design tokens for glassmorphic effects
 * From DesignTokens.swift:90-100
 */
export const GlassmorphicTokens = {
  opacity: {
    ultraLight: 0.05,  // Ultra-premium frosted glass
    light: 0.1,        // Light frosted glass
    medium: 0.2,       // Medium frosted glass
  },
  blur: {
    standard: 20,      // Standard blur radius
    heavy: 30,         // Heavy blur (cards)
    ultra: 40,         // Ultra blur (modals)
  },
  rim: {
    thickness: 1,      // Border thickness
    opacity: 0.3,      // Rim opacity
  },
  specular: {
    opacity: 0.2,      // Highlight opacity
  }
};

/**
 * RGB color utility for Figma
 */
function rgb(r: number, g: number, b: number): RGB {
  return { r: r / 255, g: g / 255, b: b / 255 };
}

/**
 * Creates a frosted glass background layer
 *
 * @param width - Layer width
 * @param height - Layer height
 * @param opacity - Glass opacity (0.05-0.2)
 * @param cornerRadius - Corner radius
 * @returns Figma RectangleNode with frosted glass fill
 */
export function createFrostedGlassLayer(
  width: number,
  height: number,
  opacity: number = GlassmorphicTokens.opacity.ultraLight,
  cornerRadius: number = 16
): RectangleNode {
  const glassLayer = figma.createRectangle();
  glassLayer.name = 'Frosted Glass Base';
  glassLayer.resize(width, height);
  glassLayer.cornerRadius = cornerRadius;

  // White fill with low opacity
  glassLayer.fills = [{
    type: 'SOLID',
    color: rgb(255, 255, 255),
    opacity: opacity
  }];

  // Add background blur effect
  // Note: Figma's blur is not native iOS material blur, but approximates it
  glassLayer.effects = [{
    type: 'BACKGROUND_BLUR',
    radius: GlassmorphicTokens.blur.heavy,
    visible: true
  }];

  return glassLayer;
}

/**
 * Creates holographic rim lighting (gradient border)
 *
 * iOS: LinearGradient with shimmer colors (white with varying opacity)
 * Figma: Stroke with gradient fill
 *
 * @param width - Container width
 * @param height - Container height
 * @param cornerRadius - Corner radius
 * @param colors - Optional custom gradient colors
 * @returns Figma RectangleNode with gradient stroke
 */
export function createHolographicRim(
  width: number,
  height: number,
  cornerRadius: number = 16,
  colors?: Array<{ color: RGB; stop: number; opacity: number }>
): RectangleNode {
  const rimLayer = figma.createRectangle();
  rimLayer.name = 'Holographic Rim';
  rimLayer.resize(width, height);
  rimLayer.cornerRadius = cornerRadius;

  // Transparent fill
  rimLayer.fills = [];

  // Default shimmer gradient (white with varying opacity)
  const defaultColors = [
    { color: rgb(255, 255, 255), stop: 0, opacity: 0.4 },
    { color: rgb(255, 255, 255), stop: 0.33, opacity: 0.1 },
    { color: rgb(255, 255, 255), stop: 0.66, opacity: 0.3 },
    { color: rgb(255, 255, 255), stop: 1, opacity: 0.2 }
  ];

  const gradientColors = colors || defaultColors;

  // Gradient stroke
  rimLayer.strokes = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [
      [1, 0, 0],      // Top-left
      [0, 1, 0]       // To bottom-right
    ],
    gradientStops: gradientColors.map(c => ({
      position: c.stop,
      color: { ...c.color, a: c.opacity }
    }))
  }];

  rimLayer.strokeWeight = GlassmorphicTokens.rim.thickness;

  return rimLayer;
}

/**
 * Creates specular highlight overlay
 *
 * iOS: Top-left to bottom-right gradient with white opacity
 * Creates light reflection effect on glass surface
 *
 * @param width - Container width
 * @param height - Container height
 * @param cornerRadius - Corner radius
 * @returns Figma RectangleNode with gradient overlay
 */
export function createSpecularHighlight(
  width: number,
  height: number,
  cornerRadius: number = 16
): RectangleNode {
  const highlightLayer = figma.createRectangle();
  highlightLayer.name = 'Specular Highlight';
  highlightLayer.resize(width, height);
  highlightLayer.cornerRadius = cornerRadius;

  // Gradient from top-left (bright) to bottom-right (transparent)
  highlightLayer.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [
      [0.707, 0.707, 0],    // 45-degree angle
      [-0.707, 0.707, 0]
    ],
    gradientStops: [
      { position: 0, color: { r: 1, g: 1, b: 1, a: 0.4 } },      // Bright white
      { position: 0.3, color: { r: 1, g: 1, b: 1, a: 0 } },       // Fade to clear
      { position: 0.7, color: { r: 1, g: 1, b: 1, a: 0 } },       // Stay clear
      { position: 1, color: { r: 1, g: 1, b: 1, a: 0.2 } }        // Subtle reflection at bottom
    ]
  }];

  // Use overlay blend mode for realistic light interaction
  highlightLayer.blendMode = 'OVERLAY';

  return highlightLayer;
}

/**
 * Creates a complete glassmorphic frame with all effect layers
 *
 * Composition (bottom to top):
 * 1. Frosted glass base with background blur
 * 2. Holographic rim lighting
 * 3. Specular highlight overlay
 *
 * @param width - Frame width
 * @param height - Frame height
 * @param options - Configuration options
 * @returns Figma FrameNode with all glassmorphic layers
 */
export function createGlassmorphicFrame(
  width: number,
  height: number,
  options: {
    opacity?: number;
    cornerRadius?: number;
    blur?: number;
    rimColors?: Array<{ color: RGB; stop: number; opacity: number }>;
  } = {}
): FrameNode {
  const frame = figma.createFrame();
  frame.name = 'Glassmorphic Container';
  frame.resize(width, height);
  frame.cornerRadius = options.cornerRadius || 16;

  // Transparent background (effects are in child layers)
  frame.fills = [];
  frame.clipsContent = false;  // Allow effects to extend beyond bounds

  // Layer 1: Frosted glass base
  const glassLayer = createFrostedGlassLayer(
    width,
    height,
    options.opacity,
    options.cornerRadius
  );
  frame.appendChild(glassLayer);

  // Layer 2: Holographic rim
  const rimLayer = createHolographicRim(
    width,
    height,
    options.cornerRadius,
    options.rimColors
  );
  frame.appendChild(rimLayer);

  // Layer 3: Specular highlight
  const highlightLayer = createSpecularHighlight(
    width,
    height,
    options.cornerRadius
  );
  frame.appendChild(highlightLayer);

  return frame;
}

/**
 * Applies glassmorphic effect to an existing frame
 *
 * Adds effect layers as children while preserving existing content
 *
 * @param targetFrame - Existing frame to add effects to
 * @param options - Configuration options
 */
export function applyGlassmorphicEffect(
  targetFrame: FrameNode,
  options: {
    opacity?: number;
    blur?: number;
    rimColors?: Array<{ color: RGB; stop: number; opacity: number }>;
  } = {}
): void {
  const width = targetFrame.width;
  const height = targetFrame.height;
  const cornerRadius = targetFrame.cornerRadius as number || 16;

  // Store existing children
  const existingChildren = targetFrame.children.slice();

  // Add glassmorphic layers at the bottom
  const glassLayer = createFrostedGlassLayer(width, height, options.opacity, cornerRadius);
  targetFrame.insertChild(0, glassLayer);

  const rimLayer = createHolographicRim(width, height, cornerRadius, options.rimColors);
  targetFrame.insertChild(1, rimLayer);

  const highlightLayer = createSpecularHighlight(width, height, cornerRadius);
  targetFrame.insertChild(2, highlightLayer);

  // Existing content is now on top of effect layers
}

/**
 * Creates a card-specific glassmorphic background
 *
 * Optimized for ZeroCard component (358x500px, radius 16px)
 * Uses ultra-light opacity (0.05) for premium feel
 */
export function createCardGlassmorphic(): FrameNode {
  return createGlassmorphicFrame(358, 500, {
    opacity: GlassmorphicTokens.opacity.ultraLight,
    cornerRadius: 16,
    blur: GlassmorphicTokens.blur.heavy
  });
}

/**
 * Creates a modal-specific glassmorphic background
 *
 * Optimized for ZeroModal component (variable width, radius 20px)
 * Uses light opacity (0.1) for better readability
 */
export function createModalGlassmorphic(width: number): FrameNode {
  return createGlassmorphicFrame(width, 400, {
    opacity: GlassmorphicTokens.opacity.light,
    cornerRadius: 20,
    blur: GlassmorphicTokens.blur.ultra
  });
}

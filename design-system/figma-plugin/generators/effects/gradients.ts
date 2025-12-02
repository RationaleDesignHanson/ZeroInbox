/**
 * Gradient Background Utilities
 *
 * Creates animated gradient backgrounds matching iOS RichCardBackground.swift
 *
 * iOS Source: /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Views/Components/RichCardBackground.swift
 *
 * Background Types:
 * 1. Nebula/Galaxy Effect (MAIL) - Deep space with purple/blue gradients + 40 particles
 * 2. Scenic Nature Effect (ADS) - Forest/mountain with teal/green gradients
 */

/**
 * Design tokens for gradient backgrounds
 */
export const GradientTokens = {
  // MAIL gradients (nebula/galaxy)
  mail: {
    primary: { start: '#667eea', end: '#764ba2' },     // Blue → Purple
    nebula: {
      deepPurple: { r: 0.2, g: 0.1, b: 0.4 },         // rgb(51, 26, 102)
      darkBlue: { r: 0.1, g: 0.15, b: 0.3 },          // rgb(26, 38, 77)
      brightPurple: { r: 0.4, g: 0.2, b: 0.6 },       // rgb(102, 51, 153)
      bluePurple: { r: 0.2, g: 0.3, b: 0.7 }          // rgb(51, 77, 179)
    },
    blur: [60, 50, 40, 30],                           // Blur radius for each layer
    opacity: [0.6, 0.3, 0.5, 0.3]                     // Opacity for each gradient layer
  },

  // ADS gradients (scenic/nature)
  ads: {
    primary: { start: '#16bbaa', end: '#4fd19e' },    // Teal → Green
    scenic: {
      teal: { r: 0.086, g: 0.733, b: 0.667 },        // rgb(22, 187, 170)
      green: { r: 0.310, g: 0.820, b: 0.620 },       // rgb(79, 209, 158)
      lightTeal: { r: 0.2, g: 0.8, b: 0.75 },
      darkGreen: { r: 0.25, g: 0.7, b: 0.55 }
    },
    blur: [40, 30],                                   // Blur radius for each layer
    opacity: [0.7, 0.5]                               // Opacity for each layer
  },

  // Particle system
  particles: {
    count: 40,                                        // Number of particles
    minSize: 1,                                       // Minimum particle size
    maxSize: 3,                                       // Maximum particle size
    minOpacity: 0.1,                                  // Minimum particle opacity
    maxOpacity: 0.5                                   // Maximum particle opacity
  }
};

/**
 * RGB color utility
 */
function rgb(r: number, g: number, b: number): RGB {
  return { r: r / 255, g: g / 255, b: b / 255 };
}

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
 * Random number generator
 */
function random(min: number, max: number): number {
  return Math.random() * (max - min) + min;
}

/**
 * Creates a single radial gradient layer
 *
 * @param width - Layer width
 * @param height - Layer height
 * @param centerX - Gradient center X (0-1)
 * @param centerY - Gradient center Y (0-1)
 * @param colors - Gradient color stops
 * @param opacity - Layer opacity
 * @param blur - Blur radius
 * @returns Figma EllipseNode with radial gradient
 */
function createRadialGradientLayer(
  width: number,
  height: number,
  centerX: number,
  centerY: number,
  colors: Array<{ position: number; color: RGB; opacity: number }>,
  opacity: number = 1,
  blur: number = 0
): EllipseNode {
  const ellipse = figma.createEllipse();
  ellipse.resize(width, height);
  ellipse.x = centerX * width - width / 2;
  ellipse.y = centerY * height - height / 2;
  ellipse.opacity = opacity;

  // Radial gradient fill
  ellipse.fills = [{
    type: 'GRADIENT_RADIAL',
    gradientTransform: [
      [1, 0, 0.5],
      [0, 1, 0.5]
    ],
    gradientStops: colors.map(c => ({
      position: c.position,
      color: { ...c.color, a: c.opacity }
    }))
  }];

  // Apply blur effect
  if (blur > 0) {
    ellipse.effects = [{
      type: 'LAYER_BLUR',
      radius: blur,
      visible: true
    }];
  }

  return ellipse;
}

/**
 * Creates a particle system with random placement
 *
 * @param width - Container width
 * @param height - Container height
 * @param count - Number of particles
 * @returns Figma FrameNode containing all particles
 */
export function createParticleSystem(
  width: number,
  height: number,
  count: number = GradientTokens.particles.count
): FrameNode {
  const particleFrame = figma.createFrame();
  particleFrame.name = 'Particles';
  particleFrame.resize(width, height);
  particleFrame.fills = [];  // Transparent
  particleFrame.clipsContent = false;

  for (let i = 0; i < count; i++) {
    const particle = figma.createEllipse();
    particle.name = `Particle ${i + 1}`;

    // Random size
    const size = random(
      GradientTokens.particles.minSize,
      GradientTokens.particles.maxSize
    );
    particle.resize(size, size);

    // Random position
    particle.x = random(0, width);
    particle.y = random(0, height);

    // Random opacity
    particle.opacity = random(
      GradientTokens.particles.minOpacity,
      GradientTokens.particles.maxOpacity
    );

    // White fill
    particle.fills = [{
      type: 'SOLID',
      color: rgb(255, 255, 255)
    }];

    particleFrame.appendChild(particle);
  }

  return particleFrame;
}

/**
 * Creates MAIL nebula background (4-layer radial gradients + particles)
 *
 * iOS: RichCardBackground.swift MAIL mode
 * - Deep space black base (90% opacity)
 * - 4 layered radial gradients (purple/blue nebula clouds)
 * - 40 animated glowing particles
 * - Heavy blur effects (60/50/40/30px)
 *
 * @param width - Background width
 * @param height - Background height
 * @returns Figma FrameNode with complete nebula effect
 */
export function createNebulaBackground(
  width: number,
  height: number
): FrameNode {
  const background = figma.createFrame();
  background.name = 'Nebula Background (MAIL)';
  background.resize(width, height);
  background.clipsContent = true;

  // Base: Deep space black
  background.fills = [{
    type: 'SOLID',
    color: rgb(10, 10, 15),  // Very dark blue-black
    opacity: 0.95
  }];

  // Layer 1: Deep purple nebula cloud (top-left)
  const layer1 = createRadialGradientLayer(
    width * 1.2,
    height * 1.2,
    0.3,
    0.4,
    [
      { position: 0, color: GradientTokens.mail.nebula.deepPurple, opacity: 0.8 },
      { position: 0.5, color: GradientTokens.mail.nebula.darkBlue, opacity: 0.4 },
      { position: 1, color: rgb(0, 0, 0), opacity: 0 }
    ],
    GradientTokens.mail.opacity[0],
    GradientTokens.mail.blur[0]
  );
  layer1.name = 'Nebula Cloud 1 (Deep Purple)';
  background.appendChild(layer1);

  // Layer 2: Dark blue nebula cloud (bottom-right)
  const layer2 = createRadialGradientLayer(
    width * 1.5,
    height * 1.5,
    0.7,
    0.6,
    [
      { position: 0, color: GradientTokens.mail.nebula.darkBlue, opacity: 0.6 },
      { position: 0.6, color: GradientTokens.mail.nebula.deepPurple, opacity: 0.3 },
      { position: 1, color: rgb(0, 0, 0), opacity: 0 }
    ],
    GradientTokens.mail.opacity[1],
    GradientTokens.mail.blur[1]
  );
  layer2.name = 'Nebula Cloud 2 (Dark Blue)';
  background.appendChild(layer2);

  // Layer 3: Bright purple accent (center-right)
  const layer3 = createRadialGradientLayer(
    width * 0.8,
    height * 0.8,
    0.6,
    0.5,
    [
      { position: 0, color: GradientTokens.mail.nebula.brightPurple, opacity: 0.7 },
      { position: 0.4, color: GradientTokens.mail.nebula.bluePurple, opacity: 0.4 },
      { position: 1, color: rgb(0, 0, 0), opacity: 0 }
    ],
    GradientTokens.mail.opacity[2],
    GradientTokens.mail.blur[2]
  );
  layer3.name = 'Nebula Cloud 3 (Bright Purple)';
  background.appendChild(layer3);

  // Layer 4: Blue-purple accent (bottom-left)
  const layer4 = createRadialGradientLayer(
    width * 0.9,
    height * 0.9,
    0.4,
    0.7,
    [
      { position: 0, color: GradientTokens.mail.nebula.bluePurple, opacity: 0.6 },
      { position: 0.5, color: GradientTokens.mail.nebula.brightPurple, opacity: 0.3 },
      { position: 1, color: rgb(0, 0, 0), opacity: 0 }
    ],
    GradientTokens.mail.opacity[3],
    GradientTokens.mail.blur[3]
  );
  layer4.name = 'Nebula Cloud 4 (Blue-Purple)';
  background.appendChild(layer4);

  // Particle system (40 glowing particles)
  const particles = createParticleSystem(width, height, 40);
  background.appendChild(particles);

  return background;
}

/**
 * Creates ADS scenic background (teal/green gradients)
 *
 * iOS: RichCardBackground.swift ADS mode
 * - Forest/mountain aesthetic
 * - Layered earth-tone gradients (teal → green)
 * - Static (non-animated)
 * - Moderate blur effects (40/30px)
 *
 * @param width - Background width
 * @param height - Background height
 * @returns Figma FrameNode with scenic gradient effect
 */
export function createScenicBackground(
  width: number,
  height: number
): FrameNode {
  const background = figma.createFrame();
  background.name = 'Scenic Background (ADS)';
  background.resize(width, height);
  background.clipsContent = true;

  // Base: Dark teal
  background.fills = [{
    type: 'SOLID',
    color: GradientTokens.ads.scenic.teal,
    opacity: 0.3
  }];

  // Layer 1: Teal gradient (top-left to bottom-right)
  const layer1 = figma.createRectangle();
  layer1.name = 'Scenic Layer 1 (Teal)';
  layer1.resize(width, height);
  layer1.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [
      [1, 0, 0],
      [0, 1, 0]
    ],
    gradientStops: [
      { position: 0, color: { ...GradientTokens.ads.scenic.teal, a: 0.7 } },
      { position: 0.5, color: { ...GradientTokens.ads.scenic.lightTeal, a: 0.5 } },
      { position: 1, color: { ...GradientTokens.ads.scenic.green, a: 0.3 } }
    ]
  }];
  layer1.effects = [{
    type: 'LAYER_BLUR',
    radius: GradientTokens.ads.blur[0],
    visible: true
  }];
  background.appendChild(layer1);

  // Layer 2: Green radial gradient (center accent)
  const layer2 = createRadialGradientLayer(
    width * 1.2,
    height * 1.2,
    0.5,
    0.5,
    [
      { position: 0, color: GradientTokens.ads.scenic.green, opacity: 0.6 },
      { position: 0.5, color: GradientTokens.ads.scenic.lightTeal, opacity: 0.4 },
      { position: 1, color: GradientTokens.ads.scenic.darkGreen, opacity: 0 }
    ],
    GradientTokens.ads.opacity[1],
    GradientTokens.ads.blur[1]
  );
  layer2.name = 'Scenic Layer 2 (Green Accent)';
  background.appendChild(layer2);

  return background;
}

/**
 * Creates a simple linear gradient background
 *
 * @param width - Background width
 * @param height - Background height
 * @param startColor - Gradient start color (hex)
 * @param endColor - Gradient end color (hex)
 * @param angle - Gradient angle in degrees (0 = left to right)
 * @returns Figma RectangleNode with linear gradient
 */
export function createLinearGradient(
  width: number,
  height: number,
  startColor: string,
  endColor: string,
  angle: number = 135
): RectangleNode {
  const rect = figma.createRectangle();
  rect.name = 'Linear Gradient';
  rect.resize(width, height);

  // Convert angle to radians and calculate transform
  const rad = (angle * Math.PI) / 180;
  const cos = Math.cos(rad);
  const sin = Math.sin(rad);

  rect.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [
      [cos, sin, 0.5 - cos * 0.5 - sin * 0.5],
      [-sin, cos, 0.5 + sin * 0.5 - cos * 0.5]
    ],
    gradientStops: [
      { position: 0, color: { ...hexToRgb(startColor), a: 1 } },
      { position: 1, color: { ...hexToRgb(endColor), a: 1 } }
    ]
  }];

  return rect;
}

/**
 * Creates a card background with mode-specific gradient
 *
 * @param mode - Card mode ('mail' or 'ads')
 * @returns Figma FrameNode with appropriate background
 */
export function createCardBackground(mode: 'mail' | 'ads'): FrameNode {
  const width = 358;  // iOS card width
  const height = 500; // iOS card height

  if (mode === 'mail') {
    return createNebulaBackground(width, height);
  } else {
    return createScenicBackground(width, height);
  }
}

/**
 * Creates a simple 2-color gradient overlay
 * Useful for button backgrounds
 *
 * @param width - Overlay width
 * @param height - Overlay height
 * @param colors - Array of color stops
 * @param cornerRadius - Corner radius
 * @returns Figma RectangleNode with gradient
 */
export function createGradientOverlay(
  width: number,
  height: number,
  colors: Array<{ position: number; color: string }>,
  cornerRadius: number = 0
): RectangleNode {
  const overlay = figma.createRectangle();
  overlay.name = 'Gradient Overlay';
  overlay.resize(width, height);
  overlay.cornerRadius = cornerRadius;

  overlay.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [
      [1, 0, 0],
      [0, 1, 0]
    ],
    gradientStops: colors.map(c => ({
      position: c.position,
      color: { ...hexToRgb(c.color), a: 1 }
    }))
  }];

  return overlay;
}

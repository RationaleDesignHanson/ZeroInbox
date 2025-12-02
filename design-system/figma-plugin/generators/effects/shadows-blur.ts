/**
 * Shadow and Blur Effect Utilities
 *
 * Creates shadow and blur effects matching iOS DesignTokens.swift
 *
 * iOS Source: /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Config/DesignTokens.swift
 *
 * Effect Types:
 * 1. Drop shadows (cards, modals, buttons)
 * 2. Inner shadows (depth, inset elements)
 * 3. Layer blur (backgrounds, overlays)
 * 4. Background blur (glassmorphic effects)
 */

/**
 * Design tokens for shadows and blur
 * From DesignTokens.swift:103-120
 */
export const ShadowBlurTokens = {
  shadows: {
    // Card shadow (floating cards)
    card: {
      color: { r: 0, g: 0, b: 0, a: 0.1 },
      offset: { x: 0, y: 4 },
      radius: 12,
      spread: 0
    },

    // Modal shadow (elevated modals)
    modal: {
      color: { r: 0, g: 0, b: 0, a: 0.25 },
      offset: { x: 0, y: 8 },
      radius: 24,
      spread: 0
    },

    // Button shadow (raised buttons)
    button: {
      color: { r: 0, g: 0, b: 0, a: 0.15 },
      offset: { x: 0, y: 2 },
      radius: 8,
      spread: 0
    },

    // Subtle shadow (minimal elevation)
    subtle: {
      color: { r: 0, g: 0, b: 0, a: 0.05 },
      offset: { x: 0, y: 1 },
      radius: 4,
      spread: 0
    },

    // Heavy shadow (maximum elevation)
    heavy: {
      color: { r: 0, g: 0, b: 0, a: 0.3 },
      offset: { x: 0, y: 12 },
      radius: 32,
      spread: -4
    }
  },

  blur: {
    // Standard blur (general use)
    standard: 20,

    // Heavy blur (cards, important backgrounds)
    heavy: 30,

    // Ultra blur (modals, overlays)
    ultra: 40,

    // Light blur (subtle effects)
    light: 10,

    // Minimal blur (very subtle)
    minimal: 5
  },

  innerShadow: {
    // Inset depth (pressed buttons, input fields)
    depth: {
      color: { r: 0, g: 0, b: 0, a: 0.15 },
      offset: { x: 0, y: 2 },
      radius: 4,
      spread: 0
    },

    // Subtle inset (minimal depth)
    subtle: {
      color: { r: 0, g: 0, b: 0, a: 0.08 },
      offset: { x: 0, y: 1 },
      radius: 2,
      spread: 0
    }
  }
};

/**
 * Applies card shadow to a node
 *
 * @param node - Target node (FrameNode, RectangleNode, etc.)
 */
export function applyCardShadow(node: SceneNode & EffectMixin): void {
  const shadow = ShadowBlurTokens.shadows.card;

  node.effects = [
    ...(node.effects || []),
    {
      type: 'DROP_SHADOW',
      color: shadow.color,
      offset: shadow.offset,
      radius: shadow.radius,
      spread: shadow.spread,
      visible: true,
      blendMode: 'NORMAL'
    }
  ];
}

/**
 * Applies modal shadow to a node
 *
 * @param node - Target node
 */
export function applyModalShadow(node: SceneNode & EffectMixin): void {
  const shadow = ShadowBlurTokens.shadows.modal;

  node.effects = [
    ...(node.effects || []),
    {
      type: 'DROP_SHADOW',
      color: shadow.color,
      offset: shadow.offset,
      radius: shadow.radius,
      spread: shadow.spread,
      visible: true,
      blendMode: 'NORMAL'
    }
  ];
}

/**
 * Applies button shadow to a node
 *
 * @param node - Target node
 */
export function applyButtonShadow(node: SceneNode & EffectMixin): void {
  const shadow = ShadowBlurTokens.shadows.button;

  node.effects = [
    ...(node.effects || []),
    {
      type: 'DROP_SHADOW',
      color: shadow.color,
      offset: shadow.offset,
      radius: shadow.radius,
      spread: shadow.spread,
      visible: true,
      blendMode: 'NORMAL'
    }
  ];
}

/**
 * Applies subtle shadow to a node
 *
 * @param node - Target node
 */
export function applySubtleShadow(node: SceneNode & EffectMixin): void {
  const shadow = ShadowBlurTokens.shadows.subtle;

  node.effects = [
    ...(node.effects || []),
    {
      type: 'DROP_SHADOW',
      color: shadow.color,
      offset: shadow.offset,
      radius: shadow.radius,
      spread: shadow.spread,
      visible: true,
      blendMode: 'NORMAL'
    }
  ];
}

/**
 * Applies heavy shadow to a node
 *
 * @param node - Target node
 */
export function applyHeavyShadow(node: SceneNode & EffectMixin): void {
  const shadow = ShadowBlurTokens.shadows.heavy;

  node.effects = [
    ...(node.effects || []),
    {
      type: 'DROP_SHADOW',
      color: shadow.color,
      offset: shadow.offset,
      radius: shadow.radius,
      spread: shadow.spread,
      visible: true,
      blendMode: 'NORMAL'
    }
  ];
}

/**
 * Applies custom drop shadow to a node
 *
 * @param node - Target node
 * @param color - Shadow color (RGBA)
 * @param offset - Shadow offset {x, y}
 * @param radius - Blur radius
 * @param spread - Shadow spread
 */
export function applyDropShadow(
  node: SceneNode & EffectMixin,
  color: RGBA,
  offset: { x: number; y: number },
  radius: number,
  spread: number = 0
): void {
  node.effects = [
    ...(node.effects || []),
    {
      type: 'DROP_SHADOW',
      color,
      offset,
      radius,
      spread,
      visible: true,
      blendMode: 'NORMAL'
    }
  ];
}

/**
 * Applies inner shadow (depth effect) to a node
 *
 * @param node - Target node
 */
export function applyInnerDepth(node: SceneNode & EffectMixin): void {
  const shadow = ShadowBlurTokens.innerShadow.depth;

  node.effects = [
    ...(node.effects || []),
    {
      type: 'INNER_SHADOW',
      color: shadow.color,
      offset: shadow.offset,
      radius: shadow.radius,
      spread: shadow.spread,
      visible: true,
      blendMode: 'NORMAL'
    }
  ];
}

/**
 * Applies subtle inner shadow to a node
 *
 * @param node - Target node
 */
export function applySubtleInnerShadow(node: SceneNode & EffectMixin): void {
  const shadow = ShadowBlurTokens.innerShadow.subtle;

  node.effects = [
    ...(node.effects || []),
    {
      type: 'INNER_SHADOW',
      color: shadow.color,
      offset: shadow.offset,
      radius: shadow.radius,
      spread: shadow.spread,
      visible: true,
      blendMode: 'NORMAL'
    }
  ];
}

/**
 * Applies layer blur to a node
 *
 * @param node - Target node
 * @param intensity - Blur intensity ('minimal', 'light', 'standard', 'heavy', 'ultra')
 */
export function applyLayerBlur(
  node: SceneNode & EffectMixin,
  intensity: 'minimal' | 'light' | 'standard' | 'heavy' | 'ultra' = 'standard'
): void {
  const radius = ShadowBlurTokens.blur[intensity];

  node.effects = [
    ...(node.effects || []),
    {
      type: 'LAYER_BLUR',
      radius,
      visible: true
    }
  ];
}

/**
 * Applies background blur to a node (glassmorphic effect)
 *
 * @param node - Target node
 * @param intensity - Blur intensity
 */
export function applyBackgroundBlur(
  node: SceneNode & EffectMixin,
  intensity: 'minimal' | 'light' | 'standard' | 'heavy' | 'ultra' = 'heavy'
): void {
  const radius = ShadowBlurTokens.blur[intensity];

  node.effects = [
    ...(node.effects || []),
    {
      type: 'BACKGROUND_BLUR',
      radius,
      visible: true
    }
  ];
}

/**
 * Clears all effects from a node
 *
 * @param node - Target node
 */
export function clearEffects(node: SceneNode & EffectMixin): void {
  node.effects = [];
}

/**
 * Creates a shadow configuration object
 * Useful for storing and reusing shadow configs
 *
 * @param color - Shadow color
 * @param x - X offset
 * @param y - Y offset
 * @param radius - Blur radius
 * @param spread - Shadow spread
 * @returns Shadow effect object
 */
export function createShadowConfig(
  color: RGBA,
  x: number,
  y: number,
  radius: number,
  spread: number = 0
): DropShadowEffect {
  return {
    type: 'DROP_SHADOW',
    color,
    offset: { x, y },
    radius,
    spread,
    visible: true,
    blendMode: 'NORMAL'
  };
}

/**
 * Creates a blur configuration object
 *
 * @param radius - Blur radius
 * @param type - Blur type ('LAYER_BLUR' or 'BACKGROUND_BLUR')
 * @returns Blur effect object
 */
export function createBlurConfig(
  radius: number,
  type: 'LAYER_BLUR' | 'BACKGROUND_BLUR' = 'LAYER_BLUR'
): BlurEffect {
  return {
    type,
    radius,
    visible: true
  };
}

/**
 * Applies multiple shadow layers (stacked shadows)
 * Useful for complex elevation effects
 *
 * @param node - Target node
 * @param shadows - Array of shadow configurations
 */
export function applyMultipleShadows(
  node: SceneNode & EffectMixin,
  shadows: Array<{
    color: RGBA;
    offset: { x: number; y: number };
    radius: number;
    spread?: number;
  }>
): void {
  const effects: DropShadowEffect[] = shadows.map(shadow => ({
    type: 'DROP_SHADOW',
    color: shadow.color,
    offset: shadow.offset,
    radius: shadow.radius,
    spread: shadow.spread || 0,
    visible: true,
    blendMode: 'NORMAL'
  }));

  node.effects = [...(node.effects || []), ...effects];
}

/**
 * Creates elevated card effect (shadow + subtle glow)
 *
 * @param node - Target node
 */
export function applyElevatedCardEffect(node: SceneNode & EffectMixin): void {
  applyMultipleShadows(node, [
    // Primary shadow
    {
      color: { r: 0, g: 0, b: 0, a: 0.1 },
      offset: { x: 0, y: 4 },
      radius: 12
    },
    // Ambient shadow (wider, softer)
    {
      color: { r: 0, g: 0, b: 0, a: 0.05 },
      offset: { x: 0, y: 8 },
      radius: 24
    }
  ]);
}

/**
 * Creates floating modal effect (heavy shadow + glow)
 *
 * @param node - Target node
 */
export function applyFloatingModalEffect(node: SceneNode & EffectMixin): void {
  applyMultipleShadows(node, [
    // Primary shadow
    {
      color: { r: 0, g: 0, b: 0, a: 0.25 },
      offset: { x: 0, y: 8 },
      radius: 24
    },
    // Ambient shadow (very wide, very soft)
    {
      color: { r: 0, g: 0, b: 0, a: 0.1 },
      offset: { x: 0, y: 16 },
      radius: 48
    },
    // Subtle glow (enhances glassmorphic effect)
    {
      color: { r: 1, g: 1, b: 1, a: 0.05 },
      offset: { x: 0, y: 0 },
      radius: 8
    }
  ]);
}

/**
 * Creates pressed button effect (inner shadow + reduced outer shadow)
 *
 * @param node - Target node
 */
export function applyPressedButtonEffect(node: SceneNode & EffectMixin): void {
  node.effects = [
    // Inner shadow (depth)
    {
      type: 'INNER_SHADOW',
      color: { r: 0, g: 0, b: 0, a: 0.2 },
      offset: { x: 0, y: 2 },
      radius: 4,
      spread: 0,
      visible: true,
      blendMode: 'NORMAL'
    },
    // Minimal outer shadow
    {
      type: 'DROP_SHADOW',
      color: { r: 0, g: 0, b: 0, a: 0.1 },
      offset: { x: 0, y: 1 },
      radius: 3,
      spread: 0,
      visible: true,
      blendMode: 'NORMAL'
    }
  ];
}

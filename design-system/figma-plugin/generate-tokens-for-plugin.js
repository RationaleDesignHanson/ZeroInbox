#!/usr/bin/env node

/**
 * Generate TypeScript tokens file for Figma plugin
 * Reads tokens.json and outputs tokens-for-plugin.ts
 * 
 * Run this before building the plugin:
 *   node generate-tokens-for-plugin.js
 */

const fs = require('fs');
const path = require('path');

const TOKENS_FILE = path.join(__dirname, '../tokens.json');
const OUTPUT_FILE = path.join(__dirname, 'tokens-for-plugin.ts');

// Helper to convert hex to RGB object
function hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (!result) return { r: 0, g: 0, b: 0 };
    return {
        r: parseInt(result[1], 16) / 255,
        g: parseInt(result[2], 16) / 255,
        b: parseInt(result[3], 16) / 255
    };
}

// Helper to resolve token references like {primitive.size.xl}
function resolveValue(value, tokens) {
    if (typeof value === 'string' && value.startsWith('{') && value.endsWith('}')) {
        const tokenPath = value.slice(1, -1).split('.');
        let result = tokens;
        for (const key of tokenPath) {
            result = result[key];
            if (result && result.$value !== undefined) {
                result = result.$value;
            }
        }
        return resolveValue(result, tokens);
    }
    return value;
}

// Parse pixel or ms values
function parsePixelValue(value) {
    if (typeof value === 'string') {
        if (value.endsWith('px')) {
            return parseInt(value);
        }
        if (value.endsWith('ms')) {
            return parseInt(value);
        }
    }
    return value;
}

function generateTokensFile() {
    console.log('Generating tokens-for-plugin.ts from tokens.json...\n');

    if (!fs.existsSync(TOKENS_FILE)) {
        console.error(`Error: ${TOKENS_FILE} not found`);
        process.exit(1);
    }

    const tokens = JSON.parse(fs.readFileSync(TOKENS_FILE, 'utf8'));

    // Extract values needed by the plugin
    const primitive = tokens.primitive || {};
    const colors = tokens.colors || {};
    const spacing = tokens.spacing || {};
    const radius = tokens.radius || {};
    const opacity = tokens.opacity || {};
    const components = tokens.components || {};
    const typography = tokens.typography || {};
    const animation = tokens.animation || {};

    // Build the output object structure
    const output = `/**
 * Design Tokens for Figma Plugin
 * Auto-generated from tokens.json
 * DO NOT EDIT MANUALLY - Run: node generate-tokens-for-plugin.js
 * Generated: ${new Date().toISOString()}
 */

// Helper types
interface RGB { r: number; g: number; b: number; }
interface RGBA extends RGB { a: number; }

/**
 * Design Tokens - Matches iOS DesignTokens.swift
 */
export const DesignTokens = {
    // Primitive values
    primitive: {
        size: {
${Object.entries(primitive.size || {})
    .filter(([k]) => !k.startsWith('$'))
    .map(([k, v]) => `            ${k}: ${parsePixelValue(v.$value)}`)
    .join(',\n')}
        },
        opacity: {
${Object.entries(primitive.opacity || {})
    .filter(([k]) => !k.startsWith('$'))
    .map(([k, v]) => `            ${k}: ${v.$value}`)
    .join(',\n')}
        },
        blur: {
${Object.entries(primitive.blur || {})
    .filter(([k]) => !k.startsWith('$'))
    .map(([k, v]) => `            ${k}: ${parsePixelValue(v.$value)}`)
    .join(',\n')}
        },
        duration: {
${Object.entries(primitive.duration || {})
    .filter(([k]) => !k.startsWith('$'))
    .map(([k, v]) => `            ${k}: ${parsePixelValue(v.$value)}`)
    .join(',\n')}
        }
    },

    // Spacing tokens
    spacing: {
${Object.entries(spacing)
    .filter(([k]) => !k.startsWith('$'))
    .map(([k, v]) => {
        const resolved = resolveValue(v.$value, tokens);
        return `        ${k}: ${parsePixelValue(resolved)}`;
    })
    .join(',\n')}
    },

    // Border radius tokens
    radius: {
${Object.entries(radius)
    .filter(([k]) => !k.startsWith('$'))
    .map(([k, v]) => {
        const resolved = resolveValue(v.$value, tokens);
        return `        ${k}: ${parsePixelValue(resolved)}`;
    })
    .join(',\n')}
    },

    // Opacity tokens
    opacity: {
${Object.entries(opacity)
    .filter(([k]) => !k.startsWith('$'))
    .map(([k, v]) => {
        const resolved = resolveValue(v.$value, tokens);
        return `        ${k}: ${resolved}`;
    })
    .join(',\n')}
    },

    // Color tokens
    colors: {
        gradients: {
${colors.gradients ? Object.entries(colors.gradients)
    .filter(([k]) => !k.startsWith('$'))
    .map(([archetype, gradient]) => {
        const start = hexToRgb(gradient.start?.$value || gradient.start);
        const end = hexToRgb(gradient.end?.$value || gradient.end);
        return `            ${archetype}: {
                start: { r: ${start.r.toFixed(3)}, g: ${start.g.toFixed(3)}, b: ${start.b.toFixed(3)} },
                end: { r: ${end.r.toFixed(3)}, g: ${end.g.toFixed(3)}, b: ${end.b.toFixed(3)} }
            }`;
    })
    .join(',\n') : ''}
        },
        semantic: {
${colors.semantic ? Object.entries(colors.semantic)
    .filter(([k]) => !k.startsWith('$'))
    .map(([state, values]) => {
        const primary = hexToRgb(values.primary?.$value || '#000000');
        return `            ${state}: { r: ${primary.r.toFixed(3)}, g: ${primary.g.toFixed(3)}, b: ${primary.b.toFixed(3)} }`;
    })
    .join(',\n') : ''}
        }
    },

    // Typography tokens
    typography: {
        fontSize: {
${typography.fontSize ? Object.entries(typography.fontSize)
    .filter(([k]) => !k.startsWith('$'))
    .map(([category, sizes]) => {
        if (typeof sizes === 'object' && !sizes.$value) {
            const sizeEntries = Object.entries(sizes)
                .filter(([k]) => !k.startsWith('$'))
                .map(([name, token]) => {
                    const size = parsePixelValue(token.$value);
                    const weight = token.fontWeight || 'regular';
                    const design = token.fontDesign || 'default';
                    return `                ${name}: { size: ${size}, weight: '${weight}', design: '${design}' }`;
                })
                .join(',\n');
            return `            ${category}: {\n${sizeEntries}\n            }`;
        }
        return '';
    })
    .filter(s => s)
    .join(',\n') : ''}
        }
    },

    // Animation tokens
    animation: {
        spring: {
${animation.spring ? Object.entries(animation.spring)
    .filter(([k]) => !k.startsWith('$'))
    .map(([name, preset]) => {
        if (preset.response && preset.dampingFraction) {
            const response = preset.response.$value !== undefined ? preset.response.$value : preset.response;
            const damping = preset.dampingFraction.$value !== undefined ? preset.dampingFraction.$value : preset.dampingFraction;
            return `            ${name}: { response: ${response}, dampingFraction: ${damping} }`;
        }
        return '';
    })
    .filter(s => s)
    .join(',\n') : ''}
        }
    },

    // Component tokens
    components: {
        card: {
            shadowRadius: ${parsePixelValue(components.card?.shadowRadius?.$value || 20)},
            shadowOpacity: ${components.card?.shadowOpacity?.$value ? resolveValue(components.card.shadowOpacity.$value, tokens) : 0.3}
        },
        button: {
            heightStandard: ${parsePixelValue(components.button?.heightStandard?.$value || 56)},
            heightCompact: ${parsePixelValue(components.button?.heightCompact?.$value || 44)},
            heightSmall: ${parsePixelValue(components.button?.heightSmall?.$value || 32)},
            iconSize: ${parsePixelValue(components.button?.iconSize?.$value || 20)}
        },
        modal: {
            shadowRadius: 24,
            shadowOpacity: 0.25
        }
    }
};

/**
 * Effect tokens for visual effects (glassmorphic, holographic, etc.)
 * These extend the base tokens with effect-specific values
 */
export const EffectTokens = {
    glassmorphic: {
        opacity: {
            ultraLight: DesignTokens.opacity.glassUltraLight,
            light: DesignTokens.opacity.glassLight,
            medium: DesignTokens.opacity.glassMedium
        },
        blur: {
            standard: DesignTokens.primitive.blur.standard,
            heavy: DesignTokens.primitive.blur.heavy,
            ultra: DesignTokens.primitive.blur.ultra
        }
    },
    shadows: {
        card: {
            color: { r: 0, g: 0, b: 0, a: 0.4 },
            offset: { x: 0, y: 10 },
            radius: DesignTokens.components.card.shadowRadius
        },
        modal: {
            color: { r: 0, g: 0, b: 0, a: 0.25 },
            offset: { x: 0, y: 8 },
            radius: 24
        },
        button: {
            color: { r: 0, g: 0, b: 0, a: 0.15 },
            offset: { x: 0, y: 5 },
            radius: 10
        }
    },
    gradients: {
        mail: {
            nebula: {
                deepPurple: { r: 0.2, g: 0.1, b: 0.4 },
                darkBlue: { r: 0.1, g: 0.15, b: 0.3 },
                brightPurple: { r: 0.4, g: 0.2, b: 0.6 },
                bluePurple: { r: 0.2, g: 0.3, b: 0.7 }
            },
            start: DesignTokens.colors.gradients.mail?.start || { r: 0.4, g: 0.49, b: 0.92 },
            end: DesignTokens.colors.gradients.mail?.end || { r: 0.46, g: 0.29, b: 0.64 },
            blur: [60, 50, 40, 30],
            opacity: [0.6, 0.3, 0.5, 0.3]
        },
        ads: {
            teal: DesignTokens.colors.gradients.ads?.start || { r: 0.086, g: 0.733, b: 0.667 },
            green: DesignTokens.colors.gradients.ads?.end || { r: 0.310, g: 0.820, b: 0.620 },
            lightTeal: { r: 0.2, g: 0.8, b: 0.75 }
        }
    },
    holographic: {
        mail: {
            colors: ['#00FFFF', '#0000FF', '#800080', '#FF00FF'],
            opacities: [0.4, 0.5, 0.4, 0.3],
            edgeGlow: { color: '#00FFFF', opacity: 0.5, blur: 8 }
        },
        ads: {
            colors: ['#16bbaa', '#4fd19e', '#16bbaa', '#4fd19e'],
            opacities: [0.7, 0.8, 0.6, 0.5],
            edgeGlow: { color: '#4fd19e', opacity: 0.6, blur: 8 }
        }
    }
};

export default DesignTokens;
`;

    fs.writeFileSync(OUTPUT_FILE, output);

    console.log(`Generated: ${OUTPUT_FILE}`);
    console.log('\nToken categories included:');
    console.log(`  - Primitive: size, opacity, blur, duration`);
    console.log(`  - Spacing: ${Object.keys(spacing).filter(k => !k.startsWith('$')).length} tokens`);
    console.log(`  - Radius: ${Object.keys(radius).filter(k => !k.startsWith('$')).length} tokens`);
    console.log(`  - Opacity: ${Object.keys(opacity).filter(k => !k.startsWith('$')).length} tokens`);
    console.log(`  - Colors: gradients, semantic`);
    console.log(`  - Typography: fontSize categories`);
    console.log(`  - Animation: spring presets`);
    console.log(`  - Components: card, button, modal`);
    console.log(`  - EffectTokens: glassmorphic, shadows, gradients, holographic`);
    console.log('\nRun this before building the Figma plugin.');
}

generateTokensFile();


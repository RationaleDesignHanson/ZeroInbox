/**
 * Design Tokens for Figma Plugin
 * Auto-generated from tokens.json
 * DO NOT EDIT MANUALLY - Run: node generate-tokens-for-plugin.js
 * Generated: 2025-12-18T23:15:52.262Z
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
            xxxs: 2,
            xxs: 4,
            xs: 6,
            sm: 8,
            md: 10,
            lg: 12,
            xl: 16,
            xxl: 20,
            xxxl: 24,
            xxxxl: 32,
            xxxxxl: 48
        },
        opacity: {
            none: 0,
            glass: 0.05,
            subtle: 0.1,
            light: 0.2,
            medium: 0.3,
            strong: 0.5,
            disabled: 0.6,
            secondary: 0.7,
            tertiary: 0.8,
            primary: 0.9,
            full: 1
        },
        blur: {
            subtle: 10,
            standard: 20,
            heavy: 30,
            ultra: 40
        },
        duration: {
            instant: 100,
            quick: 200,
            fast: 300,
            normal: 500,
            slow: 700,
            lazy: 1000
        }
    },

    // Spacing tokens
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

    // Border radius tokens
    radius: {
        card: 16,
        modal: 20,
        container: 16,
        button: 12,
        chip: 8,
        minimal: 4,
        circle: 999
    },

    // Opacity tokens
    opacity: {
        glassUltraLight: 0.05,
        glassLight: 0.1,
        glassMedium: 0.2,
        overlayLight: 0.2,
        overlayMedium: 0.3,
        overlayStrong: 0.5,
        textDisabled: 0.6,
        textSubtle: 0.7,
        textTertiary: 0.8,
        textSecondary: 0.9,
        textPrimary: 1
    },

    // Color tokens
    colors: {
        gradients: {
            mail: {
                start: { r: 0.400, g: 0.494, b: 0.918 },
                end: { r: 0.463, g: 0.294, b: 0.635 }
            },
            ads: {
                start: { r: 0.086, g: 0.733, b: 0.667 },
                end: { r: 0.310, g: 0.820, b: 0.620 }
            }
        },
        semantic: {
            error: { r: 1.000, g: 0.231, b: 0.188 },
            warning: { r: 1.000, g: 0.584, b: 0.000 },
            success: { r: 0.204, g: 0.780, b: 0.349 },
            info: { r: 0.000, g: 0.478, b: 1.000 }
        }
    },

    // Typography tokens
    typography: {
        fontSize: {
            display: {
                large: { size: 34, weight: 'bold', design: 'rounded' },
                medium: { size: 28, weight: 'bold', design: 'rounded' }
            },
            heading: {
                large: { size: 22, weight: 'bold', design: 'rounded' },
                medium: { size: 20, weight: 'semibold', design: 'rounded' },
                small: { size: 17, weight: 'semibold', design: 'default' }
            },
            body: {
                large: { size: 17, weight: 'regular', design: 'default' },
                medium: { size: 15, weight: 'regular', design: 'default' },
                small: { size: 14, weight: 'regular', design: 'default' }
            },
            label: {
                large: { size: 13, weight: 'semibold', design: 'default' },
                medium: { size: 12, weight: 'medium', design: 'default' },
                small: { size: 11, weight: 'regular', design: 'default' }
            },
            card: {
                title: { size: 20, weight: 'bold', design: 'rounded' },
                sender: { size: 16, weight: 'semibold', design: 'default' },
                summary: { size: 15, weight: 'regular', design: 'default' },
                sectionHeader: { size: 13, weight: 'bold', design: 'default' },
                timestamp: { size: 13, weight: 'medium', design: 'default' },
                metadata: { size: 12, weight: 'regular', design: 'default' }
            },
            thread: {
                title: { size: 15, weight: 'semibold', design: 'default' },
                summary: { size: 16, weight: 'regular', design: 'default' },
                messageSender: { size: 14, weight: 'semibold', design: 'default' },
                messageBody: { size: 14, weight: 'regular', design: 'default' }
            },
            reader: {
                subject: { size: 24, weight: 'bold', design: 'rounded' },
                sender: { size: 17, weight: 'semibold', design: 'default' },
                body: { size: 16, weight: 'regular', design: 'default' },
                quote: { size: 15, weight: 'regular', design: 'serif' },
                metadata: { size: 13, weight: 'medium', design: 'default' }
            },
            action: {
                primary: { size: 17, weight: 'semibold', design: 'rounded' },
                secondary: { size: 15, weight: 'medium', design: 'default' },
                tertiary: { size: 14, weight: 'medium', design: 'default' }
            },
            badge: {
                large: { size: 12, weight: 'bold', design: 'default' },
                small: { size: 10, weight: 'bold', design: 'default' }
            },
            aiAnalysis: {
                title: { size: 11, weight: 'bold', design: 'default' },
                sectionHeader: { size: 11, weight: 'semibold', design: 'default' },
                actionText: { size: 15, weight: 'regular', design: 'default' },
                contextText: { size: 14, weight: 'regular', design: 'default' },
                whyText: { size: 14, weight: 'regular', design: 'default' }
            }
        }
    },

    // Animation tokens
    animation: {
        spring: {
            snappy: { response: 0.25, dampingFraction: 0.7 },
            bouncy: { response: 0.4, dampingFraction: 0.6 },
            gentle: { response: 0.5, dampingFraction: 0.8 },
            heavy: { response: 0.6, dampingFraction: 0.75 }
        }
    },

    // Component tokens
    components: {
        card: {
            shadowRadius: 20,
            shadowOpacity: 0.3
        },
        button: {
            heightStandard: 56,
            heightCompact: 44,
            heightSmall: 32,
            iconSize: 20
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

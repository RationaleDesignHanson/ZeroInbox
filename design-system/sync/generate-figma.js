#!/usr/bin/env node

/**
 * Generate Figma Design System from iOS Source Code
 *
 * Reads DesignTokens.swift and ActionRegistry.swift to programmatically
 * create the entire design system in Figma via REST API.
 *
 * Usage: FIGMA_ACCESS_TOKEN=xxx node generate-figma.js
 */

const fs = require('fs');
const path = require('path');

// Configuration
const FIGMA_TOKEN = process.env.FIGMA_ACCESS_TOKEN || '';
const FILE_KEY = process.env.FIGMA_FILE_KEY || 'WuQicPi1wbHXqEcYCQcLfr';
const API_BASE = 'https://api.figma.com/v1';

// Paths to source files
const DESIGN_TOKENS_PATH = path.resolve(__dirname, '../../Zero_ios_2/Zero/Config/DesignTokens.swift');
const ACTION_REGISTRY_PATH = path.resolve(__dirname, '../../Zero_ios_2/Zero/Services/ActionRegistry.swift');

console.log('\n╔══════════════════════════════════════════════════╗');
console.log('║  Figma Design System Generator                  ║');
console.log('║  iOS Source → Figma Components                   ║');
console.log('╚══════════════════════════════════════════════════╝\n');

// ============================================================================
// STEP 1: PARSE iOS SOURCE CODE
// ============================================================================

/**
 * Parse DesignTokens.swift to extract all design tokens
 */
function parseDesignTokens() {
    console.log('📖 Step 1/4: Parsing DesignTokens.swift...');
    console.log('━'.repeat(50) + '\n');

    const content = fs.readFileSync(DESIGN_TOKENS_PATH, 'utf8');

    const tokens = {
        spacing: {},
        radius: {},
        opacity: {},
        colors: {},
        typography: {},
        button: {},
        card: {},
        modal: {},
        animation: {}
    };

    // Parse spacing tokens
    const spacingMatches = content.match(/enum Spacing \{[\s\S]*?static let (\w+): CGFloat = .*?\/\/ (\d+)/g);
    if (spacingMatches) {
        spacingMatches.forEach(match => {
            const nameMatch = match.match(/static let (\w+):/);
            const valueMatch = match.match(/\/\/ (\d+)/);
            if (nameMatch && valueMatch) {
                tokens.spacing[nameMatch[1]] = parseInt(valueMatch[1]);
            }
        });
    }

    // Parse radius tokens
    const radiusMatches = content.match(/enum Radius \{[\s\S]*?static let (\w+): CGFloat = .*?\/\/ (\d+)/g);
    if (radiusMatches) {
        radiusMatches.forEach(match => {
            const nameMatch = match.match(/static let (\w+):/);
            const valueMatch = match.match(/\/\/ (\d+)/);
            if (nameMatch && valueMatch) {
                tokens.radius[nameMatch[1]] = parseInt(valueMatch[1]);
            }
        });
    }

    // Parse opacity tokens
    const opacitySection = content.match(/enum Opacity \{[\s\S]*?static let (\w+): Double = .*?\/\/ ([\d.]+)/g);
    if (opacitySection) {
        opacitySection.forEach(match => {
            const nameMatch = match.match(/static let (\w+):/);
            const valueMatch = match.match(/\/\/ ([\d.]+)/);
            if (nameMatch && valueMatch) {
                tokens.opacity[nameMatch[1]] = parseFloat(valueMatch[1]);
            }
        });
    }

    // Parse gradient colors
    const mailStartMatch = content.match(/mailGradientStart.*?#(\w+)/);
    const mailEndMatch = content.match(/mailGradientEnd.*?#(\w+)/);
    const adsStartMatch = content.match(/adsGradientStart.*?#(\w+)/);
    const adsEndMatch = content.match(/adsGradientEnd.*?#(\w+)/);

    tokens.colors.gradients = {
        mail: {
            start: mailStartMatch ? `#${mailStartMatch[1]}` : '#667eea',
            end: mailEndMatch ? `#${mailEndMatch[1]}` : '#764ba2'
        },
        ads: {
            start: adsStartMatch ? `#${adsStartMatch[1]}` : '#16bbaa',
            end: adsEndMatch ? `#${adsEndMatch[1]}` : '#4fd19e'
        }
    };

    // Parse button tokens
    const buttonHeight = content.match(/heightStandard: CGFloat = (\d+)/);
    const buttonCompact = content.match(/heightCompact: CGFloat = (\d+)/);
    const buttonSmall = content.match(/heightSmall: CGFloat = (\d+)/);

    if (buttonHeight) tokens.button.heightStandard = parseInt(buttonHeight[1]);
    if (buttonCompact) tokens.button.heightCompact = parseInt(buttonCompact[1]);
    if (buttonSmall) tokens.button.heightSmall = parseInt(buttonSmall[1]);

    console.log('✅ Parsed design tokens:');
    console.log(`   - Spacing: ${Object.keys(tokens.spacing).length} tokens`);
    console.log(`   - Radius: ${Object.keys(tokens.radius).length} tokens`);
    console.log(`   - Opacity: ${Object.keys(tokens.opacity).length} tokens`);
    console.log(`   - Gradients: 2 (Mail, Ads)`);
    console.log(`   - Button sizes: ${Object.keys(tokens.button).length}\n`);

    return tokens;
}

/**
 * Parse ActionRegistry.swift to extract all actions
 */
function parseActionRegistry() {
    console.log('📖 Step 2/4: Parsing ActionRegistry.swift...');
    console.log('━'.repeat(50) + '\n');

    const content = fs.readFileSync(ACTION_REGISTRY_PATH, 'utf8');

    const actions = {
        goTo: [],
        inApp: []
    };

    // Extract all ActionConfig entries
    const configMatches = content.matchAll(/ActionConfig\(([\s\S]*?)\)/g);

    for (const match of configMatches) {
        const config = match[1];

        const actionIdMatch = config.match(/actionId: "([^"]+)"/);
        const displayNameMatch = config.match(/displayName: "([^"]+)"/);
        const actionTypeMatch = config.match(/actionType: \.(\w+)/);
        const modalMatch = config.match(/modalComponent: "([^"]+)"/);

        if (actionIdMatch && displayNameMatch && actionTypeMatch) {
            const action = {
                id: actionIdMatch[1],
                name: displayNameMatch[1],
                type: actionTypeMatch[1],
                modal: modalMatch ? modalMatch[1] : null
            };

            if (action.type === 'goTo') {
                actions.goTo.push(action);
            } else if (action.type === 'inApp') {
                actions.inApp.push(action);
            }
        }
    }

    console.log('✅ Parsed actions:');
    console.log(`   - GO_TO actions: ${actions.goTo.length}`);
    console.log(`   - IN_APP actions: ${actions.inApp.length}`);
    console.log(`   - Total: ${actions.goTo.length + actions.inApp.length}\n`);

    return actions;
}

// ============================================================================
// STEP 2: GENERATE FIGMA STRUCTURE
// ============================================================================

/**
 * Create Figma page structure
 */
function generatePageStructure(tokens, actions) {
    console.log('🎨 Step 3/4: Generating Figma structure...');
    console.log('━'.repeat(50) + '\n');

    const pages = [
        {
            name: '🎨 Design Tokens',
            children: [
                createTokensSection('Spacing', tokens.spacing),
                createTokensSection('Radius', tokens.radius),
                createTokensSection('Opacity', tokens.opacity),
                createGradientsSection(tokens.colors.gradients)
            ]
        },
        {
            name: '⚛️ Atomic Components',
            children: [
                createButtonsSection(tokens),
                createInputsSection(tokens),
                createBadgesSection(tokens),
                createProgressSection(tokens)
            ]
        },
        {
            name: '🧩 Molecule Components',
            children: [
                createModalHeaderSection(tokens),
                createModalFooterSection(tokens),
                createInfoCardSection(tokens),
                createActionCardSection(tokens)
            ]
        },
        {
            name: '🏗️ Modal Templates',
            children: [
                createGenericActionModal(tokens),
                createCommunicationModal(tokens),
                createViewContentModal(tokens),
                // Add other 9 modal templates...
            ]
        },
        {
            name: '↗️ GO_TO Visual Feedback',
            children: [
                createExternalIndicator(tokens),
                createActionCardStates(tokens),
                createLoadingSpinner(tokens)
            ]
        }
    ];

    console.log('✅ Generated structure:');
    console.log(`   - Pages: ${pages.length}`);
    console.log(`   - Components: ${pages.reduce((sum, p) => sum + p.children.length, 0)}\n`);

    return pages;
}

// ============================================================================
// COMPONENT GENERATORS
// ============================================================================

function createTokensSection(name, tokens) {
    return {
        type: 'FRAME',
        name: name,
        children: Object.entries(tokens).map(([key, value]) => ({
            type: 'TEXT',
            name: `${key}: ${value}`,
            characters: `${key}: ${value}`
        }))
    };
}

function createGradientsSection(gradients) {
    return {
        type: 'FRAME',
        name: 'Gradients',
        children: [
            {
                type: 'RECTANGLE',
                name: 'Mail Gradient',
                fills: [{
                    type: 'GRADIENT_LINEAR',
                    gradientStops: [
                        { position: 0, color: hexToRgba(gradients.mail.start) },
                        { position: 1, color: hexToRgba(gradients.mail.end) }
                    ]
                }],
                size: { width: 200, height: 100 }
            },
            {
                type: 'RECTANGLE',
                name: 'Ads Gradient',
                fills: [{
                    type: 'GRADIENT_LINEAR',
                    gradientStops: [
                        { position: 0, color: hexToRgba(gradients.ads.start) },
                        { position: 1, color: hexToRgba(gradients.ads.end) }
                    ]
                }],
                size: { width: 200, height: 100 }
            }
        ]
    };
}

function createButtonsSection(tokens) {
    const sizes = [
        { name: 'Standard', height: tokens.button.heightStandard || 56 },
        { name: 'Compact', height: tokens.button.heightCompact || 44 },
        { name: 'Small', height: tokens.button.heightSmall || 32 }
    ];

    return {
        type: 'FRAME',
        name: 'Gradient Buttons',
        children: sizes.map(size => ({
            type: 'RECTANGLE',
            name: `Button - ${size.name} (${size.height}px)`,
            size: { width: 200, height: size.height },
            cornerRadius: tokens.radius.button || 12,
            fills: [{
                type: 'GRADIENT_LINEAR',
                gradientStops: [
                    { position: 0, color: hexToRgba('#667eea') },
                    { position: 1, color: hexToRgba('#764ba2') }
                ]
            }]
        }))
    };
}

function createInputsSection(tokens) {
    const inputTypes = [
        'TextField', 'TextArea', 'DatePicker', 'TimePicker',
        'Dropdown', 'Checkbox', 'Radio', 'Toggle'
    ];

    return {
        type: 'FRAME',
        name: 'Input Components',
        children: inputTypes.map(type => ({
            type: 'RECTANGLE',
            name: type,
            size: { width: 300, height: 44 },
            cornerRadius: tokens.radius.button || 12,
            strokes: [{ color: { r: 1, g: 1, b: 1, a: 0.2 } }],
            strokeWeight: 1
        }))
    };
}

function createBadgesSection(tokens) {
    const priorities = [
        { name: 'Critical', value: 95, color: '#FF3B30' },
        { name: 'Very High', value: 90, color: '#FF9500' },
        { name: 'High', value: 85, color: '#FFCC00' },
        { name: 'Medium-High', value: 80, color: '#34C759' },
        { name: 'Medium', value: 75, color: '#667eea' },
        { name: 'Medium-Low', value: 70, color: '#5AC8FA' },
        { name: 'Low', value: 65, color: '#8E8E93' },
        { name: 'Very Low', value: 60, color: '#636366' }
    ];

    return {
        type: 'FRAME',
        name: 'Priority Badges',
        children: priorities.map(priority => ({
            type: 'RECTANGLE',
            name: `${priority.name} (${priority.value})`,
            size: { width: 40, height: 40 },
            cornerRadius: 999,
            fills: [{ color: hexToRgba(priority.color) }]
        }))
    };
}

function createProgressSection(tokens) {
    return {
        type: 'FRAME',
        name: 'Progress Indicators',
        children: [
            { type: 'RECTANGLE', name: 'Progress Bar', size: { width: 200, height: 4 } },
            { type: 'ELLIPSE', name: 'Progress Ring', size: { width: 40, height: 40 } },
            { type: 'TEXT', name: 'Progress Numeric', characters: '75%' },
            { type: 'ELLIPSE', name: 'Loading Spinner', size: { width: 20, height: 20 } }
        ]
    };
}

function createModalHeaderSection(tokens) {
    return {
        type: 'FRAME',
        name: 'Modal Header',
        size: { width: 375, height: 80 },
        children: [
            {
                type: 'TEXT',
                name: 'Title',
                characters: 'Modal Title',
                fontSize: 24
            },
            {
                type: 'ELLIPSE',
                name: 'Close Button',
                size: { width: 32, height: 32 }
            }
        ]
    };
}

function createModalFooterSection(tokens) {
    return {
        type: 'FRAME',
        name: 'Modal Footer',
        size: { width: 375, height: 80 },
        children: [
            {
                type: 'RECTANGLE',
                name: 'Primary Button',
                size: { width: 150, height: 56 },
                cornerRadius: tokens.radius.button || 12
            },
            {
                type: 'RECTANGLE',
                name: 'Secondary Button',
                size: { width: 150, height: 56 },
                cornerRadius: tokens.radius.button || 12
            }
        ]
    };
}

function createInfoCardSection(tokens) {
    return {
        type: 'FRAME',
        name: 'Info Card',
        size: { width: 343, height: 120 },
        cornerRadius: tokens.radius.card || 16,
        fills: [{ color: { r: 1, g: 1, b: 1, a: 0.05 } }]
    };
}

function createActionCardSection(tokens) {
    return {
        type: 'FRAME',
        name: 'Action Card',
        size: { width: 343, height: 80 },
        cornerRadius: tokens.radius.card || 16,
        fills: [{
            type: 'GRADIENT_LINEAR',
            gradientStops: [
                { position: 0, color: hexToRgba('#667eea') },
                { position: 1, color: hexToRgba('#764ba2') }
            ]
        }]
    };
}

function createGenericActionModal(tokens) {
    return {
        type: 'FRAME',
        name: 'GenericActionModal',
        size: { width: 375, height: 600 },
        cornerRadius: tokens.radius.modal || 20,
        children: [
            { type: 'TEXT', name: 'Header', characters: 'Add to Calendar' },
            { type: 'TEXT', name: 'Description', characters: 'Event details...' },
            { type: 'RECTANGLE', name: 'Date Input', size: { width: 343, height: 44 } },
            { type: 'RECTANGLE', name: 'Primary Button', size: { width: 343, height: 56 } }
        ]
    };
}

function createCommunicationModal(tokens) {
    return {
        type: 'FRAME',
        name: 'CommunicationModal',
        size: { width: 375, height: 500 },
        cornerRadius: tokens.radius.modal || 20,
        children: [
            { type: 'TEXT', name: 'Header', characters: 'Quick Reply' },
            { type: 'RECTANGLE', name: 'Message Input', size: { width: 343, height: 120 } },
            { type: 'RECTANGLE', name: 'Send Button', size: { width: 343, height: 56 } }
        ]
    };
}

function createViewContentModal(tokens) {
    return {
        type: 'FRAME',
        name: 'ViewContentModal',
        size: { width: 375, height: 600 },
        cornerRadius: tokens.radius.modal || 20,
        children: [
            { type: 'TEXT', name: 'Header', characters: 'Document Details' },
            { type: 'RECTANGLE', name: 'Content Area', size: { width: 343, height: 400 } },
            { type: 'RECTANGLE', name: 'Close Button', size: { width: 343, height: 56 } }
        ]
    };
}

function createExternalIndicator(tokens) {
    return {
        type: 'FRAME',
        name: 'External Indicator (↗)',
        size: { width: 16, height: 16 },
        children: [
            {
                type: 'TEXT',
                name: 'Arrow Icon',
                characters: '↗',
                fontSize: 16
            }
        ]
    };
}

function createActionCardStates(tokens) {
    return {
        type: 'FRAME',
        name: 'Action Card States',
        children: [
            { type: 'RECTANGLE', name: 'Idle', size: { width: 343, height: 80 }, opacity: 1.0 },
            { type: 'RECTANGLE', name: 'Pressed', size: { width: 343, height: 80 }, opacity: 0.8 },
            { type: 'RECTANGLE', name: 'Loading', size: { width: 343, height: 80 }, opacity: 1.0 }
        ]
    };
}

function createLoadingSpinner(tokens) {
    return {
        type: 'ELLIPSE',
        name: 'Loading Spinner',
        size: { width: 20, height: 20 },
        strokeWeight: 2,
        strokes: [{ color: { r: 0.4, g: 0.49, b: 0.92, a: 1 } }]
    };
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function hexToRgba(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16) / 255,
        g: parseInt(result[2], 16) / 255,
        b: parseInt(result[3], 16) / 255,
        a: 1
    } : { r: 1, g: 1, b: 1, a: 1 };
}

// ============================================================================
// STEP 3: SEND TO FIGMA API
// ============================================================================

async function sendToFigma(structure) {
    console.log('🚀 Step 4/4: Creating components in Figma...');
    console.log('━'.repeat(50) + '\n');

    console.log('⚠️  Note: Full Figma REST API creation requires plugin context');
    console.log('   This script generates the structure. Next step:');
    console.log('   Convert to Figma Plugin that runs inside Figma.\n');

    // For now, save the structure to a JSON file
    const outputPath = path.resolve(__dirname, 'figma-structure.json');
    fs.writeFileSync(outputPath, JSON.stringify(structure, null, 2));

    console.log('✅ Structure generated and saved to:');
    console.log(`   ${outputPath}\n`);

    return structure;
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================

async function main() {
    try {
        // Parse source code
        const tokens = parseDesignTokens();
        const actions = parseActionRegistry();

        // Generate Figma structure
        const structure = generatePageStructure(tokens, actions);

        // Send to Figma
        await sendToFigma(structure);

        console.log('╔══════════════════════════════════════════════════╗');
        console.log('║  ✅ Generation Complete!                         ║');
        console.log('╚══════════════════════════════════════════════════╝\n');

        console.log('📊 Summary:');
        console.log(`   - Design tokens: ${Object.keys(tokens.spacing).length + Object.keys(tokens.radius).length} parsed`);
        console.log(`   - Actions: ${actions.goTo.length + actions.inApp.length} analyzed`);
        console.log(`   - Pages: ${structure.length} generated`);
        console.log(`   - Components: ${structure.reduce((sum, p) => sum + p.children.length, 0)} created\n`);

        console.log('💡 Next Step: Convert to Figma Plugin');
        console.log('   The structure is ready. We need to run this inside');
        console.log('   Figma as a plugin to actually create the components.\n');

    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

// Run if called directly
if (require.main === module) {
    main();
}

module.exports = { parseDesignTokens, parseActionRegistry, generatePageStructure };

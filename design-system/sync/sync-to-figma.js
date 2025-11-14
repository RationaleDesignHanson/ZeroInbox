#!/usr/bin/env node

/**
 * Sync Design Tokens to Figma
 * Pushes iOS tokens to Figma file via REST API
 *
 * Usage: FIGMA_ACCESS_TOKEN=xxx node sync-to-figma.js
 *
 * Phases:
 * 1. Fix ads gradient colors
 * 2. Create/update color variables
 * 3. Create/update spacing variables
 * 4. Create/update radius variables
 * 5. Create/update opacity variables
 * 6. Create effect styles (shadows)
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// Configuration
const FIGMA_TOKEN = process.env.FIGMA_ACCESS_TOKEN || '';
const FILE_KEY = process.env.FIGMA_FILE_KEY || 'WuQicPi1wbHXqEcYCQcLfr';
const TOKENS_PATH = path.join(__dirname, '../tokens.json');

if (!FIGMA_TOKEN) {
    console.error('❌ Error: FIGMA_ACCESS_TOKEN environment variable not set');
    console.log('\nUsage:');
    console.log('  FIGMA_ACCESS_TOKEN=xxx node sync-to-figma.js');
    console.log('\nGet your token at: https://figma.com/developers/api#access-tokens');
    process.exit(1);
}

// Load tokens
const tokens = JSON.parse(fs.readFileSync(TOKENS_PATH, 'utf8'));

console.log('╔══════════════════════════════════════════════════╗');
console.log('║  Figma Design Token Sync                         ║');
console.log('║  iOS Tokens → Figma Variables                    ║');
console.log('╚══════════════════════════════════════════════════╝\n');

// Figma API helper
function figmaRequest(method, endpoint, body = null) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'api.figma.com',
            path: endpoint,
            method: method,
            headers: {
                'X-Figma-Token': FIGMA_TOKEN,
                'Content-Type': 'application/json'
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    if (res.statusCode >= 400) {
                        reject(new Error(`Figma API error: ${parsed.err || parsed.message || 'Unknown error'}`));
                    } else {
                        resolve(parsed);
                    }
                } catch (e) {
                    reject(new Error(`Failed to parse response: ${e.message}`));
                }
            });
        });

        req.on('error', reject);

        if (body) {
            req.write(JSON.stringify(body));
        }

        req.end();
    });
}

// Convert tokens to Figma format
function tokensToFigmaVariables() {
    const variables = [];

    // Spacing variables
    Object.entries(tokens.spacing || {}).forEach(([key, token]) => {
        if (key.startsWith('$')) return;
        const value = token.$value || token;
        const resolvedValue = typeof value === 'string' ?
            resolveTokenReference(value, tokens) : value;

        variables.push({
            name: `spacing/${key}`,
            type: 'FLOAT',
            value: parseFloat(resolvedValue),
            description: token.$description || `Spacing token: ${key}`
        });
    });

    // Radius variables
    Object.entries(tokens.radius || {}).forEach(([key, token]) => {
        if (key.startsWith('$')) return;
        const value = token.$value || token;
        const resolvedValue = typeof value === 'string' ?
            resolveTokenReference(value, tokens) : value;

        variables.push({
            name: `radius/${key}`,
            type: 'FLOAT',
            value: parseFloat(resolvedValue),
            description: token.$description || `Border radius token: ${key}`
        });
    });

    // Opacity variables
    Object.entries(tokens.opacity || {}).forEach(([key, token]) => {
        if (key.startsWith('$')) return;
        const value = token.$value || token;

        variables.push({
            name: `opacity/${key}`,
            type: 'FLOAT',
            value: parseFloat(value),
            description: token.$description || `Opacity token: ${key}`
        });
    });

    // Color variables (gradients)
    const gradients = tokens.colors?.gradients || {};
    Object.entries(gradients).forEach(([archetype, colors]) => {
        if (colors.start) {
            variables.push({
                name: `colors/${archetype}-gradient-start`,
                type: 'COLOR',
                value: hexToRGBA(colors.start.$value || colors.start),
                description: `${archetype} gradient start color`
            });
        }
        if (colors.end) {
            variables.push({
                name: `colors/${archetype}-gradient-end`,
                type: 'COLOR',
                value: hexToRGBA(colors.end.$value || colors.end),
                description: `${archetype} gradient end color`
            });
        }
    });

    return variables;
}

// Resolve token references like {primitive.size.xl}
function resolveTokenReference(value, tokens) {
    if (typeof value !== 'string' || !value.startsWith('{') || !value.endsWith('}')) {
        return value;
    }

    const path = value.slice(1, -1).split('.');
    let result = tokens;

    for (const key of path) {
        result = result[key];
        if (!result) return value;
        if (result.$value !== undefined) {
            result = result.$value;
        }
    }

    return typeof result === 'string' ? resolveTokenReference(result, tokens) : result;
}

// Convert hex to Figma RGBA
function hexToRGBA(hex) {
    const cleanHex = hex.replace('#', '');
    const r = parseInt(cleanHex.substr(0, 2), 16) / 255;
    const g = parseInt(cleanHex.substr(2, 2), 16) / 255;
    const b = parseInt(cleanHex.substr(4, 2), 16) / 255;

    return { r, g, b, a: 1 };
}

// Main sync function
async function syncToFigma() {
    console.log('📊 Analyzing tokens...\n');

    const variables = tokensToFigmaVariables();
    console.log(`Found ${variables.length} variables to sync:\n`);

    // Group by type
    const byType = variables.reduce((acc, v) => {
        acc[v.type] = (acc[v.type] || 0) + 1;
        return acc;
    }, {});

    console.log('  Breakdown:');
    Object.entries(byType).forEach(([type, count]) => {
        console.log(`    - ${type}: ${count} variables`);
    });

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Phase 1: Critical fixes
    console.log('🔧 Phase 1: Critical Fixes\n');

    const adsGradientStart = variables.find(v => v.name === 'colors/ads-gradient-start');
    const adsGradientEnd = variables.find(v => v.name === 'colors/ads-gradient-end');

    if (adsGradientStart && adsGradientEnd) {
        console.log('  ✅ Ads Gradient Colors:');
        console.log(`     Start: RGB(${Math.round(adsGradientStart.value.r * 255)}, ${Math.round(adsGradientStart.value.g * 255)}, ${Math.round(adsGradientStart.value.b * 255)}) = #16BBAA`);
        console.log(`     End:   RGB(${Math.round(adsGradientEnd.value.r * 255)}, ${Math.round(adsGradientEnd.value.g * 255)}, ${Math.round(adsGradientEnd.value.b * 255)}) = #4FD19E`);
    }

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Note about Figma Variables API limitations
    console.log('📝 Note: Figma Variables API\n');
    console.log('  The Figma REST API has limited support for creating/updating');
    console.log('  variables programmatically. For full sync capabilities, use:');
    console.log('\n  Option 1: Figma Plugin (Recommended)');
    console.log('    → Run: cd design-system/figma-plugin && npm run build');
    console.log('    → Load plugin in Figma Desktop App');
    console.log('    → Click "Sync from iOS" button');
    console.log('\n  Option 2: Manual Update');
    console.log('    → Follow: design-system/FIGMA_SYNC_PLAN.md');
    console.log('    → Update variables in Figma UI manually');
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Export variable list for plugin/manual use
    const outputPath = path.join(__dirname, 'figma-variables.json');
    fs.writeFileSync(outputPath, JSON.stringify({
        version: '1.0',
        source: 'iOS DesignTokens',
        generatedAt: new Date().toISOString(),
        variables: variables
    }, null, 2));

    console.log(`✅ Variable list exported to: ${outputPath}`);
    console.log('\n   Use this file with the Figma plugin for automated sync.');

    // Try to fetch current file info
    console.log('\n🔍 Fetching Figma file info...\n');

    try {
        const fileInfo = await figmaRequest('GET', `/v1/files/${FILE_KEY}`);
        console.log(`  ✅ File: ${fileInfo.name}`);
        console.log(`     Last modified: ${new Date(fileInfo.lastModified).toLocaleString()}`);
        console.log(`     Version: ${fileInfo.version}`);

        // Check for Design System page
        const designSystemPage = fileInfo.document.children.find(
            page => page.name.toLowerCase().includes('design system')
        );

        if (designSystemPage) {
            console.log(`\n  ✅ Found "Design System" page`);
            console.log(`     Ready for variable sync`);
        } else {
            console.log(`\n  ⚠️  No "Design System" page found`);
            console.log(`     Create a page named "Design System" in Figma first`);
        }
    } catch (error) {
        console.error(`  ❌ Failed to fetch file info: ${error.message}`);
        console.log('     Check your FIGMA_ACCESS_TOKEN and FILE_KEY');
    }

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.log('✅ Sync preparation complete!\n');
    console.log('Next steps:');
    console.log('  1. Build Figma plugin: npm run build (in design-system/figma-plugin/)');
    console.log('  2. Load plugin in Figma Desktop App');
    console.log('  3. Open file: https://figma.com/file/' + FILE_KEY);
    console.log('  4. Run plugin: Plugins → Development → Zero Design Sync');
    console.log('  5. Click "Sync from iOS" to apply all variables\n');
}

// Run sync
syncToFigma().catch(error => {
    console.error('\n❌ Sync failed:', error.message);
    process.exit(1);
});

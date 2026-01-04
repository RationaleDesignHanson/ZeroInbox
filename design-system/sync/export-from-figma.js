#!/usr/bin/env node

/**
 * Export Design Tokens from Figma Variables
 * Fetches Figma Variables and transforms them into tokens.json format
 *
 * Usage: FIGMA_ACCESS_TOKEN=xxx node export-from-figma.js
 * Output: ../tokens.json (merges with existing structure)
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const FIGMA_TOKEN = process.env.FIGMA_ACCESS_TOKEN || '';
const FILE_KEY = process.env.FIGMA_FILE_KEY || 'WuQicPi1wbHXqEcYCQcLfr';
const TOKENS_FILE = path.join(__dirname, '../tokens.json');
const BACKUP_FILE = path.join(__dirname, '../tokens.backup.json');

if (!FIGMA_TOKEN) {
    console.error('Error: FIGMA_ACCESS_TOKEN environment variable not set');
    console.log('\nUsage:');
    console.log('  FIGMA_ACCESS_TOKEN=xxx node export-from-figma.js');
    console.log('\nGet your token at: https://figma.com/developers/api#access-tokens');
    process.exit(1);
}

// Figma API helper
function figmaRequest(endpoint) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'api.figma.com',
            path: endpoint,
            method: 'GET',
            headers: {
                'X-Figma-Token': FIGMA_TOKEN,
                'Content-Type': 'application/json'
            }
        };

        https.get(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    if (res.statusCode >= 400) {
                        reject(new Error(`Figma API error: ${parsed.err || parsed.message || res.statusCode}`));
                    } else {
                        resolve(parsed);
                    }
                } catch (e) {
                    reject(new Error(`Failed to parse response: ${e.message}`));
                }
            });
        }).on('error', reject);
    });
}

// Convert Figma RGB color to hex
function rgbToHex(r, g, b) {
    const toHex = (n) => {
        const hex = Math.round(n * 255).toString(16);
        return hex.length === 1 ? '0' + hex : hex;
    };
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

// Extract variables from Figma
async function extractFigmaVariables() {
    console.log('Fetching Figma Variables...\n');
    
    try {
        // Get local variables
        const variablesResponse = await figmaRequest(`/v1/files/${FILE_KEY}/variables/local`);
        
        if (variablesResponse.error) {
            throw new Error(variablesResponse.error);
        }

        const { meta } = variablesResponse;
        const variables = meta?.variables || {};
        const collections = meta?.variableCollections || {};

        console.log(`Found ${Object.keys(variables).length} variables in ${Object.keys(collections).length} collections\n`);

        // Organize variables by collection and type
        const organized = {
            colors: {},
            spacing: {},
            radius: {},
            opacity: {},
            typography: {},
            animation: {}
        };

        // Process each variable
        for (const [id, variable] of Object.entries(variables)) {
            const name = variable.name;
            const resolvedType = variable.resolvedType;
            const values = variable.valuesByMode;

            // Get value from first mode (usually light/default)
            const modeId = Object.keys(values)[0];
            const value = values[modeId];

            // Parse variable path (e.g., "spacing/card" -> category: spacing, name: card)
            const parts = name.split('/');
            const category = parts[0].toLowerCase();
            const tokenName = parts.slice(1).join('/') || parts[0];

            // Route to appropriate category
            if (resolvedType === 'COLOR' && value.r !== undefined) {
                const hex = rgbToHex(value.r, value.g, value.b);
                setNestedValue(organized.colors, tokenName, {
                    '$value': hex,
                    opacity: value.a !== 1 ? value.a : undefined
                });
            } else if (resolvedType === 'FLOAT') {
                if (category === 'spacing' || name.includes('spacing')) {
                    setNestedValue(organized.spacing, tokenName, {
                        '$value': `${value}px`
                    });
                } else if (category === 'radius' || name.includes('radius')) {
                    setNestedValue(organized.radius, tokenName, {
                        '$value': `${value}px`
                    });
                } else if (category === 'opacity' || name.includes('opacity')) {
                    setNestedValue(organized.opacity, tokenName, {
                        '$value': value
                    });
                } else if (category === 'animation' || name.includes('duration')) {
                    setNestedValue(organized.animation, tokenName, {
                        '$value': `${value}ms`
                    });
                }
            } else if (resolvedType === 'STRING') {
                // Typography font families, etc.
                if (category === 'typography' || name.includes('font')) {
                    setNestedValue(organized.typography, tokenName, {
                        '$value': value
                    });
                }
            }
        }

        return organized;

    } catch (error) {
        if (error.message.includes('403') || error.message.includes('Forbidden')) {
            console.log('Note: Figma Variables API requires a paid Figma plan.');
            console.log('Falling back to file-based extraction...\n');
            return await extractFromFigmaFile();
        }
        throw error;
    }
}

// Helper to set nested values in an object
function setNestedValue(obj, path, value) {
    const parts = path.split('/');
    let current = obj;
    
    for (let i = 0; i < parts.length - 1; i++) {
        const key = parts[i];
        if (!current[key]) {
            current[key] = {};
        }
        current = current[key];
    }
    
    current[parts[parts.length - 1]] = value;
}

// Fallback: Extract from Figma file structure (original method)
async function extractFromFigmaFile() {
    console.log('Using file-based extraction...\n');
    
    const fileData = await figmaRequest(`/v1/files/${FILE_KEY}`);
    
    if (fileData.error || !fileData.document) {
        throw new Error(fileData.error || 'Invalid Figma data');
    }

    const designSystemPage = fileData.document.children.find(
        page => page.name.toLowerCase().includes('design system')
    );

    if (!designSystemPage) {
        throw new Error('No "Design System" page found in Figma file');
    }

    console.log('Found Design System page\n');

    // Extract tokens from visual elements
    const extracted = {
        colors: extractColorsFromNodes(designSystemPage),
        spacing: extractSpacingFromNodes(designSystemPage),
        radius: extractRadiusFromNodes(designSystemPage),
        typography: extractTypographyFromNodes(designSystemPage),
        opacity: extractOpacityFromNodes(designSystemPage),
        gradients: extractGradientsFromNodes(designSystemPage)
    };

    return extracted;
}

// Node-based extraction functions (fallback)
function extractColorsFromNodes(node, colors = {}, section = null) {
    if (node.name === 'Color Palette' || node.name.includes('Colors')) {
        section = 'base';
    }
    
    if (node.type === 'FRAME' && node.fills && node.fills[0]?.type === 'SOLID') {
        const name = node.name.toLowerCase().replace(/\s+/g, '-');
        if (!['frame', 'container'].includes(name)) {
            const color = node.fills[0].color;
            const hex = rgbToHex(color.r, color.g, color.b);
            if (!colors[section || 'other']) colors[section || 'other'] = {};
            colors[section || 'other'][name] = { '$value': hex };
        }
    }
    
    if (node.children) {
        node.children.forEach(child => extractColorsFromNodes(child, colors, section));
    }
    
    return colors;
}

function extractSpacingFromNodes(node, spacing = {}) {
    if (node.name.includes('Spacing')) {
        if (node.children) {
            node.children.forEach(child => {
                if (child.type === 'TEXT' && child.characters.match(/\d+/)) {
                    const match = child.characters.match(/(\w+):\s*(\d+)/);
                    if (match) {
                        spacing[match[1]] = { '$value': `${match[2]}px` };
                    }
                }
            });
        }
    }
    
    if (node.children) {
        node.children.forEach(child => extractSpacingFromNodes(child, spacing));
    }
    
    return spacing;
}

function extractRadiusFromNodes(node, radius = {}) {
    if (node.name.includes('Radius') || node.name.includes('Corner')) {
        if (node.children) {
            node.children.forEach(child => {
                if (child.type === 'TEXT') {
                    const match = child.characters.match(/(\w+):\s*(\d+)/);
                    if (match) {
                        radius[match[1]] = { '$value': `${match[2]}px` };
                    }
                }
            });
        }
    }
    
    if (node.children) {
        node.children.forEach(child => extractRadiusFromNodes(child, radius));
    }
    
    return radius;
}

function extractTypographyFromNodes(node, typography = {}) {
    if (node.name.includes('Typography')) {
        if (node.children) {
            node.children.forEach(child => {
                if (child.type === 'TEXT') {
                    const style = child.style;
                    if (style && style.fontSize) {
                        const name = child.name.toLowerCase().replace(/\s+/g, '-');
                        typography[name] = {
                            '$value': `${style.fontSize}px`,
                            fontWeight: style.fontWeight,
                            fontFamily: style.fontFamily
                        };
                    }
                }
            });
        }
    }
    
    if (node.children) {
        node.children.forEach(child => extractTypographyFromNodes(child, typography));
    }
    
    return typography;
}

function extractOpacityFromNodes(node, opacity = {}) {
    if (node.name.includes('Opacity')) {
        if (node.children) {
            node.children.forEach(child => {
                if (child.type === 'TEXT') {
                    const match = child.characters.match(/(\w+):\s*([\d.]+)/);
                    if (match) {
                        opacity[match[1]] = { '$value': parseFloat(match[2]) };
                    }
                }
            });
        }
    }
    
    if (node.children) {
        node.children.forEach(child => extractOpacityFromNodes(child, opacity));
    }
    
    return opacity;
}

function extractGradientsFromNodes(node, gradients = {}) {
    if (node.name.includes('Gradient') || node.name.includes('Archetype')) {
        if (node.fills && node.fills[0]?.type === 'GRADIENT_LINEAR') {
            const gradient = node.fills[0];
            const stops = gradient.gradientStops || [];
            if (stops.length >= 2) {
                const name = node.name.toLowerCase().replace(/\s+/g, '-');
                gradients[name] = {
                    start: { '$value': rgbToHex(stops[0].color.r, stops[0].color.g, stops[0].color.b) },
                    end: { '$value': rgbToHex(stops[stops.length-1].color.r, stops[stops.length-1].color.g, stops[stops.length-1].color.b) }
                };
            }
        }
    }
    
    if (node.children) {
        node.children.forEach(child => extractGradientsFromNodes(child, gradients));
    }
    
    return gradients;
}

// Merge extracted tokens with existing tokens.json structure
function mergeWithExisting(extracted, existing) {
    const merged = JSON.parse(JSON.stringify(existing)); // Deep clone
    
    // Update colors.gradients if extracted
    if (extracted.gradients && Object.keys(extracted.gradients).length > 0) {
        if (!merged.colors) merged.colors = {};
        if (!merged.colors.gradients) merged.colors.gradients = {};
        
        for (const [key, value] of Object.entries(extracted.gradients)) {
            merged.colors.gradients[key] = value;
        }
    }
    
    // Update spacing tokens
    if (extracted.spacing && Object.keys(extracted.spacing).length > 0) {
        for (const [key, value] of Object.entries(extracted.spacing)) {
            if (merged.spacing && merged.spacing[key]) {
                merged.spacing[key].$value = value.$value;
            }
        }
    }
    
    // Update radius tokens
    if (extracted.radius && Object.keys(extracted.radius).length > 0) {
        for (const [key, value] of Object.entries(extracted.radius)) {
            if (merged.radius && merged.radius[key]) {
                merged.radius[key].$value = value.$value;
            }
        }
    }
    
    // Update meta
    merged.meta = {
        ...merged.meta,
        lastSyncedFromFigma: new Date().toISOString(),
        figmaFileKey: FILE_KEY
    };
    
    return merged;
}

// Main export function
async function exportTokens() {
    console.log('========================================');
    console.log('  Figma Design Token Export');
    console.log('  Figma Variables -> tokens.json');
    console.log('========================================\n');

    try {
        // Backup existing tokens.json
        if (fs.existsSync(TOKENS_FILE)) {
            const existing = fs.readFileSync(TOKENS_FILE, 'utf8');
            fs.writeFileSync(BACKUP_FILE, existing);
            console.log('Backed up existing tokens.json\n');
        }

        // Extract from Figma
        const extracted = await extractFigmaVariables();
        
        // Load existing tokens
        let existingTokens = {};
        if (fs.existsSync(TOKENS_FILE)) {
            existingTokens = JSON.parse(fs.readFileSync(TOKENS_FILE, 'utf8'));
        }

        // Merge extracted with existing
        const merged = mergeWithExisting(extracted, existingTokens);

        // Write to tokens.json
        fs.writeFileSync(TOKENS_FILE, JSON.stringify(merged, null, 2));

        console.log('========================================');
        console.log('  Export Summary');
        console.log('========================================');
        console.log(`Colors extracted: ${Object.keys(extracted.colors || {}).length} groups`);
        console.log(`Spacing extracted: ${Object.keys(extracted.spacing || {}).length} tokens`);
        console.log(`Radius extracted: ${Object.keys(extracted.radius || {}).length} tokens`);
        console.log(`Typography extracted: ${Object.keys(extracted.typography || {}).length} styles`);
        console.log(`Opacity extracted: ${Object.keys(extracted.opacity || {}).length} tokens`);
        console.log(`\nTokens written to: ${TOKENS_FILE}`);
        console.log(`Backup saved to: ${BACKUP_FILE}\n`);

        return merged;

    } catch (error) {
        console.error('\nError exporting tokens:', error.message);
        
        // Restore backup if export failed
        if (fs.existsSync(BACKUP_FILE)) {
            console.log('Restoring backup...');
            fs.copyFileSync(BACKUP_FILE, TOKENS_FILE);
        }
        
        process.exit(1);
    }
}

// Run if called directly
if (require.main === module) {
    exportTokens();
}

module.exports = { exportTokens };

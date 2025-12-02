"use strict";
/**
 * Zero Design System - Component Generator Plugin
 *
 * Automatically generates the 5 core components with variants and Variable bindings
 * Components: ZeroButton, ZeroCard, ZeroModal, ZeroListItem, ZeroAlert
 *
 * Phase 0 Day 2: Automates Figma component creation
 */
// MARK: - Helper Functions
/**
 * Find or create a Figma Variable by name
 */
function findVariable(name) {
    const localVariables = figma.variables.getLocalVariables();
    return localVariables.find(v => v.name === name) || null;
}
/**
 * Bind a numeric property to a Variable
 */
function bindNumberVariable(node, property, variableName) {
    const variable = findVariable(variableName);
    if (!variable) {
        console.warn(`Variable not found: ${variableName}`);
        return;
    }
    // Figma API for variable binding
    // @ts-ignore - Figma API types may not be fully up to date
    if (node.boundVariables) {
        // @ts-ignore
        node.boundVariables[property] = {
            type: 'VARIABLE_ALIAS',
            id: variable.id
        };
    }
}
/**
 * Create text node with styling
 * Uses system default font to avoid font loading issues
 */
async function createText(content, fontSize, weight = 'Regular') {
    const text = figma.createText();
    // Use default font (no loading required)
    await figma.loadFontAsync({ family: 'Inter', style: weight });
    text.fontName = { family: 'Inter', style: weight };
    text.characters = content;
    text.fontSize = fontSize;
    return text;
}
/**
 * Create frame with Auto Layout
 */
function createAutoLayoutFrame(name, direction, padding, gap) {
    const frame = figma.createFrame();
    frame.name = name;
    frame.layoutMode = direction;
    frame.paddingLeft = padding;
    frame.paddingRight = padding;
    frame.paddingTop = padding;
    frame.paddingBottom = padding;
    frame.itemSpacing = gap;
    frame.counterAxisSizingMode = 'AUTO';
    frame.primaryAxisSizingMode = 'AUTO';
    return frame;
}
// MARK: - Component Generators
/**
 * Generate ZeroButton component
 * Variants: 4 styles × 3 sizes × 4 states
 */
async function generateZeroButton() {
    console.log('Generating ZeroButton...');
    // Create base frame
    const button = figma.createComponent();
    button.name = 'ZeroButton';
    button.layoutMode = 'HORIZONTAL';
    button.paddingLeft = 16;
    button.paddingRight = 16;
    button.primaryAxisSizingMode = 'AUTO';
    button.counterAxisSizingMode = 'FIXED';
    button.counterAxisAlignItems = 'CENTER';
    button.itemSpacing = 8;
    button.cornerRadius = 12; // Will bind to radius/button variable
    // Add text label
    await figma.loadFontAsync({ family: 'Inter', style: 'Medium' });
    const label = figma.createText();
    label.name = 'Label';
    label.characters = 'Button Text';
    label.fontSize = 15;
    label.fontName = { family: 'Inter', style: 'Medium' };
    label.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    button.appendChild(label);
    // Add icon (optional, hidden by default)
    const icon = figma.createRectangle();
    icon.name = 'Icon';
    icon.resize(20, 20);
    icon.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    icon.visible = false;
    button.insertChild(0, icon);
    // Background
    button.fills = [{ type: 'SOLID', color: { r: 0.23, g: 0.51, b: 0.96 } }]; // Blue
    // Try to bind corner radius to variable
    bindNumberVariable(button, 'cornerRadius', 'radius/button');
    // Add component properties
    button.addComponentProperty('Style', 'VARIANT', 'Primary');
    button.addComponentProperty('Size', 'VARIANT', 'Large');
    button.addComponentProperty('State', 'VARIANT', 'Default');
    button.addComponentProperty('HasIcon', 'BOOLEAN', false);
    // Create variants
    const variants = [
        // Primary Large
        { style: 'Primary', size: 'Large', state: 'Default', bg: { r: 0.23, g: 0.51, b: 0.96 }, height: 56 },
        { style: 'Primary', size: 'Large', state: 'Hover', bg: { r: 0.28, g: 0.56, b: 1 }, height: 56 },
        { style: 'Primary', size: 'Large', state: 'Pressed', bg: { r: 0.18, g: 0.46, b: 0.86 }, height: 56 },
        { style: 'Primary', size: 'Large', state: 'Disabled', bg: { r: 0.23, g: 0.51, b: 0.96 }, height: 56, opacity: 0.6 },
        // Secondary Large
        { style: 'Secondary', size: 'Large', state: 'Default', bg: { r: 1, g: 1, b: 1, a: 0.1 }, height: 56 },
        // Destructive Large
        { style: 'Destructive', size: 'Large', state: 'Default', bg: { r: 0.94, g: 0.23, b: 0.19 }, height: 56 },
        // Text Large
        { style: 'Text', size: 'Large', state: 'Default', bg: { r: 0, g: 0, b: 0, a: 0 }, height: 56 },
        // Medium sizes
        { style: 'Primary', size: 'Medium', state: 'Default', bg: { r: 0.23, g: 0.51, b: 0.96 }, height: 44, fontSize: 14 },
        // Small sizes
        { style: 'Primary', size: 'Small', state: 'Default', bg: { r: 0.23, g: 0.51, b: 0.96 }, height: 32, fontSize: 13 },
    ];
    // TODO: Create actual variants using Figma's variant system
    // This requires creating a component set and instances
    return button;
}
/**
 * Generate ZeroCard component
 * Variants: Default, Focused, Expanded
 */
async function generateZeroCard() {
    console.log('Generating ZeroCard...');
    const card = figma.createComponent();
    card.name = 'ZeroCard';
    card.layoutMode = 'VERTICAL';
    card.paddingLeft = 24;
    card.paddingRight = 24;
    card.paddingTop = 24;
    card.paddingBottom = 24;
    card.itemSpacing = 12;
    card.primaryAxisSizingMode = 'AUTO';
    card.counterAxisSizingMode = 'FIXED';
    card.resize(358, 200);
    card.cornerRadius = 16;
    // Background
    card.fills = [{
            type: 'SOLID',
            color: { r: 1, g: 1, b: 1 },
            opacity: 0.1
        }];
    // Try to bind variables
    bindNumberVariable(card, 'cornerRadius', 'radius/card');
    bindNumberVariable(card, 'paddingLeft', 'spacing/card');
    // Header section
    const header = createAutoLayoutFrame('Header', 'HORIZONTAL', 0, 8);
    header.layoutAlign = 'STRETCH';
    await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
    const title = figma.createText();
    title.name = 'Title';
    title.characters = 'Email Title';
    title.fontSize = 17;
    title.fontName = { family: 'Inter', style: 'Semi Bold' };
    title.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    title.layoutGrow = 1;
    header.appendChild(title);
    await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
    const timestamp = figma.createText();
    timestamp.name = 'Timestamp';
    timestamp.characters = '2m ago';
    timestamp.fontSize = 13;
    timestamp.fontName = { family: 'Inter', style: 'Regular' };
    timestamp.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0.7 }];
    header.appendChild(timestamp);
    card.appendChild(header);
    // Summary
    await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
    const summary = figma.createText();
    summary.name = 'Summary';
    summary.characters = 'Email summary text goes here. This is a preview of the email content.';
    summary.fontSize = 15;
    summary.fontName = { family: 'Inter', style: 'Regular' };
    summary.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0.9 }];
    summary.layoutAlign = 'STRETCH';
    card.appendChild(summary);
    // Add component properties
    card.addComponentProperty('State', 'VARIANT', 'Default');
    card.addComponentProperty('ShowPriority', 'BOOLEAN', false);
    return card;
}
/**
 * Generate ZeroModal component
 * Variants: Standard, Action Picker, Confirmation
 */
async function generateZeroModal() {
    console.log('Generating ZeroModal...');
    // Create backdrop frame
    const backdrop = figma.createFrame();
    backdrop.name = 'ZeroModal + Backdrop';
    backdrop.resize(390, 844); // iPhone 14 screen size
    backdrop.fills = [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 }, opacity: 0.5 }];
    // Create modal component
    const modal = figma.createComponent();
    modal.name = 'ZeroModal';
    modal.layoutMode = 'VERTICAL';
    modal.paddingLeft = 24;
    modal.paddingRight = 24;
    modal.paddingTop = 24;
    modal.paddingBottom = 24;
    modal.itemSpacing = 16;
    modal.primaryAxisSizingMode = 'AUTO';
    modal.counterAxisSizingMode = 'FIXED';
    modal.resize(335, 400);
    modal.cornerRadius = 20;
    // Glassmorphism background
    modal.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0.15 }];
    // TODO: Add background blur effect manually in Figma (20px blur)
    // Try to bind variables
    bindNumberVariable(modal, 'cornerRadius', 'radius/modal');
    bindNumberVariable(modal, 'paddingLeft', 'spacing/modal');
    // Title
    await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
    const title = figma.createText();
    title.name = 'Title';
    title.characters = 'Modal Title';
    title.fontSize = 20;
    title.fontName = { family: 'Inter', style: 'Bold' };
    title.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    title.layoutAlign = 'STRETCH';
    modal.appendChild(title);
    // Body
    await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
    const body = figma.createText();
    body.name = 'Body';
    body.characters = 'Modal body text goes here with additional information.';
    body.fontSize = 15;
    body.fontName = { family: 'Inter', style: 'Regular' };
    body.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0.9 }];
    body.layoutAlign = 'STRETCH';
    body.layoutGrow = 1;
    modal.appendChild(body);
    // Buttons footer
    const footer = createAutoLayoutFrame('Footer', 'HORIZONTAL', 0, 12);
    footer.layoutAlign = 'STRETCH';
    footer.primaryAxisAlignItems = 'MAX';
    modal.appendChild(footer);
    // Center modal on backdrop
    modal.x = (backdrop.width - modal.width) / 2;
    modal.y = (backdrop.height - modal.height) / 2;
    backdrop.appendChild(modal);
    // Add properties
    modal.addComponentProperty('Type', 'VARIANT', 'Standard');
    return modal;
}
/**
 * Generate ZeroListItem component
 * Variants: with icon, badge, arrow
 */
async function generateZeroListItem() {
    console.log('Generating ZeroListItem...');
    const item = figma.createComponent();
    item.name = 'ZeroListItem';
    item.layoutMode = 'HORIZONTAL';
    item.paddingLeft = 12;
    item.paddingRight = 12;
    item.paddingTop = 12;
    item.paddingBottom = 12;
    item.itemSpacing = 12;
    item.counterAxisSizingMode = 'FIXED';
    item.primaryAxisSizingMode = 'FIXED';
    item.counterAxisAlignItems = 'CENTER';
    item.resize(358, 52);
    item.cornerRadius = 4;
    // Try to bind variables
    bindNumberVariable(item, 'paddingLeft', 'spacing/element');
    bindNumberVariable(item, 'cornerRadius', 'radius/minimal');
    // Background (transparent by default)
    item.fills = [];
    // Leading icon
    const icon = figma.createRectangle();
    icon.name = 'Icon';
    icon.resize(20, 20);
    icon.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    icon.visible = false;
    item.appendChild(icon);
    // Label
    await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
    const label = figma.createText();
    label.name = 'Label';
    label.characters = 'List Item';
    label.fontSize = 16;
    label.fontName = { family: 'Inter', style: 'Regular' };
    label.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    label.layoutGrow = 1;
    item.appendChild(label);
    // Badge
    const badge = figma.createRectangle();
    badge.name = 'Badge';
    badge.resize(24, 24);
    badge.cornerRadius = 12;
    badge.fills = [{ type: 'SOLID', color: { r: 0.23, g: 0.51, b: 0.96 }, opacity: 0.3 }];
    badge.visible = false;
    item.appendChild(badge);
    // Arrow
    const arrow = figma.createRectangle();
    arrow.name = 'Arrow';
    arrow.resize(16, 16);
    arrow.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0.7 }];
    arrow.visible = false;
    item.appendChild(arrow);
    // Add properties
    item.addComponentProperty('HasIcon', 'BOOLEAN', false);
    item.addComponentProperty('HasBadge', 'BOOLEAN', false);
    item.addComponentProperty('HasArrow', 'BOOLEAN', false);
    item.addComponentProperty('State', 'VARIANT', 'Default');
    return item;
}
/**
 * Generate ZeroAlert component
 * Variants: Success, Error, Warning, Info
 */
async function generateZeroAlert() {
    console.log('Generating ZeroAlert...');
    const alert = figma.createComponent();
    alert.name = 'ZeroAlert';
    alert.layoutMode = 'HORIZONTAL';
    alert.paddingLeft = 16;
    alert.paddingRight = 16;
    alert.paddingTop = 16;
    alert.paddingBottom = 16;
    alert.itemSpacing = 12;
    alert.counterAxisSizingMode = 'FIXED';
    alert.primaryAxisSizingMode = 'FIXED';
    alert.counterAxisAlignItems = 'CENTER';
    alert.resize(358, 68);
    alert.cornerRadius = 12;
    // Try to bind variables
    bindNumberVariable(alert, 'paddingLeft', 'spacing/component');
    bindNumberVariable(alert, 'cornerRadius', 'radius/button');
    // Background (green for success)
    alert.fills = [{ type: 'SOLID', color: { r: 0.06, g: 0.73, b: 0.35 }, opacity: 0.2 }];
    alert.strokes = [{ type: 'SOLID', color: { r: 0.06, g: 0.73, b: 0.35 }, opacity: 0.3 }];
    alert.strokeWeight = 1;
    // Icon
    const icon = figma.createRectangle();
    icon.name = 'Icon';
    icon.resize(24, 24);
    icon.fills = [{ type: 'SOLID', color: { r: 0.06, g: 0.73, b: 0.35 } }];
    alert.appendChild(icon);
    // Text section
    const textSection = createAutoLayoutFrame('TextSection', 'VERTICAL', 0, 4);
    textSection.layoutGrow = 1;
    await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
    const title = figma.createText();
    title.name = 'Title';
    title.characters = 'Success';
    title.fontSize = 15;
    title.fontName = { family: 'Inter', style: 'Semi Bold' };
    title.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
    title.layoutAlign = 'STRETCH';
    textSection.appendChild(title);
    await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
    const message = figma.createText();
    message.name = 'Message';
    message.characters = 'Your action was completed successfully.';
    message.fontSize = 13;
    message.fontName = { family: 'Inter', style: 'Regular' };
    message.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0.9 }];
    message.layoutAlign = 'STRETCH';
    textSection.appendChild(message);
    alert.appendChild(textSection);
    // Close button
    const closeButton = figma.createRectangle();
    closeButton.name = 'CloseButton';
    closeButton.resize(20, 20);
    closeButton.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0.7 }];
    alert.appendChild(closeButton);
    // Add properties
    alert.addComponentProperty('Type', 'VARIANT', 'Success');
    alert.addComponentProperty('HasCloseButton', 'BOOLEAN', true);
    return alert;
}
// MARK: - Main Plugin Logic
async function generateAllComponents() {
    try {
        // Create or find Components page
        let componentsPage = figma.root.children.find(page => page.name === 'Components');
        if (!componentsPage) {
            componentsPage = figma.createPage();
            componentsPage.name = 'Components';
        }
        figma.currentPage = componentsPage;
        // Generate all components
        const button = await generateZeroButton();
        button.x = 100;
        button.y = 100;
        const card = await generateZeroCard();
        card.x = 100;
        card.y = 300;
        const modal = await generateZeroModal();
        modal.x = 600;
        modal.y = 100;
        const listItem = await generateZeroListItem();
        listItem.x = 100;
        listItem.y = 650;
        const alertComponent = await generateZeroAlert();
        alertComponent.x = 100;
        alertComponent.y = 800;
        // Zoom to fit all components
        figma.viewport.scrollAndZoomIntoView([button, card, modal, listItem, alertComponent]);
        figma.closePlugin('✅ Generated 5 core components!\n\n' +
            '• ZeroButton\n' +
            '• ZeroCard\n' +
            '• ZeroModal\n' +
            '• ZeroListItem\n' +
            '• ZeroAlert\n\n' +
            'Check the Components page to see them.');
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        figma.closePlugin(`❌ Error: ${errorMessage}`);
    }
}
// MARK: - Plugin Entry Point
figma.showUI(__html__, { width: 300, height: 400 });
figma.ui.onmessage = async (msg) => {
    if (msg.type === 'generate-all') {
        await generateAllComponents();
    }
    else if (msg.type === 'cancel') {
        figma.closePlugin();
    }
};

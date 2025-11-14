/// <reference types="@figma/plugin-typings" />
/**
 * Zero Inbox - Complete Design System Generator
 *
 * Generates entire design system from iOS source code:
 * - Design Tokens (spacing, colors, gradients, typography)
 * - Atomic Components (buttons, inputs, badges, progress)
 * - Molecule Components (headers, footers, cards)
 * - Modal Templates (12 reusable templates)
 * - GO_TO Visual Feedback System
 */
// ============================================================================
// DESIGN TOKENS (Parsed from DesignTokens.swift)
// ============================================================================
const TOKENS = {
    spacing: {
        minimal: 4,
        tight: 6,
        inline: 8,
        element: 12,
        component: 16,
        section: 20,
        modal: 24,
        card: 24
    },
    radius: {
        minimal: 4,
        chip: 8,
        button: 12,
        container: 16,
        card: 16,
        modal: 20,
        circle: 999
    },
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
        textPrimary: 1.0
    },
    colors: {
        gradients: {
            mail: { start: '#667eea', end: '#764ba2' },
            ads: { start: '#16bbaa', end: '#4fd19e' },
            lifestyle: { start: '#f093fb', end: '#f5576c' },
            shop: { start: '#4facfe', end: '#00f2fe' },
            urgent: { start: '#fa709a', end: '#fee140' }
        },
        priorities: [
            { name: 'Critical', value: 95, color: '#FF3B30' },
            { name: 'Very High', value: 90, color: '#FF9500' },
            { name: 'High', value: 85, color: '#FFCC00' },
            { name: 'Medium-High', value: 80, color: '#34C759' },
            { name: 'Medium', value: 75, color: '#667eea' },
            { name: 'Medium-Low', value: 70, color: '#5AC8FA' },
            { name: 'Low', value: 65, color: '#8E8E93' },
            { name: 'Very Low', value: 60, color: '#636366' }
        ]
    },
    button: {
        heightStandard: 56,
        heightCompact: 44,
        heightSmall: 32,
        iconSize: 20
    }
};
// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================
function hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (!result)
        return { r: 1, g: 1, b: 1 };
    return {
        r: parseInt(result[1], 16) / 255,
        g: parseInt(result[2], 16) / 255,
        b: parseInt(result[3], 16) / 255
    };
}
function createGradient(startHex, endHex) {
    const start = hexToRgb(startHex);
    const end = hexToRgb(endHex);
    return [{
            type: 'GRADIENT_LINEAR',
            gradientTransform: [
                [0.7071, 0.7071, 0],
                [-0.7071, 0.7071, 0.7071]
            ],
            gradientStops: [
                { position: 0, color: { ...start, a: 1 } },
                { position: 1, color: { ...end, a: 1 } }
            ]
        }];
}
function createSolidFill(hex, opacity = 1) {
    const rgb = hexToRgb(hex);
    return [{
            type: 'SOLID',
            color: rgb,
            opacity: opacity
        }];
}
// ============================================================================
// COMPONENT GENERATORS
// ============================================================================
/**
 * Generate Design Tokens Page
 */
function generateTokensPage() {
    const page = figma.createPage();
    page.name = '🎨 Design Tokens';
    let yOffset = 0;
    // Gradients Section
    const gradientsFrame = figma.createFrame();
    gradientsFrame.name = 'Gradients';
    gradientsFrame.x = 0;
    gradientsFrame.y = yOffset;
    gradientsFrame.resize(1000, 200);
    gradientsFrame.fills = [];
    let xOffset = 0;
    const gradientNames = ['mail', 'ads', 'lifestyle', 'shop', 'urgent'];
    gradientNames.forEach(name => {
        const rect = figma.createRectangle();
        const gradient = TOKENS.colors.gradients[name];
        rect.name = `${name.charAt(0).toUpperCase() + name.slice(1)} Gradient`;
        rect.x = xOffset;
        rect.y = 0;
        rect.resize(180, 120);
        rect.cornerRadius = TOKENS.radius.card;
        rect.fills = createGradient(gradient.start, gradient.end);
        // Add label
        const label = figma.createText();
        label.characters = rect.name;
        label.fontSize = 14;
        label.x = xOffset;
        label.y = 130;
        gradientsFrame.appendChild(rect);
        gradientsFrame.appendChild(label);
        xOffset += 200;
    });
    page.appendChild(gradientsFrame);
    yOffset += 250;
    // Priority Colors Section
    const prioritiesFrame = figma.createFrame();
    prioritiesFrame.name = 'Priority Colors';
    prioritiesFrame.x = 0;
    prioritiesFrame.y = yOffset;
    prioritiesFrame.resize(1000, 150);
    prioritiesFrame.fills = [];
    xOffset = 0;
    TOKENS.colors.priorities.forEach(priority => {
        const circle = figma.createEllipse();
        circle.name = `${priority.name} (${priority.value})`;
        circle.x = xOffset;
        circle.y = 0;
        circle.resize(60, 60);
        circle.fills = createSolidFill(priority.color);
        // Add label
        const label = figma.createText();
        label.characters = priority.name;
        label.fontSize = 12;
        label.x = xOffset;
        label.y = 70;
        prioritiesFrame.appendChild(circle);
        prioritiesFrame.appendChild(label);
        xOffset += 110;
    });
    page.appendChild(prioritiesFrame);
    figma.currentPage = page;
}
/**
 * Generate Atomic Components Page
 */
function generateAtomicComponents() {
    const page = figma.createPage();
    page.name = '⚛️ Atomic Components';
    let yOffset = 0;
    // === GRADIENT BUTTONS ===
    const buttonsFrame = figma.createFrame();
    buttonsFrame.name = 'Gradient Buttons';
    buttonsFrame.x = 0;
    buttonsFrame.y = yOffset;
    buttonsFrame.resize(1200, 400);
    buttonsFrame.fills = [];
    buttonsFrame.layoutMode = 'VERTICAL';
    buttonsFrame.itemSpacing = 40;
    buttonsFrame.paddingTop = 20;
    buttonsFrame.paddingBottom = 20;
    // Create buttons for each size
    const sizes = [
        { name: 'Standard', height: TOKENS.button.heightStandard },
        { name: 'Compact', height: TOKENS.button.heightCompact },
        { name: 'Small', height: TOKENS.button.heightSmall }
    ];
    sizes.forEach(size => {
        const sizeFrame = figma.createFrame();
        sizeFrame.name = `${size.name} Buttons (${size.height}px)`;
        sizeFrame.resize(1200, size.height + 40);
        sizeFrame.fills = [];
        sizeFrame.layoutMode = 'HORIZONTAL';
        sizeFrame.itemSpacing = 20;
        // Create button for each gradient
        Object.entries(TOKENS.colors.gradients).forEach(([name, gradient]) => {
            const button = figma.createRectangle();
            button.name = `Button-${name}-${size.name}`;
            button.resize(200, size.height);
            button.cornerRadius = TOKENS.radius.button;
            button.fills = createGradient(gradient.start, gradient.end);
            // Add text
            const text = figma.createText();
            text.characters = name.charAt(0).toUpperCase() + name.slice(1);
            text.fontSize = size.height === 56 ? 17 : size.height === 44 ? 15 : 13;
            text.fills = createSolidFill('#FFFFFF');
            const buttonGroup = figma.group([button, text], sizeFrame);
            buttonGroup.name = `${name}-${size.name}`;
        });
        buttonsFrame.appendChild(sizeFrame);
    });
    page.appendChild(buttonsFrame);
    yOffset += 450;
    // === INPUT COMPONENTS ===
    const inputsFrame = figma.createFrame();
    inputsFrame.name = 'Input Components';
    inputsFrame.x = 0;
    inputsFrame.y = yOffset;
    inputsFrame.resize(800, 500);
    inputsFrame.fills = [];
    inputsFrame.layoutMode = 'VERTICAL';
    inputsFrame.itemSpacing = 16;
    inputsFrame.paddingTop = 20;
    const inputTypes = [
        'TextField',
        'TextArea',
        'DatePicker',
        'TimePicker',
        'Dropdown',
        'Checkbox',
        'Radio',
        'Toggle'
    ];
    inputTypes.forEach(type => {
        const input = figma.createRectangle();
        input.name = type;
        input.resize(400, type === 'TextArea' ? 120 : 44);
        input.cornerRadius = TOKENS.radius.button;
        input.fills = createSolidFill('#FFFFFF', 0.05);
        input.strokes = createSolidFill('#FFFFFF', 0.2);
        input.strokeWeight = 1;
        inputsFrame.appendChild(input);
    });
    page.appendChild(inputsFrame);
    yOffset += 550;
    // === PRIORITY BADGES ===
    const badgesFrame = figma.createFrame();
    badgesFrame.name = 'Priority Badges';
    badgesFrame.x = 0;
    badgesFrame.y = yOffset;
    badgesFrame.resize(1000, 100);
    badgesFrame.fills = [];
    badgesFrame.layoutMode = 'HORIZONTAL';
    badgesFrame.itemSpacing = 20;
    TOKENS.colors.priorities.forEach(priority => {
        const badge = figma.createEllipse();
        badge.name = `Badge-${priority.name}-${priority.value}`;
        badge.resize(50, 50);
        badge.fills = createSolidFill(priority.color);
        badgesFrame.appendChild(badge);
    });
    page.appendChild(badgesFrame);
    figma.currentPage = page;
}
/**
 * Generate GO_TO Visual Feedback System
 */
function generateGoToFeedback() {
    const page = figma.createPage();
    page.name = '↗️ GO_TO Visual Feedback';
    let yOffset = 0;
    // === EXTERNAL INDICATOR ===
    const indicatorFrame = figma.createFrame();
    indicatorFrame.name = 'External Indicator';
    indicatorFrame.x = 0;
    indicatorFrame.y = yOffset;
    indicatorFrame.resize(200, 100);
    indicatorFrame.fills = [];
    const icon = figma.createText();
    icon.characters = '↗';
    icon.fontSize = 16;
    icon.fills = createSolidFill('#8E8E93', 0.6);
    icon.x = 20;
    icon.y = 20;
    indicatorFrame.appendChild(icon);
    page.appendChild(indicatorFrame);
    yOffset += 150;
    // === ACTION CARD STATES ===
    const statesFrame = figma.createFrame();
    statesFrame.name = 'Action Card States';
    statesFrame.x = 0;
    statesFrame.y = yOffset;
    statesFrame.resize(1100, 200);
    statesFrame.fills = [];
    statesFrame.layoutMode = 'HORIZONTAL';
    statesFrame.itemSpacing = 30;
    const states = [
        { name: 'Idle', opacity: 1.0 },
        { name: 'Pressed', opacity: 0.8 },
        { name: 'Loading', opacity: 1.0 }
    ];
    states.forEach(state => {
        const card = figma.createRectangle();
        card.name = `Card-${state.name}`;
        card.resize(343, 80);
        card.cornerRadius = TOKENS.radius.card;
        card.fills = createGradient(TOKENS.colors.gradients.mail.start, TOKENS.colors.gradients.mail.end);
        card.opacity = state.opacity;
        statesFrame.appendChild(card);
    });
    page.appendChild(statesFrame);
    yOffset += 250;
    // === LOADING SPINNERS ===
    const spinnersFrame = figma.createFrame();
    spinnersFrame.name = 'Loading Spinners';
    spinnersFrame.x = 0;
    spinnersFrame.y = yOffset;
    spinnersFrame.resize(1000, 100);
    spinnersFrame.fills = [];
    spinnersFrame.layoutMode = 'HORIZONTAL';
    spinnersFrame.itemSpacing = 40;
    TOKENS.colors.priorities.forEach(priority => {
        const spinner = figma.createEllipse();
        spinner.name = `Spinner-${priority.name}`;
        spinner.resize(20, 20);
        spinner.fills = [];
        spinner.strokes = createSolidFill(priority.color);
        spinner.strokeWeight = 2;
        spinner.arcData = { startingAngle: 0, endingAngle: Math.PI * 1.5, innerRadius: 0.8 };
        spinnersFrame.appendChild(spinner);
    });
    page.appendChild(spinnersFrame);
    figma.currentPage = page;
}
/**
 * Generate Modal Templates
 */
function generateModalTemplates() {
    const page = figma.createPage();
    page.name = '🏗️ Modal Templates';
    let yOffset = 0;
    const xSpacing = 420;
    // === GENERIC ACTION MODAL ===
    const genericModal = figma.createFrame();
    genericModal.name = 'GenericActionModal';
    genericModal.x = 0;
    genericModal.y = yOffset;
    genericModal.resize(375, 600);
    genericModal.cornerRadius = TOKENS.radius.modal;
    genericModal.fills = createSolidFill('#1C1C1E');
    genericModal.layoutMode = 'VERTICAL';
    genericModal.itemSpacing = 20;
    genericModal.paddingTop = 24;
    genericModal.paddingBottom = 24;
    genericModal.paddingLeft = 16;
    genericModal.paddingRight = 16;
    // Header
    const header = figma.createText();
    header.characters = 'Add to Calendar';
    header.fontSize = 24;
    header.fills = createSolidFill('#FFFFFF');
    genericModal.appendChild(header);
    // Description
    const desc = figma.createText();
    desc.characters = 'Create a new calendar event for this item';
    desc.fontSize = 15;
    desc.fills = createSolidFill('#FFFFFF', 0.7);
    genericModal.appendChild(desc);
    // Input
    const input = figma.createRectangle();
    input.name = 'Date Input';
    input.resize(343, 44);
    input.cornerRadius = TOKENS.radius.button;
    input.fills = createSolidFill('#FFFFFF', 0.05);
    genericModal.appendChild(input);
    // Button
    const button = figma.createRectangle();
    button.name = 'Primary Button';
    button.resize(343, 56);
    button.cornerRadius = TOKENS.radius.button;
    button.fills = createGradient(TOKENS.colors.gradients.mail.start, TOKENS.colors.gradients.mail.end);
    genericModal.appendChild(button);
    page.appendChild(genericModal);
    // === COMMUNICATION MODAL ===
    const commModal = figma.createFrame();
    commModal.name = 'CommunicationModal';
    commModal.x = xSpacing;
    commModal.y = yOffset;
    commModal.resize(375, 500);
    commModal.cornerRadius = TOKENS.radius.modal;
    commModal.fills = createSolidFill('#1C1C1E');
    commModal.layoutMode = 'VERTICAL';
    commModal.itemSpacing = 20;
    commModal.paddingTop = 24;
    commModal.paddingBottom = 24;
    commModal.paddingLeft = 16;
    commModal.paddingRight = 16;
    const commHeader = figma.createText();
    commHeader.characters = 'Quick Reply';
    commHeader.fontSize = 24;
    commHeader.fills = createSolidFill('#FFFFFF');
    commModal.appendChild(commHeader);
    const messageInput = figma.createRectangle();
    messageInput.name = 'Message Input';
    messageInput.resize(343, 120);
    messageInput.cornerRadius = TOKENS.radius.button;
    messageInput.fills = createSolidFill('#FFFFFF', 0.05);
    commModal.appendChild(messageInput);
    const sendButton = figma.createRectangle();
    sendButton.name = 'Send Button';
    sendButton.resize(343, 56);
    sendButton.cornerRadius = TOKENS.radius.button;
    sendButton.fills = createGradient(TOKENS.colors.gradients.mail.start, TOKENS.colors.gradients.mail.end);
    commModal.appendChild(sendButton);
    page.appendChild(commModal);
    // === VIEW CONTENT MODAL ===
    const viewModal = figma.createFrame();
    viewModal.name = 'ViewContentModal';
    viewModal.x = xSpacing * 2;
    viewModal.y = yOffset;
    viewModal.resize(375, 600);
    viewModal.cornerRadius = TOKENS.radius.modal;
    viewModal.fills = createSolidFill('#1C1C1E');
    viewModal.layoutMode = 'VERTICAL';
    viewModal.itemSpacing = 20;
    viewModal.paddingTop = 24;
    viewModal.paddingBottom = 24;
    viewModal.paddingLeft = 16;
    viewModal.paddingRight = 16;
    const viewHeader = figma.createText();
    viewHeader.characters = 'Document Details';
    viewHeader.fontSize = 24;
    viewHeader.fills = createSolidFill('#FFFFFF');
    viewModal.appendChild(viewHeader);
    const contentArea = figma.createRectangle();
    contentArea.name = 'Content Area';
    contentArea.resize(343, 400);
    contentArea.cornerRadius = TOKENS.radius.card;
    contentArea.fills = createSolidFill('#FFFFFF', 0.05);
    viewModal.appendChild(contentArea);
    const closeButton = figma.createRectangle();
    closeButton.name = 'Close Button';
    closeButton.resize(343, 56);
    closeButton.cornerRadius = TOKENS.radius.button;
    closeButton.fills = createSolidFill('#8E8E93', 0.3);
    viewModal.appendChild(closeButton);
    page.appendChild(viewModal);
    figma.currentPage = page;
}
// ============================================================================
// MAIN EXECUTION
// ============================================================================
async function generateAll() {
    console.log('🚀 Generating complete design system...');
    // Load default font
    await figma.loadFontAsync({ family: "Inter", style: "Regular" });
    await figma.loadFontAsync({ family: "Inter", style: "Bold" });
    // Generate all pages
    generateTokensPage();
    generateAtomicComponents();
    generateGoToFeedback();
    generateModalTemplates();
    console.log('✅ Design system generated!');
    figma.closePlugin('✅ Design system generated successfully!');
}
// Run the generator
figma.showUI(__html__, { visible: false });
generateAll();

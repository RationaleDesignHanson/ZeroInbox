"use strict";
/**
 * Modal Component Utilities
 *
 * Shared generator functions for building action modals efficiently.
 * Prevents code duplication and ensures consistency across all 46 modals.
 *
 * Based on iOS DesignTokens.swift for dimensional accuracy.
 * Follows design system best practices from architecture review.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.COLORS = exports.ModalTokens = void 0;
exports.createText = createText;
exports.createAutoLayoutFrame = createAutoLayoutFrame;
exports.createModalHeader = createModalHeader;
exports.createContextHeader = createContextHeader;
exports.createPrimaryButton = createPrimaryButton;
exports.createSecondaryButton = createSecondaryButton;
exports.createDestructiveButton = createDestructiveButton;
exports.createTextButton = createTextButton;
exports.createActionButtons = createActionButtons;
exports.createFormTextInput = createFormTextInput;
exports.createFormTextArea = createFormTextArea;
exports.createFormDropdown = createFormDropdown;
exports.createFormDatePicker = createFormDatePicker;
exports.createFormToggle = createFormToggle;
exports.createDetailRow = createDetailRow;
exports.createDivider = createDivider;
exports.createSignatureCanvas = createSignatureCanvas;
exports.createStatusBanner = createStatusBanner;
exports.createProgressBar = createProgressBar;
exports.createModalContainer = createModalContainer;
exports.finalizeModalWithEffects = finalizeModalWithEffects;
// ============================================================================
// Design Tokens (from iOS DesignTokens.swift)
// ============================================================================
exports.ModalTokens = {
    spacing: {
        modal: 24, // Modal container padding
        card: 16, // Card/section padding
        buttonHorizontal: 20,
        buttonVertical: 12,
        inputHorizontal: 12,
        inputVertical: 10,
        itemGap: 12, // Gap between items in auto-layout
        sectionGap: 20 // Gap between major sections
    },
    radius: {
        modal: 20,
        card: 16,
        button: 12,
        input: 8
    },
    modal: {
        widthDefault: 480,
        widthLarge: 640,
        widthSmall: 360
    },
    fontSize: {
        modalTitle: 20,
        sectionTitle: 17,
        label: 14,
        body: 15,
        caption: 13,
        closeButton: 24
    }
};
// ============================================================================
// Color Palette
// ============================================================================
exports.COLORS = {
    // Primary
    blue: { r: 0.23, g: 0.51, b: 0.96 },
    purple: { r: 0.46, g: 0.29, b: 0.64 },
    // Grayscale
    gray50: { r: 0.98, g: 0.98, b: 0.98 },
    gray100: { r: 0.96, g: 0.96, b: 0.96 },
    gray200: { r: 0.90, g: 0.91, b: 0.92 },
    gray300: { r: 0.82, g: 0.84, b: 0.86 },
    gray400: { r: 0.63, g: 0.65, b: 0.67 },
    gray600: { r: 0.45, g: 0.47, b: 0.49 },
    gray900: { r: 0.07, g: 0.09, b: 0.15 },
    // Status
    green: { r: 0.06, g: 0.73, b: 0.51 },
    greenBg: { r: 0.94, g: 0.99, b: 0.96 },
    red: { r: 0.94, g: 0.27, b: 0.35 },
    redBg: { r: 0.99, g: 0.94, b: 0.95 },
    yellow: { r: 0.96, g: 0.76, b: 0.05 },
    yellowBg: { r: 0.99, g: 0.98, b: 0.92 },
    // Base
    white: { r: 1, g: 1, b: 1 },
    black: { r: 0, g: 0, b: 0 }
};
// ============================================================================
// Helper Functions
// ============================================================================
async function createText(content, fontSize, weight = 'Regular') {
    const text = figma.createText();
    await figma.loadFontAsync({ family: 'Inter', style: weight });
    text.fontName = { family: 'Inter', style: weight };
    text.characters = content;
    text.fontSize = fontSize;
    return text;
}
function createAutoLayoutFrame(name, direction, spacing, padding) {
    const frame = figma.createFrame();
    frame.name = name;
    frame.layoutMode = direction;
    frame.itemSpacing = spacing;
    if (typeof padding === 'number') {
        frame.paddingLeft = padding;
        frame.paddingRight = padding;
        frame.paddingTop = padding;
        frame.paddingBottom = padding;
    }
    else {
        frame.paddingLeft = padding.left;
        frame.paddingRight = padding.right;
        frame.paddingTop = padding.top;
        frame.paddingBottom = padding.bottom;
    }
    frame.primaryAxisSizingMode = 'AUTO';
    frame.counterAxisSizingMode = 'AUTO';
    return frame;
}
// ============================================================================
// Modal Structure Components
// ============================================================================
/**
 * Creates modal header with title and close button
 * Matches iOS ModalHeader pattern
 */
async function createModalHeader(title, width = 432) {
    const header = createAutoLayoutFrame('Header', 'HORIZONTAL', exports.ModalTokens.spacing.itemGap, 0);
    header.primaryAxisSizingMode = 'FIXED';
    header.counterAxisSizingMode = 'AUTO';
    header.primaryAxisAlignItems = 'SPACE_BETWEEN';
    header.counterAxisAlignItems = 'CENTER';
    header.resize(width, 32);
    const titleText = await createText(title, exports.ModalTokens.fontSize.modalTitle, 'Semi Bold');
    titleText.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    header.appendChild(titleText);
    const closeBtn = await createText('×', exports.ModalTokens.fontSize.closeButton, 'Regular');
    closeBtn.fills = [{ type: 'SOLID', color: exports.COLORS.gray600 }];
    header.appendChild(closeBtn);
    return header;
}
/**
 * Creates context header with icon/avatar, title, and subtitle
 * Used for email info, document details, etc.
 */
async function createContextHeader(config) {
    const width = config.width || 432;
    const header = createAutoLayoutFrame('Context Header', 'HORIZONTAL', exports.ModalTokens.spacing.itemGap, exports.ModalTokens.spacing.card);
    header.primaryAxisSizingMode = 'FIXED';
    header.counterAxisSizingMode = 'AUTO';
    header.counterAxisAlignItems = 'CENTER';
    header.resize(width, config.subtitle ? 64 : 56);
    header.fills = [{ type: 'SOLID', color: config.backgroundColor || exports.COLORS.gray50 }];
    header.cornerRadius = exports.ModalTokens.radius.input;
    // Avatar or icon
    if (config.avatar) {
        const avatar = figma.createRectangle();
        avatar.name = 'Avatar';
        avatar.resize(40, 40);
        avatar.cornerRadius = 20;
        avatar.fills = [{ type: 'SOLID', color: exports.COLORS.blue }];
        header.appendChild(avatar);
    }
    else if (config.icon) {
        const icon = await createText(config.icon, 24, 'Regular');
        header.appendChild(icon);
    }
    // Text content
    const textContainer = createAutoLayoutFrame('Info', 'VERTICAL', 4, 0);
    const titleText = await createText(config.title, exports.ModalTokens.fontSize.body, 'Semi Bold');
    titleText.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    textContainer.appendChild(titleText);
    if (config.subtitle) {
        const subtitleText = await createText(config.subtitle, exports.ModalTokens.fontSize.caption, 'Regular');
        subtitleText.fills = [{ type: 'SOLID', color: exports.COLORS.gray600 }];
        textContainer.appendChild(subtitleText);
    }
    header.appendChild(textContainer);
    return header;
}
// ============================================================================
// Button Components
// ============================================================================
/**
 * Creates primary gradient button
 * Purple-blue gradient matching iOS ButtonPrimaryGradient
 */
async function createPrimaryButton(label, width) {
    const button = figma.createFrame();
    button.name = label;
    button.layoutMode = 'HORIZONTAL';
    button.paddingLeft = exports.ModalTokens.spacing.buttonHorizontal;
    button.paddingRight = exports.ModalTokens.spacing.buttonHorizontal;
    button.paddingTop = exports.ModalTokens.spacing.buttonVertical;
    button.paddingBottom = exports.ModalTokens.spacing.buttonVertical;
    button.primaryAxisSizingMode = width ? 'FIXED' : 'AUTO';
    button.counterAxisSizingMode = 'AUTO';
    button.primaryAxisAlignItems = 'CENTER';
    button.counterAxisAlignItems = 'CENTER';
    if (width)
        button.resize(width, 44);
    button.cornerRadius = exports.ModalTokens.radius.button;
    // Purple-blue gradient
    button.fills = [{
            type: 'GRADIENT_LINEAR',
            gradientTransform: [[1, 0, 0], [0, 1, 0]],
            gradientStops: [
                { position: 0, color: { r: 0.40, g: 0.49, b: 0.92, a: 1 } }, // Blue
                { position: 1, color: { r: 0.46, g: 0.29, b: 0.64, a: 1 } } // Purple
            ]
        }];
    const text = await createText(label, exports.ModalTokens.fontSize.body, 'Semi Bold');
    text.fills = [{ type: 'SOLID', color: exports.COLORS.white }];
    button.appendChild(text);
    return button;
}
/**
 * Creates secondary gray button
 * Matches iOS ButtonSecondaryGlass
 */
async function createSecondaryButton(label, width) {
    const button = figma.createFrame();
    button.name = label;
    button.layoutMode = 'HORIZONTAL';
    button.paddingLeft = exports.ModalTokens.spacing.buttonHorizontal;
    button.paddingRight = exports.ModalTokens.spacing.buttonHorizontal;
    button.paddingTop = exports.ModalTokens.spacing.buttonVertical;
    button.paddingBottom = exports.ModalTokens.spacing.buttonVertical;
    button.primaryAxisSizingMode = width ? 'FIXED' : 'AUTO';
    button.counterAxisSizingMode = 'AUTO';
    button.primaryAxisAlignItems = 'CENTER';
    button.counterAxisAlignItems = 'CENTER';
    if (width)
        button.resize(width, 44);
    button.cornerRadius = exports.ModalTokens.radius.button;
    button.fills = [{ type: 'SOLID', color: exports.COLORS.gray200 }];
    const text = await createText(label, exports.ModalTokens.fontSize.body, 'Medium');
    text.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    button.appendChild(text);
    return button;
}
/**
 * Creates destructive red button
 * For delete, cancel, unsubscribe actions
 */
async function createDestructiveButton(label, width) {
    const button = figma.createFrame();
    button.name = label;
    button.layoutMode = 'HORIZONTAL';
    button.paddingLeft = exports.ModalTokens.spacing.buttonHorizontal;
    button.paddingRight = exports.ModalTokens.spacing.buttonHorizontal;
    button.paddingTop = exports.ModalTokens.spacing.buttonVertical;
    button.paddingBottom = exports.ModalTokens.spacing.buttonVertical;
    button.primaryAxisSizingMode = width ? 'FIXED' : 'AUTO';
    button.counterAxisSizingMode = 'AUTO';
    button.primaryAxisAlignItems = 'CENTER';
    button.counterAxisAlignItems = 'CENTER';
    if (width)
        button.resize(width, 44);
    button.cornerRadius = exports.ModalTokens.radius.button;
    button.fills = [{ type: 'SOLID', color: exports.COLORS.red }];
    const text = await createText(label, exports.ModalTokens.fontSize.body, 'Semi Bold');
    text.fills = [{ type: 'SOLID', color: exports.COLORS.white }];
    button.appendChild(text);
    return button;
}
/**
 * Creates text-only button (for "Clear", "Learn More", etc.)
 */
async function createTextButton(label, color = exports.COLORS.blue) {
    const button = createAutoLayoutFrame('Text Button', 'HORIZONTAL', 0, {
        left: exports.ModalTokens.spacing.card,
        right: exports.ModalTokens.spacing.card,
        top: 8,
        bottom: 8
    });
    button.fills = [];
    const text = await createText(label, exports.ModalTokens.fontSize.caption, 'Medium');
    text.fills = [{ type: 'SOLID', color }];
    button.appendChild(text);
    return button;
}
/**
 * Creates action button row (cancel + primary)
 * Standard modal footer pattern
 */
async function createActionButtons(config) {
    const actions = createAutoLayoutFrame('Actions', 'HORIZONTAL', exports.ModalTokens.spacing.itemGap, 0);
    actions.primaryAxisSizingMode = 'FIXED';
    actions.counterAxisSizingMode = 'AUTO';
    actions.primaryAxisAlignItems = 'SPACE_BETWEEN';
    actions.resize(config.width, 44);
    actions.appendChild(await createSecondaryButton(config.cancel));
    actions.appendChild(config.destructive
        ? await createDestructiveButton(config.primary)
        : await createPrimaryButton(config.primary));
    return actions;
}
// ============================================================================
// Form Components
// ============================================================================
/**
 * Creates text input field with label
 * Matches iOS FormTextInput
 */
async function createFormTextInput(label, placeholder, width = 432, defaultValue) {
    const field = createAutoLayoutFrame('Input Field', 'VERTICAL', 8, 0);
    field.primaryAxisSizingMode = 'FIXED';
    field.resize(width, 70);
    const labelText = await createText(label, exports.ModalTokens.fontSize.label, 'Medium');
    labelText.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    field.appendChild(labelText);
    const input = figma.createFrame();
    input.name = 'Input';
    input.layoutMode = 'VERTICAL';
    input.paddingLeft = exports.ModalTokens.spacing.inputHorizontal;
    input.paddingRight = exports.ModalTokens.spacing.inputHorizontal;
    input.paddingTop = exports.ModalTokens.spacing.inputVertical;
    input.paddingBottom = exports.ModalTokens.spacing.inputVertical;
    input.primaryAxisSizingMode = 'FIXED';
    input.counterAxisSizingMode = 'AUTO';
    input.resize(width, 44);
    input.cornerRadius = exports.ModalTokens.radius.input;
    input.fills = [{ type: 'SOLID', color: exports.COLORS.white }];
    input.strokes = [{ type: 'SOLID', color: exports.COLORS.gray300 }];
    input.strokeWeight = 1;
    const valueText = await createText(defaultValue || placeholder, exports.ModalTokens.fontSize.body, 'Regular');
    valueText.fills = [{
            type: 'SOLID',
            color: defaultValue ? exports.COLORS.gray900 : exports.COLORS.gray400
        }];
    input.appendChild(valueText);
    field.appendChild(input);
    return field;
}
/**
 * Creates textarea field for multi-line input
 * Matches iOS FormTextArea
 */
async function createFormTextArea(label, placeholder, width = 432, height = 140) {
    const field = createAutoLayoutFrame('Textarea Field', 'VERTICAL', 8, 0);
    field.primaryAxisSizingMode = 'FIXED';
    field.resize(width, height + 30);
    const labelText = await createText(label, exports.ModalTokens.fontSize.label, 'Medium');
    labelText.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    field.appendChild(labelText);
    const textarea = figma.createFrame();
    textarea.name = 'Textarea';
    textarea.layoutMode = 'VERTICAL';
    textarea.paddingLeft = exports.ModalTokens.spacing.inputHorizontal;
    textarea.paddingRight = exports.ModalTokens.spacing.inputHorizontal;
    textarea.paddingTop = exports.ModalTokens.spacing.inputVertical;
    textarea.paddingBottom = exports.ModalTokens.spacing.inputVertical;
    textarea.primaryAxisSizingMode = 'FIXED';
    textarea.counterAxisSizingMode = 'FIXED';
    textarea.resize(width, height);
    textarea.cornerRadius = exports.ModalTokens.radius.input;
    textarea.fills = [{ type: 'SOLID', color: exports.COLORS.white }];
    textarea.strokes = [{ type: 'SOLID', color: exports.COLORS.gray300 }];
    textarea.strokeWeight = 1;
    const placeholderText = await createText(placeholder, exports.ModalTokens.fontSize.body, 'Regular');
    placeholderText.fills = [{ type: 'SOLID', color: exports.COLORS.gray400 }];
    textarea.appendChild(placeholderText);
    field.appendChild(textarea);
    return field;
}
/**
 * Creates dropdown/select field
 * Matches iOS FormDropdown
 */
async function createFormDropdown(label, value, width = 432) {
    const field = createAutoLayoutFrame('Dropdown Field', 'VERTICAL', 8, 0);
    field.primaryAxisSizingMode = 'FIXED';
    field.resize(width, 70);
    const labelText = await createText(label, exports.ModalTokens.fontSize.label, 'Medium');
    labelText.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    field.appendChild(labelText);
    const dropdown = figma.createFrame();
    dropdown.name = 'Dropdown';
    dropdown.layoutMode = 'HORIZONTAL';
    dropdown.paddingLeft = exports.ModalTokens.spacing.inputHorizontal;
    dropdown.paddingRight = exports.ModalTokens.spacing.inputHorizontal;
    dropdown.paddingTop = exports.ModalTokens.spacing.inputVertical;
    dropdown.paddingBottom = exports.ModalTokens.spacing.inputVertical;
    dropdown.itemSpacing = 8;
    dropdown.primaryAxisSizingMode = 'FIXED';
    dropdown.counterAxisSizingMode = 'AUTO';
    dropdown.primaryAxisAlignItems = 'SPACE_BETWEEN';
    dropdown.counterAxisAlignItems = 'CENTER';
    dropdown.resize(width, 44);
    dropdown.cornerRadius = exports.ModalTokens.radius.input;
    dropdown.fills = [{ type: 'SOLID', color: exports.COLORS.white }];
    dropdown.strokes = [{ type: 'SOLID', color: exports.COLORS.gray300 }];
    dropdown.strokeWeight = 1;
    const valueText = await createText(value, exports.ModalTokens.fontSize.body, 'Regular');
    valueText.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    dropdown.appendChild(valueText);
    const chevron = await createText('▼', 12, 'Regular');
    chevron.fills = [{ type: 'SOLID', color: exports.COLORS.gray600 }];
    dropdown.appendChild(chevron);
    field.appendChild(dropdown);
    return field;
}
/**
 * Creates date picker field
 * Matches iOS FormDatePicker
 */
async function createFormDatePicker(label, value, icon = '📅', width = 432) {
    const field = createAutoLayoutFrame('Date Field', 'VERTICAL', 8, 0);
    field.primaryAxisSizingMode = 'FIXED';
    field.resize(width, 70);
    const labelText = await createText(label, exports.ModalTokens.fontSize.label, 'Medium');
    labelText.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    field.appendChild(labelText);
    const picker = figma.createFrame();
    picker.name = 'Date Picker';
    picker.layoutMode = 'HORIZONTAL';
    picker.paddingLeft = exports.ModalTokens.spacing.inputHorizontal;
    picker.paddingRight = exports.ModalTokens.spacing.inputHorizontal;
    picker.paddingTop = exports.ModalTokens.spacing.inputVertical;
    picker.paddingBottom = exports.ModalTokens.spacing.inputVertical;
    picker.itemSpacing = 8;
    picker.primaryAxisSizingMode = 'FIXED';
    picker.counterAxisSizingMode = 'AUTO';
    picker.primaryAxisAlignItems = 'SPACE_BETWEEN';
    picker.counterAxisAlignItems = 'CENTER';
    picker.resize(width, 44);
    picker.cornerRadius = exports.ModalTokens.radius.input;
    picker.fills = [{ type: 'SOLID', color: exports.COLORS.white }];
    picker.strokes = [{ type: 'SOLID', color: exports.COLORS.gray300 }];
    picker.strokeWeight = 1;
    const valueText = await createText(value, exports.ModalTokens.fontSize.body, 'Regular');
    valueText.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    picker.appendChild(valueText);
    const iconText = await createText(icon, 16, 'Regular');
    picker.appendChild(iconText);
    field.appendChild(picker);
    return field;
}
/**
 * Creates toggle switch with label
 * Matches iOS FormToggle
 */
async function createFormToggle(label, enabled = true, width = 432) {
    const field = createAutoLayoutFrame('Toggle Field', 'HORIZONTAL', exports.ModalTokens.spacing.itemGap, 0);
    field.primaryAxisSizingMode = 'FIXED';
    field.counterAxisSizingMode = 'AUTO';
    field.primaryAxisAlignItems = 'SPACE_BETWEEN';
    field.counterAxisAlignItems = 'CENTER';
    field.resize(width, 44);
    const labelText = await createText(label, exports.ModalTokens.fontSize.body, 'Regular');
    labelText.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    field.appendChild(labelText);
    // Toggle track
    const toggle = figma.createFrame();
    toggle.name = 'Toggle';
    toggle.resize(44, 24);
    toggle.cornerRadius = 12;
    toggle.fills = [{ type: 'SOLID', color: enabled ? exports.COLORS.blue : exports.COLORS.gray300 }];
    toggle.clipsContent = false;
    // Toggle knob
    const knob = figma.createEllipse();
    knob.resize(20, 20);
    knob.x = enabled ? 22 : 2;
    knob.y = 2;
    knob.fills = [{ type: 'SOLID', color: exports.COLORS.white }];
    toggle.appendChild(knob);
    field.appendChild(toggle);
    return field;
}
// ============================================================================
// Content Components
// ============================================================================
/**
 * Creates detail row (label + value)
 * For showing key-value pairs like "Amount: $50.00"
 */
async function createDetailRow(label, value, width = 432, bold = false) {
    const row = createAutoLayoutFrame('Detail Row', 'HORIZONTAL', exports.ModalTokens.spacing.itemGap, 0);
    row.primaryAxisSizingMode = 'FIXED';
    row.counterAxisSizingMode = 'AUTO';
    row.primaryAxisAlignItems = 'SPACE_BETWEEN';
    row.resize(width, 24);
    const labelText = await createText(label, exports.ModalTokens.fontSize.body, bold ? 'Semi Bold' : 'Regular');
    labelText.fills = [{ type: 'SOLID', color: exports.COLORS.gray600 }];
    row.appendChild(labelText);
    const valueText = await createText(value, exports.ModalTokens.fontSize.body, bold ? 'Bold' : 'Semi Bold');
    valueText.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    row.appendChild(valueText);
    return row;
}
/**
 * Creates divider line
 */
function createDivider(width = 432) {
    const divider = figma.createRectangle();
    divider.name = 'Divider';
    divider.resize(width, 1);
    divider.fills = [{ type: 'SOLID', color: exports.COLORS.gray200 }];
    return divider;
}
/**
 * Creates signature canvas placeholder
 * Dashed border, centered placeholder text
 */
async function createSignatureCanvas(width = 432, height = 180) {
    const canvas = figma.createFrame();
    canvas.name = 'Signature Canvas';
    canvas.layoutMode = 'VERTICAL';
    canvas.primaryAxisSizingMode = 'FIXED';
    canvas.counterAxisSizingMode = 'FIXED';
    canvas.primaryAxisAlignItems = 'CENTER';
    canvas.counterAxisAlignItems = 'CENTER';
    canvas.resize(width, height);
    canvas.cornerRadius = exports.ModalTokens.radius.input;
    canvas.fills = [{ type: 'SOLID', color: exports.COLORS.gray50 }];
    canvas.strokes = [{ type: 'SOLID', color: exports.COLORS.gray300, opacity: 0.5 }];
    canvas.strokeWeight = 1;
    canvas.strokeAlign = 'INSIDE';
    canvas.dashPattern = [4, 4];
    const placeholder = await createText('Sign here', exports.ModalTokens.fontSize.body, 'Regular');
    placeholder.fills = [{ type: 'SOLID', color: exports.COLORS.gray400 }];
    placeholder.textAlignHorizontal = 'CENTER';
    placeholder.textAlignVertical = 'CENTER';
    canvas.appendChild(placeholder);
    return canvas;
}
/**
 * Creates status banner
 * Success, error, warning variants
 */
async function createStatusBanner(message, type, width = 432) {
    const colors = {
        success: { bg: exports.COLORS.greenBg, text: exports.COLORS.green, icon: '✓' },
        error: { bg: exports.COLORS.redBg, text: exports.COLORS.red, icon: '✕' },
        warning: { bg: exports.COLORS.yellowBg, text: exports.COLORS.yellow, icon: '⚠' }
    };
    const config = colors[type];
    const banner = createAutoLayoutFrame('Status Banner', 'HORIZONTAL', exports.ModalTokens.spacing.itemGap, exports.ModalTokens.spacing.card);
    banner.primaryAxisSizingMode = 'FIXED';
    banner.counterAxisSizingMode = 'AUTO';
    banner.counterAxisAlignItems = 'CENTER';
    banner.resize(width, 48);
    banner.fills = [{ type: 'SOLID', color: config.bg }];
    banner.cornerRadius = exports.ModalTokens.radius.input;
    const icon = await createText(config.icon, 18, 'Regular');
    icon.fills = [{ type: 'SOLID', color: config.text }];
    banner.appendChild(icon);
    const text = await createText(message, exports.ModalTokens.fontSize.body, 'Medium');
    text.fills = [{ type: 'SOLID', color: exports.COLORS.gray900 }];
    banner.appendChild(text);
    return banner;
}
/**
 * Creates progress bar
 */
async function createProgressBar(progress, // 0-100
width = 432) {
    const container = figma.createFrame();
    container.name = 'Progress Bar';
    container.resize(width, 8);
    container.cornerRadius = 4;
    container.fills = [{ type: 'SOLID', color: exports.COLORS.gray200 }];
    container.clipsContent = true;
    const fill = figma.createRectangle();
    fill.name = 'Fill';
    fill.resize((width * progress) / 100, 8);
    fill.fills = [{ type: 'SOLID', color: exports.COLORS.blue }];
    container.appendChild(fill);
    return container;
}
// ============================================================================
// Visual Effects
// ============================================================================
/**
 * Adds glassmorphic effect to modal
 * Frosted glass with subtle rim lighting
 */
function addGlassmorphicEffect(modal) {
    // Base glassmorphic layer (frosted glass)
    const glassLayer = figma.createRectangle();
    glassLayer.name = 'Glassmorphic Layer';
    glassLayer.resize(modal.width, modal.height);
    glassLayer.cornerRadius = exports.ModalTokens.radius.modal;
    glassLayer.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0.08 }];
    glassLayer.effects = [{
            type: 'BACKGROUND_BLUR',
            radius: 30,
            visible: true
        }];
    // Subtle rim gradient
    const rimLayer = figma.createRectangle();
    rimLayer.name = 'Rim Gradient';
    rimLayer.resize(modal.width, modal.height);
    rimLayer.cornerRadius = exports.ModalTokens.radius.modal;
    rimLayer.fills = [];
    rimLayer.strokes = [{
            type: 'GRADIENT_LINEAR',
            gradientTransform: [[0, 1, 0], [-1, 0, 1]],
            gradientStops: [
                { position: 0, color: { r: 1, g: 1, b: 1, a: 0.3 } },
                { position: 0.5, color: { r: 1, g: 1, b: 1, a: 0.05 } },
                { position: 1, color: { r: 1, g: 1, b: 1, a: 0.2 } }
            ]
        }];
    rimLayer.strokeWeight = 1;
    rimLayer.strokeAlign = 'INSIDE';
    // Insert as first child (behind all content)
    modal.insertChild(0, rimLayer);
    modal.insertChild(0, glassLayer);
}
// ============================================================================
// Full Modal Container
// ============================================================================
/**
 * Creates complete modal container with enhanced visual effects
 * Use this as the base for all modals
 *
 * Options:
 * - withGlassmorphic: Add frosted glass effect (default: true)
 * - withEnhancedShadow: Use elevated shadow (default: true)
 */
function createModalContainer(name, width = exports.ModalTokens.modal.widthDefault, estimatedHeight = 500, options) {
    const withGlassmorphic = (options === null || options === void 0 ? void 0 : options.withGlassmorphic) !== false;
    const withEnhancedShadow = (options === null || options === void 0 ? void 0 : options.withEnhancedShadow) !== false;
    const modal = figma.createComponent();
    modal.name = name;
    modal.layoutMode = 'VERTICAL';
    modal.paddingLeft = exports.ModalTokens.spacing.modal;
    modal.paddingRight = exports.ModalTokens.spacing.modal;
    modal.paddingTop = exports.ModalTokens.spacing.modal;
    modal.paddingBottom = exports.ModalTokens.spacing.modal;
    modal.itemSpacing = exports.ModalTokens.spacing.sectionGap;
    modal.primaryAxisSizingMode = 'AUTO';
    modal.counterAxisSizingMode = 'FIXED';
    modal.resize(width, estimatedHeight);
    modal.cornerRadius = exports.ModalTokens.radius.modal;
    modal.fills = [{ type: 'SOLID', color: exports.COLORS.white }];
    // Enhanced shadow with multiple layers for depth
    if (withEnhancedShadow) {
        modal.effects = [
            // Ambient shadow (large, soft)
            {
                type: 'DROP_SHADOW',
                color: { r: 0, g: 0, b: 0, a: 0.15 },
                offset: { x: 0, y: 20 },
                radius: 40,
                spread: 0,
                visible: true,
                blendMode: 'NORMAL'
            },
            // Direct shadow (smaller, sharper)
            {
                type: 'DROP_SHADOW',
                color: { r: 0, g: 0, b: 0, a: 0.12 },
                offset: { x: 0, y: 8 },
                radius: 16,
                spread: -2,
                visible: true,
                blendMode: 'NORMAL'
            }
        ];
    }
    else {
        // Standard iOS modal shadow
        modal.effects = [{
                type: 'DROP_SHADOW',
                color: { r: 0, g: 0, b: 0, a: 0.25 },
                offset: { x: 0, y: 8 },
                radius: 24,
                spread: 0,
                visible: true,
                blendMode: 'NORMAL'
            }];
    }
    // Add glassmorphic effect if requested
    if (withGlassmorphic) {
        // We'll add this after all content is added
        // For now, just mark it for later addition
        modal._needsGlassmorphic = true;
    }
    return modal;
}
/**
 * Finalizes modal with glassmorphic effects
 * Call this after all content has been added to the modal
 */
function finalizeModalWithEffects(modal) {
    if (modal._needsGlassmorphic) {
        addGlassmorphicEffect(modal);
        delete modal._needsGlassmorphic;
    }
}

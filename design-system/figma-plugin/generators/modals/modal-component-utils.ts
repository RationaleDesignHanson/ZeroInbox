/**
 * Modal Component Utilities
 *
 * Shared generator functions for building action modals efficiently.
 * Prevents code duplication and ensures consistency across all 46 modals.
 *
 * Based on iOS DesignTokens.swift for dimensional accuracy.
 * Follows design system best practices from architecture review.
 */

// ============================================================================
// Design Tokens (from iOS DesignTokens.swift)
// ============================================================================

export const ModalTokens = {
  spacing: {
    modal: 24,           // Modal container padding
    card: 16,            // Card/section padding
    buttonHorizontal: 20,
    buttonVertical: 12,
    inputHorizontal: 12,
    inputVertical: 10,
    itemGap: 12,         // Gap between items in auto-layout
    sectionGap: 20       // Gap between major sections
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

export const COLORS = {
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

export async function createText(
  content: string,
  fontSize: number,
  weight: string = 'Regular'
): Promise<TextNode> {
  const text = figma.createText();
  await figma.loadFontAsync({ family: 'Inter', style: weight });
  text.fontName = { family: 'Inter', style: weight };
  text.characters = content;
  text.fontSize = fontSize;
  return text;
}

export function createAutoLayoutFrame(
  name: string,
  direction: 'HORIZONTAL' | 'VERTICAL',
  spacing: number,
  padding: number | { left: number; right: number; top: number; bottom: number }
): FrameNode {
  const frame = figma.createFrame();
  frame.name = name;
  frame.layoutMode = direction;
  frame.itemSpacing = spacing;

  if (typeof padding === 'number') {
    frame.paddingLeft = padding;
    frame.paddingRight = padding;
    frame.paddingTop = padding;
    frame.paddingBottom = padding;
  } else {
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
export async function createModalHeader(
  title: string,
  width: number = 432
): Promise<FrameNode> {
  const header = createAutoLayoutFrame('Header', 'HORIZONTAL', ModalTokens.spacing.itemGap, 0);
  header.primaryAxisSizingMode = 'FIXED';
  header.counterAxisSizingMode = 'AUTO';
  header.primaryAxisAlignItems = 'SPACE_BETWEEN';
  header.counterAxisAlignItems = 'CENTER';
  header.resize(width, 32);

  const titleText = await createText(title, ModalTokens.fontSize.modalTitle, 'Semi Bold');
  titleText.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  header.appendChild(titleText);

  const closeBtn = await createText('×', ModalTokens.fontSize.closeButton, 'Regular');
  closeBtn.fills = [{ type: 'SOLID', color: COLORS.gray600 }];
  header.appendChild(closeBtn);

  return header;
}

/**
 * Creates context header with icon/avatar, title, and subtitle
 * Used for email info, document details, etc.
 */
export async function createContextHeader(config: {
  avatar?: boolean;
  icon?: string;
  title: string;
  subtitle?: string;
  width?: number;
  backgroundColor?: RGB;
}): Promise<FrameNode> {
  const width = config.width || 432;
  const header = createAutoLayoutFrame(
    'Context Header',
    'HORIZONTAL',
    ModalTokens.spacing.itemGap,
    ModalTokens.spacing.card
  );
  header.primaryAxisSizingMode = 'FIXED';
  header.counterAxisSizingMode = 'AUTO';
  header.counterAxisAlignItems = 'CENTER';
  header.resize(width, config.subtitle ? 64 : 56);
  header.fills = [{ type: 'SOLID', color: config.backgroundColor || COLORS.gray50 }];
  header.cornerRadius = ModalTokens.radius.input;

  // Avatar or icon
  if (config.avatar) {
    const avatar = figma.createRectangle();
    avatar.name = 'Avatar';
    avatar.resize(40, 40);
    avatar.cornerRadius = 20;
    avatar.fills = [{ type: 'SOLID', color: COLORS.blue }];
    header.appendChild(avatar);
  } else if (config.icon) {
    const icon = await createText(config.icon, 24, 'Regular');
    header.appendChild(icon);
  }

  // Text content
  const textContainer = createAutoLayoutFrame('Info', 'VERTICAL', 4, 0);

  const titleText = await createText(config.title, ModalTokens.fontSize.body, 'Semi Bold');
  titleText.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  textContainer.appendChild(titleText);

  if (config.subtitle) {
    const subtitleText = await createText(config.subtitle, ModalTokens.fontSize.caption, 'Regular');
    subtitleText.fills = [{ type: 'SOLID', color: COLORS.gray600 }];
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
export async function createPrimaryButton(
  label: string,
  width?: number
): Promise<FrameNode> {
  const button = figma.createFrame();
  button.name = label;
  button.layoutMode = 'HORIZONTAL';
  button.paddingLeft = ModalTokens.spacing.buttonHorizontal;
  button.paddingRight = ModalTokens.spacing.buttonHorizontal;
  button.paddingTop = ModalTokens.spacing.buttonVertical;
  button.paddingBottom = ModalTokens.spacing.buttonVertical;
  button.primaryAxisSizingMode = width ? 'FIXED' : 'AUTO';
  button.counterAxisSizingMode = 'AUTO';
  button.primaryAxisAlignItems = 'CENTER';
  button.counterAxisAlignItems = 'CENTER';
  if (width) button.resize(width, 44);
  button.cornerRadius = ModalTokens.radius.button;

  // Purple-blue gradient
  button.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [[1, 0, 0], [0, 1, 0]],
    gradientStops: [
      { position: 0, color: { r: 0.40, g: 0.49, b: 0.92, a: 1 } },  // Blue
      { position: 1, color: { r: 0.46, g: 0.29, b: 0.64, a: 1 } }   // Purple
    ]
  }];

  const text = await createText(label, ModalTokens.fontSize.body, 'Semi Bold');
  text.fills = [{ type: 'SOLID', color: COLORS.white }];
  button.appendChild(text);

  return button;
}

/**
 * Creates secondary gray button
 * Matches iOS ButtonSecondaryGlass
 */
export async function createSecondaryButton(
  label: string,
  width?: number
): Promise<FrameNode> {
  const button = figma.createFrame();
  button.name = label;
  button.layoutMode = 'HORIZONTAL';
  button.paddingLeft = ModalTokens.spacing.buttonHorizontal;
  button.paddingRight = ModalTokens.spacing.buttonHorizontal;
  button.paddingTop = ModalTokens.spacing.buttonVertical;
  button.paddingBottom = ModalTokens.spacing.buttonVertical;
  button.primaryAxisSizingMode = width ? 'FIXED' : 'AUTO';
  button.counterAxisSizingMode = 'AUTO';
  button.primaryAxisAlignItems = 'CENTER';
  button.counterAxisAlignItems = 'CENTER';
  if (width) button.resize(width, 44);
  button.cornerRadius = ModalTokens.radius.button;
  button.fills = [{ type: 'SOLID', color: COLORS.gray200 }];

  const text = await createText(label, ModalTokens.fontSize.body, 'Medium');
  text.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  button.appendChild(text);

  return button;
}

/**
 * Creates destructive red button
 * For delete, cancel, unsubscribe actions
 */
export async function createDestructiveButton(
  label: string,
  width?: number
): Promise<FrameNode> {
  const button = figma.createFrame();
  button.name = label;
  button.layoutMode = 'HORIZONTAL';
  button.paddingLeft = ModalTokens.spacing.buttonHorizontal;
  button.paddingRight = ModalTokens.spacing.buttonHorizontal;
  button.paddingTop = ModalTokens.spacing.buttonVertical;
  button.paddingBottom = ModalTokens.spacing.buttonVertical;
  button.primaryAxisSizingMode = width ? 'FIXED' : 'AUTO';
  button.counterAxisSizingMode = 'AUTO';
  button.primaryAxisAlignItems = 'CENTER';
  button.counterAxisAlignItems = 'CENTER';
  if (width) button.resize(width, 44);
  button.cornerRadius = ModalTokens.radius.button;
  button.fills = [{ type: 'SOLID', color: COLORS.red }];

  const text = await createText(label, ModalTokens.fontSize.body, 'Semi Bold');
  text.fills = [{ type: 'SOLID', color: COLORS.white }];
  button.appendChild(text);

  return button;
}

/**
 * Creates text-only button (for "Clear", "Learn More", etc.)
 */
export async function createTextButton(
  label: string,
  color: RGB = COLORS.blue
): Promise<FrameNode> {
  const button = createAutoLayoutFrame('Text Button', 'HORIZONTAL', 0, {
    left: ModalTokens.spacing.card,
    right: ModalTokens.spacing.card,
    top: 8,
    bottom: 8
  });
  button.fills = [];

  const text = await createText(label, ModalTokens.fontSize.caption, 'Medium');
  text.fills = [{ type: 'SOLID', color }];
  button.appendChild(text);

  return button;
}

/**
 * Creates action button row (cancel + primary)
 * Standard modal footer pattern
 */
export async function createActionButtons(config: {
  cancel: string;
  primary: string;
  width: number;
  destructive?: boolean;
}): Promise<FrameNode> {
  const actions = createAutoLayoutFrame(
    'Actions',
    'HORIZONTAL',
    ModalTokens.spacing.itemGap,
    0
  );
  actions.primaryAxisSizingMode = 'FIXED';
  actions.counterAxisSizingMode = 'AUTO';
  actions.primaryAxisAlignItems = 'SPACE_BETWEEN';
  actions.resize(config.width, 44);

  actions.appendChild(await createSecondaryButton(config.cancel));
  actions.appendChild(config.destructive
    ? await createDestructiveButton(config.primary)
    : await createPrimaryButton(config.primary)
  );

  return actions;
}

// ============================================================================
// Form Components
// ============================================================================

/**
 * Creates text input field with label
 * Matches iOS FormTextInput
 */
export async function createFormTextInput(
  label: string,
  placeholder: string,
  width: number = 432,
  defaultValue?: string
): Promise<FrameNode> {
  const field = createAutoLayoutFrame('Input Field', 'VERTICAL', 8, 0);
  field.primaryAxisSizingMode = 'FIXED';
  field.resize(width, 70);

  const labelText = await createText(label, ModalTokens.fontSize.label, 'Medium');
  labelText.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  field.appendChild(labelText);

  const input = figma.createFrame();
  input.name = 'Input';
  input.layoutMode = 'VERTICAL';
  input.paddingLeft = ModalTokens.spacing.inputHorizontal;
  input.paddingRight = ModalTokens.spacing.inputHorizontal;
  input.paddingTop = ModalTokens.spacing.inputVertical;
  input.paddingBottom = ModalTokens.spacing.inputVertical;
  input.primaryAxisSizingMode = 'FIXED';
  input.counterAxisSizingMode = 'AUTO';
  input.resize(width, 44);
  input.cornerRadius = ModalTokens.radius.input;
  input.fills = [{ type: 'SOLID', color: COLORS.white }];
  input.strokes = [{ type: 'SOLID', color: COLORS.gray300 }];
  input.strokeWeight = 1;

  const valueText = await createText(
    defaultValue || placeholder,
    ModalTokens.fontSize.body,
    'Regular'
  );
  valueText.fills = [{
    type: 'SOLID',
    color: defaultValue ? COLORS.gray900 : COLORS.gray400
  }];
  input.appendChild(valueText);

  field.appendChild(input);
  return field;
}

/**
 * Creates textarea field for multi-line input
 * Matches iOS FormTextArea
 */
export async function createFormTextArea(
  label: string,
  placeholder: string,
  width: number = 432,
  height: number = 140
): Promise<FrameNode> {
  const field = createAutoLayoutFrame('Textarea Field', 'VERTICAL', 8, 0);
  field.primaryAxisSizingMode = 'FIXED';
  field.resize(width, height + 30);

  const labelText = await createText(label, ModalTokens.fontSize.label, 'Medium');
  labelText.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  field.appendChild(labelText);

  const textarea = figma.createFrame();
  textarea.name = 'Textarea';
  textarea.layoutMode = 'VERTICAL';
  textarea.paddingLeft = ModalTokens.spacing.inputHorizontal;
  textarea.paddingRight = ModalTokens.spacing.inputHorizontal;
  textarea.paddingTop = ModalTokens.spacing.inputVertical;
  textarea.paddingBottom = ModalTokens.spacing.inputVertical;
  textarea.primaryAxisSizingMode = 'FIXED';
  textarea.counterAxisSizingMode = 'FIXED';
  textarea.resize(width, height);
  textarea.cornerRadius = ModalTokens.radius.input;
  textarea.fills = [{ type: 'SOLID', color: COLORS.white }];
  textarea.strokes = [{ type: 'SOLID', color: COLORS.gray300 }];
  textarea.strokeWeight = 1;

  const placeholderText = await createText(placeholder, ModalTokens.fontSize.body, 'Regular');
  placeholderText.fills = [{ type: 'SOLID', color: COLORS.gray400 }];
  textarea.appendChild(placeholderText);

  field.appendChild(textarea);
  return field;
}

/**
 * Creates dropdown/select field
 * Matches iOS FormDropdown
 */
export async function createFormDropdown(
  label: string,
  value: string,
  width: number = 432
): Promise<FrameNode> {
  const field = createAutoLayoutFrame('Dropdown Field', 'VERTICAL', 8, 0);
  field.primaryAxisSizingMode = 'FIXED';
  field.resize(width, 70);

  const labelText = await createText(label, ModalTokens.fontSize.label, 'Medium');
  labelText.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  field.appendChild(labelText);

  const dropdown = figma.createFrame();
  dropdown.name = 'Dropdown';
  dropdown.layoutMode = 'HORIZONTAL';
  dropdown.paddingLeft = ModalTokens.spacing.inputHorizontal;
  dropdown.paddingRight = ModalTokens.spacing.inputHorizontal;
  dropdown.paddingTop = ModalTokens.spacing.inputVertical;
  dropdown.paddingBottom = ModalTokens.spacing.inputVertical;
  dropdown.itemSpacing = 8;
  dropdown.primaryAxisSizingMode = 'FIXED';
  dropdown.counterAxisSizingMode = 'AUTO';
  dropdown.primaryAxisAlignItems = 'SPACE_BETWEEN';
  dropdown.counterAxisAlignItems = 'CENTER';
  dropdown.resize(width, 44);
  dropdown.cornerRadius = ModalTokens.radius.input;
  dropdown.fills = [{ type: 'SOLID', color: COLORS.white }];
  dropdown.strokes = [{ type: 'SOLID', color: COLORS.gray300 }];
  dropdown.strokeWeight = 1;

  const valueText = await createText(value, ModalTokens.fontSize.body, 'Regular');
  valueText.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  dropdown.appendChild(valueText);

  const chevron = await createText('▼', 12, 'Regular');
  chevron.fills = [{ type: 'SOLID', color: COLORS.gray600 }];
  dropdown.appendChild(chevron);

  field.appendChild(dropdown);
  return field;
}

/**
 * Creates date picker field
 * Matches iOS FormDatePicker
 */
export async function createFormDatePicker(
  label: string,
  value: string,
  icon: string = '📅',
  width: number = 432
): Promise<FrameNode> {
  const field = createAutoLayoutFrame('Date Field', 'VERTICAL', 8, 0);
  field.primaryAxisSizingMode = 'FIXED';
  field.resize(width, 70);

  const labelText = await createText(label, ModalTokens.fontSize.label, 'Medium');
  labelText.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  field.appendChild(labelText);

  const picker = figma.createFrame();
  picker.name = 'Date Picker';
  picker.layoutMode = 'HORIZONTAL';
  picker.paddingLeft = ModalTokens.spacing.inputHorizontal;
  picker.paddingRight = ModalTokens.spacing.inputHorizontal;
  picker.paddingTop = ModalTokens.spacing.inputVertical;
  picker.paddingBottom = ModalTokens.spacing.inputVertical;
  picker.itemSpacing = 8;
  picker.primaryAxisSizingMode = 'FIXED';
  picker.counterAxisSizingMode = 'AUTO';
  picker.primaryAxisAlignItems = 'SPACE_BETWEEN';
  picker.counterAxisAlignItems = 'CENTER';
  picker.resize(width, 44);
  picker.cornerRadius = ModalTokens.radius.input;
  picker.fills = [{ type: 'SOLID', color: COLORS.white }];
  picker.strokes = [{ type: 'SOLID', color: COLORS.gray300 }];
  picker.strokeWeight = 1;

  const valueText = await createText(value, ModalTokens.fontSize.body, 'Regular');
  valueText.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
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
export async function createFormToggle(
  label: string,
  enabled: boolean = true,
  width: number = 432
): Promise<FrameNode> {
  const field = createAutoLayoutFrame('Toggle Field', 'HORIZONTAL', ModalTokens.spacing.itemGap, 0);
  field.primaryAxisSizingMode = 'FIXED';
  field.counterAxisSizingMode = 'AUTO';
  field.primaryAxisAlignItems = 'SPACE_BETWEEN';
  field.counterAxisAlignItems = 'CENTER';
  field.resize(width, 44);

  const labelText = await createText(label, ModalTokens.fontSize.body, 'Regular');
  labelText.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  field.appendChild(labelText);

  // Toggle track
  const toggle = figma.createFrame();
  toggle.name = 'Toggle';
  toggle.resize(44, 24);
  toggle.cornerRadius = 12;
  toggle.fills = [{ type: 'SOLID', color: enabled ? COLORS.blue : COLORS.gray300 }];
  toggle.clipsContent = false;

  // Toggle knob
  const knob = figma.createEllipse();
  knob.resize(20, 20);
  knob.x = enabled ? 22 : 2;
  knob.y = 2;
  knob.fills = [{ type: 'SOLID', color: COLORS.white }];
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
export async function createDetailRow(
  label: string,
  value: string,
  width: number = 432,
  bold: boolean = false
): Promise<FrameNode> {
  const row = createAutoLayoutFrame('Detail Row', 'HORIZONTAL', ModalTokens.spacing.itemGap, 0);
  row.primaryAxisSizingMode = 'FIXED';
  row.counterAxisSizingMode = 'AUTO';
  row.primaryAxisAlignItems = 'SPACE_BETWEEN';
  row.resize(width, 24);

  const labelText = await createText(
    label,
    ModalTokens.fontSize.body,
    bold ? 'Semi Bold' : 'Regular'
  );
  labelText.fills = [{ type: 'SOLID', color: COLORS.gray600 }];
  row.appendChild(labelText);

  const valueText = await createText(
    value,
    ModalTokens.fontSize.body,
    bold ? 'Bold' : 'Semi Bold'
  );
  valueText.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  row.appendChild(valueText);

  return row;
}

/**
 * Creates divider line
 */
export function createDivider(width: number = 432): RectangleNode {
  const divider = figma.createRectangle();
  divider.name = 'Divider';
  divider.resize(width, 1);
  divider.fills = [{ type: 'SOLID', color: COLORS.gray200 }];
  return divider;
}

/**
 * Creates signature canvas placeholder
 * Dashed border, centered placeholder text
 */
export async function createSignatureCanvas(
  width: number = 432,
  height: number = 180
): Promise<FrameNode> {
  const canvas = figma.createFrame();
  canvas.name = 'Signature Canvas';
  canvas.layoutMode = 'VERTICAL';
  canvas.primaryAxisSizingMode = 'FIXED';
  canvas.counterAxisSizingMode = 'FIXED';
  canvas.primaryAxisAlignItems = 'CENTER';
  canvas.counterAxisAlignItems = 'CENTER';
  canvas.resize(width, height);
  canvas.cornerRadius = ModalTokens.radius.input;
  canvas.fills = [{ type: 'SOLID', color: COLORS.gray50 }];
  canvas.strokes = [{ type: 'SOLID', color: COLORS.gray300, opacity: 0.5 }];
  canvas.strokeWeight = 1;
  canvas.strokeAlign = 'INSIDE';
  canvas.dashPattern = [4, 4];

  const placeholder = await createText('Sign here', ModalTokens.fontSize.body, 'Regular');
  placeholder.fills = [{ type: 'SOLID', color: COLORS.gray400 }];
  placeholder.textAlignHorizontal = 'CENTER';
  placeholder.textAlignVertical = 'CENTER';
  canvas.appendChild(placeholder);

  return canvas;
}

/**
 * Creates status banner
 * Success, error, warning variants
 */
export async function createStatusBanner(
  message: string,
  type: 'success' | 'error' | 'warning',
  width: number = 432
): Promise<FrameNode> {
  const colors = {
    success: { bg: COLORS.greenBg, text: COLORS.green, icon: '✓' },
    error: { bg: COLORS.redBg, text: COLORS.red, icon: '✕' },
    warning: { bg: COLORS.yellowBg, text: COLORS.yellow, icon: '⚠' }
  };
  const config = colors[type];

  const banner = createAutoLayoutFrame(
    'Status Banner',
    'HORIZONTAL',
    ModalTokens.spacing.itemGap,
    ModalTokens.spacing.card
  );
  banner.primaryAxisSizingMode = 'FIXED';
  banner.counterAxisSizingMode = 'AUTO';
  banner.counterAxisAlignItems = 'CENTER';
  banner.resize(width, 48);
  banner.fills = [{ type: 'SOLID', color: config.bg }];
  banner.cornerRadius = ModalTokens.radius.input;

  const icon = await createText(config.icon, 18, 'Regular');
  icon.fills = [{ type: 'SOLID', color: config.text }];
  banner.appendChild(icon);

  const text = await createText(message, ModalTokens.fontSize.body, 'Medium');
  text.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  banner.appendChild(text);

  return banner;
}

/**
 * Creates progress bar
 */
export async function createProgressBar(
  progress: number,  // 0-100
  width: number = 432
): Promise<FrameNode> {
  const container = figma.createFrame();
  container.name = 'Progress Bar';
  container.resize(width, 8);
  container.cornerRadius = 4;
  container.fills = [{ type: 'SOLID', color: COLORS.gray200 }];
  container.clipsContent = true;

  const fill = figma.createRectangle();
  fill.name = 'Fill';
  fill.resize((width * progress) / 100, 8);
  fill.fills = [{ type: 'SOLID', color: COLORS.blue }];
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
function addGlassmorphicEffect(modal: ComponentNode): void {
  // Base glassmorphic layer (frosted glass)
  const glassLayer = figma.createRectangle();
  glassLayer.name = 'Glassmorphic Layer';
  glassLayer.resize(modal.width, modal.height);
  glassLayer.cornerRadius = ModalTokens.radius.modal;
  glassLayer.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0.08 }];
  glassLayer.effects = [{
    type: 'BACKGROUND_BLUR',
    radius: 30,
    visible: true
  } as any];

  // Subtle rim gradient
  const rimLayer = figma.createRectangle();
  rimLayer.name = 'Rim Gradient';
  rimLayer.resize(modal.width, modal.height);
  rimLayer.cornerRadius = ModalTokens.radius.modal;
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
export function createModalContainer(
  name: string,
  width: number = ModalTokens.modal.widthDefault,
  estimatedHeight: number = 500,
  options?: {
    withGlassmorphic?: boolean;
    withEnhancedShadow?: boolean;
  }
): ComponentNode {
  const withGlassmorphic = options?.withGlassmorphic !== false;
  const withEnhancedShadow = options?.withEnhancedShadow !== false;

  const modal = figma.createComponent();
  modal.name = name;
  modal.layoutMode = 'VERTICAL';
  modal.paddingLeft = ModalTokens.spacing.modal;
  modal.paddingRight = ModalTokens.spacing.modal;
  modal.paddingTop = ModalTokens.spacing.modal;
  modal.paddingBottom = ModalTokens.spacing.modal;
  modal.itemSpacing = ModalTokens.spacing.sectionGap;
  modal.primaryAxisSizingMode = 'AUTO';
  modal.counterAxisSizingMode = 'FIXED';
  modal.resize(width, estimatedHeight);
  modal.cornerRadius = ModalTokens.radius.modal;
  modal.fills = [{ type: 'SOLID', color: COLORS.white }];

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
  } else {
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
    (modal as any)._needsGlassmorphic = true;
  }

  return modal;
}

/**
 * Finalizes modal with glassmorphic effects
 * Call this after all content has been added to the modal
 */
export function finalizeModalWithEffects(modal: ComponentNode): void {
  if ((modal as any)._needsGlassmorphic) {
    addGlassmorphicEffect(modal);
    delete (modal as any)._needsGlassmorphic;
  }
}

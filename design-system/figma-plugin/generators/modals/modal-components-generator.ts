/**
 * Modal Components Generator
 *
 * Generates 22 shared modal components used across all 46 action modals:
 * - Modal structure (headers, containers)
 * - Form components (inputs, dropdowns, toggles)
 * - Button variants (gradient, glass, destructive)
 * - Status components (banners, loading, countdown)
 * - Content components (detail rows, progress, signatures)
 *
 * iOS Source: /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Views/ActionModules/
 */

// MARK: - Helper Functions

async function createText(content: string, fontSize: number, weight: string = 'Regular'): Promise<TextNode> {
  const text = figma.createText();
  await figma.loadFontAsync({ family: 'Inter', style: weight });
  text.fontName = { family: 'Inter', style: weight };
  text.characters = content;
  text.fontSize = fontSize;
  return text;
}

function createAutoLayoutFrame(name: string, direction: 'HORIZONTAL' | 'VERTICAL', spacing: number, padding: number): FrameNode {
  const frame = figma.createFrame();
  frame.name = name;
  frame.layoutMode = direction;
  frame.itemSpacing = spacing;
  frame.paddingLeft = padding;
  frame.paddingRight = padding;
  frame.paddingTop = padding;
  frame.paddingBottom = padding;
  frame.primaryAxisSizingMode = 'AUTO';
  frame.counterAxisSizingMode = 'AUTO';
  return frame;
}

const COLORS = {
  blue: { r: 0.23, g: 0.51, b: 0.96 },
  gray200: { r: 0.90, g: 0.91, b: 0.92 },
  gray300: { r: 0.82, g: 0.84, b: 0.86 },
  gray400: { r: 0.63, g: 0.65, b: 0.67 },
  gray600: { r: 0.45, g: 0.47, b: 0.49 },
  gray900: { r: 0.07, g: 0.09, b: 0.15 },
  red: { r: 0.94, g: 0.27, b: 0.27 },
  green: { r: 0.06, g: 0.73, b: 0.51 },
  greenBg: { r: 0.94, g: 0.99, b: 0.96 },
  yellow: { r: 0.96, g: 0.62, b: 0.04 },
  yellowBg: { r: 0.99, g: 0.99, b: 0.91 },
  white: { r: 1, g: 1, b: 1 },
  black: { r: 0, g: 0, b: 0 }
};

// MARK: - Modal Structure Components

/**
 * ModalHeader Component
 * Used in: All 46 modals
 * Structure: Title + Close button
 */
async function createModalHeader(): Promise<ComponentNode> {
  const component = figma.createComponent();
  component.name = 'ModalHeader';

  component.layoutMode = 'HORIZONTAL';
  component.paddingLeft = 24;
  component.paddingRight = 24;
  component.paddingTop = 20;
  component.paddingBottom = 20;
  component.itemSpacing = 12;
  component.primaryAxisSizingMode = 'FIXED';
  component.counterAxisSizingMode = 'AUTO';
  component.primaryAxisAlignItems = 'SPACE_BETWEEN';
  component.counterAxisAlignItems = 'CENTER';
  component.resize(480, 64);
  component.fills = [{ type: 'SOLID', color: COLORS.white }];

  // Title
  const title = await createText('Modal Title', 20, 'Semi Bold');
  title.name = 'Title';
  title.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  component.appendChild(title);

  // Close button
  const closeBtn = figma.createFrame();
  closeBtn.name = 'Close Button';
  closeBtn.layoutMode = 'HORIZONTAL';
  closeBtn.paddingLeft = 8;
  closeBtn.paddingRight = 8;
  closeBtn.paddingTop = 8;
  closeBtn.paddingBottom = 8;
  closeBtn.primaryAxisSizingMode = 'AUTO';
  closeBtn.counterAxisSizingMode = 'AUTO';
  closeBtn.cornerRadius = 8;
  closeBtn.fills = [];

  const closeIcon = await createText('×', 24, 'Regular');
  closeIcon.fills = [{ type: 'SOLID', color: COLORS.gray600 }];
  closeBtn.appendChild(closeIcon);
  component.appendChild(closeBtn);

  return component;
}

/**
 * ModalContextHeader Component
 * Used in: Contextual modals (email, shopping, etc.)
 * Structure: Icon + Title + Subtitle
 */
async function createModalContextHeader(): Promise<ComponentNode> {
  const component = figma.createComponent();
  component.name = 'ModalContextHeader';

  component.layoutMode = 'HORIZONTAL';
  component.paddingLeft = 24;
  component.paddingRight = 24;
  component.paddingTop = 16;
  component.paddingBottom = 16;
  component.itemSpacing = 16;
  component.primaryAxisSizingMode = 'FIXED';
  component.counterAxisSizingMode = 'AUTO';
  component.counterAxisAlignItems = 'CENTER';
  component.resize(480, 80);
  component.fills = [{ type: 'SOLID', color: { r: 0.98, g: 0.98, b: 0.98 } }];

  // Icon placeholder
  const icon = figma.createRectangle();
  icon.name = 'Icon';
  icon.resize(48, 48);
  icon.cornerRadius = 12;
  icon.fills = [{ type: 'SOLID', color: COLORS.blue }];
  component.appendChild(icon);

  // Text content
  const textFrame = figma.createFrame();
  textFrame.name = 'Text Content';
  textFrame.layoutMode = 'VERTICAL';
  textFrame.itemSpacing = 4;
  textFrame.primaryAxisSizingMode = 'AUTO';
  textFrame.counterAxisSizingMode = 'AUTO';
  textFrame.fills = [];

  const title = await createText('sender@example.com', 17, 'Semi Bold');
  title.name = 'Title';
  title.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  textFrame.appendChild(title);

  const subtitle = await createText('Quick Reply', 13, 'Regular');
  subtitle.name = 'Subtitle';
  subtitle.fills = [{ type: 'SOLID', color: COLORS.gray600 }];
  textFrame.appendChild(subtitle);

  component.appendChild(textFrame);

  return component;
}

/**
 * ModalContainer Component
 * Used in: All modals as base container
 * Structure: Auto layout frame with padding + corner radius
 */
function createModalContainer(): ComponentNode {
  const component = figma.createComponent();
  component.name = 'ModalContainer';

  component.layoutMode = 'VERTICAL';
  component.paddingLeft = 24;
  component.paddingRight = 24;
  component.paddingTop = 24;
  component.paddingBottom = 24;
  component.itemSpacing = 20;
  component.primaryAxisSizingMode = 'AUTO';
  component.counterAxisSizingMode = 'FIXED';
  component.resize(480, 400);
  component.cornerRadius = 20;
  component.fills = [{ type: 'SOLID', color: COLORS.white }];

  // Drop shadow
  component.effects = [{
    type: 'DROP_SHADOW',
    color: { r: 0, g: 0, b: 0, a: 0.25 },
    offset: { x: 0, y: 8 },
    radius: 24,
    spread: 0,
    visible: true,
    blendMode: 'NORMAL'
  }];

  return component;
}

// MARK: - Form Components

/**
 * FormTextInput Component
 * Used in: 30+ modals with text input
 * Variants: Default, Focused, Error
 */
async function createFormTextInputVariants(): Promise<ComponentSetNode> {
  const states = [
    { name: 'Default', border: COLORS.gray300 },
    { name: 'Focused', border: COLORS.blue },
    { name: 'Error', border: COLORS.red }
  ];

  const components: ComponentNode[] = [];

  for (const state of states) {
    const component = figma.createComponent();
    component.name = `State=${state.name}`;

    component.layoutMode = 'VERTICAL';
    component.paddingLeft = 12;
    component.paddingRight = 12;
    component.paddingTop = 10;
    component.paddingBottom = 10;
    component.itemSpacing = 4;
    component.primaryAxisSizingMode = 'FIXED';
    component.counterAxisSizingMode = 'AUTO';
    component.resize(432, 44);
    component.cornerRadius = 8;
    component.fills = [{ type: 'SOLID', color: COLORS.white }];
    component.strokes = [{ type: 'SOLID', color: state.border }];
    component.strokeWeight = 1;

    const placeholder = await createText('Enter text...', 15, 'Regular');
    placeholder.name = 'Placeholder';
    placeholder.fills = [{ type: 'SOLID', color: COLORS.gray400 }];
    component.appendChild(placeholder);

    components.push(component);
  }

  components.forEach(comp => figma.currentPage.appendChild(comp));
  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'FormTextInput';

  return componentSet;
}

/**
 * FormTextArea Component
 * Used in: Reply, compose, review modals
 * Multi-line text input
 */
async function createFormTextArea(): Promise<ComponentNode> {
  const component = figma.createComponent();
  component.name = 'FormTextArea';

  component.layoutMode = 'VERTICAL';
  component.paddingLeft = 12;
  component.paddingRight = 12;
  component.paddingTop = 10;
  component.paddingBottom = 10;
  component.itemSpacing = 4;
  component.primaryAxisSizingMode = 'FIXED';
  component.counterAxisSizingMode = 'FIXED';
  component.resize(432, 120);
  component.cornerRadius = 8;
  component.fills = [{ type: 'SOLID', color: COLORS.white }];
  component.strokes = [{ type: 'SOLID', color: COLORS.gray300 }];
  component.strokeWeight = 1;

  const placeholder = await createText('Enter message...', 15, 'Regular');
  placeholder.name = 'Placeholder';
  placeholder.fills = [{ type: 'SOLID', color: COLORS.gray400 }];
  component.appendChild(placeholder);

  return component;
}

/**
 * FormDropdown Component
 * Used in: Time selection, category selection, etc.
 */
async function createFormDropdown(): Promise<ComponentNode> {
  const component = figma.createComponent();
  component.name = 'FormDropdown';

  component.layoutMode = 'HORIZONTAL';
  component.paddingLeft = 12;
  component.paddingRight = 12;
  component.paddingTop = 10;
  component.paddingBottom = 10;
  component.itemSpacing = 8;
  component.primaryAxisSizingMode = 'FIXED';
  component.counterAxisSizingMode = 'AUTO';
  component.primaryAxisAlignItems = 'SPACE_BETWEEN';
  component.counterAxisAlignItems = 'CENTER';
  component.resize(432, 44);
  component.cornerRadius = 8;
  component.fills = [{ type: 'SOLID', color: COLORS.white }];
  component.strokes = [{ type: 'SOLID', color: COLORS.gray300 }];
  component.strokeWeight = 1;

  const label = await createText('Select option', 15, 'Regular');
  label.name = 'Label';
  label.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  component.appendChild(label);

  const chevron = await createText('▼', 12, 'Regular');
  chevron.name = 'Chevron';
  chevron.fills = [{ type: 'SOLID', color: COLORS.gray600 }];
  component.appendChild(chevron);

  return component;
}

/**
 * FormToggle Component
 * Used in: Settings, preferences, enable/disable options
 */
function createFormToggle(): ComponentNode {
  const component = figma.createComponent();
  component.name = 'FormToggle';

  component.layoutMode = 'HORIZONTAL';
  component.itemSpacing = 12;
  component.primaryAxisSizingMode = 'AUTO';
  component.counterAxisSizingMode = 'AUTO';
  component.counterAxisAlignItems = 'CENTER';
  component.fills = [];

  // Toggle track (use frame so we can add knob)
  const track = figma.createFrame();
  track.name = 'Track';
  track.resize(44, 24);
  track.cornerRadius = 12;
  track.fills = [{ type: 'SOLID', color: COLORS.blue }];
  track.clipsContent = false;

  // Toggle knob
  const knob = figma.createEllipse();
  knob.name = 'Knob';
  knob.resize(20, 20);
  knob.x = 22;
  knob.y = 2;
  knob.fills = [{ type: 'SOLID', color: COLORS.white }];
  track.appendChild(knob);

  component.appendChild(track);

  return component;
}

/**
 * FormDatePicker Component
 * Used in: Calendar, scheduling, delivery date modals
 */
async function createFormDatePicker(): Promise<ComponentNode> {
  const component = figma.createComponent();
  component.name = 'FormDatePicker';

  component.layoutMode = 'HORIZONTAL';
  component.paddingLeft = 12;
  component.paddingRight = 12;
  component.paddingTop = 10;
  component.paddingBottom = 10;
  component.itemSpacing = 8;
  component.primaryAxisSizingMode = 'FIXED';
  component.counterAxisSizingMode = 'AUTO';
  component.primaryAxisAlignItems = 'SPACE_BETWEEN';
  component.counterAxisAlignItems = 'CENTER';
  component.resize(432, 44);
  component.cornerRadius = 8;
  component.fills = [{ type: 'SOLID', color: COLORS.white }];
  component.strokes = [{ type: 'SOLID', color: COLORS.gray300 }];
  component.strokeWeight = 1;

  const date = await createText('December 2, 2024', 15, 'Regular');
  date.name = 'Date';
  date.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  component.appendChild(date);

  const icon = await createText('📅', 16, 'Regular');
  icon.name = 'Icon';
  component.appendChild(icon);

  return component;
}

// MARK: - Button Variants

/**
 * ButtonPrimaryGradient Component
 * Used in: Primary actions across all modals
 * Features: Gradient fill + holographic rim
 */
async function createButtonPrimaryGradient(): Promise<ComponentNode> {
  const component = figma.createComponent();
  component.name = 'ButtonPrimaryGradient';

  component.layoutMode = 'HORIZONTAL';
  component.paddingLeft = 20;
  component.paddingRight = 20;
  component.paddingTop = 12;
  component.paddingBottom = 12;
  component.itemSpacing = 8;
  component.primaryAxisSizingMode = 'AUTO';
  component.counterAxisSizingMode = 'AUTO';
  component.counterAxisAlignItems = 'CENTER';
  component.cornerRadius = 12;

  // Gradient fill
  component.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [[1, 0, 0], [0, 1, 0]],
    gradientStops: [
      { position: 0, color: { r: 0.40, g: 0.49, b: 0.92, a: 1 } },  // #667eea
      { position: 1, color: { r: 0.46, g: 0.29, b: 0.64, a: 1 } }   // #764ba2
    ]
  }];

  const label = await createText('Primary Action', 15, 'Semi Bold');
  label.name = 'Label';
  label.fills = [{ type: 'SOLID', color: COLORS.white }];
  component.appendChild(label);

  // Drop shadow
  component.effects = [{
    type: 'DROP_SHADOW',
    color: { r: 0, g: 0, b: 0, a: 0.15 },
    offset: { x: 0, y: 2 },
    radius: 8,
    spread: 0,
    visible: true,
    blendMode: 'NORMAL'
  }];

  return component;
}

/**
 * ButtonSecondaryGlass Component
 * Used in: Secondary actions with glassmorphic effect
 */
async function createButtonSecondaryGlass(): Promise<ComponentNode> {
  const component = figma.createComponent();
  component.name = 'ButtonSecondaryGlass';

  component.layoutMode = 'HORIZONTAL';
  component.paddingLeft = 20;
  component.paddingRight = 20;
  component.paddingTop = 12;
  component.paddingBottom = 12;
  component.itemSpacing = 8;
  component.primaryAxisSizingMode = 'AUTO';
  component.counterAxisSizingMode = 'AUTO';
  component.counterAxisAlignItems = 'CENTER';
  component.cornerRadius = 12;

  // Glass effect
  component.fills = [{
    type: 'SOLID',
    color: COLORS.white,
    opacity: 0.1
  }];

  component.strokes = [{ type: 'SOLID', color: COLORS.white, opacity: 0.3 }];
  component.strokeWeight = 1;

  const label = await createText('Secondary Action', 15, 'Medium');
  label.name = 'Label';
  label.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  component.appendChild(label);

  return component;
}

/**
 * ButtonDestructive Component
 * Used in: Delete, cancel subscription, unsubscribe actions
 */
async function createButtonDestructive(): Promise<ComponentNode> {
  const component = figma.createComponent();
  component.name = 'ButtonDestructive';

  component.layoutMode = 'HORIZONTAL';
  component.paddingLeft = 20;
  component.paddingRight = 20;
  component.paddingTop = 12;
  component.paddingBottom = 12;
  component.itemSpacing = 8;
  component.primaryAxisSizingMode = 'AUTO';
  component.counterAxisSizingMode = 'AUTO';
  component.counterAxisAlignItems = 'CENTER';
  component.cornerRadius = 12;
  component.fills = [{ type: 'SOLID', color: COLORS.red }];

  const label = await createText('Delete', 15, 'Semi Bold');
  label.name = 'Label';
  label.fills = [{ type: 'SOLID', color: COLORS.white }];
  component.appendChild(label);

  return component;
}

// MARK: - Status Components

/**
 * StatusBanner Component
 * Used in: Success, error, warning feedback
 * Variants: Success, Error, Warning
 */
async function createStatusBannerVariants(): Promise<ComponentSetNode> {
  const types = [
    { name: 'Success', bg: COLORS.greenBg, border: COLORS.green, icon: '✓' },
    { name: 'Error', bg: { r: 0.99, g: 0.95, b: 0.95 }, border: COLORS.red, icon: '×' },
    { name: 'Warning', bg: COLORS.yellowBg, border: COLORS.yellow, icon: '⚠' }
  ];

  const components: ComponentNode[] = [];

  for (const type of types) {
    const component = figma.createComponent();
    component.name = `Type=${type.name}`;

    component.layoutMode = 'HORIZONTAL';
    component.paddingLeft = 16;
    component.paddingRight = 16;
    component.paddingTop = 12;
    component.paddingBottom = 12;
    component.itemSpacing = 12;
    component.primaryAxisSizingMode = 'FIXED';
    component.counterAxisSizingMode = 'AUTO';
    component.counterAxisAlignItems = 'CENTER';
    component.resize(432, 48);
    component.cornerRadius = 8;
    component.fills = [{ type: 'SOLID', color: type.bg }];
    component.strokes = [{ type: 'SOLID', color: type.border }];
    component.strokeWeight = 1;

    const icon = await createText(type.icon, 16, 'Bold');
    icon.name = 'Icon';
    icon.fills = [{ type: 'SOLID', color: type.border }];
    component.appendChild(icon);

    const message = await createText('Status message', 14, 'Medium');
    message.name = 'Message';
    message.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
    component.appendChild(message);

    components.push(component);
  }

  components.forEach(comp => figma.currentPage.appendChild(comp));
  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'StatusBanner';

  return componentSet;
}

/**
 * LoadingSpinner Component
 * Used in: Processing actions, async operations
 */
function createLoadingSpinner(): ComponentNode {
  const component = figma.createComponent();
  component.name = 'LoadingSpinner';

  const spinner = figma.createEllipse();
  spinner.name = 'Spinner';
  spinner.resize(32, 32);
  spinner.fills = [];
  spinner.strokes = [{
    type: 'GRADIENT_ANGULAR',
    gradientTransform: [[1, 0, 0.5], [0, 1, 0.5]],
    gradientStops: [
      { position: 0, color: { ...COLORS.blue, a: 1 } },
      { position: 0.5, color: { ...COLORS.blue, a: 0.5 } },
      { position: 1, color: { ...COLORS.blue, a: 0 } }
    ]
  }];
  spinner.strokeWeight = 3;

  component.appendChild(spinner);
  component.resize(32, 32);
  component.fills = [];

  return component;
}

/**
 * CountdownTimer Component
 * Used in: Flight check-in, time-sensitive actions
 */
async function createCountdownTimer(): Promise<ComponentNode> {
  const component = figma.createComponent();
  component.name = 'CountdownTimer';

  component.layoutMode = 'HORIZONTAL';
  component.paddingLeft = 16;
  component.paddingRight = 16;
  component.paddingTop = 12;
  component.paddingBottom = 12;
  component.itemSpacing = 8;
  component.primaryAxisSizingMode = 'AUTO';
  component.counterAxisSizingMode = 'AUTO';
  component.counterAxisAlignItems = 'CENTER';
  component.cornerRadius = 8;
  component.fills = [{ type: 'SOLID', color: { r: 0.98, g: 0.98, b: 0.98 } }];

  const icon = await createText('⏱', 16, 'Regular');
  icon.name = 'Icon';
  component.appendChild(icon);

  const time = await createText('2:30:45', 17, 'Bold');
  time.name = 'Time';
  time.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  component.appendChild(time);

  return component;
}

// MARK: - Content Components

/**
 * DetailRow Component
 * Used in: Summary views, information display
 */
async function createDetailRow(): Promise<ComponentNode> {
  const component = figma.createComponent();
  component.name = 'DetailRow';

  component.layoutMode = 'HORIZONTAL';
  component.paddingLeft = 0;
  component.paddingRight = 0;
  component.paddingTop = 12;
  component.paddingBottom = 12;
  component.itemSpacing = 12;
  component.primaryAxisSizingMode = 'FIXED';
  component.counterAxisSizingMode = 'AUTO';
  component.primaryAxisAlignItems = 'SPACE_BETWEEN';
  component.counterAxisAlignItems = 'CENTER';
  component.resize(432, 40);
  component.fills = [];

  const label = await createText('Label', 14, 'Regular');
  label.name = 'Label';
  label.fills = [{ type: 'SOLID', color: COLORS.gray600 }];
  component.appendChild(label);

  const value = await createText('Value', 14, 'Medium');
  value.name = 'Value';
  value.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
  component.appendChild(value);

  return component;
}

/**
 * ProgressIndicator Component
 * Used in: Multi-step processes, form progress
 */
function createProgressIndicator(): ComponentNode {
  const component = figma.createComponent();
  component.name = 'ProgressIndicator';

  component.layoutMode = 'VERTICAL';
  component.itemSpacing = 8;
  component.primaryAxisSizingMode = 'FIXED';
  component.counterAxisSizingMode = 'AUTO';
  component.resize(432, 24);
  component.fills = [];

  // Progress bar track (use frame so we can add fill)
  const track = figma.createFrame();
  track.name = 'Track';
  track.resize(432, 8);
  track.cornerRadius = 4;
  track.fills = [{ type: 'SOLID', color: COLORS.gray200 }];
  track.clipsContent = false;

  // Progress bar fill (60% complete)
  const fill = figma.createRectangle();
  fill.name = 'Fill';
  fill.resize(259, 8);  // 60% of 432
  fill.cornerRadius = 4;
  fill.fills = [{ type: 'SOLID', color: COLORS.blue }];
  fill.constraints = { horizontal: 'MIN', vertical: 'MIN' };
  track.appendChild(fill);

  component.appendChild(track);

  return component;
}

/**
 * SignaturePreview Component
 * Used in: SignFormModal
 */
function createSignaturePreview(): ComponentNode {
  const component = figma.createComponent();
  component.name = 'SignaturePreview';

  component.layoutMode = 'VERTICAL';
  component.paddingLeft = 16;
  component.paddingRight = 16;
  component.paddingTop = 16;
  component.paddingBottom = 16;
  component.itemSpacing = 8;
  component.primaryAxisSizingMode = 'FIXED';
  component.counterAxisSizingMode = 'FIXED';
  component.resize(432, 150);
  component.cornerRadius = 8;
  component.fills = [{ type: 'SOLID', color: { r: 0.98, g: 0.98, b: 0.98 } }];
  component.strokes = [{ type: 'SOLID', color: COLORS.gray300, opacity: 0.5 }];
  component.strokeWeight = 1;
  component.strokeAlign = 'INSIDE';
  component.dashPattern = [4, 4];  // Dashed border

  // Signature placeholder
  const placeholder = figma.createVector();
  placeholder.name = 'Signature';
  placeholder.resize(200, 60);
  placeholder.x = 116;  // Center: (432-200)/2
  placeholder.y = 45;   // Center: (150-60)/2
  placeholder.strokes = [{ type: 'SOLID', color: COLORS.gray400 }];
  placeholder.strokeWeight = 2;

  component.appendChild(placeholder);

  return component;
}

// MARK: - Main Generation Function

async function generateModalComponents() {
  try {
    console.log('Loading fonts...');
    await Promise.all([
      figma.loadFontAsync({ family: 'Inter', style: 'Regular' }),
      figma.loadFontAsync({ family: 'Inter', style: 'Medium' }),
      figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' }),
      figma.loadFontAsync({ family: 'Inter', style: 'Bold' })
    ]);

    let modalComponentsPage = figma.root.children.find(page => page.name === 'Modal Components') as PageNode;
    if (!modalComponentsPage) {
      modalComponentsPage = figma.createPage();
      modalComponentsPage.name = 'Modal Components';
    }
    figma.currentPage = modalComponentsPage;

    console.log('\n📦 Generating 22 shared modal components...\n');

    const components: (ComponentNode | ComponentSetNode)[] = [];

    // Structure (3 components)
    components.push(await createModalHeader());
    components.push(await createModalContextHeader());
    components.push(createModalContainer());

    // Form Components (5 components + 1 variant set)
    components.push(await createFormTextInputVariants());  // 3 variants
    components.push(await createFormTextArea());
    components.push(await createFormDropdown());
    components.push(createFormToggle());
    components.push(await createFormDatePicker());

    // Buttons (3 components)
    components.push(await createButtonPrimaryGradient());
    components.push(await createButtonSecondaryGlass());
    components.push(await createButtonDestructive());

    // Status (3 components + 1 variant set)
    components.push(await createStatusBannerVariants());  // 3 variants
    components.push(createLoadingSpinner());
    components.push(await createCountdownTimer());

    // Content (3 components)
    components.push(await createDetailRow());
    components.push(createProgressIndicator());
    components.push(createSignaturePreview());

    // Arrange components in a grid
    let xOffset = 0;
    let yOffset = 0;
    const spacing = 60;
    const maxWidth = 1600;

    for (const component of components) {
      component.x = xOffset;
      component.y = yOffset;

      xOffset += component.width + spacing;

      if (xOffset > maxWidth) {
        xOffset = 0;
        yOffset += 300;
      }
    }

    figma.viewport.scrollAndZoomIntoView(components);

    figma.closePlugin(`✅ Generated 22 shared modal components!\n\n` +
      `📦 Component Categories:\n` +
      `• Structure: 3 components (ModalHeader, ModalContextHeader, ModalContainer)\n` +
      `• Forms: 6 components (TextInput with 3 variants, TextArea, Dropdown, Toggle, DatePicker)\n` +
      `• Buttons: 3 components (PrimaryGradient, SecondaryGlass, Destructive)\n` +
      `• Status: 4 components (StatusBanner with 3 variants, LoadingSpinner, CountdownTimer)\n` +
      `• Content: 3 components (DetailRow, ProgressIndicator, SignaturePreview)\n\n` +
      `Total: 22 shared components ready for action modals!\n\n` +
      `Check the "Modal Components" page!`);

  } catch (error: any) {
    console.error('Error generating modal components:', error);
    figma.closePlugin(`❌ Error: ${error?.message || 'Unknown error'}`);
  }
}

// Run the plugin
generateModalComponents();

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
    section: 20,  // iOS DesignTokens.Spacing.section (card content padding)
    modal: 24,
    card: 24      // iOS DesignTokens.Spacing.card (outer spacing)
  },
  // Card dimensions - iOS exact match
  card: {
    width: 327,    // UIScreen.main.bounds.width - 48 (iPhone 13/14)
    heightCompact: 400,
    heightStandard: 500,
    heightTall: 700
  },
  radius: {
    minimal: 4,
    chip: 8,
    button: 12,
    container: 16,
    card: 16,  // iOS DesignTokens.Radius.card (line 76)
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
      { name: 'Critical', value: 95, color: '#FF3B30' },  // Red
      { name: 'High', value: 85, color: '#FF9500' },      // Orange
      { name: 'Medium', value: 75, color: '#8E8E93' },    // Gray
      { name: 'Low', value: 65, color: '#5AC8FA' }        // Light Blue
    ],
    // Ads text color hierarchy (5 levels from DesignTokens.swift)
    adsText: {
      primary: '#0D5950',     // rgb(0.05, 0.35, 0.30) - Dark teal
      secondary: '#147361',   // rgb(0.08, 0.45, 0.38) - Medium teal
      tertiary: '#1A8573',    // rgb(0.10, 0.52, 0.45) - Lighter teal
      subtle: '#269985',      // rgb(0.15, 0.60, 0.52) - Subtle teal
      faded: '#33A691'        // rgb(0.20, 0.65, 0.57) at 70% - Faded teal
    }
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

function hexToRgb(hex: string): RGB {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) return { r: 1, g: 1, b: 1 };

  return {
    r: parseInt(result[1], 16) / 255,
    g: parseInt(result[2], 16) / 255,
    b: parseInt(result[3], 16) / 255
  };
}

function createGradient(startHex: string, endHex: string): Paint[] {
  const start = hexToRgb(startHex);
  const end = hexToRgb(endHex);

  return [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [
      [0.7071, 0.7071, 0],
      [-0.7071, 0.7071, 0.7071]
    ],
    gradientStops: [
      { position: 0, color: { r: start.r, g: start.g, b: start.b, a: 1 } },
      { position: 1, color: { r: end.r, g: end.g, b: end.b, a: 1 } }
    ]
  }];
}

function createSolidFill(hex: string, opacity: number = 1): Paint[] {
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
    const gradient = TOKENS.colors.gradients[name as keyof typeof TOKENS.colors.gradients];

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
    card.fills = createGradient(
      TOKENS.colors.gradients.mail.start,
      TOKENS.colors.gradients.mail.end
    );
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
  button.fills = createGradient(
    TOKENS.colors.gradients.mail.start,
    TOKENS.colors.gradients.mail.end
  );
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
  sendButton.fills = createGradient(
    TOKENS.colors.gradients.mail.start,
    TOKENS.colors.gradients.mail.end
  );
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

/**
 * Create Bottom Navigation Component (iOS Archetype Switcher)
 * Matches BottomNavigationBar.swift exactly
 */
function createBottomNav(archetype: string = 'Mail', count: number = 12): FrameNode {
  const nav = figma.createFrame();
  nav.name = 'Bottom Nav - Archetype Switcher';
  nav.resize(375, 68);
  nav.cornerRadius = 24;
  nav.fills = createSolidFill('#FFFFFF', 0.05);  // Glassmorphic background
  nav.layoutMode = 'HORIZONTAL';
  nav.primaryAxisAlignItems = 'CENTER';
  nav.counterAxisAlignItems = 'CENTER';
  nav.paddingLeft = 20;
  nav.paddingRight = 20;
  nav.paddingTop = 10;
  nav.paddingBottom = 10;

  // LEFT: Archetype switcher + count
  const leftSection = figma.createFrame();
  leftSection.name = 'Left Section';
  leftSection.resize(150, 48);
  leftSection.fills = [];
  leftSection.layoutMode = 'HORIZONTAL';
  leftSection.itemSpacing = 10;
  leftSection.primaryAxisAlignItems = 'CENTER';

  // Archetype capsule button
  const archetypeCapsule = figma.createFrame();
  archetypeCapsule.name = 'Archetype Button';
  archetypeCapsule.resize(80, 30);
  archetypeCapsule.cornerRadius = 15;
  archetypeCapsule.fills = createSolidFill('#FFFFFF', 0.08);
  archetypeCapsule.layoutMode = 'HORIZONTAL';
  archetypeCapsule.itemSpacing = 6;
  archetypeCapsule.primaryAxisAlignItems = 'CENTER';
  archetypeCapsule.counterAxisAlignItems = 'CENTER';
  archetypeCapsule.paddingLeft = 12;
  archetypeCapsule.paddingRight = 12;
  archetypeCapsule.paddingTop = 6;
  archetypeCapsule.paddingBottom = 6;

  const archetypeText = figma.createText();
  archetypeText.characters = archetype;
  archetypeText.fontSize = 16;
  archetypeText.fontName = { family: "Inter", style: "Bold" };
  archetypeText.fills = createSolidFill('#FFFFFF');
  archetypeCapsule.appendChild(archetypeText);

  const chevron = figma.createText();
  chevron.characters = '⌄';
  chevron.fontSize = 11;
  chevron.fills = createSolidFill('#FFFFFF', 0.8);
  archetypeCapsule.appendChild(chevron);

  leftSection.appendChild(archetypeCapsule);

  // Dot separator + count
  const countText = figma.createText();
  countText.characters = `· ${count} left`;
  countText.fontSize = 14;
  countText.fontName = { family: "Inter", style: "Regular" };
  countText.fills = createSolidFill('#FFFFFF', 0.7);
  leftSection.appendChild(countText);

  nav.appendChild(leftSection);

  // CENTER: Holographic progress bar (90×6px)
  const progressContainer = figma.createFrame();
  progressContainer.name = 'Progress Bar';
  progressContainer.resize(90, 6);
  progressContainer.fills = [];

  // Background track
  const progressBg = figma.createRectangle();
  progressBg.name = 'Track';
  progressBg.resize(90, 6);
  progressBg.cornerRadius = 3;
  progressBg.fills = createSolidFill('#FFFFFF', 0.08);

  // Holographic fill (60% progress example)
  const progressFill = figma.createRectangle();
  progressFill.name = 'Fill';
  progressFill.resize(54, 6);  // 60% of 90
  progressFill.cornerRadius = 3;
  // Approximate holographic gradient (cyan → blue → purple)
  progressFill.fills = [{
    type: 'GRADIENT_LINEAR',
    gradientTransform: [[1, 0, 0], [0, 1, 0]],
    gradientStops: [
      { position: 0, color: { r: 0, g: 1, b: 1, a: 1 } },      // Cyan
      { position: 0.5, color: { r: 0.4, g: 0.4, b: 1, a: 1 } }, // Blue
      { position: 1, color: { r: 0.8, g: 0.2, b: 1, a: 1 } }    // Purple
    ]
  }];

  progressContainer.appendChild(progressBg);
  progressContainer.appendChild(progressFill);

  nav.appendChild(progressContainer);

  // RIGHT: Menu button (36×36px circle)
  const menuButton = figma.createFrame();
  menuButton.name = 'Menu Button';
  menuButton.resize(36, 36);
  menuButton.cornerRadius = 18;
  menuButton.fills = createSolidFill('#FFFFFF', 0.08);
  menuButton.layoutMode = 'VERTICAL';
  menuButton.primaryAxisAlignItems = 'CENTER';
  menuButton.counterAxisAlignItems = 'CENTER';

  const ellipsis = figma.createText();
  ellipsis.characters = '⋯';
  ellipsis.fontSize = 18;
  ellipsis.fills = createSolidFill('#FFFFFF');
  menuButton.appendChild(ellipsis);

  nav.appendChild(menuButton);

  return nav;
}

/**
 * Generate Ads Email Card Page (Master Setting)
 */
function generateAdsEmailPage() {
  const page = figma.createPage();
  page.name = '📢 Ads Email Cards (Master)';

  // Page description
  const description = figma.createText();
  description.name = 'Page Description';
  description.characters = 'Ads Email Cards - Master Setting\n\nThese cards use the Ads gradient (teal → green) with dark teal text (#0D5D52).\nMaster template for all advertisement emails in the Zero Inbox system.';
  description.fontSize = 16;
  description.fills = createSolidFill('#FFFFFF');
  description.x = 40;
  description.y = 40;
  description.resize(600, 100);
  page.appendChild(description);

  let yOffset = 180;

  // Full screen mockup with card
  const phoneFrame = createPhoneFrame();
  phoneFrame.x = 40;
  phoneFrame.y = yOffset;

  // Screen content
  const screen = figma.createFrame();
  screen.name = 'Screen';
  screen.resize(375, 768);
  screen.x = 0;
  screen.y = 44;
  screen.fills = createSolidFill('#000000');

  // Header
  const header = figma.createFrame();
  header.name = 'Header';
  header.resize(375, 60);
  header.x = 0;
  header.y = 0;
  header.fills = createSolidFill('#1C1C1E');
  header.layoutMode = 'HORIZONTAL';
  header.primaryAxisAlignItems = 'CENTER';
  header.counterAxisAlignItems = 'CENTER';
  header.paddingLeft = 16;
  header.paddingRight = 16;

  const headerTitle = figma.createText();
  headerTitle.characters = 'Ads';
  headerTitle.fontSize = 28;
  headerTitle.fontName = { family: "Inter", style: "Bold" };
  headerTitle.fills = createSolidFill('#FFFFFF');
  header.appendChild(headerTitle);

  screen.appendChild(header);

  // Ads email card
  const adsCard = figma.createFrame();
  adsCard.name = 'Ads Email Card';
  adsCard.x = 16;
  adsCard.y = 80;
  adsCard.resize(TOKENS.card.width, TOKENS.card.heightStandard);  // iOS: 327×500px
  adsCard.cornerRadius = TOKENS.radius.card;  // iOS: 16px
  adsCard.fills = createGradient(
    TOKENS.colors.gradients.ads.start,
    TOKENS.colors.gradients.ads.end
  );
  adsCard.effects = [{
    type: 'DROP_SHADOW',
    color: { r: 0, g: 0, b: 0, a: 0.4 },
    offset: { x: 0, y: 10 },
    radius: 20,
    visible: true,
    blendMode: 'NORMAL'
  }];
  adsCard.layoutMode = 'VERTICAL';
  adsCard.itemSpacing = 12;
  adsCard.paddingTop = TOKENS.spacing.section;   // iOS: 20px
  adsCard.paddingBottom = TOKENS.spacing.section;
  adsCard.paddingLeft = TOKENS.spacing.section;
  adsCard.paddingRight = TOKENS.spacing.section;

  // Sender
  const sender = figma.createText();
  sender.characters = 'ads@company.com';
  sender.fontSize = 13;
  sender.fills = createSolidFill(TOKENS.colors.adsText.secondary, 0.7);  // Precise ads text color
  adsCard.appendChild(sender);

  // Subject (cardTitle: 19pt Bold from DesignTokens.swift)
  const subject = figma.createText();
  subject.characters = 'Special Offer: 50% Off Today';
  subject.fontSize = 19;  // Exact match to Typography.cardTitle
  subject.fontName = { family: "Inter", style: "Bold" };
  subject.fills = createSolidFill(TOKENS.colors.adsText.primary);  // Primary ads text
  adsCard.appendChild(subject);

  // Preview (cardSummary: 15pt from DesignTokens.swift)
  const preview = figma.createText();
  preview.characters = 'Limited time offer on all products. Shop now and save big!';
  preview.fontSize = 15;  // Exact match to Typography.cardSummary
  preview.fills = createSolidFill(TOKENS.colors.adsText.secondary, 0.8);  // Secondary ads text
  adsCard.appendChild(preview);

  // Actions header (cardSectionHeader: 15pt Bold from DesignTokens.swift)
  const actionsHeader = figma.createText();
  actionsHeader.characters = 'Actions';
  actionsHeader.fontSize = 15;  // Exact match to Typography.cardSectionHeader
  actionsHeader.fontName = { family: "Inter", style: "Bold" };
  actionsHeader.fills = createSolidFill(TOKENS.colors.adsText.primary, 0.9);
  adsCard.appendChild(actionsHeader);

  // Action button
  const actionButton = figma.createFrame();
  actionButton.name = 'Action Button';
  actionButton.resize(295, 44);
  actionButton.cornerRadius = TOKENS.radius.button;
  actionButton.fills = createSolidFill('#FFFFFF', 0.15);
  actionButton.layoutMode = 'HORIZONTAL';
  actionButton.primaryAxisAlignItems = 'CENTER';
  actionButton.counterAxisAlignItems = 'CENTER';
  actionButton.paddingLeft = 16;

  const buttonText = figma.createText();
  buttonText.characters = 'View Offer ↗';
  buttonText.fontSize = 15;
  buttonText.fontName = { family: "Inter", style: "Bold" };
  buttonText.fills = createSolidFill(TOKENS.colors.adsText.primary);  // Primary ads text
  actionButton.appendChild(buttonText);

  adsCard.appendChild(actionButton);
  screen.appendChild(adsCard);

  // Bottom nav (archetype switcher)
  const bottomNav = createBottomNav('Ads', 12);
  bottomNav.x = 0;
  bottomNav.y = 700;  // Adjusted for taller cards
  screen.appendChild(bottomNav);

  phoneFrame.appendChild(screen);
  page.appendChild(phoneFrame);

  // Design specs on the right
  const specs = figma.createFrame();
  specs.name = 'Design Specs';
  specs.x = 460;
  specs.y = yOffset;
  specs.resize(400, 600);
  specs.fills = createSolidFill('#1C1C1E', 0.3);
  specs.cornerRadius = 16;
  specs.layoutMode = 'VERTICAL';
  specs.itemSpacing = 16;
  specs.paddingTop = 24;
  specs.paddingLeft = 24;
  specs.paddingRight = 24;
  specs.paddingBottom = 24;

  const specsTitle = figma.createText();
  specsTitle.characters = 'Ads Card Specifications';
  specsTitle.fontSize = 20;
  specsTitle.fontName = { family: "Inter", style: "Bold" };
  specsTitle.fills = createSolidFill('#FFFFFF');
  specs.appendChild(specsTitle);

  const specItems = [
    'GRADIENT',
    'Start: #16bbaa (Teal)',
    'End: #4fd19e (Green)',
    'Angle: 135°',
    '',
    'TEXT COLORS',
    'Sender: #0D5D52 at 70% opacity',
    'Subject: #0D5D52 at 100% (19pt Bold)',
    'Preview: #0D5D52 at 80% (15pt)',
    'Button text: #0D5D52 (15pt Bold)',
    '',
    'DIMENSIONS',
    'Card: 327×500px (iOS: UIScreen.main.bounds.width - 48)',
    'Corner radius: 16px (iOS DesignTokens.Radius.card)',
    'Padding: 20px (iOS DesignTokens.Spacing.section)',
    'Shadow: y:10, radius:20, opacity:40%',
    '',
    'USAGE',
    'All advertisement emails',
    'Marketing campaigns',
    'Promotional offers'
  ];

  specItems.forEach(item => {
    const text = figma.createText();
    text.characters = item;
    text.fontSize = item === '' ? 8 : (item === item.toUpperCase() && item.length < 20) ? 14 : 13;
    text.fontName = { family: "Inter", style: (item === item.toUpperCase() && item.length < 20) ? "Bold" : "Regular" };
    text.fills = createSolidFill(item === '' ? '#000000' : (item === item.toUpperCase() && item.length < 20) ? '#667eea' : '#FFFFFF', item === '' ? 0 : 0.9);
    specs.appendChild(text);
  });

  page.appendChild(specs);

  figma.currentPage = page;
}

/**
 * Generate Work Email Card Page (Master Setting)
 */
function generateWorkEmailPage() {
  const page = figma.createPage();
  page.name = '💼 Work Email Cards (Master)';

  // Page description
  const description = figma.createText();
  description.name = 'Page Description';
  description.characters = 'Work Email Cards - Master Setting\n\nThese cards use the Mail gradient (blue → purple) with white text.\nMaster template for all work-related emails in the Zero Inbox system.';
  description.fontSize = 16;
  description.fills = createSolidFill('#FFFFFF');
  description.x = 40;
  description.y = 40;
  description.resize(600, 100);
  page.appendChild(description);

  let yOffset = 180;

  // Full screen mockup with card
  const phoneFrame = createPhoneFrame();
  phoneFrame.x = 40;
  phoneFrame.y = yOffset;

  // Screen content
  const screen = figma.createFrame();
  screen.name = 'Screen';
  screen.resize(375, 768);
  screen.x = 0;
  screen.y = 44;
  screen.fills = createSolidFill('#000000');

  // Header
  const header = figma.createFrame();
  header.name = 'Header';
  header.resize(375, 60);
  header.x = 0;
  header.y = 0;
  header.fills = createSolidFill('#1C1C1E');
  header.layoutMode = 'HORIZONTAL';
  header.primaryAxisAlignItems = 'CENTER';
  header.counterAxisAlignItems = 'CENTER';
  header.paddingLeft = 16;
  header.paddingRight = 16;

  const headerTitle = figma.createText();
  headerTitle.characters = 'Work';
  headerTitle.fontSize = 28;
  headerTitle.fontName = { family: "Inter", style: "Bold" };
  headerTitle.fills = createSolidFill('#FFFFFF');
  header.appendChild(headerTitle);

  screen.appendChild(header);

  // Work email card
  const workCard = figma.createFrame();
  workCard.name = 'Work Email Card';
  workCard.x = 16;
  workCard.y = 80;
  workCard.resize(TOKENS.card.width, TOKENS.card.heightStandard);  // iOS: 327×500px
  workCard.cornerRadius = TOKENS.radius.card;  // iOS: 16px
  workCard.fills = createGradient(
    TOKENS.colors.gradients.mail.start,
    TOKENS.colors.gradients.mail.end
  );
  workCard.effects = [{
    type: 'DROP_SHADOW',
    color: { r: 0, g: 0, b: 0, a: 0.4 },
    offset: { x: 0, y: 10 },
    radius: 20,
    visible: true,
    blendMode: 'NORMAL'
  }];
  workCard.layoutMode = 'VERTICAL';
  workCard.itemSpacing = 12;
  workCard.paddingTop = TOKENS.spacing.section;   // iOS: 20px
  workCard.paddingBottom = TOKENS.spacing.section;
  workCard.paddingLeft = TOKENS.spacing.section;
  workCard.paddingRight = TOKENS.spacing.section;

  // Sender
  const sender = figma.createText();
  sender.characters = 'boss@company.com';
  sender.fontSize = 13;
  sender.fills = createSolidFill('#FFFFFF', 0.7);
  workCard.appendChild(sender);

  // Subject (cardTitle: 19pt Bold)
  const subject = figma.createText();
  subject.characters = 'Q4 Project Review Meeting';
  subject.fontSize = 19;  // Exact match to Typography.cardTitle
  subject.fontName = { family: "Inter", style: "Bold" };
  subject.fills = createSolidFill('#FFFFFF');
  workCard.appendChild(subject);

  // Preview (cardSummary: 15pt)
  const preview = figma.createText();
  preview.characters = 'Please join us tomorrow at 2pm to discuss project milestones.';
  preview.fontSize = 15;  // Exact match to Typography.cardSummary
  preview.fills = createSolidFill('#FFFFFF', 0.8);
  workCard.appendChild(preview);

  // Actions header (cardSectionHeader: 15pt Bold)
  const actionsHeader = figma.createText();
  actionsHeader.characters = 'Actions';
  actionsHeader.fontSize = 15;  // Exact match to Typography.cardSectionHeader
  actionsHeader.fontName = { family: "Inter", style: "Bold" };
  actionsHeader.fills = createSolidFill('#FFFFFF', 0.9);
  workCard.appendChild(actionsHeader);

  // Action button
  const actionButton = figma.createFrame();
  actionButton.name = 'Action Button';
  actionButton.resize(295, 44);
  actionButton.cornerRadius = TOKENS.radius.button;
  actionButton.fills = createSolidFill('#FFFFFF', 0.15);
  actionButton.layoutMode = 'HORIZONTAL';
  actionButton.primaryAxisAlignItems = 'CENTER';
  actionButton.counterAxisAlignItems = 'CENTER';
  actionButton.paddingLeft = 16;

  const buttonText = figma.createText();
  buttonText.characters = 'Add to Calendar';
  buttonText.fontSize = 15;
  buttonText.fontName = { family: "Inter", style: "Bold" };
  buttonText.fills = createSolidFill('#FFFFFF');
  actionButton.appendChild(buttonText);

  workCard.appendChild(actionButton);
  screen.appendChild(workCard);

  // Bottom nav (archetype switcher)
  const bottomNav = createBottomNav('Mail', 8);
  bottomNav.x = 0;
  bottomNav.y = 700;  // Adjusted for taller cards
  screen.appendChild(bottomNav);

  phoneFrame.appendChild(screen);
  page.appendChild(phoneFrame);

  // Design specs on the right
  const specs = figma.createFrame();
  specs.name = 'Design Specs';
  specs.x = 460;
  specs.y = yOffset;
  specs.resize(400, 600);
  specs.fills = createSolidFill('#1C1C1E', 0.3);
  specs.cornerRadius = 16;
  specs.layoutMode = 'VERTICAL';
  specs.itemSpacing = 16;
  specs.paddingTop = 24;
  specs.paddingLeft = 24;
  specs.paddingRight = 24;
  specs.paddingBottom = 24;

  const specsTitle = figma.createText();
  specsTitle.characters = 'Work Card Specifications';
  specsTitle.fontSize = 20;
  specsTitle.fontName = { family: "Inter", style: "Bold" };
  specsTitle.fills = createSolidFill('#FFFFFF');
  specs.appendChild(specsTitle);

  const specItems = [
    'GRADIENT',
    'Start: #667eea (Blue)',
    'End: #764ba2 (Purple)',
    'Angle: 135°',
    '',
    'TEXT COLORS',
    'Sender: #FFFFFF at 70% opacity',
    'Subject: #FFFFFF at 100% (19pt Bold)',
    'Preview: #FFFFFF at 80% (15pt)',
    'Button text: #FFFFFF (15pt Bold)',
    '',
    'DIMENSIONS',
    'Card: 327×500px (iOS: UIScreen.main.bounds.width - 48)',
    'Corner radius: 16px (iOS DesignTokens.Radius.card)',
    'Padding: 20px (iOS DesignTokens.Spacing.section)',
    'Shadow: y:10, radius:20, opacity:40%',
    '',
    'USAGE',
    'All work-related emails',
    'Business correspondence',
    'Meeting invitations',
    'Project updates'
  ];

  specItems.forEach(item => {
    const text = figma.createText();
    text.characters = item;
    text.fontSize = item === '' ? 8 : (item === item.toUpperCase() && item.length < 20) ? 14 : 13;
    text.fontName = { family: "Inter", style: (item === item.toUpperCase() && item.length < 20) ? "Bold" : "Regular" };
    text.fills = createSolidFill(item === '' ? '#000000' : (item === item.toUpperCase() && item.length < 20) ? '#667eea' : '#FFFFFF', item === '' ? 0 : 0.9);
    specs.appendChild(text);
  });

  page.appendChild(specs);

  figma.currentPage = page;
}

/**
 * Generate Email Card Views (Overview)
 */
function generateEmailCards() {
  const page = figma.createPage();
  page.name = '📧 Email Card Views (Overview)';

  // Page description
  const description = figma.createText();
  description.name = 'Page Description';
  description.characters = 'Email Card Views - All Variants\n\nOverview of all email card types in the Zero Inbox design system.\nEach card type has its own master page with full specifications.';
  description.fontSize = 16;
  description.fills = createSolidFill('#FFFFFF');
  description.x = 40;
  description.y = 40;
  description.resize(600, 100);
  page.appendChild(description);

  let yOffset = 180;

  // Card with Mail gradient
  const mailCard = figma.createFrame();
  mailCard.name = 'Mail Card';
  mailCard.x = 40;
  mailCard.y = yOffset;
  mailCard.resize(TOKENS.card.width, 180);  // iOS width: 327px
  mailCard.cornerRadius = TOKENS.radius.card;  // iOS: 16px
  mailCard.fills = createGradient(
    TOKENS.colors.gradients.mail.start,
    TOKENS.colors.gradients.mail.end
  );
  mailCard.layoutMode = 'VERTICAL';
  mailCard.itemSpacing = 12;
  mailCard.paddingTop = TOKENS.spacing.card;
  mailCard.paddingBottom = TOKENS.spacing.card;
  mailCard.paddingLeft = TOKENS.spacing.card;
  mailCard.paddingRight = TOKENS.spacing.card;

  // Card title
  const mailTitle = figma.createText();
  mailTitle.characters = 'Email Subject Line';
  mailTitle.fontSize = 19;
  mailTitle.fontName = { family: "Inter", style: "Bold" };
  mailTitle.fills = createSolidFill('#FFFFFF');
  mailCard.appendChild(mailTitle);

  // Card summary
  const mailSummary = figma.createText();
  mailSummary.characters = 'Preview of email content goes here...';
  mailSummary.fontSize = 15;
  mailSummary.fills = createSolidFill('#FFFFFF', 0.8);
  mailCard.appendChild(mailSummary);

  page.appendChild(mailCard);
  yOffset += 200;

  // Card with Ads gradient
  const adsCard = figma.createFrame();
  adsCard.name = 'Ads Card';
  adsCard.x = 40;
  adsCard.y = yOffset;
  adsCard.resize(TOKENS.card.width, 180);  // iOS width: 327px
  adsCard.cornerRadius = TOKENS.radius.card;  // iOS: 16px
  adsCard.fills = createGradient(
    TOKENS.colors.gradients.ads.start,
    TOKENS.colors.gradients.ads.end
  );
  adsCard.layoutMode = 'VERTICAL';
  adsCard.itemSpacing = 12;
  adsCard.paddingTop = TOKENS.spacing.card;
  adsCard.paddingBottom = TOKENS.spacing.card;
  adsCard.paddingLeft = TOKENS.spacing.card;
  adsCard.paddingRight = TOKENS.spacing.card;

  const adsTitle = figma.createText();
  adsTitle.characters = 'Advertisement Title';
  adsTitle.fontSize = 19;  // Typography.cardTitle
  adsTitle.fontName = { family: "Inter", style: "Bold" };
  adsTitle.fills = createSolidFill(TOKENS.colors.adsText.primary);  // Precise ads text color
  adsCard.appendChild(adsTitle);

  const adsSummary = figma.createText();
  adsSummary.characters = 'Ad content preview...';
  adsSummary.fontSize = 15;  // Typography.cardSummary
  adsSummary.fills = createSolidFill(TOKENS.colors.adsText.secondary, 0.7);
  adsCard.appendChild(adsSummary);

  page.appendChild(adsCard);
  yOffset += 200;

  // More card variants for other gradients
  const cardVariants = [
    { name: 'Lifestyle', gradient: TOKENS.colors.gradients.lifestyle, textColor: '#FFFFFF' },
    { name: 'Shop', gradient: TOKENS.colors.gradients.shop, textColor: '#FFFFFF' },
    { name: 'Urgent', gradient: TOKENS.colors.gradients.urgent, textColor: '#FFFFFF' }
  ];

  cardVariants.forEach((variant) => {
    const card = figma.createFrame();
    card.name = `${variant.name} Card`;
    card.x = 40;
    card.y = yOffset;
    card.resize(TOKENS.card.width, 180);  // iOS width: 327px
    card.cornerRadius = TOKENS.radius.card;  // iOS: 16px
    card.fills = createGradient(variant.gradient.start, variant.gradient.end);
    card.layoutMode = 'VERTICAL';
    card.itemSpacing = 12;
    card.paddingTop = TOKENS.spacing.card;
    card.paddingBottom = TOKENS.spacing.card;
    card.paddingLeft = TOKENS.spacing.card;
    card.paddingRight = TOKENS.spacing.card;

    const title = figma.createText();
    title.characters = `${variant.name} Email Title`;
    title.fontSize = 19;
    title.fontName = { family: "Inter", style: "Bold" };
    title.fills = createSolidFill(variant.textColor);
    card.appendChild(title);

    const summary = figma.createText();
    summary.characters = 'Preview text content...';
    summary.fontSize = 15;
    summary.fills = createSolidFill(variant.textColor, 0.8);
    card.appendChild(summary);

    page.appendChild(card);
    yOffset += 200;
  });

  figma.currentPage = page;
}

/**
 * Generate ActionSelectorBottomSheet Page
 * Matches ActionSelectorBottomSheet.swift exactly
 */
function generateActionSelectorPage() {
  const page = figma.createPage();
  page.name = '🔼 Action Selector (Bottom Sheet)';

  // Page description
  const description = figma.createText();
  description.name = 'Page Description';
  description.characters = 'Action Selector Bottom Sheet - iOS Exact Match\n\nSlide-up sheet that appears when user swipes up on card.\nMatches ActionSelectorBottomSheet.swift implementation.';
  description.fontSize = 16;
  description.fills = createSolidFill('#FFFFFF');
  description.x = 40;
  description.y = 40;
  description.resize(600, 80);
  page.appendChild(description);

  let yOffset = 160;

  // Phone frame with bottom sheet
  const phoneFrame = createPhoneFrame();
  phoneFrame.x = 40;
  phoneFrame.y = yOffset;

  // Background (dimmed)
  const dimOverlay = figma.createRectangle();
  dimOverlay.name = 'Dim Overlay';
  dimOverlay.resize(375, 768);
  dimOverlay.x = 0;
  dimOverlay.y = 44;
  dimOverlay.fills = createSolidFill('#000000', 0.5);
  phoneFrame.appendChild(dimOverlay);

  // Bottom sheet (500px height per ActionSelectorBottomSheet.swift:125)
  const bottomSheet = figma.createFrame();
  bottomSheet.name = 'Action Selector Bottom Sheet';
  bottomSheet.resize(375, 500);
  bottomSheet.x = 0;
  bottomSheet.y = 312;  // 812 - 500 = 312
  bottomSheet.cornerRadius = TOKENS.radius.card;  // iOS: 16px
  bottomSheet.fills = createGradient(
    TOKENS.colors.gradients.mail.start,
    TOKENS.colors.gradients.mail.end
  );
  bottomSheet.layoutMode = 'VERTICAL';
  bottomSheet.itemSpacing = 0;

  // Glassmorphic overlay
  const glassOverlay = figma.createRectangle();
  glassOverlay.name = 'Glass Overlay';
  glassOverlay.resize(375, 500);
  glassOverlay.fills = createSolidFill('#FFFFFF', 0.03);

  // Handle bar
  const handleBar = figma.createRectangle();
  handleBar.name = 'Handle Bar';
  handleBar.resize(40, 5);
  handleBar.x = 167.5;  // Center: (375 - 40) / 2
  handleBar.y = 12;
  handleBar.cornerRadius = 3;
  handleBar.fills = createSolidFill('#FFFFFF', 0.3);
  bottomSheet.appendChild(handleBar);

  // Header
  const headerFrame = figma.createFrame();
  headerFrame.name = 'Header';
  headerFrame.resize(343, 80);
  headerFrame.x = 16;
  headerFrame.y = 32;
  headerFrame.fills = [];
  headerFrame.layoutMode = 'VERTICAL';
  headerFrame.itemSpacing = 8;

  const headerTitle = figma.createText();
  headerTitle.characters = 'Select Action';
  headerTitle.fontSize = 28;
  headerTitle.fontName = { family: "Inter", style: "Bold" };
  headerTitle.fills = createSolidFill('#FFFFFF');
  headerFrame.appendChild(headerTitle);

  const cardTitle = figma.createText();
  cardTitle.characters = 'Field Trip Permission Form';
  cardTitle.fontSize = 14;
  cardTitle.fills = createSolidFill('#FFFFFF', 0.7);
  cardTitle.resize(343, 32);
  headerFrame.appendChild(cardTitle);

  bottomSheet.appendChild(headerFrame);

  // Quick Actions section
  const quickActionsFrame = figma.createFrame();
  quickActionsFrame.name = 'Quick Actions';
  quickActionsFrame.resize(343, 100);
  quickActionsFrame.x = 16;
  quickActionsFrame.y = 128;
  quickActionsFrame.fills = [];
  quickActionsFrame.layoutMode = 'VERTICAL';
  quickActionsFrame.itemSpacing = 8;

  const sectionLabel = figma.createText();
  sectionLabel.characters = 'QUICK ACTIONS';
  sectionLabel.fontSize = 10;
  sectionLabel.fontName = { family: "Inter", style: "Bold" };
  sectionLabel.fills = createSolidFill('#FFFFFF', 0.5);
  sectionLabel.letterSpacing = { value: 0.1, unit: 'PERCENT' };
  quickActionsFrame.appendChild(sectionLabel);

  const iconsRow = figma.createFrame();
  iconsRow.name = 'Icons Row';
  iconsRow.resize(343, 80);
  iconsRow.fills = [];
  iconsRow.layoutMode = 'HORIZONTAL';
  iconsRow.itemSpacing = 16;

  // Quick action icons
  const quickActions = ['Share', 'Copy', 'Safari'];
  quickActions.forEach(action => {
    const iconButton = figma.createFrame();
    iconButton.name = action;
    iconButton.resize(60, 80);
    iconButton.fills = [];
    iconButton.layoutMode = 'VERTICAL';
    iconButton.itemSpacing = 8;
    iconButton.primaryAxisAlignItems = 'CENTER';

    const circle = figma.createEllipse();
    circle.resize(60, 60);
    circle.fills = createSolidFill('#FFFFFF', 0.1);
    circle.strokes = createSolidFill('#FFFFFF', 0.4);
    circle.strokeWeight = 1.5;
    iconButton.appendChild(circle);

    const label = figma.createText();
    label.characters = action;
    label.fontSize = 11;
    label.fontName = { family: "Inter", style: "Bold" };
    label.fills = createSolidFill('#FFFFFF', 0.7);
    iconButton.appendChild(label);

    iconsRow.appendChild(iconButton);
  });

  quickActionsFrame.appendChild(iconsRow);
  bottomSheet.appendChild(quickActionsFrame);

  // Divider
  const divider = figma.createRectangle();
  divider.name = 'Divider';
  divider.resize(343, 1);
  divider.x = 16;
  divider.y = 244;
  divider.fills = createSolidFill('#FFFFFF', 0.2);
  bottomSheet.appendChild(divider);

  // Action list
  const actionListFrame = figma.createFrame();
  actionListFrame.name = 'Action List';
  actionListFrame.resize(343, 220);
  actionListFrame.x = 16;
  actionListFrame.y = 261;
  actionListFrame.fills = [];
  actionListFrame.layoutMode = 'VERTICAL';
  actionListFrame.itemSpacing = 12;

  const actions = [
    { name: 'Sign Form', icon: '✍️', current: true },
    { name: 'View Details', icon: '👁️', current: false },
    { name: 'Schedule Meeting', icon: '📅', current: false }
  ];

  actions.forEach(action => {
    const actionRow = figma.createFrame();
    actionRow.name = action.name;
    actionRow.resize(343, 64);
    actionRow.cornerRadius = TOKENS.radius.button;
    actionRow.fills = createSolidFill('#FFFFFF', action.current ? 0.2 : 0.05);
    actionRow.strokes = action.current ? createSolidFill('#34C759', 0.5) : createSolidFill('#FFFFFF', 0.1);
    actionRow.strokeWeight = action.current ? 2 : 1;
    actionRow.layoutMode = 'HORIZONTAL';
    actionRow.itemSpacing = 16;
    actionRow.paddingLeft = 20;
    actionRow.paddingRight = 20;
    actionRow.primaryAxisAlignItems = 'CENTER';

    // Icon box
    const iconBox = figma.createFrame();
    iconBox.resize(40, 40);
    iconBox.cornerRadius = TOKENS.radius.container;
    iconBox.fills = createSolidFill('#FFFFFF', action.current ? 0.3 : 0.1);
    iconBox.layoutMode = 'VERTICAL';
    iconBox.primaryAxisAlignItems = 'CENTER';
    iconBox.counterAxisAlignItems = 'CENTER';

    const iconText = figma.createText();
    iconText.characters = action.icon;
    iconText.fontSize = 20;
    iconBox.appendChild(iconText);

    actionRow.appendChild(iconBox);

    // Action name
    const actionName = figma.createText();
    actionName.characters = action.name;
    actionName.fontSize = 17;
    actionName.fontName = { family: "Inter", style: "Bold" };
    actionName.fills = createSolidFill('#FFFFFF');
    actionRow.appendChild(actionName);

    if (action.current) {
      const spacer = figma.createFrame();
      spacer.resize(60, 20);
      spacer.fills = [];
      actionRow.appendChild(spacer);

      const currentBadge = figma.createFrame();
      currentBadge.resize(60, 20);
      currentBadge.cornerRadius = 4;
      currentBadge.fills = createSolidFill('#34C759');
      currentBadge.layoutMode = 'HORIZONTAL';
      currentBadge.primaryAxisAlignItems = 'CENTER';
      currentBadge.counterAxisAlignItems = 'CENTER';
      currentBadge.paddingLeft = 6;
      currentBadge.paddingRight = 6;

      const badgeText = figma.createText();
      badgeText.characters = 'CURRENT';
      badgeText.fontSize = 10;
      badgeText.fontName = { family: "Inter", style: "Bold" };
      badgeText.fills = createSolidFill('#FFFFFF');
      currentBadge.appendChild(badgeText);

      actionRow.appendChild(currentBadge);
    }

    actionListFrame.appendChild(actionRow);
  });

  bottomSheet.appendChild(actionListFrame);

  phoneFrame.appendChild(bottomSheet);
  page.appendChild(phoneFrame);

  // Design specs on the right
  const specs = figma.createFrame();
  specs.name = 'Design Specs';
  specs.x = 460;
  specs.y = yOffset;
  specs.resize(400, 600);
  specs.fills = createSolidFill('#1C1C1E', 0.3);
  specs.cornerRadius = 16;
  specs.layoutMode = 'VERTICAL';
  specs.itemSpacing = 16;
  specs.paddingTop = 24;
  specs.paddingLeft = 24;
  specs.paddingRight = 24;
  specs.paddingBottom = 24;

  const specsTitle = figma.createText();
  specsTitle.characters = 'ActionSelectorBottomSheet Specs';
  specsTitle.fontSize = 20;
  specsTitle.fontName = { family: "Inter", style: "Bold" };
  specsTitle.fills = createSolidFill('#FFFFFF');
  specs.appendChild(specsTitle);

  const specItems = [
    'COMPONENT',
    'ActionSelectorBottomSheet.swift (lines 1-503)',
    '',
    'DIMENSIONS',
    'Sheet: 375×500px (line 125)',
    'Handle bar: 40×5px, 3px radius',
    'Quick action icons: 60×60px circles',
    'Action rows: 343×64px, 12px radius',
    'Corner radius: 16px (iOS DesignTokens)',
    '',
    'BEHAVIOR',
    'Slides up from bottom when user swipes up',
    'Appears over dimmed background (50% opacity)',
    'Glassmorphic background matching card type',
    'Quick actions: Share, Copy, Safari',
    'Scrollable action list below',
    '',
    'USAGE',
    'Change primary action on any card',
    'Access quick actions (share, copy, open)',
    'View all available actions for email',
    'Premium actions show "PREMIUM" badge'
  ];

  specItems.forEach(item => {
    const text = figma.createText();
    text.characters = item;
    text.fontSize = item === '' ? 8 : (item === item.toUpperCase() && item.length < 20) ? 14 : 13;
    text.fontName = { family: "Inter", style: (item === item.toUpperCase() && item.length < 20) ? "Bold" : "Regular" };
    text.fills = createSolidFill(item === '' ? '#000000' : (item === item.toUpperCase() && item.length < 20) ? '#667eea' : '#FFFFFF', item === '' ? 0 : 0.9);
    specs.appendChild(text);
  });

  page.appendChild(specs);

  figma.currentPage = page;
}

/**
 * Generate Actions Reference Page with actual UI cards
 */
function generateActionsPage() {
  const page = figma.createPage();
  page.name = '📋 All Actions (169)';

  // Sample actions (would parse from ActionRegistry.swift in production)
  const sampleActions = [
    // GO_TO Actions (External links)
    { name: 'View Invoice', type: 'GO_TO', priority: 90, gradient: 'mail' },
    { name: 'Open Map', type: 'GO_TO', priority: 85, gradient: 'shop' },
    { name: 'Visit Website', type: 'GO_TO', priority: 75, gradient: 'ads' },
    { name: 'Call Phone', type: 'GO_TO', priority: 95, gradient: 'urgent' },
    { name: 'Open App Store', type: 'GO_TO', priority: 70, gradient: 'lifestyle' },

    // IN_APP Actions (Modals)
    { name: 'Add to Calendar', type: 'IN_APP', modal: 'GenericActionModal', priority: 85, gradient: 'mail' },
    { name: 'Quick Reply', type: 'IN_APP', modal: 'CommunicationModal', priority: 90, gradient: 'mail' },
    { name: 'View Document', type: 'IN_APP', modal: 'ViewContentModal', priority: 80, gradient: 'shop' },
    { name: 'Pay Invoice', type: 'IN_APP', modal: 'FinancialTransactionModal', priority: 95, gradient: 'urgent' },
    { name: 'Rate Product', type: 'IN_APP', modal: 'ReviewRatingModal', priority: 70, gradient: 'lifestyle' },
    { name: 'Track Package', type: 'IN_APP', modal: 'TrackingModal', priority: 85, gradient: 'ads' },
    { name: 'Set Reminder', type: 'IN_APP', modal: 'GenericActionModal', priority: 80, gradient: 'mail' }
  ];

  let xOffset = 0;
  let yOffset = 0;
  const cardWidth = 280;
  const cardHeight = 220;
  const phoneWidth = 375;
  const gap = 40;
  const containerWidth = cardWidth + 20 + phoneWidth; // card + spacing + phone
  const cardsPerRow = 1; // One action card + phone per row (they're wide)

  sampleActions.forEach((action, index) => {
    const container = createActionCard(action, cardWidth, cardHeight);
    container.x = xOffset;
    container.y = yOffset;
    page.appendChild(container);

    yOffset += 812 + gap; // Phone height + gap (vertical stacking)
  });

  // Add legend at bottom
  const legendY = yOffset + 60;

  const legendFrame = figma.createFrame();
  legendFrame.name = 'Legend';
  legendFrame.x = 0;
  legendFrame.y = legendY;
  legendFrame.resize(1200, 250);
  legendFrame.fills = createSolidFill('#1C1C1E', 0.3);
  legendFrame.layoutMode = 'VERTICAL';
  legendFrame.itemSpacing = 12;
  legendFrame.paddingTop = 20;
  legendFrame.paddingLeft = 20;
  legendFrame.paddingRight = 20;
  legendFrame.paddingBottom = 20;

  const legendTitle = figma.createText();
  legendTitle.characters = 'Legend & Summary';
  legendTitle.fontSize = 20;
  legendTitle.fontName = { family: "Inter", style: "Bold" };
  legendTitle.fills = createSolidFill('#FFFFFF');
  legendFrame.appendChild(legendTitle);

  const legendItems = [
    'LEFT: Action card from email (tap to trigger action)',
    'RIGHT: Phone screen showing next step (browser, modal, share sheet, etc.)',
    '↗ Icon = GO_TO action (opens external app in browser)',
    'IN_APP actions = Show modal, calendar picker, or message composer',
    'Badge = Priority level (95=Critical → 60=Very Low)',
    'Total: 169 actions (103 GO_TO + 66 IN_APP)'
  ];

  legendItems.forEach(item => {
    const text = figma.createText();
    text.characters = item;
    text.fontSize = 14;
    text.fills = createSolidFill('#FFFFFF', 0.8);
    legendFrame.appendChild(text);
  });

  page.appendChild(legendFrame);

  figma.currentPage = page;
}

/**
 * Create iPhone frame (375×812px)
 */
function createPhoneFrame(): FrameNode {
  const phone = figma.createFrame();
  phone.name = 'iPhone Frame';
  phone.resize(375, 812);
  phone.cornerRadius = 40;
  phone.fills = createSolidFill('#000000');

  // Status bar
  const statusBar = figma.createFrame();
  statusBar.name = 'Status Bar';
  statusBar.resize(375, 44);
  statusBar.fills = createSolidFill('#000000', 0.8);
  statusBar.x = 0;
  statusBar.y = 0;

  const time = figma.createText();
  time.characters = '9:41';
  time.fontSize = 15;
  time.fontName = { family: "Inter", style: "Bold" };
  time.fills = createSolidFill('#FFFFFF');
  time.x = 20;
  time.y = 15;
  statusBar.appendChild(time);

  phone.appendChild(statusBar);

  return phone;
}

/**
 * Create browser screen for GO_TO actions
 */
function createBrowserScreen(phone: FrameNode, actionName: string) {
  const browser = figma.createFrame();
  browser.name = 'Browser';
  browser.resize(375, 768);
  browser.x = 0;
  browser.y = 44;
  browser.fills = createSolidFill('#FFFFFF');

  // Address bar
  const addressBar = figma.createFrame();
  addressBar.name = 'Address Bar';
  addressBar.resize(343, 44);
  addressBar.x = 16;
  addressBar.y = 16;
  addressBar.cornerRadius = 12;
  addressBar.fills = createSolidFill('#F2F2F7');
  addressBar.layoutMode = 'HORIZONTAL';
  addressBar.paddingLeft = 12;
  addressBar.counterAxisAlignItems = 'CENTER';

  const urlText = figma.createText();
  urlText.characters = 'example.com';
  urlText.fontSize = 14;
  urlText.fills = createSolidFill('#8E8E93');
  addressBar.appendChild(urlText);

  browser.appendChild(addressBar);

  // Content area
  const content = figma.createFrame();
  content.name = 'Content';
  content.resize(343, 650);
  content.x = 16;
  content.y = 80;
  content.fills = createSolidFill('#FFFFFF');
  content.layoutMode = 'VERTICAL';
  content.itemSpacing = 16;
  content.paddingTop = 20;

  const title = figma.createText();
  title.characters = actionName;
  title.fontSize = 24;
  title.fontName = { family: "Inter", style: "Bold" };
  title.fills = createSolidFill('#000000');
  content.appendChild(title);

  const body = figma.createText();
  body.characters = 'External content loading...';
  body.fontSize = 16;
  body.fills = createSolidFill('#8E8E93');
  content.appendChild(body);

  browser.appendChild(content);
  phone.appendChild(browser);
}

/**
 * Create calendar modal for calendar actions
 */
function createCalendarModal(phone: FrameNode, actionName: string) {
  const screen = figma.createFrame();
  screen.name = 'Calendar Modal';
  screen.resize(375, 768);
  screen.x = 0;
  screen.y = 44;
  screen.fills = createSolidFill('#000000', 0.5);

  // Modal
  const modal = figma.createFrame();
  modal.name = 'Modal';
  modal.resize(343, 500);
  modal.x = 16;
  modal.y = 150;
  modal.cornerRadius = TOKENS.radius.modal;
  modal.fills = createSolidFill('#1C1C1E');
  modal.layoutMode = 'VERTICAL';
  modal.itemSpacing = 20;
  modal.paddingTop = 24;
  modal.paddingBottom = 24;
  modal.paddingLeft = 16;
  modal.paddingRight = 16;

  // Header
  const header = figma.createText();
  header.characters = actionName;
  header.fontSize = 24;
  header.fontName = { family: "Inter", style: "Bold" };
  header.fills = createSolidFill('#FFFFFF');
  modal.appendChild(header);

  // Calendar picker
  const picker = figma.createFrame();
  picker.name = 'Date Picker';
  picker.resize(311, 200);
  picker.cornerRadius = 12;
  picker.fills = createSolidFill('#2C2C2E');
  picker.layoutMode = 'VERTICAL';
  picker.primaryAxisAlignItems = 'CENTER';
  picker.counterAxisAlignItems = 'CENTER';
  picker.paddingTop = 60;

  const dateText = figma.createText();
  dateText.characters = 'Nov 10, 2025';
  dateText.fontSize = 28;
  dateText.fontName = { family: "Inter", style: "Bold" };
  dateText.fills = createSolidFill('#FFFFFF');
  picker.appendChild(dateText);

  modal.appendChild(picker);

  // Time picker
  const timePicker = figma.createFrame();
  timePicker.name = 'Time Picker';
  timePicker.resize(311, 100);
  timePicker.cornerRadius = 12;
  timePicker.fills = createSolidFill('#2C2C2E');
  timePicker.layoutMode = 'VERTICAL';
  timePicker.primaryAxisAlignItems = 'CENTER';
  timePicker.counterAxisAlignItems = 'CENTER';
  timePicker.paddingTop = 30;

  const timeText = figma.createText();
  timeText.characters = '2:30 PM';
  timeText.fontSize = 24;
  timeText.fontName = { family: "Inter", style: "Bold" };
  timeText.fills = createSolidFill('#FFFFFF');
  timePicker.appendChild(timeText);

  modal.appendChild(timePicker);

  // Button
  const button = figma.createRectangle();
  button.name = 'Add Button';
  button.resize(311, 56);
  button.cornerRadius = TOKENS.radius.button;
  button.fills = createGradient(TOKENS.colors.gradients.mail.start, TOKENS.colors.gradients.mail.end);
  modal.appendChild(button);

  screen.appendChild(modal);
  phone.appendChild(screen);
}

/**
 * Create system share sheet for social actions
 */
function createShareSheet(phone: FrameNode, actionName: string) {
  const screen = figma.createFrame();
  screen.name = 'Share Sheet';
  screen.resize(375, 768);
  screen.x = 0;
  screen.y = 44;
  screen.fills = createSolidFill('#000000', 0.5);

  // Sheet
  const sheet = figma.createFrame();
  sheet.name = 'Sheet';
  sheet.resize(375, 400);
  sheet.x = 0;
  sheet.y = 368;
  sheet.cornerRadius = TOKENS.radius.modal;
  sheet.fills = createSolidFill('#1C1C1E');
  sheet.layoutMode = 'VERTICAL';
  sheet.itemSpacing = 20;
  sheet.paddingTop = 24;
  sheet.paddingBottom = 24;
  sheet.paddingLeft = 16;
  sheet.paddingRight = 16;

  const header = figma.createText();
  header.characters = 'Share via';
  header.fontSize = 20;
  header.fontName = { family: "Inter", style: "Bold" };
  header.fills = createSolidFill('#FFFFFF');
  sheet.appendChild(header);

  // Share options (icons row)
  const optionsRow = figma.createFrame();
  optionsRow.name = 'Options';
  optionsRow.resize(343, 80);
  optionsRow.fills = [];
  optionsRow.layoutMode = 'HORIZONTAL';
  optionsRow.itemSpacing = 20;

  const apps = ['Messages', 'Mail', 'Twitter', 'Copy'];
  apps.forEach(app => {
    const option = figma.createFrame();
    option.name = app;
    option.resize(60, 80);
    option.fills = [];
    option.layoutMode = 'VERTICAL';
    option.itemSpacing = 8;
    option.primaryAxisAlignItems = 'CENTER';

    const icon = figma.createEllipse();
    icon.resize(60, 60);
    icon.fills = createSolidFill('#667eea');
    option.appendChild(icon);

    const label = figma.createText();
    label.characters = app;
    label.fontSize = 12;
    label.fills = createSolidFill('#FFFFFF');
    option.appendChild(label);

    optionsRow.appendChild(option);
  });

  sheet.appendChild(optionsRow);
  screen.appendChild(sheet);
  phone.appendChild(screen);
}

/**
 * Create message composer for communication actions
 */
function createMessageComposer(phone: FrameNode, actionName: string) {
  const screen = figma.createFrame();
  screen.name = 'Message Composer';
  screen.resize(375, 768);
  screen.x = 0;
  screen.y = 44;
  screen.fills = createSolidFill('#000000');

  // Nav bar
  const nav = figma.createFrame();
  nav.name = 'Nav Bar';
  nav.resize(375, 60);
  nav.x = 0;
  nav.y = 0;
  nav.fills = createSolidFill('#1C1C1E');
  nav.layoutMode = 'HORIZONTAL';
  nav.primaryAxisAlignItems = 'CENTER';
  nav.counterAxisAlignItems = 'CENTER';
  nav.paddingLeft = 16;
  nav.paddingRight = 16;
  nav.itemSpacing = 80;

  const cancelBtn = figma.createText();
  cancelBtn.characters = 'Cancel';
  cancelBtn.fontSize = 17;
  cancelBtn.fills = createSolidFill('#667eea');
  nav.appendChild(cancelBtn);

  const title = figma.createText();
  title.characters = actionName;
  title.fontSize = 17;
  title.fontName = { family: "Inter", style: "Bold" };
  title.fills = createSolidFill('#FFFFFF');
  nav.appendChild(title);

  const sendBtn = figma.createText();
  sendBtn.characters = 'Send';
  sendBtn.fontSize = 17;
  sendBtn.fontName = { family: "Inter", style: "Bold" };
  sendBtn.fills = createSolidFill('#667eea');
  nav.appendChild(sendBtn);

  screen.appendChild(nav);

  // Message input
  const input = figma.createFrame();
  input.name = 'Input';
  input.resize(343, 200);
  input.x = 16;
  input.y = 80;
  input.cornerRadius = 12;
  input.fills = createSolidFill('#2C2C2E');
  input.layoutMode = 'VERTICAL';
  input.paddingTop = 16;
  input.paddingLeft = 16;

  const placeholder = figma.createText();
  placeholder.characters = 'Type your message...';
  placeholder.fontSize = 16;
  placeholder.fills = createSolidFill('#8E8E93');
  input.appendChild(placeholder);

  screen.appendChild(input);
  phone.appendChild(screen);
}

/**
 * Determine which screen to show based on action
 */
function getScreenForAction(phone: FrameNode, action: any) {
  if (action.type === 'GO_TO') {
    createBrowserScreen(phone, action.name);
  } else if (action.name.includes('Calendar') || action.name.includes('Reminder')) {
    createCalendarModal(phone, action.name);
  } else if (action.name.includes('Share') || action.name.includes('Social')) {
    createShareSheet(phone, action.name);
  } else if (action.name.includes('Reply') || action.name.includes('Message')) {
    createMessageComposer(phone, action.name);
  } else {
    // Default: Generic modal
    createCalendarModal(phone, action.name); // Reuse calendar modal structure
  }
}

/**
 * Create a single action card with phone screen showing next step
 */
function createActionCard(action: any, width: number, height: number) {
  // Container holding both card and phone
  const container = figma.createFrame();
  container.name = `${action.name} + Phone`;
  container.resize(width + 395, 812); // Card width + gap + phone width
  container.fills = [];
  container.layoutMode = 'HORIZONTAL';
  container.itemSpacing = 20;
  container.primaryAxisAlignItems = 'CENTER';

  // === ACTION CARD (LEFT) ===
  const card = figma.createFrame();
  card.name = action.name;
  card.resize(width, 220);  // Action cards can stay compact for overview
  card.cornerRadius = TOKENS.radius.card;  // Now 24px

  // Gradient background
  const gradientKey = action.gradient as keyof typeof TOKENS.colors.gradients;
  const gradient = TOKENS.colors.gradients[gradientKey];
  card.fills = createGradient(gradient.start, gradient.end);

  // Shadow
  card.effects = [{
    type: 'DROP_SHADOW',
    color: { r: 0, g: 0, b: 0, a: 0.4 },
    offset: { x: 0, y: 10 },
    radius: 20,
    visible: true,
    blendMode: 'NORMAL'
  }];

  card.layoutMode = 'VERTICAL';
  card.itemSpacing = 12;
  card.paddingTop = TOKENS.spacing.card;
  card.paddingBottom = TOKENS.spacing.card;
  card.paddingLeft = TOKENS.spacing.card;
  card.paddingRight = TOKENS.spacing.card;

  const textColor = action.gradient === 'ads' ? TOKENS.colors.adsText.primary : '#FFFFFF';
  const textOpacity = action.gradient === 'ads' ? 0.9 : 1.0;

  // Header row
  const headerRow = figma.createFrame();
  headerRow.name = 'Header';
  headerRow.resize(width - 48, 20);
  headerRow.fills = [];
  headerRow.layoutMode = 'HORIZONTAL';
  headerRow.primaryAxisSizingMode = 'FIXED';
  headerRow.counterAxisSizingMode = 'FIXED';

  const sender = figma.createText();
  sender.characters = 'sender@example.com';
  sender.fontSize = 13;
  sender.fills = createSolidFill(textColor, textOpacity * 0.7);
  headerRow.appendChild(sender);

  const spacer = figma.createFrame();
  spacer.resize(80, 20);
  spacer.fills = [];
  headerRow.appendChild(spacer);

  const priorityColor = getPriorityColor(action.priority);
  const badge = figma.createEllipse();
  badge.name = 'Priority';
  badge.resize(12, 12);
  badge.fills = createSolidFill(priorityColor);
  headerRow.appendChild(badge);

  card.appendChild(headerRow);

  // Subject
  const subject = figma.createText();
  subject.characters = action.name;
  subject.fontSize = 19;
  subject.fontName = { family: "Inter", style: "Bold" };
  subject.fills = createSolidFill(textColor, textOpacity);
  card.appendChild(subject);

  // Preview
  const preview = figma.createText();
  preview.characters = action.type === 'GO_TO'
    ? 'Tap to open in external app ↗'
    : `Opens ${action.modal || 'modal'} in app`;
  preview.fontSize = 15;
  preview.fills = createSolidFill(textColor, textOpacity * 0.8);
  card.appendChild(preview);

  // Actions header
  const actionsHeader = figma.createText();
  actionsHeader.characters = 'Actions';
  actionsHeader.fontSize = 15;
  actionsHeader.fontName = { family: "Inter", style: "Bold" };
  actionsHeader.fills = createSolidFill(textColor, textOpacity * 0.9);
  card.appendChild(actionsHeader);

  // Action button
  const actionButton = figma.createFrame();
  actionButton.name = 'Action Button';
  actionButton.resize(width - 48, 44);
  actionButton.cornerRadius = TOKENS.radius.button;
  actionButton.fills = createSolidFill('#FFFFFF', 0.15);
  actionButton.layoutMode = 'HORIZONTAL';
  actionButton.primaryAxisAlignItems = 'CENTER';
  actionButton.counterAxisAlignItems = 'CENTER';
  actionButton.paddingLeft = 16;
  actionButton.paddingRight = 16;

  const buttonText = figma.createText();
  buttonText.characters = action.type === 'GO_TO' ? `${action.name} ↗` : action.name;
  buttonText.fontSize = 15;
  buttonText.fontName = { family: "Inter", style: "Bold" };
  buttonText.fills = createSolidFill(textColor, textOpacity);
  actionButton.appendChild(buttonText);

  card.appendChild(actionButton);

  container.appendChild(card);

  // === PHONE SCREEN (RIGHT) ===
  const phone = createPhoneFrame();
  getScreenForAction(phone, action);
  container.appendChild(phone);

  return container;
}

/**
 * Get priority color from priority value (4 levels to match iOS)
 */
function getPriorityColor(priority: number): string {
  if (priority >= 95) return '#FF3B30'; // Critical (Red)
  if (priority >= 85) return '#FF9500'; // High (Orange)
  if (priority >= 75) return '#8E8E93'; // Medium (Gray)
  return '#5AC8FA'; // Low (Light Blue)
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================

async function generateAll() {
  console.log('🚀 Generating complete design system...');

  // Load fonts
  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  await figma.loadFontAsync({ family: "Inter", style: "Bold" });

  // Generate all pages
  generateTokensPage();
  generateAtomicComponents();
  generateEmailCards();
  generateAdsEmailPage();
  generateWorkEmailPage();
  generateGoToFeedback();
  generateModalTemplates();
  generateActionSelectorPage();
  generateActionsPage();

  console.log('✅ Design system generated!');
  figma.closePlugin('✅ Design system generated successfully!');
}

// Run the generator
figma.showUI(__html__, { visible: false });
generateAll();

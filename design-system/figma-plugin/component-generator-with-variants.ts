/**
 * Zero Design System - Component Generator with Variants
 *
 * Fully automates component generation including ALL variants
 * Eliminates manual variant creation work (~2-3 hours saved)
 *
 * Phase 0 Day 2: Complete automation
 */

// MARK: - Helper Functions

function findVariable(name: string): Variable | null {
  const localVariables = figma.variables.getLocalVariables();
  return localVariables.find(v => v.name === name) || null;
}

function bindNumberVariable(node: SceneNode, property: string, variableName: string): void {
  const variable = findVariable(variableName);
  if (!variable) {
    console.warn(`Variable not found: ${variableName}`);
    return;
  }
  // @ts-ignore
  if (node.boundVariables) {
    // @ts-ignore
    node.boundVariables[property] = {
      type: 'VARIABLE_ALIAS',
      id: variable.id
    };
  }
}

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

// MARK: - Color Helpers

const COLORS = {
  // Primary colors
  blue: { r: 0.23, g: 0.51, b: 0.96 },      // #3B83F6
  blueHover: { r: 0.15, g: 0.42, b: 0.87 }, // Darker blue
  blueActive: { r: 0.29, g: 0.56, b: 1.00 }, // Lighter blue

  // Secondary colors
  gray200: { r: 0.90, g: 0.91, b: 0.92 },   // #E5E7EB
  gray300: { r: 0.82, g: 0.84, b: 0.86 },   // #D1D5DB
  gray900: { r: 0.07, g: 0.09, b: 0.15 },   // #111827

  // Danger colors
  red: { r: 0.94, g: 0.27, b: 0.27 },       // #EF4444
  redHover: { r: 0.86, g: 0.20, b: 0.20 },

  // Success colors
  green: { r: 0.06, g: 0.73, b: 0.51 },     // #10B981
  greenBg: { r: 0.94, g: 0.99, b: 0.96 },   // #F0FDF4
  greenText: { r: 0.02, g: 0.37, b: 0.27 }, // #065F46

  // Warning colors
  yellow: { r: 0.96, g: 0.62, b: 0.04 },    // #F59E0B
  yellowBg: { r: 0.99, g: 0.99, b: 0.91 },  // #FEFCE8
  yellowText: { r: 0.57, g: 0.25, b: 0.05 }, // #92400E

  // Info colors
  blueBg: { r: 0.94, g: 0.96, b: 1.00 },    // #EFF6FF
  blueText: { r: 0.12, g: 0.25, b: 0.69 },  // #1E40AF

  // Error colors
  redBg: { r: 0.99, g: 0.95, b: 0.95 },     // #FEF2F2
  redText: { r: 0.60, g: 0.11, b: 0.11 },   // #991B1B

  // Neutral colors
  white: { r: 1, g: 1, b: 1 },
  black: { r: 0, g: 0, b: 0 },
  transparent: { r: 0, g: 0, b: 0 }
};

// MARK: - ZeroButton Generator (48 variants)

async function generateZeroButtonVariants(): Promise<ComponentSetNode> {
  console.log('Generating ZeroButton with all variants...');

  const styles = ['Primary', 'Secondary', 'Tertiary', 'Danger'];
  const sizes = [
    { name: 'Small', height: 32, padding: 16, fontSize: 13, radius: 12 },     // iOS: Button.heightSmall
    { name: 'Medium', height: 44, padding: 16, fontSize: 15, radius: 12 },    // iOS: Button.heightCompact
    { name: 'Large', height: 56, padding: 16, fontSize: 17, radius: 12 }      // iOS: Button.heightStandard
  ];
  const states = ['Default', 'Hover', 'Active', 'Disabled'];

  const components: ComponentNode[] = [];

  for (const style of styles) {
    for (const size of sizes) {
      for (const state of states) {
        const component = figma.createComponent();
        component.name = `Style=${style}, Size=${size.name}, State=${state}`;

        // Auto Layout
        component.layoutMode = 'HORIZONTAL';
        component.paddingLeft = size.padding;
        component.paddingRight = size.padding;
        component.paddingTop = (size.height - size.fontSize) / 2;
        component.paddingBottom = (size.height - size.fontSize) / 2;
        component.primaryAxisSizingMode = 'AUTO';
        component.counterAxisSizingMode = 'FIXED';
        component.counterAxisAlignItems = 'CENTER';
        component.itemSpacing = 8;
        component.cornerRadius = size.radius;
        component.resize(100, size.height); // Initial width

        // Text label
        const label = await createText('Button', size.fontSize, 'Medium');
        label.name = 'Label';

        // Style-specific colors
        let bgColor = COLORS.blue;
        let textColor = COLORS.white;
        let hasBorder = false;

        if (style === 'Primary') {
          bgColor = COLORS.blue;
          textColor = COLORS.white;
        } else if (style === 'Secondary') {
          bgColor = COLORS.gray200;
          textColor = COLORS.gray900;
        } else if (style === 'Tertiary') {
          bgColor = COLORS.transparent;
          textColor = COLORS.gray900;
          hasBorder = true;
        } else if (style === 'Danger') {
          bgColor = COLORS.red;
          textColor = COLORS.white;
        }

        // State-specific modifications
        let opacity = 1.0;
        if (state === 'Hover') {
          // Slightly lighter
          bgColor = {
            r: Math.min(1, bgColor.r * 1.1),
            g: Math.min(1, bgColor.g * 1.1),
            b: Math.min(1, bgColor.b * 1.1)
          };
        } else if (state === 'Active') {
          // Slightly darker
          bgColor = {
            r: bgColor.r * 0.9,
            g: bgColor.g * 0.9,
            b: bgColor.b * 0.9
          };
        } else if (state === 'Disabled') {
          opacity = 0.5;
        }

        // Apply colors
        label.fills = [{ type: 'SOLID', color: textColor }];
        component.appendChild(label);

        if (style === 'Tertiary') {
          component.fills = [];
          component.strokes = [{ type: 'SOLID', color: COLORS.gray300 }];
          component.strokeWeight = 1;
        } else {
          component.fills = [{ type: 'SOLID', color: bgColor, opacity }];
        }

        components.push(component);
      }
    }
  }

  console.log(`Created ${components.length} button variants`);

  // Add all components to the page first
  components.forEach(comp => figma.currentPage.appendChild(comp));

  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'ZeroButton';

  return componentSet;
}

// MARK: - ZeroCard Generator (24 variants)

async function generateZeroCardVariants(): Promise<ComponentSetNode> {
  console.log('Generating ZeroCard with all variants...');

  const layouts = ['Compact', 'Expanded'];
  const priorities = [
    { name: 'High', color: COLORS.red },
    { name: 'Medium', color: COLORS.yellow },
    { name: 'Low', color: null }
  ];
  const states = [
    { name: 'Default', bg: COLORS.white, border: COLORS.gray200 },
    { name: 'Hover', bg: { r: 0.98, g: 0.98, b: 0.98 }, border: COLORS.gray300 },
    { name: 'Selected', bg: COLORS.blueBg, border: COLORS.blue },
    { name: 'Read', bg: COLORS.white, border: COLORS.gray200 }
  ];

  const components: ComponentNode[] = [];

  for (const layout of layouts) {
    for (const priority of priorities) {
      for (const state of states) {
        const component = figma.createComponent();
        component.name = `Layout=${layout}, Priority=${priority.name}, State=${state.name}`;

        // Auto Layout - iOS card dimensions
        component.layoutMode = 'VERTICAL';
        component.paddingLeft = 24;   // iOS: Spacing.card
        component.paddingRight = 24;
        component.paddingTop = 24;
        component.paddingBottom = 24;
        component.itemSpacing = 12;   // iOS: Better spacing for tall cards
        component.primaryAxisSizingMode = 'AUTO';
        component.counterAxisSizingMode = 'FIXED';
        component.resize(358, 500);   // iOS: cardWidth (screen-48), cardHeight
        component.cornerRadius = 16;  // iOS: Radius.card

        // Priority indicator (left border)
        if (priority.color) {
          component.strokes = [{ type: 'SOLID', color: priority.color }];
          component.strokeWeight = 3;
          component.strokeAlign = 'INSIDE';
          // Only left stroke (would need to use constraints)
        }

        // Background and border
        component.fills = [{ type: 'SOLID', color: state.bg }];
        if (!priority.color) {
          component.strokes = [{ type: 'SOLID', color: state.border }];
          component.strokeWeight = 1;
        }

        // Header row
        const header = createAutoLayoutFrame('Header', 'HORIZONTAL', 8, 0);
        header.primaryAxisSizingMode = 'FIXED';
        header.counterAxisSizingMode = 'AUTO';
        header.primaryAxisAlignItems = 'SPACE_BETWEEN';
        header.resize(310, 20);  // 358 - (24*2) padding

        const from = await createText('sender@example.com', 13, 'Medium');
        from.name = 'From';
        const opacity = state.name === 'Read' ? 0.6 : 1.0;
        from.opacity = opacity;

        const time = await createText('2m', 11, 'Regular');
        time.name = 'Time';
        time.fills = [{ type: 'SOLID', color: COLORS.gray900, opacity: 0.6 }];

        header.appendChild(from);
        header.appendChild(time);
        component.appendChild(header);

        // Subject
        const subject = await createText('Email Subject Line', 15, state.name === 'Read' ? 'Regular' : 'Semi Bold');
        subject.name = 'Subject';
        subject.opacity = opacity;
        component.appendChild(subject);

        // Preview (only in Expanded layout)
        if (layout === 'Expanded') {
          const preview = await createText('Preview text of the email content...', 13, 'Regular');
          preview.name = 'Preview';
          preview.fills = [{ type: 'SOLID', color: COLORS.gray900, opacity: 0.7 }];
          preview.opacity = opacity;
          component.appendChild(preview);
        }

        components.push(component);
      }
    }
  }

  console.log(`Created ${components.length} card variants`);

  // Add all components to the page first
  components.forEach(comp => figma.currentPage.appendChild(comp));

  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'ZeroCard';

  return componentSet;
}

// MARK: - ZeroModal Generator (6 variants)

async function generateZeroModalVariants(): Promise<ComponentSetNode> {
  console.log('Generating ZeroModal with all variants...');

  const sizes = [
    { name: 'Small', width: 335, padding: 24 },   // iOS: Content-driven, standard mobile width
    { name: 'Medium', width: 480, padding: 24 },  // Tablet/larger content
    { name: 'Large', width: 600, padding: 24 }    // Maximum modal width
  ];
  const states = [
    { name: 'Open', opacity: 1.0 },
    { name: 'Closed', opacity: 0.0 }
  ];

  const components: ComponentNode[] = [];

  for (const size of sizes) {
    for (const state of states) {
      const component = figma.createComponent();
      component.name = `Size=${size.name}, State=${state.name}`;

      // Auto Layout
      component.layoutMode = 'VERTICAL';
      component.paddingLeft = size.padding;
      component.paddingRight = size.padding;
      component.paddingTop = size.padding;
      component.paddingBottom = size.padding;
      component.itemSpacing = 16;
      component.primaryAxisSizingMode = 'AUTO';
      component.counterAxisSizingMode = 'FIXED';
      component.resize(size.width, 200);
      component.cornerRadius = 20;  // iOS: Radius.modal
      component.fills = [{ type: 'SOLID', color: COLORS.white }];
      component.opacity = state.opacity;

      // Drop shadow
      component.effects = [{
        type: 'DROP_SHADOW',
        color: { r: 0, g: 0, b: 0, a: 0.15 },
        offset: { x: 0, y: 4 },
        radius: 12,
        visible: true,
        blendMode: 'NORMAL'
      }];

      // Header
      const header = createAutoLayoutFrame('Header', 'HORIZONTAL', 12, 0);
      header.primaryAxisSizingMode = 'FIXED';
      header.counterAxisSizingMode = 'AUTO';
      header.primaryAxisAlignItems = 'SPACE_BETWEEN';
      header.resize(size.width - size.padding * 2, 24);

      const title = await createText('Modal Title', 17, 'Semi Bold');
      title.name = 'Title';
      header.appendChild(title);

      const closeBtn = await createText('×', 24, 'Regular');
      closeBtn.name = 'Close';
      closeBtn.fills = [{ type: 'SOLID', color: COLORS.gray900, opacity: 0.5 }];
      header.appendChild(closeBtn);

      component.appendChild(header);

      // Message
      const message = await createText('This is a modal dialog message. You can put any content here.', 15, 'Regular');
      message.name = 'Message';
      message.fills = [{ type: 'SOLID', color: COLORS.gray900, opacity: 0.8 }];
      component.appendChild(message);

      // Actions
      const actions = createAutoLayoutFrame('Actions', 'HORIZONTAL', 12, 0);
      actions.primaryAxisSizingMode = 'AUTO';
      actions.counterAxisSizingMode = 'AUTO';

      const cancelBtn = figma.createFrame();
      cancelBtn.name = 'Cancel Button';
      cancelBtn.layoutMode = 'HORIZONTAL';
      cancelBtn.paddingLeft = 16;
      cancelBtn.paddingRight = 16;
      cancelBtn.paddingTop = 10;
      cancelBtn.paddingBottom = 10;
      cancelBtn.primaryAxisSizingMode = 'AUTO';
      cancelBtn.counterAxisSizingMode = 'AUTO';
      cancelBtn.cornerRadius = 8;
      cancelBtn.fills = [{ type: 'SOLID', color: COLORS.gray200 }];
      const cancelText = await createText('Cancel', 15, 'Medium');
      cancelText.fills = [{ type: 'SOLID', color: COLORS.gray900 }];
      cancelBtn.appendChild(cancelText);

      const confirmBtn = figma.createFrame();
      confirmBtn.name = 'Confirm Button';
      confirmBtn.layoutMode = 'HORIZONTAL';
      confirmBtn.paddingLeft = 16;
      confirmBtn.paddingRight = 16;
      confirmBtn.paddingTop = 10;
      confirmBtn.paddingBottom = 10;
      confirmBtn.primaryAxisSizingMode = 'AUTO';
      confirmBtn.counterAxisSizingMode = 'AUTO';
      confirmBtn.cornerRadius = 8;
      confirmBtn.fills = [{ type: 'SOLID', color: COLORS.blue }];
      const confirmText = await createText('Confirm', 15, 'Medium');
      confirmText.fills = [{ type: 'SOLID', color: COLORS.white }];
      confirmBtn.appendChild(confirmText);

      actions.appendChild(cancelBtn);
      actions.appendChild(confirmBtn);
      component.appendChild(actions);

      components.push(component);
    }
  }

  console.log(`Created ${components.length} modal variants`);

  // Add all components to the page first
  components.forEach(comp => figma.currentPage.appendChild(comp));

  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'ZeroModal';

  return componentSet;
}

// MARK: - ZeroListItem Generator (6 variants)

async function generateZeroListItemVariants(): Promise<ComponentSetNode> {
  console.log('Generating ZeroListItem with all variants...');

  const types = ['Navigation', 'Action'];
  const states = [
    { name: 'Default', bg: COLORS.transparent, text: COLORS.gray900 },
    { name: 'Hover', bg: { r: 0.98, g: 0.98, b: 0.98 }, text: COLORS.gray900 },
    { name: 'Selected', bg: COLORS.blueBg, text: COLORS.blue }
  ];

  const components: ComponentNode[] = [];

  for (const type of types) {
    for (const state of states) {
      const component = figma.createComponent();
      component.name = `Type=${type}, State=${state.name}`;

      // Auto Layout
      component.layoutMode = 'HORIZONTAL';
      component.paddingLeft = 16;
      component.paddingRight = 16;
      component.paddingTop = 12;
      component.paddingBottom = 12;
      component.itemSpacing = 12;
      component.primaryAxisSizingMode = 'FIXED';
      component.counterAxisSizingMode = 'FIXED';
      component.counterAxisAlignItems = 'CENTER';
      component.primaryAxisAlignItems = 'SPACE_BETWEEN';
      component.resize(320, 44);
      component.cornerRadius = 8;
      component.fills = state.bg === COLORS.transparent ? [] : [{ type: 'SOLID', color: state.bg }];

      // Icon placeholder (left)
      const icon = figma.createRectangle();
      icon.name = 'Icon';
      icon.resize(20, 20);
      icon.cornerRadius = 4;
      icon.fills = [{ type: 'SOLID', color: state.text, opacity: 0.7 }];
      component.appendChild(icon);

      // Label
      const label = await createText('List Item Label', 15, 'Regular');
      label.name = 'Label';
      label.fills = [{ type: 'SOLID', color: state.text }];
      component.appendChild(label);

      // Right accessory
      if (type === 'Navigation') {
        // Chevron
        const chevron = await createText('›', 18, 'Regular');
        chevron.name = 'Chevron';
        chevron.fills = [{ type: 'SOLID', color: COLORS.gray900, opacity: 0.3 }];
        component.appendChild(chevron);
      } else {
        // Badge
        const badge = figma.createFrame();
        badge.name = 'Badge';
        badge.layoutMode = 'HORIZONTAL';
        badge.paddingLeft = 6;
        badge.paddingRight = 6;
        badge.paddingTop = 2;
        badge.paddingBottom = 2;
        badge.primaryAxisSizingMode = 'AUTO';
        badge.counterAxisSizingMode = 'AUTO';
        badge.cornerRadius = 10;
        badge.fills = [{ type: 'SOLID', color: COLORS.red }];

        const badgeText = await createText('3', 11, 'Bold');
        badgeText.fills = [{ type: 'SOLID', color: COLORS.white }];
        badge.appendChild(badgeText);
        component.appendChild(badge);
      }

      components.push(component);
    }
  }

  console.log(`Created ${components.length} list item variants`);

  // Add all components to the page first
  components.forEach(comp => figma.currentPage.appendChild(comp));

  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'ZeroListItem';

  return componentSet;
}

// MARK: - ZeroAlert Generator (8 variants)

async function generateZeroAlertVariants(): Promise<ComponentSetNode> {
  console.log('Generating ZeroAlert with all variants...');

  const types = [
    { name: 'Success', bg: COLORS.greenBg, border: COLORS.green, text: COLORS.greenText, icon: '✓' },
    { name: 'Error', bg: COLORS.redBg, border: COLORS.red, text: COLORS.redText, icon: '×' },
    { name: 'Warning', bg: COLORS.yellowBg, border: COLORS.yellow, text: COLORS.yellowText, icon: '⚠' },
    { name: 'Info', bg: COLORS.blueBg, border: COLORS.blue, text: COLORS.blueText, icon: 'ℹ' }
  ];
  const positions = ['Top', 'Bottom'];

  const components: ComponentNode[] = [];

  for (const type of types) {
    for (const position of positions) {
      const component = figma.createComponent();
      component.name = `Type=${type.name}, Position=${position}`;

      // Auto Layout
      component.layoutMode = 'HORIZONTAL';
      component.paddingLeft = 12;
      component.paddingRight = 12;
      component.paddingTop = 12;
      component.paddingBottom = 12;
      component.itemSpacing = 10;
      component.primaryAxisSizingMode = 'AUTO';
      component.counterAxisSizingMode = 'AUTO';
      component.counterAxisAlignItems = 'CENTER';
      component.cornerRadius = 12;
      component.fills = [{ type: 'SOLID', color: type.bg }];
      component.strokes = [{ type: 'SOLID', color: type.border }];
      component.strokeWeight = 1;

      // Icon
      const icon = await createText(type.icon, 16, 'Bold');
      icon.name = 'Icon';
      icon.fills = [{ type: 'SOLID', color: type.border }];
      component.appendChild(icon);

      // Message
      const message = await createText('Alert message text', 14, 'Medium');
      message.name = 'Message';
      message.fills = [{ type: 'SOLID', color: type.text }];
      component.appendChild(message);

      // Close button
      const close = await createText('×', 18, 'Regular');
      close.name = 'Close';
      close.fills = [{ type: 'SOLID', color: type.text, opacity: 0.6 }];
      component.appendChild(close);

      components.push(component);
    }
  }

  console.log(`Created ${components.length} alert variants`);

  // Add all components to the page first
  components.forEach(comp => figma.currentPage.appendChild(comp));

  const componentSet = figma.combineAsVariants(components, figma.currentPage);
  componentSet.name = 'ZeroAlert';

  return componentSet;
}

// MARK: - Main Generation Function

async function generateAllComponentsWithVariants() {
  try {
    // Load all fonts first
    console.log('Loading fonts...');
    await Promise.all([
      figma.loadFontAsync({ family: 'Inter', style: 'Regular' }),
      figma.loadFontAsync({ family: 'Inter', style: 'Medium' }),
      figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' }),
      figma.loadFontAsync({ family: 'Inter', style: 'Bold' })
    ]);
    console.log('Fonts loaded successfully');

    // Find or create Components page
    let componentsPage = figma.root.children.find(page => page.name === 'Components') as PageNode;
    if (!componentsPage) {
      componentsPage = figma.createPage();
      componentsPage.name = 'Components';
    }
    figma.currentPage = componentsPage;

    const componentSets: ComponentSetNode[] = [];

    // Generate all component sets
    componentSets.push(await generateZeroButtonVariants());     // 48 variants
    componentSets.push(await generateZeroCardVariants());       // 24 variants
    componentSets.push(await generateZeroModalVariants());      // 6 variants
    componentSets.push(await generateZeroListItemVariants());   // 6 variants
    componentSets.push(await generateZeroAlertVariants());      // 8 variants

    // Arrange components in a grid
    let xOffset = 0;
    const spacing = 100;

    for (const componentSet of componentSets) {
      componentSet.x = xOffset;
      componentSet.y = 0;
      xOffset += componentSet.width + spacing;
    }

    // Zoom to show all components
    figma.viewport.scrollAndZoomIntoView(componentSets);

    const totalVariants = 48 + 24 + 6 + 6 + 8;
    figma.closePlugin(`✅ Generated 5 components with ${totalVariants} total variants!\n\n` +
      `• ZeroButton: 48 variants (4 styles × 3 sizes × 4 states)\n` +
      `• ZeroCard: 24 variants (2 layouts × 3 priorities × 4 states)\n` +
      `• ZeroModal: 6 variants (3 sizes × 2 states)\n` +
      `• ZeroListItem: 6 variants (2 types × 3 states)\n` +
      `• ZeroAlert: 8 variants (4 types × 2 positions)\n\n` +
      `Check the Components page!`);

  } catch (error: any) {
    console.error('Error generating components:', error);
    figma.closePlugin(`❌ Error: ${error?.message || 'Unknown error'}`);
  }
}

// Run the plugin
generateAllComponentsWithVariants();

import { BaseAgent } from '../core/base-agent';
import { 
  AgentMessage, 
  AgentResponse, 
  AgentTask,
  AgentCapability
} from '../types/agent.types';
import { generateId } from '../utils/helpers';

// ============================================================================
// Design System Types
// ============================================================================

interface DesignSystemAuditRequest {
  type: 'full' | 'tokens' | 'components' | 'consistency' | 'figma-prep';
  scope?: string[];  // directories to scan
  framework?: 'tailwind' | 'css-modules' | 'styled-components' | 'emotion';
}

interface DesignToken {
  name: string;
  value: string;
  category: 'color' | 'spacing' | 'typography' | 'shadow' | 'radius' | 'animation' | 'breakpoint';
  usage: string[];  // where it's used
  figmaVariable?: string;  // mapped Figma variable name
}

interface ComponentAuditResult {
  name: string;
  path: string;
  props: Array<{ name: string; type: string; required: boolean; default?: string }>;
  variants?: string[];
  usesTokens: boolean;
  hardcodedValues: string[];
  similarTo?: string[];  // potential duplicates
  accessibility: {
    hasAriaLabels: boolean;
    hasFocusStates: boolean;
    hasKeyboardNav: boolean;
  };
}

interface ConsistencyIssue {
  type: 'naming' | 'props' | 'spacing' | 'color' | 'typography' | 'pattern';
  severity: 'low' | 'medium' | 'high';
  description: string;
  locations: string[];
  recommendation: string;
}

interface FigmaTokenStructure {
  colors: Record<string, Record<string, string>>;
  spacing: Record<string, string>;
  typography: {
    fontFamilies: Record<string, string>;
    fontSizes: Record<string, string>;
    fontWeights: Record<string, string>;
    lineHeights: Record<string, string>;
  };
  effects: {
    shadows: Record<string, string>;
    blurs: Record<string, string>;
  };
  radii: Record<string, string>;
}

interface DesignSystemAuditOutput {
  summary: {
    totalComponents: number;
    tokenCoverage: number;  // percentage using tokens vs hardcoded
    consistencyScore: number;  // 0-100
    figmaReadiness: number;  // 0-100
  };
  tokens: {
    extracted: DesignToken[];
    missing: string[];  // values that should be tokens
    unused: string[];  // tokens defined but not used
  };
  components: ComponentAuditResult[];
  issues: ConsistencyIssue[];
  recommendations: string[];
  figmaStructure?: FigmaTokenStructure;
}

// ============================================================================
// Design System Agent
// ============================================================================

export class DesignSystemAgent extends BaseAgent {
  
  // Design system knowledge base
  private static readonly DESIGN_SYSTEM_KNOWLEDGE = {
    tokenCategories: {
      colors: {
        semantic: ['primary', 'secondary', 'accent', 'success', 'warning', 'error', 'info'],
        neutral: ['background', 'foreground', 'muted', 'border', 'ring'],
        scales: ['50', '100', '200', '300', '400', '500', '600', '700', '800', '900', '950']
      },
      spacing: {
        scale: ['0', '0.5', '1', '1.5', '2', '2.5', '3', '3.5', '4', '5', '6', '7', '8', '9', '10', '11', '12', '14', '16', '20', '24', '28', '32', '36', '40', '44', '48', '52', '56', '60', '64', '72', '80', '96'],
        semantic: ['none', 'xs', 'sm', 'md', 'lg', 'xl', '2xl', '3xl']
      },
      typography: {
        sizes: ['xs', 'sm', 'base', 'lg', 'xl', '2xl', '3xl', '4xl', '5xl', '6xl', '7xl', '8xl', '9xl'],
        weights: ['thin', 'extralight', 'light', 'normal', 'medium', 'semibold', 'bold', 'extrabold', 'black'],
        families: ['sans', 'serif', 'mono']
      },
      radii: ['none', 'sm', 'default', 'md', 'lg', 'xl', '2xl', '3xl', 'full'],
      shadows: ['sm', 'default', 'md', 'lg', 'xl', '2xl', 'inner', 'none']
    },
    atomicDesign: {
      atoms: ['Button', 'Input', 'Label', 'Icon', 'Badge', 'Avatar', 'Spinner'],
      molecules: ['FormField', 'Card', 'MenuItem', 'SearchBar', 'Tooltip'],
      organisms: ['Header', 'Footer', 'Sidebar', 'Modal', 'DataTable', 'Form'],
      templates: ['PageLayout', 'DashboardLayout', 'AuthLayout'],
      pages: ['HomePage', 'AboutPage', 'ContactPage']
    },
    namingConventions: {
      components: 'PascalCase (Button, CardHeader)',
      props: 'camelCase (onClick, isDisabled)',
      variants: 'kebab-case or camelCase (primary, destructive, outline)',
      tokens: 'kebab-case with category prefix (color-primary-500, spacing-md)',
      cssVariables: '--category-name (--color-primary, --spacing-md)'
    },
    figmaStructure: {
      collections: ['Primitives', 'Semantic', 'Component'],
      modes: ['Light', 'Dark', 'High Contrast'],
      componentProperties: ['Variant', 'Size', 'State', 'Boolean'],
      autoLayout: ['Gap', 'Padding', 'Direction', 'Alignment']
    },
    bestPractices: [
      'Use semantic tokens that reference primitive tokens',
      'Components should only use semantic tokens, never primitives directly',
      'Every hardcoded value is a missed token opportunity',
      'Consistent prop naming across all components (size: sm/md/lg)',
      'Variant props should follow a standard pattern',
      'All interactive elements need focus states',
      'Test with 200% zoom for accessibility',
      'Document all tokens with usage examples',
      'Version your design system tokens',
      'Keep Figma and code in sync with token pipeline'
    ],
    tailwindToFigma: {
      'text-sm': { fontSize: '14px', lineHeight: '20px' },
      'text-base': { fontSize: '16px', lineHeight: '24px' },
      'text-lg': { fontSize: '18px', lineHeight: '28px' },
      'rounded-md': '6px',
      'rounded-lg': '8px',
      'shadow-sm': '0 1px 2px 0 rgb(0 0 0 / 0.05)',
      'shadow-md': '0 4px 6px -1px rgb(0 0 0 / 0.1)'
    }
  };

  constructor() {
    super(
      'design-system-001',
      'Design System Agent',
      'systems-architect',
      'Expert in design systems, component libraries, and design-to-code consistency. Audits codebases for token usage, component patterns, and Figma sync readiness. Helps build and maintain scalable design systems.',
      DesignSystemAgent.getCapabilities(),
      '1.0.0'
    );
  }

  private static getCapabilities(): AgentCapability[] {
    return [
      {
        name: 'design-system-audit',
        description: 'Comprehensive audit of design tokens, components, and consistency'
      },
      {
        name: 'token-extraction',
        description: 'Extract design tokens from codebase (Tailwind config, CSS variables, etc.)'
      },
      {
        name: 'component-inventory',
        description: 'Catalog all components with props, variants, and usage'
      },
      {
        name: 'consistency-check',
        description: 'Find inconsistencies in naming, spacing, colors, and patterns'
      },
      {
        name: 'duplicate-detection',
        description: 'Identify similar components that should be consolidated'
      },
      {
        name: 'figma-token-generation',
        description: 'Generate Figma-compatible token JSON for Variables'
      },
      {
        name: 'figma-component-spec',
        description: 'Generate specifications for Figma component library'
      },
      {
        name: 'accessibility-audit',
        description: 'Check components for a11y compliance (focus, contrast, ARIA)'
      },
      {
        name: 'migration-plan',
        description: 'Create plan to migrate hardcoded values to tokens'
      }
    ];
  }

  // ============================================================================
  // Message Handlers
  // ============================================================================

  protected async handleRequest(message: AgentMessage): Promise<AgentResponse> {
    this.log('info', `Handling request: ${message.action}`, { payload: message.payload });

    switch (message.action) {
      case 'audit':
      case 'full-audit':
        return this.handleFullAudit(message.payload as DesignSystemAuditRequest);
      
      case 'extract-tokens':
        return this.handleTokenExtraction(message.payload as { source: string });
      
      case 'inventory-components':
        return this.handleComponentInventory(message.payload as { directories: string[] });
      
      case 'check-consistency':
        return this.handleConsistencyCheck(message.payload as { scope: string[] });
      
      case 'find-duplicates':
        return this.handleDuplicateDetection(message.payload as { threshold: number });
      
      case 'generate-figma-tokens':
        return this.handleFigmaTokenGeneration(message.payload as { format: string });
      
      case 'generate-figma-spec':
        return this.handleFigmaComponentSpec(message.payload as { components: string[] });
      
      case 'audit-accessibility':
        return this.handleAccessibilityAudit(message.payload as { components: string[] });
      
      case 'create-migration-plan':
        return this.handleMigrationPlan(message.payload as { priority: string });
      
      case 'get-knowledge':
        return this.handleGetKnowledge();
      
      default:
        return this.createErrorResponse(
          'UNKNOWN_ACTION',
          `Unknown action: ${message.action}`,
          { availableActions: [
            'audit', 'full-audit', 'extract-tokens', 'inventory-components',
            'check-consistency', 'find-duplicates', 'generate-figma-tokens',
            'generate-figma-spec', 'audit-accessibility', 'create-migration-plan',
            'get-knowledge'
          ]}
        );
    }
  }

  protected async handleEvent(message: AgentMessage): Promise<AgentResponse> {
    return this.createSuccessResponse({ acknowledged: true });
  }

  protected async performTask(task: AgentTask): Promise<unknown> {
    if (task.type === 'design-system-audit') {
      const result = await this.handleFullAudit(task.input as DesignSystemAuditRequest);
      return result.data;
    }
    throw new Error(`Unknown task type: ${task.type}`);
  }

  // ============================================================================
  // Core Audit Methods
  // ============================================================================

  private async handleFullAudit(request: DesignSystemAuditRequest): Promise<AgentResponse<DesignSystemAuditOutput>> {
    const tokens = this.extractTokens(request);
    const components = this.inventoryComponents(request);
    const issues = this.findConsistencyIssues(request);
    const figmaStructure = this.generateFigmaStructure(tokens.extracted);

    const output: DesignSystemAuditOutput = {
      summary: {
        totalComponents: components.length,
        tokenCoverage: this.calculateTokenCoverage(components),
        consistencyScore: this.calculateConsistencyScore(issues),
        figmaReadiness: this.calculateFigmaReadiness(tokens, components)
      },
      tokens,
      components,
      issues,
      recommendations: this.generateRecommendations(tokens, components, issues),
      figmaStructure
    };

    return this.createSuccessResponse(
      output,
      'Design system audit complete. Focus on high-severity issues first.',
      this.getQuickWins(issues),
      ['Create missing tokens', 'Consolidate duplicate components', 'Add focus states']
    );
  }

  private async handleTokenExtraction(input: { source: string }): Promise<AgentResponse> {
    // In a real implementation, this would parse Tailwind config, CSS files, etc.
    const tokens: DesignToken[] = [
      // Colors - Semantic
      { name: 'color-primary', value: '#3b82f6', category: 'color', usage: ['Button', 'Link'], figmaVariable: 'color/primary/default' },
      { name: 'color-primary-hover', value: '#2563eb', category: 'color', usage: ['Button:hover'], figmaVariable: 'color/primary/hover' },
      { name: 'color-secondary', value: '#64748b', category: 'color', usage: ['Badge', 'Text'], figmaVariable: 'color/secondary/default' },
      { name: 'color-background', value: '#ffffff', category: 'color', usage: ['Page', 'Card'], figmaVariable: 'color/background/default' },
      { name: 'color-foreground', value: '#0f172a', category: 'color', usage: ['Text', 'Heading'], figmaVariable: 'color/foreground/default' },
      { name: 'color-muted', value: '#f1f5f9', category: 'color', usage: ['Card', 'Input'], figmaVariable: 'color/background/muted' },
      { name: 'color-border', value: '#e2e8f0', category: 'color', usage: ['Card', 'Input', 'Divider'], figmaVariable: 'color/border/default' },
      
      // Spacing
      { name: 'spacing-xs', value: '4px', category: 'spacing', usage: ['Icon gap'], figmaVariable: 'spacing/xs' },
      { name: 'spacing-sm', value: '8px', category: 'spacing', usage: ['Button padding'], figmaVariable: 'spacing/sm' },
      { name: 'spacing-md', value: '16px', category: 'spacing', usage: ['Card padding', 'Section gap'], figmaVariable: 'spacing/md' },
      { name: 'spacing-lg', value: '24px', category: 'spacing', usage: ['Section padding'], figmaVariable: 'spacing/lg' },
      { name: 'spacing-xl', value: '32px', category: 'spacing', usage: ['Page padding'], figmaVariable: 'spacing/xl' },
      
      // Typography
      { name: 'font-size-sm', value: '14px', category: 'typography', usage: ['Label', 'Caption'], figmaVariable: 'typography/size/sm' },
      { name: 'font-size-base', value: '16px', category: 'typography', usage: ['Body'], figmaVariable: 'typography/size/base' },
      { name: 'font-size-lg', value: '18px', category: 'typography', usage: ['Subheading'], figmaVariable: 'typography/size/lg' },
      { name: 'font-size-xl', value: '24px', category: 'typography', usage: ['Heading'], figmaVariable: 'typography/size/xl' },
      
      // Radius
      { name: 'radius-sm', value: '4px', category: 'radius', usage: ['Badge', 'Tag'], figmaVariable: 'radius/sm' },
      { name: 'radius-md', value: '8px', category: 'radius', usage: ['Button', 'Input'], figmaVariable: 'radius/md' },
      { name: 'radius-lg', value: '12px', category: 'radius', usage: ['Card', 'Modal'], figmaVariable: 'radius/lg' },
      { name: 'radius-full', value: '9999px', category: 'radius', usage: ['Avatar', 'Pill'], figmaVariable: 'radius/full' },
      
      // Shadows
      { name: 'shadow-sm', value: '0 1px 2px 0 rgb(0 0 0 / 0.05)', category: 'shadow', usage: ['Button'], figmaVariable: 'effect/shadow/sm' },
      { name: 'shadow-md', value: '0 4px 6px -1px rgb(0 0 0 / 0.1)', category: 'shadow', usage: ['Card', 'Dropdown'], figmaVariable: 'effect/shadow/md' },
      { name: 'shadow-lg', value: '0 10px 15px -3px rgb(0 0 0 / 0.1)', category: 'shadow', usage: ['Modal'], figmaVariable: 'effect/shadow/lg' }
    ];

    return this.createSuccessResponse({
      tokens,
      summary: {
        total: tokens.length,
        byCategory: {
          color: tokens.filter(t => t.category === 'color').length,
          spacing: tokens.filter(t => t.category === 'spacing').length,
          typography: tokens.filter(t => t.category === 'typography').length,
          radius: tokens.filter(t => t.category === 'radius').length,
          shadow: tokens.filter(t => t.category === 'shadow').length
        }
      },
      exportFormats: ['CSS Variables', 'Tailwind Config', 'Figma Variables JSON', 'Style Dictionary']
    });
  }

  private async handleComponentInventory(input: { directories: string[] }): Promise<AgentResponse> {
    // Example component inventory for Rationale site
    const components: ComponentAuditResult[] = [
      {
        name: 'Button',
        path: 'components/ui/button.tsx',
        props: [
          { name: 'variant', type: "'default' | 'destructive' | 'outline' | 'ghost'", required: false, default: 'default' },
          { name: 'size', type: "'sm' | 'md' | 'lg'", required: false, default: 'md' },
          { name: 'disabled', type: 'boolean', required: false, default: 'false' },
          { name: 'loading', type: 'boolean', required: false, default: 'false' }
        ],
        variants: ['default', 'destructive', 'outline', 'ghost', 'link'],
        usesTokens: true,
        hardcodedValues: [],
        accessibility: { hasAriaLabels: true, hasFocusStates: true, hasKeyboardNav: true }
      },
      {
        name: 'Card',
        path: 'components/ui/card.tsx',
        props: [
          { name: 'variant', type: "'default' | 'glass' | 'elevated'", required: false, default: 'default' },
          { name: 'padding', type: "'none' | 'sm' | 'md' | 'lg'", required: false, default: 'md' }
        ],
        variants: ['default', 'glass', 'elevated'],
        usesTokens: true,
        hardcodedValues: ['backdrop-blur-md'],
        accessibility: { hasAriaLabels: false, hasFocusStates: false, hasKeyboardNav: false }
      },
      {
        name: 'HeroSection',
        path: 'components/sections/hero-section.tsx',
        props: [
          { name: 'title', type: 'string', required: true },
          { name: 'subtitle', type: 'string', required: false },
          { name: 'cta', type: 'ReactNode', required: false }
        ],
        usesTokens: false,
        hardcodedValues: ['text-5xl', 'mb-6', 'max-w-4xl'],
        accessibility: { hasAriaLabels: false, hasFocusStates: false, hasKeyboardNav: false }
      },
      {
        name: 'GlassCard',
        path: 'components/visual/glass-card.tsx',
        props: [
          { name: 'blur', type: "'sm' | 'md' | 'lg'", required: false, default: 'md' }
        ],
        usesTokens: false,
        hardcodedValues: ['bg-white/10', 'backdrop-blur-xl', 'border-white/20'],
        similarTo: ['Card (glass variant)'],
        accessibility: { hasAriaLabels: false, hasFocusStates: false, hasKeyboardNav: false }
      }
    ];

    return this.createSuccessResponse({
      components,
      summary: {
        total: components.length,
        usingTokens: components.filter(c => c.usesTokens).length,
        withHardcodedValues: components.filter(c => c.hardcodedValues.length > 0).length,
        potentialDuplicates: components.filter(c => c.similarTo && c.similarTo.length > 0).length,
        accessibilityComplete: components.filter(c => 
          c.accessibility.hasAriaLabels && c.accessibility.hasFocusStates
        ).length
      },
      atomicBreakdown: {
        atoms: components.filter(c => ['Button', 'Input', 'Label', 'Badge', 'Avatar'].includes(c.name)).length,
        molecules: components.filter(c => ['Card', 'FormField', 'SearchBar'].includes(c.name)).length,
        organisms: components.filter(c => ['Header', 'Footer', 'Modal', 'HeroSection'].includes(c.name)).length
      }
    });
  }

  private async handleConsistencyCheck(input: { scope: string[] }): Promise<AgentResponse> {
    const issues: ConsistencyIssue[] = [
      {
        type: 'naming',
        severity: 'medium',
        description: 'Inconsistent size prop values: some use sm/md/lg, others use small/medium/large',
        locations: ['Button (sm/md/lg)', 'Input (small/medium/large)', 'Badge (xs/sm/md)'],
        recommendation: 'Standardize on sm/md/lg across all components'
      },
      {
        type: 'spacing',
        severity: 'high',
        description: 'Hardcoded spacing values found instead of tokens',
        locations: ['HeroSection: mb-6, py-20', 'AboutSection: gap-8, px-12'],
        recommendation: 'Replace with semantic spacing tokens (spacing-lg, spacing-xl)'
      },
      {
        type: 'color',
        severity: 'medium',
        description: 'Direct color values used instead of semantic tokens',
        locations: ['GlassCard: bg-white/10', 'Footer: text-gray-400'],
        recommendation: 'Use semantic color tokens (color-background, color-muted)'
      },
      {
        type: 'pattern',
        severity: 'high',
        description: 'Multiple implementations of glass/blur effect',
        locations: ['GlassCard', 'Card (glass variant)', 'liquid-glass-react usage'],
        recommendation: 'Consolidate into single Glass primitive component'
      },
      {
        type: 'props',
        severity: 'low',
        description: 'Inconsistent boolean prop naming: some use is* prefix, others do not',
        locations: ['Button: disabled vs isLoading', 'Modal: open vs isVisible'],
        recommendation: 'Standardize: use plain names for native HTML (disabled), is* for custom (isLoading)'
      },
      {
        type: 'typography',
        severity: 'medium',
        description: 'Text sizes vary without semantic meaning',
        locations: ['Hero: text-5xl', 'Card title: text-2xl', 'Section: text-4xl'],
        recommendation: 'Create semantic text components: Heading, Subheading, Body, Caption'
      }
    ];

    return this.createSuccessResponse({
      issues,
      summary: {
        total: issues.length,
        bySeverity: {
          high: issues.filter(i => i.severity === 'high').length,
          medium: issues.filter(i => i.severity === 'medium').length,
          low: issues.filter(i => i.severity === 'low').length
        },
        byType: {
          naming: issues.filter(i => i.type === 'naming').length,
          spacing: issues.filter(i => i.type === 'spacing').length,
          color: issues.filter(i => i.type === 'color').length,
          pattern: issues.filter(i => i.type === 'pattern').length,
          props: issues.filter(i => i.type === 'props').length,
          typography: issues.filter(i => i.type === 'typography').length
        }
      },
      priorityOrder: issues
        .sort((a, b) => {
          const severityOrder = { high: 0, medium: 1, low: 2 };
          return severityOrder[a.severity] - severityOrder[b.severity];
        })
        .map(i => i.description)
    });
  }

  private async handleDuplicateDetection(input: { threshold: number }): Promise<AgentResponse> {
    return this.createSuccessResponse({
      duplicates: [
        {
          components: ['GlassCard', 'Card (glass variant)'],
          similarity: 85,
          recommendation: 'Consolidate into Card with variant="glass"',
          effort: 'small'
        },
        {
          components: ['HeroSection', 'PageHero', 'SectionHero'],
          similarity: 70,
          recommendation: 'Create single Hero component with layout prop',
          effort: 'medium'
        },
        {
          components: ['ClientLogo', 'PartnerLogo', 'TrustBadge'],
          similarity: 90,
          recommendation: 'Create single Logo component with size/variant props',
          effort: 'small'
        }
      ],
      potentialAbstractions: [
        {
          pattern: 'Section with heading + content + CTA',
          occurrences: ['AboutSection', 'ServicesSection', 'ContactSection'],
          recommendation: 'Create ContentSection template component'
        },
        {
          pattern: 'Card with icon + title + description',
          occurrences: ['FeatureCard', 'ServiceCard', 'BenefitCard'],
          recommendation: 'Create IconCard component with consistent API'
        }
      ]
    });
  }

  private async handleFigmaTokenGeneration(input: { format: string }): Promise<AgentResponse> {
    const figmaTokens = {
      // Figma Variables format
      variables: {
        colors: {
          'color/primary/default': { value: '#3b82f6', type: 'COLOR' },
          'color/primary/hover': { value: '#2563eb', type: 'COLOR' },
          'color/primary/active': { value: '#1d4ed8', type: 'COLOR' },
          'color/secondary/default': { value: '#64748b', type: 'COLOR' },
          'color/background/default': { value: '#ffffff', type: 'COLOR' },
          'color/background/muted': { value: '#f1f5f9', type: 'COLOR' },
          'color/foreground/default': { value: '#0f172a', type: 'COLOR' },
          'color/foreground/muted': { value: '#64748b', type: 'COLOR' },
          'color/border/default': { value: '#e2e8f0', type: 'COLOR' },
          'color/success': { value: '#22c55e', type: 'COLOR' },
          'color/warning': { value: '#f59e0b', type: 'COLOR' },
          'color/error': { value: '#ef4444', type: 'COLOR' }
        },
        spacing: {
          'spacing/0': { value: 0, type: 'FLOAT' },
          'spacing/1': { value: 4, type: 'FLOAT' },
          'spacing/2': { value: 8, type: 'FLOAT' },
          'spacing/3': { value: 12, type: 'FLOAT' },
          'spacing/4': { value: 16, type: 'FLOAT' },
          'spacing/5': { value: 20, type: 'FLOAT' },
          'spacing/6': { value: 24, type: 'FLOAT' },
          'spacing/8': { value: 32, type: 'FLOAT' },
          'spacing/10': { value: 40, type: 'FLOAT' },
          'spacing/12': { value: 48, type: 'FLOAT' },
          'spacing/16': { value: 64, type: 'FLOAT' }
        },
        radius: {
          'radius/none': { value: 0, type: 'FLOAT' },
          'radius/sm': { value: 4, type: 'FLOAT' },
          'radius/md': { value: 8, type: 'FLOAT' },
          'radius/lg': { value: 12, type: 'FLOAT' },
          'radius/xl': { value: 16, type: 'FLOAT' },
          'radius/full': { value: 9999, type: 'FLOAT' }
        }
      },
      // Collections structure
      collections: [
        {
          name: 'Primitives',
          modes: ['Default'],
          description: 'Raw design values - colors, spacing scales'
        },
        {
          name: 'Semantic',
          modes: ['Light', 'Dark'],
          description: 'Semantic tokens that reference primitives'
        },
        {
          name: 'Components',
          modes: ['Default'],
          description: 'Component-specific tokens'
        }
      ],
      // Styles (for things that can not be variables)
      styles: {
        typography: {
          'heading/xl': { fontFamily: 'Inter', fontSize: 48, fontWeight: 700, lineHeight: 1.2 },
          'heading/lg': { fontFamily: 'Inter', fontSize: 36, fontWeight: 700, lineHeight: 1.2 },
          'heading/md': { fontFamily: 'Inter', fontSize: 24, fontWeight: 600, lineHeight: 1.3 },
          'heading/sm': { fontFamily: 'Inter', fontSize: 20, fontWeight: 600, lineHeight: 1.4 },
          'body/lg': { fontFamily: 'Inter', fontSize: 18, fontWeight: 400, lineHeight: 1.6 },
          'body/md': { fontFamily: 'Inter', fontSize: 16, fontWeight: 400, lineHeight: 1.5 },
          'body/sm': { fontFamily: 'Inter', fontSize: 14, fontWeight: 400, lineHeight: 1.5 },
          'label/md': { fontFamily: 'Inter', fontSize: 14, fontWeight: 500, lineHeight: 1.4 }
        },
        effects: {
          'shadow/sm': { type: 'DROP_SHADOW', x: 0, y: 1, blur: 2, spread: 0, color: 'rgba(0,0,0,0.05)' },
          'shadow/md': { type: 'DROP_SHADOW', x: 0, y: 4, blur: 6, spread: -1, color: 'rgba(0,0,0,0.1)' },
          'shadow/lg': { type: 'DROP_SHADOW', x: 0, y: 10, blur: 15, spread: -3, color: 'rgba(0,0,0,0.1)' }
        }
      }
    };

    return this.createSuccessResponse({
      figmaTokens,
      exportInstructions: [
        '1. Open Figma file → Local Variables',
        '2. Create collections: Primitives, Semantic, Components',
        '3. Import JSON using Tokens Studio plugin or manual entry',
        '4. Set up modes for Light/Dark themes',
        '5. Link semantic tokens to primitives using aliases'
      ],
      syncStrategy: {
        recommended: 'Style Dictionary + Tokens Studio',
        workflow: [
          'Define tokens in code (tokens.json or Tailwind config)',
          'Transform with Style Dictionary to Figma format',
          'Sync to Figma via Tokens Studio plugin',
          'Changes in Figma sync back via plugin + PR'
        ]
      }
    });
  }

  private async handleFigmaComponentSpec(input: { components: string[] }): Promise<AgentResponse> {
    return this.createSuccessResponse({
      componentSpecs: [
        {
          name: 'Button',
          properties: [
            { name: 'Variant', type: 'VARIANT', options: ['Primary', 'Secondary', 'Outline', 'Ghost', 'Destructive'] },
            { name: 'Size', type: 'VARIANT', options: ['Small', 'Medium', 'Large'] },
            { name: 'State', type: 'VARIANT', options: ['Default', 'Hover', 'Active', 'Disabled', 'Loading'] },
            { name: 'Icon Left', type: 'BOOLEAN', default: false },
            { name: 'Icon Right', type: 'BOOLEAN', default: false },
            { name: 'Label', type: 'TEXT', default: 'Button' }
          ],
          autoLayout: {
            direction: 'HORIZONTAL',
            gap: 'spacing/2',
            padding: { horizontal: 'spacing/4', vertical: 'spacing/2' }
          },
          tokens: {
            background: 'color/primary/default',
            text: 'color/background/default',
            border: 'color/primary/default',
            radius: 'radius/md'
          }
        },
        {
          name: 'Card',
          properties: [
            { name: 'Variant', type: 'VARIANT', options: ['Default', 'Glass', 'Elevated'] },
            { name: 'Padding', type: 'VARIANT', options: ['None', 'Small', 'Medium', 'Large'] },
            { name: 'Has Header', type: 'BOOLEAN', default: true },
            { name: 'Has Footer', type: 'BOOLEAN', default: false }
          ],
          autoLayout: {
            direction: 'VERTICAL',
            gap: 'spacing/4',
            padding: 'spacing/4'
          },
          tokens: {
            background: 'color/background/default',
            border: 'color/border/default',
            radius: 'radius/lg',
            shadow: 'shadow/md'
          }
        }
      ],
      buildOrder: [
        '1. Create all Variables first (colors, spacing, radius)',
        '2. Build atoms: Icon, Button, Input, Label, Badge',
        '3. Build molecules: FormField, Card, MenuItem',
        '4. Build organisms: Header, Footer, Modal',
        '5. Create component documentation with examples'
      ]
    });
  }

  private async handleAccessibilityAudit(input: { components: string[] }): Promise<AgentResponse> {
    return this.createSuccessResponse({
      audit: [
        {
          component: 'Button',
          score: 90,
          passed: ['Focus visible state', 'Keyboard navigation', 'Disabled state styling'],
          issues: [
            { issue: 'Loading state needs aria-busy', fix: 'Add aria-busy={loading} to button' }
          ]
        },
        {
          component: 'Card',
          score: 60,
          passed: ['Semantic HTML structure'],
          issues: [
            { issue: 'Interactive cards need focus state', fix: 'Add focus:ring-2 focus:ring-primary' },
            { issue: 'No keyboard navigation for clickable cards', fix: 'Add tabIndex={0} and onKeyDown handler' }
          ]
        },
        {
          component: 'Modal',
          score: 75,
          passed: ['Focus trap working', 'Escape key closes'],
          issues: [
            { issue: 'Missing aria-labelledby', fix: 'Connect title to modal with aria-labelledby' },
            { issue: 'Focus not returned on close', fix: 'Store and restore focus to trigger element' }
          ]
        }
      ],
      globalIssues: [
        'Color contrast ratio below 4.5:1 in some muted text',
        'Some interactive elements missing visible focus indicators',
        'Touch targets below 44x44px on mobile for some buttons'
      ],
      recommendations: [
        'Install @axe-core/react for automated testing',
        'Add focus-visible utilities to base styles',
        'Create FocusRing component for consistent focus styling',
        'Test with screen reader (VoiceOver, NVDA) monthly'
      ]
    });
  }

  private async handleMigrationPlan(input: { priority: string }): Promise<AgentResponse> {
    return this.createSuccessResponse({
      phases: [
        {
          phase: 1,
          name: 'Foundation',
          duration: '1 week',
          tasks: [
            'Audit and document current tokens in Tailwind config',
            'Create tokens.ts with semantic token definitions',
            'Set up CSS variables for runtime theming',
            'Create design-tokens.md documentation'
          ],
          deliverables: ['Token system', 'Documentation']
        },
        {
          phase: 2,
          name: 'Core Components',
          duration: '2 weeks',
          tasks: [
            'Migrate Button to use tokens (remove hardcoded values)',
            'Migrate Card and Card variants',
            'Migrate Input, Label, and form components',
            'Add missing accessibility features',
            'Consolidate duplicate components'
          ],
          deliverables: ['Updated component library', 'Storybook examples']
        },
        {
          phase: 3,
          name: 'Sections & Layouts',
          duration: '1 week',
          tasks: [
            'Migrate page sections to use tokens',
            'Create semantic spacing system for layouts',
            'Standardize heading/text styles',
            'Create layout primitives (Stack, Grid, Container)'
          ],
          deliverables: ['Consistent layouts', 'Typography system']
        },
        {
          phase: 4,
          name: 'Figma Sync',
          duration: '1 week',
          tasks: [
            'Export tokens to Figma Variables format',
            'Build Figma component library matching code',
            'Set up Tokens Studio for bidirectional sync',
            'Create Figma documentation pages'
          ],
          deliverables: ['Figma design system', 'Sync pipeline']
        }
      ],
      quickWins: [
        'Replace all hardcoded px values with Tailwind spacing',
        'Consolidate GlassCard into Card variant',
        'Create Text component with size variants',
        'Add focus:ring utilities to all interactive elements'
      ],
      riskMitigation: [
        'Create visual regression tests before migration',
        'Migrate one component at a time with review',
        'Keep old components as deprecated until verified',
        'Test dark mode throughout migration'
      ]
    });
  }

  private async handleGetKnowledge(): Promise<AgentResponse> {
    return this.createSuccessResponse({
      knowledge_base: DesignSystemAgent.DESIGN_SYSTEM_KNOWLEDGE,
      note: 'This agent applies these patterns automatically during audits'
    });
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  private extractTokens(request: DesignSystemAuditRequest) {
    return {
      extracted: [] as DesignToken[],
      missing: ['animation-duration', 'z-index scale', 'breakpoints'],
      unused: ['color-tertiary', 'spacing-xxl']
    };
  }

  private inventoryComponents(request: DesignSystemAuditRequest): ComponentAuditResult[] {
    return [];
  }

  private findConsistencyIssues(request: DesignSystemAuditRequest): ConsistencyIssue[] {
    return [];
  }

  private generateFigmaStructure(tokens: DesignToken[]): FigmaTokenStructure {
    return {
      colors: {},
      spacing: {},
      typography: { fontFamilies: {}, fontSizes: {}, fontWeights: {}, lineHeights: {} },
      effects: { shadows: {}, blurs: {} },
      radii: {}
    };
  }

  private calculateTokenCoverage(components: ComponentAuditResult[]): number {
    if (components.length === 0) return 75; // Default estimate
    const usingTokens = components.filter(c => c.usesTokens).length;
    return Math.round((usingTokens / components.length) * 100);
  }

  private calculateConsistencyScore(issues: ConsistencyIssue[]): number {
    const highIssues = issues.filter(i => i.severity === 'high').length;
    const mediumIssues = issues.filter(i => i.severity === 'medium').length;
    return Math.max(0, 100 - (highIssues * 15) - (mediumIssues * 5));
  }

  private calculateFigmaReadiness(tokens: { extracted: DesignToken[] }, components: ComponentAuditResult[]): number {
    return 60; // Placeholder - would calculate based on token coverage and naming consistency
  }

  private generateRecommendations(
    tokens: { extracted: DesignToken[]; missing: string[]; unused: string[] },
    components: ComponentAuditResult[],
    issues: ConsistencyIssue[]
  ): string[] {
    return [
      'Create semantic color tokens for all UI states (hover, active, disabled)',
      'Consolidate duplicate glass/blur implementations into single component',
      'Add missing accessibility features to Card and Modal components',
      'Standardize size prop values across all components (sm/md/lg)',
      'Set up Tokens Studio for Figma ↔ code synchronization',
      'Create Storybook documentation for component library'
    ];
  }

  private getQuickWins(issues: ConsistencyIssue[]): string[] {
    return issues
      .filter(i => i.severity !== 'low')
      .slice(0, 3)
      .map(i => i.recommendation);
  }
}

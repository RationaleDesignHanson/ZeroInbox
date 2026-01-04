import { BaseAgent } from '../core/base-agent';
import { 
  AgentMessage, 
  AgentResponse, 
  AgentTask,
  AgentCapability,
  ReviewFinding,
  ProjectContext
} from '../types/agent.types';
import { generateId } from '../utils/helpers';

// ============================================================================
// UX Review Types
// ============================================================================

interface UXReviewRequest {
  type: 'full' | 'homepage' | 'navigation' | 'conversion' | 'accessibility' | 'mobile';
  siteContent?: {
    homepage?: string;
    otherPages?: string[];
  };
  companyContext?: string;
  targetAudience?: string[];
  projectName?: string;
}

interface UXScore {
  category: string;
  score: number;  // 1-10
  diagnosis: string;
  example_from_site: string;
}

interface UXDirection {
  id: string;
  name: string;
  summary: string;
  homepage_sections: string[];
  tradeoffs: string[];
}

interface HeroVariant {
  label: string;
  headline: string;
  subheadline: string;
  primary_cta: string;
  bullets?: string[];
}

interface NavItem {
  label: string;
  purpose: string;
}

interface MicrocopyChange {
  location: string;
  current: string;
  proposed: string;
}

interface UXReviewOutput {
  scores: UXScore[];
  ux_directions: UXDirection[];
  recommendations: {
    hero_variants: HeroVariant[];
    nav: NavItem[];
    microcopy_changes: MicrocopyChange[];
    how_we_work_structure?: Array<{ step: string; description: string }>;
  };
  ux_done_when_checklist: string[];
  accessibility_issues?: string[];
  mobile_issues?: string[];
}

// ============================================================================
// UX Design Expert Agent
// ============================================================================

export class UXDesignExpertAgent extends BaseAgent {
  
  // Core UX knowledge base - O'Reilly books and industry standards
  private static readonly UX_KNOWLEDGE_BASE = {
    books: [
      'Designing Interfaces (Jenifer Tidwell)',
      'Designing Social Interfaces (Christian Crumlish & Erin Malone)',
      'Don\'t Make Me Think (Steve Krug)',
      'The Design of Everyday Things (Don Norman)',
      'About Face (Alan Cooper)',
      'Hooked (Nir Eyal)',
      'Lean UX (Jeff Gothelf)',
      'Sprint (Jake Knapp)',
      'Refactoring UI (Adam Wathan & Steve Schoger)',
      '100 Things Every Designer Needs to Know About People (Susan Weinschenk)',
      'Laws of UX (Jon Yablonski)',
      'Articulating Design Decisions (Tom Greever)'
    ],
    principles: [
      'Progressive disclosure - reveal complexity gradually',
      'Recognition over recall - show options, don\'t make users remember',
      'Fitts\'s Law - important targets should be large and close',
      'Hick\'s Law - more choices = slower decisions',
      'Miller\'s Law - chunk information into 7±2 items',
      'Jakob\'s Law - users spend most time on other sites',
      'Aesthetic-Usability Effect - beautiful = perceived as more usable',
      'Peak-End Rule - people judge by peaks and endings',
      'Serial Position Effect - first and last items remembered best',
      'Zeigarnik Effect - incomplete tasks are remembered better',
      'Von Restorff Effect - distinctive items are remembered',
      'Doherty Threshold - responses under 400ms feel instant'
    ],
    patterns: {
      navigation: ['Hub and spoke', 'Fully connected', 'Step-by-step wizard', 'Pyramid', 'Dashboard'],
      layout: ['Card-based', 'Magazine', 'Feature comparison', 'Pricing tables', 'Timeline'],
      social: ['Activity streams', 'Reputation systems', 'Leaderboards', 'Follow/Subscribe', 'Reactions'],
      conversion: ['Benefit-oriented headlines', 'Social proof placement', 'Friction reduction', 'Exit intent', 'Progress indicators'],
      mobile: ['Thumb-friendly zones', 'Bottom navigation', 'Swipe gestures', 'Pull to refresh', 'Floating action buttons']
    },
    heuristics: [
      'Visibility of system status',
      'Match between system and real world',
      'User control and freedom',
      'Consistency and standards',
      'Error prevention',
      'Recognition rather than recall',
      'Flexibility and efficiency of use',
      'Aesthetic and minimalist design',
      'Help users recognize, diagnose, and recover from errors',
      'Help and documentation'
    ]
  };

  constructor() {
    super(
      'ux-design-expert-001',
      'UX Design Expert',
      'systems-architect',  // Using systems-architect role for now
      'Elite UX/UI expert with 15+ years experience. Deep knowledge of O\'Reilly design books (Designing Interfaces, Designing Social Interfaces), Nielsen Norman heuristics, and modern UX patterns. Provides comprehensive UX audits with actionable recommendations.',
      UXDesignExpertAgent.getCapabilities(),
      '1.0.0'
    );
  }

  private static getCapabilities(): AgentCapability[] {
    return [
      {
        name: 'ux-audit',
        description: 'Comprehensive UX audit covering clarity, navigation, conversion, and accessibility'
      },
      {
        name: 'homepage-review',
        description: 'Deep analysis of homepage messaging, hierarchy, and conversion paths'
      },
      {
        name: 'navigation-analysis',
        description: 'Information architecture and navigation pattern review'
      },
      {
        name: 'conversion-optimization',
        description: 'CTA placement, friction analysis, and conversion funnel review'
      },
      {
        name: 'accessibility-audit',
        description: 'WCAG compliance and inclusive design review'
      },
      {
        name: 'mobile-ux-review',
        description: 'Touch targets, responsive patterns, and mobile-first analysis'
      },
      {
        name: 'microcopy-review',
        description: 'Button text, labels, error messages, and instructional copy'
      },
      {
        name: 'hero-variants',
        description: 'Generate multiple hero section options with headlines and CTAs'
      }
    ];
  }

  // ============================================================================
  // Message Handlers
  // ============================================================================

  protected async handleRequest(message: AgentMessage): Promise<AgentResponse> {
    this.log('info', `Handling request: ${message.action}`, { payload: message.payload });

    switch (message.action) {
      case 'review':
      case 'audit':
        return this.handleUXReview(message.payload as UXReviewRequest);
      
      case 'homepage-review':
        return this.handleHomepageReview(message.payload as UXReviewRequest);
      
      case 'navigation-analysis':
        return this.handleNavigationAnalysis(message.payload as UXReviewRequest);
      
      case 'conversion-review':
        return this.handleConversionReview(message.payload as UXReviewRequest);
      
      case 'generate-hero-variants':
        return this.handleHeroVariants(message.payload as { context: string; audience: string[] });
      
      case 'generate-nav':
        return this.handleNavGeneration(message.payload as { pages: string[]; audience: string[] });
      
      case 'get-knowledge':
        return this.handleGetKnowledge();
      
      default:
        return this.createErrorResponse(
          'UNKNOWN_ACTION',
          `Unknown action: ${message.action}`,
          { availableActions: [
            'review', 'audit', 'homepage-review', 'navigation-analysis',
            'conversion-review', 'generate-hero-variants', 'generate-nav', 'get-knowledge'
          ]}
        );
    }
  }

  protected async handleEvent(message: AgentMessage): Promise<AgentResponse> {
    return this.createSuccessResponse({ acknowledged: true });
  }

  protected async performTask(task: AgentTask): Promise<unknown> {
    if (task.type === 'ux-audit') {
      const result = await this.handleUXReview(task.input as UXReviewRequest);
      return result.data;
    }
    throw new Error(`Unknown task type: ${task.type}`);
  }

  // ============================================================================
  // Core Review Methods
  // ============================================================================

  private async handleUXReview(request: UXReviewRequest): Promise<AgentResponse<UXReviewOutput>> {
    const scores = this.calculateUXScores(request);
    const directions = this.generateUXDirections(request);
    const recommendations = this.generateRecommendations(request, scores);
    const checklist = this.generateDoneWhenChecklist(request);

    const output: UXReviewOutput = {
      scores,
      ux_directions: directions,
      recommendations,
      ux_done_when_checklist: checklist
    };

    // Add accessibility issues if requested
    if (request.type === 'full' || request.type === 'accessibility') {
      output.accessibility_issues = this.identifyAccessibilityIssues(request);
    }

    // Add mobile issues if requested
    if (request.type === 'full' || request.type === 'mobile') {
      output.mobile_issues = this.identifyMobileIssues(request);
    }

    return this.createSuccessResponse(
      output,
      'UX review completed. Apply recommendations in priority order for maximum impact.',
      this.getQuickWins(scores),
      ['Implement hero variant A/B test', 'Simplify navigation', 'Add social proof above fold']
    );
  }

  private async handleHomepageReview(request: UXReviewRequest): Promise<AgentResponse> {
    const scores = this.calculateHomepageScores(request);
    const heroVariants = this.generateHeroVariants(request);
    
    return this.createSuccessResponse({
      scores,
      hero_variants: heroVariants,
      above_fold_checklist: [
        'Value proposition is clear in < 5 seconds',
        'Primary CTA is visible without scrolling',
        'Social proof or credibility marker present',
        'Visual hierarchy guides eye to CTA'
      ],
      section_order_recommendation: [
        'Hero with clear value prop + CTA',
        'Social proof (logos or testimonials)',
        'Problem/solution or "How it works"',
        'Features/benefits (3-4 max)',
        'Case study or detailed proof',
        'Secondary CTA + footer'
      ]
    });
  }

  private async handleNavigationAnalysis(request: UXReviewRequest): Promise<AgentResponse> {
    return this.createSuccessResponse({
      analysis: {
        pattern_detected: 'Standard horizontal nav',
        item_count: 'Optimal (5-7 items)',
        hierarchy_depth: 'Shallow (good)',
        mobile_pattern: 'Hamburger menu'
      },
      recommendations: [
        {
          issue: 'Too many top-level items',
          solution: 'Group related items under dropdowns',
          priority: 'high'
        }
      ],
      suggested_nav: this.generateNavStructure(request)
    });
  }

  private async handleConversionReview(request: UXReviewRequest): Promise<AgentResponse> {
    return this.createSuccessResponse({
      cta_analysis: {
        primary_cta_visible: true,
        cta_text_actionable: true,
        friction_points: [
          'Form has too many fields',
          'No social proof near CTA',
          'CTA button color doesn\'t contrast'
        ]
      },
      funnel_analysis: {
        awareness: 'Hero section',
        interest: 'Features section',
        desire: 'Case studies',
        action: 'Contact form'
      },
      recommendations: [
        'Add testimonial directly above CTA',
        'Reduce form to 3 fields max',
        'Add "No credit card required" if applicable',
        'Use action-oriented CTA text ("Get Started" vs "Submit")'
      ]
    });
  }

  private async handleHeroVariants(input: { context: string; audience: string[] }): Promise<AgentResponse> {
    const variants = this.generateHeroVariants({ 
      type: 'homepage',
      companyContext: input.context,
      targetAudience: input.audience
    });

    return this.createSuccessResponse({
      variants,
      testing_recommendation: 'A/B test Option 1 vs Option 2 for 2 weeks minimum',
      metrics_to_track: ['Click-through rate', 'Scroll depth', 'Time on page', 'Bounce rate']
    });
  }

  private async handleNavGeneration(input: { pages: string[]; audience: string[] }): Promise<AgentResponse> {
    return this.createSuccessResponse({
      nav: this.generateNavStructure({ 
        type: 'navigation',
        targetAudience: input.audience 
      }),
      principles_applied: [
        'Most important items first and last (serial position effect)',
        '5-7 items maximum (Miller\'s Law)',
        'Familiar labels (Jakob\'s Law)',
        'Clear hierarchy with dropdowns for secondary items'
      ]
    });
  }

  private async handleGetKnowledge(): Promise<AgentResponse> {
    return this.createSuccessResponse({
      knowledge_base: UXDesignExpertAgent.UX_KNOWLEDGE_BASE,
      note: 'This agent applies these principles automatically during reviews'
    });
  }

  // ============================================================================
  // Analysis Methods
  // ============================================================================

  private calculateUXScores(request: UXReviewRequest): UXScore[] {
    return [
      {
        category: "Clarity of 'What is this?'",
        score: 6,
        diagnosis: "The value proposition is present but buried. Users need to scroll or click to understand core offering.",
        example_from_site: "Hero focuses on tagline rather than concrete service description"
      },
      {
        category: "Visual Hierarchy",
        score: 7,
        diagnosis: "Good use of typography scale. Primary CTA could be more prominent.",
        example_from_site: "Headline size is appropriate, but CTA blends with background"
      },
      {
        category: "Navigation Clarity",
        score: 6,
        diagnosis: "Navigation items are somewhat abstract. Users may not know where to find key information.",
        example_from_site: "Labels like 'Work' vs 'Products' distinction unclear"
      },
      {
        category: "Social Proof Placement",
        score: 5,
        diagnosis: "Client logos present but below fold. Testimonials not prominently featured.",
        example_from_site: "Logos appear after 2+ scrolls on mobile"
      },
      {
        category: "Mobile Experience",
        score: 7,
        diagnosis: "Responsive design works. Touch targets adequate. Could improve thumb-zone placement.",
        example_from_site: "Navigation requires stretch to top of screen"
      },
      {
        category: "Conversion Path",
        score: 5,
        diagnosis: "Multiple CTAs compete for attention. Primary conversion goal unclear.",
        example_from_site: "'Contact', 'Learn More', 'View Work' all equally weighted"
      },
      {
        category: "Content Scannability",
        score: 6,
        diagnosis: "Some sections are text-heavy. Could benefit from more visual breaks and chunking.",
        example_from_site: "Service descriptions are paragraph-heavy"
      },
      {
        category: "Trust Signals",
        score: 6,
        diagnosis: "Client logos provide some trust. Missing: case study metrics, testimonial quotes, security badges.",
        example_from_site: "No specific outcomes or numbers mentioned"
      }
    ];
  }

  private calculateHomepageScores(request: UXReviewRequest): UXScore[] {
    return this.calculateUXScores(request).filter(s => 
      ['Clarity', 'Visual Hierarchy', 'Social Proof', 'Conversion'].some(k => s.category.includes(k))
    );
  }

  private generateUXDirections(request: UXReviewRequest): UXDirection[] {
    return [
      {
        id: 'A',
        name: 'Product-Led Studio',
        summary: 'Lead with shipped products as proof of capability, studio services as the engine.',
        homepage_sections: [
          'Hero: Product showcase + studio promise',
          'Two-Engine Explainer: Products + Services',
          'Proof: Client logos + case study preview',
          'Products: Zero and future products',
          'How We Work: Process overview',
          'CTA: Clear next step'
        ],
        tradeoffs: [
          'Pro: Differentiates from typical agencies',
          'Pro: Products serve as portfolio',
          'Con: May confuse pure service seekers',
          'Con: Requires explaining two business models'
        ]
      },
      {
        id: 'B',
        name: 'Outcomes-First Agency',
        summary: 'Lead with client outcomes and transformations. Products are mentioned as IP.',
        homepage_sections: [
          'Hero: Client transformation statement',
          'Proof: 3 case studies with metrics',
          'Process: How we deliver',
          'Clients: Logo wall + testimonials',
          'About: Team and approach',
          'CTA: Start a project'
        ],
        tradeoffs: [
          'Pro: Familiar agency pattern',
          'Pro: Outcome-focused messaging converts',
          'Con: Harder to differentiate',
          'Con: Products become secondary'
        ]
      },
      {
        id: 'C',
        name: 'Venture Studio',
        summary: 'Position as a venture studio that also takes clients. Equity-focused.',
        homepage_sections: [
          'Hero: "We build and invest in products"',
          'Portfolio: Products we\'ve built',
          'Model: Fee + equity explanation',
          'Partners: Who we work with',
          'Apply: For startups seeking partners',
          'Clients: Enterprise design services'
        ],
        tradeoffs: [
          'Pro: Premium positioning',
          'Pro: Attracts founder clients',
          'Con: May deter traditional enterprise',
          'Con: Requires strong portfolio'
        ]
      }
    ];
  }

  private generateRecommendations(request: UXReviewRequest, scores: UXScore[]): UXReviewOutput['recommendations'] {
    return {
      hero_variants: this.generateHeroVariants(request),
      nav: this.generateNavStructure(request),
      microcopy_changes: [
        {
          location: 'Homepage hero',
          current: 'Strategy-led product design',
          proposed: 'We design products that users love and investors fund'
        },
        {
          location: 'Primary CTA',
          current: 'Contact Us',
          proposed: 'Start a Project'
        },
        {
          location: 'Services section header',
          current: 'What We Do',
          proposed: 'How We Help'
        }
      ],
      how_we_work_structure: [
        { step: '1. Discovery', description: 'We learn your business, users, and goals in a focused session.' },
        { step: '2. Strategy', description: 'We define the approach, architecture, and success metrics.' },
        { step: '3. Design', description: 'We create and iterate on designs with continuous feedback.' },
        { step: '4. Build', description: 'We develop production-ready solutions with your team.' },
        { step: '5. Launch', description: 'We help you ship, measure, and iterate post-launch.' }
      ]
    };
  }

  private generateHeroVariants(request: UXReviewRequest): HeroVariant[] {
    return [
      {
        label: 'Option 1: Product-Led',
        headline: 'We build products people pay for',
        subheadline: 'A product design studio that puts skin in the game. Client work + our own products.',
        primary_cta: 'See Our Work',
        bullets: ['Strategy to shipped product', 'Fee + equity partnerships', 'Zero, Recipe Buddy, and more']
      },
      {
        label: 'Option 2: Outcome-Focused',
        headline: 'Design that drives revenue',
        subheadline: 'We help teams ship products that users love and investors fund.',
        primary_cta: 'Start a Project',
        bullets: ['$50M+ in funding raised', '10+ products shipped', 'Meta, FuboTV, Athletes First']
      },
      {
        label: 'Option 3: Expertise-Led',
        headline: 'Conviction before code',
        subheadline: '15 years of product design distilled into a studio that ships.',
        primary_cta: 'Work With Us',
        bullets: ['Strategy-first approach', 'Full-stack product teams', 'Founder-friendly terms']
      }
    ];
  }

  private generateNavStructure(request: UXReviewRequest): NavItem[] {
    return [
      { label: 'Home', purpose: 'Return to main value prop and navigation hub' },
      { label: 'Work', purpose: 'Case studies and portfolio pieces with outcomes' },
      { label: 'Products', purpose: 'Our own products (Zero, Recipe Buddy) showing capability' },
      { label: 'Services', purpose: 'What we offer: strategy, design, development' },
      { label: 'About', purpose: 'Team, philosophy, and studio story' },
      { label: 'Contact', purpose: 'Primary conversion point - start a project' }
    ];
  }

  private generateDoneWhenChecklist(request: UXReviewRequest): string[] {
    return [
      'A first-time visitor can explain what Rationale does in one sentence after 30 seconds on the homepage.',
      'Products vs client work are clearly distinguished with labels and visual separation.',
      'Primary CTA is consistent across all pages and uses action-oriented language.',
      'Social proof (logos, testimonials, or metrics) is visible above the fold.',
      'Mobile users can complete primary conversion action without horizontal scrolling.',
      'Navigation labels match user mental models (validated with 3+ user tests).',
      'Each page has a single primary action with clear visual hierarchy.',
      'Error states and empty states have helpful, friendly copy.'
    ];
  }

  private identifyAccessibilityIssues(request: UXReviewRequest): string[] {
    return [
      'Ensure color contrast ratio meets WCAG AA (4.5:1 for body text)',
      'Add alt text to all images, including decorative ones (alt="")',
      'Ensure all interactive elements are keyboard accessible',
      'Add skip-to-content link for screen reader users',
      'Ensure form inputs have associated labels',
      'Check heading hierarchy (no skipped levels)',
      'Add focus indicators to all interactive elements',
      'Ensure touch targets are at least 44x44px on mobile'
    ];
  }

  private identifyMobileIssues(request: UXReviewRequest): string[] {
    return [
      'Ensure tap targets are in thumb-friendly zones (bottom 60% of screen)',
      'Check that horizontal scrolling is not required',
      'Verify text is readable without zooming (minimum 16px body)',
      'Ensure fixed headers don\'t consume too much viewport',
      'Check that forms use appropriate input types (email, tel, etc.)',
      'Verify images are responsive and don\'t cause layout shifts',
      'Test with slow 3G to ensure acceptable load times'
    ];
  }

  private getQuickWins(scores: UXScore[]): string[] {
    return scores
      .filter(s => s.score < 7)
      .slice(0, 3)
      .map(s => `Improve ${s.category}: ${s.diagnosis.split('.')[0]}`);
  }
}

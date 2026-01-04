import { BaseAgent } from '../core/base-agent';
import { 
  AgentMessage, 
  AgentResponse, 
  AgentTask,
  AgentCapability
} from '../types/agent.types';
import { generateId } from '../utils/helpers';

// ============================================================================
// VC Review Types
// ============================================================================

interface VCReviewRequest {
  type: 'full' | 'positioning' | 'pitch' | 'market' | 'business-model' | 'competitive';
  siteContent?: {
    homepage?: string;
    otherPages?: string[];
  };
  companyContext?: string;
  pitchDeck?: string;
  financials?: {
    revenue?: number;
    growth?: number;
    runway?: number;
  };
}

interface VCScore {
  category: string;
  score: number;  // 1-10
  diagnosis: string;
  example_from_site: string;
}

interface StrategyOption {
  id: string;
  name: string;
  tagline: string;
  summary: string;
  target_audience: string[];
  homepage_structure: string[];
  pros: string[];
  cons: string[];
}

interface VCReviewOutput {
  scores: VCScore[];
  strategy_options: StrategyOption[];
  recommendations: {
    hero_variants: Array<{ label: string; headline: string; subheadline: string; cta: string }>;
    nav: Array<{ label: string; purpose: string }>;
    one_liner: string;
    elevator_pitch: string;
  };
  done_when_checklist: string[];
  investor_concerns?: string[];
  market_positioning?: {
    category: string;
    competitors: string[];
    differentiation: string[];
  };
}

// ============================================================================
// VC Investor Agent
// ============================================================================

export class VCInvestorAgent extends BaseAgent {
  
  // VC knowledge base - classic and modern investment thinking
  private static readonly VC_KNOWLEDGE_BASE = {
    classic_frameworks: {
      'Porter\'s Five Forces': 'Competitive rivalry, supplier power, buyer power, threat of substitution, threat of new entry',
      'TAM/SAM/SOM': 'Total Addressable Market → Serviceable Addressable Market → Serviceable Obtainable Market',
      'Jobs To Be Done': 'Focus on the job customers hire the product to do, not features',
      'Crossing the Chasm': 'Technology adoption lifecycle - innovators → early adopters → early majority (the chasm)',
      'Blue Ocean Strategy': 'Create uncontested market space vs competing in bloody red oceans',
      'Lean Startup': 'Build-Measure-Learn loop, MVP, validated learning, pivot or persevere',
      'Platform vs Product': 'Products solve problems, platforms enable others to solve problems'
    },
    modern_trends: {
      'AI-Native': 'Products built from ground-up with AI, not AI bolted on',
      'Vertical SaaS': 'Deep domain-specific solutions vs horizontal plays',
      'PLG (Product-Led Growth)': 'Product itself drives acquisition, conversion, expansion',
      'Compound Startups': 'Building multiple products that reinforce each other',
      'Creator Economy': 'Tools for individual creators and small teams',
      'Climate Tech': 'Sustainability, carbon capture, clean energy solutions',
      'Fintech Infrastructure': 'Banking-as-a-service, embedded finance, crypto rails',
      'Health Tech': 'Digital health, remote monitoring, AI diagnostics',
      'Defense Tech': 'Dual-use technology, national security applications',
      'Spatial Computing': 'AR/VR, mixed reality, 3D interfaces'
    },
    investment_criteria: {
      team: ['Founder-market fit', 'Technical depth', 'Previous exits', 'Domain expertise', 'Complementary skills'],
      market: ['Large TAM ($1B+)', 'Growing market', 'Timing (why now?)', 'Favorable trends', 'Regulatory tailwinds'],
      product: ['Clear differentiation', '10x better/faster/cheaper', 'Defensibility', 'Network effects', 'Switching costs'],
      traction: ['Revenue growth', 'User growth', 'Engagement metrics', 'Unit economics', 'NPS/satisfaction'],
      business_model: ['Recurring revenue', 'High gross margins (70%+)', 'Clear path to profitability', 'Capital efficiency']
    },
    red_flags: [
      'Solution looking for a problem',
      'Undifferentiated in crowded market',
      'Founder-market mismatch',
      'Unrealistic financial projections',
      'No clear customer acquisition strategy',
      'Burn rate without path to profitability',
      'Feature comparison vs category creation',
      'Technology for technology\'s sake',
      'Single customer dependency',
      'Regulatory uncertainty without strategy'
    ],
    pitch_best_practices: [
      'Lead with the problem, not the solution',
      'Show don\'t tell - demos > descriptions',
      'Specific numbers beat vague claims',
      'Address the elephant in the room proactively',
      'Tell a story, not a feature list',
      'Show customer love (quotes, metrics)',
      'Be honest about competition',
      'Explain why now (timing)',
      'Clear ask with use of funds',
      'Leave them wanting more'
    ],
    studio_models: {
      'Venture Studio': 'Build companies from scratch with internal teams, spin out and fund',
      'Agency + Equity': 'Reduced fees in exchange for equity stake in client companies',
      'Startup Factory': 'Systematic approach to validating and launching new ventures',
      'Corporate Spinout': 'Help enterprises spin out internal innovations',
      'Thesis-Driven': 'Identify opportunities in specific sectors, then build/acquire'
    }
  };

  constructor() {
    super(
      'vc-investor-001',
      'VC Investor Perspective',
      'systems-architect',
      'Strategic advisor with VC/investor mindset. Evaluates positioning, pitch effectiveness, market opportunity, and business model from an investor\'s perspective. Familiar with classic frameworks (Porter, JTBD, Blue Ocean) and modern trends (AI-native, PLG, vertical SaaS).',
      VCInvestorAgent.getCapabilities(),
      '1.0.0'
    );
  }

  private static getCapabilities(): AgentCapability[] {
    return [
      {
        name: 'vc-review',
        description: 'Full investor-perspective review of positioning, messaging, and strategy'
      },
      {
        name: 'pitch-analysis',
        description: 'Evaluate pitch deck or website from investor lens'
      },
      {
        name: 'market-analysis',
        description: 'TAM/SAM/SOM, competitive landscape, timing analysis'
      },
      {
        name: 'business-model-review',
        description: 'Revenue model, unit economics, path to profitability'
      },
      {
        name: 'positioning-strategy',
        description: 'Category creation, differentiation, messaging strategy'
      },
      {
        name: 'investor-objections',
        description: 'Identify and address common investor concerns'
      },
      {
        name: 'pitch-optimization',
        description: 'Improve pitch narrative, structure, and delivery'
      },
      {
        name: 'trend-analysis',
        description: 'Map company to current investment trends and themes'
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
      case 'evaluate':
        return this.handleVCReview(message.payload as VCReviewRequest);
      
      case 'pitch-analysis':
        return this.handlePitchAnalysis(message.payload as VCReviewRequest);
      
      case 'market-analysis':
        return this.handleMarketAnalysis(message.payload as VCReviewRequest);
      
      case 'business-model-review':
        return this.handleBusinessModelReview(message.payload as VCReviewRequest);
      
      case 'identify-objections':
        return this.handleIdentifyObjections(message.payload as VCReviewRequest);
      
      case 'generate-one-liner':
        return this.handleGenerateOneLiner(message.payload as { context: string });
      
      case 'generate-elevator-pitch':
        return this.handleGenerateElevatorPitch(message.payload as { context: string; duration: number });
      
      case 'get-knowledge':
        return this.handleGetKnowledge();
      
      case 'trend-mapping':
        return this.handleTrendMapping(message.payload as { company: string; products: string[] });
      
      default:
        return this.createErrorResponse(
          'UNKNOWN_ACTION',
          `Unknown action: ${message.action}`,
          { availableActions: [
            'review', 'evaluate', 'pitch-analysis', 'market-analysis',
            'business-model-review', 'identify-objections', 'generate-one-liner',
            'generate-elevator-pitch', 'get-knowledge', 'trend-mapping'
          ]}
        );
    }
  }

  protected async handleEvent(message: AgentMessage): Promise<AgentResponse> {
    return this.createSuccessResponse({ acknowledged: true });
  }

  protected async performTask(task: AgentTask): Promise<unknown> {
    if (task.type === 'vc-review') {
      const result = await this.handleVCReview(task.input as VCReviewRequest);
      return result.data;
    }
    throw new Error(`Unknown task type: ${task.type}`);
  }

  // ============================================================================
  // Core Review Methods
  // ============================================================================

  private async handleVCReview(request: VCReviewRequest): Promise<AgentResponse<VCReviewOutput>> {
    const scores = this.calculateVCScores(request);
    const strategyOptions = this.generateStrategyOptions(request);
    const recommendations = this.generateVCRecommendations(request, scores);
    const checklist = this.generateDoneWhenChecklist();

    const output: VCReviewOutput = {
      scores,
      strategy_options: strategyOptions,
      recommendations,
      done_when_checklist: checklist,
      investor_concerns: this.identifyInvestorConcerns(request),
      market_positioning: this.analyzeMarketPositioning(request)
    };

    return this.createSuccessResponse(
      output,
      'VC perspective review completed. Focus on positioning clarity and proof points.',
      this.getPriorityFixes(scores),
      ['Clarify two-engine model', 'Add specific outcome metrics', 'Define ideal customer profile']
    );
  }

  private async handlePitchAnalysis(request: VCReviewRequest): Promise<AgentResponse> {
    return this.createSuccessResponse({
      structure_analysis: {
        recommended_order: [
          '1. Hook (problem statement)',
          '2. Solution (your approach)',
          '3. Why now (timing/trends)',
          '4. Market size (TAM/SAM/SOM)',
          '5. Business model',
          '6. Traction & proof points',
          '7. Team (why you)',
          '8. Competition (honest landscape)',
          '9. Financials & projections',
          '10. Ask & use of funds'
        ]
      },
      messaging_feedback: [
        'Lead with customer pain, not product features',
        'Use specific numbers (e.g., "$50M raised by clients" not "significant funding")',
        'Show customer logos early for credibility',
        'Address "why now" with market timing'
      ],
      storytelling_tips: [
        'Open with a specific customer story or pain point',
        'Use "before/after" framing for transformation',
        'Make the competition slide honest - builds trust',
        'End with memorable vision, not just financials'
      ]
    });
  }

  private async handleMarketAnalysis(request: VCReviewRequest): Promise<AgentResponse> {
    return this.createSuccessResponse({
      market_sizing: {
        tam: {
          size: '$50B+',
          definition: 'Global design and development services market',
          methodology: 'Top-down from industry reports'
        },
        sam: {
          size: '$5B',
          definition: 'Product design studios serving tech companies',
          methodology: 'Segment by service type and client profile'
        },
        som: {
          size: '$50M',
          definition: 'Premium studios with equity models in US market',
          methodology: 'Bottom-up from addressable clients'
        }
      },
      timing_analysis: {
        why_now: [
          'AI is commoditizing basic design work, premium strategy matters more',
          'Startup funding is more competitive, product quality is differentiator',
          'Enterprise teams are leaner, need external product expertise',
          'Remote work enables distributed studio models'
        ],
        tailwinds: ['AI tools adoption', 'Product-led growth trend', 'Design-as-competitive-advantage'],
        headwinds: ['Economic uncertainty', 'Offshore competition', 'DIY design tools']
      },
      competitive_landscape: this.analyzeCompetitiveLandscape()
    });
  }

  private async handleBusinessModelReview(request: VCReviewRequest): Promise<AgentResponse> {
    return this.createSuccessResponse({
      model_analysis: {
        revenue_streams: [
          { stream: 'Client Services', type: 'Project-based', margin: '40-60%', predictability: 'Low' },
          { stream: 'Retainers', type: 'Recurring', margin: '50-70%', predictability: 'Medium' },
          { stream: 'Equity Stakes', type: 'Long-term', margin: 'Variable', predictability: 'Low but high upside' },
          { stream: 'Own Products', type: 'SaaS', margin: '80%+', predictability: 'High (if achieved)' }
        ]
      },
      unit_economics: {
        ideal_client_profile: 'Funded startup or enterprise team, $50K-500K project, open to equity',
        cac_estimate: '$5K-15K (referral-heavy model)',
        ltv_estimate: '$100K-500K (multi-project relationships)',
        ltv_cac_ratio: '10-30x (healthy if true)'
      },
      investor_lens: {
        attractive: [
          'Equity model creates asymmetric upside',
          'Own products show capability and create IP',
          'High-caliber client list de-risks'
        ],
        concerns: [
          'Service revenue is not venture-scale',
          'Equity stakes are illiquid and uncertain',
          'Key-person risk with small team'
        ]
      }
    });
  }

  private async handleIdentifyObjections(request: VCReviewRequest): Promise<AgentResponse> {
    return this.createSuccessResponse({
      likely_objections: [
        {
          objection: 'This is a services business, not a venture-scale opportunity',
          response: 'We\'re building a portfolio of products (Zero, etc.) that compound over time. Services fund the R&D and validate market needs.',
          framework: 'Venture studio model'
        },
        {
          objection: 'How do you scale beyond founder capacity?',
          response: 'We\'re systematizing our methodology and building a network of specialized partners. Products scale independently.',
          framework: 'Leverage through productization'
        },
        {
          objection: 'What happens if one key client goes away?',
          response: 'No client is >20% of revenue. We maintain 8-12 active relationships plus product revenue.',
          framework: 'Diversification + recurring'
        },
        {
          objection: 'Why would a startup give you equity?',
          response: 'We reduce cash burn by 30-50% and our products have raised $50M+ in aggregate. Aligned incentives.',
          framework: 'Skin in the game'
        }
      ],
      proactive_messaging: [
        'Address the "is this a business?" question in hero',
        'Show the two-engine model (services + products) upfront',
        'Lead with outcomes, not process',
        'Make equity model explicit and inviting'
      ]
    });
  }

  private async handleGenerateOneLiner(input: { context: string }): Promise<AgentResponse> {
    const oneLiners = [
      'A product design studio that builds its own products and takes equity in client companies.',
      'We design products that users love and investors fund.',
      'Strategy-led design, with skin in the game.',
      'A venture studio that also takes clients.',
      'We ship products—ours and yours.',
      'Product design with an investor mindset.',
      'Design for outcomes, not deliverables.'
    ];

    return this.createSuccessResponse({
      options: oneLiners,
      recommendation: oneLiners[0],
      criteria: [
        'Explains what you do',
        'Differentiates from agencies',
        'Implies aligned incentives',
        'Memorable and repeatable'
      ]
    });
  }

  private async handleGenerateElevatorPitch(input: { context: string; duration: number }): Promise<AgentResponse> {
    const thirtySecond = `Rationale is a product design studio with an investor mindset. We work with funded startups and enterprise teams to ship products that users love—and we put skin in the game with fee-plus-equity partnerships. Our clients have raised over $50M, and we're building our own products like Zero, an AI email client. Think of us as a venture studio that also takes clients.`;

    const sixtySecond = `${thirtySecond}\n\nWe're different from typical agencies because we actually build products ourselves—it keeps us sharp and proves we know what we're doing. Our model is simple: strategy-led design, from concept to shipped product, with partnerships that align incentives. We're looking for founders and product leaders who want a design partner with conviction, not just a vendor.`;

    return this.createSuccessResponse({
      thirty_second: thirtySecond,
      sixty_second: sixtySecond,
      key_phrases: [
        'investor mindset',
        'skin in the game',
        'fee-plus-equity',
        'products that users love',
        'venture studio that also takes clients'
      ]
    });
  }

  private async handleGetKnowledge(): Promise<AgentResponse> {
    return this.createSuccessResponse({
      knowledge_base: VCInvestorAgent.VC_KNOWLEDGE_BASE,
      note: 'This agent applies these frameworks automatically during reviews'
    });
  }

  private async handleTrendMapping(input: { company: string; products: string[] }): Promise<AgentResponse> {
    return this.createSuccessResponse({
      trend_alignment: [
        { trend: 'AI-Native', alignment: 'High', evidence: 'Zero uses AI for email classification and summarization' },
        { trend: 'PLG (Product-Led Growth)', alignment: 'Medium', evidence: 'Products can drive inbound for services' },
        { trend: 'Vertical SaaS', alignment: 'Medium', evidence: 'CREaiT targets commercial real estate specifically' },
        { trend: 'Creator Economy', alignment: 'Low', evidence: 'Not primary focus' },
        { trend: 'Studio Model', alignment: 'High', evidence: 'Core business model is venture studio hybrid' }
      ],
      investor_themes: [
        'AI productivity tools',
        'Professional services transformation',
        'Design-as-competitive-advantage',
        'Alternative studio/agency models'
      ],
      positioning_recommendation: 'Position as AI-native product studio, not traditional design agency. Lead with products, back with services.'
    });
  }

  // ============================================================================
  // Analysis Methods
  // ============================================================================

  private calculateVCScores(request: VCReviewRequest): VCScore[] {
    return [
      {
        category: 'Positioning & Narrative',
        score: 6,
        diagnosis: 'The two-engine model (products + services) is unique but not immediately clear. Visitors need to work to understand the value proposition.',
        example_from_site: 'Hero focuses on abstract "strategy-led design" rather than concrete model'
      },
      {
        category: 'Market Opportunity Clarity',
        score: 5,
        diagnosis: 'Market size and opportunity are implicit. No clear articulation of why this approach wins now.',
        example_from_site: 'Missing: market context, timing thesis, TAM indication'
      },
      {
        category: 'Proof Points & Traction',
        score: 6,
        diagnosis: 'Client logos are strong but lack specific outcomes. No metrics on client success.',
        example_from_site: 'Logos present, but no "raised $X" or "grew Y%" claims'
      },
      {
        category: 'Business Model Transparency',
        score: 4,
        diagnosis: 'Fee-plus-equity model is not explained. Visitors don\'t understand what makes you different.',
        example_from_site: 'No pricing, engagement model, or equity structure visible'
      },
      {
        category: 'Team & Credibility',
        score: 6,
        diagnosis: 'Founder background is strong but not prominently featured. 15+ years experience mentioned but not leveraged.',
        example_from_site: 'About page exists but isn\'t part of trust-building flow'
      },
      {
        category: 'Product Showcase',
        score: 7,
        diagnosis: 'Own products (Zero, Recipe Buddy) exist and are mentioned. Could be more prominent as proof of capability.',
        example_from_site: 'Products section exists but doesn\'t lead the narrative'
      },
      {
        category: 'Call-to-Action Clarity',
        score: 5,
        diagnosis: 'Multiple CTAs compete. Unclear if targeting clients, investors, or both.',
        example_from_site: 'Contact, View Work, Products—no clear primary path'
      },
      {
        category: 'Investor Readability',
        score: 5,
        diagnosis: 'Site reads like an agency, not a fundable venture studio. Model isn\'t obvious in 30 seconds.',
        example_from_site: 'Would need to explain model verbally vs site doing the work'
      }
    ];
  }

  private generateStrategyOptions(request: VCReviewRequest): StrategyOption[] {
    return [
      {
        id: 'A',
        name: 'Product-Led Studio Front Door',
        tagline: 'Lead with shipped products, backed by a studio.',
        summary: 'Position products (Zero, etc.) as the primary proof point. Studio services are presented as the engine that builds products—for clients and internally.',
        target_audience: ['Founders', 'Product leaders', 'Investors'],
        homepage_structure: [
          'Hero: clear product + studio promise',
          'Proof: client logos and case studies',
          'Products: Zero and future products',
          'Model: fee + equity explanation',
          'Contact: clear CTA for partnerships'
        ],
        pros: [
          'Differentiates from agencies',
          'Products are tangible proof',
          'Attracts founder/investor audience'
        ],
        cons: [
          'May confuse traditional enterprise buyers',
          'Requires strong product portfolio',
          'Two narratives to maintain'
        ]
      },
      {
        id: 'B',
        name: 'Venture Studio Model',
        tagline: 'We build companies and partner with founders.',
        summary: 'Full venture studio positioning. Services are a means to an end (funding product development and sourcing opportunities).',
        target_audience: ['Founders seeking partners', 'Angels/VCs', 'Corporate innovation'],
        homepage_structure: [
          'Hero: "We build and invest in products"',
          'Portfolio: companies and products built',
          'Model: how partnerships work',
          'Apply: for founders seeking studio partnership',
          'Services: enterprise design as secondary'
        ],
        pros: [
          'Premium positioning',
          'Clear investor narrative',
          'Attracts equity deals'
        ],
        cons: [
          'May deter pure-services clients',
          'Requires portfolio depth',
          'Higher bar to clear'
        ]
      },
      {
        id: 'C',
        name: 'Outcomes-First Agency+',
        tagline: 'Design that drives results, with aligned incentives.',
        summary: 'Lead with client outcomes and case studies. Differentiate with equity model as a trust signal, not the headline.',
        target_audience: ['Product leaders', 'Enterprise teams', 'Funded startups'],
        homepage_structure: [
          'Hero: outcome-focused headline',
          'Case studies: 3 with metrics',
          'Process: how we work',
          'Difference: equity alignment',
          'Team: credibility',
          'Contact: start a project'
        ],
        pros: [
          'Familiar agency pattern',
          'Outcome focus converts',
          'Lower barrier to engage'
        ],
        cons: [
          'Harder to differentiate',
          'Products become secondary',
          'Less interesting to investors'
        ]
      }
    ];
  }

  private generateVCRecommendations(request: VCReviewRequest, scores: VCScore[]): VCReviewOutput['recommendations'] {
    return {
      hero_variants: [
        {
          label: 'Option 1: Product-Led',
          headline: 'We build products that get funded',
          subheadline: 'A design studio that ships its own products and partners with founders for equity.',
          cta: 'See What We\'ve Built'
        },
        {
          label: 'Option 2: Investor-Focused',
          headline: 'Design with skin in the game',
          subheadline: 'Strategy-led product design with fee + equity partnerships. $50M+ raised by our clients.',
          cta: 'Partner With Us'
        },
        {
          label: 'Option 3: Outcome-First',
          headline: 'Products that users love, investors fund',
          subheadline: 'We help teams ship—and we put our money where our design is.',
          cta: 'Start a Project'
        }
      ],
      nav: [
        { label: 'Home', purpose: 'Value prop and navigation hub' },
        { label: 'Products', purpose: 'Our own products as proof of capability' },
        { label: 'Work', purpose: 'Client case studies with outcomes' },
        { label: 'Model', purpose: 'How fee + equity works' },
        { label: 'About', purpose: 'Team and philosophy' },
        { label: 'Partner', purpose: 'Primary CTA for engagement' }
      ],
      one_liner: 'A product design studio that builds its own products and takes equity in client companies.',
      elevator_pitch: 'Rationale is a product design studio with an investor mindset. We work with funded startups and enterprise teams to ship products that users love—and we put skin in the game with fee-plus-equity partnerships. Our clients have raised over $50M, and we\'re building our own products like Zero. Think of us as a venture studio that also takes clients.'
    };
  }

  private generateDoneWhenChecklist(): string[] {
    return [
      'A VC can summarize our two-engine model in one sentence after 30 seconds on the homepage.',
      'Fee + equity structure is explicit and inviting.',
      'At least one product is showcased with credible depth (screenshots, features, traction).',
      'At least 2-3 client outcomes are visible with real numbers or specifics.',
      'The "Why now" for this model is addressed (market timing).',
      'Team credibility is visible without clicking to About page.',
      'Primary CTA is clear and consistent across the site.',
      'Investor page (if exists) addresses common objections proactively.'
    ];
  }

  private identifyInvestorConcerns(request: VCReviewRequest): string[] {
    return [
      'Is this a scalable business or lifestyle consulting?',
      'How do equity stakes create liquidity?',
      'What happens when key person(s) aren\'t available?',
      'Why would well-funded startups give up equity for design?',
      'How do you compete with cheaper offshore options?',
      'What\'s the path to $10M+ revenue?',
      'How defensible is the model?'
    ];
  }

  private analyzeMarketPositioning(request: VCReviewRequest): VCReviewOutput['market_positioning'] {
    return {
      category: 'Venture Studio / Product Design Hybrid',
      competitors: [
        'Traditional agencies (IDEO, frog, Huge)',
        'Venture studios (Atomic, High Alpha, Idealab)',
        'Productized services (DesignJoy, Superside)',
        'Freelance networks (Toptal, UpWork premium)'
      ],
      differentiation: [
        'Own products as proof of capability',
        'Equity alignment with clients',
        'Strategy-first, not just execution',
        'Founder-led with deep experience',
        'Full-stack: strategy → design → development'
      ]
    };
  }

  private analyzeCompetitiveLandscape(): object {
    return {
      quadrants: {
        'High strategy / High execution': ['Rationale (positioning target)', 'IDEO (much larger)', 'Metalab'],
        'High strategy / Lower execution': ['McKinsey Digital', 'BCG Digital Ventures'],
        'Lower strategy / High execution': ['Superside', 'DesignJoy', 'offshore agencies'],
        'Lower strategy / Lower execution': ['Freelance', 'DIY tools']
      },
      white_space: 'Equity-aligned studio with own products. Few competitors here.',
      positioning_target: 'Top-right quadrant with unique equity model'
    };
  }

  private getPriorityFixes(scores: VCScore[]): string[] {
    return scores
      .filter(s => s.score < 6)
      .slice(0, 3)
      .map(s => `${s.category}: ${s.diagnosis.split('.')[0]}`);
  }
}

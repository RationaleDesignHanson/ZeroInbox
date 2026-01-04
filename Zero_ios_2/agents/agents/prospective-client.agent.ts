import { BaseAgent } from '../core/base-agent';
import { 
  AgentMessage, 
  AgentResponse, 
  AgentTask,
  AgentCapability
} from '../types/agent.types';
import { generateId } from '../utils/helpers';

// ============================================================================
// Prospective Client Types
// ============================================================================

interface ClientPersona {
  id: string;
  name: string;
  role: string;
  company: string;
  companyStage: 'pre-seed' | 'seed' | 'series-a' | 'series-b' | 'growth' | 'enterprise';
  budget: string;
  timeline: string;
  projectType: 'greenfield' | 'redesign' | 'rescue' | 'mvp' | 'scale';
  sophistication: 'low' | 'medium' | 'high';  // design/tech sophistication
  priorities: string[];
  concerns: string[];
  referenceStyle: string[];  // what aesthetics they gravitate toward
}

interface SiteEvaluationRequest {
  persona?: string;  // persona ID or 'random'
  pages?: string[];  // specific pages to evaluate
  focus?: 'overall' | 'trust' | 'clarity' | 'differentiation' | 'process' | 'proof';
}

interface SiteFeedback {
  helpful: Array<{ element: string; why: string }>;
  confusing: Array<{ element: string; issue: string; suggestion: string }>;
  missing: Array<{ need: string; importance: 'critical' | 'important' | 'nice-to-have' }>;
  objections: Array<{ concern: string; severity: 'blocker' | 'hesitation' | 'minor' }>;
  decision_factors: Array<{ factor: string; current_score: number; notes: string }>;
}

interface AestheticPreferences {
  likes: Array<{ reference: string; url?: string; what_works: string }>;
  dislikes: Array<{ reference: string; why: string }>;
  mood: string[];
  specific_requests: string[];
}

interface ClientEvaluationOutput {
  persona: ClientPersona;
  first_impression: {
    hook: boolean;
    clarity: number;  // 1-10
    trust: number;    // 1-10
    differentiation: number;  // 1-10
    immediate_reaction: string;
  };
  site_feedback: SiteFeedback;
  aesthetic_preferences: AestheticPreferences;
  questions_for_rationale: string[];
  likelihood_to_reach_out: number;  // 1-10
  what_would_change_mind: string[];
  competitive_comparison: {
    also_considering: string[];
    rationale_advantages: string[];
    rationale_disadvantages: string[];
  };
}

// ============================================================================
// Prospective Client Agent
// ============================================================================

export class ProspectiveClientAgent extends BaseAgent {
  
  // Client personas library
  private static readonly CLIENT_PERSONAS: ClientPersona[] = [
    {
      id: 'startup-sarah',
      name: 'Sarah Chen',
      role: 'CEO & Co-founder',
      company: 'HealthSync (Series A healthtech)',
      companyStage: 'series-a',
      budget: '$150-300k',
      timeline: '3-4 months',
      projectType: 'greenfield',
      sophistication: 'medium',
      priorities: ['Speed to market', 'Investor-ready design', 'Technical credibility', 'Someone who gets healthcare'],
      concerns: ['Agency fluff vs actual shipping', 'Hidden costs', 'Will they understand our domain?', 'Post-launch support'],
      referenceStyle: ['Clean SaaS', 'Linear', 'Notion', 'Modern healthcare apps']
    },
    {
      id: 'enterprise-eric',
      name: 'Eric Thompson',
      role: 'VP of Product',
      company: 'Fortune 500 Financial Services',
      companyStage: 'enterprise',
      budget: '$500k-1M',
      timeline: '6-12 months',
      projectType: 'redesign',
      sophistication: 'high',
      priorities: ['Proven enterprise experience', 'Process rigor', 'Security/compliance', 'Executive presentation quality'],
      concerns: ['Are they big enough for us?', 'Can they handle our bureaucracy?', 'References from similar companies', 'IP ownership'],
      referenceStyle: ['Bloomberg', 'Stripe Dashboard', 'Sophisticated data viz', 'Premium but functional']
    },
    {
      id: 'founder-felix',
      name: 'Felix Rodriguez',
      role: 'Solo Founder',
      company: 'Pre-seed AI startup',
      companyStage: 'pre-seed',
      budget: '$30-75k',
      timeline: '6-8 weeks',
      projectType: 'mvp',
      sophistication: 'high',
      priorities: ['Equity deal possible?', 'Fast iteration', 'Technical co-building', 'Demo-ready for investors'],
      concerns: ['Can I afford this?', 'Will they take me seriously at my stage?', 'Do they actually build or just design?'],
      referenceStyle: ['YC company sites', 'Vercel', 'Raycast', 'Developer-focused']
    },
    {
      id: 'rescue-rachel',
      name: 'Rachel Kim',
      role: 'Head of Product',
      company: 'Series B marketplace (product in trouble)',
      companyStage: 'series-b',
      budget: '$200-400k',
      timeline: 'ASAP (2-3 months)',
      projectType: 'rescue',
      sophistication: 'medium',
      priorities: ['Speed', 'Someone who can diagnose fast', 'Actually ship, not just advise', 'Calm our board'],
      concerns: ['Can they really turn this around?', 'Will they blame our team?', 'NDA and discretion', 'What if it still fails?'],
      referenceStyle: ['Doesnt care about style right now', 'Just needs it to work', 'Clean and functional']
    },
    {
      id: 'scaleup-sam',
      name: 'Sam Williams',
      role: 'Chief Product Officer',
      company: 'Series C fintech ($50M raised)',
      companyStage: 'growth',
      budget: '$300-500k',
      timeline: '4-6 months',
      projectType: 'scale',
      sophistication: 'high',
      priorities: ['Design system that scales', 'Team augmentation', 'Process improvement', 'Premium quality'],
      concerns: ['Will they mesh with our team?', 'Knowledge transfer', 'Are they actually better than hiring?', 'Long-term relationship potential'],
      referenceStyle: ['Stripe', 'Mercury', 'Ramp', 'Fintech best-in-class']
    },
    {
      id: 'creative-carla',
      name: 'Carla Okonkwo',
      role: 'Founder & Creative Director',
      company: 'DTC brand going digital',
      companyStage: 'seed',
      budget: '$100-200k',
      timeline: '3-4 months',
      projectType: 'greenfield',
      sophistication: 'high',
      priorities: ['Brand-forward design', 'Unique not template', 'E-commerce expertise', 'Mobile-first'],
      concerns: ['Will they get our brand?', 'Too techy, not creative enough?', 'Shopify limitations', 'Photography/content integration'],
      referenceStyle: ['Glossier', 'Aesop', 'Apple', 'Editorial/magazine feel']
    }
  ];

  // Reference sites library
  private static readonly REFERENCE_LIBRARY = {
    saas_clean: [
      { name: 'Linear', url: 'linear.app', vibe: 'Minimal, fast, developer-loved' },
      { name: 'Notion', url: 'notion.so', vibe: 'Friendly, flexible, workspace feel' },
      { name: 'Vercel', url: 'vercel.com', vibe: 'Developer-focused, dark, premium' },
      { name: 'Raycast', url: 'raycast.com', vibe: 'Slick, productivity, Mac-native feel' }
    ],
    fintech: [
      { name: 'Stripe', url: 'stripe.com', vibe: 'Gold standard, gradient magic, trustworthy' },
      { name: 'Mercury', url: 'mercury.com', vibe: 'Clean banking, approachable finance' },
      { name: 'Ramp', url: 'ramp.com', vibe: 'Bold, confident, modern finance' },
      { name: 'Brex', url: 'brex.com', vibe: 'Startup-focused, premium feel' }
    ],
    enterprise: [
      { name: 'Figma', url: 'figma.com', vibe: 'Playful but professional, collaboration' },
      { name: 'Slack', url: 'slack.com', vibe: 'Colorful, friendly, enterprise-ready' },
      { name: 'Datadog', url: 'datadoghq.com', vibe: 'Technical but approachable' },
      { name: 'Snowflake', url: 'snowflake.com', vibe: 'Data-forward, enterprise trust' }
    ],
    creative_dtc: [
      { name: 'Glossier', url: 'glossier.com', vibe: 'Millennial pink, editorial, lifestyle' },
      { name: 'Aesop', url: 'aesop.com', vibe: 'Minimal luxury, typography-driven' },
      { name: 'Apple', url: 'apple.com', vibe: 'Product hero, premium, scroll-driven' },
      { name: 'Everlane', url: 'everlane.com', vibe: 'Transparent, clean, values-driven' }
    ],
    agencies_studios: [
      { name: 'Metalab', url: 'metalab.com', vibe: 'Case study heavy, premium positioning' },
      { name: 'Ueno', url: 'ueno.co', vibe: 'Playful, personality-driven' },
      { name: 'Work & Co', url: 'work.co', vibe: 'Enterprise clients, serious craft' },
      { name: 'Instrument', url: 'instrument.com', vibe: 'Brand + digital, beautiful work' }
    ],
    bold_experimental: [
      { name: 'Teenage Engineering', url: 'teenage.engineering', vibe: 'Product-obsessed, unique UI' },
      { name: 'Nothing', url: 'nothing.tech', vibe: 'Dot matrix, transparent, bold' },
      { name: 'Pentagram', url: 'pentagram.com', vibe: 'Gallery, work speaks' },
      { name: 'Ableton', url: 'ableton.com', vibe: 'Music tool, functional creativity' }
    ]
  };

  // Evaluation criteria
  private static readonly EVALUATION_CRITERIA = {
    trust_signals: [
      'Client logos (recognizable names)',
      'Case studies with outcomes',
      'Team photos and bios',
      'Years in business / project count',
      'Testimonials with real names',
      'Press mentions / awards',
      'Clear contact information',
      'Professional writing quality'
    ],
    clarity_factors: [
      'What do they actually do? (in 5 seconds)',
      'Who are they for?',
      'What makes them different?',
      'What does working with them look like?',
      'How much does it cost? (ballpark)',
      'How do I start a conversation?'
    ],
    differentiation_markers: [
      'Unique positioning statement',
      'Distinctive visual style',
      'Novel process or methodology',
      'Specific expertise/niche',
      'Business model innovation',
      'Personality/voice'
    ],
    red_flags: [
      'No real work shown',
      'Stock photos everywhere',
      'Vague buzzwords ("synergy", "solutions")',
      'No team information',
      'Broken links or outdated content',
      'No clear way to contact',
      'Prices hidden completely',
      'Too many services (jack of all trades)'
    ]
  };

  constructor() {
    super(
      'prospective-client-001',
      'Prospective Client',
      'systems-architect',
      'Simulates potential clients evaluating Rationale for hire. Provides buyer-perspective feedback on site effectiveness, trust signals, clarity, and differentiation. Can roleplay different personas (startup founder, enterprise buyer, etc.) and share reference sites they like.',
      ProspectiveClientAgent.getCapabilities(),
      '1.0.0'
    );
  }

  private static getCapabilities(): AgentCapability[] {
    return [
      {
        name: 'site-evaluation',
        description: 'Evaluate site from buyer perspective with specific persona'
      },
      {
        name: 'first-impression',
        description: 'Quick 5-second first impression test'
      },
      {
        name: 'trust-audit',
        description: 'Audit trust signals and credibility markers'
      },
      {
        name: 'clarity-test',
        description: 'Test if key questions are answered clearly'
      },
      {
        name: 'share-references',
        description: 'Share sites/designs the persona likes as references'
      },
      {
        name: 'raise-objections',
        description: 'Surface concerns and objections a buyer would have'
      },
      {
        name: 'competitive-compare',
        description: 'Compare to other agencies/studios buyer is considering'
      },
      {
        name: 'list-personas',
        description: 'List available buyer personas'
      },
      {
        name: 'create-persona',
        description: 'Create custom buyer persona'
      }
    ];
  }

  // ============================================================================
  // Message Handlers
  // ============================================================================

  protected async handleRequest(message: AgentMessage): Promise<AgentResponse> {
    this.log('info', `Handling request: ${message.action}`, { payload: message.payload });

    switch (message.action) {
      case 'evaluate':
      case 'site-evaluation':
        return this.handleSiteEvaluation(message.payload as SiteEvaluationRequest);
      
      case 'first-impression':
        return this.handleFirstImpression(message.payload as { persona?: string });
      
      case 'trust-audit':
        return this.handleTrustAudit(message.payload as { persona?: string });
      
      case 'clarity-test':
        return this.handleClarityTest(message.payload as { persona?: string });
      
      case 'share-references':
      case 'get-references':
        return this.handleShareReferences(message.payload as { persona?: string; category?: string });
      
      case 'raise-objections':
      case 'objections':
        return this.handleRaiseObjections(message.payload as { persona?: string });
      
      case 'competitive-compare':
      case 'compare':
        return this.handleCompetitiveCompare(message.payload as { persona?: string });
      
      case 'list-personas':
        return this.handleListPersonas();
      
      case 'create-persona':
        return this.handleCreatePersona(message.payload as Partial<ClientPersona>);
      
      case 'full-feedback':
        return this.handleFullFeedback(message.payload as SiteEvaluationRequest);
      
      default:
        return this.createErrorResponse(
          'UNKNOWN_ACTION',
          `Unknown action: ${message.action}`,
          { availableActions: [
            'evaluate', 'site-evaluation', 'first-impression', 'trust-audit',
            'clarity-test', 'share-references', 'raise-objections', 'competitive-compare',
            'list-personas', 'create-persona', 'full-feedback'
          ]}
        );
    }
  }

  protected async handleEvent(message: AgentMessage): Promise<AgentResponse> {
    return this.createSuccessResponse({ acknowledged: true });
  }

  protected async performTask(task: AgentTask): Promise<unknown> {
    if (task.type === 'client-evaluation') {
      const result = await this.handleSiteEvaluation(task.input as SiteEvaluationRequest);
      return result.data;
    }
    throw new Error(`Unknown task type: ${task.type}`);
  }

  // ============================================================================
  // Core Evaluation Methods
  // ============================================================================

  private async handleSiteEvaluation(request: SiteEvaluationRequest): Promise<AgentResponse<ClientEvaluationOutput>> {
    const persona = this.getPersona(request.persona);
    
    const output: ClientEvaluationOutput = {
      persona,
      first_impression: this.generateFirstImpression(persona),
      site_feedback: this.generateSiteFeedback(persona),
      aesthetic_preferences: this.generateAestheticPreferences(persona),
      questions_for_rationale: this.generateQuestions(persona),
      likelihood_to_reach_out: this.calculateLikelihood(persona),
      what_would_change_mind: this.generateWhatWouldHelp(persona),
      competitive_comparison: this.generateCompetitiveComparison(persona)
    };

    return this.createSuccessResponse(
      output,
      `Evaluation complete as ${persona.name} (${persona.role} at ${persona.company})`,
      output.site_feedback.missing.filter(m => m.importance === 'critical').map(m => m.need),
      output.what_would_change_mind.slice(0, 3)
    );
  }

  private async handleFirstImpression(input: { persona?: string }): Promise<AgentResponse> {
    const persona = this.getPersona(input.persona);
    const impression = this.generateFirstImpression(persona);
    
    return this.createSuccessResponse({
      persona: { name: persona.name, role: persona.role, company: persona.company },
      impression,
      verdict: impression.hook ? 'Would scroll further' : 'Might bounce',
      suggestions: this.getFirstImpressionSuggestions(impression)
    });
  }

  private async handleTrustAudit(input: { persona?: string }): Promise<AgentResponse> {
    const persona = this.getPersona(input.persona);
    
    return this.createSuccessResponse({
      persona: { name: persona.name, role: persona.role },
      trust_signals_found: [
        { signal: 'Client logos', status: 'present', effectiveness: 'medium', note: 'Good names but small display' },
        { signal: 'Case studies', status: 'partial', effectiveness: 'medium', note: 'Exist but lack depth/outcomes' },
        { signal: 'Team info', status: 'minimal', effectiveness: 'low', note: 'Need more founder story' },
        { signal: 'Testimonials', status: 'missing', effectiveness: 'n/a', note: 'Would significantly help' },
        { signal: 'Process clarity', status: 'present', effectiveness: 'high', note: 'Audit/Sprint/Pilot is clear' }
      ],
      trust_score: 6,
      what_this_persona_needs: persona.companyStage === 'enterprise' 
        ? ['References from similar-sized companies', 'Security/compliance info', 'Team size and capacity']
        : ['Proof you ship fast', 'Outcomes not just visuals', 'Founder story and credibility'],
      critical_gaps: [
        'No testimonials with real names',
        'Case studies lack business outcomes',
        'Fee + equity model needs social proof'
      ]
    });
  }

  private async handleClarityTest(input: { persona?: string }): Promise<AgentResponse> {
    const persona = this.getPersona(input.persona);
    
    const clarityChecks = [
      { question: 'What do they do?', answered: true, clarity: 7, note: 'Product studio is clear, dual engine less so' },
      { question: 'Who are they for?', answered: false, clarity: 4, note: 'Not obvious if Im a fit - startups? Enterprise? Both?' },
      { question: 'What makes them different?', answered: true, clarity: 6, note: 'Fee + equity is differentiating but buried' },
      { question: 'What does working with them look like?', answered: true, clarity: 8, note: 'Audit → Sprint → Pilot is very clear' },
      { question: 'How much does it cost?', answered: false, clarity: 2, note: 'No ballpark anywhere - I have no idea if I can afford this' },
      { question: 'How do I start?', answered: true, clarity: 7, note: 'CTA exists but could be more specific' }
    ];

    return this.createSuccessResponse({
      persona: { name: persona.name, role: persona.role },
      clarity_checks: clarityChecks,
      overall_clarity: Math.round(clarityChecks.reduce((a, c) => a + c.clarity, 0) / clarityChecks.length),
      as_this_persona: `As ${persona.name}, I ${persona.sophistication === 'high' ? 'get what they do' : 'am still confused about'} their positioning. My main uncertainty is: ${persona.concerns[0]}`,
      top_clarity_issues: clarityChecks.filter(c => c.clarity < 6).map(c => c.question)
    });
  }

  private async handleShareReferences(input: { persona?: string; category?: string }): Promise<AgentResponse> {
    const persona = this.getPersona(input.persona);
    const preferences = this.generateAestheticPreferences(persona);
    
    // Get relevant reference categories based on persona
    const relevantCategories = this.getRelevantCategories(persona);
    const references: Array<{ name: string; url: string; vibe: string; why_i_like_it: string }> = [];
    
    for (const cat of relevantCategories) {
      const categoryRefs = ProspectiveClientAgent.REFERENCE_LIBRARY[cat as keyof typeof ProspectiveClientAgent.REFERENCE_LIBRARY] || [];
      for (const ref of categoryRefs.slice(0, 2)) {
        references.push({
          ...ref,
          why_i_like_it: this.getWhyPersonaLikesReference(persona, ref)
        });
      }
    }

    return this.createSuccessResponse({
      persona: { name: persona.name, role: persona.role, company: persona.company },
      aesthetic_vibe: preferences.mood,
      references,
      specific_things_i_want: preferences.specific_requests,
      things_i_dont_want: preferences.dislikes.map(d => d.reference),
      note: `These are sites I (${persona.name}) find myself drawn to. I want Rationale's work to feel like it belongs in this company.`
    });
  }

  private async handleRaiseObjections(input: { persona?: string }): Promise<AgentResponse> {
    const persona = this.getPersona(input.persona);
    
    const objections = this.generateObjections(persona);
    
    return this.createSuccessResponse({
      persona: { name: persona.name, role: persona.role, company: persona.company },
      budget: persona.budget,
      timeline: persona.timeline,
      objections,
      internal_thoughts: this.getInternalThoughts(persona),
      what_would_overcome_objections: objections
        .filter(o => o.severity === 'blocker' || o.severity === 'hesitation')
        .map(o => this.getObjectionOvercome(o, persona))
    });
  }

  private async handleCompetitiveCompare(input: { persona?: string }): Promise<AgentResponse> {
    const persona = this.getPersona(input.persona);
    const comparison = this.generateCompetitiveComparison(persona);
    
    return this.createSuccessResponse({
      persona: { name: persona.name, role: persona.role },
      also_looking_at: comparison.also_considering,
      rationale_vs_others: {
        advantages: comparison.rationale_advantages,
        disadvantages: comparison.rationale_disadvantages
      },
      decision_criteria: this.getDecisionCriteria(persona),
      likely_winner: this.predictLikelyWinner(persona),
      what_rationale_needs_to_win: this.getWhatToWin(persona)
    });
  }

  private async handleListPersonas(): Promise<AgentResponse> {
    return this.createSuccessResponse({
      personas: ProspectiveClientAgent.CLIENT_PERSONAS.map(p => ({
        id: p.id,
        name: p.name,
        role: p.role,
        company: p.company,
        stage: p.companyStage,
        budget: p.budget,
        project_type: p.projectType
      })),
      usage: 'Pass persona id to any action, e.g., { persona: "startup-sarah" }'
    });
  }

  private async handleCreatePersona(input: Partial<ClientPersona>): Promise<AgentResponse> {
    const newPersona: ClientPersona = {
      id: input.id || `custom-${Date.now()}`,
      name: input.name || 'Custom Prospect',
      role: input.role || 'Product Leader',
      company: input.company || 'Tech Company',
      companyStage: input.companyStage || 'seed',
      budget: input.budget || '$50-150k',
      timeline: input.timeline || '2-3 months',
      projectType: input.projectType || 'greenfield',
      sophistication: input.sophistication || 'medium',
      priorities: input.priorities || ['Quality', 'Speed', 'Communication'],
      concerns: input.concerns || ['Cost', 'Timeline', 'Fit'],
      referenceStyle: input.referenceStyle || ['Clean', 'Modern', 'Professional']
    };

    return this.createSuccessResponse({
      persona: newPersona,
      note: 'Custom persona created. Use this ID in future requests.',
      example: `invokeProsectiveClient('evaluate', { persona: '${newPersona.id}' })`
    });
  }

  private async handleFullFeedback(request: SiteEvaluationRequest): Promise<AgentResponse> {
    const persona = this.getPersona(request.persona);
    
    return this.createSuccessResponse({
      persona: {
        name: persona.name,
        role: persona.role,
        company: persona.company,
        looking_for: persona.projectType,
        budget: persona.budget,
        timeline: persona.timeline
      },
      
      // The raw, unfiltered buyer perspective
      stream_of_consciousness: this.generateStreamOfConsciousness(persona),
      
      // Structured feedback
      helpful: [
        { element: 'Process clarity (Audit/Sprint/Pilot)', why: 'I know exactly what working with you looks like' },
        { element: 'Product engine (Zero Inbox)', why: 'Shows you actually ship, not just consult' },
        { element: 'Fee + equity model', why: 'Aligned incentives - you have skin in the game' },
        { element: 'Client logos', why: 'Meta, FuboTV - real companies, not just startups' }
      ],
      
      not_helpful: [
        { element: 'Vague hero messaging', issue: 'Takes too long to understand what you do', fix: 'Lead with "We build products" not abstract positioning' },
        { element: 'No pricing signals', issue: 'I have no idea if I can afford you', fix: 'Add "Engagements start at $X" or "Typical project: $X-Y"' },
        { element: 'Thin case studies', issue: 'I see screens but not outcomes', fix: 'Add: problem, solution, result (metrics)' },
        { element: 'No testimonials', issue: 'I only have your word', fix: 'Get 3-5 quotes from past clients' }
      ],
      
      what_i_want: {
        content: [
          'Real project outcomes with numbers',
          'Client testimonials (video would be amazing)',
          'Your process in more detail - what do the 2 weeks actually look like?',
          'Pricing transparency - even a range helps',
          'Who specifically will work on my project?'
        ],
        aesthetic: persona.referenceStyle,
        proof: [
          'Before/after for a rescue project',
          'Timeline of a real sprint',
          'Metrics from a launched product'
        ]
      },
      
      my_concerns: persona.concerns.map(c => ({
        concern: c,
        severity: this.assessConcernSeverity(c, persona),
        what_would_help: this.getConcernHelp(c, persona)
      })),
      
      bottom_line: {
        likelihood_to_reach_out: this.calculateLikelihood(persona),
        main_hesitation: persona.concerns[0],
        what_tips_me_over: `If I saw ${this.getKeyTipper(persona)}, I would definitely reach out.`
      }
    });
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  private getPersona(personaId?: string): ClientPersona {
    if (!personaId || personaId === 'random') {
      const randomIndex = Math.floor(Math.random() * ProspectiveClientAgent.CLIENT_PERSONAS.length);
      return ProspectiveClientAgent.CLIENT_PERSONAS[randomIndex];
    }
    
    const found = ProspectiveClientAgent.CLIENT_PERSONAS.find(p => p.id === personaId);
    if (!found) {
      // Default to startup sarah if not found
      return ProspectiveClientAgent.CLIENT_PERSONAS[0];
    }
    return found;
  }

  private generateFirstImpression(persona: ClientPersona): ClientEvaluationOutput['first_impression'] {
    const baseClarity = persona.sophistication === 'high' ? 7 : 5;
    const baseTrust = persona.companyStage === 'enterprise' ? 5 : 7;
    
    return {
      hook: persona.sophistication === 'high',
      clarity: baseClarity,
      trust: baseTrust,
      differentiation: 6,
      immediate_reaction: this.getImmediateReaction(persona)
    };
  }

  private getImmediateReaction(persona: ClientPersona): string {
    const reactions: Record<string, string> = {
      'startup-sarah': 'Interesting - they build their own products. Thats different. But can they move fast enough for my timeline?',
      'enterprise-eric': 'Looks like a boutique shop. Not sure if they can handle our scale and process requirements.',
      'founder-felix': 'Love the vibe. Fee + equity could work for me. But are they too expensive for pre-seed?',
      'rescue-rachel': 'Can they actually save my product or is this just another agency? I need proof they can turn things around.',
      'scaleup-sam': 'Solid positioning. But I need to see their team depth and if they can work alongside my designers.',
      'creative-carla': 'The aesthetic is interesting but feels very tech/SaaS. Will they understand brand and DTC?'
    };
    return reactions[persona.id] || 'Seems professional. Need to dig deeper to see if theyre right for us.';
  }

  private generateSiteFeedback(persona: ClientPersona): SiteFeedback {
    return {
      helpful: [
        { element: 'Dual engine model', why: 'Shows they have skin in the game with their own products' },
        { element: 'Clear process (Audit/Sprint/Pilot)', why: 'I understand what engagement looks like' },
        { element: 'Fee + equity option', why: 'Unique - havent seen this elsewhere' }
      ],
      confusing: [
        { element: 'Target audience', issue: 'Am I the right fit? Startups? Enterprise? Both?', suggestion: 'Add "We work with..." section with clear segments' },
        { element: 'Pricing', issue: 'No idea what this costs', suggestion: 'Add ballpark ranges or "Starting at" language' },
        { element: 'Team', issue: 'Who will actually work on my project?', suggestion: 'Show the team with roles and experience' }
      ],
      missing: [
        { need: 'Client testimonials', importance: 'critical' },
        { need: 'Detailed case studies with outcomes', importance: 'critical' },
        { need: 'Pricing transparency', importance: 'important' },
        { need: 'Team page with bios', importance: 'important' },
        { need: 'FAQ section', importance: 'nice-to-have' }
      ],
      objections: this.generateObjections(persona),
      decision_factors: [
        { factor: 'Quality of work', current_score: 7, notes: 'Work looks good but need more depth' },
        { factor: 'Process clarity', current_score: 8, notes: 'Very clear engagement model' },
        { factor: 'Trust/credibility', current_score: 6, notes: 'Need testimonials and more proof' },
        { factor: 'Fit for my needs', current_score: 5, notes: 'Not sure if they do my type of project' },
        { factor: 'Value for money', current_score: 4, notes: 'Cannot assess - no pricing info' }
      ]
    };
  }

  private generateObjections(persona: ClientPersona): SiteFeedback['objections'] {
    const baseObjections = [
      { concern: 'No pricing information - I dont know if I can afford this', severity: 'hesitation' as const },
      { concern: 'No testimonials from past clients', severity: 'hesitation' as const },
      { concern: 'Case studies lack business outcomes', severity: 'minor' as const }
    ];

    const personaSpecific: Record<string, Array<{ concern: string; severity: 'blocker' | 'hesitation' | 'minor' }>> = {
      'enterprise-eric': [
        { concern: 'Team seems small for our needs', severity: 'blocker' },
        { concern: 'No enterprise references shown', severity: 'hesitation' },
        { concern: 'Security/compliance not addressed', severity: 'hesitation' }
      ],
      'founder-felix': [
        { concern: 'Might be too expensive for pre-seed', severity: 'blocker' },
        { concern: 'Do they take early-stage seriously?', severity: 'hesitation' }
      ],
      'rescue-rachel': [
        { concern: 'No rescue/turnaround case studies', severity: 'blocker' },
        { concern: 'Can they move fast enough?', severity: 'hesitation' }
      ],
      'creative-carla': [
        { concern: 'Feels very tech - will they get brand?', severity: 'hesitation' },
        { concern: 'No DTC or e-commerce examples', severity: 'hesitation' }
      ]
    };

    return [...baseObjections, ...(personaSpecific[persona.id] || [])];
  }

  private generateAestheticPreferences(persona: ClientPersona): AestheticPreferences {
    const prefsByPersona: Record<string, AestheticPreferences> = {
      'startup-sarah': {
        likes: [
          { reference: 'Linear', url: 'linear.app', what_works: 'Clean, fast, respects my intelligence' },
          { reference: 'Notion', url: 'notion.so', what_works: 'Friendly but professional' }
        ],
        dislikes: [
          { reference: 'Overly corporate sites', why: 'Feel slow and outdated' },
          { reference: 'Too much animation', why: 'Gets in the way' }
        ],
        mood: ['Clean', 'Fast', 'Modern SaaS', 'Trustworthy'],
        specific_requests: ['Dark mode option', 'Clear CTAs', 'Mobile-optimized']
      },
      'enterprise-eric': {
        likes: [
          { reference: 'Stripe', url: 'stripe.com', what_works: 'Premium but not flashy, trustworthy' },
          { reference: 'Figma', url: 'figma.com', what_works: 'Professional with personality' }
        ],
        dislikes: [
          { reference: 'Too playful/startup-y', why: 'Hard to take to my leadership' },
          { reference: 'Dark themes', why: 'Can feel less professional in enterprise context' }
        ],
        mood: ['Premium', 'Trustworthy', 'Scalable', 'Sophisticated'],
        specific_requests: ['Light theme', 'Clear navigation', 'Enterprise-ready case studies']
      },
      'founder-felix': {
        likes: [
          { reference: 'Vercel', url: 'vercel.com', what_works: 'Developer-focused, dark, premium' },
          { reference: 'Raycast', url: 'raycast.com', what_works: 'Feels like a power tool' }
        ],
        dislikes: [
          { reference: 'Generic agency sites', why: 'All look the same' },
          { reference: 'Too much text', why: 'Show me, dont tell me' }
        ],
        mood: ['Developer-friendly', 'Bold', 'Unique', 'Fast'],
        specific_requests: ['Terminal aesthetics are cool', 'Show technical depth', 'Minimal but impactful']
      },
      'creative-carla': {
        likes: [
          { reference: 'Aesop', url: 'aesop.com', what_works: 'Typography-driven, minimal luxury' },
          { reference: 'Apple', url: 'apple.com', what_works: 'Product as hero, scroll storytelling' }
        ],
        dislikes: [
          { reference: 'Tech bro aesthetic', why: 'Doesnt feel like my world' },
          { reference: 'Blue and white SaaS', why: 'Boring and commoditized' }
        ],
        mood: ['Editorial', 'Brand-forward', 'Unique', 'Lifestyle'],
        specific_requests: ['Beautiful typography', 'Image-rich', 'Story-driven']
      }
    };

    return prefsByPersona[persona.id] || {
      likes: [{ reference: 'Clean modern sites', what_works: 'Professional and clear' }],
      dislikes: [{ reference: 'Cluttered designs', why: 'Hard to find what I need' }],
      mood: ['Professional', 'Clear', 'Modern'],
      specific_requests: ['Good mobile experience', 'Fast loading']
    };
  }

  private generateQuestions(persona: ClientPersona): string[] {
    const common = [
      'What does a typical engagement cost?',
      'Who specifically would work on my project?',
      'Can you show me a project similar to mine?',
      'Whats your availability?'
    ];

    const personaSpecific: Record<string, string[]> = {
      'startup-sarah': ['Do you have healthcare experience?', 'How does the equity arrangement work?'],
      'enterprise-eric': ['What size projects have you handled?', 'How do you handle security requirements?'],
      'founder-felix': ['Would you consider an equity-only deal?', 'How fast can you start?'],
      'rescue-rachel': ['Have you rescued a failing product before?', 'What does the first week look like?'],
      'scaleup-sam': ['Can you work embedded with my team?', 'How do you handle knowledge transfer?']
    };

    return [...common, ...(personaSpecific[persona.id] || [])];
  }

  private calculateLikelihood(persona: ClientPersona): number {
    // Base likelihood varies by persona
    const baseLikelihood: Record<string, number> = {
      'startup-sarah': 7,
      'enterprise-eric': 4,
      'founder-felix': 6,
      'rescue-rachel': 5,
      'scaleup-sam': 6,
      'creative-carla': 5
    };
    return baseLikelihood[persona.id] || 5;
  }

  private generateWhatWouldHelp(persona: ClientPersona): string[] {
    const common = [
      'Add 3-5 client testimonials with real names and companies',
      'Show business outcomes in case studies (metrics, not just visuals)',
      'Add pricing ranges or "typical engagement" costs'
    ];

    const personaSpecific: Record<string, string[]> = {
      'startup-sarah': ['Show healthcare or regulated industry experience', 'Explain equity terms clearly'],
      'enterprise-eric': ['Add enterprise-scale case studies', 'Show team depth and process rigor'],
      'founder-felix': ['Have a clear early-stage offering', 'Show you can move in weeks not months'],
      'rescue-rachel': ['Add a turnaround case study', 'Show fast-start capability'],
      'creative-carla': ['Show brand-forward work', 'Add DTC or lifestyle examples']
    };

    return [...common, ...(personaSpecific[persona.id] || [])];
  }

  private generateCompetitiveComparison(persona: ClientPersona): ClientEvaluationOutput['competitive_comparison'] {
    const competitors: Record<string, string[]> = {
      'startup-sarah': ['Ueno', 'Metalab', 'a]boutique agency', 'freelance designer'],
      'enterprise-eric': ['McKinsey Digital', 'IDEO', 'Work & Co', 'internal team expansion'],
      'founder-felix': ['freelance developer', 'another technical co-founder', 'doing it myself'],
      'rescue-rachel': ['Thoughtbot', 'Pivotal', 'consulting firm', 'new internal hire'],
      'scaleup-sam': ['Metalab', 'Instrument', 'design team expansion', 'contract designers']
    };

    return {
      also_considering: competitors[persona.id] || ['Other agencies', 'Freelancers', 'Internal hire'],
      rationale_advantages: [
        'Fee + equity model is unique',
        'Build their own products (proof they can ship)',
        'Clear process (Audit/Sprint/Pilot)',
        'Seems more hands-on than big agencies'
      ],
      rationale_disadvantages: [
        'Smaller team than big agencies',
        'Less brand recognition',
        'No pricing transparency',
        'Thin case study depth'
      ]
    };
  }

  private getFirstImpressionSuggestions(impression: ClientEvaluationOutput['first_impression']): string[] {
    const suggestions = [];
    if (impression.clarity < 7) suggestions.push('Make value prop clearer in first 5 seconds');
    if (impression.trust < 7) suggestions.push('Add trust signals above the fold');
    if (impression.differentiation < 7) suggestions.push('Lead with what makes you different');
    if (!impression.hook) suggestions.push('Hero needs a stronger hook - why should I care?');
    return suggestions;
  }

  private getRelevantCategories(persona: ClientPersona): string[] {
    const categoryMap: Record<string, string[]> = {
      'startup-sarah': ['saas_clean', 'fintech'],
      'enterprise-eric': ['enterprise', 'fintech'],
      'founder-felix': ['saas_clean', 'bold_experimental'],
      'rescue-rachel': ['saas_clean', 'enterprise'],
      'scaleup-sam': ['fintech', 'enterprise'],
      'creative-carla': ['creative_dtc', 'bold_experimental']
    };
    return categoryMap[persona.id] || ['saas_clean', 'agencies_studios'];
  }

  private getWhyPersonaLikesReference(persona: ClientPersona, ref: { name: string; vibe: string }): string {
    return `${ref.vibe} - this is the quality bar I expect`;
  }

  private getInternalThoughts(persona: ClientPersona): string {
    const thoughts: Record<string, string> = {
      'startup-sarah': 'They seem legit, but every agency says they "ship fast." I need proof. And I really need to know if this fits my budget before I waste time on a call.',
      'enterprise-eric': 'Interesting boutique option, but my CFO will ask why were not going with McKinsey or a Big 4. I need ammunition to justify this choice.',
      'founder-felix': 'Love the vibe and the equity angle. But am I too small for them? Will they actually prioritize me?',
      'rescue-rachel': 'I dont have time for agency theater. Can they actually diagnose and fix, or just make it pretty? I need someone whos been in the fire.',
      'scaleup-sam': 'Could be a good complement to my team. But I need to know they can work WITH us, not just FOR us.',
      'creative-carla': 'The work looks good but feels very tech. I need to see they can do brand, not just product.'
    };
    return thoughts[persona.id] || 'Seems professional, but I need more proof before reaching out.';
  }

  private getObjectionOvercome(objection: SiteFeedback['objections'][0], persona: ClientPersona): string {
    const overcomes: Record<string, string> = {
      'No pricing information': 'Add "Typical engagements: $50K-500K depending on scope" or similar range',
      'No testimonials': 'Get 3 video testimonials from recognizable clients',
      'Team seems small': 'Show team page with capabilities and past enterprise work',
      'Might be too expensive': 'Add "We work with teams at all stages" and show early-stage case study',
      'No rescue case studies': 'Add a detailed turnaround story with timeline and outcomes'
    };
    
    for (const key of Object.keys(overcomes)) {
      if (objection.concern.includes(key.split(' ')[1])) {
        return overcomes[key];
      }
    }
    return 'Address this directly on the site with proof';
  }

  private getDecisionCriteria(persona: ClientPersona): Array<{ criterion: string; weight: string }> {
    return persona.priorities.map((p, i) => ({
      criterion: p,
      weight: i === 0 ? 'Critical' : i === 1 ? 'Important' : 'Nice to have'
    }));
  }

  private predictLikelyWinner(persona: ClientPersona): string {
    const predictions: Record<string, string> = {
      'startup-sarah': 'Rationale has a shot if they can prove speed and show healthcare-adjacent work',
      'enterprise-eric': 'Probably going with larger agency unless Rationale shows enterprise chops',
      'founder-felix': 'Rationale could win on equity model if they show early-stage love',
      'rescue-rachel': 'Needs to see turnaround proof - currently leaning toward known rescue shops',
      'scaleup-sam': 'Good fit potential - need to see team collaboration approach',
      'creative-carla': 'Uncertain - need to see brand-forward work or might go with creative agency'
    };
    return predictions[persona.id] || 'Decision depends on initial call and fit assessment';
  }

  private getWhatToWin(persona: ClientPersona): string[] {
    const wins: Record<string, string[]> = {
      'startup-sarah': ['Healthcare case study', 'Clear equity terms', 'Fast-start option'],
      'enterprise-eric': ['Enterprise reference call', 'Process documentation', 'Team capacity proof'],
      'founder-felix': ['Early-stage pricing', 'Founder-to-founder call', 'Speed proof'],
      'rescue-rachel': ['Turnaround case study', 'Week-1 plan preview', 'Emergency availability'],
      'scaleup-sam': ['Embedded team model', 'Design system expertise', 'Handoff process'],
      'creative-carla': ['Brand-forward portfolio', 'DTC experience', 'Creative director involvement']
    };
    return wins[persona.id] || ['More case studies', 'Pricing transparency', 'Testimonials'];
  }

  private assessConcernSeverity(concern: string, persona: ClientPersona): 'blocker' | 'hesitation' | 'minor' {
    if (concern.toLowerCase().includes('afford') || concern.toLowerCase().includes('cost')) {
      return persona.companyStage === 'pre-seed' ? 'blocker' : 'hesitation';
    }
    if (concern.toLowerCase().includes('understand') || concern.toLowerCase().includes('domain')) {
      return 'hesitation';
    }
    return 'minor';
  }

  private getConcernHelp(concern: string, persona: ClientPersona): string {
    if (concern.toLowerCase().includes('afford') || concern.toLowerCase().includes('cost')) {
      return 'Pricing ranges on site or "free intro call" to discuss budget fit';
    }
    if (concern.toLowerCase().includes('domain') || concern.toLowerCase().includes('understand')) {
      return 'Case study in relevant industry or team bio showing domain experience';
    }
    return 'Direct testimonial or case study addressing this concern';
  }

  private getKeyTipper(persona: ClientPersona): string {
    const tippers: Record<string, string> = {
      'startup-sarah': 'a healthcare startup case study with real outcomes',
      'enterprise-eric': 'references from Fortune 500 companies and enterprise process documentation',
      'founder-felix': 'a clear early-stage offering with flexible equity terms',
      'rescue-rachel': 'a detailed product turnaround case study with timeline',
      'scaleup-sam': 'examples of embedded team work and knowledge transfer',
      'creative-carla': 'beautiful brand-forward DTC work that rivals top creative agencies'
    };
    return tippers[persona.id] || 'strong testimonials and clear pricing';
  }

  private generateStreamOfConsciousness(persona: ClientPersona): string {
    const streams: Record<string, string> = {
      'startup-sarah': `Okay, landing on the site... "Rationale" - interesting name. What do they do? Product studio... cool, but so is everyone. Wait, they build their own products too? Zero Inbox looks legit. That's different - means they actually ship, not just advise. Fee + equity caught my eye - that's aligned incentives which I like. But... scrolling... scrolling... where are the prices? I have $150K, maybe $200K max. Am I wasting my time here? No healthcare examples which worries me. The Audit/Sprint/Pilot thing is super clear though. I know exactly what I'd be buying. But still no testimonials? Just their word. Hmm. I'd probably book a call but I'm a bit nervous about budget fit.`,
      
      'enterprise-eric': `First impression: looks like a boutique shop. Nice design but we're a $10B company - can they handle us? Scrolling for team size... can't find it. Client logos are good (Meta, FuboTV) but not enterprise enterprises if you know what I mean. No mention of security, compliance, SOC2... that's going to be a problem with our procurement. The fee + equity thing is interesting but our legal would never go for it. Process looks solid. But I'm comparing this to McKinsey Digital and Work & Co - they have the brand recognition I can sell internally. I'd need a really compelling reference call to take this seriously.`,
      
      'founder-felix': `Oh this is cool - love the vibe. Wait they do equity deals? That's huge for me. I have like $40K runway for design/dev and was going to struggle with agencies. Let me see if they take pre-seed seriously... not obvious. Their products look solid - these people actually code, not just push pixels. The terminal aesthetic speaks to me as a technical founder. But are they too "big" for me? Would I get the B-team? No pricing is frustrating but maybe that's where the equity conversation comes in. I'd reach out for sure but I'd lead with "I'm pre-seed, is that okay?" to not waste either of our time.`,
      
      'rescue-rachel': `I don't have time for this. Does this agency fix broken products or not? Scrolling... nothing about turnarounds or rescue projects. Everyone shows their highlight reel. I need to see "Client came to us with a failing app, we shipped fixes in 2 weeks, here's what happened." The process stuff is fine but I don't have 2 weeks for an audit - I need someone who can parachute in. No testimonials from someone saying "they saved our launch" - that's what I need to see. Might reach out but I'm skeptical. They seem more "build new things" than "fix broken things."`,
      
      'scaleup-sam': `Decent studio. Work looks good. But I have 8 designers on staff - I need to know how they work WITH existing teams. Can they embed? Do they just hand off Figma files or actually work in our systems? The design system stuff interests me but I don't see deep expertise shown. Fee + equity doesn't apply to us (we're well-funded) but their process alignment is good. I'd want to see: their team, how they've worked alongside in-house teams before, knowledge transfer approach. Site's missing the "partnership" angle that would close me.`,
      
      'creative-carla': `Hmm, feels very tech. Very "SaaS". I'm building a beauty brand and I need someone who gets that. The work looks solid but it's all dashboards and apps - where's the editorial? The brand work? I don't see any e-commerce, any Shopify, any DTC experience. The aesthetic is interesting but would they make everything look like this? I need someone who can adapt to MY brand, not impose their style. Would need to see them prove they can do brand-forward, photography-rich, magazine-feel work. Otherwise I'm going to a creative agency.`
    };
    
    return streams[persona.id] || 'Looking at the site... seems professional. Need to see more proof before I reach out.';
  }
}

import { BaseAgent } from '../core/base-agent';
import { 
  AgentMessage, 
  AgentResponse, 
  AgentTask,
  AgentCapability
} from '../types/agent.types';
import { generateId } from '../utils/helpers';

// ============================================================================
// Marketing Types
// ============================================================================

interface MarketingRequest {
  type: 'copy' | 'campaign' | 'social' | 'email' | 'landing-page' | 'audit';
  audience?: string[];
  tone?: 'professional' | 'casual' | 'bold' | 'technical' | 'inspirational';
  platform?: 'twitter' | 'linkedin' | 'instagram' | 'tiktok' | 'newsletter' | 'blog';
  context?: string;
  product?: string;
  goal?: 'awareness' | 'engagement' | 'conversion' | 'retention';
}

interface CopyVariant {
  version: string;
  headline: string;
  body: string;
  cta: string;
  notes?: string;
}

interface SocialPost {
  platform: string;
  content: string;
  hashtags?: string[];
  timing?: string;
  media_suggestion?: string;
  hook?: string;
}

interface CampaignPlan {
  name: string;
  objective: string;
  duration: string;
  channels: string[];
  phases: Array<{
    phase: string;
    duration: string;
    activities: string[];
    kpis: string[];
  }>;
  content_pillars: string[];
  budget_allocation?: Record<string, number>;
}

interface MarketingAuditOutput {
  brand_voice_score: number;
  messaging_consistency: number;
  channel_effectiveness: Record<string, number>;
  recommendations: string[];
  competitor_comparison?: string[];
}

// ============================================================================
// Marketing Agent
// ============================================================================

export class MarketingAgent extends BaseAgent {
  
  // Marketing knowledge base
  private static readonly MARKETING_KNOWLEDGE = {
    frameworks: {
      'AIDA': 'Attention → Interest → Desire → Action',
      'PAS': 'Problem → Agitation → Solution',
      'BAB': 'Before → After → Bridge',
      'QUEST': 'Qualify → Understand → Educate → Stimulate → Transition',
      '4Ps': 'Promise → Picture → Proof → Push',
      'StoryBrand': 'Character → Problem → Guide → Plan → CTA → Success → Failure avoided'
    },
    psychological_triggers: [
      'Scarcity (limited time/availability)',
      'Social proof (testimonials, numbers)',
      'Authority (credentials, logos)',
      'Reciprocity (give value first)',
      'Commitment (small yes → big yes)',
      'Liking (relatability, personality)',
      'Loss aversion (what they\'ll miss)',
      'Specificity (concrete > vague)'
    ],
    headline_formulas: [
      'How to [achieve X] without [pain point]',
      'The [number] [things] [audience] need to [outcome]',
      '[Do X] like [aspirational example]',
      'Stop [common mistake]. Start [better approach].',
      'What [trusted source] taught me about [topic]',
      '[Number]% of [audience] [surprising fact]',
      'The secret to [outcome] (that nobody talks about)',
      'I [did X] for [time]. Here\'s what happened.',
      'Why [counterintuitive claim]',
      '[Outcome] in [timeframe] — without [sacrifice]'
    ],
    platform_best_practices: {
      twitter: {
        optimal_length: '70-100 characters for engagement, up to 280 max',
        best_times: '9am, 12pm, 5pm weekdays',
        hooks: ['Hot take', 'Thread intro', 'Question', 'Contrarian view'],
        tips: ['Use line breaks', 'End with CTA or question', 'Quote tweet > retweet']
      },
      linkedin: {
        optimal_length: '1200-1500 characters for engagement',
        best_times: 'Tue-Thu, 7-8am, 12pm, 5-6pm',
        hooks: ['Personal story', 'Lesson learned', 'Unpopular opinion', 'Framework share'],
        tips: ['Use "I" statements', 'Add line breaks every 1-2 sentences', 'End with question']
      },
      instagram: {
        optimal_length: 'Caption: 125-150 chars for feed, full for carousel',
        best_times: '11am-1pm, 7-9pm',
        hooks: ['Bold statement', 'Question', 'This vs That'],
        tips: ['Lead with value', 'Carousel > single image', 'Story for behind-the-scenes']
      },
      newsletter: {
        optimal_length: '500-1000 words for weekly, 200-400 for updates',
        best_times: 'Tue-Thu morning',
        hooks: ['Personal anecdote', 'Timely hook', 'Promise of value'],
        tips: ['One big idea per issue', 'Scannable format', 'Clear single CTA']
      }
    },
    content_pillars: {
      'studio': ['Behind the scenes', 'Process insights', 'Team culture', 'Client wins'],
      'thought_leadership': ['Industry trends', 'Frameworks', 'Predictions', 'Hot takes'],
      'product': ['Feature highlights', 'Use cases', 'Customer stories', 'Roadmap'],
      'educational': ['How-tos', 'Tutorials', 'Tips', 'Common mistakes'],
      'community': ['User highlights', 'Q&A', 'Polls', 'Discussions']
    }
  };

  constructor() {
    super(
      'marketing-agent-001',
      'Marketing Agent',
      'systems-architect',
      'Marketing strategist and copywriter. Creates compelling copy, campaigns, and social content. Expert in AIDA, PAS, StoryBrand frameworks and platform-specific best practices.',
      MarketingAgent.getCapabilities(),
      '1.0.0'
    );
  }

  private static getCapabilities(): AgentCapability[] {
    return [
      {
        name: 'copywriting',
        description: 'Headlines, taglines, body copy, CTAs'
      },
      {
        name: 'social-content',
        description: 'Platform-optimized social media posts'
      },
      {
        name: 'campaign-planning',
        description: 'Multi-channel marketing campaign strategy'
      },
      {
        name: 'email-marketing',
        description: 'Email sequences, newsletters, drip campaigns'
      },
      {
        name: 'landing-page-copy',
        description: 'Conversion-focused landing page content'
      },
      {
        name: 'content-calendar',
        description: 'Content planning and scheduling'
      },
      {
        name: 'brand-voice',
        description: 'Brand voice development and guidelines'
      },
      {
        name: 'marketing-audit',
        description: 'Review existing marketing for effectiveness'
      }
    ];
  }

  // ============================================================================
  // Message Handlers
  // ============================================================================

  protected async handleRequest(message: AgentMessage): Promise<AgentResponse> {
    this.log('info', `Handling request: ${message.action}`, { payload: message.payload });

    switch (message.action) {
      case 'write-copy':
        return this.handleWriteCopy(message.payload as MarketingRequest);
      
      case 'create-social-post':
        return this.handleCreateSocialPost(message.payload as MarketingRequest);
      
      case 'create-campaign':
        return this.handleCreateCampaign(message.payload as MarketingRequest);
      
      case 'write-email':
        return this.handleWriteEmail(message.payload as MarketingRequest);
      
      case 'landing-page-copy':
        return this.handleLandingPageCopy(message.payload as MarketingRequest);
      
      case 'content-calendar':
        return this.handleContentCalendar(message.payload as MarketingRequest);
      
      case 'brand-voice-guide':
        return this.handleBrandVoiceGuide(message.payload as MarketingRequest);
      
      case 'audit':
        return this.handleMarketingAudit(message.payload as MarketingRequest);
      
      case 'generate-hooks':
        return this.handleGenerateHooks(message.payload as { topic: string; platform: string });
      
      case 'get-knowledge':
        return this.handleGetKnowledge();
      
      default:
        return this.createErrorResponse(
          'UNKNOWN_ACTION',
          `Unknown action: ${message.action}`,
          { availableActions: [
            'write-copy', 'create-social-post', 'create-campaign', 'write-email',
            'landing-page-copy', 'content-calendar', 'brand-voice-guide', 'audit',
            'generate-hooks', 'get-knowledge'
          ]}
        );
    }
  }

  protected async handleEvent(message: AgentMessage): Promise<AgentResponse> {
    return this.createSuccessResponse({ acknowledged: true });
  }

  protected async performTask(task: AgentTask): Promise<unknown> {
    if (task.type === 'marketing-campaign') {
      const result = await this.handleCreateCampaign(task.input as MarketingRequest);
      return result.data;
    }
    throw new Error(`Unknown task type: ${task.type}`);
  }

  // ============================================================================
  // Core Marketing Methods
  // ============================================================================

  private async handleWriteCopy(request: MarketingRequest): Promise<AgentResponse> {
    const variants: CopyVariant[] = [
      {
        version: 'Direct',
        headline: 'Design that ships',
        body: 'We help product teams go from idea to launched product. Strategy-led design with skin in the game.',
        cta: 'Start a project',
        notes: 'Simple, action-oriented, clear value prop'
      },
      {
        version: 'Benefit-led',
        headline: 'Products that users love, investors fund',
        body: 'Partner with a studio that builds its own products. We know what it takes because we do it ourselves.',
        cta: 'See our work',
        notes: 'Focuses on outcomes, builds credibility through own products'
      },
      {
        version: 'Problem-led (PAS)',
        headline: 'Tired of design that doesn\'t ship?',
        body: 'Most agencies deliver mockups, not products. We stay until launch—and we have equity to prove we care.',
        cta: 'Work with us',
        notes: 'Agitates common frustration, differentiates with equity model'
      },
      {
        version: 'Aspirational',
        headline: 'Conviction before code',
        body: 'Build something worth building. We\'re the strategy-first studio for founders who want a partner, not a vendor.',
        cta: 'Partner with us',
        notes: 'Emotional appeal, positions client as discerning'
      }
    ];

    return this.createSuccessResponse({
      variants,
      recommendation: variants[1],
      frameworks_applied: ['PAS (Problem-Agitate-Solution)', '4Ps', 'StoryBrand'],
      testing_suggestion: 'A/B test Direct vs Benefit-led on homepage'
    });
  }

  private async handleCreateSocialPost(request: MarketingRequest): Promise<AgentResponse> {
    const platform = request.platform || 'linkedin';
    const posts: SocialPost[] = [];

    if (platform === 'linkedin' || platform === 'twitter') {
      posts.push({
        platform: 'LinkedIn',
        hook: 'The best design agencies have a secret:',
        content: `The best design agencies have a secret:

They build their own products.

Why? Because:
→ It proves they can ship, not just deliver mockups
→ They understand founder problems firsthand  
→ They stay sharp on real constraints

We take this further:
Fee + equity partnerships that align incentives.

If we're good enough to take equity, we're good enough to hire.`,
        hashtags: ['#ProductDesign', '#StartupDesign', '#VentureStudio'],
        timing: 'Tuesday-Thursday, 8am or 12pm',
        media_suggestion: 'Carousel showing product screenshots or before/after'
      });

      posts.push({
        platform: 'Twitter/X',
        hook: 'Unpopular opinion:',
        content: `Unpopular opinion:

Design agencies that don't build their own products are just guessing.

We build products like Zero (AI email) while also working with clients.

Skin in the game > pretty portfolios.`,
        hashtags: ['#design', '#startups'],
        timing: 'Weekday mornings, 9am or 12pm',
        media_suggestion: 'Screenshot of Zero app or product demo gif'
      });
    }

    if (platform === 'instagram' || platform === 'linkedin') {
      posts.push({
        platform: 'Instagram',
        hook: 'This is what skin in the game looks like 👇',
        content: `This is what skin in the game looks like 👇

Most agencies: Deliver mockups. Invoice. Move on.

Us: Reduce our fee. Take equity. Stay until launch.

Why would we do that?

Because we only work on products we believe in.

If we're not willing to invest, why should you pay us?

DM "PARTNER" if you're building something worth building.`,
        hashtags: ['#productdesign', '#startuplife', '#designstudio', '#uxdesign'],
        timing: '11am-1pm or 7-9pm',
        media_suggestion: 'Carousel: Slide 1 = hook, Slide 2-4 = process, Slide 5 = CTA'
      });
    }

    return this.createSuccessResponse({
      posts,
      content_pillar: 'thought_leadership',
      engagement_tips: [
        'Respond to every comment within 2 hours',
        'Ask a question at the end',
        'Tag 1-2 relevant people if appropriate'
      ]
    });
  }

  private async handleCreateCampaign(request: MarketingRequest): Promise<AgentResponse> {
    const campaign: CampaignPlan = {
      name: 'Studio Launch Campaign',
      objective: request.goal || 'awareness',
      duration: '6 weeks',
      channels: ['LinkedIn', 'Twitter', 'Email', 'Direct outreach'],
      phases: [
        {
          phase: 'Teaser (Week 1)',
          duration: '1 week',
          activities: [
            'Behind-the-scenes content on social',
            'Email to existing list: "Something new coming"',
            'Personal DMs to warm network'
          ],
          kpis: ['Email open rate > 40%', 'Social impressions', 'DM response rate']
        },
        {
          phase: 'Launch (Week 2-3)',
          duration: '2 weeks',
          activities: [
            'Official announcement post on all channels',
            'Product hunt / relevant community launch',
            'Email sequence (3 emails)',
            'Partner cross-promotion',
            'Founder personal posts'
          ],
          kpis: ['Website traffic', 'Inbound leads', 'Social engagement rate > 5%']
        },
        {
          phase: 'Social Proof (Week 4-5)',
          duration: '2 weeks',
          activities: [
            'Client testimonial content',
            'Case study deep-dive posts',
            'User-generated content amplification',
            'Podcast/interview outreach'
          ],
          kpis: ['Case study views', 'Testimonial engagement', 'Inbound leads quality']
        },
        {
          phase: 'Conversion Push (Week 6)',
          duration: '1 week',
          activities: [
            'Limited-time offer or bonus',
            'Direct outreach to engaged prospects',
            'Retargeting (if paid)',
            'Closing email sequence'
          ],
          kpis: ['Meetings booked', 'Proposals sent', 'Conversion rate']
        }
      ],
      content_pillars: ['Product showcase', 'Client wins', 'Founder insights', 'Industry hot takes'],
      budget_allocation: {
        'Organic social': 30,
        'Email marketing': 20,
        'Direct outreach': 25,
        'Paid promotion (optional)': 15,
        'Production/design': 10
      }
    };

    return this.createSuccessResponse({
      campaign,
      success_metrics: [
        '50+ inbound leads',
        '10+ qualified meetings',
        '3+ new projects',
        '500+ email list growth'
      ],
      risk_mitigation: [
        'Have backup content if launch content underperforms',
        'Prepare FAQ for common objections',
        'Have case study ready if social proof phase needs help'
      ]
    });
  }

  private async handleWriteEmail(request: MarketingRequest): Promise<AgentResponse> {
    const emailSequence = [
      {
        email: 1,
        subject: 'A different kind of design partnership',
        preview: 'We put our money where our design is',
        body: `Hey {{firstName}},

I noticed you're building [specific observation about their product/company].

I run Rationale, a product design studio that works a bit differently:

We take equity alongside our fee.

Why? Because we only work on products we genuinely believe in. If we're not willing to invest, why should you pay us?

Our clients have raised $50M+. We build our own products too (like Zero, an AI email client).

Would you be open to a 15-minute chat to see if there's a fit?

— Matt`,
        send_timing: 'Day 1',
        goal: 'Get reply or meeting'
      },
      {
        email: 2,
        subject: 'Quick follow-up (with proof)',
        preview: '3 products we helped ship last quarter',
        body: `{{firstName}},

Following up on my last note. 

Wanted to share what we shipped last quarter:
→ [Product 1] - raised Series A after redesign
→ [Product 2] - 3x conversion after UX overhaul  
→ [Product 3] - launched from zero to 10K users

All with our fee + equity model.

If you're planning any product work in the next 3-6 months, I'd love to explore a partnership.

Worth a quick call?

— Matt`,
        send_timing: 'Day 4',
        goal: 'Provide proof, lower barrier'
      },
      {
        email: 3,
        subject: 'Last one (for now)',
        preview: 'Closing the loop',
        body: `{{firstName}},

I'll keep this short—I know you're busy.

If the timing isn't right for a design partner, totally understand. 

But if you ever want to explore our fee + equity model, just reply to this email. I'll be here.

In the meantime, feel free to check out our work: [link]

Cheers,
Matt`,
        send_timing: 'Day 8',
        goal: 'Graceful close, leave door open'
      }
    ];

    return this.createSuccessResponse({
      sequence: emailSequence,
      best_practices: [
        'Personalize the first line with real observation',
        'Keep to 100-150 words per email',
        'Single CTA per email',
        'Send Tuesday-Thursday, 8am-10am recipient time',
        'Wait 3-4 days between emails'
      ],
      subject_line_variants: [
        'A different kind of design partnership',
        'Fee + equity (serious inquiry)',
        'Would love to design [their product]',
        'Quick question about [their company]'
      ]
    });
  }

  private async handleLandingPageCopy(request: MarketingRequest): Promise<AgentResponse> {
    return this.createSuccessResponse({
      sections: {
        hero: {
          headline: 'Products that users love, investors fund',
          subheadline: 'A product design studio that puts skin in the game. Fee + equity partnerships for founders who want a partner, not a vendor.',
          cta_primary: 'Start a Project',
          cta_secondary: 'See Our Work',
          trust_badges: ['Meta', 'FuboTV', 'Athletes First']
        },
        problem: {
          headline: 'Most design agencies deliver mockups. We deliver products.',
          points: [
            "You've worked with agencies that hand off and disappear",
            "Designs look great but don't ship",
            'No one has skin in the game'
          ]
        },
        solution: {
          headline: 'We stay until launch—with equity to prove we care',
          points: [
            'Strategy-first: we figure out what to build before designing',
            'Full-stack: design, development, and launch support',
            'Aligned incentives: we succeed when you succeed'
          ]
        },
        proof: {
          headline: "Products we've helped ship",
          case_studies: [
            { name: 'Project X', outcome: 'Raised $10M after redesign' },
            { name: 'Project Y', outcome: '3x conversion improvement' },
            { name: 'Project Z', outcome: 'Launched to 10K users in 3 months' }
          ],
          testimonial: {
            quote: 'Rationale was the partner we needed, not just another vendor.',
            author: 'Founder, Client Company'
          }
        },
        process: {
          headline: 'How we work',
          steps: [
            { step: '1', title: 'Discovery', description: 'We learn your business, users, and goals' },
            { step: '2', title: 'Strategy', description: 'We define the approach and success metrics' },
            { step: '3', title: 'Design & Build', description: 'We create and iterate with continuous feedback' },
            { step: '4', title: 'Launch', description: 'We help you ship and measure results' }
          ]
        },
        cta_final: {
          headline: 'Ready to build something worth building?',
          subheadline: "Let's talk about a partnership.",
          cta: 'Start a Project'
        }
      },
      copywriting_notes: [
        'Hero uses outcome-focused headline (PAS framework)',
        'Problem section agitates common frustrations',
        'Solution section addresses objections implicitly',
        'Proof section uses specific outcomes over vague claims',
        'Final CTA echoes brand tagline for memorability'
      ]
    });
  }

  private async handleContentCalendar(request: MarketingRequest): Promise<AgentResponse> {
    const calendar = {
      week_template: [
        { day: 'Monday', platform: 'LinkedIn', type: 'Educational', example: 'Design tip or framework' },
        { day: 'Tuesday', platform: 'Twitter', type: 'Hot take', example: 'Contrarian industry view' },
        { day: 'Wednesday', platform: 'LinkedIn', type: 'Case study', example: 'Client outcome story' },
        { day: 'Thursday', platform: 'Newsletter', type: 'Deep dive', example: 'Weekly insight or lesson' },
        { day: 'Friday', platform: 'Twitter', type: 'Thread', example: 'Lessons learned or process breakdown' }
      ],
      content_pillars: {
        'Product updates': '20% - Zero, Recipe Buddy, new features',
        'Client wins': '25% - Case studies, outcomes, testimonials',
        'Industry insights': '25% - Trends, predictions, hot takes',
        'Behind the scenes': '15% - Process, team, culture',
        'Educational': '15% - Tips, frameworks, how-tos'
      },
      quarterly_themes: {
        'Q1': 'New year, new products - launch focused',
        'Q2': 'Growth and optimization stories',
        'Q3': 'Behind the scenes, team culture',
        'Q4': 'Year in review, lessons learned, predictions'
      }
    };

    return this.createSuccessResponse({
      calendar,
      posting_cadence: {
        'LinkedIn': '3-5x/week',
        'Twitter': '5-10x/week',
        'Newsletter': '1x/week',
        'Instagram': '2-3x/week (if active)'
      },
      batch_production: 'Create 2 weeks of content in one 2-hour session'
    });
  }

  private async handleBrandVoiceGuide(request: MarketingRequest): Promise<AgentResponse> {
    return this.createSuccessResponse({
      voice_attributes: {
        primary: ['Confident', 'Direct', 'Expert'],
        secondary: ['Warm', 'Approachable', 'Candid'],
        avoid: ['Salesy', 'Jargon-heavy', 'Generic', 'Apologetic']
      },
      tone_examples: {
        confident: {
          not_this: 'We might be able to help with your design needs',
          this: "We build products that ship. Let's talk."
        },
        direct: {
          not_this: 'Our comprehensive suite of design services...',
          this: 'Strategy. Design. Build. Launch.'
        },
        warm: {
          not_this: 'Please complete the form below to initiate contact',
          this: "Drop us a note—we'd love to hear what you're building"
        }
      },
      vocabulary: {
        use: ['Ship', 'Build', 'Partner', 'Launch', 'Conviction', 'Skin in the game'],
        avoid: ['Synergy', 'Solutions', 'Leverage', 'Disrupting', 'World-class']
      },
      taglines: [
        'Conviction before code',
        'Products that ship',
        'Design with skin in the game'
      ]
    });
  }

  private async handleMarketingAudit(request: MarketingRequest): Promise<AgentResponse> {
    const audit: MarketingAuditOutput = {
      brand_voice_score: 7,
      messaging_consistency: 6,
      channel_effectiveness: {
        'Website': 6,
        'LinkedIn': 7,
        'Twitter': 5,
        'Email': 4
      },
      recommendations: [
        'Unify messaging: "conviction before code" vs "strategy-led design" - pick one',
        'Add more specific outcomes to case studies (numbers, metrics)',
        'Increase email marketing - underutilized channel',
        'Create content calendar for consistent posting',
        'Develop 3-5 core social proof assets (testimonials, case studies)'
      ],
      competitor_comparison: [
        'vs. Traditional agencies: More authentic voice, less polished production',
        'vs. Venture studios: Less institutional, more founder-friendly',
        'vs. Freelancers: More comprehensive, better positioned'
      ]
    };

    return this.createSuccessResponse({
      audit,
      priority_actions: [
        '1. Create unified messaging document',
        '2. Develop 3 detailed case studies with metrics',
        '3. Set up email nurture sequence',
        '4. Commit to consistent social posting (3x/week minimum)'
      ],
      quick_wins: [
        'Add testimonial quotes to homepage',
        'Update LinkedIn banner with clear value prop',
        'Create email signature with CTA'
      ]
    });
  }

  private async handleGenerateHooks(input: { topic: string; platform: string }): Promise<AgentResponse> {
    const hooks = [
      `The real reason ${input.topic} fails (and how to fix it)`,
      `I've been doing ${input.topic} for 15 years. Here's what nobody tells you:`,
      `Hot take: Most advice about ${input.topic} is wrong.`,
      `Stop doing ${input.topic} this way.`,
      `${input.topic} in 2024 looks completely different.`,
      `The ${input.topic} framework that changed everything:`,
      `What $50M in client projects taught me about ${input.topic}:`,
      `If your ${input.topic} isn't working, this is why:`,
      `Unpopular opinion about ${input.topic}:`,
      `The #1 ${input.topic} mistake I see:`,
      `${input.topic}: Everyone is overcomplicating this.`,
      `Here's how top companies approach ${input.topic}:`
    ];

    return this.createSuccessResponse({
      hooks,
      platform_tips: MarketingAgent.MARKETING_KNOWLEDGE.platform_best_practices[input.platform as keyof typeof MarketingAgent.MARKETING_KNOWLEDGE.platform_best_practices],
      best_practices: [
        'Test 3-5 hooks, keep the winners',
        'First line should create curiosity gap',
        'Use pattern interrupt (counterintuitive, specific, emotional)'
      ]
    });
  }

  private async handleGetKnowledge(): Promise<AgentResponse> {
    return this.createSuccessResponse({
      knowledge_base: MarketingAgent.MARKETING_KNOWLEDGE,
      note: 'This agent applies these frameworks automatically when creating content'
    });
  }
}

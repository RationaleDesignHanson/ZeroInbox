import { BaseAgent } from '../core/base-agent';
import { 
  AgentMessage, 
  AgentResponse, 
  AgentTask,
  AgentCapability
} from '../types/agent.types';
import { generateId } from '../utils/helpers';

// ============================================================================
// Brand Director Types
// ============================================================================

interface BrandReviewRequest {
  type: 'full' | 'diagnostic' | 'worlds' | 'applications' | 'experiments';
  inputs?: {
    companyContext?: string;
    siteHomepage?: string;
    siteOtherPages?: string;
    brandAssets?: string;
    decks?: string;
    visualReferences?: string;
  };
}

interface BrandScore {
  category: string;
  score: number;  // 1-10
  diagnosis: string;
  example: string;
}

interface VisualSystem {
  palette: string[];
  typography: string[];
  layout: string;
  iconography: string;
  motion: string;
}

interface BrandWorld {
  id: string;
  name: string;
  tagline: string;
  summary: string;
  coreNarrative: string;
  visual_system: VisualSystem;
  os8_tdr_integration: string;
  shader_integration: string;
  strengths: string[];
  risks: string[];
}

interface HomepageApplication {
  hero_notes: string;
  sections: Array<{ name: string; description: string; visual_notes: string }>;
  guidelines: string[];
}

interface DeckApplication {
  slide_types: Array<{ type: string; description: string; visual_notes: string }>;
  notes: string;
}

interface ProductApplication {
  carry_over: string[];
  dial_down: string[];
  ui_notes: string;
}

interface BrandExperiment {
  title: string;
  description: string;
  output_format: string;
}

interface BrandReviewOutput {
  scores: BrandScore[];
  brand_worlds: BrandWorld[];
  recommended_world_id: string;
  applications: {
    homepage: HomepageApplication;
    deck: DeckApplication;
    product: ProductApplication;
  };
  experiments: BrandExperiment[];
  done_when_checklist: string[];
}

// ============================================================================
// Brand Director Agent
// ============================================================================

export class BrandDirectorAgent extends BaseAgent {
  
  // Brand knowledge base
  private static readonly BRAND_KNOWLEDGE = {
    aestheticTerritories: {
      'retro-futurist': 'Blend of vintage computing aesthetics with forward-looking design',
      'designers-republic': 'Bold poster grids, experimental typography, Warp Records era',
      'os8-chrome': 'Classic Mac OS window chrome, title bars, system dialogs',
      'ascii-terminal': 'Monospace type, command prompts, dot-matrix patterns',
      'institutional': 'Serious, trustworthy, corporate but not boring',
      'neo-brutalist': 'Raw, honest, visible structure, anti-polish'
    },
    brandPrinciples: [
      'Distinctiveness over decoration',
      'System-ness over one-off designs',
      'Extensibility across all surfaces',
      'Credibility for serious buyers',
      'Playfulness with commercial backbone',
      'Coherence between visual and verbal'
    ],
    visualSystemComponents: {
      palette: ['Primary', 'Accent', 'Background', 'Foreground', 'Muted', 'Border', 'Success', 'Warning', 'Error'],
      typography: ['Display/Hero', 'Heading', 'Subheading', 'Body', 'Caption', 'Mono/Code', 'UI Labels'],
      layout: ['Grid system', 'Spacing scale', 'Container widths', 'Breakpoints'],
      motion: ['Easing curves', 'Duration scale', 'Entrance/exit patterns', 'Micro-interactions'],
      iconography: ['Style (outline/filled/duo)', 'Stroke weight', 'Corner radius', 'Size scale']
    },
    brandWorldArchetypes: [
      { name: 'Terminal Republic', vibe: 'Bold TDR poster grids + command-line aesthetics' },
      { name: 'Fictional OS', vibe: 'OS 8 windows as design containers, boot sequences' },
      { name: 'Noir Institutional', vibe: 'Dark, serious, minimal retro touches' },
      { name: 'Grid Protocol', vibe: 'ASCII/dot shaders as structural element' },
      { name: 'Studio Operating System', vibe: 'Entire brand as an OS metaphor' }
    ],
    applicationSurfaces: [
      'Homepage', 'About page', 'Work/Portfolio', 'Product pages',
      'Pitch deck', 'Case study deck', 'Social media', 'Email templates',
      'Product UI (Zero Inbox)', 'Documentation', 'Internal tools'
    ],
    rationaleContext: {
      dualEngine: {
        products: 'Studio-built IP (Zero Inbox, Recipe Buddy) proving shipping capability',
        clients: 'Fee + equity modernization: 2-week audit → 4-week sprint → 8-12 week pilot'
      },
      positioning: [
        'De-risk by building, not debating',
        'Prototypes ship futures',
        'Working software is the oxygen for ideas',
        'Conviction before code'
      ],
      targetAudiences: ['Founders', 'Executives', 'VCs', 'Product leaders', 'Design leaders']
    }
  };

  constructor() {
    super(
      'brand-director-001',
      'Brand Director',
      'systems-architect',
      'Senior creative director and brand systems designer. Evaluates and evolves brand worlds across web, decks, and motion. Focuses on distinctiveness, system-ness, extensibility, and credibility. Expert in retro-futurist aesthetics (Designers Republic × OS 8 × ASCII terminal).',
      BrandDirectorAgent.getCapabilities(),
      '1.0.0'
    );
  }

  private static getCapabilities(): AgentCapability[] {
    return [
      {
        name: 'brand-diagnostic',
        description: 'Score and diagnose current brand across distinctiveness, alignment, system-ness, extensibility'
      },
      {
        name: 'brand-worlds',
        description: 'Define 3-5 distinct brand world territories with visual systems'
      },
      {
        name: 'brand-application',
        description: 'Apply recommended brand world to homepage, deck, and product UI'
      },
      {
        name: 'brand-experiments',
        description: 'Suggest concrete experiments to explore aesthetic directions'
      },
      {
        name: 'visual-system-audit',
        description: 'Audit current visual system for coherence and gaps'
      },
      {
        name: 'tone-voice-review',
        description: 'Review copy and verbal identity for consistency'
      },
      {
        name: 'competitive-positioning',
        description: 'Analyze brand distinctiveness vs competitors'
      },
      {
        name: 'surface-extension',
        description: 'Plan how brand extends to new surfaces (social, docs, product)'
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
      case 'full-review':
        return this.handleFullReview(message.payload as BrandReviewRequest);
      
      case 'diagnostic':
        return this.handleDiagnostic(message.payload as BrandReviewRequest);
      
      case 'generate-worlds':
        return this.handleGenerateWorlds(message.payload as BrandReviewRequest);
      
      case 'apply-world':
        return this.handleApplyWorld(message.payload as { worldId: string; surfaces: string[] });
      
      case 'generate-experiments':
        return this.handleGenerateExperiments(message.payload as { focus: string });
      
      case 'audit-visual-system':
        return this.handleVisualSystemAudit(message.payload as { assets: string });
      
      case 'review-tone-voice':
        return this.handleToneVoiceReview(message.payload as { copy: string });
      
      case 'get-knowledge':
        return this.handleGetKnowledge();
      
      default:
        return this.createErrorResponse(
          'UNKNOWN_ACTION',
          `Unknown action: ${message.action}`,
          { availableActions: [
            'review', 'full-review', 'diagnostic', 'generate-worlds',
            'apply-world', 'generate-experiments', 'audit-visual-system',
            'review-tone-voice', 'get-knowledge'
          ]}
        );
    }
  }

  protected async handleEvent(message: AgentMessage): Promise<AgentResponse> {
    return this.createSuccessResponse({ acknowledged: true });
  }

  protected async performTask(task: AgentTask): Promise<unknown> {
    if (task.type === 'brand-review') {
      const result = await this.handleFullReview(task.input as BrandReviewRequest);
      return result.data;
    }
    throw new Error(`Unknown task type: ${task.type}`);
  }

  // ============================================================================
  // Core Review Methods
  // ============================================================================

  private async handleFullReview(request: BrandReviewRequest): Promise<AgentResponse<BrandReviewOutput>> {
    const scores = this.runDiagnostic();
    const brandWorlds = this.generateBrandWorlds();
    const recommendedWorldId = 'B'; // Terminal Republic typically best balance
    const applications = this.generateApplications(brandWorlds.find(w => w.id === recommendedWorldId)!);
    const experiments = this.generateExperiments();
    const checklist = this.generateDoneWhenChecklist();

    const output: BrandReviewOutput = {
      scores,
      brand_worlds: brandWorlds,
      recommended_world_id: recommendedWorldId,
      applications,
      experiments,
      done_when_checklist: checklist
    };

    return this.createSuccessResponse(
      output,
      'Brand review complete. Recommended world: Terminal Republic — bold but credible.',
      ['Define yellow usage rules', 'Create OS window component library', 'Test hero variants'],
      ['Run A/B test with founders', 'Build Figma brand kit', 'Document motion language']
    );
  }

  private async handleDiagnostic(request: BrandReviewRequest): Promise<AgentResponse> {
    const scores = this.runDiagnostic();
    
    return this.createSuccessResponse({
      scores,
      summary: {
        overallScore: Math.round(scores.reduce((acc, s) => acc + s.score, 0) / scores.length * 10) / 10,
        topStrength: scores.reduce((a, b) => a.score > b.score ? a : b).category,
        topWeakness: scores.reduce((a, b) => a.score < b.score ? a : b).category
      },
      priorityActions: scores
        .filter(s => s.score < 7)
        .map(s => `Improve ${s.category}: ${s.diagnosis.split('.')[0]}`)
    });
  }

  private async handleGenerateWorlds(request: BrandReviewRequest): Promise<AgentResponse> {
    const brandWorlds = this.generateBrandWorlds();
    
    return this.createSuccessResponse({
      brand_worlds: brandWorlds,
      comparison: {
        mostBold: 'A (Fictional OS 8.1)',
        mostRestrained: 'D (Noir Institutional)',
        bestBalance: 'B (Terminal Republic)',
        mostExtensible: 'C (Grid Protocol)'
      },
      recommendation: {
        id: 'B',
        reasoning: 'Terminal Republic offers the best balance of distinctiveness and credibility. Bold enough to stand out, structured enough to scale.'
      }
    });
  }

  private async handleApplyWorld(input: { worldId: string; surfaces: string[] }): Promise<AgentResponse> {
    const worlds = this.generateBrandWorlds();
    const world = worlds.find(w => w.id === input.worldId);
    
    if (!world) {
      return this.createErrorResponse('WORLD_NOT_FOUND', `No brand world found with id: ${input.worldId}`);
    }

    const applications = this.generateApplications(world);
    
    return this.createSuccessResponse({
      world,
      applications,
      implementation_notes: [
        `Apply ${world.name} visual system across: ${input.surfaces.join(', ')}`,
        'Start with homepage hero as proof of concept',
        'Build component library before scaling to other surfaces',
        'Document all token decisions in brand-tokens.md'
      ]
    });
  }

  private async handleGenerateExperiments(input: { focus: string }): Promise<AgentResponse> {
    const experiments = this.generateExperiments();
    
    return this.createSuccessResponse({
      experiments,
      priorityOrder: [
        'Hero variants (high impact, quick to test)',
        'OS window component (foundational)',
        'Shader presets (unique differentiator)',
        'Founder preference test (validates direction)'
      ],
      timeline: {
        week1: ['Hero variants', 'OS window component'],
        week2: ['Shader presets', 'Type scale finalization'],
        week3: ['Founder testing', 'Deck application'],
        week4: ['Product UI exploration', 'Documentation']
      }
    });
  }

  private async handleVisualSystemAudit(input: { assets: string }): Promise<AgentResponse> {
    return this.createSuccessResponse({
      audit: {
        palette: {
          defined: ['Yellow accent', 'Dark backgrounds', 'Light text'],
          missing: ['Secondary accent', 'Success/error states', 'Muted variants'],
          issues: ['Yellow usage inconsistent', 'No clear hierarchy rules']
        },
        typography: {
          defined: ['Display font', 'Body font'],
          missing: ['Mono/code font', 'Caption styles', 'UI label styles'],
          issues: ['Scale not systematic', 'Line heights vary']
        },
        layout: {
          defined: ['Basic grid'],
          missing: ['Spacing scale', 'Container rules', 'Breakpoint system'],
          issues: ['Inconsistent padding', 'No component spacing tokens']
        },
        motion: {
          defined: ['Basic transitions'],
          missing: ['Easing curves', 'Duration scale', 'Entrance/exit patterns'],
          issues: ['No motion language defined']
        }
      },
      recommendations: [
        'Define 8-step spacing scale based on 4px unit',
        'Create semantic color tokens (not just raw values)',
        'Add mono font for code/terminal elements',
        'Document motion principles and easing curves'
      ]
    });
  }

  private async handleToneVoiceReview(input: { copy: string }): Promise<AgentResponse> {
    return this.createSuccessResponse({
      toneAnalysis: {
        current: {
          confidence: 7,
          clarity: 6,
          distinctiveness: 5,
          consistency: 6
        },
        targetPersonality: [
          'Confident but not arrogant',
          'Technical but accessible',
          'Playful but commercially serious',
          'Direct without being cold'
        ]
      },
      voiceGuidelines: {
        do: [
          'Use active voice: "We ship" not "Shipping is done"',
          'Be specific: "$50M raised" not "significant funding"',
          'Use terminal metaphors: "run sprint()", "deploy conviction"',
          'Lead with outcomes, not process'
        ],
        avoid: [
          'Agency jargon: "synergy", "leverage", "solutions"',
          'Hedging: "might", "could potentially", "we think"',
          'Passive constructions',
          'Generic tech phrases: "cutting-edge", "innovative"'
        ]
      },
      signaturePhrases: [
        'Conviction before code',
        'De-risk by building, not debating',
        'Prototypes ship futures',
        'run rationale()',
        'Fee + equity = aligned incentives'
      ]
    });
  }

  private async handleGetKnowledge(): Promise<AgentResponse> {
    return this.createSuccessResponse({
      knowledge_base: BrandDirectorAgent.BRAND_KNOWLEDGE,
      note: 'This agent applies these principles automatically during reviews'
    });
  }

  // ============================================================================
  // Diagnostic Methods
  // ============================================================================

  private runDiagnostic(): BrandScore[] {
    return [
      {
        category: 'Distinctiveness',
        score: 6,
        diagnosis: 'Current brand has unique elements (® logo, yellow accent) but overall presentation could be mistaken for generic design agency. The retro-futurist direction is in moodboards but not fully realized on site.',
        example: 'Hero section uses standard layout patterns; OS window metaphors not yet implemented'
      },
      {
        category: 'Strategic Alignment',
        score: 5,
        diagnosis: 'Dual engine model (products + clients) not visually communicated. Fee + equity differentiation is verbal only. The "de-risk by building" thesis needs visual expression.',
        example: 'Products section exists but doesnt feel like proof of shipping capability; equity model is text-only'
      },
      {
        category: 'System-ness',
        score: 5,
        diagnosis: 'Some consistent elements (colors, fonts) but no documented system. Spacing and component patterns vary across pages. Motion language undefined.',
        example: 'Button styles vary; card treatments inconsistent between pages'
      },
      {
        category: 'Extensibility',
        score: 6,
        diagnosis: 'Current aesthetic could stretch to more pages, but would struggle with product UI and decks. No clear rules for how elements adapt across contexts.',
        example: 'How does the brand apply to Zero Inbox UI? To a pitch deck? Rules not defined'
      },
      {
        category: 'Retro-Futurist Coherence',
        score: 4,
        diagnosis: 'The TDR × OS 8 × ASCII direction is aspirational but not yet implemented. Some glass effects and grid hints, but the bold poster aesthetic and terminal metaphors are missing.',
        example: 'No OS window chrome, no ASCII shaders, no command-prompt CTAs on current site'
      },
      {
        category: 'Credibility for Serious Buyers',
        score: 7,
        diagnosis: 'Professional enough for founders/VCs but not yet distinctive. The playfulness could enhance credibility if grounded in commercial narrative, but currently feels underbaked.',
        example: 'Client logos help; case study depth could be stronger; overall impression is "competent agency"'
      },
      {
        category: 'Tone & Voice Cohesion',
        score: 6,
        diagnosis: 'Copy has moments of strong voice ("conviction before code") but inconsistent across pages. Visual tone and verbal tone not fully aligned.',
        example: 'Hero copy is bold; about page is more generic; no terminal-style language throughout'
      }
    ];
  }

  // ============================================================================
  // Brand Worlds Generation
  // ============================================================================

  private generateBrandWorlds(): BrandWorld[] {
    return [
      {
        id: 'A',
        name: 'Fictional OS 8.1',
        tagline: 'Your product conviction runs on Rationale OS.',
        summary: 'The entire brand is an operating system metaphor. Site sections are windows, navigation is a dock, products are apps, and interactions feel like system operations.',
        coreNarrative: 'Rationale isnt just a studio — its an operating system for product conviction. Every engagement is a process you run. Audits are diagnostics. Sprints are builds. Products are native apps in the Rationale ecosystem. The OS metaphor makes the dual engine tangible: client work and products are both "apps" running on the same underlying system of conviction and craft.',
        visual_system: {
          palette: [
            'Background: #0a0a0a (system black)',
            'Window chrome: #1a1a1a with #333 borders',
            'Accent: #facc15 (system yellow)',
            'Text: #fafafa (high contrast)',
            'Muted: #737373 (inactive elements)'
          ],
          typography: [
            'Display: Bold sans-serif, tight tracking, for window titles',
            'Body: Clean sans-serif, generous line height',
            'Mono: For commands, code, terminal prompts',
            'UI: Small caps or all-caps for system labels'
          ],
          layout: 'OS windows as containers — title bar, content area, optional footer. Grid of windows for multi-item displays. Dock-style navigation.',
          iconography: 'Pixel-perfect 16x16 and 32x32 icons. System-style glyphs. Folder, document, app metaphors.',
          motion: 'Window open/close animations. Minimize to dock. Boot sequence on page load. Typing cursor in terminal elements.'
        },
        os8_tdr_integration: 'Heavy OS 8 — windows are the primary container. TDR influence in bold type treatments within windows and poster-style section backgrounds behind window clusters.',
        shader_integration: 'Subtle — ASCII/dot patterns as window backgrounds or section dividers. Not the hero, but atmospheric texture.',
        strengths: [
          'Highly distinctive — no one else is doing this',
          'Natural metaphor for products + services',
          'Infinite extensibility (new "apps" for new offerings)',
          'Memorable and ownable'
        ],
        risks: [
          'Could feel gimmicky if not executed perfectly',
          'May alienate non-tech audiences',
          'Requires significant component development',
          'Risk of kitsch if chrome is too literal'
        ]
      },
      {
        id: 'B',
        name: 'Terminal Republic',
        tagline: 'run rationale() — conviction deployed.',
        summary: 'Bold Designers Republic poster aesthetics meet command-line interface. High-contrast grids, terminal-style CTAs, but grounded in serious commercial narrative.',
        coreNarrative: 'Rationale operates at the command line of product development. While others debate in meetings, we run code. The aesthetic is bold, graphic, unapologetic — but the output is serious business value. Terminal prompts arent playful decoration; theyre a statement that we execute, not just advise. The TDR influence brings poster-worthy boldness; the terminal grounds it in technical credibility.',
        visual_system: {
          palette: [
            'Background: #000000 or #0f0f0f (true black)',
            'Accent: #facc15 (terminal yellow/amber)',
            'Secondary: #22c55e (success green)',
            'Text: #ffffff (high contrast)',
            'Grid lines: #333333 (subtle structure)'
          ],
          typography: [
            'Display: Heavy condensed sans, TDR-style impact',
            'Headings: Bold sans with tight tracking',
            'Body: Clean sans, high readability',
            'Mono: Prominent for CTAs, labels, code'
          ],
          layout: 'Poster-style backplanes with bold type. Asymmetric grids. Full-bleed color blocks. Terminal-style input areas for CTAs.',
          iconography: 'Minimal. When used, simple geometric or ASCII-inspired. Arrows, brackets, slashes.',
          motion: 'Typing animations for terminal elements. Scanline flicker on hover. Grid reveals. Sharp, not floaty.'
        },
        os8_tdr_integration: 'TDR-dominant with OS touches. Poster grids and bold type from TDR. OS window chrome used sparingly for specific containers (product cards, case studies).',
        shader_integration: 'Prominent — ASCII/dot-grid shaders as hero backgrounds and section transitions. Part of the visual identity, not just decoration.',
        strengths: [
          'Highly distinctive and ownable',
          'Balances bold creativity with technical credibility',
          'Scales well across web, deck, social',
          'The "run X()" pattern is memorable and extensible'
        ],
        risks: [
          'Requires confident execution — easy to look try-hard',
          'Heavy aesthetic may need toning for some contexts',
          'Mono type overuse could hurt readability'
        ]
      },
      {
        id: 'C',
        name: 'Grid Protocol',
        tagline: 'Structure ships. Rationale is the grid.',
        summary: 'The dot-grid/ASCII shader becomes the foundational element. Everything sits on a visible structural grid. Minimal chrome, maximum system.',
        coreNarrative: 'Great products need structure before style. Rationale is that structure — a grid protocol that underlies everything we build. The visible grid isnt decoration; its a statement about how we work: systematic, rigorous, repeatable. Client work and products follow the same underlying protocol. The grid is the brand.',
        visual_system: {
          palette: [
            'Background: #fafafa or #0a0a0a (works in light or dark)',
            'Grid: #e5e5e5 (light) or #262626 (dark)',
            'Accent: #facc15 (yellow nodes/intersections)',
            'Text: #171717 (light) or #fafafa (dark)',
            'Highlight: #3b82f6 (blue for interactive)'
          ],
          typography: [
            'Display: Geometric sans, medium weight',
            'Headings: Clean sans, normal tracking',
            'Body: Highly readable sans',
            'Mono: For code and technical elements only'
          ],
          layout: 'Visible dot-grid underlays everything. Content aligned to grid intersections. Generous whitespace. Cards float on the grid.',
          iconography: 'Constructed from grid elements. Dots, lines, simple geometric shapes.',
          motion: 'Grid reveals (dots appear sequentially). Elements snap to grid points. Subtle pulse on interactive nodes.'
        },
        os8_tdr_integration: 'Minimal — grid is the system, not windows or posters. OS/TDR elements only as accent containers when needed.',
        shader_integration: 'Foundational — the shader/grid IS the brand. Always visible, always structural. Not decorative, systematic.',
        strengths: [
          'Extremely extensible and systematic',
          'Works in both light and dark modes easily',
          'Unique but not alienating',
          'Naturally communicates rigor and structure'
        ],
        risks: [
          'Could feel cold or impersonal',
          'Less visually exciting than other directions',
          'Grid everywhere might become monotonous',
          'Requires discipline to not break the grid'
        ]
      },
      {
        id: 'D',
        name: 'Noir Institutional',
        tagline: 'Serious software. Built by Rationale.',
        summary: 'Dark, restrained, premium. Retro-futurist touches are subtle — a font choice here, a scanline there. Trust first, personality second.',
        coreNarrative: 'Rationale is where serious companies come to build serious software. The aesthetic is confident understatement — we dont need to shout because the work speaks. Dark backgrounds convey focus. Restrained typography conveys precision. The occasional retro-tech touch (a scanline, a monospace label) hints at deeper technical craft without demanding attention.',
        visual_system: {
          palette: [
            'Background: #09090b (near-black)',
            'Surface: #18181b (cards, elevated)',
            'Border: #27272a (subtle definition)',
            'Text: #fafafa (primary), #a1a1aa (secondary)',
            'Accent: #facc15 (used very sparingly)'
          ],
          typography: [
            'Display: Medium-weight sans, generous size',
            'Headings: Clean, professional sans',
            'Body: Optimized for long-form reading',
            'Mono: Subtle, for labels and metadata only'
          ],
          layout: 'Clean, generous whitespace. Cards with subtle borders. No visible grids. Premium magazine feel.',
          iconography: 'Minimal, outline style. Lucide or similar. Never decorative.',
          motion: 'Subtle fades and slides. Nothing flashy. Scanline effect on images only (subtle).'
        },
        os8_tdr_integration: 'Minimal — occasional OS-style element (a dialog box, a system font choice) as accent. No poster grids.',
        shader_integration: 'Very subtle — scanline texture on images, slight noise on backgrounds. Never obvious.',
        strengths: [
          'Maximum credibility with serious buyers',
          'Easy to execute well',
          'Timeless, not trendy',
          'Works immediately for decks and enterprise contexts'
        ],
        risks: [
          'Could feel generic or forgettable',
          'Doesnt fully realize the retro-futurist vision',
          'May not stand out in a feed',
          'Sacrifices distinctiveness for safety'
        ]
      },
      {
        id: 'E',
        name: 'Studio Operating System',
        tagline: 'Products run on Rationale.',
        summary: 'Hybrid of A and B. The studio is an OS, but the visual language is TDR-bold rather than literal chrome. Best of both metaphors.',
        coreNarrative: 'Rationale is a studio that operates like an operating system. Products and client work are processes that run on our core: conviction, craft, and code. The OS metaphor is conceptual, not literal — we use bold graphic language (TDR) to express system concepts (windows, processes, terminals) without becoming a nostalgic Mac clone. The result is a brand that feels systematic AND creative.',
        visual_system: {
          palette: [
            'Background: #0a0a0a with noise texture',
            'Containers: Semi-transparent with blur',
            'Accent: #facc15 (system yellow)',
            'Secondary: #8b5cf6 (process purple)',
            'Text: #fafafa and #a1a1aa'
          ],
          typography: [
            'Display: Heavy condensed for impact',
            'System: Medium weight for UI/labels',
            'Body: Clean and readable',
            'Mono: For all interactive/command elements'
          ],
          layout: 'Modular "process" containers. Flexible grid. Some containers have chrome, others are clean. Mix of poster and UI.',
          iconography: 'System-inspired but stylized. Not pixel art, but nods to it.',
          motion: 'Process animations (loading, complete). Window transforms. Terminal typing. Blur transitions.'
        },
        os8_tdr_integration: 'Balanced — conceptually OS, visually TDR. Windows as bold graphic containers, not literal chrome recreation.',
        shader_integration: 'Strategic — shaders represent "system processes running." Activate on scroll, on hover, on state change.',
        strengths: [
          'Best of both worlds — distinctive AND systematic',
          'Flexible for different contexts',
          'Strong conceptual foundation',
          'Room for evolution'
        ],
        risks: [
          'Complex to execute consistently',
          'Could become inconsistent without clear rules',
          'Requires strong documentation',
          'May confuse if metaphor isnt clear'
        ]
      }
    ];
  }

  // ============================================================================
  // Application Generation
  // ============================================================================

  private generateApplications(world: BrandWorld): BrandReviewOutput['applications'] {
    return {
      homepage: {
        hero_notes: `Hero: "run rationale()" as main headline in heavy condensed type. ASCII/dot shader grid as animated background. OS-style dialog box for CTA: [START SPRINT] [VIEW PRODUCTS]. Yellow accent on interactive elements. Full viewport height, dark background.`,
        sections: [
          {
            name: 'Hero',
            description: 'run rationale() with OS dialog CTA and ASCII grid halo',
            visual_notes: 'Full bleed dark bg, shader animation, terminal-style prompt'
          },
          {
            name: 'Proof',
            description: 'proof.mp4 window showing shipped work (Meta, FuboTV)',
            visual_notes: 'OS window container with title bar, video/image carousel inside'
          },
          {
            name: 'Products',
            description: 'products.stack showing Zero Inbox and future products',
            visual_notes: 'Grid of product "app" windows, each with icon + name + status'
          },
          {
            name: 'Studio Methods',
            description: 'Audit → Sprint → Pilot visualized as system processes',
            visual_notes: 'Progress bars, loading states, terminal output aesthetic'
          },
          {
            name: 'Ventures & Holdings',
            description: 'Fee + equity thesis with portfolio logos',
            visual_notes: 'Diagram showing model, logo grid in window container'
          },
          {
            name: 'CTA',
            description: 'Terminal-style buttons: run sprint() | open zero.app',
            visual_notes: 'Command prompt aesthetic, blinking cursor, high contrast'
          }
        ],
        guidelines: [
          'Yellow used for: CTAs, active states, important labels only',
          'Windows used for: discrete content blocks (products, case studies, process steps)',
          'Shader used for: hero background, section transitions, hover states',
          'Minimum type: 16px body, 48px+ display, always high contrast'
        ]
      },
      deck: {
        slide_types: [
          { type: 'Cover', description: 'run rationale() with subtitle and ASCII texture', visual_notes: 'Dark bg, centered type, shader corners' },
          { type: 'Section Divider', description: 'products.stack or moats.index style', visual_notes: 'OS window title as section name, minimal content' },
          { type: 'Proof/Case Study', description: 'Full-bleed image with OS window overlay for text', visual_notes: 'Image as background, white window with black text for stats' },
          { type: 'Process', description: 'Audit → Sprint → Pilot as terminal flow', visual_notes: 'Left-to-right process with loading bars, mono type' },
          { type: 'Fee + Equity', description: 'Diagram in window container', visual_notes: 'Clean diagram, yellow for equity portion, window chrome' },
          { type: 'Team/About', description: 'Clean grid, no chrome', visual_notes: 'Photos in grid, text alongside, minimal treatment' },
          { type: 'CTA/Close', description: 'Terminal prompt: ready to run sprint()?', visual_notes: 'Command line style, contact info as system output' }
        ],
        notes: 'Decks should feel like the same OS as the website, but more restrained. Use shader textures as subtle backgrounds (10-20% opacity). Chrome on content slides only, not every slide. Maintain high contrast for projector readability.'
      },
      product: {
        carry_over: [
          'Yellow accent color (use sparingly for key actions)',
          'Mono font for status, labels, commands',
          'Dark theme as default',
          'OS window metaphor for modals and dialogs',
          'ASCII/grid texture in empty states'
        ],
        dial_down: [
          'Heavy display type (use clean UI fonts)',
          'Poster-style layouts (use functional UI patterns)',
          'Shader prominence (subtle background only)',
          'Chrome on every element (use sparingly)'
        ],
        ui_notes: 'Zero Inbox should feel like a "native app" in the Rationale OS. It inherits the DNA but prioritizes productivity. Empty states can be more playful (terminal messages, ASCII art). Loading states use the grid animation. Success/error feedback uses system colors (green/red) with yellow for warnings. Nav can use OS-style tabs or a dock metaphor.'
      }
    };
  }

  // ============================================================================
  // Experiments Generation
  // ============================================================================

  private generateExperiments(): BrandExperiment[] {
    return [
      {
        title: 'Hero Variant A/B/C',
        description: 'Design 3 hero variants: (A) Full poster TDR style, (B) OS window dialog focus, (C) Minimal terminal prompt. Test with 5 founders for preference.',
        output_format: '3 Figma frames + preference survey'
      },
      {
        title: 'OS Window Component Library',
        description: 'Build the core window component with variants: default, glass, minimal chrome. Define title bar styles, close/minimize buttons (functional or decorative), content padding.',
        output_format: 'Figma component set + React component'
      },
      {
        title: 'Shader Mood Presets',
        description: 'Create 4 shader presets mapped to brand moods: Audit (scanning), Sprint (building), Pilot (running), Holdings (stable). Define animation speed, density, color.',
        output_format: '4 shader configs + preview video'
      },
      {
        title: 'Type Scale Definition',
        description: 'Finalize type scale: Display (hero), H1-H4, Body, Small, Mono. Define sizes, weights, line heights, letter spacing. Test readability.',
        output_format: 'Type scale documentation + Figma styles'
      },
      {
        title: 'Yellow Usage Rules',
        description: 'Document exactly where yellow appears: CTAs only? Labels too? Backgrounds ever? Create do/dont examples.',
        output_format: 'Brand guidelines page with examples'
      },
      {
        title: 'TDR Reference Analysis',
        description: 'Collect 15 Designers Republic references. Annotate: what works, what to adopt, what to avoid. Extract patterns.',
        output_format: 'Annotated moodboard in Figma'
      },
      {
        title: 'Deck Template v1',
        description: 'Build 10-slide deck template using recommended brand world. Include all slide types defined in applications.',
        output_format: 'Figma deck template + PDF export'
      },
      {
        title: 'Zero Inbox Brand Integration',
        description: 'Apply studio brand to Zero Inbox: app icon, splash screen, empty states, one core screen. Show relationship between studio and product.',
        output_format: '4-5 Figma frames showing integration'
      },
      {
        title: 'Motion Language Definition',
        description: 'Define: easing curves, duration scale, entrance/exit patterns, micro-interactions. Create motion primitives.',
        output_format: 'Motion spec document + prototype video'
      },
      {
        title: 'Competitive Distinctiveness Test',
        description: 'Screenshot 10 competitor sites (IDEO, frog, Metalab, etc). Place Rationale hero alongside. Survey: "Which stands out? Which would you remember?"',
        output_format: 'Competitive grid + survey results'
      }
    ];
  }

  // ============================================================================
  // Done-When Checklist
  // ============================================================================

  private generateDoneWhenChecklist(): string[] {
    return [
      'A founder can recognize a Rationale frame (site, deck, product) from a screenshot with no logo visible.',
      'Yellow, grids, windows, and shaders all have documented rules with do/dont examples.',
      'The OS/terminal metaphor is expressed in at least 3 touchpoints (CTAs, section titles, navigation).',
      'We can apply this system to: homepage, case study page, Zero Inbox landing, pitch deck — and all feel coherent.',
      'The visual tone is playful and future-facing, but the commercial narrative is unambiguously serious.',
      'Type scale is defined with 6-8 levels, all with clear use cases.',
      'Color palette includes semantic tokens: background, foreground, accent, success, warning, error, muted.',
      'Component library exists in Figma with: Button, Card, Window, Input, Badge, Navigation.',
      'Motion language is documented: easing, duration, entrance/exit patterns.',
      'At least 5 founders/VCs have seen the brand and feedback is "distinctive but credible."',
      'Homepage hero passes the 5-second test: visitor can articulate what Rationale does.',
      'Deck template exists and has been used in at least one real pitch.',
      'Zero Inbox UI shows clear DNA connection to studio brand without sacrificing usability.',
      'Brand assets are exportable: logo variants, color codes, type specs, icon set.',
      'Internal team can extend the system to a new page without asking "how should this look?"'
    ];
  }
}

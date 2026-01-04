import { BaseAgent } from '../core/base-agent';
import { 
  AgentMessage, 
  AgentResponse, 
  AgentTask,
  AgentCapability,
  ArchitectureReview,
  ReviewFinding,
  ReviewSeverity,
  ArchitectureDiagram,
  ProjectContext
} from '../types/agent.types';
import { generateId } from '../utils/helpers';
import { runStackSpecificReview } from './review-patterns';
import { getProjectByName, getAllProjects, ZERO_INBOX_PROJECT, RATIONALE_SITE_PROJECT } from '../config/projects';

// ============================================================================
// Input/Output Types
// ============================================================================

interface ReviewRequest {
  type: 'full' | 'api' | 'database' | 'infrastructure' | 'code-patterns';
  scope?: string[];
  files?: string[];
  codeSnippets?: Array<{ path: string; content: string }>;
  focus?: string[];
  projectName?: string;  // 'zeroinbox' | 'rationale-site' | etc.
}

interface ApiDesignInput {
  endpoints?: Array<{
    method: string;
    path: string;
    description?: string;
    requestBody?: unknown;
    responseBody?: unknown;
  }>;
  openApiSpec?: string;
  graphqlSchema?: string;
}

interface DatabaseSchemaInput {
  type: 'sql' | 'nosql' | 'graph';
  schema?: string;
  models?: Array<{
    name: string;
    fields: Array<{ name: string; type: string; constraints?: string[] }>;
    relations?: Array<{ to: string; type: string }>;
  }>;
  prismaSchema?: string;
  drizzleSchema?: string;
}

interface InfrastructureInput {
  type: 'kubernetes' | 'docker' | 'serverless' | 'traditional';
  config?: string;
  services?: Array<{
    name: string;
    type: string;
    dependencies?: string[];
  }>;
}

interface CodePatternInput {
  patterns: Array<{
    name: string;
    files: string[];
    description?: string;
  }>;
  concerns?: string[];
}

// ============================================================================
// Systems Architect Agent
// ============================================================================

export class SystemsArchitectAgent extends BaseAgent {
  
  constructor() {
    super(
      'systems-architect-001',
      'Systems Architect',
      'systems-architect',
      'Expert agent for backend architecture, API design, database schema, and infrastructure review. Provides comprehensive architectural analysis, identifies issues, and suggests improvements.',
      SystemsArchitectAgent.getCapabilities(),
      '1.0.0'
    );
  }

  private static getCapabilities(): AgentCapability[] {
    return [
      {
        name: 'architecture-review',
        description: 'Comprehensive review of system architecture including patterns, scalability, and maintainability'
      },
      {
        name: 'api-design-review',
        description: 'Review REST, GraphQL, or gRPC API designs for consistency, best practices, and usability'
      },
      {
        name: 'database-schema-review',
        description: 'Analyze database schemas for normalization, indexing, relationships, and performance'
      },
      {
        name: 'infrastructure-review',
        description: 'Review infrastructure configurations for reliability, scalability, and security'
      },
      {
        name: 'code-pattern-analysis',
        description: 'Analyze code for architectural patterns, anti-patterns, and structural improvements'
      },
      {
        name: 'generate-architecture-diagram',
        description: 'Generate Mermaid diagrams for system architecture visualization'
      },
      {
        name: 'tech-stack-recommendation',
        description: 'Provide technology stack recommendations based on requirements'
      },
      {
        name: 'scalability-assessment',
        description: 'Assess system scalability and provide improvement recommendations'
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
        return this.handleReview(message.payload as ReviewRequest);
      
      case 'review-api':
        return this.handleApiReview(message.payload as ApiDesignInput);
      
      case 'review-database':
        return this.handleDatabaseReview(message.payload as DatabaseSchemaInput);
      
      case 'review-infrastructure':
        return this.handleInfrastructureReview(message.payload as InfrastructureInput);
      
      case 'analyze-patterns':
        return this.handlePatternAnalysis(message.payload as CodePatternInput);
      
      case 'generate-diagram':
        return this.handleDiagramGeneration(message.payload as { type: string; context: unknown });
      
      case 'recommend-stack':
        return this.handleStackRecommendation(message.payload as { requirements: string[] });
      
      case 'assess-scalability':
        return this.handleScalabilityAssessment(message.payload as { context: ProjectContext });
      
      case 'list-projects':
        return this.handleListProjects();
      
      default:
        return this.createErrorResponse(
          'UNKNOWN_ACTION',
          `Unknown action: ${message.action}`,
          { availableActions: [
            'review', 'review-api', 'review-database', 'review-infrastructure',
            'analyze-patterns', 'generate-diagram', 'recommend-stack', 
            'assess-scalability', 'list-projects'
          ]}
        );
    }
  }

  protected async handleEvent(message: AgentMessage): Promise<AgentResponse> {
    this.log('info', `Received event: ${message.action}`);
    
    // Handle events like project changes, file updates, etc.
    switch (message.action) {
      case 'project-updated':
        return this.createSuccessResponse({ acknowledged: true });
      
      case 'file-changed':
        return this.createSuccessResponse({ acknowledged: true, suggestion: 'Consider running incremental review' });
      
      default:
        return this.createSuccessResponse({ acknowledged: true });
    }
  }

  protected async performTask(task: AgentTask): Promise<unknown> {
    this.log('info', `Performing task: ${task.type}`, { description: task.description });
    
    switch (task.type) {
      case 'full-review':
        const reviewResult = await this.handleReview(task.input as ReviewRequest);
        return reviewResult.data;
      
      default:
        throw new Error(`Unknown task type: ${task.type}`);
    }
  }

  // ============================================================================
  // Core Review Methods
  // ============================================================================

  private async handleReview(request: ReviewRequest): Promise<AgentResponse<ArchitectureReview>> {
    const reviewId = generateId();
    const findings: ReviewFinding[] = [];
    const diagrams: ArchitectureDiagram[] = [];

    // Get project context - either from context or by name in request
    let projectContext = this.context?.project;
    if (request.projectName) {
      projectContext = getProjectByName(request.projectName) || projectContext;
    }

    // Run stack-specific reviews if we have context
    if (projectContext) {
      findings.push(...runStackSpecificReview(projectContext));
    }

    // Analyze based on review type
    switch (request.type) {
      case 'full':
        findings.push(...this.analyzeArchitecturePatterns(request));
        findings.push(...this.analyzeCodeOrganization(request));
        findings.push(...this.analyzeSecurityConcerns(request));
        findings.push(...this.analyzePerformanceConcerns(request));
        findings.push(...this.analyzeTestability(request));
        diagrams.push(this.generateComponentDiagram(request));
        break;
      
      case 'api':
        findings.push(...this.analyzeApiPatterns(request));
        break;
      
      case 'database':
        findings.push(...this.analyzeDatabasePatterns(request));
        diagrams.push(this.generateERDiagram(request));
        break;
      
      case 'infrastructure':
        findings.push(...this.analyzeInfrastructurePatterns(request));
        diagrams.push(this.generateDeploymentDiagram(request));
        break;
      
      case 'code-patterns':
        findings.push(...this.analyzeCodePatterns(request));
        break;
    }

    // Calculate scores
    const score = this.calculateScores(findings);

    const review: ArchitectureReview = {
      id: reviewId,
      timestamp: Date.now(),
      project: projectContext?.name || this.context?.project.name || 'unknown',
      reviewType: request.type === 'full' ? 'full' : 'focused',
      scope: request.scope || ['all'],
      summary: this.generateSummary(findings, score),
      score,
      findings,
      recommendations: this.generateRecommendations(findings),
      diagrams
    };

    return this.createSuccessResponse(
      review,
      'Architecture review completed successfully',
      this.generateQuickWins(findings),
      this.generateNextSteps(review)
    );
  }

  private async handleApiReview(input: ApiDesignInput): Promise<AgentResponse> {
    const findings: ReviewFinding[] = [];

    if (input.endpoints) {
      for (const endpoint of input.endpoints) {
        findings.push(...this.analyzeEndpoint(endpoint));
      }
    }

    findings.push(...this.analyzeApiConsistency(input));
    findings.push(...this.analyzeApiSecurity(input));
    findings.push(...this.analyzeApiVersioning(input));

    return this.createSuccessResponse({
      findings,
      recommendations: this.generateRecommendations(findings),
      score: this.calculateApiScore(findings)
    });
  }

  private async handleDatabaseReview(input: DatabaseSchemaInput): Promise<AgentResponse> {
    const findings: ReviewFinding[] = [];

    if (input.models) {
      findings.push(...this.analyzeNormalization(input.models));
      findings.push(...this.analyzeRelationships(input.models));
      findings.push(...this.analyzeIndexingOpportunities(input.models));
    }

    if (input.prismaSchema || input.drizzleSchema) {
      findings.push(...this.analyzeORMSchema(input));
    }

    const diagram = this.generateERDiagram({ type: 'database', codeSnippets: [] });

    return this.createSuccessResponse({
      findings,
      recommendations: this.generateRecommendations(findings),
      diagram
    });
  }

  private async handleInfrastructureReview(input: InfrastructureInput): Promise<AgentResponse> {
    const findings: ReviewFinding[] = [];

    switch (input.type) {
      case 'kubernetes':
        findings.push(...this.analyzeKubernetesConfig(input));
        break;
      case 'docker':
        findings.push(...this.analyzeDockerConfig(input));
        break;
      case 'serverless':
        findings.push(...this.analyzeServerlessConfig(input));
        break;
      case 'traditional':
        findings.push(...this.analyzeTraditionalInfra(input));
        break;
    }

    findings.push(...this.analyzeHighAvailability(input));
    findings.push(...this.analyzeDisasterRecovery(input));

    return this.createSuccessResponse({
      findings,
      recommendations: this.generateRecommendations(findings),
      diagram: this.generateDeploymentDiagram({ type: 'infrastructure' } as ReviewRequest)
    });
  }

  private async handlePatternAnalysis(input: CodePatternInput): Promise<AgentResponse> {
    const findings: ReviewFinding[] = [];

    for (const pattern of input.patterns) {
      findings.push(...this.analyzePattern(pattern));
    }

    // Detect anti-patterns
    findings.push(...this.detectAntiPatterns(input));

    // Suggest pattern improvements
    findings.push(...this.suggestPatternImprovements(input));

    return this.createSuccessResponse({
      findings,
      patterns: this.identifyPatterns(input),
      antiPatterns: this.identifyAntiPatterns(input),
      recommendations: this.generateRecommendations(findings)
    });
  }

  private async handleDiagramGeneration(input: { type: string; context: unknown }): Promise<AgentResponse> {
    let diagram: ArchitectureDiagram;

    switch (input.type) {
      case 'component':
        diagram = this.generateComponentDiagram(input.context as ReviewRequest);
        break;
      case 'sequence':
        diagram = this.generateSequenceDiagram(input.context);
        break;
      case 'deployment':
        diagram = this.generateDeploymentDiagram(input.context as ReviewRequest);
        break;
      case 'er':
        diagram = this.generateERDiagram(input.context as ReviewRequest);
        break;
      case 'flow':
        diagram = this.generateFlowDiagram(input.context);
        break;
      default:
        return this.createErrorResponse('UNKNOWN_DIAGRAM_TYPE', `Unknown diagram type: ${input.type}`);
    }

    return this.createSuccessResponse({ diagram });
  }

  private async handleStackRecommendation(input: { requirements: string[] }): Promise<AgentResponse> {
    const recommendations = this.analyzeRequirementsForStack(input.requirements);

    return this.createSuccessResponse({
      recommendations,
      reasoning: 'Stack recommendations based on project requirements analysis'
    });
  }

  private async handleScalabilityAssessment(input: { context: ProjectContext }): Promise<AgentResponse> {
    const findings: ReviewFinding[] = [];
    
    findings.push(...this.analyzeHorizontalScaling(input.context));
    findings.push(...this.analyzeVerticalScaling(input.context));
    findings.push(...this.analyzeCachingStrategy(input.context));
    findings.push(...this.analyzeDataPartitioning(input.context));

    return this.createSuccessResponse({
      findings,
      currentCapacity: this.estimateCurrentCapacity(input.context),
      recommendations: this.generateScalabilityRecommendations(findings)
    });
  }

  private async handleListProjects(): Promise<AgentResponse> {
    const projects = getAllProjects();
    
    return this.createSuccessResponse({
      projects: projects.map(p => ({
        name: p.name,
        repoUrl: p.repoUrl,
        techStack: {
          languages: p.techStack.languages,
          frameworks: p.techStack.frameworks
        },
        type: p.structure?.type,
        serviceCount: p.services?.length || 0
      })),
      knownProjects: ['zeroinbox', 'zero', 'rationale-site', 'site']
    }, 'Use projectName in review requests to get stack-specific analysis');
  }

  // ============================================================================
  // Analysis Methods
  // ============================================================================

  private analyzeArchitecturePatterns(request: ReviewRequest): ReviewFinding[] {
    const findings: ReviewFinding[] = [];

    // Example findings - in production, this would analyze actual code
    findings.push({
      id: generateId(),
      severity: 'suggestion',
      category: 'Architecture Pattern',
      title: 'Consider implementing Clean Architecture',
      description: 'The codebase would benefit from clearer separation between business logic and infrastructure concerns.',
      recommendation: 'Introduce distinct layers: Domain, Application, Infrastructure, and Presentation. Use dependency injection to maintain proper dependency direction.',
      effort: 'large',
      impact: 'high',
      references: ['https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html']
    });

    return findings;
  }

  private analyzeCodeOrganization(request: ReviewRequest): ReviewFinding[] {
    const findings: ReviewFinding[] = [];

    findings.push({
      id: generateId(),
      severity: 'info',
      category: 'Code Organization',
      title: 'Feature-based folder structure recommended',
      description: 'Organizing code by feature rather than by type improves maintainability and discoverability.',
      recommendation: 'Group related components, hooks, and utilities by feature domain rather than technical category.',
      effort: 'medium',
      impact: 'medium'
    });

    return findings;
  }

  private analyzeSecurityConcerns(request: ReviewRequest): ReviewFinding[] {
    const findings: ReviewFinding[] = [];

    findings.push({
      id: generateId(),
      severity: 'warning',
      category: 'Security',
      title: 'Input validation layer recommended',
      description: 'Ensure all API inputs are validated at the boundary before processing.',
      recommendation: 'Implement schema validation (e.g., Zod) at API route handlers to validate request bodies, query params, and path params.',
      effort: 'small',
      impact: 'high'
    });

    return findings;
  }

  private analyzePerformanceConcerns(request: ReviewRequest): ReviewFinding[] {
    const findings: ReviewFinding[] = [];

    findings.push({
      id: generateId(),
      severity: 'suggestion',
      category: 'Performance',
      title: 'Consider implementing caching strategy',
      description: 'Adding appropriate caching layers can significantly improve response times and reduce database load.',
      recommendation: 'Implement Redis or in-memory caching for frequently accessed data. Use cache invalidation patterns appropriate for your consistency requirements.',
      effort: 'medium',
      impact: 'high'
    });

    return findings;
  }

  private analyzeTestability(request: ReviewRequest): ReviewFinding[] {
    const findings: ReviewFinding[] = [];

    findings.push({
      id: generateId(),
      severity: 'suggestion',
      category: 'Testability',
      title: 'Improve dependency injection patterns',
      description: 'Current tight coupling makes unit testing difficult.',
      recommendation: 'Use constructor injection or context-based injection to make dependencies explicit and mockable.',
      effort: 'medium',
      impact: 'medium'
    });

    return findings;
  }

  private analyzeApiPatterns(request: ReviewRequest): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'info',
      category: 'API Design',
      title: 'RESTful conventions check',
      description: 'Ensure consistent use of HTTP methods and status codes.',
      recommendation: 'Use POST for creation, PUT/PATCH for updates, DELETE for removal. Return appropriate status codes (201 for creation, 204 for no content, etc.).',
      effort: 'trivial',
      impact: 'medium'
    }];
  }

  private analyzeDatabasePatterns(request: ReviewRequest): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'info',
      category: 'Database',
      title: 'Index optimization opportunities',
      description: 'Review query patterns to ensure proper indexing.',
      recommendation: 'Add composite indexes for frequently used filter combinations. Consider partial indexes for large tables with common WHERE clauses.',
      effort: 'small',
      impact: 'high'
    }];
  }

  private analyzeInfrastructurePatterns(request: ReviewRequest): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'suggestion',
      category: 'Infrastructure',
      title: 'Consider blue-green deployment',
      description: 'Reduce deployment risk with zero-downtime deployments.',
      recommendation: 'Implement blue-green or canary deployment strategies to minimize deployment risk and enable quick rollbacks.',
      effort: 'medium',
      impact: 'medium'
    }];
  }

  private analyzeCodePatterns(request: ReviewRequest): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'info',
      category: 'Code Patterns',
      title: 'Repository pattern for data access',
      description: 'Abstract data access behind repository interfaces.',
      recommendation: 'Implement repository pattern to decouple business logic from data persistence implementation details.',
      effort: 'medium',
      impact: 'medium'
    }];
  }

  private analyzeEndpoint(endpoint: { method: string; path: string; description?: string; requestBody?: unknown; responseBody?: unknown }): ReviewFinding[] {
    const findings: ReviewFinding[] = [];
    
    // Check for RESTful path conventions
    if (!endpoint.path.startsWith('/api/')) {
      findings.push({
        id: generateId(),
        severity: 'suggestion',
        category: 'API Design',
        title: 'API path prefix convention',
        description: `Endpoint ${endpoint.path} should follow /api/v{n}/ prefix convention.`,
        location: { component: endpoint.path },
        recommendation: 'Use consistent API versioning prefix like /api/v1/',
        effort: 'trivial',
        impact: 'low'
      });
    }

    return findings;
  }

  private analyzeApiConsistency(input: ApiDesignInput): ReviewFinding[] {
    return [];
  }

  private analyzeApiSecurity(input: ApiDesignInput): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'warning',
      category: 'API Security',
      title: 'Authentication middleware required',
      description: 'Ensure all protected endpoints have proper authentication.',
      recommendation: 'Implement JWT or session-based authentication middleware for protected routes.',
      effort: 'medium',
      impact: 'critical'
    }];
  }

  private analyzeApiVersioning(input: ApiDesignInput): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'suggestion',
      category: 'API Design',
      title: 'API versioning strategy',
      description: 'Implement consistent API versioning for backward compatibility.',
      recommendation: 'Use URL-based versioning (/api/v1/) or header-based versioning for API evolution.',
      effort: 'small',
      impact: 'medium'
    }];
  }

  private analyzeNormalization(models: Array<{ name: string; fields: Array<{ name: string; type: string; constraints?: string[] }>; relations?: Array<{ to: string; type: string }> }>): ReviewFinding[] {
    return [];
  }

  private analyzeRelationships(models: Array<{ name: string; fields: Array<{ name: string; type: string; constraints?: string[] }>; relations?: Array<{ to: string; type: string }> }>): ReviewFinding[] {
    return [];
  }

  private analyzeIndexingOpportunities(models: Array<{ name: string; fields: Array<{ name: string; type: string; constraints?: string[] }>; relations?: Array<{ to: string; type: string }> }>): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'suggestion',
      category: 'Database Performance',
      title: 'Review foreign key indexes',
      description: 'Ensure all foreign key columns are indexed for join performance.',
      recommendation: 'Add indexes on foreign key columns if not already present.',
      effort: 'trivial',
      impact: 'high'
    }];
  }

  private analyzeORMSchema(input: DatabaseSchemaInput): ReviewFinding[] {
    return [];
  }

  private analyzeKubernetesConfig(input: InfrastructureInput): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'warning',
      category: 'Kubernetes',
      title: 'Resource limits configuration',
      description: 'Ensure all pods have CPU and memory limits defined.',
      recommendation: 'Define resource requests and limits for all containers to ensure fair scheduling and prevent resource exhaustion.',
      effort: 'small',
      impact: 'high'
    }];
  }

  private analyzeDockerConfig(input: InfrastructureInput): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'suggestion',
      category: 'Docker',
      title: 'Multi-stage builds',
      description: 'Use multi-stage builds to reduce image size.',
      recommendation: 'Implement multi-stage Dockerfile to separate build and runtime stages, reducing final image size.',
      effort: 'small',
      impact: 'medium'
    }];
  }

  private analyzeServerlessConfig(input: InfrastructureInput): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'info',
      category: 'Serverless',
      title: 'Cold start optimization',
      description: 'Consider cold start implications for latency-sensitive operations.',
      recommendation: 'Use provisioned concurrency for critical paths or implement warming strategies.',
      effort: 'medium',
      impact: 'medium'
    }];
  }

  private analyzeTraditionalInfra(input: InfrastructureInput): ReviewFinding[] {
    return [];
  }

  private analyzeHighAvailability(input: InfrastructureInput): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'warning',
      category: 'High Availability',
      title: 'Single point of failure check',
      description: 'Identify and eliminate single points of failure.',
      recommendation: 'Ensure all critical services have redundancy. Use load balancing and health checks.',
      effort: 'large',
      impact: 'critical'
    }];
  }

  private analyzeDisasterRecovery(input: InfrastructureInput): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'suggestion',
      category: 'Disaster Recovery',
      title: 'Backup and recovery plan',
      description: 'Ensure automated backups and tested recovery procedures.',
      recommendation: 'Implement automated database backups with point-in-time recovery. Document and test recovery procedures regularly.',
      effort: 'medium',
      impact: 'critical'
    }];
  }

  private analyzePattern(pattern: { name: string; files: string[]; description?: string }): ReviewFinding[] {
    return [];
  }

  private detectAntiPatterns(input: CodePatternInput): ReviewFinding[] {
    return [];
  }

  private suggestPatternImprovements(input: CodePatternInput): ReviewFinding[] {
    return [];
  }

  private identifyPatterns(input: CodePatternInput): string[] {
    return ['Repository', 'Factory', 'Observer'];
  }

  private identifyAntiPatterns(input: CodePatternInput): string[] {
    return [];
  }

  private analyzeRequirementsForStack(requirements: string[]): object {
    return {
      frontend: ['React', 'Next.js', 'TypeScript', 'TailwindCSS'],
      backend: ['Next.js API Routes', 'tRPC', 'Prisma'],
      database: ['PostgreSQL', 'Redis'],
      infrastructure: ['Vercel', 'PlanetScale'],
      reasoning: 'Based on requirements for modern web application with SSR support and type safety.'
    };
  }

  private analyzeHorizontalScaling(context: ProjectContext): ReviewFinding[] {
    return [];
  }

  private analyzeVerticalScaling(context: ProjectContext): ReviewFinding[] {
    return [];
  }

  private analyzeCachingStrategy(context: ProjectContext): ReviewFinding[] {
    return [{
      id: generateId(),
      severity: 'suggestion',
      category: 'Scalability',
      title: 'Implement distributed caching',
      description: 'Redis or Memcached for session and data caching across instances.',
      recommendation: 'Add Redis as a caching layer for database queries and session storage.',
      effort: 'medium',
      impact: 'high'
    }];
  }

  private analyzeDataPartitioning(context: ProjectContext): ReviewFinding[] {
    return [];
  }

  private estimateCurrentCapacity(context: ProjectContext): object {
    return {
      estimatedRPS: 1000,
      estimatedConcurrentUsers: 500,
      bottlenecks: ['Database connections', 'Memory usage']
    };
  }

  private generateScalabilityRecommendations(findings: ReviewFinding[]): string[] {
    return [
      'Implement connection pooling for database',
      'Add read replicas for query distribution',
      'Use CDN for static assets',
      'Consider message queue for async operations'
    ];
  }

  // ============================================================================
  // Diagram Generation
  // ============================================================================

  private generateComponentDiagram(request: ReviewRequest): ArchitectureDiagram {
    return {
      type: 'component',
      title: 'System Component Diagram',
      mermaid: `graph TB
    subgraph Client
        Web[Web App]
        Mobile[Mobile App]
    end
    
    subgraph API Layer
        Gateway[API Gateway]
        Auth[Auth Service]
    end
    
    subgraph Services
        UserSvc[User Service]
        DataSvc[Data Service]
        NotifSvc[Notification Service]
    end
    
    subgraph Data
        DB[(PostgreSQL)]
        Cache[(Redis)]
        Queue[Message Queue]
    end
    
    Web --> Gateway
    Mobile --> Gateway
    Gateway --> Auth
    Gateway --> UserSvc
    Gateway --> DataSvc
    UserSvc --> DB
    UserSvc --> Cache
    DataSvc --> DB
    DataSvc --> Cache
    NotifSvc --> Queue`
    };
  }

  private generateSequenceDiagram(context: unknown): ArchitectureDiagram {
    return {
      type: 'sequence',
      title: 'Request Flow Sequence',
      mermaid: `sequenceDiagram
    participant Client
    participant Gateway
    participant Auth
    participant Service
    participant DB
    
    Client->>Gateway: Request
    Gateway->>Auth: Validate Token
    Auth-->>Gateway: Token Valid
    Gateway->>Service: Process Request
    Service->>DB: Query Data
    DB-->>Service: Return Data
    Service-->>Gateway: Response
    Gateway-->>Client: Response`
    };
  }

  private generateDeploymentDiagram(request: ReviewRequest): ArchitectureDiagram {
    return {
      type: 'deployment',
      title: 'Deployment Architecture',
      mermaid: `graph TB
    subgraph CDN
        CF[CloudFlare]
    end
    
    subgraph Load Balancer
        LB[nginx/ALB]
    end
    
    subgraph App Servers
        App1[App Instance 1]
        App2[App Instance 2]
        App3[App Instance 3]
    end
    
    subgraph Database Cluster
        Primary[(Primary DB)]
        Replica1[(Read Replica 1)]
        Replica2[(Read Replica 2)]
    end
    
    subgraph Cache Layer
        Redis1[Redis Primary]
        Redis2[Redis Replica]
    end
    
    CF --> LB
    LB --> App1
    LB --> App2
    LB --> App3
    App1 --> Primary
    App2 --> Primary
    App3 --> Primary
    App1 --> Replica1
    App2 --> Replica2
    App1 --> Redis1
    App2 --> Redis1
    App3 --> Redis2
    Primary --> Replica1
    Primary --> Replica2
    Redis1 --> Redis2`
    };
  }

  private generateERDiagram(request: ReviewRequest): ArchitectureDiagram {
    return {
      type: 'er',
      title: 'Entity Relationship Diagram',
      mermaid: `erDiagram
    USER ||--o{ ORDER : places
    USER ||--o{ ADDRESS : has
    USER {
        uuid id PK
        string email
        string name
        timestamp created_at
    }
    ORDER ||--|{ ORDER_ITEM : contains
    ORDER {
        uuid id PK
        uuid user_id FK
        decimal total
        string status
        timestamp created_at
    }
    PRODUCT ||--o{ ORDER_ITEM : "ordered in"
    PRODUCT {
        uuid id PK
        string name
        decimal price
        int stock
    }
    ORDER_ITEM {
        uuid id PK
        uuid order_id FK
        uuid product_id FK
        int quantity
    }
    ADDRESS {
        uuid id PK
        uuid user_id FK
        string street
        string city
        string country
    }`
    };
  }

  private generateFlowDiagram(context: unknown): ArchitectureDiagram {
    return {
      type: 'flow',
      title: 'Process Flow',
      mermaid: `flowchart TD
    A[Start] --> B{User Authenticated?}
    B -->|Yes| C[Load User Data]
    B -->|No| D[Redirect to Login]
    D --> E[Authenticate]
    E --> B
    C --> F[Display Dashboard]
    F --> G{Action?}
    G -->|Create| H[Create Resource]
    G -->|Read| I[Fetch Resource]
    G -->|Update| J[Update Resource]
    G -->|Delete| K[Delete Resource]
    H --> L[Validate Input]
    L --> M{Valid?}
    M -->|Yes| N[Save to DB]
    M -->|No| O[Show Errors]
    N --> P[Return Success]
    O --> G`
    };
  }

  // ============================================================================
  // Scoring & Summary
  // ============================================================================

  private calculateScores(findings: ReviewFinding[]): ArchitectureReview['score'] {
    const baseScore = 80;
    let deductions = 0;

    for (const finding of findings) {
      switch (finding.severity) {
        case 'critical': deductions += 15; break;
        case 'error': deductions += 10; break;
        case 'warning': deductions += 5; break;
        case 'suggestion': deductions += 2; break;
        case 'info': deductions += 0; break;
      }
    }

    const overall = Math.max(0, baseScore - deductions);

    return {
      overall,
      maintainability: Math.min(100, overall + 5),
      scalability: Math.min(100, overall - 5),
      security: Math.min(100, overall + 10),
      performance: Math.min(100, overall - 10),
      testability: Math.min(100, overall)
    };
  }

  private calculateApiScore(findings: ReviewFinding[]): number {
    const baseScore = 85;
    let deductions = 0;

    for (const finding of findings) {
      switch (finding.severity) {
        case 'critical': deductions += 20; break;
        case 'error': deductions += 15; break;
        case 'warning': deductions += 8; break;
        case 'suggestion': deductions += 3; break;
      }
    }

    return Math.max(0, baseScore - deductions);
  }

  private generateSummary(findings: ReviewFinding[], score: ArchitectureReview['score']): string {
    const criticalCount = findings.filter(f => f.severity === 'critical').length;
    const errorCount = findings.filter(f => f.severity === 'error').length;
    const warningCount = findings.filter(f => f.severity === 'warning').length;

    let summary = `Architecture review completed with an overall score of ${score.overall}/100. `;
    
    if (criticalCount > 0) {
      summary += `Found ${criticalCount} critical issues requiring immediate attention. `;
    }
    if (errorCount > 0) {
      summary += `${errorCount} errors should be addressed in the near term. `;
    }
    if (warningCount > 0) {
      summary += `${warningCount} warnings suggest areas for improvement. `;
    }

    return summary;
  }

  private generateRecommendations(findings: ReviewFinding[]): string[] {
    return findings
      .filter(f => f.severity === 'critical' || f.severity === 'error' || f.severity === 'warning')
      .sort((a, b) => {
        const severityOrder = { critical: 0, error: 1, warning: 2, suggestion: 3, info: 4 };
        return severityOrder[a.severity] - severityOrder[b.severity];
      })
      .slice(0, 5)
      .map(f => f.recommendation);
  }

  private generateQuickWins(findings: ReviewFinding[]): string[] {
    return findings
      .filter(f => f.effort === 'trivial' || f.effort === 'small')
      .filter(f => f.impact === 'high' || f.impact === 'critical')
      .map(f => f.title);
  }

  private generateNextSteps(review: ArchitectureReview): string[] {
    const steps: string[] = [];
    
    if (review.score.security < 80) {
      steps.push('Schedule security review session');
    }
    if (review.score.performance < 80) {
      steps.push('Run performance profiling');
    }
    if (review.score.testability < 80) {
      steps.push('Increase test coverage');
    }

    steps.push('Address critical findings first');
    steps.push('Create tickets for medium-effort improvements');

    return steps;
  }
}

import { z } from 'zod';

// ============================================================================
// Agent Identity & Capabilities
// ============================================================================

export type AgentRole = 
  | 'systems-architect'
  | 'frontend-engineer'
  | 'backend-engineer'
  | 'devops-engineer'
  | 'qa-engineer'
  | 'security-analyst'
  | 'product-manager'
  | 'orchestrator';

export interface AgentCapability {
  name: string;
  description: string;
  inputSchema?: z.ZodType;
  outputSchema?: z.ZodType;
}

export interface AgentMetadata {
  id: string;
  name: string;
  role: AgentRole;
  description: string;
  capabilities: AgentCapability[];
  version: string;
}

// ============================================================================
// Agent Communication
// ============================================================================

export type MessagePriority = 'low' | 'normal' | 'high' | 'critical';

export interface AgentMessage {
  id: string;
  from: string;        // agent id
  to: string;          // agent id or 'broadcast'
  type: 'request' | 'response' | 'event' | 'error';
  action: string;
  payload: unknown;
  priority: MessagePriority;
  correlationId?: string;  // for request-response matching
  timestamp: number;
  metadata?: Record<string, unknown>;
}

export interface AgentResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: unknown;
  };
  reasoning?: string;  // agent's explanation of its decision
  suggestions?: string[];
  nextSteps?: string[];
}

// ============================================================================
// Agent Context
// ============================================================================

export interface ProjectContext {
  name: string;
  rootPath: string;
  techStack: TechStack;
  structure?: ProjectStructure;
  conventions?: ProjectConventions;
  repoUrl?: string;
  services?: ServiceDefinition[];  // For microservices
}

export interface TechStack {
  languages: string[];
  frameworks: string[];
  databases?: string[];
  infrastructure?: string[];
  tools?: string[];
  // Rationale-specific
  ui?: {
    styling: 'tailwind' | 'css-modules' | 'styled-components' | 'emotion';
    animation?: 'framer-motion' | 'react-spring' | 'gsap';
    icons?: string;
    charts?: string;
  };
  threejs?: {
    enabled: boolean;
    libraries: string[];  // e.g., ['@react-three/fiber', '@react-three/drei']
  };
}

export interface ServiceDefinition {
  name: string;
  port: number;
  type: 'gateway' | 'api' | 'worker' | 'ml' | 'agent';
  endpoints?: string[];
  dependencies?: string[];
  health?: string;
}

export interface ProjectStructure {
  type: 'monorepo' | 'single-app' | 'microservices' | 'hybrid-ios-web';
  directories: DirectoryInfo[];
  appRouter?: boolean;  // Next.js App Router
  iosApp?: {
    path: string;
    pattern: 'mvvm' | 'mvc' | 'viper' | 'tca';
    swiftVersion: string;
  };
}

export interface DirectoryInfo {
  path: string;
  purpose: string;
  patterns?: string[];
}

export interface ProjectConventions {
  naming?: NamingConventions;
  architecture?: ArchitecturePatterns;
  testing?: TestingConventions;
}

export interface NamingConventions {
  files: 'kebab-case' | 'camelCase' | 'PascalCase' | 'snake_case';
  components: 'kebab-case' | 'camelCase' | 'PascalCase';
  functions: 'camelCase' | 'snake_case';
  constants: 'SCREAMING_SNAKE_CASE' | 'camelCase';
}

export interface ArchitecturePatterns {
  stateManagement?: string;
  dataFetching?: string;
  styling?: string;
  routing?: string;
}

export interface TestingConventions {
  framework: string;
  location: 'colocated' | 'separate';
  naming: string;
}

// ============================================================================
// Agent Execution
// ============================================================================

export interface ExecutionContext {
  project: ProjectContext;
  currentAgent: AgentMetadata;
  availableAgents: AgentMetadata[];
  history: AgentMessage[];
  environment: 'development' | 'staging' | 'production';
}

export interface AgentTask {
  id: string;
  type: string;
  description: string;
  input: unknown;
  priority: MessagePriority;
  deadline?: number;
  requiredCapabilities?: string[];
}

export interface TaskResult<T = unknown> {
  taskId: string;
  agentId: string;
  status: 'completed' | 'failed' | 'partial' | 'delegated';
  result?: T;
  error?: string;
  duration: number;
  delegatedTo?: string;
}

// ============================================================================
// Review Types (for Systems Architect)
// ============================================================================

export type ReviewSeverity = 'info' | 'suggestion' | 'warning' | 'error' | 'critical';

export interface ReviewFinding {
  id: string;
  severity: ReviewSeverity;
  category: string;
  title: string;
  description: string;
  location?: {
    file?: string;
    line?: number;
    component?: string;
  };
  recommendation: string;
  effort: 'trivial' | 'small' | 'medium' | 'large' | 'epic';
  impact: 'low' | 'medium' | 'high' | 'critical';
  references?: string[];
}

export interface ArchitectureReview {
  id: string;
  timestamp: number;
  project: string;
  reviewType: 'full' | 'incremental' | 'focused';
  scope: string[];
  summary: string;
  score: {
    overall: number;
    maintainability: number;
    scalability: number;
    security: number;
    performance: number;
    testability: number;
  };
  findings: ReviewFinding[];
  recommendations: string[];
  diagrams?: ArchitectureDiagram[];
}

export interface ArchitectureDiagram {
  type: 'component' | 'sequence' | 'deployment' | 'er' | 'flow';
  title: string;
  mermaid: string;
}

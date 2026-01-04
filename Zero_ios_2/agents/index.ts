// Main exports
export * from './types';
export * from './core';
export * from './agents';
export * from './config';

// Re-export singletons for convenience
export { agentRegistry } from './core/agent-registry';
export { agentRouter } from './core/agent-router';

// Re-export project configs
export { ZERO_INBOX_PROJECT, RATIONALE_SITE_PROJECT, getProjectByName, getAllProjects } from './config/projects';

// ============================================================================
// Initialization
// ============================================================================

import { agentRegistry } from './core/agent-registry';
import { agentRouter } from './core/agent-router';
import { SystemsArchitectAgent } from './agents/systems-architect.agent';
import { UXDesignExpertAgent } from './agents/ux-design-expert.agent';
import { VCInvestorAgent } from './agents/vc-investor.agent';
import { MarketingAgent } from './agents/marketing.agent';
import { DesignSystemAgent } from './agents/design-system.agent';
import { BrandDirectorAgent } from './agents/brand-director.agent';
import { ProspectiveClientAgent } from './agents/prospective-client.agent';
import { ZeroAIExpertAgent } from './agents/zero-ai-expert.agent';
import { ProjectContext } from './types/agent.types';

/**
 * Initialize the agent system with all agents
 */
export function initializeAgents(projectContext?: ProjectContext): void {
  // Register all agents
  const agents = [
    new SystemsArchitectAgent(),
    new UXDesignExpertAgent(),
    new VCInvestorAgent(),
    new MarketingAgent(),
    new DesignSystemAgent(),
    new BrandDirectorAgent(),
    new ProspectiveClientAgent(),
    new ZeroAIExpertAgent()
  ];

  for (const agent of agents) {
    if (!agentRegistry.hasAgent(agent.getId())) {
      agentRegistry.register(agent);
    }
  }

  // Set project context if provided
  if (projectContext) {
    agentRouter.setProjectContext(projectContext);
  }

  console.log('[AgentSystem] Initialized with agents:', agentRegistry.getStatus());
}

/**
 * Quick access to invoke agents by role or id
 */
export async function invokeAgent(agentId: string, action: string, payload: unknown) {
  return agentRouter.invokeAgent(agentId, action, payload);
}

export async function invokeArchitect(action: string, payload: unknown) {
  return agentRouter.invokeAgent('systems-architect-001', action, payload);
}

export async function invokeUXExpert(action: string, payload: unknown) {
  return agentRouter.invokeAgent('ux-design-expert-001', action, payload);
}

export async function invokeVCAgent(action: string, payload: unknown) {
  return agentRouter.invokeAgent('vc-investor-001', action, payload);
}

export async function invokeMarketing(action: string, payload: unknown) {
  return agentRouter.invokeAgent('marketing-agent-001', action, payload);
}

export async function invokeDesignSystem(action: string, payload: unknown) {
  return agentRouter.invokeAgent('design-system-001', action, payload);
}

export async function invokeBrandDirector(action: string, payload: unknown) {
  return agentRouter.invokeAgent('brand-director-001', action, payload);
}

export async function invokeProspectiveClient(action: string, payload: unknown) {
  return agentRouter.invokeAgent('prospective-client-001', action, payload);
}

export async function invokeZeroAIExpert(action: string, payload: unknown) {
  return agentRouter.invokeAgent('zero-ai-expert-001', action, payload);
}

// ============================================================================
// Agent IDs for reference
// ============================================================================

export const AGENT_IDS = {
  SYSTEMS_ARCHITECT: 'systems-architect-001',
  UX_DESIGN_EXPERT: 'ux-design-expert-001',
  VC_INVESTOR: 'vc-investor-001',
  MARKETING: 'marketing-agent-001',
  DESIGN_SYSTEM: 'design-system-001',
  BRAND_DIRECTOR: 'brand-director-001',
  PROSPECTIVE_CLIENT: 'prospective-client-001',
  ZERO_AI_EXPERT: 'zero-ai-expert-001'
} as const;

// ============================================================================
// Example Usage
// ============================================================================

/*
import { 
  initializeAgents, 
  invokeArchitect, 
  invokeUXExpert, 
  invokeVCAgent, 
  invokeMarketing,
  invokeDesignSystem,
  invokeBrandDirector,
  invokeProspectiveClient,
  invokeZeroAIExpert,
  RATIONALE_SITE_PROJECT 
} from '@rationale/agents-system';

// Initialize all agents
initializeAgents(RATIONALE_SITE_PROJECT);

// Run architecture review
const archReview = await invokeArchitect('review', { 
  type: 'full', 
  projectName: 'rationale-site' 
});

// Run UX audit
const uxReview = await invokeUXExpert('audit', { 
  type: 'full' 
});

// Get VC perspective
const vcReview = await invokeVCAgent('review', { 
  type: 'full' 
});

// Generate marketing content
const socialPosts = await invokeMarketing('create-social-post', { 
  platform: 'linkedin',
  topic: 'product design'
});

// Audit design system consistency
const dsAudit = await invokeDesignSystem('audit', {
  type: 'full'
});

// Generate Figma tokens
const figmaTokens = await invokeDesignSystem('generate-figma-tokens', {
  format: 'variables'
});

// Run brand diagnostic
const brandReview = await invokeBrandDirector('review', {
  type: 'full'
});

// Generate brand worlds
const brandWorlds = await invokeBrandDirector('generate-worlds', {});

// Apply brand world to surfaces
const applications = await invokeBrandDirector('apply-world', {
  worldId: 'B',
  surfaces: ['homepage', 'deck', 'product']
});

// Get prospective client feedback (as Series A founder)
const clientFeedback = await invokeProspectiveClient('full-feedback', {
  persona: 'startup-sarah'
});

// See what references they like
const references = await invokeProspectiveClient('share-references', {
  persona: 'enterprise-eric'
});

// Get their objections
const objections = await invokeProspectiveClient('raise-objections', {
  persona: 'founder-felix'
});

// ============================================================================
// Zero AI Expert - Email & AI Tuning
// ============================================================================

// Full AI tuning review for Zero
const aiReview = await invokeZeroAIExpert('review', {
  type: 'full',
  currentMetrics: { accuracy: 92, hallucinationRate: 4, latency: 2500, costPerRequest: 0.02 },
  targetMetrics: { accuracy: 95, hallucinationRate: 2, latency: 1500, costPerRequest: 0.01 }
});

// Get model recommendations
const modelRecs = await invokeZeroAIExpert('recommend-models', {
  useCase: 'classification'
});

// Cost optimization strategies
const costPlan = await invokeZeroAIExpert('cost-optimization', {
  currentCost: 0.15,
  targetCost: 0.10
});

// Gmail integration best practices
const emailIntegration = await invokeZeroAIExpert('email-integration', {
  provider: 'gmail',
  focus: 'full'
});

// Hallucination prevention techniques
const antiHallucination = await invokeZeroAIExpert('prevent-hallucinations', {
  currentRate: 4
});

// Fine-tuning plan
const fineTuningPlan = await invokeZeroAIExpert('fine-tuning-plan', {
  dataSize: 1000,
  budget: 5000
});
*/


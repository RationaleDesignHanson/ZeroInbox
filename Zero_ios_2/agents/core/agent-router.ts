import { BaseAgent } from './base-agent';
import { agentRegistry } from './agent-registry';
import { 
  AgentMessage, 
  AgentResponse, 
  AgentRole,
  ExecutionContext,
  ProjectContext 
} from '../types/agent.types';
import { generateId } from '../utils/helpers';

type RouteStrategy = 'direct' | 'role' | 'capability' | 'broadcast';

interface RoutingResult {
  success: boolean;
  targetAgent?: BaseAgent;
  response?: AgentResponse;
  error?: string;
}

export class AgentRouter {
  private static instance: AgentRouter;
  private messageHistory: AgentMessage[] = [];
  private projectContext: ProjectContext | null = null;

  private constructor() {}

  static getInstance(): AgentRouter {
    if (!AgentRouter.instance) {
      AgentRouter.instance = new AgentRouter();
    }
    return AgentRouter.instance;
  }

  // ============================================================================
  // Configuration
  // ============================================================================

  setProjectContext(context: ProjectContext): void {
    this.projectContext = context;
    console.log(`[AgentRouter] Project context set: ${context.name}`);
  }

  // ============================================================================
  // Routing
  // ============================================================================

  async routeToAgent(
    fromAgentId: string,
    toAgentId: string,
    action: string,
    payload: unknown
  ): Promise<RoutingResult> {
    const targetAgent = agentRegistry.getAgent(toAgentId);
    
    if (!targetAgent) {
      return {
        success: false,
        error: `No agent found with id: ${toAgentId}`
      };
    }

    const message = this.createMessage(fromAgentId, toAgentId, 'request', action, payload);
    this.messageHistory.push(message);

    const response = await targetAgent.receiveMessage(message);

    return {
      success: response.success,
      targetAgent,
      response
    };
  }

  async routeToRole(
    fromAgentId: string,
    role: AgentRole,
    action: string,
    payload: unknown
  ): Promise<RoutingResult> {
    const targetAgent = agentRegistry.getAgentByRole(role);
    
    if (!targetAgent) {
      return {
        success: false,
        error: `No agent found for role: ${role}`
      };
    }

    return this.routeToAgent(fromAgentId, targetAgent.getId(), action, payload);
  }

  async routeToCapability(
    fromAgentId: string,
    capability: string,
    action: string,
    payload: unknown
  ): Promise<RoutingResult> {
    const agents = agentRegistry.getAgentsByCapability(capability);
    
    if (agents.length === 0) {
      return {
        success: false,
        error: `No agent found with capability: ${capability}`
      };
    }

    // Route to the first agent with this capability
    return this.routeToAgent(fromAgentId, agents[0].getId(), action, payload);
  }

  async broadcast(
    fromAgentId: string,
    action: string,
    payload: unknown,
    excludeRoles?: AgentRole[]
  ): Promise<Map<string, RoutingResult>> {
    const results = new Map<string, RoutingResult>();
    const agents = agentRegistry.getAllAgents();

    for (const agent of agents) {
      // Skip the sender
      if (agent.getId() === fromAgentId) continue;
      
      // Skip excluded roles
      if (excludeRoles?.includes(agent.getRole())) continue;

      const result = await this.routeToAgent(fromAgentId, agent.getId(), action, payload);
      results.set(agent.getId(), result);
    }

    return results;
  }

  // ============================================================================
  // Direct Invocation (for external callers like API routes)
  // ============================================================================

  async invokeAgent(
    agentId: string,
    action: string,
    payload: unknown
  ): Promise<AgentResponse> {
    const agent = agentRegistry.getAgent(agentId);
    
    if (!agent) {
      return {
        success: false,
        error: {
          code: 'AGENT_NOT_FOUND',
          message: `No agent found with id: ${agentId}`
        }
      };
    }

    // Set up execution context
    if (this.projectContext) {
      const context: ExecutionContext = {
        project: this.projectContext,
        currentAgent: agent.getMetadata(),
        availableAgents: agentRegistry.getAllMetadata(),
        history: this.getRecentHistory(50),
        environment: 'development'
      };
      agent.setContext(context);
    }

    const message = this.createMessage('external', agentId, 'request', action, payload);
    this.messageHistory.push(message);

    return agent.receiveMessage(message);
  }

  async invokeByRole(
    role: AgentRole,
    action: string,
    payload: unknown
  ): Promise<AgentResponse> {
    const agent = agentRegistry.getAgentByRole(role);
    
    if (!agent) {
      return {
        success: false,
        error: {
          code: 'ROLE_NOT_FOUND',
          message: `No agent found for role: ${role}`
        }
      };
    }

    return this.invokeAgent(agent.getId(), action, payload);
  }

  async invokeByCapability(
    capability: string,
    action: string,
    payload: unknown
  ): Promise<AgentResponse> {
    const agents = agentRegistry.getAgentsByCapability(capability);
    
    if (agents.length === 0) {
      return {
        success: false,
        error: {
          code: 'CAPABILITY_NOT_FOUND',
          message: `No agent found with capability: ${capability}`
        }
      };
    }

    return this.invokeAgent(agents[0].getId(), action, payload);
  }

  // ============================================================================
  // Message History
  // ============================================================================

  getMessageHistory(): AgentMessage[] {
    return [...this.messageHistory];
  }

  getRecentHistory(count: number): AgentMessage[] {
    return this.messageHistory.slice(-count);
  }

  getMessagesForAgent(agentId: string): AgentMessage[] {
    return this.messageHistory.filter(
      m => m.from === agentId || m.to === agentId
    );
  }

  clearHistory(): void {
    this.messageHistory = [];
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  private createMessage(
    from: string,
    to: string,
    type: AgentMessage['type'],
    action: string,
    payload: unknown,
    correlationId?: string
  ): AgentMessage {
    return {
      id: generateId(),
      from,
      to,
      type,
      action,
      payload,
      priority: 'normal',
      correlationId,
      timestamp: Date.now()
    };
  }
}

// Export singleton instance
export const agentRouter = AgentRouter.getInstance();

import { BaseAgent } from './base-agent';
import { AgentMetadata, AgentRole, AgentCapability } from '../types/agent.types';

type AgentFilter = {
  role?: AgentRole;
  capability?: string;
  id?: string;
};

export class AgentRegistry {
  private static instance: AgentRegistry;
  private agents: Map<string, BaseAgent> = new Map();
  private roleIndex: Map<AgentRole, Set<string>> = new Map();
  private capabilityIndex: Map<string, Set<string>> = new Map();

  private constructor() {}

  static getInstance(): AgentRegistry {
    if (!AgentRegistry.instance) {
      AgentRegistry.instance = new AgentRegistry();
    }
    return AgentRegistry.instance;
  }

  // ============================================================================
  // Registration
  // ============================================================================

  register(agent: BaseAgent): void {
    const metadata = agent.getMetadata();
    
    if (this.agents.has(metadata.id)) {
      throw new Error(`Agent with id "${metadata.id}" is already registered`);
    }

    // Store the agent
    this.agents.set(metadata.id, agent);

    // Index by role
    if (!this.roleIndex.has(metadata.role)) {
      this.roleIndex.set(metadata.role, new Set());
    }
    this.roleIndex.get(metadata.role)!.add(metadata.id);

    // Index by capabilities
    for (const capability of metadata.capabilities) {
      if (!this.capabilityIndex.has(capability.name)) {
        this.capabilityIndex.set(capability.name, new Set());
      }
      this.capabilityIndex.get(capability.name)!.add(metadata.id);
    }

    console.log(`[AgentRegistry] Registered agent: ${metadata.name} (${metadata.id})`);
  }

  unregister(agentId: string): boolean {
    const agent = this.agents.get(agentId);
    if (!agent) return false;

    const metadata = agent.getMetadata();

    // Remove from role index
    this.roleIndex.get(metadata.role)?.delete(agentId);

    // Remove from capability index
    for (const capability of metadata.capabilities) {
      this.capabilityIndex.get(capability.name)?.delete(agentId);
    }

    // Remove the agent
    this.agents.delete(agentId);

    console.log(`[AgentRegistry] Unregistered agent: ${metadata.name} (${agentId})`);
    return true;
  }

  // ============================================================================
  // Discovery
  // ============================================================================

  getAgent(id: string): BaseAgent | undefined {
    return this.agents.get(id);
  }

  getAgentByRole(role: AgentRole): BaseAgent | undefined {
    const agentIds = this.roleIndex.get(role);
    if (!agentIds || agentIds.size === 0) return undefined;
    
    // Return the first agent with this role
    const firstId = agentIds.values().next().value as string | undefined;
    if (!firstId) return undefined;
    return this.agents.get(firstId);
  }

  getAgentsByRole(role: AgentRole): BaseAgent[] {
    const agentIds = this.roleIndex.get(role);
    if (!agentIds) return [];
    
    return Array.from(agentIds)
      .map(id => this.agents.get(id))
      .filter((agent): agent is BaseAgent => agent !== undefined);
  }

  getAgentsByCapability(capability: string): BaseAgent[] {
    const agentIds = this.capabilityIndex.get(capability);
    if (!agentIds) return [];
    
    return Array.from(agentIds)
      .map(id => this.agents.get(id))
      .filter((agent): agent is BaseAgent => agent !== undefined);
  }

  findAgents(filter: AgentFilter): BaseAgent[] {
    let candidates = Array.from(this.agents.values());

    if (filter.id) {
      const agent = this.agents.get(filter.id);
      return agent ? [agent] : [];
    }

    if (filter.role) {
      const roleAgentIds = this.roleIndex.get(filter.role);
      if (!roleAgentIds) return [];
      candidates = candidates.filter(a => roleAgentIds.has(a.getId()));
    }

    if (filter.capability) {
      const capAgentIds = this.capabilityIndex.get(filter.capability);
      if (!capAgentIds) return [];
      candidates = candidates.filter(a => capAgentIds.has(a.getId()));
    }

    return candidates;
  }

  findAgentForTask(requiredCapabilities: string[]): BaseAgent | undefined {
    // Find an agent that has ALL required capabilities
    for (const agent of this.agents.values()) {
      const hasAll = requiredCapabilities.every(cap => agent.hasCapability(cap));
      if (hasAll) return agent;
    }
    return undefined;
  }

  // ============================================================================
  // Introspection
  // ============================================================================

  getAllAgents(): BaseAgent[] {
    return Array.from(this.agents.values());
  }

  getAllMetadata(): AgentMetadata[] {
    return Array.from(this.agents.values()).map(a => a.getMetadata());
  }

  getAvailableRoles(): AgentRole[] {
    return Array.from(this.roleIndex.keys());
  }

  getAvailableCapabilities(): string[] {
    return Array.from(this.capabilityIndex.keys());
  }

  getAgentCount(): number {
    return this.agents.size;
  }

  hasAgent(id: string): boolean {
    return this.agents.has(id);
  }

  hasRole(role: AgentRole): boolean {
    const agentIds = this.roleIndex.get(role);
    return !!agentIds && agentIds.size > 0;
  }

  hasCapability(capability: string): boolean {
    const agentIds = this.capabilityIndex.get(capability);
    return !!agentIds && agentIds.size > 0;
  }

  // ============================================================================
  // Utilities
  // ============================================================================

  clear(): void {
    this.agents.clear();
    this.roleIndex.clear();
    this.capabilityIndex.clear();
    console.log('[AgentRegistry] Cleared all agents');
  }

  getStatus(): {
    agentCount: number;
    roles: AgentRole[];
    capabilities: string[];
    agents: Array<{ id: string; name: string; role: AgentRole }>;
  } {
    return {
      agentCount: this.agents.size,
      roles: this.getAvailableRoles(),
      capabilities: this.getAvailableCapabilities(),
      agents: Array.from(this.agents.values()).map(a => ({
        id: a.getId(),
        name: a.getMetadata().name,
        role: a.getRole()
      }))
    };
  }
}

// Export singleton instance
export const agentRegistry = AgentRegistry.getInstance();

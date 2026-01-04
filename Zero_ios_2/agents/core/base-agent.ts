import { 
  AgentMetadata, 
  AgentMessage, 
  AgentResponse, 
  AgentCapability,
  AgentRole,
  ExecutionContext,
  AgentTask,
  TaskResult
} from '../types/agent.types';
import { generateId } from '../utils/helpers';

export abstract class BaseAgent {
  protected metadata: AgentMetadata;
  protected context: ExecutionContext | null = null;
  protected messageQueue: AgentMessage[] = [];

  constructor(
    id: string,
    name: string,
    role: AgentRole,
    description: string,
    capabilities: AgentCapability[],
    version: string = '1.0.0'
  ) {
    this.metadata = {
      id,
      name,
      role,
      description,
      capabilities,
      version
    };
  }

  // ============================================================================
  // Public Interface
  // ============================================================================

  getMetadata(): AgentMetadata {
    return { ...this.metadata };
  }

  getId(): string {
    return this.metadata.id;
  }

  getRole(): AgentRole {
    return this.metadata.role;
  }

  getCapabilities(): AgentCapability[] {
    return [...this.metadata.capabilities];
  }

  hasCapability(name: string): boolean {
    return this.metadata.capabilities.some(c => c.name === name);
  }

  setContext(context: ExecutionContext): void {
    this.context = context;
  }

  // ============================================================================
  // Message Handling
  // ============================================================================

  async receiveMessage(message: AgentMessage): Promise<AgentResponse> {
    this.messageQueue.push(message);
    
    try {
      // Route to appropriate handler based on message type
      switch (message.type) {
        case 'request':
          return await this.handleRequest(message);
        case 'event':
          return await this.handleEvent(message);
        default:
          return this.createErrorResponse('UNKNOWN_MESSAGE_TYPE', `Unknown message type: ${message.type}`);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      return this.createErrorResponse('HANDLER_ERROR', errorMessage);
    }
  }

  createMessage(
    to: string,
    type: AgentMessage['type'],
    action: string,
    payload: unknown,
    correlationId?: string
  ): AgentMessage {
    return {
      id: generateId(),
      from: this.metadata.id,
      to,
      type,
      action,
      payload,
      priority: 'normal',
      correlationId,
      timestamp: Date.now()
    };
  }

  // ============================================================================
  // Task Execution
  // ============================================================================

  async executeTask(task: AgentTask): Promise<TaskResult> {
    const startTime = Date.now();

    try {
      // Check if we have the required capabilities
      if (task.requiredCapabilities) {
        const missingCapabilities = task.requiredCapabilities.filter(
          cap => !this.hasCapability(cap)
        );
        if (missingCapabilities.length > 0) {
          return {
            taskId: task.id,
            agentId: this.metadata.id,
            status: 'failed',
            error: `Missing capabilities: ${missingCapabilities.join(', ')}`,
            duration: Date.now() - startTime
          };
        }
      }

      const result = await this.performTask(task);
      
      return {
        taskId: task.id,
        agentId: this.metadata.id,
        status: 'completed',
        result,
        duration: Date.now() - startTime
      };
    } catch (error) {
      return {
        taskId: task.id,
        agentId: this.metadata.id,
        status: 'failed',
        error: error instanceof Error ? error.message : 'Unknown error',
        duration: Date.now() - startTime
      };
    }
  }

  // ============================================================================
  // Abstract Methods - Must be implemented by subclasses
  // ============================================================================

  protected abstract handleRequest(message: AgentMessage): Promise<AgentResponse>;
  protected abstract handleEvent(message: AgentMessage): Promise<AgentResponse>;
  protected abstract performTask(task: AgentTask): Promise<unknown>;

  // ============================================================================
  // Helper Methods
  // ============================================================================

  protected createSuccessResponse<T>(
    data: T,
    reasoning?: string,
    suggestions?: string[],
    nextSteps?: string[]
  ): AgentResponse<T> {
    return {
      success: true,
      data,
      reasoning,
      suggestions,
      nextSteps
    };
  }

  protected createErrorResponse(code: string, message: string, details?: unknown): AgentResponse {
    return {
      success: false,
      error: {
        code,
        message,
        details
      }
    };
  }

  protected log(level: 'debug' | 'info' | 'warn' | 'error', message: string, data?: unknown): void {
    const timestamp = new Date().toISOString();
    const prefix = `[${timestamp}] [${this.metadata.id}] [${level.toUpperCase()}]`;
    
    if (data) {
      console.log(`${prefix} ${message}`, data);
    } else {
      console.log(`${prefix} ${message}`);
    }
  }
}

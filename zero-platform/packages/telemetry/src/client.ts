import type { TelemetryEvent, ActionModalShownEvent, ActionTakenEvent, ActionUndoneEvent } from './events';

export interface TelemetryConfig {
  endpoint: string;
  flushIntervalMs?: number;
  maxQueueSize?: number;
}

export class ActionTelemetryClient {
  private queue: TelemetryEvent[] = [];
  private flushInterval: number;
  private maxQueueSize: number;
  private timer?: ReturnType<typeof setInterval>;

  constructor(private readonly config: TelemetryConfig) {
    this.flushInterval = config.flushIntervalMs ?? 30000;
    this.maxQueueSize = config.maxQueueSize ?? 100;
    this.startFlushTimer();
  }

  trackModalShown(event: Omit<ActionModalShownEvent, 'eventType' | 'timestamp'>): string {
    const eventId = crypto.randomUUID();
    this.enqueue({
      eventType: 'action_modal_shown',
      timestamp: new Date(),
      ...event,
    });
    return eventId;
  }

  trackActionTaken(
    modalEventId: string,
    event: Omit<ActionTakenEvent, 'eventType' | 'timestamp' | 'modalEventId'>
  ): void {
    this.enqueue({
      eventType: 'action_taken',
      timestamp: new Date(),
      modalEventId,
      ...event,
    });
  }

  trackUndo(actionEventId: string, event: Omit<ActionUndoneEvent, 'eventType' | 'timestamp' | 'actionEventId'>): void {
    this.enqueue({
      eventType: 'action_undone',
      timestamp: new Date(),
      actionEventId,
      ...event,
    });
  }

  async flush(): Promise<void> {
    if (this.queue.length === 0) return;
    const batch = this.queue.splice(0, this.queue.length);
    try {
      await fetch(this.config.endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ events: batch }),
      });
    } catch (error) {
      // Requeue to avoid data loss
      this.queue.unshift(...batch);
    }
  }

  private enqueue(event: TelemetryEvent): void {
    this.queue.push(event);
    if (this.queue.length >= this.maxQueueSize) {
      void this.flush();
    }
  }

  private startFlushTimer(): void {
    this.timer = setInterval(() => {
      void this.flush();
    }, this.flushInterval);
  }
}



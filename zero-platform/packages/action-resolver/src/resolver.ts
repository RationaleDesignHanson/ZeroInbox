import {
  type ActionResolutionInput,
  type ActionResolutionResult,
  type ResolvedAction,
  type ActionType,
} from '@zero/core-types';

const DEFAULT_UNDO_WINDOW = 8;

export class ActionResolver {
  resolve(input: ActionResolutionInput): ActionResolutionResult {
    const primaryAction = this.mapIntentToAction(input);
    const alternatives = this.buildAlternatives(primaryAction.type, input);

    return {
      primaryAction,
      alternativeActions: alternatives,
    };
  }

  private mapIntentToAction(input: ActionResolutionInput): ResolvedAction {
    const { intent, email, userPreferences } = input;
    const type = this.intentToAction(intent.primaryIntent.type, userPreferences.archiveOrDelete);

    return {
      id: `${type}-${email.id}`,
      type,
      label: this.labelFor(type),
      icon: this.iconFor(type),
      confidence: intent.confidence,
      parameters: this.parametersFor(type, userPreferences),
      requiresConfirmation: this.requiresConfirmation(type, userPreferences),
      undoable: true,
      undoWindowSeconds: this.undoWindow(type, input.availableActions),
    };
  }

  private buildAlternatives(primary: ActionType, input: ActionResolutionInput): ResolvedAction[] {
    const altTypes: ActionType[] = ['star', 'snooze', 'archive'].filter((t) => t !== primary) as ActionType[];
    return altTypes.map((type) => ({
      id: `${type}-${input.email.id}`,
      type,
      label: this.labelFor(type),
      icon: this.iconFor(type),
      confidence: Math.max(0.4, input.intent.confidence - 0.1),
      parameters: this.parametersFor(type, input.userPreferences),
      requiresConfirmation: this.requiresConfirmation(type, input.userPreferences),
      undoable: true,
      undoWindowSeconds: this.undoWindow(type, input.availableActions),
    }));
  }

  private intentToAction(intent: ActionType | string, archiveOrDelete: 'archive' | 'delete'): ActionType {
    if (intent === 'delete') return archiveOrDelete === 'delete' ? 'delete' : 'archive';
    if (intent === 'archive' || intent === 'snooze' || intent === 'star') return intent as ActionType;
    return 'archive';
  }

  private labelFor(type: ActionType): string {
    const labels: Record<ActionType, string> = {
      archive: 'Archive',
      delete: 'Delete',
      snooze: 'Snooze',
      move_to_folder: 'Move to Folder',
      label: 'Label',
      reply: 'Reply',
      reply_all: 'Reply All',
      forward: 'Forward',
      create_task: 'Create Task',
      create_event: 'Create Event',
    };
    return labels[type] ?? type;
  }

  private iconFor(type: ActionType): string {
    const icons: Partial<Record<ActionType, string>> = {
      archive: 'archive',
      delete: 'trash',
      star: 'star',
      snooze: 'clock',
    };
    return icons[type] ?? 'bolt';
  }

  private parametersFor(type: ActionType, prefs: ActionResolutionInput['userPreferences']) {
    if (type === 'snooze') {
      const snoozeUntil = new Date(Date.now() + prefs.defaultSnoozeTime * 60 * 1000);
      return { type: 'snooze', snoozeUntil, snoozePresets: [] as const };
    }
    return { type };
  }

  private requiresConfirmation(type: ActionType, prefs: ActionResolutionInput['userPreferences']): boolean {
    if (type === 'delete') return prefs.confirmDestructive;
    return false;
  }

  private undoWindow(type: ActionType, capabilities: ActionResolutionInput['availableActions']): number {
    const cap = capabilities.find((c) => c.type === type);
    return cap?.undoWindowSeconds ?? DEFAULT_UNDO_WINDOW;
  }
}



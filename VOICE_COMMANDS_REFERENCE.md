# Voice Commands Reference
## Zer0 Inbox - Complete Voice Command Vocabulary

**Version**: 1.0
**Date**: 2025-12-12
**Service**: VoiceNavigationService.swift

---

## Overview

This document defines the complete voice command vocabulary for hands-free email management in Zer0 Inbox. Commands are processed by `VoiceNavigationService` and are context-aware based on the current navigation state.

---

## Command Categories

### 📬 Inbox Commands
Used in idle or inbox summary state

| Command | Variations | Action | Example |
|---------|-----------|--------|---------|
| **Check inbox** | "check my inbox", "what's in my inbox", "inbox summary" | Read inbox summary (count + top 3 emails) | "Check my inbox" |
| **Read email [number]** | "read email number 2", "read first email", "open email three" | Read specific email with body | "Read email number 2" |

---

### 🧭 Navigation Commands
Used while reading an email

| Command | Variations | Action | Example |
|---------|-----------|--------|---------|
| **Next** | "next email", "go to next", "next one" | Navigate to next email in list | "Next email" |
| **Previous** | "previous email", "go back", "back", "last one" | Navigate to previous email | "Previous" |
| **Done** | "stop", "close", "exit", "I'm done" | Exit voice navigation mode | "Done" |

---

### ⚡️ Action Commands
Used while reading an email (requires confirmation)

| Command | Variations | Confirmation | Action | Example |
|---------|-----------|--------------|--------|---------|
| **Archive** | "archive this", "archive", "archive email" | Yes/No | Archive current email | "Archive this" |
| **Flag** | "flag this", "star this", "flag email" | Yes/No | Flag email as important | "Flag this" |
| **Delete** | "delete this", "delete email" | Yes/No | Delete email (destructive!) | "Delete this" |
| **Reply** | "reply", "reply to this" | Yes/No | Open voice reply mode | "Reply" |

---

### ✅ Confirmation Commands
Used after requesting a destructive action

| Command | Variations | Action | Example |
|---------|-----------|--------|---------|
| **Yes** | "yes", "confirm", "sure", "do it" | Execute action | "Yes" |
| **No** | "no", "cancel", "nevermind", "nope" | Cancel action | "No" |

---

## Command Processing by State

### State 1: Idle (Not Navigating)

**Available Commands**:
- ✅ "Check inbox" → Read inbox summary
- ✅ "Read email [number]" → Read specific email
- ❌ Navigation commands (next/previous) not available

**Voice Response to Unknown Command**:
> "I didn't understand. Try saying: Check my inbox, or Read first email."

**Example Flow**:
```
User: "Check my inbox"
Zer0: "You have 15 unread emails. Top priority:
       1. Quarterly Review Meeting from Sarah Chen.
       2. Your package has shipped from Amazon.
       3. You have 5 new LinkedIn connections from LinkedIn."

User: "Read email number 1"
Zer0: "Email: Quarterly Review Meeting. From Sarah Chen.
       Received 2 hours ago. This is a high priority email.
       Message: Your manager wants to schedule the quarterly review..."
```

---

### State 2: Inbox Summary

**Available Commands**:
- ✅ "Read email [number]" → Read specific email
- ✅ "Done" → Exit navigation
- ❌ Action commands (archive/flag) not available

**Voice Response to Unknown Command**:
> "Say: Read email number 2, or say Done to exit."

**Example Flow**:
```
[After inbox summary]
User: "Read email number 2"
Zer0: "Email: Your package has shipped. From Amazon..."
```

---

### State 3: Reading Email

**Available Commands**:
- ✅ "Next" / "Previous" → Navigate emails
- ✅ "Archive" / "Flag" / "Delete" / "Reply" → Actions (requires confirmation)
- ✅ "Done" → Exit navigation
- ❌ "Check inbox" (already in inbox)

**Voice Response to Unknown Command**:
> "Say: Archive, Flag, Reply, Next, Previous, or Done."

**Example Flow**:
```
[While reading email]
User: "Archive this"
Zer0: "Archive this email? Say Yes or No."

User: "Yes"
Zer0: "Email archived."
[Returns to reading mode, can navigate to next email]

User: "Next email"
Zer0: "Email: You have 5 new LinkedIn connections. From LinkedIn..."
```

---

### State 4: Confirming Action

**Available Commands**:
- ✅ "Yes" → Execute action
- ✅ "No" → Cancel action
- ❌ All other commands ignored (waiting for confirmation)

**Voice Response to Unknown Command**:
> "Say Yes to confirm, or No to cancel."

**Timeout**: 5 seconds (configurable)
- After 5 seconds with no response, action is automatically cancelled

**Example Flow**:
```
User: "Delete this"
Zer0: "Delete this email? This cannot be undone. Say Yes or No."

User: "No"
Zer0: "Cancelled."
[Returns to reading email]

User: "Archive"
Zer0: "Archive this email? Say Yes or No."

User: "Yes"
Zer0: "Email archived."
```

---

## Number Recognition

### Supported Formats

**Word Numbers**:
- "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"
- "first", "second", "third"

**Digit Numbers**:
- "1", "2", "3", ... "99"

**Examples**:
- "Read email number three" → Email at index 2 (0-indexed internally)
- "Read email 5" → Email at index 4
- "Read first email" → Email at index 0

### Edge Cases

| Input | Behavior |
|-------|----------|
| "Read email" (no number) | Reads first email (index 0) |
| "Read email 999" (out of range) | "Email not found." |
| "Read email zero" | Not supported, ignored |

---

## Command Variations & Synonyms

### Archive Synonyms
- "archive", "archive this", "archive email", "archive it"

### Flag Synonyms
- "flag", "flag this", "star", "star this", "flag email", "star email"

### Navigation Synonyms
- **Next**: "next", "next email", "go to next", "next one"
- **Previous**: "previous", "previous email", "go back", "back", "last one"

### Confirmation Synonyms
- **Yes**: "yes", "confirm", "sure", "do it", "yeah"
- **No**: "no", "cancel", "nevermind", "nope", "don't"

---

## Command Recognition Settings

### Confidence Threshold
**Default**: 0.7 (70% confidence required)

Commands below this threshold are ignored.

**Adjustable in**:
```swift
VoiceNavigationService.shared.config.minConfidenceScore = 0.8  // Higher = more strict
```

### Debounce Interval
**Default**: 0.5 seconds

Duplicate commands within this interval are ignored (prevents accidental double-triggering).

**Adjustable in**:
```swift
VoiceNavigationService.shared.config.commandDebounceInterval = 1.0  // Longer = more forgiving
```

### Confirmation Timeout
**Default**: 5 seconds

Time to wait for "yes" or "no" after requesting confirmation. After timeout, action is cancelled.

**Adjustable in**:
```swift
VoiceNavigationService.shared.config.confirmationTimeout = 10.0  // Longer = more time to decide
```

---

## Error Handling

### Speech Recognition Unavailable

**Cause**: User denied microphone permission

**Response**:
> "Speech recognition access denied. Enable in Settings."

**Action**: Show alert prompting user to go to Settings → Zer0 Inbox → Microphone

---

### Speech Recognition Failed

**Cause**: Network error (server-based recognition unavailable)

**Response**:
> "Speech recognition failed. Check your internet connection."

**Fallback**: Switch to on-device recognition (lower accuracy but works offline)

---

### Email Not Found

**Cause**: User requested email number out of range

**Response**:
> "Email not found."

**Action**: Prompt user to say valid number (1 to N)

---

### Unknown Command

**Cause**: Command not recognized or not valid in current state

**Response**:
- Idle: "I didn't understand. Try saying: Check my inbox, or Read first email."
- Inbox: "Say: Read email number 2, or say Done to exit."
- Reading: "Say: Archive, Flag, Reply, Next, Previous, or Done."
- Confirming: "Say Yes to confirm, or No to cancel."

**Action**: Continue listening for valid command

---

## Advanced Commands (Future)

### Not Yet Implemented

| Command | Purpose | ETA |
|---------|---------|-----|
| **Search [query]** | Voice search emails | Week 4 |
| **Filter [type]** | Filter by type (work, shopping, etc.) | Week 4 |
| **Compose email** | Start new email | Week 5 |
| **Undo** | Undo last action | Week 5 |
| **Repeat** | Repeat last TTS output | Week 3 |
| **Pause** | Pause current TTS | Week 3 |

---

## Testing Commands

### Development Mode Commands

**Enable in debug builds only:**

```swift
#if DEBUG
    if command.contains("test mode") {
        // Activate test features
    }
#endif
```

| Command | Action | Purpose |
|---------|--------|---------|
| "Test mode" | Enable debug logging | See detailed command processing |
| "Show state" | Speak current state | Debugging state machine |
| "Reset" | Return to idle state | Quick reset during testing |

---

## Accessibility Considerations

### Voice Commands for Accessibility

All voice commands work with VoiceOver enabled.

**Recommended Settings**:
- VoiceOver: On
- Speech rate: 0.5 (natural pace)
- Confirmation timeout: 10 seconds (longer for accessibility users)

### Alternative Input

Users who cannot use voice can:
- Use on-screen buttons (added in Week 7 integration)
- Use Siri Shortcuts (activatable via Shortcuts app)
- Use EMG gestures (Week 5-6, for users with speech limitations)

---

## Localization (Future)

### Supported Languages (Planned)

| Language | Speech Recognizer | TTS Voice | ETA |
|----------|-------------------|-----------|-----|
| English (US) | ✅ Implemented | ✅ Implemented | Week 1 |
| English (UK) | Supported | Supported | Week 8 |
| Spanish | Supported | Supported | Week 10 |
| French | Supported | Supported | Week 10 |

**Note**: Speech recognizer must match TTS language for best UX.

---

## Command Cheat Sheet (Quick Reference)

### 🚀 Getting Started
```
"Hey Siri, open Zer0"
→ "Start voice navigation"
→ "Check my inbox"
```

### 📬 Reading Inbox
```
"Check my inbox" → Hear summary
"Read email number 2" → Read specific email
"Read first email" → Read email #1
```

### 🧭 Navigating
```
"Next email" → Go to next
"Previous email" → Go back
"Done" → Exit
```

### ⚡️ Actions
```
"Archive this" → Archive (requires "Yes")
"Flag this" → Flag (requires "Yes")
"Reply" → Start reply (requires "Yes")
```

### ✅ Confirmations
```
"Yes" → Confirm action
"No" → Cancel action
```

---

## Integration with Siri Shortcuts

### Triggering Voice Navigation via Siri

**User can say**:
> "Hey Siri, check my Zer0 inbox"

**Zer0 responds with**:
> "You have 15 unread emails. Top priority: ..."

**Then enters voice navigation mode automatically.**

**Setup** (Week 2):
- Donate `NSUserActivity` for "Check Inbox"
- Siri learns user's phrase
- Shortcut triggers `VoiceNavigationService.startNavigation()`

---

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| **Command recognition accuracy** | >80% | TBD (Week 2 testing) |
| **Latency (command → response)** | <1 second | TBD |
| **False positive rate** | <5% | TBD |
| **Timeout handling** | 100% | TBD |

---

## Troubleshooting

### "I didn't understand" (Repeated)

**Possible Causes**:
1. Background noise too loud
2. Speaking too fast/slow
3. Microphone issue
4. Network issue (server recognition)

**Solutions**:
1. Move to quieter environment
2. Speak clearly at normal pace
3. Check microphone permissions
4. Check internet connection

---

### Commands Not Triggering Actions

**Possible Causes**:
1. Wrong state (e.g., saying "Next" in idle state)
2. Confidence score too low
3. Action callback not set

**Solutions**:
1. Check current state (say "Show state" in debug mode)
2. Lower confidence threshold
3. Verify `actionCallback` is set in production integration

---

## Command History (Debugging)

**View command history**:
```swift
let history = VoiceNavigationService.shared._testGetCommandHistory()
for (command, timestamp) in history {
    print("\(timestamp): \(command)")
}
```

**Clear history**:
```swift
VoiceNavigationService.shared._testClearHistory()
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-12 | Initial command vocabulary defined |

---

**Next Review**: Week 3 (after initial testing)
**Owner**: Matt Hanson
**Status**: Ready for testing

# EMG Gesture Control Specification
## Zer0 Inbox Wearables - Neural Interface Design

**Version**: 1.0
**Date**: 2025-12-12
**Status**: Specification Phase (Implementation Week 5-6)

---

## Overview

This document specifies the EMG (electromyography) gesture control interface for Zer0 Inbox wearables. EMG enables hands-free email management through neural wristband detection of muscle movements.

**Target Hardware**:
- Meta EMG Wristband (if available via developer partnership)
- Meta Ray-Ban with integrated EMG sensors (future)
- Meta Oakley with EMG support (future)

**Fallback**: iPhone touch gesture simulator for testing without physical EMG hardware.

---

## Gesture Vocabulary

### Primary Gestures

#### 1. **Pinch** (Thumb + Index Finger)
**Detection**: Muscle contraction in thumb and index finger
**Action**: Archive current email
**Confirmation**: Required (prevents accidental archives)
**Flow**:
1. User pinches thumb + index
2. System speaks: "Archive this email?"
3. User pinches again to confirm (within 5 seconds)
4. Email archived, system speaks: "Archived"

**Confidence Threshold**: > 0.85 (high confidence required)

---

#### 2. **Double Pinch** (Two Quick Pinches)
**Detection**: Two pinch gestures within 500ms
**Action**: Flag/star email as important
**Confirmation**: Not required (non-destructive)
**Flow**:
1. User double-pinches
2. Email flagged immediately
3. System speaks: "Flagged" (or haptic feedback on watch)

**Confidence Threshold**: > 0.80

---

#### 3. **Swipe Left** (Wrist Rotation Left)
**Detection**: Wrist rotation ~30° counterclockwise
**Action**: Next email in list
**Confirmation**: Not required
**Flow**:
1. User rotates wrist left
2. System navigates to next email
3. Begins reading next email automatically

**Confidence Threshold**: > 0.75

---

#### 4. **Swipe Right** (Wrist Rotation Right)
**Detection**: Wrist rotation ~30° clockwise
**Action**: Previous email in list
**Confirmation**: Not required
**Flow**:
1. User rotates wrist right
2. System navigates to previous email
3. Begins reading previous email

**Confidence Threshold**: > 0.75

---

#### 5. **Hold** (Sustained Pinch for 2 Seconds)
**Detection**: Pinch gesture maintained for 2+ seconds
**Action**: Open voice compose / reply mode
**Confirmation**: Not required
**Flow**:
1. User holds pinch for 2 seconds
2. System vibrates (haptic feedback)
3. System speaks: "Recording your reply"
4. Voice input activated
5. Release pinch to send, or pinch again to cancel

**Confidence Threshold**: > 0.85

---

#### 6. **Tap** (Single Quick Pinch < 150ms)
**Detection**: Very brief pinch gesture
**Action**: Toggle AR display on/off
**Confirmation**: Not required
**Flow**:
1. User taps (quick pinch)
2. AR display toggles visibility
3. No audio feedback (visual only)

**Confidence Threshold**: > 0.80

---

## Secondary Gestures (Future)

#### 7. **Swipe Up** (Arm Raise)
**Action**: Mark email as unread
**Status**: Planned for v2

#### 8. **Swipe Down** (Arm Lower)
**Action**: Delete email
**Status**: Planned for v2 (requires confirmation)

---

## Gesture Recognition Pipeline

```
┌─────────────────────────────────────────────────────────┐
│                    EMG Hardware Layer                   │
│  (Meta Wristband or Integrated Sensors)                │
└─────────────────┬──────────────────────────────────────┘
                  │
                  │ Raw EMG Signals (mV)
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│              Signal Processing                          │
│  - Noise filtering (bandpass 20-450 Hz)                │
│  - Baseline calibration                                 │
│  - Feature extraction (amplitude, frequency)           │
└─────────────────┬──────────────────────────────────────┘
                  │
                  │ Processed Features
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│           Gesture Classification                        │
│  - ML model (trained on user data)                     │
│  - Confidence scoring (0.0 - 1.0)                      │
│  - Temporal pattern matching                           │
└─────────────────┬──────────────────────────────────────┘
                  │
                  │ Recognized Gesture + Confidence
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│          EMGGestureRecognizer.swift                     │
│  - Confidence thresholding                             │
│  - Gesture debouncing (prevent duplicates)             │
│  - State validation (context-aware)                    │
└─────────────────┬──────────────────────────────────────┘
                  │
                  │ Validated Gesture Event
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│         Action Handler / App Logic                      │
│  - Archive email, navigate, reply, etc.                │
│  - Audio/haptic feedback                               │
│  - Analytics logging                                   │
└─────────────────────────────────────────────────────────┘
```

---

## EMG Simulator (iPhone Fallback)

For testing without physical EMG hardware, we map iPhone touch gestures to EMG events:

| EMG Gesture | iPhone Simulator Gesture |
|-------------|--------------------------|
| **Pinch** | Two-finger pinch on screen (reverse pinch-to-zoom) |
| **Double Pinch** | Double-tap with two fingers |
| **Swipe Left** | Three-finger swipe left |
| **Swipe Right** | Three-finger swipe right |
| **Hold** | Long press with two fingers (2s) |
| **Tap** | Single tap with two fingers |

**Implementation**: `Zero/Services/EMGSimulator.swift`

**Activation**: Enabled automatically when no EMG hardware detected.

---

## Confidence Thresholds

| Gesture | Threshold | Rationale |
|---------|-----------|-----------|
| **Pinch** | 0.85 | High confidence needed (destructive action with confirmation) |
| **Double Pinch** | 0.80 | Medium-high confidence (non-destructive, but intentional) |
| **Swipe Left/Right** | 0.75 | Medium confidence (easily undone by swiping opposite direction) |
| **Hold** | 0.85 | High confidence (initiates voice recording) |
| **Tap** | 0.80 | Medium-high confidence (toggle action, easily reversed) |

**Tuning**: Thresholds can be adjusted per-user via calibration flow.

---

## Gesture Timing Constraints

| Gesture | Timing Constraint | Purpose |
|---------|-------------------|---------|
| **Double Pinch** | 2 pinches within 500ms | Distinguish from two single pinches |
| **Tap** | Pinch duration < 150ms | Distinguish from hold |
| **Hold** | Pinch duration ≥ 2000ms | Prevent accidental activation |
| **Debounce** | 300ms cooldown between gestures | Prevent duplicate detections |
| **Confirmation Timeout** | 5 seconds | How long to wait for confirmation after archive request |

---

## Context-Aware Gesture Handling

Gestures behave differently depending on app state:

| State | Pinch | Swipe Left/Right | Hold |
|-------|-------|------------------|------|
| **Inbox Summary** | Not available | Navigate emails (read next/prev) | Not available |
| **Reading Email** | Archive email | Navigate to next/prev email | Reply to email |
| **Voice Compose** | Cancel/send | Not available | Not available |
| **Idle** | Not available | Not available | Activate voice navigation |

---

## Error Handling

### Low Confidence Detection
If gesture confidence < threshold:
- Ignore gesture (no action)
- No feedback to user
- Log to analytics for model improvement

### Conflicting Gestures
If two gestures detected simultaneously:
- Choose gesture with higher confidence
- If confidence difference < 0.1, ignore both
- Log ambiguity for debugging

### Hardware Disconnect
If EMG hardware disconnects mid-gesture:
- Cancel in-progress gesture
- Fall back to iPhone touch controls
- Show visual notification: "EMG disconnected"

### False Positives
To minimize accidental actions:
- Use confirmation for destructive actions (archive, delete)
- Implement adaptive thresholds based on user behavior
- Allow "undo" for all non-destructive actions (flag, mark unread)

---

## Calibration Flow

**When**: First time EMG hardware is connected, or on demand via Settings

**Process**:
1. **Baseline Measurement** (10 seconds)
   - "Relax your hand"
   - Measure resting muscle activity

2. **Gesture Training** (5 gestures × 3 repetitions)
   - "Pinch your thumb and index finger" (repeat 3 times)
   - "Rotate your wrist left" (repeat 3 times)
   - etc.

3. **Confidence Adjustment**
   - Analyze user's gesture strength
   - Adjust thresholds if needed (e.g., weaker gestures → lower threshold)

4. **Validation Test**
   - Perform 5 random gestures
   - Must achieve 100% accuracy to complete calibration

**Duration**: ~2 minutes

**Recalibration**: Recommended every 2 weeks or if accuracy drops below 80%

---

## Accessibility Considerations

### Alternative Input Methods
Users who cannot perform EMG gestures can use:
- Voice commands only (no gestures required)
- Apple Watch Digital Crown for navigation
- iPhone touch controls

### Gesture Sensitivity
Adjustable in Settings:
- **Low Sensitivity**: Higher confidence thresholds (fewer false positives)
- **Medium Sensitivity**: Default thresholds
- **High Sensitivity**: Lower confidence thresholds (better for weak gestures)

---

## Performance Requirements

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Latency** (gesture → action) | < 200ms | Feels instantaneous to user |
| **Accuracy** | > 90% | Confident gesture recognition |
| **False Positive Rate** | < 5% | Minimize accidental actions |
| **Battery Impact** | < 5% per hour | EMG processing is power-efficient |

---

## Analytics & Telemetry

**Track the following** (anonymized):
- Gesture type usage frequency
- Gesture confidence distribution
- False positive rate per gesture
- Calibration completion rate
- Hardware disconnect frequency

**Purpose**: Improve ML model, optimize thresholds, identify UX issues

---

## Implementation Roadmap

### Week 5-6: Core Implementation
1. **Create EMGGesture Model** (`Models/EMGGesture.swift`)
   - Enum for gesture types
   - Confidence score property
   - Timestamp

2. **Implement EMGGestureRecognizer** (`Services/EMGGestureRecognizer.swift`)
   - Integrate with Meta SDK (if available)
   - Confidence thresholding
   - Debouncing logic
   - Context-aware handling

3. **Implement EMGSimulator** (`Services/EMGSimulator.swift`)
   - Map iPhone touch gestures to EMG events
   - Use UIGestureRecognizer subclasses
   - Simulate confidence scores (0.8-0.95)

4. **Integrate with Voice Navigation**
   - Connect gestures to VoiceNavigationService
   - Add haptic feedback for confirmations
   - Audio cues for gesture detection

### Week 7-8: Testing & Refinement
- User testing with EMG simulator
- Threshold tuning based on feedback
- Edge case handling
- Performance optimization

---

## Open Questions

1. **Meta SDK Availability**: Is EMG SDK accessible to developers?
   - **Action**: Research Meta developer portal, request access

2. **Calibration Storage**: Where to store user calibration data?
   - **Proposal**: Encrypted in Keychain (per-device)

3. **Multi-Device Sync**: Should calibration sync across devices?
   - **Proposal**: No - calibration is device-specific (different wristbands)

---

## References

- [Meta EMG Research Paper](https://research.facebook.com/publications/emg-based-gesture-recognition/)
- [Apple Core Motion Framework](https://developer.apple.com/documentation/coremotion)
- [Gesture Recognition Best Practices](https://developer.apple.com/design/human-interface-guidelines/gestures)

---

**Document Owner**: Matt Hanson / Claude Code
**Review Date**: Week 4 (before implementation begins)
**Status**: Approved for implementation

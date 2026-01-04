# Zer0 Inbox Wearables Implementation Guide

**Project**: Zer0 Inbox Email Client
**Platforms**: Apple Watch, Ray-Ban Meta Glasses (Audio + AR), EMG Control
**Timeline**: 8 weeks to beta readiness
**Status**: Week 1 - Foundation Phase

---

## Table of Contents

1. [Overview](#overview)
2. [Week 1-2: Foundation](#week-1-2-foundation)
3. [Week 3-4: Core Features](#week-3-4-core-features)
4. [Week 5-6: Advanced Integration](#week-5-6-advanced-integration)
5. [Week 7-8: Beta Prep](#week-7-8-beta-prep)
6. [Testing Guide](#testing-guide)
7. [Hardware Requirements](#hardware-requirements)

---

## Overview

### Current State Analysis

**Strengths**:
- ✅ iOS widgets implemented with lock screen support
- ✅ Widget families already compatible with watchOS (`accessoryCircular`, `accessoryRectangular`, `accessoryInline`)
- ✅ App Group configured: `group.com.zero.email`
- ✅ Voice input (speech-to-text) working in SmartReplyView.swift
- ✅ Siri Shortcuts complete but dormant (SiriShortcutsService.swift)
- ✅ SwiftUI throughout (watch-compatible)
- ✅ Lightweight WidgetEmail model (perfect for wearables)

**Gaps**:
- ❌ No watchOS target or extension
- ❌ No WatchConnectivity implementation
- ❌ No audio output (TTS) for voice-first
- ❌ No background sync
- ❌ No AR display support
- ❌ No EMG gesture integration

---

## Week 1-2: Foundation

### Task 1: Enable watchOS Target for Widgets

**Current Status**: ✅ Widgets already use watchOS-compatible families

The existing widgets in `Widgets/ZeroWidget.swift` support:
- `.accessoryCircular` → Watch complication (circular)
- `.accessoryRectangular` → Watch complication (rectangular/modular)
- `.accessoryInline` → Watch complication (inline text)

**Steps to Enable on watchOS 10+**:

1. **Open Xcode Project**:
   ```bash
   open /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Zero.xcodeproj
   ```

2. **Select Widget Extension Target**:
   - In Xcode, select the `ZeroWidget` target (or `ZeroWidgetExtension`)
   - Go to **General** → **Deployment Info**
   - Click the **+** button under "Supported Destinations"
   - Add **watchOS** (version 10.0 or later)

3. **Verify App Group Entitlements**:
   - Ensure `group.com.zero.email` is enabled for watchOS target
   - Navigate to **Signing & Capabilities** → **App Groups**
   - Should already be configured if shared with iOS widget

4. **Build for watchOS Simulator**:
   ```bash
   cd /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero
   xcodebuild -scheme "ZeroWidget" -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' -configuration Debug
   ```

**Expected Outcome**: Widgets compile for watchOS and can be added to watch faces as complications.

---

### Task 2: Implement VoiceOutputService (Text-to-Speech)

**File**: `Zero/Services/VoiceOutputService.swift`

**Purpose**: Enable email reading aloud for voice-first experience (Ray-Ban Meta simulation via AirPods)

**Key Features**:
- Text-to-speech email reading
- Inbox summary narration
- Bluetooth audio routing (AirPods, Meta glasses)
- Interruption handling
- Progress tracking

**Implementation**: See `VoiceOutputService.swift` (created below)

**Testing**:
1. Connect AirPods Pro
2. Run app on iPhone
3. Navigate to inbox
4. Trigger voice output
5. Verify audio routes to AirPods
6. Test pause/resume/stop controls

---

### Task 3: Document EMG Gesture Mapping

**File**: `WEARABLES_EMG_SPEC.md` (created below)

**Gesture Mapping**:
- **Pinch** (thumb + index): Archive email
- **Double Pinch**: Flag/star email
- **Swipe Left** (wrist rotation): Next email
- **Swipe Right**: Previous email
- **Hold 2s**: Open voice reply
- **Tap**: Toggle AR display

**Simulator Fallback** (for testing without EMG hardware):
- Two-finger pinch on iPhone screen = EMG pinch
- Swipe gestures = EMG wrist rotation
- Long press = EMG hold

---

## Week 3-4: Core Features

### Task 1: WatchConnectivityManager

**File**: `Zero/Services/WatchConnectivityManager.swift`

**Purpose**: Bidirectional communication between iPhone and Apple Watch

**Features**:
- Send inbox data to watch
- Receive action requests from watch (archive, flag)
- Background message queuing
- Reachability monitoring
- Offline caching

**Testing**:
1. Pair watchOS simulator with iOS simulator
2. Archive email on watch → verify iPhone reflects change within 5s
3. Test with iPhone backgrounded
4. Test with watch out of range (use cached data)

---

### Task 2: VoiceNavigationService

**File**: `Zero/Services/VoiceNavigationService.swift`

**Purpose**: Hands-free email management via voice commands

**State Machine**:
- `idle` → Waiting for command
- `inboxSummary` → Reading inbox summary
- `readingEmail(index)` → Reading specific email
- `confirmingAction` → Confirming destructive action

**Voice Commands**:
- "Check my inbox" → Inbox summary
- "Read email number 2" → Read email
- "Next email" → Navigate
- "Archive this" → Archive with confirmation
- "Reply" → Voice compose mode

---

## Week 5-6: Advanced Integration

### Task 1: Meta Glasses Audio Integration

**File**: `Zero/Services/MetaGlassesAdapter.swift`

**Purpose**: Route audio to Ray-Ban Meta speakers (or simulate with AirPods)

**Audio Session Configuration**:
```swift
try audioSession.setCategory(
    .playback,
    mode: .voicePrompt,
    options: [.allowBluetooth, .allowBluetoothA2DP]
)
```

---

### Task 2: AR Display Service

**File**: `Zero/Services/ARDisplayService.swift`

**Purpose**: Render glanceable email UI on Meta monocular displays

**UI Elements**:
- Persistent inbox count (top-right corner)
- Email notification overlay (5s duration)
- Full email detail view
- Action icons (archive, flag, reply)

**Design Constraints**:
- High contrast (readable in sunlight)
- Large text (monocular ~1-2m focal distance)
- Peripheral placement (non-intrusive)
- Battery-conscious (minimize display time)

---

### Task 3: EMG Gesture Recognizer

**File**: `Zero/Services/EMGGestureRecognizer.swift`

**Purpose**: Detect EMG gestures for hands-free control

**Fallback Simulator**:
**File**: `Zero/Services/EMGSimulator.swift`

Maps iPhone touch gestures to EMG events for testing without Meta EMG wristband.

---

## Week 7-8: Beta Prep

### Testing Checklist

**Apple Watch**:
- [ ] Complications display on all watch faces
- [ ] Inbox count updates within 15 minutes
- [ ] Archive action syncs to iPhone < 5s
- [ ] App works offline (cached data)
- [ ] Battery drain < 5%/hour
- [ ] Memory usage < 50MB

**Voice-First**:
- [ ] Audio routes to AirPods/Meta glasses
- [ ] Command accuracy > 80%
- [ ] Hands-free navigation completes full flow
- [ ] Battery drain < 10%/hour
- [ ] Interruption handling works

**AR Display**:
- [ ] Overlay readable in bright sunlight
- [ ] Text size appropriate for monocular
- [ ] Notifications non-intrusive
- [ ] Battery impact acceptable

**EMG Control**:
- [ ] Gesture accuracy > 90%
- [ ] False positive rate < 5%
- [ ] Latency < 200ms
- [ ] Works while walking

---

## Hardware Requirements

### Week 1-2 (Simulators)
- iOS Simulator (iPhone 15 Pro, iOS 17+)
- watchOS Simulator (Apple Watch Series 9, watchOS 10+)
- AirPods Pro (for voice testing)

### Week 3+ (Physical Devices)
- **Apple Watch Series 6+** (~$300-400 used) - Required for complication testing
- **Ray-Ban Meta Wayfarer** (~$299) - Audio-only testing
- **iPhone 15 Pro** - WatchConnectivity requires iOS 17+

### Week 5+ (Advanced - Optional)
- **Ray-Ban Meta with AR display** (future product or Meta Orion developer kit)
- **Meta EMG Wristband** (may require developer partnership)

**Total Est. Cost**: $600-1000

---

## File Structure

```
Zero/
├── Services/
│   ├── VoiceOutputService.swift          ← Week 1-2
│   ├── VoiceNavigationService.swift      ← Week 3-4
│   ├── WatchConnectivityManager.swift    ← Week 3-4 (iOS + watchOS)
│   ├── MetaGlassesAdapter.swift          ← Week 5-6
│   ├── ARDisplayService.swift            ← Week 5-6
│   ├── EMGGestureRecognizer.swift        ← Week 5-6
│   └── EMGSimulator.swift                ← Week 5-6
├── Widgets/
│   ├── ZeroWidget.swift                  ← Already exists (add watchOS target)
│   ├── InboxWidgetProvider.swift         ← Already exists
│   └── InboxWidgetView.swift             ← Already exists
├── Views/
│   └── AR/
│       ├── EmailNotificationOverlay.swift   ← Week 5-6
│       └── InboxCountWidget.swift           ← Week 5-6
└── Models/
    └── EMGGesture.swift                  ← Week 5-6

Zer0Watch/                                ← New watchOS target (Week 3-4)
├── Zer0WatchApp.swift
├── Views/
│   ├── InboxView.swift
│   ├── EmailDetailView.swift
│   └── QuickActionsView.swift
└── Complications/
    └── InboxComplicationProvider.swift
```

---

## Xcode Configuration Checklist

### App Groups (Must Be Enabled on All Targets)
- [x] iOS App: `group.com.zero.email`
- [x] iOS Widget Extension: `group.com.zero.email`
- [ ] watchOS App: `group.com.zero.email` ← **Add in Week 3**
- [ ] watchOS Widget Extension: `group.com.zero.email` ← **Add in Week 1**

### Capabilities
- [ ] **Siri & Shortcuts**: Enable for voice commands (Week 1-2)
- [ ] **Background Modes**: Remote notifications, Background fetch (Week 5-6)
- [ ] **WatchConnectivity**: Enable for iPhone ↔ Watch sync (Week 3-4)

### Info.plist Additions
```xml
<!-- Speech Recognition Permission -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>Zer0 needs speech recognition for hands-free email management</string>

<!-- Microphone Permission (already exists for voice input) -->
<key>NSMicrophoneUsageDescription</key>
<string>Zer0 needs microphone access for voice commands</string>

<!-- Bluetooth Permission (for Meta glasses) -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Zer0 connects to your smart glasses for hands-free email</string>
```

---

## Performance Targets

| Metric | Target | Critical Path |
|--------|--------|---------------|
| **Watch Complication Update** | < 15 min | Background sync → WatchConnectivity |
| **Watch Action Sync** | < 5 sec | WCSession.sendMessage() |
| **Voice Command Response** | < 1 sec | Speech recognition → TTS |
| **EMG Gesture Latency** | < 200ms | Gesture detection → Action |
| **Battery Drain (Watch)** | < 5%/hour | Optimize complication refresh rate |
| **Battery Drain (Voice)** | < 10%/hour | Efficient audio session management |
| **Memory (Watch App)** | < 50MB | Lightweight models, cache pruning |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Meta SDK unavailable** | High | Medium | Build ARKit simulator, document for future |
| **EMG hardware inaccessible** | High | Low | Create touch-based simulator |
| **WatchConnectivity unreliable** | Medium | High | Implement robust retry + offline caching |
| **Voice accuracy < 80%** | Medium | High | Add visual confirmation UI |
| **Timeline slips** | Medium | Medium | Feature-flag wearables, ship incrementally |

---

## Next Steps (Immediate)

1. ✅ **Enable watchOS target** for ZeroWidget (1 hour)
   - Open Xcode → ZeroWidget target → Add watchOS deployment

2. **Implement VoiceOutputService** (4-6 hours)
   - Create `Services/VoiceOutputService.swift`
   - Implement TTS for inbox summary
   - Test with AirPods

3. **Test widgets on watchOS simulator** (2 hours)
   ```bash
   # Pair simulators
   xcrun simctl list devices
   xcrun simctl pair <watch-udid> <iphone-udid>

   # Run widget
   xcodebuild -scheme "ZeroWidget" -destination 'platform=watchOS Simulator...'
   ```

4. **Document EMG gestures** (2 hours)
   - Create specification doc
   - Design simulator fallback

---

## Success Criteria (Week 1-2)

- [ ] Widgets compile for watchOS target
- [ ] Widgets display on watch simulator
- [ ] Inbox count updates when iOS app updates data
- [ ] TTS reads inbox summary through AirPods
- [ ] Voice command accuracy > 70% (basic commands)
- [ ] EMG gesture spec documented

**Deliverables**: Working widgets on watch simulator, TTS via AirPods, EMG spec doc

---

**Document Version**: 1.0
**Last Updated**: 2025-12-12
**Owner**: Matt Hanson / Claude Code

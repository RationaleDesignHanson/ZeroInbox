# Wearables Integration Roadmap
## Zero - Production Integration Plan

**Version**: 1.0
**Date**: 2025-12-12
**Strategy**: Build foundation separately, integrate once, avoid rework
**Status**: Foundation Phase (Week 1-6) → Integration Phase (Week 7-8)

---

## Philosophy

**Build First, Integrate Later**
- ✅ All wearables features built as standalone, testable services
- ✅ Zero modifications to production app during development
- ✅ Comprehensive documentation of integration points
- ✅ Single integration event in Week 7-8 when foundation complete
- ✅ Easy rollback if needed

**Avoid Rework**
- Document every integration point now
- Define prerequisites before building
- Test services in isolation first
- Integrate with confidence, not experimentation

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Service Dependency Graph](#service-dependency-graph)
3. [Foundation Services (Week 1-6)](#foundation-services-week-1-6)
4. [Integration Points](#integration-points)
5. [Integration Sequence (Week 7-8)](#integration-sequence-week-7-8)
6. [Testing Strategy](#testing-strategy)
7. [Rollback Plan](#rollback-plan)
8. [Success Criteria](#success-criteria)

---

## Architecture Overview

### Wearables Foundation Stack

```
┌─────────────────────────────────────────────────────────┐
│                   Production App                        │
│               (Untouched until Week 7)                  │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  InboxView   │  │ EmailDetail  │  │  SettingsView│ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
                          │ Integration Layer (Week 7)
                          │
┌─────────────────────────────────────────────────────────┐
│              Wearables Foundation Services              │
│               (Built Week 1-6, Isolated)                │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  VoiceOutputService (Week 1) ✅                  │  │
│  │  - TTS engine, Bluetooth routing, email reading │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  VoiceNavigationService (Week 2-3)               │  │
│  │  - Command processing, state machine, hands-free│  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  WatchConnectivityManager (Week 3-4)             │  │
│  │  - iPhone ↔ Watch sync, message queue, cache    │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  MetaGlassesAdapter (Week 5-6)                   │  │
│  │  - Meta SDK wrapper, audio routing, AR display  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  ARDisplayService (Week 5-6)                     │  │
│  │  - Monocular overlay, notification rendering    │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  EMGGestureRecognizer (Week 5-6)                 │  │
│  │  - Gesture detection, confidence scoring         │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Service Dependency Graph

### Dependencies (Must Build in Order)

```
VoiceOutputService (Week 1)
    ↓ depends on
VoiceNavigationService (Week 2-3)
    ↓ depends on
MetaGlassesAdapter (Week 5-6)

---

WatchConnectivityManager (Week 3-4)
    ↓ uses
WidgetDataService (existing) ✅

---

ARDisplayService (Week 5-6)
    ↓ uses
MetaGlassesAdapter (Week 5-6)

---

EMGGestureRecognizer (Week 5-6)
    ↓ triggers
VoiceNavigationService (Week 2-3)
```

**Critical Path**: VoiceOutput → VoiceNavigation → Meta Integration

---

## Foundation Services (Week 1-6)

### Service 1: VoiceOutputService ✅
**Status**: Complete (Week 1)
**File**: `Services/VoiceOutputService.swift`
**LOC**: 450

**Capabilities**:
- Text-to-speech for email reading
- Bluetooth audio routing
- Inbox summary narration
- Playback controls (pause/resume/stop)
- Speech rate configuration

**Testing**: Standalone via `VoiceTestView.swift`

**Integration Points**:
- InboxView: "Read Inbox" button
- EmailDetailView: "Read Email" button
- SettingsView: Speech rate preference

**Prerequisites**: None (complete)

---

### Service 2: VoiceNavigationService
**Status**: Not Started (Week 2-3)
**File**: `Services/VoiceNavigationService.swift`
**Est. LOC**: 400

**Capabilities**:
- Voice command recognition
- State machine (idle → inboxSummary → readingEmail → confirmingAction)
- Command processing ("next", "archive", "reply")
- Confirmation flow for destructive actions

**Dependencies**:
- ✅ VoiceOutputService (for TTS responses)
- Speech framework (for STT)

**Testing**: Standalone via `VoiceNavigationTestView.swift` (to be created)

**Integration Points**:
- InboxView: Voice navigation mode toggle
- EmailDetailView: Voice commands enabled
- Global: Hands-free mode

**Prerequisites**:
- VoiceOutputService complete ✅
- Design command vocabulary
- Define state transitions

---

### Service 3: WatchConnectivityManager
**Status**: Not Started (Week 3-4)
**Files**:
- `Services/WatchConnectivityManager.swift` (iOS)
- `Zer0Watch/Services/WatchConnectivityManager.swift` (watchOS)
**Est. LOC**: 300 (iOS) + 200 (watchOS)

**Capabilities**:
- Bidirectional iPhone ↔ Watch communication
- Message queuing and retry
- Reachability monitoring
- Offline caching
- Background updates

**Dependencies**:
- ✅ WidgetDataService (existing)
- ✅ App Groups configured

**Testing**:
- Paired simulators
- Physical devices (Week 3+)

**Integration Points**:
- AppLifecycleObserver: Setup WCSession on launch
- InboxViewModel: Push updates to watch
- EmailService: Queue watch actions

**Prerequisites**:
- watchOS app target created
- WCSession delegate implemented
- Data models serializable

---

### Service 4: MetaGlassesAdapter
**Status**: Not Started (Week 5-6)
**File**: `Services/MetaGlassesAdapter.swift`
**Est. LOC**: 250

**Capabilities**:
- Meta SDK integration
- Audio routing to glasses speakers
- AR display coordination
- Wake word detection

**Dependencies**:
- ✅ VoiceOutputService
- ✅ VoiceNavigationService
- Meta SDK (external)

**Testing**:
- AirPods Pro fallback
- Physical Ray-Ban Meta (Week 5+)

**Integration Points**:
- VoiceOutputService: Override audio routing
- ARDisplayService: Trigger display rendering
- AppLifecycleObserver: Initialize on launch

**Prerequisites**:
- Meta SDK available/documented
- Bluetooth permissions configured
- Audio session advanced setup

---

### Service 5: ARDisplayService
**Status**: Not Started (Week 5-6)
**File**: `Services/ARDisplayService.swift`
**Est. LOC**: 300

**Capabilities**:
- Render email notifications on monocular display
- Persistent inbox count widget
- Glanceable email cards
- Action icons (archive/flag/reply)

**Dependencies**:
- MetaGlassesAdapter (for display access)
- Meta Display API or ARKit fallback

**Testing**:
- ARKit simulator (iPhone)
- Physical Meta glasses with display (if available)

**Integration Points**:
- EmailService: Trigger notification on new email
- VoiceNavigationService: Show visual confirmation
- SettingsView: AR display preferences

**Prerequisites**:
- Display API available
- UI designs finalized
- Rendering pipeline tested

---

### Service 6: EMGGestureRecognizer
**Status**: Not Started (Week 5-6)
**File**: `Services/EMGGestureRecognizer.swift`
**Est. LOC**: 400

**Capabilities**:
- Detect 6 primary gestures (pinch, double-pinch, swipe, hold, tap)
- Confidence scoring
- Debouncing and validation
- Calibration support

**Dependencies**:
- Meta EMG SDK or custom ML model
- VoiceNavigationService (to trigger actions)

**Testing**:
- `EMGSimulator.swift` (iPhone touch gestures)
- Physical EMG hardware (if available)

**Integration Points**:
- VoiceNavigationService: Gesture → Command mapping
- EmailDetailView: Gesture shortcuts
- SettingsView: Calibration UI

**Prerequisites**:
- EMG SDK available
- Gesture vocabulary finalized
- Confidence thresholds tuned

---

## Integration Points

### Production Views to Modify (Week 7-8 ONLY)

#### 1. InboxView
**File**: `Views/Feed/InboxView.swift` (assumed path)

**Additions**:
```swift
// Add voice service
@StateObject private var voiceService = VoiceOutputService.shared
@StateObject private var voiceNav = VoiceNavigationService.shared

// Add toolbar button
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
            Button("Read Inbox", systemImage: "speaker.wave.2") {
                readInboxAloud()
            }
            Button("Voice Navigation", systemImage: "waveform.circle") {
                startVoiceNavigation()
            }
        } label: {
            Image(systemName: "speaker.wave.2")
        }
    }
}

// Add methods
private func readInboxAloud() { ... }
private func startVoiceNavigation() { ... }
```

**Lines Added**: ~30
**Risk**: Low (additive only, no existing code modified)

---

#### 2. EmailDetailView
**File**: `Views/Detail/EmailDetailView.swift` (assumed path)

**Additions**:
```swift
// Add voice service
@StateObject private var voiceService = VoiceOutputService.shared

// Add read button in toolbar or bottom bar
Button("Read Aloud") {
    voiceService.readEmail(email, includeBody: true)
}
.buttonStyle(.bordered)
```

**Lines Added**: ~15
**Risk**: Low (additive only)

---

#### 3. AppLifecycleObserver
**File**: `Services/AppLifecycleObserver.swift`

**Additions**:
```swift
// Setup watch connectivity
#if os(iOS)
func setupWatchConnectivity() {
    WatchConnectivityManager.shared.activate()
}
#endif

// Call in init or app launch
```

**Lines Added**: ~10
**Risk**: Low (initialization code only)

---

#### 4. SettingsView
**File**: `Views/Settings/SettingsView.swift` (assumed path)

**Additions**:
```swift
// Wearables section
Section("Wearables") {
    Toggle("Voice Commands", isOn: $voiceEnabled)

    Picker("Speech Rate", selection: $speechRate) {
        Text("Slow").tag(0.4)
        Text("Normal").tag(0.5)
        Text("Fast").tag(0.6)
    }

    NavigationLink("Calibrate EMG Gestures") {
        EMGCalibrationView()
    }
}
```

**Lines Added**: ~30
**Risk**: Low (new section only)

---

#### 5. ServiceContainer
**File**: `DI/ServiceContainer.swift`

**Additions**:
```swift
// Register wearables services
let voiceOutput = VoiceOutputService.shared
let voiceNav = VoiceNavigationService.shared
let watchConnectivity = WatchConnectivityManager.shared
let metaGlasses = MetaGlassesAdapter.shared
```

**Lines Added**: ~5
**Risk**: Low (DI registration)

---

### Total Integration Impact

| File | Lines Added | Risk Level | Rollback Ease |
|------|-------------|------------|---------------|
| InboxView | ~30 | Low | Easy (delete block) |
| EmailDetailView | ~15 | Low | Easy (delete block) |
| AppLifecycleObserver | ~10 | Low | Easy (comment out) |
| SettingsView | ~30 | Low | Easy (delete section) |
| ServiceContainer | ~5 | Low | Easy (comment out) |
| **Total** | **~90 lines** | **Low** | **Easy** |

**Impact**: <100 lines of code added, zero existing lines modified

---

## Integration Sequence (Week 7-8)

### Phase 1: Core Voice (Day 1)
**Goal**: Get basic voice output working in production

1. **Add VoiceOutputService to InboxView**
   - Add toolbar button
   - Implement `readInboxAloud()` method
   - Test with real inbox data

2. **Add VoiceOutputService to EmailDetailView**
   - Add "Read Aloud" button
   - Test with various email types

3. **Test voice output on physical device**
   - Connect AirPods
   - Verify audio routing
   - Check battery drain

**Success Criteria**:
- [ ] Voice buttons appear in UI
- [ ] Inbox summary reads correctly
- [ ] Email reading works with body
- [ ] No crashes or audio issues

**Rollback**: Delete toolbar buttons, remove voice service references

---

### Phase 2: Voice Navigation (Day 2-3)
**Goal**: Enable hands-free email management

1. **Add VoiceNavigationService to InboxView**
   - Add "Voice Navigation" mode toggle
   - Implement command processing
   - Test state transitions

2. **Integrate with EmailDetailView**
   - Enable voice commands for actions
   - Add confirmation flow

3. **Test full voice flow**
   - Start from inbox
   - Navigate via voice
   - Archive email via voice

**Success Criteria**:
- [ ] Voice commands recognized (>80% accuracy)
- [ ] State machine works correctly
- [ ] Actions execute properly
- [ ] No stuck states

**Rollback**: Disable voice navigation toggle, hide menu option

---

### Phase 3: Watch Integration (Day 4-5)
**Goal**: Sync inbox data to Apple Watch

1. **Initialize WatchConnectivityManager**
   - Add to AppLifecycleObserver
   - Setup session delegate
   - Test activation

2. **Connect to InboxViewModel**
   - Push inbox updates to watch
   - Handle watch actions (archive, flag)
   - Test bidirectional sync

3. **Test on paired devices**
   - Archive on watch → iPhone updates
   - New email → watch complication updates
   - Offline/cache behavior

**Success Criteria**:
- [ ] Watch receives inbox data
- [ ] Actions sync correctly (<5 seconds)
- [ ] Offline mode works
- [ ] No connectivity errors

**Rollback**: Comment out WatchConnectivity initialization

---

### Phase 4: Meta Glasses (Day 6-7)
**Goal**: Route audio to Meta glasses, enable AR display

1. **Initialize MetaGlassesAdapter**
   - Detect glasses connection
   - Route audio to glasses speakers
   - Test audio quality

2. **Enable AR Display (if available)**
   - Render inbox count widget
   - Show email notifications
   - Test glanceable design

3. **Test on physical Meta glasses**
   - Voice commands via glasses
   - AR display readability
   - Battery impact

**Success Criteria**:
- [ ] Audio routes to glasses
- [ ] Wake word detection works (if supported)
- [ ] AR display renders correctly (if available)
- [ ] No audio glitches

**Rollback**: Fallback to AirPods audio routing

---

### Phase 5: EMG Gestures (Day 8)
**Goal**: Enable gesture-based email management

1. **Initialize EMGGestureRecognizer**
   - Connect to Meta EMG hardware (or simulator)
   - Map gestures to actions
   - Test recognition accuracy

2. **Integrate with VoiceNavigationService**
   - Gesture → Command pipeline
   - Confirmation flow for destructive gestures
   - Test all 6 gestures

3. **Test on physical hardware**
   - Pinch to archive
   - Swipe to navigate
   - Hold to reply

**Success Criteria**:
- [ ] Gestures recognized (>90% accuracy)
- [ ] Low false positive rate (<5%)
- [ ] Latency <200ms
- [ ] Works while walking

**Rollback**: Use EMGSimulator (touch gestures) only

---

### Phase 6: Polish & Settings (Day 9-10)
**Goal**: Add user preferences and polish

1. **Add Settings UI**
   - Speech rate preference
   - Voice gender preference
   - EMG calibration
   - Feature toggles

2. **Add onboarding**
   - First-time voice setup
   - Permissions explanation
   - EMG calibration flow

3. **Final testing**
   - End-to-end flows
   - Performance profiling
   - Bug fixes

**Success Criteria**:
- [ ] All settings work
- [ ] Onboarding clear
- [ ] No major bugs
- [ ] Performance acceptable

---

## Testing Strategy

### Isolation Testing (Week 1-6)

**Each service tested independently BEFORE integration:**

#### VoiceOutputService ✅
- Test via `VoiceTestView.swift`
- No production app needed
- Mock data only

#### VoiceNavigationService
- Test via `VoiceNavigationTestView.swift` (to create)
- Uses VoiceOutputService
- Mock email data

#### WatchConnectivityManager
- Test via paired simulators
- Mock message passing
- Verify cache/retry logic

#### MetaGlassesAdapter
- Test via AirPods fallback
- Verify audio routing
- Mock SDK responses

#### ARDisplayService
- Test via ARKit preview (iPhone)
- Render test overlays
- Verify layout/readability

#### EMGGestureRecognizer
- Test via `EMGSimulator.swift`
- iPhone touch gestures
- Measure accuracy

**Goal**: Every service at 90%+ complete before integration

---

### Integration Testing (Week 7)

**Test in production app with real data:**

#### Test Suite 1: Voice Basic
- [ ] Read inbox summary (real emails)
- [ ] Read individual email
- [ ] Pause/resume/stop controls
- [ ] Speech rate adjustment

#### Test Suite 2: Voice Navigation
- [ ] Start voice navigation mode
- [ ] Navigate through emails ("next", "previous")
- [ ] Archive email via voice
- [ ] Reply via voice dictation

#### Test Suite 3: Watch Sync
- [ ] Archive on watch → iPhone updates
- [ ] New email → watch notifies
- [ ] Offline mode (watch cached data)
- [ ] Complications update

#### Test Suite 4: Meta Glasses
- [ ] Audio routes to glasses
- [ ] Voice commands work
- [ ] AR notifications (if available)
- [ ] Battery acceptable

#### Test Suite 5: EMG Gestures
- [ ] All 6 gestures recognized
- [ ] Low false positive rate
- [ ] Latency acceptable
- [ ] Works in motion

---

### Regression Testing (Week 7-8)

**Ensure existing features still work:**

- [ ] Inbox loads correctly
- [ ] Email detail displays correctly
- [ ] Archive/flag/delete work
- [ ] Search works
- [ ] Filters work
- [ ] No performance degradation
- [ ] No new crashes

**If ANY regression found**: Rollback immediately

---

## Rollback Plan

### Instant Rollback (If Critical Issue)

**Feature Flags** (recommended approach):
```swift
// In build config or environment
#if ENABLE_WEARABLES
    // All wearables code here
#endif
```

**To disable**: Set `ENABLE_WEARABLES = false` and rebuild

---

### Service-Level Rollback

**If specific service causes issues, disable independently:**

```swift
// In ServiceContainer or AppLifecycleObserver
let disableVoice = true  // Set to true to disable
let disableWatch = true
let disableMetaGlasses = true
let disableEMG = true

if !disableVoice {
    VoiceOutputService.shared.activate()
}
```

---

### Code-Level Rollback

**All wearables code in clearly marked blocks:**

```swift
// ============================================
// WEARABLES INTEGRATION - START
// Added: 2025-12-12 (Week 7)
// Can be safely removed if needed
// ============================================

// ... wearables code here ...

// WEARABLES INTEGRATION - END
// ============================================
```

**To rollback**: Search for markers and delete blocks

---

### Git Rollback

**All wearables work on feature branch:**
```bash
git checkout main  # Switch back to main
# Or
git revert <commit-hash>  # Undo specific integration commit
```

---

## Success Criteria

### Foundation Phase (Week 1-6)
- [ ] All 6 services implemented
- [ ] Each service tested in isolation
- [ ] All documentation complete
- [ ] No production app modifications

### Integration Phase (Week 7-8)
- [ ] <100 lines of code added to production
- [ ] Zero existing lines modified
- [ ] All integration tests pass
- [ ] No regressions detected
- [ ] Performance acceptable
- [ ] Rollback plan tested

### Beta Launch (Week 8+)
- [ ] 10 beta testers using wearables features
- [ ] >80% voice command accuracy
- [ ] <5% crash rate
- [ ] Positive user feedback
- [ ] Battery drain acceptable

---

## Documentation Checklist

### Before Integration (Complete by Week 6)
- [ ] All service APIs documented
- [ ] Integration points identified
- [ ] Prerequisites listed
- [ ] Testing procedures written
- [ ] Rollback plan documented
- [ ] Common issues & fixes listed

### During Integration (Week 7-8)
- [ ] Integration progress tracked
- [ ] Issues logged
- [ ] Decisions documented
- [ ] Code comments added
- [ ] README updated

### After Integration (Week 8+)
- [ ] Final architecture documented
- [ ] Performance benchmarks recorded
- [ ] Known issues listed
- [ ] Future improvements noted
- [ ] Lessons learned captured

---

## Communication Plan

### Weekly Check-ins
**Every Monday**: Review progress against roadmap
**Every Friday**: Document blockers and decisions

### Integration Week (Week 7)
**Daily standup**: Morning sync on integration progress
**Daily wrap-up**: Evening summary of completed integrations

### Stakeholder Updates
**Week 4**: Foundation 50% complete
**Week 6**: Foundation 100% complete, ready for integration
**Week 7**: Integration in progress
**Week 8**: Beta launch

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Owner |
|------|------------|--------|------------|-------|
| **Meta SDK unavailable** | High | Medium | Use ARKit fallback, document for future | Dev |
| **EMG hardware inaccessible** | High | Low | Use touch simulator, works without hardware | Dev |
| **Integration breaks existing features** | Low | High | Comprehensive regression testing, easy rollback | QA |
| **Voice accuracy <80%** | Medium | Medium | Add visual confirmations, improve error handling | Dev |
| **Watch connectivity unreliable** | Medium | Medium | Robust retry logic, offline caching | Dev |
| **Timeline slips** | Low | Low | Feature flags allow partial launch | PM |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-12-12 | Initial roadmap created | Claude Code |

---

**Next Review**: Week 4 (Foundation 50% checkpoint)
**Owner**: Matt Hanson
**Status**: Approved for execution

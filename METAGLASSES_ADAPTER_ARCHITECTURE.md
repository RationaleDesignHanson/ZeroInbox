# MetaGlasses Adapter Architecture
## Ray-Ban Meta Smart Glasses Integration

**Version**: 1.0
**Date**: 2025-12-12
**Status**: Architecture Complete, Ready for Implementation
**Implementation**: Week 5-6

---

## Table of Contents

1. [Overview](#overview)
2. [Meta Glasses Capabilities](#meta-glasses-capabilities)
3. [Architecture Design](#architecture-design)
4. [Audio Routing System](#audio-routing-system)
5. [AR Display Integration](#ar-display-integration)
6. [SDK Integration Strategy](#sdk-integration-strategy)
7. [Fallback Mechanisms](#fallback-mechanisms)
8. [Implementation Plan](#implementation-plan)

---

## Overview

### Purpose

Integrate Zer0 Inbox with Meta Ray-Ban smart glasses ecosystem, enabling:
- **Audio Output**: Route voice output to glasses speakers
- **Audio Input**: Capture voice commands via glasses microphones
- **AR Display**: Show email notifications on monocular displays (if available)
- **Camera Integration**: Capture photos/videos for email attachments (future)
- **Wake Word**: Activate with "Hey Meta" or custom wake word

### Target Devices

| Device | Audio | AR Display | Camera | Status |
|--------|-------|------------|--------|--------|
| **Ray-Ban Meta Wayfarer** | ✅ Yes | ❌ No | ✅ Yes | Available Now |
| **Ray-Ban Meta Headliner** | ✅ Yes | ❌ No | ✅ Yes | Available Now |
| **Ray-Ban Stories (Gen 1)** | ✅ Yes | ❌ No | ✅ Yes | Legacy Support |
| **Meta Oakley (Future)** | ✅ Yes | ✅ Yes | ✅ Yes | Roadmap 2024-2025 |
| **Meta Orion (AR)** | ✅ Yes | ✅ Yes | ✅ Yes | Developer Preview |

---

## Meta Glasses Capabilities

### Current Generation (Ray-Ban Meta Wayfarer/Headliner)

#### Audio System
- **Speakers**: Open-ear speakers (no earbuds)
- **Audio Quality**: Good for voice, acceptable for music
- **Microphones**: 5-microphone array with beamforming
- **Noise Cancellation**: Yes (for input)
- **Directional Audio**: Limited spatial audio

#### Controls
- **Physical Buttons**: Power, volume, capture
- **Touch Controls**: Swipe on temple (play/pause, skip)
- **Voice Commands**: "Hey Meta" wake word

#### Connectivity
- **Bluetooth**: 5.2
- **Range**: ~30 feet (10 meters)
- **Battery Life**: 4-6 hours active use
- **Charging Case**: Provides 3-4 additional charges

#### Camera
- **Resolution**: 12MP photos, 1080p video
- **Field of View**: ~90 degrees
- **Capture Modes**: Photo, video (30s/60s/90s), Live streaming
- **Storage**: 32GB internal

---

### Future Generation (Oakley + Orion)

#### AR Display (Monocular)
- **Display Type**: Waveguide projector
- **Resolution**: ~720p equivalent
- **Field of View**: ~45 degrees
- **Brightness**: 2000+ nits (sunlight visible)
- **Refresh Rate**: 60Hz+
- **Position**: Right eye (adjustable)

#### Enhanced Audio
- **Spatial Audio**: 3D positioning
- **ANC**: Active noise cancellation for speakers
- **Bone Conduction**: Backup audio channel

#### Advanced Controls
- **EMG Wristband**: Neural input (gestures)
- **Eye Tracking**: Gaze-based UI navigation
- **Voice**: Enhanced NLU with on-device processing

---

## Architecture Design

### Component Overview

```
┌─────────────────────────────────────────────────────┐
│            Zero iOS App                             │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  MetaGlassesAdapter                          │  │
│  │  - Device detection                          │  │
│  │  - Connection management                     │  │
│  │  - Audio routing orchestration               │  │
│  │  - AR display coordination                   │  │
│  └────────────┬─────────────────────────────────┘  │
│               │                                     │
└───────────────┼─────────────────────────────────────┘
                │
                │ Bluetooth / Meta SDK
                │
┌───────────────┼─────────────────────────────────────┐
│               │                                     │
│  ┌────────────▼──────────────────────────────────┐  │
│  │  Ray-Ban Meta Glasses Firmware               │  │
│  │  - Audio playback/recording                  │  │
│  │  - AR display rendering (if available)       │  │
│  │  - Camera control                            │  │
│  │  - Button/touch input                        │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│           Ray-Ban Meta Glasses                      │
└─────────────────────────────────────────────────────┘
```

### Service Architecture

```
MetaGlassesAdapter
├── Device Management
│   ├── Discovery (scan for glasses)
│   ├── Pairing (Bluetooth connection)
│   ├── Capability detection (audio/AR/camera)
│   └── Battery monitoring
│
├── Audio Subsystem
│   ├── Audio routing (route to glasses speakers)
│   ├── Microphone access (capture commands)
│   ├── Wake word detection ("Hey Meta")
│   └── Audio quality optimization
│
├── AR Display Subsystem (if available)
│   ├── Display capability detection
│   ├── Render pipeline coordination
│   ├── Layout management (monocular constraints)
│   └── Brightness/contrast adjustment
│
├── Camera Subsystem (future)
│   ├── Photo/video capture
│   ├── Attachment creation
│   └── Privacy indicators
│
└── SDK Abstraction Layer
    ├── Meta SDK wrapper (primary)
    ├── CoreBluetooth fallback
    └── AVAudioSession integration
```

---

## Audio Routing System

### Audio Session Configuration

```swift
// Optimized for Meta glasses
try audioSession.setCategory(
    .playAndRecord,              // Bidirectional audio
    mode: .voiceChat,            // Optimized for voice
    options: [
        .allowBluetooth,
        .allowBluetoothA2DP,
        .defaultToSpeaker,       // Fallback to iPhone speaker if needed
        .mixWithOthers           // Allow other app audio
    ]
)
```

### Audio Route Priority

**Routing Priority** (highest to lowest):
1. Meta Glasses (if connected and available)
2. AirPods Pro (if connected)
3. Other Bluetooth headphones
4. iPhone speaker (fallback)

**Route Selection Logic**:
```swift
func selectAudioRoute() -> AudioRoute {
    // Check for Meta glasses
    if isMetaGlassesConnected && isMetaGlassesAudioAvailable {
        return .metaGlasses
    }

    // Check for AirPods (good for testing)
    if isAirPodsConnected {
        return .airPods
    }

    // Check for generic Bluetooth
    if isBluetoothHeadphonesConnected {
        return .bluetooth
    }

    // Fallback to speaker
    return .speaker
}
```

### Audio Output Characteristics

| Route | Latency | Quality | Suitability |
|-------|---------|---------|-------------|
| **Meta Glasses** | ~40ms | Good | ✅ Excellent for voice |
| **AirPods Pro** | ~200ms | Excellent | ✅ Good for testing |
| **iPhone Speaker** | ~10ms | Good | ⚠️ Not hands-free |

---

## AR Display Integration

### Display Capability Detection

```swift
struct GlassesCapabilities {
    let hasAudioOutput: Bool
    let hasAudioInput: Bool
    let hasARDisplay: Bool           // Ray-Ban Meta: false, Oakley/Orion: true
    let hasCam: Bool
    let hasEMG: Bool

    let displayResolution: CGSize?   // e.g., (1280, 720) for monocular
    let displayFOV: Float?           // Field of view in degrees
    let displayBrightness: Float?    // Max brightness in nits
}
```

### AR Display Modes

#### Mode 1: No Display (Current Ray-Ban Meta)
- Audio-only interaction
- Voice output via speakers
- Voice input via microphones
- No visual UI

**UX**:
```
User: "Check my inbox"
Glasses: 🔊 "You have 15 unread emails. Top priority..."
```

#### Mode 2: With Display (Future Oakley/Orion)
- Audio + visual interaction
- Email notifications shown on monocular display
- Persistent inbox count widget
- Action icons for EMG gestures

**UX**:
```
User: "Check my inbox"
Glasses: 🔊 "You have 15 unread emails."
Display: ┌─────────────┐
         │  📧 15      │  ← Top-right corner
         │             │
         │ Meeting     │  ← Notification
         │ Sarah Chen  │
         └─────────────┘
```

### Display Rendering Pipeline

```
┌─────────────────────────────────────────┐
│  ARDisplayService                       │
│  - Generate display content             │
│  - Layout for monocular constraints     │
│  - Render to texture/buffer             │
└──────────────┬──────────────────────────┘
               │
               │ Display data (PNG/buffer)
               │
┌──────────────▼──────────────────────────┐
│  MetaGlassesAdapter                     │
│  - Send to glasses firmware             │
│  - Adjust brightness/contrast           │
│  - Handle display lifecycle             │
└──────────────┬──────────────────────────┘
               │
               │ Meta SDK / Display API
               │
┌──────────────▼──────────────────────────┐
│  Glasses Firmware                       │
│  - Waveguide projection                 │
│  - Display on right eye lens            │
└─────────────────────────────────────────┘
```

---

## SDK Integration Strategy

### Primary: Meta SDK (When Available)

```swift
#if canImport(MetaGlassesSDK)
import MetaGlassesSDK

// Official SDK usage
let glassesManager = MetaGlassesManager.shared
glassesManager.connect { result in
    switch result {
    case .success(let device):
        // Connected
    case .failure(let error):
        // Handle error
    }
}

// Audio routing via SDK
glassesManager.setAudioOutput(.speakers)

// AR display (if available)
if glassesManager.capabilities.hasDisplay {
    glassesManager.displayContent(image)
}
#endif
```

**SDK Features** (Hypothetical - based on common smart glasses SDKs):
- Device discovery and pairing
- Audio routing control
- Display rendering (if available)
- Camera control
- Button/touch event handling
- Battery status
- Firmware updates

**SDK Availability**:
- **Status**: Developer program access required
- **Request**: Apply at [Meta Developer Portal](https://developers.facebook.com/)
- **Alternative**: Use CoreBluetooth fallback

---

### Fallback: CoreBluetooth + AVAudioSession

**If Meta SDK unavailable, use standard iOS frameworks:**

```swift
// Device discovery via CoreBluetooth
let centralManager = CBCentralManager()
centralManager.scanForPeripherals(
    withServices: [metaGlassesServiceUUID]
)

// Audio routing via AVAudioSession
let audioSession = AVAudioSession.sharedInstance()
try audioSession.setCategory(.playAndRecord, mode: .voiceChat)

// Route will automatically prefer Bluetooth A2DP
let currentRoute = audioSession.currentRoute
if currentRoute.outputs.contains(where: { $0.portType == .bluetoothA2DP }) {
    // Audio is routed to glasses
}
```

**Limitations of Fallback**:
- ❌ No AR display control (not accessible via standard APIs)
- ❌ No camera control (requires Meta SDK)
- ❌ No button/touch events (no SDK integration)
- ✅ Audio routing works (standard Bluetooth)
- ✅ Microphone access works (standard AVAudioEngine)

---

## Fallback Mechanisms

### Tier 1: Full Meta SDK Integration
**Capabilities**: Audio + AR Display + Camera + Controls
**Requirements**: Meta SDK, developer partnership
**Best For**: Production release with full features

### Tier 2: Audio-Only (CoreBluetooth)
**Capabilities**: Audio output + microphone input
**Requirements**: Standard iOS frameworks
**Best For**: MVP, testing without SDK

### Tier 3: AirPods Simulation
**Capabilities**: Audio output + microphone input
**Requirements**: AirPods Pro
**Best For**: Development and testing

### Tier 4: iPhone Speaker (No Glasses)
**Capabilities**: Audio output + microphone input
**Requirements**: None
**Best For**: Fallback, accessibility

### Fallback Decision Tree

```
1. Is Meta SDK available?
   ├─ Yes → Use Meta SDK (Tier 1)
   └─ No → Continue

2. Are Meta glasses connected (Bluetooth)?
   ├─ Yes → Use CoreBluetooth audio routing (Tier 2)
   └─ No → Continue

3. Are AirPods connected?
   ├─ Yes → Use AirPods (Tier 3)
   └─ No → Use iPhone speaker (Tier 4)
```

---

## Implementation Plan

### Phase 1: Audio-Only (Week 5, Days 1-3)

**Goal**: Route voice output to Meta glasses speakers

**Tasks**:
1. Implement `MetaGlassesAdapter.swift` skeleton
2. Add Bluetooth device discovery
3. Implement audio routing logic
4. Test with real Ray-Ban Meta glasses
5. Fallback to AirPods if no glasses

**Deliverable**: Audio plays through glasses speakers

---

### Phase 2: Voice Input (Week 5, Days 4-5)

**Goal**: Capture voice commands via glasses microphones

**Tasks**:
1. Integrate glasses microphone with Speech framework
2. Test wake word detection ("Hey Meta")
3. Integrate with VoiceNavigationService
4. Test command recognition through glasses

**Deliverable**: Full voice navigation via glasses

---

### Phase 3: AR Display (Week 6, Days 1-4)

**Goal**: Show email notifications on monocular display (if hardware available)

**Tasks**:
1. Detect AR display capability
2. Integrate ARDisplayService
3. Render inbox count widget
4. Render email notifications
5. Test on AR-capable glasses (Oakley/Orion)

**Deliverable**: Visual notifications on glasses display

---

### Phase 4: Polish & Optimization (Week 6, Days 5-7)

**Goal**: Optimize battery, latency, UX

**Tasks**:
1. Battery optimization (reduce audio latency)
2. Error handling (connection loss, low battery)
3. User preferences (enable/disable AR, adjust volume)
4. Analytics (track usage, battery drain)

**Deliverable**: Production-ready glasses integration

---

## MetaGlassesAdapter API Design

### Public Interface

```swift
@MainActor
class MetaGlassesAdapter: NSObject, ObservableObject {
    static let shared = MetaGlassesAdapter()

    // MARK: - Published State

    @Published var isConnected: Bool = false
    @Published var capabilities: GlassesCapabilities?
    @Published var batteryLevel: Float?  // 0.0 - 1.0
    @Published var connectionError: String?

    // MARK: - Public API

    /// Start scanning for Meta glasses
    func startScanning()

    /// Connect to specific glasses
    func connect(to device: DiscoveredDevice) async throws

    /// Disconnect from glasses
    func disconnect()

    /// Route audio to glasses (if connected)
    func enableAudioOutput() throws

    /// Capture audio from glasses microphone
    func startAudioInput(completion: @escaping (String) -> Void)

    /// Show content on AR display (if available)
    func displayContent(_ content: ARDisplayContent) async throws

    /// Dismiss AR display content
    func dismissDisplay()

    // MARK: - Delegates

    weak var delegate: MetaGlassesAdapterDelegate?
}

protocol MetaGlassesAdapterDelegate: AnyObject {
    func glassesDidConnect(_ glasses: MetaGlassesAdapter)
    func glassesDidDisconnect(_ glasses: MetaGlassesAdapter)
    func glassesButtonPressed(_ button: GlassesButton)
    func glassesBatteryLow(_ level: Float)
}
```

---

## Testing Strategy

### Unit Tests
- [ ] Device discovery logic
- [ ] Capability detection
- [ ] Audio route selection
- [ ] Fallback logic

### Integration Tests

#### Test 1: Audio Routing
```swift
func testAudioRoutingToGlasses() async throws {
    // Connect to glasses
    try await adapter.connect(to: testGlasses)

    // Enable audio
    try adapter.enableAudioOutput()

    // Play test audio
    VoiceOutputService.shared.speak("Test audio")

    // Verify audio routes to glasses
    let route = AVAudioSession.sharedInstance().currentRoute
    XCTAssertTrue(route.outputs.contains { $0.portName.contains("Meta") })
}
```

#### Test 2: Voice Commands
```swift
func testVoiceCommandsViaGlasses() async throws {
    // Enable glasses microphone
    adapter.startAudioInput { recognizedText in
        XCTAssertEqual(recognizedText, "check my inbox")
    }

    // Simulate voice command
    // (Manual test: speak into glasses)
}
```

#### Test 3: AR Display (if available)
```swift
func testARDisplayRendering() async throws {
    guard adapter.capabilities?.hasARDisplay == true else {
        throw XCTSkip("AR display not available")
    }

    // Create display content
    let content = ARDisplayContent.inboxCount(15)

    // Display
    try await adapter.displayContent(content)

    // Verify displayed
    XCTAssertTrue(adapter.isDisplayingContent)
}
```

### Manual Tests (Physical Glasses)

| Test | Setup | Expected Result |
|------|-------|-----------------|
| **Pairing** | Turn on glasses, open app | App discovers and connects |
| **Audio Output** | Say "Check inbox" | Hear response through glasses |
| **Voice Input** | Say "Hey Meta, check inbox" | Command recognized |
| **Battery Indicator** | Check app | Shows glasses battery level |
| **Disconnect** | Turn off glasses | App shows disconnected state |
| **Reconnect** | Turn on glasses | App auto-reconnects |

---

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Audio Latency** | < 100ms | User presses button → hear audio |
| **Connection Time** | < 3 seconds | Start scan → connected |
| **Battery Impact (Glasses)** | < 10% per hour | Active voice usage |
| **Battery Impact (iPhone)** | < 2% per hour | With glasses connected |
| **Voice Recognition Accuracy** | > 80% | Via glasses microphone |
| **Range** | 30 feet | Reliable connection distance |

---

## Privacy & Security

### User Privacy

**Audio Recording**:
- ✅ Explicit permission required (microphone access)
- ✅ User can see when microphone is active (iOS status indicator)
- ✅ No recording stored locally (streaming to Speech API only)

**Camera Access** (future):
- ✅ Explicit permission required
- ✅ On-device processing preferred
- ✅ User notification when camera active

### Data Security

**Bluetooth Communication**:
- ✅ Encrypted (Bluetooth 5.2 standard)
- ✅ Authenticated pairing required
- ✅ No sensitive data sent over Bluetooth

**Cloud Communication** (if Meta SDK uses cloud):
- ⚠️ Review Meta SDK privacy policy
- ✅ Opt-in for cloud features
- ✅ Data minimization (only send necessary data)

---

## Dependencies

**Required Before Implementation**:
- ✅ VoiceOutputService complete
- ✅ VoiceNavigationService complete
- ⚪ Meta SDK access (optional, fallback available)
- ⚪ Physical Ray-Ban Meta glasses (Week 5)
- ⚪ ARDisplayService (for AR features)

**Required Before Integration** (Week 7):
- Audio session management in AppLifecycleObserver
- Settings toggle for "Enable Meta Glasses"
- Pairing UI in settings

---

## Future Enhancements (Post-MVP)

### Phase 2 Features
- [ ] Camera integration (photo attachments)
- [ ] EMG gesture support (via wristband)
- [ ] Live streaming integration
- [ ] Multi-glasses support (pair multiple)

### Phase 3 Features
- [ ] Spatial audio (directional TTS)
- [ ] Eye tracking (gaze-based UI)
- [ ] On-device AI (reduce cloud dependency)
- [ ] Cellular glasses support (no iPhone needed)

---

## References

- [Meta Ray-Ban Stories Product Page](https://www.meta.com/smart-glasses/)
- [Meta Developer Portal](https://developers.facebook.com/)
- [Ray-Ban Meta Specifications](https://www.meta.com/smart-glasses/ray-ban-meta/specs/)
- [Apple CoreBluetooth Framework](https://developer.apple.com/documentation/corebluetooth)
- [AVAudioSession Guide](https://developer.apple.com/documentation/avfoundation/avaudiosession)

---

**Status**: ✅ Architecture Complete
**Next Step**: Implement MetaGlassesAdapter.swift (Week 5)
**Dependencies**: VoiceOutput ✅, VoiceNavigation ✅, Physical glasses (Week 5)

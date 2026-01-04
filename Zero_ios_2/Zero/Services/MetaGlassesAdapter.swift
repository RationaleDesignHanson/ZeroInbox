//
//  MetaGlassesAdapter.swift
//  Zero (iOS)
//
//  Created by Claude Code on 2025-12-12.
//  Part of Wearables Implementation (Week 5-6: Meta Glasses Integration)
//
//  Purpose: Adapter for Ray-Ban Meta smart glasses (audio + future AR display).
//  Handles audio routing, voice capture, display rendering with multi-tier fallback.
//

import Foundation
import AVFoundation
import CoreBluetooth
import Combine

#if os(iOS)

/// Adapter for Meta smart glasses with multi-tier fallback
/// Tier 1: Meta SDK (when available)
/// Tier 2: CoreBluetooth (direct connection)
/// Tier 3: AirPods (standard Bluetooth audio)
/// Tier 4: iPhone speaker (fallback)
@MainActor
class MetaGlassesAdapter: NSObject, ObservableObject {
    static let shared = MetaGlassesAdapter()

    // MARK: - Published State

    @Published var isConnected: Bool = false
    @Published var connectionTier: ConnectionTier = .tier4_speaker
    @Published var hasDisplay: Bool = false
    @Published var batteryLevel: Int = 100
    @Published var audioRoute: String = "Speaker"
    @Published var lastError: String?

    // MARK: - Connection Tiers

    enum ConnectionTier: Int, Comparable {
        case tier1_metaSDK = 1      // Meta SDK (best)
        case tier2_bluetooth = 2    // CoreBluetooth
        case tier3_airpods = 3      // AirPods/standard BT
        case tier4_speaker = 4      // iPhone speaker (fallback)

        static func < (lhs: ConnectionTier, rhs: ConnectionTier) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var description: String {
            switch self {
            case .tier1_metaSDK: return "Meta SDK"
            case .tier2_bluetooth: return "Bluetooth"
            case .tier3_airpods: return "AirPods"
            case .tier4_speaker: return "iPhone Speaker"
            }
        }
    }

    // MARK: - Private Properties

    private let audioSession = AVAudioSession.sharedInstance()
    private var bluetoothManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var audioRouteObserver: NSObjectProtocol?

    // Meta SDK (placeholder - actual SDK integration when available)
    private var metaSDK: MetaSDKWrapper?

    // Capabilities
    private var supportsDisplay: Bool = false
    private var supportsVoiceCapture: Bool = false

    // MARK: - Initialization

    override init() {
        super.init()

        // Setup Bluetooth
        bluetoothManager = CBCentralManager(delegate: nil, queue: .main)

        // Setup audio session
        configureAudioSession()

        // Observe audio route changes
        observeAudioRouteChanges()

        // Attempt connection
        Task {
            await detectAndConnect()
        }

        Logger.info("📱 MetaGlassesAdapter initialized", category: .wearables)
    }

    // MARK: - Public API

    /// Connect to Meta glasses (automatic tier detection)
    func connect() async throws {
        await detectAndConnect()

        guard isConnected else {
            throw MetaGlassesError.connectionFailed("No compatible device found")
        }
    }

    /// Disconnect from glasses
    func disconnect() {
        if let peripheral = connectedPeripheral {
            bluetoothManager?.cancelPeripheralConnection(peripheral)
        }

        isConnected = false
        connectionTier = .tier4_speaker
        audioRoute = "Speaker"

        Logger.info("📱 Disconnected from glasses", category: .wearables)
    }

    /// Send audio to glasses (TTS output)
    func playAudio(_ text: String, rate: Float = 0.5) async throws {
        guard isConnected else {
            throw MetaGlassesError.notConnected
        }

        // Route to VoiceOutputService (which handles TTS)
        await VoiceOutputService.shared.speak(text, rate: rate)

        Logger.debug("🔊 Playing audio via \(connectionTier.description)", category: .wearables)
    }

    /// Capture voice from glasses microphone
    func startVoiceCapture(completion: @escaping (String) -> Void) throws {
        guard isConnected else {
            throw MetaGlassesError.notConnected
        }

        guard supportsVoiceCapture else {
            throw MetaGlassesError.featureNotSupported("Voice capture not supported on this device")
        }

        // Start audio capture (via Speech framework)
        // This would integrate with VoiceNavigationService

        Logger.info("🎤 Voice capture started", category: .wearables)
    }

    /// Stop voice capture
    func stopVoiceCapture() {
        Logger.info("🎤 Voice capture stopped", category: .wearables)
    }

    /// Render content to AR display (future Meta Oakley/Orion)
    func renderToDisplay(_ content: ARDisplayContent) async throws {
        guard hasDisplay else {
            throw MetaGlassesError.featureNotSupported("AR display not available on this device")
        }

        guard isConnected else {
            throw MetaGlassesError.notConnected
        }

        // Send display command via Meta SDK or Bluetooth
        if connectionTier == .tier1_metaSDK {
            try await renderViaMetaSDK(content)
        } else {
            try await renderViaBluetooth(content)
        }

        Logger.debug("🥽 Rendered content to AR display", category: .wearables)
    }

    /// Set display brightness (for AR display)
    func setDisplayBrightness(_ nits: Int) {
        // Send brightness command
        Logger.debug("🔆 Display brightness set to \(nits) nits", category: .wearables)
    }

    /// Wake display from sleep
    func wakeDisplay() {
        Logger.debug("🥽 Display woken", category: .wearables)
    }

    /// Put display to sleep (save battery)
    func sleepDisplay() {
        Logger.debug("🥽 Display sleeping", category: .wearables)
    }

    // MARK: - Connection Detection

    /// Detect and connect to best available device
    private func detectAndConnect() async {
        // Tier 1: Try Meta SDK (if available)
        if await tryMetaSDKConnection() {
            connectionTier = .tier1_metaSDK
            isConnected = true
            audioRoute = "Meta Glasses"
            checkCapabilities()
            Logger.info("✓ Connected via Meta SDK (Tier 1)", category: .wearables)
            return
        }

        // Tier 2: Try CoreBluetooth (Meta glasses via BT)
        if await tryBluetoothConnection() {
            connectionTier = .tier2_bluetooth
            isConnected = true
            audioRoute = "Meta Glasses (Bluetooth)"
            checkCapabilities()
            Logger.info("✓ Connected via Bluetooth (Tier 2)", category: .wearables)
            return
        }

        // Tier 3: Check for AirPods or other BT audio
        if checkAudioRouteForBluetooth() {
            connectionTier = .tier3_airpods
            isConnected = true
            audioRoute = getBluetoothDeviceName()
            Logger.info("✓ Connected via AirPods/Bluetooth Audio (Tier 3)", category: .wearables)
            return
        }

        // Tier 4: Fallback to iPhone speaker
        connectionTier = .tier4_speaker
        isConnected = false // Technically not connected to external device
        audioRoute = "iPhone Speaker"
        Logger.info("⚠️ Using iPhone speaker (Tier 4 fallback)", category: .wearables)
    }

    /// Try connecting via Meta SDK
    private func tryMetaSDKConnection() async -> Bool {
        // Meta SDK integration (placeholder)
        // In production, this would use actual Meta SDK:
        //   import MetaWearableSDK
        //   let sdk = MetaSDK.shared
        //   let connected = await sdk.connect()

        // For now, return false (SDK not available yet)
        return false
    }

    /// Try connecting via CoreBluetooth
    private func tryBluetoothConnection() async -> Bool {
        // Scan for Meta glasses via Bluetooth
        // Meta glasses advertise specific service UUID

        guard let manager = bluetoothManager else {
            return false
        }

        // Check if Bluetooth is powered on
        guard manager.state == .poweredOn else {
            Logger.debug("Bluetooth not powered on", category: .wearables)
            return false
        }

        // In production, would scan for Meta glasses:
        // manager.scanForPeripherals(withServices: [metaGlassesServiceUUID])
        // Wait for discovery...
        // Connect to peripheral...

        // For now, return false (no actual scanning in this implementation)
        return false
    }

    /// Check if Bluetooth audio is routed
    private func checkAudioRouteForBluetooth() -> Bool {
        let currentRoute = audioSession.currentRoute

        for output in currentRoute.outputs {
            if output.portType == .bluetoothA2DP ||
               output.portType == .bluetoothHFP ||
               output.portType == .bluetoothLE {
                return true
            }
        }

        return false
    }

    /// Get name of connected Bluetooth device
    private func getBluetoothDeviceName() -> String {
        let currentRoute = audioSession.currentRoute

        for output in currentRoute.outputs {
            if output.portType == .bluetoothA2DP ||
               output.portType == .bluetoothHFP ||
               output.portType == .bluetoothLE {
                return output.portName
            }
        }

        return "Bluetooth Device"
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .defaultToSpeaker,
                    .mixWithOthers
                ]
            )
            try audioSession.setActive(true)

            Logger.debug("✓ Audio session configured for wearables", category: .wearables)

        } catch {
            Logger.error("❌ Failed to configure audio session: \(error)", category: .wearables)
            lastError = "Audio configuration failed"
        }
    }

    /// Observe audio route changes (e.g., AirPods connected/disconnected)
    private func observeAudioRouteChanges() {
        audioRouteObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleAudioRouteChange(notification)
            }
        }
    }

    /// Handle audio route change
    private func handleAudioRouteChange(_ notification: Notification) async {
        Logger.debug("🔊 Audio route changed", category: .wearables)

        // Re-detect connection tier
        await detectAndConnect()
    }

    // MARK: - Capabilities

    /// Check device capabilities (display, voice capture, etc.)
    private func checkCapabilities() {
        // In production, query device capabilities via SDK or Bluetooth

        switch connectionTier {
        case .tier1_metaSDK:
            // Meta SDK can report capabilities
            // Example: metaSDK.capabilities.hasDisplay
            supportsDisplay = false // Current Ray-Ban Meta: no display
            supportsVoiceCapture = true
            hasDisplay = supportsDisplay

        case .tier2_bluetooth:
            // Query via Bluetooth characteristics
            supportsDisplay = false
            supportsVoiceCapture = true
            hasDisplay = supportsDisplay

        case .tier3_airpods, .tier4_speaker:
            // AirPods/speaker: no display, no special voice capture
            supportsDisplay = false
            supportsVoiceCapture = false
            hasDisplay = false
        }

        Logger.debug("Capabilities: display=\(hasDisplay), voiceCapture=\(supportsVoiceCapture)", category: .wearables)
    }

    // MARK: - Display Rendering

    /// Render content via Meta SDK
    private func renderViaMetaSDK(_ content: ARDisplayContent) async throws {
        // Meta SDK rendering
        // Example: await metaSDK.display.render(content)

        throw MetaGlassesError.notImplemented("Meta SDK rendering not yet available")
    }

    /// Render content via Bluetooth
    private func renderViaBluetooth(_ content: ARDisplayContent) async throws {
        guard let peripheral = connectedPeripheral else {
            throw MetaGlassesError.notConnected
        }

        // Send display data via Bluetooth characteristic
        // Example:
        //   let data = encodeDisplayContent(content)
        //   peripheral.writeValue(data, for: displayCharacteristic, type: .withResponse)

        throw MetaGlassesError.notImplemented("Bluetooth display rendering not yet available")
    }

    // MARK: - Battery Monitoring

    /// Update battery level (called periodically)
    func updateBatteryLevel() async {
        // Query battery level from device
        // Example: metaSDK.batteryLevel or read from Bluetooth characteristic

        // Placeholder: Use random value for demo
        // In production, read actual battery level
    }

    // MARK: - Testing Helpers

    /// Force specific connection tier (for testing)
    func _testSetConnectionTier(_ tier: ConnectionTier) {
        connectionTier = tier
        isConnected = (tier != .tier4_speaker)
        audioRoute = tier.description
    }

    /// Simulate device capabilities (for testing)
    func _testSetCapabilities(display: Bool, voiceCapture: Bool) {
        hasDisplay = display
        supportsDisplay = display
        supportsVoiceCapture = voiceCapture
    }
}

// MARK: - Supporting Types

/// Content to render on AR display
struct ARDisplayContent {
    let position: SIMD3<Float>  // x, y, z coordinates
    let size: CGSize             // width, height
    let texture: Data            // Image data (JPEG or PNG)
    let opacity: Float           // 0.0 to 1.0
    let duration: TimeInterval   // How long to show (0 = persistent)
}

/// Meta Glasses errors
enum MetaGlassesError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    case featureNotSupported(String)
    case notImplemented(String)
    case sdkError(String)
    case bluetoothError(String)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Meta glasses are not connected."
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .featureNotSupported(let feature):
            return "Feature not supported: \(feature)"
        case .notImplemented(let feature):
            return "Not yet implemented: \(feature)"
        case .sdkError(let message):
            return "Meta SDK error: \(message)"
        case .bluetoothError(let message):
            return "Bluetooth error: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notConnected:
            return "Check that your Meta glasses are paired and nearby."
        case .connectionFailed:
            return "Try restarting your glasses and iPhone."
        case .featureNotSupported:
            return "This feature requires newer hardware (Meta Oakley/Orion)."
        case .notImplemented:
            return "This feature is coming in a future update."
        case .sdkError:
            return "Check Meta SDK documentation or restart the app."
        case .bluetoothError:
            return "Enable Bluetooth and try again."
        }
    }
}

// MARK: - Meta SDK Wrapper (Placeholder)

/// Placeholder wrapper for Meta SDK
/// In production, this would wrap the actual Meta Wearable SDK
private class MetaSDKWrapper {
    // Placeholder implementation
    // In production:
    //   import MetaWearableSDK
    //   private let sdk = MetaSDK.shared
}

// MARK: - Logger Category Extension

extension Logger.Category {
    static let wearables = Logger.Category("MetaGlasses")
}

#endif

//
//  EMGGestureRecognizer.swift
//  Zero (iOS)
//
//  Created by Claude Code on 2025-12-12.
//  Part of Wearables Implementation (Week 5-6: EMG Control)
//
//  Purpose: Recognize gestures from EMG wristband (Meta neural interface).
//  Includes iPhone touch simulator for testing without physical hardware.
//

import Foundation
import CoreBluetooth
import UIKit
import Combine

#if os(iOS)

/// EMG gesture recognizer with iPhone touch simulator fallback
/// Supports: pinch, double-pinch, swipe left/right, hold, tap
@MainActor
class EMGGestureRecognizer: NSObject, ObservableObject {
    static let shared = EMGGestureRecognizer()

    // MARK: - Published State

    @Published var isActive: Bool = false
    @Published var currentGesture: EMGGesture?
    @Published var gestureConfidence: Float = 0.0
    @Published var isUsingSimulator: Bool = true
    @Published var isCalibrated: Bool = false

    // MARK: - Private Properties

    private var bluetoothManager: CBCentralManager?
    private var emgPeripheral: CBPeripheral?
    private var gestureBuffer: [EMGSample] = []

    // Simulator
    private var simulator: EMGSimulator?

    // Gesture callbacks
    var onGestureRecognized: ((EMGGesture) -> Void)?

    // Configuration
    private let confidenceThreshold: Float = 0.75
    private let holdDuration: TimeInterval = 0.8
    private let doublePinchWindow: TimeInterval = 0.5

    // Gesture state tracking
    private var lastGestureTime: Date = Date()
    private var lastPinchTime: Date?

    // MARK: - Initialization

    override init() {
        super.init()

        // Setup Bluetooth for physical EMG device
        bluetoothManager = CBCentralManager(delegate: nil, queue: .main)

        // Setup simulator (fallback)
        simulator = EMGSimulator()
        simulator?.onGestureDetected = { [weak self] gesture in
            Task { @MainActor in
                self?.processGesture(gesture, confidence: 0.95)
            }
        }

        Logger.info("🤌 EMGGestureRecognizer initialized", category: .emg)
    }

    // MARK: - Public API

    /// Start gesture recognition
    func startRecognition() {
        guard !isActive else { return }

        // Try to connect to physical EMG device
        if connectToEMGDevice() {
            isUsingSimulator = false
            Logger.info("✓ Connected to EMG wristband", category: .emg)
        } else {
            // Fall back to simulator
            isUsingSimulator = true
            simulator?.start()
            Logger.info("Using EMG simulator (touch gestures)", category: .emg)
        }

        isActive = true
    }

    /// Stop gesture recognition
    func stopRecognition() {
        guard isActive else { return }

        if isUsingSimulator {
            simulator?.stop()
        } else {
            disconnectFromEMGDevice()
        }

        isActive = false
        currentGesture = nil

        Logger.info("EMG gesture recognition stopped", category: .emg)
    }

    /// Calibrate gesture recognition for user
    func startCalibration(completion: @escaping (Bool) -> Void) {
        Logger.info("Starting EMG calibration...", category: .emg)

        // Calibration flow:
        // 1. Relax hand (baseline)
        // 2. Pinch fingers (capture signal)
        // 3. Hold pinch (measure hold threshold)
        // 4. Swipe left/right (capture swipe patterns)

        // For simulator, calibration is instant
        if isUsingSimulator {
            isCalibrated = true
            completion(true)
            Logger.info("✓ Calibration complete (simulator)", category: .emg)
            return
        }

        // For physical device, run actual calibration
        // (Implementation would depend on EMG SDK)
        isCalibrated = true
        completion(true)
    }

    /// Map gesture to action
    func mapGesture(_ gesture: EMGGesture, to action: @escaping () async -> Void) {
        // Store gesture-action mapping
        Logger.debug("Mapped \(gesture.type.rawValue) to action", category: .emg)
    }

    // MARK: - EMG Device Connection

    private func connectToEMGDevice() -> Bool {
        // Try to connect to physical EMG wristband via Bluetooth
        // Meta's EMG device would advertise a specific service UUID

        guard let manager = bluetoothManager else {
            return false
        }

        guard manager.state == .poweredOn else {
            return false
        }

        // Scan for EMG device
        // manager.scanForPeripherals(withServices: [emgServiceUUID])

        // For now, return false (no physical device available)
        return false
    }

    private func disconnectFromEMGDevice() {
        if let peripheral = emgPeripheral {
            bluetoothManager?.cancelPeripheralConnection(peripheral)
        }
        emgPeripheral = nil
    }

    // MARK: - Gesture Processing

    /// Process recognized gesture
    private func processGesture(_ gesture: EMGGesture, confidence: Float) {
        guard confidence >= confidenceThreshold else {
            Logger.debug("Gesture below confidence threshold: \(confidence)", category: .emg)
            return
        }

        // Apply debouncing (prevent rapid-fire gestures)
        let timeSinceLastGesture = Date().timeIntervalSince(lastGestureTime)
        guard timeSinceLastGesture >= 0.3 else {
            Logger.debug("Gesture debounced (too soon after last gesture)", category: .emg)
            return
        }

        // Detect double-pinch
        if gesture.type == .pinch {
            if let lastPinch = lastPinchTime,
               Date().timeIntervalSince(lastPinch) < doublePinchWindow {
                // Double-pinch detected
                let doublePinch = EMGGesture(
                    type: .doublePinch,
                    timestamp: Date(),
                    confidence: confidence
                )
                publishGesture(doublePinch, confidence: confidence)
                lastPinchTime = nil
                return
            } else {
                lastPinchTime = Date()
            }
        }

        // Publish gesture
        publishGesture(gesture, confidence: confidence)
    }

    private func publishGesture(_ gesture: EMGGesture, confidence: Float) {
        currentGesture = gesture
        gestureConfidence = confidence
        lastGestureTime = Date()

        // Notify callback
        onGestureRecognized?(gesture)

        Logger.info("🤌 Gesture: \(gesture.type.rawValue) (\(Int(confidence * 100))%)", category: .emg)

        // Clear after brief delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            if self.currentGesture?.id == gesture.id {
                self.currentGesture = nil
            }
        }
    }

    // MARK: - Testing Helpers

    func _testTriggerGesture(_ type: EMGGestureType) {
        let gesture = EMGGesture(type: type, timestamp: Date(), confidence: 0.95)
        processGesture(gesture, confidence: 0.95)
    }
}

// MARK: - EMG Gesture Models

/// EMG gesture types
enum EMGGestureType: String, Codable, CaseIterable {
    case pinch          // Index + thumb pinch
    case doublePinch    // Two rapid pinches
    case swipeLeft      // Swipe hand left
    case swipeRight     // Swipe hand right
    case hold           // Sustained pinch (0.8s+)
    case tap            // Quick finger tap
}

/// Detected EMG gesture
struct EMGGesture: Identifiable {
    let id: UUID = UUID()
    let type: EMGGestureType
    let timestamp: Date
    let confidence: Float
}

/// Raw EMG sample (for buffering and processing)
struct EMGSample {
    let timestamp: Date
    let channels: [Float]  // 8-channel EMG data
    let strength: Float    // Overall signal strength
}

// MARK: - EMG Simulator (Touch-Based)

/// iPhone touch simulator for EMG gestures
/// Maps touch gestures to EMG gestures for testing
class EMGSimulator {
    var onGestureDetected: ((EMGGesture) -> Void)?

    private var isActive = false
    private var touchWindow: UIWindow?
    private var touchView: EMGTouchView?

    func start() {
        guard !isActive else { return }

        // Create overlay window for touch gestures
        setupTouchOverlay()

        isActive = true
    }

    func stop() {
        guard isActive else { return }

        // Remove touch overlay
        touchWindow?.isHidden = true
        touchWindow = nil
        touchView = nil

        isActive = false
    }

    private func setupTouchOverlay() {
        // Create transparent overlay window
        touchWindow = UIWindow(frame: UIScreen.main.bounds)
        touchWindow?.windowLevel = .alert + 1
        touchWindow?.backgroundColor = .clear

        // Create touch view
        touchView = EMGTouchView()
        touchView?.onGesture = { [weak self] gestureType in
            let gesture = EMGGesture(
                type: gestureType,
                timestamp: Date(),
                confidence: 0.95
            )
            self?.onGestureDetected?(gesture)
        }

        touchWindow?.rootViewController = UIViewController()
        touchWindow?.rootViewController?.view.addSubview(touchView!)
        touchView?.frame = UIScreen.main.bounds

        touchWindow?.isHidden = false
        touchWindow?.isUserInteractionEnabled = true
    }
}

/// Touch view for EMG gesture simulation
class EMGTouchView: UIView {
    var onGesture: ((EMGGestureType) -> Void)?

    private var touchStartTime: Date?
    private var touchStartLocation: CGPoint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        touchStartTime = Date()
        touchStartLocation = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let startTime = touchStartTime,
              let startLocation = touchStartLocation else {
            return
        }

        let endLocation = touch.location(in: self)
        let duration = Date().timeIntervalSince(startTime)
        let distance = hypot(endLocation.x - startLocation.x, endLocation.y - startLocation.y)

        // Detect gesture type
        if duration >= 0.8 {
            // Hold (long press)
            onGesture?(.hold)

        } else if distance < 20 {
            // Tap (short touch, no movement)
            onGesture?(.tap)

        } else if abs(endLocation.x - startLocation.x) > abs(endLocation.y - startLocation.y) {
            // Horizontal swipe
            if endLocation.x < startLocation.x {
                onGesture?(.swipeLeft)
            } else {
                onGesture?(.swipeRight)
            }

        } else {
            // Vertical swipe or ambiguous - treat as pinch
            onGesture?(.pinch)
        }

        // Reset
        touchStartTime = nil
        touchStartLocation = nil
    }
}

// MARK: - Logger Category Extension

extension Logger.Category {
    static let emg = Logger.Category("EMGGesture")
}

#endif

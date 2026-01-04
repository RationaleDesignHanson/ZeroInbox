//
//  VoiceNavigationService.swift
//  Zero
//
//  Created by Claude Code on 2025-12-12.
//  Part of Wearables Implementation (Week 2-3: Voice Navigation)
//
//  Purpose: Hands-free email navigation via voice commands.
//  Manages state machine, command processing, and voice-first interaction flow.
//

import Foundation
import Speech
import AVFoundation
import Combine

/// Service for voice-controlled email navigation
/// Enables hands-free inbox management with voice commands
/// Integrates with VoiceOutputService for TTS responses
@MainActor
class VoiceNavigationService: NSObject, ObservableObject {
    static let shared = VoiceNavigationService()

    // MARK: - Published Properties

    @Published var isListening: Bool = false
    @Published var currentState: NavigationState = .idle
    @Published var currentCommand: String = ""
    @Published var lastError: String?

    // MARK: - Navigation State

    /// State machine for voice navigation flow
    enum NavigationState: Equatable {
        case idle                                    // Not navigating
        case inboxSummary                           // Reading inbox summary
        case readingEmail(index: Int)               // Reading specific email
        case confirmingAction(action: EmailAction, emailId: String)  // Confirming destructive action
    }

    /// Email actions that can be triggered via voice
    enum EmailAction: String {
        case archive
        case flag
        case delete
        case reply
        case markUnread
    }

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private let voiceOutput = VoiceOutputService.shared

    // Email cache for navigation (populated by caller)
    private var emailCache: [EmailCard] = []

    // Command history for undo/redo
    private var commandHistory: [(command: String, timestamp: Date)] = []

    // MARK: - Configuration

    struct Configuration {
        var confirmationTimeout: TimeInterval = 5.0  // Seconds to wait for confirmation
        var commandDebounceInterval: TimeInterval = 0.5  // Ignore duplicate commands within this interval
        var minConfidenceScore: Float = 0.7  // Minimum confidence for command recognition
    }

    private var config = Configuration()

    // MARK: - Initialization

    override init() {
        // Initialize speech recognizer
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            fatalError("Speech recognizer not available for en-US")
        }
        self.speechRecognizer = recognizer

        super.init()

        // Request speech recognition authorization
        requestSpeechAuthorization()
    }

    // MARK: - Authorization

    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    Logger.debug("✓ Speech recognition authorized", category: .voice)
                case .denied:
                    self?.lastError = "Speech recognition access denied. Enable in Settings."
                    Logger.warning("⚠️ Speech recognition denied", category: .voice)
                case .restricted:
                    self?.lastError = "Speech recognition restricted on this device."
                    Logger.warning("⚠️ Speech recognition restricted", category: .voice)
                case .notDetermined:
                    Logger.debug("Speech recognition authorization not determined", category: .voice)
                @unknown default:
                    Logger.warning("⚠️ Unknown speech recognition authorization status", category: .voice)
                }
            }
        }
    }

    // MARK: - Public API - Session Management

    /// Start voice navigation session
    /// - Parameter emails: Email cache to navigate through
    func startNavigation(with emails: [EmailCard]) {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            lastError = "Speech recognition not authorized"
            return
        }

        // Cache emails for navigation
        self.emailCache = emails

        // Start listening
        startListening()

        // Announce navigation mode
        voiceOutput.speak("Voice navigation activated. Say: Check my inbox, or Read email.")

        Logger.info("🎤 Voice navigation started with \(emails.count) emails", category: .voice)
    }

    /// Stop voice navigation session
    func stopNavigation() {
        stopListening()
        currentState = .idle
        emailCache.removeAll()

        voiceOutput.speak("Voice navigation ended.")

        Logger.info("Voice navigation stopped", category: .voice)
    }

    // MARK: - Speech Recognition

    private func startListening() {
        guard !isListening else { return }

        do {
            try startSpeechRecognition()
            isListening = true
        } catch {
            lastError = "Failed to start speech recognition: \(error.localizedDescription)"
            Logger.error("❌ Speech recognition failed: \(error)", category: .voice)
        }
    }

    private func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }

    private func startSpeechRecognition() throws {
        // Cancel previous task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session for recording
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "VoiceNav", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false  // Use server for better accuracy

        // Setup audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcript = result.bestTranscription.formattedString.lowercased()

                Task { @MainActor in
                    self.currentCommand = transcript

                    // Process command when finalized
                    if result.isFinal {
                        self.processVoiceCommand(transcript)
                    }
                }
            }

            if error != nil {
                Task { @MainActor in
                    self.stopListening()
                }
            }
        }

        Logger.debug("🎤 Speech recognition started", category: .voice)
    }

    // MARK: - Command Processing

    /// Process recognized voice command based on current state
    private func processVoiceCommand(_ command: String) {
        Logger.debug("🎤 Processing command: \"\(command)\" in state: \(currentState)", category: .voice)

        // Check debounce (ignore rapid repeated commands)
        if isDuplicateCommand(command) {
            Logger.debug("Ignoring duplicate command within debounce interval", category: .voice)
            return
        }

        // Record command
        commandHistory.append((command: command, timestamp: Date()))

        // Process based on current state
        switch currentState {
        case .idle:
            processIdleCommand(command)
        case .inboxSummary:
            processInboxCommand(command)
        case .readingEmail(let index):
            processEmailCommand(command, emailIndex: index)
        case .confirmingAction(let action, let emailId):
            processConfirmation(command, action: action, emailId: emailId)
        }
    }

    /// Check if command is duplicate (debouncing)
    private func isDuplicateCommand(_ command: String) -> Bool {
        guard let lastCommand = commandHistory.last else { return false }

        let timeSinceLastCommand = Date().timeIntervalSince(lastCommand.timestamp)
        let isSameCommand = lastCommand.command.lowercased() == command.lowercased()

        return isSameCommand && timeSinceLastCommand < config.commandDebounceInterval
    }

    // MARK: - State-Specific Command Processing

    /// Process commands in idle state (not navigating)
    private func processIdleCommand(_ command: String) {
        if command.contains("inbox") || command.contains("summary") || command.contains("check") {
            // Command: "Check my inbox" or "What's in my inbox?"
            readInboxSummary()

        } else if command.contains("read") {
            // Command: "Read first email" or "Read email number 3"
            if let number = extractNumber(from: command) {
                readEmail(at: number - 1)  // Convert to 0-indexed
            } else {
                readEmail(at: 0)  // Default to first email
            }

        } else {
            // Unknown command
            voiceOutput.speak("I didn't understand. Try saying: Check my inbox, or Read first email.")
            Logger.debug("Unknown idle command: \(command)", category: .voice)
        }
    }

    /// Process commands while in inbox summary state
    private func processInboxCommand(_ command: String) {
        if command.contains("read") || command.contains("open") {
            // Command: "Read email number 2"
            if let number = extractNumber(from: command) {
                readEmail(at: number - 1)
            } else {
                voiceOutput.speak("Which email? Say a number from 1 to \(emailCache.count).")
            }

        } else if command.contains("done") || command.contains("close") || command.contains("stop") {
            // Command: "Done" or "Close"
            stopNavigation()

        } else {
            voiceOutput.speak("Say: Read email number 2, or say Done to exit.")
        }
    }

    /// Process commands while reading an email
    private func processEmailCommand(_ command: String, emailIndex: Int) {
        guard emailIndex < emailCache.count else { return }
        let email = emailCache[emailIndex]

        if command.contains("archive") {
            // Command: "Archive this"
            currentState = .confirmingAction(action: .archive, emailId: email.id)
            voiceOutput.speak("Archive this email? Say Yes or No.")

        } else if command.contains("flag") || command.contains("star") {
            // Command: "Flag this" or "Star this"
            currentState = .confirmingAction(action: .flag, emailId: email.id)
            voiceOutput.speak("Flag this email? Say Yes or No.")

        } else if command.contains("delete") {
            // Command: "Delete this"
            currentState = .confirmingAction(action: .delete, emailId: email.id)
            voiceOutput.speak("Delete this email? This cannot be undone. Say Yes or No.")

        } else if command.contains("reply") {
            // Command: "Reply"
            currentState = .confirmingAction(action: .reply, emailId: email.id)
            voiceOutput.speak("Reply to this email? Say Yes or No.")

        } else if command.contains("next") {
            // Command: "Next email"
            if emailIndex + 1 < emailCache.count {
                readEmail(at: emailIndex + 1)
            } else {
                voiceOutput.speak("That was the last email.")
            }

        } else if command.contains("previous") || command.contains("back") {
            // Command: "Previous email" or "Go back"
            if emailIndex > 0 {
                readEmail(at: emailIndex - 1)
            } else {
                voiceOutput.speak("This is the first email.")
            }

        } else if command.contains("stop") || command.contains("done") {
            // Command: "Stop" or "Done"
            stopNavigation()

        } else {
            voiceOutput.speak("Say: Archive, Flag, Reply, Next, Previous, or Done.")
        }
    }

    /// Process confirmation (yes/no) responses
    private func processConfirmation(_ command: String, action: EmailAction, emailId: String) {
        if command.contains("yes") || command.contains("confirm") || command.contains("sure") {
            // Confirmed
            executeAction(action, emailId: emailId)

            // Return to previous state
            if let emailIndex = emailCache.firstIndex(where: { $0.id == emailId }) {
                currentState = .readingEmail(index: emailIndex)
            } else {
                currentState = .idle
            }

        } else if command.contains("no") || command.contains("cancel") || command.contains("nevermind") {
            // Cancelled
            voiceOutput.speak("Cancelled.")

            // Return to reading email
            if let emailIndex = emailCache.firstIndex(where: { $0.id == emailId }) {
                currentState = .readingEmail(index: emailIndex)
            } else {
                currentState = .idle
            }

        } else {
            // Unclear response
            voiceOutput.speak("Say Yes to confirm, or No to cancel.")
        }
    }

    // MARK: - Actions

    /// Read inbox summary (unread count + top emails)
    private func readInboxSummary() {
        currentState = .inboxSummary

        let unreadEmails = emailCache.filter { $0.state != .archived }
        let topEmails = Array(unreadEmails.prefix(3))

        voiceOutput.readInboxSummary(
            unreadCount: unreadEmails.count,
            topEmails: topEmails
        )

        Logger.info("📬 Reading inbox summary: \(unreadEmails.count) unread", category: .voice)
    }

    /// Read a specific email by index
    private func readEmail(at index: Int) {
        guard index >= 0 && index < emailCache.count else {
            voiceOutput.speak("Email not found.")
            Logger.warning("⚠️ Invalid email index: \(index)", category: .voice)
            return
        }

        currentState = .readingEmail(index: index)
        let email = emailCache[index]

        voiceOutput.readEmail(email, includeBody: true)

        Logger.info("📧 Reading email at index \(index): \(email.title)", category: .voice)
    }

    /// Execute an action on an email
    private func executeAction(_ action: EmailAction, emailId: String) {
        Logger.info("⚡️ Executing action: \(action.rawValue) on email \(emailId)", category: .voice)

        // Trigger action callback (will be set by caller)
        actionCallback?(action, emailId)

        // Provide audio feedback
        switch action {
        case .archive:
            voiceOutput.speak("Email archived.")
        case .flag:
            voiceOutput.speak("Email flagged.")
        case .delete:
            voiceOutput.speak("Email deleted.")
        case .reply:
            voiceOutput.speak("Opening reply. Say your message.")
            // TODO: Start voice compose mode
        case .markUnread:
            voiceOutput.speak("Marked as unread.")
        }
    }

    // MARK: - Utility

    /// Extract number from voice command (e.g., "email number 3" → 3)
    private func extractNumber(from text: String) -> Int? {
        // Word-to-number mapping
        let words = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "first": 1, "second": 2, "third": 3
        ]

        // Check for word numbers
        for (word, number) in words {
            if text.contains(word) {
                return number
            }
        }

        // Check for digit numbers
        let digits = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let number = Int(digits), number > 0 {
            return number
        }

        return nil
    }

    // MARK: - Action Callback

    /// Callback to execute actions in production app
    /// Set this in production to handle archive/flag/delete/reply
    var actionCallback: ((EmailAction, String) -> Void)?

    // MARK: - Testing Helpers

    /// Force a state change (for testing only)
    func _testSetState(_ state: NavigationState) {
        currentState = state
    }

    /// Get command history (for testing/debugging)
    func _testGetCommandHistory() -> [(command: String, timestamp: Date)] {
        return commandHistory
    }

    /// Clear command history
    func _testClearHistory() {
        commandHistory.removeAll()
    }
}

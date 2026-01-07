//
//  VoiceOutputService.swift
//  Zero
//
//  Created by Claude Code on 2025-12-12.
//  Part of Wearables Implementation (Week 1-2: Foundation)
//
//  Purpose: Text-to-speech service for voice-first wearables experience.
//  Enables email reading aloud for Ray-Ban Meta glasses and hands-free navigation.
//

import Foundation
import AVFoundation
import Combine

/// Service for converting text to speech, primarily for voice-first wearables experience
/// Supports email reading, inbox summaries, and hands-free navigation with Meta glasses/AirPods
@MainActor
class VoiceOutputService: NSObject, ObservableObject {
    static let shared = VoiceOutputService()

    // MARK: - Published Properties

    @Published var isSpeaking: Bool = false
    @Published var currentUtteranceProgress: Float = 0.0
    @Published var isAudioRouted: Bool = false  // True if audio is routed to Bluetooth

    // MARK: - Private Properties

    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession: AVAudioSession = .sharedInstance()

    private var currentUtterance: AVSpeechUtterance?
    private var utteranceQueue: [AVSpeechUtterance] = []

    // MARK: - Configuration

    struct Configuration {
        var defaultRate: Float = 0.50  // 0.0 (slow) to 1.0 (fast), 0.5 is natural
        var defaultVolume: Float = 1.0
        var defaultLanguage: String = "en-US"
        var pauseBetweenSentences: TimeInterval = 0.3

        // Voice preferences (can be customized in Settings)
        var preferFemaleVoice: Bool = false
    }

    private var config = Configuration()

    // MARK: - Initialization

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
        detectAudioRoute()

        // Observe audio route changes (AirPods connect/disconnect)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Audio Session Configuration

    /// Configure audio session for voice-first wearable experience
    /// Optimized for Bluetooth routing (AirPods, Meta glasses)
    private func configureAudioSession() {
        do {
            // Configure for voice prompts with Bluetooth support
            try audioSession.setCategory(
                .playback,
                mode: .voicePrompt,  // Optimized for speech clarity
                options: [
                    .duckOthers,  // Lower volume of other audio
                    .allowBluetooth,
                    .allowBluetoothA2DP
                ]
            )

            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            Logger.debug("✓ Audio session configured for voice output", category: .audio)
        } catch {
            Logger.error("❌ Audio session configuration failed: \(error.localizedDescription)", category: .audio)
        }
    }

    /// Detect current audio route (speaker, AirPods, Meta glasses, etc.)
    private func detectAudioRoute() {
        let outputs = audioSession.currentRoute.outputs
        let isBluetoothActive = outputs.contains {
            $0.portType == .bluetoothA2DP || $0.portType == .bluetoothHFP || $0.portType == .bluetoothLE
        }

        DispatchQueue.main.async {
            self.isAudioRouted = isBluetoothActive
        }

        if isBluetoothActive {
            let deviceName = outputs.first?.portName ?? "Unknown"
            Logger.debug("✓ Audio routing to Bluetooth: \(deviceName)", category: .audio)
        } else {
            Logger.debug("⚠️ Audio routing to iPhone speaker", category: .audio)
        }
    }

    @objc private func audioRouteChanged(_ notification: Notification) {
        detectAudioRoute()
    }

    // MARK: - Email Reading

    /// Read an email aloud with subject, sender, and optionally the body
    /// - Parameters:
    ///   - email: The EmailCard to read
    ///   - includeBody: Whether to read the email body (default: false, just subject/sender)
    func readEmail(_ email: EmailCard, includeBody: Bool = false) {
        let text = formatEmailForSpeech(email, includeBody: includeBody)
        speak(text, rate: config.defaultRate)

        Logger.info("📧 Reading email: \(email.title)", category: .voice)
    }

    /// Read a summary of the inbox (unread count + top priority emails)
    /// - Parameters:
    ///   - unreadCount: Total number of unread emails
    ///   - topEmails: Top priority emails to summarize (typically 3-5)
    func readInboxSummary(unreadCount: Int, topEmails: [EmailCard]) {
        var summary = ""

        // Greeting based on unread count
        if unreadCount == 0 {
            summary = "You have no unread emails. Your inbox is clear."
        } else if unreadCount == 1 {
            summary = "You have 1 unread email. "
        } else {
            summary = "You have \(unreadCount) unread emails. "
        }

        // Top priority emails
        if !topEmails.isEmpty {
            summary += "Top priority: "
            for (index, email) in topEmails.prefix(3).enumerated() {
                let sender = email.sender?.name ?? "Unknown sender"
                summary += "\(index + 1). \(email.title) from \(sender). "
            }
        }

        speak(summary, rate: config.defaultRate + 0.02)  // Slightly faster for summaries

        Logger.info("📬 Reading inbox summary: \(unreadCount) unread", category: .voice)
    }

    // MARK: - Core TTS Functions

    /// Speak arbitrary text aloud
    /// - Parameters:
    ///   - text: The text to speak
    ///   - rate: Speech rate (0.0 slow - 1.0 fast, default from config)
    ///   - voice: Optional specific voice to use
    func speak(_ text: String, rate: Float? = nil, voice: AVSpeechSynthesisVoice? = nil) {
        guard !text.isEmpty else {
            Logger.warning("⚠️ Attempted to speak empty text", category: .voice)
            return
        }

        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate ?? config.defaultRate
        utterance.volume = config.defaultVolume
        utterance.voice = voice ?? selectVoice()

        // Slightly increase pitch for better clarity on small speakers
        utterance.pitchMultiplier = 1.1

        currentUtterance = utterance
        synthesizer.speak(utterance)

        Logger.debug("🔊 Speaking: \"\(text.prefix(50))...\"", category: .voice)
    }

    /// Stop current speech immediately
    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
        currentUtterance = nil
        utteranceQueue.removeAll()

        Logger.debug("⏹ Speech stopped", category: .voice)
    }

    /// Pause current speech
    func pause() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .word)

        Logger.debug("⏸ Speech paused", category: .voice)
    }

    /// Resume paused speech
    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()

        Logger.debug("▶️ Speech resumed", category: .voice)
    }

    // MARK: - Voice Selection

    /// Select the best available voice for speech
    /// Prefers high-quality "enhanced" voices, falls back to defaults
    private func selectVoice() -> AVSpeechSynthesisVoice? {
        let language = config.defaultLanguage
        let allVoices = AVSpeechSynthesisVoice.speechVoices()

        // Filter voices by language
        let languageVoices = allVoices.filter { $0.language == language }

        // Prefer "enhanced" quality voices (better for wearables)
        let enhancedVoices = languageVoices.filter { $0.quality == .enhanced }

        // Apply gender preference if configured
        let preferredVoices: [AVSpeechSynthesisVoice]
        if config.preferFemaleVoice {
            // Try to find female voice (name heuristic: Samantha, Victoria, etc.)
            preferredVoices = enhancedVoices.filter {
                $0.name.contains("Samantha") || $0.name.contains("Victoria") || $0.name.contains("Karen")
            }
        } else {
            // Try to find male voice (name heuristic: Alex, Daniel, etc.)
            preferredVoices = enhancedVoices.filter {
                $0.name.contains("Alex") || $0.name.contains("Daniel") || $0.name.contains("Tom")
            }
        }

        // Return in order of preference
        if let voice = preferredVoices.first {
            Logger.debug("✓ Selected voice: \(voice.name) (enhanced)", category: .voice)
            return voice
        } else if let voice = enhancedVoices.first {
            Logger.debug("✓ Selected voice: \(voice.name) (enhanced)", category: .voice)
            return voice
        } else if let voice = languageVoices.first {
            Logger.debug("✓ Selected voice: \(voice.name) (default)", category: .voice)
            return voice
        }

        // Ultimate fallback: system default
        Logger.warning("⚠️ Using system default voice", category: .voice)
        return AVSpeechSynthesisVoice(language: language)
    }

    // MARK: - Text Formatting for Speech

    /// Format an email card into speech-friendly text
    /// - Parameters:
    ///   - email: The email to format
    ///   - includeBody: Whether to include the email body
    /// - Returns: Formatted text ready for TTS
    private func formatEmailForSpeech(_ email: EmailCard, includeBody: Bool) -> String {
        var text = ""

        // Subject
        text += "Email: \(email.title). "

        // Sender
        if let senderName = email.sender?.name {
            text += "From \(senderName). "
        } else if let senderEmail = email.sender?.email {
            text += "From \(senderEmail). "
        }

        // Time (relative)
        text += "Received \(email.timeAgo). "

        // Priority indicator
        if email.priority == .high || email.urgent == true {
            text += "This is a high priority email. "
        }

        // Body preview (if requested)
        if includeBody {
            let bodyText = email.aiGeneratedSummary ?? email.summary
            let cleanBody = cleanTextForSpeech(bodyText)

            // Limit body length to avoid very long reads
            let truncatedBody = String(cleanBody.prefix(300))

            if truncatedBody.count < cleanBody.count {
                text += "Message: \(truncatedBody)... "
            } else {
                text += "Message: \(truncatedBody). "
            }
        }

        return text
    }

    /// Clean text for speech (remove special characters, fix formatting)
    /// - Parameter text: Raw text to clean
    /// - Returns: Speech-friendly text
    private func cleanTextForSpeech(_ text: String) -> String {
        var cleaned = text

        // Replace newlines with pauses
        cleaned = cleaned.replacingOccurrences(of: "\n", with: ". ")

        // Remove multiple spaces
        cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")

        // Remove HTML tags (basic)
        cleaned = cleaned.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Fix common email formatting
        cleaned = cleaned.replacingOccurrences(of: "&nbsp;", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "&amp;", with: "and")
        cleaned = cleaned.replacingOccurrences(of: "&quot;", with: "\"")

        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned
    }

    // MARK: - Configuration Updates

    /// Update speech rate (useful for user preferences)
    /// - Parameter rate: New speech rate (0.0 slow - 1.0 fast)
    func updateSpeechRate(_ rate: Float) {
        config.defaultRate = min(max(rate, 0.0), 1.0)  // Clamp to 0.0-1.0
        Logger.debug("🎚 Speech rate updated: \(config.defaultRate)", category: .voice)
    }

    /// Update voice gender preference
    /// - Parameter preferFemale: True for female voice, false for male
    func updateVoiceGender(preferFemale: Bool) {
        config.preferFemaleVoice = preferFemale
        Logger.debug("👤 Voice gender preference: \(preferFemale ? "Female" : "Male")", category: .voice)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceOutputService: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
            self.currentUtteranceProgress = 0.0
        }

        Logger.debug("▶️ Speech started", category: .voice)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentUtteranceProgress = 0.0
            self.currentUtterance = nil
        }

        Logger.debug("✓ Speech finished", category: .voice)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Logger.debug("⏸ Speech paused", category: .voice)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Logger.debug("▶️ Speech continued", category: .voice)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentUtteranceProgress = 0.0
            self.currentUtterance = nil
        }

        Logger.debug("⏹ Speech cancelled", category: .voice)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // Update progress for visual feedback (useful for UI)
        let totalLength = utterance.speechString.count
        guard totalLength > 0 else { return }

        let progress = Float(characterRange.location) / Float(totalLength)

        Task { @MainActor in
            self.currentUtteranceProgress = progress
        }
    }
}

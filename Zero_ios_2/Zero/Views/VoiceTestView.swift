//
//  VoiceTestView.swift
//  Zero
//
//  Created by Claude Code on 2025-12-12.
//  Testing view for VoiceOutputService - Voice-first wearables
//
//  Usage: Add to navigation or present as sheet for testing voice output
//

import SwiftUI

struct VoiceTestView: View {
    @StateObject private var voiceService = VoiceOutputService.shared
    @State private var testEmailIndex: Int = 0
    @State private var speechRate: Double = 0.50

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Status Section
                    statusSection

                    Divider()

                    // MARK: - Quick Tests
                    quickTestsSection

                    Divider()

                    // MARK: - Email Tests
                    emailTestsSection

                    Divider()

                    // MARK: - Controls
                    controlsSection

                    Divider()

                    // MARK: - Configuration
                    configurationSection

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Voice Output Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 12) {
            Text("Audio Status")
                .font(.headline)

            // Audio routing indicator
            HStack(spacing: 12) {
                Circle()
                    .fill(voiceService.isAudioRouted ? .green : .orange)
                    .frame(width: 16, height: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(voiceService.isAudioRouted ? "Bluetooth Connected" : "Using iPhone Speaker")
                        .font(.body)
                    Text(voiceService.isAudioRouted ? "Audio routing to AirPods/Meta Glasses" : "Connect Bluetooth device for best experience")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Speaking indicator
            if voiceService.isSpeaking {
                HStack(spacing: 12) {
                    ProgressView()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Speaking...")
                            .font(.body)
                            .fontWeight(.medium)
                        if voiceService.currentUtteranceProgress > 0 {
                            Text("\(Int(voiceService.currentUtteranceProgress * 100))% complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Quick Tests

    private var quickTestsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Tests")
                .font(.headline)

            Button(action: testSimpleText) {
                Label("Simple Text", systemImage: "text.bubble")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(action: testInboxSummary) {
                Label("Inbox Summary (3 emails)", systemImage: "tray.full")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button(action: testFullEmail) {
                Label("Full Email (with body)", systemImage: "envelope.open.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Email Tests

    private var emailTestsSection: some View {
        VStack(spacing: 12) {
            Text("Email Test Cases")
                .font(.headline)

            // Email selector
            Picker("Test Email", selection: $testEmailIndex) {
                Text("Work - High Priority").tag(0)
                Text("Shopping - Package").tag(1)
                Text("Social - LinkedIn").tag(2)
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Button(action: { testEmail(includeBody: false) }) {
                    VStack(spacing: 4) {
                        Image(systemName: "envelope")
                        Text("Subject Only")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: { testEmail(includeBody: true) }) {
                    VStack(spacing: 4) {
                        Image(systemName: "envelope.open")
                        Text("Full Email")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        VStack(spacing: 12) {
            Text("Playback Controls")
                .font(.headline)

            HStack(spacing: 16) {
                Button(action: { voiceService.pause() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "pause.circle.fill")
                            .font(.title)
                        Text("Pause")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!voiceService.isSpeaking)

                Button(action: { voiceService.resume() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                        Text("Resume")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: { voiceService.stop() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        Text("Stop")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Configuration

    private var configurationSection: some View {
        VStack(spacing: 16) {
            Text("Configuration")
                .font(.headline)

            // Speech rate slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Speech Rate")
                        .font(.subheadline)
                    Spacer()
                    Text("\(speechRate, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Text("Slow")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(value: $speechRate, in: 0.3...0.7, step: 0.05)
                        .onChange(of: speechRate) { oldValue, newValue in
                            voiceService.updateSpeechRate(Float(newValue))
                        }

                    Text("Fast")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Reset button
            Button(action: {
                speechRate = 0.50
                voiceService.updateSpeechRate(0.50)
            }) {
                Label("Reset to Default (0.50)", systemImage: "arrow.counterclockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Test Functions

    private func testSimpleText() {
        voiceService.speak("This is a test of the voice output service. Audio should play through your connected Bluetooth device.")
    }

    private func testInboxSummary() {
        let mockEmails = createMockEmails()
        voiceService.readInboxSummary(
            unreadCount: 15,
            topEmails: Array(mockEmails.prefix(3))
        )
    }

    private func testFullEmail() {
        let mockEmails = createMockEmails()
        voiceService.readEmail(mockEmails[testEmailIndex], includeBody: true)
    }

    private func testEmail(includeBody: Bool) {
        let mockEmails = createMockEmails()
        voiceService.readEmail(mockEmails[testEmailIndex], includeBody: includeBody)
    }

    // MARK: - Mock Data

    private func createMockEmails() -> [EmailCard] {
        return [
            // Work email - High priority
            EmailCard(
                id: "1",
                type: .work,
                state: .active,
                priority: .high,
                hpa: "Schedule Meeting",
                timeAgo: "2 hours ago",
                title: "Quarterly Review Meeting",
                summary: "Let's schedule our quarterly review for next week.",
                aiGeneratedSummary: "Your manager Sarah Chen wants to schedule the quarterly review meeting. She's available Tuesday through Thursday afternoons next week.",
                body: nil,
                htmlBody: nil,
                metaCTA: "Reply",
                sender: SenderInfo(name: "Sarah Chen", initial: "SC", email: "boss@company.com"),
                recipientEmail: "you@company.com",
                urgent: true
            ),

            // Shopping email - Package tracking
            EmailCard(
                id: "2",
                type: .shopping,
                state: .active,
                priority: .medium,
                hpa: "Track Package",
                timeAgo: "5 hours ago",
                title: "Your package has shipped",
                summary: "Your order from Amazon is on its way.",
                aiGeneratedSummary: "Your Amazon package with tracking number 1Z999AA10123456784 shipped and will arrive tomorrow evening by 8 PM.",
                body: nil,
                htmlBody: nil,
                metaCTA: "Track",
                sender: SenderInfo(name: "Amazon", initial: "A", email: "ship-confirm@amazon.com"),
                recipientEmail: "you@gmail.com",
                trackingNumber: "1Z999AA10123456784",
                isShoppingEmail: true
            ),

            // Social email - Low priority
            EmailCard(
                id: "3",
                type: .social,
                state: .active,
                priority: .low,
                hpa: "View",
                timeAgo: "1 day ago",
                title: "You have 5 new LinkedIn connections",
                summary: "Connect with more professionals in your industry.",
                aiGeneratedSummary: "LinkedIn notification about 5 new connection requests from professionals in your industry.",
                body: nil,
                htmlBody: nil,
                metaCTA: "View",
                sender: SenderInfo(name: "LinkedIn", initial: "L", email: "notifications@linkedin.com"),
                recipientEmail: "you@gmail.com"
            )
        ]
    }
}

// MARK: - Preview

#Preview {
    VoiceTestView()
}

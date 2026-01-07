//
//  WearablesTestView.swift
//  Zero (iOS)
//
//  Created by Claude Code on 2025-12-12.
//  Comprehensive testing interface for all wearables features
//
//  Purpose: Test voice, watch, AR display, and EMG features in one view.
//  Add to iOS app for development and QA testing.
//

import SwiftUI

#if os(iOS)

struct WearablesTestView: View {
    @StateObject private var voiceOutput = VoiceOutputService.shared
    @StateObject private var voiceNav = VoiceNavigationService.shared
    @StateObject private var watchManager = WatchConnectivityManager.shared

    @State private var selectedTab: Tab = .voice

    enum Tab: String, CaseIterable {
        case voice = "Voice"
        case watch = "Watch"
        case ar = "AR Display"
        case integration = "Integration"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Test Category", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Tab content
                TabView(selection: $selectedTab) {
                    VoiceTestSection()
                        .tag(Tab.voice)

                    WatchTestSection()
                        .tag(Tab.watch)

                    ARTestSection()
                        .tag(Tab.ar)

                    IntegrationTestSection()
                        .tag(Tab.integration)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Wearables Testing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Voice Test Section

struct VoiceTestSection: View {
    @StateObject private var voiceOutput = VoiceOutputService.shared
    @StateObject private var voiceNav = VoiceNavigationService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                statusCard

                Divider()

                voiceOutputTests

                Divider()

                voiceNavigationTests
            }
            .padding()
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice Services Status")
                .font(.headline)

            HStack {
                StatusIndicator(
                    isActive: voiceOutput.isAudioRouted,
                    label: "Bluetooth Audio",
                    icon: "airpodspro"
                )

                Spacer()

                StatusIndicator(
                    isActive: voiceNav.isListening,
                    label: "Listening",
                    icon: "mic.fill"
                )
            }

            if voiceOutput.isAudioRouted {
                Text("✓ Audio routed to Bluetooth device")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("⚠️ Using iPhone speaker")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var voiceOutputTests: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice Output Tests")
                .font(.headline)

            Button("Test Simple Speech") {
                voiceOutput.speak("Voice output is working correctly.")
            }
            .buttonStyle(.bordered)

            Button("Test Inbox Summary") {
                let emails = createMockEmails()
                voiceOutput.readInboxSummary(unreadCount: emails.count, topEmails: Array(emails.prefix(3)))
            }
            .buttonStyle(.bordered)

            Button("Test Email Reading") {
                let email = createMockEmails().first!
                voiceOutput.readEmail(email, includeBody: false)
            }
            .buttonStyle(.bordered)

            Button("Stop Speech") {
                voiceOutput.stop()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    private var voiceNavigationTests: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice Navigation Tests")
                .font(.headline)

            Text("Current State: \(stateDescription(voiceNav.currentState))")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Start Navigation") {
                let emails = createMockEmails()
                voiceNav.startNavigation(with: emails)
            }
            .buttonStyle(.bordered)

            Button("Simulate 'Check Inbox'") {
                // Simulate voice command processing
                print("Simulating: 'check inbox' command")
            }
            .buttonStyle(.bordered)

            Button("Simulate 'Archive This'") {
                // Simulate voice command processing
                print("Simulating: 'archive this' command")
            }
            .buttonStyle(.bordered)

            Button("Stop Navigation") {
                voiceNav.stopNavigation()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    private func stateDescription(_ state: VoiceNavigationService.NavigationState) -> String {
        switch state {
        case .idle:
            return "Idle"
        case .inboxSummary:
            return "Inbox Summary"
        case .readingEmail(let index):
            return "Reading Email \(index + 1)"
        case .confirmingAction(let action, _):
            return "Confirming \(action.rawValue)"
        }
    }
}

// MARK: - Watch Test Section

struct WatchTestSection: View {
    @StateObject private var watchManager = WatchConnectivityManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                connectionStatus

                Divider()

                watchActions

                Divider()

                recentSync
            }
            .padding()
        }
    }

    private var connectionStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watch Connection Status")
                .font(.headline)

            HStack {
                StatusIndicator(
                    isActive: watchManager.isWatchPaired,
                    label: "Paired",
                    icon: "applewatch"
                )

                Spacer()

                StatusIndicator(
                    isActive: watchManager.isWatchReachable,
                    label: "Reachable",
                    icon: "antenna.radiowaves.left.and.right"
                )

                Spacer()

                StatusIndicator(
                    isActive: watchManager.isWatchAppInstalled,
                    label: "App Installed",
                    icon: "checkmark.circle"
                )
            }

            if let error = watchManager.syncError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var watchActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watch Actions")
                .font(.headline)

            Button("Push Inbox to Watch") {
                watchManager._testForcePush()
            }
            .buttonStyle(.bordered)
            .disabled(!watchManager.isWatchPaired)

            Button("Simulate Action from Watch") {
                // In production, this would come FROM watch
                // For testing, we simulate receiving an action
                print("Simulating watch action (implement in production)")
            }
            .buttonStyle(.bordered)
            .disabled(!watchManager.isWatchReachable)

            Text("Note: Install watch app to test full sync")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var recentSync: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sync")
                .font(.headline)

            if let lastSync = watchManager.lastSyncDate {
                HStack {
                    Text("Last sync:")
                    Text(lastSync, style: .relative)
                        .foregroundColor(.secondary)
                    Text("ago")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            } else {
                Text("No sync yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - AR Display Test Section

struct ARTestSection: View {
    @State private var arAvailable = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("AR Display Testing")
                    .font(.headline)

                Text("AR display features will be available when Meta Oakley/Orion glasses are released.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Simulation Mode")
                        .font(.headline)

                    Button("Enable ARKit Simulation") {
                        // Would initialize ARKit preview
                        print("ARKit simulation (implement in Week 5-6)")
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)

                    Text("Coming in Week 5-6")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
        }
    }
}

// MARK: - Integration Test Section

struct IntegrationTestSection: View {
    @StateObject private var voiceOutput = VoiceOutputService.shared
    @StateObject private var voiceNav = VoiceNavigationService.shared
    @StateObject private var watchManager = WatchConnectivityManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("End-to-End Integration Tests")
                    .font(.headline)

                Divider()

                testScenarios
            }
            .padding()
        }
    }

    private var testScenarios: some View {
        VStack(alignment: .leading, spacing: 16) {
            TestScenarioCard(
                title: "Voice → Watch Sync",
                description: "Archive email via voice, verify on watch",
                action: runVoiceWatchTest
            )

            TestScenarioCard(
                title: "Watch → Voice Confirmation",
                description: "Archive email on watch, hear voice confirmation",
                action: runWatchVoiceTest
            )

            TestScenarioCard(
                title: "Inbox Summary Flow",
                description: "Voice: 'Check inbox' → Hear summary → See on watch",
                action: runInboxSummaryTest
            )

            TestScenarioCard(
                title: "Offline Queue Test",
                description: "Disconnect watch, archive email, reconnect, verify sync",
                action: runOfflineTest
            )
        }
    }

    private func runVoiceWatchTest() {
        print("Test: Voice → Watch Sync")
        // 1. Archive email via voice
        voiceNav._testProcessCommand("archive this")

        // 2. Wait 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 3. Push update to watch
            watchManager._testForcePush()
        }

        print("✓ Test initiated. Check watch for updated inbox.")
    }

    private func runWatchVoiceTest() {
        print("Test: Watch → Voice Confirmation")
        // Simulate action from watch
        print("Note: Requires physical watch to test fully")
    }

    private func runInboxSummaryTest() {
        print("Test: Inbox Summary Flow")

        // 1. Voice reads inbox summary
        let emails = createMockEmails()
        voiceOutput.readInboxSummary(unreadCount: emails.count, topEmails: Array(emails.prefix(3)))

        // 2. Push to watch
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            watchManager._testForcePush()
        }

        print("✓ Listen for summary, then check watch")
    }

    private func runOfflineTest() {
        print("Test: Offline Queue")
        print("Manual steps:")
        print("1. Unpair watch from iPhone")
        print("2. Archive email on watch")
        print("3. Pair watch again")
        print("4. Verify email archives on iPhone")
    }
}

// MARK: - Helper Views

struct StatusIndicator: View {
    let isActive: Bool
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isActive ? .green : .gray)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
        }
    }
}

struct TestScenarioCard: View {
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Run Test") {
                action()
            }
            .buttonStyle(.borderedProminent)
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Mock Data

private func createMockEmails() -> [EmailCard] {
    return [
        EmailCard(
            id: "1",
            title: "Q4 Report Ready",
            summary: "Please review by EOD",
            state: .unread,
            priority: .high,
            type: .work,
            sender: SenderInfo(name: "Sarah Chen", initial: "SC", email: "sarah@company.com"),
            timeAgo: "2h ago",
            hpa: "Review report",
            urgent: true
        ),
        EmailCard(
            id: "2",
            title: "Package Delivered",
            summary: "Your order has arrived",
            state: .unread,
            priority: .medium,
            type: .shopping,
            sender: SenderInfo(name: "Amazon", initial: "A", email: "shipment@amazon.com"),
            timeAgo: "4h ago",
            hpa: "Track package",
            urgent: false
        ),
        EmailCard(
            id: "3",
            title: "Team Lunch Tomorrow",
            summary: "Don't forget to RSVP",
            state: .unread,
            priority: .low,
            type: .social,
            sender: SenderInfo(name: "LinkedIn", initial: "L", email: "events@linkedin.com"),
            timeAgo: "1d ago",
            hpa: "RSVP to event",
            urgent: false
        )
    ]
}

// MARK: - Preview

struct WearablesTestView_Previews: PreviewProvider {
    static var previews: some View {
        WearablesTestView()
    }
}

#endif

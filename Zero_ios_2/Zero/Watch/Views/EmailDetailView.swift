//
//  EmailDetailView.swift
//  Zer0Watch (watchOS)
//
//  Created by Claude Code on 2025-12-12.
//  Part of Wearables Implementation (Week 3-4: Watch App)
//
//  Purpose: Detail view for reading a single email on Apple Watch.
//  Shows sender, subject, HPA, and quick actions.
//

import SwiftUI

#if os(watchOS)

struct EmailDetailView: View {
    let email: WatchEmail

    @StateObject private var watchManager = WatchConnectivityManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingActionConfirmation = false
    @State private var lastAction: WatchAction?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                headerSection

                Divider()

                // Email content
                contentSection

                Divider()

                // High-priority action
                if !email.hpa.isEmpty {
                    hpaSection
                    Divider()
                }

                // Quick actions
                actionsSection
            }
            .padding()
        }
        .navigationTitle("Email")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Action Complete", isPresented: $showingActionConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if let action = lastAction {
                Text("Email \(action.rawValue)d successfully")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sender
            HStack(spacing: 8) {
                // Avatar
                Circle()
                    .fill(email.accentColor.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(email.senderInitial)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(email.accentColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(email.sender)
                        .font(.headline)
                        .foregroundColor(email.accentColor)

                    Text(email.timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Badges
            HStack(spacing: 6) {
                if email.isUrgent {
                    Badge(text: "Urgent", color: .red)
                }

                if email.priority == .high {
                    Badge(text: "High", color: .orange)
                }

                Badge(text: email.archetype.capitalized, color: email.accentColor)
            }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Subject
            Text(email.title)
                .font(.body)
                .fontWeight(.semibold)

            // Note: Full email body not sent to watch (data minimization)
            Text("Open on iPhone for full email")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }

    // MARK: - HPA Section

    private var hpaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Action")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text(email.hpa)
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Primary action: Archive
            Button {
                performAction(.archive)
            } label: {
                Label("Archive", systemImage: "archivebox")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            HStack(spacing: 12) {
                // Flag
                Button {
                    performAction(.flag)
                } label: {
                    Label("Flag", systemImage: "flag.fill")
                }
                .buttonStyle(.bordered)
                .tint(.orange)

                // Mark Read
                Button {
                    performAction(.markRead)
                } label: {
                    Label("Read", systemImage: "envelope.open")
                }
                .buttonStyle(.bordered)
            }

            // Destructive: Delete
            Button(role: .destructive) {
                performAction(.delete)
            } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Action Handler

    private func performAction(_ action: WatchAction) {
        Task {
            do {
                try await watchManager.executeAction(action, on: email.id)

                // Success feedback
                WKInterfaceDevice.current().play(.success)

                // Show confirmation
                lastAction = action
                showingActionConfirmation = true

                Logger.info("✓ Action completed: \(action.rawValue) on \(email.id)", category: .watch)

            } catch WatchError.iPhoneNotReachable {
                // Queued for later
                WKInterfaceDevice.current().play(.notification)

                Logger.debug("Action queued: \(action.rawValue) on \(email.id)", category: .watch)

                // Show queued confirmation
                lastAction = action
                showingActionConfirmation = true

            } catch {
                // Error
                WKInterfaceDevice.current().play(.failure)

                Logger.error("❌ Action failed: \(error)", category: .watch)
            }
        }
    }
}

// MARK: - Preview

struct EmailDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EmailDetailView(email: WatchEmail(
                id: "1",
                title: "Q4 Report Ready for Review",
                sender: "Sarah Chen",
                senderInitial: "SC",
                timeAgo: "2h ago",
                priority: .high,
                archetype: "work",
                hpa: "Review and approve by EOD",
                isUnread: true,
                isUrgent: true
            ))
        }
    }
}

#endif

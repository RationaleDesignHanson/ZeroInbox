//
//  InboxView.swift
//  Zer0Watch (watchOS)
//
//  Created by Claude Code on 2025-12-12.
//  Part of Wearables Implementation (Week 3-4: Watch App)
//
//  Purpose: Main inbox view showing list of emails on Apple Watch.
//  Supports swipe actions (archive, flag), pull to refresh.
//

import SwiftUI

#if os(watchOS)

struct InboxView: View {
    @StateObject private var watchManager = WatchConnectivityManager.shared
    @State private var selectedEmail: WatchEmail?
    @State private var showingActionSheet = false
    @State private var actionSheetEmail: WatchEmail?

    var body: some View {
        NavigationView {
            Group {
                if let inboxState = watchManager.inboxState {
                    if inboxState.emails.isEmpty {
                        emptyInboxView
                    } else {
                        emailListView(emails: inboxState.emails)
                    }
                } else {
                    loadingView
                }
            }
            .navigationTitle("Zer0 Inbox")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    statusIndicator
                }
            }
        }
    }

    // MARK: - Email List

    private func emailListView(emails: [WatchEmail]) -> some View {
        List {
            // Summary section
            Section {
                if let state = watchManager.inboxState {
                    summaryRow(unread: state.unreadCount, urgent: state.urgentCount)
                }
            }

            // Email list
            Section {
                ForEach(emails) { email in
                    NavigationLink(destination: EmailDetailView(email: email)) {
                        EmailRowView(email: email)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            archiveEmail(email)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteEmail(email)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            flagEmail(email)
                        } label: {
                            Label("Flag", systemImage: "flag.fill")
                        }
                        .tint(.orange)
                    }
                }
            } header: {
                HStack {
                    Text("Emails")
                    Spacer()
                    if let syncDate = watchManager.lastSyncDate {
                        Text(syncDate, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .refreshable {
            watchManager.requestInboxUpdate()
        }
    }

    // MARK: - Summary Row

    private func summaryRow(unread: Int, urgent: Int) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(unread)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Unread")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("\(urgent)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(urgent > 0 ? .red : .primary)
                Text("Urgent")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Pending actions indicator
            if watchManager.isPendingAction {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty Inbox

    private var emptyInboxView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Inbox Zero!")
                .font(.headline)

            Text("No unread emails")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()

            if let error = watchManager.syncError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)

                Button("Retry") {
                    watchManager.requestInboxUpdate()
                }
                .buttonStyle(.bordered)
            } else {
                Text("Syncing with iPhone...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(watchManager.isPhoneReachable ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            if !watchManager.isPhoneReachable {
                Image(systemName: "iphone.slash")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func archiveEmail(_ email: WatchEmail) {
        Task {
            do {
                try await watchManager.executeAction(.archive, on: email.id)
                Logger.info("✓ Archived email: \(email.title)", category: .watch)

                // Haptic feedback
                WKInterfaceDevice.current().play(.success)

            } catch WatchError.iPhoneNotReachable {
                Logger.debug("iPhone not reachable, action queued", category: .watch)

                // Haptic feedback (queued)
                WKInterfaceDevice.current().play(.notification)

            } catch {
                Logger.error("❌ Archive failed: \(error)", category: .watch)

                // Haptic feedback (error)
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }

    private func flagEmail(_ email: WatchEmail) {
        Task {
            do {
                try await watchManager.executeAction(.flag, on: email.id)
                WKInterfaceDevice.current().play(.success)
            } catch {
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }

    private func deleteEmail(_ email: WatchEmail) {
        Task {
            do {
                try await watchManager.executeAction(.delete, on: email.id)
                WKInterfaceDevice.current().play(.success)
            } catch {
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }
}

// MARK: - Email Row View

struct EmailRowView: View {
    let email: WatchEmail

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Sender + Time
            HStack {
                Text(email.sender)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(email.accentColor)

                Spacer()

                Text(email.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Subject
            Text(email.title)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(email.isUnread ? .primary : .secondary)

            // Badges
            HStack(spacing: 6) {
                if email.isUrgent {
                    Badge(text: "Urgent", color: .red)
                }

                if email.priority == .high {
                    Badge(text: "High Priority", color: .orange)
                }

                Image(systemName: email.icon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Badge View

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(4)
    }
}

// MARK: - Preview

struct InboxView_Previews: PreviewProvider {
    static var previews: some View {
        InboxView()
    }
}

#endif

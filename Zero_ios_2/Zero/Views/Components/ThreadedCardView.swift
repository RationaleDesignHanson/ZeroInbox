import SwiftUI

struct ThreadedCardView: View {
    let thread: [EmailCard]
    @Binding var selectedEmail: EmailCard?
    @State private var isExpanded = false

    var latestEmail: EmailCard {
        thread.max(by: { $0.timestamp < $1.timestamp }) ?? thread[0]
    }

    var threadSummary: ThreadSummary {
        ThreadingService.shared.getThreadSummary(thread)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Latest email preview (always visible)
            Button {
                if thread.count == 1 {
                    selectedEmail = latestEmail
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    // Thread indicator
                    if thread.count > 1 {
                        VStack {
                            Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        }
                        .frame(width: 24)
                    }

                    // Latest email card content
                    VStack(alignment: .leading, spacing: 8) {
                        // Sender
                        HStack {
                            if let sender = latestEmail.sender {
                                Text(sender.name ?? sender.email ?? "Unknown")
                                    .font(.subheadline.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }

                            Spacer()

                            // Thread count badge
                            if thread.count > 1 {
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .font(.caption2)
                                    Text("\(thread.count)")
                                        .font(.caption.bold())
                                }
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .padding(.horizontal, DesignTokens.Spacing.inline)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.3))
                                )
                            }

                            // Unread indicator
                            if threadSummary.hasUnread {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                            }
                        }

                        // Title (reduced to 80% for consistency)
                        Text(latestEmail.title)
                            .font(DesignTokens.Typography.threadTitle)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        // Summary (increased for readability)
                        Text(latestEmail.summary)
                            .font(DesignTokens.Typography.threadSummary)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        // Metadata row
                        HStack(spacing: 12) {
                            // Time
                            Text(RelativeDateFormatter.string(from: latestEmail.timestamp))
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)

                            // Status dots (VIP, Deadline, Newsletter, Shopping)
                            StatusDots(from: latestEmail)

                            // Participants (if thread)
                            if thread.count > 1 && threadSummary.participants.count > 1 {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                        .font(.caption2)
                                    Text("\(threadSummary.participants.count)")
                                        .font(.caption)
                                }
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                            }

                            Spacer()

                            // Additional badges (attachments, calendar)
                            HStack(spacing: 6) {
                                if latestEmail.hasAttachments == true {
                                    Image(systemName: "paperclip")
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.textSubtle)
                                }

                                if latestEmail.calendarInvite != nil {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundColor(.blue.opacity(0.8))
                                }
                            }
                        }
                    }
                }
                .padding(DesignTokens.Spacing.section)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                        .fill(Color.white.opacity(threadSummary.hasUnread ? 0.15 : 0.08))
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded thread messages
            if isExpanded && thread.count > 1 {
                VStack(spacing: 8) {
                    ForEach(thread.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { email in
                        if email.id != latestEmail.id {
                            ThreadMessageRow(
                                email: email,
                                onTap: {
                                    selectedEmail = email
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                    }
                }
                .padding(.leading, 36)
                .padding(.top, DesignTokens.Spacing.inline)
            }
        }
    }
}

struct ThreadMessageRow: View {
    let email: EmailCard
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Connector line
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 2)
                }
                .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    // Sender & time
                    HStack {
                        if let sender = email.sender {
                            Text(sender.name ?? sender.email ?? "Unknown")
                                .font(DesignTokens.Typography.threadMessageSender)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                        }

                        Spacer()

                        Text(RelativeDateFormatter.string(from: email.timestamp))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))

                        if email.hasRead == false {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                        }
                    }

                    // Summary (increased for readability)
                    Text(email.summary)
                        .font(DesignTokens.Typography.threadMessageBody)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(DesignTokens.Spacing.component)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                        .fill(Color.white.opacity(email.hasRead == false ? 0.1 : 0.05))
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Relative Date Formatter

struct RelativeDateFormatter {
    static func string(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        // Today
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }

        // Yesterday
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        // This week
        let daysAgo = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: date)
        }

        // This year
        if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }

        // Older
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

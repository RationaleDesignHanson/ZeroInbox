import WidgetKit
import SwiftUI

/// Main widget view that adapts to different widget sizes
struct InboxWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: InboxWidgetEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        case .accessoryInline:
            InlineWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Icon + Count)

struct SmallWidgetView: View {
    let entry: InboxWidgetEntry

    var body: some View {
        ZStack {
            // Gradient background based on urgency
            LinearGradient(
                colors: entry.urgentCount > 0
                    ? [Color.red.opacity(0.6), Color.orange.opacity(0.4)]
                    : [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)

                Text("\(entry.unreadCount)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)

                Text("Unread")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))

                if entry.urgentCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                        Text("\(entry.urgentCount) urgent")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.3))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Medium Widget (Count + Top Email)

struct MediumWidgetView: View {
    let entry: InboxWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Unread count
            VStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(gradient)

                Text("\(entry.unreadCount)")
                    .font(.system(size: 36, weight: .bold))

                Text("Unread")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if entry.urgentCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("\(entry.urgentCount)")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: 100)

            Divider()

            // Right: Top priority email
            VStack(alignment: .leading, spacing: 8) {
                if let topEmail = entry.topPriorityEmail {
                    HStack {
                        Image(systemName: iconForArchetype(topEmail.archetype))
                            .font(.caption)
                            .foregroundStyle(colorForArchetype(topEmail.archetype))
                        Text("Top Priority")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }

                    Text(topEmail.title)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    Text(topEmail.sender)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack {
                        Image(systemName: "hand.point.right.fill")
                            .font(.caption2)
                        Text(topEmail.hpa)
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(6)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.green)
                        Text("Inbox Zero")
                            .font(.headline)
                        Text("All caught up!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    private var gradient: LinearGradient {
        entry.urgentCount > 0
            ? LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func iconForArchetype(_ archetype: String) -> String {
        switch archetype {
        case "shopping": return "cart.fill"
        case "work": return "briefcase.fill"
        case "social": return "person.2.fill"
        case "finance": return "dollarsign.circle.fill"
        case "travel": return "airplane"
        case "personal": return "envelope.fill"
        default: return "envelope.fill"
        }
    }

    private func colorForArchetype(_ archetype: String) -> Color {
        switch archetype {
        case "shopping": return .orange
        case "work": return .blue
        case "social": return .pink
        case "finance": return .green
        case "travel": return .cyan
        case "personal": return .purple
        default: return .gray
        }
    }
}

// MARK: - Large Widget (Count + Multiple Emails)

struct LargeWidgetView: View {
    let entry: InboxWidgetEntry

    var body: some View {
        VStack(spacing: 12) {
            // Header with count
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Zero Inbox")
                        .font(.headline)
                    Text("\(entry.unreadCount) unread")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if entry.urgentCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("\(entry.urgentCount) urgent")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.red)
                    .cornerRadius(12)
                }

                Image(systemName: "envelope.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }

            Divider()

            // Recent emails list
            if !entry.recentEmails.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(entry.recentEmails.prefix(4)) { email in
                        EmailRowView(email: email)
                        if email.id != entry.recentEmails.prefix(4).last?.id {
                            Divider()
                                .opacity(0.5)
                        }
                    }
                }
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Inbox Zero")
                        .font(.title2.bold())
                    Text("You're all caught up!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Email Row (for large widget)

struct EmailRowView: View {
    let email: WidgetEmail

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconForArchetype(email.archetype))
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(colorForArchetype(email.archetype))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 3) {
                Text(email.title)
                    .font(.caption.bold())
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(email.sender)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(email.timeAgo)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(email.hpa)
                .font(.caption2)
                .foregroundStyle(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.blue.opacity(0.1))
                .cornerRadius(4)
        }
    }

    private func iconForArchetype(_ archetype: String) -> String {
        switch archetype {
        case "shopping": return "cart.fill"
        case "work": return "briefcase.fill"
        case "social": return "person.2.fill"
        case "finance": return "dollarsign.circle.fill"
        case "travel": return "airplane"
        case "personal": return "envelope.fill"
        default: return "envelope.fill"
        }
    }

    private func colorForArchetype(_ archetype: String) -> Color {
        switch archetype {
        case "shopping": return .orange
        case "work": return .blue
        case "social": return .pink
        case "finance": return .green
        case "travel": return .cyan
        case "personal": return .purple
        default: return .gray
        }
    }
}

// MARK: - Lock Screen Widgets

struct CircularWidgetView: View {
    let entry: InboxWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 14))
                Text("\(entry.unreadCount)")
                    .font(.system(size: 16, weight: .bold))
            }
        }
    }
}

struct RectangularWidgetView: View {
    let entry: InboxWidgetEntry

    var body: some View {
        if let topEmail = entry.topPriorityEmail {
            HStack(spacing: 8) {
                Image(systemName: iconForArchetype(topEmail.archetype))
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text(topEmail.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Text(topEmail.sender)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .widgetAccentable()
        } else {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Inbox Zero")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
    }

    private func iconForArchetype(_ archetype: String) -> String {
        switch archetype {
        case "shopping": return "cart.fill"
        case "work": return "briefcase.fill"
        case "social": return "person.2.fill"
        case "finance": return "dollarsign.circle.fill"
        case "travel": return "airplane"
        case "personal": return "envelope.fill"
        default: return "envelope.fill"
        }
    }
}

struct InlineWidgetView: View {
    let entry: InboxWidgetEntry

    var body: some View {
        if entry.unreadCount > 0 {
            Text("Zero: \(entry.unreadCount) unread")
        } else {
            Text("Zero: Inbox clear ✓")
        }
    }
}

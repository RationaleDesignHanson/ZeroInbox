import WidgetKit
import SwiftUI

/// Main widget entry point for Zero email widgets
/// Supports small, medium, and large home screen widgets, plus lock screen widgets (iOS 16+)
@main
struct ZeroWidget: Widget {
    let kind: String = "ZeroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InboxWidgetProvider()) { entry in
            InboxWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Zero Inbox")
        .description("Quick glance at your urgent emails and unread count")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,      // Lock screen circular
            .accessoryRectangular,   // Lock screen rectangular
            .accessoryInline         // Lock screen inline
        ])
    }
}

/// Small circular widget for lock screen showing unread count
struct UnreadCountWidget: Widget {
    let kind: String = "UnreadCountWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InboxWidgetProvider()) { entry in
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
        .configurationDisplayName("Unread Count")
        .description("Show unread email count")
        .supportedFamilies([.accessoryCircular])
    }
}

/// Rectangular lock screen widget showing top priority email
struct TopPriorityWidget: Widget {
    let kind: String = "TopPriorityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InboxWidgetProvider()) { entry in
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
        .configurationDisplayName("Top Priority")
        .description("Show your most urgent email")
        .supportedFamilies([.accessoryRectangular])
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

/// Inline lock screen widget
struct InlineStatusWidget: Widget {
    let kind: String = "InlineStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InboxWidgetProvider()) { entry in
            if entry.unreadCount > 0 {
                Text("Zero: \(entry.unreadCount) unread")
            } else {
                Text("Zero: Inbox clear ✓")
            }
        }
        .configurationDisplayName("Inbox Status")
        .description("Show inbox status inline")
        .supportedFamilies([.accessoryInline])
    }
}

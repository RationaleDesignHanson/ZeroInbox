//
//  ZeroListItem.swift
//  Zero Design System
//
//  READY TO INTEGRATE - Drop into: Zero_ios_2/Zero/Core/UI/Components/
//  Requires: DesignTokens.swift in Zero/Config/
//
//  Usage:
//  List {
//      ZeroListItem(
//          icon: "envelope.fill",
//          title: "Inbox",
//          badge: 12,
//          hasArrow: true
//      ) {
//          // Action
//      }
//  }
//

import SwiftUI

struct ZeroListItem: View {
    // MARK: - Types

    enum Style {
        case `default`
        case emphasized
        case subtle

        var titleColor: Color {
            switch self {
            case .default: return DesignTokens.Colors.textPrimary
            case .emphasized: return DesignTokens.Colors.accentBlue
            case .subtle: return DesignTokens.Colors.textSecondary
            }
        }

        var titleWeight: Font.Weight {
            switch self {
            case .emphasized: return .semibold
            case .default, .subtle: return .regular
            }
        }
    }

    // MARK: - Properties

    let icon: String? // SF Symbol name
    let iconColor: Color?
    let title: String
    let subtitle: String?
    let badge: Int?
    let hasArrow: Bool
    let style: Style
    let isSelected: Bool
    let action: (() -> Void)?

    // MARK: - Initializers

    init(
        icon: String? = nil,
        iconColor: Color? = nil,
        title: String,
        subtitle: String? = nil,
        badge: Int? = nil,
        hasArrow: Bool = false,
        style: Style = .default,
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.hasArrow = hasArrow
        self.style = style
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: DesignTokens.Spacing.element) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor ?? DesignTokens.Colors.accentBlue)
                        .frame(width: 32, height: 32)
                }

                // Title + Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DesignTokens.Typography.bodyMedium)
                        .fontWeight(style.titleWeight)
                        .foregroundColor(style.titleColor)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Badge
                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(DesignTokens.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.textInverse)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignTokens.Colors.accentBlue)
                        .clipShape(Capsule())
                }

                // Arrow
                if hasArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.component)
            .padding(.vertical, DesignTokens.Spacing.element)
            .background(isSelected ? DesignTokens.Colors.overlay10 : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Email List Item (Specialized variant)

struct ZeroEmailListItem: View {
    // MARK: - Properties

    let sender: String
    let subject: String
    let preview: String
    let timestamp: String
    let isUnread: Bool
    let isStarred: Bool
    let hasAttachment: Bool
    let isSelected: Bool
    let onTap: (() -> Void)?
    let onStar: (() -> Void)?

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: DesignTokens.Spacing.element) {
                // Unread indicator
                Circle()
                    .fill(isUnread ? DesignTokens.Colors.accentBlue : Color.clear)
                    .frame(width: 8, height: 8)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Sender + Timestamp
                    HStack {
                        Text(sender)
                            .font(DesignTokens.Typography.bodyMedium)
                            .fontWeight(isUnread ? .semibold : .regular)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        Spacer()

                        Text(timestamp)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }

                    // Subject
                    Text(subject)
                        .font(DesignTokens.Typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(1)

                    // Preview
                    Text(preview)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(2)

                    // Metadata (attachment, star)
                    HStack(spacing: DesignTokens.Spacing.inline) {
                        if hasAttachment {
                            HStack(spacing: 4) {
                                Image(systemName: "paperclip")
                                    .font(.system(size: 12))
                                Text("Attachment")
                                    .font(DesignTokens.Typography.caption)
                            }
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                        }

                        Spacer()

                        Button(action: { onStar?() }) {
                            Image(systemName: isStarred ? "star.fill" : "star")
                                .font(.system(size: 16))
                                .foregroundColor(isStarred ? DesignTokens.Colors.warningPrimary : DesignTokens.Colors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 4)
            }
            .padding(.horizontal, DesignTokens.Spacing.component)
            .padding(.vertical, DesignTokens.Spacing.element)
            .background(isSelected ? DesignTokens.Colors.overlay10 : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Swipeable List Item (With actions)

struct ZeroSwipeableListItem<Content: View>: View {
    // MARK: - Properties

    let content: Content
    let leadingActions: [SwipeAction]?
    let trailingActions: [SwipeAction]?

    struct SwipeAction: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let action: () -> Void

        init(icon: String, color: Color, action: @escaping () -> Void) {
            self.icon = icon
            self.color = color
            self.action = action
        }
    }

    init(
        leadingActions: [SwipeAction]? = nil,
        trailingActions: [SwipeAction]? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.leadingActions = leadingActions
        self.trailingActions = trailingActions
    }

    // MARK: - Body

    var body: some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if let actions = leadingActions {
                    ForEach(actions) { action in
                        Button(action: action.action) {
                            Image(systemName: action.icon)
                        }
                        .tint(action.color)
                    }
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if let actions = trailingActions {
                    ForEach(actions) { action in
                        Button(action: action.action) {
                            Image(systemName: action.icon)
                        }
                        .tint(action.color)
                    }
                }
            }
    }
}

// MARK: - Previews

#Preview("Basic List Items") {
    List {
        ZeroListItem(
            icon: "envelope.fill",
            title: "Inbox",
            badge: 12,
            hasArrow: true
        ) {}

        ZeroListItem(
            icon: "paperplane.fill",
            title: "Sent",
            hasArrow: true
        ) {}

        ZeroListItem(
            icon: "star.fill",
            iconColor: DesignTokens.Colors.warningPrimary,
            title: "Starred",
            badge: 3,
            hasArrow: true
        ) {}

        ZeroListItem(
            icon: "trash.fill",
            iconColor: DesignTokens.Colors.errorPrimary,
            title: "Trash",
            hasArrow: true
        ) {}
    }
}

#Preview("List Item Styles") {
    List {
        ZeroListItem(
            icon: "house.fill",
            title: "Default Style",
            subtitle: "Regular weight, primary color",
            style: .default
        ) {}

        ZeroListItem(
            icon: "bell.fill",
            title: "Emphasized Style",
            subtitle: "Semibold weight, accent color",
            style: .emphasized
        ) {}

        ZeroListItem(
            icon: "gear",
            title: "Subtle Style",
            subtitle: "Regular weight, secondary color",
            style: .subtle
        ) {}
    }
}

#Preview("With Subtitles") {
    List {
        ZeroListItem(
            icon: "person.fill",
            title: "John Appleseed",
            subtitle: "john@example.com",
            hasArrow: true
        ) {}

        ZeroListItem(
            icon: "building.2.fill",
            title: "Work Account",
            subtitle: "Synced 2 minutes ago",
            hasArrow: true
        ) {}

        ZeroListItem(
            icon: "icloud.fill",
            title: "iCloud Storage",
            subtitle: "4.2 GB available",
            hasArrow: true
        ) {}
    }
}

#Preview("Email List Items") {
    List {
        ZeroEmailListItem(
            sender: "Sarah Chen",
            subject: "Q4 Budget Review Meeting",
            preview: "Hi team, I've scheduled our quarterly budget review for next Tuesday at 2 PM. Please review the attached documents before the meeting.",
            timestamp: "2h ago",
            isUnread: true,
            isStarred: true,
            hasAttachment: true,
            isSelected: false,
            onTap: nil,
            onStar: nil
        )

        ZeroEmailListItem(
            sender: "Amazon",
            subject: "Your order has shipped",
            preview: "Good news! Your order #123-4567890 has shipped and will arrive by December 20th.",
            timestamp: "5h ago",
            isUnread: true,
            isStarred: false,
            hasAttachment: false,
            isSelected: false,
            onTap: nil,
            onStar: nil
        )

        ZeroEmailListItem(
            sender: "LinkedIn",
            subject: "Weekly job recommendations",
            preview: "We found 12 new jobs that match your preferences.",
            timestamp: "1d ago",
            isUnread: false,
            isStarred: false,
            hasAttachment: false,
            isSelected: true,
            onTap: nil,
            onStar: nil
        )
    }
}

#Preview("Swipeable Items") {
    List {
        ZeroSwipeableListItem(
            leadingActions: [
                .init(icon: "envelope.open.fill", color: DesignTokens.Colors.accentBlue) {},
                .init(icon: "star.fill", color: DesignTokens.Colors.warningPrimary) {}
            ],
            trailingActions: [
                .init(icon: "archivebox.fill", color: DesignTokens.Colors.successPrimary) {},
                .init(icon: "trash.fill", color: DesignTokens.Colors.errorPrimary) {}
            ]
        ) {
            ZeroEmailListItem(
                sender: "Sarah Chen",
                subject: "Q4 Budget Review",
                preview: "Hi team, I've scheduled our quarterly budget review...",
                timestamp: "2h ago",
                isUnread: true,
                isStarred: false,
                hasAttachment: true,
                isSelected: false,
                onTap: nil,
                onStar: nil
            )
        }

        ZeroSwipeableListItem(
            trailingActions: [
                .init(icon: "trash.fill", color: DesignTokens.Colors.errorPrimary) {}
            ]
        ) {
            ZeroListItem(
                icon: "bell.fill",
                title: "Notifications",
                subtitle: "Swipe left to delete",
                badge: 5
            ) {}
        }
    }
}

#Preview("Selected States") {
    List {
        ZeroListItem(
            icon: "envelope.fill",
            title: "Not Selected",
            badge: 12,
            isSelected: false
        ) {}

        ZeroListItem(
            icon: "paperplane.fill",
            title: "Selected",
            isSelected: true
        ) {}

        ZeroListItem(
            icon: "star.fill",
            title: "Also Not Selected",
            badge: 3,
            isSelected: false
        ) {}
    }
}

#Preview("Dark Mode") {
    List {
        ZeroListItem(
            icon: "envelope.fill",
            title: "Inbox",
            badge: 12,
            hasArrow: true
        ) {}

        ZeroEmailListItem(
            sender: "Sarah Chen",
            subject: "Q4 Budget Review",
            preview: "Hi team, I've scheduled our quarterly budget review for next Tuesday at 2 PM.",
            timestamp: "2h ago",
            isUnread: true,
            isStarred: true,
            hasAttachment: true,
            isSelected: false,
            onTap: nil,
            onStar: nil
        )
    }
    .preferredColorScheme(.dark)
}
